unit UnitTurnBState;

interface

uses
  BattleState, BattlescapeGame, Savegame.BattleUnit, Savegame.SavedBattleGame,
  Mod.Mod, Engine.Sound, Engine.Options, TileEngine, Map;

type
  TUnitTurnBState = class(TBattleState)
  private
    FUnit: TBattleUnit;
    FTurret: Boolean;
    FChargeTUs: Boolean;
  public
    constructor Create(Parent: TBattlescapeGame; Action: TBattleAction; ChargeTUs: Boolean = True);
    destructor Destroy; override;
    procedure Init; override;
    procedure Cancel; override;
    procedure Think; override;
  end;

implementation

constructor TUnitTurnBState.Create(Parent: TBattlescapeGame; Action: TBattleAction; ChargeTUs: Boolean = True);
begin
  inherited Create(Parent, Action);
  FUnit := nil;
  FTurret := False;
  FChargeTUs := ChargeTUs;
end;

destructor TUnitTurnBState.Destroy;
begin
  inherited;
end;

procedure TUnitTurnBState.Init;
begin
  FUnit := FAction.Actor;
  if FUnit.IsOut then
  begin
    FParent.PopState;
    Exit;
  end;
  FAction.TU := 0;
  if FUnit.GetFaction = FACTION_PLAYER then
    FParent.SetStateInterval(Options.battleXcomSpeed)
  else
    FParent.SetStateInterval(Options.battleAlienSpeed);

  FTurret := (FUnit.GetTurretType <> -1) and (FAction.Targeting or FAction.Strafe);

  FUnit.LookAt(FAction.Target, FTurret);

  if FChargeTUs and (FUnit.GetStatus <> STATUS_TURNING) then
  begin
    if FAction.Type_ = BA_NONE then
    begin
      var door := FParent.GetTileEngine.UnitOpensDoor(FUnit, True);
      if door = 0 then
        FParent.GetMod.GetSoundByDepth(FParent.GetDepth, Mod.DOOR_OPEN).Play(-1, FParent.GetMap.GetSoundAngle(FUnit.GetPosition))
      else if door = 1 then
        FParent.GetMod.GetSoundByDepth(FParent.GetDepth, Mod.SLIDING_DOOR_OPEN).Play(-1, FParent.GetMap.GetSoundAngle(FUnit.GetPosition))
      else if door = 4 then
        FAction.Result := 'STR_NOT_ENOUGH_TIME_UNITS';
    end;
    FParent.PopState;
  end;
end;

procedure TUnitTurnBState.Think;
var
  tu: Integer;
  unitSpotted: SizeInt;
begin
  tu := 0;
  if FChargeTUs then tu := 1;

  if FChargeTUs and (FUnit.GetFaction = FParent.GetSave.GetSide) and FParent.GetPanicHandled and
     (not FAction.Targeting) and (not FParent.CheckReservedTU(FUnit, tu)) then
  begin
    FUnit.AbortTurn;
    FParent.PopState;
    Exit;
  end;

  if FUnit.SpendTimeUnits(tu) then
  begin
    unitSpotted := FUnit.GetUnitsSpottedThisTurn.Count;
    FUnit.Turn(FTurret);
    FParent.GetTileEngine.CalculateFOV(FUnit);
    FUnit.SetCache(0);
    FParent.GetMap.CacheUnit(FUnit);
    if FChargeTUs and (FUnit.GetFaction = FParent.GetSave.GetSide) and FParent.GetPanicHandled and
       (FAction.Type_ = BA_NONE) and (FUnit.GetUnitsSpottedThisTurn.Count > unitSpotted) then
      FUnit.AbortTurn;
    if FUnit.GetStatus = STATUS_STANDING then
      FParent.PopState;
  end
  else if FParent.GetPanicHandled then
  begin
    FAction.Result := 'STR_NOT_ENOUGH_TIME_UNITS';
    FUnit.AbortTurn;
    FParent.PopState;
  end;
end;

procedure TUnitTurnBState.Cancel;
begin
  // cannot cancel
end;

end.