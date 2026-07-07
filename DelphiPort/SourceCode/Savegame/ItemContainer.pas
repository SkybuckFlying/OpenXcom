unit ItemContainer;

interface

uses
  Classes, SysSysUtils, Generics.Collections, YAML, Mod;

type
  TItemContainer = class
  private
    FItems: TDictionary<string, Integer>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function Save: TYamlNode;
    procedure AddItem(const Id: string; Qty: Integer = 1);
    procedure RemoveItem(const Id: string; Qty: Integer = 1);
    function GetItem(const Id: string): Integer;
    function GetTotalQuantity: Integer;
    function GetTotalSize(Mod: TMod): Double;
    property Contents: TDictionary<string, Integer> read FItems;
  end;

implementation

constructor TItemContainer.Create;
begin
  FItems := TDictionary<string, Integer>.Create;
end;

destructor TItemContainer.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TItemContainer.Load(const Node: TYamlNode);
begin
  FItems.Clear;
  for var pair in Node do
    FItems.Add(pair.Key, pair.Value.AsInteger);
end;

function TItemContainer.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  for var pair in FItems do
    Result[pair.Key] := pair.Value;
end;

procedure TItemContainer.AddItem(const Id: string; Qty: Integer);
begin
  if Id = '' then Exit;
  var val := GetItem(Id);
  FItems.AddOrSet(Id, val + Qty);
end;

procedure TItemContainer.RemoveItem(const Id: string; Qty: Integer);
begin
  if (Id = '') or not FItems.ContainsKey(Id) then Exit;
  var val := FItems[Id];
  if Qty < val then
    FItems[Id] := val - Qty
  else
    FItems.Remove(Id);
end;

function TItemContainer.GetItem(const Id: string): Integer;
begin
  if Id = '' then Exit(0);
  if not FItems.TryGetValue(Id, Result) then Result := 0;
end;

function TItemContainer.GetTotalQuantity: Integer;
begin
  Result := 0;
  for var pair in FItems do
    Result := Result + pair.Value;
end;

function TItemContainer.GetTotalSize(Mod: TMod): Double;
begin
  Result := 0;
  for var pair in FItems do
    Result := Result + Mod.GetItem(pair.Key).Size * pair.Value;
end;

end.