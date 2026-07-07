unit Vehicle;

interface

uses
  Classes, SysUtils, YAML, RuleItem;

type
  TVehicle = class
  private
    FRules: TRuleItem;
    FAmmo: Integer;
    FSize: Integer;
  public
    constructor Create(Rules: TRuleItem; Ammo, Size: Integer);
    procedure Load(const Node: TYamlNode);
    function Save: TYamlNode;
    property Rules: TRuleItem read FRules;
    property Ammo: Integer read FAmmo write FAmmo;
    property Size: Integer read FSize;
  end;

implementation

constructor TVehicle.Create(Rules: TRuleItem; Ammo, Size: Integer);
begin
  FRules := Rules;
  FAmmo := Ammo;
  FSize := Size;
end;

procedure TVehicle.Load(const Node: TYamlNode);
begin
  FAmmo := Node['ammo'].AsInteger(FAmmo);
  FSize := Node['size'].AsInteger(FSize);
end;

function TVehicle.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['type'] := FRules.Type;
  Result['ammo'] := FAmmo;
  Result['size'] := FSize;
end;

end.