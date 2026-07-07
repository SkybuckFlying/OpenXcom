unit Craft;

interface

uses
  Classes, SysUtils, Generics.Collections, YAML, MovingTarget, Mod, Base,
  RuleCraft, CraftWeapon, ItemContainer, Soldier, Vehicle, SavedGame, Target,
  Ufo, Waypoint, MissionSite, AlienBase, Language;

type
  TCraftId = record
    CraftType: string;
    Id: Integer;
  end;

  TCraft = class(TMovingTarget)
  private
    FRules: TRuleCraft;
    FBase: TBase;
    FFuel: Integer;
    FDamage: Integer;
    FInterceptionOrder: Integer;
    FTakeoff: Integer;
    FWeapons: TObjectList<TCraftWeapon>;
    FItems: TItemContainer;
    FVehicles: TObjectList<TVehicle>;
    FStatus: string;
    FLowFuel: Boolean;
    FMission: Boolean;
    FInBattlescape: Boolean;
    FInDogfight: Boolean;
    FSpeedMaxRadian: Double;
  public
    constructor Create(Rules: TRuleCraft; Base: TBase; Id: Integer = 0);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode; Mod: TMod; Save: TSavedGame);
    function Save: TYamlNode;
    class function LoadId(const Node: TYamlNode): TCraftId;
    function GetType: string; override;
    property Rules: TRuleCraft read FRules write FRules;
    function GetDefaultName(Lang: TLanguage): string;
    function GetMarker: Integer; override;
    property Base: TBase read FBase write SetBase;
    procedure SetBase(Base: TBase; Move: Boolean = True);
    property Status: string read FStatus write FStatus;
    function GetAltitude: string;
    procedure SetDestination(Dest: TTarget); override;
    function GetNumWeapons: Integer;
    function GetNumSoldiers: Integer;
    function GetNumEquipment: Integer;
    function GetNumVehicles: Integer;
    property Weapons: TObjectList<TCraftWeapon> read FWeapons;
    property Items: TItemContainer read FItems;
    property Vehicles: TObjectList<TVehicle> read FVehicles;
    property Fuel: Integer read FFuel write SetFuel;
    function GetFuelPercentage: Integer;
    property Damage: Integer read FDamage write SetDamage;
    function GetDamagePercentage: Integer;
    property LowFuel: Boolean read FLowFuel write FLowFuel;
    property MissionComplete: Boolean read FMission write FMission;
    function GetDistanceFromBase: Double;
    function GetFuelConsumption: Integer; overload;
    function GetFuelConsumption(Speed: Integer): Integer; overload;
    function GetFuelLimit: Integer; overload;
    function GetFuelLimit(Base: TBase): Integer; overload;
    function GetBaseRange: Double;
    procedure ReturnToBase;
    function Detect(Target: TTarget): Boolean;
    function InsideRadarRange(Target: TTarget): Boolean;
    procedure Think;
    procedure Checkup;
    procedure ConsumeFuel;
    procedure Repair;
    function Refuel: string;
    function Rearm(Mod: TMod): string;
    property InBattlescape: Boolean read FInBattlescape write FInBattlescape;
    function IsDestroyed: Boolean;
    function GetSpaceAvailable: Integer;
    function GetSpaceUsed: Integer;
    function GetVehicleCount(const VehicleType: string): Integer;
    property InDogfight: Boolean read FInDogfight write FInDogfight;
    property InterceptionOrder: Integer read FInterceptionOrder write FInterceptionOrder;
    function GetUniqueId: TCraftId;
    procedure Unload(Mod: TMod);
    procedure ReuseItem(const Item: string);
  end;

implementation

uses
  Math, RNG, Logger, RuleCraftWeapon, RuleItem, Mod;

constructor TCraft.Create(Rules: TRuleCraft; Base: TBase; Id: Integer);
begin
  inherited Create;
  FRules := Rules;
  FBase := Base;
  FFuel := 0;
  FDamage := 0;
  FInterceptionOrder := 0;
  FTakeoff := 0;
  FStatus := 'STR_READY';
  FLowFuel := False;
  FMission := False;
  FInBattlescape := False;
  FInDogfight := False;
  FItems := TItemContainer.Create;
  FWeapons := TObjectList<TCraftWeapon>.Create;
  FVehicles := TObjectList<TVehicle>.Create;
  FId := Id;
  if Base <> nil then
    SetBase(Base);
  FSpeedMaxRadian := CalculateRadianSpeed(FRules.MaxSpeed) * 120;
