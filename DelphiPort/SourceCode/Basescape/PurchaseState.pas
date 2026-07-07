unit PurchaseState;

interface

uses
  Classes, SysUtils, Generics.Collections, Math,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Timer, Engine.Options,
  Engine.Unicode, Interface.TextButton, Interface.Window,
  Interface.Text, Interface.ComboBox, Interface.TextList,
  Savegame.SavedGame, Mod.RuleCraft, Mod.RuleItem,
  Savegame.Base, Savegame.Craft, Savegame.ItemContainer,
  Menu.ErrorMessageState, Mod.RuleInterface, Mod.RuleSoldier,
  Mod.RuleCraftWeapon, Mod.Armor, fmath;

type
  TPurchaseState = class(TState)
  private
    FBase: TBase;
    FBtnOk, FBtnCancel: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtFunds, FTxtPurchases, FTxtCost, FTxtQuantity, FTxtSpaceUsed: TText;
    FCbxCategory: TComboBox;
    FLstItems: TTextList;
    FItems: TList<TTransferRow>;
    FRows: TList<Integer>;
    FCats: TStringList;
    FCraftWeapons, FArmors: TSet<string>;
    FSel: Integer;
    FTotal: Integer;
    FPQty: Integer;
    FCQty: Integer;
    FIQty: Double;
    FAmmoColor: Byte;
    FTimerInc, FTimerDec: TTimer;

    function GetCategory(Index: Integer): string;
    function GetRow: TTransferRow;
    procedure UpdateList;
    procedure UpdateItemStrings;
    procedure IncreaseByValue(Change: Integer);
    procedure DecreaseByValue(Change: Integer);
  public
    constructor Create(AOwner: TComponent; Base: TBase);
    destructor Destroy; override;
    procedure Think; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure BtnCancelClick(Sender: TObject; Action: TAction);
    procedure LstItemsLeftArrowPress(Sender: TObject; Action: TAction);
    procedure LstItemsLeftArrowRelease(Sender: TObject; Action: TAction);
    procedure LstItemsLeftArrowClick(Sender: TObject; Action: TAction);
    procedure LstItemsRightArrowPress(Sender: TObject; Action: TAction);
    procedure LstItemsRightArrowRelease(Sender: TObject; Action: TAction);
    procedure LstItemsRightArrowClick(Sender: TObject; Action: TAction);
    procedure LstItemsMousePress(Sender: TObject; Action: TAction);
    procedure Increase;
    procedure Decrease;
    procedure CbxCategoryChange(Sender: TObject; Action: TAction);
  end;

implementation

constructor TPurchaseState.Create(AOwner: TComponent; Base: TBase);
var
  cw: TStringList;
  ar: TStringList;
  soldiers: TStringList;
  crafts: TStringList;
  items: TStringList;
  i: Integer;
  rule: TRuleItem;
  row: TTransferRow;
