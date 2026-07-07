unit BaseDestroyedState;

interface

uses
  Engine.State, Engine.Game, Engine.Mod, Engine.LocalizedText,
  Interface.Window, Interface.Text, Interface.TextButton,
  Savegame.SavedGame, Savegame.Base, Savegame.Region,
  Savegame.AlienMission, Savegame.Ufo, Mod.RuleRegion,
  Engine.Options;

type
  TBaseDestroyedState = class(TState)
  private
    FWindow: TWindow;
    FTxtMessage: TText;
    FBtnOk: TTextButton;
    FBase: TBase;
    procedure BtnOkClick(AAction: TAction);
  public
    constructor Create(ABase: TBase);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils, System.Classes;

{ TBaseDestroyedState }

constructor TBaseDestroyedState.Create(ABase: TBase);
var
  i: Integer;
  region: TRegion;
  am: TAlienMission;
begin
  inherited Create(nil);
  FBase := ABase;
  FScreen := False;

  FWindow := TWindow.Create(Self, 256, 160, 32, 20);
  FBtnOk := TTextButton.Create(100, 20, 110, 142);
  FTxtMessage := TText.Create(224, 48, 48, 76);

  SetInterface('baseDestroyed');

  Add(FWindow, 'window', 'baseDestroyed');
  Add(FBtnOk, 'button', 'baseDestroyed');
  Add(FTxtMessage, 'text', 'baseDestroyed');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK15.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.keyOk, BtnOkClick);
  FBtnOk.OnKeyboardPress(Options.keyCancel, BtnOkClick);

  FTxtMessage.Align := ALIGN_CENTER;
  FTxtMessage.Big := True;
  FTxtMessage.WordWrap := True;
  FTxtMessage.Text := Tr('STR_THE_ALIENS_HAVE_DESTROYED_THE_UNDEFENDED_BASE').Arg(FBase.Name);

  // Locate region of destroyed base
  region := nil;
  for i := 0 to Game.SavedGame.Regions.Count - 1 do
  begin
    if Game.SavedGame.Regions[i].Rules.InsideRegion(FBase.Longitude, FBase.Latitude) then
    begin
      region := Game.SavedGame.Regions[i];
      Break;
    end;
  end;

  if Assigned(region) then
  begin
    am := Game.SavedGame.FindAlienMission(region.Rules.TypeName, OBJECTIVE_RETALIATION);
    // Remove all UFOs belonging to this retaliation mission
    i := 0;
    while i < Game.SavedGame.Ufos.Count do
    begin
      if Game.SavedGame.Ufos[i].Mission = am then
        Game.SavedGame.Ufos.Delete(i)
      else
        Inc(i);
    end;
    // Remove the mission itself
    for i := 0 to Game.SavedGame.AlienMissions.Count - 1 do
    begin
      if Game.SavedGame.AlienMissions[i] = am then
      begin
        am.Free;
        Game.SavedGame.AlienMissions.Delete(i);
        Break;
      end;
    end;
  end;
end;

destructor TBaseDestroyedState.Destroy;
begin
  inherited;
end;

procedure TBaseDestroyedState.BtnOkClick(AAction: TAction);
var
  i: Integer;
begin
  Game.PopState;
  // Remove the destroyed base from saved game
  for i := 0 to Game.SavedGame.Bases.Count - 1 do
  begin
    if Game.SavedGame.Bases[i] = FBase then
    begin
      FBase.Free;
      Game.SavedGame.Bases.Delete(i);
      Break;
    end;
  end;
end;

end.