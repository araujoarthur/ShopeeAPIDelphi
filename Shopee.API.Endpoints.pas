unit Shopee.API.Endpoints;

interface
uses
  System.DateUtils,
  System.SysUtils,
  System.Hash;
type
  TSignatureType = (stPublic, stShop, stMerchant);
  TRequestMethod = (rmGet, rmPost, rmPut, rmOption);
  IEndpoint = interface
    function GetEndpoint: string;
    function GetSignatureType: TSignatureType;
    function GetSignature(AAPIKey, APartnerID: string; ATimestamp: Integer; AAccessToken: string = ''; EntityID: string = ''): string;
    function GetProtocolMethod: TRequestMethod;

    property Endpoint: string read GetEndpoint;
    property SignatureType: TSignatureType read GetSignatureType;
    property EndpointMethod: TRequestMethod read GetProtocolMethod;
  end;

  TEndpoint = class(TInterfacedObject, IEndpoint)
  private
    FEndpoint: string;
    FSignatureType: TSignatureType;
    FProtocolType: TRequestMethod;

    function GetEndpoint: string;
    function GetSignatureType: TSignatureType;
    function GetProtocolMethod: TRequestMethod;

  public
    function GetSignature(AAPIKey, APartnerID: string; ATimestamp: Integer; AAccessToken: string = ''; EntityID: string = ''): string;
    constructor Create(AURL: string; ASignatureType: TSignatureType; AMethod: TRequestMethod); reintroduce; virtual; final;
  end;

  Endpoints = record
    ShopAPI: string;
    MerchantAPI: string;
    PublicAPI: string;
  end;

implementation

{ TShopAPIEndpoint }

constructor TEndpoint.Create(AURL: string; ASignatureType: TSignatureType; AMethod: TRequestMethod);
begin
  inherited Create;
  FEndpoint := AURL;
  FSignatureType := ASignatureType;
end;

function TEndpoint.GetEndpoint: string;
begin
  Result := FEndpoint;
end;

function TEndpoint.GetProtocolMethod: TRequestMethod;
begin
  Result := FProtocolType;
end;

function TEndpoint.GetSignature(AAPIKey, APartnerID: string; ATimestamp: Integer;  AAccessToken: string = ''; EntityID: string = ''): string;
var
  ConcatStr: string;
  InputBytes, KeyBytes, HashBytes: TBytes;
begin
  {
    Concatena os dados fornecidos na ordem correta, de modo que os dados não necessários são inseridos por ultimo
    e caso não haja informação (seja = ''), simplesmente não concatena.
  }
  ConcatStr := APartnerID + FEndpoint + IntToStr(ATimestamp) + AAccessToken + EntityID;

  InputBytes := TEncoding.UTF8.GetBytes(ConcatStr);
  KeyBytes := TEncoding.UTF8.GetBytes(AAPIKey);

  HashBytes := THashSHA2.GetHMACAsBytes(InputBytes, KeyBytes, THashSHA2.TSHA2Version.SHA256);

  Result := THash.DigestAsString(HashBytes);
end;


function TEndpoint.GetSignatureType: TSignatureType;
begin
  Result := FSignatureType;
end;

end.