begin
  inherited Create(AOwner);
  FBase := Base;
  FItems := TList<TTransferRow>.Create;
  FRows := TList<Integer>.Create;
  FCats := TStringList.Create;
  FCraftWeapons := TSet<string>.Create;
  FArmors := TSet<string>.Create;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TTextButton.Create(148, 16, 8, 176);
  FBtnCancel := TTextButton.Create(148, 16, 164, 176);
  FTxtTitle := TText.Create(310, 17, 5, 8);
  FTxtFunds := TText.Create(150, 9, 10, 24);
  FTxtPurchases := TText.Create(150, 9, 160, 24);
  FTxtSpaceUsed := TText.Create(150, 9, 160, 34);
  FTxtCost := TText.Create(102, 9, 152, 44);
  FTxtQuantity := TText.Create(60, 9, 256, 44);
  FCbxCategory := TComboBox.Create(Self, 120, 16, 10, 36);
  FLstItems := TTextList.Create(287, 120, 8, 54);

  SetInterface('buyMenu');
  FAmmoColor := FGame.GetMod.GetInterface('buyMenu').GetElement('ammoColor').Color;
  Add(FWindow, 'window', 'buyMenu');
  Add(FBtnOk, 'button', 'buyMenu');
  Add(FBtnCancel, 'button', 'buyMenu');
  Add(FTxtTitle, 'text', 'buyMenu');
  Add(FTxtFunds, 'text', 'buyMenu');
  Add(FTxtPurchases, 'text', 'buyMenu');
  Add(FTxtSpaceUsed, 'text', 'buyMenu');
  Add(FTxtCost, 'text', 'buyMenu');
  Add(FTxtQuantity, 'text', 'buyMenu');
  Add(FLstItems, 'list', 'buyMenu');
  Add(FCbxCategory, 'text', 'buyMenu');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK13.SCR'));
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  FBtnCancel.SetText(Translate('STR_CANCEL'));
  FBtnCancel.OnMouseClick := BtnCancelClick;
  FBtnCancel.OnKeyboardPress := BtnCancelClick;

  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetText(Translate('STR_PURCHASE_HIRE_PERSONNEL'));
  FTxtFunds.SetText(Translate('STR_CURRENT_FUNDS').Arg(Unicode.FormatFunding(FGame.GetSavedGame.GetFunds)));
  FTxtPurchases.SetText(Translate('STR_COST_OF_PURCHASES').Arg(Unicode.FormatFunding(FTotal)));

  FTxtSpaceUsed.Visible := Options.StorageLimitsEnforced;
  FTxtSpaceUsed.SetText(Translate('STR_SPACE_USED').Arg(
    Format('%d:%d', [Floor(FBase.GetUsedStores), FBase.GetAvailableStores])));

  FTxtCost.SetText(Translate('STR_COST_PER_UNIT_UC'));
  FTxtQuantity.SetText(Translate('STR_QUANTITY_UC'));

  FLstItems.SetArrowColumn(227, ARROW_VERTICAL);
  FLstItems.SetColumns([150, 55, 50, 32]);
  FLstItems.SetSelectable(True);
  FLstItems.SetBackground(FWindow);
  FLstItems.SetMargin(2);
  FLstItems.OnLeftArrowPress := LstItemsLeftArrowPress;
  FLstItems.OnLeftArrowRelease := LstItemsLeftArrowRelease;
  FLstItems.OnLeftArrowClick := LstItemsLeftArrowClick;
  FLstItems.OnRightArrowPress := LstItemsRightArrowPress;
  FLstItems.OnRightArrowRelease := LstItemsRightArrowRelease;
  FLstItems.OnRightArrowClick := LstItemsRightArrowClick;
  FLstItems.OnMousePress := LstItemsMousePress;

  FCats.Add('STR_ALL_ITEMS');

  // Collect craft weapon launcher and clip items
  cw := FGame.GetMod.GetCraftWeaponsList;
  for i := 0 to cw.Count - 1 do
  begin
    var ruleCW := FGame.GetMod.GetCraftWeapon(cw[i]);
    FCraftWeapons.Add(ruleCW.GetLauncherItem);
    FCraftWeapons.Add(ruleCW.GetClipItem);
  end;
  ar := FGame.GetMod.GetArmorsList;
  for i := 0 to ar.Count - 1 do
    FArmors.Add(FGame.GetMod.GetArmor(ar[i]).GetStoreItem);

  // Soldiers
  soldiers := FGame.GetMod.GetSoldiersList;
  for i := 0 to soldiers.Count - 1 do
  begin
    var ruleS := FGame.GetMod.GetSoldier(soldiers[i]);
    if (ruleS.GetBuyCost <> 0) and FGame.GetSavedGame.IsResearched(ruleS.GetRequirements) then
    begin
      row.Type := TRANSFER_SOLDIER;
      row.Rule := ruleS;
      row.Name := Translate(ruleS.GetType);
      row.Cost := ruleS.GetBuyCost;
      row.QtySrc := FBase.GetSoldierCount(ruleS.GetType);
      row.Amount := 0;
      FItems.Add(row);
      var cat := GetCategory(FItems.Count-1);
      if FCats.IndexOf(cat) = -1 then FCats.Add(cat);
    end;
  end;
  // Scientists
  row.Type := TRANSFER_SCIENTIST;
  row.Rule := nil;
  row.Name := Translate('STR_SCIENTIST');
  row.Cost := FGame.GetMod.GetScientistCost * 2;
  row.QtySrc := FBase.GetTotalScientists;
  row.Amount := 0;
  FItems.Add(row);
  var cat2 := GetCategory(FItems.Count-1);
  if FCats.IndexOf(cat2) = -1 then FCats.Add(cat2);

  // Engineers
  row.Type := TRANSFER_ENGINEER;
  row.Rule := nil;
  row.Name := Translate('STR_ENGINEER');
  row.Cost := FGame.GetMod.GetEngineerCost * 2;
  row.QtySrc := FBase.GetTotalEngineers;
  row.Amount := 0;
  FItems.Add(row);
  cat2 := GetCategory(FItems.Count-1);
  if FCats.IndexOf(cat2) = -1 then FCats.Add(cat2);

  // Crafts
  crafts := FGame.GetMod.GetCraftsList;
  for i := 0 to crafts.Count - 1 do
  begin
    var ruleC := FGame.GetMod.GetCraft(crafts[i]);
    if (ruleC.GetBuyCost <> 0) and FGame.GetSavedGame.IsResearched(ruleC.GetRequirements) then
    begin
      row.Type := TRANSFER_CRAFT;
      row.Rule := ruleC;
      row.Name := Translate(ruleC.GetType);
      row.Cost := ruleC.GetBuyCost;
      row.QtySrc := FBase.GetCraftCount(ruleC.GetType);
      row.Amount := 0;
      FItems.Add(row);
      var cat3 := GetCategory(FItems.Count-1);
      if FCats.IndexOf(cat3) = -1 then FCats.Add(cat3);
    end;
  end;

  // Items
  items := FGame.GetMod.GetItemsList;
  for i := 0 to items.Count - 1 do
  begin
    rule := FGame.GetMod.GetItem(items[i]);
    if (rule.GetBuyCost <> 0) and FGame.GetSavedGame.IsResearched(rule.GetRequirements) then
    begin
      row.Type := TRANSFER_ITEM;
      row.Rule := rule;
      row.Name := Translate(rule.GetType);
      row.Cost := rule.GetBuyCost;
      row.QtySrc := FBase.GetStorageItems.GetItem(rule.GetType);
      row.Amount := 0;
      FItems.Add(row);
      var cat4 := GetCategory(FItems.Count-1);
      if FCats.IndexOf(cat4) = -1 then FCats.Add(cat4);
    end;
  end;

  FCbxCategory.SetOptions(FCats, True);
  FCbxCategory.OnChange := CbxCategoryChange;

  UpdateList;

  FTimerInc := TTimer.Create(250);
  FTimerInc.OnTimer := Increase;
  FTimerDec := TTimer.Create(250);
  FTimerDec.OnTimer := Decrease;
