unit BattlescapeGame;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Math, System.Classes,
  BattlescapeState, BattleState, UnitWalkBState, ProjectileFlyBState,
  MeleeAttackBState, PsiAttackBState, ExplosionBState, UnitDieBState,
  UnitPanicBState, UnitTurnBState, UnitFallBState,
  Savegame.SavedBattleGame, Savegame.BattleUnit, Savegame.BattleItem,
  Savegame.Tile, Savegame.SavedGame, Savegame.Node,
  TileEngine, Pathfinding, Map, Camera, AIModule,
  Mod.Mod, Mod.RuleItem, Mod.Armor, Mod.RuleInventory,
  Engine.Game, Engine.Language, Engine.Sound, Engine.Options, Engine.RNG,
  Engine.Logger, Engine.Timer, Interface.Cursor, Interface.Text,
  InfoboxState, InfoboxOKState, BattlescapeGenerator,
  fmath;

type
  TBattlescapeGame = class
  private
    FSave: TSavedBattleGame;
    FParentState: TBattlescapeState;
    FStates: TList<TBattleState>;
    FDeleted: TList<TBattleState>;
    FPlayerPanicHandled: Boolean;
    FAIActionCounter: Integer;
    FCurrentAction: TBattleAction;
    FAISecondMove: Boolean;
    FPlayedAggroSound: Boolean;
    FEndTurnRequested: Boolean;
    FEndTurnProcessed: Boolean;
    FInfoboxQueue: TList<TInfoboxOKState>;
    procedure EndTurn;
    function HandlePanickingPlayer: Boolean;
    function HandlePanickingUnit(AUnit: TBattleUnit): Boolean;
    function NoActionsPending(ABu: TBattleUnit): Boolean;
    procedure ShowInfoBoxQueue;
    procedure TallyUnits(var LiveAliens, LiveSoldiers: Integer);
    function ConvertInfected: Boolean;
    procedure AutoEndBattle;
  public
    class var DebugPlay: Boolean;
    constructor Create(ASave: TSavedBattleGame; AParent: TBattlescapeState);
    destructor Destroy; override;
    procedure Think;
    procedure Init;
    function PlayableUnitSelected: Boolean;
    procedure HandleState;
    procedure StatePushFront(BS: TBattleState);
    procedure StatePushNext(BS: TBattleState);
    procedure StatePushBack(BS: TBattleState);
    procedure HandleNonTargetAction;
    procedure PopState;
    procedure SetStateInterval(AInterval: Cardinal);
    procedure CheckForCasualties(MurderWeapon: TBattleItem; OrigMurderer: TBattleUnit;
                                HiddenExplosion: Boolean = False; TerrainExplosion: Boolean = False);
    function CheckReservedTU(Bu: TBattleUnit; TU: Integer; JustChecking: Boolean = False): Boolean;
    procedure HandleAI(AUnit: TBattleUnit);
    procedure DropItem(Position: TPosition; Item: TBattleItem; NewItem: Boolean = False; RemoveItem: Boolean = False);
    function ConvertUnit(AUnit: TBattleUnit): TBattleUnit;
    function Kneel(Bu: TBattleUnit): Boolean;
    function CancelCurrentAction(BForce: Boolean = False): Boolean;
    procedure CancelAllActions;
    function GetCurrentAction: PBattleAction;
    function IsBusy: Boolean;
    procedure PrimaryAction(Pos: TPosition);
    procedure SecondaryAction(Pos: TPosition);
    procedure LaunchAction;
    procedure PsiButtonAction;
    procedure MoveUpDown(AUnit: TBattleUnit; Dir: Integer);
    procedure RequestEndTurn;
    procedure SetTUReserved(Tur: TBattleActionType);
    procedure SetupCursor;
    function GetMap: TMap;
    function GetSave: TSavedBattleGame;
    function GetTileEngine: TTileEngine;
    function GetPathfinding: TPathfinding;
    function GetMod: TMod;
    function GetPanicHandled: Boolean;
    procedure FindItem(var Action: TBattleAction);
    function SurveyItems(var Action: TBattleAction): TBattleItem;
    function WorthTaking(AItem: TBattleItem; var Action: TBattleAction): Boolean;
    function TakeItemFromGround(AItem: TBattleItem; var Action: TBattleAction): Integer;
    function TakeItem(AItem: TBattleItem; var Action: TBattleAction): Boolean;
    function GetReservedAction: TBattleActionType;
    procedure TallyUnits(var LiveAliens, LiveSoldiers: Integer);
    function ConvertInfected: Boolean;
    procedure SetKneelReserved(Reserved: Boolean);
    function GetKneelReserved: Boolean;
    function CheckForProximityGrenades(AUnit: TBattleUnit): Boolean;
    procedure CleanupDeleted;
    function GetDepth: Integer;
    procedure MissionComplete;
    function GetStates: TList<TBattleState>;
    procedure AutoEndBattle;
  end;

implementation

uses
  BattlescapeState, UnitDieBState, UnitPanicBState, UnitTurnBState,
  UnitWalkBState, ProjectileFlyBState, MeleeAttackBState, PsiAttackBState,
  ExplosionBState, UnitFallBState, AIModule, BattlescapeGenerator,
  Savegame.BattleUnitStatistics, Mod.Mod, Engine.Sound, Engine.RNG,
  Engine.Options, Engine.Logger, Mod.RuleItem, Mod.Armor, Mod.RuleInventory,
  Savegame.BattleItem, Savegame.Tile, TileEngine, Pathfinding, Map, Camera,
  InfoboxState, InfoboxOKState, Engine.Game, Interface.Cursor,
  Savegame.SavedGame;

{ TBattlescapeGame }

constructor TBattlescapeGame.Create(ASave: TSavedBattleGame; AParent: TBattlescapeState);
begin
  inherited Create;
  FSave := ASave;
  FParentState := AParent;
  FStates := TList<TBattleState>.Create;
  FDeleted := TList<TBattleState>.Create;
  FInfoboxQueue := TList<TInfoboxOKState>.Create;
  FCurrentAction.Actor := nil;
  FCurrentAction.Targeting := False;
  FCurrentAction.aType := BA_NONE;
  FPlayerPanicHandled := True;
  FAIActionCounter := 0;
  FAISecondMove := False;
  FPlayedAggroSound := False;
  FEndTurnRequested := False;
  FEndTurnProcessed := False;
  DebugPlay := False;
  CheckForCasualties(nil, nil, True);
  CancelCurrentAction(False);
end;

destructor TBattlescapeGame.Destroy;
var
  BS: TBattleState;
begin
  for BS in FStates do
    BS.Free;
  FStates.Free;
  for BS in FDeleted do
    BS.Free;
  FDeleted.Free;
  FInfoboxQueue.Free;
  inherited;
end;

procedure TBattlescapeGame.Think;
begin
  if FStates.Count = 0 then
  begin
    if FSave.GetUnitsFalling then
    begin
      StatePushFront(TUnitFallBState.Create(Self));
      FSave.SetUnitsFalling(False);
      Exit;
    end;

    if FSave.GetSide <> FACTION_PLAYER then
    begin
      FSave.ResetUnitHitStates;
      if not DebugPlay then
      begin
        if FSave.GetSelectedUnit <> nil then
        begin
          if not HandlePanickingUnit(FSave.GetSelectedUnit) then
            HandleAI(FSave.GetSelectedUnit);
        end
        else
        begin
          if FSave.SelectNextPlayerUnit(True, FAISecondMove) = nil then
          begin
            if not FSave.GetDebugMode then
            begin
              FEndTurnRequested := True;
              StatePushBack(nil); // end AI turn
            end
            else
            begin
              FSave.SelectNextPlayerUnit;
              DebugPlay := True;
            end;
          end;
        end;
      end;
    end
    else
    begin
      if not FPlayerPanicHandled then
      begin
        FPlayerPanicHandled := HandlePanickingPlayer;
        FParentState.UpdateSoldierInfo;
      end;
    end;
  end;
end;

procedure TBattlescapeGame.Init;
begin
  if FSave.GetSide = FACTION_PLAYER then
    if FSave.GetTurn > 1 then
      FPlayerPanicHandled := False;
end;

procedure TBattlescapeGame.HandleAI(AUnit: TBattleUnit);
var
  AI: TAIModule;
  Action: TBattleAction;
  Weapon: TBattleItem;
  ss: TStringBuilder;
