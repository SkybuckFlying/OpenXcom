unit ConfirmCydoniaState;

interface

uses
  Engine.State, Engine.Game, Mod.Mod, Engine.LocalizedText,
  Interface.Window, Interface.Text, Interface.TextButton,
  Battlescape.BattlescapeGenerator, Battlescape.BriefingState,
  Savegame.SavedBattleGame, Savegame.SavedGame, Mod.AlienDeployment,
  Engine.Options, Savegame.Craft;

type
  TConfirmCydoniaState = class(TState)
  private
    FWindow: TWindow;
    FTxtMessage: TText;
    FBtnNo, FBtnYes: TTextButton;
    FCraft: TCraft;
    procedure BtnYesClick(AAction: TAction);
    procedure BtnNoClick(AAction: TAction);
  public
    constructor Create(ACraft: TCraft);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils, System.Classes;

{ TConfirmCydoniaState }

constructor TConfirmCydoniaState.Create(ACraft: TCraft);
begin
  inherited Create(nil);
  FCraft := ACraft;
  FScreen := False;

  FWindow := TWindow.Create(Self, 256, 160, 32, 20);
  FBtnYes := TTextButton.Create(80, 20, 70, 142);
  FBtnNo := TTextButton.Create(80, 20, 170, 142);
  FTxtMessage := TText.Create(224, 48, 48, 76);

  SetInterface('confirmCydonia');

  Add(FWindow, 'window', 'confirmCydonia');
  Add(FBtnYes, 'button', 'confirmCydonia');
  Add(FBtnNo, 'button', 'confirmCydonia');
  Add(FTxtMessage, 'text', 'confirmCydonia');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK12.SCR'));

  FBtnYes.Text := Tr('STR_YES');
  FBtnYes.OnMouseClick := BtnYesClick;
  FBtnYes.OnKeyboardPress(Options.keyOk, BtnYesClick);

  FBtnNo.Text := Tr('STR_NO');
  FBtnNo.OnMouseClick := BtnNoClick;
  FBtnNo.OnKeyboardPress(Options.keyCancel, BtnNoClick);

  FTxtMessage.Align := ALIGN_CENTER;
  FTxtMessage.Big := True;
  FTxtMessage.WordWrap := True;
  FTxtMessage.Text := Tr('STR_ARE_YOU_SURE_CYDONIA');
end;

destructor TConfirmCydoniaState.Destroy;
begin
  inherited;
end;

procedure TConfirmCydoniaState.BtnYesClick(AAction: TAction);
var
  bgame: TSavedBattleGame;
  bgen: TBattlescapeGenerator;
  deployment: TAlienDeployment;
  i: Integer;
begin
  Game.PopState;
  Game.PopState; // pop the previous state (SelectDestinationState)

  bgame := TSavedBattleGame.Create;
  Game.SavedGame.BattleGame := bgame;

  bgen := TBattlescapeGenerator.Create(Game);
  try
    // Find final deployment
    for i := 0 to Game.Mod.DeploymentsList.Count - 1 do
    begin
      deployment := Game.Mod.GetDeployment(Game.Mod.DeploymentsList[i]);
      if deployment.IsFinalDestination then
      begin
        bgame.MissionType := deployment.TypeName;
        bgen.AlienRace := deployment.Race;
        Break;
      end;
    end;
    bgen.Craft := FCraft;
    bgen.Run;
  finally
    bgen.Free;
  end;

  Game.PushState(TBriefingState.Create(FCraft));
end;

procedure TConfirmCydoniaState.BtnNoClick(AAction: TAction);
begin
  Game.PopState;
end;

end.