unit ComboBox;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics,
  Common, TextButton, TextList, Window, Language, Font, Timer;

type
  TComboBox = class(TInteractiveSurface)
  private
    const
      HORIZONTAL_MARGIN = 2;
      VERTICAL_MARGIN = 3;
      MAX_ITEMS = 10;
      BUTTON_WIDTH = 14;
      TEXT_HEIGHT = 8;
    FButton: TTextButton;
    FArrow: TSurface;
    FWindow: TWindow;
    FList: TTextList;
    FChange: TNotifyEvent;
    FSel: Integer;
    FState: TState;
    FLang: TLanguage;
    FToggled: Boolean;
    FPopupAboveButton: Boolean;
    procedure DrawArrow;
    procedure SetDropdown(Options: Integer);
    function GetPopupWindowY(ButtonY, PopupHeight: Integer): Integer;
  public
    constructor Create(State: TState; AWidth, AHeight, AX, AY: Integer; PopupAbove: Boolean = False);
    destructor Destroy; override;
    procedure SetX(X: Integer); override;
    procedure SetY(Y: Integer); override;
    procedure SetPalette(const Colors: array of TColor; FirstColor, NumColors: Integer); override;
    procedure InitText(Big, Small: TFont; Lang: TLanguage);
    procedure SetBackground(BG: TSurface);
    procedure SetColor(Color: TColor);
    function GetColor: TColor;
    procedure SetHighContrast(Contrast: Boolean);
    procedure SetArrowColor(Color: TColor);
    function GetSelected: Integer;
    function GetHoveredListIdx: Integer;
    procedure SetText(const Text: string);
    procedure SetSelected(Idx: Integer);
    procedure SetOptions(const Options: array of string; Translate: Boolean = False);
    procedure Blit(Dest: TSurface); override;
    procedure Handle(Action: TAction; State: TState);
    procedure Think;
    procedure Toggle(First: Boolean = False);
    procedure OnChange(Handler: TNotifyEvent);
    procedure OnListMouseIn(Handler: TNotifyEvent);
    procedure OnListMouseOut(Handler: TNotifyEvent);
    procedure OnListMouseOver(Handler: TNotifyEvent);
  end;

implementation

uses
  Math, Options;

constructor TComboBox.Create(State: TState; AWidth, AHeight, AX, AY: Integer; PopupAbove: Boolean = False);
var
  PopupHeight, PopupY: Integer;
begin
  inherited Create(AOwner);
  Width := AWidth;
  Height := AHeight;
  Left := AX;
  Top := AY;
  FState := State;
  FPopupAboveButton := PopupAbove;
  FSel := 0;

  FButton := TTextButton.Create(AWidth, AHeight, AX, AY, Self);
  FButton.SetComboBox(Self);

  FArrow := TSurface.Create(Self);
  FArrow.Width := 11;
  FArrow.Height := 8;
  FArrow.Left := AX + AWidth - BUTTON_WIDTH;
  FArrow.Top := AY + 4;

  PopupHeight := MAX_ITEMS * TEXT_HEIGHT + VERTICAL_MARGIN * 2;
  PopupY := GetPopupWindowY(AY, PopupHeight);
  FWindow := TWindow.Create(State, AWidth, PopupHeight, AX, PopupY, Self);
  FWindow.SetThinBorder;

  FList := TTextList.Create(AWidth - HORIZONTAL_MARGIN * 2 - BUTTON_WIDTH + 1,
                            PopupHeight - (VERTICAL_MARGIN * 2 + 2),
                            AX + HORIZONTAL_MARGIN,
                            PopupY + VERTICAL_MARGIN, Self);
  FList.SetComboBox(Self);
  FList.SetColumns(1, FList.Width);
  FList.SetSelectable(True);
  FList.SetBackground(FWindow);
  FList.SetAlign(alCenter);
  FList.SetScrolling(True, 0);

  Toggle(True);
end;

destructor TComboBox.Destroy;
begin
  FButton.Free;
  FArrow.Free;
  FWindow.Free;
  FList.Free;
  inherited;
end;

function TComboBox.GetPopupWindowY(ButtonY, PopupHeight: Integer): Integer;
begin
  if FPopupAboveButton then
    Result := ButtonY - PopupHeight
  else
    Result := ButtonY + Height;
end;

procedure TComboBox.SetX(X: Integer);
begin
  inherited SetX(X);
  FButton.Left := X;
  FArrow.Left := X + Width - BUTTON_WIDTH;
  FWindow.Left := X;
  FList.Left := X + HORIZONTAL_MARGIN;
end;

procedure TComboBox.SetY(Y: Integer);
var
  PopupHeight, PopupY: Integer;
begin
  inherited SetY(Y);
  FButton.Top := Y;
  FArrow.Top := Y + 4;
  PopupHeight := FWindow.Height;
  PopupY := GetPopupWindowY(Y, PopupHeight);
  FWindow.Top := PopupY;
  FList.Top := PopupY + VERTICAL_MARGIN;
end;

procedure TComboBox.SetPalette(const Colors: array of TColor; FirstColor, NumColors: Integer);
begin
  inherited SetPalette(Colors, FirstColor, NumColors);
  FButton.SetPalette(Colors, FirstColor, NumColors);
  FArrow.SetPalette(Colors, FirstColor, NumColors);
  FWindow.SetPalette(Colors, FirstColor, NumColors);
  FList.SetPalette(Colors, FirstColor, NumColors);
