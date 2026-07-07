unit RuleInventory;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, RuleItem;

type
  TRuleSlot = record
    X, Y: Integer;
  end;

  TInventoryType = (invSlot, invHand, invGround);

  TRuleInventory = class
  public const
    SLOT_W = 16;
    SLOT_H = 16;
    HAND_W = 2;
    HAND_H = 3;
  private
    FId: string;
    FX, FY: Integer;
    FType: TInventoryType;
    FSlots: TArray<TRuleSlot>;
    FCosts: TDictionary<string, Integer>;
    FListOrder: Integer;
  public
    constructor Create(const AId: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode; AListOrder: Integer);
    function GetId: string;
    function GetX: Integer;
    function GetY: Integer;
    function GetType: TInventoryType;
    function GetSlots: TArray<TRuleSlot>;
    function CheckSlotInPosition(var X, Y: Integer): Boolean;
    function FitItemInSlot(Item: TRuleItem; X, Y: Integer): Boolean;
    function GetCost(Slot: TRuleInventory): Integer;
    function GetListOrder: Integer;
  end;

implementation

{ TRuleInventory }

constructor TRuleInventory.Create(const AId: string);
begin
  inherited Create;
  FId := AId;
  FX := 0; FY := 0;
  FType := invSlot;
  FListOrder := 0;
  FCosts := TDictionary<string, Integer>.Create;
end;

destructor TRuleInventory.Destroy;
begin
  FCosts.Free;
  inherited;
end;

procedure TRuleInventory.Load(const Node: TYamlNode; AListOrder: Integer);
begin
  FId := Node['id'].AsString(FId);
  FX := Node['x'].AsInteger(FX);
  FY := Node['y'].AsInteger(FY);
  FType := TInventoryType(Node['type'].AsInteger(Integer(FType)));
  FSlots := Node['slots'].AsArray<TRuleSlot>(FSlots);
  FCosts.Clear;
  var costNode := Node['costs'];
  if not costNode.IsNull then
    for var kv in costNode do
      FCosts.Add(kv.Key.AsString, kv.Value.AsInteger);
  FListOrder := Node['listOrder'].AsInteger(AListOrder);
end;

function TRuleInventory.GetId: string;
begin
  Result := FId;
end;

function TRuleInventory.GetX: Integer;
begin
  Result := FX;
end;

function TRuleInventory.GetY: Integer;
begin
  Result := FY;
end;

function TRuleInventory.GetType: TInventoryType;
begin
  Result := FType;
end;

function TRuleInventory.GetSlots: TArray<TRuleSlot>;
begin
  Result := FSlots;
end;

function TRuleInventory.CheckSlotInPosition(var X, Y: Integer): Boolean;
begin
  // Implementation similar to C++ version
  Result := False;
end;

function TRuleInventory.FitItemInSlot(Item: TRuleItem; X, Y: Integer): Boolean;
begin
  // Implementation similar to C++ version
  Result := False;
end;

function TRuleInventory.GetCost(Slot: TRuleInventory): Integer;
begin
  if FCosts.TryGetValue(Slot.GetId, Result) then
    Exit;
  Result := 0;
end;

function TRuleInventory.GetListOrder: Integer;
begin
  Result := FListOrder;
end;

end.