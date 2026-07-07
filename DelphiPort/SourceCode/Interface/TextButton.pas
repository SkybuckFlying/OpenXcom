unit TextButton;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics,
  Common, Text, Sound, Action, ComboBox;

type
  TTextButton = class(TInteractiveSurface)
  private
    FColor: TColor;
    FText: TText;
    FGroup: ^TTextButton;
    FContrast: Boolean;
    FGeoscapeButton: Boolean;
    FComboBox: TComboBox;
    class var SoundPress: TObject; // simplified
    procedure SetSecondaryColor(Color: TColor); // for RuleInterface
  protected
    function IsButtonHandled(Button: TMouseButton): Boolean; override;
  public
    constructor Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent); reintroduce;
    destructor Destroy; override;
    procedure SetColor(Color: TColor);
    function GetColor: TColor;
    procedure SetTextColor(Color: TColor);
    procedure SetBig;
    procedure SetSmall;
    function GetFont: TFont;
    procedure InitText(Big, Small: TFont; Lang: TLanguage);
    procedure SetHighContrast(Contrast: Boolean);
    procedure SetText(const Text: string);
    function GetText: string;
    procedure SetGroup(Group: Pointer);
    procedure SetPalette(const Colors: array of TColor; FirstColor, NumColors: Integer); override;
    procedure DrawContent; override;
    procedure MousePress(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseRelease(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure SetComboBox(ComboBox: TComboBox);
    procedure SetWidth(AWidth: Integer); override;
    procedure SetHeight(AHeight: Integer); override;
    procedure SetGeoscapeButton(Geo: Boolean);
  end;

implementation

uses
  Math;

constructor TTextButton.Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := AWidth;
  Height := AHeight;
  Left := AX;
  Top := AY;
  FColor := 0;
  FGroup := nil;
  FContrast := False;
  FGeoscapeButton := False;
  FComboBox := nil;

  FText := TText.Create(AWidth, AHeight, 0, 0, Self);
  FText.SetSmall;
  FText.SetAlign(alCenter);
  FText.SetVerticalAlign(alMiddle);
  FText.SetWordWrap(True);
end;

destructor TTextButton.Destroy;
begin
  FText.Free;
  inherited;
end;

function TTextButton.IsButtonHandled(Button: TMouseButton): Boolean;
begin
  if FComboBox <> nil then
    Result := (Button = mbLeft)
  else
    Result := inherited IsButtonHandled(Button);
end;

procedure TTextButton.SetColor(Color: TColor);
begin
  FColor := Color;
  FText.SetColor(Color);
  Redraw := True;
end;

function TTextButton.GetColor: TColor;
begin
  Result := FColor;
end;

procedure TTextButton.SetTextColor(Color: TColor);
begin
  FText.SetColor(Color);
  Redraw := True;
end;

procedure TTextButton.SetBig;
begin
  FText.SetBig;
  Redraw := True;
end;

procedure TTextButton.SetSmall;
begin
  FText.SetSmall;
  Redraw := True;
end;

function TTextButton.GetFont: TFont;
begin
  Result := FText.GetFont;
end;

procedure TTextButton.InitText(Big, Small: TFont; Lang: TLanguage);
begin
  FText.InitText(Big, Small, Lang);
  Redraw := True;
end;

procedure TTextButton.SetHighContrast(Contrast: Boolean);
begin
  FContrast := Contrast;
  FText.SetHighContrast(Contrast);
  Redraw := True;
end;

procedure TTextButton.SetText(const Text: string);
begin
  FText.SetText(Text);
  Redraw := True;
end;

function TTextButton.GetText: string;
begin
  Result := FText.GetText;
end;

procedure TTextButton.SetGroup(Group: Pointer);
begin
  FGroup := Group;
  Redraw := True;
end;

procedure TTextButton.SetPalette(const Colors: array of TColor; FirstColor, NumColors: Integer);
begin
  inherited SetPalette(Colors, FirstColor, NumColors);
  FText.SetPalette(Colors, FirstColor, NumColors);
end;

procedure TTextButton.DrawContent;
var
  Rect: TRect;
  Color: TColor;
  I: Integer;
  Mul: Integer;
  Press: Boolean;
begin
  inherited;
  Mul := 1;
  if FContrast then Mul := 2;
  Color := FColor + 1 * Mul;

  Rect := Bounds(0, 0, Width, Height);
  for I := 0 to 4 do
  begin
    Canvas.Pen.Color := Color;
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(Rect);
    if (I mod 2) = 0 then
    begin
      Inc(Rect.Left);
      Inc(Rect.Top);
    end;
    Dec(Rect.Width);
    Dec(Rect.Height);
    case I of
      0: begin
           Color := FColor + 5 * Mul;
           Canvas.Pixels[Rect.Width, 0] := Color;
         end;
      1: Color := FColor + 2 * Mul;
      2: begin
           Color := FColor + 4 * Mul;
           Canvas.Pixels[Rect.Width+1, 1] := Color;
         end;
      3: Color := FColor + 3 * Mul;
      4: if FGeoscapeButton then
         begin
           Canvas.Pixels[0, 0] := FColor;
           Canvas.Pixels[1, 1] := FColor;
         end;
    end;
  end;

  if FGroup = nil then
    Press := IsPressed
  else
    Press := (FGroup^ = Self);

  if Press then
  begin
    if FGeoscapeButton then
      InvertColor(FColor + 2 * Mul)
    else
      InvertColor(FColor + 3 * Mul);
  end;
  FText.SetInvert(Press);
  FText.Blit(Self);
end;

procedure TTextButton.MousePress(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Old: TTextButton;
begin
  inherited;
  if (Button = mbLeft) and (FGroup <> nil) then
  begin
    Old := FGroup^;
    FGroup^ := Self;
    if Old <> nil then Old.DrawContent;
    DrawContent;
  end;
  if IsButtonHandled(Button) then
  begin
    if (SoundPress <> nil) and (FGroup = nil) and
       (Button <> mbWheelUp) and (Button <> mbWheelDown) then
      // play sound
    if FComboBox <> nil then
      FComboBox.Toggle;
    DrawContent;
  end;
end;

procedure TTextButton.MouseRelease(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if IsButtonHandled(Button) then
    DrawContent;
end;

procedure TTextButton.SetComboBox(ComboBox: TComboBox);
begin
  FComboBox := ComboBox;
  if FComboBox <> nil then
    FText.Left := -6
  else
    FText.Left := 0;
end;

procedure TTextButton.SetWidth(AWidth: Integer);
begin
  inherited SetWidth(AWidth);
  FText.Width := AWidth;
end;

procedure TTextButton.SetHeight(AHeight: Integer);
begin
  inherited SetHeight(AHeight);
  FText.Height := AHeight;
end;

procedure TTextButton.SetGeoscapeButton(Geo: Boolean);
begin
  FGeoscapeButton := Geo;
end;

procedure TTextButton.SetSecondaryColor(Color: TColor);
begin
  SetTextColor(Color);
end;

end.