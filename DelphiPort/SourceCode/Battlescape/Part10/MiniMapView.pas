unit MiniMapView;

interface

uses
  Classes, SysTypes, SDL2,
  Engine.InteractiveSurface,
  Engine.Game,
  Engine.SurfaceSet,
  Engine.Action,
  Engine.Cursor,
  Engine.Screen,
  Engine.Options,
  Savegame.SavedBattleGame,
  Savegame.Tile,
  Mod.Mod,
  Mod.Armor,
  Battlescape.Camera,
  Battlescape.Position,
  Battlescape.Pathfinding;

type
  TMiniMapView = class(TInteractiveSurface)
  private const
    CELL_WIDTH = 4;
    CELL_HEIGHT = 4;
    MAX_FRAME = 2;
  private
    FGame: TGame;
    FCamera: TCamera;
    FBattleGame: TSavedBattleGame;
    FFrame: Integer;
    FSet: TSurfaceSet;
    FIsMouseScrolling: Boolean;
    FIsMouseScrolled: Boolean;
    FXBeforeMouseScrolling, FYBeforeMouseScrolling: Integer;
    FMouseScrollX, FMouseScrollY: Integer;
    FPosBeforeMouseScrolling: TPosition;
    FCursorPosition: TPosition;
    FMouseScrollingStartTime: Cardinal;
    FTotalMouseMoveX, FTotalMouseMoveY: Integer;
    FMouseMovedOverThreshold: Boolean;

    procedure StopScrolling(Action: TAction);
    procedure MousePress(Action: TAction; State: TState);
    procedure MouseClick(Action: TAction; State: TState);
    procedure MouseOver(Action: TAction; State: TState);
    procedure MouseIn(Action: TAction; State: TState);
  public
    constructor Create(W, H, X, Y: Integer; Game: TGame; Camera: TCamera; BattleGame: TSavedBattleGame);
    procedure Draw; override;
    function Up: Integer;
    function Down: Integer;
    procedure Animate;
  end;

implementation

uses
  Math,
  fmath;

{ TMiniMapView }

constructor TMiniMapView.Create(W, H, X, Y: Integer; Game: TGame; Camera: TCamera; BattleGame: TSavedBattleGame);
begin
  inherited Create(W, H, X, Y);
  FGame := Game;
  FCamera := Camera;
  FBattleGame := BattleGame;
  FFrame := 0;
  FIsMouseScrolling := False;
  FIsMouseScrolled := False;
  FXBeforeMouseScrolling := 0;
  FYBeforeMouseScrolling := 0;
  FMouseScrollX := 0;
  FMouseScrollY := 0;
  FPosBeforeMouseScrolling := TPosition.Create(0,0,0);
  FCursorPosition := TPosition.Create(0,0,0);
  FMouseScrollingStartTime := 0;
  FTotalMouseMoveX := 0;
  FTotalMouseMoveY := 0;
  FMouseMovedOverThreshold := False;
  FSet := FGame.Mod.SurfaceSet['SCANG.DAT'];
end;

procedure TMiniMapView.Draw;
var
  StartX, StartY: Integer;
  Lvl, Py, Px: Integer;
  X, Y: Integer;
  P: TPosition;
  Tile: TTile;
  I: TTilePart;
  Data: TMapData;
  Surf: TSurface;
  Shade: Integer;
  Frame: Integer;
  Size: Integer;
  CenterX, CenterY: Integer;
  Color: Byte;
  XOff, YOff: Integer;
begin
  StartX := FCamera.CenterPosition.X - ((Width div CELL_WIDTH) div 2);
  StartY := FCamera.CenterPosition.Y - ((Height div CELL_HEIGHT) div 2);

  inherited Draw;
  if FSet = nil then Exit;

  DrawRect(0, 0, Width, Height, 15);
  Lock;
  try
    for Lvl := 0 to FCamera.CenterPosition.Z do
    begin
      Py := StartY;
      for Y := 0 to Height - 1 do
      begin
        Px := StartX;
        for X := 0 to Width - 1 do
        begin
          P := TPosition.Create(Px, Py, Lvl);
          Tile := FBattleGame.GetTile(P);
          if Tile = nil then
          begin
            Inc(Px);
            Continue;
          end;
          for I := Low(TTilePart) to High(TTilePart) do
          begin
            Data := Tile.GetMapData(I);
            if Assigned(Data) and (Data.MiniMapIndex <> 0) then
            begin
              Surf := FSet.GetFrame(Data.MiniMapIndex + 35);
              if Surf <> nil then
              begin
                Shade := 16;
                if Tile.IsDiscovered(2) then
                begin
                  Shade := Tile.Shade;
                  if Shade > 7 then Shade := 7;
                end;
                Surf.BlitNShade(Self, X, Y, Shade);
              end;
            end;
          end;

          // Units
          if Assigned(Tile.Unit) and Tile.Unit.Visible then
          begin
            Frame := Tile.Unit.MiniMapSpriteIndex;
            Size := Tile.Unit.Armor.Size;
            Frame := Frame + (Tile.Position.Y - Tile.Unit.Position.Y) * Size +
                     (Tile.Position.X - Tile.Unit.Position.X) +
                     FFrame * Size * Size;
            Surf := FSet.GetFrame(Frame);
            if Size > 1 and (Tile.Unit.Faction = FACTION_NEUTRAL) then
              Surf.BlitNShade(Self, X, Y, 0, False, Pathfinding.red)
            else
              Surf.BlitNShade(Self, X, Y, 0);
          end;

          // Items
          if Tile.IsDiscovered(2) and (Tile.Inventory.Count > 0) then
          begin
            Surf := FSet.GetFrame(9 + FFrame);
            Surf.BlitNShade(Self, X, Y, 0);
          end;

          Inc(Px);
        end;
        Inc(Py);
      end;
    end;
  finally
    Unlock;
  end;

  CenterX := Width div 2 - 1;
  CenterY := Height div 2 - 1;
  Color := 1 + FFrame * 3;
  XOff := CELL_WIDTH div 2;
  YOff := CELL_HEIGHT div 2;

  DrawLine(CenterX - CELL_WIDTH, CenterY - CELL_HEIGHT,
           CenterX - XOff, CenterY - YOff, Color);
  DrawLine(CenterX + XOff, CenterY - YOff,
           CenterX + CELL_WIDTH, CenterY - CELL_HEIGHT, Color);
  DrawLine(CenterX - CELL_WIDTH, CenterY + CELL_HEIGHT,
           CenterX - XOff, CenterY + YOff, Color);
  DrawLine(CenterX + CELL_WIDTH, CenterY + CELL_HEIGHT,
           CenterX + XOff, CenterY + YOff, Color);
