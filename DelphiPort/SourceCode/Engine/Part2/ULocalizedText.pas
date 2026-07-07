unit ULocalizedText;

interface

uses
  SysUtils;

type
  TLocalizedText = record
  private
    FText: string;
    FNextArg: Integer;
    function ReplaceMarker(const Val: string): TLocalizedText;
  public
    constructor Create(const AText: string); overload;
    constructor Create(const AText: string; AReplaced: Integer); overload;
    function Arg(const Val: string): TLocalizedText; overload;
    function Arg(const Val: Integer): TLocalizedText; overload;
    function Arg(const Val: Double): TLocalizedText; overload;
    function ToString: string;
    class operator Implicit(const S: string): TLocalizedText;
    class operator Implicit(const LT: TLocalizedText): string;
  end;

implementation

uses
  UUnicode;

constructor TLocalizedText.Create(const AText: string);
begin
  FText := AText;
  FNextArg := 0;
end;

constructor TLocalizedText.Create(const AText: string; AReplaced: Integer);
begin
  FText := AText;
  FNextArg := AReplaced + 1;
end;

function TLocalizedText.ReplaceMarker(const Val: string): TLocalizedText;
var
  Marker: string;
  P: Integer;
begin
  Marker := '{' + IntToStr(FNextArg) + '}';
  P := Pos(Marker, FText);
  if P = 0 then
    Result := Self
  else
  begin
    var NewText := FText;
    while P > 0 do
    begin
      Delete(NewText, P, Length(Marker));
      Insert(Val, NewText, P);
      P := Pos(Marker, NewText, P + Length(Val));
    end;
    Result := TLocalizedText.Create(NewText, FNextArg);
  end;
end;

function TLocalizedText.Arg(const Val: string): TLocalizedText;
begin
  Result := ReplaceMarker(Val);
end;

function TLocalizedText.Arg(const Val: Integer): TLocalizedText;
begin
  Result := Arg(IntToStr(Val));
end;

function TLocalizedText.Arg(const Val: Double): TLocalizedText;
begin
  Result := Arg(FloatToStr(Val));
end;

function TLocalizedText.ToString: string;
begin
  Result := FText;
end;

class operator TLocalizedText.Implicit(const S: string): TLocalizedText;
begin
  Result := TLocalizedText.Create(S);
end;

class operator TLocalizedText.Implicit(const LT: TLocalizedText): string;
begin
  Result := LT.FText;
end;

end.