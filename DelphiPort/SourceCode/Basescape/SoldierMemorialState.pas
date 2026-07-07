unit SoldierMemorialState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Savegame.SavedGame, Savegame.Base, Savegame.Soldier,
  Savegame.SoldierDeath, Savegame.GameTime,
  SoldierInfoState, Menu.StatisticsState;

type
  TSoldierMemorialState = class(TState)
  private
    FBtnOk, FBtnStatistics: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtName, FTxtRank, FTxtDate, FTxtRecruited, FTxtLost: TText;
    FLstSoldiers: TTextList;
  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure BtnStatisticsClick(Sender: TObject; Action: TAction);
    procedure LstSoldiersClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TSoldierMemorialState.Create(AOwner: TComponent);
var
  lost, recruited: Integer;
  dead: TSoldier;
begin
  inherited Create(AOwner);

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TTextButton.Create(148, 16, 164, 176);
  FBtnStatistics := TTextButton.Create(148, 16, 8, 176);
  FTxtTitle := TText.Create(310, 17, 5, 8);
  FTxtName := TText.Create(114, 9, 16, 36);
  FTxtRank := TText.Create(102, 9, 130, 36);
  FTxtDate := TText.Create(90, 9, 218, 36);
  FTxtRecruited := TText.Create(150, 9, 16, 24);
  FTxtLost := TText.Create(150, 9, 160, 24);
  FLstSoldiers := TTextList.Create(288, 120, 8, 44);

  SetInterface('soldierMemorial');
  Add(FWindow, 'window', 'soldierMemorial');
  Add(FBtnOk, 'button', 'soldierMemorial');
  Add(FBtnStatistics, 'button', 'soldierMemorial');
  Add(FTxtTitle, 'text', 'soldierMemorial');
  Add(FTxtName, 'text', 'soldierMemorial');
  Add(FTxtRank, 'text', 'soldierMemorial');
  Add(FTxtDate, 'text', 'soldierMemorial');
  Add(FTxtRecruited, 'text', 'soldierMemorial');
  Add(FTxtLost, 'text', 'soldierMemorial');
  Add(FLstSoldiers, 'list', 'soldierMemorial');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK02.SCR'));
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  FBtnStatistics.SetText(Translate('STR_STATISTICS'));
  FBtnStatistics.OnMouseClick := BtnStatisticsClick;

  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetText(Translate('STR_MEMORIAL'));
  FTxtName.SetText(Translate('STR_NAME_UC'));
  FTxtRank.SetText(Translate('STR_RANK'));
  FTxtDate.SetText(Translate('STR_DATE_UC'));

  lost := FGame.GetSavedGame.GetDeadSoldiers.Count;
  recruited := lost;
  for Base in FGame.GetSavedGame.GetBases do
    recruited := recruited + Base.GetTotalSoldiers;

  FTxtRecruited.SetText(Translate('STR_SOLDIERS_RECRUITED_UC').Arg(recruited));
  FTxtLost.SetText(Translate('STR_SOLDIERS_LOST_UC').Arg(lost));

  FLstSoldiers.SetColumns([114, 88, 30, 25, 35]);
  FLstSoldiers.SetSelectable(True);
  FLstSoldiers.SetBackground(FWindow);
  FLstSoldiers.SetMargin(8);
  FLstSoldiers.OnMouseClick := LstSoldiersClick;

  for dead in FGame.GetSavedGame.GetDeadSoldiers do
  begin
    var death := dead.GetDeath;
    FLstSoldiers.AddRow([
      dead.GetName,
      Translate(dead.GetRankString),
      death.GetTime.GetDayString(FGame.GetLanguage),
      Translate(death.GetTime.GetMonthString),
      IntToStr(death.GetTime.GetYear)
    ]);
  end;
end;

destructor TSoldierMemorialState.Destroy;
begin
  inherited;
end;

procedure TSoldierMemorialState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
  FGame.GetMod.PlayMusic('GMGEO');
end;

procedure TSoldierMemorialState.BtnStatisticsClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TStatisticsState.Create(Self));
end;

procedure TSoldierMemorialState.LstSoldiersClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TSoldierInfoState.Create(Self, nil, FLstSoldiers.GetSelectedRow));
end;

end.