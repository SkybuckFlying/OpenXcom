unit WeightedOptions;

interface

uses
  Classes, SysUtils, Generics.Collections, YAML, RNG;

type
  TWeightedOptions = class
  private
    FChoices: TDictionary<string, Integer>;
    FTotalWeight: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function Choose: string;
    procedure SetOption(const ID: string; Weight: Integer);
    function IsEmpty: Boolean;
    procedure Clear;
    procedure Load(const Node: TYamlNode);
    function Save: TYamlNode;
    function GetNames: TArray<string>;
  end;

implementation

constructor TWeightedOptions.Create;
begin
  FChoices := TDictionary<string, Integer>.Create;
  FTotalWeight := 0;
end;

destructor TWeightedOptions.Destroy;
begin
  FChoices.Free;
  inherited;
end;

function TWeightedOptions.Choose: string;
var
  r: Integer;
  pair: TPair<string, Integer>;
begin
  if FTotalWeight = 0 then
    Exit('');
  r := RNG.Generate(0, FTotalWeight);
  for pair in FChoices do
  begin
    if r <= pair.Value then
      Exit(pair.Key);
    Dec(r, pair.Value);
  end;
  Result := '';
end;

procedure TWeightedOptions.SetOption(const ID: string; Weight: Integer);
var
  old: Integer;
begin
  if FChoices.TryGetValue(ID, old) then
  begin
    Dec(FTotalWeight, old);
    if Weight = 0 then
      FChoices.Remove(ID)
    else
    begin
      FChoices[ID] := Weight;
      Inc(FTotalWeight, Weight);
    end;
  end
  else if Weight <> 0 then
  begin
    FChoices.Add(ID, Weight);
    Inc(FTotalWeight, Weight);
  end;
end;

function TWeightedOptions.IsEmpty: Boolean;
begin
  Result := FTotalWeight = 0;
end;

procedure TWeightedOptions.Clear;
begin
  FChoices.Clear;
  FTotalWeight := 0;
end;

procedure TWeightedOptions.Load(const Node: TYamlNode);
var
  pair: TPair<string, TYamlNode>;
begin
  for pair in Node do
    SetOption(pair.Key, pair.Value.AsInteger);
end;

function TWeightedOptions.Save: TYamlNode;
var
  pair: TPair<string, Integer>;
begin
  Result := TYamlNode.Create;
  for pair in FChoices do
    Result[pair.Key] := pair.Value;
end;

function TWeightedOptions.GetNames: TArray<string>;
begin
  Result := FChoices.Keys.ToArray;
end;

end.