unit OpenXcom.Engine;

interface

type
  TGame = class
  end;

  TAction = class
  end;

  TSDLColor = record end;
  TSDLColorArray = array[0..255] of TSDLColor;

  TSaveSort = (sortNameAsc, sortNameDesc, sortDateAsc, sortDateDesc);
  TSaveType = (stDefault, stQuick, stAutoGeoscape, stAutoBattlescape, stIronman, stIronmanEnd);
  TLoadingPhase = (lpStarted, lpFailed, lpSuccessful, lpDone);

  TSaveInfo = record
    FileName, DisplayName, IsoDate, IsoTime, Details: string;
    Reserved: Boolean;
    Mods: TArray<string>;
  end;
  TSaveInfoList = TArray<TSaveInfo>;

  TSaveOriginal = record
    Id: Integer;
    Name, Time, Date: string;
    Tactical: Boolean;
  end;

  TModInfo = class
    function IsMaster: Boolean; virtual;
    function IsEngineOk: Boolean; virtual;
    function CanActivate(const MasterId: string): Boolean; virtual;
    function GetId: string; virtual;
    function GetName: string; virtual;
    function GetVersion: string; virtual;
    function GetAuthor: string; virtual;
    function GetDescription: string; virtual;
    function GetRequiredExtendedEngine: string; virtual;
  end;

  TModPair = record
    Id: string;
    Enabled: Boolean;
  end;

  TOptionInfo = class
    function Type_: Integer; virtual;
    function Description: string; virtual;
    function Category: string; virtual;
    function AsBool: PBoolean; virtual;
    function AsInt: PInteger; virtual;
    function AsKey: PSDLKey; virtual;
  end;
  TOptionInfoList = TArray<TOptionInfo>;

  TOptions = class
  strict private
    class var FInstance: TOptions;
  public
    class procedure BackupDisplay; static;
    class procedure SwitchDisplay; static;
    class procedure Save(AForce: Boolean = False); static;
    class procedure Load; static;
    class procedure ResetDefault(AForce: Boolean = False); static;
    class procedure UpdateMods; static;
    class function GetModInfo(const Id: string): TModInfo; static;
    class function GetModInfos: TDictionary<string, TModInfo>; static;
    class procedure RefreshMods; static;
    class function GetActiveMaster: string; static;
    class function GetMasterUserFolder: string; static;
    class function GetUserFolder: string; static;
    class function GetConfigFolder: string; static;
    class function GetDataFolder: string; static;
    class procedure MapResources; static;
    class property KeepAspectRatio: Boolean read FKeepAspectRatio write FKeepAspectRatio;
    class property BaseXResolution: Integer read FBaseXResolution write FBaseXResolution;
    class property BaseYResolution: Integer read FBaseYResolution write FBaseYResolution;
    class property BaseXGeoscape: Integer read FBaseXGeoscape write FBaseXGeoscape;
    class property BaseYGeoscape: Integer read FBaseYGeoscape write FBaseYGeoscape;
    class property BaseXBattlescape: Integer read FBaseXBattlescape write FBaseXBattlescape;
    class property BaseYBattlescape: Integer read FBaseYBattlescape write FBaseYBattlescape;
    class property GeoscapeScale: Integer read FGeoscapeScale write FGeoscapeScale;
    class property BattlescapeScale: Integer read FBattlescapeScale write FBattlescapeScale;
    class property MusicVolume: Integer read FMusicVolume write FMusicVolume;
    class property SoundVolume: Integer read FSoundVolume write FSoundVolume;
    class property UiVolume: Integer read FUiVolume write FUiVolume;
    class property PreferredMusic: Integer read FPreferredMusic write FPreferredMusic;
    class property PreferredSound: Integer read FPreferredSound write FPreferredSound;
    class property PreferredVideo: Integer read FPreferredVideo write FPreferredVideo;
    class property CurrentSound: Integer read FCurrentSound write FCurrentSound;
    class property Mute: Boolean read FMute write FMute;
    class property BackgroundMute: Boolean read FBackgroundMute write FBackgroundMute;
    class property Reload: Boolean read FReload write FReload;
    class property CaptureMouse: Integer read FCaptureMouse write FCaptureMouse;
    class property DisplayWidth: Integer read FDisplayWidth write FDisplayWidth;
    class property DisplayHeight: Integer read FDisplayHeight write FDisplayHeight;
    class property NewDisplayWidth: Integer read FNewDisplayWidth write FNewDisplayWidth;
    class property NewDisplayHeight: Integer read FNewDisplayHeight write FNewDisplayHeight;
    class property NewFullscreen: Boolean read FNewFullscreen write FNewFullscreen;
    class property NewBorderless: Boolean read FNewBorderless write FNewBorderless;
    class property NewAllowResize: Boolean read FNewAllowResize write FNewAllowResize;
    class property NewOpenGL: Boolean read FNewOpenGL write FNewOpenGL;
    class property NewScaleFilter: Boolean read FNewScaleFilter write FNewScaleFilter;
    class property NewHQXFilter: Boolean read FNewHQXFilter write FNewHQXFilter;
    class property NewXBRZFilter: Boolean read FNewXBRZFilter write FNewXBRZFilter;
    class property NewOpenGLShader: string read FNewOpenGLShader write FNewOpenGLShader;
    class property NewGeoscapeScale: Integer read FNewGeoscapeScale write FNewGeoscapeScale;
    class property NewBattlescapeScale: Integer read FNewBattlescapeScale write FNewBattlescapeScale;
    class property NewRootWindowedMode: Boolean read FNewRootWindowedMode write FNewRootWindowedMode;
    class property NewWindowedModePositionX: Integer read FNewWindowedModePositionX write FNewWindowedModePositionX;
    class property NewWindowedModePositionY: Integer read FNewWindowedModePositionY write FNewWindowedModePositionY;
    class property Language: string read FLanguage write FLanguage;
    class property Mods: TArray<TModPair> read FMods write FMods;
    class property SaveOrder: TSaveSort read FSaveOrder write FSaveOrder;
    class property BattleEdgeScroll: Integer read FBattleEdgeScroll write FBattleEdgeScroll;
    class property BattleDragScrollButton: Integer read FBattleDragScrollButton write FBattleDragScrollButton;
    class property BattleScrollSpeed: Integer read FBattleScrollSpeed write FBattleScrollSpeed;
    class property BattleFireSpeed: Integer read FBattleFireSpeed write FBattleFireSpeed;
    class property BattleXcomSpeed: Integer read FBattleXcomSpeed write FBattleXcomSpeed;
    class property BattleAlienSpeed: Integer read FBattleAlienSpeed write FBattleAlienSpeed;
    class property BattleNewPreviewPath: Integer read FBattleNewPreviewPath write FBattleNewPreviewPath;
    class property BattleTooltips: Boolean read FBattleTooltips write FBattleTooltips;
    class property BattleNotifyDeath: Boolean read FBattleNotifyDeath write FBattleNotifyDeath;
    class property GlobeDetail: Boolean read FGlobeDetail write FGlobeDetail;
    class property GlobeRadarLines: Boolean read FGlobeRadarLines write FGlobeRadarLines;
    class property GlobeFlightPaths: Boolean read FGlobeFlightPaths write FGlobeFlightPaths;
    class property ShowFundsOnGeoscape: Boolean read FShowFundsOnGeoscape write FShowFundsOnGeoscape;
    class property GeoDragScrollButton: Integer read FGeoDragScrollButton write FGeoDragScrollButton;
    class property GeoScrollSpeed: Integer read FGeoScrollSpeed write FGeoScrollSpeed;
    class property DogfightSpeed: Integer read FDogfightSpeed write FDogfightSpeed;
    class property GeoClockSpeed: Integer read FGeoClockSpeed write FGeoClockSpeed;
    class property KeyOk: Integer read FKeyOk write FKeyOk;
    class property KeyCancel: Integer read FKeyCancel write FKeyCancel;
    class property KeyGeoOptions: Integer read FKeyGeoOptions write FKeyGeoOptions;
    class property KeyBattleOptions: Integer read FKeyBattleOptions write FKeyBattleOptions;
    class property PlayIntro: Boolean read FPlayIntro write FPlayIntro;
  end;

  TSDL_Rect = record end;
  TSDL_RectArray = TArray<TSDL_Rect>;

  TSDLKey = type Integer;

implementation

end.