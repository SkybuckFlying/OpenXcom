unit TextList;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics,
  Common, ArrowButton, ScrollBar, ComboBox, Font, Language, Options;

type
  TArrowOrientation = (aoVertical, aoHorizontal);

  TTextList = class(TInteractiveSurface)
  private
    FTexts: TArray<TArray<TText>>;
    FColumns: TArray<Integer>;
    FRows: TArray<Integer>; // mapping to physical row index
    FBigFont: TFont;
    FSmallFont: TFont;
    FCurrentFont: TFont;
    FLang: TLanguage;
    FScroll: Integer;
    FVisibleRows: Integer;
    FSelRow: Integer;
    FColor: TColor;
    FColor2: TColor;
    FAlign: array of TTextHAlign;
    FDot: Boolean;
    FSelectable: Boolean;
    FCondensed: Boolean;
    FContrast: Boolean;
    FWrap: Boolean;
    FFlooding: Boolean;
    FBg: TSurface;
    FSelector: TSurface;
    FUp: TArrowButton;
    FDown: TArrowButton;
    FScrollBar: TScrollBar;
    FMargin: Integer;
    FScrolling: Boolean;
    FArrowLeft: TArray<TArrowButton>;
    FArrowRight: TArray<TArrowButton>;
    FArrowPos: Integer;
    FScrollPos: Integer;
    FArrowType: TArrowOrientation;
    FLeftClick: TNotifyEvent;
    FLeftPress: TNotifyEvent;
    FLeftRelease: TNotifyEvent;
    FRightClick: TNotifyEvent;
    FRightPress: TNotifyEvent;
    FRightRelease: TNotifyEvent;
    FArrowsLeftEdge: Integer;
    FArrowsRightEdge: Integer;
    FComboBox: TComboBox;
    procedure UpdateArrows;
    procedure UpdateVisible;
  public
    constructor Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent); reintroduce;
    destructor Destroy; override;
    procedure SetX(X: Integer); override;
    procedure SetY(Y: Integer); override;
    function GetArrowsLeftEdge: Integer;
    function GetArrowsRightEdge: Integer;
    procedure Unpress(State: TState);
    procedure SetCellColor(Row, Col: Integer; Color: TColor);
    procedure SetRowColor(Row: Integer; Color: TColor);
    function GetCellText(Row, Col: Integer): string;
    procedure SetCellText(Row, Col: Integer; const Text: string);
    function GetColumnX(Col: Integer): Integer;
    function GetRowY(Row: Integer): Integer;
    function GetTextHeight(Row: Integer): Integer;
    function GetNumTextLines(Row: Integer): Integer;
    function GetTexts: Integer;
    function GetRows: Integer;
    function GetVisibleRows: Integer;
    procedure AddRow(Cols: Integer; const Args: array of string);
    procedure SetColumns(Cols: Integer; const Widths: array of Integer);
    procedure SetPalette(const Colors: array of TColor; FirstColor, NumColors: Integer); override;
    procedure InitText(Big, Small: TFont; Lang: TLanguage);
    procedure SetHeight(AHeight: Integer); override;
    procedure SetColor(Color: TColor);
    function GetColor: TColor;
    procedure SetSecondaryColor(Color: TColor);
    function GetSecondaryColor: TColor;
    procedure SetWordWrap(Wrap: Boolean);
    procedure SetHighContrast(Contrast: Boolean);
    procedure SetAlign(Align: TTextHAlign; Col: Integer = -1);
    procedure SetDot(Dot: Boolean);
    procedure SetSelectable(Selectable: Boolean);
    procedure SetBig;
    procedure SetSmall;
    procedure SetCondensed(Condensed: Boolean);
    procedure SetBackground(BG: TSurface);
    function GetSelectedRow: Integer;
    procedure SetMargin(Margin: Integer);
    function GetMargin: Integer;
    procedure SetArrowColor(Color: TColor);
    procedure SetArrowColumn(Pos: Integer; Orientation: TArrowOrientation);
    procedure OnLeftArrowClick(Handler: TNotifyEvent);
    procedure OnLeftArrowPress(Handler: TNotifyEvent);
    procedure OnLeftArrowRelease(Handler: TNotifyEvent);
    procedure OnRightArrowClick(Handler: TNotifyEvent);
    procedure OnRightArrowPress(Handler: TNotifyEvent);
    procedure OnRightArrowRelease(Handler: TNotifyEvent);
    procedure ClearList;
    procedure ScrollUp(ToMax: Boolean; ScrollByWheel: Boolean = False);
    procedure ScrollDown(ToMax: Boolean; ScrollByWheel: Boolean = False);
    procedure SetScrolling(Scrolling: Boolean; ScrollPos: Integer = 4);
    procedure DrawContent; override;
    procedure Blit(Dest: TSurface); override;
    procedure Think; override;
    procedure Handle(Action: TAction; State: TState); override;
    procedure MousePress(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseRelease(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseClick(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseOver(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseOut(Shift: TShiftState; X, Y: Integer); override;
    function GetScroll: Integer;
    procedure ScrollTo(Scroll: Integer);
    procedure SetComboBox(ComboBox: TComboBox);
    function GetComboBox: TComboBox;
    procedure SetBorderColor(Color: TColor);
    function GetScrollbarColor: TColor;
    procedure SetFlooding(Flooding: Boolean);
  end;

implementation

uses
  Math, Windows, ShaderDraw;

constructor TTextList.Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := AWidth;
  Height := AHeight;
  Left := AX;
  Top := AY;
  FScroll := 0;
  FVisibleRows := 0;
  FSelRow := 0;
  FColor := 0;
  FColor2 := 0;
  FDot := False;
  FSelectable := False;
  FCondensed := False;
  FContrast := False;
  FWrap := False;
  FFlooding := False;
  FMargin := 0;
  FScrolling := True;
  FArrowPos := -1;
  FScrollPos := 4;
  FArrowType := aoVertical;
  FComboBox := nil;

  FUp := TArrowButton.Create(asBigUp, 13, 14, Left + Width + FScrollPos, Top, Self);
  FUp.Visible := False;
  FUp.SetTextList(Self);
  FDown := TArrowButton.Create(asBigDown, 13, 14, Left + Width + FScrollPos, Top + Height - 14, Self);
  FDown.Visible := False;
  FDown.SetTextList(Self);
  FScrollBar := TScrollBar.Create(13, Max(1, FDown.Top - FUp.Top - FUp.Height), Left + Width + FScrollPos, FUp.Top + FUp.Height, Self);
  FScrollBar.Visible := False;
  FScrollBar.SetTextList(Self);
end;

destructor TTextList.Destroy;
var
  I, J: Integer;
begin
  for I := 0 to High(FTexts) do
    for J := 0 to High(FTexts[I]) do
      FTexts[I][J].Free;
  for I := 0 to High(FArrowLeft) do
  begin
    FArrowLeft[I].Free;
    FArrowRight[I].Free;
  end;
  FSelector.Free;
  FUp.Free;
  FDown.Free;
  FScrollBar.Free;
  inherited;
end;

procedure TTextList.SetX(X: Integer);
begin
  inherited SetX(X);
  FUp.Left := X + Width + FScrollPos;
  FDown.Left := X + Width + FScrollPos;
  FScrollBar.Left := X + Width + FScrollPos;
  if FSelector <> nil then
    FSelector.Left := X;
end;

procedure TTextList.SetY(Y: Integer);
begin
  inherited SetY(Y);
  FUp.Top := Y;
  FDown.Top := Y + Height - 14;
  FScrollBar.Top := FUp.Top + FUp.Height;
  if FSelector <> nil then
    FSelector.Top := Y;
end;

function TTextList.GetArrowsLeftEdge: Integer;
begin
  Result := FArrowsLeftEdge;
end;

function TTextList.GetArrowsRightEdge: Integer;
begin
  Result := FArrowsRightEdge;
end;

procedure TTextList.Unpress(State: TState);
var
  I: Integer;
begin
  inherited Unpress(State);
  for I := 0 to High(FArrowLeft) do
    FArrowLeft[I].Unpress(State);
  for I := 0 to High(FArrowRight) do
    FArrowRight[I].Unpress(State);
end;

procedure TTextList.SetCellColor(Row, Col: Integer; Color: TColor);
begin
  if (Row >= 0) and (Row < Length(FTexts)) and (Col < Length(FTexts[Row])) then
  begin
    FTexts[Row][Col].SetColor(Color);
    Redraw := True;
  end;
end;

procedure TTextList.SetRowColor(Row: Integer; Color: TColor);
var
  C: Integer;
begin
  if (Row >= 0) and (Row < Length(FTexts)) then
  begin
    for C := 0 to High(FTexts[Row]) do
      FTexts[Row][C].SetColor(Color);
    Redraw := True;
  end;
end;

function TTextList.GetCellText(Row, Col: Integer): string;
begin
  if (Row >= 0) and (Row < Length(FTexts)) and (Col < Length(FTexts[Row])) then
    Result := FTexts[Row][Col].GetText
  else
    Result := '';
end;

procedure TTextList.SetCellText(Row, Col: Integer; const Text: string);
begin
  if (Row >= 0) and (Row < Length(FTexts)) and (Col < Length(FTexts[Row])) then
  begin
    FTexts[Row][Col].SetText(Text);
    Redraw := True;
  end;
end;

function TTextList.GetColumnX(Col: Integer): Integer;
begin
  if (Col >= 0) and (Col < Length(FTexts[0])) then
    Result := Left + FTexts[0][Col].Left
  else
    Result := 0;
end;

function TTextList.GetRowY(Row: Integer): Integer;
begin
  if (Row >= 0) and (Row < Length(FTexts)) then
    Result := Top + FTexts[Row][0].Top
  else
    Result := 0;
end;

function TTextList.GetTextHeight(Row: Integer): Integer;
begin
  if (Row >= 0) and (Row < Length(FTexts)) and (Length(FTexts[Row]) > 0) then
    Result := FTexts[Row][0].GetTextHeight
  else
    Result := 0;
end;

function TTextList.GetNumTextLines(Row: Integer): Integer;
begin
  if (Row >= 0) and (Row < Length(FTexts)) and (Length(FTexts[Row]) > 0) then
    Result := FTexts[Row][0].GetNumLines
  else
    Result := 0;
end;

function TTextList.GetTexts: Integer;
begin
  Result := Length(FTexts);
end;

function TTextList.GetRows: Integer;
begin
  Result := Length(FRows);
end;

function TTextList.GetVisibleRows: Integer;
begin
  Result := FVisibleRows;
end;

procedure TTextList.AddRow(Cols: Integer; const Args: array of string);
var
  I, RowX, RowY, Rows, RowHeight, VMargin: Integer;
  Txt: TText;
begin
  RowX := 0;
  RowY := 0;
  if Length(FTexts) > 0 then
    RowY := FTexts[High(FTexts)][0].Top + FTexts[High(FTexts)][0].Height + FCurrentFont.Spacing;
  Rows := 1;
  RowHeight := 0;
  // Create Text objects
  SetLength(FTexts, Length(FTexts)+1);
  SetLength(FTexts[High(FTexts)], Cols);
  for I := 0 to Cols-1 do
  begin
    if FFlooding then
      Txt := TText.Create(340, FCurrentFont.Height, FMargin + RowX, RowY, Self)
    else
      Txt := TText.Create(FColumns[I], FCurrentFont.Height, FMargin + RowX, RowY, Self);
    Txt.SetPalette(GetPalette, 0, 256);
    Txt.InitText(FBigFont, FSmallFont, FLang);
    Txt.SetColor(FColor);
    Txt.SetSecondaryColor(FColor2);
    if I < Length(FAlign) then
      Txt.SetAlign(FAlign[I]);
    Txt.SetHighContrast(FContrast);
    if FCurrentFont = FBigFont then
      Txt.SetBig
    else
      Txt.SetSmall;
    if I < Length(Args) then
      Txt.SetText(Args[I]);
    VMargin := FCurrentFont.Height - Txt.GetTextHeight;
    if FWrap and (Txt.GetTextWidth > Txt.Width) then
    begin
      Txt.SetWordWrap(True, True);
      Rows := Max(Rows, Txt.GetNumLines);
    end;
    RowHeight := Max(RowHeight, Txt.GetTextHeight + VMargin);
    if FDot and (I < Cols-1) then
    begin
      // add dots (simplified)
    end;
    FTexts[High(FTexts)][I] := Txt;
    if FCondensed then
      RowX := RowX + Txt.GetTextWidth
    else
      RowX := RowX + FColumns[I];
  end;
  // Set all same height
  for I := 0 to Cols-1 do
    FTexts[High(FTexts)][I].Height := RowHeight;
  // Update FRows (add multiple entries for wrapped lines)
  for I := 0 to Rows-1 do
  begin
    SetLength(FRows, Length(FRows)+1);
    FRows[High(FRows)] := High(FTexts);
  end;
  // Arrow buttons if needed
  if FArrowPos <> -1 then
  begin
    // create arrows (simplified)
  end;
  Redraw := True;
  UpdateArrows;
end;

procedure TTextList.SetColumns(Cols: Integer; const Widths: array of Integer);
var
  I: Integer;
begin
  SetLength(FColumns, Cols);
  for I := 0 to Cols-1 do
    if I < Length(Widths) then
      FColumns[I] := Widths[I]
    else
      FColumns[I] := 0;
  SetLength(FAlign, Cols);
  for I := 0 to Cols-1 do
    FAlign[I] := alLeft;
end;

procedure TTextList.SetPalette(const Colors: array of TColor; FirstColor, NumColors: Integer);
var
  I, J: Integer;
begin
  inherited SetPalette(Colors, FirstColor, NumColors);
  for I := 0 to High(FTexts) do
    for J := 0 to High(FTexts[I]) do
      FTexts[I][J].SetPalette(Colors, FirstColor, NumColors);
  for I := 0 to High(FArrowLeft) do
  begin
    FArrowLeft[I].SetPalette(Colors, FirstColor, NumColors);
    FArrowRight[I].SetPalette(Colors, FirstColor, NumColors);
  end;
  if FSelector <> nil then
    FSelector.SetPalette(Colors, FirstColor, NumColors);
  FUp.SetPalette(Colors, FirstColor, NumColors);
  FDown.SetPalette(Colors, FirstColor, NumColors);
  FScrollBar.SetPalette(Colors, FirstColor, NumColors);
end;

procedure TTextList.InitText(Big, Small: TFont; Lang: TLanguage);
begin
  FBigFont := Big;
  FSmallFont := Small;
  FCurrentFont := Small;
  FLang := Lang;
  FSelector := TSurface.Create(Self);
  FSelector.Width := Width;
  FSelector.Height := FCurrentFont.Height + FCurrentFont.Spacing;
  FSelector.Left := Left;
  FSelector.Top := Top;
  FSelector.SetPalette(GetPalette, 0, 256);
  FSelector.Visible := False;
  UpdateVisible;
end;

procedure TTextList.SetHeight(AHeight: Integer);
begin
  inherited SetHeight(AHeight);
  FDown.Top := Top + Height - 14;
  FScrollBar.Top := FUp.Top + FUp.Height;
  FScrollBar.Height := Max(1, FDown.Top - FUp.Top - FUp.Height);
  UpdateVisible;
end;

procedure TTextList.SetColor(Color: TColor);
var
  I, J: Integer;
begin
  FColor := Color;
  FUp.SetColor(Color);
  FDown.SetColor(Color);
  FScrollBar.SetColor(Color);
  for I := 0 to High(FTexts) do
    for J := 0 to High(FTexts[I]) do
      FTexts[I][J].SetColor(Color);
end;

function TTextList.GetColor: TColor;
begin
  Result := FColor;
end;

procedure TTextList.SetSecondaryColor(Color: TColor);
begin
  FColor2 := Color;
end;

function TTextList.GetSecondaryColor: TColor;
begin
  Result := FColor2;
end;

procedure TTextList.SetWordWrap(Wrap: Boolean);
begin
  FWrap := Wrap;
end;

procedure TTextList.SetHighContrast(Contrast: Boolean);
var
  I, J: Integer;
begin
  FContrast := Contrast;
  for I := 0 to High(FTexts) do
    for J := 0 to High(FTexts[I]) do
      FTexts[I][J].SetHighContrast(Contrast);
  FScrollBar.SetHighContrast(Contrast);
end;

procedure TTextList.SetAlign(Align: TTextHAlign; Col: Integer = -1);
var
  I: Integer;
begin
  if Col = -1 then
    for I := 0 to High(FAlign) do
      FAlign[I] := Align
  else if (Col >= 0) and (Col < Length(FAlign)) then
    FAlign[Col] := Align;
end;

procedure TTextList.SetDot(Dot: Boolean);
begin
  FDot := Dot;
end;

procedure TTextList.SetSelectable(Selectable: Boolean);
begin
  FSelectable := Selectable;
end;

procedure TTextList.SetBig;
begin
  FCurrentFont := FBigFont;
  FSelector.Free;
  FSelector := TSurface.Create(Self);
  FSelector.Width := Width;
  FSelector.Height := FCurrentFont.Height + FCurrentFont.Spacing;
  FSelector.Left := Left;
  FSelector.Top := Top;
  FSelector.SetPalette(GetPalette, 0, 256);
  FSelector.Visible := False;
  UpdateVisible;
end;

procedure TTextList.SetSmall;
begin
  FCurrentFont := FSmallFont;
  FSelector.Free;
  FSelector := TSurface.Create(Self);
  FSelector.Width := Width;
  FSelector.Height := FCurrentFont.Height + FCurrentFont.Spacing;
  FSelector.Left := Left;
  FSelector.Top := Top;
  FSelector.SetPalette(GetPalette, 0, 256);
  FSelector.Visible := False;
  UpdateVisible;
end;

procedure TTextList.SetCondensed(Condensed: Boolean);
begin
  FCondensed := Condensed;
end;

procedure TTextList.SetBackground(BG: TSurface);
begin
  FBg := BG;
  FScrollBar.SetBackground(BG);
end;

function TTextList.GetSelectedRow: Integer;
begin
  if Length(FRows) = 0 then
    Result := -1
  else
    Result := FRows[FSelRow];
end;

procedure TTextList.SetMargin(Margin: Integer);
begin
  FMargin := Margin;
end;

function TTextList.GetMargin: Integer;
begin
  Result := FMargin;
end;

procedure TTextList.SetArrowColor(Color: TColor);
begin
  FUp.SetColor(Color);
  FDown.SetColor(Color);
  FScrollBar.SetColor(Color);
end;

procedure TTextList.SetArrowColumn(Pos: Integer; Orientation: TArrowOrientation);
begin
  FArrowPos := Pos;
  FArrowType := Orientation;
  FArrowsLeftEdge := Left + FArrowPos;
  FArrowsRightEdge := FArrowsLeftEdge + 12 + 11;
end;

procedure TTextList.OnLeftArrowClick(Handler: TNotifyEvent);
var
  I: Integer;
begin
  FLeftClick := Handler;
  for I := 0 to High(FArrowLeft) do
    FArrowLeft[I].OnClick := Handler;
end;

procedure TTextList.OnLeftArrowPress(Handler: TNotifyEvent);
var
  I: Integer;
begin
  FLeftPress := Handler;
  for I := 0 to High(FArrowLeft) do
    FArrowLeft[I].OnMouseDown := Handler;
end;

procedure TTextList.OnLeftArrowRelease(Handler: TNotifyEvent);
var
  I: Integer;
begin
  FLeftRelease := Handler;
  for I := 0 to High(FArrowLeft) do
    FArrowLeft[I].OnMouseUp := Handler;
end;

procedure TTextList.OnRightArrowClick(Handler: TNotifyEvent);
var
  I: Integer;
begin
  FRightClick := Handler;
  for I := 0 to High(FArrowRight) do
    FArrowRight[I].OnClick := Handler;
end;

procedure TTextList.OnRightArrowPress(Handler: TNotifyEvent);
var
  I: Integer;
begin
  FRightPress := Handler;
  for I := 0 to High(FArrowRight) do
    FArrowRight[I].OnMouseDown := Handler;
end;

procedure TTextList.OnRightArrowRelease(Handler: TNotifyEvent);
var
  I: Integer;
begin
  FRightRelease := Handler;
  for I := 0 to High(FArrowRight) do
    FArrowRight[I].OnMouseUp := Handler;
end;

procedure TTextList.ClearList;
var
  I, J: Integer;
begin
  for I := 0 to High(FTexts) do
    for J := 0 to High(FTexts[I]) do
      FTexts[I][J].Free;
  SetLength(FTexts, 0);
  SetLength(FRows, 0);
  Redraw := True;
end;

procedure TTextList.ScrollUp(ToMax: Boolean; ScrollByWheel: Boolean = False);
begin
  if not FScrolling then Exit;
  if (Length(FRows) > FVisibleRows) and (FScroll > 0) then
  begin
    if ToMax then
      ScrollTo(0)
    else
    begin
      if ScrollByWheel then
        ScrollTo(FScroll - Min(Options.MouseWheelSpeed, FScroll))
      else
        ScrollTo(FScroll - 1);
    end;
  end;
end;

procedure TTextList.ScrollDown(ToMax: Boolean; ScrollByWheel: Boolean = False);
begin
  if not FScrolling then Exit;
  if (Length(FRows) > FVisibleRows) and (FScroll < Length(FRows) - FVisibleRows) then
  begin
    if ToMax then
      ScrollTo(Length(FRows) - FVisibleRows)
    else
    begin
      if ScrollByWheel then
        ScrollTo(FScroll + Options.MouseWheelSpeed)
      else
        ScrollTo(FScroll + 1);
    end;
  end;
end;

procedure TTextList.UpdateArrows;
begin
  FUp.Visible := (Length(FRows) > FVisibleRows);
  FDown.Visible := (Length(FRows) > FVisibleRows);
  FScrollBar.Visible := (Length(FRows) > FVisibleRows);
end;

procedure TTextList.UpdateVisible;
begin
  FVisibleRows := 0;
  if FCurrentFont = nil then Exit;
  while (FVisibleRows * (FCurrentFont.Height + FCurrentFont.Spacing) < Height) do
    Inc(FVisibleRows);
  UpdateArrows;
end;

procedure TTextList.DrawContent;
var
  Y, I, RowIdx, Col: Integer;
begin
  inherited;
  if Length(FRows) = 0 then Exit;
  Y := 0;
  RowIdx := FRows[FScroll];
  for I := FScroll to FScroll + FVisibleRows - 1 do
  begin
    if I >= Length(FRows) then Break;
    RowIdx := FRows[I];
    for Col := 0 to High(FTexts[RowIdx]) do
    begin
      FTexts[RowIdx][Col].Top := Y;
      FTexts[RowIdx][Col].Blit(Self);
    end;
    if Length(FTexts[RowIdx]) > 0 then
      Y := Y + FTexts[RowIdx][0].Height + FCurrentFont.Spacing
    else
      Y := Y + FCurrentFont.Height + FCurrentFont.Spacing;
  end;
end;

procedure TTextList.Blit(Dest: TSurface);
var
  I, Y, RowIdx, Col: Integer;
begin
  if Visible and not Hidden then
    FSelector.Blit(Dest);
  inherited Blit(Dest);
  if Visible and not Hidden then
  begin
    // Draw arrows if any
    if FArrowPos <> -1 then
    begin
      Y := 0;
      RowIdx := FRows[FScroll];
      for I := FScroll to FScroll + FVisibleRows - 1 do
      begin
        if I >= Length(FRows) then Break;
        RowIdx := FRows[I];
        if I < Length(FArrowLeft) then
        begin
          FArrowLeft[RowIdx].Top := Y;
          FArrowRight[RowIdx].Top := Y;
          if Y >= 0 then
          begin
            FArrowLeft[RowIdx].Blit(Dest);
            FArrowRight[RowIdx].Blit(Dest);
          end;
        end;
        if Length(FTexts[RowIdx]) > 0 then
          Y := Y + FTexts[RowIdx][0].Height + FCurrentFont.Spacing
        else
          Y := Y + FCurrentFont.Height + FCurrentFont.Spacing;
      end;
    end;
    FUp.Blit(Dest);
    FDown.Blit(Dest);
    FScrollBar.Blit(Dest);
  end;
end;

procedure TTextList.Think;
var
  I: Integer;
begin
  inherited;
  FUp.Think;
  FDown.Think;
  FScrollBar.Think;
  for I := 0 to High(FArrowLeft) do
  begin
    FArrowLeft[I].Think;
    FArrowRight[I].Think;
  end;
end;

procedure TTextList.Handle(Action: TAction; State: TState);
var
  I, StartIdx, EndIdx, EndRow: Integer;
begin
  inherited Handle(Action, State);
  FUp.Handle(Action, State);
  FDown.Handle(Action, State);
  FScrollBar.Handle(Action, State);
  if FArrowPos <> -1 then
  begin
    StartIdx := FRows[FScroll];
    if (FScroll > 0) and (FRows[FScroll] = FRows[FScroll-1]) then
      Inc(StartIdx);
    EndIdx := FRows[FScroll] + 1;
    EndRow := Min(Length(FRows), FScroll + FVisibleRows);
    for I := FScroll + 1 to EndRow - 1 do
      if FRows[I] <> FRows[I-1] then
        Inc(EndIdx);
    for I := StartIdx to EndIdx - 1 do
    begin
      if I < Length(FArrowLeft) then
      begin
        FArrowLeft[I].Handle(Action, State);
        FArrowRight[I].Handle(Action, State);
      end;
    end;
  end;
end;

procedure TTextList.MousePress(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  AllowScroll: Boolean;
begin
  inherited;
  AllowScroll := True;
  if Options.ChangeValueByMouseWheel <> 0 then
    AllowScroll := (X < FArrowsLeftEdge) or (X > FArrowsRightEdge);
  if AllowScroll then
  begin
    if Button = mbWheelUp then ScrollUp(False, True)
    else if Button = mbWheelDown then ScrollDown(False, True);
  end;
  if FSelectable and (FSelRow < Length(FRows)) then
    inherited MousePress(Button, Shift, X, Y)
  else
    inherited MousePress(Button, Shift, X, Y);
end;

procedure TTextList.MouseRelease(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if FSelectable and (FSelRow < Length(FRows)) then
    inherited MouseRelease(Button, Shift, X, Y)
  else
    inherited MouseRelease(Button, Shift, X, Y);
end;

procedure TTextList.MouseClick(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if FSelectable and (FSelRow < Length(FRows)) then
  begin
    inherited MouseClick(Button, Shift, X, Y);
    if (FComboBox <> nil) and (Button = mbLeft) then
    begin
      FComboBox.SetSelected(FSelRow);
      FComboBox.Toggle;
    end;
  end
  else
    inherited MouseClick(Button, Shift, X, Y);
end;

procedure TTextList.MouseOver(Shift: TShiftState; X, Y: Integer);
var
  RowHeight, ActualHeight: Integer;
begin
  inherited;
  if FSelectable then
  begin
    RowHeight := FCurrentFont.Height + FCurrentFont.Spacing;
    FSelRow := FScroll + Trunc(Y / RowHeight);
    if FSelRow < Length(FRows) then
    begin
      FSelector.Visible := True;
      FSelector.Top := Top + FTexts[FRows[FSelRow]][0].Top;
      FSelector.Height := Max(1, FTexts[FRows[FSelRow]][0].Height + FCurrentFont.Spacing);
      // copy background and offset
      if FBg <> nil then
      begin
        FSelector.Copy(FBg);
        FSelector.OffsetBlock(-10);
      end;
    end
    else
      FSelector.Visible := False;
  end;
end;

procedure TTextList.MouseOut(Shift: TShiftState; X, Y: Integer);
begin
  if FSelectable then
    FSelector.Visible := False;
  inherited;
end;

function TTextList.GetScroll: Integer;
begin
  Result := FScroll;
end;

procedure TTextList.ScrollTo(Scroll: Integer);
begin
  if not FScrolling then Exit;
  if Length(FRows) <= FVisibleRows then Exit;
  FScroll := EnsureRange(Scroll, 0, Length(FRows) - FVisibleRows);
  DrawContent;
  UpdateArrows;
end;

procedure TTextList.SetComboBox(ComboBox: TComboBox);
begin
  FComboBox := ComboBox;
end;

function TTextList.GetComboBox: TComboBox;
begin
  Result := FComboBox;
end;

procedure TTextList.SetBorderColor(Color: TColor);
begin
  FUp.SetColor(Color);
  FDown.SetColor(Color);
  FScrollBar.SetColor(Color);
end;

function TTextList.GetScrollbarColor: TColor;
begin
  Result := FScrollBar.GetColor;
end;

procedure TTextList.SetFlooding(Flooding: Boolean);
begin
  FFlooding := Flooding;
end;

end.