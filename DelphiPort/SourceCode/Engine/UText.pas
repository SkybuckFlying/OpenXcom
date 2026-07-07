unit UText;

interface

uses
  SysUtils, Classes, SDL, USurface, UFont, ULanguage, ULocalizedText, UInteractiveSurface;

type
  TText = class(TInteractiveSurface)
  private
    FText: UString;
    FFont: TFont;
    FLang: TLanguage;
    FColor: Byte;
    FSecondaryColor: Byte;
    FHighContrast: Boolean;
    FWordWrap: Boolean;
    FAlign: Integer; // 0=left, 1=center, 2=right
    FVerticalAlign: Integer; // 0=top, 1=center, 2=bottom
    FInvert: Boolean;
    FContrast: Boolean;
    FTextDirection: Integer; // 0=LTR, 1=RTL
    procedure DrawText;
  public
    constructor Create(Width, Height, X, Y: Integer);
    destructor Destroy; override;
    procedure InitText(BigFont, SmallFont: TFont; Lang: TLanguage); override;
    procedure SetText(const Text: UString);
    procedure SetText(const Text: string);
    procedure SetColor(Color: Byte); override;
    procedure SetSecondaryColor(Color: Byte); override;
    procedure SetHighContrast(Contrast: Boolean); override;
    procedure SetWordWrap(Enable: Boolean);
    procedure SetAlign(Align: Integer);
    procedure SetVerticalAlign(Align: Integer);
    procedure SetInvert(Enable: Boolean);
    procedure SetContrast(Enable: Boolean);
    procedure SetTextDirection(Direction: Integer);
    procedure Draw; override;
    procedure Think; override;
  end;

implementation

uses
  UUnicode, UOptions;

constructor TText.Create(Width, Height, X, Y: Integer);
begin
  inherited Create(Width, Height, X, Y);
  FFont := nil;
  FLang := nil;
  FColor := 0;
  FSecondaryColor := 0;
  FHighContrast := False;
  FWordWrap := False;
  FAlign := 0;
  FVerticalAlign := 0;
  FInvert := False;
  FContrast := False;
  FTextDirection := 0;
end;

destructor TText.Destroy;
begin
  inherited;
end;

procedure TText.InitText(BigFont, SmallFont: TFont; Lang: TLanguage);
begin
  FFont := BigFont; // simplified; actual logic chooses font based on tokens
  FLang := Lang;
end;

procedure TText.SetText(const Text: UString);
begin
  FText := Text;
  FRedraw := True;
end;

procedure TText.SetText(const Text: string);
begin
  SetText(Unicode.ConvUtf8ToUtf32(Text));
end;

procedure TText.SetColor(Color: Byte);
begin
  FColor := Color;
  FRedraw := True;
end;

procedure TText.SetSecondaryColor(Color: Byte);
begin
  FSecondaryColor := Color;
  FRedraw := True;
end;

procedure TText.SetHighContrast(Contrast: Boolean);
begin
  FHighContrast := Contrast;
  FRedraw := True;
end;

procedure TText.SetWordWrap(Enable: Boolean);
begin
  FWordWrap := Enable;
  FRedraw := True;
end;

procedure TText.SetAlign(Align: Integer);
begin
  FAlign := Align;
  FRedraw := True;
end;

procedure TText.SetVerticalAlign(Align: Integer);
begin
  FVerticalAlign := Align;
  FRedraw := True;
end;

procedure TText.SetInvert(Enable: Boolean);
begin
  FInvert := Enable;
  FRedraw := True;
end;

procedure TText.SetContrast(Enable: Boolean);
begin
  FContrast := Enable;
  FRedraw := True;
end;

procedure TText.SetTextDirection(Direction: Integer);
begin
  FTextDirection := Direction;
  FRedraw := True;
end;

procedure TText.DrawText;
var
  Lines: TArray<UString>;
  Line, Word: UString;
  I, X, Y, LineHeight, TotalHeight, SpaceWidth: Integer;
  C: UCode;
  Surf: TSurface;
  Rect: TSDL_Rect;
  Color: Byte;
  CharSurf: TSurface;
  CharRect: TSDL_Rect;
begin
  if FFont = nil then Exit;
  if FText = '' then Exit;
  // Simple word wrap (stub)
  // For brevity, we'll just render one line.
  Line := FText;
  X := 0; Y := 0;
  LineHeight := FFont.GetHeight + FFont.GetSpacing;
  SpaceWidth := FFont.GetCharSize(' ').w;
  // Loop over characters
  for I := 1 to Length(Line) do
  begin
    C := Line[I];
    if C = Unicode.TOK_COLOR_FLIP then
    begin
      // Flip color (simplified)
      if Color = FColor then Color := FSecondaryColor else Color := FColor;
      Continue;
    end;
    if C = Unicode.TOK_NL_SMALL then
    begin
      // Switch to small font? (stub)
      Continue;
    end;
    if C = #10 then // newline
    begin
      X := 0;
      Y := Y + LineHeight;
      Continue;
    end;
    // Draw character
    CharSurf := FFont.GetChar(C);
    CharRect := CharSurf.GetCrop^;
    Rect.x := FX + X; Rect.y := FY + Y; Rect.w := CharRect.w; Rect.h := CharRect.h;
    // Blit directly? We'll do it here.
    if not FInvert then
      SDL_BlitSurface(CharSurf.GetSurface, @CharRect, FSurface, @Rect)
    else
    begin
      // Inverted blit (stub)
    end;
    X := X + FFont.GetCharSize(C).w;
  end;
end;

procedure TText.Draw;
begin
  FRedraw := False;
  Clear(0); // transparent background
  DrawText;
end;

procedure TText.Think;
begin
  // Nothing
end;

end.