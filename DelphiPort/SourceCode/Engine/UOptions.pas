unit UOptions;

interface

uses
  SysUtils, Classes, SDL, UOptionInfo, UModInfo;

type
  TOptions = class
  public
    // General
    class var displayWidth, displayHeight, maxFrameSkip: Integer;
    class var baseXResolution, baseYResolution: Integer;
    class var baseXGeoscape, baseYGeoscape: Integer;
    class var baseXBattlescape, baseYBattlescape: Integer;
    class var soundVolume, musicVolume, uiVolume: Integer;
    class var audioSampleRate, audioBitDepth, audioChunkSize: Integer;
    class var pauseMode: Integer;
    class var windowedModePositionX, windowedModePositionY: Integer;
    class var FPS, FPSInactive: Integer;
    class var changeValueByMouseWheel: Integer;
    class var dragScrollTimeTolerance, dragScrollPixelTolerance: Integer;
    class var mousewheelSpeed: Integer;
    class var autosaveFrequency: Integer;
    class var fullscreen, asyncBlit, playIntro: Boolean;
    class var useScaleFilter, useHQXFilter, useXBRZFilter: Boolean;
    class var useOpenGL, checkOpenGLErrors, vSyncForOpenGL: Boolean;
    class var useOpenGLSmoothing: Boolean;
    class var autosave, allowResize, borderless: Boolean;
    class var debug, debugUi, fpsCounter: Boolean;
    class var newSeedOnLoad: Boolean;
    class var keepAspectRatio, nonSquarePixelRatio: Boolean;
    class var cursorInBlackBandsInFullscreen, cursorInBlackBandsInWindow: Boolean;
    class var cursorInBlackBandsInBorderlessWindow: Boolean;
    class var maximizeInfoScreens: Boolean;
    class var musicAlwaysLoop, StereoSound: Boolean;
    class var verboseLogging: Boolean;
    class var soldierDiaries: Boolean;
    class var touchEnabled, rootWindowedMode: Boolean;
    class var lazyLoadResources, backgroundMute: Boolean;
    class var language, useOpenGLShader: string;
    class var keyboardMode: TKeyboardType;
    class var saveOrder: TSaveSort;
    class var preferredMusic: TMusicFormat;
    class var preferredSound: TSoundFormat;
    class var preferredVideo: TVideoFormat;
    class var captureMouse: SDL_GrabMode;
    class var wordwrap: TTextWrapping;
    class var keyOk, keyCancel, keyScreenshot, keyFps, keyQuickLoad, keyQuickSave: TSDL_Key;
    // Geoscape
    class var geoClockSpeed, dogfightSpeed, geoScrollSpeed: Integer;
    class var geoDragScrollButton: Integer;
    class var geoscapeScale: Integer;
    class var includePrimeStateInSavedLayout: Boolean;
    class var anytimePsiTraining, weaponSelfDestruction: Boolean;
    class var retainCorpses, craftLaunchAlways: Boolean;
    class var globeSurfaceCache, globeSeasons, globeDetail: Boolean;
    class var globeRadarLines, globeFlightPaths: Boolean;
    class var globeAllRadarsOnBaseBuild: Boolean;
    class var storageLimitsEnforced, canSellLiveAliens: Boolean;
    class var canTransferCraftsWhileAirborne: Boolean;
    class var customInitialBase, aggressiveRetaliation: Boolean;
    class var geoDragScrollInvert: Boolean;
    class var allowBuildingQueue, showFundsOnGeoscape: Boolean;
    class var psiStrengthEval, allowPsiStrengthImprovement: Boolean;
    class var fieldPromotions, meetingPoint: Boolean;
    class var keyGeoLeft, keyGeoRight, keyGeoUp, keyGeoDown: TSDL_Key;
    class var keyGeoZoomIn, keyGeoZoomOut: TSDL_Key;
    class var keyGeoSpeed1, keyGeoSpeed2, keyGeoSpeed3, keyGeoSpeed4, keyGeoSpeed5, keyGeoSpeed6: TSDL_Key;
    class var keyGeoIntercept, keyGeoBases, keyGeoGraphs, keyGeoUfopedia, keyGeoOptions, keyGeoFunding: TSDL_Key;
    class var keyGeoToggleDetail, keyGeoToggleRadar: TSDL_Key;
    class var keyBaseSelect1..keyBaseSelect8: TSDL_Key;
    // Battlescape
    class var battleEdgeScroll: TScrollType;
    class var battleNewPreviewPath: TPathPreview;
    class var battleScrollSpeed, battleDragScrollButton: Integer;
    class var battleFireSpeed, battleXcomSpeed, battleAlienSpeed: Integer;
    class var battleExplosionHeight, battlescapeScale: Integer;
    class var traceAI, sneakyAI, battleInstantGrenade: Boolean;
    class var battleNotifyDeath, battleTooltips: Boolean;
    class var battleHairBleach, battleAutoEnd: Boolean;
    class var strafe, forceFire, showMoreStatsInInventoryView: Boolean;
    class var allowPsionicCapture, skipNextTurnScreen: Boolean;
    class var disableAutoEquip, battleDragScrollInvert: Boolean;
    class var battleUFOExtenderAccuracy, battleConfirmFireMode: Boolean;
    class var battleSmoothCamera, noAlienPanicMessages: Boolean;
    class var alienBleeding: Boolean;
    class var keyBattleLeft..keyBattleRight, keyBattleUp, keyBattleDown, keyBattleLevelUp, keyBattleLevelDown: TSDL_Key;
    class var keyBattleCenterUnit, keyBattlePrevUnit, keyBattleNextUnit: TSDL_Key;
    class var keyBattleDeselectUnit, keyBattleUseLeftHand, keyBattleUseRightHand: TSDL_Key;
    class var keyBattleInventory, keyBattleMap, keyBattleOptions, keyBattleEndTurn: TSDL_Key;
    class var keyBattleAbort, keyBattleStats, keyBattleKneel, keyBattleReload: TSDL_Key;
    class var keyBattlePersonalLighting, keyBattleReserveNone, keyBattleReserveSnap, keyBattleReserveAimed: TSDL_Key;
    class var keyBattleReserveAuto, keyBattleReserveKneel, keyBattleZeroTUs: TSDL_Key;
    class var keyBattleCenterEnemy1..keyBattleCenterEnemy10: TSDL_Key;
    class var keyBattleVoxelView, keyInvCreateTemplate, keyInvApplyTemplate, keyInvClear, keyInvAutoEquip: TSDL_Key;

    // Flags
    class var mute, reload, newOpenGL, newScaleFilter, newHQXFilter, newXBRZFilter: Boolean;
    class var newRootWindowedMode, newFullscreen, newAllowResize, newBorderless: Boolean;
    class var newDisplayWidth, newDisplayHeight, newBattlescapeScale, newGeoscapeScale: Integer;
    class var newWindowedModePositionX, newWindowedModePositionY: Integer;
    class var newOpenGLShader: string;
    class var mods: TArray<TPair<string, Boolean>>;
    class var currentSound: TSoundFormat;

    class procedure Create;
    class procedure ResetDefault(IncludeMods: Boolean);
    class function LoadArgs(Argc: Integer; Argv: array of string): Boolean;
    class procedure SetFolders;
    class procedure UpdateOptions;
    class procedure BackupDisplay;
    class procedure SwitchDisplay;
    class function GetActiveMaster: string;
    class procedure MapResources;
    class procedure RefreshMods;
    class procedure UpdateMods;
    class function GetActiveMods: TArray<TModInfo>;
    class function GetModInfo(const ID: string): TModInfo;
  end;