begin
  if AUnit.GetTimeUnits <= 5 then
    AUnit.DontReselect;

  if (FAIActionCounter >= 2) or (not AUnit.ReselectAllowed) then
  begin
    if FSave.SelectNextPlayerUnit(True, FAISecondMove) = nil then
    begin
      if not FSave.GetDebugMode then
      begin
        FEndTurnRequested := True;
        StatePushBack(nil);
      end
      else
      begin
        FSave.SelectNextPlayerUnit;
        DebugPlay := True;
      end;
    end;
    if FSave.GetSelectedUnit <> nil then
    begin
      FParentState.UpdateSoldierInfo;
      GetMap.GetCamera.CenterOnPosition(FSave.GetSelectedUnit.GetPosition);
      if FSave.GetSelectedUnit.GetId <= AUnit.GetId then
        FAISecondMove := True;
    end;
    FAIActionCounter := 0;
    Exit;
  end;

  AUnit.SetVisible(False);
  FSave.GetTileEngine.CalculateFOV(AUnit.GetPosition);

  AI := AUnit.GetAIModule;
  if AI = nil then
  begin
    AI := TAIModule.Create(FSave, AUnit, nil);
    AUnit.SetAIModule(AI);
  end;
  Inc(FAIActionCounter);
  if FAIActionCounter = 1 then
  begin
    FPlayedAggroSound := False;
    AUnit.SetHiding(False);
    if Options.TraceAI then
      Logger.Log(LOG_INFO, '#' + IntToStr(AUnit.GetId) + '--' + AUnit.GetType);
  end;

  Action.Actor := AUnit;
  Action.Number := FAIActionCounter;
  AUnit.Think(Action);

  if Action.aType = BA_RETHINK then
  begin
    FParentState.Debug('Rethink');
    AUnit.Think(Action);
  end;

  FAIActionCounter := Action.Number;
  Weapon := AUnit.GetMainHandWeapon;
  if (Weapon = nil) or (Weapon.GetAmmoItem = nil) then
  begin
    if (AUnit.GetOriginalFaction = FACTION_HOSTILE) and (AUnit.GetVisibleUnits.Count = 0) then
      FindItem(Action);
  end;

  if AUnit.GetCharging <> nil then
  begin
    if (AUnit.GetAggroSound <> -1) and (not FPlayedAggroSound) then
    begin
      GetMod.GetSoundByDepth(FSave.GetDepth, AUnit.GetAggroSound).Play(-1,
        GetMap.GetSoundAngle(AUnit.GetPosition));
      FPlayedAggroSound := True;
    end;
  end;

  if Action.aType = BA_WALK then
  begin
    FParentState.Debug('Walking to ' + Action.Target.ToString);
    if FSave.GetTile(Action.Target) <> nil then
      FSave.GetPathfinding.Calculate(Action.Actor, Action.Target);
    if FSave.GetPathfinding.GetStartDirection <> -1 then
      StatePushBack(TUnitWalkBState.Create(Self, Action));
  end;

  if Action.aType in [BA_SNAPSHOT, BA_AUTOSHOT, BA_AIMEDSHOT, BA_THROW,
                      BA_HIT, BA_MINDCONTROL, BA_PANIC, BA_LAUNCH] then
  begin
    FParentState.Debug('Attack type=' + IntToStr(Ord(Action.aType)) +
                       ' target=' + Action.Target.ToString +
                       ' weapon=' + Action.Weapon.GetRules.GetName);
    Action.TU := AUnit.GetActionTUs(Action.aType, Action.Weapon);
    if Action.aType in [BA_MINDCONTROL, BA_PANIC] then
      StatePushBack(TPsiAttackBState.Create(Self, Action))
    else
    begin
      StatePushBack(TUnitTurnBState.Create(Self, Action));
      if Action.aType = BA_HIT then
      begin
        Action.Weapon := AUnit.GetMeleeWeapon;
        StatePushBack(TMeleeAttackBState.Create(Self, Action));
      end
      else
        StatePushBack(TProjectileFlyBState.Create(Self, Action));
    end;
  end;

  if Action.aType = BA_NONE then
  begin
    FParentState.Debug('Idle');
    FAIActionCounter := 0;
    if FSave.SelectNextPlayerUnit(True, FAISecondMove) = nil then
    begin
      if not FSave.GetDebugMode then
      begin
        FEndTurnRequested := True;
        StatePushBack(nil);
      end
      else
      begin
        FSave.SelectNextPlayerUnit;
        DebugPlay := True;
      end;
    end;
    if FSave.GetSelectedUnit <> nil then
    begin
      FParentState.UpdateSoldierInfo;
      GetMap.GetCamera.CenterOnPosition(FSave.GetSelectedUnit.GetPosition);
      if FSave.GetSelectedUnit.GetId <= AUnit.GetId then
        FAISecondMove := True;
    end;
  end;
end;

function TBattlescapeGame.Kneel(Bu: TBattleUnit): Boolean;
var
  TU: Integer;
begin
  Result := False;
  if Bu.GetType <> 'SOLDIER' then Exit;
  TU := IfThen(Bu.IsKneeled, 8, 4);
  if Bu.IsFloating then Exit;
  if (not Bu.IsKneeled) and (not FSave.GetKneelReserved) then
    if not CheckReservedTU(Bu, TU) then
    begin
      FParentState.Warning('STR_NOT_ENOUGH_TIME_UNITS');
      Exit;
    end;
  if Bu.SpendTimeUnits(TU) then
  begin
    Bu.Kneel(not Bu.IsKneeled);
    GetTileEngine.CalculateFOV(Bu);
    GetMap.CacheUnits;
    FParentState.UpdateSoldierInfo;
    GetTileEngine.CheckReactionFire(Bu);
    Result := True;
  end
  else
    FParentState.Warning('STR_NOT_ENOUGH_TIME_UNITS');
end;

procedure TBattlescapeGame.EndTurn;
var
  P: TPosition;
  I: Integer;
  Tile: TTile;
  It: TBattleItem;
  T: TTile;
  LiveAliens, LiveSoldiers, InExit: Integer;
  Unit: TBattleUnit;
