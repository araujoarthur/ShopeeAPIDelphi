unit Shopee.Interfaces.DataHolder;

interface
type
  IDataHolder = interface
  ['{563A6F08-48AE-4083-BD34-722A2461C1FA}']

    function GetCode: string;
    function GetAuthType: string;
    function GetEntityID: string;
    function GetRefreshToken: string;
    function GetAccessToken: string;
    function GetMustRenew: Boolean;
    function GetExpireTS: UInt64;
    function GetAuthorizationDate: TDateTime;

    function HasRefreshToken: Boolean;
    function HasAccessToken: Boolean;
    function HasCode: Boolean;
    function IsAuthorized: Boolean;

    procedure SetCode(AValue: string);
    procedure SetAuthType(AValue: string);
    procedure SetEntityID(AValue: string);
    procedure SetRefreshToken(AValue: string);
    procedure SetAccessToken(AValue: string);
    procedure SetExpiretTimestamp(AValue: UInt64);
    procedure SetAuthorizationDate(ADate: TDateTime);

    property Code: string read GetCode write SetCode;
    property AuthType: string read GetAuthType write SetAuthType;
    property EntityID: string read GetEntityID write SetEntityID;
    property RefreshToken: string read GetRefreshToken write SetRefreshToken;
    property AccessToken: string read GetAccessToken write SetAccessToken;
    property MustRenew: Boolean read GetMustRenew;
    property ExpireTimestamp: UInt64 read GetExpireTS write SetExpiretTimestamp;
    property AuthorizationDate: TDateTime read GetAuthorizationDate write SetAuthorizationDate;
end;

implementation

end.
