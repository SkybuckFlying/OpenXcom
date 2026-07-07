unit StoresState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Savegame.Base, Mod.RuleItem, Savegame.ItemContainer;

type
  TStoresState = class(TState)
  private
    FBase: TBase;
    FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtItem, FTxtQuantity, FTxtSpaceUsed: TText;
    FLstStores: TTextList;
  public
    constructor Create(AOwner: TComponent; Base: TBase);
    destructor Destroy; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TStoresState.Create(AOwner: TComponent; Base: TBase);
var
  items: TStringList;
  i: Integer;
  rule: TRuleItem;
  qty: Integer;
begin
  inherited Create(AOwner);
  FBase := Base;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TTextButton.Create(300, 16, 10, 176);
  FTxtTitle := TText.Create(310, 17, 5, 8);
  FTxtItem := TText.Create(142, 9, 10, 32);
  FTxtQuantity := TText.Create(88, 9, 152, 32);
  FTxtSpaceUsed := TText.Create(74, 9, 240, 32);
  FLstStores := TTextList.Create(288, 128, 8, 40);

  SetInterface('storesInfo');
  Add(FWindow, 'window', 'storesInfo');
  Add(FBtnOk, 'button', 'storesInfo');
  Add(FTxtTitle, 'text', 'storesInfo');
  Add(FTxtItem, 'text', 'storesInfo');
  Add(FTxtQuantity, 'text', 'storesInfo');
  Add(FTxtSpaceUsed, 'text', 'storesInfo');
  Add(FLstStores, 'list', 'storesInfo');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK13.SCR'));
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;

  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetText(Translate('STR_STORES'));
  FTxtItem.SetText(Translate('STR_ITEM'));
  FTxtQuantity.SetText(Translate('STR_QUANTITY_UC'));
  FTxtSpaceUsed.SetText(Translate('STR_SPACE_USED_UC'));

  FLstStores.SetColumns([162, 92, 32]);
  FLstStores.SetSelectable(True);
  FLstStores.SetBackground(FWindow);
  FLstStores.SetMargin(2);

  items := FGame.GetMod.GetItemsList;
  for i := 0 to items.Count - 1 do
  begin
    qty := FBase.GetStorageItems.GetItem(items[i]);
    if qty > 0 then
    begin
      rule := FGame.GetMod.GetItem(items[i], True);
      FLstStores.AddRow([
        Translate(items[i]),
        IntToStr(qty),
        IntToStr(qty * rule.GetSize)
      ]);
    end;
  end;
end;

destructor TStoresState.Destroy;
begin
  inherited;
end;

procedure TStoresState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

end.