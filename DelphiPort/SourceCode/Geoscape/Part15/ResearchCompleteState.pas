unit ResearchCompleteState;

interface

uses
  System.SysUtils, System.Classes,
  Engine.State, Engine.Game, Engine.LocalizedText, Engine.Mod,
  Interface.TextButton, Interface.Window, Interface.Text,
  Mod.RuleResearch, Ufopaedia.Ufopaedia, Engine.Options;

type
  TResearchCompleteState = class(TState)
  private
    FWindow: TWindow;
    FTxtTitle, FTxtResearch: TText;
    FBtnReport, FBtnOk: TTextButton;
    FResearch: TRuleResearch;
    FBonus: TRuleResearch;
    procedure BtnOkClick(AAction: TAction);
    procedure BtnReportClick(AAction: TAction);
  public
    constructor Create(ANewResearch, ABonus, AResearch: TRuleResearch);
  end;

implementation

{ TResearchCompleteState }

constructor TResearchCompleteState.Create(ANewResearch, ABonus, AResearch: TRuleResearch);
var
  name: string;
  bonusName: string;
begin
  inherited Create(nil);
  FResearch := ANewResearch;
  FBonus := ABonus;
  FScreen := False;

  FWindow := TWindow.Create(Self, 230, 140, 45, 30, POPUP_BOTH);
  FBtnOk := TTextButton.Create(80, 16, 64, 146);
  FBtnReport := TTextButton.Create(80, 16, 176, 146);
  FTxtTitle := TText.Create(230, 17, 45, 70);
  FTxtResearch := TText.Create(230, 32, 45, 96);

  SetInterface('geoResearchComplete');

  Add(FWindow, 'window', 'geoResearchComplete');
  Add(FBtnOk, 'button', 'geoResearchComplete');
  Add(FBtnReport, 'button', 'geoResearchComplete');
  Add(FTxtTitle, 'text1', 'geoResearchComplete');
  Add(FTxtResearch, 'text2', 'geoResearchComplete');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK05.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.KeyCancel, BtnOkClick);

  FBtnReport.Text := Tr('STR_VIEW_REPORTS');
  FBtnReport.OnMouseClick := BtnReportClick;
  FBtnReport.OnKeyboardPress(Options.KeyOk, BtnReportClick);

  FTxtTitle.Big := True;
  FTxtTitle.Align := ALIGN_CENTER;
  FTxtTitle.Text := Tr('STR_RESEARCH_COMPLETED');

  FTxtResearch.Align := ALIGN_CENTER;
  FTxtResearch.Big := True;
  FTxtResearch.WordWrap := True;
  if Assigned(AResearch) then
    FTxtResearch.Text := Tr(AResearch.Name);
end;

procedure TResearchCompleteState.BtnOkClick(AAction: TAction);
begin
  Game.PopState;
end;

procedure TResearchCompleteState.BtnReportClick(AAction: TAction);
begin
  Game.PopState;
  if Assigned(FBonus) then
  begin
    if FBonus.Lookup.IsEmpty then
      Ufopaedia.OpenArticle(Game, FBonus.Name)
    else
      Ufopaedia.OpenArticle(Game, FBonus.Lookup);
  end;
  if Assigned(FResearch) then
  begin
    if FResearch.Lookup.IsEmpty then
      Ufopaedia.OpenArticle(Game, FResearch.Name)
    else
      Ufopaedia.OpenArticle(Game, FResearch.Lookup);
  end;
end;

end.