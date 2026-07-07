unit Camera;

interface

uses
  System.SysUtils, System.Math,
  Position, Engine.Timer, Engine.Action, Engine.State,
  Battlescape.Map, Engine.Options;

type
  TCamera = class
  private
    FScrollMouseTimer: TTimer;
    FScrollKeyTimer: TTimer;
    FSpriteWidth: Integer;
    FSpriteHeight: Integer;
    FMapsizeX: Integer;
    FMapsizeY: Integer;
    FMapsizeZ: Integer;
    FScreenWidth: Integer;
    FScreenHeight: Integer;
    FMapOffset: TPosition;
    FCenter: TPosition;
    FScrollMouseX: Integer;
    FScrollMouseY: Integer;
    FScrollKeyX: Integer;
    FScrollKeyY: Integer;
    FScrollTrigger: Boolean;
    FVisibleMapHeight: Integer;
    FShowAllLayers: Boolean;
    FMap: TMap;
  public
    const SCROLL_BORDER = 5;
    const SCROLL_DIAGONAL_EDGE = 60;
    constructor Create(SpriteWidth, SpriteHeight, MapsizeX, MapsizeY, MapsizeZ: Integer; AMap: TMap; VisibleMapHeight: Integer);
    destructor Destroy; override;
    procedure SetScrollTimer(Mouse, Key: TTimer);
    procedure MousePress(AAction: TAction; AState: TState);
    procedure MouseRelease(AAction: TAction; AState: TState);
    procedure MouseOver(AAction: TAction; AState: TState);
    procedure KeyboardPress(AAction: TAction; AState: TState);
    procedure KeyboardRelease(AAction: TAction; AState: TState);
    procedure ScrollMouse;
    procedure ScrollKey;
    procedure ScrollXY(X, Y: Integer; Redraw: Boolean);
    procedure JumpXY(X, Y: Integer);
    procedure Up;
    procedure Down;
    procedure SetViewLevel(ViewLevel: Integer);
    procedure ConvertMapToScreen(MapPos: TPosition; var ScreenPos: TPosition);
    procedure ConvertVoxelToScreen(VoxelPos: TPosition; var ScreenPos: TPosition);
    procedure ConvertScreenToMap(ScreenX, ScreenY: Integer; var MapX, MapY: Integer);
    procedure CenterOnPosition(Pos: TPosition; Redraw: Boolean = True);
    function GetCenterPosition: TPosition;
    function GetViewLevel: Integer;
    function GetMapSizeX: Integer;
    function GetMapSizeY: Integer;
    function GetMapOffset: TPosition;
    procedure SetMapOffset(const Pos: TPosition);
    function ToggleShowAllLayers: Integer;
    function GetShowAllLayers: Boolean;
    function IsOnScreen(MapPos: TPosition; UnitWalking: Boolean; UnitSize: Integer; Boundary: Boolean): Boolean;
    procedure Resize;
    procedure StopMouseScrolling;
  end;

implementation

uses
  fmath;

constructor TCamera.Create(SpriteWidth, SpriteHeight, MapsizeX, MapsizeY, MapsizeZ: Integer; AMap: TMap; VisibleMapHeight: Integer);
begin
  inherited Create;
  FSpriteWidth := SpriteWidth;
  FSpriteHeight := SpriteHeight;
  FMapsizeX := MapsizeX;
  FMapsizeY := MapsizeY;
  FMapsizeZ := MapsizeZ;
  FMap := AMap;
  FVisibleMapHeight := VisibleMapHeight;
  FScreenWidth := FMap.GetWidth;
  FScreenHeight := FMap.GetHeight;
  FMapOffset := Position(-250, 250, 0);
  FShowAllLayers := False;
  FScrollMouseX := 0;
  FScrollMouseY := 0;
  FScrollKeyX := 0;
  FScrollKeyY := 0;
  FScrollTrigger := False;
  FScrollMouseTimer := nil;
  FScrollKeyTimer := nil;
end;

destructor TCamera.Destroy;
begin
  inherited;
end;

procedure TCamera.SetScrollTimer(Mouse, Key: TTimer);
begin
  FScrollMouseTimer := Mouse;
  FScrollKeyTimer := Key;
