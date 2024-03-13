{
  This unit is responsible for handling the Authorization within Shopee OAuth
  context. Its only class inherits from TRequestHandler, which lives in the
  Shopee.API.RequestHandler unit.

  This class is used by the context manager (FUTURE IMPLEMENTATION) to
  request a new code to fullfill a request from context handler
  (FUTURE IMPLEMENTATION) or for itself for a new authorization grant.

  * The context manager is responsible for checking the existence (through Configurator)
  of an authorization code and to get the token and keep it live while the application is running
  (in a way the token is refreshed automatically when needed).
}
unit Shopee.API.OAuth.Authorization;

interface

uses
  ShellApi, Windows, System.Classes, System.SysUtils,
  System.DateUtils,
  Shopee.API.RequestHandler,
  Shopee.API.Catcher,
  Shopee.Interfaces.DataHolder,
  Core.GlobalEvents,
  Core.Utils;

type

  TShopeeAuthorizator = class(TRequestCapable)
    private

      FAPIKey, FPartnerID: string;
      FTimestamp: string;
      FSignature: string;
      FPort: Integer;

      FRequestParameters: TRequestParams;

      FCatcherServer: TCatcherServer;

      FDataHolder: IDataHolder;

      FSuccess: Boolean;
      procedure FieldsReadyHandler(Sender: TObject; Code, AuthorizatedID: string);
    public
      constructor Create(AHolder: IDataHolder; AHost, APIKey, APartnerID: string; APort: Integer); reintroduce;
      procedure AuthorizationRequest;

      property APIKey: string read FAPIKey;
      property Signature: string read FSignature;
  end;

implementation

procedure TShopeeAuthorizator.AuthorizationRequest;
begin
  // Obtem a assinatura da chamada
  FSignature := GetPublicSignString(API_PATH_AUTHORIZATION, FTimestamp);

  // Constroi os parametros
  FRequestParameters.AddItem('partner_id', FPartnerID);
  FRequestParameters.AddItem('timestamp', FTimeStamp);
  FRequestParameters.AddItem('sign', FSignature);
  FRequestParameters.AddItem('redirect', REDIRECT_URL_WS+':'+IntToStr(FPort));

  ShellExecute(0, 'open', PChar(GenerateRequestURL(API_PATH_AUTHORIZATION, FRequestParameters)), nil, nil, SW_SHOWNORMAL);

  FCatcherServer := TCatcherServer.Create();
  FCatcherServer.OnFieldsReady := FieldsReadyHandler;
  FCatcherServer.Listen(FPort);
end;

constructor TShopeeAuthorizator.Create(AHolder: IDataHolder; AHost, APIKey, APartnerID: string; APort: Integer);
begin
  inherited Create(AHost, APIKey, APartnerID);
  FDataHolder := AHolder;
  FSuccess := False;
  FAPIKey := APIKey;
  FPartnerID := APartnerID;
  FPort := APort;
end;

procedure TShopeeAuthorizator.FieldsReadyHandler(Sender: TObject; Code,
  AuthorizatedID: string);
begin
  // Handle Code, Auth Type and AuthorizatedID.
  FDataHolder.Code := Code;
  FDataHolder.EntityID := AuthorizatedID;
  FDataHolder.AuthType := (Sender as TCatcherServer).AuthorizationType;
  FDataHolder.AuthorizationDate := TTimeZone.Local.ToUniversalTime(Now);
  FSuccess := True;

  // Uses the event to notify completion.
  AuthorizationDone.SetEvent;

  TThread.Queue(nil, procedure
  begin
    Sender.Free;
  end);
end;

end.