end;

destructor TPurchaseState.Destroy;
begin
  FItems.Free;
  FRows.Free;
  FCats.Free;
  FCraftWeapons.Free;
  FArmors.Free;
  FTimerInc.Free;
  FTimerDec.Free;
  inherited;
end;

function TPurchaseState.GetCategory(Index: Integer): string;
var
  rule: TRuleItem;
begin
  case FItems[Index].Type of
    TRANSFER_SOLDIER, TRANSFER_SCIENTIST, TRANSFER_ENGINEER:
      Result := 'STR_PERSONNEL';
    TRANSFER_CRAFT:
      Result := 'STR_CRAFT_ARMAMENT';
    TRANSFER_ITEM:
    begin
      rule := TRuleItem(FItems[Index].Rule);
      if (rule.GetBattleType = BT_CORPSE) or rule.IsAlien then
        Result := 'STR_ALIENS'
      else if rule.GetBattleType = BT_NONE then
      begin
        if FCraftWeapons.Contains(rule.GetType) then
          Result := 'STR_CRAFT_ARMAMENT'
        else if FArmors.Contains(rule.GetType) then
          Result := 'STR_EQUIPMENT'
        else
          Result := 'STR_COMPONENTS';
      end
      else
        Result := 'STR_EQUIPMENT';
    end
    else
      Result := 'STR_ALL_ITEMS';
  end;
