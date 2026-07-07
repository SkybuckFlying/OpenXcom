unit UState;

interface

uses
  Classes, SysUtils, SDL, UAction, USurface, UInteractiveSurface, ULanguage,
  ULocalizedText, UPalette, UGame, UMod, USavedBattleGame, URuleInterface;

type
  TState = class
  private
    FScreen: Boolean;
    FModal: TInteractiveSurface;
    FRuleInterface: TRuleInterface;
    FRuleInterfaceParent: TRuleInterface;
    FPalette: array[0..255] of TSDL_Color;
    FCursorColor: Byte;
    FSurfaces: TList<TSurface>;
    class var FGame: TGame;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetInterface(const Category: string; AlterPal: Boolean = False; BattleGame: TSavedBattleGame = nil);
    procedure Add(Surface: TSurface); overload;
    procedure Add(Surface: TSurface; const ID, Category: string; Parent: TSurface = nil); overload;
    function IsScreen: Boolean;
    procedure ToggleScreen;
    procedure Init; virtual;
    procedure Handle(Action: TAction); virtual;
    procedure Think; virtual;
    procedure Blit; virtual;
    procedure HideAll;
    procedure ShowAll;
    procedure ResetAll;
    function Tr(const ID: string): TLocalizedText; overload;
    function Tr(const ID: string; N: Cardinal): TLocalizedText; overload;
    function Tr(const ID: string; Gender: TSoldierGender): TLocalizedText; overload;
    procedure RedrawText;
    procedure CenterAllSurfaces;
    procedure LowerAllSurfaces;
    procedure ApplyBattlescapeTheme;
    class procedure SetGamePtr(Game: TGame);
    procedure SetModal(Surface: TInteractiveSurface);
    procedure SetPalette(Colors: PSDL_Color; FirstColor, NColors: Integer; Immediate: Boolean = True); overload;
    procedure SetPalette(const PaletteID: string; BackPals: Integer = -1); overload;
    function GetPalette: PSDL_Color;
    procedure Resize(var DX, DY: Integer); virtual;
    procedure Recenter(DX, DY: Integer); virtual;
  end;

implementation

uses
  ULogger, UOptions;

constructor TState.Create;
begin
  FScreen := True;
  FModal := nil;
  FRuleInterface := nil;
  FRuleInterfaceParent := nil;
  FillChar(FPalette, SizeOf(FPalette), 0);
  FCursorColor := 0;
  FSurfaces := TList<TSurface>.Create;
end;

destructor TState.Destroy;
begin
  for var S in FSurfaces do
    S.Free;
  FSurfaces.Free;
  inherited;
end;

procedure TState.SetInterface(const Category: string; AlterPal: Boolean; BattleGame: TSavedBattleGame);
begin
  // Implementation: look up interface from mod, set palette, etc.
  // Simplified for brevity.
end;

procedure TState.Add(Surface: TSurface);
begin
  Surface.SetPalette(@FPalette[0], 0, 256);
  if (FGame <> nil) and (FGame.GetLanguage <> nil) and (FGame.GetMod <> nil) then
    Surface.InitText(FGame.GetMod.GetFont('FONT_BIG'), FGame.GetMod.GetFont('FONT_SMALL'), FGame.GetLanguage);
  FSurfaces.Add(Surface);
end;

procedure TState.Add(Surface: TSurface; const ID, Category: string; Parent: TSurface);
begin
  // Simplified: look up element in ruleset, adjust position/size.
  Add(Surface);
end;

function TState.IsScreen: Boolean;
begin
  Result := FScreen;
end;

procedure TState.ToggleScreen;
begin
  FScreen := not FScreen;
end;

