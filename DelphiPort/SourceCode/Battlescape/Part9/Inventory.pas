unit Inventory;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Math,
  System.Classes, System.Types,
  Engine.InteractiveSurface, Engine.Game, Engine.Action, Engine.State,
  Engine.Surface, Engine.Font, Engine.Language, Engine.Options,
  Engine.Sound, Engine.Screen, Engine.Timer, Engine.Palette,
  Interface.Text, Interface.NumberText,
  Mod.Mod, Mod.RuleInventory, Mod.RuleInterface, Mod.RuleItem,
  Savegame.BattleUnit, Savegame.BattleItem, Savegame.Tile,
  Savegame.SavedBattleGame,
  Battlescape.WarningMessage, Battlescape.PrimeGrenadeState;

type
  TInventory = class(TInteractiveSurface)
  private
    FGame: TGame;
    FGrid: TSurface;
    FItems: TSurface;
    FSelection: TSurface;
    FWarning: TWarningMessage;
    FSelUnit: TBattleUnit;
    FSelItem: TBattleItem;
    FTuMode: Boolean;
    FBaseMode: Boolean;
    FMouseOverItem: TBattleItem;
    FGroundOffset: Integer;
    FAnimFrame: Integer;
    FStackLevel: TDictionary<TPair<Integer,Integer>, Integer>;
    FGrenadeIndicators: TList<TPair<Integer,Integer>>;
    FStackNumber: TNumberText;
    FAnimTimer: TTimer;
    FDepth: Integer;
    procedure MoveItem(AItem: TBattleItem; ASlot: TRuleInventory; AX, AY: Integer);
    function GetSlotInPosition(var X, Y: Integer): TRuleInventory;
    procedure ArrangeGround(AlterOffset: Boolean = True);
    function FitItem(NewSlot: TRuleInventory; Item: TBattleItem; var WarningMsg: string): Boolean;
    function CanBeStacked(ItemA, ItemB: TBattleItem): Boolean;
    procedure DrawPrimers;
    procedure DrawGrid;
    procedure DrawItems;
  public
    constructor Create(AGame: TGame; AWidth, AHeight, AX, AY: Integer; ABase: Boolean = False);
    destructor Destroy; override;
    procedure SetPalette(AColors: PSDL_Color; AFirstColor: Integer = 0; ANColors: Integer = 256); override;
    procedure SetTuMode(ATu: Boolean);
    procedure SetSelectedUnit(AUnit: TBattleUnit);
    procedure Draw; override;
    function GetSelectedItem: TBattleItem;
    procedure SetSelectedItem(AItem: TBattleItem);
    function GetMouseOverItem: TBattleItem;
    procedure SetMouseOverItem(AItem: TBattleItem);
    procedure Think;
    procedure Blit(ASurface: TSurface); override;
    procedure MouseOver(AAction: TAction; AState: TState); override;
    procedure MouseClick(AAction: TAction; AState: TState); override;
    function Unload: Boolean;
    procedure ShowWarning(const AMsg: string);
    class function OverlapItems(AUnit: TBattleUnit; AItem: TBattleItem; ASlot: TRuleInventory; AX: Integer = 0; AY: Integer = 0): Boolean;
  end;

implementation

uses
  Engine.SurfaceSet, Engine.LocalizedText;

{ TInventory }

constructor TInventory.Create(AGame: TGame; AWidth, AHeight, AX, AY: Integer; ABase: Boolean);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FGame := AGame;
  FDepth := FGame.GetSavedGame.GetSavedBattle.GetDepth;
  FGrid := TSurface.Create(AWidth, AHeight, 0, 0);
  FItems := TSurface.Create(AWidth, AHeight, 0, 0);
  FSelection := TSurface.Create(RuleInventory.HAND_W * RuleInventory.SLOT_W,
                                RuleInventory.HAND_H * RuleInventory.SLOT_H, AX, AY);
  FWarning := TWarningMessage.Create(224, 24, 48, 176);
  FWarning.InitText(FGame.GetMod.GetFont('FONT_BIG'), FGame.GetMod.GetFont('FONT_SMALL'), FGame.GetLanguage);
  FWarning.Color := FGame.GetMod.GetInterface('battlescape').GetElement('warning').Color2;
  FWarning.TextColor := FGame.GetMod.GetInterface('battlescape').GetElement('warning').Color;

  FStackNumber := TNumberText.Create(15, 15, 0, 0);
  FStackNumber.Bordered := True;

  FAnimTimer := TTimer.Create(125);
  FAnimTimer.OnTimer := DrawPrimers;
  FAnimTimer.Start;

  FSelUnit := nil;
  FSelItem := nil;
  FTuMode := True;
  FBaseMode := ABase;
  FMouseOverItem := nil;
  FGroundOffset := 999;
  FAnimFrame := 0;
  FStackLevel := TDictionary<TPair<Integer,Integer>, Integer>.Create;
  FGrenadeIndicators := TList<TPair<Integer,Integer>>.Create;

  ArrangeGround;
