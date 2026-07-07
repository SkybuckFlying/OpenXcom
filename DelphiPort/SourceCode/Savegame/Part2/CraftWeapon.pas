unit CraftWeapon;

interface

uses
  Classes, SysUtils, YAML, RuleCraftWeapon, Mod, CraftWeaponProjectile;

type
  TCraftWeapon = class
  private
    FRules: TRuleCraftWeapon;
    FAmmo: Integer;
    FRearming: Boolean;
  public
    constructor Create(Rules: TRuleCraftWeapon; Ammo: Integer);
    procedure Load(const Node: TYamlNode);
    function Save: TYamlNode;
    property Rules: TRuleCraftWeapon read FRules;
    property Ammo: Integer read FAmmo write SetAmmo;
    function SetAmmo(Value: Integer): Boolean;
    property Rearming: Boolean read FRearming write FRearming;
    function Rearm(Available, ClipSize: Integer): Integer;
    function Fire: TCraftWeaponProjectile;
    function GetClipsLoaded(Mod: TMod): Integer;
  end;

implementation

uses
  Math, RuleItem;

constructor TCraftWeapon.Create(Rules: TRuleCraftWeapon; Ammo: Integer);
begin
  FRules := Rules;
  FAmmo := Ammo;
  FRearming := False;
end;

procedure TCraftWeapon.Load(const Node: TYamlNode);
begin
  FAmmo := Node['ammo'].AsInteger(FAmmo);
  FRearming := Node['rearming'].AsBoolean(FRearming);
end;

function TCraftWeapon.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['type'] := FRules.Type;
  Result['ammo'] := FAmmo;
  if FRearming then Result['rearming'] := FRearming;
end;

function TCraftWeapon.SetAmmo(Value: Integer): Boolean;
begin
  FAmmo := Value;
  if FAmmo < 0 then FAmmo := 0;
  if FAmmo > FRules.AmmoMax then FAmmo := FRules.AmmoMax;
  Result := FAmmo > 0;
end;

function TCraftWeapon.Rearm(Available, ClipSize: Integer): Integer;
var
  needed, used: Integer;
begin
  if ClipSize > 0 then
  begin
    needed := (Min(FRules.RearmRate, FRules.AmmoMax - FAmmo + ClipSize - 1) div ClipSize);
    used := Min(needed, Available) * ClipSize;
  end
  else
  begin
    used := FRules.RearmRate;
  end;
  SetAmmo(FAmmo + used);
  FRearming := FAmmo < FRules.AmmoMax;
  Result := IfThen(ClipSize <= 0, 0, used div ClipSize);
end;

function TCraftWeapon.Fire: TCraftWeaponProjectile;
begin
  Result := TCraftWeaponProjectile.Create;
  Result.ProjectileType := FRules.ProjectileType;
  Result.Speed := FRules.ProjectileSpeed;
  Result.Accuracy := FRules.Accuracy;
  Result.Damage := FRules.Damage;
  Result.Range := FRules.Range;
end;

function TCraftWeapon.GetClipsLoaded(Mod: TMod): Integer;
var
  clip: TRuleItem;
begin
  Result := FAmmo div FRules.RearmRate;
  clip := Mod.GetItem(FRules.ClipItem);
  if (clip <> nil) and (clip.ClipSize > 0) then
    Result := FAmmo div clip.ClipSize;
end;

end.