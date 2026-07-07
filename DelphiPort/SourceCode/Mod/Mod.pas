unit ModUnit;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, System.Math,
  Yaml, Engine.Options, Savegame.GameTime, UnitStats, RuleAlienMission,
  Engine.Surface, Engine.SurfaceSet, Engine.Font, Engine.Palette, Engine.Music,
  Engine.SoundSet, Engine.Sound, Engine.CatFile, Engine.GMCatFile,
  Interface.TextButton, Interface.Window, MapDataSet, RuleMusic, Engine.ShaderDraw,
  Engine.ShaderMove, Engine.Exception, Engine.Logger, SoundDefinition,
  ExtraSprites, ExtraSounds, Engine.AdlibMusic, fmath, Engine.RNG,
  Battlescape.Pathfinding, RuleCountry, RuleRegion, RuleBaseFacility,
  RuleCraft, RuleCraftWeapon, RuleItem, RuleUfo, RuleTerrain, MapScript,
  RuleSoldier, RuleCommendations, AlienRace, AlienDeployment, Armor,
  ArticleDefinition, RuleInventory, RuleResearch, RuleManufacture,
  ExtraStrings, RuleInterface, RuleMissionScript, Geoscape.Globe,
  Savegame.SavedGame, Savegame.Region, Savegame.Base, Savegame.Country,
  Savegame.Soldier, Savegame.Craft, Savegame.Vehicle, Savegame.ItemContainer,
  Savegame.Transfer, Ufopaedia.Ufopaedia, Savegame.AlienStrategy,
  UfoTrajectory, RuleAlienMission, MCDPatch, StatString, RuleGlobe,
  RuleVideo, RuleConverter;