end;

function TPurchaseState.GetRow: TTransferRow;
begin
  Result := FItems[FRows[FSel]];
end;

procedure TPurchaseState.UpdateList;
var
  i: Integer;
  cat, name: string;
  row: TTransferRow;
  ammo: Boolean;
begin
  FLstItems.ClearList;
  FRows.Clear;
  cat := FCats[FCbxCategory.GetSelected];
  for i := 0 to FItems.Count - 1 do
  begin
    if (cat <> 'STR_ALL_ITEMS') and (cat <> GetCategory(i)) then Continue;
    row := FItems[i];
    name := row.Name;
    ammo := False;
    if row.Type = TRANSFER_ITEM then
    begin
      var rule := TRuleItem(row.Rule);
      ammo := (rule.GetBattleType = BT_AMMO) or ((rule.GetBattleType = BT_NONE) and (rule.GetClipSize > 0));
      if ammo then name := '  ' + name;
    end;
    FLstItems.AddRow([
      name,
      Unicode.FormatFunding(row.Cost),
      IntToStr(row.QtySrc),
      IntToStr(row.Amount)
    ]);
    FRows.Add(i);
    if row.Amount > 0 then
      FLstItems.SetRowColor(FRows.Count-1, FLstItems.GetSecondaryColor)
    else if ammo then
      FLstItems.SetRowColor(FRows.Count-1, FAmmoColor);
  end;
end;

procedure TPurchaseState.UpdateItemStrings;
var
  row: TTransferRow;
begin
  row := GetRow;
  FLstItems.SetCellText(FSel, 3, IntToStr(row.Amount));
  if row.Amount > 0 then
    FLstItems.SetRowColor(FSel, FLstItems.GetSecondaryColor)
  else
  begin
    FLstItems.SetRowColor(FSel, FLstItems.GetColor);
    if row.Type = TRANSFER_ITEM then
    begin
      var rule := TRuleItem(row.Rule);
      if (rule.GetBattleType = BT_AMMO) or ((rule.GetBattleType = BT_NONE) and (rule.GetClipSize > 0)) then
        FLstItems.SetRowColor(FSel, FAmmoColor);
    end;
  end;
  FTxtPurchases.SetText(Translate('STR_COST_OF_PURCHASES').Arg(Unicode.FormatFunding(FTotal)));
  FTxtSpaceUsed.SetText(Translate('STR_SPACE_USED').Arg(
    Format('%d(%s):%d', [Floor(FBase.GetUsedStores),
      IfThen(Abs(FIQty) > 0.05, Format('%s%.1f', [IfThen(FIQty>0,'+',''), FIQty]), ''),
      FBase.GetAvailableStores])));
end;

procedure TPurchaseState.IncreaseByValue(Change: Integer);
var
  row: TTransferRow;
  errorMessage: string;
  maxByMoney, maxByQuarters, maxByHangars: Integer;
  rule: TRuleItem;
  freeStores: Double;
  maxByStores: Integer;
