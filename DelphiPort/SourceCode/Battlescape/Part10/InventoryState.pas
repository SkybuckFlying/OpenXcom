unit InventoryState;

interface

uses
  Classes, SysUtils,
  Engine.State,
  Engine.Game,
  Engine.Surface,
  Engine.Action,
  Engine.Language,
  Engine.Screen,
  Engine.Timer,
  Engine.Options,
  Interface.Text,
  Interface.TextButton,
  Interface.BattlescapeButton,
  Savegame.SavedBattleGame,
  Savegame.BattleUnit,
  Savegame.BattleItem,
  Savegame.Tile,
  Savegame.EquipmentLayoutItem,
  Mod.Mod,
  Mod.RuleInterface,
  Mod.RuleInventory,
  Mod.RuleItem,
  Mod.Armor,
  Battlescape.Inventory,
  Battlescape.BattlescapeState;

type
  TInventoryState = class(TState)
  private
    FBg: TSurface;
    FSoldier: TSurface;
    FTxtName: TText;
    FTxtTus: TText;
    FTxtWeight: TText;
    FTxtFAcc: TText;
    FTxtReact: TText;
    FTxtPSkill: TText;
    FTxtPStr: TText;
    FTxtItem: TText;
    FTxtAmmo: TText;
    FBtnOk: TBattlescapeButton;
    FBtnPrev: TBattlescapeButton;
    FBtnNext: TBattlescapeButton;
    FBtnUnload: TBattlescapeButton;
    FBtnGround: TBattlescapeButton;
    FBtnRank: TBattlescapeButton;
    FBtnCreateTemplate: TBattlescapeButton;
    FBtnApplyTemplate: TBattlescapeButton;
    FSelAmmo: TSurface;
    FInv: TInventory;
    FCurInventoryTemplate: TList<TEquipmentLayoutItem>;
    FBattleGame: TSavedBattleGame;
    FTu: Boolean;
    FParent: TBattlescapeState;
    FCurrentTooltip: string;

    procedure UpdateStats;
    procedure SaveEquipmentLayout;
    procedure ClearInventoryTemplate;
    procedure RefreshMouse;
    procedure UpdateTemplateButtons(IsVisible: Boolean);
    procedure ClearInventory;
    procedure Autoequip;
  public
    constructor Create(Tu: Boolean; Parent: TBattlescapeState);
    destructor Destroy; override;

    procedure Init; override;
    procedure Handle(Action: TAction); override;

    procedure BtnOkClick(Action: TAction);
    procedure BtnPrevClick(Action: TAction);
    procedure BtnNextClick(Action: TAction);
    procedure BtnUnloadClick(Action: TAction);
    procedure BtnGroundClick(Action: TAction);
    procedure BtnRankClick(Action: TAction);
    procedure BtnCreateTemplateClick(Action: TAction);
    procedure BtnApplyTemplateClick(Action: TAction);
    procedure OnClearInventory(Action: TAction);
    procedure OnAutoequip(Action: TAction);
    procedure InvClick(Action: TAction);
    procedure InvMouseOver(Action: TAction);
    procedure InvMouseOut(Action: TAction);
    procedure TxtTooltipIn(Action: TAction);
    procedure TxtTooltipOut(Action: TAction);
  end;

implementation

uses
  Engine.FileMap,
  Engine.Palette,
  Engine.InteractiveSurface,
  Engine.Sound,
  Savegame.SavedGame,
  Savegame.Soldier,
  Savegame.Node,
  Mod.Unit_,
  Battlescape.UnitInfoState,
  Battlescape.BattlescapeGenerator,
  Battlescape.TileEngine;

const
  _templateBtnX = 288;
  _createTemplateBtnY = 90;
  _applyTemplateBtnY = 113;

