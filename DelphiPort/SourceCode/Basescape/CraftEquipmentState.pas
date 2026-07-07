unit CraftEquipmentState;

interface

uses
  Classes, SysUtils, Generics.Collections,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Engine.Timer, Interface.TextButton, Interface.Window,
  Interface.Text, Interface.TextList,
  Mod.Armor, Savegame.Base, Savegame.Craft,
  Mod.RuleCraft, Savegame.ItemContainer, Mod.RuleItem,
  Savegame.Vehicle, Savegame.SavedGame,
  Menu.ErrorMessageState, Battlescape.InventoryState,
  Battlescape.BattlescapeGenerator, Savegame.SavedBattleGame,
  Mod.RuleInterface, Math;

type
  TCraftEquipmentState = class(TState)
  private
    FBtnOk, FBtnClear, FBtnInventory: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtItem, FTxtStores, FTxtAvailable, FTxtUsed, FTxtCrew: TText;
    FLstEquipment: TTextList;
    FTimerLeft, FTimerRight: TTimer;
    FSel, FCraft: Integer;
    FBase: TBase;
    FItems: TStringList;
    FTotalItems: Integer;
    FAmmoColor: Byte;

    procedure UpdateQuantity;
    procedure MoveLeftByValue(Change: Integer);
    procedure MoveRightByValue(Change: Integer);
  public
    constructor Create(AOwner: TComponent; Base: TBase; Craft: Integer);
    destructor Destroy; override;
    procedure Init; override;
    procedure Think; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure LstEquipmentLeftArrowPress(Sender: TObject; Action: TAction);
    procedure LstEquipmentLeftArrowRelease(Sender: TObject; Action: TAction);
    procedure LstEquipmentLeftArrowClick(Sender: TObject; Action: TAction);
    procedure LstEquipmentRightArrowPress(Sender: TObject; Action: TAction);
    procedure LstEquipmentRightArrowRelease(Sender: TObject; Action: TAction);
    procedure LstEquipmentRightArrowClick(Sender: TObject; Action: TAction);
    procedure LstEquipmentMousePress(Sender: TObject; Action: TAction);
    procedure MoveLeft;
    procedure MoveRight;
    procedure BtnClearClick(Sender: TObject; Action: TAction);
    procedure BtnInventoryClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TCraftEquipmentState.Create(AOwner: TComponent; Base: TBase; Craft: Integer);
var
  c: TCraft;
  items: TStringList;
  rule: TRuleItem;
  cQty: Integer;
  row: Integer;
  s: string;
