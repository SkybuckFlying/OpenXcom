unit Position;

interface

type
  TPosition = record
    X, Y, Z: Integer;
    class operator Add(const A, B: TPosition): TPosition;
    class operator Subtract(const A, B: TPosition): TPosition;
    class operator Multiply(const A, B: TPosition): TPosition;
    class operator Multiply(const A: TPosition; const V: Integer): TPosition;
    class operator Divide(const A, B: TPosition): TPosition;
    class operator Divide(const A: TPosition; const V: Integer): TPosition;
    class operator Equal(const A, B: TPosition): Boolean;
    class operator NotEqual(const A, B: TPosition): Boolean;
    class function Create(X, Y, Z: Integer): TPosition; static;
    function ToString: string;
  end;

implementation

uses
  SysUtils;

{ TPosition }

class operator TPosition.Add(const A, B: TPosition): TPosition;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
  Result.Z := A.Z + B.Z;
end;

class operator TPosition.Subtract(const A, B: TPosition): TPosition;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
  Result.Z := A.Z - B.Z;
end;

class operator TPosition.Multiply(const A, B: TPosition): TPosition;
begin
  Result.X := A.X * B.X;
  Result.Y := A.Y * B.Y;
  Result.Z := A.Z * B.Z;
end;

class operator TPosition.Multiply(const A: TPosition; const V: Integer): TPosition;
begin
  Result.X := A.X * V;
  Result.Y := A.Y * V;
  Result.Z := A.Z * V;
end;

class operator TPosition.Divide(const A, B: TPosition): TPosition;
begin
  Result.X := A.X div B.X;
  Result.Y := A.Y div B.Y;
  Result.Z := A.Z div B.Z;
end;

class operator TPosition.Divide(const A: TPosition; const V: Integer): TPosition;
begin
  Result.X := A.X div V;
  Result.Y := A.Y div V;
  Result.Z := A.Z div V;
end;

class operator TPosition.Equal(const A, B: TPosition): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y) and (A.Z = B.Z);
end;

class operator TPosition.NotEqual(const A, B: TPosition): Boolean;
begin
  Result := (A.X <> B.X) or (A.Y <> B.Y) or (A.Z <> B.Z);
end;

class function TPosition.Create(X, Y, Z: Integer): TPosition;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
end;

function TPosition.ToString: string;
begin
  Result := Format('(%d,%d,%d)', [X, Y, Z]);
end;

end.