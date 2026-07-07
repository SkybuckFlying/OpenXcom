unit SellState;

interface

uses
  Classes, SysUtils, Generics.Collections, Math,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Timer, Engine.Options,
  Engine.Unicode, Interface.TextButton, Interface.Window,
  Interface.Text, Interface.ComboBox, Interface.TextList,
  Savegame.BaseFacility, Savegame.SavedGame, Savegame.Base,
  Savegame.Soldier, Savegame.Craft, Savegame.ItemContainer,
  Mod.RuleItem, Mod.Armor, Mod.RuleCraft, Savegame.CraftWeapon,
  Mod.RuleCraftWeapon, Mod.RuleInterface, Menu.OptionsBaseState,
  fmath;

type
  TSellState = class(TState)
  private
    FBase: TBase;
    FBtnOk, FBtnCancel: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtSales, FTxtFunds, FTxtQuantity, FTxtSell, FTxtValue, FTxtSpaceUsed: TText;
    FCbxCategory: TComboBox;
    FLstItems: TTextList;
    FItems: TList<TTransferRow>;
    FRows: TList<Integer>;
    FCats: TStringList;
    FCraftWeapons, FArmors: TSet<string>;
    FSel: Integer;
    FTotal: Integer;
    FSpaceChange: Double;
    FTimerInc, FTimerDec: TTimer;
    FAmmoColor: Byte;
    FOrigin: TOptionsOrigin;

    function GetCategory(Index: Integer): string;
    function GetRow: TTransferRow;
    procedure UpdateList;
    procedure UpdateItemStrings;
    procedure ChangeByValue(Change: Integer; Dir: Integer);
  public
    constructor Create(AOwner: TComponent; Base: TBase; Origin: TOptionsOrigin = OPT_GEOSCAPE);
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

constructor TSellState.Create(AOwner: TComponent; Base: TBase; Origin: TOptionsOrigin);
var
  cw: TStringList;
  ar: TStringList;
  items: TStringList;
  i: Integer;
  row: TTransferRow;
  soldier: TSoldier;
  craft: TCraft;
  rule: TRuleItem;
  qty: Integer;
