unit PsiAttackBState;

interface

uses
  Classes, SysUtils,
  Battlescape.BattleState,
  Battlescape.BattlescapeGame,
  Battlescape.Position,
  Savegame.BattleUnit,
  Savegame.BattleItem;

type
  TPsiAttackBState = class(TBattleState)
  private
    FUnit: TBattleUnit;
    FTarget: TBattleUnit;
    FItem: TBattleItem;
    FInitialized: Boolean;
    procedure PsiAttack;
  public
    constructor Create(Parent: TBattlescapeGame; Action: TBattleAction);
    destructor Destroy; override;
    procedure Init; override;
    procedure Think; override;
  end;

implementation

uses
  Engine.RNG,
  Engine.Sound,
  Engine.Options,
  Mod.Mod,
  Mod.RuleItem,
  Savegame.SavedGame,
  Savegame.SavedBattleGame,
  Savegame.Tile,
  Battlescape.ExplosionBState,
  Battlescape.TileEngine,
  Battlescape.Map,
  Battlescape.Camera,
  Battlescape.InfoboxState,
  Battlescape.BattlescapeState,
  Battlescape.BattlescapeGame,
  Savegame.BattleUnitStatistics;

{ TPsiAttackBState }

constructor TPsiAttackBState.Create(Parent: TBattlescapeGame; Action: TBattleAction);
begin
  inherited Create(Parent, Action);
  FUnit := nil;
  FTarget := nil;
  FItem := nil;
  FInitialized := False;
end;

destructor TPsiAttackBState.Destroy;
begin
  inherited;
end;

procedure TPsiAttackBState.Init;
var
  Height: Integer;
  Voxel: TPosition;
begin
  if FInitialized then Exit;
  FInitialized := True;

  FItem := FAction.Weapon;
  FUnit := FAction.Actor;

  if FParent.Save.GetTile(FAction.Target) = nil then
  begin
    FParent.PopState;
    Exit;
  end;

  if FUnit.TimeUnits < FAction.TU then
  begin
    FAction.Result := 'STR_NOT_ENOUGH_TIME_UNITS';
    FParent.PopState;
    Exit;
  end;

  FTarget := FParent.Save.GetTile(FAction.Target).Unit;
  if FTarget = nil then
  begin
    FParent.PopState;
    Exit;
  end;

  if FItem = nil then
  begin
    FParent.PopState;
    Exit;
  end
  else if FItem.Rules.HitSound <> -1 then
    FParent.Mod.GetSoundByDepth(FParent.Depth, FItem.Rules.HitSound).Play(-1, FParent.Map.GetSoundAngle(FAction.Target));

  Height := FTarget.FloatHeight + (FTarget.Height div 2) - FParent.Save.GetTile(FAction.Target).TerrainLevel;
  Voxel := FAction.Target * TPosition.Create(16,16,24) + TPosition.Create(8,8,Height);
  FParent.StatePushFront(TExplosionBState.Create(FParent, Voxel, FItem, FUnit, 0, False, True));
end;

procedure TPsiAttackBState.Think;
begin
  PsiAttack;
  if FAction.CameraPosition.Z <> -1 then
  begin
    FParent.Map.Camera.SetMapOffset(FAction.CameraPosition);
    FParent.Map.Invalidate;
  end;
  if (FParent.Save.Side = FACTION_PLAYER) or FParent.Save.DebugMode then
    FParent.SetupCursor;
  FParent.PopState;
end;

procedure TPsiAttackBState.PsiAttack;
var
  AttackStrength, DefenseStrength: Double;
  Dist: Integer;
  Game: TGame;
  KillStat: TBattleUnitKills;
begin
  AttackStrength := FUnit.BaseStats.PsiStrength * FUnit.BaseStats.PsiSkill / 50.0;
  DefenseStrength := FTarget.BaseStats.PsiStrength +
                     IfThen(FTarget.BaseStats.PsiSkill > 0, 10.0 + FTarget.BaseStats.PsiSkill / 5.0, 10.0);
  Dist := FParent.TileEngine.Distance(FUnit.Position, FAction.Target);
  AttackStrength := AttackStrength - Dist + RNG.Generate(0,55);

  if FAction.Type_ = BA_MINDCONTROL then
    DefenseStrength := DefenseStrength + 20;

  FUnit.AddPsiSkillExp;
  if Options.AllowPsiStrengthImprovement then
    FTarget.AddPsiStrengthExp;

  if AttackStrength > DefenseStrength then
  begin
    Game := FParent.Save.BattleState.Game;
    FAction.Actor.AddPsiSkillExp;
    FAction.Actor.AddPsiSkillExp;

    KillStat := TBattleUnitKills.Create;
    KillStat.SetUnitStats(FTarget);
    KillStat.Turn := FParent.Save.Turn;
    KillStat.Side := FParent.Save.Side;
    KillStat.Weapon := FAction.Weapon.Rules.Name;
    KillStat.WeaponAmmo := FAction.Weapon.Rules.Name;
    KillStat.Faction := FTarget.Faction;
    KillStat.Mission := FParent.Save.GeoscapeSave.MissionStatistics.Count;
    KillStat.Id := FTarget.Id;

    if FAction.Type_ = BA_PANIC then
    begin
      FTarget.MoraleChange(-Max(0, (110 - FTarget.BaseStats.Bravery)));
      FTarget.SetMindControllerId(FUnit.Id);
      if not FUnit.Statistics.DuplicateEntry(STATUS_PANICKING, FTarget.Id) then
      begin
        KillStat.Status := STATUS_PANICKING;
        FUnit.Statistics.Kills.Add(KillStat);
      end;
      if FParent.Save.Side = FACTION_PLAYER then
        Game.PushState(TInfoboxState.Create(Game.Language.GetString('STR_MORALE_ATTACK_SUCCESSFUL')));
    end
    else if FAction.Type_ = BA_MINDCONTROL then
    begin
      if not FUnit.Statistics.DuplicateEntry(STATUS_TURNING, FTarget.Id) then
      begin
        KillStat.Status := STATUS_TURNING;
        FUnit.Statistics.Kills.Add(KillStat);
      end;
      FTarget.SetMindControllerId(FUnit.Id);
      FTarget.ConvertToFaction(FUnit.Faction);
      FParent.TileEngine.CalculateFOV(FTarget.Position);
      FParent.TileEngine.CalculateUnitLighting;
      FTarget.RecoverTimeUnits;
      FTarget.AllowReselect;
      FTarget.AbortTurn;
      if FParent.Save.Side = FACTION_PLAYER then
      begin
        if Options.AllowPsionicCapture then
          FParent.AutoEndBattle;
        Game.PushState(TInfoboxState.Create(Game.Language.GetString('STR_MIND_CONTROL_SUCCESSFUL')));
        FParent.Save.BattleState.UpdateSoldierInfo;
      end
      else
        Game.PushState(TInfoboxState.Create(Game.Language.GetString('STR_IS_UNDER_ALIEN_CONTROL', FTarget.Gender).Replace('%s', FTarget.Name(Game.Language))));
    end;
  end
  else
  begin
    if Options.AllowPsiStrengthImprovement then
      FTarget.AddPsiStrengthExp;
  end;
end;

end.