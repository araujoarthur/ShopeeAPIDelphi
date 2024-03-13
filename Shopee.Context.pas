unit Shopee.Context;

interface
uses
  VCL.Dialogs,
  System.Classes,
  System.JSON,
  System.SysUtils,
  SyncObjs,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.NetConsts,
  Shopee.API.OAuth.Authorization,
  Shopee.API.OAuth.Authentication,
  Core.GlobalEvents,
  Shopee.Interfaces.DataHolder,
  Shopee.Core.DataHolder,
  Shopee.API.Endpoints,
  Core.Utils;

type
  TTokenReceivedEvent = procedure of object;
  TRequestFailedEvent = procedure of object;
  TAuthorizationDoneEvent = procedure of object;
  TGettingTokenErrorOcurredEvent = procedure of object;

  // This function must return true if there is no updated data on Database,
  // otherwise returns false so the worker knows the user already updated the FDataHolder.
  TTokenRefreshNeededEvent = reference to function: Boolean;

  TRequestData = record 
  private
    FRequestURL, FRequestSignature, FRequestPayload: string;
    FRequestError: Boolean;
    FRequestCommonParameters: TRequestParams;
    FRequestResult: string;
    FRequestMethod: string;
  public
    property URL: string read FRequestURL write FRequestURL;
    property Signature: string read FRequestSignature write FRequestSignature;
    property hasError: Boolean read FRequestError write FRequestError;
    property CommonParameters: TRequestParams read FRequestCommonParameters write FRequestCommonParameters;
    property Payload: string read FRequestPayload write FRequestPayload;
    property RequestResult: string read FRequestResult write FRequestResult;
    property Method: string read FRequestMethod write FRequestMethod;
  end;
  
  TErrorData = record
  private
    FError, FMessage: string;
    FErrorTimestamp: Integer;
    FErrorDT: TDateTime;
    FRequestResponseCode: Integer;
  public
    constructor Create(AError, AMessage: string; AResponseCode: Integer);

    property Error: string read FError write FError;
    property ErrorTimestamp: Integer read FErrorTimestamp write FErrorTimestamp;
    property ErrorDateTime: TDateTime read FErrorDT write FErrorDT;
    property RequestResponseCode: Integer read FRequestResponseCode write FRequestResponseCode;
  end;
  
  TShopeeContext = class
  private
    FHost: string;
    FAPI_Key: string;
    FPartnerID: string;

    FRequestResultString: string;
    FRecentRequestBodyString: string;
    FRecentRequestStatusCode: Integer;
    FTokenResponseJSON: TJSONObject;
    FLastErrorOccurred: TErrorData;
    FLastRequestData: TRequestData;

    FOnTokenReceived: TTokenReceivedEvent;
    FOnRequestFailed: TRequestFailedEvent;
    FOnAuthorizationDone: TAuthorizationDoneEvent;
    FOnGettingTokenErrorOcurred: TGettingTokenErrorOcurredEvent;
    FOnTokenRefreshNeeded: TTokenRefreshNeededEvent;

    FDataHolder: IDataHolder;

    procedure CheckAndAuthorize;
    procedure Authorize;
    procedure GetData(ACode: string);
    procedure GetToken;
    procedure ForceGetToken;
  public
    constructor Create(AMode, AAPIKey, APartnerID: string);
    destructor Destroy; override;

    function MakeRequest(AEndpoint: IEndpoint; APayload: TJSONObject): string;

    property RequestResultString: string read FRequestResultString;
    property RecentRequestBodyString: string read FRecentRequestBodyString;
    property RecentRequestStatusCode: Integer read FRecentRequestStatusCode;
    property LastErrorOccurred: TErrorData read FLastErrorOccurred;
    property LastRequestData: TRequestData read FLastRequestData;

    {EVENTS}
    property OnTokenReceived: TTokenReceivedEvent read FOnTokenReceived write FOnTokenReceived;
    property OnRequestFailed: TRequestFailedEvent read FOnRequestFailed write FOnRequestFailed;
    property OnAuthorizationDone: TAuthorizationDoneEvent read FOnAuthorizationDone write FOnAuthorizationDone;
    property OnGettingTokenErrorOcurred: TGettingTokenErrorOcurredEvent read FOnGettingTokenErrorOcurred write FOnGettingTokenErrorOcurred;
    property OnTokenRefreshNeeded: TTokenRefreshNeededEvent read FOnTokenRefreshNeeded write FOnTokenRefreshNeeded;

    {$IFDEF DEBUG}
    property DataHolder: IDataHolder read FDataHolder;
    {$ENDIF}
  end;

  const
    TEST_SHOPEE = 'https://partner.test-stable.shopeemobile.com';
    PRODUCTION_SHOPEE_BR = 'https://openplatform.shopee.com.br';

