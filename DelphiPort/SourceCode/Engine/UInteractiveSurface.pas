unit UInteractiveSurface;

interface

uses
  SysUtils, Classes, SDL, USurface, UAction, UState;

type
  TActionHandler = procedure(Sender: TObject; Action: TAction) of object;

  TInteractiveSurface = class(TSurface)
  private
    FButtonsPressed: Byte;
    FClickHandlers: TDictionary<Byte, TActionHandler>;
    FPressHandlers: TDictionary<Byte, TActionHandler>;
    FReleaseHandlers: TDictionary<Byte, TActionHandler>;
    FInHandler, FOverHandler, FOutHandler: TActionHandler;
    FKeyPressHandlers, FKeyReleaseHandlers: TDictionary<Integer, TActionHandler>;
    FIsHovered: Boolean;
    FIsFocused: Boolean;
    FListButton: Boolean;
    function IsButtonHandled(Button: Byte): Boolean;
    function IsButtonPressed(Button: Byte): Boolean;
    procedure SetButtonPressed(Button: Byte; Pressed: Boolean);
  public
    constructor Create(Width, Height, X, Y: Integer);
    destructor Destroy; override;
    procedure SetVisible(Visible: Boolean); override;
    procedure Handle(Action: TAction; State: TState);
    procedure SetFocus(Focus: Boolean);
    function IsFocused: Boolean;
    procedure Unpress(State: TState);
    procedure MousePress(Action: TAction; State: TState); virtual;
    procedure MouseRelease(Action: TAction; State: TState); virtual;
    procedure MouseClick(Action: TAction; State: TState); virtual;
    procedure MouseIn(Action: TAction; State: TState); virtual;
    procedure MouseOver(Action: TAction; State: TState); virtual;
    procedure MouseOut(Action: TAction; State: TState); virtual;
    procedure KeyboardPress(Action: TAction; State: TState); virtual;
    procedure KeyboardRelease(Action: TAction; State: TState); virtual;
    procedure OnMouseClick(Handler: TActionHandler; Button: Byte = SDL_BUTTON_LEFT);
    procedure OnMousePress(Handler: TActionHandler; Button: Byte = 0);
    procedure OnMouseRelease(Handler: TActionHandler; Button: Byte = 0);
    procedure OnMouseIn(Handler: TActionHandler);
    procedure OnMouseOver(Handler: TActionHandler);
    procedure OnMouseOut(Handler: TActionHandler);
    procedure OnKeyboardPress(Handler: TActionHandler; Key: Integer = -1);
    procedure OnKeyboardRelease(Handler: TActionHandler; Key: Integer = -1);
    procedure SetListButton;
  end;

implementation

const
  NUM_BUTTONS = 7;

constructor TInteractiveSurface.Create(Width, Height, X, Y: Integer);
begin
  inherited Create(Width, Height, X, Y);
  FButtonsPressed := 0;
  FClickHandlers := TDictionary<Byte, TActionHandler>.Create;
  FPressHandlers := TDictionary<Byte, TActionHandler>.Create;
  FReleaseHandlers := TDictionary<Byte, TActionHandler>.Create;
  FKeyPressHandlers := TDictionary<Integer, TActionHandler>.Create;
  FKeyReleaseHandlers := TDictionary<Integer, TActionHandler>.Create;
  FIsHovered := False;
  FIsFocused := True;
  FListButton := False;
end;

destructor TInteractiveSurface.Destroy;
begin
  FClickHandlers.Free;
  FPressHandlers.Free;
  FReleaseHandlers.Free;
  FKeyPressHandlers.Free;
  FKeyReleaseHandlers.Free;
  inherited;
end;

procedure TInteractiveSurface.SetVisible(Visible: Boolean);
begin
  inherited;
  if not Visible then
    Unpress(nil);
end;

function TInteractiveSurface.IsButtonHandled(Button: Byte): Boolean;
begin
  Result := FClickHandlers.ContainsKey(0) or FClickHandlers.ContainsKey(Button) or
            FPressHandlers.ContainsKey(0) or FPressHandlers.ContainsKey(Button) or
            FReleaseHandlers.ContainsKey(0) or FReleaseHandlers.ContainsKey(Button);