type
  TModData = record
    Name: string;
    Info: TModInfo;
    Offset: Integer;
    Size: Integer;
  end;

  TMod = class
  private const
    ModNameMaster = 'master';
    ModNameCurrent = 'current';
    TransparceySizeReduction = 100;
  public
    class var DOOR_OPEN: Integer;
    class var SLIDING_DOOR_OPEN: Integer;
    class var SLIDING_DOOR_CLOSE: Integer;
    class var SMALL_EXPLOSION: Integer;
    class var LARGE_EXPLOSION: Integer;
    class var EXPLOSION_OFFSET: Integer;
    class var SMOKE_OFFSET: Integer;
    class var UNDERWATER_SMOKE_OFFSET: Integer;
    class var ITEM_DROP: Integer;
    class var ITEM_THROW: Integer;
    class var ITEM_RELOAD: Integer;
    class var WALK_OFFSET: Integer;
    class var FLYING_SOUND: Integer;
    class var BUTTON_PRESS: Integer;
    class var WINDOW_POPUP: array[0..2] of Integer;
    class var UFO_FIRE: Integer;
    class var UFO_HIT: Integer;
    class var UFO_CRASH: Integer;
    class var UFO_EXPLODE: Integer;
    class var INTERCEPTOR_HIT: Integer;
    class var INTERCEPTOR_EXPLODE: Integer;
    class var GEOSCAPE_CURSOR: Integer;
    class var BASESCAPE_CURSOR: Integer;
    class var BATTLESCAPE_CURSOR: Integer;
    class var UFOPAEDIA_CURSOR: Integer;
    class var GRAPHS_CURSOR: Integer;
    class var DAMAGE_RANGE: Integer;
    class var EXPLOSIVE_DAMAGE_RANGE: Integer;
    class var FIRE_DAMAGE_RANGE: array[0..1] of Integer;
    class var DEBRIEF_MUSIC_GOOD: string;
    class var DEBRIEF_MUSIC_BAD: string;
    class var DIFFICULTY_COEFFICIENT: array[0..4] of Integer;
    class procedure ResetGlobalStatics;
  private
    FMuteMusic: TMusic;
    FMuteSound: TSound;
    FPlayingMusic: string;
    FPalettes: TDictionary<string, TPalette>;
    FFonts: TDictionary<string, TFont>;
    FSurfaces: TDictionary<string, TSurface>;
    FSets: TDictionary<string, TSurfaceSet>;
    FSounds: TDictionary<string, TSoundSet>;
    FMusics: TDictionary<string, TMusic>;
    FVoxelData: TArray<Word>;
    FTransparencyLUTs: TArray<TArray<Byte>>;

    FCountries: TDictionary<string, TRuleCountry>;
    FRegions: TDictionary<string, TRuleRegion>;
    FFacilities: TDictionary<string, TRuleBaseFacility>;
    FCrafts: TDictionary<string, TRuleCraft>;
    FCraftWeapons: TDictionary<string, TRuleCraftWeapon>;
    FItems: TDictionary<string, TRuleItem>;
    FUfos: TDictionary<string, TRuleUfo>;
    FTerrains: TDictionary<string, TRuleTerrain>;
    FMapDataSets: TDictionary<string, TMapDataSet>;
    FSoldiers: TDictionary<string, TRuleSoldier>;
    FUnits: TDictionary<string, TUnit>;
    FAlienRaces: TDictionary<string, TAlienRace>;
    FAlienDeployments: TDictionary<string, TAlienDeployment>;
    FArmors: TDictionary<string, TArmor>;
    FUfopaediaArticles: TDictionary<string, TArticleDefinition>;
    FInvs: TDictionary<string, TRuleInventory>;
    FResearch: TDictionary<string, TRuleResearch>;
    FManufacture: TDictionary<string, TRuleManufacture>;
    FUfoTrajectories: TDictionary<string, TUfoTrajectory>;
    FAlienMissions: TDictionary<string, TRuleAlienMission>;
    FInterfaces: TDictionary<string, TRuleInterface>;
    FSoundDefs: TDictionary<string, TSoundDefinition>;
    FVideos: TDictionary<string, TRuleVideo>;
    FMCDPatches: TDictionary<string, TMDCPatch>;
    FMapScripts: TDictionary<string, TArray<TMapScript>>;
    FCommendations: TDictionary<string, TRuleCommendations>;
    FMissionScripts: TDictionary<string, TRuleMissionScript>;
    FExtraSprites: TDictionary<string, TArray<TExtraSprites>>;
    FExtraSounds: TArray<TPair<string, TExtraSounds>>;
    FExtraStrings: TDictionary<string, TExtraStrings>;
    FStatStrings: TArray<TStatString>;
    FMusicDefs: TDictionary<string, TRuleMusic>;
    FGlobe: TRuleGlobe;
    FConverter: TRuleConverter;
    FCostEngineer: Integer;
    FCostScientist: Integer;
    FTimePersonnel: Integer;
    FInitialFunding: Integer;
    FTurnAIUseGrenade: Integer;
    FTurnAIUseBlaster: Integer;
    FDefeatScore: Integer;
    FDefeatFunds: Integer;
    FDifficultyDemigod: Boolean;
    FAlienFuel: TPair<string, Integer>;
    FFontName: string;
    FFinalResearch: string;
    FStartingBase: TYamlNode;
    FStartingTime: TGameTime;
    FStatAdjustment: array[0..4] of TStatAdjustment;
    FUfopaediaSections: TDictionary<string, Integer>;
    FCountriesIndex: TArray<string>;
    FRegionsIndex: TArray<string>;
    FFacilitiesIndex: TArray<string>;
    FCraftsIndex: TArray<string>;
    FCraftWeaponsIndex: TArray<string>;
    FItemsIndex: TArray<string>;
    FInvsIndex: TArray<string>;
    FUfosIndex: TArray<string>;
    FSoldiersIndex: TArray<string>;
    FAliensIndex: TArray<string>;
    FDeploymentsIndex: TArray<string>;
    FArmorsIndex: TArray<string>;
    FUfopaediaIndex: TArray<string>;
    FUfopaediaCatIndex: TArray<string>;
    FResearchIndex: TArray<string>;
    FManufactureIndex: TArray<string>;
    FAlienMissionsIndex: TArray<string>;
    FTerrainIndex: TArray<string>;
    FMissionScriptIndex: TArray<string>;
    FAlienItemLevels: TArray<TArray<Integer>>;
    FTransparencies: TArray<TSDL_Color>;
    FFacilityListOrder: Integer;
    FCraftListOrder: Integer;
    FItemListOrder: Integer;
    FResearchListOrder: Integer;
    FManufactureListOrder: Integer;
    FUfopaediaListOrder: Integer;
    FInvListOrder: Integer;
    FModData: TArray<TModData>;
    FModCurrent: ^TModData;
    FStatePalette: PSDL_Color;
    FPsiRequirements: TArray<string>;

    procedure LoadResourceConfigFile(const FileName: string);
    procedure LoadConstants(const Node: TYamlNode);
    procedure LoadFile(const FileName: string);
    procedure LoadMod(const RulesetFiles: TArray<string>);
    procedure LoadVanillaResources;
    procedure LoadBattlescapeResources;
    procedure LoadExtraResources;
    procedure LazyLoadSurface(const Name: string);
    procedure LoadExtraSprite(SpritePack: TExtraSprites);
    procedure ModResources;
    procedure SortLists;
    function LoadMusic(Fmt: TMusicFormat; Rule: TRuleMusic; Adlibcat, Aintrocat: TCatFile; Gmcat: TGMCatFile): TMusic;
    procedure CreateTransparencyLUT(Pal: TPalette);
    function GetRule<T: class>(const Id, Name: string; const Map: TDictionary<string,T>; Error: Boolean): T;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadAll(const Mods: TArray<TPair<string, TArray<string>>>);
    function NewSave: TSavedGame;

    // Resource getters
    function GetFont(const Name: string; Error: Boolean = True): TFont;
    function GetSurface(const Name: string; Error: Boolean = True): TSurface;
    function GetSurfaceSet(const Name: string; Error: Boolean = True): TSurfaceSet;
    function GetMusic(const Name: string; Error: Boolean = True): TMusic;
    procedure PlayMusic(const Name: string; Id: Integer = 0);
    function GetSound(const SetName: string; Sound: Cardinal; Error: Boolean = True): TSound;
    function GetPalette(const Name: string; Error: Boolean = True): TPalette;
    procedure SetPalette(Colors: PSDL_Color; FirstColor: Integer = 0; NColors: Integer = 256);
    function GetVoxelData: TArray<Word>;
    function GetSoundByDepth(Depth: Cardinal; Sound: Cardinal; Error: Boolean = True): TSound;
    function GetLUTs: TArray<TArray<Byte>>;
    function GetModOffset: Integer;
    procedure LoadOffsetNode(const Parent: string; var Offset: Integer; const Node: TYamlNode; Shared: Integer; const SetName: string; Multiplier: Integer; SizeScale: Integer = 1);
    procedure LoadSpriteOffset(const Parent: string; var Sprite: Integer; const Node: TYamlNode; const SetName: string; Multiplier: Integer = 1);
    procedure LoadSoundOffset(const Parent: string; var Sound: Integer; const Node: TYamlNode; const SetName: string);
    procedure LoadSoundOffset(const Parent: string; var Sounds: TArray<Integer>; const Node: TYamlNode; const SetName: string);
    procedure LoadTransparencyOffset(const Parent: string; var Index: Integer; const Node: TYamlNode);
    function GetOffset(Id, MaxVal: Integer): Integer;

    // Rule getters
    function GetCountry(const Id: string; Error: Boolean = False): TRuleCountry;
    function GetRegion(const Id: string; Error: Boolean = False): TRuleRegion;
    function GetBaseFacility(const Id: string; Error: Boolean = False): TRuleBaseFacility;
    function GetCraft(const Id: string; Error: Boolean = False): TRuleCraft;
    function GetCraftWeapon(const Id: string; Error: Boolean = False): TRuleCraftWeapon;
    function GetItem(const Id: string; Error: Boolean = False): TRuleItem;
    function GetUfo(const Id: string; Error: Boolean = False): TRuleUfo;
    function GetTerrain(const Name: string; Error: Boolean = False): TRuleTerrain;
    function GetMapDataSet(const Name: string): TMapDataSet;
    function GetSoldier(const Name: string; Error: Boolean = False): TRuleSoldier;
    function GetCommendation(const Id: string; Error: Boolean = False): TRuleCommendations;
    function GetUnit(const Name: string; Error: Boolean = False): TUnit;
    function GetAlienRace(const Name: string; Error: Boolean = False): TAlienRace;
    function GetDeployment(const Name: string; Error: Boolean = False): TAlienDeployment;
    function GetArmor(const Name: string; Error: Boolean = False): TArmor;
    function GetUfopaediaArticle(const Name: string; Error: Boolean = False): TArticleDefinition;
    function GetInventory(const Id: string; Error: Boolean = False): TRuleInventory;
    function GetResearch(const Id: string; Error: Boolean = False): TRuleResearch;
    function GetManufacture(const Id: string; Error: Boolean = False): TRuleManufacture;
    function GetUfoTrajectory(const Id: string; Error: Boolean = False): TUfoTrajectory;
    function GetAlienMission(const Id: string; Error: Boolean = False): TRuleAlienMission;
    function GetRandomMission(Objective: TMissionObjective; MonthsPassed: Integer): TRuleAlienMission;
    function GetMCDPatch(const Id: string): TMDCPatch;
    function GetExtraSprites: TDictionary<string, TArray<TExtraSprites>>;
    function GetExtraSounds: TArray<TPair<string, TExtraSounds>>;
    function GetExtraStrings: TDictionary<string, TExtraStrings>;
    function GetStatStrings: TArray<TStatString>;
    function GetPsiRequirements: TArray<string>;
    function GetInterface(const Id: string; Error: Boolean = True): TRuleInterface;
    function GetGlobe: TRuleGlobe;
    function GetConverter: TRuleConverter;
    function GetSoundDefinitions: TDictionary<string, TSoundDefinition>;
    function GetTransparencies: TArray<TSDL_Color>;
    function GetMapScript(const Id: string): TArray<TMapScript>;
    function GetVideo(const Id: string; Error: Boolean = False): TRuleVideo;
    function GetMusicDefs: TDictionary<string, TRuleMusic>;
    function GetMissionScriptList: TArray<string>;
    function GetMissionScript(const Name: string; Error: Boolean = False): TRuleMissionScript;
    function GetFinalResearch: string;
    function GetStatAdjustment(Difficulty: Integer): PStatAdjustment;
    function GetDefeatScore: Integer;
    function GetDefeatFunds: Integer;
    function IsDemigod: Boolean;

    // Lists
    function GetCountriesList: TArray<string>;
    function GetRegionsList: TArray<string>;
    function GetBaseFacilitiesList: TArray<string>;
    function GetCraftsList: TArray<string>;
    function GetCraftWeaponsList: TArray<string>;
    function GetItemsList: TArray<string>;
    function GetUfosList: TArray<string>;
    function GetTerrainList: TArray<string>;
    function GetSoldiersList: TArray<string>;
    function GetCommendationsList: TDictionary<string, TRuleCommendations>;
    function GetAlienRacesList: TArray<string>;
    function GetDeploymentsList: TArray<string>;
    function GetArmorsList: TArray<string>;
    function GetUfopaediaList: TArray<string>;
    function GetUfopaediaCategoryList: TArray<string>;
    function GetInvsList: TArray<string>;
    function GetResearchList: TArray<string>;
    function GetManufactureList: TArray<string>;
    function GetAlienMissionList: TArray<string>;
    function GetAlienItemLevels: TArray<TArray<Integer>>;
    function GetStartingBase: TYamlNode;
    function GetStartingTime: TGameTime;
    function GetCustomBaseFacilities: TArray<TRuleBaseFacility>;
    function GetMinRadarRange: Integer;
    function GetEngineerCost: Integer;
    function GetScientistCost: Integer;
    function GetPersonnelTime: Integer;
    function GetAlienFuelName: string;
    function GetAlienFuelQuantity: Integer;
    function GetFontName: string;
    function GetTurnAIUseGrenade: Integer;
    function GetTurnAIUseBlaster: Integer;
    function GetInventories: TDictionary<string, TRuleInventory>;

    function GenSoldier(Save: TSavedGame; const AType: string = ''): TSoldier;
  end;

