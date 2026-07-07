unit ResearchState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Savegame.Base, NewResearchListState, Savegame.ResearchProject,
  Mod.RuleResearch, ResearchInfoState;

type
  TResearchState = class(TState)
  private
    FBase: TBase;
    FBtnNew, FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtAvailable, FTxtAllocated, FTxtSpace,
    FTxtProject, FTxtScientists, FTxtProgress: TText;
    FLstResearch: TTextList;

    procedure FillProjectList;
    procedure OnSelectProject(Sender: TObject; Action: TAction);
  public
    constructor Create(AOwner: TComponent; Base: TBase);
    destructor Destroy; override;
    procedure Init; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure BtnNewClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TResearchState.Create(AOwner: TComponent; Base: TBase);
begin
  inherited Create(AOwner);
  FBase := Base;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnNew := TTextButton.Create(148, 16, 8, 176);
  FBtnOk := TTextButton.Create(148, 16, 164, 176);
  FTxtTitle := TText.Create(310, 17, 5, 8);
  FTxtAvailable := TText.Create(150, 9, 10, 24);
  FTxtAllocated := TText.Create(150, 9, 160, 24);
  FTxtSpace := TText.Create(300, 9, 10, 34);
  FTxtProject := TText.Create(110, 17, 10, 44);
  FTxtScientists := TText.Create(106, 17, 120, 44);
  FTxtProgress := TText.Create(84, 9, 226, 44);
  FLstResearch := TTextList.Create(288, 112, 8, 62);

  SetInterface('researchMenu');
  Add(FWindow, 'window', 'researchMenu');
  Add(FBtnNew, 'button', 'researchMenu');
  Add(FBtnOk, 'button', 'researchMenu');
  Add(FTxtTitle, 'text', 'researchMenu');
  Add(FTxtAvailable, 'text', 'researchMenu');
  Add(FTxtAllocated, 'text', 'researchMenu');
  Add(FTxtSpace, 'text', 'researchMenu');
  Add(FTxtProject, 'text', 'researchMenu');
  Add(FTxtScientists, 'text', 'researchMenu');
  Add(FTxtProgress, 'text', 'researchMenu');
  Add(FLstResearch, 'list', 'researchMenu');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK05.SCR'));
  FBtnNew.SetText(Translate('STR_NEW_PROJECT'));
  FBtnNew.OnMouseClick := BtnNewClick;
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;

  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetText(Translate('STR_CURRENT_RESEARCH'));
  FTxtProject.SetWordWrap(True);
  FTxtProject.SetText(Translate('STR_RESEARCH_PROJECT'));
  FTxtScientists.SetWordWrap(True);
  FTxtScientists.SetText(Translate('STR_SCIENTISTS_ALLOCATED_UC'));
  FTxtProgress.SetText(Translate('STR_PROGRESS'));

  FLstResearch.SetColumns([158, 58, 70]);
  FLstResearch.SetSelectable(True);
  FLstResearch.SetBackground(FWindow);
  FLstResearch.SetMargin(2);
  FLstResearch.SetWordWrap(True);
  FLstResearch.OnMouseClick := OnSelectProject;
end;

destructor TResearchState.Destroy;
begin
  inherited;
end;

procedure TResearchState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TResearchState.BtnNewClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TNewResearchListState.Create(Self, FBase));
end;

procedure TResearchState.OnSelectProject(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TResearchInfoState.Create(Self, FBase, FBase.GetResearch[FLstResearch.GetSelectedRow]));
end;

procedure TResearchState.Init;
begin
  inherited;
  FillProjectList;
end;

procedure TResearchState.FillProjectList;
var
  proj: TResearchProject;
  s: string;
begin
  FLstResearch.ClearList;
  for proj in FBase.GetResearch do
  begin
    s := IntToStr(proj.GetAssigned);
    FLstResearch.AddRow([Translate(proj.GetRules.GetName), s, Translate(proj.GetResearchProgress)]);
  end;
  FTxtAvailable.SetText(Translate('STR_SCIENTISTS_AVAILABLE').Arg(FBase.GetAvailableScientists));
  FTxtAllocated.SetText(Translate('STR_SCIENTISTS_ALLOCATED').Arg(FBase.GetAllocatedScientists));
  FTxtSpace.SetText(Translate('STR_LABORATORY_SPACE_AVAILABLE').Arg(FBase.GetFreeLaboratories));
end;

end.