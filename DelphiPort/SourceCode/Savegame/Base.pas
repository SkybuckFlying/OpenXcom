unit Base;

interface

uses
  Classes, SysUtils, Generics.Collections, YAML, Target, Mod, BaseFacility,
  Soldier, Craft, ItemContainer, Transfer, ResearchProject, Production, Vehicle,
  SavedGame;

type
  TBase = class(TTarget)
  private
    const BASE_SIZE = 6;
    FMod: TMod;
    FFacilities: TObjectList<TBaseFacility>;
    FSoldiers: TObjectList<TSoldier>;
    FCrafts: TObjectList<TCraft>;
    FTransfers: TObjectList<TTransfer>;
    FItems: TItemContainer;
    FScientists: Integer;
    FEngineers: Integer;
    FResearch: TObjectList<TResearchProject>;
    FProductions: TObjectList<TProduction>;
    FInBattlescape: Boolean;
    FRetaliationTarget: Boolean;
    FVehicles: TObjectList<TVehicle>;
    FDefenses: TObjectList<TBaseFacility>;
    function GetIgnoredStores: Double;
  public
    constructor Create(Mod: TMod);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode; Save: TSavedGame; NewGame: Boolean; NewBattleGame: Boolean = False);
    function Save: TYamlNode;
    function GetType: string; override;
    function GetName(Lang: TLanguage): string; override;
    function GetMarker: Integer; override;
    property Facilities: TObjectList<TBaseFacility> read FFacilities;
    property Soldiers: TObjectList<TSoldier> read FSoldiers;
    property Crafts: TObjectList<TCraft> read FCrafts;
    property Transfers: TObjectList<TTransfer> read FTransfers;
    property StorageItems: TItemContainer read FItems;
    property Scientists: Integer read FScientists write FScientists;
    property Engineers: Integer read FEngineers write FEngineers;
    function Detect(Target: TTarget): Integer;
    function InsideRadarRange(Target: TTarget): Integer;
    function GetAvailableSoldiers(CheckCombatReadiness: Boolean = False): Integer;
    function GetTotalSoldiers: Integer;
    function GetAvailableScientists: Integer;
    function GetTotalScientists: Integer;
    function GetAvailableEngineers: Integer;
    function GetTotalEngineers: Integer;
    function GetUsedQuarters: Integer;
    function GetAvailableQuarters: Integer;
    function GetUsedStores: Double;
    function StoresOverfull(Offset: Double = 0.0): Boolean;
    function GetAvailableStores: Integer;
    function GetUsedLaboratories: Integer;
    function GetAvailableLaboratories: Integer;
    function GetUsedWorkshops: Integer;
    function GetAvailableWorkshops: Integer;
    function GetUsedHangars: Integer;
    function GetAvailableHangars: Integer;
    function GetFreeLaboratories: Integer;
    function GetFreeWorkshops: Integer;
    function GetFreePsiLabs: Integer;
    function GetFreeContainment: Integer;
    function GetAllocatedScientists: Integer;
    function GetAllocatedEngineers: Integer;
    function GetDefenseValue: Integer;
    function GetShortRangeDetection: Integer;
    function GetLongRangeDetection: Integer;
    function GetCraftCount(const CraftType: string): Integer;
    function GetCraftMaintenance: Integer;
    function GetSoldierCount(const SoldierType: string): Integer;
    function GetPersonnelMaintenance: Integer;
    function GetFacilityMaintenance: Integer;
    function GetMonthlyMaintenance: Integer;
    property Research: TObjectList<TResearchProject> read FResearch;
    procedure AddResearch(Project: TResearchProject);
    procedure RemoveResearch(Project: TResearchProject);
    procedure AddProduction(Prod: TProduction);
    procedure RemoveProduction(Prod: TProduction);
    property Productions: TObjectList<TProduction> read FProductions;
    function GetAvailablePsiLabs: Integer;
    function GetUsedPsiLabs: Integer;
    function GetAvailableContainment: Integer;
    function GetUsedContainment: Integer;
    property InBattlescape: Boolean read FInBattlescape write FInBattlescape;
    property RetaliationTarget: Boolean read FRetaliationTarget write FRetaliationTarget;
    function GetDetectionChance: Integer;
    function GetGravShields: Integer;
    procedure SetupDefenses;
    property Defenses: TObjectList<TBaseFacility> read FDefenses;
    property Vehicles: TObjectList<TVehicle> read FVehicles;
    procedure DestroyDisconnectedFacilities;
    function GetDisconnectedFacilities(Remove: TBaseFacility): TList<TObject>;
    procedure DestroyFacility(Facility: TBaseFacility);
    procedure CleanupDefenses(ReclaimItems: Boolean);
    function RemoveCraft(Craft: TCraft; Unload: Boolean): Integer;
  end;

