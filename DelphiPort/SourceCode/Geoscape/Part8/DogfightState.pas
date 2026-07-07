unit DogfightState;

interface

uses
  Engine.State, Engine.Game, Engine.Mod, Engine.Screen,
  Engine.LocalizedText, Engine.SurfaceSet, Engine.Surface,
  Interface.ImageButton, Interface.Text, Engine.Timer,
  Geoscape.GeoscapeState, Geoscape.Globe, Savegame.SavedGame,
  Savegame.Craft, Mod.RuleCraft, Savegame.CraftWeapon,
  Mod.RuleCraftWeapon, Savegame.Ufo, Mod.RuleUfo, Engine.RNG,
  Engine.Sound, Savegame.Base, Savegame.CraftWeaponProjectile,
  Savegame.Country, Mod.RuleCountry, Savegame.Region,
  Mod.RuleRegion, Savegame.AlienMission,
  Geoscape.DogfightErrorState, Mod.RuleInterface;

const
  STANDOFF_DIST = 560;

type
  TColorNames = (cnCraftMin, cnCraftMax, cnRadarMin, cnRadarMax,
    cnDamageMin, cnDamageMax, cnBlobMin, cnRangeMeter,
    cnDisabledWeapon, cnDisabledAmmo, cnDisabledRange);

  TDogfightState = class(TState)
  private
    FState: TGeoscapeState;
    FCraft: TCraft;
    FUfo: TUfo;
    FWindow: TSurface;
    FBattle: TSurface;
    FWeapon1, FWeapon2: TInteractiveSurface;
    FRange1, FRange2, FDamage: TSurface;
    FBtnMinimize: TInteractiveSurface;
    FPreview: TInteractiveSurface;
    FBtnStandoff, FBtnCautious, FBtnStandard, FBtnAggressive, FBtnDisengage, FBtnUfo: TImageButton;
    FMode: TImageButton;
    FBtnMinimizedIcon: TInteractiveSurface;
    FTxtAmmo1, FTxtAmmo2, FTxtDistance, FTxtStatus, FTxtInterceptionNumber: TText;
    FTimeout, FCurrentDist, FTargetDist, FW1FireInterval, FW2FireInterval,
    FW1FireCountdown, FW2FireCountdown: Integer;
    FEnd, FDestroyUfo, FDestroyCraft, FUfoBreakingOff, FWeapon1Enabled, FWeapon2Enabled: Boolean;
    FMinimized, FEndDogfight, FAnimatingHit, FWaitForPoly, FWaitForAltitude: Boolean;
    FProjectiles: TList;
    FUfoSize, FCraftHeight, FCurrentCraftDamageColor, FInterceptionNumber: Integer;
    FInterceptionsCount: Integer;
    FX, FY, FMinimizedIconX, FMinimizedIconY: Integer;
    FColors: array[TColorNames] of Byte;
    FTimer: TTimer;
    procedure EndDogfight;
    procedure FireWeapon1;
    procedure FireWeapon2;
    procedure UfoFireWeapon;
    procedure MinimumDistance;
    procedure MaximumDistance;
    procedure SetStatus(const AStatus: string);
    procedure BtnMinimizeClick(AAction: TAction);
    procedure BtnStandoffPress(AAction: TAction);
    procedure BtnCautiousPress(AAction: TAction);
    procedure BtnStandardPress(AAction: TAction);
    procedure BtnAggressivePress(AAction: TAction);
    procedure BtnDisengagePress(AAction: TAction);
    procedure BtnUfoClick(AAction: TAction);
    procedure PreviewClick(AAction: TAction);
    procedure DrawUfo;
    procedure DrawProjectile(p: TCraftWeaponProjectile);
    procedure AnimateCraftDamage;
    procedure DrawCraftDamage;
    procedure Weapon1Click(AAction: TAction);
    procedure Weapon2Click(AAction: TAction);
    procedure Recolor(WeaponNo: Integer; CurrentState: Boolean);
    procedure BtnMinimizedIconClick(AAction: TAction);
    procedure CalculateWindowPosition;
    procedure MoveWindow;
  public
    constructor Create(AState: TGeoscapeState; ACraft: TCraft; AUfo: TUfo);
    destructor Destroy; override;
    procedure Think; override;
    procedure Animate;
    procedure Update;
    function IsMinimized: Boolean;
    procedure SetMinimized(Minimized: Boolean);
    procedure SetInterceptionNumber(Number: Integer);
    procedure SetInterceptionsCount(Count: Integer);
    function DogfightEnded: Boolean;
    function GetUfo: TUfo;
    function GetCraft: TCraft;
    function GetInterceptionNumber: Integer;
    procedure SetWaitForPoly(Wait: Boolean);
    function GetWaitForPoly: Boolean;
    procedure SetWaitForAltitude(Wait: Boolean);
    function GetWaitForAltitude: Boolean;
  end;

implementation

uses
  System.SysUtils, System.Math, System.Classes, System.Types;