end;

function TInteractiveSurface.IsButtonPressed(Button: Byte): Boolean;
begin
  if Button = 0 then
    Result := FButtonsPressed <> 0
  else
    Result := (FButtonsPressed and SDL_BUTTON(Button)) <> 0;
end;

procedure TInteractiveSurface.SetButtonPressed(Button: Byte; Pressed: Boolean);
begin
  if Pressed then
    FButtonsPressed := FButtonsPressed or SDL_BUTTON(Button)
  else
    FButtonsPressed := FButtonsPressed and not SDL_BUTTON(Button);
end;

procedure TInteractiveSurface.Handle(Action: TAction; State: TState);
var
  X, Y: Double;
  Button: Byte;
  Handler: TActionHandler;
begin
  if not FVisible or FHidden then Exit;
  Action.SetSender(Self);
  // Handle mouse events
  if Action.GetDetails.type_ in [SDL_MOUSEBUTTONUP, SDL_MOUSEBUTTONDOWN, SDL_MOUSEMOTION] then
  begin
    // Compute absolute coordinates
    X := Action.GetAbsoluteXMouse;
    Y := Action.GetAbsoluteYMouse;
    if (X >= FX) and (X < FX + GetWidth) and (Y >= FY) and (Y < FY + GetHeight) then
    begin
      if not FIsHovered then
      begin
        FIsHovered := True;
        MouseIn(Action, State);
      end;
      if FListButton and (Action.GetDetails.type_ = SDL_MOUSEMOTION) then
      begin
        // Simulate press for list buttons
        FButtonsPressed := SDL_GetMouseState(nil, nil);
        for Button := 1 to NUM_BUTTONS do
          if IsButtonPressed(Button) then
          begin
            Action.GetDetails.button.button := Button;
            MousePress(Action, State);
          end;
      end;
      MouseOver(Action, State);
    end
    else
    begin
      if FIsHovered then
      begin
        FIsHovered := False;
        MouseOut(Action, State);
        if FListButton and (Action.GetDetails.type_ = SDL_MOUSEMOTION) then
        begin
          for Button := 1 to NUM_BUTTONS do
            if IsButtonPressed(Button) then
              SetButtonPressed(Button, False);
          // Call release? Simplified
        end;
      end;
    end;
  end;
  // Mouse button down/up
  if Action.GetDetails.type_ = SDL_MOUSEBUTTONDOWN then
  begin
    if FIsHovered and not IsButtonPressed(Action.GetDetails.button.button) then
    begin
      SetButtonPressed(Action.GetDetails.button.button, True);
      MousePress(Action, State);
    end;
  end
  else if Action.GetDetails.type_ = SDL_MOUSEBUTTONUP then
  begin
    if IsButtonPressed(Action.GetDetails.button.button) then
    begin
      SetButtonPressed(Action.GetDetails.button.button, False);
      MouseRelease(Action, State);
      if FIsHovered then
        MouseClick(Action, State);
    end;
  end;
  // Keyboard events
  if FIsFocused then
  begin
    if Action.GetDetails.type_ = SDL_KEYDOWN then
      KeyboardPress(Action, State)
    else if Action.GetDetails.type_ = SDL_KEYUP then
      KeyboardRelease(Action, State);
  end;
end;

procedure TInteractiveSurface.SetFocus(Focus: Boolean);
begin
  FIsFocused := Focus;
end;

function TInteractiveSurface.IsFocused: Boolean;
begin
  Result := FIsFocused;
end;

procedure TInteractiveSurface.Unpress(State: TState);
var
  Action: TAction;
  Event: TSDL_Event;
begin
  if IsButtonPressed(0) then
  begin
    FButtonsPressed := 0;
    Event.type_ := SDL_MOUSEBUTTONUP;
    Event.button.button := SDL_BUTTON_LEFT;
    Action := TAction.Create(@Event, 0, 0, 0, 0);
    try
      MouseRelease(Action, State);
    finally
      Action.Free;
    end;
  end;
end;

procedure TInteractiveSurface.MousePress(Action: TAction; State: TState);
var
  Btn: Byte;