begin
  DebugPlay := False;
  FCurrentAction.aType := BA_NONE;
  GetMap.GetWaypoints.Clear;
  FCurrentAction.Waypoints.Clear;
  FParentState.ShowLaunchButton(False);
  FCurrentAction.Targeting := False;
  FAISecondMove := False;

  if not FEndTurnProcessed then
  begin
    if FSave.GetTileEngine.CloseUfoDoors and (Mod.SLIDING_DOOR_CLOSE <> -1) then
      GetMod.GetSoundByDepth(FSave.GetDepth, Mod.SLIDING_DOOR_CLOSE).Play;

    if FSave.GetSide <> FACTION_NEUTRAL then
    begin
      for I := 0 to FSave.GetMapSizeXYZ - 1 do
      begin
        Tile := FSave.GetTiles[I];
        It := Tile.GetInventory.First;
        while It <> nil do
        begin
          if (It.GetRules.GetBattleType = BT_GRENADE) and (It.GetFuseTimer = 0) then
          begin
            P.X := Tile.GetPosition.X * 16 + 8;
            P.Y := Tile.GetPosition.Y * 16 + 8;
            P.Z := Tile.GetPosition.Z * 24 - Tile.GetTerrainLevel;
            StatePushNext(TExplosionBState.Create(Self, P, It, It.GetPreviousOwner));
            FSave.RemoveItem(It);
            StatePushBack(nil);
            Exit;
          end;
          It := Tile.GetInventory.Next(It);
        end;
      end;
    end;
  end;

  T := FSave.GetTileEngine.CheckForTerrainExplosions;
  if T <> nil then
  begin
    P := Position(T.GetPosition.X * 16, T.GetPosition.Y * 16, T.GetPosition.Z * 24);
    StatePushNext(TExplosionBState.Create(Self, P, nil, nil, T));
    StatePushBack(nil);
    Exit;
  end;

  if not FEndTurnProcessed then
  begin
    if FSave.GetSide <> FACTION_NEUTRAL then
    begin
      for It in FSave.GetItems do
      begin
        if ((It.GetRules.GetBattleType = BT_GRENADE) or
            (It.GetRules.GetBattleType = BT_PROXIMITYGRENADE)) and
           (It.GetFuseTimer > 0) then
          It.SetFuseTimer(It.GetFuseTimer - 1);
      end;
    end;

    FSave.EndTurn;
    T := FSave.GetTileEngine.CheckForTerrainExplosions;
    if T <> nil then
    begin
      P := Position(T.GetPosition.X * 16, T.GetPosition.Y * 16, T.GetPosition.Z * 24);
      StatePushNext(TExplosionBState.Create(Self, P, nil, nil, T));
      StatePushBack(nil);
      FEndTurnProcessed := True;
      Exit;
    end;
  end;

  FEndTurnProcessed := False;

  if FSave.GetSide = FACTION_PLAYER then
    SetupCursor
  else
    GetMap.SetCursorType(CT_NONE);

  CheckForCasualties(nil, nil, False, False);
  FSave.GetTileEngine.CalculateUnitLighting;

  LiveAliens := 0;
  LiveSoldiers := 0;
  InExit := 0;
  for Unit in FSave.GetUnits do
  begin
    if Unit.IsOut then Continue;
    if Unit.GetOriginalFaction = FACTION_HOSTILE then
    begin
      if (not Options.AllowPsionicCapture) or (Unit.GetFaction <> FACTION_PLAYER) or
         (not Unit.GetCapturable) then
        Inc(LiveAliens);
    end
    else if Unit.GetOriginalFaction = FACTION_PLAYER then
    begin
      if Unit.IsInExitArea(END_POINT) then
        Inc(InExit);
      if Unit.GetFaction = FACTION_PLAYER then
        Inc(LiveSoldiers)
      else
        Inc(LiveAliens);
    end;
  end;

  if FSave.AllObjectivesDestroyed and (FSave.GetObjectiveType = MUST_DESTROY) then
  begin
    FParentState.FinishBattle(False, LiveSoldiers);
    Exit;
  end;

  if (FSave.GetTurnLimit > 0) and (FSave.GetTurn > FSave.GetTurnLimit) then
  begin
    case FSave.GetChronoTrigger of
      FORCE_ABORT: begin FSave.SetAborted(True); FParentState.FinishBattle(True, InExit); Exit; end;
      FORCE_WIN: begin FParentState.FinishBattle(False, LiveSoldiers); Exit; end;
      else begin FSave.SetAborted(True); FParentState.FinishBattle(False, 0); Exit; end;
    end;
  end;

  if (LiveAliens > 0) and (LiveSoldiers > 0) then
  begin
    ShowInfoBoxQueue;
    FParentState.UpdateSoldierInfo;
    if PlayableUnitSelected then
    begin
      GetMap.GetCamera.CenterOnPosition(FSave.GetSelectedUnit.GetPosition);
      SetupCursor;
    end;
  end;

  if ((FSave.GetSide <> FACTION_NEUTRAL) or (LiveAliens = 0) or (LiveSoldiers = 0))
     and FEndTurnRequested then
    FParentState.GetGame.PushState(TNextTurnState.Create(FSave, FParentState));

  FEndTurnRequested := False;
end;

procedure TBattlescapeGame.CheckForCasualties(MurderWeapon: TBattleItem;
  OrigMurderer: TBattleUnit; HiddenExplosion, TerrainExplosion: Boolean);
var
  Murderer: TBattleUnit;
  KillStat: TBattleUnitKills;
  Victim: TBattleUnit;
  TempWeapon, TempAmmo: string;
  NoSound, NoCorpse: Boolean;
  Modifier, LoserMod, WinnerMod, Bravery: Integer;
  DeathStat: TBattleUnitKills;
begin
  if (OrigMurderer <> nil) and (OrigMurderer.GetGeoscapeSoldier = nil) and
     ((OrigMurderer.GetUnitRules.GetSpecialAbility = SPECAB_EXPLODEONDEATH) or
      (OrigMurderer.GetUnitRules.GetSpecialAbility = SPECAB_BURN_AND_EXPLODE)) and
     (OrigMurderer.GetStatus = STATUS_DEAD) and (OrigMurderer.GetMurdererId <> 0) then
  begin
    for Victim in FSave.GetUnits do
      if Victim.GetId = OrigMurderer.GetMurdererId then
      begin
        OrigMurderer := Victim;
        Break;
      end;
  end;

  TempWeapon := 'STR_WEAPON_UNKNOWN';
  TempAmmo := 'STR_WEAPON_UNKNOWN';
  if OrigMurderer <> nil then
  begin
    if MurderWeapon <> nil then
    begin
      TempAmmo := MurderWeapon.GetRules.GetName;
      TempWeapon := TempAmmo;
    end;
    // Try to find matching weapon
  end;

  for Victim in FSave.GetUnits do
  begin
    if Victim.GetStatus = STATUS_IGNORE_ME then Continue;
    Murderer := OrigMurderer;
    KillStat.Mission := FParentState.GetGame.GetSavedGame.GetMissionStatistics.Count;
    KillStat.SetTurn(FSave.GetTurn, FSave.GetSide);
    KillStat.SetUnitStats(Victim);
    KillStat.Faction := Victim.GetFaction;
    KillStat.Side := Victim.GetFatalShotSide;
    KillStat.BodyPart := Victim.GetFatalShotBodyPart;
    KillStat.Id := Victim.GetId;
    KillStat.Weapon := TempWeapon;
    KillStat.WeaponAmmo := TempAmmo;

    if Victim.GetStatus <> STATUS_DEAD then
    begin
      if Victim.GetHealth = 0 then
        KillStat.Status := STATUS_DEAD
      else if (Victim.GetStunLevel >= Victim.GetHealth) and (Victim.GetStatus <> STATUS_UNCONSCIOUS) then
        KillStat.Status := STATUS_UNCONSCIOUS;
    end;

    if (Murderer = nil) and (not TerrainExplosion) then
    begin
      for Victim in FSave.GetUnits do
        if Victim.GetId = Victim.GetMurdererId then
        begin
          Murderer := Victim;
          KillStat.Weapon := Victim.GetMurdererWeapon;
          KillStat.WeaponAmmo := Victim.GetMurdererWeaponAmmo;
          Break;
        end;
    end;

    if (Murderer <> nil) and (KillStat.Status <> STATUS_IGNORE_ME) then
    begin
      if (Murderer.GetFaction = FACTION_PLAYER) and (Murderer.GetOriginalFaction <> FACTION_PLAYER) then
      begin
        for Victim in FSave.GetUnits do
          if Victim.GetId = Murderer.GetMindControllerId then
          begin
            if Victim.GetGeoscapeSoldier <> nil then
            begin
              Victim.GetStatistics.Kills.Add(TBattleUnitKills.Create(KillStat));
              if Victim.GetFaction = FACTION_HOSTILE then
                Victim.GetStatistics.SlaveKills := Victim.GetStatistics.SlaveKills + 1;
              Victim.SetMurdererId(Victim.GetId);
            end;
            Break;
          end;
      end
      else if not Murderer.GetStatistics.DuplicateEntry(KillStat.Status, Victim.GetId) then
      begin
        Murderer.GetStatistics.Kills.Add(TBattleUnitKills.Create(KillStat));
        Victim.SetMurdererId(Murderer.GetId);
      end;
    end;

    NoSound := False;
    NoCorpse := False;
    if Victim.GetStatus <> STATUS_DEAD then
    begin
      if Victim.GetHealth = 0 then
      begin
        if Victim.GetStatus = STATUS_UNCONSCIOUS then
          NoCorpse := True;
        if Murderer <> nil then
        begin
          Murderer.AddKillCount;
          Victim.KilledBy(Murderer.GetFaction);
          if (Victim.GetOriginalFaction = FACTION_PLAYER) and (Murderer.GetFaction = FACTION_HOSTILE) then
            Murderer.MoraleChange(20 * FSave.GetMoraleModifier div 100)
          else if (Victim.GetOriginalFaction = FACTION_HOSTILE) and (Murderer.GetFaction = FACTION_PLAYER) then
            Murderer.MoraleChange(20 * FSave.GetMoraleModifier div 100);
          if Victim.GetOriginalFaction = Murderer.GetOriginalFaction then
            Murderer.MoraleChange(-(2000 div FSave.GetMoraleModifier));
          if Victim.GetOriginalFaction = FACTION_NEUTRAL then
          begin
            if Murderer.GetOriginalFaction = FACTION_PLAYER then
              Murderer.MoraleChange(-(1000 div FSave.GetMoraleModifier))
            else
              Murderer.MoraleChange(10);
          end;
        end;

        if Victim.GetFaction <> FACTION_NEUTRAL then
        begin
          Modifier := FSave.GetMoraleModifier(Victim);
          LoserMod := IfThen(Victim.GetFaction = FACTION_HOSTILE, 100, FSave.GetMoraleModifier);
          WinnerMod := IfThen(Victim.GetFaction = FACTION_HOSTILE, FSave.GetMoraleModifier, 100);
          for Victim in FSave.GetUnits do
          begin
            if Victim.IsOut or (Victim.GetArmor.GetSize <> 1) then Continue;
            if Victim.GetOriginalFaction = Victim.GetOriginalFaction then
            begin
              Bravery := (110 - Victim.GetBaseStats.Bravery) div 10;
              Victim.MoraleChange(-(Modifier * 200 * Bravery div LoserMod div 100));
              if Victim.GetFaction = FACTION_HOSTILE then
                if Murderer <> nil then
                  Murderer.SetTurnsSinceSpotted(0);
            end
            else
              Victim.MoraleChange(10 * WinnerMod div 100);
          end;
        end;

        if MurderWeapon <> nil then
          StatePushNext(TUnitDieBState.Create(Self, Victim, MurderWeapon.GetRules.GetDamageType, NoSound, NoCorpse))
        else if HiddenExplosion then
          StatePushNext(TUnitDieBState.Create(Self, Victim, DT_HE, True, NoCorpse))
        else if TerrainExplosion then
          StatePushNext(TUnitDieBState.Create(Self, Victim, DT_HE, NoSound, NoCorpse))
        else
          StatePushNext(TUnitDieBState.Create(Self, Victim, DT_NONE, NoSound, NoCorpse));

        if Victim.GetGeoscapeSoldier <> nil then
        begin
          Victim.GetStatistics.KIA := True;
          DeathStat := TBattleUnitKills.Create(KillStat);
          if Murderer <> nil then
          begin
            DeathStat.SetUnitStats(Murderer);
            DeathStat.Faction := Murderer.GetFaction;
          end;
          FParentState.GetGame.GetSavedGame.KillSoldier(Victim.GetGeoscapeSoldier, DeathStat);
        end;
      end
      else if (Victim.GetStunLevel >= Victim.GetHealth) and (Victim.GetStatus <> STATUS_UNCONSCIOUS) then
      begin
        if Victim.GetGeoscapeSoldier <> nil then
          Victim.GetStatistics.WasUnconcious := True;
        NoSound := True;
        StatePushNext(TUnitDieBState.Create(Self, Victim, DT_STUN, NoSound, NoCorpse));
      end;
    end;
  end;

  if FSave.GetSide = FACTION_PLAYER then
    FParentState.ShowPsiButton((FSave.GetSelectedUnit <> nil) and
      (FSave.GetSelectedUnit.GetSpecialWeapon(BT_PSIAMP) <> nil) and
      (not FSave.GetSelectedUnit.IsOut));