const
  { UFO blobs graphics (8 sizes, 13x13) }
  UfoBlobs: array[0..7, 0..12, 0..12] of Integer = (
    // 0 STR_VERY_SMALL
    ((0,0,0,0,0,0,0,0,0,0,0,0,0),
     (0,0,0,0,0,0,0,0,0,0,0,0,0),
     (0,0,0,0,0,0,0,0,0,0,0,0,0),
     (0,0,0,0,0,0,0,0,0,0,0,0,0),
     (0,0,0,0,0,1,1,1,0,0,0,0,0),
     (0,0,0,0,1,2,3,2,1,0,0,0,0),
     (0,0,0,0,1,3,5,3,1,0,0,0,0),
     (0,0,0,0,1,2,3,2,1,0,0,0,0),
     (0,0,0,0,0,1,1,1,0,0,0,0,0),
     (0,0,0,0,0,0,0,0,0,0,0,0,0),
     (0,0,0,0,0,0,0,0,0,0,0,0,0),
     (0,0,0,0,0,0,0,0,0,0,0,0,0),
     (0,0,0,0,0,0,0,0,0,0,0,0,0)),
    // 1 STR_SMALL
    ((0,0,0,0,0,0,0,0,0,0,0,0,0),
     (0,0,0,0,0,0,0,0,0,0,0,0,0),
     (0,0,0,0,0,0,0,0,0,0,0,0,0),
     (0,0,0,0,0,1,1,1,0,0,0,0,0),
     (0,0,0,0,1,2,2,2,1,0,0,0,0),
     (0,0,0,1,2,3,4,3,2,1,0,0,0),
     (0,0,0,1,2,4,5,4,2,1,0,0,0),
     (0,0,0,1,2,3,4,3,2,1,0,0,0),
     (0,0,0,0,1,2,2,2,1,0,0,0,0),
     (0,0,0,0,0,1,1,1,0,0,0,0,0),
     (0,0,0,0,0,0,0,0,0,0,0,0,0),
     (0,0,0,0,0,0,0,0,0,0,0,0,0),
     (0,0,0,0,0,0,0,0,0,0,0,0,0)),
    // 2 STR_MEDIUM_UC
    ((0,0,0,0,0,0,0,0,0,0,0,0,0),
     (0,0,0,0,0,0,0,0,0,0,0,0,0),
     (0,0,0,0,0,1,1,1,0,0,0,0,0),
     (0,0,0,1,1,2,2,2,1,1,0,0,0),
     (0,0,0,1,2,3,3,3,2,1,0,0,0),
     (0,0,1,2,3,4,5,4,3,2,1,0,0),
     (0,0,1,2,3,5,5,5,3,2,1,0,0),
     (0,0,1,2,3,4,5,4,3,2,1,0,0),
     (0,0,0,1,2,3,3,3,2,1,0,0,0),
     (0,0,0,1,1,2,2,2,1,1,0,0,0),
     (0,0,0,0,0,1,1,1,0,0,0,0,0),
     (0,0,0,0,0,0,0,0,0,0,0,0,0),
     (0,0,0,0,0,0,0,0,0,0,0,0,0)),
    // 3 STR_LARGE
    ((0,0,0,0,0,0,0,0,0,0,0,0,0),
     (0,0,0,0,0,1,1,1,0,0,0,0,0),
     (0,0,0,1,1,2,2,2,1,1,0,0,0),
     (0,0,1,2,2,3,3,3,2,2,1,0,0),
     (0,0,1,2,3,4,4,4,3,2,1,0,0),
     (0,1,2,3,4,5,5,5,4,3,2,1,0),
     (0,1,2,3,4,5,5,5,4,3,2,1,0),
     (0,1,2,3,4,5,5,5,4,3,2,1,0),
     (0,0,1,2,3,4,4,4,3,2,1,0,0),
     (0,0,1,2,2,3,3,3,2,2,1,0,0),
     (0,0,0,1,1,2,2,2,1,1,0,0,0),
     (0,0,0,0,0,1,1,1,0,0,0,0,0),
     (0,0,0,0,0,0,0,0,0,0,0,0,0)),
    // 4 STR_VERY_LARGE
    ((0,0,0,0,0,1,1,1,0,0,0,0,0),
     (0,0,0,1,1,2,2,2,1,1,0,0,0),
     (0,0,1,2,2,3,3,3,2,2,1,0,0),
     (0,1,2,3,3,4,4,4,3,3,2,1,0),
     (0,1,2,3,4,5,5,5,4,3,2,1,0),
     (1,2,3,4,5,5,5,5,5,4,3,2,1),
     (1,2,3,4,5,5,5,5,5,4,3,2,1),
     (1,2,3,4,5,5,5,5,5,4,3,2,1),
     (0,1,2,3,4,5,5,5,4,3,2,1,0),
     (0,1,2,3,3,4,4,4,3,3,2,1,0),
     (0,0,1,2,2,3,3,3,2,2,1,0,0),
     (0,0,0,1,1,2,2,2,1,1,0,0,0),
     (0,0,0,0,0,1,1,1,0,0,0,0,0)),
    // 5 STR_HUGE
    ((0,0,0,1,1,2,2,2,1,1,0,0,0),
     (0,0,1,2,2,3,3,3,2,2,1,0,0),
     (0,1,2,3,3,4,4,4,3,3,2,1,0),
     (1,2,3,4,4,5,5,5,4,4,3,2,1),
     (1,2,3,4,5,5,5,5,5,4,3,2,1),
     (2,3,4,5,5,5,5,5,5,5,4,3,2),
     (2,3,4,5,5,5,5,5,5,5,4,3,2),
     (2,3,4,5,5,5,5,5,5,5,4,3,2),
     (1,2,3,4,5,5,5,5,5,4,3,2,1),
     (1,2,3,4,4,5,5,5,4,4,3,2,1),
     (0,1,2,3,3,4,4,4,3,3,2,1,0),
     (0,0,1,2,2,3,3,3,2,2,1,0,0),
     (0,0,0,1,1,2,2,2,1,1,0,0,0)),
    // 6 STR_VERY_HUGE
    ((0,0,0,2,2,3,3,3,2,2,0,0,0),
     (0,0,2,3,3,4,4,4,3,3,2,0,0),
     (0,2,3,4,4,5,5,5,4,4,3,2,0),
     (2,3,4,5,5,5,5,5,5,5,4,3,2),
     (2,3,4,5,5,5,5,5,5,5,4,3,2),
     (3,4,5,5,5,5,5,5,5,5,5,4,3),
     (3,4,5,5,5,5,5,5,5,5,5,4,3),
     (3,4,5,5,5,5,5,5,5,5,5,4,3),
     (2,3,4,5,5,5,5,5,5,5,4,3,2),
     (2,3,4,5,5,5,5,5,5,5,4,3,2),
     (0,2,3,4,4,5,5,5,4,4,3,2,0),
     (0,0,2,3,3,4,4,4,3,3,2,0,0),
     (0,0,0,2,2,3,3,3,2,2,0,0,0)),
    // 7 STR_ENORMOUS
    ((0,0,0,3,3,4,4,4,3,3,0,0,0),
     (0,0,3,4,4,5,5,5,4,4,3,0,0),
     (0,3,4,5,5,5,5,5,5,5,4,3,0),
     (3,4,5,5,5,5,5,5,5,5,5,4,3),
     (3,4,5,5,5,5,5,5,5,5,5,4,3),
     (4,5,5,5,5,5,5,5,5,5,5,5,4),
     (4,5,5,5,5,5,5,5,5,5,5,5,4),
     (4,5,5,5,5,5,5,5,5,5,5,5,4),
     (3,4,5,5,5,5,5,5,5,5,5,4,3),
     (3,4,5,5,5,5,5,5,5,5,5,4,3),
     (0,3,4,5,5,5,5,5,5,5,4,3,0),
     (0,0,3,4,4,5,5,5,4,4,3,0,0),
     (0,0,0,3,3,4,4,4,3,3,0,0,0))
  );

  { Projectile blobs (4 types, 6x3) }
  ProjectileBlobs: array[0..3, 0..5, 0..2] of Integer = (
    // 0 STR_STINGRAY_MISSILE
    ((0,1,0),
     (1,9,1),
     (1,4,1),
     (0,3,0),
     (0,2,0),
     (0,1,0)),
    // 1 STR_AVALANCHE_MISSILE
    ((1,2,1),
     (2,9,2),
     (2,5,2),
     (1,3,1),
     (0,2,0),
     (0,1,0)),
    // 2 STR_CANNON_ROUND
    ((0,0,0),
     (0,7,0),
     (0,2,0),
     (0,1,0),
     (0,0,0),
     (0,0,0)),
    // 3 STR_FUSION_BALL
    ((2,4,2),
     (4,9,4),
     (2,4,2),
     (0,0,0),
     (0,0,0),
     (0,0,0))
  );

{ TDogfightState }

constructor TDogfightState.Create(AState: TGeoscapeState; ACraft: TCraft; AUfo: TUfo);
var
  dogfightInterface: TRuleInterface;
  graphic: TSurface;
  set: TSurfaceSet;
  frame: TSurface;
  w: TCraftWeapon;
  i: Integer;
  x1, x2: Integer;
  weapon, range: TSurface;
  ammo: TText;
  ss: string;
