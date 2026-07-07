unit ArrowButton;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics,
  Common, TextList, Timer;

type
  TArrowShape = (asNone, asBigUp, asBigDown, asSmallUp, asSmallDown, asSmallLeft, asSmallRight);

  TArrowButton = class(TInteractiveSurface)
  private
    FShape: TArrowShape;
    FList: TTextList;
    FTimer: TTimer;
    procedure Scroll(Sender: TObject);
  protected
    procedure DrawContent; override;
    function IsButtonHandled(Button: TMouseButton): Boolean; override;
  public
    constructor Create(Shape: TArrowShape; AWidth, AHeight, AX, AY: Integer; AOwner: TComponent); reintroduce;
    destructor Destroy; override;
    procedure SetColor(Color: TColor);
    procedure SetShape(Shape: TArrowShape);
    procedure SetTextList(List: TTextList);
    procedure Think;
    procedure MousePress(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseRelease(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseClick(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  end;

implementation

uses
  Winapi.Windows, Math;

constructor TArrowButton.Create(Shape: TArrowShape; AWidth, AHeight, AX, AY: Integer; AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := AWidth;
  Height := AHeight;
  Left := AX;
  Top := AY;
  FShape := Shape;
  FList := nil;
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 50;
  FTimer.OnTimer := Scroll;
  FTimer.Enabled := False;
end;

destructor TArrowButton.Destroy;
begin
  FTimer.Free;
  inherited;
end;

function TArrowButton.IsButtonHandled(Button: TMouseButton): Boolean;
begin
  if FList <> nil then
    Result := (Button = mbLeft) or (Button = mbRight)
  else
    Result := inherited IsButtonHandled(Button);
end;

procedure TArrowButton.SetColor(Color: TColor);
begin
  inherited SetColor(Color);
  Redraw := True;
end;

procedure TArrowButton.SetShape(Shape: TArrowShape);
begin
  FShape := Shape;
  Redraw := True;
end;

procedure TArrowButton.SetTextList(List: TTextList);
begin
  FList := List;
end;

procedure TArrowButton.Scroll(Sender: TObject);
begin
  if FShape = asBigUp then
    FList.ScrollUp(False)
  else if FShape = asBigDown then
    FList.ScrollDown(False);
end;

procedure TArrowButton.DrawContent;
var
  Rect: TRect;
  Color: TColor;
  I: Integer;
begin
  inherited;
  Canvas.Pen.Color := GetColor + 2; // simplified
  Canvas.Brush.Style := bsClear;
  Rect := Bounds(0, 0, Width, Height);
  Canvas.Rectangle(Rect);
  // Draw arrow based on shape (simplified)
  Canvas.Pen.Color := GetColor + 1;
  case FShape of
    asBigUp:
      begin
        // draw big up arrow (pseudocode)
      end;
    asBigDown:
      begin
        // draw big down arrow
      end;
    asSmallUp:
      begin
        // draw small up
      end;
    asSmallDown:
      begin
        // draw small down
      end;
    asSmallLeft:
      begin
        // draw small left
      end;
    asSmallRight:
      begin
        // draw small right
      end;
  end;
end;

procedure TArrowButton.Think;
begin
  // timer handles scrolling
end;

procedure TArrowButton.MousePress(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if FList <> nil then
  begin
    if Button = mbLeft then
      FTimer.Enabled := True
    else if (Button = mbRight) and (FShape = asBigUp) then
      FList.ScrollUp(False, True)
    else if (Button = mbRight) and (FShape = asBigDown) then
      FList.ScrollDown(False, True);
  end;
end;

procedure TArrowButton.MouseRelease(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if (FList <> nil) and (Button = mbLeft) then
    FTimer.Enabled := False;
end;

procedure TArrowButton.MouseClick(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if (FList <> nil) and (Button = mbRight) then
  begin
    if FShape = asBigUp then
      FList.ScrollUp(True)
    else if FShape = asBigDown then
      FList.ScrollDown(True);
  end;
end;

end.