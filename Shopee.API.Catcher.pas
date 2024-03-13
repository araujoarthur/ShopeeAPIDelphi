{
  This unit holds a concrete implementation of TServer, which lives in Core.Server,
  to listen for and catch the result of the autorization proccess.
}
unit Shopee.API.Catcher;

interface

uses
  IdHTTPServer, IdContext, IdCustomHTTPServer, DateUtils,
  Core.Server;

type

  TAuthorizationType = (atNone, atShopAuthorization, atMainAccountAuthorization);

  TFieldsReadyEvent = procedure(Sender: TObject; Code, AuthorizatedID: string) of object;
  TCatcherServer = class(TServer)
  private
    FOnFieldsReady: TFieldsReadyEvent;
    FCode: string;
    FAuthoID: string;
    FAuthorizationType: TAuthorizationType;
    function GetAuthorizationType: string;
    function GetCode: string;
    function GetEntityID: string;
  public
    property OnFieldsReady: TFieldsReadyEvent read FOnFieldsReady write FOnFieldsReady;
    property Code: string read GetCode;
    property EntityID: string read GetEntityID;
    property AuthorizationType: string read GetAuthorizationType;
    procedure Callback(Session: TIdContext; Req: TIdHTTPRequestInfo; Res: TIdHTTPResponseInfo); override;
  end;

implementation

{ TCatcherServer }

procedure TCatcherServer.Callback(Session: TIdContext;
  Req: TIdHTTPRequestInfo; Res: TIdHTTPResponseInfo);
begin
  inherited Callback(Session, Req, Res);
  if (Req.Params.Values['code'] <> '') and ((Req.Params.Values['shop_id'] <> '') or (Req.Params.Values['main_account_id'] <> '')) then
  begin
    Res.ResponseNo := 200;
    Res.ResponseText := '{"message":"continue on the application"}';
    FCode := Req.Params.Values['code'];
    if (Req.Params.Values['shop_id'] <> '') then
    begin
      FAuthorizationType := atShopAuthorization;
      FAuthoID := Req.Params.Values['shop_id'];
    end else
    begin
      FAuthorizationType := atMainAccountAuthorization;
      FAuthoID := Req.Params.Values['main_account_id'];
    end;

    FOnFieldsReady(Self, FCode, FAuthoID);
  end else
  begin
    Res.ResponseNo := 400;
    Res.ResponseText := '{"message":"Something went wrong."}';
  end;
end;

function TCatcherServer.GetAuthorizationType: string;
begin
  case FAuthorizationType of
    atNone:  Result := 'None';
    atShopAuthorization: Result := 'Shop';
    atMainAccountAuthorization: Result := 'Main';
  end;
end;

function TCatcherServer.GetCode: string;
begin

end;

function TCatcherServer.GetEntityID: string;
begin

end;

end.
