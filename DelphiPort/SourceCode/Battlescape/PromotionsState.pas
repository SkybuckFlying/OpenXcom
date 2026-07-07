unit PromotionsState;

interface

uses
  Classes, SysUtils,
  Engine.State,
  Engine.Game,
  Engine.Action,
  Engine.Options,
  Mod.Mod,
  Interface.TextButton,
  Interface.Window,
  Interface.Text,
  Interface.TextList;

type
  TPromotionsState = class(TState)
  private
    FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtName, FTxtRank, FTxtBase: TText;
    FLstSoldiers: TTextList;
    procedure BtnOkClick(Action: TAction);
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  Savegame.SavedGame,
  Savegame.Base,
  Savegame.Soldier;

{ TPromotionsState }

constructor TPromotionsState.Create;
var
  Base: TBase;
  Soldier: TSoldier;
begin
  inherited Create;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TTextButton.Create(288, 16, 16, 176);
  FTxtTitle := TText.Create(300, 17, 10, 8);
  FTxtName := TText.Create(114, 9, 16, 32);
  FTxtRank := TText.Create(90, 9, 130, 32);
  FTxtBase := TText.Create(80, 9, 220, 32);
  FLstSoldiers := TTextList.Create(288, 128, 8, 40);

  SetInterface('promotions');

  Add(FWindow, 'window', 'promotions');
  Add(FBtnOk, 'button', 'promotions');
  Add(FTxtTitle, 'heading', 'promotions');
  Add(FTxtName, 'text', 'promotions');
  Add(FTxtRank, 'text', 'promotions');
  Add(FTxtBase, 'text', 'promotions');
  Add(FLstSoldiers, 'list', 'promotions');

  CenterAllSurfaces;

  FWindow.Background := FGame.Mod.Surface['BACK01.SCR'];

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.KeyOk, BtnOkClick);
  FBtnOk.OnKeyboardPress(Options.KeyCancel, BtnOkClick);

  FTxtTitle.Text := Tr('STR_PROMOTIONS');
  FTxtTitle.Align := ALIGN_CENTER;
  FTxtTitle.Big := True;

  FTxtName.Text := Tr('STR_NAME');
  FTxtRank.Text := Tr('STR_NEW_RANK');
  FTxtBase.Text := Tr('STR_BASE');

  FLstSoldiers.SetColumns(3, 114, 90, 84);
  FLstSoldiers.Selectable := True;
  FLstSoldiers.Background := FWindow;
  FLstSoldiers.Margin := 8;

  for Base in FGame.SavedGame.Bases do
    for Soldier in Base.Soldiers do
      if Soldier.IsPromoted then
        FLstSoldiers.AddRow([Soldier.Name, Tr(Soldier.RankString), Base.Name]);
end;

destructor TPromotionsState.Destroy;
begin
  inherited;
end;

procedure TPromotionsState.BtnOkClick(Action: TAction);
begin
  FGame.PopState;
end;

end.