implementation

class procedure TOptions.Create;
begin
  // Initialize default values
  displayWidth := 640; displayHeight := 400; maxFrameSkip := 0;
  // ... etc
end;

class procedure TOptions.ResetDefault(IncludeMods: Boolean);
begin
  // Reset all to default
end;

class function TOptions.LoadArgs(Argc: Integer; Argv: array of string): Boolean;
begin
  Result := True;
  // Parse command line
end;

class procedure TOptions.SetFolders;
begin
  // Set data/user/config folders
end;

class procedure TOptions.UpdateOptions;
begin
  // Load from config, apply command line
end;

class procedure TOptions.BackupDisplay;
begin
  // Store current display settings
end;

class procedure TOptions.SwitchDisplay;
begin
  // Swap display settings
end;

class function TOptions.GetActiveMaster: string;
begin
  Result := 'xcom1';
end;

class procedure TOptions.MapResources;
begin
  // Map virtual resources
end;

class procedure TOptions.RefreshMods;
begin
  // Scan mods
end;

class procedure TOptions.UpdateMods;
begin
  // Refresh and map
end;

class function TOptions.GetActiveMods: TArray<TModInfo>;
begin
  SetLength(Result, 0);
end;

class function TOptions.GetModInfo(const ID: string): TModInfo;
begin
  // Return info
end;

end.