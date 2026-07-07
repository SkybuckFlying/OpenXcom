unit RuleCraft;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, RuleTerrain, ModUnit;

type
  TRuleCraft = class
  private
    FType: string;
    FRequires: TArray<string>;
    FSprite: Integer;
    FMarker: Integer;
    FFuelMax: Integer;
    FDamageMax: Integer;
    FSpeedMax: Integer;
    FAccel: Integer;
    FWeapons: Integer;
    FSoldiers: Integer;
    FVehicles: Integer;
    FCostBuy: Integer;
    FCostRent: Integer;
    FCostSell: Integer;
    FRefuelItem: string;
    FRepairRate: Integer;
    FRefuelRate: Integer;
    FRadarRange: Integer;
    FRadarChance: Integer;
    FSightRange: Integer;
    FTransferTime: Integer;
    FScore: Integer;
    FBattlescapeTerrainData: TRuleTerrain;
    FSpacecraft: Boolean;
    FListOrder: Integer;
    FMaxItems: Integer;
    FMaxAltitude: Integer;
    FDeployment: TArray<TArray<Integer>>;
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode; ModObj: TMod; AListOrder: Integer);
    function GetType: string;
    function GetRequirements: TArray<string>;
    function GetSprite: Integer;
    function GetMarker: Integer;
    function GetMaxFuel: Integer;
    function GetMaxDamage: Integer;
    function GetMaxSpeed: Integer;
    function GetAcceleration: Integer;
    function GetWeapons: Integer;
    function GetSoldiers: Integer;
    function GetVehicles: Integer;
    function GetBuyCost: Integer;
    function GetRentCost: Integer;
    function GetSellCost: Integer;
    function GetRefuelItem: string;
    function GetRepairRate: Integer;
    function GetRefuelRate: Integer;
    function GetRadarRange: Integer;
    function GetRadarChance: Integer;
    function GetSightRange: Integer;
    function GetTransferTime: Integer;
    function GetScore: Integer;
    function GetBattlescapeTerrainData: TRuleTerrain;
    function GetSpacecraft: Boolean;
    function GetListOrder: Integer;
    function GetDeployment: TArray<TArray<Integer>>;
    function GetMaxItems: Integer;
    function GetMaxAltitude: Integer;
    function IsWaterOnly: Boolean;
  end;

implementation

{ TRuleCraft }

constructor TRuleCraft.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FSprite := -1;
  FMarker := -1;
  FFuelMax := 0;
  FDamageMax := 0;
  FSpeedMax := 0;
  FAccel := 0;
  FWeapons := 0;
  FSoldiers := 0;
  FVehicles := 0;
  FCostBuy := 0;
  FCostRent := 0;
  FCostSell := 0;
  FRepairRate := 1;
  FRefuelRate := 1;
  FRadarRange := 672;
  FRadarChance := 100;
  FSightRange := 1696;
  FTransferTime := 0;
  FScore := 0;
  FSpacecraft := False;
  FListOrder := 0;
  FMaxItems := 0;
  FMaxAltitude := -1;
end;

destructor TRuleCraft.Destroy;
begin
  FBattlescapeTerrainData.Free;
  inherited;
end;

