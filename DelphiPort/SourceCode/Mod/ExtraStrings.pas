unit ExtraStrings;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml;

type
  TExtraStrings = class
  private
    FStrings: TDictionary<string, string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function GetStrings: TDictionary<string, string>;
  end;

implementation

{ TExtraStrings }

constructor TExtraStrings.Create;
begin
  inherited Create;
  FStrings := TDictionary<string, string>.Create;
end;

destructor TExtraStrings.Destroy;
begin
  FStrings.Free;
  inherited;
end;

procedure TExtraStrings.Load(const Node: TYamlNode);
var
  stringsNode: TYamlNode;
begin
  stringsNode := Node['strings'];
  if stringsNode.IsNull then Exit;
  for var kv in stringsNode do
  begin
    if kv.Value.IsScalar then
      FStrings.Add(kv.Key.AsString, kv.Value.AsString)
    else if kv.Value.IsMap then
    begin
      for var subKv in kv.Value do
        FStrings.Add(kv.Key.AsString + '_' + subKv.Key.AsString, subKv.Value.AsString);
    end;
  end;
end;

function TExtraStrings.GetStrings: TDictionary<string, string>;
begin
  Result := FStrings;
end;

end.