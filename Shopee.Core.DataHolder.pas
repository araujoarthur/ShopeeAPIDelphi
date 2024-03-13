unit Shopee.Core.DataHolder;

interface

uses
  System.DateUtils, System.SysUtils,
  Shopee.Interfaces.DataHolder, Core.Utils;

type
  TDataHolder = class(TInterfacedObject, IDataHolder)
  private
    FCode, FAuthType, FEntityID, FRefreshToken, FAccessToken: string;
    FExpireTimestamp: UInt64;

    FAuthorizationDate: TDateTime;

    FMustRenew: Boolean;

    function GetCode: string;
    function GetAuthType: string;
    function GetEntityID: string;
    function GetRefreshToken: string;
    function GetAccessToken: string;
    function GetMustRenew: Boolean;
    function GetExpireTS: UInt64;
    function GetAuthorizationDate: TDateTime;

    procedure SetCode(AValue: string);
    procedure SetAuthType(AValue: string);
    procedure SetEntityID(AValue: string);
    procedure SetRefreshToken(AValue: string);
    procedure SetAccessToken(AValue: string);
    procedure SetExpiretTimestamp(AValue: UInt64);
    procedure SetAuthorizationDate(ADate: TDateTime);

  public
    constructor Create;
    function HasRefreshToken: Boolean;
    function HasAccessToken: Boolean;
    function HasCode: Boolean;
    function IsAuthorized: Boolean;
  end;

implementation

{ TDataHolder }

constructor TDataHolder.Create;
begin
    FCode := '';
    FAuthType := '';
    FEntityID := '';
    FRefreshToken := '';
    FAccessToken := '';
    FExpireTimestamp := 0;
    FAuthorizationDate := EncodeDate(1970, 1, 1);

    FMustRenew := True;
end;

function TDataHolder.GetAccessToken: string;
begin
  Result := FAccessToken;
end;

function TDataHolder.GetAuthorizationDate: TDateTime;
begin
 Result := FAuthorizationDate;
end;

function TDataHolder.GetAuthType: string;
begin
  Result := FAuthType;
end;

function TDataHolder.GetCode: string;
begin
  Result := FCode;
end;

function TDataHolder.GetEntityID: string;
begin
  Result := FEntityID;
end;

function TDataHolder.GetExpireTS: UInt64;
begin
  Result := FExpireTimestamp;
end;

function TDataHolder.GetMustRenew: Boolean;
begin
  if FExpireTimestamp - GetCurrentUTCTimestamp < 150 then
  begin
    Result := True;
  end else
  begin
    Result := False;
  end;

end;

function TDataHolder.GetRefreshToken: string;
begin
  Result := FRefreshToken;
end;

function TDataHolder.HasAccessToken: Boolean;
begin
  Result := False;
  if FAccessToken <> '' then
    Result := True;
end;

function TDataHolder.HasCode: Boolean;
begin
  Result := False;
  if FCode <> '' then
    Result := True;
end;

function TDataHolder.HasRefreshToken: Boolean;
begin
  Result := False;
  if FRefreshToken <> '' then
    Result := True;
end;

function TDataHolder.IsAuthorized: Boolean;
begin
  Result := HasCode();
end;

procedure TDataHolder.SetExpiretTimestamp(AValue: UInt64);
begin
  FExpireTimestamp := AValue;
end;

procedure TDataHolder.SetAccessToken(AValue: string);
begin
  FAccessToken := AValue;
end;

procedure TDataHolder.SetAuthorizationDate(ADate: TDateTime);
begin
  FAuthorizationDate := ADate;
end;

procedure TDataHolder.SetAuthType(AValue: string);
begin
  FAuthType := AValue;
end;

procedure TDataHolder.SetCode(AValue: string);
begin
  FCode := Avalue;
end;

procedure TDataHolder.SetEntityID(AValue: string);
begin
  FEntityID := AValue;
end;

procedure TDataHolder.SetRefreshToken(AValue: string);
begin
  FRefreshToken := AValue;
end;

end.