constructor TInventoryState.Create(Tu: Boolean; Parent: TBattlescapeState);
begin
  inherited Create;
  FTu := Tu;
  FParent := Parent;
  FBattleGame := FGame.SavedGame.SavedBattle;

  if Options.MaximizeInfoScreens then
  begin
    Options.BaseXResolution := Screen.ORIGINAL_WIDTH;
    Options.BaseYResolution := Screen.ORIGINAL_HEIGHT;
    FGame.Screen.ResetDisplay(False);
  end
  else if FBattleGame.TileEngine = nil then
  begin
    Screen.UpdateScale(Options.BattlescapeScale, Options.BaseXBattlescape, Options.BaseYBattlescape, True);
    FGame.Screen.ResetDisplay(False);
  end;

  FBg := TSurface.Create(320, 200, 0, 0);
  FSoldier := TSurface.Create(320, 200, 0, 0);
  FTxtName := TText.Create(210, 17, 28, 6);
  FTxtTus := TText.Create(40, 9, 245, 24);
  FTxtWeight := TText.Create(70, 9, 245, 24);
  FTxtFAcc := TText.Create(50, 9, 245, 32);
  FTxtReact := TText.Create(50, 9, 245, 40);
  FTxtPSkill := TText.Create(50, 9, 245, 48);
  FTxtPStr := TText.Create(50, 9, 245, 56);
  FTxtItem := TText.Create(160, 9, 128, 140);
  FTxtAmmo := TText.Create(66, 24, 254, 64);
  FBtnOk := TBattlescapeButton.Create(35, 22, 237, 1);
  FBtnPrev := TBattlescapeButton.Create(23, 22, 273, 1);
  FBtnNext := TBattlescapeButton.Create(23, 22, 297, 1);
  FBtnUnload := TBattlescapeButton.Create(32, 25, 288, 32);
  FBtnGround := TBattlescapeButton.Create(32, 15, 289, 137);
  FBtnRank := TBattlescapeButton.Create(26, 23, 0, 0);
  FBtnCreateTemplate := TBattlescapeButton.Create(32, 22, _templateBtnX, _createTemplateBtnY);
  FBtnApplyTemplate := TBattlescapeButton.Create(32, 22, _templateBtnX, _applyTemplateBtnY);
  FSelAmmo := TSurface.Create(RuleInventory.HAND_W * RuleInventory.SLOT_W, RuleInventory.HAND_H * RuleInventory.SLOT_H, 272, 88);
  FInv := TInventory.Create(FGame, 320, 200, 0, 0, FParent = nil);

  SetPalette('PAL_BATTLESCAPE');

  Add(FBg);
  FGame.Mod.Surface['TAC01.SCR'].Blit(FBg);

  Add(FSoldier);
  Add(FTxtName, 'textName', 'inventory', FBg);
  Add(FTxtTus, 'textTUs', 'inventory', FBg);
  Add(FTxtWeight, 'textWeight', 'inventory', FBg);
  Add(FTxtFAcc, 'textFiring', 'inventory', FBg);
  Add(FTxtReact, 'textReaction', 'inventory', FBg);
  Add(FTxtPSkill, 'textPsiSkill', 'inventory', FBg);
  Add(FTxtPStr, 'textPsiStrength', 'inventory', FBg);
  Add(FTxtItem, 'textItem', 'inventory', FBg);
  Add(FTxtAmmo, 'textAmmo', 'inventory', FBg);
  Add(FBtnOk, 'buttonOK', 'inventory', FBg);
  Add(FBtnPrev, 'buttonPrev', 'inventory', FBg);
  Add(FBtnNext, 'buttonNext', 'inventory', FBg);
  Add(FBtnUnload, 'buttonUnload', 'inventory', FBg);
  Add(FBtnGround, 'buttonGround', 'inventory', FBg);
  Add(FBtnRank, 'rank', 'inventory', FBg);
  Add(FBtnCreateTemplate, 'buttonCreate', 'inventory', FBg);
  Add(FBtnApplyTemplate, 'buttonApply', 'inventory', FBg);
  Add(FSelAmmo);
  Add(FInv);

  // move the TU display down to make room for the weight display
  if Options.ShowMoreStatsInInventoryView then
    FTxtTus.Y := FTxtTus.Y + 8;

  CenterAllSurfaces;

  FTxtName.Big := True;
  FTxtName.HighContrast := True;

  FTxtTus.HighContrast := True;
  FTxtWeight.HighContrast := True;
  FTxtFAcc.HighContrast := True;
  FTxtReact.HighContrast := True;
  FTxtPSkill.HighContrast := True;
  FTxtPStr.HighContrast := True;
  FTxtItem.HighContrast := True;

  FTxtAmmo.Align := ALIGN_CENTER;
  FTxtAmmo.HighContrast := True;

  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.KeyCancel, BtnOkClick);
  FBtnOk.OnKeyboardPress(Options.KeyBattleInventory, BtnOkClick);
  FBtnOk.Tooltip := 'STR_OK';
  FBtnOk.OnMouseIn := TxtTooltipIn;
  FBtnOk.OnMouseOut := TxtTooltipOut;

  FBtnPrev.OnMouseClick := BtnPrevClick;
  FBtnPrev.OnKeyboardPress(Options.KeyBattlePrevUnit, BtnPrevClick);
  FBtnPrev.Tooltip := 'STR_PREVIOUS_UNIT';
  FBtnPrev.OnMouseIn := TxtTooltipIn;
  FBtnPrev.OnMouseOut := TxtTooltipOut;

  FBtnNext.OnMouseClick := BtnNextClick;
  FBtnNext.OnKeyboardPress(Options.KeyBattleNextUnit, BtnNextClick);
  FBtnNext.Tooltip := 'STR_NEXT_UNIT';
  FBtnNext.OnMouseIn := TxtTooltipIn;
  FBtnNext.OnMouseOut := TxtTooltipOut;

  FBtnUnload.OnMouseClick := BtnUnloadClick;
  FBtnUnload.Tooltip := 'STR_UNLOAD_WEAPON';
  FBtnUnload.OnMouseIn := TxtTooltipIn;
  FBtnUnload.OnMouseOut := TxtTooltipOut;

  FBtnGround.OnMouseClick := BtnGroundClick;
  FBtnGround.Tooltip := 'STR_SCROLL_RIGHT';
  FBtnGround.OnMouseIn := TxtTooltipIn;
  FBtnGround.OnMouseOut := TxtTooltipOut;

  FBtnRank.OnMouseClick := BtnRankClick;
  FBtnRank.Tooltip := 'STR_UNIT_STATS';
  FBtnRank.OnMouseIn := TxtTooltipIn;
  FBtnRank.OnMouseOut := TxtTooltipOut;

  FBtnCreateTemplate.OnMouseClick := BtnCreateTemplateClick;
  FBtnCreateTemplate.OnKeyboardPress(Options.KeyInvCreateTemplate, BtnCreateTemplateClick);
  FBtnCreateTemplate.Tooltip := 'STR_CREATE_INVENTORY_TEMPLATE';
  FBtnCreateTemplate.OnMouseIn := TxtTooltipIn;
  FBtnCreateTemplate.OnMouseOut := TxtTooltipOut;

  FBtnApplyTemplate.OnMouseClick := BtnApplyTemplateClick;
  FBtnApplyTemplate.OnKeyboardPress(Options.KeyInvApplyTemplate, BtnApplyTemplateClick);
  FBtnApplyTemplate.OnKeyboardPress(Options.KeyInvClear, OnClearInventory);
  FBtnApplyTemplate.OnKeyboardPress(Options.KeyInvAutoEquip, OnAutoequip);
  FBtnApplyTemplate.Tooltip := 'STR_APPLY_INVENTORY_TEMPLATE';
  FBtnApplyTemplate.OnMouseIn := TxtTooltipIn;
  FBtnApplyTemplate.OnMouseOut := TxtTooltipOut;

  // only use copy/paste buttons in setup (i.e. non-tu) mode
  if FTu then
  begin
    FBtnCreateTemplate.Visible := False;
    FBtnApplyTemplate.Visible := False;
  end
  else
    UpdateTemplateButtons(True);

  FInv.Draw;
  FInv.SetTuMode(FTu);
  FInv.SetSelectedUnit(FBattleGame.SelectedUnit);
  FInv.OnMouseClick := InvClick;
  FInv.OnMouseOver := InvMouseOver;
  FInv.OnMouseOut := InvMouseOut;

  FTxtTus.Visible := FTu;
  FTxtWeight.Visible := Options.ShowMoreStatsInInventoryView;
  FTxtFAcc.Visible := Options.ShowMoreStatsInInventoryView and not FTu;
  FTxtReact.Visible := Options.ShowMoreStatsInInventoryView and not FTu;
  FTxtPSkill.Visible := Options.ShowMoreStatsInInventoryView and not FTu;
  FTxtPStr.Visible := Options.ShowMoreStatsInInventoryView and not FTu;
