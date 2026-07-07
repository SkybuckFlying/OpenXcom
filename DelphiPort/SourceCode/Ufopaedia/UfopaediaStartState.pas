{----------------------------------------------------------------------------}
{ Unit: UfopaediaStartState                                                  }
{ Start state showing section buttons.                                       }
{----------------------------------------------------------------------------}
unit UfopaediaStartState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action, Engine.Options, Engine.LocalizedText,
  Engine.Timer, Interface.Window, Interface.Text, Interface.TextButton,
  Interface.ArrowButton, Mod.Mod;

type
  TUfopaediaStartState = class(TState)
  private const
    CAT_MIN_BUTTONS = 9;
    CAT_MAX_BUTTONS = 10;
  private
    FOffset: Integer;
    FScroll: Integer;
    FCats: TStringList; // list of category names
    FWindow: TWindow;
    FTxtTitle: TText;
    FBtnOk: TTextButton;
    FBtnSections: TList<TTextButton>;
    FBtnScrollUp: TArrowButton;
    FBtnScrollDown: TArrowButton;
    FTimerScroll: TTimer;
    procedure BtnSectionClick(Action: TAction);
    procedure BtnOkClick(Action: TAction);
    procedure BtnScrollUpPress(Action: TAction);
    procedure BtnScrollUpClick(Action: TAction);
    procedure BtnScrollDownPress(Action: TAction);
    procedure BtnScrollDownClick(Action: TAction);
    procedure BtnScrollRelease(Action: TAction);
    procedure Scroll;
    procedure UpdateButtons;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Think; override;
  end;

implementation

uses
  Math, UfopaediaSelectState;

{ TUfopaediaStartState }

constructor TUfopaediaStartState.Create;
var
  y: Integer;
  numButtons: Integer;
  i: Integer;
begin
  inherited Create;
  FScreen := False;
  FOffset := 0;
  FScroll := 0;

  FCats := Game.Mod.GetUfopaediaCategoryList; // returns TStringList; we keep reference

  FWindow := TWindow.Create(Self, 256, 180, 32, 10, POPUP_BOTH);
  FTxtTitle := TText.Create(220, 17, 50, 33);

  SetInterface('ufopaedia');

  Add(FWindow, 'window', 'ufopaedia');
  Add(FTxtTitle, 'text', 'ufopaedia');

  FBtnOk := TTextButton.Create(220, 12, 50, 167);
  Add(FBtnOk, 'button1', 'ufopaedia');

  // section buttons
  y := 50;
  numButtons := Min(FCats.Count, CAT_MAX_BUTTONS);
  if numButtons > CAT_MIN_BUTTONS then
    Dec(y, 13 * (numButtons - CAT_MIN_BUTTONS));

  FBtnScrollUp := TArrowButton.Create(ARROW_BIG_UP, 13, 14, 270, y);
  Add(FBtnScrollUp, 'button1', 'ufopaedia');
  FBtnScrollDown := TArrowButton.Create(ARROW_BIG_DOWN, 13, 14, 270, 152);
  Add(FBtnScrollDown, 'button1', 'ufopaedia');

  FBtnSections := TList<TTextButton>.Create;
  for i := 0 to numButtons - 1 do
  begin
    var btn := TTextButton.Create(220, 12, 50, y);
    Inc(y, 13);
    Add(btn, 'button1', 'ufopaedia');
    btn.OnMouseClick := BtnSectionClick;
    btn.OnMousePress := BtnScrollUpClick;
    btn.OnMousePressDown := BtnScrollDownClick; // handle wheel
    FBtnSections.Add(btn);
  end;

  UpdateButtons;

  if FBtnSections.Count > 0 then
    FTxtTitle.Y := FBtnSections[0].Y - FTxtTitle.Height;

  CenterAllSurfaces;

  FWindow.Background := Game.Mod.GetSurface('BACK01.SCR');

  FTxtTitle.Big := True;
  FTxtTitle.Align := ALIGN_CENTER;
  FTxtTitle.Text := tr('STR_UFOPAEDIA');

  FBtnOk.Text := tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  FBtnOk.KeyboardPressKey := Options.KeyCancel;
  // also keyGeoUfopedia - we'll need to handle separately

  FBtnScrollUp.Visible := FCats.Count > CAT_MAX_BUTTONS;
  FBtnScrollUp.OnMousePress := BtnScrollUpPress;
  FBtnScrollUp.OnMouseRelease := BtnScrollRelease;
  FBtnScrollDown.Visible := FCats.Count > CAT_MAX_BUTTONS;
  FBtnScrollDown.OnMousePress := BtnScrollDownPress;
  FBtnScrollDown.OnMouseRelease := BtnScrollRelease;

  FTimerScroll := TTimer.Create(50);
  FTimerScroll.OnTimer := Scroll;
end;

destructor TUfopaediaStartState.Destroy;
begin
  FBtnSections.Free;
  FTimerScroll.Free;
  FBtnOk.Free;
  FTxtTitle.Free;
  FWindow.Free;
  // FCats is owned by Mod, don't free
  inherited;
end;

procedure TUfopaediaStartState.Think;
begin
  inherited;
  FTimerScroll.Think(Self, 0);
end;

procedure TUfopaediaStartState.BtnOkClick(Action: TAction);
begin
  Game.PopState;
end;

procedure TUfopaediaStartState.BtnSectionClick(Action: TAction);
var
  i: Integer;
begin
  for i := 0 to FBtnSections.Count - 1 do
    if Action.Sender = FBtnSections[i] then
    begin
      Game.PushState(TUfopaediaSelectState.Create(FCats[FOffset + i]));
      Break;
    end;
end;

procedure TUfopaediaStartState.BtnScrollUpPress(Action: TAction);
begin
  FScroll := -1;
  FTimerScroll.Start;
end;

procedure TUfopaediaStartState.BtnScrollUpClick(Action: TAction);
begin
  FScroll := -1;
  Scroll;
end;

procedure TUfopaediaStartState.BtnScrollDownPress(Action: TAction);
begin
  FScroll := 1;
  FTimerScroll.Start;
end;

procedure TUfopaediaStartState.BtnScrollDownClick(Action: TAction);
begin
  FScroll := 1;
  Scroll;
end;

procedure TUfopaediaStartState.BtnScrollRelease(Action: TAction);
begin
  FTimerScroll.Stop;
end;

procedure TUfopaediaStartState.Scroll;
begin
  if FCats.Count > CAT_MAX_BUTTONS then
  begin
    FOffset := Math.Clamp(FOffset + FScroll, 0, FCats.Count - CAT_MAX_BUTTONS);
    UpdateButtons;
  end;
end;

procedure TUfopaediaStartState.UpdateButtons;
var
  i: Integer;
begin
  for i := 0 to FBtnSections.Count - 1 do
    FBtnSections[i].Text := tr(FCats[FOffset + i]);
end;

end.