implementation

uses
  Math, RNG, Options, Logger, RuleBaseFacility, RuleCraft, RuleItem, Armor,
  RuleManufacture, RuleResearch, Language;

constructor TBase.Create(Mod: TMod);
begin
  inherited Create;
  FMod := Mod;
  FFacilities := TObjectList<TBaseFacility>.Create;
  FSoldiers := TObjectList<TSoldier>.Create;
  FCrafts := TObjectList<TCraft>.Create;
  FTransfers := TObjectList<TTransfer>.Create;
  FItems := TItemContainer.Create;
  FResearch := TObjectList<TResearchProject>.Create;
  FProductions := TObjectList<TProduction>.Create;
  FVehicles := TObjectList<TVehicle>.Create;
  FDefenses := TObjectList<TBaseFacility>.Create;
  FScientists := 0;
  FEngineers := 0;
  FInBattlescape := False;
  FRetaliationTarget := False;
end;

destructor TBase.Destroy;
begin
  FFacilities.Free;
  FSoldiers.Free;
  FCrafts.Free;
  FTransfers.Free;
  FItems.Free;
  FResearch.Free;
  FProductions.Free;
  FVehicles.Free;
  FDefenses.Free;
  inherited;
end;

procedure TBase.Load(const Node: TYamlNode; Save: TSavedGame; NewGame: Boolean; NewBattleGame: Boolean);
begin
  inherited Load(Node);
  // Load facilities, soldiers, crafts, etc. from YAML
end;

function TBase.Save: TYamlNode;
begin
  Result := inherited Save;
  // Save all contents
end;

function TBase.GetType: string;
begin
  Result := 'STR_BASE';
end;

function TBase.GetName(Lang: TLanguage): string;
begin
  Result := FName;
end;

function TBase.GetMarker: Integer;
begin
  if (Abs(FLon) < 1e-12) and (Abs(FLat) < 1e-12) then
    Result := -1
  else
    Result := 0;
end;

function TBase.Detect(Target: TTarget): Integer;
var
  chance: Integer;
  distance: Double;
begin
  chance := 0;
  distance := GetDistance(Target) * 60.0 * (180.0 / Pi);
  for var fac in FFacilities do
  begin
    if (fac.Rules.RadarRange >= distance) and (fac.BuildTime = 0) then
    begin
      if fac.Rules.IsHyperwave then
      begin
        if (fac.Rules.RadarChance = 100) or RNG.Percent(fac.Rules.RadarChance) then
          Exit(2);
      end
      else
        chance := chance + fac.Rules.RadarChance;
    end;
  end;
  if chance = 0 then Exit(0);
  var u := Target as TUfo;
  if u <> nil then
    chance := chance * (100 + u.Visibility) div 100;
  if RNG.Percent(chance) then
    Result := 1
  else
    Result := 0;
end;

function TBase.InsideRadarRange(Target: TTarget): Integer;
var
  inside: Boolean;
  distance: Double;
begin
  inside := False;
  distance := GetDistance(Target) * 60.0 * (180.0 / Pi);
  for var fac in FFacilities do
  begin
    if (fac.Rules.RadarRange >= distance) and (fac.BuildTime = 0) then
    begin
      if fac.Rules.IsHyperwave then
        Exit(2);
      inside := True;
    end;
  end;
  if inside then Result := 1 else Result := 0;
