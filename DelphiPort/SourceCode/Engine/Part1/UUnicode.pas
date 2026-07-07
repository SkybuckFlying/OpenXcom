unit UUnicode;

interface

uses
  SysUtils, Classes;

type
  UCode = Cardinal;  // 32-bit Unicode codepoint
  UString = TArray<UCode>;

  TUnicode = class
  public
    class function ConvUtf8ToUtf32(const S: RawByteString): UString;
    class function ConvUtf32ToUtf8(const US: UString): RawByteString;
    class function ConvWcToMb(const WS: WideString; CP: Cardinal = 0): RawByteString;
    class function ConvMbToWc(const S: RawByteString; CP: Cardinal = 0): WideString;
    class function ConvPathToUtf8(const S: string): string;
    class function ConvUtf8ToPath(const S: string): string;
    class function NaturalCompare(const A, B: string): Boolean;
    class function CaseCompare(const A, B: string): Boolean;
    class function CaseFind(const Haystack, Needle: string): Boolean;
    class procedure UpperCase(var S: string);
    class procedure LowerCase(var S: string);
    class procedure Replace(var S: string; const Find, ReplaceWith: string);
    class function FormatNumber(Value: Int64; const Currency: string = ''): string;
    class function FormatFunding(Funds: Int64): string;
    class function FormatPercentage(Value: Integer): string;
  end;

const
  TOK_NL_SMALL = #2;
  TOK_COLOR_FLIP = #1;
  TOK_NBSP = #$A0;

implementation

uses
  Windows, SysUtils; // for Win32 APIs

class function TUnicode.ConvUtf8ToUtf32(const S: RawByteString): UString;
var
  I, L: Integer;
  CP: UCode;
begin
  SetLength(Result, 0);
  I := 1;
  while I <= Length(S) do
  begin
    L := 1;
    CP := 0;
    if (Byte(S[I]) and $80) = 0 then
      CP := Byte(S[I])
    else if (Byte(S[I]) and $E0) = $C0 then
    begin
      CP := Byte(S[I]) and $1F; L := 2;
    end
    else if (Byte(S[I]) and $F0) = $E0 then
    begin
      CP := Byte(S[I]) and $0F; L := 3;
    end
    else if (Byte(S[I]) and $F8) = $F0 then
    begin
      CP := Byte(S[I]) and $07; L := 4;
    end;
    for var J := 1 to L-1 do
      CP := (CP shl 6) or (Byte(S[I+J]) and $3F);
    SetLength(Result, Length(Result)+1);
    Result[High(Result)] := CP;
    Inc(I, L);
  end;
end;

class function TUnicode.ConvUtf32ToUtf8(const US: UString): RawByteString;
var
  C: UCode;
  Buf: array[0..3] of Byte;
  L: Integer;
begin
  Result := '';
  for C in US do
  begin
    if C <= $7F then
    begin
      L := 1; Buf[0] := C;
    end
    else if C <= $7FF then
    begin
      L := 2;
      Buf[0] := $C0 or (C shr 6);
      Buf[1] := $80 or (C and $3F);
    end
    else if C <= $FFFF then
    begin
      L := 3;
      Buf[0] := $E0 or (C shr 12);
      Buf[1] := $80 or ((C shr 6) and $3F);
      Buf[2] := $80 or (C and $3F);
    end
    else
    begin
      L := 4;
      Buf[0] := $F0 or (C shr 18);
      Buf[1] := $80 or ((C shr 12) and $3F);
      Buf[2] := $80 or ((C shr 6) and $3F);
      Buf[3] := $80 or (C and $3F);
    end;
    SetLength(Result, Length(Result)+L);
    Move(Buf, Result[Length(Result)-L+1], L);
  end;
end;

class function TUnicode.ConvWcToMb(const WS: WideString; CP: Cardinal): RawByteString;
var
  Len: Integer;
