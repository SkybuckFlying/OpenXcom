unit TransfersState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Savegame.Base, Savegame.Transfer;

type
  TTransfersState = class(TState)
  private
    FBase: TBase;
    FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtItem, FTxtQuantity, FTxtArrivalTime: TText;
    FLstTransfers: TTextList;
  public
    constructor Create(AOwner: TComponent; Base: TBase);
    destructor Destroy; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TTransfersState.Create(AOwner: TComponent; Base: TBase);
begin
  inherited Create(AOwner);
  FBase := Base;
  Screen := False;

  FWindow := TWindow.Create(Self, 320, 184, 0, 8, POPUP_BOTH);
  FBtnOk := TTextButton.Create(288, 16, 16, 166);
  FTxtTitle := TText.Create(278, 17, 21, 18);
  FTxtItem := TText.Create(114, 9, 16, 34);
  FTxtQuantity := TText.Create(54, 9, 152, 34);
  FTxtArrivalTime := TText.Create(112, 9, 212, 34);
  FLstTransfers := TTextList.Create(273, 112, 14, 50);

  SetInterface('transferInfo');
  Add(FWindow, 'window', 'transferInfo');
  Add(FBtnOk, 'button', 'transferInfo');
  Add(FTxtTitle, 'text', 'transferInfo');
  Add(FTxtItem, 'text', 'transferInfo');
  Add(FTxtQuantity, 'text', 'transferInfo');
  Add(FTxtArrivalTime, 'text', 'transferInfo');
  Add(FLstTransfers, 'list', 'transferInfo');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK13.SCR'));
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;

  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetText(Translate('STR_TRANSFERS'));
  FTxtItem.SetText(Translate('STR_ITEM'));
  FTxtQuantity.SetText(Translate('STR_QUANTITY_UC'));
  FTxtArrivalTime.SetText(Translate('STR_ARRIVAL_TIME_HOURS'));

  FLstTransfers.SetColumns([155, 75, 46]);
  FLstTransfers.SetSelectable(True);
  FLstTransfers.SetBackground(FWindow);
  FLstTransfers.SetMargin(2);

  for t in FBase.GetTransfers do
    FLstTransfers.AddRow([
      t.GetName(FGame.GetLanguage),
      IntToStr(t.GetQuantity),
      IntToStr(t.GetHours)
    ]);
end;

destructor TTransfersState.Destroy;
begin
  inherited;
end;

procedure TTransfersState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

end.