end;

procedure TComboBox.InitText(Big, Small: TFont; Lang: TLanguage);
begin
  FLang := Lang;
  FButton.InitText(Big, Small, Lang);
  FList.InitText(Big, Small, Lang);
end;

procedure TComboBox.SetBackground(BG: TSurface);
begin
  FWindow.SetBackground(BG);
end;

procedure TComboBox.SetColor(Color: TColor);
begin
  FColor := Color;
  DrawArrow;
  FButton.SetColor(Color);
  FWindow.SetColor(Color);
  FList.SetColor(Color);
end;

function TComboBox.GetColor: TColor;
begin
  Result := FColor;
end;

procedure TComboBox.DrawArrow;
begin
  // simplified arrow drawing
  FArrow.Canvas.Brush.Color := FColor + 1;
  FArrow.Canvas.Pen.Color := FColor + 1;
  // draw triangle
end;

procedure TComboBox.SetHighContrast(Contrast: Boolean);
begin
  FButton.SetHighContrast(Contrast);
  FWindow.SetHighContrast(Contrast);
  FList.SetHighContrast(Contrast);
end;

procedure TComboBox.SetArrowColor(Color: TColor);
begin
  FList.SetArrowColor(Color);
end;

function TComboBox.GetSelected: Integer;
begin
  Result := FSel;
end;

function TComboBox.GetHoveredListIdx: Integer;
begin
  Result := -1;
  if FList.Visible then
    Result := FList.GetSelectedRow;
  if Result = -1 then
    Result := FSel;
end;

procedure TComboBox.SetText(const Text: string);
begin
  FButton.SetText(Text);
end;

procedure TComboBox.SetSelected(Idx: Integer);
begin
  FSel := Idx;
  if (FSel >= 0) and (FSel < FList.GetTexts) then
    FButton.SetText(FList.GetCellText(FSel, 0));
end;

procedure TComboBox.SetDropdown(Options: Integer);
var
  Items, H, PopupHeight, PopupY: Integer;
begin
  Items := Min(Options, MAX_ITEMS);
  H := FButton.GetFont.Height + FButton.GetFont.Spacing;
  while FWindow.Top + Items * H + VERTICAL_MARGIN * 2 > 200 do
    Dec(Items);
  PopupHeight := Items * H + VERTICAL_MARGIN * 2;
  PopupY := GetPopupWindowY(Top, PopupHeight);
  FWindow.SetBounds(Left, PopupY, Width, PopupHeight);
  FList.SetBounds(Left + HORIZONTAL_MARGIN, PopupY + VERTICAL_MARGIN, FList.Width, Items * H);
end;

procedure TComboBox.SetOptions(const Options: array of string; Translate: Boolean = False);
var
  I: Integer;
begin
  SetDropdown(Length(Options));
  FList.ClearList;
  for I := 0 to High(Options) do
    if Translate then
      FList.AddRow(1, FLang.GetString(Options[I]))
    else
      FList.AddRow(1, Options[I]);
  SetSelected(FSel);
end;

procedure TComboBox.Blit(Dest: TSurface);
begin
  inherited Blit(Dest);
  FList.InvalidateSurface;
  if Visible and not Hidden then
  begin
    FButton.Blit(Dest);
    FArrow.Blit(Dest);
    FWindow.Blit(Dest);
    FList.Blit(Dest);
  end;
end;

procedure TComboBox.Handle(Action: TAction; State: TState);
begin
  FButton.Handle(Action, State);
  FList.Handle(Action, State);
  inherited Handle(Action, State);
  if FWindow.Visible and (Action.Details.Button = mbLeft) and
     ((Action.GetAbsoluteXMouse < Left) or (Action.GetAbsoluteXMouse >= Left + Width) or
      (Action.GetAbsoluteYMouse < Min(Top, FWindow.Top)) or
      (Action.GetAbsoluteYMouse >= Max(Top + Height, FWindow.Top + FWindow.Height))) then
    Toggle;
  if FToggled then
  begin
    if Assigned(FChange) then FChange(Self);
    FToggled := False;
  end;
end;

procedure TComboBox.Think;
begin
  FButton.Think;
  FArrow.Think;
  FWindow.Think;
  FList.Think;
  inherited Think;
end;

procedure TComboBox.Toggle(First: Boolean = False);
begin
  FWindow.Visible := not FWindow.Visible;
  FList.Visible := not FList.Visible;
  if not First and not FWindow.Visible then
    FToggled := True;
  if FList.Visible then
    if FSel < FList.GetVisibleRows div 2 then
      FList.ScrollTo(0)
    else
      FList.ScrollTo(FSel - FList.GetVisibleRows div 2);
end;

procedure TComboBox.OnChange(Handler: TNotifyEvent);
begin
  FChange := Handler;
end;

procedure TComboBox.OnListMouseIn(Handler: TNotifyEvent);
begin
  FList.OnMouseEnter := Handler;
end;

procedure TComboBox.OnListMouseOut(Handler: TNotifyEvent);
begin
  FList.OnMouseLeave := Handler;
end;

procedure TComboBox.OnListMouseOver(Handler: TNotifyEvent);
begin
  FList.OnMouseMove := Handler;
end;

end.