end;

destructor TInventory.Destroy;
begin
  FGrid.Free;
  FItems.Free;
  FSelection.Free;
  FWarning.Free;
  FStackNumber.Free;
  FAnimTimer.Free;
  FStackLevel.Free;
  FGrenadeIndicators.Free;
  inherited;
end;

procedure TInventory.SetPalette(AColors: PSDL_Color; AFirstColor, ANColors: Integer);
begin
  inherited SetPalette(AColors, AFirstColor, ANColors);
  FGrid.SetPalette(AColors, AFirstColor, ANColors);
  FItems.SetPalette(AColors, AFirstColor, ANColors);
  FSelection.SetPalette(AColors, AFirstColor, ANColors);
  FWarning.SetPalette(AColors, AFirstColor, ANColors);
  FStackNumber.SetPalette(FPalette);
end;

procedure TInventory.SetTuMode(ATu: Boolean);
begin
  FTuMode := ATu;
end;

procedure TInventory.SetSelectedUnit(AUnit: TBattleUnit);
begin
  FSelUnit := AUnit;
  FGroundOffset := 999;
  ArrangeGround;
end;

procedure TInventory.Draw;
begin
  DrawGrid;
  DrawItems;
end;

procedure TInventory.DrawGrid;
var
  Text: TText;
  Rule: TRuleInterface;
  Color: Byte;
  Rect: TRect;
  Inv: TRuleInventory;
  Slot: TRuleSlot;
  X, Y: Integer;
begin
  FGrid.Clear;
  Text := TText.Create(80, 9, 0, 0);
  try
    Text.Palette := FGrid.Palette;
    Text.InitText(FGame.GetMod.GetFont('FONT_BIG'), FGame.GetMod.GetFont('FONT_SMALL'), FGame.GetLanguage);
    Rule := FGame.GetMod.GetInterface('inventory');
    Text.Color := Rule.GetElement('textSlots').Color;
    Text.HighContrast := True;
    Color := Rule.GetElement('grid').Color;

    for Inv in FGame.GetMod.GetInventories.Values do
    begin
      if Inv.GetType = INV_SLOT then
      begin
        for Slot in Inv.GetSlots do
        begin
          Rect := Rect(Inv.GetX + RuleInventory.SLOT_W * Slot.X,
                       Inv.GetY + RuleInventory.SLOT_H * Slot.Y,
                       RuleInventory.SLOT_W + 1,
                       RuleInventory.SLOT_H + 1);
          FGrid.DrawRect(Rect, Color);
          Rect.Left := Rect.Left + 1; Rect.Top := Rect.Top + 1;
          Rect.Width := Rect.Width - 2; Rect.Height := Rect.Height - 2;
          FGrid.DrawRect(Rect, 0);
        end;
      end
      else if Inv.GetType = INV_HAND then
      begin
        Rect := Rect(Inv.GetX, Inv.GetY,
                     RuleInventory.HAND_W * RuleInventory.SLOT_W,
                     RuleInventory.HAND_H * RuleInventory.SLOT_H);
        FGrid.DrawRect(Rect, Color);
        Rect.Left := Rect.Left + 1; Rect.Top := Rect.Top + 1;
        Rect.Width := Rect.Width - 2; Rect.Height := Rect.Height - 2;
        FGrid.DrawRect(Rect, 0);
      end
      else if Inv.GetType = INV_GROUND then
      begin
        X := Inv.GetX;
        while X <= 320 do
        begin
          Y := Inv.GetY;
          while Y <= 200 do
          begin
            Rect := Rect(X, Y, RuleInventory.SLOT_W + 1, RuleInventory.SLOT_H + 1);
            FGrid.DrawRect(Rect, Color);
            Rect.Left := Rect.Left + 1; Rect.Top := Rect.Top + 1;
            Rect.Width := Rect.Width - 2; Rect.Height := Rect.Height - 2;
            FGrid.DrawRect(Rect, 0);
            Y := Y + RuleInventory.SLOT_H;
          end;
          X := X + RuleInventory.SLOT_W;
        end;
      end;

      Text.X := Inv.GetX;
      Text.Y := Inv.GetY - Text.Font.Height - Text.Font.Spacing;
      Text.Text := FGame.GetLanguage.GetString(Inv.GetId);
      Text.Blit(FGrid);
    end;
  finally
    Text.Free;
  end;
