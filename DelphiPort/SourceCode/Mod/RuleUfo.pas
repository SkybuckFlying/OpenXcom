unit RuleUfo;

interface

uses
  System.Classes, System.SysUtils,
  Yaml, RuleTerrain, ModUnit;

type
  TRuleUfo = class
  private
    FType: string;
    FSize: string;
    FSprite: Integer;
    FMarker: Integer;
    FMarkerLand: Integer;
    FMarkerCrash: Integer;
    FDamageMax: Integer;
    FSpeedMax: Integer;
    FPower: Integer;
    FRange: Integer;
    FScore: Integer;
    FReload: Integer;
    FBreakOffTime: Integer;
    FSightRange: Integer;
    FMissionScore: Integer;
    FBattlescapeTerrainData: TRuleTerrain;
    FModSprite: string;
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode; ModObj: TMod);
    function GetType: string;
    function GetSize: string;
    function GetRadius: Integer;
    function GetSprite: Integer;
    function GetMarker: Integer;
    function GetLandMarker: Integer;
    function GetCrashMarker: Integer;
    function GetMaxDamage: Integer;
    function GetMaxSpeed: Integer;
    function GetWeaponPower: Integer;
    function GetWeaponRange: Integer;
    function GetScore: Integer;
    function GetBattlescapeTerrainData: TRuleTerrain;
    function GetWeaponReload: Integer;
    function GetBreakOffTime: Integer;
    function GetModSprite: string;
    function GetSightRange: Integer;
    function GetMissionScore: Integer;
  end;

implementation

{ TRuleUfo }

constructor TRuleUfo.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FSize := 'STR_VERY_SMALL';
  FSprite := -1; FMarker := -1; FMarkerLand := -1; FMarkerCrash := -1;
  FDamageMax := 0; FSpeedMax := 0; FPower := 0; FRange := 0; FScore := 0;
  FReload := 0; FBreakOffTime := 0; FSightRange := 268; FMissionScore := 1;
end;

destructor TRuleUfo.Destroy;
begin
  FBattlescapeTerrainData.Free;
  inherited;
end;

procedure TRuleUfo.Load(const Node: TYamlNode; ModObj: TMod);
begin
  FType := Node['type'].AsString(FType);
  FSize := Node['size'].AsString(FSize);
  FSprite := Node['sprite'].AsInteger(FSprite);
  if Node.Has('marker') then
    FMarker := ModObj.GetOffset(Node['marker'].AsInteger(FMarker), 8);
  if Node.Has('markerLand') then
    FMarkerLand := ModObj.GetOffset(Node['markerLand'].AsInteger(FMarkerLand), 8);
  if Node.Has('markerCrash') then
    FMarkerCrash := ModObj.GetOffset(Node['markerCrash'].AsInteger(FMarkerCrash), 8);
  FDamageMax := Node['damageMax'].AsInteger(FDamageMax);
  FSpeedMax := Node['speedMax'].AsInteger(FSpeedMax);
  FPower := Node['power'].AsInteger(FPower);
  FRange := Node['range'].AsInteger(FRange);
  FScore := Node['score'].AsInteger(FScore);
  FReload := Node['reload'].AsInteger(FReload);
  FBreakOffTime := Node['breakOffTime'].AsInteger(FBreakOffTime);
  FSightRange := Node['sightRange'].AsInteger(FSightRange);
  FMissionScore := Node['missionScore'].AsInteger(FMissionScore);
  var terrNode := Node['battlescapeTerrainData'];
  if not terrNode.IsNull then
  begin
    FBattlescapeTerrainData := TRuleTerrain.Create(terrNode['name'].AsString);
    FBattlescapeTerrainData.Load(terrNode, ModObj);
  end;
  FModSprite := Node['modSprite'].AsString(FModSprite);
end;

function TRuleUfo.GetType: string;
begin
  Result := FType;
end;

function TRuleUfo.GetSize: string;
begin
  Result := FSize;
end;

function TRuleUfo.GetRadius: Integer;
begin
  if FSize = 'STR_VERY_SMALL' then Result := 2
  else if FSize = 'STR_SMALL' then Result := 3
  else if FSize = 'STR_MEDIUM_UC' then Result := 4
  else if FSize = 'STR_LARGE' then Result := 5
  else if FSize = 'STR_VERY_LARGE' then Result := 6
  else Result := 0;
end;

// Other getters
function TRuleUfo.GetSprite: Integer; begin Result := FSprite; end;
function TRuleUfo.GetMarker: Integer; begin Result := FMarker; end;
function TRuleUfo.GetLandMarker: Integer; begin Result := FMarkerLand; end;
function TRuleUfo.GetCrashMarker: Integer; begin Result := FMarkerCrash; end;
function TRuleUfo.GetMaxDamage: Integer; begin Result := FDamageMax; end;
function TRuleUfo.GetMaxSpeed: Integer; begin Result := FSpeedMax; end;
function TRuleUfo.GetWeaponPower: Integer; begin Result := FPower; end;
function TRuleUfo.GetWeaponRange: Integer; begin Result := FRange; end;
function TRuleUfo.GetScore: Integer; begin Result := FScore; end;
function TRuleUfo.GetBattlescapeTerrainData: TRuleTerrain; begin Result := FBattlescapeTerrainData; end;
function TRuleUfo.GetWeaponReload: Integer; begin Result := FReload; end;
function TRuleUfo.GetBreakOffTime: Integer; begin Result := FBreakOffTime; end;
function TRuleUfo.GetModSprite: string; begin Result := FModSprite; end;
function TRuleUfo.GetSightRange: Integer; begin Result := FSightRange; end;
function TRuleUfo.GetMissionScore: Integer; begin Result := FMissionScore; end;

end.