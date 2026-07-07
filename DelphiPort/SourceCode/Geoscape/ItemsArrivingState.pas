unit ItemsArrivingState;

interface

uses
  System.SysUtils, System.Classes,
  Engine.State, Engine.Game, Engine.Mod, Engine.LocalizedText,
  Interface.TextButton, Interface.Window, Interface.Text,
  Interface.TextList, Savegame.SavedGame, Savegame.Base,
  Savegame.ItemContainer, Savegame.Transfer, Savegame.Craft,
  Savegame.CraftWeapon, Savegame.Vehicle, Mod.RuleItem,
  Mod.RuleCraftWeapon, Geoscape.GeoscapeState, Engine.Options,
  Basescape.BasescapeState;

type
  TItemsArrivingState = class(TState)
  private
    FState: TGeoscapeState;
    FBase: TBase;
    FBtnOk, FBtnGotoBase: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtItem, FTxtQuantity, FTxtDestination: TText;
    FLstTransfers: TTextList;
    procedure BtnOkClick(AAction: TAction);
    procedure BtnGotoBaseClick(AAction: TAction);
  public
    constructor Create(AState: TGeoscapeState);
    destructor Destroy; override;
  end;

implementation

{ TItemsArrivingState }

constructor TItemsArrivingState.Create(AState: TGeoscapeState);
var
  b: TBase;
  t: TTransfer;
  ss: string;
begin
  inherited Create(nil);
  FState := AState;
  FScreen := False;

  FWindow := TWindow.Create(Self, 320, 184, 0, 8, POPUP_BOTH);
  FBtnOk := TTextButton.Create(142, 16, 16, 166);
  FBtnGotoBase := TTextButton.Create(142, 16, 162, 166);
  FTxtTitle := TText.Create(310, 17, 5, 18);
  FTxtItem := TText.Create(114, 9, 16, 34);
  FTxtQuantity := TText.Create(54, 9, 152, 34);
  FTxtDestination := TText.Create(112, 9, 212, 34);
  FLstTransfers := TTextList.Create(271, 112, 14, 50);

  SetInterface('itemsArriving');

  Add(FWindow, 'window', 'itemsArriving');
  Add(FBtnOk, 'button', 'itemsArriving');
  Add(FBtnGotoBase, 'button', 'itemsArriving');
  Add(FTxtTitle, 'text1', 'itemsArriving');
  Add(FTxtItem, 'text1', 'itemsArriving');
  Add(FTxtQuantity, 'text1', 'itemsArriving');
  Add(FTxtDestination, 'text1', 'itemsArriving');
  Add(FLstTransfers, 'text2', 'itemsArriving');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK13.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.KeyCancel, BtnOkClick);

  FBtnGotoBase.Text := Tr('STR_GO_TO_BASE');
  FBtnGotoBase.OnMouseClick := BtnGotoBaseClick;
  FBtnGotoBase.OnKeyboardPress(Options.KeyOk, BtnGotoBaseClick);

  FTxtTitle.Big := True;
  FTxtTitle.Align := ALIGN_CENTER;
  FTxtTitle.Text := Tr('STR_ITEMS_ARRIVING');

  FTxtItem.Text := Tr('STR_ITEM');
  FTxtQuantity.Text := Tr('STR_QUANTITY_UC');
  FTxtDestination.Text := Tr('STR_DESTINATION_UC');

  FLstTransfers.SetColumns(3, 155, 41, 98);
  FLstTransfers.Selectable := True;
  FLstTransfers.Background := FWindow;
  FLstTransfers.Margin := 2;

  for b in Game.SavedGame.Bases do
  begin
    var i := 0;
    while i < b.Transfers.Count do
    begin
      t := b.Transfers[i];
      if t.Hours = 0 then
      begin
        FBase := b;
        // Auto-use items
        if t.TransferType = TRANSFER_ITEM then
        begin
          var item := Game.Mod.GetItem(t.Items, True);
          if item.BattleType = BT_NONE then
            for var c in b.Crafts do
              c.ReuseItem(t.Items);
        end;
        ss := IntToStr(t.Quantity);
        FLstTransfers.AddRow(3, [t.Name(Game.Language), ss, b.Name]);
        t.Free;
        b.Transfers.Delete(i);
      end
      else
        Inc(i);
    end;
  end;
end;

destructor TItemsArrivingState.Destroy;
begin
  inherited;
end;

procedure TItemsArrivingState.BtnOkClick(AAction: TAction);
begin
  Game.PopState;
end;

procedure TItemsArrivingState.BtnGotoBaseClick(AAction: TAction);
begin
  FState.TimerReset;
  Game.PopState;
  Game.PushState(TBasescapeState.Create(FBase, FState.Globe));
end;

end.