begin
  inherited Create(nil);
  FState := AState;
  FCraft := ACraft;
  FUfo := AUfo;
  FTimeout := 50;
  FCurrentDist := 640;
  FTargetDist := 560;
  FW1FireCountdown := 0;
  FW2FireCountdown := 0;
  FEnd := False;
  FDestroyUfo := False;
  FDestroyCraft := False;
  FUfoBreakingOff := False;
  FWeapon1Enabled := True;
  FWeapon2Enabled := True;
  FMinimized := False;
  FEndDogfight := False;
  FAnimatingHit := False;
  FWaitForPoly := False;
  FWaitForAltitude := False;
  FUfoSize := 0;
  FCraftHeight := 0;
  FCurrentCraftDamageColor := 0;
  FInterceptionNumber := 0;
  FInterceptionsCount := 0;
  FX := 0;
  FY := 0;
  FMinimizedIconX := 0;
  FMinimizedIconY := 0;

  FCraft.SetInDogfight(True);

  // Create objects
  FWindow := TSurface.Create(160, 96, FX, FY);
  FBattle := TSurface.Create(77, 74, FX + 3, FY + 3);
  FWeapon1 := TInteractiveSurface.Create(15, 17, FX + 4, FY + 52);
  FRange1 := TSurface.Create(21, 74, FX + 19, FY + 3);
  FWeapon2 := TInteractiveSurface.Create(15, 17, FX + 64, FY + 52);
  FRange2 := TSurface.Create(21, 74, FX + 43, FY + 3);
  FDamage := TSurface.Create(22, 25, FX + 93, FY + 40);
  FBtnMinimize := TInteractiveSurface.Create(12, 12, FX, FY);
  FPreview := TInteractiveSurface.Create(160, 96, FX, FY);
  FBtnStandoff := TImageButton.Create(36, 15, FX + 83, FY + 4);
  FBtnCautious := TImageButton.Create(36, 15, FX + 120, FY + 4);
  FBtnStandard := TImageButton.Create(36, 15, FX + 83, FY + 20);
  FBtnAggressive := TImageButton.Create(36, 15, FX + 120, FY + 20);
  FBtnDisengage := TImageButton.Create(36, 15, FX + 120, FY + 36);
  FBtnUfo := TImageButton.Create(36, 17, FX + 120, FY + 52);
  FTxtAmmo1 := TText.Create(16, 9, FX + 4, FY + 70);
  FTxtAmmo2 := TText.Create(16, 9, FX + 64, FY + 70);
  FTxtDistance := TText.Create(40, 9, FX + 116, FY + 72);
  FTxtStatus := TText.Create(150, 9, FX + 4, FY + 85);
  FBtnMinimizedIcon := TInteractiveSurface.Create(32, 20, FMinimizedIconX, FMinimizedIconY);
  FTxtInterceptionNumber := TText.Create(16, 9, FMinimizedIconX + 18, FMinimizedIconY + 6);

  FMode := FBtnStandoff;
  FTimer := TTimer.Create(500);
  FTimer.OnTimer := AnimateCraftDamage;

  SetInterface('dogfight');

  Add(FWindow);
  Add(FBattle);
  Add(FWeapon1);
  Add(FRange1);
  Add(FWeapon2);
  Add(FRange2);
  Add(FDamage);
  Add(FBtnMinimize);
  Add(FBtnStandoff, 'standoffButton', 'dogfight', FWindow);
  Add(FBtnCautious, 'cautiousButton', 'dogfight', FWindow);
  Add(FBtnStandard, 'standardButton', 'dogfight', FWindow);
  Add(FBtnAggressive, 'aggressiveButton', 'dogfight', FWindow);
  Add(FBtnDisengage, 'disengageButton', 'dogfight', FWindow);
  Add(FBtnUfo, 'ufoButton', 'dogfight', FWindow);
  Add(FTxtAmmo1, 'numbers', 'dogfight', FWindow);
  Add(FTxtAmmo2, 'numbers', 'dogfight', FWindow);
  Add(FTxtDistance, 'distance', 'dogfight', FWindow);
  Add(FPreview);
  Add(FTxtStatus, 'text', 'dogfight', FWindow);
  Add(FBtnMinimizedIcon);
  Add(FTxtInterceptionNumber, 'minimizedNumber', 'dogfight');

  FBtnStandoff.Invalidate(False);
  FBtnCautious.Invalidate(False);
  FBtnStandard.Invalidate(False);
  FBtnAggressive.Invalidate(False);
  FBtnDisengage.Invalidate(False);
  FBtnUfo.Invalidate(False);

  // Set up objects
  dogfightInterface := Game.Mod.Interface('dogfight');

  graphic := Game.Mod.GetSurface('INTERWIN.DAT');
  graphic.X := 0;
  graphic.Y := 0;
  graphic.Crop := Rect(0, 0, FWindow.Width, FWindow.Height);
  FWindow.DrawRect(FWindow.Bounds, 15);
  graphic.Blit(FWindow);

  FPreview.DrawRect(FWindow.Bounds, 15);
  graphic.Crop := Rect(dogfightInterface.GetElement('previewTop').X,
                       dogfightInterface.GetElement('previewTop').Y,
                       dogfightInterface.GetElement('previewTop').Width,
                       dogfightInterface.GetElement('previewTop').Height);
  graphic.Blit(FPreview);
  graphic.Y := FWindow.Height - dogfightInterface.GetElement('previewBot').Height;
  graphic.Crop := Rect(dogfightInterface.GetElement('previewBot').X,
                       dogfightInterface.GetElement('previewBot').Y,
                       dogfightInterface.GetElement('previewBot').Width,
                       dogfightInterface.GetElement('previewBot').Height);
  graphic.Blit(FPreview);
  if FUfo.Rules.ModSprite = '' then
    graphic.Crop := Rect(dogfightInterface.GetElement('previewMid').X,
                         dogfightInterface.GetElement('previewMid').Y +
                           dogfightInterface.GetElement('previewMid').Height * FUfo.Rules.Sprite,
                         dogfightInterface.GetElement('previewMid').Width,
                         dogfightInterface.GetElement('previewMid').Height)
  else
    graphic := Game.Mod.GetSurface(FUfo.Rules.ModSprite);
  graphic.X := dogfightInterface.GetElement('previewTop').X;
  graphic.Y := dogfightInterface.GetElement('previewTop').Height;
  graphic.Blit(FPreview);
  FPreview.Visible := False;
  FPreview.OnMouseClick := PreviewClick;

  FBtnMinimize.OnMouseClick := BtnMinimizeClick;

  FBtnStandoff.Copy(FWindow);
  FBtnStandoff.Group := FMode;
  FBtnStandoff.OnMousePress := BtnStandoffPress;

  FBtnCautious.Copy(FWindow);
  FBtnCautious.Group := FMode;
  FBtnCautious.OnMousePress := BtnCautiousPress;

  FBtnStandard.Copy(FWindow);
  FBtnStandard.Group := FMode;
  FBtnStandard.OnMousePress := BtnStandardPress;

  FBtnAggressive.Copy(FWindow);
  FBtnAggressive.Group := FMode;
  FBtnAggressive.OnMousePress := BtnAggressivePress;

  FBtnDisengage.Copy(FWindow);
  FBtnDisengage.OnMousePress := BtnDisengagePress;
  FBtnDisengage.Group := FMode;

  FBtnUfo.Copy(FWindow);
  FBtnUfo.OnMouseClick := BtnUfoClick;

  FTxtDistance.Text := '640';
  FTxtStatus.Text := Tr('STR_STANDOFF');

  set := Game.Mod.SurfaceSet('INTICON.PCK');

  // Create minimized icon
  frame := set.GetFrame(FCraft.Rules.Sprite);
  frame.X := 0;
  frame.Y := 0;
  frame.Blit(FBtnMinimizedIcon);
  FBtnMinimizedIcon.OnMouseClick := BtnMinimizedIconClick;
  FBtnMinimizedIcon.Visible := False;

  // Draw number on minimized icon
  if FCraft.InterceptionOrder = 0 then
  begin
    // find max order
    for var b in Game.SavedGame.Bases do
      for var c in b.Crafts do
        if c.InterceptionOrder > FCraft.InterceptionOrder then
          FCraft.InterceptionOrder := c.InterceptionOrder;
    Inc(FCraft.InterceptionOrder);
  end;
  FTxtInterceptionNumber.Text := IntToStr(FCraft.InterceptionOrder);
  FTxtInterceptionNumber.Visible := False;

  // Define colors
  FColors[cnCraftMin] := dogfightInterface.GetElement('craftRange').Color;
  FColors[cnCraftMax] := dogfightInterface.GetElement('craftRange').Color2;
  FColors[cnRadarMin] := dogfightInterface.GetElement('radarRange').Color;
  FColors[cnRadarMax] := dogfightInterface.GetElement('radarRange').Color2;
  FColors[cnDamageMin] := dogfightInterface.GetElement('damageRange').Color;
  FColors[cnDamageMax] := dogfightInterface.GetElement('damageRange').Color2;
  FColors[cnBlobMin] := dogfightInterface.GetElement('radarDetail').Color;
  FColors[cnRangeMeter] := dogfightInterface.GetElement('radarDetail').Color2;
  FColors[cnDisabledWeapon] := dogfightInterface.GetElement('disabledWeapon').Color;
  FColors[cnDisabledAmmo] := dogfightInterface.GetElement('disabledAmmo').Color;
  FColors[cnDisabledRange] := dogfightInterface.GetElement('disabledWeapon').Color2;

  for i := 0 to FCraft.Rules.Weapons - 1 do
  begin
    w := FCraft.Weapons[i];
    if w = nil then Continue;
    if i = 0 then
    begin
      weapon := FWeapon1; range := FRange1; ammo := FTxtAmmo1; x1 := 2; x2 := 0;
    end
    else
    begin
      weapon := FWeapon2; range := FRange2; ammo := FTxtAmmo2; x1 := 0; x2 := 18;
    end;
    frame := set.GetFrame(w.Rules.Sprite + 5);
    frame.X := 0; frame.Y := 0;
    frame.Blit(weapon);
    ammo.Text := IntToStr(w.Ammo);
    // Draw range
    range.Lock;
    for var x := x1 to x1 + 18 step 2 do
      range.SetPixel(x, range.Height - w.Rules.Range, FColors[cnRangeMeter]);
    var connectY := 57;
    if range.Height - w.Rules.Range < connectY then
      for var y := range.Height - w.Rules.Range to connectY do
        range.SetPixel(x1 + x2, y, FColors[cnRangeMeter])
    else
      for var y := connectY to range.Height - w.Rules.Range do
        range.SetPixel(x1 + x2, y, FColors[cnRangeMeter]);
    for var x := x2 to x2 + 2 do
      range.SetPixel(x, connectY, FColors[cnRangeMeter]);
    range.Unlock;
  end;

  if not ((FCraft.Rules.Weapons > 0) and (FCraft.Weapons[0] <> nil)) then
  begin
    FWeapon1.Visible := False; FRange1.Visible := False; FTxtAmmo1.Visible := False;
  end;
  if not ((FCraft.Rules.Weapons > 1) and (FCraft.Weapons[1] <> nil)) then
  begin
    FWeapon2.Visible := False; FRange2.Visible := False; FTxtAmmo2.Visible := False;
  end;

  // Draw damage indicator
  frame := set.GetFrame(FCraft.Rules.Sprite + 11);
  frame.X := 0; frame.Y := 0;
  frame.Blit(FDamage);

  FTimer.Start;

  // UFO escape countdown
  if not FUfo.EscapeCountdown then
  begin
    FUfo.FireCountdown := 0;
    var escape := FUfo.Rules.BreakOffTime + RNG.Generate(0, FUfo.Rules.BreakOffTime) -
                  30 * Game.SavedGame.DifficultyCoefficient;
    FUfo.EscapeCountdown := Max(1, escape);
  end;

  // Weapon intervals
  if (FCraft.Rules.Weapons > 0) and (FCraft.Weapons[0] <> nil) then
    FW1FireInterval := FCraft.Weapons[0].Rules.StandardReload;
  if (FCraft.Rules.Weapons > 1) and (FCraft.Weapons[1] <> nil) then
    FW2FireInterval := FCraft.Weapons[1].Rules.StandardReload;

  // Set UFO size
  var sizeStr := FUfo.Rules.Size;
  if sizeStr = 'STR_VERY_SMALL' then FUfoSize := 0
  else if sizeStr = 'STR_SMALL' then FUfoSize := 1
  else if sizeStr = 'STR_MEDIUM_UC' then FUfoSize := 2
  else if sizeStr = 'STR_LARGE' then FUfoSize := 3
  else FUfoSize := 4;

  // Get craft height for damage
  var cx := FDamage.Width div 2;
  FCraftHeight := 0;
  for var y := 0 to FDamage.Height - 1 do
  begin
    var pixel := FDamage.GetPixel(cx, y);
    if (pixel >= FColors[cnCraftMin]) and (pixel < FColors[cnCraftMax]) then
      Inc(FCraftHeight);
  end;
  DrawCraftDamage;

  FWeapon1.OnMouseClick := Weapon1Click;
  FWeapon2.OnMouseClick := Weapon2Click;

  FProjectiles := TList.Create;
