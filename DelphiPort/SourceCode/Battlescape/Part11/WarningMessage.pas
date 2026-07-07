unit WarningMessage;

interface

uses
  Engine.Surface, Engine.Timer, Interface.Text, System.SysUtils, System.Classes, SDL;

type
  TWarningMessage = class(TSurface)
  private
    FText: TText;
    FTimer: TTimer;
    FColor: Byte;
    FFade: Byte;
    procedure Fade;
  public
    constructor Create(Width, Height, X, Y: Integer);
    destructor Destroy; override;
    procedure SetColor(Color: Byte);
    procedure SetTextColor(Color: Byte);
    procedure InitText(BigFont, SmallFont: TFont; Lang: TLanguage);
    procedure SetPalette(Colors: PSDL_Color; FirstColor, NColors: Integer);
    procedure ShowMessage(const Msg: string);
    procedure Think;
    procedure Draw; override;
  end;

implementation

constructor TWarningMessage.Create(Width, Height, X, Y: Integer);
begin
  inherited Create(Width, Height, X, Y);
  FColor := 0;
  FFade := 0;
  FText := TText.Create(Width, Height, 0, 0);
  FText.SetHighContrast(True);
  FText.SetAlign(ALIGN_CENTER);
  FText.SetVerticalAlign(ALIGN_MIDDLE);
  FText.SetWordWrap(True);
  FTimer := TTimer.Create(50);
  FTimer.OnTimer := Fade;
  SetVisible(False);
end;

destructor TWarningMessage.Destroy;
begin
  FTimer.Free;
  FText.Free;
  inherited;
end;

procedure TWarningMessage.SetColor(Color: Byte);
begin
  FColor := Color;
end;

procedure TWarningMessage.SetTextColor(Color: Byte);
begin
  FText.SetColor(Color);
end;

procedure TWarningMessage.InitText(BigFont, SmallFont: TFont; Lang: TLanguage);
begin
  FText.InitText(BigFont, SmallFont, Lang);
end;

procedure TWarningMessage.SetPalette(Colors: PSDL_Color; FirstColor, NColors: Integer);
begin
  inherited SetPalette(Colors, FirstColor, NColors);
  FText.SetPalette(Colors, FirstColor, NColors);
end;

procedure TWarningMessage.ShowMessage(const Msg: string);
begin
  FText.SetText(Msg);
  FFade := 0;
  Redraw := True;
  SetVisible(True);
  FTimer.Start;
end;

procedure TWarningMessage.Think;
begin
  FTimer.Think(0, Self);
end;

procedure TWarningMessage.Fade;
begin
  Inc(FFade);
  Redraw := True;
  if FFade = 24 then
  begin
    SetVisible(False);
    FTimer.Stop;
  end;
end;

procedure TWarningMessage.Draw;
var
  col: Byte;
begin
  inherited Draw;
  if FFade > 12 then
    col := FColor + 12
  else
    col := FColor + FFade;
  DrawRect(0, 0, GetWidth, GetHeight, col);
  FText.Blit(Self);
end;

end.