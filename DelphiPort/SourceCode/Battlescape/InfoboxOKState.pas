unit InfoboxOKState;

interface

uses
  System.SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Interface.TextButton, Interface.Frame, Interface.Text,
  Engine.Options;

type
  TInfoboxOKState = class(TState)
  private
    FBtnOk: TTextButton;
    FFrame: TFrame;
    FTxtTitle: TText;
    procedure BtnOkClick(Sender: TObject);
  public
    constructor Create(const AMsg: string);
    destructor Destroy; override;
  end;

implementation

uses
  Savegame.SavedGame, Savegame.SavedBattleGame;

constructor TInfoboxOKState.Create(const AMsg: string);
begin
  inherited Create;
  _screen := False;
  FFrame := TFrame.Create(261, 89, 30, 48);
  FBtnOk := TTextButton.Create(120, 18, 100, 112);
  FTxtTitle := TText.Create(255, 61, 33, 51);

  Game.GetSavedGame.GetSavedBattle.SetPaletteByDepth(Self);

  Add(FFrame, 'infoBoxOK', 'battlescape');
  Add(FBtnOk, 'infoBoxOKButton', 'battlescape');
  Add(FTxtTitle, 'infoBoxOK', 'battlescape');

  CenterAllSurfaces;

  FFrame.SetThickness(3);
  FFrame.SetHighContrast(True);

  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.keyOk, BtnOkClick);
  FBtnOk.OnKeyboardPress(Options.keyCancel, BtnOkClick);
  FBtnOk.SetHighContrast(True);

  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetVerticalAlign(ALIGN_MIDDLE);
  FTxtTitle.SetHighContrast(True);
  FTxtTitle.SetWordWrap(True);
  FTxtTitle.SetText(AMsg);

  Game.GetCursor.SetVisible(True);
end;

destructor TInfoboxOKState.Destroy;
begin
  inherited;
end;

procedure TInfoboxOKState.BtnOkClick(Sender: TObject);
begin
  Game.PopState;
end;

end.