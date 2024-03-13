{
  This unit is responsible for handling Authentication within Shopee OAuth
  context. Its only class inherits from TRequestCapable, which lives in
  Shopee.API.RequestHandler, thus have the ability to make requests.

  This class is used by the context manager (FUTURE IMPLMENETATION)
  to request for the first time access token or refreshing the access token.
}
unit Shopee.API.OAuth.Authentication;

interface
uses
  System.SysUtils, System.JSON,
  Shopee.API.RequestHandler, Core.Utils;

type
  TAuthenticator = class(TRequestCapable)
  private
    FPartnerID, FCode, FEntityID, FAuthorizationType: string;
    FTimestamp: string;
    FSignature: string;

    FRequestParameters: TRequestParams;
    FRequestBodyParameters: string;
    FRequestStatusCode: Integer;

    function GetTokenShopLevel(AShopID: string): string;
  public
    function GetToken: string;
    constructor Create(AHost, AAPIKey, APartnerID, ACode, AEntityID, AAuthorizationType: string); reintroduce;

    property RequestBody: string read FRequestBodyParameters;
    property RequestStatusCode: Integer read FRequestStatusCode;
  end;

implementation

{ TAuthenticator }

constructor TAuthenticator.Create(AHost, AAPIKey, APartnerID, ACode, AEntityID, AAuthorizationType: string);
begin
  inherited Create(AHost, AAPIKey, APartnerID);
  FPartnerID := APartnerID;
  FCode := ACode;
  FEntityID := AEntityID;
  FAuthorizationType := AAuthorizationType;
end;

function TAuthenticator.GetToken: string;
begin
  Result := '';

  if FAuthorizationType = 'Shop' then
  begin
    Result := GetTokenShopLevel(FEntityID);
  end else if FAuthorizationType = 'Account' then
  begin
    //Result := GetTokenAccountLevel(FEntityID); TO-DO
  end;

end;

function TAuthenticator.GetTokenShopLevel(AShopID: string): string;
var
  RequestBody: TJSONObject;
begin
  FSignature := GetPublicSignString(API_PATH_AUTHENTICATION, FTimestamp);

  // Constroi os parametros da Querystring
  FRequestParameters.AddItem('partner_id', FPartnerID);
  FRequestParameters.AddItem('timestamp', FTimeStamp);
  FRequestParameters.AddItem('sign', FSignature);

  // Constroi os parametros do corpo da requisição
  RequestBody := TJSONObject.Create;
  try
    RequestBody.AddPair('code', FCode);
    RequestBody.AddPair('partner_id', TJSONNumber.Create(StrToInt(FPartnerID)));
    RequestBody.AddPair('shop_id', TJSONNumber.Create(StrToInt(FEntityID)));

    // Solicita o Token
    Result := MakePostRequest(API_PATH_AUTHENTICATION, FRequestParameters, RequestBody);
    FRequestBodyParameters := RequestBody.ToString;
    FRequestStatusCode := PostResponse.StatusCode;
  finally
    RequestBody.Free;
  end;

end;

end.