end;

procedure TInventory.DrawItems;
var
  Texture: TSurfaceSet;
  Frame: TSurface;
  Item: TBattleItem;
  Pair: TPair<Integer,Integer>;
  StackLayer: TSurface;
begin
  FItems.Clear;
  FGrenadeIndicators.Clear;
  FStackLevel.Clear;

  if FSelUnit = nil then Exit;

  Texture := FGame.GetMod.GetSurfaceSet('BIGOBS.PCK');

  // Draw soldier items
  for Item in FSelUnit.GetInventory do
  begin
    if Item = FSelItem then Continue;
    Frame := Texture.GetFrame(Item.GetRules.GetBigSprite);
    if Item.GetSlot.GetType = INV_SLOT then
    begin
      Frame.X := Item.GetSlot.GetX + Item.GetSlotX * RuleInventory.SLOT_W;
      Frame.Y := Item.GetSlot.GetY + Item.GetSlotY * RuleInventory.SLOT_H;
    end
    else if Item.GetSlot.GetType = INV_HAND then
    begin
      Frame.X := Item.GetSlot.GetX + (RuleInventory.HAND_W - Item.GetRules.GetInventoryWidth) * RuleInventory.SLOT_W div 2;
      Frame.Y := Item.GetSlot.GetY + (RuleInventory.HAND_H - Item.GetRules.GetInventoryHeight) * RuleInventory.SLOT_H div 2;
    end;
    Frame.Blit(FItems);
    if Item.GetFuseTimer >= 0 then
      FGrenadeIndicators.Add(TPair<Integer,Integer>.Create(Frame.X, Frame.Y));
  end;

  // Ground items
  StackLayer := TSurface.Create(FItems.Width, FItems.Height, 0, 0);
  try
    StackLayer.Palette := FPalette;
    for Item in FSelUnit.GetTile.GetInventory do
    begin
      if (Item = FSelItem) or (Item.GetSlotX < FGroundOffset) or
         (Item.GetRules.GetInventoryHeight = 0) or (Item.GetRules.GetInventoryWidth = 0) then Continue;
      Frame := Texture.GetFrame(Item.GetRules.GetBigSprite);
      Frame.X := Item.GetSlot.GetX + (Item.GetSlotX - FGroundOffset) * RuleInventory.SLOT_W;
      Frame.Y := Item.GetSlot.GetY + Item.GetSlotY * RuleInventory.SLOT_H;
      Frame.Blit(FItems);
      if Item.GetFuseTimer >= 0 then
        FGrenadeIndicators.Add(TPair<Integer,Integer>.Create(Frame.X, Frame.Y));

      // Stack count
      var Key := TPair<Integer,Integer>.Create(Item.GetSlotX, Item.GetSlotY);
      FStackLevel.AddOrSetValue(Key, FStackLevel.GetValueOrDefault(Key, 0) + 1);
      if FStackLevel[Key] > 1 then
      begin
        FStackNumber.X := Item.GetSlot.GetX + ((Item.GetSlotX + Item.GetRules.GetInventoryWidth) - FGroundOffset) * RuleInventory.SLOT_W - 4;
        if FStackLevel[Key] > 9 then FStackNumber.X := FStackNumber.X - 4;
        FStackNumber.Y := Item.GetSlot.GetY + (Item.GetSlotY + Item.GetRules.GetInventoryHeight) * RuleInventory.SLOT_H - 6;
        FStackNumber.Value := FStackLevel[Key];
        FStackNumber.Color := FGame.GetMod.GetInterface('inventory').GetElement('numStack').Color;
        FStackNumber.Draw;
        FStackNumber.Blit(StackLayer);
      end;
    end;
    StackLayer.Blit(FItems);
  finally
    StackLayer.Free;
  end;
end;

