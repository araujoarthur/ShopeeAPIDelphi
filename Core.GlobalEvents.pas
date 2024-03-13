unit Core.GlobalEvents;

interface
uses
  SyncObjs;

var
  AuthorizationDone: TEvent;

implementation

initialization
// Initialization runs when windows loads the module.
  AuthorizationDone := TEvent.Create(nil, True, False, '');

finalization
// Finalization runs when windows unloads the module.
  AuthorizationDone.Free;

end.