end;

procedure TCamera.MousePress(AAction: TAction; AState: TState);
begin
  if (AAction.GetDetails.button.button = SDL_BUTTON_LEFT) and (Options.BattleEdgeScroll = SCROLL_TRIGGER) then
  begin
    FScrollTrigger := True;
    MouseOver(AAction, AState);
  end
  else if (Options.BattleDragScrollButton <> SDL_BUTTON_MIDDLE) or
          ((SDL_GetMouseState(0,0) and SDL_BUTTON(Options.BattleDragScrollButton)) = 0) then
  begin
    if AAction.GetDetails.button.button = SDL_BUTTON_WHEELUP then
      Up
    else if AAction.GetDetails.button.button = SDL_BUTTON_WHEELDOWN then
      Down;
  end;
end;

procedure TCamera.MouseRelease(AAction: TAction; AState: TState);
var
  PosX, PosY: Integer;
begin
  if (AAction.GetDetails.button.button = SDL_BUTTON_LEFT) and (Options.BattleEdgeScroll = SCROLL_TRIGGER) then
  begin
    FScrollMouseX := 0;
    FScrollMouseY := 0;
    FScrollMouseTimer.Stop;
    FScrollTrigger := False;
    PosX := AAction.GetXMouse;
    PosY := AAction.GetYMouse;
    if ((PosX < (SCROLL_BORDER * AAction.GetXScale)) and (PosX > 0)) or
       ((PosX > (FScreenWidth - SCROLL_BORDER) * AAction.GetXScale)) or
       ((PosY < (SCROLL_BORDER * AAction.GetYScale)) and (PosY > 0)) or
       ((PosY > (FScreenHeight - SCROLL_BORDER) * AAction.GetYScale)) then
      AAction.GetDetails.button.button := 0;
  end;
end;

procedure TCamera.MouseOver(AAction: TAction; AState: TState);
var
  PosX, PosY, ScrollSpeed: Integer;
begin
  if FMap.GetCursorType = CT_NONE then Exit;
  if (Options.BattleEdgeScroll <> SCROLL_AUTO) and (not FScrollTrigger) then Exit;

  PosX := AAction.GetXMouse;
  PosY := AAction.GetYMouse;
  ScrollSpeed := Options.BattleScrollSpeed;

  FScrollMouseX := 0;
  FScrollMouseY := 0;

  if (PosX < (SCROLL_BORDER * AAction.GetXScale)) and (PosX >= 0) then
  begin
    FScrollMouseX := ScrollSpeed;
    if (PosY < (SCROLL_DIAGONAL_EDGE * AAction.GetYScale)) and (PosY >= 0) then
      FScrollMouseY := ScrollSpeed div 2
    else if PosY > (FScreenHeight - SCROLL_DIAGONAL_EDGE) * AAction.GetYScale then
      FScrollMouseY := -(ScrollSpeed div 2);
  end
  else if (PosX > (FScreenWidth - SCROLL_BORDER) * AAction.GetXScale) then
  begin
    FScrollMouseX := -ScrollSpeed;
    if (PosY <= (SCROLL_DIAGONAL_EDGE * AAction.GetYScale)) and (PosY >= 0) then
      FScrollMouseY := ScrollSpeed div 2
    else if PosY > (FScreenHeight - SCROLL_DIAGONAL_EDGE) * AAction.GetYScale then
      FScrollMouseY := -(ScrollSpeed div 2);
  end;

  if (PosY < (SCROLL_BORDER * AAction.GetYScale)) and (PosY >= 0) then
  begin
    FScrollMouseY := ScrollSpeed;
    if (PosX < (SCROLL_DIAGONAL_EDGE * AAction.GetXScale)) and (PosX >= 0) then
    begin
      FScrollMouseX := ScrollSpeed;
      FScrollMouseY := FScrollMouseY div 2;
    end
    else if PosX > (FScreenWidth - SCROLL_DIAGONAL_EDGE) * AAction.GetXScale then
    begin
      FScrollMouseX := -ScrollSpeed;
      FScrollMouseY := FScrollMouseY div 2;
    end;
  end
  else if (PosY > (FScreenHeight - SCROLL_BORDER) * AAction.GetYScale) then
  begin
    FScrollMouseY := -ScrollSpeed;
    if (PosX < (SCROLL_DIAGONAL_EDGE * AAction.GetXScale)) and (PosX >= 0) then
    begin
      FScrollMouseX := ScrollSpeed;
      FScrollMouseY := FScrollMouseY div 2;
    end
    else if PosX > (FScreenWidth - SCROLL_DIAGONAL_EDGE) * AAction.GetXScale then
    begin
      FScrollMouseX := -ScrollSpeed;
      FScrollMouseY := FScrollMouseY div 2;
    end;
  end;

  if ((FScrollMouseX <> 0) or (FScrollMouseY <> 0)) and (not FScrollMouseTimer.IsRunning) and
     (not FScrollKeyTimer.IsRunning) and ((SDL_GetMouseState(0,0) and SDL_BUTTON(Options.BattleDragScrollButton)) = 0) then
    FScrollMouseTimer.Start
  else if ((FScrollMouseX = 0) and (FScrollMouseY = 0)) and FScrollMouseTimer.IsRunning then
    FScrollMouseTimer.Stop;