procedure TInventory.MoveItem(AItem: TBattleItem; ASlot: TRuleInventory; AX, AY: Integer);
begin
  if ASlot = nil then
  begin
    if AItem.GetSlot.GetType = INV_GROUND then
      FSelUnit.GetTile.RemoveItem(AItem)
    else
      AItem.MoveToOwner(nil);
  end
  else
  begin
    if ASlot <> AItem.GetSlot then
    begin
      if ASlot.GetType = INV_GROUND then
      begin
        AItem.MoveToOwner(nil);
        FSelUnit.GetTile.AddItem(AItem, ASlot);
        if (AItem.GetUnit <> nil) and (AItem.GetUnit.GetStatus = STATUS_UNCONSCIOUS) then
          AItem.GetUnit.SetPosition(FSelUnit.GetPosition);
      end
      else if (AItem.GetSlot = nil) or (AItem.GetSlot.GetType = INV_GROUND) then
      begin
        AItem.MoveToOwner(FSelUnit);
        FSelUnit.GetTile.RemoveItem(AItem);
        AItem.SetTurnFlag(False);
        if (AItem.GetUnit <> nil) and (AItem.GetUnit.GetStatus = STATUS_UNCONSCIOUS) then
          AItem.GetUnit.SetPosition(Position(-1,-1,-1));
      end;
    end;
    AItem.SetSlot(ASlot);
    AItem.SetSlotX(AX);
    AItem.SetSlotY(AY);
  end;
end;

class function TInventory.OverlapItems(AUnit: TBattleUnit; AItem: TBattleItem; ASlot: TRuleInventory; AX, AY: Integer): Boolean;
var
  Item: TBattleItem;
begin
  Result := False;
  if ASlot.GetType <> INV_GROUND then
  begin
    for Item in AUnit.GetInventory do
      if (Item.GetSlot = ASlot) and Item.OccupiesSlot(AX, AY, AItem) then Exit(True);
  end
  else if AUnit.GetTile <> nil then
  begin
    for Item in AUnit.GetTile.GetInventory do
      if Item.OccupiesSlot(AX, AY, AItem) then Exit(True);
  end;
end;

function TInventory.GetSlotInPosition(var X, Y: Integer): TRuleInventory;
var
  Inv: TRuleInventory;
begin
  for Inv in FGame.GetMod.GetInventories.Values do
    if Inv.CheckSlotInPosition(X, Y) then Exit(Inv);
  Result := nil;
end;

function TInventory.GetSelectedItem: TBattleItem;
begin
  Result := FSelItem;
end;

procedure TInventory.SetSelectedItem(AItem: TBattleItem);
begin
  if (AItem <> nil) and AItem.GetRules.IsFixed then AItem := nil;
  FSelItem := AItem;
  if FSelItem = nil then
    FSelection.Clear
  else
  begin
    if FSelItem.GetSlot.GetType = INV_GROUND then
    begin
      var Key := TPair<Integer,Integer>.Create(FSelItem.GetSlotX, FSelItem.GetSlotY);
      FStackLevel.AddOrSetValue(Key, FStackLevel.GetValueOrDefault(Key, 0) - 1);
    end;
    FSelItem.GetRules.DrawHandSprite(FGame.GetMod.GetSurfaceSet('BIGOBS.PCK'), FSelection);
  end;
  DrawItems;
end;

function TInventory.GetMouseOverItem: TBattleItem;
begin
  Result := FMouseOverItem;
end;

procedure TInventory.SetMouseOverItem(AItem: TBattleItem);
begin
  if (AItem <> nil) and AItem.GetRules.IsFixed then
    FMouseOverItem := nil
  else
    FMouseOverItem := AItem;
end;

procedure TInventory.Think;
begin
  FWarning.Think;
  FAnimTimer.Think(0, Self);
end;

procedure TInventory.Blit(ASurface: TSurface);
begin
  Clear;
  FGrid.Blit(Self);
  FItems.Blit(Self);
  FSelection.Blit(Self);
  FWarning.Blit(Self);
  inherited Blit(ASurface);
end;

procedure TInventory.MouseOver(AAction: TAction; AState: TState);
var
  X, Y: Integer;
  Slot: TRuleInventory;
  Item: TBattleItem;
begin
  FSelection.X := Round(AAction.GetAbsoluteXMouse) - FSelection.Width div 2 - GetX;
  FSelection.Y := Round(AAction.GetAbsoluteYMouse) - FSelection.Height div 2 - GetY;

  if FSelUnit = nil then Exit;

  X := Round(AAction.GetAbsoluteXMouse) - GetX;
  Y := Round(AAction.GetAbsoluteYMouse) - GetY;
  Slot := GetSlotInPosition(X, Y);
  if Slot <> nil then
  begin
    if Slot.GetType = INV_GROUND then X := X + FGroundOffset;
    Item := FSelUnit.GetItem(Slot, X, Y);
    SetMouseOverItem(Item);
  end
  else
    SetMouseOverItem(nil);

  FSelection.X := Round(AAction.GetAbsoluteXMouse) - FSelection.Width div 2 - GetX;
  FSelection.Y := Round(AAction.GetAbsoluteYMouse) - FSelection.Height div 2 - GetY;
  inherited MouseOver(AAction, AState);