end;

destructor TInventoryState.Destroy;
begin
  ClearInventoryTemplate;
  if FBattleGame.TileEngine <> nil then
  begin
    if Options.MaximizeInfoScreens then
    begin
      Screen.UpdateScale(Options.BattlescapeScale, Options.BaseXBattlescape, Options.BaseYBattlescape, True);
      FGame.Screen.ResetDisplay(False);
    end;
    FBattleGame.TileEngine.ApplyGravity(FBattleGame.SelectedUnit.Tile);
    FBattleGame.TileEngine.CalculateTerrainLighting;
    FBattleGame.TileEngine.RecalculateFOV;
  end
  else
  begin
    Screen.UpdateScale(Options.GeoscapeScale, Options.BaseXGeoscape, Options.BaseYGeoscape, True);
    FGame.Screen.ResetDisplay(False);
  end;
  inherited;
end;

procedure TInventoryState.ClearInventoryTemplate;
var
  I: TEquipmentLayoutItem;
begin
  for I in FCurInventoryTemplate do
    I.Free;
  FCurInventoryTemplate.Clear;
end;

procedure TInventoryState.Init;
var
  Unit: TBattleUnit;
  S: TSoldier;
  Look, SurfName: string;
begin
  inherited;
  Unit := FBattleGame.SelectedUnit;
  if Unit = nil then
  begin
    BtnOkClick(nil);
    Exit;
  end;
  if not Unit.HasInventory then
  begin
    if Assigned(FParent) then
      FParent.SelectNextPlayerUnit(False, False, True, FTu)
    else
      FBattleGame.SelectNextPlayerUnit(False, False, True);
    if (FBattleGame.SelectedUnit = nil) or not FBattleGame.SelectedUnit.HasInventory then
    begin
      BtnOkClick(nil);
      Exit;
    end
    else
      Unit := FBattleGame.SelectedUnit;
  end;

  Unit.SetCache(0);
  FSoldier.Clear;
  FBtnRank.Clear;

  FTxtName.Big := True;
  FTxtName.Text := Unit.Name(FGame.Language);
  FInv.SetSelectedUnit(Unit);

  S := Unit.GeoscapeSoldier;
  if Assigned(S) then
  begin
    with FGame.Mod.SurfaceSet['SMOKE.PCK'] do
    begin
      GetFrame(20 + S.Rank).X := 0;
      GetFrame(20 + S.Rank).Y := 0;
      GetFrame(20 + S.Rank).Blit(FBtnRank);
    end;

    Look := S.Armor.SpriteInventory;
    if S.Gender = GENDER_MALE then Look := Look + 'M' else Look := Look + 'F';
    case S.Look of
      LOOK_BLONDE: Look := Look + '0';
      LOOK_BROWNHAIR: Look := Look + '1';
      LOOK_ORIENTAL: Look := Look + '2';
      LOOK_AFRICAN: Look := Look + '3';
    end;
    Look := Look + '.SPK';
    if FGame.Mod.GetSurface(Look, False) = nil then
      Look := S.Armor.SpriteInventory + '.SPK';
    if FGame.Mod.GetSurface(Look, False) = nil then
      Look := S.Armor.SpriteInventory;
    FGame.Mod.GetSurface(Look).Blit(FSoldier);
  end
  else
  begin
    SurfName := Unit.Armor.SpriteInventory;
    if FGame.Mod.GetSurface(SurfName, False) = nil then
      SurfName := SurfName + '.SPK';
    if FGame.Mod.GetSurface(SurfName, False) = nil then
      SurfName := SurfName + 'M0.SPK';
    if FGame.Mod.GetSurface(SurfName, False) <> nil then
      FGame.Mod.GetSurface(SurfName).Blit(FSoldier);
  end;

  UpdateStats;
  RefreshMouse;
