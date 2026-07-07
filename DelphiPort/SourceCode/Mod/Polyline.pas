unit Polyline;

interface

uses
  System.Classes, System.SysUtils,
  Yaml, fmath;

type
  TPolyline = class
  private
    FLat, FLon: TArray<Double>;
    FPoints: Integer;
  public
    constructor Create(APoints: Integer);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function GetLatitude(Index: Integer): Double;
    procedure SetLatitude(Index: Integer; Lat: Double);
    function GetLongitude(Index: Integer): Double;
    procedure SetLongitude(Index: Integer; Lon: Double);
    function GetPoints: Integer;
  end;

implementation

{ TPolyline }

constructor TPolyline.Create(APoints: Integer);
begin
  inherited Create;
  FPoints := APoints;
  SetLength(FLat, APoints);
  SetLength(FLon, APoints);
end;

destructor TPolyline.Destroy;
begin
  inherited;
end;

procedure TPolyline.Load(const Node: TYamlNode);
var
  coords: TArray<Double>;
  i: Integer;
begin
  coords := Node.AsArray<Double>;
  FPoints := Length(coords) div 2;
  SetLength(FLat, FPoints);
  SetLength(FLon, FPoints);
  for i := 0 to FPoints-1 do
  begin
    FLon[i] := Deg2Rad(coords[i*2]);
    FLat[i] := Deg2Rad(coords[i*2+1]);
  end;
end;

function TPolyline.GetLatitude(Index: Integer): Double;
begin
  Result := FLat[Index];
end;

procedure TPolyline.SetLatitude(Index: Integer; Lat: Double);
begin
  FLat[Index] := Lat;
end;

function TPolyline.GetLongitude(Index: Integer): Double;
begin
  Result := FLon[Index];
end;

procedure TPolyline.SetLongitude(Index: Integer; Lon: Double);
begin
  FLon[Index] := Lon;
end;

function TPolyline.GetPoints: Integer;
begin
  Result := FPoints;
end;

end.