end;

destructor TDogfightState.Destroy;
begin
  FTimer.Free;
  for var i := 0 to FProjectiles.Count - 1 do
    TCraftWeaponProjectile(FProjectiles[i]).Free;
  FProjectiles.Free;
  inherited;
end;

procedure TDogfightState.Think;
begin
  if not FEndDogfight then
  begin
    Update;
    FTimer.Think(Self, 0);
  end;
  if (not FCraft.IsInDogfight) or (FCraft.Destination <> FUfo) or (FUfo.Status = UfoStatus.LANDED) then
    EndDogfight;
end;

procedure TDogfightState.AnimateCraftDamage;
begin
  if FMinimized then Exit;
  Dec(FCurrentCraftDamageColor);
  if FCurrentCraftDamageColor < FColors[cnDamageMin] then
    FCurrentCraftDamageColor := FColors[cnDamageMax];
  DrawCraftDamage;
end;

procedure TDogfightState.DrawCraftDamage;
var
  damagePercentage, rowsToColor, rowsColored: Integer;
begin
  if FCraft.DamagePercentage = 0 then
  begin
    if FTimer.IsRunning then FTimer.Stop;
    Exit;
  end;
  if not FTimer.IsRunning then
    FTimer.Start;
  if FCurrentCraftDamageColor < FColors[cnDamageMin] then
    FCurrentCraftDamageColor := FColors[cnDamageMin];

  damagePercentage := FCraft.DamagePercentage;
  rowsToColor := Floor(FCraftHeight * damagePercentage / 100);
  if rowsToColor = 0 then Exit;

  rowsColored := 0;
  for var y := 0 to FDamage.Height - 1 do
  begin
    var rowColored := False;
    for var x := 0 to FDamage.Width - 1 do
    begin
      var pixel := FDamage.GetPixel(x, y);
      if (pixel >= FColors[cnDamageMin]) and (pixel <= FColors[cnDamageMax]) then
      begin
        FDamage.SetPixel(x, y, FCurrentCraftDamageColor);
        rowColored := True;
      end
      else if (pixel >= FColors[cnCraftMin]) and (pixel < FColors[cnCraftMax]) then
      begin
        FDamage.SetPixel(x, y, FCurrentCraftDamageColor);
        rowColored := True;
      end;
    end;
    if rowColored then Inc(rowsColored);
    if rowsColored = rowsToColor then Break;
  end;