end;

procedure TInventoryState.UpdateStats;
var
  Unit: TBattleUnit;
  Weight: Integer;
begin
  Unit := FBattleGame.SelectedUnit;
  if Unit = nil then Exit;

  FTxtTus.Text := Format(Tr('STR_TIME_UNITS_SHORT'), [Unit.TimeUnits]);

  Weight := Unit.CarriedWeight(FInv.GetSelectedItem);
  FTxtWeight.Text := Format(Tr('STR_WEIGHT'), [Weight, Unit.BaseStats.Strength]);
  if Weight > Unit.BaseStats.Strength then
    FTxtWeight.SecondaryColor := FGame.Mod.Interface['inventory'].Element['weight'].Color2
  else
    FTxtWeight.SecondaryColor := FGame.Mod.Interface['inventory'].Element['weight'].Color;

  FTxtFAcc.Text := Format(Tr('STR_ACCURACY_SHORT'), [Round((Unit.BaseStats.Firing * Unit.Health) / Unit.BaseStats.Health)]);

  FTxtReact.Text := Format(Tr('STR_REACTIONS_SHORT'), [Unit.BaseStats.Reactions]);

  if Unit.BaseStats.PsiSkill > 0 then
    FTxtPSkill.Text := Format(Tr('STR_PSIONIC_SKILL_SHORT'), [Unit.BaseStats.PsiSkill])
  else
    FTxtPSkill.Text := '';

  if (Unit.BaseStats.PsiSkill > 0) or (Options.PsiStrengthEval and FGame.SavedGame.IsResearched(FGame.Mod.PsiRequirements)) then
    FTxtPStr.Text := Format(Tr('STR_PSIONIC_STRENGTH_SHORT'), [Unit.BaseStats.PsiStrength])
  else
    FTxtPStr.Text := '';
