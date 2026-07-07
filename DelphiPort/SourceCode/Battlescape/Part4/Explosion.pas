unit Explosion;

interface

uses
  Position;

type
  TExplosion = class
  private
    FPosition: TPosition;
    FCurrentFrame: Integer;
    FStartFrame: Integer;
    FFrameDelay: Integer;
    FBig: Boolean;
    FHit: Boolean;
  public
    const HIT_FRAMES = 4;
    const EXPLODE_FRAMES = 8;
    const BULLET_FRAMES = 10;
    constructor Create(APosition: TPosition; AStartFrame: Integer; AFrameDelay: Integer = 0; ABig: Boolean = False; AHit: Boolean = False);
    destructor Destroy; override;
    function Animate: Boolean;
    function GetPosition: TPosition;
    function GetCurrentFrame: Integer;
    function IsBig: Boolean;
    function IsHit: Boolean;
  end;

implementation

constructor TExplosion.Create(APosition: TPosition; AStartFrame: Integer; AFrameDelay: Integer; ABig: Boolean; AHit: Boolean);
begin
  inherited Create;
  FPosition := APosition;
  FStartFrame := AStartFrame;
  FCurrentFrame := AStartFrame;
  FFrameDelay := AFrameDelay;
  FBig := ABig;
  FHit := AHit;
end;

destructor TExplosion.Destroy;
begin
  inherited;
end;

function TExplosion.Animate: Boolean;
begin
  if FFrameDelay > 0 then
  begin
    Dec(FFrameDelay);
    Exit(True);
  end;
  Inc(FCurrentFrame);
  if (FHit and (FCurrentFrame = FStartFrame + HIT_FRAMES)) or
     (FBig and (FCurrentFrame = FStartFrame + EXPLODE_FRAMES)) or
     ((not FBig) and (not FHit) and (FCurrentFrame = FStartFrame + BULLET_FRAMES)) then
    Result := False
  else
    Result := True;
end;

function TExplosion.GetPosition: TPosition;
begin
  Result := FPosition;
end;

function TExplosion.GetCurrentFrame: Integer;
begin
  if FFrameDelay > 0 then
    Result := -1
  else
    Result := FCurrentFrame;
end;

function TExplosion.IsBig: Boolean;
begin
  Result := FBig;
end;

function TExplosion.IsHit: Boolean;
begin
  Result := FHit;
end;

end.