implementation

{ TContext }

procedure TShopeeContext.Authorize;
var
  Authorizator: TShopeeAuthorizator;
begin
  // Request Authorization;
  Authorizator := TShopeeAuthorizator.Create(FDataHolder, FHost, FAPI_Key, FPartnerID, 8342);
  try
    // Resets the event before triggering.
    AuthorizationDone.ResetEvent;

    Authorizator.AuthorizationRequest;

    if AuthorizationDone.WaitFor(45000) <> wrSignaled then
    begin
      raise Exception.Create('Authorization Timed Out');
    end else
    begin
      ShowMessage('Autenticado com Sucesso');
      ShowMessage(FDataHolder.Code + ' ' + FDataHolder.EntityID);
    end;

  finally
    Authorizator.Free;
  end;

end;

procedure TShopeeContext.CheckAndAuthorize;
begin
  // Checks if the authorization has been granted and is younger than 365 days.
   if (not FDataHolder.IsAuthorized) or ((Now - FDataHolder.AuthorizationDate) > 365) then
  begin
    Authorize;
  end;

  if Assigned(FOnAuthorizationDone) then
    FOnAuthorizationDone();
end;

constructor TShopeeContext.Create(AMode, AAPIKey, APartnerID: string);
begin
  if (AMode <> TEST_SHOPEE) and (AMode <> PRODUCTION_SHOPEE_BR) then
    raise Exception.Create('Mode Invalid for Context');

  FDataHolder := TDataHolder.Create();
  FHost := AMode;
  FAPI_Key := AAPIKey;
  FPartnerID := APartnerID;
end;

destructor TShopeeContext.Destroy;
begin
  if Assigned(FTokenResponseJSON) then
    FTokenResponseJSON.Free;
  inherited;
end;

procedure TShopeeContext.ForceGetToken;
begin
    if not FDataHolder.HasAccessToken then
    begin
      // The First Time Requesting the Access Token;
      GetData(FDataHolder.Code);
    end else
    begin
      // Not the first time requesting access token;
      GetData(FDataHolder.RefreshToken);
    end;
end;

procedure TShopeeContext.GetData(ACode: string);
var
  Authenticator: TAuthenticator;
begin

  Authenticator := TAuthenticator.Create(FHost, FAPI_Key, FPartnerID, FDataHolder.Code, FDataHolder.EntityID, FDataHolder.AuthType);
  try
    FRequestResultString := Authenticator.GetToken;
    FRecentRequestBodyString := Authenticator.RequestBody;
    FRecentRequestStatusCode := Authenticator.RequestStatusCode;
  finally
    Authenticator.Free;
  end;

  FTokenResponseJSON := TJSONObject.ParseJSONValue(FRequestResultString) as TJSONObject;

  // If the request is not Forbidden.
  if (FRecentRequestStatusCode <> 403) and (FTokenResponseJSON.Get('error').Value <> '') then
  begin
    FDataHolder.AccessToken := FTokenResponseJSON.Get('access_token').Value;
    FDataHolder.RefreshToken := FTokenResponseJSON.Get('refresh_token').Value;
    FDataHolder.ExpireTimestamp := Integer(GetCurrentUTCTimestamp) + Integer(FTokenResponseJson.Get('expire_in').Value) - 150;
  end else
  begin
    // Opens a door to check the last error occurred.
    FLastErrorOccurred := TErrorData.Create(FTokenResponseJSON.Get('error').Value, 
                                            FTokenResponseJSON.Get('message').Value,
                                            FRecentRequestStatusCode);
  end;

end;

procedure TShopeeContext.GetToken;
begin
  CheckAndAuthorize;

  if (FDataHolder.IsAuthorized and FDataHolder.MustRenew) then
  begin
    ForceGetToken;
  end;

  if Assigned(FOnTokenReceived) then
    FOnTokenReceived();
end;

function TShopeeContext.MakeRequest(AEndpoint: IEndpoint; APayload: TJSONObject): string;
var
  RequestSignature: string;
  RequestURL: string;
  RequestData: TRequestData;
  CommonParameters: TRequestParams;
  iSignatureTimestamp: Integer;
  HTTPClient: THTTPClient;
  HTTPResponse: IHTTPResponse;
