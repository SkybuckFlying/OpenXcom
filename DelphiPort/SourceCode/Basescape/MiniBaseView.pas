unit MiniBaseView;

interface

uses
  Classes, SysUtils, Generics.Collections,
  Engine.InteractiveSurface, Engine.SurfaceSet, Engine.Action,
  Savegame.Base, Savegame.BaseFacility, Mod.RuleBaseFacility;

type
  TMiniBaseView = class(TInteractiveSurface)
  private const
    MINI_SIZE = 14;
    MAX_BASES = 8;
  private
    FBases: TList<TBase>;
    FTexture: TSurfaceSet;
    FBase: Integer;
    FHoverBase: Integer;
    FRed, FGreen: Byte;
  public
    constructor Create(Width, Height, X, Y: Integer);
    destructor Destroy; override;
    procedure SetBases(Bases: TList<TBase>);
    procedure SetTexture(Texture: TSurfaceSet);
    function GetHoveredBase: Integer;
    procedure SetSelectedBase(Base: Integer);
    procedure Draw; override;
    procedure MouseOver(Action: TAction; State: TState); override;
    procedure SetColor(Color: Byte);
    procedure SetSecondaryColor(Color: Byte);
  end;

implementation

uses Math;

constructor TMiniBaseView.Create(Width, Height, X, Y: Integer);
begin
  inherited Create(Width, Height, X, Y);
  FBases := nil;
  FTexture := nil;
  FBase := 0;
  FHoverBase := 0;
  FRed := 0;
  FGreen := 0;
end;

destructor TMiniBaseView.Destroy;
begin
  inherited;
end;

procedure TMiniBaseView.SetBases(Bases: TList<TBase>);
begin
  FBases := Bases;
  Redraw := True;
end;

procedure TMiniBaseView.SetTexture(Texture: TSurfaceSet);
begin
  FTexture := Texture;
end;

function TMiniBaseView.GetHoveredBase: Integer;
begin
  Result := FHoverBase;
end;

procedure TMiniBaseView.SetSelectedBase(Base: Integer);
begin
  FBase := Base;
  Redraw := True;
end;

procedure TMiniBaseView.Draw;
var
  i, x, y: Integer;
  R: TRect;
  Fac: TBaseFacility;
  color: Integer;
begin
  inherited Draw;
  for i := 0 to MAX_BASES-1 do
  begin
    if i = FBase then
    begin
      R := Rect(i * (MINI_SIZE + 2), 0, i * (MINI_SIZE + 2) + MINI_SIZE + 2, MINI_SIZE + 2);
      DrawRect(R, 1);
    end;
    FTexture.GetFrame(41).SetX(i * (MINI_SIZE + 2));
    FTexture.GetFrame(41).SetY(0);
    FTexture.GetFrame(41).Blit(Self);

    if i < FBases.Count then
    begin
      Lock;
      for Fac in FBases[i].GetFacilities do
      begin
        if Fac.GetBuildTime = 0 then
          color := FGreen
        else
          color := FRed;

        R := Rect(i * (MINI_SIZE + 2) + 2 + Fac.GetX * 2,
                  2 + Fac.GetY * 2,
                  Fac.GetRules.GetSize * 2,
                  Fac.GetRules.GetSize * 2);
        DrawRect(R, color + 3);
        R.Left := R.Left + 1;
        R.Top := R.Top + 1;
        R.Right := R.Right - 1;
        R.Bottom := R.Bottom - 1;
        DrawRect(R, color + 5);
        R.Left := R.Left - 1;
        R.Top := R.Top - 1;
        R.Right := R.Right + 1;
        R.Bottom := R.Bottom + 1;
        DrawRect(R, color + 2);
        R.Left := R.Left + 1;
        R.Top := R.Top + 1;
        R.Right := R.Right - 1;
        R.Bottom := R.Bottom - 1;
        DrawRect(R, color + 3);
        R.Left := R.Left - 1;
        R.Top := R.Top - 1;
        SetPixel(R.Left, R.Top, color + 1);
      end;
      Unlock;
    end;
  end;
end;

procedure TMiniBaseView.MouseOver(Action: TAction; State: TState);
begin
  FHoverBase := Floor(Action.GetRelativeXMouse / ((MINI_SIZE + 2) * Action.GetXScale));
  if FHoverBase >= MAX_BASES then FHoverBase := MAX_BASES - 1;
  inherited MouseOver(Action, State);
end;

procedure TMiniBaseView.SetColor(Color: Byte);
begin
  FGreen := Color;
end;

procedure TMiniBaseView.SetSecondaryColor(Color: Byte);
begin
  FRed := Color;
end;

end.