end;

procedure TInventory.MouseClick(AAction: TAction; AState: TState);
var
  X, Y: Integer;
  Slot: TRuleInventory;
  Item, SelItem: TBattleItem;
  CanStack: Boolean;
  Wrong: Boolean;
  WarningMsg: string;
  Placed: Boolean;
begin
  if AAction.GetDetails.button.button = SDL_BUTTON_LEFT then
  begin
    if FSelUnit = nil then Exit;

    // Pickup
    if FSelItem = nil then
    begin
      X := Round(AAction.GetAbsoluteXMouse) - GetX;
      Y := Round(AAction.GetAbsoluteYMouse) - GetY;
      Slot := GetSlotInPosition(X, Y);
      if Slot <> nil then
      begin
        if Slot.GetType = INV_GROUND then X := X + FGroundOffset;
        Item := FSelUnit.GetItem(Slot, X, Y);
        if (Item <> nil) and (not Item.GetRules.IsFixed) then
        begin
          if (SDL_GetModState and KMOD_CTRL) <> 0 then
          begin
            WarningMsg := 'STR_NOT_ENOUGH_SPACE';
            Placed := False;
            var NewSlot := FGame.GetMod.GetInventory('STR_GROUND', True);

            if Slot.GetType = INV_GROUND then
            begin
              case Item.GetRules.GetBattleType of
                BT_FIREARM: NewSlot := FGame.GetMod.GetInventory('STR_RIGHT_HAND', True);
                BT_MINDPROBE, BT_PSIAMP, BT_MELEE, BT_CORPSE: NewSlot := FGame.GetMod.GetInventory('STR_LEFT_HAND', True);
                else
                  if Item.GetRules.GetInventoryHeight > 2 then
                    NewSlot := FGame.GetMod.GetInventory('STR_BACK_PACK', True)
                  else
                    NewSlot := FGame.GetMod.GetInventory('STR_BELT', True);
              end;
            end;

            if NewSlot.GetType <> INV_GROUND then
            begin
              var Key := TPair<Integer,Integer>.Create(Item.GetSlotX, Item.GetSlotY);
              FStackLevel.AddOrSetValue(Key, FStackLevel.GetValueOrDefault(Key, 0) - 1);
              Placed := FitItem(NewSlot, Item, WarningMsg);
              if not Placed then
              begin
                for var Inv in FGame.GetMod.GetInventories.Values do
                  if (Inv.GetType <> INV_GROUND) and (not Placed) then
                    Placed := FitItem(Inv, Item, WarningMsg);
                if not Placed then
                  FStackLevel.AddOrSetValue(Key, FStackLevel.GetValueOrDefault(Key, 0) + 1);
              end;
            end
            else
            begin
              if (not FTuMode) or FSelUnit.SpendTimeUnits(Item.GetSlot.GetCost(NewSlot)) then
              begin
                Placed := True;
                MoveItem(Item, NewSlot, 0, 0);
                FGame.GetMod.GetSoundByDepth(FDepth, Mod.ITEM_DROP).Play;
                ArrangeGround(False);
              end
              else
                WarningMsg := 'STR_NOT_ENOUGH_TIME_UNITS';
            end;

            if not Placed then
              FWarning.ShowMessage(FGame.GetLanguage.GetString(WarningMsg));
          end
          else
          begin
            SetSelectedItem(Item);
            if Item.GetFuseTimer >= 0 then
              FWarning.ShowMessage(FGame.GetLanguage.GetString('STR_GRENADE_IS_ACTIVATED'));
          end;
        end;
      end;
    end
    // Drop item
    else
    begin
      SelItem := FSelItem;
      X := FSelection.X + (RuleInventory.HAND_W - SelItem.GetRules.GetInventoryWidth) * RuleInventory.SLOT_W div 2 + RuleInventory.SLOT_W div 2;
      Y := FSelection.Y + (RuleInventory.HAND_H - SelItem.GetRules.GetInventoryHeight) * RuleInventory.SLOT_H div 2 + RuleInventory.SLOT_H div 2;
      Slot := GetSlotInPosition(X, Y);

      if Slot <> nil then
      begin
        if Slot.GetType = INV_GROUND then X := X + FGroundOffset;
        Item := FSelUnit.GetItem(Slot, X, Y);
        CanStack := (Slot.GetType = INV_GROUND) and CanBeStacked(Item, SelItem);

        if (Item = nil) or (Item = SelItem) or CanStack then
        begin
          if (not OverlapItems(FSelUnit, SelItem, Slot, X, Y)) and Slot.FitItemInSlot(SelItem.GetRules, X, Y) then
          begin
            if (not FTuMode) or FSelUnit.SpendTimeUnits(SelItem.GetSlot.GetCost(Slot)) then
            begin
              MoveItem(SelItem, Slot, X, Y);
              if Slot.GetType = INV_GROUND then
              begin
                var Key := TPair<Integer,Integer>.Create(X, Y);
                FStackLevel.AddOrSetValue(Key, FStackLevel.GetValueOrDefault(Key, 0) + 1);
              end;
              SetSelectedItem(nil);
              FGame.GetMod.GetSoundByDepth(FDepth, Mod.ITEM_DROP).Play;
            end
            else
              FWarning.ShowMessage(FGame.GetLanguage.GetString('STR_NOT_ENOUGH_TIME_UNITS'));
          end
          else if CanStack then
          begin
            if (not FTuMode) or FSelUnit.SpendTimeUnits(SelItem.GetSlot.GetCost(Slot)) then
            begin
              MoveItem(SelItem, Slot, Item.GetSlotX, Item.GetSlotY);
              var Key := TPair<Integer,Integer>.Create(Item.GetSlotX, Item.GetSlotY);
              FStackLevel.AddOrSetValue(Key, FStackLevel.GetValueOrDefault(Key, 0) + 1);
              SetSelectedItem(nil);
              FGame.GetMod.GetSoundByDepth(FDepth, Mod.ITEM_DROP).Play;
            end
            else
              FWarning.ShowMessage(FGame.GetLanguage.GetString('STR_NOT_ENOUGH_TIME_UNITS'));
          end;
        end
        else if not Item.GetRules.GetCompatibleAmmo.IsEmpty then
        begin
          Wrong := True;
          for var AmmoType in Item.GetRules.GetCompatibleAmmo do
            if AmmoType = SelItem.GetRules.GetType then Wrong := False;
          if Wrong then
            FWarning.ShowMessage(FGame.GetLanguage.GetString('STR_WRONG_AMMUNITION_FOR_THIS_WEAPON'))
          else
          begin
            if Item.GetAmmoItem <> nil then
              FWarning.ShowMessage(FGame.GetLanguage.GetString('STR_WEAPON_IS_ALREADY_LOADED'))
            else if (not FTuMode) or FSelUnit.SpendTimeUnits(15) then
            begin
              MoveItem(SelItem, nil, 0, 0);
              Item.SetAmmoItem(SelItem);
              SelItem.MoveToOwner(nil);
              SetSelectedItem(nil);
              FGame.GetMod.GetSoundByDepth(FDepth, Mod.ITEM_RELOAD).Play;
              if Item.GetSlot.GetType = INV_GROUND then ArrangeGround(False);
            end
            else
              FWarning.ShowMessage(FGame.GetLanguage.GetString('STR_NOT_ENOUGH_TIME_UNITS'));
          end;
        end;
      end
      else
      begin
        // Try using mouse position directly (for stacking)
        X := Round(AAction.GetAbsoluteXMouse) - GetX;
        Y := Round(AAction.GetAbsoluteYMouse) - GetY;
        Slot := GetSlotInPosition(X, Y);
        if (Slot <> nil) and (Slot.GetType = INV_GROUND) then
        begin
          X := X + FGroundOffset;
          Item := FSelUnit.GetItem(Slot, X, Y);
          if CanBeStacked(Item, SelItem) then
          begin
            if (not FTuMode) or FSelUnit.SpendTimeUnits(SelItem.GetSlot.GetCost(Slot)) then
            begin
              MoveItem(SelItem, Slot, Item.GetSlotX, Item.GetSlotY);
              var Key := TPair<Integer,Integer>.Create(Item.GetSlotX, Item.GetSlotY);
              FStackLevel.AddOrSetValue(Key, FStackLevel.GetValueOrDefault(Key, 0) + 1);
              SetSelectedItem(nil);
              FGame.GetMod.GetSoundByDepth(FDepth, Mod.ITEM_DROP).Play;
            end
            else
              FWarning.ShowMessage(FGame.GetLanguage.GetString('STR_NOT_ENOUGH_TIME_UNITS'));
          end;
        end;
      end;
    end;
  end
  else if AAction.GetDetails.button.button = SDL_BUTTON_RIGHT then
  begin
    if FSelItem = nil then
    begin
      if (not FBaseMode) or Options.IncludePrimeStateInSavedLayout then
      begin
        if not FTuMode then
        begin
          X := Round(AAction.GetAbsoluteXMouse) - GetX;
          Y := Round(AAction.GetAbsoluteYMouse) - GetY;
          Slot := GetSlotInPosition(X, Y);
          if Slot <> nil then
          begin
            if Slot.GetType = INV_GROUND then X := X + FGroundOffset;
            Item := FSelUnit.GetItem(Slot, X, Y);
            if (Item <> nil) and (Item.GetRules.GetBattleType in [BT_GRENADE, BT_PROXIMITYGRENADE]) then
            begin
              if Item.GetFuseTimer = -1 then
              begin
                if Item.GetRules.GetBattleType = BT_PROXIMITYGRENADE then
                begin
                  FWarning.ShowMessage(FGame.GetLanguage.GetString('STR_GRENADE_IS_ACTIVATED'));
                  Item.SetFuseTimer(0);
                  ArrangeGround(False);
                end
                else
                  FGame.PushState(TPrimeGrenadeState.Create(nil, True, Item));
              end
              else
              begin
                FWarning.ShowMessage(FGame.GetLanguage.GetString('STR_GRENADE_IS_DEACTIVATED'));
                Item.SetFuseTimer(-1);
                ArrangeGround(False);
              end;
            end;
          end;
        end
        else
          FGame.PopState; // Close inventory on right-click in battle
      end;
    end
    else
    begin
      // Return item to original position
      if FSelItem.GetSlot.GetType = INV_GROUND then
      begin
        var Key := TPair<Integer,Integer>.Create(FSelItem.GetSlotX, FSelItem.GetSlotY);
        FStackLevel.AddOrSetValue(Key, FStackLevel.GetValueOrDefault(Key, 0) + 1);
      end;
      SetSelectedItem(nil);
    end;
  end;

  inherited MouseClick(AAction, AState);
