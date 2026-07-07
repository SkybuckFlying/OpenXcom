unit TransferItemsState;

interface

uses
  Classes, SysUtils, Generics.Collections, Math,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Timer, Engine.Options,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Interface.ComboBox, Savegame.BaseFacility, Savegame.SavedGame,
  Savegame.Base, Savegame.Soldier, Savegame.Craft,
  Savegame.ItemContainer, Mod.RuleItem,
  Menu.ErrorMessageState, TransferConfirmState,
  fmath, Mod.RuleInterface, Mod.RuleCraftWeapon, Mod.Armor;

type
  TTransferItemsState = class(TState)
  private
    FBaseFrom, FBaseTo: TBase;
    FBtnOk, FBtnCancel: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtQuantity, FTxtAmountTransfer, FTxtAmountDestination: TText;
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
    FAQty: Integer;
    FIQty: Double;
    FDistance: Double;
    FAmmoColor: Byte;
    FTimerInc, FTimerDec: TTimer;

    function GetCategory(Index: Integer): string;
    function GetRow: TTransferRow;
    procedure UpdateList;
    procedure UpdateItemStrings;
    procedure IncreaseByValue(Change: Integer);
    procedure DecreaseByValue(Change: Integer);
    function GetDistance: Double;
  public
    constructor Create(AOwner: TComponent; BaseFrom, BaseTo: TBase);
    destructor Destroy; override;
    procedure Think; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure CompleteTransfer;
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
    function GetTotal: Integer;
    procedure CbxCategoryChange(Sender: TObject; Action: TAction);
  end;

implementation

constructor TTransferItemsState.Create(AOwner: TComponent; BaseFrom, BaseTo: TBase);
var
  cw: TStringList;
  ar: TStringList;
  items: TStringList;
  i: Integer;
  row: TTransferRow;
  craft: TCraft;
  rule: TRuleItem;
