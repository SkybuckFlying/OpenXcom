unit NewResearchListState;

interface

uses
  Classes, SysUtils, Generics.Collections,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Savegame.SavedGame, Savegame.Base, Mod.RuleResearch,
  ResearchInfoState;

type
  TNewResearchListState = class(TState)
  private
    FBase: TBase;
    FBtnOK: TTextButton;
    FWindow: TWindow;
    FTxtTitle: TText;
    FLstResearch: TTextList;
    FProjects: TList<TRuleResearch>;

    procedure OnSelectProject(Sender: TObject; Action: TAction);
    procedure FillProjectList;
  public
    constructor Create(AOwner: TComponent; Base: TBase);
    destructor Destroy; override;
    procedure Init; override;
    procedure BtnOKClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TNewResearchListState.Create(AOwner: TComponent; Base: TBase);
begin
  inherited Create(AOwner);
  FBase := Base;
  Screen := False;

  FWindow := TWindow.Create(Self, 230, 140, 45, 30, POPUP_BOTH);
  FBtnOK := TTextButton.Create(214, 16, 53, 146);
  FTxtTitle := TText.Create(214, 16, 53, 38);
  FLstResearch := TTextList.Create(198, 88, 53, 54);

  SetInterface('selectNewResearch');
  Add(FWindow, 'window', 'selectNewResearch');
  Add(FBtnOK, 'button', 'selectNewResearch');
  Add(FTxtTitle, 'text', 'selectNewResearch');
  Add(FLstResearch, 'list', 'selectNewResearch');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK05.SCR'));
  FBtnOK.SetText(Translate('STR_OK'));
  FBtnOK.OnMouseClick := BtnOKClick;
  FBtnOK.OnKeyboardPress := BtnOKClick;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetText(Translate('STR_NEW_RESEARCH_PROJECTS'));

  FLstResearch.SetColumns([190]);
  FLstResearch.SetSelectable(True);
  FLstResearch.SetBackground(FWindow);
  FLstResearch.SetMargin(8);
  FLstResearch.SetAlign(ALIGN_CENTER);
  FLstResearch.OnMouseClick := OnSelectProject;
end;

destructor TNewResearchListState.Destroy;
begin
  FProjects.Free;
  inherited;
end;

procedure TNewResearchListState.Init;
begin
  inherited;
  FillProjectList;
end;

procedure TNewResearchListState.OnSelectProject(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TResearchInfoState.Create(Self, FBase, FProjects[FLstResearch.GetSelectedRow]));
end;

procedure TNewResearchListState.BtnOKClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TNewResearchListState.FillProjectList;
var
  rule: TRuleResearch;
begin
  FProjects := TList<TRuleResearch>.Create;
  FLstResearch.ClearList;
  FGame.GetSavedGame.GetAvailableResearchProjects(FProjects, FGame.GetMod, FBase, True);
  for rule in FProjects do
  begin
    // Only projects without requirements (see C++ explanation)
    if rule.GetRequirements.IsEmpty then
      FLstResearch.AddRow([Translate(rule.GetName)])
    else
      // remove from list
      FProjects.Remove(rule); // but we can't modify while iterating; better use an index loop
  end;
  // Since we can't remove while iterating, we recreate list
  var temp := TList<TRuleResearch>.Create;
  try
    for rule in FProjects do
      if rule.GetRequirements.IsEmpty then
        temp.Add(rule);
    FProjects.Free;
    FProjects := temp;
    FLstResearch.ClearList;
    for rule in FProjects do
      FLstResearch.AddRow([Translate(rule.GetName)]);
  except
    temp.Free;
  end;
end;

end.