begin
  inherited Create(AOwner);
  FBase := Base;
  FCraft := Craft;
  c := FBase.GetCrafts[Craft];

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TTextButton.Create(IfThen((c.GetNumSoldiers > 0) or (FGame.GetSavedGame.GetMonthsPassed = -1), 148, 288), 16,
    IfThen((c.GetNumSoldiers > 0) or (FGame.GetSavedGame.GetMonthsPassed = -1), 164, 16), 176);
  FBtnClear := TTextButton.Create(148, 16, 8, 176);
  FBtnInventory := TTextButton.Create(148, 16, 8, 176);
  FTxtTitle := TText.Create(300, 17, 16, 7);
  FTxtItem := TText.Create(144, 9, 16, 32);
  FTxtStores := TText.Create(150, 9, 160, 32);
  FTxtAvailable := TText.Create(110, 9, 16, 24);
  FTxtUsed := TText.Create(110, 9, 130, 24);
  FTxtCrew := TText.Create(71, 9, 244, 24);
  FLstEquipment := TTextList.Create(288, 128, 8, 40);

  SetInterface('craftEquipment');
  FAmmoColor := FGame.GetMod.GetInterface('craftEquipment').GetElement('ammoColor').Color;
  Add(FWindow, 'window', 'craftEquipment');
  Add(FBtnOk, 'button', 'craftEquipment');
  Add(FBtnClear, 'button', 'craftEquipment');
  Add(FBtnInventory, 'button', 'craftEquipment');
  Add(FTxtTitle, 'text', 'craftEquipment');
  Add(FTxtItem, 'text', 'craftEquipment');
  Add(FTxtStores, 'text', 'craftEquipment');
  Add(FTxtAvailable, 'text', 'craftEquipment');
  Add(FTxtUsed, 'text', 'craftEquipment');
  Add(FTxtCrew, 'text', 'craftEquipment');
  Add(FLstEquipment, 'list', 'craftEquipment');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK04.SCR'));
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  FBtnClear.SetText(Translate('STR_UNLOAD_CRAFT'));
  FBtnClear.OnMouseClick := BtnClearClick;
  FBtnClear.Visible := (FGame.GetSavedGame.GetMonthsPassed = -1);
  FBtnInventory.SetText(Translate('STR_INVENTORY'));
  FBtnInventory.OnMouseClick := BtnInventoryClick;
  FBtnInventory.Visible := (c.GetNumSoldiers > 0) and (FGame.GetSavedGame.GetMonthsPassed <> -1);
  FTxtTitle.SetBig;
  FTxtTitle.SetText(Translate('STR_EQUIPMENT_FOR_CRAFT').Arg(c.GetName(FGame.GetLanguage)));
  FTxtItem.SetText(Translate('STR_ITEM'));
  FTxtStores.SetText(Translate('STR_STORES'));
  FTxtAvailable.SetText(Translate('STR_SPACE_AVAILABLE').Arg(c.GetSpaceAvailable));
  FTxtUsed.SetText(Translate('STR_SPACE_USED').Arg(c.GetSpaceUsed));
  FTxtCrew.SetText(Translate('STR_SOLDIERS_UC') + '>' + Unicode.TOK_COLOR_FLIP + IntToStr(c.GetNumSoldiers));

  FLstEquipment.SetArrowColumn(203, ARROW_HORIZONTAL);
  FLstEquipment.SetColumns([156, 83, 41]);
  FLstEquipment.SetSelectable(True);
  FLstEquipment.SetBackground(FWindow);
  FLstEquipment.SetMargin(8);
  FLstEquipment.OnLeftArrowPress := LstEquipmentLeftArrowPress;
  FLstEquipment.OnLeftArrowRelease := LstEquipmentLeftArrowRelease;
  FLstEquipment.OnLeftArrowClick := LstEquipmentLeftArrowClick;
  FLstEquipment.OnRightArrowPress := LstEquipmentRightArrowPress;
  FLstEquipment.OnRightArrowRelease := LstEquipmentRightArrowRelease;
  FLstEquipment.OnRightArrowClick := LstEquipmentRightArrowClick;
  FLstEquipment.OnMousePress := LstEquipmentMousePress;

  FItems := TStringList.Create;
  row := 0;
  items := FGame.GetMod.GetItemsList;
  try
    for s in items do
    begin
      rule := FGame.GetMod.GetItem(s);
      if rule.GetBigSprite > -1 then
      begin
        if rule.IsFixed then
          cQty := c.GetVehicleCount(s)
        else
          cQty := c.GetItems.GetItem(s);
        FTotalItems := FTotalItems + cQty;
        if (rule.GetBattleType <> BT_NONE) and (rule.GetBattleType <> BT_CORPSE) and
           FGame.GetSavedGame.IsResearched(rule.GetRequirements) and
           ((FBase.GetStorageItems.GetItem(s) > 0) or (cQty > 0)) then
        begin
          FItems.Add(s);
          FLstEquipment.AddRow([
            IfThen(rule.GetBattleType = BT_AMMO, '  ', '') + Translate(s),
            IfThen(FGame.GetSavedGame.GetMonthsPassed > -1, IntToStr(FBase.GetStorageItems.GetItem(s)), '-'),
            IntToStr(cQty)]);
          if cQty = 0 then
            FLstEquipment.SetRowColor(row, IfThen(rule.GetBattleType = BT_AMMO, FAmmoColor, FLstEquipment.GetColor))
          else
            FLstEquipment.SetRowColor(row, FLstEquipment.GetSecondaryColor);
          Inc(row);
        end;
      end;
    end;
  finally
    items.Free;
  end;

  FTimerLeft := TTimer.Create(250);
  FTimerLeft.OnTimer := MoveLeft;
  FTimerRight := TTimer.Create(250);
  FTimerRight.OnTimer := MoveRight;
