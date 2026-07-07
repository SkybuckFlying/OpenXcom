unit InfoboxState;

interface

uses
  System.SysUtils,
  Engine.State, Engine.Game, Engine.Action, Engine.Timer,
  Interface.Text, Interface.Frame;

type
  TInfoboxState = class(TState)
  private
    FText: TText;
    FFrame: TFrame;
    FTimer: TTimer;
    procedure Close;
  public
    const INFOBOX_DELAY = 2000;
    constructor Create(const AMsg: string);
    destructor Destroy; override;
    procedure Handle(AAction: TAction); override;
    procedure Think; override;
  end;

implementation

uses
  Savegame.SavedGame, Savegame.SavedBattleGame;

constructor TInfoboxState.Create(const AMsg: string);
begin
  inherited Create;
  _screen := False;
  FFrame := TFrame.Create(261, 122, 34, 10);
  FText := TText.Create(251, 112, 39, 15);

  Game.GetSavedGame.GetSavedBattle.SetPaletteByDepth(Self);

  Add(FFrame, 'infoBox', 'battlescape');
  Add(FText, 'infoBox', 'battlescape');

  CenterAllSurfaces;

  FFrame.SetHighContrast(True);
  FFrame.SetThickness(9);

  FText.SetAlign(ALIGN_CENTER);
  FText.SetVerticalAlign(ALIGN_MIDDLE);
  FText.SetBig;
  FText.SetWordWrap(True);
  FText.SetText(AMsg);
  FText.SetHighContrast(True);

  FTimer := TTimer.Create(INFOBOX_DELAY);
  FTimer.OnTimer := Close;
  FTimer.Start;
end;

destructor TInfoboxState.Destroy;
begin
  FTimer.Free;
  inherited;
end;

procedure TInfoboxState.Handle(AAction: TAction);
begin
  inherited;
  if (AAction.GetDetails.typ = SDL_KEYDOWN) or (AAction.GetDetails.typ = SDL_MOUSEBUTTONDOWN) then
    Close;
end;

procedure TInfoboxState.Think;
begin
  FTimer.Think(Self, 0);
end;

procedure TInfoboxState.Close;
begin
  Game.PopState;
end;

end.