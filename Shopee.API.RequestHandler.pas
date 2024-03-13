{
  This unit has the responsibility of holding the TRequestParam and
  TRequestParams types, its enumerator and TRequestHandler, which is an
  abstract class to provide a common base for Request making to other classes.
}
unit Shopee.API.RequestHandler;

interface

uses
  System.Classes,
  System.SysUtils,
  System.DateUtils,
  System.Hash,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.NetConsts,
  System.JSON;

type
  TRequestParamsEnumerator = class;
  TRequestCapable = class;
  {
    TRequestParam is the unitary element of TRequestParams. It holds the
    Name and Value of the parameter.
  }
  TRequestParam = record
    private
      FName: string;
      FValue: string;
    public
      constructor Create(AName, AValue: string); overload;

      property Name: string read FName;
      property Value: string read FValue;
  end;

  {
    TRequestParams groups the parameter elements of a request.
    For sake of simplicity, it must be used only for simple
    requests, for instance: Query strings.
  }
  TRequestParams = record
    private type RequestPrivateArray = array of TRequestParam;

    private
      FValues: RequestPrivateArray;
      FCount: Integer;
      function GetParam(Index: Integer): TRequestParam;

    public
      procedure AddItem(AParamName, AParamValue: string);
      procedure RemoveItem(AParamIndex: Integer);

      function GetEnumerator: TRequestParamsEnumerator;
      function AsStringList: TStringList;
      function AsPayload: string;

      property Parameters[Index: Integer]:TRequestParam read GetParam; default;
      property Count: Integer read FCount;
  end;

  // Enumerator for the TRequestParams
  TRequestParamsEnumerator = class
    private
      FIndex: Integer;
      FList: TRequestParams;
    public
      constructor Create(AList: TRequestParams);

      function MoveNext: Boolean;
      function GetCurrent: TRequestParam;

      property Current: TRequestParam read GetCurrent;
  end;

  // Request Capable Class, Adds the Request Capability for Authorizator, for instance.
  TRequestCapable = class
    private
      FAPIKey, FPartnerID, FHost: string;

      FHTTPResponse: IHTTPResponse;
      FPayload: string;

      function GetSignString(AConcatString: string): string;
      function BuildQueryString(AParameters: TRequestParams): string;
      function GetPostResponse: IHTTPResponse;
      
    protected
      function GetPublicSignString(const AAPIPath: string; var ATimestampOutput: String): string;
      // TO-DO: GetShopSignString and GetMerchantSignString
      function GenerateRequestURL(const AAPIPath: string; AParameters: TRequestParams): string;
      // Actually makes the request
      function MakeRequest(): string; virtual; abstract;
      // Makes a POST Request. Overload This to accept JSON too.
      function MakePostRequest(AAPIPath: string; ACommonParams: TRequestParams; APostParams: TJSONObject): string;

      //
      property PostResponse: IHTTPResponse read GetPostResponse;
      // Latest payload sent.
      property Payload: string read FPayload;


    public
      constructor Create(AHost, APIKey, APartnerID: string); virtual;
    const
      REDIRECT_URL_WS = 'http://127.0.0.1';
      API_PATH_AUTHORIZATION = '/api/v2/shop/auth_partner';
      API_PATH_AUTHENTICATION = '/api/v2/auth/token/get';
      TOKEN_LIFESPAN_HOURS = 4;

  end;
implementation

{ TRequestCapable }

constructor TRequestCapable.Create(AHost, APIKey, APartnerID: string);
begin
  FAPIKey := APIKey;
  FPartnerID := APartnerID;
  FHost := AHost;
end;

function TRequestCapable.GetPostResponse: IHTTPResponse;
begin
  if Assigned(FHTTPResponse) then
    Result := FHTTPResponse
  else
    Result := nil;
end;

function TRequestCapable.GetPublicSignString(const AAPIPath: string; var ATimestampOutput: String): string;
var
  ConcatStr: string;
begin
  // Important: Conversion to UTC is required to match server timestamp.
  ATimestampOutput := IntToStr(DateTimeToUnix(TTimeZone.Local.ToUniversalTime(Now)));

  //In the context of UTF-8 encoding, the result of concatenating several Unicode strings and then encoding the entire
  //concatenation as UTF-8 is the same as encoding each string as UTF-8 separately and then concatenating the bytes.
  //This property holds because UTF-8 is designed to be a byte-oriented encoding that maintains self-synchronization:
  //it allows a decoder to pick up at any point in a byte stream and find the next character boundary without error, and it
  //does not introduce or change byte values based on context within a string.
  ConcatStr := FPartnerID + AAPIPath + ATimestampOutput;
  // result := System.UTF8ToString(GetSignString(ConcatStr));
  Result := GetSignString(ConcatStr);
end;

function TRequestCapable.GetSignString(AConcatString: string): string;
var
  KeyBytes, InputBytes, HashBytes: TBytes;
begin
  // Converts both key and string to UTF8
  InputBytes := TEncoding.UTF8.GetBytes(AConcatString);
  KeyBytes := TEncoding.UTF8.GetBytes(FAPIKey);

  HashBytes :=  THashSHA2.GetHMACAsBytes(InputBytes, KeyBytes, THashSHA2.TSHA2Version.SHA256);

  Result := THash.DigestAsString(HashBytes);
end;

function TRequestCapable.MakePostRequest(AAPIPath: string; ACommonParams: TRequestParams;
  APostParams: TJSONObject): string;
var
  RequestURL: string;
  HTTPClient: THTTPClient;
