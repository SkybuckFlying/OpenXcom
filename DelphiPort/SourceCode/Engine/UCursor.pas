unit UCursor;

interface

uses
  SysUtils, Classes, SDL, USurface, UInteractiveSurface, UAction;

type
  TCursor = class(TInteractiveSurface)
  private
    FColor: Byte;
    FVisible: Boolean;
    FShape: Integer; // 0=normal, 1=hand, etc.
    procedure DrawCursor;
  public
    constructor Create(Width, Height: Integer);
    procedure SetColor(Color: Byte); override;
    procedure SetVisible(Visible: Boolean);
    procedure SetShape(Shape: Integer);
    procedure Handle(Action: TAction); override;
    procedure Draw; override;
  end;

implementation

constructor TCursor.Create(Width, Height: Integer);
begin
  inherited Create(Width, Height, 0, 0);
  FColor := 0;
  FVisible := True;
  FShape := 0;
end;

procedure TCursor.SetColor(Color: Byte);
begin
  FColor := Color;
  FRedraw := True;
end;

procedure TCursor.SetVisible(Visible: Boolean);
begin
  FVisible := Visible;
  if not Visible then
    FHidden := True
  else
    FHidden := False;
  FRedraw := True;
end;

procedure TCursor.SetShape(Shape: Integer);
begin
  FShape := Shape;
  FRedraw := True;
end;

procedure TCursor.DrawCursor;
begin
  Clear(0);
  // Draw a simple arrow or cross based on shape (stub)
  if FShape = 0 then
  begin
    // Draw arrow
  end
  else
  begin
    // Draw hand or other
  end;
end;

procedure TCursor.Handle(Action: TAction);
begin
  if not FVisible then Exit;
  // Update position
  if Action.IsMouseAction then
  begin
    SetX(Round(Action.GetAbsoluteXMouse));
    SetY(Round(Action.GetAbsoluteYMouse));
    FRedraw := True;
  end;
end;

procedure TCursor.Draw;
begin
  FRedraw := False;
  DrawCursor;
end;

end.