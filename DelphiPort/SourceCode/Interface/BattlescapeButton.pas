unit BattlescapeButton;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics,
  Common, Action, State;

type
  TInversionType = (itNone, itClick, itToggle);

  TBattlescapeButton = class(TInteractiveSurface)
  private
    FColor: TColor;
    FGroup: ^TBattlescapeButton;
    FInverted: Boolean;
    FToggleMode: TInversionType;
    FAltSurface: TSurface;
    FTFTDMode: Boolean;
  protected
    function IsButtonHandled(Button: TMouseButton): Boolean; override;
  public
    constructor Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent); reintroduce;
    destructor Destroy; override;
    procedure SetColor(Color: TColor);
    function GetColor: TColor;
    procedure SetGroup(Group: Pointer);
    procedure MousePress(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseRelease(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Toggle(Press: Boolean);
    procedure AllowToggleInversion;
    procedure AllowClickInversion;
    procedure InitSurfaces;
    procedure Blit(Dest: TSurface); override;
    procedure SetX(X: Integer); override;
    procedure SetY(Y: Integer); override;
  end;

implementation

constructor TBattlescapeButton.Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := AWidth;
  Height := AHeight;
  Left := AX;
  Top := AY;
  FColor := 0;
  FGroup := nil;
  FInverted := False;
  FToggleMode := itNone;
  FAltSurface := nil;
  FTFTDMode := False;
end;

destructor TBattlescapeButton.Destroy;
begin
  FAltSurface.Free;
  inherited;
end;

function TBattlescapeButton.IsButtonHandled(Button: TMouseButton): Boolean;
begin
  Result := True; // handle all buttons
end;

procedure TBattlescapeButton.SetColor(Color: TColor);
begin
  FColor := Color;
end;

function TBattlescapeButton.GetColor: TColor;
begin
  Result := FColor;
end;

procedure TBattlescapeButton.SetGroup(Group: Pointer);
begin
  FGroup := Group;
  if (FGroup <> nil) and (FGroup^ = Self) then
    FInverted := True;
end;

procedure TBattlescapeButton.MousePress(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if FGroup <> nil then
  begin
    if Button = mbLeft then
    begin
      FGroup^.Toggle(False);
      FGroup^ := Self;
      FInverted := True;
    end;
  end
  else if (FToggleMode = itClick) and not FInverted and IsButtonHandled(Button) then
    FInverted := True;
end;

procedure TBattlescapeButton.MouseRelease(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if FInverted and IsButtonHandled(Button) then
    FInverted := False;
end;

procedure TBattlescapeButton.Toggle(Press: Boolean);
begin
  if (FToggleMode = itClick) or (FToggleMode = itToggle) or FInverted then
    FInverted := Press;
end;

procedure TBattlescapeButton.AllowToggleInversion;
begin
  FToggleMode := itToggle;
end;

procedure TBattlescapeButton.AllowClickInversion;
begin
  FToggleMode := itClick;
end;

procedure TBattlescapeButton.InitSurfaces;
var
  X, Y: Integer;
  Pixel: TColor;
begin
  FAltSurface := TSurface.Create(Self);
  FAltSurface.Width := Width;
  FAltSurface.Height := Height;
  FAltSurface.SetPalette(GetPalette, 0, 256); // inherit palette

  if FTFTDMode then
  begin
    // TFTD color mapping (simplified)
    for Y := 0 to Height-1 do
      for X := 0 to Width-1 do
      begin
        Pixel := GetPixel(X, Y);
        // apply mapping
        FAltSurface.SetPixel(X, Y, Pixel); // stub
      end;
  end
  else
  begin
    for Y := 0 to Height-1 do
      for X := 0 to Width-1 do
      begin
        Pixel := GetPixel(X, Y);
        if Pixel <> 0 then
          FAltSurface.SetPixel(X, Y, Pixel + 2 * (FColor + 3 - Pixel)) // invert
        else
          FAltSurface.SetPixel(X, Y, 0);
      end;
  end;
end;

procedure TBattlescapeButton.Blit(Dest: TSurface);
begin
  if FInverted then
    FAltSurface.Blit(Dest)
  else
    inherited Blit(Dest);
end;

procedure TBattlescapeButton.SetX(X: Integer);
begin
  inherited SetX(X);
  if FAltSurface <> nil then
    FAltSurface.Left := X;
end;

procedure TBattlescapeButton.SetY(Y: Integer);
begin
  inherited SetY(Y);
  if FAltSurface <> nil then
    FAltSurface.Top := Y;
end;

end.