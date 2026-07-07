unit UfoTrajectory;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, Savegame.Ufo;

type
  TTrajectoryWaypoint = record
    Zone: Integer;
    Altitude: Integer;
    Speed: Integer;
  end;

  TUfoTrajectory = class
  public const
    RETALIATION_ASSAULT_RUN = '__RETALIATION_ASSAULT_RUN';
  private
    FId: string;
    FGroundTimer: Integer;
    FWaypoints: TArray<TTrajectoryWaypoint>;
  public
    constructor Create(const AId: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function GetID: string;
    function GetWaypointCount: Integer;
    function GetZone(Wp: Integer): Integer;
    function GetAltitude(Wp: Integer): string;
    function ApplySpeedPercentage(Wp, BaseSpeed: Integer): Integer;
    function GroundTimer: Integer;
  end;

implementation

{ TUfoTrajectory }

constructor TUfoTrajectory.Create(const AId: string);
begin
  inherited Create;
  FId := AId;
  FGroundTimer := 5;
end;

destructor TUfoTrajectory.Destroy;
begin
  inherited;
end;

procedure TUfoTrajectory.Load(const Node: TYamlNode);
begin
  FId := Node['id'].AsString(FId);
  FGroundTimer := Node['groundTimer'].AsInteger(FGroundTimer);
  FWaypoints := Node['waypoints'].AsArray<TTrajectoryWaypoint>(FWaypoints);
end;

function TUfoTrajectory.GetID: string;
begin
  Result := FId;
end;

function TUfoTrajectory.GetWaypointCount: Integer;
begin
  Result := Length(FWaypoints);
end;

function TUfoTrajectory.GetZone(Wp: Integer): Integer;
begin
  Result := FWaypoints[Wp].Zone;
end;

function TUfoTrajectory.GetAltitude(Wp: Integer): string;
begin
  Result := Ufo.ALTITUDE_STRING[FWaypoints[Wp].Altitude];
end;

function TUfoTrajectory.ApplySpeedPercentage(Wp, BaseSpeed: Integer): Integer;
begin
  Result := BaseSpeed * FWaypoints[Wp].Speed div 100;
end;

function TUfoTrajectory.GroundTimer: Integer;
begin
  Result := FGroundTimer;
end;

end.