begin
  inherited Create(AOwner);
  FBaseFrom := BaseFrom;
  FBaseTo := BaseTo;
  FItems := TList<TTransferRow>.Create;
  FRows := TList<Integer>.Create;
  FCats := TStringList.Create;
  FCraftWeapons := TSet<string>.Create;
  FArmors := TSet<string>.Create;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TTextButton.Create(148, 16, 8, 176);
  FBtnCancel := TTextButton.Create(148, 16, 164, 176);
  FTxtTitle := TText.Create(310, 17, 5, 8);
  FTxtQuantity := TText.Create(50, 9, 150, 24);
  FTxtAmountTransfer := TText.Create(60, 17, 200, 24);
  FTxtAmountDestination := TText.Create(60, 17, 260, 24);
  FCbxCategory := TComboBox.Create(Self, 120, 16, 10, 24);
  FLstItems := TTextList.Create(287, 128, 8, 44);

  SetInterface('transferMenu');
  FAmmoColor := FGame.GetMod.GetInterface('transferMenu').GetElement('ammoColor').Color;
  Add(FWindow, 'window', 'transferMenu');
  Add(FBtnOk, 'button', 'transferMenu');
  Add(FBtnCancel, 'button', 'transferMenu');
  Add(FTxtTitle, 'text', 'transferMenu');
  Add(FTxtQuantity, 'text', 'transferMenu');
  Add(FTxtAmountTransfer, 'text', 'transferMenu');
  Add(FTxtAmountDestination, 'text', 'transferMenu');
  Add(FLstItems, 'list', 'transferMenu');
  Add(FCbxCategory, 'text', 'transferMenu');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK13.SCR'));
  FBtnOk.SetText(Translate('STR_TRANSFER'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  FBtnCancel.SetText(Translate('STR_CANCEL'));
  FBtnCancel.OnMouseClick := BtnCancelClick;
  FBtnCancel.OnKeyboardPress := BtnCancelClick;

  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetText(Translate('STR_TRANSFER'));
  FTxtQuantity.SetText(Translate('STR_QUANTITY_UC'));
  FTxtAmountTransfer.SetText(Translate('STR_AMOUNT_TO_TRANSFER'));
  FTxtAmountTransfer.SetWordWrap(True);
  FTxtAmountDestination.SetText(Translate('STR_AMOUNT_AT_DESTINATION'));
  FTxtAmountDestination.SetWordWrap(True);

  FLstItems.SetArrowColumn(193, ARROW_VERTICAL);
  FLstItems.SetColumns([162, 58, 40, 27]);
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

  FDistance := GetDistance;
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
  for soldier in FBaseFrom.GetSoldiers do
    if soldier.GetCraft = nil then
    begin
      row.Type := TRANSFER_SOLDIER;
      row.Rule := soldier;
      row.Name := soldier.GetName(True);
      row.Cost := Round(5 * FDistance);
      row.QtySrc := 1;
      row.Amount := 0;
      row.QtyDst := 0;
      FItems.Add(row);
      var cat := GetCategory(FItems.Count-1);
      if FCats.IndexOf(cat) = -1 then FCats.Add(cat);
    end;

  // Crafts (not out or allowed airborne)
  for craft in FBaseFrom.GetCrafts do
    if (craft.GetStatus <> 'STR_OUT') or (Options.CanTransferCraftsWhileAirborne and (craft.GetFuel >= craft.GetFuelLimit(FBaseTo))) then
    begin
      row.Type := TRANSFER_CRAFT;
      row.Rule := craft;
      row.Name := craft.GetName(FGame.GetLanguage);
      row.Cost := Round(25 * FDistance);
      row.QtySrc := 1;
      row.Amount := 0;
      row.QtyDst := 0;
      FItems.Add(row);
      var cat2 := GetCategory(FItems.Count-1);
      if FCats.IndexOf(cat2) = -1 then FCats.Add(cat2);
    end;

  // Scientists
  if FBaseFrom.GetAvailableScientists > 0 then
  begin
    row.Type := TRANSFER_SCIENTIST;
    row.Rule := nil;
    row.Name := Translate('STR_SCIENTIST');
    row.Cost := Round(5 * FDistance);
    row.QtySrc := FBaseFrom.GetAvailableScientists;
    row.Amount := 0;
    row.QtyDst := FBaseTo.GetAvailableScientists;
    FItems.Add(row);
    var cat3 := GetCategory(FItems.Count-1);
    if FCats.IndexOf(cat3) = -1 then FCats.Add(cat3);
  end;

  // Engineers
  if FBaseFrom.GetAvailableEngineers > 0 then
  begin
    row.Type := TRANSFER_ENGINEER;
    row.Rule := nil;
    row.Name := Translate('STR_ENGINEER');
    row.Cost := Round(5 * FDistance);
    row.QtySrc := FBaseFrom.GetAvailableEngineers;
    row.Amount := 0;
    row.QtyDst := FBaseTo.GetAvailableEngineers;
    FItems.Add(row);
    var cat4 := GetCategory(FItems.Count-1);
    if FCats.IndexOf(cat4) = -1 then FCats.Add(cat4);
  end;

  // Items
  items := FGame.GetMod.GetItemsList;
  for i := 0 to items.Count - 1 do
  begin
    var qty := FBaseFrom.GetStorageItems.GetItem(items[i]);
    if qty > 0 then
    begin
      rule := FGame.GetMod.GetItem(items[i]);
      row.Type := TRANSFER_ITEM;
      row.Rule := rule;
      row.Name := Translate(items[i]);
      row.Cost := Round(1 * FDistance);
      row.QtySrc := qty;
      row.Amount := 0;
      row.QtyDst := FBaseTo.GetStorageItems.GetItem(items[i]);
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

destructor TTransferItemsState.Destroy;
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

function TTransferItemsState.GetCategory(Index: Integer): string;
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

function TTransferItemsState.GetRow: TTransferRow;
begin
  Result := FItems[FRows[FSel]];
end;

procedure TTransferItemsState.UpdateList;
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
      IntToStr(row.QtyDst)
    ]);
    FRows.Add(i);
    if row.Amount > 0 then
      FLstItems.SetRowColor(FRows.Count-1, FLstItems.GetSecondaryColor)
    else if ammo then
      FLstItems.SetRowColor(FRows.Count-1, FAmmoColor);
  end;