end;

procedure TBattlescapeGame.ShowInfoBoxQueue;
begin
  for var Info in FInfoboxQueue do
    FParentState.GetGame.PushState(Info);
  FInfoboxQueue.Clear;
end;

procedure TBattlescapeGame.MissionComplete;
var
  Msg: string;
begin
  Msg := FParentState.GetGame.GetMod.GetDeployment(FSave.GetMissionType).GetObjectivePopup;
  if Msg <> '' then
    FInfoboxQueue.Add(TInfoboxOKState.Create(FParentState.GetGame.GetLanguage.GetString(Msg)));
end;

procedure TBattlescapeGame.HandleNonTargetAction;
begin
  if not FCurrentAction.Targeting then
  begin
    FCurrentAction.CameraPosition := Position(0,0,-1);
    if FCurrentAction.Result <> '' then
    begin
      FParentState.Warning(FCurrentAction.Result);
      FCurrentAction.Result := '';
    end
    else if (FCurrentAction.aType = BA_PRIME) and (FCurrentAction.Value > -1) then
    begin
      if FCurrentAction.Actor.SpendTimeUnits(FCurrentAction.TU) then
      begin
        FParentState.Warning('STR_GRENADE_IS_ACTIVATED');
        FCurrentAction.Weapon.SetFuseTimer(FCurrentAction.Value);
      end
      else
        FParentState.Warning('STR_NOT_ENOUGH_TIME_UNITS');
    end
    else if FCurrentAction.aType = BA_USE then
      FSave.ReviveUnconsciousUnits
    else if FCurrentAction.aType = BA_HIT then
    begin
      if FCurrentAction.Actor.SpendTimeUnits(FCurrentAction.TU) then
        StatePushBack(TMeleeAttackBState.Create(Self, FCurrentAction))
      else
        FParentState.Warning('STR_NOT_ENOUGH_TIME_UNITS');
    end;
    if FCurrentAction.aType <> BA_HIT then
      FCurrentAction.aType := BA_NONE;
    FParentState.UpdateSoldierInfo;
  end;
  SetupCursor;
end;

procedure TBattlescapeGame.SetupCursor;
begin
  if FCurrentAction.Targeting then
  begin
    case FCurrentAction.aType of
      BA_THROW: GetMap.SetCursorType(CT_THROW);
      BA_MINDCONTROL, BA_PANIC, BA_USE: GetMap.SetCursorType(CT_PSI);
      BA_LAUNCH: GetMap.SetCursorType(CT_WAYPOINT);
      else GetMap.SetCursorType(CT_AIM);
    end;
  end
  else if FCurrentAction.aType <> BA_HIT then
  begin
    FCurrentAction.Actor := FSave.GetSelectedUnit;
    if FCurrentAction.Actor <> nil then
      GetMap.SetCursorType(CT_NORMAL, FCurrentAction.Actor.GetArmor.GetSize)
    else
      GetMap.SetCursorType(CT_NORMAL);
  end;
end;

function TBattlescapeGame.PlayableUnitSelected: Boolean;
begin
  Result := (FSave.GetSelectedUnit <> nil) and
            ((FSave.GetSide = FACTION_PLAYER) or FSave.GetDebugMode);
end;

procedure TBattlescapeGame.HandleState;
begin
  if FStates.Count > 0 then
  begin
    if FStates[0] = nil then
    begin
      FStates.Delete(0);
      EndTurn;
    end
    else
    begin
      FStates[0].Think;
    end;
    GetMap.Invalidate;
  end;
end;

procedure TBattlescapeGame.StatePushFront(BS: TBattleState);
begin
  FStates.Insert(0, BS);
  if BS <> nil then BS.Init;
end;

procedure TBattlescapeGame.StatePushNext(BS: TBattleState);
begin
  if FStates.Count = 0 then
    StatePushFront(BS)
  else
    FStates.Insert(1, BS);
end;

procedure TBattlescapeGame.StatePushBack(BS: TBattleState);
begin
  if FStates.Count = 0 then
  begin
    FStates.Add(BS);
    if BS <> nil then BS.Init;
  end
  else
    FStates.Add(BS);
end;

procedure TBattlescapeGame.PopState;
var
  Action: TBattleAction;
  ActionFailed: Boolean;