end;

function TInventory.Unload: Boolean;
var
  Item: TBattleItem;
begin
  Result := False;
  if FSelItem = nil then Exit;
  if (FSelItem.GetAmmoItem = nil) and (not FSelItem.GetRules.GetCompatibleAmmo.IsEmpty) then
  begin
    FWarning.ShowMessage(FGame.GetLanguage.GetString('STR_NO_AMMUNITION_LOADED'));
    Exit;
  end;
  if (FSelItem.GetAmmoItem = nil) or (not FSelItem.NeedsAmmo) then Exit;

  for Item in FSelUnit.GetInventory do
    if (Item.GetSlot.GetType = INV_HAND) and (Item <> FSelItem) then
    begin
      FWarning.ShowMessage(FGame.GetLanguage.GetString('STR_BOTH_HANDS_MUST_BE_EMPTY'));
      Exit;
    end;

  if (not FTuMode) or FSelUnit.SpendTimeUnits(8) then
  begin
    MoveItem(FSelItem.GetAmmoItem, FGame.GetMod.GetInventory('STR_LEFT_HAND', True), 0, 0);
    FSelItem.GetAmmoItem.MoveToOwner(FSelUnit);
    MoveItem(FSelItem, FGame.GetMod.GetInventory('STR_RIGHT_HAND', True), 0, 0);
    FSelItem.MoveToOwner(FSelUnit);
    FSelItem.SetAmmoItem(nil);
    SetSelectedItem(nil);
    Result := True;
  end
  else
    FWarning.ShowMessage(FGame.GetLanguage.GetString('STR_NOT_ENOUGH_TIME_UNITS'));
