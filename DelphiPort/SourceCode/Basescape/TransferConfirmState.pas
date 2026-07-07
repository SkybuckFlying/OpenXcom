unit TransferConfirmState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options, Engine.Unicode,
  Interface.TextButton, Interface.Window, Interface.Text,
  Savegame.Base, TransferItemsState;

type
  TTransferConfirmState = class(TState)
  private
    FBase: TBase;
    FState: TTransferItemsState;
    FBtnCancel, FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtCost, FTxtTotal: TText;
  public
    constructor Create(AOwner: TComponent; Base: TBase; State: TTransferItemsState);
    destructor Destroy; override;
    procedure BtnCancelClick(Sender: TObject; Action: TAction);
    procedure BtnOkClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TTransferConfirmState.Create(AOwner: TComponent; Base: TBase; State: TTransferItemsState);
begin
  inherited Create(AOwner);
  FBase := Base;
  FState := State;
  Screen := False;

  FWindow := TWindow.Create(Self, 320, 80, 0, 60);
  FBtnCancel := TTextButton.Create(128, 16, 176, 115);
  FBtnOk := TTextButton.Create(128, 16, 16, 115);
  FTxtTitle := TText.Create(310, 17, 5, 75);
  FTxtCost := TText.Create(60, 17, 110, 95);
  FTxtTotal := TText.Create(100, 17, 170, 95);

  SetInterface('transferConfirm');
  Add(FWindow, 'window', 'transferConfirm');
  Add(FBtnCancel, 'button', 'transferConfirm');
  Add(FBtnOk, 'button', 'transferConfirm');
  Add(FTxtTitle, 'text', 'transferConfirm');
  Add(FTxtCost, 'text', 'transferConfirm');
  Add(FTxtTotal, 'text', 'transferConfirm');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK13.SCR'));
  FBtnCancel.SetText(Translate('STR_CANCEL_UC'));
  FBtnCancel.OnMouseClick := BtnCancelClick;
  FBtnCancel.OnKeyboardPress := BtnCancelClick;
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;

  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetText(Translate('STR_TRANSFER_ITEMS_TO').Arg(FBase.GetName));
  FTxtCost.SetBig;
  FTxtCost.SetText(Translate('STR_COST'));
  FTxtTotal.SetBig;
  FTxtTotal.SetText(Unicode.TOK_COLOR_FLIP + Unicode.FormatFunding(FState.GetTotal));
end;

destructor TTransferConfirmState.Destroy;
begin
  inherited;
end;

procedure TTransferConfirmState.BtnCancelClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TTransferConfirmState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FState.CompleteTransfer;
  FGame.PopState;
  FGame.PopState;
  FGame.PopState;
end;

end.