implementation

{ TMod }

class procedure TMod.ResetGlobalStatics;
begin
  DOOR_OPEN := 3;
  SLIDING_DOOR_OPEN := 20;
  SLIDING_DOOR_CLOSE := 21;
  SMALL_EXPLOSION := 2;
  LARGE_EXPLOSION := 5;
  EXPLOSION_OFFSET := 0;
  SMOKE_OFFSET := 8;
  UNDERWATER_SMOKE_OFFSET := 0;
  ITEM_DROP := 38;
  ITEM_THROW := 39;
  ITEM_RELOAD := 17;
  WALK_OFFSET := 22;
  FLYING_SOUND := 15;
  BUTTON_PRESS := 0;
  WINDOW_POPUP[0] := 1; WINDOW_POPUP[1] := 2; WINDOW_POPUP[2] := 3;
  UFO_FIRE := 8; UFO_HIT := 12; UFO_CRASH := 10; UFO_EXPLODE := 11;
  INTERCEPTOR_HIT := 10; INTERCEPTOR_EXPLODE := 13;
  GEOSCAPE_CURSOR := 252; BASESCAPE_CURSOR := 252; BATTLESCAPE_CURSOR := 144;
  UFOPAEDIA_CURSOR := 252; GRAPHS_CURSOR := 252;
  DAMAGE_RANGE := 100; EXPLOSIVE_DAMAGE_RANGE := 50;
  FIRE_DAMAGE_RANGE[0] := 5; FIRE_DAMAGE_RANGE[1] := 10;
  DEBRIEF_MUSIC_GOOD := 'GMMARS'; DEBRIEF_MUSIC_BAD := 'GMMARS';
  Globe.OCEAN_COLOR := TPalette.BlockOffset(12);
  Globe.OCEAN_SHADING := True;
  Globe.COUNTRY_LABEL_COLOR := 239;
  Globe.LINE_COLOR := 162;
  Globe.CITY_LABEL_COLOR := 138;
  Globe.BASE_LABEL_COLOR := 133;
  TTextButton.soundPress := 0;
  TWindow.soundPopup[0] := 0;
  TWindow.soundPopup[1] := 0;
  TWindow.soundPopup[2] := 0;
  Pathfinding.red := 3;
  Pathfinding.yellow := 10;
  Pathfinding.green := 4;
  DIFFICULTY_COEFFICIENT[0] := 0; DIFFICULTY_COEFFICIENT[1] := 1;
  DIFFICULTY_COEFFICIENT[2] := 2; DIFFICULTY_COEFFICIENT[3] := 3;
  DIFFICULTY_COEFFICIENT[4] := 4;
