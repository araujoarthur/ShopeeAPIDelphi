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
  System.JSON,
  Core.Utils;

type
  // MARKED FOR FUTURE DEPRECIATION
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

end.