end;

destructor TCraft.Destroy;
begin
  FItems.Free;
  FWeapons.Free;
  FVehicles.Free;
  inherited;
end;

procedure TCraft.Load(const Node: TYamlNode; Mod: TMod; Save: TSavedGame);
begin
  inherited Load(Node);
  // Load craft specific data
end;

function TCraft.Save: TYamlNode;
begin
  Result := inherited Save;
  // Save craft data
end;

class function TCraft.LoadId(const Node: TYamlNode): TCraftId;
begin
  Result.CraftType := Node['type'].AsString;
  Result.Id := Node['id'].AsInteger;
end;

function TCraft.GetType: string;
begin
  Result := FRules.Type;
end;

function TCraft.GetDefaultName(Lang: TLanguage): string;
begin
  Result := Lang.GetString('STR_CRAFTNAME').Format([Lang.GetString(GetType), FId]);
end;

function TCraft.GetMarker: Integer;
begin
  if FStatus <> 'STR_OUT' then
    Result := -1
  else if FRules.Marker = -1 then
    Result := 1
  else
    Result := FRules.Marker;
end;

procedure TCraft.SetBase(Base: TBase; Move: Boolean);
begin
  FBase := Base;
  if Move then
  begin
    FLon := FBase.Longitude;
    FLat := FBase.Latitude;
  end;
end;

function TCraft.GetAltitude: string;
var
  u: TUfo;
begin
  u := FDest as TUfo;
  if (u <> nil) and (u.Altitude <> 'STR_GROUND') then
    Result := u.Altitude
  else
    Result := 'STR_VERY_LOW';
end;

procedure TCraft.SetDestination(Dest: TTarget);
begin
  if FStatus <> 'STR_OUT' then
    FTakeoff := 60;
  if Dest = nil then
    SetSpeed(FRules.MaxSpeed div 2)
  else
    SetSpeed(FRules.MaxSpeed);
  inherited SetDestination(Dest);
end;

function TCraft.GetNumWeapons: Integer;
begin
  Result := 0;
  for var w in FWeapons do
    if w <> nil then Inc(Result);
end;

function TCraft.GetNumSoldiers: Integer;
begin
  if FRules.Soldiers = 0 then Exit(0);
  Result := 0;
  for var s in FBase.Soldiers do
    if s.Craft = Self then Inc(Result);
end;

function TCraft.GetNumEquipment: Integer;
begin
  Result := FItems.GetTotalQuantity;
end;

function TCraft.GetNumVehicles: Integer;
begin
  Result := FVehicles.Count;
end;

procedure TCraft.SetFuel(Value: Integer);
begin
  FFuel := Value;
  if FFuel > FRules.MaxFuel then FFuel := FRules.MaxFuel;
  if FFuel < 0 then FFuel := 0;
end;

function TCraft.GetFuelPercentage: Integer;
begin
  Result := Round(FFuel / FRules.MaxFuel * 100);
end;

procedure TCraft.SetDamage(Value: Integer);
begin
  FDamage := Value;
  if FDamage < 0 then FDamage := 0;
end;

function TCraft.GetDamagePercentage: Integer;
begin
  Result := Round(FDamage / FRules.MaxDamage * 100);
end;

function TCraft.GetDistanceFromBase: Double;
begin
  Result := GetDistance(FBase);
end;

function TCraft.GetFuelConsumption: Integer;
begin
  Result := GetFuelConsumption(FSpeed);
end;

function TCraft.GetFuelConsumption(Speed: Integer): Integer;
begin
  if FRules.RefuelItem <> '' then
    Result := 1
  else
    Result := Speed div 100;
end;

function TCraft.GetFuelLimit: Integer;
begin
  Result := GetFuelLimit(FBase);
end;

function TCraft.GetFuelLimit(Base: TBase): Integer;
begin
  Result := Round(GetFuelConsumption(FRules.MaxSpeed) * GetDistance(Base) / FSpeedMaxRadian);
end;

function TCraft.GetBaseRange: Double;
begin
  Result := FFuel / 2.0 / GetFuelConsumption(FRules.MaxSpeed) * FSpeedMaxRadian;
end;

procedure TCraft.ReturnToBase;
begin
  SetDestination(FBase);
end;

