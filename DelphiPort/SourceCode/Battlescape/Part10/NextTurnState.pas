unit NextTurnState;

interface

uses
  Classes, SysUtils,
  Engine.State,
  Engine.Game,
  Engine.Timer,
  Engine.Screen,
  Engine.Action,
  Engine.Options,
  Mod.Mod,
  Mod.RuleInterface,
  Engine.LocalizedText,
  Engine.Palette,
  Interface.Window,
  Interface.Text,
  Savegame.SavedBattleGame,
  Battlescape.BattlescapeState,
  Battlescape.Map;

type
  TNextTurnState = class(TState)
  private const
    NEXT_TURN_DELAY = 500;
  private
    FWindow: TWindow;
    FTxtTitle: TText;
    FTxtTurn: TText;
    FTxtSide: TText;
    FTxtMessage: TText;
    FBattleGame: TSavedBattleGame;
    FState: TBattlescapeState;
    FTimer: TTimer;
    FBg: TSurface;
    procedure Close;
  public
    constructor Create(BattleGame: TSavedBattleGame; State: TBattlescapeState);
    destructor Destroy; override;
    procedure Handle(Action: TAction); override;
    procedure Think; override;
    procedure Resize(var DX, DY: Integer); override;
  end;

implementation

{ TNextTurnState }

constructor TNextTurnState.Create(BattleGame: TSavedBattleGame; State: TBattlescapeState);
var
  Y: Integer;
  SS: TStringStream;
begin
  inherited Create;
  FBattleGame := BattleGame;
  FState := State;
  FTimer := nil;

  Y := State.Map.GetMessageY;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FTxtTitle := TText.Create(320, 17, 0, 68);
  FTxtTurn := TText.Create(320, 17, 0, 92);
  FTxtSide := TText.Create(320, 17, 0, 108);
  FTxtMessage := TText.Create(320, 17, 0, 132);
  FBg := TSurface.Create(FGame.Screen.Width, FGame.Screen.Width, 0, 0);

  BattleGame.SetPaletteByDepth(Self);

  Add(FBg);
  Add(FWindow);
  Add(FTxtTitle, 'messageWindows', 'battlescape');
  Add(FTxtTurn, 'messageWindows', 'battlescape');
  Add(FTxtSide, 'messageWindows', 'battlescape');
  Add(FTxtMessage, 'messageWindows', 'battlescape');

  CenterAllSurfaces;

  FBg.X := 0;
  FBg.Y := 0;
  FBg.DrawRect(0, 0, FBg.Width, FBg.Height, Palette.BlockOffset(0)+15);

  FWindow.Y := Y;
  FTxtTitle.Y := Y + 68;
  FTxtTurn.Y := Y + 92;
  FTxtSide.Y := Y + 108;
  FTxtMessage.Y := Y + 132;

  FWindow.Color := Palette.BlockOffset(0)-1;
  FWindow.HighContrast := True;
  FWindow.Background := FGame.Mod.Surface['TAC00.SCR'];

  FTxtTitle.Big := True;
  FTxtTitle.Align := ALIGN_CENTER;
  FTxtTitle.HighContrast := True;
  FTxtTitle.Text := Tr('STR_OPENXCOM');

  FTxtTurn.Big := True;
  FTxtTurn.Align := ALIGN_CENTER;
  FTxtTurn.HighContrast := True;
  SS := TStringStream.Create;
  try
    SS.WriteString(Format(Tr('STR_TURN'), [FBattleGame.Turn]));
    if FBattleGame.TurnLimit > 0 then
    begin
      SS.WriteString('/' + IntToStr(FBattleGame.TurnLimit));
      if FBattleGame.TurnLimit - FBattleGame.Turn <= 3 then
        FTxtTurn.Color := FGame.Mod.Interface['inventory'].Element['weight'].Color2;
    end;
    FTxtTurn.Text := SS.DataString;
  finally
    SS.Free;
  end;

  FTxtSide.Big := True;
  FTxtSide.Align := ALIGN_CENTER;
  FTxtSide.HighContrast := True;
  FTxtSide.Text := Format(Tr('STR_SIDE'), [Tr(IfThen(FBattleGame.Side = FACTION_PLAYER, 'STR_XCOM', 'STR_ALIENS'))]);

  FTxtMessage.Big := True;
  FTxtMessage.Align := ALIGN_CENTER;
  FTxtMessage.HighContrast := True;
  FTxtMessage.Text := Tr('STR_PRESS_BUTTON_TO_CONTINUE');

  FState.ClearMouseScrollingState;

  if Options.SkipNextTurnScreen then
  begin
    FTimer := TTimer.Create(NEXT_TURN_DELAY);
    FTimer.OnTimer := Close;
    FTimer.Start;
  end;
end;

destructor TNextTurnState.Destroy;
begin
  FTimer.Free;
  inherited;
end;

procedure TNextTurnState.Handle(Action: TAction);
begin
  inherited;
  if (Action.Details.Type_ = SDL_KEYDOWN) or (Action.Details.Type_ = SDL_MOUSEBUTTONDOWN) then
    Close;
end;

procedure TNextTurnState.Think;
begin
  inherited;
  if Assigned(FTimer) then
    FTimer.Think(Self, nil);
end;

procedure TNextTurnState.Close;
var
  LiveAliens, LiveSoldiers: Integer;
begin
  FBattleGame.BattleGame.CleanupDeleted;
  FGame.PopState;

  LiveAliens := 0;
  LiveSoldiers := 0;
  FState.BattleGame.TallyUnits(LiveAliens, LiveSoldiers);

  if ((FBattleGame.ObjectiveType <> MUST_DESTROY) and (LiveAliens = 0)) or (LiveSoldiers = 0) then
    FState.FinishBattle(False, LiveSoldiers)
  else
  begin
    FState.BtnCenterClick(nil);
    if ((FBattleGame.Turn = 1) or (FBattleGame.Turn mod Options.AutosaveFrequency = 0)) and (FBattleGame.Side = FACTION_PLAYER) then
      FState.Autosave;
  end;
end;

procedure TNextTurnState.Resize(var DX, DY: Integer);
begin
  inherited;
  FBg.X := 0;
  FBg.Y := 0;
end;

end.