end;

destructor TCraftEquipmentState.Destroy;
begin
  FItems.Free;
  FTimerLeft.Free;
  FTimerRight.Free;
  inherited;
end;

procedure TCraftEquipmentState.Init;
begin
  inherited;
  FGame.GetSavedGame.SetBattleGame(nil);
  FBase.GetCrafts[FCraft].SetInBattlescape(False);
end;

procedure TCraftEquipmentState.Think;
begin
  inherited;
  FTimerLeft.Think(Self, 0);
  FTimerRight.Think(Self, 0);
end;

procedure TCraftEquipmentState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TCraftEquipmentState.LstEquipmentLeftArrowPress(Sender: TObject; Action: TAction);
begin
  FSel := FLstEquipment.GetSelectedRow;
  if (Action.GetDetails.button.button = SDL_BUTTON_LEFT) and (not FTimerLeft.IsRunning) then
    FTimerLeft.Start;
end;

procedure TCraftEquipmentState.LstEquipmentLeftArrowRelease(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
    FTimerLeft.Stop;
end;

procedure TCraftEquipmentState.LstEquipmentLeftArrowClick(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_RIGHT then
    MoveLeftByValue(MaxInt)
  else if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
  begin
    MoveLeftByValue(1);
    FTimerRight.SetInterval(250);
    FTimerLeft.SetInterval(250);
  end;
end;

procedure TCraftEquipmentState.LstEquipmentRightArrowPress(Sender: TObject; Action: TAction);
begin
  FSel := FLstEquipment.GetSelectedRow;
  if (Action.GetDetails.button.button = SDL_BUTTON_LEFT) and (not FTimerRight.IsRunning) then
    FTimerRight.Start;
end;

procedure TCraftEquipmentState.LstEquipmentRightArrowRelease(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
    FTimerRight.Stop;
end;

procedure TCraftEquipmentState.LstEquipmentRightArrowClick(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_RIGHT then
    MoveRightByValue(MaxInt)
  else if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
  begin
    MoveRightByValue(1);
    FTimerRight.SetInterval(250);
    FTimerLeft.SetInterval(250);
  end;
end;

procedure TCraftEquipmentState.LstEquipmentMousePress(Sender: TObject; Action: TAction);
begin
  FSel := FLstEquipment.GetSelectedRow;
  if Action.GetDetails.button.button = SDL_BUTTON_WHEELUP then
  begin
    FTimerRight.Stop;
    FTimerLeft.Stop;
    if (Action.GetAbsoluteXMouse >= FLstEquipment.GetArrowsLeftEdge) and
       (Action.GetAbsoluteXMouse <= FLstEquipment.GetArrowsRightEdge) then
      MoveRightByValue(Options.ChangeValueByMouseWheel);
  end
  else if Action.GetDetails.button.button = SDL_BUTTON_WHEELDOWN then
  begin
    FTimerRight.Stop;
    FTimerLeft.Stop;
    if (Action.GetAbsoluteXMouse >= FLstEquipment.GetArrowsLeftEdge) and
       (Action.GetAbsoluteXMouse <= FLstEquipment.GetArrowsRightEdge) then
      MoveLeftByValue(Options.ChangeValueByMouseWheel);
  end;
end;

procedure TCraftEquipmentState.UpdateQuantity;
var
  c: TCraft;
  rule: TRuleItem;
  cQty: Integer;
begin
  c := FBase.GetCrafts[FCraft];
  rule := FGame.GetMod.GetItem(FItems[FSel], True);
  if rule.IsFixed then
    cQty := c.GetVehicleCount(FItems[FSel])
  else
    cQty := c.GetItems.GetItem(FItems[FSel]);
  FLstEquipment.SetCellText(FSel, 1, IfThen(FGame.GetSavedGame.GetMonthsPassed > -1, IntToStr(FBase.GetStorageItems.GetItem(FItems[FSel])), '-'));
  FLstEquipment.SetCellText(FSel, 2, IntToStr(cQty));
  if cQty = 0 then
    FLstEquipment.SetRowColor(FSel, IfThen(rule.GetBattleType = BT_AMMO, FAmmoColor, FLstEquipment.GetColor))
  else
    FLstEquipment.SetRowColor(FSel, FLstEquipment.GetSecondaryColor);
  FTxtAvailable.SetText(Translate('STR_SPACE_AVAILABLE').Arg(c.GetSpaceAvailable));
  FTxtUsed.SetText(Translate('STR_SPACE_USED').Arg(c.GetSpaceUsed));
end;

procedure TCraftEquipmentState.MoveLeft;
begin
  FTimerLeft.SetInterval(50);
  FTimerRight.SetInterval(50);
  MoveLeftByValue(1);
end;

procedure TCraftEquipmentState.MoveLeftByValue(Change: Integer);
var
  c: TCraft;
  rule: TRuleItem;
  cQty, ammoPerVehicle: Integer;
  ammo: TRuleItem;
  i: Integer;
begin
  c := FBase.GetCrafts[FCraft];
  rule := FGame.GetMod.GetItem(FItems[FSel], True);
  if rule.IsFixed then
    cQty := c.GetVehicleCount(FItems[FSel])
  else
    cQty := c.GetItems.GetItem(FItems[FSel]);
  if (Change <= 0) or (cQty <= 0) then Exit;
  Change := Min(cQty, Change);

  if rule.IsFixed then
  begin
    if not rule.GetCompatibleAmmo.IsEmpty then
    begin
      ammo := FGame.GetMod.GetItem(rule.GetCompatibleAmmo[0], True);
      if (ammo.GetClipSize > 0) and (rule.GetClipSize > 0) then
        ammoPerVehicle := rule.GetClipSize div ammo.GetClipSize
      else
        ammoPerVehicle := ammo.GetClipSize;
      if FGame.GetSavedGame.GetMonthsPassed <> -1 then
      begin
        FBase.GetStorageItems.AddItem(FItems[FSel], Change);
        FBase.GetStorageItems.AddItem(ammo.GetType, ammoPerVehicle * Change);
      end;
      // remove vehicles from craft
      for i := c.GetVehicles.Count - 1 downto 0 do
        if (c.GetVehicles[i].GetRules = rule) and (Change > 0) then
        begin
          c.GetVehicles[i].Free;
          c.GetVehicles.Delete(i);
          Dec(Change);
        end;
    end
    else
    begin
      if FGame.GetSavedGame.GetMonthsPassed <> -1 then
        FBase.GetStorageItems.AddItem(FItems[FSel], Change);
      for i := c.GetVehicles.Count - 1 downto 0 do
        if (c.GetVehicles[i].GetRules = rule) and (Change > 0) then
        begin
          c.GetVehicles[i].Free;
          c.GetVehicles.Delete(i);
          Dec(Change);
        end;
    end;
  end
  else
  begin
    c.GetItems.RemoveItem(FItems[FSel], Change);
    FTotalItems := FTotalItems - Change;
    if FGame.GetSavedGame.GetMonthsPassed > -1 then
      FBase.GetStorageItems.AddItem(FItems[FSel], Change);
  end;
  UpdateQuantity;
end;

procedure TCraftEquipmentState.MoveRight;
begin
  FTimerLeft.SetInterval(50);
  FTimerRight.SetInterval(50);
  MoveRightByValue(1);
end;

procedure TCraftEquipmentState.MoveRightByValue(Change: Integer);
var
  c: TCraft;
  rule: TRuleItem;
  bqty, room, canBeAdded, ammoPerVehicle, clipSize: Integer;
  ammo: TRuleItem;
  i: Integer;
begin
  c := FBase.GetCrafts[FCraft];
  rule := FGame.GetMod.GetItem(FItems[FSel], True);
  bqty := FBase.GetStorageItems.GetItem(FItems[FSel]);
  if FGame.GetSavedGame.GetMonthsPassed = -1 then
  begin
    if Change = MaxInt then Change := 10;
    bqty := Change;
  end;
  if (Change <= 0) or (bqty <= 0) then Exit;
  Change := Min(bqty, Change);

  if rule.IsFixed then
  begin
    // vehicle logic
    room := Min(c.GetRules.GetVehicles - c.GetNumVehicles, c.GetSpaceAvailable div 4);
    if room > 0 then
    begin
      Change := Min(room, Change);
      if not rule.GetCompatibleAmmo.IsEmpty then
      begin
        ammo := FGame.GetMod.GetItem(rule.GetCompatibleAmmo[0], True);
        if (ammo.GetClipSize > 0) and (rule.GetClipSize > 0) then
        begin
          clipSize := rule.GetClipSize;
          ammoPerVehicle := clipSize div ammo.GetClipSize;
        end
        else
        begin
          clipSize := ammo.GetClipSize;
          ammoPerVehicle := clipSize;
        end;
        if FGame.GetSavedGame.GetMonthsPassed = -1 then
          canBeAdded := Change
        else
          canBeAdded := Min(Change, FBase.GetStorageItems.GetItem(ammo.GetType) div ammoPerVehicle);
        if canBeAdded > 0 then
        begin
          for i := 1 to canBeAdded do
          begin
            if FGame.GetSavedGame.GetMonthsPassed <> -1 then
            begin
              FBase.GetStorageItems.RemoveItem(ammo.GetType, ammoPerVehicle);
              FBase.GetStorageItems.RemoveItem(FItems[FSel]);
            end;
            c.GetVehicles.Add(TVehicle.Create(rule, clipSize, 4));
          end;
        end
        else
        begin
          FTimerRight.Stop;
          FGame.PushState(TErrorMessageState.Create(Self,
            Translate('STR_NOT_ENOUGH_AMMO_TO_ARM_HWP').Arg(ammoPerVehicle).Arg(Translate(ammo.GetType)),
            FPalette, FGame.GetMod.GetInterface('craftEquipment').GetElement('errorMessage').Color,
            'BACK04.SCR', FGame.GetMod.GetInterface('craftEquipment').GetElement('errorPalette').Color));
        end;
      end
      else
      begin
        for i := 1 to Change do
        begin
          c.GetVehicles.Add(TVehicle.Create(rule, rule.GetClipSize, 4));
          if FGame.GetSavedGame.GetMonthsPassed <> -1 then
            FBase.GetStorageItems.RemoveItem(FItems[FSel]);
        end;
      end;
    end;
  end
  else
  begin
    if (c.GetRules.GetMaxItems > 0) and (FTotalItems + Change > c.GetRules.GetMaxItems) then
    begin
      FTimerRight.Stop;
      FGame.PushState(TErrorMessageState.Create(Self,
        Translate('STR_NO_MORE_EQUIPMENT_ALLOWED', c.GetRules.GetMaxItems),
        FPalette, FGame.GetMod.GetInterface('craftEquipment').GetElement('errorMessage').Color,
        'BACK04.SCR', FGame.GetMod.GetInterface('craftEquipment').GetElement('errorPalette').Color));
      Change := c.GetRules.GetMaxItems - FTotalItems;
    end;
    c.GetItems.AddItem(FItems[FSel], Change);
    FTotalItems := FTotalItems + Change;
    if FGame.GetSavedGame.GetMonthsPassed > -1 then
      FBase.GetStorageItems.RemoveItem(FItems[FSel], Change);
  end;
  UpdateQuantity;
end;

procedure TCraftEquipmentState.BtnClearClick(Sender: TObject; Action: TAction);
begin
  for FSel := 0 to FItems.Count - 1 do
    MoveLeftByValue(MaxInt);
end;

procedure TCraftEquipmentState.BtnInventoryClick(Sender: TObject; Action: TAction);
var
  craft: TCraft;
  bgen: TBattlescapeGenerator;
begin
  craft := FBase.GetCrafts[FCraft];
  if craft.GetNumSoldiers > 0 then
  begin
    FGame.GetSavedGame.SetBattleGame(TSavedBattleGame.Create);
    bgen := TBattlescapeGenerator.Create(FGame);
    try
      bgen.RunInventory(craft);
    finally
      bgen.Free;
    end;
    FGame.GetScreen.Clear;
    FGame.PushState(TInventoryState.Create(Self, False, 0));
  end;
end;

end.