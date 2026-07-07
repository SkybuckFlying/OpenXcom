unit UnitPanicBState;

interface

uses
  Classes, SysUtils,
  Battlescape.BattleState,
  Battlescape.BattlescapeGame,
  Savegame.BattleUnit;

type
  TUnitPanicBState = class(TBattleState)
  private
    FUnit: TBattleUnit;
    FBerserking: Boolean;
    FShotsFired: Integer;
  public
    constructor Create(Parent: TBattlescapeGame; Unit: TBattleUnit);
    destructor Destroy; override;
    procedure Init; override;
    procedure Cancel; override;
    procedure Think; override;
  end;

implementation

uses
  Engine.RNG,
  Engine.Options,
  Battlescape.UnitTurnBState,
  Battlescape.ProjectileFlyBState,
  Battlescape.TileEngine,
  Mod.Mod,
  Mod.RuleItem;

{ TUnitPanicBState }

constructor TUnitPanicBState.Create(Parent: TBattlescapeGame; Unit: TBattleUnit);
begin
  inherited Create(Parent);
  FUnit := Unit;
  FShotsFired := 0;
  FBerserking := Unit.Status = STATUS_BERSERK;
  Unit.AbortTurn;
end;

destructor TUnitPanicBState.Destroy;
begin
  inherited;
end;

procedure TUnitPanicBState.Init;
begin
  // nothing
end;

procedure TUnitPanicBState.Think;
var
  Ba: TBattleAction;
  TurnCost: Integer;
begin
  if Assigned(FUnit) then
  begin
    if not FUnit.IsOut and (FShotsFired < 10) and FBerserking then
    begin
      Inc(FShotsFired);
      FillChar(Ba, SizeOf(Ba), 0);
      Ba.Actor := FUnit;
      Ba.Weapon := FUnit.GetMainHandWeapon;
      if Assigned(Ba.Weapon) and ((Ba.Weapon.Rules.TUSnap > 0) or (Ba.Weapon.Rules.TUAuto > 0)) and
         FParent.Save.IsItemUsable(Ba.Weapon) then
      begin
        if Ba.Weapon.Rules.TUAuto > 0 then Ba.Type_ := BA_AUTOSHOT
        else Ba.Type_ := BA_SNAPSHOT;
        Ba.TU := FUnit.GetActionTUs(Ba.Type_, Ba.Weapon);

        if FUnit.TimeUnits >= Ba.TU then
        begin
          if FUnit.VisibleUnits.Count > 0 then
          begin
            // target closest visible unit
            // (implementation of closest)
          end
          else
            Ba.Target := TPosition.Create(FUnit.Position.X + RNG.Generate(-6,6), FUnit.Position.Y + RNG.Generate(-6,6), FUnit.Position.Z);

          TurnCost := Abs(FUnit.Direction - FUnit.DirectionTo(Ba.Target));
          if TurnCost > 4 then TurnCost := 8 - TurnCost;
          FParent.StatePushFront(TUnitTurnBState.Create(FParent, Ba, False));
          if FUnit.SpendTimeUnits(Ba.TU + TurnCost) then
            FParent.StatePushNext(TProjectileFlyBState.Create(FParent, Ba))
          else
            FUnit.SpendTimeUnits(TurnCost);
        end;
      end;
      Exit;
    end;

    if not FUnit.IsOut then
      FUnit.AbortTurn;
    FUnit.SetTimeUnits(0);
  end;
  FParent.PopState;
  FParent.SetupCursor;
end;

procedure TUnitPanicBState.Cancel;
begin
  // no cancel
end;

end.