end;

procedure TInventory.ArrangeGround(AlterOffset: Boolean);
var
  Ground: TRuleInventory;
  SlotsX, SlotsY, X, Y, XMax: Integer;
  Item: TBattleItem;
  Ok: Boolean;
  Key: TPair<Integer,Integer>;
begin
  Ground := FGame.GetMod.GetInventory('STR_GROUND', True);
  SlotsX := (Screen.ORIGINAL_WIDTH - Ground.GetX) div RuleInventory.SLOT_W;
  SlotsY := (Screen.ORIGINAL_HEIGHT - Ground.GetY) div RuleInventory.SLOT_H;
  X := 0; Y := 0; XMax := 0;
  FStackLevel.Clear;

  if FSelUnit <> nil then
  begin
    // Reset all ground items to a large X offset
    for Item in FSelUnit.GetTile.GetInventory do
    begin
      Item.SetSlot(Ground);
      Item.SetSlotX(1000000);
      Item.SetSlotY(0);
    end;

    // Place each item
    for Item in FSelUnit.GetTile.GetInventory do
    begin
      X := 0; Y := 0; Ok := False;
      while not Ok do
      begin
        Ok := True;
        for var XD := 0 to Item.GetRules.GetInventoryWidth - 1 do
          if (X + XD) mod SlotsX < X mod SlotsX then Ok := False
          else
            for var YD := 0 to Item.GetRules.GetInventoryHeight - 1 do
            begin
              var Existing := FSelUnit.GetItem(Ground, X + XD, Y + YD);
              if (Existing <> nil) and (not CanBeStacked(Existing, Item)) then Ok := False;
            end;
        if Ok then
        begin
          Item.SetSlotX(X);
          Item.SetSlotY(Y);
          if Item.GetRules.GetInventoryWidth > 0 then
          begin
            Key := TPair<Integer,Integer>.Create(X, Y);
            FStackLevel.AddOrSetValue(Key, FStackLevel.GetValueOrDefault(Key, 0) + 1);
          end;
          XMax := Max(XMax, X + Item.GetRules.GetInventoryWidth);
        end
        else
        begin
          Inc(Y);
          if Y > SlotsY - Item.GetRules.GetInventoryHeight then
          begin
            Y := 0;
            Inc(X);
          end;
        end;
      end;
    end;
  end;

  if AlterOffset then
  begin
    if XMax >= FGroundOffset + SlotsX then
      FGroundOffset := FGroundOffset + SlotsX
    else
      FGroundOffset := 0;
  end;
  DrawItems;