function TCraft.Detect(Target: TTarget): Boolean;
begin
  if FRules.RadarRange = 0 then Exit(False);
  if not InsideRadarRange(Target) then Exit(False);
  if FRules.RadarChance = 100 then Exit(True);
  var u := Target as TUfo;
  var chance := FRules.RadarChance * (100 + u.Visibility) div 100;
  Result := RNG.Percent(chance);
end;

function TCraft.InsideRadarRange(Target: TTarget): Boolean;
begin
  Result := GetDistance(Target) <= Nautical(FRules.RadarRange);
end;

procedure TCraft.Think;
begin
  if FTakeoff = 0 then
    Move
  else
    Dec(FTakeoff);
  if ReachedDestination and (FDest = FBase) then
  begin
    FInterceptionOrder := 0;
    Checkup;
    SetDestination(nil);
    SetSpeed(0);
    FLowFuel := False;
    FMission := False;
    FTakeoff := 0;
  end;
end;

procedure TCraft.Checkup;
var
  available, full: Integer;
begin
  available := 0;
  full := 0;
  for var w in FWeapons do
  begin
    if w = nil then Continue;
    Inc(available);
    if w.Ammo >= w.Rules.AmmoMax then
      Inc(full)
    else
      w.IsRearming := True;
  end;
  if FDamage > 0 then
    FStatus := 'STR_REPAIRS'
  else if available <> full then
    FStatus := 'STR_REARMING'
  else
    FStatus := 'STR_REFUELLING';
end;

procedure TCraft.ConsumeFuel;
begin
  SetFuel(FFuel - GetFuelConsumption);
end;

procedure TCraft.Repair;
begin
  SetDamage(FDamage - FRules.RepairRate);
  if FDamage <= 0 then
    FStatus := 'STR_REARMING';
end;

function TCraft.Refuel: string;
var
  fuelItem: string;
begin
  if FFuel < FRules.MaxFuel then
  begin
    fuelItem := FRules.RefuelItem;
    if fuelItem = '' then
      SetFuel(FFuel + FRules.RefuelRate)
    else
    begin
      if FBase.StorageItems.GetItem(fuelItem) > 0 then
      begin
        FBase.StorageItems.RemoveItem(fuelItem);
        SetFuel(FFuel + FRules.RefuelRate);
        FLowFuel := False;
      end
      else if not FLowFuel then
      begin
        Result := fuelItem;
        if FFuel > 0 then
          FStatus := 'STR_READY'
        else
          FLowFuel := True;
      end;
    end;
  end;
  if FFuel >= FRules.MaxFuel then
  begin
    FStatus := 'STR_READY';
    for var w in FWeapons do
      if (w <> nil) and w.IsRearming then
      begin
        FStatus := 'STR_REARMING';
        Break;
      end;
  end;
end;

function TCraft.Rearm(Mod: TMod): string;
begin
  for var i := 0 to FWeapons.Count - 1 do
  begin
    var w := FWeapons[i];
    if (w <> nil) and w.IsRearming then
    begin
      var clip := w.Rules.ClipItem;
      var available := FBase.StorageItems.GetItem(clip);
      if clip = '' then
        w.Rearm(0, 0)
      else if available > 0 then
      begin
        var used := w.Rearm(available, Mod.GetItem(clip).ClipSize);
        if used = available then
          Result := clip;
        FBase.StorageItems.RemoveItem(clip, used);
      end
      else
      begin
        Result := clip;
        w.IsRearming := False;
      end;
      Break;
    end;
  end;
end;

function TCraft.IsDestroyed: Boolean;
begin
  Result := FDamage >= FRules.MaxDamage;
end;

function TCraft.GetSpaceAvailable: Integer;
begin
  Result := FRules.Soldiers - GetSpaceUsed;
end;

function TCraft.GetSpaceUsed: Integer;
var
  vehicleSpace: Integer;
begin
  vehicleSpace := 0;
  for var v in FVehicles do
    vehicleSpace := vehicleSpace + v.Size;
  Result := GetNumSoldiers + vehicleSpace;
end;

function TCraft.GetVehicleCount(const VehicleType: string): Integer;
begin
  Result := 0;
  for var v in FVehicles do
    if v.Rules.Type = VehicleType then Inc(Result);
end;

function TCraft.GetUniqueId: TCraftId;
begin
  Result.CraftType := FRules.Type;
  Result.Id := FId;
end;

procedure TCraft.Unload(Mod: TMod);
begin
  // Unload weapons, items, vehicles, soldiers
end;

procedure TCraft.ReuseItem(const Item: string);
begin
  // Check if this item can be used
end;

end.