end;

function TBase.GetAvailableSoldiers(CheckCombatReadiness: Boolean): Integer;
begin
  Result := 0;
  for var s in FSoldiers do
  begin
    if not CheckCombatReadiness then
    begin
      if s.Craft = nil then Inc(Result);
    end
    else
    begin
      if ((s.Craft <> nil) and (s.Craft.Status <> 'STR_OUT')) or
         ((s.Craft = nil) and (s.WoundRecovery = 0)) then
        Inc(Result);
    end;
  end;
end;

function TBase.GetTotalSoldiers: Integer;
begin
  Result := FSoldiers.Count;
  for var t in FTransfers do
    if t.Type = TRANSFER_SOLDIER then
      Result := Result + t.Quantity;
end;

function TBase.GetAvailableScientists: Integer;
begin
  Result := FScientists;
end;

function TBase.GetTotalScientists: Integer;
begin
  Result := FScientists;
  for var t in FTransfers do
    if t.Type = TRANSFER_SCIENTIST then
      Result := Result + t.Quantity;
  for var r in FResearch do
    Result := Result + r.Assigned;
end;

function TBase.GetAvailableEngineers: Integer;
begin
  Result := FEngineers;
end;

function TBase.GetTotalEngineers: Integer;
begin
  Result := FEngineers;
  for var t in FTransfers do
    if t.Type = TRANSFER_ENGINEER then
      Result := Result + t.Quantity;
  for var p in FProductions do
    Result := Result + p.AssignedEngineers;
end;

function TBase.GetUsedQuarters: Integer;
begin
  Result := GetTotalSoldiers + GetTotalScientists + GetTotalEngineers;
end;

function TBase.GetAvailableQuarters: Integer;
begin
  Result := 0;
  for var fac in FFacilities do
    if fac.BuildTime = 0 then
      Result := Result + fac.Rules.Personnel;
end;

function TBase.GetUsedStores: Double;
begin
  Result := FItems.GetTotalSize(FMod);
  for var c in FCrafts do
  begin
    Result := Result + c.Items.GetTotalSize(FMod);
    for var v in c.Vehicles do
      Result := Result + v.Rules.Size;
  end;
  for var t in FTransfers do
  begin
    if t.Type = TRANSFER_ITEM then
      Result := Result + t.Quantity * FMod.GetItem(t.Items).Size
    else if t.Type = TRANSFER_CRAFT then
      Result := Result + t.Craft.Items.GetTotalSize(FMod);
  end;
  Result := Result - GetIgnoredStores;
end;

function TBase.StoresOverfull(Offset: Double): Boolean;
var
  capacity: Integer;
begin
  capacity := GetAvailableStores * 100;
  Result := Round((GetUsedStores + Offset) * 100) > capacity;
end;

function TBase.GetAvailableStores: Integer;
begin
  Result := 0;
  for var fac in FFacilities do
    if fac.BuildTime = 0 then
      Result := Result + fac.Rules.Storage;
end;

function TBase.GetIgnoredStores: Double;
begin
  Result := 0;
  for var c in FCrafts do
  begin
    if c.Status = 'STR_REARMING' then
    begin
      for var w in c.Weapons do
      begin
        if (w <> nil) and w.IsRearming then
        begin
          var clip := w.Rules.ClipItem;
          var available := FItems.GetItem(clip);
          if (clip <> '') and (available > 0) then
          begin
            var clipSize := FMod.GetItem(clip).ClipSize;
            var needed := 0;
            if clipSize > 0 then
              needed := (w.Rules.AmmoMax - w.Ammo) div clipSize;
            Result := Result + Min(available, needed) * FMod.GetItem(clip).Size;
          end;
        end;
      end;
    end;
  end;
end;

function TBase.GetUsedLaboratories: Integer;
begin
  Result := 0;
  for var r in FResearch do
    Result := Result + r.Assigned;
end;

function TBase.GetAvailableLaboratories: Integer;
begin
  Result := 0;
  for var fac in FFacilities do
    if fac.BuildTime = 0 then
      Result := Result + fac.Rules.Laboratories;
