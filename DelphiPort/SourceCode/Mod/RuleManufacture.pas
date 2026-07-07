unit RuleManufacture;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml;

type
  TRuleManufacture = class
  private
    FName: string;
    FCategory: string;
    FRequires: TArray<string>;
    FSpace: Integer;
    FTime: Integer;
    FCost: Integer;
    FRequiredItems: TDictionary<string, Integer>;
    FProducedItems: TDictionary<string, Integer>;
    FListOrder: Integer;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode; AListOrder: Integer);
    function GetName: string;
    function GetCategory: string;
    function GetRequirements: TArray<string>;
    function GetRequiredSpace: Integer;
    function GetManufactureTime: Integer;
    function GetManufactureCost: Integer;
    function HaveEnoughMoneyForOneMoreUnit(Funds: Int64): Boolean;
    function GetRequiredItems: TDictionary<string, Integer>;
    function GetProducedItems: TDictionary<string, Integer>;
    function GetListOrder: Integer;
  end;

implementation

{ TRuleManufacture }

constructor TRuleManufacture.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FSpace := 0; FTime := 0; FCost := 0;
  FRequiredItems := TDictionary<string, Integer>.Create;
  FProducedItems := TDictionary<string, Integer>.Create;
  FProducedItems.Add(AName, 1);
  FListOrder := 0;
end;

destructor TRuleManufacture.Destroy;
begin
  FRequiredItems.Free;
  FProducedItems.Free;
  inherited;
end;

procedure TRuleManufacture.Load(const Node: TYamlNode; AListOrder: Integer);
begin
  FName := Node['name'].AsString(FName);
  FCategory := Node['category'].AsString(FCategory);
  FRequires := Node['requires'].AsArray<string>(FRequires);
  FSpace := Node['space'].AsInteger(FSpace);
  FTime := Node['time'].AsInteger(FTime);
  FCost := Node['cost'].AsInteger(FCost);
  FRequiredItems.Clear;
  var reqNode := Node['requiredItems'];
  if not reqNode.IsNull then
    for var kv in reqNode do
      FRequiredItems.Add(kv.Key.AsString, kv.Value.AsInteger);
  FProducedItems.Clear;
  var prodNode := Node['producedItems'];
  if not prodNode.IsNull then
    for var kv in prodNode do
      FProducedItems.Add(kv.Key.AsString, kv.Value.AsInteger);
  FListOrder := Node['listOrder'].AsInteger(FListOrder);
  if FListOrder = 0 then FListOrder := AListOrder;
end;

function TRuleManufacture.GetName: string;
begin
  Result := FName;
end;

function TRuleManufacture.GetCategory: string;
begin
  Result := FCategory;
end;

function TRuleManufacture.GetRequirements: TArray<string>;
begin
  Result := FRequires;
end;

function TRuleManufacture.GetRequiredSpace: Integer;
begin
  Result := FSpace;
end;

function TRuleManufacture.GetManufactureTime: Integer;
begin
  Result := FTime;
end;

function TRuleManufacture.GetManufactureCost: Integer;
begin
  Result := FCost;
end;

function TRuleManufacture.HaveEnoughMoneyForOneMoreUnit(Funds: Int64): Boolean;
begin
  Result := (Funds >= FCost) or (FCost <= 0);
end;

function TRuleManufacture.GetRequiredItems: TDictionary<string, Integer>;
begin
  Result := FRequiredItems;
end;

function TRuleManufacture.GetProducedItems: TDictionary<string, Integer>;
begin
  Result := FProducedItems;
end;

function TRuleManufacture.GetListOrder: Integer;
begin
  Result := FListOrder;
end;

end.