begin
  inherited Create(AOwner);
  FBase := Base;
  FOrigin := Origin;
  FItems := TList<TTransferRow>.Create;
  FRows := TList<Integer>.Create;
  FCats := TStringList.Create;
  FCraftWeapons := TSet<string>.Create;
  FArmors := TSet<string>.Create;

  var overfull := Options.StorageLimitsEnforced and FBase.StoresOverfull;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TTextButton.Create(IfThen(overfull, 288, 148), 16, IfThen(overfull, 16, 8), 176);
  FBtnCancel := TTextButton.Create(148, 16, 164, 176);
  FTxtTitle := TText.Create(310, 17, 5, 8);
  FTxtSales := TText.Create(150, 9, 10, 24);
  FTxtFunds := TText.Create(150, 9, 160, 24);
  FTxtSpaceUsed := TText.Create(150, 9, 160, 34);
  FTxtQuantity := TText.Create(54, 9, 136, 44);
  FTxtSell := TText.Create(96, 9, 190, 44);
  FTxtValue := TText.Create(40, 9, 270, 44);
  FCbxCategory := TComboBox.Create(Self, 120, 16, 10, 36);
  FLstItems := TTextList.Create(287, 120, 8, 54);

  SetInterface('sellMenu');
  FAmmoColor := FGame.GetMod.GetInterface('sellMenu').GetElement('ammoColor').Color;
  Add(FWindow, 'window', 'sellMenu');
  Add(FBtnOk, 'button', 'sellMenu');
  Add(FBtnCancel, 'button', 'sellMenu');
  Add(FTxtTitle, 'text', 'sellMenu');
  Add(FTxtSales, 'text', 'sellMenu');
  Add(FTxtFunds, 'text', 'sellMenu');
  Add(FTxtSpaceUsed, 'text', 'sellMenu');
  Add(FTxtQuantity, 'text', 'sellMenu');
  Add(FTxtSell, 'text', 'sellMenu');
  Add(FTxtValue, 'text', 'sellMenu');
  Add(FLstItems, 'list', 'sellMenu');
  Add(FCbxCategory, 'text', 'sellMenu');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK13.SCR'));
  FBtnOk.SetText(Translate('STR_SELL_SACK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  FBtnCancel.SetText(Translate('STR_CANCEL'));
  FBtnCancel.OnMouseClick := BtnCancelClick;
  FBtnCancel.OnKeyboardPress := BtnCancelClick;

  if overfull then
  begin
    FBtnCancel.Visible := False;
    FBtnOk.Visible := False;
  end;

  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetText(Translate('STR_SELL_ITEMS_SACK_PERSONNEL'));
  FTxtSales.SetText(Translate('STR_VALUE_OF_SALES').Arg(Unicode.FormatFunding(FTotal)));
  FTxtFunds.SetText(Translate('STR_FUNDS').Arg(Unicode.FormatFunding(FGame.GetSavedGame.GetFunds)));

  FTxtSpaceUsed.Visible := Options.StorageLimitsEnforced;
  FTxtSpaceUsed.SetText(Translate('STR_SPACE_USED').Arg(
    Format('%d:%d', [Floor(FBase.GetUsedStores), FBase.GetAvailableStores])));

  FTxtQuantity.SetText(Translate('STR_QUANTITY_UC'));
  FTxtSell.SetText(Translate('STR_SELL_SACK'));
  FTxtValue.SetText(Translate('STR_VALUE'));

  FLstItems.SetArrowColumn(182, ARROW_VERTICAL);
  FLstItems.SetColumns([156, 54, 24, 53]);
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

  // Craft weapons
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

  // Soldiers not on craft
  for soldier in FBase.GetSoldiers do
    if soldier.GetCraft = nil then
    begin
      row.Type := TRANSFER_SOLDIER;
      row.Rule := soldier;
      row.Name := soldier.GetName(True);
      row.Cost := 0;
      row.QtySrc := 1;
      row.Amount := 0;
      FItems.Add(row);
      var cat := GetCategory(FItems.Count-1);
      if FCats.IndexOf(cat) = -1 then FCats.Add(cat);
    end;

  // Crafts not out
  for craft in FBase.GetCrafts do
    if craft.GetStatus <> 'STR_OUT' then
    begin
      row.Type := TRANSFER_CRAFT;
      row.Rule := craft;
      row.Name := craft.GetName(FGame.GetLanguage);
      row.Cost := craft.GetRules.GetSellCost;
      row.QtySrc := 1;
      row.Amount := 0;
      FItems.Add(row);
      var cat2 := GetCategory(FItems.Count-1);
      if FCats.IndexOf(cat2) = -1 then FCats.Add(cat2);
    end;

  // Scientists
  if FBase.GetAvailableScientists > 0 then
  begin
    row.Type := TRANSFER_SCIENTIST;
    row.Rule := nil;
    row.Name := Translate('STR_SCIENTIST');
    row.Cost := 0;
    row.QtySrc := FBase.GetAvailableScientists;
    row.Amount := 0;
    FItems.Add(row);
    var cat3 := GetCategory(FItems.Count-1);
    if FCats.IndexOf(cat3) = -1 then FCats.Add(cat3);
  end;

  // Engineers
  if FBase.GetAvailableEngineers > 0 then
  begin
    row.Type := TRANSFER_ENGINEER;
    row.Rule := nil;
    row.Name := Translate('STR_ENGINEER');
    row.Cost := 0;
    row.QtySrc := FBase.GetAvailableEngineers;
    row.Amount := 0;
    FItems.Add(row);
    var cat4 := GetCategory(FItems.Count-1);
    if FCats.IndexOf(cat4) = -1 then FCats.Add(cat4);
  end;

  // Items
  items := FGame.GetMod.GetItemsList;
  for i := 0 to items.Count - 1 do
  begin
    qty := FBase.GetStorageItems.GetItem(items[i]);
    if Options.StorageLimitsEnforced and (FOrigin = OPT_BATTLESCAPE) then
    begin
      for t in FBase.GetTransfers do
        if t.GetItems = items[i] then qty := qty + t.GetQuantity;
      for craft in FBase.GetCrafts do
        qty := qty + craft.GetItems.GetItem(items[i]);
    end;
    rule := FGame.GetMod.GetItem(items[i], True);
    if (qty > 0) and (Options.CanSellLiveAliens or not rule.IsAlien) then
    begin
      row.Type := TRANSFER_ITEM;
      row.Rule := rule;
      row.Name := Translate(items[i]);
      row.Cost := rule.GetSellCost;
      row.QtySrc := qty;
      row.Amount := 0;
      FItems.Add(row);
      var cat5 := GetCategory(FItems.Count-1);
      if FCats.IndexOf(cat5) = -1 then FCats.Add(cat5);
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

destructor TSellState.Destroy;
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

function TSellState.GetCategory(Index: Integer): string;
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

function TSellState.GetRow: TTransferRow;
begin
  Result := FItems[FRows[FSel]];
end;

procedure TSellState.UpdateList;
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
      IntToStr(row.QtySrc - row.Amount),
      IntToStr(row.Amount),
      Unicode.FormatFunding(row.Cost)
    ]);
    FRows.Add(i);
    if row.Amount > 0 then
      FLstItems.SetRowColor(FRows.Count-1, FLstItems.GetSecondaryColor)
    else if ammo then
      FLstItems.SetRowColor(FRows.Count-1, FAmmoColor);
  end;
