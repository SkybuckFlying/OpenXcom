unit CraftWeaponProjectile;

interface

type
  TCraftWeaponProjectileType = (CWPT_STINGRAY_MISSILE, CWPT_AVALANCHE_MISSILE,
    CWPT_CANNON_ROUND, CWPT_FUSION_BALL, CWPT_LASER_BEAM, CWPT_PLASMA_BEAM);
  TCraftWeaponProjectileGlobalType = (CWPGT_MISSILE, CWPGT_BEAM);
  TDirections = (D_NONE, D_UP, D_DOWN);

  TCraftWeaponProjectile = class
  private
    FType: TCraftWeaponProjectileType;
    FGlobalType: TCraftWeaponProjectileGlobalType;
    FSpeed: Integer;
    FDirection: TDirections;
    FCurrentPosition: Integer;
    FHorizontalPosition: Integer;
    FState: Integer;
    FAccuracy: Integer;
    FDamage: Integer;
    FRange: Integer;
    FToBeRemoved: Boolean;
    FMissed: Boolean;
    FDistanceCovered: Integer;
  public
    constructor Create;
    property ProjectileType: TCraftWeaponProjectileType read FType write FType;
    property GlobalType: TCraftWeaponProjectileGlobalType read FGlobalType;
    property Direction: TDirections read FDirection write FDirection;
    property Speed: Integer read FSpeed write FSpeed;
    procedure Move;
    property Position: Integer read FCurrentPosition write FCurrentPosition;
    property HorizontalPosition: Integer read FHorizontalPosition write FHorizontalPosition;
    procedure Remove;
    property ToBeRemoved: Boolean read FToBeRemoved;
    property State: Integer read FState;
    property Damage: Integer read FDamage write FDamage;
    property Accuracy: Integer read FAccuracy write FAccuracy;
    property Missed: Boolean read FMissed write FMissed;
    property Range: Integer read FRange write FRange;
  end;

implementation

constructor TCraftWeaponProjectile.Create;
begin
  FType := CWPT_CANNON_ROUND;
  FGlobalType := CWPGT_MISSILE;
  FSpeed := 0;
  FDirection := D_NONE;
  FCurrentPosition := 0;
  FHorizontalPosition := 0;
  FState := 0;
  FAccuracy := 0;
  FDamage := 0;
  FRange := 0;
  FToBeRemoved := False;
  FMissed := False;
  FDistanceCovered := 0;
  if FType >= CWPT_LASER_BEAM then
  begin
    FGlobalType := CWPGT_BEAM;
    FState := 8;
  end;
end;

procedure TCraftWeaponProjectile.Move;
begin
  if FGlobalType = CWPGT_MISSILE then
  begin
    var posChange := FSpeed;
    if ((FDistanceCovered div 8) < FRange) and (((FDistanceCovered + FSpeed) div 8) >= FRange) then
      posChange := FRange * 8 - FDistanceCovered;
    if (FDistanceCovered div 8) >= FRange then
      FMissed := True;
    if FDirection = D_UP then
      FCurrentPosition := FCurrentPosition + posChange
    else if FDirection = D_DOWN then
      FCurrentPosition := FCurrentPosition - posChange;
    FDistanceCovered := FDistanceCovered + posChange;
  end
  else if FGlobalType = CWPGT_BEAM then
  begin
    FState := FState div 2;
    if FState = 1 then
      FToBeRemoved := True;
  end;
end;

procedure TCraftWeaponProjectile.Remove;
begin
  FToBeRemoved := True;
end;

end.