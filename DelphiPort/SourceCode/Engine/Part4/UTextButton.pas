unit UTextButton;

interface

uses
  SysUtils, Classes, SDL, UText, UInteractiveSurface;

type
  TTextButton = class(TText)
  private
    FWidth, FHeight: Integer;
    FColor, FColor2: Byte;
    FPressed: Boolean;
    FToggled: Boolean;
    FGroup: Integer;
    FButton: Byte;
    procedure DrawButton;
  public
    constructor Create(Width, Height, X, Y: Integer);
    procedure SetColor(Color: Byte); override;
    procedure SetSecondaryColor(Color: Byte); override;
    procedure SetPressed(Pressed: Boolean);
    procedure SetToggled(Toggled: Boolean);
    procedure SetGroup(Group: Integer);
    procedure SetButton(Button: Byte);
    procedure MousePress(Action: TAction; State: TState); override;
    procedure MouseRelease(Action: TAction; State: TState); override;
    procedure MouseClick(Action: TAction; State: TState); override;
    procedure Draw; override;
  end;

implementation

constructor TTextButton.Create(Width, Height, X, Y: Integer);
begin
  inherited Create(Width, Height, X, Y);
  FPressed := False;
  FToggled := False;
  FGroup := 0;
  FButton := SDL_BUTTON_LEFT;
  FColor := 0;
  FColor2 := 0;
end;

procedure TTextButton.SetColor(Color: Byte);
begin
  inherited SetColor(Color);
  FColor := Color;
end;

procedure TTextButton.SetSecondaryColor(Color: Byte);
begin
  inherited SetSecondaryColor(Color);
  FColor2 := Color;
end;

procedure TTextButton.SetPressed(Pressed: Boolean);
begin
  FPressed := Pressed;
  FRedraw := True;
end;

procedure TTextButton.SetToggled(Toggled: Boolean);
begin
  FToggled := Toggled;
  FRedraw := True;
end;

procedure TTextButton.SetGroup(Group: Integer);
begin
  FGroup := Group;
end;

procedure TTextButton.SetButton(Button: Byte);
begin
  FButton := Button;
end;

procedure TTextButton.MousePress(Action: TAction; State: TState);
begin
  inherited;
  if (Action.GetDetails.button.button = FButton) then
    SetPressed(True);
end;

procedure TTextButton.MouseRelease(Action: TAction; State: TState);
begin
  inherited;
  if (Action.GetDetails.button.button = FButton) then
    SetPressed(False);
end;

procedure TTextButton.MouseClick(Action: TAction; State: TState);
begin
  inherited;
  if (Action.GetDetails.button.button = FButton) then
  begin
    FToggled := not FToggled;
    FRedraw := True;
  end;
end;

procedure TTextButton.DrawButton;
begin
  // Draw background based on state
  if FPressed or FToggled then
    Clear(FColor2)
  else
    Clear(FColor);
  // Draw border (simplified)
  DrawRect(0, 0, GetWidth, 1, 15);
  DrawRect(0, GetHeight-1, GetWidth, 1, 15);
  DrawRect(0, 1, 1, GetHeight-2, 15);
  DrawRect(GetWidth-1, 1, 1, GetHeight-2, 15);
end;

procedure TTextButton.Draw;
begin
  FRedraw := False;
  DrawButton;
  // Draw text on top
  DrawText;
end;

end.