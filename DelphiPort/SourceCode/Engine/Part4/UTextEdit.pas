unit UTextEdit;

interface

uses
  SysUtils, Classes, SDL, UText, UInteractiveSurface, UAction, UState;

type
  TTextEdit = class(TText)
  private
    FText: string;
    FCursorPos: Integer;
    FMaxLength: Integer;
    FPasswordMode: Boolean;
    FEditable: Boolean;
    FBlinkTimer: Integer;
    FCursorVisible: Boolean;
    procedure DrawCursor;
    procedure InsertChar(Ch: Char);
    procedure DeleteChar;
    procedure MoveCursor(Direction: Integer);
  public
    constructor Create(Width, Height, X, Y: Integer);
    procedure SetText(const Text: string);
    function GetText: string;
    procedure SetMaxLength(Length: Integer);
    procedure SetPasswordMode(Enable: Boolean);
    procedure SetEditable(Enable: Boolean);
    procedure KeyboardPress(Action: TAction; State: TState); override;
    procedure Think; override;
    procedure Draw; override;
    procedure SetFocus(Focus: Boolean); override;
  end;

implementation

constructor TTextEdit.Create(Width, Height, X, Y: Integer);
begin
  inherited Create(Width, Height, X, Y);
  FText := '';
  FCursorPos := 0;
  FMaxLength := 0;
  FPasswordMode := False;
  FEditable := True;
  FBlinkTimer := 0;
  FCursorVisible := True;
  SetFocus(False);
end;

procedure TTextEdit.SetText(const Text: string);
begin
  FText := Text;
  if FCursorPos > Length(FText) then FCursorPos := Length(FText);
  FRedraw := True;
end;

function TTextEdit.GetText: string;
begin
  Result := FText;
end;

procedure TTextEdit.SetMaxLength(Length: Integer);
begin
  FMaxLength := Length;
end;

procedure TTextEdit.SetPasswordMode(Enable: Boolean);
begin
  FPasswordMode := Enable;
  FRedraw := True;
end;

procedure TTextEdit.SetEditable(Enable: Boolean);
begin
  FEditable := Enable;
end;

procedure TTextEdit.InsertChar(Ch: Char);
begin
  if not FEditable then Exit;
  if (FMaxLength > 0) and (Length(FText) >= FMaxLength) then Exit;
  Insert(Ch, FText, FCursorPos+1);
  Inc(FCursorPos);
  FRedraw := True;
end;

procedure TTextEdit.DeleteChar;
begin
  if not FEditable then Exit;
  if (FCursorPos > 0) and (Length(FText) > 0) then
  begin
    Delete(FText, FCursorPos, 1);
    Dec(FCursorPos);
    FRedraw := True;
  end;
end;

procedure TTextEdit.MoveCursor(Direction: Integer);
begin
  FCursorPos := FCursorPos + Direction;
  if FCursorPos < 0 then FCursorPos := 0;
  if FCursorPos > Length(FText) then FCursorPos := Length(FText);
  FRedraw := True;
end;

procedure TTextEdit.KeyboardPress(Action: TAction; State: TState);
var
  Sym: Integer;
  Mods: Word;
  Ch: Char;
begin
  inherited;
  if not FEditable or not FIsFocused then Exit;
  Sym := Action.GetDetails.key.keysym.sym;
  Mods := Action.GetDetails.key.keysym.mod;
  // Check for control keys
  if (Mods and KMOD_CTRL) <> 0 then
  begin
    case Sym of
      SDLK_v: // paste (stub)
        ;
      SDLK_c: // copy (stub)
        ;
      SDLK_x: // cut (stub)
        ;
    end;
    Exit;
  end;
  // Handle special keys
  case Sym of
    SDLK_BACKSPACE: DeleteChar;
    SDLK_DELETE: if FCursorPos < Length(FText) then begin Delete(FText, FCursorPos+1, 1); FRedraw := True; end;
    SDLK_LEFT: MoveCursor(-1);
    SDLK_RIGHT: MoveCursor(1);
    SDLK_HOME: begin FCursorPos := 0; FRedraw := True; end;
    SDLK_END: begin FCursorPos := Length(FText); FRedraw := True; end;
    SDLK_RETURN: // maybe commit? (stub)
      ;
    else
      // Check for printable characters
      if Action.GetDetails.key.keysym.unicode <> 0 then
      begin
        Ch := Char(Action.GetDetails.key.keysym.unicode);
        if (Ch >= ' ') and (Ch <= '~') then
          InsertChar(Ch);
      end;
  end;
end;

procedure TTextEdit.Think;
begin
  inherited;
  if FIsFocused and FEditable then
  begin
    Inc(FBlinkTimer);
    if FBlinkTimer >= 30 then
    begin
      FBlinkTimer := 0;
      FCursorVisible := not FCursorVisible;
      FRedraw := True;
    end;
  end
  else
    FCursorVisible := False;
end;

procedure TTextEdit.DrawCursor;
var
  X, Y: Integer;
begin
  if not FCursorVisible then Exit;
  // Calculate cursor position (simplified)
  X := 2 + FCursorPos * FFont.GetCharSize('W').w;
  Y := 2;
  DrawRect(X, Y, 1, FFont.GetHeight, 15);
end;

procedure TTextEdit.Draw;
begin
  FRedraw := False;
  Clear(0);
  // Draw text (with password masking if needed)
  var DisplayText := FText;
  if FPasswordMode then
    DisplayText := StringOfChar('*', Length(FText));
  // Use inherited to draw
  inherited SetText(DisplayText);
  inherited Draw;
  // Draw cursor
  DrawCursor;
end;

procedure TTextEdit.SetFocus(Focus: Boolean);
begin
  inherited SetFocus(Focus);
  if Focus then
  begin
    FBlinkTimer := 0;
    FCursorVisible := True;
  end
  else
    FCursorVisible := False;
  FRedraw := True;
end;

end.