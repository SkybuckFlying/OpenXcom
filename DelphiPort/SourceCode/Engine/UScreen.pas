unit UScreen;

interface

uses
  SysUtils, SDL, USurface, UOptions, UAction, UOpenGL;

type
  TScreen = class
  private
    FScreen: PSDL_Surface;
    FBuffer: TSurface;
    FScaleX, FScaleY: Double;
    FTopBlackBand, FBottomBlackBand, FLeftBlackBand, FRightBlackBand: Integer;
    FCursorTopBlackBand, FCursorLeftBlackBand: Integer;
    FFlags: UInt32;
    FDeferredPalette: array[0..255] of TSDL_Color;
    FNumColors, FFirstColor: Integer;
    FPushPalette: Boolean;
    FOpenGL: TOpenGL;
    procedure MakeVideoFlags;
    procedure ResetDisplay(ResetVideo: Boolean = True);
  public
    constructor Create;
    destructor Destroy; override;
    function GetSurface: TSurface;
    procedure Handle(Action: TAction);
    procedure Flip;
    procedure Clear;
    procedure SetPalette(Colors: PSDL_Color; FirstColor, NColors: Integer; Immediate: Boolean = False);
    function GetPalette: PSDL_Color;
    function GetWidth: Integer;
    function GetHeight: Integer;
    function GetXScale: Double;
    function GetYScale: Double;
    function GetCursorTopBlackBand: Integer;
    function GetCursorLeftBlackBand: Integer;
    procedure Screenshot(const Filename: string);
    class function Use32bitScaler: Boolean;
    class function UseOpenGL: Boolean;
    class procedure UpdateScale(ScaleType, var Width, Height: Integer; Change: Boolean);
  end;

const
  ORIGINAL_WIDTH = 320;
  ORIGINAL_HEIGHT = 200;

implementation

uses
  UException, ULogger, UCrossPlatform, UZoom, UFileMap;

constructor TScreen.Create;
begin
  FBuffer := TSurface.Create(ORIGINAL_WIDTH, ORIGINAL_HEIGHT);
  ResetDisplay;
end;

destructor TScreen.Destroy;
begin
  FBuffer.Free;
  inherited;
end;

procedure TScreen.MakeVideoFlags;
begin
  FFlags := SDL_HWSURFACE or SDL_DOUBLEBUF or SDL_HWPALETTE;
  if UOptions.asyncBlit then
    FFlags := FFlags or SDL_ASYNCBLIT;
  if UseOpenGL then
  begin
    FFlags := SDL_OPENGL;
    SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 5);
    SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 5);
    SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 5);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
  end;
  if UOptions.allowResize then
    FFlags := FFlags or SDL_RESIZABLE;
  // Window positioning, etc. (simplified)
end;

procedure TScreen.ResetDisplay(ResetVideo: Boolean);
var
  Width, Height: Integer;
begin
  Width := UOptions.displayWidth;
  Height := UOptions.displayHeight;
  MakeVideoFlags;
  // Recreate buffer if needed
  if (FBuffer = nil) or (FBuffer.GetSurface^.format^.BitsPerPixel <> 8) etc... // simplified
  // Create screen
  if ResetVideo then
  begin
    FScreen := SDL_SetVideoMode(Width, Height, 8, FFlags);
    if FScreen = nil then
      raise EOpenXcom.Create(SDL_GetError);
    UOptions.displayWidth := FScreen^.w;
    UOptions.displayHeight := FScreen^.h;
  end;
  // Calculate scaling and black bands (simplified)
  FScaleX := FScreen^.w / ORIGINAL_WIDTH;
  FScaleY := FScreen^.h / ORIGINAL_HEIGHT;
end;

procedure TScreen.Flip;
begin
  // Apply zoom if needed
  if UseOpenGL then
  begin
    // Use OpenGL
  end
  else
    SDL_BlitSurface(FBuffer.GetSurface, nil, FScreen, nil);
  // Palette update
  if FPushPalette and (FScreen^.format^.BitsPerPixel = 8) then
  begin
    SDL_SetColors(FScreen, @FDeferredPalette[FFirstColor], FFirstColor, FNumColors);
    FNumColors := 0;
    FPushPalette := False;
  end;
  SDL_Flip(FScreen);
end;

// Other methods omitted for brevity, but full implementation would be provided.
// For this bundle we include the core skeleton.
end.