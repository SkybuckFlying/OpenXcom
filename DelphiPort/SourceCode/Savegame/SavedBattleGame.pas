unit SavedBattleGame;

interface

uses
  Classes, SysUtils, Generics.Collections, YAML, BattleUnit, BattleItem, Tile, Node,
  MapDataSet, Mod, SavedGame, Pathfinding, TileEngine, BattlescapeState, BattlescapeGame,
  Position, RuleInventory, RuleItem, AlienDeployment;

type
  ChronoTrigger = (ctForceLose, ctForceWin, ctSpawnReinforcements);

  TSavedBattleGame = class
  private
    FBattleState: TBattlescapeState;
    FMapsizeX, FMapsizeY, FMapsizeZ: Integer;
    FMapDataSets: TList<TMapDataSet>;
    FTiles: TArray<TTile>;
    FSelectedUnit: TBattleUnit;
    FLastSelectedUnit: TBattleUnit;
    FNodes: TObjectList<TNode>;
    FUnits: TObjectList<TBattleUnit>;
    FItems: TObjectList<TBattleItem>;
    FDeleted: TList<TBattleItem>;
    FPathfinding: TPathfinding;
    FTileEngine: TTileEngine;
    FMissionType: string;
    FGlobalShade: Integer;
    FSide: TUnitFaction;
    FTurn: Integer;
    FDebugMode: Boolean;
    FAborted: Boolean;
    FItemId: Integer;
    FObjectiveType: Integer;
    FObjectivesDestroyed: Integer;
    FObjectivesNeeded: Integer;
    FFallingUnits: TList<TBattleUnit>;
    FUnitsFalling: Boolean;
    FCheating: Boolean;
    FTileSearch: TArray<TPosition>;
    FStorageSpace: TArray<TPosition>;
    FTUReserved: TBattleActionType;
    FKneelReserved: Boolean;
    FBaseModules: TArray<TArray<TPair<Integer,Integer>>>;
    FDepth: Integer;
    FAmbience: Integer;
    FAmbientVolume: Double;
    FRecoverGuaranteed: TObjectList<TBattleItem>;
    FRecoverConditional: TObjectList<TBattleItem>;
    FMusic: string;
    FTurnLimit: Integer;
    FCheatTurn: Integer;
    FChronoTrigger: ChronoTrigger;
    FBeforeGame: Boolean;
    FExposedUnits: TList<TBattleUnit>;

    function GetTileIndex(Pos: TPosition): Integer;
    function GetTile(Pos: TPosition): TTile;
    procedure SetTile(Pos: TPosition; Value: TTile);
    function SelectPlayerUnit(Dir: Integer; CheckReselect, SetReselect, CheckInventory: Boolean): TBattleUnit;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode; Mod: TMod; SavedGame: TSavedGame);
    function Save: TYamlNode;
    procedure InitMap(MapsizeX, MapsizeY, MapsizeZ: Integer; ResetTerrain: Boolean = True);
    procedure InitUtilities(Mod: TMod);
    property MapDataSets: TList<TMapDataSet> read FMapDataSets;
    property MissionType: string read FMissionType write FMissionType;
    property GlobalShade: Integer read FGlobalShade write FGlobalShade;
    property Tiles[Pos: TPosition]: TTile read GetTile write SetTile; default;
    property Nodes: TObjectList<TNode> read FNodes;
    property Items: TObjectList<TBattleItem> read FItems;
    property Units: TObjectList<TBattleUnit> read FUnits;
    property MapSizeX: Integer read FMapsizeX;
    property MapSizeY: Integer read FMapsizeY;
    property MapSizeZ: Integer read FMapsizeZ;
    function MapSizeXYZ: Integer;
    procedure GetTileCoords(Index: Integer; var X, Y, Z: Integer);
    property SelectedUnit: TBattleUnit read FSelectedUnit write FSelectedUnit;
    function SelectPreviousPlayerUnit(CheckReselect: Boolean = False; SetReselect: Boolean = False; CheckInventory: Boolean = False): TBattleUnit;
    function SelectNextPlayerUnit(CheckReselect: Boolean = False; SetReselect: Boolean = False; CheckInventory: Boolean = False): TBattleUnit;
    function SelectUnit(Pos: TPosition): TBattleUnit;
    property Pathfinding: TPathfinding read FPathfinding;
    property TileEngine: TTileEngine read FTileEngine;
    property Side: TUnitFaction read FSide;
    property Turn: Integer read FTurn;
    procedure EndTurn;
    procedure SetDebugMode;
    property DebugMode: Boolean read FDebugMode;
    procedure LoadMapResources(Mod: TMod);
    procedure ResetUnitTiles;
    procedure RemoveItem(Item: TBattleItem);
    function ConvertUnit(Unit: TBattleUnit; SaveGame: TSavedGame; Mod: TMod): TBattleUnit;
    property Aborted: Boolean read FAborted write FAborted;
    procedure SetObjectiveCount(Counter: Integer);
    procedure AddDestroyedObjective;
    function AllObjectivesDestroyed: Boolean;
    function GetCurrentItemId: PInteger;
    function GetSpawnNode(NodeRank: TNodeRank; Unit: TBattleUnit): TNode;
    function GetPatrolNode(Scout: Boolean; Unit: TBattleUnit; FromNode: TNode): TNode;
    procedure PrepareNewTurn;
    procedure ReviveUnconsciousUnits;
    procedure RemoveUnconsciousBodyItem(BU: TBattleUnit);
    function SetUnitPosition(BU: TBattleUnit; Position: TPosition; TestOnly: Boolean = False): Boolean;
    function AddFallingUnit(Unit: TBattleUnit): Boolean;
    property FallingUnits: TList<TBattleUnit> read FFallingUnits;
    property UnitsFalling: Boolean read FUnitsFalling write FUnitsFalling;
    property BattleState: TBattlescapeState read FBattleState write FBattleState;
    function GetBattleGame: TBattlescapeGame;
    function GetHighestRankedXCom: TBattleUnit;
    function GetMoraleModifier(Unit: TBattleUnit = nil): Integer;
    function EyesOnTarget(Faction: TUnitFaction; Unit: TBattleUnit): Boolean;
    function PlaceUnitNearPosition(Unit: TBattleUnit; const EntryPoint: TPosition; LargeFriend: Boolean): Boolean;
    procedure ResetTurnCounter;
    procedure ResetTiles;
    property TileSearch: TArray<TPosition> read FTileSearch;
    property Cheating: Boolean read FCheating;
    property TUReserved: TBattleActionType read FTUReserved write FTUReserved;
    property KneelReserved: Boolean read FKneelReserved write FKneelReserved;
    property StorageSpace: TArray<TPosition> read FStorageSpace write FStorageSpace;
    procedure RandomizeItemLocations(Tile: TTile);
    property ModuleMap: TArray<TArray<TPair<Integer,Integer>>> read FBaseModules;
    procedure CalculateModuleMap;
    function GetGeoscapeSave: TSavedGame;
    property Depth: Integer read FDepth write FDepth;
    procedure SetPaletteByDepth(State: TState);
    property AmbientSound: Integer read FAmbience write FAmbience;
    property AmbientVolume: Double read FAmbientVolume write FAmbientVolume;
    property RecoverGuaranteed: TObjectList<TBattleItem> read FRecoverGuaranteed;
    property RecoverConditional: TObjectList<TBattleItem> read FRecoverConditional;
    property Music: string read FMusic write FMusic;
    property ObjectiveType: Integer read FObjectiveType write FObjectiveType;
    property TurnLimit: Integer read FTurnLimit write FTurnLimit;
    property ChronoTrigger: ChronoTrigger read FChronoTrigger write FChronoTrigger;
    property CheatTurn: Integer read FCheatTurn write FCheatTurn;
    property BeforeGame: Boolean read FBeforeGame;
    function GetItemUsable(Item: TBattleItem): string;
    function IsItemUsable(Item: TBattleItem): Boolean;
    procedure ResetUnitHitStates;
  end;