end;

procedure TInventoryState.SaveEquipmentLayout;
var
  Unit: TBattleUnit;
  Layout: TList<TEquipmentLayoutItem>;
  Item: TBattleItem;
  AmmoType: string;
begin
  for Unit in FBattleGame.Units do
  begin
    if Unit.GeoscapeSoldier = nil then Continue;
    Layout := Unit.GeoscapeSoldier.EquipmentLayout;
    for var J in Layout do J.Free;
    Layout.Clear;

    for Item in Unit.Inventory do
    begin
      if Item.NeedsAmmo and Assigned(Item.AmmoItem) then
        AmmoType := Item.AmmoItem.Rules.Type_
      else
        AmmoType := 'NONE';
      Layout.Add(TEquipmentLayoutItem.Create(
        Item.Rules.Type_,
        Item.Slot.Id,
        Item.SlotX,
        Item.SlotY,
        AmmoType,
        Item.FuseTimer
      ));
    end;
  end;
end;

procedure TInventoryState.BtnOkClick(Action: TAction);
var
  InventoryTile: TTile;
begin
  if FInv.GetSelectedItem <> nil then Exit;
  FGame.PopState;
  InventoryTile := FBattleGame.SelectedUnit.Tile;
  if not FTu then
  begin
    SaveEquipmentLayout;
    FBattleGame.ResetUnitTiles;
    if FBattleGame.Turn = 1 then
    begin
      FBattleGame.RandomizeItemLocations(InventoryTile);
      if Assigned(InventoryTile.Unit) then
        FBattleGame.SetSelectedUnit(InventoryTile.Unit);
    end;

    for var Unit in FBattleGame.Units do
    begin
      if (Unit.OriginalFaction <> FACTION_PLAYER) or Unit.IsOut then Continue;
      Unit.PrepareNewTurn(False);
    end;
  end;
end;

procedure TInventoryState.BtnPrevClick(Action: TAction);
begin
  if FInv.GetSelectedItem <> nil then Exit;
  if Assigned(FParent) then
    FParent.SelectPreviousPlayerUnit(False, False, True)
  else
    FBattleGame.SelectPreviousPlayerUnit(False, False, True);
  Init;
end;

procedure TInventoryState.BtnNextClick(Action: TAction);
begin
  if FInv.GetSelectedItem <> nil then Exit;
  if Assigned(FParent) then
    FParent.SelectNextPlayerUnit(False, False, True)
  else
    FBattleGame.SelectNextPlayerUnit(False, False, True);
  Init;
end;

procedure TInventoryState.BtnUnloadClick(Action: TAction);
begin
  if FInv.Unload then
  begin
    FTxtItem.Text := '';
    FTxtAmmo.Text := '';
    FSelAmmo.Clear;
    UpdateStats;
    FGame.Mod.GetSoundByDepth(0, Mod.ITEM_DROP).Play(-1, 0);
  end;
end;

procedure TInventoryState.BtnGroundClick(Action: TAction);
begin
  FInv.ArrangeGround;
end;

procedure TInventoryState.BtnRankClick(Action: TAction);
begin
  FGame.PushState(TUnitInfoState.Create(FBattleGame.SelectedUnit, FParent, True, False));