procedure TRuleCraft.Load(const Node: TYamlNode; ModObj: TMod; AListOrder: Integer);
begin
  FType := Node['type'].AsString(FType);
  FRequires := Node['requires'].AsArray<string>(FRequires);
  if Node.Has('sprite') then
    FSprite := ModObj.GetOffset(Node['sprite'].AsInteger(FSprite), 4);
  if Node.Has('marker') then
    FMarker := ModObj.GetOffset(Node['marker'].AsInteger(FMarker), 8);
  FFuelMax := Node['fuelMax'].AsInteger(FFuelMax);
  FDamageMax := Node['damageMax'].AsInteger(FDamageMax);
  FSpeedMax := Node['speedMax'].AsInteger(FSpeedMax);
  FAccel := Node['accel'].AsInteger(FAccel);
  FWeapons := Node['weapons'].AsInteger(FWeapons);
  FSoldiers := Node['soldiers'].AsInteger(FSoldiers);
  FVehicles := Node['vehicles'].AsInteger(FVehicles);
  FCostBuy := Node['costBuy'].AsInteger(FCostBuy);
  FCostRent := Node['costRent'].AsInteger(FCostRent);
  FCostSell := Node['costSell'].AsInteger(FCostSell);
  FRefuelItem := Node['refuelItem'].AsString(FRefuelItem);
  FRepairRate := Node['repairRate'].AsInteger(FRepairRate);
  FRefuelRate := Node['refuelRate'].AsInteger(FRefuelRate);
  FRadarRange := Node['radarRange'].AsInteger(FRadarRange);
  FRadarChance := Node['radarChance'].AsInteger(FRadarChance);
  FSightRange := Node['sightRange'].AsInteger(FSightRange);
  FTransferTime := Node['transferTime'].AsInteger(FTransferTime);
  FScore := Node['score'].AsInteger(FScore);
  var terrNode := Node['battlescapeTerrainData'];
  if not terrNode.IsNull then
  begin
    FBattlescapeTerrainData := TRuleTerrain.Create(terrNode['name'].AsString);
    FBattlescapeTerrainData.Load(terrNode, ModObj);
  end;
  FDeployment := Node['deployment'].AsArray<TArray<Integer>>(FDeployment);
  FSpacecraft := Node['spacecraft'].AsBoolean(FSpacecraft);
  FListOrder := Node['listOrder'].AsInteger(FListOrder);
  if FListOrder = 0 then FListOrder := AListOrder;
  FMaxAltitude := Node['maxAltitude'].AsInteger(FMaxAltitude);
  FMaxItems := Node['maxItems'].AsInteger(FMaxItems);
end;

// Getters
function TRuleCraft.GetType: string;
begin
  Result := FType;
end;

function TRuleCraft.GetRequirements: TArray<string>;
begin
  Result := FRequires;
end;

function TRuleCraft.GetSprite: Integer;
begin
  Result := FSprite;
end;

function TRuleCraft.GetMarker: Integer;
begin
  Result := FMarker;
end;

function TRuleCraft.GetMaxFuel: Integer;
begin
  Result := FFuelMax;
end;

function TRuleCraft.GetMaxDamage: Integer;
begin
  Result := FDamageMax;
end;

function TRuleCraft.GetMaxSpeed: Integer;
begin
  Result := FSpeedMax;
end;

function TRuleCraft.GetAcceleration: Integer;
begin
  Result := FAccel;
end;

function TRuleCraft.GetWeapons: Integer;
begin
  Result := FWeapons;
end;

function TRuleCraft.GetSoldiers: Integer;
begin
  Result := FSoldiers;
end;

function TRuleCraft.GetVehicles: Integer;
begin
  Result := FVehicles;
end;

function TRuleCraft.GetBuyCost: Integer;
begin
  Result := FCostBuy;
end;

function TRuleCraft.GetRentCost: Integer;
begin
  Result := FCostRent;
end;

function TRuleCraft.GetSellCost: Integer;
begin
  Result := FCostSell;
end;

function TRuleCraft.GetRefuelItem: string;
begin
  Result := FRefuelItem;
end;

function TRuleCraft.GetRepairRate: Integer;
begin
  Result := FRepairRate;
end;

function TRuleCraft.GetRefuelRate: Integer;
begin
  Result := FRefuelRate;
end;

function TRuleCraft.GetRadarRange: Integer;
begin
  Result := FRadarRange;
end;

function TRuleCraft.GetRadarChance: Integer;
begin
  Result := FRadarChance;
end;

function TRuleCraft.GetSightRange: Integer;
begin
  Result := FSightRange;
end;

function TRuleCraft.GetTransferTime: Integer;
begin
  Result := FTransferTime;
end;

function TRuleCraft.GetScore: Integer;
begin
  Result := FScore;
end;

function TRuleCraft.GetBattlescapeTerrainData: TRuleTerrain;
begin
  Result := FBattlescapeTerrainData;
end;

function TRuleCraft.GetSpacecraft: Boolean;
begin
  Result := FSpacecraft;
end;

function TRuleCraft.GetListOrder: Integer;
begin
  Result := FListOrder;
end;

function TRuleCraft.GetDeployment: TArray<TArray<Integer>>;
begin
  Result := FDeployment;
end;

function TRuleCraft.GetMaxItems: Integer;
begin
  Result := FMaxItems;
end;

function TRuleCraft.GetMaxAltitude: Integer;
begin
  Result := FMaxAltitude;
end;

function TRuleCraft.IsWaterOnly: Boolean;
begin
  Result := FMaxAltitude > -1;
end;

end.