begin
  Btn := Action.GetDetails.button.button;
  if FPressHandlers.ContainsKey(0) then
    FPressHandlers[0](Self, Action);
  if FPressHandlers.ContainsKey(Btn) then
    FPressHandlers[Btn](Self, Action);
end;

procedure TInteractiveSurface.MouseRelease(Action: TAction; State: TState);
var
  Btn: Byte;
begin
  Btn := Action.GetDetails.button.button;
  if FReleaseHandlers.ContainsKey(0) then
    FReleaseHandlers[0](Self, Action);
  if FReleaseHandlers.ContainsKey(Btn) then
    FReleaseHandlers[Btn](Self, Action);
end;

procedure TInteractiveSurface.MouseClick(Action: TAction; State: TState);
var
  Btn: Byte;
begin
  Btn := Action.GetDetails.button.button;
  if FClickHandlers.ContainsKey(0) then
    FClickHandlers[0](Self, Action);
  if FClickHandlers.ContainsKey(Btn) then
    FClickHandlers[Btn](Self, Action);
end;

procedure TInteractiveSurface.MouseIn(Action: TAction; State: TState);
begin
  if Assigned(FInHandler) then
    FInHandler(Self, Action);
end;

procedure TInteractiveSurface.MouseOver(Action: TAction; State: TState);
begin
  if Assigned(FOverHandler) then
    FOverHandler(Self, Action);
end;

procedure TInteractiveSurface.MouseOut(Action: TAction; State: TState);
begin
  if Assigned(FOutHandler) then
    FOutHandler(Self, Action);
end;

procedure TInteractiveSurface.KeyboardPress(Action: TAction; State: TState);
var
  Key: Integer;
begin
  Key := Action.GetDetails.key.keysym.sym;
  if FKeyPressHandlers.ContainsKey(-1) then
    FKeyPressHandlers[-1](Self, Action);
  if FKeyPressHandlers.ContainsKey(Key) then
    FKeyPressHandlers[Key](Self, Action);
end;

procedure TInteractiveSurface.KeyboardRelease(Action: TAction; State: TState);
var
  Key: Integer;
begin
  Key := Action.GetDetails.key.keysym.sym;
  if FKeyReleaseHandlers.ContainsKey(-1) then
    FKeyReleaseHandlers[-1](Self, Action);
  if FKeyReleaseHandlers.ContainsKey(Key) then
    FKeyReleaseHandlers[Key](Self, Action);
end;

procedure TInteractiveSurface.OnMouseClick(Handler: TActionHandler; Button: Byte);
begin
  if Assigned(Handler) then
    FClickHandlers.AddOrSetValue(Button, Handler)
  else
    FClickHandlers.Remove(Button);
end;

procedure TInteractiveSurface.OnMousePress(Handler: TActionHandler; Button: Byte);
begin
  if Assigned(Handler) then
    FPressHandlers.AddOrSetValue(Button, Handler)
  else
    FPressHandlers.Remove(Button);
end;

procedure TInteractiveSurface.OnMouseRelease(Handler: TActionHandler; Button: Byte);
begin
  if Assigned(Handler) then
    FReleaseHandlers.AddOrSetValue(Button, Handler)
  else
    FReleaseHandlers.Remove(Button);
end;

procedure TInteractiveSurface.OnMouseIn(Handler: TActionHandler);
begin
  FInHandler := Handler;
end;

procedure TInteractiveSurface.OnMouseOver(Handler: TActionHandler);
begin
  FOverHandler := Handler;
end;

procedure TInteractiveSurface.OnMouseOut(Handler: TActionHandler);
begin
  FOutHandler := Handler;
end;

procedure TInteractiveSurface.OnKeyboardPress(Handler: TActionHandler; Key: Integer);
begin
  if Assigned(Handler) then
    FKeyPressHandlers.AddOrSetValue(Key, Handler)
  else
    FKeyPressHandlers.Remove(Key);
end;

procedure TInteractiveSurface.OnKeyboardRelease(Handler: TActionHandler; Key: Integer);
begin
  if Assigned(Handler) then
    FKeyReleaseHandlers.AddOrSetValue(Key, Handler)
  else
    FKeyReleaseHandlers.Remove(Key);
end;

procedure TInteractiveSurface.SetListButton;
begin
  FListButton := True;
end;

end.