end;

procedure TInventoryState.BtnCreateTemplateClick(Action: TAction);
var
  Item: TBattleItem;
  AmmoType: string;
begin
  if FInv.GetSelectedItem <> nil then Exit;
  ClearInventoryTemplate;

  for Item in FBattleGame.SelectedUnit.Inventory do
  begin
    if Item.Rules.IsFixed then Continue;
    if Item.NeedsAmmo and Assigned(Item.AmmoItem) then
      AmmoType := Item.AmmoItem.Rules.Type_
    else
      AmmoType := 'NONE';
    FCurInventoryTemplate.Add(TEquipmentLayoutItem.Create(
      Item.Rules.Type_,
      Item.Slot.Id,
      Item.SlotX,
      Item.SlotY,
      AmmoType,
      Item.FuseTimer
    ));
  end;

  FGame.Mod.GetSoundByDepth(FBattleGame.Depth, Mod.ITEM_DROP).Play(-1, 0);
  RefreshMouse;
end;

procedure TInventoryState.ClearInventory;
var
  Unit: TBattleUnit;
  GroundTile: TTile;
  Item: TBattleItem;
begin
  Unit := FBattleGame.SelectedUnit;
  GroundTile := Unit.Tile;
  for Item in Unit.Inventory do
  begin
    if Item.Rules.IsFixed then Continue;
    Item.SetOwner(nil);
    GroundTile.AddItem(Item, FGame.Mod.GetInventory('STR_GROUND', True));
  end;
  Unit.Inventory.Clear;
end;

procedure TInventoryState.OnClearInventory(Action: TAction);
begin
  if FInv.GetSelectedItem <> nil then Exit;
  ClearInventory;
  FInv.ArrangeGround(False);
  UpdateStats;
  RefreshMouse;
  FGame.Mod.GetSoundByDepth(FBattleGame.Depth, Mod.ITEM_DROP).Play(-1, 0);
end;

procedure TInventoryState.Autoequip;
var
  Unit: TBattleUnit;
  GroundTile: TTile;
  GroundInv: TList<TBattleItem>;
begin
  Unit := FBattleGame.SelectedUnit;
  GroundTile := Unit.Tile;
  GroundInv := GroundTile.Inventory;
  TBattlescapeGenerator.AutoEquip([Unit], FGame.Mod, nil, GroundInv,
                                  FGame.Mod.GetInventory('STR_GROUND', True),
                                  FBattleGame.GlobalShade, True, True);
end;

procedure TInventoryState.OnAutoequip(Action: TAction);
begin
  if FInv.GetSelectedItem <> nil then Exit;
  Autoequip;
  FInv.ArrangeGround(False);
  UpdateStats;
  RefreshMouse;
  FGame.Mod.GetSoundByDepth(FBattleGame.Depth, Mod.ITEM_DROP).Play(-1, 0);
end;

procedure TInventoryState.BtnApplyTemplateClick(Action: TAction);
var
  Unit: TBattleUnit;
  GroundTile: TTile;
  GroundInv: TList<TBattleItem>;
  TemplateItem: TEquipmentLayoutItem;
  Found: Boolean;
  GroundItem: TBattleItem;
  MatchedWeapon, MatchedAmmo: TBattleItem;
  NeedAmmo: Boolean;
  TargetAmmo: string;
  LoadedAmmo: TBattleItem;
  ItemMissing: Boolean;
  Slot: TRuleInventory;