begin
  if WS = '' then Exit('');
  Len := WideCharToMultiByte(CP, 0, PWideChar(WS), Length(WS), nil, 0, nil, nil);
  SetLength(Result, Len);
  WideCharToMultiByte(CP, 0, PWideChar(WS), Length(WS), PAnsiChar(Result), Len, nil, nil);
end;

class function TUnicode.ConvMbToWc(const S: RawByteString; CP: Cardinal): WideString;
var
  Len: Integer;
begin
  if S = '' then Exit('');
  Len := MultiByteToWideChar(CP, 0, PAnsiChar(S), Length(S), nil, 0);
  SetLength(Result, Len);
  MultiByteToWideChar(CP, 0, PAnsiChar(S), Length(S), PWideChar(Result), Len);
end;

class function TUnicode.ConvPathToUtf8(const S: string): string;
begin
  {$IFDEF MSWINDOWS}
  Result := ConvWcToMb(ConvMbToWc(S, CP_ACP), CP_UTF8);
  {$ELSE}
  Result := S;
  {$ENDIF}
end;

class function TUnicode.ConvUtf8ToPath(const S: string): string;
begin
  {$IFDEF MSWINDOWS}
  Result := ConvWcToMb(ConvMbToWc(S, CP_UTF8), CP_ACP);
  {$ELSE}
  Result := S;
  {$ENDIF}
end;

class function TUnicode.NaturalCompare(const A, B: string): Boolean;
begin
  // Use StrCmpLogicalW on Windows if available
  Result := A < B; // fallback
end;

class function TUnicode.CaseCompare(const A, B: string): Boolean;
var
  WA, WB: WideString;
begin
  WA := ConvMbToWc(A, CP_UTF8);
  WB := ConvMbToWc(B, CP_UTF8);
  Result := CompareStringW(LOCALE_USER_DEFAULT, NORM_IGNORECASE, PWideChar(WA), Length(WA), PWideChar(WB), Length(WB)) = CSTR_LESS_THAN;
end;

class function TUnicode.CaseFind(const Haystack, Needle: string): Boolean;
var
  WH, WN: WideString;
begin
  WH := ConvMbToWc(Haystack, CP_UTF8);
  WN := ConvMbToWc(Needle, CP_UTF8);
  Result := Pos(PWideChar(WN), PWideChar(WH)) <> 0;
end;

class procedure TUnicode.UpperCase(var S: string);
var
  WS: WideString;
begin
  WS := ConvMbToWc(S, CP_UTF8);
  CharUpperW(PWideChar(WS));
  S := ConvWcToMb(WS, CP_UTF8);
end;

class procedure TUnicode.LowerCase(var S: string);
var
  WS: WideString;
begin
  WS := ConvMbToWc(S, CP_UTF8);
  CharLowerW(PWideChar(WS));
  S := ConvWcToMb(WS, CP_UTF8);
end;

class procedure TUnicode.Replace(var S: string; const Find, ReplaceWith: string);
var
  P: Integer;
begin
  P := Pos(Find, S);
  while P > 0 do
  begin
    Delete(S, P, Length(Find));
    Insert(ReplaceWith, S, P);
    P := Pos(Find, S, P + Length(ReplaceWith));
  end;
end;

class function TUnicode.FormatNumber(Value: Int64; const Currency: string): string;
var
  Neg: Boolean;
  S: string;
  I: Integer;
begin
  Neg := Value < 0;
  if Neg then Value := -Value;
  S := IntToStr(Value);
  I := Length(S) - 3;
  while I > 0 do
  begin
    Insert(#$C2#$A0, S, I+1);
    Dec(I, 3);
  end;
  if Currency <> '' then S := Currency + S;
  if Neg then S := '-' + S;
  Result := S;
end;

class function TUnicode.FormatFunding(Funds: Int64): string;
begin
  Result := FormatNumber(Funds, '$');
end;

class function TUnicode.FormatPercentage(Value: Integer): string;
begin
  Result := IntToStr(Value) + '%';
end;

end.