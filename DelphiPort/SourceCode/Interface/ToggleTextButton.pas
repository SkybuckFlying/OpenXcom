unit ToggleTextButton;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics,
  TextButton, Action, State;

type
  TToggleTextButton = class(TTextButton)
  private
    FIsPressed: Boolean;
    FOriginalColor: TColor;
    FInvertedColor: TColor;
    FFakeGroup: TTextButton;
  public
    constructor Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent); reintroduce;
    destructor Destroy; override;
    procedure MousePress(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure SetPressed(Pressed: Boolean);
    function GetPressed: Boolean;
    procedure SetColor(Color: TColor); override;
    procedure SetInvertColor(Color: TColor);
    procedure DrawContent; override;
  end;

implementation

constructor TToggleTextButton.Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent);
begin
  inherited Create(AWidth, AHeight, AX, AY, AOwner);
  FIsPressed := False;
  FOriginalColor := -1;
  FInvertedColor := -1;
  FFakeGroup := nil;
  inherited SetGroup(@FFakeGroup);
end;

destructor TToggleTextButton.Destroy;
begin
  inherited;
end;

procedure TToggleTextButton.MousePress(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) or (Button = mbRight) then
  begin
    FIsPressed := not FIsPressed;
    FFakeGroup := IfThen(FIsPressed, Self, nil);
    if FIsPressed and (FInvertedColor > -1) then
      inherited SetColor(FInvertedColor)
    else
      inherited SetColor(FOriginalColor);
  end;
  // skip TextButton's group handling
  inherited MousePress(Button, Shift, X, Y);
  DrawContent;
end;

procedure TToggleTextButton.SetPressed(Pressed: Boolean);
begin
  FIsPressed := Pressed;
  FFakeGroup := IfThen(FIsPressed, Self, nil);
  if FIsPressed and (FInvertedColor > -1) then
    inherited SetColor(FInvertedColor)
  else
    inherited SetColor(FOriginalColor);
  Redraw := True;
end;

function TToggleTextButton.GetPressed: Boolean;
begin
  Result := FIsPressed;
end;

procedure TToggleTextButton.SetColor(Color: TColor);
begin
  FOriginalColor := Color;
  inherited SetColor(Color);
end;

procedure TToggleTextButton.SetInvertColor(Color: TColor);
begin
  FInvertedColor := Color;
  FFakeGroup := nil;
  Redraw := True;
end;

procedure TToggleTextButton.DrawContent;
begin
  if FInvertedColor > -1 then
    FFakeGroup := nil; // prevent TextButton from inverting
  inherited DrawContent;
  if (FInvertedColor > -1) and FIsPressed then
    InvertColor(FInvertedColor + 4);
end;

end.