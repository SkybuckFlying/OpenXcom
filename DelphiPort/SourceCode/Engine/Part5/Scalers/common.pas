unit common;

{$POINTERMATH ON}
{$WARN UNSAFE_CAST OFF}

interface

uses
  SysUtils, Math;

var
  RGBtoYUV: array[0..16777215] of Cardinal;

function rgb_to_yuv(c: Cardinal): Cardinal; inline;
function yuv_diff(yuv1, yuv2: Cardinal): Integer; inline;
function Diff(c1, c2: Cardinal): Integer; inline;
function Interpolate_2(c1: Cardinal; w1: Integer; c2: Cardinal; w2: Integer; s: Integer): Cardinal;
function Interpolate_3(c1: Cardinal; w1: Integer; c2: Cardinal; w2: Integer; c3: Cardinal; w3: Integer; s: Integer): Cardinal;
function Interp1(c1, c2: Cardinal): Cardinal; inline;
function Interp2(c1, c2, c3: Cardinal): Cardinal; inline;
function Interp3(c1, c2: Cardinal): Cardinal; inline;
function Interp4(c1, c2, c3: Cardinal): Cardinal; inline;
function Interp5(c1, c2: Cardinal): Cardinal; inline;
function Interp6(c1, c2, c3: Cardinal): Cardinal; inline;
function Interp7(c1, c2, c3: Cardinal): Cardinal; inline;
function Interp8(c1, c2: Cardinal): Cardinal; inline;
function Interp9(c1, c2, c3: Cardinal): Cardinal; inline;
function Interp10(c1, c2, c3: Cardinal): Cardinal; inline;

implementation

const
  MASK_2     = $0000FF00;
  MASK_13    = $00FF00FF;
  MASK_RGB   = $00FFFFFF;
  MASK_ALPHA = $FF000000;
  Ymask      = $00FF0000;
  Umask      = $0000FF00;
  Vmask      = $000000FF;
  trY        = $00300000;
  trU        = $00000700;
  trV        = $00000006;

function rgb_to_yuv(c: Cardinal): Cardinal;
begin
  Result := RGBtoYUV[c and MASK_RGB];
end;

function yuv_diff(yuv1, yuv2: Cardinal): Integer;
begin
  if (Abs(Integer((yuv1 and Ymask) - (yuv2 and Ymask))) > trY) or
     (Abs(Integer((yuv1 and Umask) - (yuv2 and Umask))) > trU) or
     (Abs(Integer((yuv1 and Vmask) - (yuv2 and Vmask))) > trV) then
    Result := 1
  else
    Result := 0;
end;

function Diff(c1, c2: Cardinal): Integer;
begin
  Result := yuv_diff(rgb_to_yuv(c1), rgb_to_yuv(c2));
end;

function Interpolate_2(c1: Cardinal; w1: Integer; c2: Cardinal; w2: Integer; s: Integer): Cardinal;
begin
  if c1 = c2 then Exit(c1);
  Result :=
    (((((c1 and MASK_ALPHA) shr 24) * w1 + ((c2 and MASK_ALPHA) shr 24) * w2) shl (24 - s)) and MASK_ALPHA) +
    ((((c1 and MASK_2) * w1 + (c2 and MASK_2) * w2) shr s) and MASK_2) +
    ((((c1 and MASK_13) * w1 + (c2 and MASK_13) * w2) shr s) and MASK_13);
end;

function Interpolate_3(c1: Cardinal; w1: Integer; c2: Cardinal; w2: Integer; c3: Cardinal; w3: Integer; s: Integer): Cardinal;
begin
  Result :=
    (((((c1 and MASK_ALPHA) shr 24) * w1 + ((c2 and MASK_ALPHA) shr 24) * w2 + ((c3 and MASK_ALPHA) shr 24) * w3) shl (24 - s)) and MASK_ALPHA) +
    ((((c1 and MASK_2) * w1 + (c2 and MASK_2) * w2 + (c3 and MASK_2) * w3) shr s) and MASK_2) +
    ((((c1 and MASK_13) * w1 + (c2 and MASK_13) * w2 + (c3 and MASK_13) * w3) shr s) and MASK_13);
end;

function Interp1(c1, c2: Cardinal): Cardinal;
begin
  Result := Interpolate_2(c1, 3, c2, 1, 2);
end;

function Interp2(c1, c2, c3: Cardinal): Cardinal;
begin
  Result := Interpolate_3(c1, 2, c2, 1, c3, 1, 2);
end;

function Interp3(c1, c2: Cardinal): Cardinal;
begin
  Result := Interpolate_2(c1, 7, c2, 1, 3);
end;

function Interp4(c1, c2, c3: Cardinal): Cardinal;
begin
  Result := Interpolate_3(c1, 2, c2, 7, c3, 7, 4);
end;

function Interp5(c1, c2: Cardinal): Cardinal;
begin
  Result := Interpolate_2(c1, 1, c2, 1, 1);
end;

function Interp6(c1, c2, c3: Cardinal): Cardinal;
begin
  Result := Interpolate_3(c1, 5, c2, 2, c3, 1, 3);
end;

function Interp7(c1, c2, c3: Cardinal): Cardinal;
begin
  Result := Interpolate_3(c1, 6, c2, 1, c3, 1, 3);
end;

function Interp8(c1, c2: Cardinal): Cardinal;
begin
  Result := Interpolate_2(c1, 5, c2, 3, 3);
end;

function Interp9(c1, c2, c3: Cardinal): Cardinal;
begin
  Result := Interpolate_3(c1, 2, c2, 3, c3, 3, 3);
end;

function Interp10(c1, c2, c3: Cardinal): Cardinal;
begin
  Result := Interpolate_3(c1, 14, c2, 1, c3, 1, 4);
end;

procedure hqxInit;
var
  c, r, g, b, y, u, v: Cardinal;
begin
  for c := 0 to 16777215 do
  begin
    r := (c and $FF0000) shr 16;
    g := (c and $00FF00) shr 8;
    b := c and $0000FF;
    y := Round(0.299 * r + 0.587 * g + 0.114 * b);
    u := Round(-0.169 * r - 0.331 * g + 0.5 * b) + 128;
    v := Round(0.5 * r - 0.419 * g - 0.081 * b) + 128;
    RGBtoYUV[c] := (y shl 16) or (u shl 8) or v;
  end;
end;

initialization
  hqxInit;
end.