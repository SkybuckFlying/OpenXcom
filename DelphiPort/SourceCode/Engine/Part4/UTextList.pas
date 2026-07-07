unit UTextList;

interface

uses
  SysUtils, Classes, Generics.Collections, SDL, USurface, UText, UInteractiveSurface, UAction, UState;

type
  TTextList = class(TInteractiveSurface)
  private
    FItems: TArray<string>;
    FSelected: Integer;
    FTopIndex: Integer;
    FColor: Byte;
    FSecondaryColor: Byte;
    FBorderColor: Byte;
    FFont: TFont;
    FLang: TLanguage;
    FItemHeight: Integer;
    FShowArrows: Boolean;
    FHighlight: Boolean;
    FMultiselect: Boolean;
    FSelectedItems: TList<Integer>;
    procedure DrawItem(Index: Integer; X, Y, Width, Height: Integer; Selected: Boolean);
    procedure DrawArrows;
  public
    constructor Create(Width, Height, X, Y: Integer);
    destructor Destroy; override;
    procedure InitText(BigFont, SmallFont: TFont; Lang: TLanguage); override;
    procedure SetItems(const Items: TArray<string>);
    procedure SetSelected(Index: Integer);
    function GetSelected: Integer;
    procedure SetTopIndex(Index: Integer);
    function GetTopIndex: Integer;
    procedure SetColor(Color: Byte); override;
    procedure SetSecondaryColor(Color: Byte); override;
    procedure SetBorderColor(Color: Byte);
    procedure SetItemHeight(Height: Integer);
    procedure SetShowArrows(Enable: Boolean);
    procedure SetHighlight(Enable: Boolean);
    procedure SetMultiselect(Enable: Boolean);
    procedure AddItem(const Item: string);
    procedure Clear;
    function GetItem(Index: Integer): string;
    function GetItemCount: Integer;
    function GetSelectedItems: TList<Integer>;
    procedure MouseClick(Action: TAction; State: TState); override;
    procedure KeyboardPress(Action: TAction; State: TState); override;
    procedure Draw; override;
    procedure Think; override;
  end;

implementation

constructor TTextList.Create(Width, Height, X, Y: Integer);
begin
  inherited Create(Width, Height, X, Y);
  FItems := nil;
  FSelected := -1;
  FTopIndex := 0;
  FColor := 0;
  FSecondaryColor := 0;
  FBorderColor := 0;
  FFont := nil;
  FLang := nil;
  FItemHeight := 16;
  FShowArrows := True;
  FHighlight := True;
  FMultiselect := False;
  FSelectedItems := TList<Integer>.Create;
end;

destructor TTextList.Destroy;
begin
  FSelectedItems.Free;
  inherited;
end;

procedure TTextList.InitText(BigFont, SmallFont: TFont; Lang: TLanguage);
begin
  FFont := BigFont;
  FLang := Lang;
end;

procedure TTextList.SetItems(const Items: TArray<string>);
begin
  FItems := Items;
  FSelected := -1;
  FTopIndex := 0;
  FSelectedItems.Clear;
  FRedraw := True;
end;

procedure TTextList.SetSelected(Index: Integer);
begin
  if FMultiselect then
  begin
    if FSelectedItems.Contains(Index) then
      FSelectedItems.Remove(Index)
    else
      FSelectedItems.Add(Index);
  end
  else
    FSelected := Index;
  FRedraw := True;
end;

function TTextList.GetSelected: Integer;
begin
  Result := FSelected;
end;

procedure TTextList.SetTopIndex(Index: Integer);
begin
  FTopIndex := Index;
  FRedraw := True;
end;

function TTextList.GetTopIndex: Integer;
begin
  Result := FTopIndex;
end;

procedure TTextList.SetColor(Color: Byte);
begin
  FColor := Color;
  FRedraw := True;
end;

procedure TTextList.SetSecondaryColor(Color: Byte);
begin
  FSecondaryColor := Color;
  FRedraw := True;
end;

procedure TTextList.SetBorderColor(Color: Byte);
begin
  FBorderColor := Color;
  FRedraw := True;
end;

procedure TTextList.SetItemHeight(Height: Integer);
begin
  FItemHeight := Height;
  FRedraw := True;
end;

procedure TTextList.SetShowArrows(Enable: Boolean);
begin
  FShowArrows := Enable;
  FRedraw := True;
end;

