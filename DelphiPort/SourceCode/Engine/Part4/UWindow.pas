unit UWindow;

interface

uses
  SysUtils, Classes, SDL, USurface, UPalette, UFont, ULanguage, UInteractiveSurface;

type
  TWindow = class(TInteractiveSurface)
  private
    FBackground: TSurface;
    FColor: Byte;
    FSecondaryColor: Byte;
    FBorderColor: Byte;
    FHighContrast: Boolean;
    FTFTDMode: Boolean;
    FInternalBorder: Boolean;
    FShaded: Boolean;
    FTitle: string;
    FTitleFont: TFont;
    FTitleY: Integer;
    procedure DrawBackground;
    procedure DrawBorder;
    procedure DrawTitle;
  public
    constructor Create(Width, Height, X, Y: Integer);
    destructor Destroy; override;
    procedure SetBackground(BG: TSurface);
    procedure SetColor(Color: Byte); override;
    procedure SetSecondaryColor(Color: Byte); override;
    procedure SetBorderColor(Color: Byte); override;
    procedure SetHighContrast(Contrast: Boolean); override;
    procedure SetTFTDMode(Mode: Boolean); override;
    procedure SetInternalBorder(Enable: Boolean);
    procedure SetShaded(Enable: Boolean);
    procedure SetTitle(const Title: string);
    procedure SetTitleFont(Font: TFont);
    procedure SetTitleY(Y: Integer);
    procedure Draw; override;
    procedure Think; override;
    procedure Blit(Dest: TSurface); override;
    procedure Invalidate(Valid: Boolean = True);
  end;

implementation

uses
  ULogger, UOptions, UCrossPlatform;

constructor TWindow.Create(Width, Height, X, Y: Integer);
begin
  inherited Create(Width, Height, X, Y);
  FBackground := nil;
  FColor := 0;
  FSecondaryColor := 0;
  FBorderColor := 0;
  FHighContrast := False;
  FTFTDMode := False;
  FInternalBorder := True;
  FShaded := False;
  FTitle := '';
  FTitleFont := nil;
  FTitleY := 0;
end;

destructor TWindow.Destroy;
begin
  // FBackground is owned externally
  inherited;
end;

procedure TWindow.SetBackground(BG: TSurface);
begin
  FBackground := BG;
  FRedraw := True;
end;

procedure TWindow.SetColor(Color: Byte);
begin
  FColor := Color;
  FRedraw := True;
end;

procedure TWindow.SetSecondaryColor(Color: Byte);
begin
  FSecondaryColor := Color;
  FRedraw := True;
end;

procedure TWindow.SetBorderColor(Color: Byte);
begin
  FBorderColor := Color;
  FRedraw := True;
end;

procedure TWindow.SetHighContrast(Contrast: Boolean);
begin
  FHighContrast := Contrast;
  FRedraw := True;
end;

procedure TWindow.SetTFTDMode(Mode: Boolean);
begin
  FTFTDMode := Mode;
  FRedraw := True;
end;

procedure TWindow.SetInternalBorder(Enable: Boolean);
begin
  FInternalBorder := Enable;
  FRedraw := True;
end;

procedure TWindow.SetShaded(Enable: Boolean);
begin
  FShaded := Enable;
  FRedraw := True;
end;

procedure TWindow.SetTitle(const Title: string);
begin
  FTitle := Title;
  FRedraw := True;
end;

procedure TWindow.SetTitleFont(Font: TFont);
begin
  FTitleFont := Font;
  FRedraw := True;
end;

procedure TWindow.SetTitleY(Y: Integer);
begin
  FTitleY := Y;
  FRedraw := True;
end;

procedure TWindow.DrawBackground;
begin
  if FBackground <> nil then
  begin
    // Blit background (tiled or stretched)
    if (FBackground.GetWidth = GetWidth) and (FBackground.GetHeight = GetHeight) then
      SDL_BlitSurface(FBackground.GetSurface, nil, FSurface, nil)
    else
    begin
      // Tile or stretch (simplified: fill with background color)
      Clear(FColor);
    end;
  end
  else
    Clear(FColor);
end;

procedure TWindow.DrawBorder;
var
  R: TSDL_Rect;
  BorderColor: Byte;
begin
  if not FInternalBorder then Exit;
  BorderColor := FBorderColor;
  if BorderColor = 0 then BorderColor := FColor;
  // Draw 1-pixel border
  R.x := 0; R.y := 0; R.w := GetWidth; R.h := 1;
  DrawRect(R, BorderColor);
  R.y := GetHeight - 1;
  DrawRect(R, BorderColor);
  R.x := 0; R.y := 1; R.w := 1; R.h := GetHeight - 2;
  DrawRect(R, BorderColor);
  R.x := GetWidth - 1;
  DrawRect(R, BorderColor);
  // Draw inner shadow if shaded
  if FShaded then
  begin
    // Simple shadow effect (stub)
  end;
end;

procedure TWindow.DrawTitle;
var
  Surf: TSurface;
  Rect: TSDL_Rect;
  X, Y: Integer;
begin
  if FTitle = '' then Exit;
  if FTitleFont = nil then Exit;
  // Calculate title position
  Y := FTitleY;
  if Y = 0 then Y := 2;
  // Draw title using font (stub)
  // In real implementation, loop over characters and blit
end;

procedure TWindow.Draw;
begin
  FRedraw := False;
  DrawBackground;
  DrawBorder;
  DrawTitle;
  // Draw any child elements? No, they are separate surfaces.
end;

procedure TWindow.Think;
begin
  // Nothing
end;

procedure TWindow.Blit(Dest: TSurface);
begin
  if FRedraw then Draw;
  inherited;
end;

procedure TWindow.Invalidate(Valid: Boolean);
begin
  FRedraw := Valid;
end;

end.