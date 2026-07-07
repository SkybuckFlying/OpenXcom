unit ResearchInfoState;

interface

uses
  Classes, SysUtils, Math,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Interface.TextButton, Interface.Window, Interface.Text,
  Interface.ArrowButton, Engine.Timer, Engine.RNG,
  Savegame.Base, Mod.RuleResearch, Savegame.ResearchProject,
  Savegame.ItemContainer;

type
  TResearchInfoState = class(TState)
  private
    FBase: TBase;
    FProject: TResearchProject;
    FRule: TRuleResearch;
    FWindow: TWindow;
    FBtnOk, FBtnCancel: TTextButton;
    FBtnMore, FBtnLess: TArrowButton;
    FTxtTitle, FTxtAvailableScientist, FTxtAvailableSpace,
    FTxtAllocatedScientist, FTxtMore, FTxtLess: TText;
    FSurfaceScientists: TInteractiveSurface;
    FTimerMore, FTimerLess: TTimer;

    procedure SetAssignedScientist;
    procedure BuildUi;
    procedure MoreByValue(Change: Integer);
    procedure LessByValue(Change: Integer);
  public
    constructor Create(AOwner: TComponent; Base: TBase; Rule: TRuleResearch); overload;
    constructor Create(AOwner: TComponent; Base: TBase; Project: TResearchProject); overload;
    destructor Destroy; override;
    procedure Think; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure BtnCancelClick(Sender: TObject; Action: TAction);
    procedure HandleWheel(Sender: TObject; Action: TAction);
    procedure MorePress(Sender: TObject; Action: TAction);
    procedure MoreRelease(Sender: TObject; Action: TAction);
    procedure MoreClick(Sender: TObject; Action: TAction);
    procedure LessPress(Sender: TObject; Action: TAction);
    procedure LessRelease(Sender: TObject; Action: TAction);
    procedure LessClick(Sender: TObject; Action: TAction);
    procedure More;
    procedure Less;
  end;

implementation

constructor TResearchInfoState.Create(AOwner: TComponent; Base: TBase; Rule: TRuleResearch);
begin
  FBase := Base;
  FRule := Rule;
  FProject := TResearchProject.Create(Rule, Round(Rule.GetCost * RNG.Generate(50, 150) / 100));
  BuildUi;
end;

constructor TResearchInfoState.Create(AOwner: TComponent; Base: TBase; Project: TResearchProject);
begin
  FBase := Base;
  FRule := nil;
  FProject := Project;
  BuildUi;
end;

procedure TResearchInfoState.BuildUi;
begin
  inherited Create(nil);
  Screen := False;

  FWindow := TWindow.Create(Self, 230, 140, 45, 30);
  FTxtTitle := TText.Create(210, 17, 61, 40);
  FTxtAvailableScientist := TText.Create(210, 9, 61, 60);
  FTxtAvailableSpace := TText.Create(210, 9, 61, 70);
  FTxtAllocatedScientist := TText.Create(210, 17, 61, 80);
  FTxtMore := TText.Create(110, 17, 85, 100);
  FTxtLess := TText.Create(110, 17, 85, 120);
  FBtnCancel := TTextButton.Create(90, 16, 61, 145);
  FBtnOk := TTextButton.Create(90, 16, 169, 145);
  FBtnMore := TArrowButton.Create(ARROW_BIG_UP, 13, 14, 195, 100);
  FBtnLess := TArrowButton.Create(ARROW_BIG_DOWN, 13, 14, 195, 120);
  FSurfaceScientists := TInteractiveSurface.Create(230, 140, 45, 30);
  FSurfaceScientists.OnMouseClick := HandleWheel;

  SetInterface('allocateResearch');
  Add(FSurfaceScientists);
  Add(FWindow, 'window', 'allocateResearch');
  Add(FBtnOk, 'button2', 'allocateResearch');
  Add(FBtnCancel, 'button2', 'allocateResearch');
  Add(FTxtTitle, 'text', 'allocateResearch');
  Add(FTxtAvailableScientist, 'text', 'allocateResearch');
  Add(FTxtAvailableSpace, 'text', 'allocateResearch');
  Add(FTxtAllocatedScientist, 'text', 'allocateResearch');
  Add(FTxtMore, 'text', 'allocateResearch');
  Add(FTxtLess, 'text', 'allocateResearch');
  Add(FBtnMore, 'button1', 'allocateResearch');
  Add(FBtnLess, 'button1', 'allocateResearch');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK05.SCR'));
  FTxtTitle.SetBig;
  if FRule <> nil then
    FTxtTitle.SetText(Translate(FRule.GetName))
  else
    FTxtTitle.SetText(Translate(FProject.GetRules.GetName));
  FTxtAllocatedScientist.SetBig;
  FTxtMore.SetText(Translate('STR_INCREASE'));
  FTxtLess.SetText(Translate('STR_DECREASE'));
  FTxtMore.SetBig;
  FTxtLess.SetBig;

  if FRule <> nil then
  begin
    FBase.AddResearch(FProject);
    if FRule.NeedItem and FRule.DestroyItem then
      FBase.GetStorageItems.RemoveItem(FRule.GetName, 1);
  end;
  SetAssignedScientist;

  FBtnMore.OnMousePress := MorePress;
  FBtnMore.OnMouseRelease := MoreRelease;
  FBtnMore.OnMouseClick := MoreClick;
  FBtnLess.OnMousePress := LessPress;
  FBtnLess.OnMouseRelease := LessRelease;
  FBtnLess.OnMouseClick := LessClick;

  FTimerMore := TTimer.Create(250);
  FTimerMore.OnTimer := More;
  FTimerLess := TTimer.Create(250);
  FTimerLess.OnTimer := Less;

  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  if FRule <> nil then
  begin
    FBtnOk.SetText(Translate('STR_START_PROJECT'));
    FBtnCancel.SetText(Translate('STR_CANCEL_UC'));
    FBtnCancel.OnKeyboardPress := BtnCancelClick;
  end
  else
  begin
    FBtnOk.SetText(Translate('STR_OK'));
    FBtnCancel.SetText(Translate('STR_CANCEL_PROJECT'));
    FBtnOk.OnKeyboardPress := BtnOkClick;
  end;
  FBtnCancel.OnMouseClick := BtnCancelClick;
