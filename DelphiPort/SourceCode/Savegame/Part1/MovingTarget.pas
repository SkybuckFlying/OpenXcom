unit MovingTarget;

interface

uses
  Target, YAML, Options;

type
  TMovingTarget = class(TTarget)
  private
    FDest: TTarget;
    FSpeedLon: Double;
    FSpeedLat: Double;
    FSpeedRadian: Double;
    FMeetPointLon: Double;
    FMeetPointLat: Double;
    FSpeed: Integer;
    FMeetCalculated: Boolean;
  protected
    procedure CalculateSpeed; virtual;
    class function CalculateRadianSpeed(Speed: Integer): Double;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode); override;
    function Save: TYamlNode; override;
    property Destination: TTarget read FDest write SetDestination;
    property Speed: Integer read FSpeed write SetSpeed;
    property SpeedRadian: Double read FSpeedRadian;
    function ReachedDestination: Boolean;
    procedure Move;
    procedure CalculateMeetPoint;
    property MeetLatitude: Double read FMeetPointLat;
    property MeetLongitude: Double read FMeetPointLon;
    procedure ResetMeetPoint;
    function IsMeetCalculated: Boolean;
    procedure SetDestination(Dest: TTarget); virtual;
    procedure SetSpeed(Speed: Integer);
  end;

implementation

uses
  Math, SerializationHelper;

constructor TMovingTarget.Create;
begin
  inherited;
  FDest := nil;
  FSpeedLon := 0.0;
  FSpeedLat := 0.0;
  FSpeedRadian := 0.0;
  FMeetPointLon := 0.0;
  FMeetPointLat := 0.0;
  FSpeed := 0;
  FMeetCalculated := False;
end;

destructor TMovingTarget.Destroy;
begin
  SetDestination(nil);
  inherited;
end;

procedure TMovingTarget.Load(const Node: TYamlNode);
begin
  inherited;
  FSpeedLon := Node['speedLon'].AsDouble(FSpeedLon);
  FSpeedLat := Node['speedLat'].AsDouble(FSpeedLat);
  FSpeedRadian := Node['speedRadian'].AsDouble(FSpeedRadian);
  FSpeed := Node['speed'].AsInteger(FSpeed);
end;

function TMovingTarget.Save: TYamlNode;
begin
  Result := inherited Save;
  if FDest <> nil then
    Result['dest'] := FDest.SaveId;
  Result['speedLon'] := SerializeDouble(FSpeedLon);
  Result['speedLat'] := SerializeDouble(FSpeedLat);
  Result['speedRadian'] := SerializeDouble(FSpeedRadian);
  Result['speed'] := FSpeed;
end;

class function TMovingTarget.CalculateRadianSpeed(Speed: Integer): Double;
begin
  Result := (Speed / 60.0) / 720.0;
end;

procedure TMovingTarget.SetDestination(Dest: TTarget);
var
  i: Integer;
begin
  FMeetCalculated := False;
  if FDest <> nil then
  begin
    for i := FDest.GetFollowers.Count - 1 downto 0 do
      if FDest.GetFollowers[i] = Self then
      begin
        FDest.GetFollowers.Delete(i);
        Break;
      end;
  end;
  FDest := Dest;
  if FDest <> nil then
    FDest.GetFollowers.Add(Self);
  for i := 0 to GetFollowers.Count - 1 do
    GetFollowers[i].ResetMeetPoint;
  CalculateSpeed;
end;

procedure TMovingTarget.SetSpeed(Speed: Integer);
var
  i: Integer;
begin
  FSpeed := Speed;
  FSpeedRadian := CalculateRadianSpeed(FSpeed);
  for i := 0 to GetFollowers.Count - 1 do
    GetFollowers[i].ResetMeetPoint;
  CalculateSpeed;
end;

procedure TMovingTarget.CalculateSpeed;
var
  dLon, dLat, length: Double;
begin
  CalculateMeetPoint;
  if FDest <> nil then
  begin
    dLon := Sin(FMeetPointLon - FLon) * Cos(FMeetPointLat);
    dLat := Cos(FLat) * Sin(FMeetPointLat) - Sin(FLat) * Cos(FMeetPointLat) * Cos(FMeetPointLon - FLon);
    length := Sqrt(dLon * dLon + dLat * dLat);
    if length <> 0 then
    begin
      FSpeedLat := dLat / length * FSpeedRadian;
      FSpeedLon := dLon / length * FSpeedRadian / Cos(FLat + FSpeedLat);
    end
    else
    begin
      FSpeedLon := 0;
      FSpeedLat := 0;
    end;
  end
  else
  begin
    FSpeedLon := 0;
    FSpeedLat := 0;
  end;
end;

