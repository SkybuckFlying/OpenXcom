unit FundingState;

interface

uses
  Engine.State, Engine.Game, Mod.Mod, Engine.LocalizedText,
  Engine.Unicode, Interface.TextButton, Interface.Window,
  Interface.Text, Interface.TextList, Savegame.Country,
  Mod.RuleCountry, Savegame.SavedGame, Engine.Options;

type
  TFundingState = class(TState)
  private
    FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtCountry, FTxtFunding, FTxtChange: TText;
    FLstCountries: TTextList;
    procedure BtnOkClick(AAction: TAction);
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils, System.Classes;

{ TFundingState }

constructor TFundingState.Create;
var
  i: Integer;
  country: TCountry;
  ss, ss2: string;
begin
  inherited Create(nil);
  FScreen := False;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0, POPUP_BOTH);
  FBtnOk := TTextButton.Create(50, 12, 135, 180);
  FTxtTitle := TText.Create(320, 17, 0, 8);
  FTxtCountry := TText.Create(100, 9, 32, 30);
  FTxtFunding := TText.Create(100, 9, 140, 30);
  FTxtChange := TText.Create(72, 9, 240, 30);
  FLstCountries := TTextList.Create(260, 136, 32, 40);

  SetInterface('fundingWindow');

  Add(FWindow, 'window', 'fundingWindow');
  Add(FBtnOk, 'button', 'fundingWindow');
  Add(FTxtTitle, 'text1', 'fundingWindow');
  Add(FTxtCountry, 'text2', 'fundingWindow');
  Add(FTxtFunding, 'text2', 'fundingWindow');
  Add(FTxtChange, 'text2', 'fundingWindow');
  Add(FLstCountries, 'list', 'fundingWindow');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK13.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.keyOk, BtnOkClick);
  FBtnOk.OnKeyboardPress(Options.keyCancel, BtnOkClick);
  FBtnOk.OnKeyboardPress(Options.keyGeoFunding, BtnOkClick);

  FTxtTitle.Align := ALIGN_CENTER;
  FTxtTitle.Big := True;
  FTxtTitle.Text := Tr('STR_INTERNATIONAL_RELATIONS');

  FTxtCountry.Text := Tr('STR_COUNTRY');
  FTxtFunding.Text := Tr('STR_FUNDING');
  FTxtChange.Text := Tr('STR_CHANGE');

  FLstCountries.SetColumns(3, 108, 100, 52);
  FLstCountries.Dot := True;

  for i := 0 to Game.SavedGame.Countries.Count - 1 do
  begin
    country := Game.SavedGame.Countries[i];
    ss := Unicode.TOK_COLOR_FLIP + Unicode.FormatFunding(country.Funding[country.Funding.Count - 1]) + Unicode.TOK_COLOR_FLIP;
    if country.Funding.Count > 1 then
    begin
      ss2 := Unicode.TOK_COLOR_FLIP;
      if country.Funding[country.Funding.Count - 1] - country.Funding[country.Funding.Count - 2] > 0 then
        ss2 := ss2 + '+';
      ss2 := ss2 + Unicode.FormatFunding(country.Funding[country.Funding.Count - 1] - country.Funding[country.Funding.Count - 2]);
      ss2 := ss2 + Unicode.TOK_COLOR_FLIP;
    end
    else
      ss2 := Unicode.FormatFunding(0);
    FLstCountries.AddRow(3, [Tr(country.Rules.TypeName), ss, ss2]);
  end;

  FLstCountries.AddRow(2, [Tr('STR_TOTAL_UC'), Unicode.FormatFunding(Game.SavedGame.CountryFunding)]);
  FLstCountries.SetRowColor(Game.SavedGame.Countries.Count, FTxtCountry.Color);
end;

destructor TFundingState.Destroy;
begin
  inherited;
end;

procedure TFundingState.BtnOkClick(AAction: TAction);
begin
  Game.PopState;
end;

end.