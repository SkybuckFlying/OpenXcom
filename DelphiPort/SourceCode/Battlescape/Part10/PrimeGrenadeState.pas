unit PrimeGrenadeState;

interface

uses
  Classes, SysUtils,
  Engine.State,
  Engine.Game,
  Engine.Action,
  Engine.Language,
  Engine.InteractiveSurface,
  Interface.Text,
  Interface.Frame,
  Savegame.BattleItem,
  Savegame.SavedGame,
  Savegame.SavedBattleGame,
  Mod.Mod,
  Mod.RuleInterface,
  Battlescape.BattlescapeGame;

type
  TPrimeGrenadeState = class(TState)
  private
    FAction: PBattleAction;
    FInInventoryView: Boolean;
    FGrenadeInInventory: TBattleItem;
    FNumber: array[0..23] of TText;
    FTitle: TText;
    FFrame: TFrame;
    FButton: array[0..23] of TInteractiveSurface;
    FBg: TSurface;
    procedure BtnClick(Action: TAction);
  public
    constructor Create(Action: PBattleAction; InInventoryView: Boolean; GrenadeInInventory: TBattleItem);
    destructor Destroy; override;
    procedure Handle(Action: TAction); override;
  end;

implementation

{ TPrimeGrenadeState }

constructor TPrimeGrenadeState.Create(Action: PBattleAction; InInventoryView: Boolean; GrenadeInInventory: TBattleItem);
var
  I: Integer;
  X, Y: Integer;
  Square: TSDL_Rect;
  SS: TStringStream;
begin
  inherited Create;
  FAction := Action;
  FInInventoryView := InInventoryView;
  FGrenadeInInventory := GrenadeInInventory;
  Screen := False;

  FTitle := TText.Create(192, 24, 65, 44);
  FFrame := TFrame.Create(192, 27, 65, 37);
  FBg := TSurface.Create(192, 93, 65, 45);

  for I := 0 to 23 do
  begin
    X := 67 + (I mod 8) * 24;
    Y := 68 + (I div 8) * 25;
    FButton[I] := TInteractiveSurface.Create(22, 22, X-1, Y-4);
    FNumber[I] := TText.Create(20, 20, X, Y-1);
  end;

  if InInventoryView then
    SetPalette('PAL_BATTLESCAPE')
  else
    FGame.SavedGame.SavedBattle.SetPaletteByDepth(Self);

  Add(FBg);
  FBg.DrawRect(0, 0, FBg.Width, FBg.Height,
               FGame.Mod.Interface['battlescape'].Element['grenadeBackground'].Color);

  Add(FFrame, 'grenadeMenu', 'battlescape');
  FFrame.Thickness := 3;
  FFrame.HighContrast := True;

  Add(FTitle, 'grenadeMenu', 'battlescape');
  FTitle.Align := ALIGN_CENTER;
  FTitle.Big := True;
  FTitle.Text := Tr('STR_SET_TIMER');
  FTitle.HighContrast := True;

  for I := 0 to 23 do
  begin
    Add(FButton[I]);
    FButton[I].OnMouseClick := BtnClick;
    Square.x := 0; Square.y := 0;
    Square.w := FButton[I].Width;
    Square.h := FButton[I].Height;
    FButton[I].DrawRect(@Square, FGame.Mod.Interface['battlescape'].Element['grenadeBackground'].Border);
    Square.x := 1; Square.y := 1;
    Square.w := Square.w - 2;
    Square.h := Square.h - 2;
    FButton[I].DrawRect(@Square, FGame.Mod.Interface['battlescape'].Element['grenadeBackground'].Color2);

    SS := TStringStream.Create('');
    SS.WriteString(IntToStr(I));
    Add(FNumber[I], 'grenadeMenu', 'battlescape');
    FNumber[I].Big := True;
    FNumber[I].Text := SS.DataString;
    FNumber[I].HighContrast := True;
    FNumber[I].Align := ALIGN_CENTER;
    FNumber[I].VerticalAlign := ALIGN_MIDDLE;
    SS.Free;
  end;

  CenterAllSurfaces;
  LowerAllSurfaces;
end;

destructor TPrimeGrenadeState.Destroy;
begin
  inherited;
end;

procedure TPrimeGrenadeState.Handle(Action: TAction);
begin
  inherited;
  if (Action.Details.Type_ = SDL_MOUSEBUTTONDOWN) and (Action.Details.Button.Button = SDL_BUTTON_RIGHT) then
  begin
    if not FInInventoryView then FAction.Value := -1;
    FGame.PopState;
  end;
end;

procedure TPrimeGrenadeState.BtnClick(Action: TAction);
var
  BtnID: Integer;
  I: Integer;
begin
  if Action.Details.Button.Button = SDL_BUTTON_RIGHT then
  begin
    if not FInInventoryView then FAction.Value := -1;
    FGame.PopState;
    Exit;
  end;

  BtnID := -1;
  for I := 0 to 23 do
    if Action.Sender = FButton[I] then
    begin
      BtnID := I;
      Break;
    end;

  if BtnID <> -1 then
  begin
    if FInInventoryView then
      FGrenadeInInventory.FuseTimer := 0 + BtnID
    else
      FAction.Value := BtnID;
    FGame.PopState;
    if not FInInventoryView then FGame.PopState;
  end;
end;

end.