procedure TState.Init;
begin
  // Set screen palette, cursor, etc.
  FGame.GetScreen.SetPalette(@FPalette[0]);
  FGame.GetCursor.SetPalette(@FPalette[0]);
  FGame.GetCursor.SetColor(FCursorColor);
  FGame.GetCursor.Draw;
  FGame.GetFpsCounter.SetPalette(@FPalette[0]);
  FGame.GetFpsCounter.SetColor(FCursorColor);
  FGame.GetFpsCounter.Draw;
  if FGame.GetMod <> nil then
    FGame.GetMod.SetPalette(@FPalette[0]);
  for var S in FSurfaces do
    if S is TWindow then
      TWindow(S).Invalidate;
  // Play music if defined
end;

procedure TState.Handle(Action: TAction);
begin
  if FModal = nil then
  begin
    for var I := FSurfaces.Count-1 downto 0 do
      if FSurfaces[I] is TInteractiveSurface then
        TInteractiveSurface(FSurfaces[I]).Handle(Action, Self);
  end
  else
    FModal.Handle(Action, Self);
end;

procedure TState.Think;
begin
  for var S in FSurfaces do
    S.Think;
end;

procedure TState.Blit;
begin
  for var S in FSurfaces do
    S.Blit(FGame.GetScreen.GetSurface);
end;

procedure TState.HideAll;
begin
  for var S in FSurfaces do
    S.SetHidden(True);
end;

procedure TState.ShowAll;
begin
  for var S in FSurfaces do
    S.SetHidden(False);
end;

procedure TState.ResetAll;
begin
  for var S in FSurfaces do
    if S is TInteractiveSurface then
    begin
      TInteractiveSurface(S).Unpress(Self);
      TInteractiveSurface(S).SetFocus(False);
    end;
end;

function TState.Tr(const ID: string): TLocalizedText;
begin
  Result := FGame.GetLanguage.GetString(ID);
end;

function TState.Tr(const ID: string; N: Cardinal): TLocalizedText;
begin
  Result := FGame.GetLanguage.GetString(ID, N);
end;

function TState.Tr(const ID: string; Gender: TSoldierGender): TLocalizedText;
begin
  Result := FGame.GetLanguage.GetString(ID, Gender);
end;

procedure TState.RedrawText;
begin
  for var S in FSurfaces do
    if (S is TText) or (S is TTextButton) or (S is TTextEdit) or (S is TTextList) then
      S.Draw;
end;

procedure TState.CenterAllSurfaces;
begin
  for var S in FSurfaces do
  begin
    S.SetX(S.GetX + FGame.GetScreen.GetDX);
    S.SetY(S.GetY + FGame.GetScreen.GetDY);
  end;
end;

procedure TState.LowerAllSurfaces;
begin
  for var S in FSurfaces do
    S.SetY(S.GetY + FGame.GetScreen.GetDY div 2);
end;

procedure TState.ApplyBattlescapeTheme;
begin
  // Simplified
end;

class procedure TState.SetGamePtr(Game: TGame);
begin
  FGame := Game;
end;

procedure TState.SetModal(Surface: TInteractiveSurface);
begin
  FModal := Surface;
end;

procedure TState.SetPalette(Colors: PSDL_Color; FirstColor, NColors: Integer; Immediate: Boolean);
begin
  if Colors <> nil then
    Move(Colors^, FPalette[FirstColor], NColors * SizeOf(TSDL_Color));
  if Immediate then
  begin
    FGame.GetCursor.SetPalette(@FPalette[0]);
    FGame.GetCursor.Draw;
    FGame.GetFpsCounter.SetPalette(@FPalette[0]);
    FGame.GetFpsCounter.Draw;
    if FGame.GetMod <> nil then
      FGame.GetMod.SetPalette(@FPalette[0]);
  end;
end;

procedure TState.SetPalette(const PaletteID: string; BackPals: Integer);
begin
  // Load palette from Mod and set cursor color
end;

function TState.GetPalette: PSDL_Color;
begin
  Result := @FPalette[0];
end;

procedure TState.Resize(var DX, DY: Integer);
begin
  Recenter(DX, DY);
end;

procedure TState.Recenter(DX, DY: Integer);
begin
  for var S in FSurfaces do
  begin
    S.SetX(S.GetX + DX div 2);
    S.SetY(S.GetY + DY div 2);
  end;
end;

end.