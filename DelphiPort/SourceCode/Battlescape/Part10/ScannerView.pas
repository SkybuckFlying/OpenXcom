unit ScannerView;

interface

uses
  Classes, SysUtils,
  Engine.InteractiveSurface,
  Engine.Game,
  Engine.Action,
  Engine.SurfaceSet,
  Savegame.BattleUnit,
  Savegame.SavedBattleGame;

type
  TScannerView = class(TInteractiveSurface)
  private
    FGame: TGame;
    FUnit: TBattleUnit;
    FFrame: Integer;
    procedure MouseClick(Action: TAction; State: TState);
  public
    constructor Create(W, H, X, Y: Integer; Game: TGame; Unit: TBattleUnit);
    procedure Draw; override;
    procedure Animate;
  end;

implementation

uses
  Savegame.Tile,
  Mod.Mod;

{ TScannerView }

constructor TScannerView.Create(W, H, X, Y: Integer; Game: TGame; Unit: TBattleUnit);
begin
  inherited Create(W, H, X, Y);
  FGame := Game;
  FUnit := Unit;
  FFrame := 0;
  Redraw := True;
end;

procedure TScannerView.Draw;
var
  Set_: TSurfaceSet;
  Surface: TSurface;
  X, Y, Z: Integer;
  Tile: TTile;
  Frame: Integer;
begin
  Set_ := FGame.Mod.SurfaceSet['DETBLOB.DAT'];
  Clear;

  Lock;
  try
    for X := -9 to 9 do
      for Y := -9 to 9 do
        for Z := 0 to FGame.SavedGame.SavedBattle.MapSizeZ - 1 do
        begin
          Tile := FGame.SavedGame.SavedBattle.GetTile(TPosition.Create(X,Y,Z) + TPosition.Create(FUnit.Position.X, FUnit.Position.Y, 0));
          if Assigned(Tile) and Assigned(Tile.Unit) and (Tile.Unit.MotionPoints > 0) then
          begin
            Frame := Tile.Unit.MotionPoints div 5;
            if Frame > 5 then Frame := 5;
            Surface := Set_.GetFrame(Frame + FFrame);
            if Surface <> nil then
              Surface.BlitNShade(Self, X + ((9+X)*8)-4, Y + ((9+Y)*8)-4, 0);
          end;
        end;

    // Direction arrow
    Surface := Set_.GetFrame(7 + FUnit.Direction);
    if Surface <> nil then
      Surface.BlitNShade(Self, 9*8-4, 9*8-4, 0);
  finally
    Unlock;
  end;
end;

procedure TScannerView.MouseClick(Action: TAction; State: TState);
begin
  // no-op
end;

procedure TScannerView.Animate;
begin
  FFrame := (FFrame + 1) mod 2;
  Redraw := True;
end;

end.