unit Polygon;

interface

uses
  System.Classes, System.SysUtils,
  Yaml, fmath;

type
  TPolygon = class
  private
    FLat, FLon: TArray<Double>;
    FX, FY: TArray<SmallInt>;
    FPoints: Integer;
    FTexture: Integer;
  public
    constructor Create(APoints: Integer);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function GetLatitude(Index: Integer): Double;
    procedure SetLatitude(Index: Integer; Lat: Double);
    function GetLongitude(Index: Integer): Double;
    procedure SetLongitude(Index: Integer; Lon: Double);
    function GetX(Index: Integer): SmallInt;
    procedure SetX(Index: Integer; X: SmallInt);
    function GetY(Index: Integer): SmallInt;
    procedure SetY(Index: Integer; Y: SmallInt);
    function GetTexture: Integer;
    procedure SetTexture(ATexture: Integer);
    function GetPoints: Integer;
  end;

implementation

{ TPolygon }

constructor TPolygon.Create(APoints: Integer);
begin
  inherited Create;
  FPoints := APoints;
  SetLength(FLat, APoints);
  SetLength(FLon, APoints);
  SetLength(FX, APoints);
  SetLength(FY, APoints);
  FTexture := 0;
end;

destructor TPolygon.Destroy;
begin
  inherited;
end;

procedure TPolygon.Load(const Node: TYamlNode);
var
  coords: TArray<Double>;
  i: Integer;
begin
  coords := Node.AsArray<Double>;
  FPoints := (Length(coords) - 1) div 2;
  SetLength(FLat, FPoints);
  SetLength(FLon, FPoints);
  SetLength(FX, FPoints);
  SetLength(FY, FPoints);
  FTexture := Trunc(coords[0]);
  for i := 0 to FPoints-1 do
  begin
    FLon[i] := Deg2Rad(coords[1 + i*2]);
    FLat[i] := Deg2Rad(coords[2 + i*2]);
    FX[i] := 0;
    FY[i] := 0;
  end;
end;

function TPolygon.GetLatitude(Index: Integer): Double;
begin
  Result := FLat[Index];
end;

procedure TPolygon.SetLatitude(Index: Integer; Lat: Double);
begin
  FLat[Index] := Lat;
end;

function TPolygon.GetLongitude(Index: Integer): Double;
begin
  Result := FLon[Index];
end;

procedure TPolygon.SetLongitude(Index: Integer; Lon: Double);
begin
  FLon[Index] := Lon;
end;

function TPolygon.GetX(Index: Integer): SmallInt;
begin
  Result := FX[Index];
end;

procedure TPolygon.SetX(Index: Integer; X: SmallInt);
begin
  FX[Index] := X;
end;

function TPolygon.GetY(Index: Integer): SmallInt;
begin
  Result := FY[Index];
end;

procedure TPolygon.SetY(Index: Integer; Y: SmallInt);
begin
  FY[Index] := Y;
end;

function TPolygon.GetTexture: Integer;
begin
  Result := FTexture;
end;

procedure TPolygon.SetTexture(ATexture: Integer);
begin
  FTexture := ATexture;
end;

function TPolygon.GetPoints: Integer;
begin
  Result := FPoints;
end;

end.