end;

procedure TDogfightState.Animate;
begin
  // Animate radar waves
  for var x := 0 to FWindow.Width - 1 do
    for var y := 0 to FWindow.Height - 1 do
    begin
      var pixel := FWindow.GetPixel(x, y);
      if (pixel >= FColors[cnRadarMin]) and (pixel < FColors[cnRadarMax]) then
      begin
        Inc(pixel);
        if pixel >= FColors[cnRadarMax] then
          pixel := FColors[cnRadarMin];
        FWindow.SetPixel(x, y, pixel);
      end;
    end;

  FBattle.Clear;

  // Draw UFO
  if not FUfo.IsDestroyed then
    DrawUfo;

  // Draw projectiles
  for var i := 0 to FProjectiles.Count - 1 do
    DrawProjectile(TCraftWeaponProjectile(FProjectiles[i]));

  // Clear status text after timeout
  if FTimeout = 0 then
    FTxtStatus.Text := ''
  else
    Dec(FTimeout);

  // Animate UFO hit
  if FAnimatingHit and (FUfo.HitFrame > 0) then
  begin
    FUfo.HitFrame := FUfo.HitFrame - 1;
    if FUfo.HitFrame = 0 then
      FAnimatingHit := False;
  end;

  // Animate UFO crash landing
  if FUfo.IsCrashed and (FUfo.HitFrame = 0) then
    Dec(FUfoSize);
end;

procedure TDogfightState.Update;
var
  finalRun: Boolean;
  projectileInFlight: Boolean;
  distanceChange: Integer;
  i: Integer;
  w: TCraftWeapon;
  wTimer: Integer;