end;

function TMiniMapView.Up: Integer;
begin
  FCamera.SetViewLevel(FCamera.ViewLevel + 1);
  Redraw := True;
  Result := FCamera.ViewLevel;
end;

function TMiniMapView.Down: Integer;
begin
  FCamera.SetViewLevel(FCamera.ViewLevel - 1);
  Redraw := True;
  Result := FCamera.ViewLevel;
end;

procedure TMiniMapView.MousePress(Action: TAction; State: TState);
begin
  inherited;
  if Action.Details.Button.Button = Options.BattleDragScrollButton then
  begin
    FIsMouseScrolling := True;
    FIsMouseScrolled := False;
    SDL_GetMouseState(FXBeforeMouseScrolling, FYBeforeMouseScrolling);
    FPosBeforeMouseScrolling := FCamera.CenterPosition;
    if not Options.BattleDragScrollInvert and (FCursorPosition.Z = 0) then
    begin
      FCursorPosition.X := Action.Details.Motion.X;
      FCursorPosition.Y := Action.Details.Motion.Y;
      FCursorPosition.Z := 1;
    end;
    FMouseScrollX := 0; FMouseScrollY := 0;
    FTotalMouseMoveX := 0; FTotalMouseMoveY := 0;
    FMouseMovedOverThreshold := False;
    FMouseScrollingStartTime := SDL_GetTicks;
  end;
end;

procedure TMiniMapView.MouseClick(Action: TAction; State: TState);
var
  OrigX, OrigY: Integer;
  XOff, YOff: Integer;
  NewX, NewY: Integer;
begin
  inherited;

  // Handle missed release
  if FIsMouseScrolling then
    if (Action.Details.Button.Button <> Options.BattleDragScrollButton) and
       ((SDL_GetMouseState(nil, nil) and SDL_BUTTON(Options.BattleDragScrollButton)) = 0) then
    begin
      if (not FMouseMovedOverThreshold) and ((SDL_GetTicks - FMouseScrollingStartTime) <= Cardinal(Options.DragScrollTimeTolerance)) then
        FCamera.CenterOnPosition(FPosBeforeMouseScrolling);
      FIsMouseScrolled := False;
      FIsMouseScrolling := False;
      StopScrolling(Action);
    end;

  if FIsMouseScrolling then
  begin
    if Action.Details.Button.Button = Options.BattleDragScrollButton then
    begin
      FIsMouseScrolling := False;
      StopScrolling(Action);
    end
    else
      Exit;
    if (not FMouseMovedOverThreshold) and ((SDL_GetTicks - FMouseScrollingStartTime) <= Cardinal(Options.DragScrollTimeTolerance)) then
    begin
      FIsMouseScrolled := False;
      StopScrolling(Action);
      FCamera.CenterOnPosition(FPosBeforeMouseScrolling);
    end;
    if FIsMouseScrolled then Exit;
  end;

  if Action.Details.Button.Button = SDL_BUTTON_RIGHT then
    (State as TMiniMapState).BtnOkClick(Action);

  if Action.Details.Button.Button = SDL_BUTTON_LEFT then
  begin
    OrigX := Round(Action.RelativeXMouse / Action.XScale);
    OrigY := Round(Action.RelativeYMouse / Action.YScale);
    XOff := (OrigX div CELL_WIDTH) - ((Width div 2) div CELL_WIDTH);
    YOff := (OrigY div CELL_HEIGHT) - ((Height div 2) div CELL_HEIGHT);
    NewX := FCamera.CenterPosition.X + XOff;
    NewY := FCamera.CenterPosition.Y + YOff;
    FCamera.CenterOnPosition(TPosition.Create(NewX, NewY, FCamera.ViewLevel));
    Redraw := True;
  end;
