unit RuleCraftWeapon;

interface

uses
  System.Classes, System.SysUtils,
  Yaml, ModUnit, Savegame.CraftWeaponProjectile;

type
  TCraftWeaponProjectileType = (cwptCannonRound, cwptMissile, cwptLaser, cwptPlasma, cwptStingray);

  TRuleCraftWeapon = class
  private
    FType: string;
    FSprite: Integer;
    FSound: Integer;
    FDamage: Integer;
    FRange: Integer;
    FAccuracy: Integer;
    FReloadCautious: Integer;
    FReloadStandard: Integer;
    FReloadAggressive: Integer;
    FAmmoMax: Integer;
    FRearmRate: Integer;
    FProjectileSpeed: Integer;
    FProjectileType: TCraftWeaponProjectileType;
    FLauncher: string;
    FClip: string;
    FUnderwaterOnly: Boolean;
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode; ModObj: TMod);
    function GetType: string;
    function GetSprite: Integer;
    function GetSound: Integer;
    function GetDamage: Integer;
    function GetRange: Integer;
    function GetAccuracy: Integer;
    function GetCautiousReload: Integer;
    function GetStandardReload: Integer;
    function GetAggressiveReload: Integer;
    function GetAmmoMax: Integer;
    function GetRearmRate: Integer;
    function GetLauncherItem: string;
    function GetClipItem: string;
    function GetProjectileType: TCraftWeaponProjectileType;
    function GetProjectileSpeed: Integer;
    function IsWaterOnly: Boolean;
  end;

implementation

{ TRuleCraftWeapon }

constructor TRuleCraftWeapon.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FSprite := -1;
  FSound := -1;
  FDamage := 0;
  FRange := 0;
  FAccuracy := 0;
  FReloadCautious := 0;
  FReloadStandard := 0;
  FReloadAggressive := 0;
  FAmmoMax := 0;
  FRearmRate := 1;
  FProjectileSpeed := 0;
  FProjectileType := cwptCannonRound;
  FUnderwaterOnly := False;
end;

destructor TRuleCraftWeapon.Destroy;
begin
  inherited;
end;

procedure TRuleCraftWeapon.Load(const Node: TYamlNode; ModObj: TMod);
begin
  FType := Node['type'].AsString(FType);
  if Node.Has('sprite') then
    FSprite := ModObj.GetOffset(Node['sprite'].AsInteger(FSprite), 5);
  ModObj.LoadSoundOffset(FType, FSound, Node['sound'], 'GEO.CAT');
  FDamage := Node['damage'].AsInteger(FDamage);
  FRange := Node['range'].AsInteger(FRange);
  FAccuracy := Node['accuracy'].AsInteger(FAccuracy);
  FReloadCautious := Node['reloadCautious'].AsInteger(FReloadCautious);
  FReloadStandard := Node['reloadStandard'].AsInteger(FReloadStandard);
  FReloadAggressive := Node['reloadAggressive'].AsInteger(FReloadAggressive);
  FAmmoMax := Node['ammoMax'].AsInteger(FAmmoMax);
  FRearmRate := Node['rearmRate'].AsInteger(FRearmRate);
  FProjectileType := TCraftWeaponProjectileType(Node['projectileType'].AsInteger(Integer(FProjectileType)));
  FProjectileSpeed := Node['projectileSpeed'].AsInteger(FProjectileSpeed);
  FLauncher := Node['launcher'].AsString(FLauncher);
  FClip := Node['clip'].AsString(FClip);
  FUnderwaterOnly := Node['underwaterOnly'].AsBoolean(FUnderwaterOnly);
end;

function TRuleCraftWeapon.GetType: string;
begin
  Result := FType;
end;

function TRuleCraftWeapon.GetSprite: Integer;
begin
  Result := FSprite;
end;

function TRuleCraftWeapon.GetSound: Integer;
begin
  Result := FSound;
end;

function TRuleCraftWeapon.GetDamage: Integer;
begin
  Result := FDamage;
end;

function TRuleCraftWeapon.GetRange: Integer;
begin
  Result := FRange;
end;

function TRuleCraftWeapon.GetAccuracy: Integer;
begin
  Result := FAccuracy;
end;

function TRuleCraftWeapon.GetCautiousReload: Integer;
begin
  Result := FReloadCautious;
end;

function TRuleCraftWeapon.GetStandardReload: Integer;
begin
  Result := FReloadStandard;
end;

function TRuleCraftWeapon.GetAggressiveReload: Integer;
begin
  Result := FReloadAggressive;
end;

function TRuleCraftWeapon.GetAmmoMax: Integer;
begin
  Result := FAmmoMax;
end;

function TRuleCraftWeapon.GetRearmRate: Integer;
begin
  Result := FRearmRate;
end;

function TRuleCraftWeapon.GetLauncherItem: string;
begin
  Result := FLauncher;
end;

function TRuleCraftWeapon.GetClipItem: string;
begin
  Result := FClip;
end;

function TRuleCraftWeapon.GetProjectileType: TCraftWeaponProjectileType;
begin
  Result := FProjectileType;
end;

function TRuleCraftWeapon.GetProjectileSpeed: Integer;
begin
  Result := FProjectileSpeed;
end;

function TRuleCraftWeapon.IsWaterOnly: Boolean;
begin
  Result := FUnderwaterOnly;
end;

end.