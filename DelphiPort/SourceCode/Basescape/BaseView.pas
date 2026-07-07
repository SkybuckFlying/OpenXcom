unit BaseView;

interface

uses
  Classes, SysUtils, Generics.Collections,
  Engine.InteractiveSurface, Engine.SurfaceSet, Engine.Action,
  Savegame.Base, Savegame.BaseFacility, Savegame.Craft,
  Mod.RuleBaseFacility, Mod.RuleCraft, Interface.Text,
  Engine.Timer, Engine.Options, Engine.State, Engine.Font, Engine.Language;

type
  TBaseView = class(TInteractiveSurface)
  private const
    BASE_SIZE = 6;
    GRID_SIZE = 32;
  private
    FBase: TBase;
    FTexture: TSurfaceSet;
    FFacilities: array[0..BASE_SIZE-1, 0..BASE_SIZE-1] of TBaseFacility;
    FSelFacility: TBaseFacility;
    FBigFont: TFont;
    FSmallFont: TFont;
    FLang: TLanguage;
    FGridX, FGridY, FSelSize: Integer;
    FSelector: TSurface;
    FBlink: Boolean;
    FTimer: TTimer;
    FCellColor, FSelectorColor: Byte;

    procedure Blink(Sender: TObject);
    procedure UpdateNeighborFacilityBuildTime(Facility, Neighbor: TBaseFacility);
  public
    constructor Create(Width, Height, X, Y: Integer);
    destructor Destroy; override;
    procedure InitText(Big, Small: TFont; Lang: TLanguage);
    procedure SetBase(Base: TBase);
    procedure SetTexture(Texture: TSurfaceSet);
    function GetSelectedFacility: TBaseFacility;
    procedure ResetSelectedFacility;
    function GetGridX: Integer;
    function GetGridY: Integer;
    procedure SetSelectable(Size: Integer);
    function IsPlaceable(Rule: TRuleBaseFacility): Boolean;
    function IsQueuedBuilding(Rule: TRuleBaseFacility): Boolean;
    procedure ReCalcQueuedBuildings;
    procedure Think; override;
    procedure Draw; override;
    procedure Blit(Surface: TSurface); override;
    procedure MouseOver(Action: TAction; State: TState); override;
    procedure MouseOut(Action: TAction; State: TState); override;
    procedure SetColor(Color: Byte);
    procedure SetSecondaryColor(Color: Byte);
  end;

implementation

uses Math, Mod.Mod;

constructor TBaseView.Create(Width, Height, X, Y: Integer);
var
  i, j: Integer;
begin
  inherited Create(Width, Height, X, Y);
  FBase := nil;
  FTexture := nil;
  FSelFacility := nil;
  FBigFont := nil;
  FSmallFont := nil;
  FLang := nil;
  FGridX := 0;
  FGridY := 0;
  FSelSize := 0;
  FSelector := nil;
  FBlink := True;
  FCellColor := 0;
  FSelectorColor := 0;
  for i := 0 to BASE_SIZE-1 do
    for j := 0 to BASE_SIZE-1 do
      FFacilities[i, j] := nil;

  FTimer := TTimer.Create(100);
  FTimer.OnTimer := Blink;
  FTimer.Start;
end;

destructor TBaseView.Destroy;
begin
  FSelector.Free;
  FTimer.Free;
  inherited;
end;

procedure TBaseView.InitText(Big, Small: TFont; Lang: TLanguage);
begin
  FBigFont := Big;
  FSmallFont := Small;
  FLang := Lang;
end;

procedure TBaseView.SetBase(Base: TBase);
var
  x, y: Integer;
  Fac: TBaseFacility;
begin
  FBase := Base;
  FSelFacility := nil;
  for x := 0 to BASE_SIZE-1 do
    for y := 0 to BASE_SIZE-1 do
      FFacilities[x, y] := nil;

  for Fac in FBase.GetFacilities do
    for y := Fac.GetY to Fac.GetY + Fac.GetRules.GetSize - 1 do
      for x := Fac.GetX to Fac.GetX + Fac.GetRules.GetSize - 1 do
        FFacilities[x, y] := Fac;
  Redraw := True;
end;

procedure TBaseView.SetTexture(Texture: TSurfaceSet);
begin
  FTexture := Texture;
end;

function TBaseView.GetSelectedFacility: TBaseFacility;
begin
  Result := FSelFacility;
end;

procedure TBaseView.ResetSelectedFacility;
begin
  if FSelFacility <> nil then
  begin
    FFacilities[FSelFacility.GetX, FSelFacility.GetY] := nil;
    FSelFacility := nil;
  end;