end;

procedure TTransferItemsState.UpdateItemStrings;
var
  row: TTransferRow;
begin
  row := GetRow;
  FLstItems.SetCellText(FSel, 1, IntToStr(row.QtySrc - row.Amount));
  FLstItems.SetCellText(FSel, 2, IntToStr(row.Amount));
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
end;

procedure TTransferItemsState.IncreaseByValue(Change: Integer);
var
  row: TTransferRow;
  errorMessage: string;
  craft: TCraft;
  rule: TRuleItem;
  freeQuarters, freeHangars, freeContainment: Integer;
  freeStores: Double;
  maxByStores: Integer;
begin
  if Change <= 0 then Exit;
  row := GetRow;
  errorMessage := '';
  case row.Type of
    TRANSFER_SOLDIER, TRANSFER_SCIENTIST, TRANSFER_ENGINEER:
      if FPQty + 1 > FBaseTo.GetAvailableQuarters - FBaseTo.GetUsedQuarters then
        errorMessage := Translate('STR_NO_FREE_ACCOMODATION');
    TRANSFER_CRAFT:
    begin
      craft := TCraft(row.Rule);
      if FCQty + 1 > FBaseTo.GetAvailableHangars - FBaseTo.GetUsedHangars then
        errorMessage := Translate('STR_NO_FREE_HANGARS_FOR_TRANSFER')
      else if FPQty + craft.GetNumSoldiers > FBaseTo.GetAvailableQuarters - FBaseTo.GetUsedQuarters then
        errorMessage := Translate('STR_NO_FREE_ACCOMODATION_CREW')
      else if Options.StorageLimitsEnforced and FBaseTo.StoresOverfull(FIQty + craft.GetItems.GetTotalSize(FGame.GetMod)) then
        errorMessage := Translate('STR_NOT_ENOUGH_STORE_SPACE_FOR_CRAFT');
    end;
    TRANSFER_ITEM:
    begin
      rule := TRuleItem(row.Rule);
      if not rule.IsAlien then
      begin
        if FBaseTo.StoresOverfull(rule.GetSize + FIQty) then
          errorMessage := Translate('STR_NOT_ENOUGH_STORE_SPACE');
      end
      else
      begin
        freeContainment := IfThen(Options.StorageLimitsEnforced, FBaseTo.GetAvailableContainment - FBaseTo.GetUsedContainment - FAQty, MaxInt);
        if freeContainment <= 0 then
          errorMessage := Translate('STR_NO_ALIEN_CONTAINMENT_FOR_TRANSFER');
      end;
    end;
  end;

  if errorMessage = '' then
  begin
    freeQuarters := FBaseTo.GetAvailableQuarters - FBaseTo.GetUsedQuarters - FPQty;
    case row.Type of
      TRANSFER_SOLDIER, TRANSFER_SCIENTIST, TRANSFER_ENGINEER:
      begin
        Change := Min(Min(freeQuarters, row.QtySrc - row.Amount), Change);
        FPQty := FPQty + Change;
        row.Amount := row.Amount + Change;
        FTotal := FTotal + row.Cost * Change;
      end;
      TRANSFER_CRAFT:
      begin
        craft := TCraft(row.Rule);
        FCQty := FCQty + 1;
        FPQty := FPQty + craft.GetNumSoldiers;
        FIQty := FIQty + craft.GetItems.GetTotalSize(FGame.GetMod);
        row.Amount := row.Amount + 1;
        if not Options.CanTransferCraftsWhileAirborne or (craft.GetStatus <> 'STR_OUT') then
          FTotal := FTotal + row.Cost;
      end;
      TRANSFER_ITEM:
      begin
        rule := TRuleItem(row.Rule);
        if not rule.IsAlien then
        begin
          freeStores := FBaseTo.GetAvailableStores - FBaseTo.GetUsedStores - FIQty;
          if not AreSame(rule.GetSize, 0.0) then
            maxByStores := Floor((freeStores + 0.05) / rule.GetSize)
          else
            maxByStores := MaxInt;
          Change := Min(Min(maxByStores, row.QtySrc - row.Amount), Change);
          FIQty := FIQty + Change * rule.GetSize;
          row.Amount := row.Amount + Change;
          FTotal := FTotal + row.Cost * Change;
        end
        else
        begin
          freeContainment := IfThen(Options.StorageLimitsEnforced, FBaseTo.GetAvailableContainment - FBaseTo.GetUsedContainment - FAQty, MaxInt);
          Change := Min(Min(freeContainment, row.QtySrc - row.Amount), Change);
          FAQty := FAQty + Change;
          row.Amount := row.Amount + Change;
          FTotal := FTotal + row.Cost * Change;
        end;
      end;
    end;
    FItems[FRows[FSel]] := row;
    UpdateItemStrings;
  end
  else
  begin
    FTimerInc.Stop;
    var menuInterface := FGame.GetMod.GetInterface('transferMenu');
    FGame.PushState(TErrorMessageState.Create(Self, errorMessage, FPalette,
      menuInterface.GetElement('errorMessage').Color, 'BACK13.SCR',
      menuInterface.GetElement('errorPalette').Color));
  end;