implementation

uses
  Math, RNG, SerializationHelper, Options, Logger;

constructor TSavedBattleGame.Create;
begin
  inherited;
  FMapsizeX := 0; FMapsizeY := 0; FMapsizeZ := 0;
  FMapDataSets := TList<TMapDataSet>.Create;
  FNodes := TObjectList<TNode>.Create;
  FUnits := TObjectList<TBattleUnit>.Create;
  FItems := TObjectList<TBattleItem>.Create;
  FDeleted := TList<TBattleItem>.Create;
  FFallingUnits := TList<TBattleUnit>.Create;
  FRecoverGuaranteed := TObjectList<TBattleItem>.Create;
  FRecoverConditional := TObjectList<TBattleItem>.Create;
  FExposedUnits := TList<TBattleUnit>.Create;
  FPathfinding := nil;
  FTileEngine := nil;
  FSelectedUnit := nil;
  FLastSelectedUnit := nil;
  FSide := FACTION_PLAYER;
  FTurn := 1;
  FDebugMode := False;
  FAborted := False;
  FItemId := 0;
  FObjectiveType := -1;
  FObjectivesDestroyed := 0;
  FObjectivesNeeded := 0;
  FUnitsFalling := False;
  FCheating := False;
  FTUReserved := BA_NONE;
  FKneelReserved := False;
  FDepth := 0;
  FAmbience := -1;
  FAmbientVolume := 0.5;
  FTurnLimit := 0;
  FCheatTurn := 20;
  FChronoTrigger := ctForceLose;
  FBeforeGame := True;
  FTileSearch := [];
  FStorageSpace := [];