end;

procedure TCamera.KeyboardPress(AAction: TAction; AState: TState);
var
  Key: Integer;
  ScrollSpeed: Integer;
begin
  if FMap.GetCursorType = CT_NONE then Exit;
  Key := AAction.GetDetails.key.keysym.sym;
  ScrollSpeed := Options.BattleScrollSpeed;
  if Key = Options.KeyBattleLeft then FScrollKeyX := ScrollSpeed
  else if Key = Options.KeyBattleRight then FScrollKeyX := -ScrollSpeed
  else if Key = Options.KeyBattleUp then FScrollKeyY := ScrollSpeed
  else if Key = Options.KeyBattleDown then FScrollKeyY := -ScrollSpeed
  else Exit;

  if ((FScrollKeyX <> 0) or (FScrollKeyY <> 0)) and (not FScrollKeyTimer.IsRunning) and
     (not FScrollMouseTimer.IsRunning) and ((SDL_GetMouseState(0,0) and SDL_BUTTON(Options.BattleDragScrollButton)) = 0) then
    FScrollKeyTimer.Start
  else if ((FScrollKeyX = 0) and (FScrollKeyY = 0)) and FScrollKeyTimer.IsRunning then
    FScrollKeyTimer.Stop;
end;

procedure TCamera.KeyboardRelease(AAction: TAction; AState: TState);
var
  Key: Integer;
begin
  if FMap.GetCursorType = CT_NONE then Exit;
  Key := AAction.GetDetails.key.keysym.sym;
  if Key = Options.KeyBattleLeft then FScrollKeyX := 0
  else if Key = Options.KeyBattleRight then FScrollKeyX := 0
  else if Key = Options.KeyBattleUp then FScrollKeyY := 0
  else if Key = Options.KeyBattleDown then FScrollKeyY := 0
  else Exit;

  if ((FScrollKeyX <> 0) or (FScrollKeyY <> 0)) and (not FScrollKeyTimer.IsRunning) and
     (not FScrollMouseTimer.IsRunning) and ((SDL_GetMouseState(0,0) and SDL_BUTTON(Options.BattleDragScrollButton)) = 0) then
    FScrollKeyTimer.Start
  else if ((FScrollKeyX = 0) and (FScrollKeyY = 0)) and FScrollKeyTimer.IsRunning then
    FScrollKeyTimer.Stop;
end;

procedure TCamera.ScrollMouse;
begin
  ScrollXY(FScrollMouseX, FScrollMouseY, True);
end;

procedure TCamera.ScrollKey;
begin
  ScrollXY(FScrollKeyX, FScrollKeyY, True);
end;