begin
  if Options.TraceAI then
    Log(LOG_INFO, 'BattlescapeGame.PopState #' + IntToStr(FAIActionCounter) +
                  ' TU=' + IfThen(FSave.GetSelectedUnit <> nil, IntToStr(FSave.GetSelectedUnit.GetTimeUnits), '-9999'));
  if FStates.Count = 0 then Exit;

  Action := FStates[0].GetAction;
  ActionFailed := False;
  if (Action.Actor <> nil) and (Action.Result <> '') and
     (Action.Actor.GetFaction = FACTION_PLAYER) and
     FPlayerPanicHandled and ((FSave.GetSide = FACTION_PLAYER) or DebugPlay) then
  begin
    FParentState.Warning(Action.Result);
    ActionFailed := True;
  end;

  FDeleted.Add(FStates[0]);
  FStates.Delete(0);

  if (Action.Actor <> nil) and NoActionsPending(Action.Actor) then
  begin
    if Action.Actor.GetFaction = FACTION_PLAYER then
    begin
      if Action.Targeting and (FSave.GetSelectedUnit <> nil) and (not ActionFailed) then
        Action.Actor.SpendTimeUnits(Action.TU);
      if FSave.GetSide = FACTION_PLAYER then
      begin
        if (Action.aType in [BA_THROW, BA_LAUNCH]) and (not ActionFailed) then
        begin
          if Action.aType = BA_LAUNCH then
            FCurrentAction.Waypoints.Clear;
          CancelCurrentAction(True);
        end;
        FParentState.GetGame.GetCursor.SetVisible(True);
        SetupCursor;
      end;
    end
    else
    begin
      Action.Actor.SpendTimeUnits(Action.TU);
      if (FSave.GetSide <> FACTION_PLAYER) and (not DebugPlay) then
      begin
        if (FAIActionCounter > 2) or (FSave.GetSelectedUnit = nil) or
           (FSave.GetSelectedUnit.IsOut) then
        begin
          if FSave.GetSelectedUnit <> nil then
          begin
            FSave.GetSelectedUnit.SetCache(0);
            GetMap.CacheUnit(FSave.GetSelectedUnit);
          end;
          FAIActionCounter := 0;
          if (FStates.Count = 0) and (FSave.SelectNextPlayerUnit(True) = nil) then
          begin
            if not FSave.GetDebugMode then
            begin
              FEndTurnRequested := True;
              StatePushBack(nil);
            end
            else
            begin
              FSave.SelectNextPlayerUnit;
              DebugPlay := True;
            end;
          end;
          if FSave.GetSelectedUnit <> nil then
            GetMap.GetCamera.CenterOnPosition(FSave.GetSelectedUnit.GetPosition);
        end;
      end
      else if DebugPlay then
      begin
        FParentState.GetGame.GetCursor.SetVisible(True);
        SetupCursor;
      end;
    end;
  end;

  if FStates.Count > 0 then
  begin
    if FStates[0] = nil then
    begin
      while (FStates.Count > 0) and (FStates[0] = nil) do
        FStates.Delete(0);
      if FStates.Count = 0 then
        EndTurn
      else
        FStates.Add(nil);
    end
    else
      FStates[0].Init;
  end;

  if (FSave.GetSelectedUnit = nil) or (FSave.GetSelectedUnit.IsOut) then
  begin
    CancelCurrentAction;
    GetMap.SetCursorType(CT_NORMAL, 1);
    FParentState.GetGame.GetCursor.SetVisible(True);
    if FSave.GetSide = FACTION_PLAYER then
      FSave.SetSelectedUnit(nil)
    else
      FSave.SelectNextPlayerUnit(True, True);
  end;
  FParentState.UpdateSoldierInfo;
end;

function TBattlescapeGame.NoActionsPending(Bu: TBattleUnit): Boolean;
var
  BS: TBattleState;
begin
  Result := True;
  for BS in FStates do
    if (BS <> nil) and (BS.GetAction.Actor = Bu) then
      Exit(False);
end;

procedure TBattlescapeGame.SetStateInterval(AInterval: Cardinal);
begin
  FParentState.SetStateInterval(AInterval);
end;

function TBattlescapeGame.CheckReservedTU(Bu: TBattleUnit; TU: Integer; JustChecking: Boolean): Boolean;
var
  EffectiveReserved: TBattleActionType;
  SlowestWeapon: TBattleItem;
  TUKneel: Integer;
begin
  EffectiveReserved := FSave.GetTUReserved;
  if (FSave.GetSide <> Bu.GetFaction) or (FSave.GetSide = FACTION_NEUTRAL) then
    Exit(TU <= Bu.GetTimeUnits);

  if (FSave.GetSide = FACTION_HOSTILE) and (not DebugPlay) then
  begin
    if Bu.GetAIModule <> nil then
      EffectiveReserved := Bu.GetAIModule.GetReserveMode;
    case EffectiveReserved of
      BA_SNAPSHOT: Exit(TU + (Bu.GetBaseStats.TU div 3) <= Bu.GetTimeUnits);
      BA_AUTOSHOT: Exit(TU + ((Bu.GetBaseStats.TU div 5) * 2) <= Bu.GetTimeUnits);
      BA_AIMEDSHOT: Exit(TU + (Bu.GetBaseStats.TU div 2) <= Bu.GetTimeUnits);
      else Exit(TU <= Bu.GetTimeUnits);
    end;
  end;

  SlowestWeapon := Bu.GetMainHandWeapon(False);
  if (Bu.GetActionTUs(EffectiveReserved, SlowestWeapon) = 0) and (EffectiveReserved = BA_AUTOSHOT) then
    EffectiveReserved := BA_SNAPSHOT;
  if (Bu.GetActionTUs(EffectiveReserved, SlowestWeapon) = 0) and (EffectiveReserved = BA_SNAPSHOT) then
    EffectiveReserved := BA_AIMEDSHOT;
  TUKneel := IfThen(FSave.GetKneelReserved and (not Bu.IsKneeled) and (Bu.GetType = 'SOLDIER'), 4, 0);
  if (Bu.GetActionTUs(EffectiveReserved, SlowestWeapon) = 0) and (EffectiveReserved = BA_AIMEDSHOT) then
  begin
    if TUKneel > 0 then
      EffectiveReserved := BA_NONE
    else
      Exit(True);
  end;

  if ((EffectiveReserved <> BA_NONE) or FSave.GetKneelReserved) and
     (TU + TUKneel + Bu.GetActionTUs(EffectiveReserved, SlowestWeapon) > Bu.GetTimeUnits) and
     ((TUKneel + Bu.GetActionTUs(EffectiveReserved, SlowestWeapon) <= Bu.GetTimeUnits) or JustChecking) then
  begin
    if not JustChecking then
    begin
      if TUKneel > 0 then
        FParentState.Warning('STR_TIME_UNITS_RESERVED_FOR_KNEELING_AND_FIRING')
      else
        case EffectiveReserved of
          BA_SNAPSHOT: FParentState.Warning('STR_TIME_UNITS_RESERVED_FOR_SNAP_SHOT');
          BA_AUTOSHOT: FParentState.Warning('STR_TIME_UNITS_RESERVED_FOR_AUTO_SHOT');
          BA_AIMEDSHOT: FParentState.Warning('STR_TIME_UNITS_RESERVED_FOR_AIMED_SHOT');
        end;
    end;
    Exit(False);
  end;
  Result := True;
end;

function TBattlescapeGame.HandlePanickingPlayer: Boolean;
var
  Unit: TBattleUnit;
begin
  for Unit in FSave.GetUnits do
    if (Unit.GetFaction = FACTION_PLAYER) and (Unit.GetOriginalFaction = FACTION_PLAYER) and
       HandlePanickingUnit(Unit) then
      Exit(False);
  Result := True;
end;

function TBattlescapeGame.HandlePanickingUnit(AUnit: TBattleUnit): Boolean;
var
  Status: TUnitStatus;
  Flee: Integer;
  Action: TBattleAction;
  Item: TBattleItem;
  I: Integer;
begin
  Status := AUnit.GetStatus;
  if (Status <> STATUS_PANICKING) and (Status <> STATUS_BERSERK) then Exit(False);
  FSave.SetSelectedUnit(AUnit);
  GetMap.SetCursorType(CT_NONE);

  if AUnit.GetVisible or (not Options.NoAlienPanicMessages) then
  begin
    GetMap.GetCamera.CenterOnPosition(AUnit.GetPosition);
    if Status = STATUS_PANICKING then
      FParentState.GetGame.PushState(TInfoboxState.Create(
        FParentState.GetGame.GetLanguage.GetString('STR_HAS_PANICKED', AUnit.GetGender).Arg(AUnit.GetName(FParentState.GetGame.GetLanguage))))
    else
      FParentState.GetGame.PushState(TInfoboxState.Create(
        FParentState.GetGame.GetLanguage.GetString('STR_HAS_GONE_BERSERK', AUnit.GetGender).Arg(AUnit.GetName(FParentState.GetGame.GetLanguage))));
  end;

  Flee := RNG.Generate(0,100);
  Action.Actor := AUnit;
  if (Status = STATUS_PANICKING) and (Flee <= 50) then
  begin
    Item := AUnit.GetItem('STR_RIGHT_HAND');
    if Item <> nil then
      DropItem(AUnit.GetPosition, Item, False, True);
    Item := AUnit.GetItem('STR_LEFT_HAND');
    if Item <> nil then
      DropItem(AUnit.GetPosition, Item, False, True);
    AUnit.SetCache(0);
    for I := 0 to 19 do
    begin
      Action.Target := Position(AUnit.GetPosition.X + RNG.Generate(-5,5),
                                AUnit.GetPosition.Y + RNG.Generate(-5,5),
                                AUnit.GetPosition.Z);
      if (I >= 10) and (Action.Target.Z > 0) then Dec(Action.Target.Z);
      if (I >= 15) and (Action.Target.Z > 0) then Dec(Action.Target.Z);
      if FSave.GetTile(Action.Target) <> nil then
      begin
        FSave.GetPathfinding.Calculate(Action.Actor, Action.Target);
        if FSave.GetPathfinding.GetStartDirection <> -1 then
        begin
          StatePushBack(TUnitWalkBState.Create(Self, Action));
          Break;
        end;
      end;
    end;
  end;
  StatePushBack(TUnitPanicBState.Create(Self, Action.Actor));
  AUnit.MoraleChange(15);
  Result := True;