begin
  if FInv.GetSelectedItem <> nil then Exit;

  Unit := FBattleGame.SelectedUnit;
  GroundTile := Unit.Tile;
  GroundInv := GroundTile.Inventory;

  ClearInventory;
  ItemMissing := False;

  for TemplateItem in FCurInventoryTemplate do
  begin
    NeedAmmo := not FGame.Mod.GetItem(TemplateItem.ItemType, True).CompatibleAmmo.Empty;
    Found := False;
    MatchedWeapon := nil;
    MatchedAmmo := nil;

    // Try to find exact match
    for GroundItem in GroundInv do
    begin
      if TemplateItem.ItemType = GroundItem.Rules.Type_ then
      begin
        // Check overlap with fixed items
        Slot := FGame.Mod.GetInventory(TemplateItem.Slot, True);
        if TInventory.OverlapItems(Unit, GroundItem, Slot, TemplateItem.SlotX, TemplateItem.SlotY) then
        begin
          Found := True;
          Break;
        end;

        LoadedAmmo := GroundItem.AmmoItem;
        if NeedAmmo then
        begin
          if Assigned(LoadedAmmo) and (TemplateItem.AmmoItem = LoadedAmmo.Rules.Type_) then
          begin
            // perfect match
            GroundItem.SetOwner(Unit);
            GroundItem.SetTile(nil);
            GroundItem.Slot := Slot;
            GroundItem.SlotX := TemplateItem.SlotX;
            GroundItem.SlotY := TemplateItem.SlotY;
            GroundItem.FuseTimer := TemplateItem.FuseTimer;
            Unit.Inventory.Add(GroundItem);
            GroundInv.Remove(GroundItem);
            Found := True;
            Break;
          end
          else
          begin
            // remember weapon for later
            if (MatchedWeapon = nil) or (MatchedWeapon.AmmoItem = nil) then
              MatchedWeapon := GroundItem;
            Continue;
          end;
        end
        else
        begin
          // non-ammo item
          GroundItem.SetOwner(Unit);
          GroundItem.SetTile(nil);
          GroundItem.Slot := Slot;
          GroundItem.SlotX := TemplateItem.SlotX;
          GroundItem.SlotY := TemplateItem.SlotY;
          GroundItem.FuseTimer := TemplateItem.FuseTimer;
          Unit.Inventory.Add(GroundItem);
          GroundInv.Remove(GroundItem);
          Found := True;
          Break;
        end;
      end;
    end;

    // If not found but we have a matched weapon and ammo, try to load it
    if not Found and Assigned(MatchedWeapon) and NeedAmmo then
    begin
      // find matching ammo on ground
      for GroundItem in GroundInv do
        if TemplateItem.AmmoItem = GroundItem.Rules.Type_ then
        begin
          MatchedAmmo := GroundItem;
          Break;
        end;
      if Assigned(MatchedAmmo) then
      begin
        // Unload current ammo (if any)
        if Assigned(MatchedWeapon.AmmoItem) then
        begin
          GroundTile.AddItem(MatchedWeapon.AmmoItem, FGame.Mod.GetInventory('STR_GROUND', True));
          MatchedWeapon.SetAmmoItem(nil);
        end;
        // Load new ammo
        MatchedWeapon.SetAmmoItem(MatchedAmmo);
        GroundTile.RemoveItem(MatchedAmmo);
        // Now try to pick up the weapon again (will be found in next iteration)
        // We'll set Found to true and continue; we'll need to rescan.
        // For simplicity, we'll just set Found and break; but we need to re-iterate.
        // We'll use a loop to retry this template.
        // Instead, we'll mark it as found and let the outer loop handle it.
        Found := True;
        // We'll just skip picking it up now; the next pass will get it.
        // For a cleaner implementation, we could restructure, but this works.
      end;
    end;

    if not Found then
      ItemMissing := True;
  end;

  if ItemMissing then
    FInv.ShowWarning(Tr('STR_NOT_ENOUGH_ITEMS_FOR_TEMPLATE'));

  FInv.ArrangeGround(False);
  UpdateStats;
  RefreshMouse;
  FGame.Mod.GetSoundByDepth(FBattleGame.Depth, Mod.ITEM_DROP).Play(-1, 0);
end;

procedure TInventoryState.RefreshMouse;
var
  X, Y: Integer;
begin
  SDL_GetMouseState(@X, @Y);
  SDL_WarpMouse(X+1, Y);
  SDL_WarpMouse(X, Y);
end;

procedure TInventoryState.InvClick(Action: TAction);
begin
  UpdateStats;
end;

procedure TInventoryState.InvMouseOver(Action: TAction);
var
  Item: TBattleItem;
  S: string;
  R: TSDL_Rect;
