unit ConfirmDestinationState;

interface

uses
  Engine.State, Engine.Game, Mod.Mod, Engine.LocalizedText,
  Interface.Window, Interface.Text, Interface.TextButton,
  Savegame.SavedGame, Savegame.Craft, Savegame.Target,
  Savegame.Waypoint, Savegame.Base, Engine.Options;

type
  TConfirmDestinationState = class(TState)
  private
    FCraft: TCraft;
    FTarget: TTarget;
    FWindow: TWindow;
    FTxtTarget: TText;
    FBtnOk, FBtnCancel: TTextButton;
    procedure BtnOkClick(AAction: TAction);
    procedure BtnCancelClick(AAction: TAction);
  public
    constructor Create(ACraft: TCraft; ATarget: TTarget);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils, System.Classes;

{ TConfirmDestinationState }

constructor TConfirmDestinationState.Create(ACraft: TCraft; ATarget: TTarget);
var
  w: TWaypoint;
begin
  inherited Create(nil);
  FCraft := ACraft;
  FTarget := ATarget;

  w := FTarget as TWaypoint;
  FScreen := False;

  FWindow := TWindow.Create(Self, 244, 72, 6, 64);
  FBtnOk := TTextButton.Create(50, 12, 68, 104);
  FBtnCancel := TTextButton.Create(50, 12, 138, 104);
  FTxtTarget := TText.Create(232, 32, 12, 72);

  SetInterface('confirmDestination', (w <> nil) and (w.Id = 0));

  Add(FWindow, 'window', 'confirmDestination');
  Add(FBtnOk, 'button', 'confirmDestination');
  Add(FBtnCancel, 'button', 'confirmDestination');
  Add(FTxtTarget, 'text', 'confirmDestination');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK12.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.keyOk, BtnOkClick);

  FBtnCancel.Text := Tr('STR_CANCEL_UC');
  FBtnCancel.OnMouseClick := BtnCancelClick;
  FBtnCancel.OnKeyboardPress(Options.keyCancel, BtnCancelClick);

  FTxtTarget.Big := True;
  FTxtTarget.Align := ALIGN_CENTER;
  FTxtTarget.VerticalAlign := ALIGN_MIDDLE;
  FTxtTarget.WordWrap := True;

  if (w <> nil) and (w.Id = 0) then
    FTxtTarget.Text := Tr('STR_TARGET').Arg(Tr('STR_WAY_POINT'))
  else
    FTxtTarget.Text := Tr('STR_TARGET').Arg(FTarget.Name(Game.Language));
end;

destructor TConfirmDestinationState.Destroy;
begin
  inherited;
end;

procedure TConfirmDestinationState.BtnOkClick(AAction: TAction);
var
  w: TWaypoint;
begin
  w := FTarget as TWaypoint;
  if (w <> nil) and (w.Id = 0) then
  begin
    w.Id := Game.SavedGame.GetId('STR_WAY_POINT');
    Game.SavedGame.Waypoints.Add(w);
  end;
  FCraft.Destination := FTarget;
  FCraft.Status := 'STR_OUT';
  Game.PopState;
  Game.PopState;
end;

procedure TConfirmDestinationState.BtnCancelClick(AAction: TAction);
var
  w: TWaypoint;
begin
  w := FTarget as TWaypoint;
  if (w <> nil) and (w.Id = 0) then
    w.Free;
  Game.PopState;
end;

end.