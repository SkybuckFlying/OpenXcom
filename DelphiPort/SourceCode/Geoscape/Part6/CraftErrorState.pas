unit CraftErrorState;

interface

uses
  System.SysUtils, Engine.State, Engine.Game, Mod.Mod,
  Engine.LocalizedText, Interface.TextButton, Interface.Window,
  Interface.Text, Geoscape.GeoscapeState, Engine.Options;

type
  TCraftErrorState = class(TState)
  private
    FState: TGeoscapeState;
    FBtnOk, FBtnOk5Secs: TTextButton;
    FWindow: TWindow;
    FTxtMessage: TText;
    procedure BtnOkClick(AAction: TAction);
    procedure BtnOk5SecsClick(AAction: TAction);
  public
    constructor Create(AState: TGeoscapeState; const AMsg: string);
    destructor Destroy; override;
  end;

implementation

{ TCraftErrorState }

constructor TCraftErrorState.Create(AState: TGeoscapeState; const AMsg: string);
begin
  inherited Create(nil);
  FState := AState;
  FScreen := False;

  FWindow := TWindow.Create(Self, 256, 160, 32, 20, POPUP_BOTH);
  FBtnOk := TTextButton.Create(100, 18, 48, 150);
  FBtnOk5Secs := TTextButton.Create(100, 18, 172, 150);
  FTxtMessage := TText.Create(246, 96, 37, 42);

  SetInterface('craftError');

  Add(FWindow, 'window', 'craftError');
  Add(FBtnOk, 'button', 'craftError');
  Add(FBtnOk5Secs, 'button', 'craftError');
  Add(FTxtMessage, 'text1', 'craftError');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK12.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.keyCancel, BtnOkClick);

  FBtnOk5Secs.Text := Tr('STR_OK_5_SECONDS');
  FBtnOk5Secs.OnMouseClick := BtnOk5SecsClick;
  FBtnOk5Secs.OnKeyboardPress(Options.keyOk, BtnOk5SecsClick);

  FTxtMessage.Align := ALIGN_CENTER;
  FTxtMessage.VerticalAlign := ALIGN_MIDDLE;
  FTxtMessage.Big := True;
  FTxtMessage.WordWrap := True;
  FTxtMessage.Text := AMsg;
end;

destructor TCraftErrorState.Destroy;
begin
  inherited;
end;

procedure TCraftErrorState.BtnOkClick(AAction: TAction);
begin
  Game.PopState;
end;

procedure TCraftErrorState.BtnOk5SecsClick(AAction: TAction);
begin
  FState.TimerReset;
  Game.PopState;
end;

end.