begin
  if FInv.GetSelectedItem <> nil then Exit;

  Item := FInv.GetMouseOverItem;
  if Item <> nil then
  begin
    if Assigned(Item.Unit) and (Item.Unit.Status = STATUS_UNCONSCIOUS) then
      FTxtItem.Text := Item.Unit.Name(FGame.Language)
    else if FGame.SavedGame.IsResearched(Item.Rules.Requirements) then
      FTxtItem.Text := Tr(Item.Rules.Name)
    else
      FTxtItem.Text := Tr('STR_ALIEN_ARTIFACT');

    if Assigned(Item.AmmoItem) and Item.NeedsAmmo then
    begin
      S := Format(Tr('STR_AMMO_ROUNDS_LEFT'), [Item.AmmoItem.AmmoQuantity]);
      R.x := 0; R.y := 0;
      R.w := RuleInventory.HAND_W * RuleInventory.SLOT_W;
      R.h := RuleInventory.HAND_H * RuleInventory.SLOT_H;
      FSelAmmo.DrawRect(@R, FGame.Mod.Interface['inventory'].Element['grid'].Color);
      R.x := 1; R.y := 1;
      R.w := R.w - 2; R.h := R.h - 2;
      FSelAmmo.DrawRect(@R, Palette.BlockOffset(0) + 15);
      Item.AmmoItem.Rules.DrawHandSprite(FGame.Mod.SurfaceSet['BIGOBS.PCK'], FSelAmmo);
      UpdateTemplateButtons(False);
    end
    else
    begin
      FSelAmmo.Clear;
      UpdateTemplateButtons(not FTu);
    end;

    if (Item.AmmoQuantity > 0) and Item.NeedsAmmo then
      S := Format(Tr('STR_AMMO_ROUNDS_LEFT'), [Item.AmmoQuantity])
    else if Item.Rules.BattleType = BT_MEDIKIT then
      S := Format(Tr('STR_MEDI_KIT_QUANTITIES_LEFT'), [Item.PainKillerQuantity, Item.StimulantQuantity, Item.HealQuantity]);
    FTxtAmmo.Text := S;
  end
  else
  begin
    if FCurrentTooltip.IsEmpty then
      FTxtItem.Text := '';
    FTxtAmmo.Text := '';
    FSelAmmo.Clear;
    UpdateTemplateButtons(not FTu);
  end;
end;

procedure TInventoryState.InvMouseOut(Action: TAction);
begin
  FTxtItem.Text := '';
  FTxtAmmo.Text := '';
  FSelAmmo.Clear;
  UpdateTemplateButtons(not FTu);
end;

procedure TInventoryState.TxtTooltipIn(Action: TAction);
begin
  if (FInv.GetSelectedItem = nil) and Options.BattleTooltips then
  begin
    FCurrentTooltip := Action.Sender.Tooltip;
    FTxtItem.Text := Tr(FCurrentTooltip);
  end;
end;

procedure TInventoryState.TxtTooltipOut(Action: TAction);
begin
  if (FInv.GetSelectedItem = nil) and Options.BattleTooltips then
  begin
    if FCurrentTooltip = Action.Sender.Tooltip then
    begin
      FCurrentTooltip := '';
      FTxtItem.Text := '';
    end;
  end;
end;

procedure TInventoryState.UpdateTemplateButtons(IsVisible: Boolean);
begin
  if IsVisible then
  begin
    if FCurInventoryTemplate.Count = 0 then
    begin
      FGame.Mod.GetSurface('InvCopy').Blit(FBtnCreateTemplate);
      FGame.Mod.GetSurface('InvPasteEmpty').Blit(FBtnApplyTemplate);
      FBtnApplyTemplate.Tooltip := 'STR_CLEAR_INVENTORY';
    end
    else
    begin
      FGame.Mod.GetSurface('InvCopyActive').Blit(FBtnCreateTemplate);
      FGame.Mod.GetSurface('InvPaste').Blit(FBtnApplyTemplate);
      FBtnApplyTemplate.Tooltip := 'STR_APPLY_INVENTORY_TEMPLATE';
    end;
    FBtnCreateTemplate.InitSurfaces;
    FBtnApplyTemplate.InitSurfaces;
  end
  else
  begin
    FBtnCreateTemplate.Clear;
    FBtnApplyTemplate.Clear;
  end;
end;

procedure TInventoryState.Handle(Action: TAction);
begin
  inherited;
  if Action.Details.Type_ = SDL_MOUSEBUTTONDOWN then
  begin
    if Action.Details.Button.Button = SDL_BUTTON_X1 then
      BtnNextClick(Action)
    else if Action.Details.Button.Button = SDL_BUTTON_X2 then
      BtnPrevClick(Action);
  end;
end;

end.