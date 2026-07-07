unit AlienBase;

interface

uses
  Classes, SysUtils, YAML, Target, AlienDeployment;

type
  TAlienBase = class(TTarget)
  private
    FRace: string;
    FInBattlescape: Boolean;
    FDiscovered: Boolean;
    FDeployment: TAlienDeployment;
  public
    constructor Create(Deployment: TAlienDeployment);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function Save: TYamlNode;
    function GetType: string; override;
    property AlienRace: string read FRace write FRace;
    property InBattlescape: Boolean read FInBattlescape write FInBattlescape;
    property Discovered: Boolean read FDiscovered write FDiscovered;
    property Deployment: TAlienDeployment read FDeployment;
    function GetMarker: Integer; override;
  end;

implementation

constructor TAlienBase.Create(Deployment: TAlienDeployment);
begin
  inherited Create;
  FDeployment := Deployment;
  FInBattlescape := False;
  FDiscovered := False;
end;

destructor TAlienBase.Destroy;
begin
  inherited;
end;

procedure TAlienBase.Load(const Node: TYamlNode);
begin
  inherited Load(Node);
  FRace := Node['race'].AsString(FRace);
  FInBattlescape := Node['inBattlescape'].AsBoolean(FInBattlescape);
  FDiscovered := Node['discovered'].AsBoolean(FDiscovered);
end;

function TAlienBase.Save: TYamlNode;
begin
  Result := inherited Save;
  Result['race'] := FRace;
  if FInBattlescape then Result['inBattlescape'] := FInBattlescape;
  if FDiscovered then Result['discovered'] := FDiscovered;
  Result['deployment'] := FDeployment.Type;
end;

function TAlienBase.GetType: string;
begin
  Result := FDeployment.MarkerName;
end;

function TAlienBase.GetMarker: Integer;
begin
  if not FDiscovered then Exit(-1);
  Result := FDeployment.MarkerIcon;
end;

end.