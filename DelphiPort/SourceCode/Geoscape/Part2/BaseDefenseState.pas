unit BaseDefenseState;

interface

uses
  Engine.State, Engine.Game, Engine.Mod, Engine.LocalizedText,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Savegame.Base, Savegame.BaseFacility, Mod.RuleBaseFacility,
  Savegame.Ufo, Geoscape.GeoscapeState, Engine.Action,
  Engine.Timer, Engine.Sound, Engine.RNG, Engine.Options;

type
  TBaseDefenseActionType = (BDA_NONE, BDA_FIRE, BDA_RESOLVE, BDA_DESTROY, BDA_END);

  TBaseDefenseState = class(TState)
  private
    FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtInit: TText;
    FLstDefenses: TTextList;
    FBase: TBase;
    FUfo: TUfo;
    FThinkCycles, FRow, FPasses, FGravShields, FDefenses, FAttacks, FExplosionCount: Integer;
    FAction: TBaseDefenseActionType;
    FTimer: TTimer;
    FState: TGeoscapeState;
    procedure BtnOkClick(AAction: TAction);
    procedure NextStep;
  public
    constructor Create(ABase: TBase; AUfo: TUfo; AState: TGeoscapeState);
    destructor Destroy; override;
    procedure Think; override;
  end;

implementation

uses
  System.SysUtils;

{ TBaseDefenseState }

constructor TBaseDefenseState.Create(ABase: TBase; AUfo: TUfo; AState: TGeoscapeState);
begin
  inherited Create(nil);
  FState := AState;
  FBase := ABase;
  FAction := BDA_NONE;
  FRow := -1;
  FPasses := 0;
  FAttacks := 0;
  FThinkCycles := 0;
  FUfo := AUfo;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FTxtTitle := TText.Create(300, 17, 16, 6);
  FTxtInit := TText.Create(300, 10, 16, 24);
  FLstDefenses := TTextList.Create(300, 128, 16, 40);
  FBtnOk := TTextButton.Create(120, 18, 100, 170);

  SetInterface('baseDefense');

  Add(FWindow, 'window', 'baseDefense');
  Add(FBtnOk, 'button', 'baseDefense');
  Add(FTxtTitle, 'text', 'baseDefense');
  Add(FTxtInit, 'text', 'baseDefense');
  Add(FLstDefenses, 'text', 'baseDefense');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK04.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.keyOk, BtnOkClick);
  FBtnOk.OnKeyboardPress(Options.keyCancel, BtnOkClick);
  FBtnOk.Visible := False;

  FTxtTitle.Big := True;
  FTxtTitle.Text := Tr('STR_BASE_UNDER_ATTACK').Arg(FBase.Name);

  FTxtInit.Visible := False;
  FTxtInit.Text := Tr('STR_BASE_DEFENSES_INITIATED');

  FLstDefenses.SetColumns(3, 134, 70, 50);

  FGravShields := FBase.GravShields;
  FDefenses := FBase.Defenses.Count;

  FTimer := TTimer.Create(250);
  FTimer.OnTimer := NextStep;
  FTimer.Start;

  FExplosionCount := 0;
end;

destructor TBaseDefenseState.Destroy;
begin
  FTimer.Free;
  inherited;
end;

procedure TBaseDefenseState.Think;
begin
  inherited;
  if Assigned(FTimer) then
    FTimer.Think(Self, 0);
end;

procedure TBaseDefenseState.NextStep;
var
  def: TBaseFacility;
  dmg: Integer;
begin
  if FThinkCycles = -1 then Exit;

  Inc(FThinkCycles);

  if FThinkCycles = 1 then
  begin
    FTxtInit.Visible := True;
    Exit;
  end;

  if FThinkCycles > 1 then
  begin
    case FAction of
      BDA_DESTROY:
        begin
          if FExplosionCount = 0 then
          begin
            FLstDefenses.AddRow(2, [Tr('STR_UFO_DESTROYED'), ' ', ' ']);
            Inc(FRow);
            if FRow > 14 then FLstDefenses.ScrollDown(True);
          end;
          Game.Mod.GetSound('GEO.CAT', Mod.UFO_EXPLODE).Play;
          Inc(FExplosionCount);
          if FExplosionCount = 3 then
            FAction := BDA_END;
          Exit;
        end;
      BDA_END:
        begin
          FBtnOk.Visible := True;
          FThinkCycles := -1;
          Exit;
        end;
    end;

    if (FAttacks = FDefenses) and (FPasses = FGravShields) then
    begin
      FAction := BDA_END;
      Exit;
    end
    else if (FAttacks = FDefenses) and (FPasses < FGravShields) then
    begin
      FLstDefenses.AddRow(3, [Tr('STR_GRAV_SHIELD_REPELS_UFO'), ' ', ' ']);
      if FRow > 14 then FLstDefenses.ScrollDown(True);
      Inc(FRow);
      Inc(FPasses);
      FAttacks := 0;
      Exit;
    end;

    def := FBase.Defenses[FAttacks];

    case FAction of
      BDA_NONE:
        begin
          FLstDefenses.AddRow(3, [Tr(def.Rules.TypeName), ' ', ' ']);
          Inc(FRow);
          FAction := BDA_FIRE;
          if FRow > 14 then FLstDefenses.ScrollDown(True);
          Exit;
        end;
      BDA_FIRE:
        begin
          FLstDefenses.SetCellText(FRow, 1, Tr('STR_FIRING'));
          Game.Mod.GetSound('GEO.CAT', def.Rules.FireSound).Play;
          FTimer.Interval := 333;
          FAction := BDA_RESOLVE;
          Exit;
        end;
      BDA_RESOLVE:
        begin
          if not RNG.Percent(def.Rules.HitRatio) then
            FLstDefenses.SetCellText(FRow, 2, Tr('STR_MISSED'))
          else
          begin
            FLstDefenses.SetCellText(FRow, 2, Tr('STR_HIT'));
            Game.Mod.GetSound('GEO.CAT', def.Rules.HitSound).Play;
            dmg := def.Rules.DefenseValue;
            FUfo.Damage := FUfo.Damage + (dmg div 2 + RNG.Generate(0, dmg));
          end;
          if FUfo.Status = TUfoStatus.DESTROYED then
            FAction := BDA_DESTROY
          else
            FAction := BDA_NONE;
          Inc(FAttacks);
          FTimer.Interval := 250;
          Exit;
        end;
    end;
  end;
end;

procedure TBaseDefenseState.BtnOkClick(AAction: TAction);
begin
  FTimer.Stop;
  Game.PopState;
  if FUfo.Status <> TUfoStatus.DESTROYED then
    FState.HandleBaseDefense(FBase, FUfo)
  else
    FBase.CleanupDefenses(True);
end;

end.