end;

procedure TSellState.UpdateItemStrings;
var
  row: TTransferRow;
begin
  row := GetRow;
  FLstItems.SetCellText(FSel, 1, IntToStr(row.QtySrc - row.Amount));
  FLstItems.SetCellText(FSel, 2, IntToStr(row.Amount));
  FTxtSales.SetText(Translate('STR_VALUE_OF_SALES').Arg(Unicode.FormatFunding(FTotal)));

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

  var usedStr := IntToStr(FBase.GetUsedStores);
  if Abs(FSpaceChange) > 0.05 then
    usedStr := usedStr + Format('(%s%.1f)', [IfThen(FSpaceChange>0,'+',''), FSpaceChange]);
  FTxtSpaceUsed.SetText(Translate('STR_SPACE_USED').Arg(
    Format('%s:%d', [usedStr, FBase.GetAvailableStores])));

  if Options.StorageLimitsEnforced then
    FBtnOk.Visible := not FBase.StoresOverfull(FSpaceChange);
end;

procedure TSellState.ChangeByValue(Change: Integer; Dir: Integer);
var
  row: TTransferRow;
  craft: TCraft;
  soldier: TSoldier;
  armor, item, weapon, ammo: TRuleItem;
  total: Double;
begin
  row := GetRow;
  if Dir > 0 then
  begin
    if (Change <= 0) or (row.QtySrc <= row.Amount) then Exit;
    Change := Min(row.QtySrc - row.Amount, Change);
  end
  else
  begin
    if (Change <= 0) or (row.Amount <= 0) then Exit;
    Change := Min(row.Amount, Change);
  end;

  row.Amount := row.Amount + Dir * Change;
  FTotal := FTotal + Dir * row.Cost * Change;

  // Adjust storage space
  case row.Type of
    TRANSFER_SOLDIER:
    begin
      soldier := TSoldier(row.Rule);
      if soldier.GetArmor.GetStoreItem <> Armor.NONE then
      begin
        armor := FGame.GetMod.GetItem(soldier.GetArmor.GetStoreItem, True);
        FSpaceChange := FSpaceChange + Dir * armor.GetSize;
      end;
    end;
    TRANSFER_CRAFT:
    begin
      craft := TCraft(row.Rule);
      total := 0;
      for w in craft.GetWeapons do
        if w <> nil then
        begin
          weapon := FGame.GetMod.GetItem(w.GetRules.GetLauncherItem, True);
          total := total + weapon.GetSize;
          ammo := FGame.GetMod.GetItem(w.GetRules.GetClipItem);
          if ammo <> nil then total := total + ammo.GetSize * w.GetClipsLoaded(FGame.GetMod);
        end;
      FSpaceChange := FSpaceChange + Dir * total;
    end;
    TRANSFER_ITEM:
    begin
      item := TRuleItem(row.Rule);
      FSpaceChange := FSpaceChange - Dir * Change * item.GetSize;
    end;
    // SCIENTIST and ENGINEER have no storage
  end;

  FItems[FRows[FSel]] := row;
  UpdateItemStrings;
end;

procedure TSellState.Think;
begin
  inherited;
  FTimerInc.Think(Self, 0);
  FTimerDec.Think(Self, 0);
end;

procedure TSellState.BtnOkClick(Sender: TObject; Action: TAction);
var
  row: TTransferRow;
  soldier: TSoldier;
  craft: TCraft;
  item: TRuleItem;
  i, toRemove: Integer;
