unit UZoom;

interface

uses
  SDL, UOpenGL;

type
  TZoom = class
  public
    class procedure FlipWithZoom(Src, Dst: PSDL_Surface; TopBlackBand, BottomBlackBand, LeftBlackBand, RightBlackBand: Integer; GLOut: TOpenGL);
    class function ZoomSurfaceY(Src, Dst: PSDL_Surface; FlipX, FlipY: Integer): Integer;
    class function HaveSSE2: Boolean;
  end;

implementation

uses
  UOptions, UScreen, ULogger, SysUtils, Math;

class procedure TZoom.FlipWithZoom(Src, Dst: PSDL_Surface; TopBlackBand, BottomBlackBand, LeftBlackBand, RightBlackBand: Integer; GLOut: TOpenGL);
var
  DstWidth, DstHeight: Integer;
  Tmp: PSDL_Surface;
  R: TSDL_Rect;
begin
  DstWidth := Dst^.w - LeftBlackBand - RightBlackBand;
  DstHeight := Dst^.h - TopBlackBand - BottomBlackBand;
  if UScreen.UseOpenGL then
  begin
    // OpenGL path
    // Stub
  end
  else if (TopBlackBand = 0) and (BottomBlackBand = 0) and (LeftBlackBand = 0) and (RightBlackBand = 0) then
  begin
    ZoomSurfaceY(Src, Dst, 0, 0);
  end
  else if (DstWidth = Src^.w) and (DstHeight = Src^.h) then
  begin
    R.x := LeftBlackBand; R.y := TopBlackBand; R.w := Src^.w; R.h := Src^.h;
    SDL_BlitSurface(Src, nil, Dst, @R);
  end
  else
  begin
    Tmp := SDL_CreateRGBSurface(Dst^.flags, DstWidth, DstHeight, Dst^.format^.BitsPerPixel, 0,0,0,0);
    if Tmp = nil then Exit;
    ZoomSurfaceY(Src, Tmp, 0, 0);
    if Src^.format^.palette <> nil then
      SDL_SetPalette(Tmp, SDL_LOGPAL or SDL_PHYSPAL, Src^.format^.palette^.colors, 0, Src^.format^.palette^.ncolors);
    R.x := LeftBlackBand; R.y := TopBlackBand; R.w := Tmp^.w; R.h := Tmp^.h;
    SDL_BlitSurface(Tmp, nil, Dst, @R);
    SDL_FreeSurface(Tmp);
  end;
end;

class function TZoom.ZoomSurfaceY(Src, Dst: PSDL_Surface; FlipX, FlipY: Integer): Integer;
var
  Sax, Say: array of Cardinal;
  X, Y: Integer;
  Sp, Dp, Csp: PByte;
  Dgap: Integer;
begin
  // Simplified nearest-neighbor scaling; full implementation would include optimized paths.
  if UScreen.Use32bitScaler then
  begin
    // Check for HQX or XBRZ (stub)
    // We'll just do a simple loop.
  end;
  // Allocate row increment arrays
  SetLength(Sax, Dst^.w + 1);
  SetLength(Say, Dst^.h + 1);
  Sp := PByte(Src^.pixels);
  Dp := PByte(Dst^.pixels);
  Dgap := Dst^.pitch - Dst^.w;
  if FlipX then Csp := Sp + (Src^.w - 1) else Csp := Sp;
  if FlipY then Csp := Csp + Src^.pitch * (Src^.h - 1);
  // Precalculate X increments
  var CSX := 0;
  for X := 0 to Dst^.w-1 do
  begin
    CSX := CSX + Src^.w;
    Sax[X] := 0;
    while CSX >= Dst^.w do
    begin
      CSX := CSX - Dst^.w;
      Inc(Sax[X]);
    end;
    if FlipX then Sax[X] := -Sax[X];
  end;
  var CSY := 0;
  for Y := 0 to Dst^.h-1 do
  begin
    CSY := CSY + Src^.h;
    Say[Y] := 0;
    while CSY >= Dst^.h do
    begin
      CSY := CSY - Dst^.h;
      Inc(Say[Y]);
    end;
    if FlipY then Say[Y] := -Say[Y];
    Say[Y] := Say[Y] * Src^.pitch;
  end;
  // Draw
  for Y := 0 to Dst^.h-1 do
  begin
    for X := 0 to Dst^.w-1 do
    begin
      Dp^ := Csp^;
      Csp := Csp + Sax[X];
      Inc(Dp);
    end;
    Csp := Csp + Say[Y];
    Dp := Dp + Dgap;
  end;
  Result := 0;
end;

class function TZoom.HaveSSE2: Boolean;
begin
  Result := False; // stub
end;

end.