begin
  RequestURL := GenerateRequestURL(AAPIPath, ACommonParams);
  HTTPClient := THTTPClient.Create;
  try
    HTTPClient.ContentType := 'application/json';
    // function Post(const AURL: string; const ASource: TStrings;
    // const AResponseContent: TStream = nil;
    // const AEncoding: TEncoding = nil; const AHeaders: TNetHeaders = nil)
    FHTTPResponse := HTTPClient.Post(RequestURL, TStringStream.Create(APostParams.ToString, TEncoding.UTF8));
    if FHTTPResponse.StatusCode = 200 then
    begin
      Result := FHTTPResponse.ContentAsString();

    end else
    begin
      Result := IntTOStr(FHTTPResponse.StatusCode) +' '+ FHTTPResponse.StatusText + ' ' + FHTTPResponse.ContentAsString();
    end;

  finally
    HTTPClient.Free;
  end;
end;

function TRequestCapable.GenerateRequestURL(const AAPIPath: string;
  AParameters: TRequestParams): string;
var
  QueryString: string;
  RequestURL: string;
begin
  QueryString := BuildQueryString(AParameters);
  RequestURL := FHost + AAPIPath + QueryString;
  Result := RequestURL;
  // Actually Makes the Request
end;

// Timestamp passed as parameter must be the same used on GetPublicSignString
function TRequestCapable.BuildQueryString(AParameters: TRequestParams): string;
var 
  QueryString: string;
  RequestParam: TRequestParam;
begin
  QueryString := '?';
  for RequestParam in AParameters do
  begin
    if QueryString.EndsWith('?') then
    begin
      QueryString := QueryString + RequestParam.Name + '=' + RequestParam.Value;
    end else begin
      QueryString := QueryString + '&' + RequestParam.Name + '=' + RequestParam.Value;
    end;
  end;

  Result := QueryString;
end;

{ TRequestParam }

constructor TRequestParam.Create(AName, AValue: string);
begin
  FName := AName;
  FValue := AValue;
end;

{ TRequestParams }

procedure TRequestParams.AddItem(AParamName, AParamValue: string);
begin
  SetLength(FValues, Length(FValues) + 1);
  FCount := Length(FValues);

  FValues[Length(FValues) - 1] := TRequestParam.Create(AParamName, AParamValue);
end;

// MIGHT CAUSE ISSUES ON OLDER DELPHI VERSIONS!
function TRequestParams.AsPayload: string;
var
  Parameter: TRequestParam;
  JSONObject: TJSONObject;
begin
  JSONObject := TJSONObject.Create;
  try
    for Parameter in FValues do
    begin

      JSONObject.AddPair(Parameter.Name, Parameter.Value);
      // Type check, then assign correctly within a json object string.
    end;
    Result := JSONObject.ToString;
  finally
    JSONObject.Free;
  end;

end;

function TRequestParams.AsStringList: TStringList;
var
  Parameter: TRequestParam;
begin
  Result := TStringList.Create;
  for Parameter in FValues do
  begin
    Result.Add(Parameter.Name + '=' + Parameter.Value);
  end;
end;

function TRequestParams.GetEnumerator: TRequestParamsEnumerator;
begin
  Result := TRequestParamsEnumerator.Create(Self);
end;

function TRequestParams.GetParam(Index: Integer): TRequestParam;
begin
  if (Length(FValues) = 0) or (Length(FValues) - 1 < Index) then
  begin
    raise ERangeError.Create('The provided index does not exist in the current list') at @TRequestParams.GetParam;
  end else
  begin
    Result := FValues[Index];
  end;
end;

procedure TRequestParams.RemoveItem(AParamIndex: Integer);
var
  ArrLength: Integer;
  SurplusElements: Integer;
begin
  ArrLength := Length(FValues);
  if (ArrLength > 0) and (AParamIndex < ArrLength) then
  begin
    // Frees dynamically allocated memory
    Finalize(FValues[AParamIndex]);

    // Elements that are to the right of the "hole". If it's 0,
    // it means we had deleted the last one element and there are 0 to the right.
    SurplusElements := ArrLength - AParamIndex;


    if SurplusElements > 0 then
    begin
      // Move signature: procedure Move(const Source; var Dest; Count: NativeInt);
      // It will move SizeOf(TRequestParam) * SurplusElements bytes to the starting position FValues[AParamIndex]
      // and it will fill the hole created when we finalize() that value before.
      Move(FValues[AParamIndex + 1], FValues[AParamIndex], SizeOf(TRequestParam)* SurplusElements);
    end;

    // By the docs: "Initialize simply zeros out the memory occupied by long strings"
    // https://docwiki.embarcadero.com/Libraries/Athens/en/System.Initialize
    // So we are, actually, cleaning that spot we won't use anymore.
    Initialize(FValues[ArrLength - 1]);
    SetLength(FValues, ArrLength - 1);

    FCount := ArrLength - 1;
  end else
  begin
    raise ERangeError.Create('The provided index does not exist in the current list') at @TRequestParams.GetParam;
  end;

end;

{ TRequestParamsEnumerator }

constructor TRequestParamsEnumerator.Create(AList: TRequestParams);
begin
  FList := AList;
  FIndex := -1;
end;

function TRequestParamsEnumerator.GetCurrent: TRequestParam;
begin
  Result := FList[FIndex];
end;

function TRequestParamsEnumerator.MoveNext: Boolean;
begin
  Result := FIndex < (FList.Count - 1);
  if Result then
    Inc(FIndex);
end;

end.
