{
  This unit holds responsibility for creating, reading and writing into the
  configuration file to keep the (FUTURE IMPLEMENTATION) context manager up-to-date.

  Here the context manager can grab information about authorization grant, and current
  authorization code.
}
unit Shopee.API.Configurator;

interface
uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  System.DateUtils,
  IniFiles;

type
  TConfiguratorFile = class
  private
    FIniFile: TMemIniFile;
    FExePath: string;
    FIniPath: string;

    FFieldsAvailable: Boolean;
    FCode: string;
    FEntityID: string;
    FAuthType: string;
    FAuthorizationGranted: Boolean;
    FAuthorizationDate: TDateTime;
    FRefreshToken: string;
    
    function GetAuthType: string;
    function GetCode: string;
    function GetEntityID: string;
    
  public
    FStringDebug: string;
    constructor Create();
    destructor Destroy(); reintroduce;

    procedure SaveAuthorizationInfo(ACode, AAuthID, AAuthType: string);

    property ExePath: string read FExePath;
    property IniPath: string read FIniPath;
    property Code: string read GetCode;
    property EntityID: string read GetEntityID;
    property AuthType: string read GetAuthType;
    property AuthorizationDate: TDateTime read FAuthorizationDate;
    property AuthorizationGranted: Boolean read FAuthorizationGranted;
  end;

implementation

{ TConfiguratorFile }

constructor TConfiguratorFile.Create;
var
  initial_configs: TStringList;
begin
  FFieldsAvailable := False;
  FExePath := ExtractFilePath(ParamStr(0));
  FIniPath := TPath.Combine(FExePath, 'ShopeeAPIData\');

  // Cria o diretório se não existir
  if not DirectoryExists(FIniPath) then begin
    ForceDirectories(FIniPath);
  end;

  if not FileExists(FIniPath + 'api_config.ini') then
  begin
    initial_configs := TStringList.Create;
    try
      initial_configs.Add('[SHOPEE]');
      initial_configs.Add('authorization_granted=0');
      initial_configs.Add('code=');
      initial_configs.Add('auth_id=');
      initial_configs.Add('auth_type=');
      initial_configs.Add('refresh_token=');
      initial_configs.SaveToFile(FIniPath + 'api_config.ini');
    finally
      initial_configs.Free;
    end;
  end;
  
  FIniFile := TMemIniFile.Create(FIniPath + 'api_config.ini');

  FCode := FIniFile.ReadString('SHOPEE', 'code', '');
  FEntityID := FIniFile.ReadString('SHOPEE', 'auth_id', '');
  FAuthType := FIniFIle.ReadString('SHOPEE', 'auth_type', '');
  FAuthorizationGranted := FIniFile.ReadBool('SHOPEE', 'authorization_granted', False);
  FAuthorizationDate := FIniFile.ReadDateTime('SHOPEE', 'authorization_date', UnixToDateTime(0));
  FRefreshToken := FIniFile.ReadString('SHOPEE', 'refresh_token', '');

  FFieldsAvailable := True;
end;

destructor TConfiguratorFile.Destroy;
begin
  if Assigned(FIniFile) then
    FIniFile.Free;

  inherited Destroy;
end;

function TConfiguratorFile.GetAuthType: string;
begin
  if FFieldsAvailable then
    Result := FAuthType
  else
    raise Exception.Create('Fields not yet available.');
end;

function TConfiguratorFile.GetCode: string;
begin
  if FFieldsAvailable then
    Result := FCode
  else
    raise Exception.Create('Fields not yet available.');
end;

function TConfiguratorFile.GetEntityID: string;
begin
  if FFieldsAvailable then
    Result := FEntityID
  else
    raise Exception.Create('Fields not yet available.');
end;

procedure TConfiguratorFile.SaveAuthorizationInfo(ACode, AAuthID,
  AAuthType: string);
begin
  FIniFile.WriteBool('SHOPEE','authorization_granted', True);
  FIniFile.WriteString('SHOPEE', 'code', ACode);
  FIniFile.WriteString('SHOPEE', 'auth_id', AAuthID);
  FIniFile.WriteString('SHOPEE', 'auth_type', AAuthType);
  FIniFile.WriteDateTime('SHOPEE', 'authorization_date', Now);

  FCode := FIniFile.ReadString('SHOPEE', 'code', '');
  FEntityID := FIniFile.ReadString('SHOPEE', 'auth_id', '');
  FAuthType := FIniFIle.ReadString('SHOPEE', 'auth_type', '');
  FAuthorizationGranted := FIniFile.ReadBool('SHOPEE', 'authorization_granted', False);
  FAuthorizationDate := FIniFile.ReadDateTime('SHOPEE', 'authorization_date', UnixToDateTime(0));

  FIniFile.UpdateFile;
end;

end.