end;

function TBaseView.GetGridX: Integer;
begin
  Result := FGridX;
end;

function TBaseView.GetGridY: Integer;
begin
  Result := FGridY;
end;

procedure TBaseView.SetSelectable(Size: Integer);
var
  R: TRect;
begin
  FSelSize := Size;
  if FSelSize > 0 then
  begin
    FSelector := TSurface.Create(Size * GRID_SIZE, Size * GRID_SIZE, X, Y);
    FSelector.SetPalette(GetPalette);
    R := Rect(0, 0, FSelector.Width, FSelector.Height);
    FSelector.DrawRect(R, FSelectorColor);
    R := Rect(1, 1, FSelector.Width-2, FSelector.Height-2);
    FSelector.DrawRect(R, 0);
    FSelector.Visible := False;
  end
  else
    FreeAndNil(FSelector);
end;

function TBaseView.IsPlaceable(Rule: TRuleBaseFacility): Boolean;
var
  x, y: Integer;
  i: Integer;
  bq: Boolean;
begin
  Result := False;
  for y := FGridY to FGridY + Rule.GetSize - 1 do
    for x := FGridX to FGridX + Rule.GetSize - 1 do
    begin
      if (x < 0) or (x >= BASE_SIZE) or (y < 0) or (y >= BASE_SIZE) then
        Exit(False);
      if FFacilities[x, y] <> nil then
        Exit(False);
    end;

  bq := Options.AllowBuildingQueue;
  for i := 0 to Rule.GetSize - 1 do
  begin
    if (FGridX > 0) and (FFacilities[FGridX-1, FGridY+i] <> nil) and (bq or (FFacilities[FGridX-1, FGridY+i].GetBuildTime = 0)) then
      Exit(True);
    if (FGridY > 0) and (FFacilities[FGridX+i, FGridY-1] <> nil) and (bq or (FFacilities[FGridX+i, FGridY-1].GetBuildTime = 0)) then
      Exit(True);
    if (FGridX + Rule.GetSize < BASE_SIZE) and (FFacilities[FGridX + Rule.GetSize, FGridY+i] <> nil) and (bq or (FFacilities[FGridX + Rule.GetSize, FGridY+i].GetBuildTime = 0)) then
      Exit(True);
    if (FGridY + Rule.GetSize < BASE_SIZE) and (FFacilities[FGridX+i, FGridY + Rule.GetSize] <> nil) and (bq or (FFacilities[FGridX+i, FGridY + Rule.GetSize].GetBuildTime = 0)) then
      Exit(True);
  end;
end;

function TBaseView.IsQueuedBuilding(Rule: TRuleBaseFacility): Boolean;
var
  i: Integer;
begin
  for i := 0 to Rule.GetSize - 1 do
  begin
    if (FGridX > 0) and (FFacilities[FGridX-1, FGridY+i] <> nil) and (FFacilities[FGridX-1, FGridY+i].GetBuildTime = 0) then
      Exit(False);
    if (FGridY > 0) and (FFacilities[FGridX+i, FGridY-1] <> nil) and (FFacilities[FGridX+i, FGridY-1].GetBuildTime = 0) then
      Exit(False);
    if (FGridX + Rule.GetSize < BASE_SIZE) and (FFacilities[FGridX + Rule.GetSize, FGridY+i] <> nil) and (FFacilities[FGridX + Rule.GetSize, FGridY+i].GetBuildTime = 0) then
      Exit(False);
    if (FGridY + Rule.GetSize < BASE_SIZE) and (FFacilities[FGridX+i, FGridY + Rule.GetSize] <> nil) and (FFacilities[FGridX+i, FGridY + Rule.GetSize].GetBuildTime = 0) then
      Exit(False);
  end;
  Result := True;
end;

procedure TBaseView.UpdateNeighborFacilityBuildTime(Facility, Neighbor: TBaseFacility);
begin
  if (Facility <> nil) and (Neighbor <> nil) and
     (Neighbor.GetBuildTime > Neighbor.GetRules.GetBuildTime) and
     (Facility.GetBuildTime + Neighbor.GetRules.GetBuildTime < Neighbor.GetBuildTime) then
    Neighbor.SetBuildTime(Facility.GetBuildTime + Neighbor.GetRules.GetBuildTime);
end;

procedure TBaseView.ReCalcQueuedBuildings;
var
  Facilities: TList<TBaseFacility>;
  Fac: TBaseFacility;
  i, x, y: Integer;
  Rule: TRuleBaseFacility;
  MinFac: TBaseFacility;
  MinIdx: Integer;