procedure TCamera.ScrollXY(X, Y: Integer; Redraw: Boolean);
begin
  FMapOffset.X := FMapOffset.X + X;
  FMapOffset.Y := FMapOffset.Y + Y;

  repeat
    ConvertScreenToMap(FScreenWidth div 2, FVisibleMapHeight div 2, FCenter.X, FCenter.Y);
    if FCenter.X < 0 then begin FMapOffset.X := FMapOffset.X - 1; FMapOffset.Y := FMapOffset.Y - 1; Continue; end;
    if FCenter.X > FMapsizeX - 1 then begin FMapOffset.X := FMapOffset.X + 1; FMapOffset.Y := FMapOffset.Y + 1; Continue; end;
    if FCenter.Y < 0 then begin FMapOffset.X := FMapOffset.X + 1; FMapOffset.Y := FMapOffset.Y - 1; Continue; end;
    if FCenter.Y > FMapsizeY - 1 then begin FMapOffset.X := FMapOffset.X - 1; FMapOffset.Y := FMapOffset.Y + 1; Continue; end;
    Break;
  until False;

  FMap.RefreshSelectorPosition;
  if Redraw then FMap.Invalidate;
end;

procedure TCamera.JumpXY(X, Y: Integer);
begin
  FMapOffset.X := FMapOffset.X + X;
  FMapOffset.Y := FMapOffset.Y + Y;
  ConvertScreenToMap(FScreenWidth div 2, FVisibleMapHeight div 2, FCenter.X, FCenter.Y);
end;

procedure TCamera.Up;
begin
  if FMapOffset.Z < FMapsizeZ - 1 then
  begin
    FMapOffset.Z := FMapOffset.Z + 1;
    FMapOffset.Y := FMapOffset.Y + (FSpriteHeight * 3) div 5;
    FMap.Draw;
  end;
end;

procedure TCamera.Down;
begin
  if FMapOffset.Z > 0 then
  begin
    FMapOffset.Z := FMapOffset.Z - 1;
    FMapOffset.Y := FMapOffset.Y - (FSpriteHeight * 3) div 5;
    FMap.Draw;
  end;
end;

procedure TCamera.SetViewLevel(ViewLevel: Integer);
begin
  FMapOffset.Z := Clamp(ViewLevel, 0, FMapsizeZ - 1);
  FMap.Draw;
end;

procedure TCamera.ConvertMapToScreen(MapPos: TPosition; var ScreenPos: TPosition);
begin
  ScreenPos.Z := 0;
  ScreenPos.X := MapPos.X * (FSpriteWidth div 2) - MapPos.Y * (FSpriteWidth div 2);
  ScreenPos.Y := MapPos.X * (FSpriteWidth div 4) + MapPos.Y * (FSpriteWidth div 4) -
                 MapPos.Z * ((FSpriteHeight + FSpriteWidth div 4) div 2);
end;

procedure TCamera.ConvertVoxelToScreen(VoxelPos: TPosition; var ScreenPos: TPosition);
var
  MapPos: TPosition;
  dx, dy, dz: Double;
begin
  MapPos := Position(VoxelPos.X div 16, VoxelPos.Y div 16, VoxelPos.Z div 24);
  ConvertMapToScreen(MapPos, ScreenPos);
  dx := VoxelPos.X - (MapPos.X * 16);
  dy := VoxelPos.Y - (MapPos.Y * 16);
  dz := VoxelPos.Z - (MapPos.Z * 24);
  ScreenPos.X := ScreenPos.X + Round(dx - dy) + (FSpriteWidth div 2);
  ScreenPos.Y := ScreenPos.Y + Round((FSpriteHeight / 2.0) + (dx / 2.0) + (dy / 2.0) - dz);
  ScreenPos.X := ScreenPos.X + FMapOffset.X;
  ScreenPos.Y := ScreenPos.Y + FMapOffset.Y;
end;

procedure TCamera.ConvertScreenToMap(ScreenX, ScreenY: Integer; var MapX, MapY: Integer);
begin
  ScreenY := ScreenY + (-FSpriteWidth div 2) + FMapOffset.Z * ((FSpriteHeight + FSpriteWidth div 4) div 2);
  MapY := -ScreenX + FMapOffset.X + 2 * ScreenY - 2 * FMapOffset.Y;
  MapX := ScreenY - FMapOffset.Y - MapY div 4 - (FSpriteWidth div 4);
  MapX := MapX div (FSpriteWidth div 4);
  MapY := MapY div FSpriteWidth;
  MapX := Clamp(MapX, -1, FMapsizeX);
  MapY := Clamp(MapY, -1, FMapsizeY);