end;

destructor TResearchInfoState.Destroy;
begin
  FTimerMore.Free;
  FTimerLess.Free;
  inherited;
end;

procedure TResearchInfoState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TResearchInfoState.BtnCancelClick(Sender: TObject; Action: TAction);
begin
  FBase.RemoveResearch(FProject);
  FGame.PopState;
end;

procedure TResearchInfoState.SetAssignedScientist;
begin
  FTxtAvailableScientist.SetText(Translate('STR_SCIENTISTS_AVAILABLE_UC').Arg(FBase.GetAvailableScientists));
  FTxtAvailableSpace.SetText(Translate('STR_LABORATORY_SPACE_AVAILABLE_UC').Arg(FBase.GetFreeLaboratories));
  FTxtAllocatedScientist.SetText(Translate('STR_SCIENTISTS_ALLOCATED').Arg(FProject.GetAssigned));
end;

procedure TResearchInfoState.HandleWheel(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_WHEELUP then
    MoreByValue(Options.ChangeValueByMouseWheel)
  else if Action.GetDetails.button.button = SDL_BUTTON_WHEELDOWN then
    LessByValue(Options.ChangeValueByMouseWheel);
end;

procedure TResearchInfoState.MorePress(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then FTimerMore.Start;
end;

procedure TResearchInfoState.MoreRelease(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
  begin
    FTimerMore.SetInterval(250);
    FTimerMore.Stop;
  end;
end;

procedure TResearchInfoState.MoreClick(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_RIGHT then
    MoreByValue(MaxInt)
  else if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
    MoreByValue(1);
end;

procedure TResearchInfoState.LessPress(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then FTimerLess.Start;
end;

procedure TResearchInfoState.LessRelease(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
  begin
    FTimerLess.SetInterval(250);
    FTimerLess.Stop;
  end;
end;

procedure TResearchInfoState.LessClick(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_RIGHT then
    LessByValue(MaxInt)
  else if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
    LessByValue(1);
end;

procedure TResearchInfoState.More;
begin
  FTimerMore.SetInterval(50);
  MoreByValue(1);
end;

procedure TResearchInfoState.MoreByValue(Change: Integer);
var
  freeScientists, freeSpace: Integer;
begin
  if Change <= 0 then Exit;
  freeScientists := FBase.GetAvailableScientists;
  freeSpace := FBase.GetFreeLaboratories;
  if (freeScientists > 0) and (freeSpace > 0) then
  begin
    Change := Min(Min(freeScientists, freeSpace), Change);
    FProject.SetAssigned(FProject.GetAssigned + Change);
    FBase.SetScientists(FBase.GetScientists - Change);
    SetAssignedScientist;
  end;
end;

procedure TResearchInfoState.Less;
begin
  FTimerLess.SetInterval(50);
  LessByValue(1);
end;

procedure TResearchInfoState.LessByValue(Change: Integer);
var
  assigned: Integer;
begin
  if Change <= 0 then Exit;
  assigned := FProject.GetAssigned;
  if assigned > 0 then
  begin
    Change := Min(assigned, Change);
    FProject.SetAssigned(assigned - Change);
    FBase.SetScientists(FBase.GetScientists + Change);
    SetAssignedScientist;
  end;
end;

procedure TResearchInfoState.Think;
begin
  inherited;
  FTimerMore.Think(Self, 0);
  FTimerLess.Think(Self, 0);
end;

end.