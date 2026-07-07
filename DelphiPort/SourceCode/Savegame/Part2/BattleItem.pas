unit BattleItem;

interface

uses
  Classes, SysUtils, YAML, RuleItem, RuleInventory, BattleUnit, Tile, Mod;

type
  TBattleItem = class
  private
    FId: Integer;
    FRules: TRuleItem;
    FOwner: TBattleUnit;
    FPreviousOwner: TBattleUnit;
    FUnit: TBattleUnit;
    FTile: TTile;
    FSlot: TRuleInventory;
    FSlotX: Integer;
    FSlotY: Integer;
    FAmmoItem: TBattleItem;
    FFuseTimer: Integer;
    FAmmoQuantity: Integer;
    FPainKiller: Integer;
    FHeal: Integer;
    FStimulant: Integer;
    FXCOMProperty: Boolean;
    FDroppedOnAlienTurn: Boolean;
    FIsAmmo: Boolean;
  public
    constructor Create(Rules: TRuleItem; var Id: Integer);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode; Mod: TMod);
    function Save: TYamlNode;
    property Rules: TRuleItem read FRules;
    property AmmoQuantity: Integer read FAmmoQuantity write FAmmoQuantity;
    property FuseTimer: Integer read FFuseTimer write FFuseTimer;
    function SpendBullet: Boolean;
    property Owner: TBattleUnit read FOwner write FOwner;
    property PreviousOwner: TBattleUnit read FPreviousOwner write FPreviousOwner;
    procedure MoveToOwner(Owner: TBattleUnit);
    property Slot: TRuleInventory read FSlot write FSlot;
    property SlotX: Integer read FSlotX write FSlotX;
    property SlotY: Integer read FSlotY write FSlotY;
    function OccupiesSlot(X, Y: Integer; Item: TBattleItem = nil): Boolean;
    property AmmoItem: TBattleItem read FAmmoItem write SetAmmoItem;
    function NeedsAmmo: Boolean;
    function SetAmmoItem(Item: TBattleItem): Integer;
    property Tile: TTile read FTile write FTile;
    property Id: Integer read FId;
    property Unit_: TBattleUnit read FUnit write FUnit;
    property HealQuantity: Integer read FHeal write FHeal;
    property PainKillerQuantity: Integer read FPainKiller write FPainKiller;
    property StimulantQuantity: Integer read FStimulant write FStimulant;
    property XCOMProperty: Boolean read FXCOMProperty write FXCOMProperty;
    property TurnFlag: Boolean read FDroppedOnAlienTurn write FDroppedOnAlienTurn;
    procedure ConvertToCorpse(Rules: TRuleItem);
    property IsAmmo: Boolean read FIsAmmo write FIsAmmo;
  end;

implementation

constructor TBattleItem.Create(Rules: TRuleItem; var Id: Integer);
begin
  FId := Id;
  Inc(Id);
  FRules := Rules;
  FOwner := nil;
  FPreviousOwner := nil;
  FUnit := nil;
  FTile := nil;
  FSlot := nil;
  FSlotX := 0;
  FSlotY := 0;
  FAmmoItem := nil;
  FFuseTimer := -1;
  FAmmoQuantity := 0;
  FPainKiller := 0;
  FHeal := 0;
  FStimulant := 0;
  FXCOMProperty := False;
  FDroppedOnAlienTurn := False;
  FIsAmmo := False;
  if FRules <> nil then
  begin
    FAmmoQuantity := FRules.ClipSize;
    if FRules.BattleType = BT_MEDIKIT then
    begin
      FHeal := FRules.HealQuantity;
      FPainKiller := FRules.PainKillerQuantity;
      FStimulant := FRules.StimulantQuantity;
    end
    else if (FRules.BattleType = BT_FIREARM) or (FRules.BattleType = BT_MELEE) then
      if FRules.CompatibleAmmo.Count = 0 then
        FAmmoItem := Self;
  end;
end;

destructor TBattleItem.Destroy;
begin
  inherited;
end;