begin
  SetBase(FBase);
  Facilities := TList<TBaseFacility>.Create;
  try
    for Fac in FBase.GetFacilities do
      if Fac.GetBuildTime > 0 then
      begin
        if Fac.GetBuildTime > Fac.GetRules.GetBuildTime then
          Fac.SetBuildTime(MaxInt);
        Facilities.Add(Fac);
      end;

    while Facilities.Count > 0 do
    begin
      MinIdx := 0;
      for i := 1 to Facilities.Count-1 do
        if Facilities[i].GetBuildTime < Facilities[MinIdx].GetBuildTime then
          MinIdx := i;
      Fac := Facilities[MinIdx];
      Facilities.Delete(MinIdx);
      Rule := Fac.GetRules;
      x := Fac.GetX;
      y := Fac.GetY;
      for i := 0 to Rule.GetSize - 1 do
      begin
        if x > 0 then UpdateNeighborFacilityBuildTime(Fac, FFacilities[x-1, y+i]);
        if y > 0 then UpdateNeighborFacilityBuildTime(Fac, FFacilities[x+i, y-1]);
        if x + Rule.GetSize < BASE_SIZE then UpdateNeighborFacilityBuildTime(Fac, FFacilities[x + Rule.GetSize, y+i]);
        if y + Rule.GetSize < BASE_SIZE then UpdateNeighborFacilityBuildTime(Fac, FFacilities[x+i, y + Rule.GetSize]);
      end;
    end;
  finally
    Facilities.Free;
  end;
end;

procedure TBaseView.Think;
begin
  inherited;
  FTimer.Think(0, Self);
end;

procedure TBaseView.Blink(Sender: TObject);
var
  R: TRect;
begin
  FBlink := not FBlink;
  if FSelSize > 0 then
  begin
    R := Rect(0, 0, FSelector.Width, FSelector.Height);
    if FBlink then
    begin
      FSelector.DrawRect(R, FSelectorColor);
      R := Rect(1, 1, FSelector.Width-2, FSelector.Height-2);
      FSelector.DrawRect(R, 0);
    end
    else
      FSelector.DrawRect(R, 0);
  end;
end;

procedure TBaseView.Draw;
var
  x, y, num: Integer;
  Frame: TSurface;
  Fac: TBaseFacility;
  Craft: TCraft;
  TextObj: TText;
  ss: TStringStream;