end;

constructor TMod.Create;
begin
  inherited Create;
  FMuteMusic := TMusic.Create;
  FMuteSound := TSound.Create;
  FGlobe := TRuleGlobe.Create;
  FConverter := TRuleConverter.Create;
  FStatAdjustment[0].AimAndArmorMultiplier := 0.5;
  FStatAdjustment[0].GrowthMultiplier := 0;
  for var i := 1 to 4 do
  begin
    FStatAdjustment[i].AimAndArmorMultiplier := 1.0;
    FStatAdjustment[i].GrowthMultiplier := i;
  end;
  FPalettes := TDictionary<string, TPalette>.Create;
  FFonts := TDictionary<string, TFont>.Create;
  FSurfaces := TDictionary<string, TSurface>.Create;
  FSets := TDictionary<string, TSurfaceSet>.Create;
  FSounds := TDictionary<string, TSoundSet>.Create;
  FMusics := TDictionary<string, TMusic>.Create;
  FCountries := TDictionary<string, TRuleCountry>.Create;
  FRegions := TDictionary<string, TRuleRegion>.Create;
  FFacilities := TDictionary<string, TRuleBaseFacility>.Create;
  FCrafts := TDictionary<string, TRuleCraft>.Create;
  FCraftWeapons := TDictionary<string, TRuleCraftWeapon>.Create;
  FItems := TDictionary<string, TRuleItem>.Create;
  FUfos := TDictionary<string, TRuleUfo>.Create;
  FTerrains := TDictionary<string, TRuleTerrain>.Create;
  FMapDataSets := TDictionary<string, TMapDataSet>.Create;
  FSoldiers := TDictionary<string, TRuleSoldier>.Create;
  FUnits := TDictionary<string, TUnit>.Create;
  FAlienRaces := TDictionary<string, TAlienRace>.Create;
  FAlienDeployments := TDictionary<string, TAlienDeployment>.Create;
  FArmors := TDictionary<string, TArmor>.Create;
  FUfopaediaArticles := TDictionary<string, TArticleDefinition>.Create;
  FInvs := TDictionary<string, TRuleInventory>.Create;
  FResearch := TDictionary<string, TRuleResearch>.Create;
  FManufacture := TDictionary<string, TRuleManufacture>.Create;
  FUfoTrajectories := TDictionary<string, TUfoTrajectory>.Create;
  FAlienMissions := TDictionary<string, TRuleAlienMission>.Create;
  FInterfaces := TDictionary<string, TRuleInterface>.Create;
  FSoundDefs := TDictionary<string, TSoundDefinition>.Create;
  FVideos := TDictionary<string, TRuleVideo>.Create;
  FMCDPatches := TDictionary<string, TMDCPatch>.Create;
  FMapScripts := TDictionary<string, TArray<TMapScript>>.Create;
  FCommendations := TDictionary<string, TRuleCommendations>.Create;
  FMissionScripts := TDictionary<string, TRuleMissionScript>.Create;
  FExtraSprites := TDictionary<string, TArray<TExtraSprites>>.Create;
  FExtraStrings := TDictionary<string, TExtraStrings>.Create;
  FMusicDefs := TDictionary<string, TRuleMusic>.Create;
  FUfopaediaSections := TDictionary<string, Integer>.Create;
end;

destructor TMod.Destroy;
begin
  // Free dictionaries and their contents
  // ...
  inherited;
end;

procedure TMod.LoadAll(const Mods: TArray<TPair<string, TArray<string>>>);
begin
  // Implementation would parse mods, load resources, etc.
  // This is a stub for brevity.
end;

function TMod.NewSave: TSavedGame;
begin
  Result := TSavedGame.Create;
  // Implementation would build starting save
end;

// ... all getter methods would be implemented similarly.

end.