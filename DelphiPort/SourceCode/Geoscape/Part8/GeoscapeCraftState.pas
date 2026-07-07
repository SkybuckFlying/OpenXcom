unit GeoscapeCraftState;

interface

uses
  Engine.State, Engine.Game, Mod.Mod, Engine.LocalizedText,
  Interface.TextButton, Interface.Window, Interface.Text,
  Savegame.Base, Savegame.Craft, Mod.RuleCraft,
  Savegame.CraftWeapon, Mod.RuleCraftWeapon, Savegame.Target,
  Savegame.Ufo, Savegame.SavedGame, Savegame.Waypoint,
  Geoscape.SelectDestinationState, Engine.Options, Engine.Unicode;

type
  TGeoscapeCraftState = class(TState)
  private
    FCraft: TCraft;
    FGlobe: TGlobe;
    FWaypoint: TWaypoint;
    FBtnBase, FBtnTarget, FBtnPatrol, FBtnCancel: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtStatus, FTxtBase, FTxtSpeed, FTxtMaxSpeed, FTxtAltitude,
    FTxtFuel, FTxtDamage, FTxtW1Name, FTxtW1Ammo, FTxtW2Name, FTxtW2Ammo,
    FTxtRedirect, FTxtSoldier, FTxtHWP: TText;
    procedure BtnBaseClick(AAction: TAction);
    procedure BtnTargetClick(AAction: TAction);
    procedure BtnPatrolClick(AAction: TAction);
    procedure BtnCancelClick(AAction: TAction);
  public
    constructor Create(ACraft: TCraft; AGlobe: TGlobe; AWaypoint: TWaypoint);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils, System.Classes;

{ TGeoscapeCraftState }

constructor TGeoscapeCraftState.Create(ACraft: TCraft; AGlobe: TGlobe; AWaypoint: TWaypoint);
var
  status, altitude: string;
  u: TUfo;
