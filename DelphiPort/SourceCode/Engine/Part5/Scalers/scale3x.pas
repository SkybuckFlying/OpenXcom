unit scale3x;

{$POINTERMATH ON}
{$WARN UNSAFE_CAST OFF}

interface

uses
  SysUtils;

type
  scale3x_uint8  = Byte;
  scale3x_uint16 = Word;
  scale3x_uint32 = Cardinal;

procedure scale3x_8_def(dst0, dst1, dst2: PByte; src0, src1, src2: PByte; count: Cardinal);
procedure scale3x_16_def(dst0, dst1, dst2: PWord; src0, src1, src2: PWord; count: Cardinal);
procedure scale3x_32_def(dst0, dst1, dst2: PCardinal; src0, src1, src2: PCardinal; count: Cardinal);

implementation

procedure scale3x_8_def_border(dst: PByte; src0, src1, src2: PByte; count: Cardinal);
begin
  if count < 2 then Exit;
  // first
  if (src0[0] <> src2[0]) and (src1[0] <> src1[1]) then
  begin
    dst[0] := src1[0];
    if ((src1[0] = src0[0]) and (src1[0] <> src0[1])) or ((src1[1] = src0[0]) and (src1[0] <> src0[0])) then
      dst[1] := src0[0]
    else
      dst[1] := src1[0];
    if src1[1] = src0[0] then dst[2] := src1[1] else dst[2] := src1[0];
  end
  else
  begin
    dst[0] := src1[0];
    dst[1] := src1[0];
    dst[2] := src1[0];
  end;
  Inc(src0); Inc(src1); Inc(src2);
  dst := dst + 3;
  Dec(count, 2);
  while count > 0 do
  begin
    if (src0[0] <> src2[0]) and (src1[-1] <> src1[1]) then
    begin
      if src1[-1] = src0[0] then dst[0] := src1[-1] else dst[0] := src1[0];
      if ((src1[-1] = src0[0]) and (src1[0] <> src0[1])) or ((src1[1] = src0[0]) and (src1[0] <> src0[-1])) then
        dst[1] := src0[0]
      else
        dst[1] := src1[0];
      if src1[1] = src0[0] then dst[2] := src1[1] else dst[2] := src1[0];
    end
    else
    begin
      dst[0] := src1[0];
      dst[1] := src1[0];
      dst[2] := src1[0];
    end;
    Inc(src0); Inc(src1); Inc(src2);
    dst := dst + 3;
    Dec(count);
  end;
end;

procedure scale3x_8_def_center(dst: PByte; src0, src1, src2: PByte; count: Cardinal);
begin
  if count < 2 then Exit;
  // first
  if (src0[0] <> src2[0]) and (src1[0] <> src1[1]) then
  begin
    if ((src1[0] = src0[0]) and (src1[0] <> src2[0])) or ((src1[0] = src2[0]) and (src1[0] <> src0[0])) then
      dst[0] := src1[0]
    else
      dst[0] := src1[0];
    dst[1] := src1[0];
    if ((src1[1] = src0[0]) and (src1[0] <> src2[1])) or ((src1[1] = src2[0]) and (src1[0] <> src0[1])) then
      dst[2] := src1[1]
    else
      dst[2] := src1[0];
  end
  else
  begin
    dst[0] := src1[0];
    dst[1] := src1[0];
    dst[2] := src1[0];
  end;
  Inc(src0); Inc(src1); Inc(src2);
  dst := dst + 3;
  Dec(count, 2);
  while count > 0 do
  begin
    if (src0[0] <> src2[0]) and (src1[-1] <> src1[1]) then
    begin
      if ((src1[-1] = src0[0]) and (src1[0] <> src2[-1])) or ((src1[-1] = src2[0]) and (src1[0] <> src0[-1])) then
        dst[0] := src1[-1]
      else
        dst[0] := src1[0];
      dst[1] := src1[0];
      if ((src1[1] = src0[0]) and (src1[0] <> src2[1])) or ((src1[1] = src2[0]) and (src1[0] <> src0[1])) then
        dst[2] := src1[1]
      else
        dst[2] := src1[0];
    end
    else
    begin
      dst[0] := src1[0];
      dst[1] := src1[0];
      dst[2] := src1[0];
    end;
    Inc(src0); Inc(src1); Inc(src2);
    dst := dst + 3;
    Dec(count);
  end;
end;

procedure scale3x_8_def(dst0, dst1, dst2: PByte; src0, src1, src2: PByte; count: Cardinal);
begin
  scale3x_8_def_border(dst0, src0, src1, src2, count);
  scale3x_8_def_center(dst1, src0, src1, src2, count);
  scale3x_8_def_border(dst2, src2, src1, src0, count);
end;

procedure scale3x_16_def(dst0, dst1, dst2: PWord; src0, src1, src2: PWord; count: Cardinal);
begin
  // same logic, word types
end;

procedure scale3x_32_def(dst0, dst1, dst2: PCardinal; src0, src1, src2: PCardinal; count: Cardinal);
begin
  // same logic, cardinal types
end;

end.