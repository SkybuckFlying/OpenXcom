unit SoldiersState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Geoscape.AllocatePsiTrainingState,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Savegame.Base, Savegame.Soldier,
  SoldierInfoState, SoldierMemorialState;

type
  TSoldiersState = class(TState)
  private
    FBase: TBase;
    FBtnOk, FBtnPsiTraining, FBtnMemorial: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtName, FTxtRank, FTxtCraft: TText;
    FLstSoldiers: TTextList;
  public
    constructor Create(AOwner: TComponent; Base: TBase);
    destructor Destroy; override;
    procedure Init; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure BtnPsiTrainingClick(Sender: TObject; Action: TAction);
    procedure BtnMemorialClick(Sender: TObject; Action: TAction);
    procedure LstSoldiersClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TSoldiersState.Create(AOwner: TComponent; Base: TBase);
var
  isPsiBtnVisible: Boolean;
begin
  inherited Create(AOwner);
  FBase := Base;
  isPsiBtnVisible := Options.AnytimePsiTraining and (FBase.GetAvailablePsiLabs > 0);

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  if isPsiBtnVisible then
  begin
    FBtnOk := TTextButton.Create(96, 16, 216, 176);
    FBtnPsiTraining := TTextButton.Create(96, 16, 112, 176);
    FBtnMemorial := TTextButton.Create(96, 16, 8, 176);
  end
  else
  begin
    FBtnOk := TTextButton.Create(148, 16, 164, 176);
    FBtnPsiTraining := TTextButton.Create(148, 16, 164, 176);
    FBtnMemorial := TTextButton.Create(148, 16, 8, 176);
  end;
  FTxtTitle := TText.Create(310, 17, 5, 8);
  FTxtName := TText.Create(114, 9, 16, 32);
  FTxtRank := TText.Create(102, 9, 130, 32);
  FTxtCraft := TText.Create(82, 9, 222, 32);
  FLstSoldiers := TTextList.Create(288, 128, 8, 40);

  SetInterface('soldierList');
  Add(FWindow, 'window', 'soldierList');
  Add(FBtnOk, 'button', 'soldierList');
  Add(FBtnPsiTraining, 'button', 'soldierList');
  Add(FBtnMemorial, 'button', 'soldierList');
  Add(FTxtTitle, 'text1', 'soldierList');
  Add(FTxtName, 'text2', 'soldierList');
  Add(FTxtRank, 'text2', 'soldierList');
  Add(FTxtCraft, 'text2', 'soldierList');
  Add(FLstSoldiers, 'list', 'soldierList');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK02.SCR'));
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;

  FBtnPsiTraining.SetText(Translate('STR_PSI_TRAINING'));
  FBtnPsiTraining.OnMouseClick := BtnPsiTrainingClick;
  FBtnPsiTraining.Visible := isPsiBtnVisible;

  FBtnMemorial.SetText(Translate('STR_MEMORIAL'));
  FBtnMemorial.OnMouseClick := BtnMemorialClick;

  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetText(Translate('STR_SOLDIER_LIST'));
  FTxtName.SetText(Translate('STR_NAME_UC'));
  FTxtRank.SetText(Translate('STR_RANK'));
  FTxtCraft.SetText(Translate('STR_CRAFT'));

  FLstSoldiers.SetColumns([114, 92, 74]);
  FLstSoldiers.SetSelectable(True);
  FLstSoldiers.SetBackground(FWindow);
  FLstSoldiers.SetMargin(8);
  FLstSoldiers.OnMouseClick := LstSoldiersClick;
end;

destructor TSoldiersState.Destroy;
begin
  inherited;
end;

procedure TSoldiersState.Init;
var
  row: Integer;
  s: TSoldier;
begin
  inherited;
  row := 0;
  FLstSoldiers.ClearList;
  for s in FBase.GetSoldiers do
  begin
    FLstSoldiers.AddRow([s.GetName(True), Translate(s.GetRankString), s.GetCraftString(FGame.GetLanguage)]);
    if s.GetCraft = nil then
      FLstSoldiers.SetRowColor(row, FLstSoldiers.GetSecondaryColor);
    Inc(row);
  end;
  if (row > 0) and (FLstSoldiers.GetScroll >= row) then
    FLstSoldiers.ScrollTo(0);
end;

procedure TSoldiersState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TSoldiersState.BtnPsiTrainingClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TAllocatePsiTrainingState.Create(Self, FBase));
end;

procedure TSoldiersState.BtnMemorialClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TSoldierMemorialState.Create(Self));
end;

procedure TSoldiersState.LstSoldiersClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TSoldierInfoState.Create(Self, FBase, FLstSoldiers.GetSelectedRow));
end;

end.