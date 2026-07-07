unit Particle;

interface

uses
  SDL2;

type
  TParticle = class
  private
    FXOffset, FYOffset, FDensity: Single;
    FColor: Byte;
    FOpacity: Byte;
    FSize: Byte;
  public
    constructor Create(XOffset, YOffset, Density: Single; Color, Opacity: Byte);
    destructor Destroy; override;
    function Animate: Boolean;
    property Size: Byte read FSize;
    property Color: Byte read FColor;
    property Opacity: Byte read GetOpacity;
    property X: Single read FXOffset;
    property Y: Single read FYOffset;
  end;

implementation

uses
  Engine.RNG,
  Math;

{ TParticle }

constructor TParticle.Create(XOffset, YOffset, Density: Single; Color, Opacity: Byte);
begin
  FXOffset := XOffset;
  FYOffset := YOffset;
  FDensity := Density;
  FColor := Color;
  FOpacity := Opacity;
  FSize := 0;
  if Density < 100 then FSize := 3
  else if Density < 125 then FSize := 2
  else if Density < 150 then FSize := 1;
end;

destructor TParticle.Destroy;
begin
  inherited;
end;

function TParticle.Animate: Boolean;
begin
  FYOffset := FYOffset - ((320 - FDensity) / 256.0);
  Dec(FOpacity);
  FXOffset := FXOffset + (RNG.Seedless(0, 1) * 2 - 1) * (0.25 + RNG.Seedless(0, 9) / 30.0);
  Result := FOpacity > 0;
end;

function TParticle.GetOpacity: Byte;
begin
  Result := Min((FOpacity + 7) div 10, 3);
end;

end.