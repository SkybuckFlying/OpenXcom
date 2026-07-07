unit TextEdit;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics,
  Common, Text, Timer, Action, Options, State, Unicode;

type
  TTextEditConstraint = (tecNone, tecNumericPositive, tecNumeric);

  TTextEdit = class(TInteractiveSurface)
  private
    FText: TText;
    FCaret: TText;
    FValue: string;
    FBlink: Boolean;
    FModal: Boolean;
    FTimer: TTimer;
    FChar: Char;
    FCaretPos: Integer;
    FConstraint: TTextEditConstraint;
    FChange: TNotifyEvent;
    FState: TState;
    procedure Blink(Sender: TObject);
    function ExceedsMaxWidth(C: Char): Boolean;
    function IsValidChar(C: Char): Boolean;
  public
    constructor Create(State: TState; AWidth, AHeight, AX, AY: Integer; AOwner: TComponent); reintroduce;
    destructor Destroy; override;
    procedure Handle(Action: TAction; State: TState); override;
    procedure SetFocus(Focused: Boolean; Modal: Boolean = True);
    procedure SetBig;
    procedure SetSmall;
    procedure InitText(Big, Small: TFont; Lang: TLanguage); override;
    procedure SetText(const Text: string);
    function GetText: string;
    procedure SetWordWrap(Wrap: Boolean);
    procedure SetInvert(Invert: Boolean);
    procedure SetHighContrast(Contrast: Boolean); override;
    procedure SetAlign(Align: TTextHAlign);
    procedure SetVerticalAlign(VAlign: TTextVAlign);
    procedure SetConstraint(Constraint: TTextEditConstraint);
    procedure SetColor(Color: TColor); override;
    function GetColor: TColor;
    procedure SetSecondaryColor(Color: TColor); override;
    function GetSecondaryColor: TColor;
    procedure SetPalette(const Colors: array of TColor; FirstColor, NumColors: Integer); override;
    procedure Think; override;
    procedure DrawContent; override;
    procedure MousePress(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyboardPress(var Key: Word; Shift: TShiftState); override;
    procedure OnChange(Handler: TNotifyEvent);
  end;

implementation

uses
  Math, Windows;

constructor TTextEdit.Create(State: TState; AWidth, AHeight, AX, AY: Integer; AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := AWidth;
  Height := AHeight;
  Left := AX;
  Top := AY;
  FState := State;
  FBlink := True;
  FModal := True;
  FChar := 'A';
  FCaretPos := 0;
  FConstraint := tecNone;
  FChange := nil;

  FText := TText.Create(AWidth, AHeight, 0, 0, Self);
  FCaret := TText.Create(16, 17, 0, 0, Self);
  FCaret.SetText('|');
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 100;
  FTimer.OnTimer := Blink;
  FTimer.Enabled := False;
  IsFocused := False;
end;

destructor TTextEdit.Destroy;
begin
  FText.Free;
  FCaret.Free;
  FTimer.Free;
  if FModal then
    FState.SetModal(nil);
  inherited;
end;

procedure TTextEdit.Handle(Action: TAction; State: TState);
begin
  inherited Handle(Action, State);
  if IsFocused and FModal and (Action.Details.Button = mbLeft) and
     ((Action.GetAbsoluteXMouse < Left) or (Action.GetAbsoluteXMouse >= Left + Width) or
      (Action.GetAbsoluteYMouse < Top) or (Action.GetAbsoluteYMouse >= Top + Height)) then
    SetFocus(False);
end;

procedure TTextEdit.SetFocus(Focused: Boolean; Modal: Boolean = True);
begin
  FModal := Modal;
  if Focused <> IsFocused then
  begin
    Redraw := True;
    inherited SetFocus(Focused);
    if IsFocused then
    begin
      Windows.SetFocus(Handle);
      FCaretPos := Length(FValue);
      FBlink := True;
      FTimer.Enabled := True;
      if FModal then FState.SetModal(Self);
    end
    else
    begin
      FBlink := False;
      FTimer.Enabled := False;
      if FModal then FState.SetModal(nil);
    end;
  end;
end;

procedure TTextEdit.Blink(Sender: TObject);
begin
  FBlink := not FBlink;
  Redraw := True;
end;

procedure TTextEdit.SetBig;
begin
  FText.SetBig;
  FCaret.SetBig;
end;

procedure TTextEdit.SetSmall;
begin
  FText.SetSmall;
  FCaret.SetSmall;
end;

procedure TTextEdit.InitText(Big, Small: TFont; Lang: TLanguage);
begin
  FText.InitText(Big, Small, Lang);
  FCaret.InitText(Big, Small, Lang);
end;

procedure TTextEdit.SetText(const Text: string);
begin
  FValue := Text;
  FCaretPos := Length(FValue);
  Redraw := True;
end;

function TTextEdit.GetText: string;
begin
  Result := FValue;
end;

procedure TTextEdit.SetWordWrap(Wrap: Boolean);
begin
  FText.SetWordWrap(Wrap, False);
end;

procedure TTextEdit.SetInvert(Invert: Boolean);
begin
  FText.SetInvert(Invert);
  FCaret.SetInvert(Invert);
end;

procedure TTextEdit.SetHighContrast(Contrast: Boolean);
begin
  FText.SetHighContrast(Contrast);
  FCaret.SetHighContrast(Contrast);
end;

procedure TTextEdit.SetAlign(Align: TTextHAlign);
begin
  FText.SetAlign(Align);
end;

procedure TTextEdit.SetVerticalAlign(VAlign: TTextVAlign);
begin
  FText.SetVerticalAlign(VAlign);
end;

procedure TTextEdit.SetConstraint(Constraint: TTextEditConstraint);
begin
  FConstraint := Constraint;
end;

procedure TTextEdit.SetColor(Color: TColor);
begin
  FText.SetColor(Color);
  FCaret.SetColor(Color);
end;

function TTextEdit.GetColor: TColor;
begin
  Result := FText.GetColor;
end;

procedure TTextEdit.SetSecondaryColor(Color: TColor);
begin
  FText.SetSecondaryColor(Color);
end;

function TTextEdit.GetSecondaryColor: TColor;
begin
  Result := FText.GetSecondaryColor;
end;

procedure TTextEdit.SetPalette(const Colors: array of TColor; FirstColor, NumColors: Integer);
begin
  inherited SetPalette(Colors, FirstColor, NumColors);
  FText.SetPalette(Colors, FirstColor, NumColors);
  FCaret.SetPalette(Colors, FirstColor, NumColors);
end;

procedure TTextEdit.Think;
begin
  inherited;
  FTimer.Enabled := IsFocused;
end;

procedure TTextEdit.DrawContent;
var
  DisplayText: string;
  X, Y: Integer;
begin
  inherited;
  DisplayText := FValue;
  if Options.KeyboardMode = kmOff then
  begin
    if IsFocused and FBlink then
      DisplayText := DisplayText + FChar;
  end;
  FText.SetText(DisplayText);
  Clear;
  FText.Blit(Self);
  if Options.KeyboardMode = kmOn then
  begin
    if IsFocused and FBlink then
    begin
      case FText.GetAlign of
        alLeft: X := 0;
        alCenter: X := (FText.Width - FText.GetTextWidth) div 2;
        alRight: X := FText.Width - FText.GetTextWidth;
      end;
      // advance X by caret position (simplified)
      // (in real code, measure substring)
      Y := 0;
      case FText.GetVerticalAlign of
        alTop: Y := 0;
        alMiddle: Y := (Height - FText.GetTextHeight) div 2;
        alBottom: Y := Height - FText.GetTextHeight;
      end;
      FCaret.Left := X;
      FCaret.Top := Y;
      FCaret.Blit(Self);
    end;
  end;
end;

function TTextEdit.ExceedsMaxWidth(C: Char): Boolean;
var
  S: string;
  W: Integer;
begin
  S := FValue + C;
  W := FText.Canvas.TextWidth(S);
  Result := W > Width;
end;

function TTextEdit.IsValidChar(C: Char): Boolean;
begin
  case FConstraint of
    tecNumericPositive:
      Result := (C >= '0') and (C <= '9');
    tecNumeric:
      if FCaretPos > 0 then
        Result := (C >= '0') and (C <= '9')
      else
        Result := ((C >= '0') and (C <= '9')) or (C = '+') or (C = '-');
  else
    Result := (C >= ' ') and (C <= '~');
  end;
end;

procedure TTextEdit.MousePress(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  MouseX: Integer;
  W, CurrW: Integer;
  I: Integer;
begin
  inherited;
  if Button = mbLeft then
  begin
    if not IsFocused then
      SetFocus(True)
    else
    begin
      MouseX := X;
      W := 0;
      FCaretPos := 0;
      for I := 1 to Length(FValue) do
      begin
        CurrW := FText.Canvas.TextWidth(FValue[I]);
        if MouseX <= W + CurrW div 2 then Break;
        W := W + CurrW;
        Inc(FCaretPos);
      end;
    end;
  end;
end;

procedure TTextEdit.KeyboardPress(var Key: Word; Shift: TShiftState);
var
  C: Char;
begin
  inherited;
  if Options.KeyboardMode = kmOff then
  begin
    case Key of
      VK_UP: begin
                Inc(FChar);
                if FChar > '~' then FChar := ' ';
                Redraw := True;
              end;
      VK_DOWN: begin
                 Dec(FChar);
                 if FChar < ' ' then FChar := '~';
                 Redraw := True;
               end;
      VK_LEFT: if Length(FValue) > 0 then
               begin
                 SetLength(FValue, Length(FValue)-1);
                 Redraw := True;
               end;
      VK_RIGHT: if not ExceedsMaxWidth(FChar) then
                begin
                  FValue := FValue + FChar;
                  Redraw := True;
                end;
    end;
  end
  else if Options.KeyboardMode = kmOn then
  begin
    case Key of
      VK_LEFT: if FCaretPos > 0 then Dec(FCaretPos);
      VK_RIGHT: if FCaretPos < Length(FValue) then Inc(FCaretPos);
      VK_HOME: FCaretPos := 0;
      VK_END: FCaretPos := Length(FValue);
      VK_BACK: if FCaretPos > 0 then
               begin
                 Delete(FValue, FCaretPos, 1);
                 Dec(FCaretPos);
               end;
      VK_DELETE: if FCaretPos < Length(FValue) then
                   Delete(FValue, FCaretPos+1, 1);
      VK_RETURN: if not FValue.IsEmpty then SetFocus(False);
      else
        C := Char(Key);
        if IsValidChar(C) and not ExceedsMaxWidth(C) then
        begin
          Insert(C, FValue, FCaretPos+1);
          Inc(FCaretPos);
        end;
    end;
    Redraw := True;
    if Assigned(FChange) then FChange(Self);
  end;
end;

procedure TTextEdit.OnChange(Handler: TNotifyEvent);
begin
  FChange := Handler;
end;

end.