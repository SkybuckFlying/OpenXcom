unit OpenXcom.Engine.Impl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SDL2, SDL2_mixer, OpenXcom.Engine, OpenXcom.Interface, OpenXcom.Savegame, OpenXcom.Mod;

type
  { TGame implementation }
  TGameImpl = class(TGame)
  private
    FScreen: TScreen;
    FMod: TMod;
    FSavedGame: TSaveGame;
    FStateStack: TList;
    FMusicVolume, FSoundVolume, FUiVolume: Integer;
    procedure SetVolume(AVolume: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure PushState(AState: TState);
    procedure PopState;
    procedure SetState(AState: TState);
    procedure Quit;
    procedure LoadMods;
    procedure LoadLanguages;
    procedure InitAudio;
    function GetScreen: TScreen;
    function GetMod: TMod;
    function GetSavedGame: TSaveGame;
    procedure SetSavedGame(ASave: TSaveGame);
    function GetCursor: TCursor;
    function GetFpsCounter: TFpsCounter;
    procedure SetVolume(Sound, Music, UI: Integer);
  end;

  { TScreen }
  TScreen = class
  private
    FSurface: PSDL_Surface;
    FPalette: TSDL_ColorArray;
    FWidth, FHeight: Integer;
  public
    constructor Create(AWidth, AHeight: Integer);
    destructor Destroy; override;
    procedure ResetDisplay(AReset: Boolean);
    procedure Flip;
    procedure Clear;
    procedure SetPalette(const APalette: TSDL_ColorArray; Offset, Count: Integer; Async: Boolean);
    function GetSurface: PSDL_Surface;
    function GetPalette: TSDL_ColorArray;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
  end;

  { TOptions implementation }
  TOptionsImpl = class(TOptions)
  private
    class var FInstance: TOptionsImpl;
    class var FOptions: record
      KeepAspectRatio: Boolean;
      BaseXResolution, BaseYResolution: Integer;
      BaseXGeoscape, BaseYGeoscape: Integer;
      BaseXBattlescape, BaseYBattlescape: Integer;
      GeoscapeScale, BattlescapeScale: Integer;
      MusicVolume, SoundVolume, UiVolume: Integer;
      PreferredMusic, PreferredSound, PreferredVideo: Integer;
      CurrentSound: Integer;
      Mute, BackgroundMute: Boolean;
      Reload: Boolean;
      CaptureMouse: Integer;
      DisplayWidth, DisplayHeight: Integer;
      NewDisplayWidth, NewDisplayHeight: Integer;
      NewFullscreen, NewBorderless, NewAllowResize: Boolean;
      NewOpenGL, NewScaleFilter, NewHQXFilter, NewXBRZFilter: Boolean;
      NewOpenGLShader: string;
      NewGeoscapeScale, NewBattlescapeScale: Integer;
      NewRootWindowedMode: Boolean;
      NewWindowedModePositionX, NewWindowedModePositionY: Integer;
      Language: string;
      Mods: TArray<TModPair>;
      SaveOrder: TSaveSort;
      BattleEdgeScroll, BattleDragScrollButton: Integer;
      BattleScrollSpeed, BattleFireSpeed: Integer;
      BattleXcomSpeed, BattleAlienSpeed: Integer;
      BattleNewPreviewPath: Integer;
      BattleTooltips, BattleNotifyDeath: Boolean;
      GlobeDetail, GlobeRadarLines, GlobeFlightPaths: Boolean;
      ShowFundsOnGeoscape: Boolean;
      GeoDragScrollButton: Integer;
      GeoScrollSpeed, DogfightSpeed, GeoClockSpeed: Integer;
      KeyOk, KeyCancel, KeyGeoOptions, KeyBattleOptions: Integer;
      PlayIntro: Boolean;
    end;
    class function GetInstance: TOptionsImpl; static;
  public
    class procedure BackupDisplay; override;
    class procedure SwitchDisplay; override;
    class procedure Save(AForce: Boolean = False); override;
    class procedure Load; override;
    class procedure ResetDefault(AForce: Boolean = False); override;
    class procedure UpdateMods; override;
    class function GetModInfo(const Id: string): TModInfo; override;
    class function GetModInfos: TDictionary<string, TModInfo>; override;
    class procedure RefreshMods; override;
    class function GetActiveMaster: string; override;
    class function GetMasterUserFolder: string; override;
    class function GetUserFolder: string; override;
    class function GetConfigFolder: string; override;
    class function GetDataFolder: string; override;
    class procedure MapResources; override;
  end;

implementation

{ TGameImpl }
constructor TGameImpl.Create;
begin
  inherited;
  FStateStack := TList.Create;
  FScreen := TScreen.Create(Options.DisplayWidth, Options.DisplayHeight);
  FMod := TMod.Create;
  FSavedGame := nil;
end;

destructor TGameImpl.Destroy;
begin
  FStateStack.Free;
  FScreen.Free;
  FMod.Free;
  FSavedGame.Free;
  inherited;
end;

procedure TGameImpl.PushState(AState: TState);
begin
  FStateStack.Add(AState);
  AState.Init;
end;

procedure TGameImpl.PopState;
var
  S: TState;
begin
  if FStateStack.Count > 0 then
  begin
    S := TState(FStateStack.Last);
    FStateStack.Delete(FStateStack.Count-1);
    S.Free;
    if FStateStack.Count > 0 then
      TState(FStateStack.Last).Init;
  end;
end;

procedure TGameImpl.SetState(AState: TState);
begin
  while FStateStack.Count > 0 do
  begin
    TState(FStateStack.Last).Free;
    FStateStack.Delete(FStateStack.Count-1);
  end;
  PushState(AState);
end;

procedure TGameImpl.Quit;
begin
  // signal quit
end;

procedure TGameImpl.LoadMods;
begin
  FMod.LoadAll;
end;

procedure TGameImpl.LoadLanguages;
begin
  // load language files
end;

procedure TGameImpl.InitAudio;
begin
  // init SDL_mixer
end;

function TGameImpl.GetScreen: TScreen;
begin
  Result := FScreen;
end;

function TGameImpl.GetMod: TMod;
begin
  Result := FMod;
end;

function TGameImpl.GetSavedGame: TSaveGame;
begin
  Result := FSavedGame;
end;

procedure TGameImpl.SetSavedGame(ASave: TSaveGame);
begin
  FSavedGame := ASave;
end;

function TGameImpl.GetCursor: TCursor;
begin
  Result := nil;
end;

function TGameImpl.GetFpsCounter: TFpsCounter;
begin
  Result := nil;
end;

procedure TGameImpl.SetVolume(Sound, Music, UI: Integer);
begin
  FMusicVolume := Music;
  FSoundVolume := Sound;
  FUiVolume := UI;
  Mix_VolumeMusic(Music);
  Mix_Volume(-1, Sound);
  // UI volume separate
end;

{ TScreen }
constructor TScreen.Create(AWidth, AHeight: Integer);
begin
  FWidth := AWidth;
  FHeight := AHeight;
  FSurface := SDL_CreateRGBSurface(0, AWidth, AHeight, 32, 0,0,0,0);
end;

destructor TScreen.Destroy;
begin
  SDL_FreeSurface(FSurface);
  inherited;
end;

procedure TScreen.ResetDisplay(AReset: Boolean);
begin
  // resize etc.
end;

procedure TScreen.Flip;
begin
  // SDL_Flip
end;

procedure TScreen.Clear;
begin
  SDL_FillRect(FSurface, nil, 0);
end;

procedure TScreen.SetPalette(const APalette: TSDL_ColorArray; Offset, Count: Integer; Async: Boolean);
begin
  FPalette := APalette;
  SDL_SetPalette(FSurface, SDL_LOGPAL, PSDL_Color(@APalette[Offset]), Offset, Count);
end;

function TScreen.GetSurface: PSDL_Surface;
begin
  Result := FSurface;
end;

function TScreen.GetPalette: TSDL_ColorArray;
begin
  Result := FPalette;
end;

{ TOptionsImpl }
class function TOptionsImpl.GetInstance: TOptionsImpl;
begin
  if FInstance = nil then FInstance := TOptionsImpl.Create;
  Result := FInstance;
end;

class procedure TOptionsImpl.BackupDisplay;
begin
  // store current display settings
end;

class procedure TOptionsImpl.SwitchDisplay;
begin
  // swap new/old
end;

class procedure TOptionsImpl.Save(AForce: Boolean = False);
begin
  // write to config file
end;

class procedure TOptionsImpl.Load;
begin
  // read from config
end;

class procedure TOptionsImpl.ResetDefault(AForce: Boolean = False);
begin
  // reset all to defaults
end;

class procedure TOptionsImpl.UpdateMods;
begin
  // refresh mod list
end;

class function TOptionsImpl.GetModInfo(const Id: string): TModInfo;
begin
  Result := nil;
end;

class function TOptionsImpl.GetModInfos: TDictionary<string, TModInfo>;
begin
  Result := nil;
end;

class procedure TOptionsImpl.RefreshMods;
begin
  // scan folders
end;

class function TOptionsImpl.GetActiveMaster: string;
begin
  Result := '';
end;

class function TOptionsImpl.GetMasterUserFolder: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + 'user' + PathDelim;
end;

class function TOptionsImpl.GetUserFolder: string;
begin
  Result := GetMasterUserFolder;
end;

class function TOptionsImpl.GetConfigFolder: string;
begin
  Result := GetMasterUserFolder + 'config' + PathDelim;
end;

class function TOptionsImpl.GetDataFolder: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + 'data' + PathDelim;
end;

class procedure TOptionsImpl.MapResources;
begin
  // build file map
end;

end.