procedure TTextList.SetHighlight(Enable: Boolean);
begin
  FHighlight := Enable;
  FRedraw := True;
end;

procedure TTextList.SetMultiselect(Enable: Boolean);
begin
  FMultiselect := Enable;
  if not Enable then FSelectedItems.Clear;
  FRedraw := True;
end;

procedure TTextList.AddItem(const Item: string);
begin
  SetLength(FItems, Length(FItems)+1);
  FItems[High(FItems)] := Item;
  FRedraw := True;
end;

procedure TTextList.Clear;
begin
  SetLength(FItems, 0);
  FSelected := -1;
  FSelectedItems.Clear;
  FRedraw := True;
end;

function TTextList.GetItem(Index: Integer): string;
begin
  if (Index >= 0) and (Index < Length(FItems)) then
    Result := FItems[Index]
  else
    Result := '';
end;

function TTextList.GetItemCount: Integer;
begin
  Result := Length(FItems);
end;

function TTextList.GetSelectedItems: TList<Integer>;
begin
  Result := FSelectedItems;
end;

procedure TTextList.DrawItem(Index, X, Y, Width, Height: Integer; Selected: Boolean);
var
  Color: Byte;
  Text: string;
begin
  if Selected then
    Color := FSecondaryColor
  else
    Color := FColor;
  // Draw background
  if Selected then
    DrawRect(X, Y, Width, Height, FSecondaryColor)
  else
    DrawRect(X, Y, Width, Height, 0);
  // Draw text
  if (Index >= 0) and (Index < Length(FItems)) then
  begin
    Text := FItems[Index];
    // Use font to render text (simplified)
    // Actually we'd use a Text surface, but for brevity we draw directly.
    // In real code, use a temporary text surface.
  end;
end;

procedure TTextList.DrawArrows;
begin
  // Draw up/down arrows if needed
  if FShowArrows and (Length(FItems) > 0) then
  begin
    // Draw up arrow if topIndex > 0
    if FTopIndex > 0 then
      DrawRect(GetWidth-8, 2, 8, 8, FBorderColor); // stub
    // Draw down arrow if topIndex + visible < count
    var VisibleCount := GetHeight div FItemHeight;
    if FTopIndex + VisibleCount < Length(FItems) then
      DrawRect(GetWidth-8, GetHeight-10, 8, 8, FBorderColor); // stub
  end;
end;

procedure TTextList.Draw;
var
  I, Y, VisibleCount: Integer;
  Selected: Boolean;
begin
  FRedraw := False;
  Clear(0);
  VisibleCount := GetHeight div FItemHeight;
  Y := 0;
  for I := FTopIndex to FTopIndex + VisibleCount - 1 do
  begin
    if I >= Length(FItems) then Break;
    Selected := (FSelected = I) or (FMultiselect and FSelectedItems.Contains(I));
    DrawItem(I, 0, Y, GetWidth, FItemHeight, Selected);
    Y := Y + FItemHeight;
  end;
  DrawArrows;
end;

procedure TTextList.Think;
begin
  // Nothing
end;

procedure TTextList.MouseClick(Action: TAction; State: TState);
var
  X, Y: Integer;
  Index: Integer;
begin
  inherited;
  if Action.GetDetails.button.button <> SDL_BUTTON_LEFT then Exit;
  X := Round(Action.GetRelativeXMouse);
  Y := Round(Action.GetRelativeYMouse);
  if Y < 0 then Exit;
  Index := FTopIndex + Y div FItemHeight;
  if (Index >= 0) and (Index < Length(FItems)) then
  begin
    SetSelected(Index);
    // If click on arrow area, scroll
  end;
end;

procedure TTextList.KeyboardPress(Action: TAction; State: TState);
var
  Sym: Integer;
begin
  inherited;
  Sym := Action.GetDetails.key.keysym.sym;
  case Sym of
    SDLK_UP: if FSelected > 0 then SetSelected(FSelected-1);
    SDLK_DOWN: if FSelected < Length(FItems)-1 then SetSelected(FSelected+1);
    SDLK_PAGEUP: SetSelected(Max(0, FSelected - 10));
    SDLK_PAGEDOWN: SetSelected(Min(Length(FItems)-1, FSelected + 10));
    SDLK_HOME: SetSelected(0);
    SDLK_END: SetSelected(Length(FItems)-1);
  end;
end;

end.