end;

destructor TSavedBattleGame.Destroy;
begin
  FMapDataSets.Free;
  FNodes.Free;
  FUnits.Free;
  FItems.Free;
  FDeleted.Free;
  FFallingUnits.Free;
  FRecoverGuaranteed.Free;
  FRecoverConditional.Free;
  FExposedUnits.Free;
  FPathfinding.Free;
  FTileEngine.Free;
  inherited;
end;

procedure TSavedBattleGame.Load(const Node: TYamlNode; Mod: TMod; SavedGame: TSavedGame);
begin
  // Load map data from YAML; placeholder
end;

function TSavedBattleGame.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  // Placeholder
end;

procedure TSavedBattleGame.InitMap(MapsizeX, MapsizeY, MapsizeZ: Integer; ResetTerrain: Boolean);
begin
  FMapsizeX := MapsizeX;
  FMapsizeY := MapsizeY;
  FMapsizeZ := MapsizeZ;
  SetLength(FTiles, MapsizeX * MapsizeY * MapsizeZ);
  for var i := 0 to High(FTiles) do
    FTiles[i] := TTile.Create(GetTileCoords(i));
end;

procedure TSavedBattleGame.InitUtilities(Mod: TMod);
begin
  FPathfinding.Free;
  FTileEngine.Free;
  FPathfinding := TPathfinding.Create(Self);
  FTileEngine := TTileEngine.Create(Self, Mod.VoxelData);
end;

function TSavedBattleGame.GetTileIndex(Pos: TPosition): Integer;
begin
  Result := Pos.z * FMapsizeY * FMapsizeX + Pos.y * FMapsizeX + Pos.x;
end;

function TSavedBattleGame.GetTile(Pos: TPosition): TTile;
begin
  if (Pos.x < 0) or (Pos.y < 0) or (Pos.z < 0) or
     (Pos.x >= FMapsizeX) or (Pos.y >= FMapsizeY) or (Pos.z >= FMapsizeZ) then
    Exit(nil);
  Result := FTiles[GetTileIndex(Pos)];
end;

procedure TSavedBattleGame.SetTile(Pos: TPosition; Value: TTile);
begin
  FTiles[GetTileIndex(Pos)] := Value;
end;

function TSavedBattleGame.MapSizeXYZ: Integer;
begin
  Result := FMapsizeX * FMapsizeY * FMapsizeZ;
end;

