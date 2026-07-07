unit NewPossibleResearchState;

interface

uses
  System.SysUtils, System.Classes,
  Engine.State, Engine.Game, Engine.LocalizedText, Engine.Mod,
  Interface.TextButton, Interface.Window, Interface.Text,
  Interface.TextList, Mod.RuleResearch, Basescape.ResearchState,
  Savegame.SavedGame, Savegame.Base, Engine.Options;

type
  TNewPossibleResearchState = class(TState)
  private
    FWindow: TWindow;
    FTxtTitle: TText;
    FLstPossibilities: TTextList;
    FBtnResearch, FBtnOk: TTextButton;
    FBase: TBase;
    procedure BtnOkClick(AAction: TAction);
    procedure BtnResearchClick(AAction: TAction);
  public
    constructor Create(ABase: TBase; const APossibilities: TList);
  end;

implementation

{ TNewPossibleResearchState }

constructor TNewPossibleResearchState.Create(ABase: TBase; const APossibilities: TList);
var
  i: Integer;
  rule: TRuleResearch;
  foundNew: Boolean;
begin
  inherited Create(nil);
  FBase := ABase;
  FScreen := False;

  FWindow := TWindow.Create(Self, 288, 180, 16, 10);
  FBtnOk := TTextButton.Create(160, 14, 80, 149);
  FBtnResearch := TTextButton.Create(160, 14, 80, 165);
  FTxtTitle := TText.Create(288, 40, 16, 20);
  FLstPossibilities := TTextList.Create(250, 96, 35, 50);

  SetInterface('geoResearch');

  Add(FWindow, 'window', 'geoResearch');
  Add(FBtnOk, 'button', 'geoResearch');
  Add(FBtnResearch, 'button', 'geoResearch');
  Add(FTxtTitle, 'text1', 'geoResearch');
  Add(FLstPossibilities, 'text2', 'geoResearch');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK05.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.KeyCancel, BtnOkClick);

  FBtnResearch.Text := Tr('STR_ALLOCATE_RESEARCH');
  FBtnResearch.OnMouseClick := BtnResearchClick;
  FBtnResearch.OnKeyboardPress(Options.KeyOk, BtnResearchClick);

  FTxtTitle.Big := True;
  FTxtTitle.Align := ALIGN_CENTER;

  FLstPossibilities.SetColumns(1, 250);
  FLstPossibilities.Big := True;
  FLstPossibilities.Align := ALIGN_CENTER;
  FLstPossibilities.Scrolling := True;
  FLstPossibilities.ScrollAmount := 0;

  foundNew := False;
  for i := 0 to APossibilities.Count - 1 do
  begin
    rule := TRuleResearch(APossibilities[i]);
    // Only show topics without requirements (that are directly researchable)
    // and that haven't been popped or already researched
    if (rule.Requirements.Count = 0) and
       (not Game.SavedGame.WasResearchPopped(rule)) and
       (not Game.SavedGame.IsResearched(rule.Name, False)) then
    begin
      Game.SavedGame.AddPoppedResearch(rule);
      FLstPossibilities.AddRow(1, [Tr(rule.Name)]);
      foundNew := True;
    end;
  end;

  if foundNew then
    FTxtTitle.Text := Tr('STR_WE_CAN_NOW_RESEARCH');
end;

procedure TNewPossibleResearchState.BtnOkClick(AAction: TAction);
begin
  Game.PopState;
end;

procedure TNewPossibleResearchState.BtnResearchClick(AAction: TAction);
begin
  Game.PopState;
  Game.PushState(TResearchState.Create(FBase));
end;

end.