end;

procedure TTransferItemsState.DecreaseByValue(Change: Integer);
var
  row: TTransferRow;
  craft: TCraft;
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
    begin
      craft := TCraft(row.Rule);
      FCQty := FCQty - 1;
      FPQty := FPQty - craft.GetNumSoldiers;
      FIQty := FIQty - craft.GetItems.GetTotalSize(FGame.GetMod);
    end;
    TRANSFER_ITEM:
    begin
      rule := TRuleItem(row.Rule);
      if not rule.IsAlien then
        FIQty := FIQty - rule.GetSize * Change
      else
        FAQty := FAQty - Change;
    end;
  end;
  row.Amount := row.Amount - Change;
  if not Options.CanTransferCraftsWhileAirborne or (row.Type <> TRANSFER_CRAFT) or (TCraft(row.Rule).GetStatus <> 'STR_OUT') then
    FTotal := FTotal - row.Cost * Change;
  FItems[FRows[FSel]] := row;
  UpdateItemStrings;
end;

procedure TTransferItemsState.Think;
begin
  inherited;
  FTimerInc.Think(Self, 0);
  FTimerDec.Think(Self, 0);
end;

procedure TTransferItemsState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TTransferConfirmState.Create(Self, FBaseTo, Self));
end;

procedure TTransferItemsState.CompleteTransfer;
var
  row: TTransferRow;
  time: Integer;
  t: TTransfer;
  craft: TCraft;
  soldier: TSoldier;
  i: Integer;
begin
  time := Round(6 + FDistance / 10);
  FGame.GetSavedGame.SetFunds(FGame.GetSavedGame.GetFunds - FTotal);
  for row in FItems do
  begin
    if row.Amount <= 0 then Continue;
    t := nil;
    case row.Type of
      TRANSFER_SOLDIER:
      begin
        soldier := TSoldier(row.Rule);
        if FBaseFrom.GetSoldiers.Remove(soldier) then
        begin
          soldier.SetPsiTraining(False);
          t := TTransfer.Create(time);
          t.SetSoldier(soldier);
          FBaseTo.GetTransfers.Add(t);
        end;
      end;
      TRANSFER_CRAFT:
      begin
        craft := TCraft(row.Rule);
        // transfer soldiers inside
        for i := FBaseFrom.GetSoldiers.Count - 1 downto 0 do
        begin
          var s := FBaseFrom.GetSoldiers[i];
          if s.GetCraft = craft then
          begin
            s.SetPsiTraining(False);
            if craft.GetStatus = 'STR_OUT' then
              FBaseTo.GetSoldiers.Add(s)
            else
            begin
              t := TTransfer.Create(time);
              t.SetSoldier(s);
              FBaseTo.GetTransfers.Add(t);
            end;
            FBaseFrom.GetSoldiers.Delete(i);
          end;
        end;
        // transfer craft
        FBaseFrom.RemoveCraft(craft, False);
        if craft.GetStatus = 'STR_OUT' then
        begin
          FBaseTo.GetCrafts.Add(craft);
          craft.SetBase(FBaseTo, False);
          if craft.GetFuel <= craft.GetFuelLimit(FBaseTo) then
          begin
            craft.SetLowFuel(True);
            craft.ReturnToBase;
          end
          else if craft.GetDestination = craft.GetBase then
          begin
            craft.SetLowFuel(False);
            craft.ReturnToBase;
          end;
        end
        else
        begin
          t := TTransfer.Create(time);
          t.SetCraft(craft);
          FBaseTo.GetTransfers.Add(t);
        end;
      end;
      TRANSFER_SCIENTIST:
      begin
        FBaseFrom.SetScientists(FBaseFrom.GetScientists - row.Amount);
        t := TTransfer.Create(time);
        t.SetScientists(row.Amount);
        FBaseTo.GetTransfers.Add(t);
      end;
      TRANSFER_ENGINEER:
      begin
        FBaseFrom.SetEngineers(FBaseFrom.GetEngineers - row.Amount);
        t := TTransfer.Create(time);
        t.SetEngineers(row.Amount);
        FBaseTo.GetTransfers.Add(t);
      end;
      TRANSFER_ITEM:
      begin
        var rule := TRuleItem(row.Rule);
        FBaseFrom.GetStorageItems.RemoveItem(rule.GetType, row.Amount);
        t := TTransfer.Create(time);
        t.SetItems(rule.GetType, row.Amount);
        FBaseTo.GetTransfers.Add(t);
      end;
    end;
  end;