begin
  FGame.GetSavedGame.SetFunds(FGame.GetSavedGame.GetFunds + FTotal);
  for row in FItems do
  begin
    if row.Amount <= 0 then Continue;
    case row.Type of
      TRANSFER_SOLDIER:
      begin
        soldier := TSoldier(row.Rule);
        if FBase.GetSoldiers.Remove(soldier) then
        begin
          if soldier.GetArmor.GetStoreItem <> Armor.NONE then
            FBase.GetStorageItems.AddItem(soldier.GetArmor.GetStoreItem);
          soldier.Free;
        end;
      end;
      TRANSFER_CRAFT:
      begin
        craft := TCraft(row.Rule);
        FBase.RemoveCraft(craft, True);
        craft.Free;
      end;
      TRANSFER_SCIENTIST:
        FBase.SetScientists(FBase.GetScientists - row.Amount);
      TRANSFER_ENGINEER:
        FBase.SetEngineers(FBase.GetEngineers - row.Amount);
      TRANSFER_ITEM:
      begin
        item := TRuleItem(row.Rule);
        if FBase.GetStorageItems.GetItem(item.GetType) < row.Amount then
        begin
          toRemove := row.Amount - FBase.GetStorageItems.GetItem(item.GetType);
          FBase.GetStorageItems.RemoveItem(item.GetType, MaxInt);
          for craft in FBase.GetCrafts do
            if toRemove > 0 then
            begin
              var qty := craft.GetItems.GetItem(item.GetType);
              if qty >= toRemove then
              begin
                craft.GetItems.RemoveItem(item.GetType, toRemove);
                toRemove := 0;
              end
              else
              begin
                craft.GetItems.RemoveItem(item.GetType, qty);
                toRemove := toRemove - qty;
              end;
            end;
          // Remove from transfers
          for i := FBase.GetTransfers.Count - 1 downto 0 do
            if toRemove > 0 then
            begin
              var t := FBase.GetTransfers[i];
              if t.GetItems = item.GetType then
              begin
                if t.GetQuantity <= toRemove then
                begin
                  toRemove := toRemove - t.GetQuantity;
                  t.Free;
                  FBase.GetTransfers.Delete(i);
                end
                else
                begin
                  t.SetItems(t.GetItems, t.GetQuantity - toRemove);
                  toRemove := 0;
                end;
              end;
            end;
        end
        else
          FBase.GetStorageItems.RemoveItem(item.GetType, row.Amount);
      end;
    end;
  end;
  FGame.PopState;
end;

procedure TSellState.BtnCancelClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TSellState.LstItemsLeftArrowPress(Sender: TObject; Action: TAction);
begin
  FSel := FLstItems.GetSelectedRow;
  if (Action.GetDetails.button.button = SDL_BUTTON_LEFT) and (not FTimerInc.IsRunning) then
    FTimerInc.Start;
end;

procedure TSellState.LstItemsLeftArrowRelease(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
    FTimerInc.Stop;
end;

procedure TSellState.LstItemsLeftArrowClick(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_RIGHT then
    ChangeByValue(MaxInt, 1)
  else if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
  begin
    ChangeByValue(1, 1);
    FTimerInc.SetInterval(250);
    FTimerDec.SetInterval(250);
  end;
end;

procedure TSellState.LstItemsRightArrowPress(Sender: TObject; Action: TAction);
begin
  FSel := FLstItems.GetSelectedRow;
  if (Action.GetDetails.button.button = SDL_BUTTON_LEFT) and (not FTimerDec.IsRunning) then
    FTimerDec.Start;
end;

procedure TSellState.LstItemsRightArrowRelease(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
    FTimerDec.Stop;
end;

procedure TSellState.LstItemsRightArrowClick(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_RIGHT then
    ChangeByValue(MaxInt, -1)
  else if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
  begin
    ChangeByValue(1, -1);
    FTimerInc.SetInterval(250);
    FTimerDec.SetInterval(250);
  end;
end;

procedure TSellState.LstItemsMousePress(Sender: TObject; Action: TAction);
begin
  FSel := FLstItems.GetSelectedRow;
  if Action.GetDetails.button.button = SDL_BUTTON_WHEELUP then
  begin
    FTimerInc.Stop;
    FTimerDec.Stop;
    if (Action.GetAbsoluteXMouse >= FLstItems.GetArrowsLeftEdge) and
       (Action.GetAbsoluteXMouse <= FLstItems.GetArrowsRightEdge) then
      ChangeByValue(Options.ChangeValueByMouseWheel, 1);
  end
  else if Action.GetDetails.button.button = SDL_BUTTON_WHEELDOWN then
  begin
    FTimerInc.Stop;
    FTimerDec.Stop;
    if (Action.GetAbsoluteXMouse >= FLstItems.GetArrowsLeftEdge) and
       (Action.GetAbsoluteXMouse <= FLstItems.GetArrowsRightEdge) then
      ChangeByValue(Options.ChangeValueByMouseWheel, -1);
  end;
end;

procedure TSellState.Increase;
begin
  FTimerDec.SetInterval(50);
  FTimerInc.SetInterval(50);
  ChangeByValue(1, 1);
end;

procedure TSellState.Decrease;
begin
  FTimerInc.SetInterval(50);
  FTimerDec.SetInterval(50);
  ChangeByValue(1, -1);
end;

procedure TSellState.CbxCategoryChange(Sender: TObject; Action: TAction);
begin
  UpdateList;
end;

end.