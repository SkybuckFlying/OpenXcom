unit AllocatePsiTrainingState;

interface

uses
  Engine.State, Engine.Game, Engine.Mod, Engine.LocalizedText,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Savegame.SavedGame, Savegame.Base, Savegame.Soldier,
  Engine.Action, Engine.Options;

type
  TAllocatePsiTrainingState = class(TState)
  private
    FBase: TBase;
    FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtTraining, FTxtName, FTxtRemaining: TText;
    FTxtPsiStrength, FTxtPsiSkill: TText;
    FLstSoldiers: TTextList;
    FSoldiers: array of TSoldier; // vector replacement
    FSel: Integer;
    FLabSpace: Integer;
    procedure BtnOkClick(AAction: TAction);
    procedure LstSoldiersClick(AAction: TAction);
  public
    constructor Create(ABase: TBase);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils, System.Classes;

{ TAllocatePsiTrainingState }

constructor TAllocatePsiTrainingState.Create(ABase: TBase);
var
  i: Integer;
  soldier: TSoldier;
  ssStr, ssSkl: string;
  row: Integer;
begin
  inherited Create(nil);
  FBase := ABase;
  FSel := 0;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FTxtTitle := TText.Create(300, 17, 10, 8);
  FTxtRemaining := TText.Create(300, 10, 10, 24);
  FTxtName := TText.Create(64, 10, 10, 40);
  FTxtPsiStrength := TText.Create(80, 20, 124, 32);
  FTxtPsiSkill := TText.Create(80, 20, 188, 32);
  FTxtTraining := TText.Create(48, 20, 270, 32);
  FBtnOk := TTextButton.Create(160, 14, 80, 174);
  FLstSoldiers := TTextList.Create(290, 112, 8, 52);

  SetInterface('allocatePsi');

  Add(FWindow, 'window', 'allocatePsi');
  Add(FBtnOk, 'button', 'allocatePsi');
  Add(FTxtName, 'text', 'allocatePsi');
  Add(FTxtTitle, 'text', 'allocatePsi');
  Add(FTxtRemaining, 'text', 'allocatePsi');
  Add(FTxtPsiStrength, 'text', 'allocatePsi');
  Add(FTxtPsiSkill, 'text', 'allocatePsi');
  Add(FTxtTraining, 'text', 'allocatePsi');
  Add(FLstSoldiers, 'list', 'allocatePsi');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK01.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.keyCancel, BtnOkClick);

  FTxtTitle.Big := True;
  FTxtTitle.Align := ALIGN_CENTER;
  FTxtTitle.Text := Tr('STR_PSIONIC_TRAINING');

  FLabSpace := FBase.AvailablePsiLabs - FBase.UsedPsiLabs;
  FTxtRemaining.Text := Tr('STR_REMAINING_PSI_LAB_CAPACITY').Arg(FLabSpace);

  FTxtName.Text := Tr('STR_NAME');
  FTxtPsiStrength.Text := Tr('STR_PSIONIC__STRENGTH');
  FTxtPsiSkill.Text := Tr('STR_PSIONIC_SKILL_IMPROVEMENT');
  FTxtTraining.Text := Tr('STR_IN_TRAINING');

  FLstSoldiers.Align := ALIGN_RIGHT;
  FLstSoldiers.SetColumns(4, 114, 80, 62, 30);
  FLstSoldiers.Selectable := True;
  FLstSoldiers.Background := FWindow;
  FLstSoldiers.Margin := 2;
  FLstSoldiers.OnMouseClick := LstSoldiersClick;

  SetLength(FSoldiers, 0);
  row := 0;
  for i := 0 to FBase.Soldiers.Count - 1 do
  begin
    soldier := FBase.Soldiers[i];
    SetLength(FSoldiers, Length(FSoldiers) + 1);
    FSoldiers[High(FSoldiers)] := soldier;

    // Build strength string
    if (soldier.CurrentStats.PsiSkill > 0) or (Options.PsiStrengthEval and Game.SavedGame.IsResearched(Game.Mod.PsiRequirements)) then
      ssStr := '   ' + IntToStr(soldier.CurrentStats.PsiStrength) +
               IIf(Options.AllowPsiStrengthImprovement, '/+' + IntToStr(soldier.PsiStrImprovement), '')
    else
      ssStr := Tr('STR_UNKNOWN');

    // Build skill string
    if soldier.CurrentStats.PsiSkill > 0 then
      ssSkl := IntToStr(soldier.CurrentStats.PsiSkill) + '/+' + IntToStr(soldier.Improvement)
    else
      ssSkl := '0/+0';

    if soldier.IsInPsiTraining then
    begin
      FLstSoldiers.AddRow(4, [soldier.Name(True), ssStr, ssSkl, Tr('STR_YES')]);
      FLstSoldiers.SetRowColor(row, FLstSoldiers.SecondaryColor);
    end
    else
    begin
      FLstSoldiers.AddRow(4, [soldier.Name(True), ssStr, ssSkl, Tr('STR_NO')]);
      FLstSoldiers.SetRowColor(row, FLstSoldiers.Color);
    end;
    Inc(row);
  end;
end;

destructor TAllocatePsiTrainingState.Destroy;
begin
  // no dynamic allocations
  inherited;
end;

procedure TAllocatePsiTrainingState.BtnOkClick(AAction: TAction);
var
  i: Integer;
begin
  for i := 0 to FBase.Soldiers.Count - 1 do
    FBase.Soldiers[i].CalcStatString(Game.Mod.StatStrings,
      (Options.PsiStrengthEval and Game.SavedGame.IsResearched(Game.Mod.PsiRequirements)));
  Game.PopState;
end;

procedure TAllocatePsiTrainingState.LstSoldiersClick(AAction: TAction);
var
  sel: Integer;
  soldier: TSoldier;
begin
  sel := FLstSoldiers.SelectedRow;
  if sel < 0 then Exit;
  if AAction.Details.button.button = SDL_BUTTON_LEFT then
  begin
    soldier := FBase.Soldiers[sel];
    if not soldier.IsInPsiTraining then
    begin
      if FBase.UsedPsiLabs < FBase.AvailablePsiLabs then
      begin
        FLstSoldiers.SetCellText(sel, 3, Tr('STR_YES'));
        FLstSoldiers.SetRowColor(sel, FLstSoldiers.SecondaryColor);
        Dec(FLabSpace);
        FTxtRemaining.Text := Tr('STR_REMAINING_PSI_LAB_CAPACITY').Arg(FLabSpace);
        soldier.SetPsiTraining(True);
      end;
    end
    else
    begin
      FLstSoldiers.SetCellText(sel, 3, Tr('STR_NO'));
      FLstSoldiers.SetRowColor(sel, FLstSoldiers.Color);
      Inc(FLabSpace);
      FTxtRemaining.Text := Tr('STR_REMAINING_PSI_LAB_CAPACITY').Arg(FLabSpace);
      soldier.SetPsiTraining(False);
    end;
  end;
end;

end.