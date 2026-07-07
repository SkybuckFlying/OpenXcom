unit Target;

interface

uses
  Classes, SysUtils, Generics.Collections, YAML;

type
  TTarget = class
  private
    FLon: Double;
    FLat: Double;
    FId: Integer;
    FName: string;
    FFollowers: TList<TMovingTarget>;
  protected
    function GetType: string; virtual; abstract;
    function GetMarkerName: string; virtual;
    function GetMarkerId: Integer; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode); virtual;
    function Save: TYamlNode; virtual;
    function SaveId: TYamlNode;
    property Longitude: Double read FLon write SetLongitude;
    property Latitude: Double read FLat write SetLatitude;
    property Id: Integer read FId write FId;
    property Name: string read FName write FName;
    function GetName(Lang: TLanguage): string; virtual;
    function GetDefaultName(Lang: TLanguage): string; virtual;
    function GetMarker: Integer; virtual; abstract;
    function GetFollowers: TList<TMovingTarget>;
    function GetCraftFollowers: TArray<TCraft>;
    function GetDistance(ATarget: TTarget): Double; overload;
    function GetDistance(Lon, Lat: Double): Double; overload;
    procedure SetLongitude(Lon: Double);
    procedure SetLatitude(Lat: Double);
  end;

  TMovingTarget = class; // forward

implementation

uses
  Math, MovingTarget, Craft;

constructor TTarget.Create;
begin
  FLon := 0.0;
  FLat := 0.0;
  FId := 0;
  FFollowers := TList<TMovingTarget>.Create;
end;

destructor TTarget.Destroy;
begin
  FFollowers.Free;
  inherited;
end;

procedure TTarget.Load(const Node: TYamlNode);
begin
  FLon := Node['lon'].AsDouble(FLon);
  FLat := Node['lat'].AsDouble(FLat);
  FId := Node['id'].AsInteger(FId);
  if Node['name'] <> nil then
    FName := Node['name'].AsString;
end;

function TTarget.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['lon'] := SerializeDouble(FLon);
  Result['lat'] := SerializeDouble(FLat);
  if FId <> 0 then Result['id'] := FId;
  if FName <> '' then Result['name'] := FName;
end;

function TTarget.SaveId: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['lon'] := SerializeDouble(FLon);
  Result['lat'] := SerializeDouble(FLat);
  Result['type'] := GetType;
  Result['id'] := FId;
end;

function TTarget.GetName(Lang: TLanguage): string;
begin
  if FName = '' then
    Result := GetDefaultName(Lang)
  else
    Result := FName;
end;

function TTarget.GetDefaultName(Lang: TLanguage): string;
begin
  Result := Lang.GetString(GetMarkerName) + IntToStr(FId);
end;

function TTarget.GetMarkerName: string;
begin
  Result := GetType + '_';
end;

function TTarget.GetMarkerId: Integer;
begin
  Result := FId;
end;

procedure TTarget.SetLongitude(Lon: Double);
begin
  FLon := Lon;
  while FLon < 0 do FLon := FLon + 2 * Pi;
  while FLon >= 2 * Pi do FLon := FLon - 2 * Pi;
end;

procedure TTarget.SetLatitude(Lat: Double);
begin
  FLat := Lat;
  if FLat < -Pi/2 then
  begin
    FLat := -Pi - FLat;
    SetLongitude(FLon + Pi);
  end
  else if FLat > Pi/2 then
  begin
    FLat := Pi - FLat;
    SetLongitude(FLon - Pi);
  end;
end;

function TTarget.GetFollowers: TList<TMovingTarget>;
begin
  Result := FFollowers;
end;

function TTarget.GetDistance(ATarget: TTarget): Double;
begin
  Result := GetDistance(ATarget.Longitude, ATarget.Latitude);
end;

function TTarget.GetDistance(Lon, Lat: Double): Double;
begin
  if (Abs(Lon - FLon) < 1e-12) and (Abs(Lat - FLat) < 1e-12) then
    Exit(0.0);
  Result := ArcCos(Cos(FLat) * Cos(Lat) * Cos(Lon - FLon) + Sin(FLat) * Sin(Lat));
end;

function TTarget.GetCraftFollowers: TArray<TCraft>;
var
  mt: TMovingTarget;
  craft: TCraft;
begin
  Result := [];
  for mt in FFollowers do
    if mt is TCraft then
    begin
      craft := TCraft(mt);
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := craft;
    end;
end;

end.