end;

function TBattlescapeGame.CancelCurrentAction(BForce: Boolean): Boolean;
var
  Previewed: Boolean;
begin
  Previewed := Options.BattleNewPreviewPath <> PATH_NONE;
  if FSave.GetPathfinding.RemovePreview and Previewed then Exit(True);

  if (FStates.Count = 0) or BForce then
  begin
    if FCurrentAction.Targeting then
    begin
      if (FCurrentAction.aType = BA_LAUNCH) and (FCurrentAction.Waypoints.Count > 0) then
      begin
        FCurrentAction.Waypoints.Delete(FCurrentAction.Waypoints.Count - 1);
        if GetMap.GetWaypoints.Count > 0 then
          GetMap.GetWaypoints.Delete(GetMap.GetWaypoints.Count - 1);
        if FCurrentAction.Waypoints.Count = 0 then
          FParentState.ShowLaunchButton(False);
        Exit(True);
      end
      else
      begin
        if Options.BattleConfirmFireMode and (FCurrentAction.Waypoints.Count > 0) then
        begin
          FCurrentAction.Waypoints.Delete(FCurrentAction.Waypoints.Count - 1);
          GetMap.GetWaypoints.Delete(GetMap.GetWaypoints.Count - 1);
          Exit(True);
        end;
        FCurrentAction.Targeting := False;
        FCurrentAction.aType := BA_NONE;
        SetupCursor;
        FParentState.GetGame.GetCursor.SetVisible(True);
        Exit(True);
      end;
    end;
  end
  else if (FStates.Count > 0) and (FStates[0] <> nil) then
  begin
    FStates[0].Cancel;
    Exit(True);
  end;
  Result := False;
end;

procedure TBattlescapeGame.CancelAllActions;
begin
  FSave.GetPathfinding.RemovePreview;
  FCurrentAction.Waypoints.Clear;
  GetMap.GetWaypoints.Clear;
  FParentState.ShowLaunchButton(False);
  FCurrentAction.Targeting := False;
  FCurrentAction.aType := BA_NONE;
  SetupCursor;
  FParentState.GetGame.GetCursor.SetVisible(True);
end;

function TBattlescapeGame.GetCurrentAction: PBattleAction;
begin
  Result := @FCurrentAction;
end;

function TBattlescapeGame.IsBusy: Boolean;
begin
  Result := FStates.Count > 0;
end;

procedure TBattlescapeGame.PrimaryAction(Pos: TPosition);
var
  Previewed: Boolean;
  Unit: TBattleUnit;
  ModifierPressed: Boolean;
begin
  Previewed := Options.BattleNewPreviewPath <> PATH_NONE;
  GetMap.ResetObstacles;

  if FCurrentAction.Targeting and (FSave.GetSelectedUnit <> nil) then
  begin
    if FCurrentAction.aType = BA_LAUNCH then
    begin
      if (FCurrentAction.Waypoints.Count < FCurrentAction.Weapon.GetRules.GetWaypoints) or
         (FCurrentAction.Weapon.GetRules.GetWaypoints = -1) then
      begin
        FParentState.ShowLaunchButton(True);
        FCurrentAction.Waypoints.Add(Pos);
        GetMap.GetWaypoints.Add(Pos);
      end;
    end
    else if (FCurrentAction.aType = BA_USE) and
            (FCurrentAction.Weapon.GetRules.GetBattleType = BT_MINDPROBE) then
    begin
      Unit := FSave.SelectUnit(Pos);
      if (Unit <> nil) and (Unit.GetFaction <> FSave.GetSelectedUnit.GetFaction) and Unit.GetVisible then
      begin
        if (not FCurrentAction.Weapon.GetRules.IsLOSRequired) or
           (FCurrentAction.Actor.GetVisibleUnits.Contains(Unit)) then
        begin
          if FCurrentAction.Actor.SpendTimeUnits(FCurrentAction.TU) then
          begin
            FParentState.GetGame.GetMod.GetSoundByDepth(FSave.GetDepth, FCurrentAction.Weapon.GetRules.GetHitSound).Play(-1, GetMap.GetSoundAngle(Pos));
            FParentState.GetGame.PushState(TUnitInfoState.Create(Unit, FParentState, False, True));
            CancelCurrentAction;
          end
          else
            FParentState.Warning('STR_NOT_ENOUGH_TIME_UNITS');
        end
        else
          FParentState.Warning('STR_NO_LINE_OF_FIRE');
      end;
    end
    else if (FCurrentAction.aType in [BA_PANIC, BA_MINDCONTROL]) then
    begin
      Unit := FSave.SelectUnit(Pos);
      if (Unit <> nil) and (Unit.GetFaction <> FSave.GetSelectedUnit.GetFaction) and Unit.GetVisible then
      begin
        FCurrentAction.TU := FCurrentAction.Actor.GetActionTUs(FCurrentAction.aType, FCurrentAction.Weapon);
        FCurrentAction.Target := Pos;
        if (not FCurrentAction.Weapon.GetRules.IsLOSRequired) or
           (FCurrentAction.Actor.GetVisibleUnits.Contains(Unit)) then
        begin
          GetMap.SetCursorType(CT_NONE);
          FParentState.GetGame.GetCursor.SetVisible(False);
          FCurrentAction.CameraPosition := GetMap.GetCamera.GetMapOffset;
          StatePushBack(TPsiAttackBState.Create(Self, FCurrentAction));
        end
        else
          FParentState.Warning('STR_NO_LINE_OF_FIRE');
      end;
    end
    else if Options.BattleConfirmFireMode and
            ((FCurrentAction.Waypoints.Count = 0) or (Pos <> FCurrentAction.Waypoints[0])) then
    begin
      FCurrentAction.Waypoints.Clear;
      FCurrentAction.Waypoints.Add(Pos);
      GetMap.GetWaypoints.Clear;
      GetMap.GetWaypoints.Add(Pos);
    end
    else
    begin
      FCurrentAction.Target := Pos;
      GetMap.SetCursorType(CT_NONE);
      if Options.BattleConfirmFireMode then
      begin
        FCurrentAction.Waypoints.Clear;
        GetMap.GetWaypoints.Clear;
      end;
      FParentState.GetGame.GetCursor.SetVisible(False);
      FCurrentAction.CameraPosition := GetMap.GetCamera.GetMapOffset;
      FStates.Add(TProjectileFlyBState.Create(Self, FCurrentAction));
      StatePushFront(TUnitTurnBState.Create(Self, FCurrentAction));
    end;
  end
  else
  begin
    FCurrentAction.Actor := FSave.GetSelectedUnit;
    Unit := FSave.SelectUnit(Pos);
    if (Unit <> nil) and (Unit <> FSave.GetSelectedUnit) and (Unit.GetVisible or DebugPlay) then
    begin
      if Unit.GetFaction = FSave.GetSide then
      begin
        FSave.SetSelectedUnit(Unit);
        FParentState.UpdateSoldierInfo;
        CancelCurrentAction;
        SetupCursor;
        FCurrentAction.Actor := Unit;
      end;
    end
    else if PlayableUnitSelected then
    begin
      ModifierPressed := (SDL_GetModState and KMOD_CTRL) <> 0;
      if Previewed and ((FCurrentAction.Target <> Pos) or
         (FSave.GetPathfinding.IsModifierUsed <> ModifierPressed)) then
        FSave.GetPathfinding.RemovePreview;
      FCurrentAction.Target := Pos;
      FSave.GetPathfinding.Calculate(FCurrentAction.Actor, FCurrentAction.Target);
      FCurrentAction.Run := False;
      FCurrentAction.Strafe := Options.Strafe and ModifierPressed and
                               (FSave.GetSelectedUnit.GetArmor.GetSize = 1);
      if FCurrentAction.Strafe and (FSave.GetPathfinding.GetPath.Count > 1) then
      begin
        FCurrentAction.Run := True;
        FCurrentAction.Strafe := False;
      end;
      if Previewed and (not FSave.GetPathfinding.PreviewPath) and
         (FSave.GetPathfinding.GetStartDirection <> -1) then
      begin
        FSave.GetPathfinding.RemovePreview;
        Previewed := False;
      end;
      if (not Previewed) and (FSave.GetPathfinding.GetStartDirection <> -1) then
      begin
        GetMap.SetCursorType(CT_NONE);
        FParentState.GetGame.GetCursor.SetVisible(False);
        StatePushBack(TUnitWalkBState.Create(Self, FCurrentAction));
      end;
    end;
  end;
