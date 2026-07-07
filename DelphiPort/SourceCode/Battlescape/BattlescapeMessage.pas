unit BattlescapeMessage;

interface

uses
  System.SysUtils,
  Engine.Surface, Interface.Window, Interface.Text, Engine.Font, Engine.Language;

type
  TBattlescapeMessage = class(TSurface)
  private
    FWindow: TWindow;
    FText: TText;
  public
    constructor Create(AWidth, AHeight, AX, AY: Integer);
    destructor Destroy; override;
    procedure SetX(X: Integer); override;
    procedure SetY(Y: Integer); override;
    procedure SetBackground(ABackground: TSurface);
    procedure SetText(const AMessage: string);
    procedure InitText(Big, Small: TFont; Lang: TLanguage);
    procedure SetPalette(AColors: PSDL_Color; AFirstColor: Integer = 0; ANColors: Integer = 256); override;
    procedure Blit(ASurface: TSurface); override;
    procedure SetHeight(AHeight: Integer); override;
    procedure SetTextColor(AColor: Byte);
  end;

implementation

uses Engine.Palette;

constructor TBattlescapeMessage.Create(AWidth, AHeight, AX, AY: Integer);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FWindow := TWindow.Create(Self, AWidth, AHeight, AX, AY, POPUP_NONE);
  FWindow.SetColor(Palette.BlockOffset(0) - 1);
  FWindow.SetHighContrast(True);
  FText := TText.Create(AWidth, AHeight, AX, AY);
  FText.SetColor(Palette.BlockOffset(0) - 1);
  FText.SetAlign(ALIGN_CENTER);
  FText.SetVerticalAlign(ALIGN_MIDDLE);
  FText.SetHighContrast(True);
end;

destructor TBattlescapeMessage.Destroy;
begin
  FWindow.Free;
  FText.Free;
  inherited;
end;

procedure TBattlescapeMessage.SetX(X: Integer);
begin
  inherited SetX(X);
  FWindow.SetX(X);
  FText.SetX(X);
end;

procedure TBattlescapeMessage.SetY(Y: Integer);
begin
  inherited SetY(Y);
  FWindow.SetY(Y);
  FText.SetY(Y);
end;

procedure TBattlescapeMessage.SetBackground(ABackground: TSurface);
begin
  FWindow.SetBackground(ABackground);
end;

procedure TBattlescapeMessage.SetText(const AMessage: string);
begin
  FText.SetText(AMessage);
end;

procedure TBattlescapeMessage.InitText(Big, Small: TFont; Lang: TLanguage);
begin
  FText.InitText(Big, Small, Lang);
  FText.SetBig;
end;

procedure TBattlescapeMessage.SetPalette(AColors: PSDL_Color; AFirstColor, ANColors: Integer);
begin
  inherited SetPalette(AColors, AFirstColor, ANColors);
  FWindow.SetPalette(AColors, AFirstColor, ANColors);
  FText.SetPalette(AColors, AFirstColor, ANColors);
end;

procedure TBattlescapeMessage.Blit(ASurface: TSurface);
begin
  inherited Blit(ASurface);
  FWindow.Blit(ASurface);
  FText.Blit(ASurface);
end;

procedure TBattlescapeMessage.SetHeight(AHeight: Integer);
begin
  inherited SetHeight(AHeight);
  FWindow.SetHeight(AHeight);
  FText.SetHeight(AHeight);
end;

procedure TBattlescapeMessage.SetTextColor(AColor: Byte);
begin
  FText.SetColor(AColor);
end;

end.