unit UBattlescapeButton;

interface

uses
  SysUtils, Classes, SDL, USurface, UInteractiveSurface, USurfaceSet;

type
  TBattlescapeButton = class(TInteractiveSurface)
  private
    FColor: Byte;
    FSecondaryColor: Byte;
    FBorderColor: Byte;
    FSurfaceSet: TSurfaceSet;
    FFrame: Integer;
    FGroup: Integer;
    FPressed: Boolean;
    FToggled: Boolean;
    FDisabled: Boolean;
    function GetFrameSurface: TSurface;
    procedure DrawButton;
  public
    constructor Create(Width, Height, X, Y: Integer);
    destructor Destroy; override;
    procedure Copy(Parent: TSurface); // stub
    procedure InitSurfaces; // stub
    procedure SetColor(Color: Byte); override;
    procedure SetSecondaryColor(Color: Byte); override;
    procedure SetBorderColor(Color: Byte); override;
    procedure SetSurfaceSet(SurfaceSet: TSurfaceSet);
    procedure SetFrame(Frame: Integer);
    procedure SetGroup(Group: Integer);
    procedure SetPressed(Pressed: Boolean);
    procedure SetToggled(Toggled: Boolean);
    procedure SetDisabled(Disabled: Boolean);
    procedure MousePress(Action: TAction; State: TState); override;
    procedure MouseRelease(Action: TAction; State: TState); override;
    procedure MouseClick(Action: TAction; State: TState); override;
    procedure Draw; override;
  end;

implementation

constructor TBattlescapeButton.Create(Width, Height, X, Y: Integer);
begin
  inherited Create(Width, Height, X, Y);
  FColor := 0;
  FSecondaryColor := 0;
  FBorderColor := 0;
  FSurfaceSet := nil;
  FFrame := 0;
  FGroup := 0;
  FPressed := False;
  FToggled := False;
  FDisabled := False;
end;

destructor TBattlescapeButton.Destroy;
begin
  // FSurfaceSet is owned externally
  inherited;
end;

procedure TBattlescapeButton.Copy(Parent: TSurface);
begin
  // stub
end;

procedure TBattlescapeButton.InitSurfaces;
begin
  // stub
end;

procedure TBattlescapeButton.SetColor(Color: Byte);
begin
  FColor := Color;
  FRedraw := True;
end;

procedure TBattlescapeButton.SetSecondaryColor(Color: Byte);
begin
  FSecondaryColor := Color;
  FRedraw := True;
end;

procedure TBattlescapeButton.SetBorderColor(Color: Byte);
begin
  FBorderColor := Color;
  FRedraw := True;
end;

procedure TBattlescapeButton.SetSurfaceSet(SurfaceSet: TSurfaceSet);
begin
  FSurfaceSet := SurfaceSet;
  FRedraw := True;
end;

procedure TBattlescapeButton.SetFrame(Frame: Integer);
begin
  FFrame := Frame;
  FRedraw := True;
end;

procedure TBattlescapeButton.SetGroup(Group: Integer);
begin
  FGroup := Group;
end;

procedure TBattlescapeButton.SetPressed(Pressed: Boolean);
begin
  FPressed := Pressed;
  FRedraw := True;
end;

procedure TBattlescapeButton.SetToggled(Toggled: Boolean);
begin
  FToggled := Toggled;
  FRedraw := True;
end;

procedure TBattlescapeButton.SetDisabled(Disabled: Boolean);
begin
  FDisabled := Disabled;
  FRedraw := True;
end;

function TBattlescapeButton.GetFrameSurface: TSurface;
begin
  if (FSurfaceSet <> nil) then
    Result := FSurfaceSet.GetFrame(FFrame)
  else
    Result := nil;
end;

procedure TBattlescapeButton.DrawButton;
var
  Surf: TSurface;
begin
  Clear(0);
  // Draw based on state
  if FDisabled then
  begin
    // Draw disabled (grayed out)
  end
  else if FPressed or FToggled then
  begin
    // Draw pressed state (color shift)
  end;
  // Blit the frame surface
  Surf := GetFrameSurface;
  if Surf <> nil then
    SDL_BlitSurface(Surf.GetSurface, nil, FSurface, nil);
end;

procedure TBattlescapeButton.Draw;
begin
  FRedraw := False;
  DrawButton;
end;

procedure TBattlescapeButton.MousePress(Action: TAction; State: TState);
begin
  inherited;
  if not FDisabled then
    SetPressed(True);
end;

procedure TBattlescapeButton.MouseRelease(Action: TAction; State: TState);
begin
  inherited;
  SetPressed(False);
end;

procedure TBattlescapeButton.MouseClick(Action: TAction; State: TState);
begin
  inherited;
  if not FDisabled then
  begin
    FToggled := not FToggled;
    FRedraw := True;
  end;
end;

end.