begin
  finalRun := False;
  // Check if craft is low on fuel or destination changed
  var u := FCraft.Destination as TUfo;
  if (u <> FUfo) or not FCraft.IsInDogfight or FCraft.LowFuel or (FMinimized and FUfo.IsCrashed) then
  begin
    EndDogfight;
    Exit;
  end;

  if not FMinimized then
  begin
    Animate;
    if not FUfo.IsCrashed and not FUfo.IsDestroyed and not FCraft.IsDestroyed and not FUfo.InterceptionProcessed then
    begin
      FUfo.InterceptionProcessed := True;
      var escape := FUfo.EscapeCountdown;
      if escape > 0 then
      begin
        Dec(escape);
        FUfo.EscapeCountdown := escape;
        if escape = 0 then
          FUfo.Speed := FUfo.Rules.MaxSpeed;
      end;
      if FUfo.FireCountdown > 0 then
        Dec(FUfo.FireCountdown);
    end;
  end;

  // Check if UFO is outrunning interceptor
  if FUfo.Speed > FCraft.Rules.MaxSpeed then
  begin
    FUfoBreakingOff := True;
    finalRun := True;
    SetStatus('STR_UFO_OUTRUNNING_INTERCEPTOR');
  end
  else
    FUfoBreakingOff := False;

  projectileInFlight := False;

  if not FMinimized then
  begin
    distanceChange := 0;
    if not FUfoBreakingOff then
    begin
      if FCurrentDist < FTargetDist then
      begin
        distanceChange := 4;
        if FCurrentDist + distanceChange > FTargetDist then
          distanceChange := FTargetDist - FCurrentDist;
      end
      else if FCurrentDist > FTargetDist then
        distanceChange := -2;

      // Move projectiles with craft (except beams)
      for var p in FProjectiles do
        if (p.GlobalType <> CWPGT_BEAM) and (p.Direction = D_UP) then
          p.Position := p.Position + distanceChange;
    end
    else
      distanceChange := 4;

    FCurrentDist := FCurrentDist + distanceChange;
    FTxtDistance.Text := IntToStr(FCurrentDist);

    // Move projectiles and check for hits
    i := 0;
    while i < FProjectiles.Count do
    begin
      var p := TCraftWeaponProjectile(FProjectiles[i]);
      p.Move;
      if p.Direction = D_UP then // interceptor projectiles
      begin
        if ((p.Position >= FCurrentDist) or ((p.GlobalType = CWPGT_BEAM) and p.ToBeRemoved)) and not FUfo.IsCrashed and not p.Missed then
        begin
          // UFO hit check
          var acc := (p.Accuracy * (100 + 300 / (5 - FUfoSize)) + 100) div 200;
          if RNG.Percent(acc) then
          begin
            var dmg := RNG.Generate(p.Damage div 2, p.Damage);
            FUfo.Damage := FUfo.Damage + dmg;
            if FUfo.IsCrashed then
            begin
              FUfo.ShotDownByCraftId := FCraft.UniqueId;
              FUfo.Speed := 0;
              FUfo.Destination := nil;
              FUfoBreakingOff := False;
              finalRun := False;
              FEnd := False;
            end;
            if FUfo.HitFrame = 0 then
            begin
              FAnimatingHit := True;
              FUfo.HitFrame := 3;
            end;
            SetStatus('STR_UFO_HIT');
            Game.Mod.GetSound('GEO.CAT', Mod.UFO_HIT).Play;
            p.Remove;
          end
          else
          begin
            if p.GlobalType = CWPGT_BEAM then
              p.Remove
            else
              p.Missed := True;
          end;
        end;
        if (p.GlobalType = CWPGT_MISSILE) and (p.Position div 8 >= p.Range) then
          p.Remove
        else if not FUfo.IsCrashed then
          projectileInFlight := True;
      end
      else if p.Direction = D_DOWN then // UFO projectiles
      begin
        if (p.GlobalType = CWPGT_MISSILE) or ((p.GlobalType = CWPGT_BEAM) and p.ToBeRemoved) then
        begin
          if RNG.Percent(p.Accuracy) then
          begin
            var dmg := RNG.Generate(0, FUfo.Rules.WeaponPower);
            if dmg > 0 then
            begin
              FCraft.Damage := FCraft.Damage + dmg;
              DrawCraftDamage;
              SetStatus('STR_INTERCEPTOR_DAMAGED');
              Game.Mod.GetSound('GEO.CAT', Mod.INTERCEPTOR_HIT).Play;
              if (FMode = FBtnCautious) and (FCraft.DamagePercentage >= 50) then
                FTargetDist := STANDOFF_DIST;
            end;
          end;
          p.Remove;
        end;
      end;
      if p.ToBeRemoved or (p.Missed and (p.Position <= 0)) then
      begin
        p.Free;
        FProjectiles.Delete(i);
      end
      else
        Inc(i);
    end;

    // Handle weapon firing
    for i := 0 to FCraft.Rules.Weapons - 1 do
    begin
      w := FCraft.Weapons[i];
      if w = nil then Continue;
      if i = 0 then wTimer := FW1FireCountdown else wTimer := FW2FireCountdown;
      if (wTimer = 0) and (FCurrentDist <= w.Rules.Range * 8) and (w.Ammo > 0) and
         (FMode <> FBtnStandoff) and (FMode <> FBtnDisengage) and not FUfo.IsCrashed and not FCraft.IsDestroyed then
      begin
        if i = 0 then
        begin
          if FWeapon1Enabled then
          begin
            FireWeapon1;
            projectileInFlight := True;
          end;
        end
        else
        begin
          if FWeapon2Enabled then
          begin
            FireWeapon2;
            projectileInFlight := True;
          end;
        end;
      end
      else if wTimer > 0 then
      begin
        if i = 0 then Dec(FW1FireCountdown) else Dec(FW2FireCountdown);
      end;
      if (w.Ammo = 0) and not projectileInFlight and not FCraft.IsDestroyed then
      begin
        if FMode = FBtnCautious then MinimumDistance
        else if FMode = FBtnStandard then MaximumDistance;
      end;
    end;

    // Handle UFO firing
    if (FCurrentDist <= FUfo.Rules.WeaponRange * 8) and not FUfo.IsCrashed and not FCraft.IsDestroyed then
    begin
      if FUfo.ShootingAt = 0 then
        FUfo.ShootingAt := FInterceptionNumber;
      if FUfo.ShootingAt = FInterceptionNumber then
        if FUfo.FireCountdown = 0 then
          UfoFireWeapon;
    end
    else if FUfo.ShootingAt = FInterceptionNumber then
      FUfo.ShootingAt := 0;
  end;

  // Check when battle is over
  if FEnd and (((FCurrentDist > 640) or FMinimized) and ((FMode = FBtnDisengage) or FUfoBreakingOff) or
      ((FTimeout = 0) and (FUfo.IsCrashed or FCraft.IsDestroyed))) then
  begin
    if FUfoBreakingOff then
    begin
      FUfo.Move;
      FCraft.Destination := FUfo;
    end;
    if not FDestroyCraft and (FDestroyUfo or (FMode = FBtnDisengage)) then
      FCraft.ReturnToBase;
    if FUfo.IsCrashed then
    begin
      for var follower in FUfo.CraftFollowers do
        if (follower.NumSoldiers = 0) and (follower.NumVehicles = 0) then
          follower.ReturnToBase;
    end;
    EndDogfight;
  end;

  if (FCurrentDist > 640) and FUfoBreakingOff then
    finalRun := True;

  if not FEnd then
  begin
    if FCraft.IsDestroyed then
    begin
      SetStatus('STR_INTERCEPTOR_DESTROYED');
      FTimeout := FTimeout + 30;
      Game.Mod.GetSound('GEO.CAT', Mod.INTERCEPTOR_EXPLODE).Play;
      finalRun := True;
      FDestroyCraft := True;
      FUfo.ShootingAt := 0;
    end;
    if FUfo.IsCrashed then
    begin
      var mission := FUfo.Mission;
      mission.UfoShotDown(FUfo);
      var retalOdds := mission.Rules.RetaliationOdds;
      if retalOdds = -1 then
        retalOdds := 100 - (4 * (24 - Game.SavedGame.DifficultyCoefficient));
      if RNG.Percent(retalOdds) then
      begin
        var targetRegion: string;
        if RNG.Percent(50 - 6 * Game.SavedGame.DifficultyCoefficient) then
          targetRegion := FUfo.Mission.Region
        else
          targetRegion := Game.SavedGame.LocateRegion(FCraft.Base).Rules.TypeName;
        if not Assigned(Game.SavedGame.FindAlienMission(targetRegion, OBJECTIVE_RETALIATION)) then
        begin
          var rule := Game.Mod.GetRandomMission(OBJECTIVE_RETALIATION, Game.SavedGame.MonthsPassed);
          var newMission := TAlienMission.Create(rule);
          newMission.Id := Game.SavedGame.GetId('ALIEN_MISSIONS');
          newMission.Region := targetRegion;
          newMission.Race := FUfo.AlienRace;
          newMission.Start(rule.Wave[0].SpawnTimer);
          Game.SavedGame.AlienMissions.Add(newMission);
        end;
      end;
      if FUfo.IsDestroyed then
      begin
        if FUfo.ShotDownByCraftId = FCraft.UniqueId then
        begin
          for var c in Game.SavedGame.Countries do
            if c.Rules.InsideCountry(FUfo.Longitude, FUfo.Latitude) then
            begin
              c.AddActivityXcom(FUfo.Rules.Score * 2);
              Break;
            end;
          for var r in Game.SavedGame.Regions do
            if r.Rules.InsideRegion(FUfo.Longitude, FUfo.Latitude) then
            begin
              r.AddActivityXcom(FUfo.Rules.Score * 2);
              Break;
            end;
          SetStatus('STR_UFO_DESTROYED');
          Game.Mod.GetSound('GEO.CAT', Mod.UFO_EXPLODE).Play;
        end;
        FDestroyUfo := True;
      end
      else
      begin
        if FUfo.ShotDownByCraftId = FCraft.UniqueId then
        begin
          SetStatus('STR_UFO_CRASH_LANDS');
          Game.Mod.GetSound('GEO.CAT', Mod.UFO_CRASH).Play;
          for var c in Game.SavedGame.Countries do
            if c.Rules.InsideCountry(FUfo.Longitude, FUfo.Latitude) then
            begin
              c.AddActivityXcom(FUfo.Rules.Score);
              Break;
            end;
          for var r in Game.SavedGame.Regions do
            if r.Rules.InsideRegion(FUfo.Longitude, FUfo.Latitude) then
            begin
              r.AddActivityXcom(FUfo.Rules.Score);
              Break;
            end;
        end;
        if not FState.Globe.InsideLand(FUfo.Longitude, FUfo.Latitude) then
        begin
          FUfo.Status := UfoStatus.DESTROYED;
          FDestroyUfo := True;
        end
        else
        begin
          FUfo.SecondsRemaining := RNG.Generate(24, 96) * 3600;
          FUfo.Altitude := 'STR_GROUND';
          if FUfo.CrashId = 0 then
            FUfo.CrashId := Game.SavedGame.GetId('STR_CRASH_SITE');
        end;
      end;
      FTimeout := FTimeout + 30;
      if FUfo.ShotDownByCraftId <> FCraft.UniqueId then
      begin
        FTimeout := FTimeout + 50;
        FUfo.HitFrame := 3;
      end;
      finalRun := True;
      if FUfo.Status = UfoStatus.LANDED then
      begin
        FTimeout := FTimeout + 30;
        finalRun := True;
        FUfo.ShootingAt := 0;
      end;
    end;
  end;

  if not projectileInFlight and finalRun then
    FEnd := True;
end;

procedure TDogfightState.FireWeapon1;
var
  w: TCraftWeapon;
begin
  w := FCraft.Weapons[0];
  if w = nil then Exit;
  if w.SetAmmo(w.Ammo - 1) then
  begin
    FW1FireCountdown := FW1FireInterval;
    FTxtAmmo1.Text := IntToStr(w.Ammo);
    var p := w.Fire;
    p.Direction := D_UP;
    p.HorizontalPosition := HP_LEFT;
    FProjectiles.Add(p);
    Game.Mod.GetSound('GEO.CAT', w.Rules.Sound).Play;
  end;
end;

procedure TDogfightState.FireWeapon2;
var
  w: TCraftWeapon;
begin
  w := FCraft.Weapons[1];
  if w = nil then Exit;
  if w.SetAmmo(w.Ammo - 1) then
  begin
    FW2FireCountdown := FW2FireInterval;
    FTxtAmmo2.Text := IntToStr(w.Ammo);
    var p := w.Fire;
    p.Direction := D_UP;
    p.HorizontalPosition := HP_RIGHT;
    FProjectiles.Add(p);
    Game.Mod.GetSound('GEO.CAT', w.Rules.Sound).Play;
  end;
end;