function TMovingTarget.ReachedDestination: Boolean;
begin
  Result := (FDest <> nil) and (Abs(FDest.Longitude - FLon) < 1e-12) and (Abs(FDest.Latitude - FLat) < 1e-12);
end;

procedure TMovingTarget.Move;
begin
  CalculateSpeed;
  if FDest <> nil then
  begin
    if GetDistance(FMeetPointLon, FMeetPointLat) > FSpeedRadian then
    begin
      SetLongitude(FLon + FSpeedLon);
      SetLatitude(FLat + FSpeedLat);
    end
    else
    begin
      if GetDistance(FDest) > FSpeedRadian then
      begin
        SetLongitude(FMeetPointLon);
        SetLatitude(FMeetPointLat);
      end
      else
      begin
        SetLongitude(FDest.Longitude);
        SetLatitude(FDest.Latitude);
      end;
      ResetMeetPoint;
    end;
  end;
end;

procedure TMovingTarget.CalculateMeetPoint;
var
  speedRatio, nx, ny, nz, nk, path, distance: Double;
begin
  if not Options.MeetingPoint then FMeetCalculated := False;
  if FMeetCalculated then Exit;
  if FDest <> nil then
  begin
    FMeetPointLat := FDest.Latitude;
    FMeetPointLon := FDest.Longitude;
  end
  else
  begin
    FMeetPointLat := FLat;
    FMeetPointLon := FLon;
  end;
  if (FDest = nil) or (not Options.MeetingPoint) or ReachedDestination then Exit;
  if not (FDest is TMovingTarget) then Exit;
  if Abs((FDest as TMovingTarget).SpeedRadian) < 1e-12 then Exit;
  speedRatio := FSpeedRadian / (FDest as TMovingTarget).SpeedRadian;
  nx := Cos((FDest as TMovingTarget).Latitude) * Sin((FDest as TMovingTarget).Longitude) * Sin((FDest as TMovingTarget).Destination.Latitude)
        - Sin((FDest as TMovingTarget).Latitude) * Cos((FDest as TMovingTarget).Destination.Latitude) * Sin((FDest as TMovingTarget).Destination.Longitude);
  ny := Sin((FDest as TMovingTarget).Latitude) * Cos((FDest as TMovingTarget).Destination.Latitude) * Cos((FDest as TMovingTarget).Destination.Longitude)
        - Cos((FDest as TMovingTarget).Latitude) * Cos((FDest as TMovingTarget).Longitude) * Sin((FDest as TMovingTarget).Destination.Latitude);
  nz := Cos((FDest as TMovingTarget).Latitude) * Cos((FDest as TMovingTarget).Destination.Latitude) * Sin((FDest as TMovingTarget).Destination.Longitude - (FDest as TMovingTarget).Longitude);
  nk := FSpeedRadian / Sqrt(nx*nx + ny*ny + nz*nz);
  nx := nx * nk;
  ny := ny * nk;
  nz := nz * nk;

  path := 0;
  while path < Pi do
  begin
    distance := ArcCos(Cos(FLat) * Cos(FMeetPointLat) * Cos(FMeetPointLon - FLon) + Sin(FLat) * Sin(FMeetPointLat));
    if distance - path * speedRatio <= 0 then Break;
    if path * speedRatio >= 1 then Break;
    FMeetPointLat := FMeetPointLat + nx * Sin(FMeetPointLon) - ny * Cos(FMeetPointLon);
    if Abs(FMeetPointLat) < Pi/2 then
      FMeetPointLon := FMeetPointLon + nz - (nx * Cos(FMeetPointLon) + ny * Sin(FMeetPointLon)) * Tan(FMeetPointLat)
    else
      FMeetPointLon := FMeetPointLon + Pi;
    path := path + FSpeedRadian;
  end;
  while Abs(FMeetPointLon) > Pi do
    if FMeetPointLon > 0 then FMeetPointLon := FMeetPointLon - 2*Pi else FMeetPointLon := FMeetPointLon + 2*Pi;
  while Abs(FMeetPointLat) > Pi do
    if FMeetPointLat > 0 then FMeetPointLat := FMeetPointLat - 2*Pi else FMeetPointLat := FMeetPointLat + 2*Pi;
  if Abs(FMeetPointLat) > Pi/2 then
  begin
    FMeetPointLat := Sign(FMeetPointLat) * Abs(2*Pi - Abs(FMeetPointLat));
    FMeetPointLon := FMeetPointLon - Sign(FMeetPointLon) * Pi;
  end;
  FMeetCalculated := True;
end;

procedure TMovingTarget.ResetMeetPoint;
begin
  FMeetCalculated := False;
end;

function TMovingTarget.IsMeetCalculated: Boolean;
begin
  Result := FMeetCalculated;
end;

end.