end;

function TInventory.FitItem(NewSlot: TRuleInventory; Item: TBattleItem; var WarningMsg: string): Boolean;
var
  Placed: Boolean;
  MaxSlotX, MaxSlotY, X, Y: Integer;
  Slot: TRuleSlot;
begin
  Placed := False;
  MaxSlotX := 0; MaxSlotY := 0;
  for Slot in NewSlot.GetSlots do
  begin
    if Slot.X > MaxSlotX then MaxSlotX := Slot.X;
    if Slot.Y > MaxSlotY then MaxSlotY := Slot.Y;
  end;
  for Y := 0 to MaxSlotY do
    for X := 0 to MaxSlotX do
      if (not OverlapItems(FSelUnit, Item, NewSlot, X, Y)) and NewSlot.FitItemInSlot(Item.GetRules, X, Y) then
      begin
        if (not FTuMode) or FSelUnit.SpendTimeUnits(Item.GetSlot.GetCost(NewSlot)) then
        begin
          Placed := True;
          MoveItem(Item, NewSlot, X, Y);
          FGame.GetMod.GetSoundByDepth(FDepth, Mod.ITEM_DROP).Play;
          DrawItems;
        end
        else
          WarningMsg := 'STR_NOT_ENOUGH_TIME_UNITS';
        Break;
      end;
  Result := Placed;
end;

function TInventory.CanBeStacked(ItemA, ItemB: TBattleItem): Boolean;
begin
  Result := (ItemA <> nil) and (ItemB <> nil) and
            (ItemA.GetRules = ItemB.GetRules) and
            (((ItemA.GetAmmoItem = nil) and (ItemB.GetAmmoItem = nil)) or
             ((ItemA.GetAmmoItem <> nil) and (ItemB.GetAmmoItem <> nil) and
              (ItemA.GetAmmoItem.GetRules = ItemB.GetAmmoItem.GetRules) and
              (ItemA.GetAmmoItem.GetAmmoQuantity = ItemB.GetAmmoItem.GetAmmoQuantity))) and
            (ItemA.GetFuseTimer = -1) and (ItemB.GetFuseTimer = -1) and
            (ItemA.GetUnit = nil) and (ItemB.GetUnit = nil) and
            (ItemA.GetPainKillerQuantity = ItemB.GetPainKillerQuantity) and
            (ItemA.GetHealQuantity = ItemB.GetHealQuantity) and
            (ItemA.GetStimulantQuantity = ItemB.GetStimulantQuantity);
end;

procedure TInventory.ShowWarning(const AMsg: string);
begin
  FWarning.ShowMessage(AMsg);
end;

procedure TInventory.DrawPrimers;
const
  Pulsate: array[0..7] of Byte = (0,1,2,3,4,3,2,1);
var
  TempSurface: TSurface;
  Pair: TPair<Integer,Integer>;
begin
  if FAnimFrame = 8 then FAnimFrame := 0;
  TempSurface := FGame.GetMod.GetSurfaceSet('SCANG.DAT').GetFrame(6);
  for Pair in FGrenadeIndicators do
    TempSurface.BlitNShade(FItems, Pair.Key, Pair.Value, Pulsate[FAnimFrame]);
  Inc(FAnimFrame);
end;

end.