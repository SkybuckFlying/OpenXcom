unit ConfirmLandingState;

interface

uses
  Engine.State, Engine.Game, Mod.Mod, Engine.LocalizedText,
  Interface.Window, Interface.Text, Interface.TextButton,
  Savegame.SavedBattleGame, Savegame.SavedGame, Savegame.Craft,
  Savegame.Target, Savegame.Ufo, Savegame.Base, Savegame.MissionSite,
  Savegame.AlienBase, Battlescape.BriefingState,
  Battlescape.BattlescapeGenerator, Engine.Exception, Engine.Options,
  Mod.AlienDeployment;

type
  TConfirmLandingState = class(TState)
  private
    FCraft: TCraft;
    FWindow: TWindow;
    FTexture: TTexture;
    FShade: Integer;
    FTxtMessage, FTxtBegin: TText;
    FBtnYes, FBtnNo: TTextButton;
    procedure BtnYesClick(AAction: TAction);
    procedure BtnNoClick(AAction: TAction);
  public
    constructor Create(ACraft: TCraft; ATexture: TTexture; AShade: Integer);
    destructor Destroy; override;
    procedure Init; override;
  end;

implementation

uses
  System.SysUtils, System.Classes;

{ TConfirmLandingState }

constructor TConfirmLandingState.Create(ACraft: TCraft; ATexture: TTexture; AShade: Integer);
begin
  inherited Create(nil);
  FCraft := ACraft;
  FTexture := ATexture;
  FShade := AShade;
  FScreen := False;

  FWindow := TWindow.Create(Self, 216, 160, 20, 20, POPUP_BOTH);
  FBtnYes := TTextButton.Create(80, 20, 40, 150);
  FBtnNo := TTextButton.Create(80, 20, 136, 150);
  FTxtMessage := TText.Create(206, 80, 25, 40);
  FTxtBegin := TText.Create(206, 17, 25, 130);

  SetInterface('confirmLanding');

  Add(FWindow, 'window', 'confirmLanding');
  Add(FBtnYes, 'button', 'confirmLanding');
  Add(FBtnNo, 'button', 'confirmLanding');
  Add(FTxtMessage, 'text', 'confirmLanding');
  Add(FTxtBegin, 'text', 'confirmLanding');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK15.SCR'));

  FBtnYes.Text := Tr('STR_YES');
  FBtnYes.OnMouseClick := BtnYesClick;
  FBtnYes.OnKeyboardPress(Options.keyOk, BtnYesClick);

  FBtnNo.Text := Tr('STR_NO');
  FBtnNo.OnMouseClick := BtnNoClick;
  FBtnNo.OnKeyboardPress(Options.keyCancel, BtnNoClick);

  FTxtMessage.Big := True;
  FTxtMessage.Align := ALIGN_CENTER;
  FTxtMessage.WordWrap := True;
  FTxtMessage.Text := Tr('STR_CRAFT_READY_TO_LAND_NEAR_DESTINATION')
                       .Arg(FCraft.Name(Game.Language))
                       .Arg(FCraft.Destination.Name(Game.Language));

  FTxtBegin.Big := True;
  FTxtBegin.Align := ALIGN_CENTER;
  FTxtBegin.Text := Unicode.TOK_COLOR_FLIP + Tr('STR_BEGIN_MISSION');
end;

destructor TConfirmLandingState.Destroy;
begin
  inherited;
end;

procedure TConfirmLandingState.Init;
begin
  inherited;
  // If destination is its own base, cancel automatically
  if (FCraft.Destination is TBase) and (TBase(FCraft.Destination) = FCraft.Base) then
    Game.PopState;
end;

procedure TConfirmLandingState.BtnYesClick(AAction: TAction);
var
  bgame: TSavedBattleGame;
  bgen: TBattlescapeGenerator;
  u: TUfo;
  m: TMissionSite;
  b: TAlienBase;
begin
  Game.PopState;

  u := FCraft.Destination as TUfo;
  m := FCraft.Destination as TMissionSite;
  b := FCraft.Destination as TAlienBase;

  bgame := TSavedBattleGame.Create;
  Game.SavedGame.BattleGame := bgame;

  bgen := TBattlescapeGenerator.Create(Game);
  try
    bgen.WorldTexture := FTexture;
    bgen.WorldShade := FShade;
    bgen.Craft := FCraft;

    if Assigned(u) then
    begin
      if u.Status = TUfoStatus.CRASHED then
        bgame.MissionType := 'STR_UFO_CRASH_RECOVERY'
      else
        bgame.MissionType := 'STR_UFO_GROUND_ASSAULT';
      bgen.Ufo := u;
      bgen.AlienRace := u.AlienRace;
    end
    else if Assigned(m) then
    begin
      bgame.MissionType := m.Deployment.TypeName;
      bgen.MissionSite := m;
      bgen.AlienRace := m.AlienRace;
    end
    else if Assigned(b) then
    begin
      bgame.MissionType := b.Deployment.TypeName;
      bgen.AlienBase := b;
      bgen.AlienRace := b.AlienRace;
      bgen.WorldTexture := nil;
    end
    else
      raise Exception.Create('No mission available!');

    bgen.Run;
  finally
    bgen.Free;
  end;

  Game.PushState(TBriefingState.Create(FCraft));
end;

procedure TConfirmLandingState.BtnNoClick(AAction: TAction);
begin
  FCraft.ReturnToBase;
  Game.PopState;
end;

end.