begin
  inherited Draw;

  for x := 0 to BASE_SIZE-1 do
    for y := 0 to BASE_SIZE-1 do
    begin
      Frame := FTexture.GetFrame(0);
      Frame.SetX(x * GRID_SIZE);
      Frame.SetY(y * GRID_SIZE);
      Frame.Blit(Self);
    end;

  // Draw facility shapes
  for Fac in FBase.GetFacilities do
  begin
    num := 0;
    for y := Fac.GetY to Fac.GetY + Fac.GetRules.GetSize - 1 do
      for x := Fac.GetX to Fac.GetX + Fac.GetRules.GetSize - 1 do
      begin
        if Fac.GetBuildTime = 0 then
          Frame := FTexture.GetFrame(Fac.GetRules.GetSpriteShape + num)
        else
          Frame := FTexture.GetFrame(Fac.GetRules.GetSpriteShape + num + Max(Fac.GetRules.GetSize * Fac.GetRules.GetSize, 3));
        Frame.SetX(x * GRID_SIZE);
        Frame.SetY(y * GRID_SIZE);
        Frame.Blit(Self);
        Inc(num);
      end;
  end;

  // Draw connectors
  for Fac in FBase.GetFacilities do
  begin
    if Fac.GetBuildTime = 0 then
    begin
      x := Fac.GetX + Fac.GetRules.GetSize;
      if x < BASE_SIZE then
        for y := Fac.GetY to Fac.GetY + Fac.GetRules.GetSize - 1 do
          if (FFacilities[x, y] <> nil) and (FFacilities[x, y].GetBuildTime = 0) then
          begin
            Frame := FTexture.GetFrame(7);
            Frame.SetX(x * GRID_SIZE - GRID_SIZE div 2);
            Frame.SetY(y * GRID_SIZE);
            Frame.Blit(Self);
          end;
      y := Fac.GetY + Fac.GetRules.GetSize;
      if y < BASE_SIZE then
        for x := Fac.GetX to Fac.GetX + Fac.GetRules.GetSize - 1 do
          if (FFacilities[x, y] <> nil) and (FFacilities[x, y].GetBuildTime = 0) then
          begin
            Frame := FTexture.GetFrame(8);
            Frame.SetX(x * GRID_SIZE);
            Frame.SetY(y * GRID_SIZE - GRID_SIZE div 2);
            Frame.Blit(Self);
          end;
    end;
  end;

  // Draw facility graphics and crafts
  Craft := nil;
  for Fac in FBase.GetFacilities do
  begin
    num := 0;
    for y := Fac.GetY to Fac.GetY + Fac.GetRules.GetSize - 1 do
      for x := Fac.GetX to Fac.GetX + Fac.GetRules.GetSize - 1 do
      begin
        if Fac.GetRules.GetSize = 1 then
        begin
          Frame := FTexture.GetFrame(Fac.GetRules.GetSpriteFacility + num);
          Frame.SetX(x * GRID_SIZE);
          Frame.SetY(y * GRID_SIZE);
          Frame.Blit(Self);
        end;
        Inc(num);
      end;

    Fac.SetCraft(nil);
    if (Fac.GetBuildTime = 0) and (Fac.GetRules.GetCrafts > 0) then
    begin
      if Craft = nil then
        Craft := FBase.GetCrafts.First; // simplified
      if Craft <> nil then
      begin
        if Craft.GetStatus <> 'STR_OUT' then
        begin
          Frame := FTexture.GetFrame(Craft.GetRules.GetSprite + 33);
          Frame.SetX(Fac.GetX * GRID_SIZE + ((Fac.GetRules.GetSize - 1) * GRID_SIZE) div 2 + 2);
          Frame.SetY(Fac.GetY * GRID_SIZE + ((Fac.GetRules.GetSize - 1) * GRID_SIZE) div 2 - 4);
          Frame.Blit(Self);
          Fac.SetCraft(Craft);
        end;
        Craft := nil; // only one craft per facility? simplify
      end;
    end;

    // Draw build time
    if Fac.GetBuildTime > 0 then
    begin
      TextObj := TText.Create(GRID_SIZE * Fac.GetRules.GetSize, 16, 0, 0);
      TextObj.SetPalette(GetPalette);
      TextObj.InitText(FBigFont, FSmallFont, FLang);
      TextObj.SetX(Fac.GetX * GRID_SIZE);
      TextObj.SetY(Fac.GetY * GRID_SIZE + (GRID_SIZE * Fac.GetRules.GetSize - 16) div 2);
      TextObj.SetBig;
      ss := TStringStream.Create;
      try
        ss.WriteString(IntToStr(Fac.GetBuildTime));
        TextObj.SetAlign(ALIGN_CENTER);
        TextObj.SetColor(FCellColor);
        TextObj.SetText(ss.DataString);
        TextObj.Blit(Self);
      finally
        ss.Free;
        TextObj.Free;
      end;
    end;
  end;
end;

procedure TBaseView.Blit(Surface: TSurface);
begin
  inherited Blit(Surface);
  if FSelector <> nil then
    FSelector.Blit(Surface);
end;

procedure TBaseView.MouseOver(Action: TAction; State: TState);
begin
  FGridX := Floor(Action.GetRelativeXMouse / (GRID_SIZE * Action.GetXScale));
  FGridY := Floor(Action.GetRelativeYMouse / (GRID_SIZE * Action.GetYScale));
  if (FGridX >= 0) and (FGridX < BASE_SIZE) and (FGridY >= 0) and (FGridY < BASE_SIZE) then
  begin
    FSelFacility := FFacilities[FGridX, FGridY];
    if FSelSize > 0 then
    begin
      if (FGridX + FSelSize - 1 < BASE_SIZE) and (FGridY + FSelSize - 1 < BASE_SIZE) then
      begin
        FSelector.SetX(Self.X + FGridX * GRID_SIZE);
        FSelector.SetY(Self.Y + FGridY * GRID_SIZE);
        FSelector.Visible := True;
      end
      else
        FSelector.Visible := False;
    end;
  end
  else
  begin
    FSelFacility := nil;
    if FSelSize > 0 then
      FSelector.Visible := False;
  end;
  inherited MouseOver(Action, State);
end;

procedure TBaseView.MouseOut(Action: TAction; State: TState);
begin
  FSelFacility := nil;
  if FSelSize > 0 then
    FSelector.Visible := False;
  inherited MouseOut(Action, State);
end;

procedure TBaseView.SetColor(Color: Byte);
begin
  FCellColor := Color;
end;

procedure TBaseView.SetSecondaryColor(Color: Byte);
begin
  FSelectorColor := Color;
end;

end.