end;

procedure TTransferItemsState.BtnCancelClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
  FGame.PopState;
end;

procedure TTransferItemsState.LstItemsLeftArrowPress(Sender: TObject; Action: TAction);
begin
  FSel := FLstItems.GetSelectedRow;
  if (Action.GetDetails.button.button = SDL_BUTTON_LEFT) and (not FTimerInc.IsRunning) then
    FTimerInc.Start;
end;

procedure TTransferItemsState.LstItemsLeftArrowRelease(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
    FTimerInc.Stop;
end;

procedure TTransferItemsState.LstItemsLeftArrowClick(Sender: TObject; Action: TAction);
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

procedure TTransferItemsState.LstItemsRightArrowPress(Sender: TObject; Action: TAction);
begin
  FSel := FLstItems.GetSelectedRow;
  if (Action.GetDetails.button.button = SDL_BUTTON_LEFT) and (not FTimerDec.IsRunning) then
    FTimerDec.Start;
end;

procedure TTransferItemsState.LstItemsRightArrowRelease(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
    FTimerDec.Stop;
end;

procedure TTransferItemsState.LstItemsRightArrowClick(Sender: TObject; Action: TAction);
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

procedure TTransferItemsState.LstItemsMousePress(Sender: TObject; Action: TAction);
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

procedure TTransferItemsState.Increase;
begin
  FTimerDec.SetInterval(50);
  FTimerInc.SetInterval(50);
  IncreaseByValue(1);
end;

procedure TTransferItemsState.Decrease;
begin
  FTimerInc.SetInterval(50);
  FTimerDec.SetInterval(50);
  DecreaseByValue(1);
end;

function TTransferItemsState.GetTotal: Integer;
begin
  Result := FTotal;
end;

procedure TTransferItemsState.CbxCategoryChange(Sender: TObject; Action: TAction);
begin
  UpdateList;
end;

function TTransferItemsState.GetDistance: Double;
var
  x, y, z: array[0..2] of Double;
  r: Double;
  base: TBase;
  i: Integer;
begin
  r := 51.2;
  base := FBaseFrom;
  for i := 0 to 1 do
  begin
    x[i] := r * Cos(base.GetLatitude) * Cos(base.GetLongitude);
    y[i] := r * Cos(base.GetLatitude) * Sin(base.GetLongitude);
    z[i] := r * -Sin(base.GetLatitude);
    base := FBaseTo;
  end;
  x[2] := x[1] - x[0];
  y[2] := y[1] - y[0];
  z[2] := z[1] - z[0];
  Result := Sqrt(x[2]*x[2] + y[2]*y[2] + z[2]*z[2]);
end;

end.