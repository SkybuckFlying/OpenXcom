unit RuleMusic;

interface

uses
  System.Classes, System.SysUtils,
  Yaml;

type
  TRuleMusic = class
  private
    FType: string;
    FName: string;
    FCatPos: Integer;
    FNormalization: Single;
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function GetName: string;
    function GetCatPos: Integer;
    function GetNormalization: Single;
  end;

implementation

{ TRuleMusic }

constructor TRuleMusic.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FCatPos := MaxInt;
  FNormalization := 0.76;
end;

destructor TRuleMusic.Destroy;
begin
  inherited;
end;

procedure TRuleMusic.Load(const Node: TYamlNode);
begin
  FName := Node['name'].AsString(FName);
  FCatPos := Node['catPos'].AsInteger(FCatPos);
  FNormalization := Node['normalization'].AsFloat(FNormalization);
end;

function TRuleMusic.GetName: string;
begin
  if FName.IsEmpty then
    Result := FType
  else
    Result := FName;
end;

function TRuleMusic.GetCatPos: Integer;
begin
  Result := FCatPos;
end;

function TRuleMusic.GetNormalization: Single;
begin
  Result := FNormalization;
end;

end.