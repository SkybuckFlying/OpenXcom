unit RuleInterface;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml;

type
  TElement = record
    X, Y, W, H: Integer;
    Color, Color2, Border: Integer;
    TFTDMode: Boolean;
  end;

  TRuleInterface = class
  private
    FType: string;
    FPalette: string;
    FParent: string;
    FMusic: string;
    FElements: TDictionary<string, TElement>;
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function GetElement(const Id: string): PElement;
    function GetPalette: string;
    function GetParent: string;
    function GetMusic: string;
  end;

implementation

{ TRuleInterface }

constructor TRuleInterface.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FElements := TDictionary<string, TElement>.Create;
end;

destructor TRuleInterface.Destroy;
begin
  FElements.Free;
  inherited;
end;

procedure TRuleInterface.Load(const Node: TYamlNode);
begin
  FPalette := Node['palette'].AsString(FPalette);
  FParent := Node['parent'].AsString(FParent);
  FMusic := Node['music'].AsString(FMusic);
  var elemNode := Node['elements'];
  if not elemNode.IsNull then
  begin
    FElements.Clear;
    for var kv in elemNode do
    begin
      var el: TElement;
      var size := kv.Value['size'];
      if not size.IsNull then
      begin
        el.W := size[0].AsInteger;
        el.H := size[1].AsInteger;
      end
      else
      begin
        el.W := MaxInt;
        el.H := MaxInt;
      end;
      var pos := kv.Value['pos'];
      if not pos.IsNull then
      begin
        el.X := pos[0].AsInteger;
        el.Y := pos[1].AsInteger;
      end
      else
      begin
        el.X := MaxInt;
        el.Y := MaxInt;
      end;
      el.Color := kv.Value['color'].AsInteger(MaxInt);
      el.Color2 := kv.Value['color2'].AsInteger(MaxInt);
      el.Border := kv.Value['border'].AsInteger(MaxInt);
      el.TFTDMode := kv.Value['TFTDMode'].AsBoolean(False);
      FElements.Add(kv.Key.AsString, el);
    end;
  end;
end;

function TRuleInterface.GetElement(const Id: string): PElement;
var
  el: TElement;
begin
  if FElements.TryGetValue(Id, el) then
    Result := @el
  else
    Result := nil;
end;

function TRuleInterface.GetPalette: string;
begin
  Result := FPalette;
end;

function TRuleInterface.GetParent: string;
begin
  Result := FParent;
end;

function TRuleInterface.GetMusic: string;
begin
  Result := FMusic;
end;

end.