end;

procedure TCamera.CenterOnPosition(Pos: TPosition; Redraw: Boolean);
var
  ScreenPos: TPosition;
begin
  FCenter := Pos;
  FCenter.X := Clamp(FCenter.X, -1, FMapsizeX);
  FCenter.Y := Clamp(FCenter.Y, -1, FMapsizeY);
  ConvertMapToScreen(FCenter, ScreenPos);
  FMapOffset.X := -(ScreenPos.X - (FScreenWidth div 2));
  FMapOffset.Y := -(ScreenPos.Y - (FVisibleMapHeight div 2));
  FMapOffset.Z := FCenter.Z;
  if Redraw then FMap.Draw;
end;

function TCamera.GetCenterPosition: TPosition;
begin
  FCenter.Z := FMapOffset.Z;
  Result := FCenter;
end;

function TCamera.GetViewLevel: Integer;
begin
  Result := FMapOffset.Z;
end;

function TCamera.GetMapSizeX: Integer;
begin
  Result := FMapsizeX;
end;

function TCamera.GetMapSizeY: Integer;
begin
  Result := FMapsizeY;
end;

function TCamera.GetMapOffset: TPosition;
begin
  Result := FMapOffset;
end;

procedure TCamera.SetMapOffset(const Pos: TPosition);
begin
  FMapOffset := Pos;
end;

function TCamera.ToggleShowAllLayers: Integer;
begin
  FShowAllLayers := not FShowAllLayers;
  Result := IfThen(FShowAllLayers, 2, 1);
end;

function TCamera.GetShowAllLayers: Boolean;
begin
  Result := FShowAllLayers;
end;

function TCamera.IsOnScreen(MapPos: TPosition; UnitWalking: Boolean; UnitSize: Integer; Boundary: Boolean): Boolean;
var
  ScreenPos: TPosition;
  PosX, PosY, SizeX, SizeY, Side: Integer;
begin
  ConvertMapToScreen(MapPos, ScreenPos);
  PosX := FSpriteWidth div 2;
  PosY := FSpriteHeight - FSpriteWidth div 4;
  SizeX := FSpriteWidth div 2;
  SizeY := FSpriteHeight div 2;
  if UnitSize > 0 then
  begin
    PosY := PosY - FSpriteWidth div 4;
    SizeX := FSpriteWidth * UnitSize;
    SizeY := FSpriteWidth * UnitSize div 2;
  end;
  ScreenPos.X := ScreenPos.X + FMapOffset.X + PosX;
  ScreenPos.Y := ScreenPos.Y + FMapOffset.Y + PosY;
  if UnitWalking then
  begin
    if Boundary then
    begin
      SizeX := SizeX + FSpriteWidth;
      SizeY := SizeY + FSpriteWidth div 2;
    end;
    if (ScreenPos.X < 0 - SizeX) or (ScreenPos.X >= FScreenWidth + SizeX) or
       (ScreenPos.Y < 0 - SizeY) or (ScreenPos.Y >= FScreenHeight + SizeY) then
      Exit(False);
    Side := (FScreenWidth - FMap.GetIconWidth) div 2;
    if ScreenPos.Y < (FScreenHeight - FMap.GetIconHeight) + SizeY then
      Exit(True);
    if (Side > 1) and ((ScreenPos.X < Side + SizeX) or (ScreenPos.X >= (FScreenWidth - Side - SizeX))) then
      Exit(True);
    Exit(False);
  end
  else
  begin
    Result := (ScreenPos.X >= 0) and (ScreenPos.X <= FScreenWidth - 10) and
              (ScreenPos.Y >= 0) and (ScreenPos.Y <= FScreenHeight - 10);
  end;
end;

procedure TCamera.Resize;
begin
  FScreenWidth := FMap.GetWidth;
  FScreenHeight := FMap.GetHeight;
  FVisibleMapHeight := FMap.GetHeight - FMap.GetIconHeight;
end;

procedure TCamera.StopMouseScrolling;
begin
  FScrollMouseTimer.Stop;
end;

end.