end;

function TBase.GetUsedWorkshops: Integer;
begin
  Result := 0;
  for var p in FProductions do
    Result := Result + p.AssignedEngineers + p.Rules.RequiredSpace;
end;

function TBase.GetAvailableWorkshops: Integer;
begin
  Result := 0;
  for var fac in FFacilities do
    if fac.BuildTime = 0 then
      Result := Result + fac.Rules.Workshops;
end;

function TBase.GetUsedHangars: Integer;
begin
  Result := FCrafts.Count;
  for var t in FTransfers do
    if t.Type = TRANSFER_CRAFT then
      Result := Result + t.Quantity;
  for var p in FProductions do
    if p.Rules.Category = 'STR_CRAFT' then
      Result := Result + (p.AmountTotal - p.AmountProduced);
end;

function TBase.GetAvailableHangars: Integer;
begin
  Result := 0;
  for var fac in FFacilities do
    if fac.BuildTime = 0 then
      Result := Result + fac.Rules.Crafts;
end;

function TBase.GetFreeLaboratories: Integer;
begin
  Result := GetAvailableLaboratories - GetUsedLaboratories;
end;

function TBase.GetFreeWorkshops: Integer;
begin
  Result := GetAvailableWorkshops - GetUsedWorkshops;
end;

function TBase.GetFreePsiLabs: Integer;
begin
  Result := GetAvailablePsiLabs - GetUsedPsiLabs;
end;

function TBase.GetFreeContainment: Integer;
begin
  Result := GetAvailableContainment - GetUsedContainment;
end;

function TBase.GetAllocatedScientists: Integer;
begin
  Result := 0;
  for var r in FResearch do
    Result := Result + r.Assigned;
end;

function TBase.GetAllocatedEngineers: Integer;
begin
  Result := 0;
  for var p in FProductions do
    Result := Result + p.AssignedEngineers;
end;

function TBase.GetDefenseValue: Integer;
begin
  Result := 0;
  for var fac in FFacilities do
    if fac.BuildTime = 0 then
      Result := Result + fac.Rules.DefenseValue;
end;

function TBase.GetShortRangeDetection: Integer;
begin
  Result := 0;
  var minRange := FMod.GetMinRadarRange;
  if minRange = 0 then Exit(0);
  for var fac in FFacilities do
    if (fac.Rules.RadarRange = minRange) and (fac.BuildTime = 0) then
      Inc(Result);
end;

function TBase.GetLongRangeDetection: Integer;
begin
  Result := 0;
  var minRange := FMod.GetMinRadarRange;
  for var fac in FFacilities do
    if (fac.Rules.RadarRange > minRange) and (fac.BuildTime = 0) then
      Inc(Result);
end;

function TBase.GetCraftCount(const CraftType: string): Integer;
begin
  Result := 0;
  for var t in FTransfers do
    if (t.Type = TRANSFER_CRAFT) and (t.Craft.Rules.Type = CraftType) then
      Inc(Result);
  for var c in FCrafts do
    if c.Rules.Type = CraftType then
      Inc(Result);
end;

function TBase.GetCraftMaintenance: Integer;
begin
  Result := 0;
  for var t in FTransfers do
    if t.Type = TRANSFER_CRAFT then
      Result := Result + t.Craft.Rules.RentCost;
  for var c in FCrafts do
    Result := Result + c.Rules.RentCost;
end;

function TBase.GetSoldierCount(const SoldierType: string): Integer;
begin
  Result := 0;
  for var t in FTransfers do
    if (t.Type = TRANSFER_SOLDIER) and (t.Soldier.Rules.Type = SoldierType) then
      Inc(Result);
  for var s in FSoldiers do
    if s.Rules.Type = SoldierType then
      Inc(Result);
end;

function TBase.GetPersonnelMaintenance: Integer;
begin
  Result := 0;
  for var t in FTransfers do
    if t.Type = TRANSFER_SOLDIER then
      Result := Result + t.Soldier.Rules.SalaryCost;
  for var s in FSoldiers do
    Result := Result + s.Rules.SalaryCost;
  Result := Result + GetTotalEngineers * FMod.EngineerCost;
  Result := Result + GetTotalScientists * FMod.ScientistCost;