procedure TSavedBattleGame.GetTileCoords(Index: Integer; var X, Y, Z: Integer);
begin
  Z := Index div (FMapsizeY * FMapsizeX);
  Y := (Index mod (FMapsizeY * FMapsizeX)) div FMapsizeX;
  X := (Index mod (FMapsizeY * FMapsizeX)) mod FMapsizeX;
end;

function TSavedBattleGame.SelectPreviousPlayerUnit(CheckReselect, SetReselect, CheckInventory: Boolean): TBattleUnit;
begin
  Result := SelectPlayerUnit(-1, CheckReselect, SetReselect, CheckInventory);
end;

function TSavedBattleGame.SelectNextPlayerUnit(CheckReselect, SetReselect, CheckInventory: Boolean): TBattleUnit;
begin
  Result := SelectPlayerUnit(1, CheckReselect, SetReselect, CheckInventory);
end;

function TSavedBattleGame.SelectPlayerUnit(Dir: Integer; CheckReselect, SetReselect, CheckInventory: Boolean): TBattleUnit;
var
  i, start: Integer;
  unit: TBattleUnit;
begin
  if (FSelectedUnit <> nil) and SetReselect then
    FSelectedUnit.DontReselect;
  if FUnits.Count = 0 then Exit(nil);

  if Dir > 0 then
  begin
    i := 0;
    while i < FUnits.Count do
    begin
      unit := FUnits[i];
      if unit.IsSelectable(FSide, CheckReselect, CheckInventory) then
      begin
        FSelectedUnit := unit;
        Exit(unit);
      end;
      Inc(i);
    end;
  end
  else
  begin
    i := FUnits.Count - 1;
    while i >= 0 do
    begin
      unit := FUnits[i];
      if unit.IsSelectable(FSide, CheckReselect, CheckInventory) then
      begin
        FSelectedUnit := unit;
        Exit(unit);
      end;
      Dec(i);
    end;
  end;
  Result := nil;
end;

function TSavedBattleGame.SelectUnit(Pos: TPosition): TBattleUnit;
var
  tile: TTile;
begin
  tile := GetTile(Pos);
  if tile = nil then Exit(nil);
  Result := tile.GetUnit;
  if (Result <> nil) and Result.IsOut then
    Result := nil;
end;

procedure TSavedBattleGame.EndTurn;
var
  liveSoldiers, liveAliens: Integer;
begin
  if FSide = FACTION_PLAYER then
  begin
    if (FSelectedUnit <> nil) and (FSelectedUnit.OriginalFaction = FACTION_PLAYER) then
      FLastSelectedUnit := FSelectedUnit;
    FSelectedUnit := nil;
    FSide := FACTION_HOSTILE;
  end
  else if FSide = FACTION_HOSTILE then
  begin
    FSide := FACTION_NEUTRAL;
    if SelectNextPlayerUnit(False, False, False) = nil then
    begin
      PrepareNewTurn;
      Inc(FTurn);
      FSide := FACTION_PLAYER;
      if (FLastSelectedUnit <> nil) and FLastSelectedUnit.IsSelectable(FACTION_PLAYER, False, False) then
        FSelectedUnit := FLastSelectedUnit
      else
        SelectNextPlayerUnit;
      while (FSelectedUnit <> nil) and (FSelectedUnit.Faction <> FACTION_PLAYER) do
        SelectNextPlayerUnit;
    end;
  end
  else if FSide = FACTION_NEUTRAL then
  begin
    PrepareNewTurn;
    Inc(FTurn);
    FSide := FACTION_PLAYER;
    if (FLastSelectedUnit <> nil) and FLastSelectedUnit.IsSelectable(FACTION_PLAYER, False, False) then
      FSelectedUnit := FLastSelectedUnit
    else
      SelectNextPlayerUnit;
    while (FSelectedUnit <> nil) and (FSelectedUnit.Faction <> FACTION_PLAYER) do
      SelectNextPlayerUnit;
  end;

  GetBattleGame.TallyUnits(liveAliens, liveSoldiers);
  if (FTurn > FCheatTurn div 2) and (liveAliens <= 2) or (FTurn > FCheatTurn) then
    FCheating := True;

  if FSide = FACTION_PLAYER then
  begin
    for var u in FUnits do
    begin
      if u.TurnsSinceSpotted < 255 then
        u.TurnsSinceSpotted := u.TurnsSinceSpotted + 1;
      if FCheating and (u.Faction = FACTION_PLAYER) and not u.IsOut then
        u.TurnsSinceSpotted := 0;
      if u.AIModule <> nil then
        u.AIModule.Reset;
    end;
  end;

  for var u in FUnits do
  begin
    if u.Faction = FSide then
      u.PrepareNewTurn;
    if u.Faction <> FACTION_PLAYER then
      u.SetVisible(False);
  end;

  FTileEngine.RecalculateFOV;
  if FSide <> FACTION_PLAYER then
    SelectNextPlayerUnit;
