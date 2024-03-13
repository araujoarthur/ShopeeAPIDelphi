{
  This unit provides an abstract implementation for a server that will be
  realized in Shopee.API.Catcher, to gather the data from the outcome of the
  authorization proccess.
}
unit Core.Server;

interface
uses
  System.SysUtils, System.Classes,
  IdHTTPServer, IdContext, IdCustomHTTPServer, DateUtils;
type
 TServer = class
  private
    FServer: TIdHTTPServer;
    FServerLog: TStringList;
  protected
    property Server: TIdHTTPServer read FServer;
    procedure ServerLogAdd(ALogString: string);
    function ServerLog: TStringList;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Listen(const APort: Word);
    procedure Stop;
    procedure Callback(Session: TIdContext; Req: TIdHTTPRequestInfo; Res: TIdHTTPResponseInfo); virtual;
  end;

implementation

{ TServer }

function TServer.ServerLog: TStringList;
begin

  Result := Nil;
  if Assigned(FServerLog) then
  begin
    Result := FServerLog;
  end;

end;

procedure TServer.ServerLogAdd(ALogString: string);
begin
  FServerLog.Add('['+IntToStr(DateTimeToUnix(Now))+'] - ' + ALogString);
end;

procedure TServer.Callback(Session: TIdContext; Req: TIdHTTPRequestInfo;
  Res: TIdHTTPResponseInfo);
var
  LogString: string;
begin
  LogString := Req.Command + ' | ' + Req.UnparsedParams;
  ServerLogAdd(LogString);
  //ConsoleMemo.Lines.Add(Req.Params.Values['code']);
  //Res.ResponseNo := 200;
  //Res.ContentText := '{"message":"hello world"}';
end;

constructor TServer.Create;
begin
  FServer := TIdHTTPServer.Create(nil);
  FServerLog := TStringList.Create;
  FServer.ParseParams := True;
  FServer.DefaultPort := 7070;
end;

destructor TServer.Destroy;
begin
  if Assigned(FServerLog) then
    FServerLog.Free;

  if Assigned(FServer) then
    FServer.Free;

  inherited;
end;

procedure TServer.Listen(const APort: Word);
begin
  FServer.DefaultPort := APort;
  FServer.OnCommandGet := Callback;  // Event definer
  FServer.Active := True;
  ServerLogAdd(Format('Server is listening on port: %d', [APort]));
end;

procedure TServer.Stop;
begin
  FServer.Active := False;
  if FServer.Active then
  begin
    ServerLogAdd('Server not stopped!');
  end else
  begin
    ServerLogAdd('Server stopped!');
  end;
end;

end.