end;

function TBase.GetFacilityMaintenance: Integer;
begin
  Result := 0;
  for var fac in FFacilities do
    if fac.BuildTime = 0 then
      Result := Result + fac.Rules.MonthlyCost;
end;

function TBase.GetMonthlyMaintenance: Integer;
begin
  Result := GetCraftMaintenance + GetPersonnelMaintenance + GetFacilityMaintenance;
end;

procedure TBase.AddResearch(Project: TResearchProject);
begin
  FResearch.Add(Project);
end;

procedure TBase.RemoveResearch(Project: TResearchProject);
begin
  FScientists := FScientists + Project.Assigned;
  FResearch.Remove(Project);
  Project.Free;
end;

procedure TBase.AddProduction(Prod: TProduction);
begin
  FProductions.Add(Prod);
end;

procedure TBase.RemoveProduction(Prod: TProduction);
begin
  FEngineers := FEngineers + Prod.AssignedEngineers;
  FProductions.Remove(Prod);
  Prod.Free;
end;

function TBase.GetAvailablePsiLabs: Integer;
begin
  Result := 0;
  for var fac in FFacilities do
    if fac.BuildTime = 0 then
      Result := Result + fac.Rules.PsiLaboratories;
end;

function TBase.GetUsedPsiLabs: Integer;
begin
  Result := 0;
  for var s in FSoldiers do
    if s.IsInPsiTraining then
      Inc(Result);
end;

function TBase.GetAvailableContainment: Integer;
begin
  Result := 0;
  for var fac in FFacilities do
    if fac.BuildTime = 0 then
      Result := Result + fac.Rules.Aliens;
end;

function TBase.GetUsedContainment: Integer;
begin
  Result := 0;
  for var pair in FItems.Contents do
    if FMod.GetItem(pair.Key).IsAlien then
      Result := Result + pair.Value;
  for var t in FTransfers do
    if (t.Type = TRANSFER_ITEM) and FMod.GetItem(t.Items).IsAlien then
      Result := Result + t.Quantity;
  for var r in FResearch do
    if r.Rules.NeedItem and (FMod.GetUnit(r.Rules.Name) <> nil) then
      Inc(Result);
end;

function TBase.GetDetectionChance: Integer;
var
  mindShields, completedFacilities: Integer;
begin
  mindShields := 0;
  completedFacilities := 0;
  for var fac in FFacilities do
  begin
    if fac.BuildTime = 0 then
    begin
      if fac.Rules.IsMindShield then
        Inc(mindShields);
      completedFacilities := completedFacilities + fac.Rules.Size * fac.Rules.Size;
    end;
  end;
  Result := (completedFacilities div 6 + 15) div (mindShields + 1);
end;

function TBase.GetGravShields: Integer;
begin
  Result := 0;
  for var fac in FFacilities do
    if (fac.BuildTime = 0) and fac.Rules.IsGravShield then
      Inc(Result);
end;

procedure TBase.SetupDefenses;
begin
  // Build defenses list and vehicles
end;

procedure TBase.DestroyDisconnectedFacilities;
begin
  // Remove disconnected facilities
end;

function TBase.GetDisconnectedFacilities(Remove: TBaseFacility): TList<TObject>;
begin
  Result := TList<TObject>.Create;
  // Implement connectivity algorithm
end;

procedure TBase.DestroyFacility(Facility: TBaseFacility);
begin
  // Remove facility and handle consequences
end;

procedure TBase.CleanupDefenses(ReclaimItems: Boolean);
begin
  // Cleanup defenses
end;

function TBase.RemoveCraft(Craft: TCraft; Unload: Boolean): Integer;
begin
  if Unload then
    Craft.Unload(FMod);
  // Clear hangar and remove craft
  Result := FCrafts.IndexOf(Craft);
  FCrafts.Remove(Craft);
end;

end.