end;

procedure TBattlescapeGame.SecondaryAction(Pos: TPosition);
begin
  FCurrentAction.Target := Pos;
  FCurrentAction.Actor := FSave.GetSelectedUnit;
  FCurrentAction.Strafe := Options.Strafe and ((SDL_GetModState and KMOD_CTRL) <> 0) and
                           (FSave.GetSelectedUnit.GetTurretType > -1);
  StatePushBack(TUnitTurnBState.Create(Self, FCurrentAction));
end;

procedure TBattlescapeGame.LaunchAction;
begin
  FParentState.ShowLaunchButton(False);
  GetMap.GetWaypoints.Clear;
  FCurrentAction.Target := FCurrentAction.Waypoints[0];
  GetMap.SetCursorType(CT_NONE);
  FParentState.GetGame.GetCursor.SetVisible(False);
  FCurrentAction.CameraPosition := GetMap.GetCamera.GetMapOffset;
  FStates.Add(TProjectileFlyBState.Create(Self, FCurrentAction));
  StatePushFront(TUnitTurnBState.Create(Self, FCurrentAction));
end;

procedure TBattlescapeGame.PsiButtonAction;
begin
  if FCurrentAction.Waypoints.Count > 0 then Exit;
  FCurrentAction.Weapon := FSave.GetSelectedUnit.GetSpecialWeapon(BT_PSIAMP);
  FCurrentAction.Targeting := True;
  FCurrentAction.aType := BA_PANIC;
  FCurrentAction.TU := FCurrentAction.Weapon.GetRules.GetTUUse;
  if not FCurrentAction.Weapon.GetRules.GetFlatRate then
    FCurrentAction.TU := Floor(FSave.GetSelectedUnit.GetBaseStats.TU * FCurrentAction.TU / 100.0);
  SetupCursor;
end;

procedure TBattlescapeGame.MoveUpDown(AUnit: TBattleUnit; Dir: Integer);
begin
  FCurrentAction.Target := AUnit.GetPosition;
  if Dir = Pathfinding.DIR_UP then
    FCurrentAction.Target.Z := FCurrentAction.Target.Z + 1
  else
    FCurrentAction.Target.Z := FCurrentAction.Target.Z - 1;
  GetMap.SetCursorType(CT_NONE);
  FParentState.GetGame.GetCursor.SetVisible(False);
  if FSave.GetSelectedUnit.IsKneeled then
    Kneel(FSave.GetSelectedUnit);
  FSave.GetPathfinding.Calculate(FCurrentAction.Actor, FCurrentAction.Target);
  StatePushBack(TUnitWalkBState.Create(Self, FCurrentAction));
end;

procedure TBattlescapeGame.RequestEndTurn;
begin
  CancelCurrentAction;
  if not FEndTurnRequested then
  begin
    FEndTurnRequested := True;
    StatePushBack(nil);
  end;
end;

procedure TBattlescapeGame.SetTUReserved(Tur: TBattleActionType);
begin
  FSave.SetTUReserved(Tur);
end;

procedure TBattlescapeGame.DropItem(Position: TPosition; Item: TBattleItem;
  NewItem, RemoveItem: Boolean);
begin
  GetTileEngine.ItemDrop(FSave.GetTile(Position), Item, GetMod, NewItem, RemoveItem);
end;

function TBattlescapeGame.ConvertUnit(AUnit: TBattleUnit): TBattleUnit;
begin
  FParentState.ShowPsiButton(False);
  Result := FSave.ConvertUnit(AUnit, FParentState.GetGame.GetSavedGame, GetMod);
  GetMap.CacheUnit(Result);
end;

function TBattlescapeGame.GetMap: TMap;
begin
  Result := FParentState.GetMap;
end;

function TBattlescapeGame.GetSave: TSavedBattleGame;
begin
  Result := FSave;
end;

function TBattlescapeGame.GetTileEngine: TTileEngine;
begin
  Result := FSave.GetTileEngine;
end;

function TBattlescapeGame.GetPathfinding: TPathfinding;
begin
  Result := FSave.GetPathfinding;
end;

function TBattlescapeGame.GetMod: TMod;
begin
  Result := FParentState.GetGame.GetMod;
end;

function TBattlescapeGame.GetPanicHandled: Boolean;
begin
  Result := FPlayerPanicHandled;
end;

procedure TBattlescapeGame.FindItem(var Action: TBattleAction);
var
  TargetItem: TBattleItem;
begin
  if Action.Actor.GetRankString = 'STR_LIVE_TERRORIST' then Exit;
  TargetItem := SurveyItems(Action);
  if (TargetItem <> nil) and WorthTaking(TargetItem, Action) then
  begin
    if TargetItem.GetTile.GetPosition = Action.Actor.GetPosition then
    begin
      if TakeItemFromGround(TargetItem, Action) = 0 then
        if TargetItem.GetAmmoItem = nil then
          Action.Actor.CheckAmmo;
    end
    else if (TargetItem.GetTile.GetUnit = nil) or TargetItem.GetTile.GetUnit.IsOut then
    begin
      Action.Target := TargetItem.GetTile.GetPosition;
      Action.aType := BA_WALK;
    end;
  end;
end;

function TBattlescapeGame.SurveyItems(var Action: TBattleAction): TBattleItem;
var
  DroppedItems: TList<TBattleItem>;
  Item: TBattleItem;
  MaxWorth, CurrentWorth: Integer;
begin
  Result := nil;
  DroppedItems := TList<TBattleItem>.Create;
  try
    for Item in FSave.GetItems do
      if (Item.GetSlot <> nil) and (Item.GetSlot.GetId = 'STR_GROUND') and
         (Item.GetTile <> nil) and Item.GetTurnFlag and (Item.GetRules.GetAttraction > 0) then
        DroppedItems.Add(Item);
    MaxWorth := 0;
    for Item in DroppedItems do
    begin
      CurrentWorth := Item.GetRules.GetAttraction div ((GetTileEngine.Distance(Action.Actor.GetPosition, Item.GetTile.GetPosition) * 2) + 1);
      if CurrentWorth > MaxWorth then
      begin
        MaxWorth := CurrentWorth;
        Result := Item;
      end;
    end;
  finally
    DroppedItems.Free;
  end;
end;

function TBattlescapeGame.WorthTaking(AItem: TBattleItem; var Action: TBattleAction): Boolean;
var
  WorthToTake: Integer;
  AmmoFound, WeaponFound: Boolean;
  Item: TBattleItem;
  FreeSlots, Size: Integer;
begin
  WorthToTake := 0;
  if Action.Actor.GetVisibleUnits.Count = 0 then
  begin
    WorthToTake := AItem.GetRules.GetAttraction;
    if (AItem.GetRules.GetWaypoints = 0) and (AItem.GetRules.GetBattleType <> BT_AMMO) then
    begin
      AmmoFound := True;
      if AItem.GetAmmoItem = nil then
      begin
        AmmoFound := False;
        for Item in Action.Actor.GetInventory do
          if (Item.GetRules.GetBattleType = BT_AMMO) then
            for var AmmoType in AItem.GetRules.GetCompatibleAmmo do
              if Item.GetRules.GetName = AmmoType then
              begin
                AmmoFound := True;
                Break;
              end;
      end;
      if not AmmoFound then Exit(False);
    end;

    if AItem.GetRules.GetBattleType = BT_AMMO then
    begin
      WeaponFound := False;
      for Item in Action.Actor.GetInventory do
        if Item.GetRules.GetBattleType = BT_FIREARM then
          for var AmmoType in Item.GetRules.GetCompatibleAmmo do
            if Item.GetRules.GetName = AmmoType then
            begin
              WeaponFound := True;
              Break;
            end;
      if not WeaponFound then Exit(False);
    end;
  end;

  if WorthToTake > 0 then
  begin
    FreeSlots := 25;
    for Item in Action.Actor.GetInventory do
      FreeSlots := FreeSlots - (Item.GetRules.GetInventoryHeight * Item.GetRules.GetInventoryWidth);
    Size := AItem.GetRules.GetInventoryHeight * AItem.GetRules.GetInventoryWidth;
    if FreeSlots < Size then Exit(False);
  end;

  Result := (WorthToTake - (GetTileEngine.Distance(Action.Actor.GetPosition, AItem.GetTile.GetPosition) * 2)) > 5;