procedure TBattleItem.Load(const Node: TYamlNode; Mod: TMod);
begin
  var slotId := Node['inventoryslot'].AsString('NULL');
  if slotId <> 'NULL' then
  begin
    if Mod.GetInventory(slotId) <> nil then
      FSlot := Mod.GetInventory(slotId)
    else
      FSlot := Mod.GetInventory('STR_GROUND');
  end;
  FSlotX := Node['inventoryX'].AsInteger(FSlotX);
  FSlotY := Node['inventoryY'].AsInteger(FSlotY);
  FAmmoQuantity := Node['ammoqty'].AsInteger(FAmmoQuantity);
  FPainKiller := Node['painKiller'].AsInteger(FPainKiller);
  FHeal := Node['heal'].AsInteger(FHeal);
  FStimulant := Node['stimulant'].AsInteger(FStimulant);
  FFuseTimer := Node['fuseTimer'].AsInteger(FFuseTimer);
  FDroppedOnAlienTurn := Node['droppedOnAlienTurn'].AsBoolean(FDroppedOnAlienTurn);
  FXCOMProperty := Node['XCOMProperty'].AsBoolean(FXCOMProperty);
end;

function TBattleItem.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['id'] := FId;
  Result['type'] := FRules.Type;
  if FOwner <> nil then Result['owner'] := FOwner.Id;
  if FPreviousOwner <> nil then Result['previousOwner'] := FPreviousOwner.Id;
  if FUnit <> nil then Result['unit'] := FUnit.Id;
  if FSlot <> nil then Result['inventoryslot'] := FSlot.Id;
  Result['inventoryX'] := FSlotX;
  Result['inventoryY'] := FSlotY;
  if FTile <> nil then Result['position'] := FTile.Position.ToYaml;
  if FAmmoQuantity <> 0 then Result['ammoqty'] := FAmmoQuantity;
  if FAmmoItem <> nil then Result['ammoItem'] := FAmmoItem.Id;
  if (FRules <> nil) and (FRules.BattleType = BT_MEDIKIT) then
  begin
    Result['painKiller'] := FPainKiller;
    Result['heal'] := FHeal;
    Result['stimulant'] := FStimulant;
  end;
  if FFuseTimer <> -1 then Result['fuseTimer'] := FFuseTimer;
  if FDroppedOnAlienTurn then Result['droppedOnAlienTurn'] := FDroppedOnAlienTurn;
  if FXCOMProperty then Result['XCOMProperty'] := FXCOMProperty;
end;

function TBattleItem.SpendBullet: Boolean;
begin
  if FAmmoQuantity > 0 then
    Dec(FAmmoQuantity);
  Result := FAmmoQuantity > 0;
end;

procedure TBattleItem.MoveToOwner(Owner: TBattleUnit);
begin
  FPreviousOwner := FOwner;
  FOwner := Owner;
  if FPreviousOwner <> nil then
  begin
    for var i := 0 to FPreviousOwner.Inventory.Count - 1 do
      if FPreviousOwner.Inventory[i] = Self then
      begin
        FPreviousOwner.Inventory.Delete(i);
        Break;
      end;
  end;
  if FOwner <> nil then
    FOwner.Inventory.Add(Self);
end;

function TBattleItem.OccupiesSlot(X, Y: Integer; Item: TBattleItem): Boolean;
begin
  if Item = Self then Exit(False);
  if FSlot.Type_ = INV_HAND then Exit(True);
  if Item = nil then
    Result := (X >= FSlotX) and (X < FSlotX + FRules.InventoryWidth) and
              (Y >= FSlotY) and (Y < FSlotY + FRules.InventoryHeight)
  else
    Result := not ((X >= FSlotX + FRules.InventoryWidth) or
                   (X + Item.Rules.InventoryWidth <= FSlotX) or
                   (Y >= FSlotY + FRules.InventoryHeight) or
                   (Y + Item.Rules.InventoryHeight <= FSlotY));
end;

function TBattleItem.NeedsAmmo: Boolean;
begin
  Result := not (FAmmoItem = Self);
end;

function TBattleItem.SetAmmoItem(Item: TBattleItem): Integer;
begin
  if not NeedsAmmo then Exit(-2);
  if Item = nil then
  begin
    if FAmmoItem <> nil then
      FAmmoItem.IsAmmo := False;
    FAmmoItem := nil;
    Exit(0);
  end;
  if FAmmoItem <> nil then Exit(-1);
  for var ammoType in FRules.CompatibleAmmo do
    if ammoType = Item.Rules.Type then
    begin
      FAmmoItem := Item;
      Item.IsAmmo := True;
      Exit(0);
    end;
  Result := -2;
end;

procedure TBattleItem.ConvertToCorpse(Rules: TRuleItem);
begin
  if (FUnit <> nil) and (FRules.BattleType = BT_CORPSE) and (Rules.BattleType = BT_CORPSE) then
    FRules := Rules;
end;

end.