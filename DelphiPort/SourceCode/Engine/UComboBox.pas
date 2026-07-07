unit UComboBox;

interface

uses
  SysUtils, Classes, SDL, USurface, UText, UInteractiveSurface, UAction, UState, UTextList;

type
  TComboBox = class(TInteractiveSurface)
  private
    FItems: TArray<string>;
    FSelected: Integer;
    FColor: Byte;
    FSecondaryColor: Byte;
    FBorderColor: Byte;
    FFont: TFont;
    FLang: TLanguage;
    FExpanded: Boolean;
    FList: TTextList;
    FArrowColor: Byte;
    procedure DrawArrow;
    procedure ToggleList;
  public
    constructor Create(Width, Height, X, Y: Integer);
    destructor Destroy; override;
    procedure InitText(BigFont, SmallFont: TFont; Lang: TLanguage); override;
    procedure SetItems(const Items: TArray<string>);
    procedure SetSelected(Index: Integer);
    function GetSelected: Integer;
    procedure SetColor(Color: Byte); override;
    procedure SetSecondaryColor(Color: Byte); override;
    procedure SetBorderColor(Color: Byte);
    procedure SetArrowColor(Color: Byte);
    procedure MouseClick(Action: TAction; State: TState); override;
    procedure KeyboardPress(Action: TAction; State: TState); override;
    procedure Draw; override;
    procedure Think; override;
    procedure SetFocus(Focus: Boolean); override;
  end;

implementation

constructor TComboBox.Create(Width, Height, X, Y: Integer);
begin
  inherited Create(Width, Height, X, Y);
  FItems := nil;
  FSelected := -1;
  FColor := 0;
  FSecondaryColor := 0;
  FBorderColor := 0;
  FArrowColor := 0;
  FFont := nil;
  FLang := nil;
  FExpanded := False;
  FList := nil;
end;

destructor TComboBox.Destroy;
begin
  FList.Free;
  inherited;
end;

procedure TComboBox.InitText(BigFont, SmallFont: TFont; Lang: TLanguage);
begin
  FFont := BigFont;
  FLang := Lang;
end;

procedure TComboBox.SetItems(const Items: TArray<string>);
begin
  FItems := Items;
  FSelected := -1;
  FRedraw := True;
end;

procedure TComboBox.SetSelected(Index: Integer);
begin
  FSelected := Index;
  FRedraw := True;
end;

function TComboBox.GetSelected: Integer;
begin
  Result := FSelected;
end;

procedure TComboBox.SetColor(Color: Byte);
begin
  FColor := Color;
  FRedraw := True;
end;

procedure TComboBox.SetSecondaryColor(Color: Byte);
begin
  FSecondaryColor := Color;
  FRedraw := True;
end;

procedure TComboBox.SetBorderColor(Color: Byte);
begin
  FBorderColor := Color;
  FRedraw := True;
end;

procedure TComboBox.SetArrowColor(Color: Byte);
begin
  FArrowColor := Color;
  FRedraw := True;
end;

procedure TComboBox.DrawArrow;
begin
  if FArrowColor = 0 then FArrowColor := FSecondaryColor;
  // Draw down arrow
  var CX := GetWidth - 12;
  var CY := (GetHeight - 8) div 2;
  DrawLine(CX, CY, CX+4, CY+4, FArrowColor);
  DrawLine(CX+4, CY+4, CX+8, CY, FArrowColor);
end;

procedure TComboBox.ToggleList;
begin
  if FExpanded then
  begin
    FExpanded := False;
    if FList <> nil then
    begin
      FList.SetVisible(False);
      FList.SetHidden(True);
    end;
  end
  else
  begin
    FExpanded := True;
    if FList = nil then
    begin
      FList := TTextList.Create(GetWidth, 100, FX, FY + GetHeight);
      FList.InitText(FFont, FFont, FLang);
      FList.SetItems(FItems);
      FList.SetColor(FColor);
      FList.SetSecondaryColor(FSecondaryColor);
      FList.SetBorderColor(FBorderColor);
      FList.SetVisible(True);
      FList.SetHidden(False);
      // Add to state? This would need to be managed externally.
      // In practice, we'd need to add to the parent state.
    end
    else
    begin
      FList.SetVisible(True);
      FList.SetHidden(False);
    end;
  end;
end;

procedure TComboBox.MouseClick(Action: TAction; State: TState);
begin
  inherited;
  ToggleList;
end;

procedure TComboBox.KeyboardPress(Action: TAction; State: TState);
var
  Sym: Integer;
begin
  inherited;
  Sym := Action.GetDetails.key.keysym.sym;
  case Sym of
    SDLK_UP: if FSelected > 0 then SetSelected(FSelected-1);
    SDLK_DOWN: if FSelected < Length(FItems)-1 then SetSelected(FSelected+1);
    SDLK_RETURN, SDLK_SPACE: ToggleList;
    SDLK_ESCAPE: if FExpanded then ToggleList;
  end;
end;

procedure TComboBox.Draw;
begin
  FRedraw := False;
  Clear(0);
  // Draw background
  DrawRect(0, 0, GetWidth, GetHeight, FColor);
  // Draw border
  DrawRect(0, 0, GetWidth, 1, FBorderColor);
  DrawRect(0, GetHeight-1, GetWidth, 1, FBorderColor);
  DrawRect(0, 1, 1, GetHeight-2, FBorderColor);
  DrawRect(GetWidth-1, 1, 1, GetHeight-2, FBorderColor);
  // Draw selected text
  if (FSelected >= 0) and (FSelected < Length(FItems)) then
  begin
    // Use a Text surface to draw (simplified)
  end;
  DrawArrow;
end;

procedure TComboBox.Think;
begin
  if FExpanded and (FList <> nil) then
    FList.Think;
end;

procedure TComboBox.SetFocus(Focus: Boolean);
begin
  inherited;
  if not Focus and FExpanded then
    ToggleList;
end;

end.