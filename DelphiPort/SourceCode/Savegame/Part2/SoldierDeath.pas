unit SoldierDeath;

interface

uses
  Classes, SysUtils, YAML, GameTime, BattleUnitStatistics;

type
  TSoldierDeath = class
  private
    FTime: TGameTime;
    FCause: TBattleUnitKills;
  public
    constructor Create; overload;
    constructor Create(Time: TGameTime; Cause: TBattleUnitKills); overload;
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function Save: TYamlNode;
    property Time: TGameTime read FTime;
    property Cause: TBattleUnitKills read FCause;
  end;

implementation

constructor TSoldierDeath.Create;
begin
  FTime := TGameTime.Create(0,0,0,0,0,0,0);
  FCause := nil;
end;

constructor TSoldierDeath.Create(Time: TGameTime; Cause: TBattleUnitKills);
begin
  FTime := Time;
  FCause := Cause;
end;

destructor TSoldierDeath.Destroy;
begin
  FTime.Free;
  FCause.Free;
  inherited;
end;

procedure TSoldierDeath.Load(const Node: TYamlNode);
begin
  FTime.Load(Node['time']);
  if Node['cause'] <> nil then
  begin
    FCause := TBattleUnitKills.Create;
    FCause.Load(Node['cause']);
  end;
end;

function TSoldierDeath.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['time'] := FTime.Save;
  if FCause <> nil then
    Result['cause'] := FCause.Save;
end;

end.