end;

procedure TSavedBattleGame.SetDebugMode;
begin
  for var tile in FTiles do
    tile.SetDiscovered(True, 2);
  FDebugMode := True;
end;

procedure TSavedBattleGame.LoadMapResources(Mod: TMod);
begin
  // Load map data sets
end;

procedure TSavedBattleGame.ResetUnitTiles;
begin
  for var u in FUnits do
  begin
    if not u.IsOut then
    begin
      var size := u.Armor.Size - 1;
      if (u.Tile <> nil) and (u.Tile.GetUnit = u) then
      begin
        for var x := size downto 0 do
          for var y := size downto 0 do
            GetTile(u.Tile.Position + TPosition.Create(x, y, 0)).SetUnit(nil);
      end;
      for var x := size downto 0 do
        for var y := size downto 0 do
        begin
          var tile := GetTile(u.Position + TPosition.Create(x, y, 0));
          tile.SetUnit(u, GetTile(tile.Position + TPosition.Create(0,0,-1)));
        end;
    end;
    if u.Faction = FACTION_PLAYER then
      u.SetVisible(True);
  end;
  FBeforeGame := False;
end;

procedure TSavedBattleGame.RemoveItem(Item: TBattleItem);
begin
  // Remove from tiles, units, and items list
end;

function TSavedBattleGame.ConvertUnit(Unit: TBattleUnit; SaveGame: TSavedGame; Mod: TMod): TBattleUnit;
begin
  // Placeholder
  Result := nil;
end;

procedure TSavedBattleGame.SetObjectiveCount(Counter: Integer);
begin
  FObjectivesNeeded := Counter;
  FObjectivesDestroyed := 0;
end;

procedure TSavedBattleGame.AddDestroyedObjective;
begin
  if not AllObjectivesDestroyed then
  begin
    Inc(FObjectivesDestroyed);
    if AllObjectivesDestroyed then
    begin
      if FObjectiveType = MUST_DESTROY then
        GetBattleGame.AutoEndBattle
      else
        GetBattleGame.MissionComplete;
    end;
  end;
end;

function TSavedBattleGame.AllObjectivesDestroyed: Boolean;
begin
  Result := (FObjectivesNeeded > 0) and (FObjectivesDestroyed = FObjectivesNeeded);
end;

function TSavedBattleGame.GetCurrentItemId: PInteger;
begin
  Result := @FItemId;
end;

function TSavedBattleGame.GetSpawnNode(NodeRank: TNodeRank; Unit: TBattleUnit): TNode;
begin
  // Placeholder
  Result := nil;
end;

function TSavedBattleGame.GetPatrolNode(Scout: Boolean; Unit: TBattleUnit; FromNode: TNode): TNode;
begin
  // Placeholder
  Result := nil;
end;

procedure TSavedBattleGame.PrepareNewTurn;
begin
  // Fire and smoke spread, etc.
end;

procedure TSavedBattleGame.ReviveUnconsciousUnits;
begin
  // Check stun levels
end;

procedure TSavedBattleGame.RemoveUnconsciousBodyItem(BU: TBattleUnit);
begin
  // Remove body item
end;