begin
  inherited Create(nil);
  FCraft := ACraft;
  FGlobe := AGlobe;
  FWaypoint := AWaypoint;
  FScreen := False;

  FWindow := TWindow.Create(Self, 240, 184, 8, 8, POPUP_BOTH);
  FBtnBase := TTextButton.Create(212, 12, 22, 124);
  FBtnTarget := TTextButton.Create(212, 12, 22, 140);
  FBtnPatrol := TTextButton.Create(212, 12, 22, 156);
  FBtnCancel := TTextButton.Create(212, 12, 22, 172);
  FTxtTitle := TText.Create(210, 17, 32, 20);
  FTxtStatus := TText.Create(210, 17, 32, 36);
  FTxtBase := TText.Create(210, 9, 32, 52);
  FTxtSpeed := TText.Create(210, 9, 32, 60);
  FTxtMaxSpeed := TText.Create(210, 9, 32, 68);
  FTxtAltitude := TText.Create(210, 9, 32, 76);
  FTxtFuel := TText.Create(130, 9, 32, 84);
  FTxtDamage := TText.Create(80, 9, 164, 84);
  FTxtW1Name := TText.Create(130, 9, 32, 92);
  FTxtW1Ammo := TText.Create(80, 9, 164, 92);
  FTxtW2Name := TText.Create(130, 9, 32, 100);
  FTxtW2Ammo := TText.Create(80, 9, 164, 100);
  FTxtRedirect := TText.Create(230, 17, 13, 108);
  FTxtSoldier := TText.Create(80, 9, 164, 68);
  FTxtHWP := TText.Create(80, 9, 164, 76);

  SetInterface('geoCraft');

  Add(FWindow, 'window', 'geoCraft');
  Add(FBtnBase, 'button', 'geoCraft');
  Add(FBtnTarget, 'button', 'geoCraft');
  Add(FBtnPatrol, 'button', 'geoCraft');
  Add(FBtnCancel, 'button', 'geoCraft');
  Add(FTxtTitle, 'text1', 'geoCraft');
  Add(FTxtStatus, 'text1', 'geoCraft');
  Add(FTxtBase, 'text3', 'geoCraft');
  Add(FTxtSpeed, 'text3', 'geoCraft');
  Add(FTxtMaxSpeed, 'text3', 'geoCraft');
  Add(FTxtAltitude, 'text3', 'geoCraft');
  Add(FTxtFuel, 'text3', 'geoCraft');
  Add(FTxtDamage, 'text3', 'geoCraft');
  Add(FTxtW1Name, 'text3', 'geoCraft');
  Add(FTxtW1Ammo, 'text3', 'geoCraft');
  Add(FTxtW2Name, 'text3', 'geoCraft');
  Add(FTxtW2Ammo, 'text3', 'geoCraft');
  Add(FTxtRedirect, 'text3', 'geoCraft');
  Add(FTxtSoldier, 'text3', 'geoCraft');
  Add(FTxtHWP, 'text3', 'geoCraft');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK12.SCR'));

  FBtnBase.Text := Tr('STR_RETURN_TO_BASE');
  FBtnBase.OnMouseClick := BtnBaseClick;

  FBtnTarget.Text := Tr('STR_SELECT_NEW_TARGET');
  FBtnTarget.OnMouseClick := BtnTargetClick;

  FBtnPatrol.Text := Tr('STR_PATROL');
  FBtnPatrol.OnMouseClick := BtnPatrolClick;

  FBtnCancel.Text := Tr('STR_CANCEL_UC');
  FBtnCancel.OnMouseClick := BtnCancelClick;
  FBtnCancel.OnKeyboardPress(Options.keyCancel, BtnCancelClick);

  FTxtTitle.Big := True;
  FTxtTitle.Text := FCraft.Name(Game.Language);

  FTxtStatus.WordWrap := True;
  status := '';
  if Assigned(FWaypoint) then
    status := Tr('STR_INTERCEPTING_UFO').Arg(FWaypoint.Id)
  else if FCraft.LowFuel then
    status := Tr('STR_LOW_FUEL_RETURNING_TO_BASE')
  else if FCraft.MissionComplete then
    status := Tr('STR_MISSION_COMPLETE_RETURNING_TO_BASE')
  else if FCraft.Destination = nil then
    status := Tr('STR_PATROLLING')
  else if FCraft.Destination = FCraft.Base then
    status := Tr('STR_RETURNING_TO_BASE')
  else
  begin
    u := FCraft.Destination as TUfo;
    if Assigned(u) then
    begin
      if FCraft.IsInDogfight then
        status := Tr('STR_TAILING_UFO')
      else if u.Status = UfoStatus.FLYING then
        status := Tr('STR_INTERCEPTING_UFO').Arg(u.Id)
      else
        status := Tr('STR_DESTINATION_UC_').Arg(u.Name(Game.Language));
    end
    else
      status := Tr('STR_DESTINATION_UC_').Arg(FCraft.Destination.Name(Game.Language));
  end;
  FTxtStatus.Text := Tr('STR_STATUS_').Arg(status);

  FTxtBase.Text := Tr('STR_BASE_UC').Arg(FCraft.Base.Name);

  FTxtSpeed.Text := Tr('STR_SPEED_').Arg(Unicode.FormatNumber(FCraft.Speed));
  FTxtMaxSpeed.Text := Tr('STR_MAXIMUM_SPEED_UC').Arg(Unicode.FormatNumber(FCraft.Rules.MaxSpeed));

  altitude := FCraft.Altitude;
  if altitude = 'STR_GROUND' then altitude := 'STR_GROUNDED';
  if FCraft.Rules.IsWaterOnly and not FGlobe.InsideLand(FCraft.Longitude, FCraft.Latitude) then
    altitude := 'STR_AIRBORNE';
  FTxtAltitude.Text := Tr('STR_ALTITUDE_').Arg(Tr(altitude));

  FTxtFuel.Text := Tr('STR_FUEL').Arg(Unicode.FormatPercentage(FCraft.FuelPercentage));
  FTxtDamage.Text := Tr('STR_DAMAGE_UC_').Arg(Unicode.FormatPercentage(FCraft.DamagePercentage));

  // Weapon info
  if FCraft.Rules.Weapons > 0 then
  begin
    if Assigned(FCraft.Weapons[0]) then
    begin
      FTxtW1Name.Text := Tr('STR_WEAPON_ONE').Arg(Tr(FCraft.Weapons[0].Rules.TypeName));
      FTxtW1Ammo.Text := Tr('STR_ROUNDS_').Arg(FCraft.Weapons[0].Ammo);
    end
    else
    begin
      FTxtW1Name.Text := Tr('STR_WEAPON_ONE').Arg(Tr('STR_NONE_UC'));
      FTxtW1Ammo.Visible := False;
    end;
  end;
  if FCraft.Rules.Weapons > 1 then
  begin
    if Assigned(FCraft.Weapons[1]) then
    begin
      FTxtW2Name.Text := Tr('STR_WEAPON_TWO').Arg(Tr(FCraft.Weapons[1].Rules.TypeName));
      FTxtW2Ammo.Text := Tr('STR_ROUNDS_').Arg(FCraft.Weapons[1].Ammo);
    end
    else
    begin
      FTxtW2Name.Text := Tr('STR_WEAPON_TWO').Arg(Tr('STR_NONE_UC'));
      FTxtW2Ammo.Visible := False;
    end;
  end;

  FTxtRedirect.Big := True;
  FTxtRedirect.Align := ALIGN_CENTER;
  FTxtRedirect.Text := Tr('STR_REDIRECT_CRAFT');

  FTxtSoldier.Text := Tr('STR_SOLDIERS_UC') + '>' + Unicode.TOK_COLOR_FLIP + IntToStr(FCraft.NumSoldiers);
  FTxtHWP.Text := Tr('STR_HWPS') + '>' + Unicode.TOK_COLOR_FLIP + IntToStr(FCraft.NumVehicles);

  if Assigned(FWaypoint) then
    FBtnCancel.Text := Tr('STR_GO_TO_LAST_KNOWN_UFO_POSITION')
  else
    FTxtRedirect.Visible := False;

  if FCraft.LowFuel or FCraft.MissionComplete then
  begin
    FBtnBase.Visible := False;
    FBtnTarget.Visible := False;
    FBtnPatrol.Visible := False;
  end;

  if FCraft.Rules.Soldiers = 0 then FTxtSoldier.Visible := False;
  if FCraft.Rules.Vehicles = 0 then FTxtHWP.Visible := False;
end;

destructor TGeoscapeCraftState.Destroy;
begin
  inherited;
end;

procedure TGeoscapeCraftState.BtnBaseClick(AAction: TAction);
begin
  Game.PopState;
  FCraft.ReturnToBase;
  FWaypoint.Free;
end;

procedure TGeoscapeCraftState.BtnTargetClick(AAction: TAction);
begin
  Game.PopState;
  Game.PushState(TSelectDestinationState.Create(FCraft, FGlobe));
  FWaypoint.Free;
end;

procedure TGeoscapeCraftState.BtnPatrolClick(AAction: TAction);
begin
  Game.PopState;
  FCraft.Destination := nil;
  FWaypoint.Free;
end;

procedure TGeoscapeCraftState.BtnCancelClick(AAction: TAction);
begin
  if Assigned(FWaypoint) then
  begin
    FWaypoint.Id := Game.SavedGame.GetId('STR_WAY_POINT');
    Game.SavedGame.Waypoints.Add(FWaypoint);
    FCraft.Destination := FWaypoint;
  end;
  Game.PopState;
end;

end.