begin
  if Change <= 0 then Exit;
  row := GetRow;
  if FTotal + row.Cost > FGame.GetSavedGame.GetFunds then
    errorMessage := Translate('STR_NOT_ENOUGH_MONEY')
  else
  begin
    case row.Type of
      TRANSFER_SOLDIER, TRANSFER_SCIENTIST, TRANSFER_ENGINEER:
        if FPQty + 1 > FBase.GetAvailableQuarters - FBase.GetUsedQuarters then
          errorMessage := Translate('STR_NOT_ENOUGH_LIVING_SPACE');
      TRANSFER_CRAFT:
        if FCQty + 1 > FBase.GetAvailableHangars - FBase.GetUsedHangars then
          errorMessage := Translate('STR_NO_FREE_HANGARS_FOR_PURCHASE');
      TRANSFER_ITEM:
      begin
        rule := TRuleItem(row.Rule);
        if FBase.StoresOverfull(FIQty + rule.GetSize) then
          errorMessage := Translate('STR_NOT_ENOUGH_STORE_SPACE');
      end;
    end;
  end;

  if errorMessage = '' then
  begin
    maxByMoney := (FGame.GetSavedGame.GetFunds - FTotal) div row.Cost;
    if maxByMoney >= 0 then Change := Min(maxByMoney, Change);
    case row.Type of
      TRANSFER_SOLDIER, TRANSFER_SCIENTIST, TRANSFER_ENGINEER:
      begin
        maxByQuarters := FBase.GetAvailableQuarters - FBase.GetUsedQuarters - FPQty;
        Change := Min(maxByQuarters, Change);
        FPQty := FPQty + Change;
      end;
      TRANSFER_CRAFT:
      begin
        maxByHangars := FBase.GetAvailableHangars - FBase.GetUsedHangars - FCQty;
        Change := Min(maxByHangars, Change);
        FCQty := FCQty + Change;
      end;
      TRANSFER_ITEM:
      begin
        rule := TRuleItem(row.Rule);
        freeStores := FBase.GetAvailableStores - FBase.GetUsedStores - FIQty;
        if not AreSame(rule.GetSize, 0.0) then
          maxByStores := Floor((freeStores + 0.05) / rule.GetSize)
        else
          maxByStores := MaxInt;
        Change := Min(maxByStores, Change);
        FIQty := FIQty + Change * rule.GetSize;
      end;
    end;
    row.Amount := row.Amount + Change;
    FTotal := FTotal + row.Cost * Change;
    FItems[FRows[FSel]] := row;
    UpdateItemStrings;
  end
  else
  begin
    FTimerInc.Stop;
    var menuInterface := FGame.GetMod.GetInterface('buyMenu');
    FGame.PushState(TErrorMessageState.Create(Self, errorMessage, FPalette,
      menuInterface.GetElement('errorMessage').Color, 'BACK13.SCR',
      menuInterface.GetElement('errorPalette').Color));
  end;
end;

procedure TPurchaseState.DecreaseByValue(Change: Integer);
var
  row: TTransferRow;
  rule: TRuleItem;
begin
  if Change <= 0 then Exit;
  row := GetRow;
  if row.Amount <= 0 then Exit;
  Change := Min(row.Amount, Change);
  case row.Type of
    TRANSFER_SOLDIER, TRANSFER_SCIENTIST, TRANSFER_ENGINEER:
      FPQty := FPQty - Change;
    TRANSFER_CRAFT:
      FCQty := FCQty - Change;
    TRANSFER_ITEM:
    begin
      rule := TRuleItem(row.Rule);
      FIQty := FIQty - rule.GetSize * Change;
    end;
  end;
  row.Amount := row.Amount - Change;
  FTotal := FTotal - row.Cost * Change;
  FItems[FRows[FSel]] := row;
  UpdateItemStrings;
end;

procedure TPurchaseState.Think;
begin
  inherited;
  FTimerInc.Think(Self, 0);
  FTimerDec.Think(Self, 0);
end;

procedure TPurchaseState.BtnOkClick(Sender: TObject; Action: TAction);
var
  row: TTransferRow;
  t: TTransfer;
  i: Integer;
  ruleSoldier: TRuleSoldier;
  ruleCraft: TRuleCraft;
  ruleItem: TRuleItem;