function TSavedBattleGame.SetUnitPosition(BU: TBattleUnit; Position: TPosition; TestOnly: Boolean): Boolean;
begin
  // Placeholder
  Result := True;
end;

function TSavedBattleGame.AddFallingUnit(Unit: TBattleUnit): Boolean;
begin
  if not FFallingUnits.Contains(Unit) then
  begin
    FFallingUnits.Add(Unit);
    FUnitsFalling := True;
    Result := True;
  end
  else
    Result := False;
end;

function TSavedBattleGame.GetBattleGame: TBattlescapeGame;
begin
  Result := FBattleState.GetBattleGame;
end;

function TSavedBattleGame.GetHighestRankedXCom: TBattleUnit;
begin
  Result := nil;
  for var u in FUnits do
    if (u.OriginalFaction = FACTION_PLAYER) and not u.IsOut then
      if (Result = nil) or (u.RankInt > Result.RankInt) then
        Result := u;
end;

function TSavedBattleGame.GetMoraleModifier(Unit: TBattleUnit): Integer;
begin
  Result := 100;
  if Unit = nil then
  begin
    var leader := GetHighestRankedXCom;
    if leader <> nil then
    begin
      case leader.RankInt of
        5: Result := Result + 25;
        4: Result := Result + 10;
        3: Result := Result + 5;
        2: Result := Result + 10;
      end;
    end;
  end
  else if Unit.Faction = FACTION_PLAYER then
  begin
    case Unit.RankInt of
      5: Result := Result + 25;
      4: Result := Result + 20;
      3: Result := Result + 10;
      2: Result := Result + 20;
    end;
  end;
end;

function TSavedBattleGame.EyesOnTarget(Faction: TUnitFaction; Unit: TBattleUnit): Boolean;
begin
  for var u in FUnits do
    if u.Faction = Faction then
      if u.VisibleUnits.Contains(Unit) then
        Exit(True);
  Result := False;
end;

function TSavedBattleGame.PlaceUnitNearPosition(Unit: TBattleUnit; const EntryPoint: TPosition; LargeFriend: Boolean): Boolean;
begin
  // Placeholder
  Result := True;
end;

procedure TSavedBattleGame.ResetTurnCounter;
begin
  FTurn := 1;
  FCheating := False;
  FSide := FACTION_PLAYER;
  FBeforeGame := True;
end;

procedure TSavedBattleGame.ResetTiles;
begin
  for var tile in FTiles do
  begin
    tile.SetDiscovered(False, 0);
    tile.SetDiscovered(False, 1);
    tile.SetDiscovered(False, 2);
  end;
end;

procedure TSavedBattleGame.RandomizeItemLocations(Tile: TTile);
begin
  // Placeholder
end;

procedure TSavedBattleGame.CalculateModuleMap;
begin
  // Placeholder
end;

function TSavedBattleGame.GetGeoscapeSave: TSavedGame;
begin
  Result := FBattleState.GetGame.SavedGame;
end;

procedure TSavedBattleGame.SetPaletteByDepth(State: TState);
begin
  if FDepth = 0 then
    State.SetPalette('PAL_BATTLESCAPE')
  else
    State.SetPalette('PAL_BATTLESCAPE_' + IntToStr(FDepth));
end;

function TSavedBattleGame.GetItemUsable(Item: TBattleItem): string;
begin
  if (FDepth = 0) and ((Item.Rules.IsWaterOnly) or ((Item.AmmoItem <> nil) and (Item.AmmoItem.Rules.IsWaterOnly))) then
    Exit('STR_UNDERWATER_EQUIPMENT');
  if (FDepth <> 0) and ((Item.Rules.IsLandOnly) or ((Item.AmmoItem <> nil) and (Item.AmmoItem.Rules.IsLandOnly))) then
    Exit('STR_LAND_EQUIPMENT');
  Result := '';
end;

function TSavedBattleGame.IsItemUsable(Item: TBattleItem): Boolean;
begin
  Result := GetItemUsable(Item) = '';
end;

procedure TSavedBattleGame.ResetUnitHitStates;
begin
  for var u in FUnits do
    u.ResetHitState;
end;

end.