begin
  CheckAndAuthorize; // Check if authorization is needed, authorize if so, returns if don't.

  if not FDataHolder.HasAccessToken then // Checks if there's access token already.
  begin                                  // This assumes the user is either authenticating for the first time OR have already set the up to date token in this session.
    GetToken();
  end else if FDataHolder.MustRenew then
  begin
    if not OnTokenRefreshNeeded() then
    begin
      ForceGetToken;
    end;
  end;

  // Gets the Signature String and Stores the Signature Timestamp.
  iSignatureTimestamp := GetCurrentUTCTimestamp;
  if AEndpoint.SignatureType = stPublic then
  begin
    // Generates Signature and Common Parameters for Public Request TO-DO;
    end else if AEndpoint.SignatureType = stShop then
  begin
    //  Generates Signature and Common Parameters for Shop Request; TO-DO
    RequestSignature := AEndpoint.GetSignature(FAPI_Key, FPartnerID, iSignatureTimestamp, FDataHolder.AccessToken, FDataHolder.EntityID);
    CommonParameters.AddItem('sign', RequestSignature);
    CommonParameters.AddItem('partner_id', FPartnerID);
    CommonParameters.AddItem('path', AEndpoint.Endpoint);
    CommonParameters.AddItem('timestamp', IntToStr(iSignatureTimestamp));
    CommonParameters.AddItem('shop_id', FDataHolder.EntityID);
  end else
  begin
    //  Generates Signature and Common Parameters for Merchant Request; TO-DO
  end;

  // Builds the URL.
  RequestURL := GenerateRequestURL(FHost, AEndpoint.Endpoint, CommonParameters);

  // Start the building of LastRequestData logging record.
  RequestData.URL := RequestURL;
  RequestData.CommonParameters := CommonParameters;
  RequestData.Signature := IntToStr(iSignatureTimestamp);
   

  
  // Creates the HTTP client needed for requests.
  HTTPClient := THTTPClient.Create;
  try
    HTTPClient.ContentType := 'application/json';
    try
      // Bifurcates dependig on the type of request needed.
      if AEndpoint.EndpointMethod = rmGet then
      begin
        RequestData.Method := 'GET'; // Saves the request method in the LastRequestData logging record.
        RequestData.Payload := '';
        HTTPResponse := HTTPClient.Get(RequestURL);
      end else if AEndpoint.EndpointMethod = rmPost then
      begin
        RequestData.Method := 'POST';
        RequestData.Payload := APayload.ToString;
        HTTPResponse := HTTPClient.Post(RequestURL, TStringStream.Create(APayload.ToString, TEncoding.UTF8));
      end;  
    except on E: Exception do
      raise Exception.Create(E.Message);
    end;

    // Deal with the response, check if error
    // Use recursion to recall it if a 403 rises to ensure data needs to be updated. Pensar bastante, fazer diagrama se necessário.
    // (If an error_auth rises, it might have updated on client side the refresh/access token, so if we recall we must ensure we receive data from client
    // to update the FDataHolder. 
    
  finally
    HTTPClient.Free;
  end;

  FLastRequestData := RequestData;





  // From here it's assumed the data is up to date on the FDataHolder.

  {
   ALGORITHIMIC TO-DO LIST
   FROM THE ENDPOINT, TAKE TYPE OF SIGNATURE (Implement IEndpoint as param)
   GENERATE THE SIGNATURE

   BUILD UP THE QUERY STRING

   CREATE TSTRINGSTREAM FROM THE APAYLOAD

   MAKE THE REQUEST

   EVALUATE THE RESULT WITHIN CONDITIONS BELOW
  }


    {
    If the Request is 403 Forbidden, we must:
    1) Check if it's time to Get the Token again. If it is, call users
    OnRefreshNeeded to safely refresh the token. On the user side, this function
    should check if there's updated data on DB before requesting the token again.

    2) If it's not time to get the token again, call users defined
    OnRequestFailed and retry the operation.
  }
end;

{ TErrorData }

constructor TErrorData.Create(AError, AMessage: string; AResponseCode: Integer);
begin
  FErrorTimestamp := GetCurrentUTCTimestamp;
  FErrorDT := Now();
  
  FError := AError;
  FMessage := AMessage;
  FRequestResponseCode := AResponseCode;
end;

end.
