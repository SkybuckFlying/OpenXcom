unit Production;

interface

uses
  Classes, SysUtils, YAML, RuleManufacture, Base, SavedGame, Mod, ItemContainer,
  Craft, BaseFacility;

type
  TProductionProgress = (PROGRESS_NOT_COMPLETE, PROGRESS_COMPLETE,
                         PROGRESS_NOT_ENOUGH_MONEY, PROGRESS_NOT_ENOUGH_MATERIALS,
                         PROGRESS_MAX, PROGRESS_CONSTRUCTION);

  TProduction = class
  private
    FRules: TRuleManufacture;
    FAmountTotal: Integer;
    FInfinite: Boolean;
    FTimeSpent: Integer;
    FEngineers: Integer;
    FSell: Boolean;
    function HaveEnoughMoneyForOneMoreUnit(Game: TSavedGame): Boolean;
    function HaveEnoughMaterialsForOneMoreUnit(Base: TBase; Mod: TMod): Boolean;
    procedure StartItem(Base: TBase; Game: TSavedGame; Mod: TMod);
  public
    constructor Create(Rules: TRuleManufacture; Amount: Integer);
    property AmountTotal: Integer read FAmountTotal write FAmountTotal;
    property Infinite: Boolean read FInfinite write FInfinite;
    property TimeSpent: Integer read FTimeSpent write FTimeSpent;
    property AssignedEngineers: Integer read FEngineers write FEngineers;
    property SellItems: Boolean read FSell write FSell;
    function AmountProduced: Integer;
    function Step(Base: TBase; Game: TSavedGame; Mod: TMod): TProductionProgress;
    property Rules: TRuleManufacture read FRules;
    function Save: TYamlNode;
    procedure Load(const Node: TYamlNode);
  end;

implementation

uses
  Math, RuleItem, RuleCraft;

constructor TProduction.Create(Rules: TRuleManufacture; Amount: Integer);
begin
  FRules := Rules;
  FAmountTotal := Amount;
  FInfinite := False;
  FTimeSpent := 0;
  FEngineers := 0;
  FSell := False;
end;

function TProduction.AmountProduced: Integer;
begin
  if FRules.ManufactureTime > 0 then
    Result := FTimeSpent div FRules.ManufactureTime
  else
    Result := FAmountTotal;
end;

function TProduction.HaveEnoughMoneyForOneMoreUnit(Game: TSavedGame): Boolean;
begin
  Result := FRules.HaveEnoughMoneyForOneMoreUnit(Game.Funds);
end;

function TProduction.HaveEnoughMaterialsForOneMoreUnit(Base: TBase; Mod: TMod): Boolean;
begin
  for var pair in FRules.RequiredItems do
  begin
    if Mod.GetItem(pair.Key) <> nil then
    begin
      if Base.StorageItems.GetItem(pair.Key) < pair.Value then
        Exit(False);
    end
    else if Mod.GetCraft(pair.Key) <> nil then
    begin
      if Base.GetCraftCount(pair.Key) < pair.Value then
        Exit(False);
    end;
  end;
  Result := True;
end;

procedure TProduction.StartItem(Base: TBase; Game: TSavedGame; Mod: TMod);
begin
  Game.Funds := Game.Funds - FRules.ManufactureCost;
  for var pair in FRules.RequiredItems do
  begin
    if Mod.GetItem(pair.Key) <> nil then
      Base.StorageItems.RemoveItem(pair.Key, pair.Value)
    else if Mod.GetCraft(pair.Key) <> nil then
    begin
      for var i := Base.Crafts.Count - 1 downto 0 do
        if Base.Crafts[i].Rules.Type = pair.Key then
        begin
          var craft := Base.Crafts[i];
          Base.RemoveCraft(craft, True);
          craft.Free;
          Break;
        end;
    end;
  end;
end;

function TProduction.Step(Base: TBase; Game: TSavedGame; Mod: TMod): TProductionProgress;
var
  done, produced, count: Integer;
begin
  done := AmountProduced;
  FTimeSpent := FTimeSpent + FEngineers;
  if done < AmountProduced then
  begin
    if not Infinite then
      produced := Min(AmountProduced, FAmountTotal) - done
    else
      produced := AmountProduced - done;
    count := 0;
    repeat
      for var pair in FRules.ProducedItems do
      begin
        if FRules.Category = 'STR_CRAFT' then
        begin
          var craft := TCraft.Create(Mod.GetCraft(pair.Key), Base, Game.GetId(pair.Key));
          craft.Status := 'STR_REFUELLING';
          Base.Crafts.Add(craft);
          Break;
        end
        else
        begin
          if Mod.GetItem(pair.Key).BattleType = BT_NONE then
            for var c in Base.Crafts do
              c.ReuseItem(pair.Key);
          if FSell then
            Game.Funds := Game.Funds + Mod.GetItem(pair.Key).SellCost * pair.Value
          else
            Base.StorageItems.AddItem(pair.Key, pair.Value);
        end;
      end;
      Inc(count);
      if count < produced then
      begin
        if not HaveEnoughMoneyForOneMoreUnit(Game) then Exit(PROGRESS_NOT_ENOUGH_MONEY);
        if not HaveEnoughMaterialsForOneMoreUnit(Base, Mod) then Exit(PROGRESS_NOT_ENOUGH_MATERIALS);
        StartItem(Base, Game, Mod);
      end;
    until count >= produced;
  end;
  if (AmountProduced >= FAmountTotal) and not Infinite then Exit(PROGRESS_COMPLETE);
  if done < AmountProduced then
  begin
    if not HaveEnoughMoneyForOneMoreUnit(Game) then Exit(PROGRESS_NOT_ENOUGH_MONEY);
    if not HaveEnoughMaterialsForOneMoreUnit(Base, Mod) then Exit(PROGRESS_NOT_ENOUGH_MATERIALS);
    StartItem(Base, Game, Mod);
  end;
  Result := PROGRESS_NOT_COMPLETE;
end;

function TProduction.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['item'] := FRules.Name;
  Result['assigned'] := FEngineers;
  Result['spent'] := FTimeSpent;
  Result['amount'] := FAmountTotal;
  Result['infinite'] := FInfinite;
  if FSell then Result['sell'] := FSell;
end;

procedure TProduction.Load(const Node: TYamlNode);
begin
  FEngineers := Node['assigned'].AsInteger(FEngineers);
  FTimeSpent := Node['spent'].AsInteger(FTimeSpent);
  FAmountTotal := Node['amount'].AsInteger(FAmountTotal);
  FInfinite := Node['infinite'].AsBoolean(FInfinite);
  FSell := Node['sell'].AsBoolean(FSell);
  if FAmountTotal = MaxInt then
  begin
    FAmountTotal := 999;
    FInfinite := True;
    FSell := True;
  end;
end;

end.