begin
  FGame.GetSavedGame.SetFunds(FGame.GetSavedGame.GetFunds - FTotal);
  for row in FItems do
  begin
    if row.Amount <= 0 then Continue;
    t := nil;
    case row.Type of
      TRANSFER_SOLDIER:
      begin
        ruleSoldier := TRuleSoldier(row.Rule);
        for i := 1 to row.Amount do
        begin
          var time := ruleSoldier.GetTransferTime;
          if time = 0 then time := FGame.GetMod.GetPersonnelTime;
          t := TTransfer.Create(time);
          t.SetSoldier(FGame.GetMod.GenSoldier(FGame.GetSavedGame, ruleSoldier.GetType));
          FBase.GetTransfers.Add(t);
        end;
      end;
      TRANSFER_SCIENTIST:
      begin
        t := TTransfer.Create(FGame.GetMod.GetPersonnelTime);
        t.SetScientists(row.Amount);
        FBase.GetTransfers.Add(t);
      end;
      TRANSFER_ENGINEER:
      begin
        t := TTransfer.Create(FGame.GetMod.GetPersonnelTime);
        t.SetEngineers(row.Amount);
        FBase.GetTransfers.Add(t);
      end;
      TRANSFER_CRAFT:
      begin
        ruleCraft := TRuleCraft(row.Rule);
        for i := 1 to row.Amount do
        begin
          t := TTransfer.Create(ruleCraft.GetTransferTime);
          var craft := TCraft.Create(ruleCraft, FBase, FGame.GetSavedGame.GetId(ruleCraft.GetType));
          craft.SetStatus('STR_REFUELLING');
          t.SetCraft(craft);
          FBase.GetTransfers.Add(t);
        end;
      end;
      TRANSFER_ITEM:
      begin
        ruleItem := TRuleItem(row.Rule);
        t := TTransfer.Create(ruleItem.GetTransferTime);
        t.SetItems(ruleItem.GetType, row.Amount);
        FBase.GetTransfers.Add(t);
      end;
    end;
  end;
  FGame.PopState;
end;

procedure TPurchaseState.BtnCancelClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TPurchaseState.LstItemsLeftArrowPress(Sender: TObject; Action: TAction);
begin
  FSel := FLstItems.GetSelectedRow;
  if (Action.GetDetails.button.button = SDL_BUTTON_LEFT) and (not FTimerInc.IsRunning) then
    FTimerInc.Start;
end;

procedure TPurchaseState.LstItemsLeftArrowRelease(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
    FTimerInc.Stop;
end;

procedure TPurchaseState.LstItemsLeftArrowClick(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_RIGHT then
    IncreaseByValue(MaxInt)
  else if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
  begin
    IncreaseByValue(1);
    FTimerInc.SetInterval(250);
    FTimerDec.SetInterval(250);
  end;
end;

procedure TPurchaseState.LstItemsRightArrowPress(Sender: TObject; Action: TAction);
begin
  FSel := FLstItems.GetSelectedRow;
  if (Action.GetDetails.button.button = SDL_BUTTON_LEFT) and (not FTimerDec.IsRunning) then
    FTimerDec.Start;
end;

procedure TPurchaseState.LstItemsRightArrowRelease(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
    FTimerDec.Stop;
end;

procedure TPurchaseState.LstItemsRightArrowClick(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_RIGHT then
    DecreaseByValue(MaxInt)
  else if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
  begin
    DecreaseByValue(1);
    FTimerInc.SetInterval(250);
    FTimerDec.SetInterval(250);
  end;
end;

procedure TPurchaseState.LstItemsMousePress(Sender: TObject; Action: TAction);
begin
  FSel := FLstItems.GetSelectedRow;
  if Action.GetDetails.button.button = SDL_BUTTON_WHEELUP then
  begin
    FTimerInc.Stop;
    FTimerDec.Stop;
    if (Action.GetAbsoluteXMouse >= FLstItems.GetArrowsLeftEdge) and
       (Action.GetAbsoluteXMouse <= FLstItems.GetArrowsRightEdge) then
      IncreaseByValue(Options.ChangeValueByMouseWheel);
  end
  else if Action.GetDetails.button.button = SDL_BUTTON_WHEELDOWN then
  begin
    FTimerInc.Stop;
    FTimerDec.Stop;
    if (Action.GetAbsoluteXMouse >= FLstItems.GetArrowsLeftEdge) and
       (Action.GetAbsoluteXMouse <= FLstItems.GetArrowsRightEdge) then
      DecreaseByValue(Options.ChangeValueByMouseWheel);
  end;
end;

procedure TPurchaseState.Increase;
begin
  FTimerDec.SetInterval(50);
  FTimerInc.SetInterval(50);
  IncreaseByValue(1);
end;

procedure TPurchaseState.Decrease;
begin
  FTimerInc.SetInterval(50);
  FTimerDec.SetInterval(50);
  DecreaseByValue(1);
end;

procedure TPurchaseState.CbxCategoryChange(Sender: TObject; Action: TAction);
begin
  UpdateList;
end;

end.