procedure TDogfightState.UfoFireWeapon;
begin
  var fireCountdown := Max(1, (FUfo.Rules.WeaponReload - 2 * Game.SavedGame.DifficultyCoefficient));
  FUfo.FireCountdown := RNG.Generate(0, fireCountdown) + fireCountdown;
  SetStatus('STR_UFO_RETURN_FIRE');
  var p := TCraftWeaponProjectile.Create;
  p.Type := CWPT_PLASMA_BEAM;
  p.Accuracy := 60;
  p.Damage := FUfo.Rules.WeaponPower;
  p.Direction := D_DOWN;
  p.HorizontalPosition := HP_CENTER;
  p.Position := FCurrentDist - (FUfo.Rules.Radius div 2);
  FProjectiles.Add(p);
  Game.Mod.GetSound('GEO.CAT', Mod.UFO_FIRE).Play;
end;

procedure TDogfightState.MinimumDistance;
var
  maxRange: Integer;
begin
  maxRange := 0;
  for var w in FCraft.Weapons do
    if (w <> nil) and (w.Rules.Range > maxRange) and (w.Ammo > 0) then
      maxRange := w.Rules.Range;
  if maxRange = 0 then
    FTargetDist := STANDOFF_DIST
  else
    FTargetDist := maxRange * 8;
end;

procedure TDogfightState.MaximumDistance;
var
  minRange: Integer;
begin
  minRange := 1000;
  for var w in FCraft.Weapons do
    if (w <> nil) and (w.Rules.Range < minRange) and (w.Ammo > 0) then
      minRange := w.Rules.Range;
  if minRange = 1000 then
    FTargetDist := STANDOFF_DIST
  else
    FTargetDist := minRange * 8;
end;

procedure TDogfightState.SetStatus(const AStatus: string);
begin
  FTxtStatus.Text := Tr(AStatus);
  FTimeout := 50;
end;

procedure TDogfightState.BtnMinimizeClick(AAction: TAction);
begin
  if not FUfo.IsCrashed and not FCraft.IsDestroyed and not FUfoBreakingOff then
  begin
    if FCurrentDist >= STANDOFF_DIST then
      SetMinimized(True)
    else
      SetStatus('STR_MINIMISE_AT_STANDOFF_RANGE_ONLY');
  end;
end;

procedure TDogfightState.BtnStandoffPress(AAction: TAction);
begin
  if not FUfo.IsCrashed and not FCraft.IsDestroyed and not FUfoBreakingOff then
  begin
    FEnd := False;
    SetStatus('STR_STANDOFF');
    FTargetDist := STANDOFF_DIST;
  end;
end;

procedure TDogfightState.BtnCautiousPress(AAction: TAction);
begin
  if not FUfo.IsCrashed and not FCraft.IsDestroyed and not FUfoBreakingOff then
  begin
    FEnd := False;
    SetStatus('STR_CAUTIOUS_ATTACK');
    if (FCraft.Rules.Weapons > 0) and (FCraft.Weapons[0] <> nil) then
      FW1FireInterval := FCraft.Weapons[0].Rules.CautiousReload;
    if (FCraft.Rules.Weapons > 1) and (FCraft.Weapons[1] <> nil) then
      FW2FireInterval := FCraft.Weapons[1].Rules.CautiousReload;
    MinimumDistance;
  end;
end;

procedure TDogfightState.BtnStandardPress(AAction: TAction);
begin
  if not FUfo.IsCrashed and not FCraft.IsDestroyed and not FUfoBreakingOff then
  begin
    FEnd := False;
    SetStatus('STR_STANDARD_ATTACK');
    if (FCraft.Rules.Weapons > 0) and (FCraft.Weapons[0] <> nil) then
      FW1FireInterval := FCraft.Weapons[0].Rules.StandardReload;
    if (FCraft.Rules.Weapons > 1) and (FCraft.Weapons[1] <> nil) then
      FW2FireInterval := FCraft.Weapons[1].Rules.StandardReload;
    MaximumDistance;
  end;
end;

procedure TDogfightState.BtnAggressivePress(AAction: TAction);
begin
  if not FUfo.IsCrashed and not FCraft.IsDestroyed and not FUfoBreakingOff then
  begin
    FEnd := False;
    SetStatus('STR_AGGRESSIVE_ATTACK');
    if (FCraft.Rules.Weapons > 0) and (FCraft.Weapons[0] <> nil) then
      FW1FireInterval := FCraft.Weapons[0].Rules.AggressiveReload;
    if (FCraft.Rules.Weapons > 1) and (FCraft.Weapons[1] <> nil) then
      FW2FireInterval := FCraft.Weapons[1].Rules.AggressiveReload;
    FTargetDist := 64;
  end;
end;

procedure TDogfightState.BtnDisengagePress(AAction: TAction);
begin
  if not FUfo.IsCrashed and not FCraft.IsDestroyed and not FUfoBreakingOff then
  begin
    FEnd := True;
    SetStatus('STR_DISENGAGING');
    FTargetDist := 800;
  end;
end;

procedure TDogfightState.BtnUfoClick(AAction: TAction);
begin
  FPreview.Visible := True;
  FBtnStandoff.Visible := False;
  FBtnCautious.Visible := False;
  FBtnStandard.Visible := False;
  FBtnAggressive.Visible := False;
  FBtnDisengage.Visible := False;
  FBtnUfo.Visible := False;
  FBtnMinimize.Visible := False;
  FWeapon1.Visible := False;
  FWeapon2.Visible := False;
end;

procedure TDogfightState.PreviewClick(AAction: TAction);
begin
  FPreview.Visible := False;
  FBtnStandoff.Visible := True;
  FBtnCautious.Visible := True;
  FBtnStandard.Visible := True;
  FBtnAggressive.Visible := True;
  FBtnDisengage.Visible := True;
  FBtnUfo.Visible := True;
  FBtnMinimize.Visible := True;
  FWeapon1.Visible := True;
  FWeapon2.Visible := True;
end;

procedure TDogfightState.DrawUfo;
var
  x, y: Integer;
  pixelOffset: Integer;
  radarPixelColor, color: Byte;
begin
  if (FUfoSize < 0) or FUfo.IsDestroyed then Exit;
  var ufoX := FBattle.Width div 2 - 6;
  var ufoY := FBattle.Height - (FCurrentDist div 8) - 6;
  for y := 0 to 12 do
    for x := 0 to 12 do
    begin
      pixelOffset := UfoBlobs[FUfoSize + FUfo.HitFrame][y][x];
      if pixelOffset = 0 then Continue;
      if FUfo.IsCrashed or (FUfo.HitFrame > 0) then
        pixelOffset := pixelOffset * 2;
      radarPixelColor := FWindow.GetPixel(ufoX + x + 3, ufoY + y + 3);
      color := radarPixelColor - pixelOffset;
      if color < FColors[cnBlobMin] then
        color := FColors[cnBlobMin];
      FBattle.SetPixel(ufoX + x, ufoY + y, color);
    end;
end;

procedure TDogfightState.DrawProjectile(p: TCraftWeaponProjectile);
var
  xPos, yPos: Integer;
  pixelOffset: Integer;
  radarPixelColor, color: Byte;