end;

function TBattlescapeGame.TakeItemFromGround(AItem: TBattleItem; var Action: TBattleAction): Integer;
var
  FreeSlots: Integer;
  Item: TBattleItem;
begin
  if Action.Actor.GetTimeUnits < 6 then Exit(1);
  FreeSlots := 25;
  for Item in Action.Actor.GetInventory do
    FreeSlots := FreeSlots - (Item.GetRules.GetInventoryHeight * Item.GetRules.GetInventoryWidth);
  if FreeSlots < (AItem.GetRules.GetInventoryHeight * AItem.GetRules.GetInventoryWidth) then
    Exit(2);
  if TakeItem(AItem, Action) then
  begin
    Action.Actor.SpendTimeUnits(6);
    AItem.GetTile.RemoveItem(AItem);
    Exit(0);
  end
  else
    Exit(3);
end;

function TBattlescapeGame.TakeItem(AItem: TBattleItem; var Action: TBattleAction): Boolean;
var
  Placed: Boolean;
  ModPtr: TMod;
  Item: TBattleItem;
  I: Integer;
begin
  Placed := False;
  ModPtr := FParentState.GetGame.GetMod;
  case AItem.GetRules.GetBattleType of
    BT_AMMO:
      begin
        if (Action.Actor.GetItem('STR_RIGHT_HAND') <> nil) and
           (Action.Actor.GetItem('STR_RIGHT_HAND').GetAmmoItem = nil) then
        begin
          if Action.Actor.GetItem('STR_RIGHT_HAND').SetAmmoItem(AItem) = 0 then
            Placed := True;
        end
        else
          for I := 0 to 3 do
            if Action.Actor.GetItem('STR_BELT', I) = nil then
            begin
              AItem.MoveToOwner(Action.Actor);
              AItem.SetSlot(ModPtr.GetInventory('STR_BELT', True));
              AItem.SetSlotX(I);
              Placed := True;
              Break;
            end;
      end;
    BT_GRENADE, BT_PROXIMITYGRENADE:
      for I := 0 to 3 do
        if Action.Actor.GetItem('STR_BELT', I) = nil then
        begin
          AItem.MoveToOwner(Action.Actor);
          AItem.SetSlot(ModPtr.GetInventory('STR_BELT', True));
          AItem.SetSlotX(I);
          Placed := True;
          Break;
        end;
    BT_FIREARM, BT_MELEE:
      if Action.Actor.GetItem('STR_RIGHT_HAND') = nil then
      begin
        AItem.MoveToOwner(Action.Actor);
        AItem.SetSlot(ModPtr.GetInventory('STR_RIGHT_HAND', True));
        Placed := True;
      end;
    BT_MEDIKIT, BT_SCANNER:
      if Action.Actor.GetItem('STR_BACK_PACK') = nil then
      begin
        AItem.MoveToOwner(Action.Actor);
        AItem.SetSlot(ModPtr.GetInventory('STR_BACK_PACK', True));
        Placed := True;
      end;
    BT_MINDPROBE:
      if Action.Actor.GetItem('STR_LEFT_HAND') = nil then
      begin
        AItem.MoveToOwner(Action.Actor);
        AItem.SetSlot(ModPtr.GetInventory('STR_LEFT_HAND', True));
        Placed := True;
      end;
  end;
  Result := Placed;
end;

function TBattlescapeGame.GetReservedAction: TBattleActionType;
begin
  Result := FSave.GetTUReserved;
end;

procedure TBattlescapeGame.TallyUnits(var LiveAliens, LiveSoldiers: Integer);
var
  Unit: TBattleUnit;
begin
  LiveSoldiers := 0;
  LiveAliens := 0;
  for Unit in FSave.GetUnits do
  begin
    if Unit.IsOut then Continue;
    if Unit.GetOriginalFaction = FACTION_HOSTILE then
    begin
      if (not Options.AllowPsionicCapture) or (Unit.GetFaction <> FACTION_PLAYER) or
         (not Unit.GetCapturable) then
        Inc(LiveAliens);
    end
    else if Unit.GetOriginalFaction = FACTION_PLAYER then
    begin
      if Unit.GetFaction = FACTION_PLAYER then
        Inc(LiveSoldiers)
      else
        Inc(LiveAliens);
    end;
  end;
end;

function TBattlescapeGame.ConvertInfected: Boolean;
var
  Unit: TBattleUnit;
  I: Integer;
begin
  Result := False;
  I := 0;
  while I < FSave.GetUnits.Count do
  begin
    Unit := FSave.GetUnits[I];
    if (Unit.GetHealth > 0) and (Unit.GetHealth >= Unit.GetStunLevel) and Unit.GetRespawn then
    begin
      Result := True;
      Unit.SetRespawn(False);
      if Options.BattleNotifyDeath and (Unit.GetFaction = FACTION_PLAYER) then
        FParentState.GetGame.PushState(TInfoboxState.Create(
          FParentState.GetGame.GetLanguage.GetString('STR_HAS_BEEN_KILLED', Unit.GetGender).Arg(Unit.GetName(FParentState.GetGame.GetLanguage))));
      ConvertUnit(Unit);
      I := 0; // restart loop
    end
    else
      Inc(I);
  end;
end;

procedure TBattlescapeGame.SetKneelReserved(Reserved: Boolean);
begin
  FSave.SetKneelReserved(Reserved);
end;

function TBattlescapeGame.GetKneelReserved: Boolean;
begin
  Result := FSave.GetKneelReserved;
end;

function TBattlescapeGame.CheckForProximityGrenades(AUnit: TBattleUnit): Boolean;
var
  Size, X, Y, TX, TY: Integer;
  Tile: TTile;
  Item: TBattleItem;
  P: TPosition;
begin
  Result := False;
  Size := AUnit.GetArmor.GetSize - 1;
  for X := 0 to Size do
    for Y := 0 to Size do
      for TX := -1 to 1 do
        for TY := -1 to 1 do
        begin
          Tile := FSave.GetTile(AUnit.GetPosition + Position(X,Y,0) + Position(TX,TY,0));
          if Tile = nil then Continue;
          for Item in Tile.GetInventory do
            if (Item.GetRules.GetBattleType = BT_PROXIMITYGRENADE) and (Item.GetFuseTimer = 0) then
            begin
              P.X := Tile.GetPosition.X * 16 + 8;
              P.Y := Tile.GetPosition.Y * 16 + 8;
              P.Z := Tile.GetPosition.Z * 24 + Tile.GetTerrainLevel;
              StatePushNext(TExplosionBState.Create(Self, P, Item, Item.GetPreviousOwner));
              FSave.RemoveItem(Item);
              AUnit.SetCache(0);
              GetMap.CacheUnit(AUnit);
              Exit(True);
            end;
        end;
end;

procedure TBattlescapeGame.CleanupDeleted;
var
  BS: TBattleState;
begin
  for BS in FDeleted do
    BS.Free;
  FDeleted.Clear;
end;

function TBattlescapeGame.GetDepth: Integer;
begin
  Result := FSave.GetDepth;
end;

function TBattlescapeGame.GetStates: TList<TBattleState>;
begin
  Result := FStates;
end;

procedure TBattlescapeGame.AutoEndBattle;
var
  EndBattle: Boolean;
  LiveAliens, LiveSoldiers: Integer;
begin
  if Options.BattleAutoEnd then
  begin
    EndBattle := False;
    if FSave.GetObjectiveType = MUST_DESTROY then
      EndBattle := FSave.AllObjectivesDestroyed
    else
    begin
      TallyUnits(LiveAliens, LiveSoldiers);
      EndBattle := (LiveAliens = 0) or (LiveSoldiers = 0);
    end;
    if EndBattle then
    begin
      FSave.SetSelectedUnit(nil);
      CancelCurrentAction(True);
      RequestEndTurn;
    end;
  end;
end;

end.