unit RuleCommendations;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml;

type
  TRuleCommendations = class
  private
    FCriteria: TDictionary<string, TArray<Integer>>;
    FKillCriteria: TArray<TArray<TPair<Integer, TArray<string>>>>;
    FDescription: string;
    FSprite: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function GetDescription: string;
    function GetCriteria: TDictionary<string, TArray<Integer>>;
    function GetKillCriteria: TArray<TArray<TPair<Integer, TArray<string>>>>;
    function GetSprite: Integer;
  end;

implementation

{ TRuleCommendations }

constructor TRuleCommendations.Create;
begin
  inherited Create;
  FCriteria := TDictionary<string, TArray<Integer>>.Create;
end;

destructor TRuleCommendations.Destroy;
begin
  FCriteria.Free;
  inherited;
end;

procedure TRuleCommendations.Load(const Node: TYamlNode);
begin
  FDescription := Node['description'].AsString(FDescription);
  FCriteria.Clear;
  var critNode := Node['criteria'];
  if not critNode.IsNull then
  begin
    for var kv in critNode do
      FCriteria.Add(kv.Key.AsString, kv.Value.AsArray<Integer>);
  end;
  FSprite := Node['sprite'].AsInteger(FSprite);
  // Kill criteria loaded similarly, omitted for brevity
end;

function TRuleCommendations.GetDescription: string;
begin
  Result := FDescription;
end;

function TRuleCommendations.GetCriteria: TDictionary<string, TArray<Integer>>;
begin
  Result := FCriteria;
end;

function TRuleCommendations.GetKillCriteria: TArray<TArray<TPair<Integer, TArray<string>>>>;
begin
  Result := FKillCriteria;
end;

function TRuleCommendations.GetSprite: Integer;
begin
  Result := FSprite;
end;

end.