begin
  xPos := FBattle.Width div 2 + p.HorizontalPosition;
  if p.GlobalType = CWPGT_MISSILE then
  begin
    xPos := xPos - 1;
    yPos := FBattle.Height - (p.Position div 8);
    for var y := 0 to 5 do
      for var x := 0 to 2 do
      begin
        pixelOffset := ProjectileBlobs[p.Type][y][x];
        if pixelOffset = 0 then Continue;
        radarPixelColor := FWindow.GetPixel(xPos + x + 3, yPos + y + 3);
        color := radarPixelColor - pixelOffset;
        if color < FColors[cnBlobMin] then
          color := FColors[cnBlobMin];
        FBattle.SetPixel(xPos + x, yPos + y, color);
      end;
  end
  else if p.GlobalType = CWPGT_BEAM then
  begin
    var yStart := FBattle.Height - 2;
    var yEnd := FBattle.Height - (FCurrentDist div 8);
    for var y := yStart downto yEnd do
    begin
      radarPixelColor := FWindow.GetPixel(xPos + 3, y + 3);
      color := radarPixelColor - p.State;
      if color < FColors[cnBlobMin] then
        color := FColors[cnBlobMin];
      FBattle.SetPixel(xPos, y, color);
    end;
  end;
end;

procedure TDogfightState.Weapon1Click(AAction: TAction);
begin
  FWeapon1Enabled := not FWeapon1Enabled;
  Recolor(0, FWeapon1Enabled);
end;

procedure TDogfightState.Weapon2Click(AAction: TAction);
begin
  FWeapon2Enabled := not FWeapon2Enabled;
  Recolor(1, FWeapon2Enabled);
end;

procedure TDogfightState.Recolor(WeaponNo: Integer; CurrentState: Boolean);
var
  weapon: TInteractiveSurface;
  ammo: TText;
  range: TSurface;
begin
  if WeaponNo = 0 then
  begin
    weapon := FWeapon1; ammo := FTxtAmmo1; range := FRange1;
  end
  else if WeaponNo = 1 then
  begin
    weapon := FWeapon2; ammo := FTxtAmmo2; range := FRange2;
  end
  else
    Exit;

  if CurrentState then
  begin
    weapon.Offset(-FColors[cnDisabledWeapon]);
    ammo.Offset(-FColors[cnDisabledAmmo]);
    range.Offset(-FColors[cnDisabledRange]);
  end
  else
  begin
    weapon.Offset(FColors[cnDisabledWeapon]);
    ammo.Offset(FColors[cnDisabledAmmo]);
    range.Offset(FColors[cnDisabledRange]);
  end;
end;

function TDogfightState.IsMinimized: Boolean;
begin
  Result := FMinimized;
end;

procedure TDogfightState.SetMinimized(Minimized: Boolean);
begin
  FMinimized := Minimized;
  FBtnMinimizedIcon.Visible := Minimized;
  FTxtInterceptionNumber.Visible := Minimized;
  FWindow.Visible := not Minimized;
  FBtnStandoff.Visible := not Minimized;
  FBtnCautious.Visible := not Minimized;
  FBtnStandard.Visible := not Minimized;
  FBtnAggressive.Visible := not Minimized;
  FBtnDisengage.Visible := not Minimized;
  FBtnUfo.Visible := not Minimized;
  FBtnMinimize.Visible := not Minimized;
  FBattle.Visible := not Minimized;
  FWeapon1.Visible := not Minimized;
  FRange1.Visible := not Minimized;
  FWeapon2.Visible := not Minimized;
  FRange2.Visible := not Minimized;
  FDamage.Visible := not Minimized;
  FTxtAmmo1.Visible := not Minimized;
  FTxtAmmo2.Visible := not Minimized;
  FTxtDistance.Visible := not Minimized;
  FTxtStatus.Visible := not Minimized;
  FPreview.Visible := False;
end;

procedure TDogfightState.BtnMinimizedIconClick(AAction: TAction);
begin
  if FCraft.Rules.IsWaterOnly and (FUfo.AltitudeInt > FCraft.Rules.MaxAltitude) then
  begin
    FState.Popup(TDogfightErrorState.Create(FCraft, Tr('STR_UNABLE_TO_ENGAGE_DEPTH')));
    SetWaitForAltitude(True);
  end
  else if FCraft.Rules.IsWaterOnly and not FState.Globe.InsideLand(FCraft.Longitude, FCraft.Latitude) then
  begin
    FState.Popup(TDogfightErrorState.Create(FCraft, Tr('STR_UNABLE_TO_ENGAGE_AIRBORNE')));
    SetWaitForPoly(True);
  end
  else
    SetMinimized(False);
end;

procedure TDogfightState.SetInterceptionNumber(Number: Integer);
begin
  FInterceptionNumber := Number;
end;

procedure TDogfightState.SetInterceptionsCount(Count: Integer);
begin
  FInterceptionsCount := Count;
  CalculateWindowPosition;
  MoveWindow;
end;

procedure TDogfightState.CalculateWindowPosition;
begin
  FMinimizedIconX := 5;
  FMinimizedIconY := (5 * FInterceptionNumber) + (16 * (FInterceptionNumber - 1));

  if FInterceptionsCount = 1 then
  begin
    FX := 80; FY := 52;
  end
  else if FInterceptionsCount = 2 then
  begin
    if FInterceptionNumber = 1 then
      FX := 80; FY := 0
    else
      FX := 80; FY := 200 - FWindow.Height;
  end
  else if FInterceptionsCount = 3 then
  begin
    if FInterceptionNumber = 1 then
      FX := 80; FY := 0
    else if FInterceptionNumber = 2 then
      FX := 0; FY := 200 - FWindow.Height
    else
      FX := 320 - FWindow.Width; FY := 200 - FWindow.Height;
  end
  else
  begin
    if FInterceptionNumber = 1 then
      FX := 0; FY := 0
    else if FInterceptionNumber = 2 then
      FX := 320 - FWindow.Width; FY := 0
    else if FInterceptionNumber = 3 then
      FX := 0; FY := 200 - FWindow.Height
    else
      FX := 320 - FWindow.Width; FY := 200 - FWindow.Height;
  end;
  FX := FX + Game.Screen.DX;
  FY := FY + Game.Screen.DY;
end;

procedure TDogfightState.MoveWindow;
var
  dx, dy: Integer;
begin
  dx := FWindow.X - FX;
  dy := FWindow.Y - FY;
  for var surf in FSurfaces do
  begin
    surf.X := surf.X - dx;
    surf.Y := surf.Y - dy;
  end;
  FBtnMinimizedIcon.X := FMinimizedIconX;
  FBtnMinimizedIcon.Y := FMinimizedIconY;
  FTxtInterceptionNumber.X := FMinimizedIconX + 18;
  FTxtInterceptionNumber.Y := FMinimizedIconY + 6;
end;

function TDogfightState.DogfightEnded: Boolean;
begin
  Result := FEndDogfight;
end;

function TDogfightState.GetUfo: TUfo;
begin
  Result := FUfo;
end;

function TDogfightState.GetCraft: TCraft;
begin
  Result := FCraft;
end;

function TDogfightState.GetInterceptionNumber: Integer;
begin
  Result := FInterceptionNumber;
end;

procedure TDogfightState.SetWaitForPoly(Wait: Boolean);
begin
  FWaitForPoly := Wait;
end;

function TDogfightState.GetWaitForPoly: Boolean;
begin
  Result := FWaitForPoly;
end;

procedure TDogfightState.SetWaitForAltitude(Wait: Boolean);
begin
  FWaitForAltitude := Wait;
end;

function TDogfightState.GetWaitForAltitude: Boolean;
begin
  Result := FWaitForAltitude;
end;

procedure TDogfightState.EndDogfight;
begin
  if FEndDogfight then Exit;
  if Assigned(FCraft) then
  begin
    FCraft.SetInDogfight(False);
    FCraft.InterceptionOrder := 0;
  end;
  if Assigned(FUfo) then
    FUfo.InterceptionProcessed := False;
  FEndDogfight := True;
end;

end.