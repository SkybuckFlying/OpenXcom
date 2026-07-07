unit AliensCrashState;

interface

uses
  System.SysUtils,
  Engine.State, Engine.Game, Engine.Action, Engine.Options,
  Interface.TextButton, Interface.Window, Interface.Text,
  Mod.Mod, Engine.LocalizedText;

type
  TAliensCrashState = class(TState)
  private
    FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle: TText;
    procedure BtnOkClick(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  Battlescape.DebriefingState;

constructor TAliensCrashState.Create;
begin
  inherited Create;
  FWindow := TWindow.Create(Self, 256, 160, 32, 20);
  FBtnOk := TTextButton.Create(120, 18, 100, 154);
  FTxtTitle := TText.Create(246, 80, 37, 50);

  SetPalette('PAL_BATTLESCAPE');

  Add(FWindow, 'messageWindowBorder', 'battlescape');
  Add(FBtnOk, 'messageWindowButtons', 'battlescape');
  Add(FTxtTitle, 'messageWindows', 'battlescape');

  CenterAllSurfaces;

  FWindow.SetHighContrast(True);
  FWindow.SetBackground(Game.GetMod.GetSurface('TAC00.SCR'));

  FBtnOk.SetHighContrast(True);
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.keyOk, BtnOkClick);
  FBtnOk.OnKeyboardPress(Options.keyCancel, BtnOkClick);

  FTxtTitle.SetHighContrast(True);
  FTxtTitle.SetText(Tr('STR_ALL_ALIENS_KILLED_IN_CRASH'));
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetVerticalAlign(ALIGN_MIDDLE);
  FTxtTitle.SetBig;
  FTxtTitle.SetWordWrap(True);
end;

destructor TAliensCrashState.Destroy;
begin
  inherited;
end;

procedure TAliensCrashState.BtnOkClick(Sender: TObject);
begin
  Game.PopState;
  Game.PushState(TDebriefingState.Create);
end;

end.