end;

procedure TMiniMapView.MouseOver(Action: TAction; State: TState);
var
  NewX, NewY: Integer;
  ScrollX, ScrollY: Integer;
  BarWidth, BarHeight: Integer;
  CursorX, CursorY: Integer;
begin
  inherited;

  if FIsMouseScrolling and (Action.Details.Type_ = SDL_MOUSEMOTION) then
  begin
    if (SDL_GetMouseState(nil, nil) and SDL_BUTTON(Options.BattleDragScrollButton)) = 0 then
    begin
      if (not FMouseMovedOverThreshold) and ((SDL_GetTicks - FMouseScrollingStartTime) <= Cardinal(Options.DragScrollTimeTolerance)) then
        FCamera.CenterOnPosition(FPosBeforeMouseScrolling);
      FIsMouseScrolled := False;
      FIsMouseScrolling := False;
      StopScrolling(Action);
      Exit;
    end;

    FIsMouseScrolled := True;

    if not Options.TouchEnabled then
    begin
      SDL_EventState(SDL_MOUSEMOTION, SDL_IGNORE);
      SDL_WarpMouse(FXBeforeMouseScrolling, FYBeforeMouseScrolling);
      SDL_EventState(SDL_MOUSEMOTION, SDL_ENABLE);
    end;

    FTotalMouseMoveX := FTotalMouseMoveX + Action.Details.Motion.XRel;
    FTotalMouseMoveY := FTotalMouseMoveY + Action.Details.Motion.YRel;
    if not FMouseMovedOverThreshold then
      FMouseMovedOverThreshold := (Abs(FTotalMouseMoveX) > Options.DragScrollPixelTolerance) or
                                  (Abs(FTotalMouseMoveY) > Options.DragScrollPixelTolerance);

    if Options.BattleDragScrollInvert then
    begin
      ScrollX := Action.Details.Motion.XRel;
      ScrollY := Action.Details.Motion.YRel;
    end
    else
    begin
      ScrollX := -Action.Details.Motion.XRel;
      ScrollY := -Action.Details.Motion.YRel;
    end;
    FMouseScrollX := FMouseScrollX + ScrollX;
    FMouseScrollY := FMouseScrollY + ScrollY;
    NewX := FPosBeforeMouseScrolling.X + Round(FMouseScrollX / Action.XScale / 4);
    NewY := FPosBeforeMouseScrolling.Y + Round(FMouseScrollY / Action.YScale / 4);

    if (NewX < -1) or (FCamera.MapSizeX < NewX) then
    begin
      FMouseScrollX := FMouseScrollX - ScrollX;
      NewX := FPosBeforeMouseScrolling.X + Round(FMouseScrollX / 4);
    end;
    if (NewY < -1) or (FCamera.MapSizeY < NewY) then
    begin
      FMouseScrollY := FMouseScrollY - ScrollY;
      NewY := FPosBeforeMouseScrolling.Y + Round(FMouseScrollY / 4);
    end;

    FCamera.CenterOnPosition(TPosition.Create(NewX, NewY, FCamera.ViewLevel));
    Redraw := True;

    if not Options.TouchEnabled then
    begin
      if Options.BattleDragScrollInvert then
      begin
        Action.Details.Motion.X := FXBeforeMouseScrolling;
        Action.Details.Motion.Y := FYBeforeMouseScrolling;
      end
      else
      begin
        BarWidth := FGame.Screen.CursorLeftBlackBand;
        BarHeight := FGame.Screen.CursorTopBlackBand;
        CursorX := FCursorPosition.X - ScrollX;
        CursorY := FCursorPosition.Y - ScrollY;
        FCursorPosition.X := Clamp(CursorX, Round(X * Action.XScale) + BarWidth, Round((X + Width) * Action.XScale) + BarWidth);
        FCursorPosition.Y := Clamp(CursorY, Round(Y * Action.YScale) + BarHeight, Round((Y + Height) * Action.YScale) + BarHeight);
        Action.Details.Motion.X := FCursorPosition.X;
        Action.Details.Motion.Y := FCursorPosition.Y;
      end;
      FGame.Cursor.Handle(Action);
    end;
  end;
end;

procedure TMiniMapView.MouseIn(Action: TAction; State: TState);
begin
  inherited;
  FIsMouseScrolling := False;
  SetButtonPressed(SDL_BUTTON_RIGHT, False);
end;

procedure TMiniMapView.Animate;
begin
  FFrame := (FFrame + 1) mod (MAX_FRAME + 1);
  Redraw := True;
end;

procedure TMiniMapView.StopScrolling(Action: TAction);
begin
  if not Options.BattleDragScrollInvert then
  begin
    SDL_WarpMouse(FCursorPosition.X, FCursorPosition.Y);
    Action.SetMouseAction(FCursorPosition.X, FCursorPosition.Y, X, Y);
  end;
  FCursorPosition.Z := 0;
end;

end.