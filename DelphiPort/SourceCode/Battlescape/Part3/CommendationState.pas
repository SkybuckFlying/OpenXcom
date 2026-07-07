unit CommendationState;

interface

uses
  System.SysUtils, System.Generics.Collections,
  Engine.State, Engine.Game, Engine.Action,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Savegame.Soldier;

type
  TCommendationState = class(TState)
  private
    FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle: TText;
    FLstSoldiers: TTextList;
    procedure BtnOkClick(Sender: TObject);
  public
    constructor Create(Soldiers: TList<TSoldier>);
    destructor Destroy; override;
  end;

implementation

uses
  Engine.Options, Engine.LocalizedText, Mod.Mod, Savegame.SoldierDiary,
  Mod.RuleCommendations;

constructor TCommendationState.Create(Soldiers: TList<TSoldier>);
var
  CommendationsList: TDictionary<string, TRuleCommendations>;
  ModularCommendation: Boolean;
  Noun: string;
  Row, TitleRow: Integer;
  CommList: TPair<string, TRuleCommendations>;
  S: TSoldier;
  SoldierComm: TSoldierCommendations;
  SkipCounter, LastInt, ThisInt, VectorIterator, I: Integer;
  wssName, wssCommendation: string;
  TitleChosen: Boolean;
begin
  inherited Create;
  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TTextButton.Create(288, 16, 16, 176);
  FTxtTitle := TText.Create(300, 16, 10, 8);
  FLstSoldiers := TTextList.Create(288, 128, 8, 32);

  SetInterface('commendations');

  Add(FWindow, 'window', 'commendations');
  Add(FBtnOk, 'button', 'commendations');
  Add(FTxtTitle, 'heading', 'commendations');
  Add(FLstSoldiers, 'list', 'commendations');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.GetMod.GetSurface('BACK01.SCR'));

  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.keyOk, BtnOkClick);
  FBtnOk.OnKeyboardPress(Options.keyCancel, BtnOkClick);

  FTxtTitle.SetText(Tr('STR_MEDALS'));
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetBig;

  FLstSoldiers.SetColumns(2, 204, 84);
  FLstSoldiers.SetSelectable(True);
  FLstSoldiers.SetBackground(FWindow);
  FLstSoldiers.SetMargin(8);

  Row := 0;
  TitleRow := 0;
  CommendationsList := Game.GetMod.GetCommendationsList;
  TitleChosen := True;

  for CommList in CommendationsList do
  begin
    ModularCommendation := False;
    Noun := 'noNoun';
    if TitleChosen then
    begin
      FLstSoldiers.AddRow(2, ['', '']);
      Inc(Row);
    end;
    TitleChosen := False;
    TitleRow := Row - 1;

    for S in Soldiers do
    begin
      for SoldierComm in S.GetDiary.GetSoldierCommendations do
      begin
        if (SoldierComm.GetType = CommList.Key) and SoldierComm.IsNew then
        begin
          SoldierComm.MakeOld;
          Inc(Row);
          if SoldierComm.GetNoun <> 'noNoun' then
          begin
            Noun := SoldierComm.GetNoun;
            ModularCommendation := True;
          end;
          wssName := '   ' + S.GetName;
          SkipCounter := 0;
          LastInt := -2;
          ThisInt := -1;
          VectorIterator := 0;
          for I := 0 to CommList.Value.GetCriteria[CommList.Value.GetCriteria.Keys[0]].Count - 1 do
          begin
            if VectorIterator = SoldierComm.GetDecorationLevelInt + 1 then Break;
            ThisInt := CommList.Value.GetCriteria[CommList.Value.GetCriteria.Keys[0]][I];
            if I > 0 then LastInt := CommList.Value.GetCriteria[CommList.Value.GetCriteria.Keys[0]][I-1];
            if ThisInt = LastInt then Inc(SkipCounter);
            Inc(VectorIterator);
          end;
          FLstSoldiers.AddRow(2, [wssName, SoldierComm.GetDecorationLevelName(SkipCounter)]);
          Break;
        end;
      end;
    end;

    if TitleRow <> Row - 1 then
    begin
      wssCommendation := '';
      if ModularCommendation then
        wssCommendation := Tr(CommList.Key).Arg(Tr(Noun))
      else
        wssCommendation := Tr(CommList.Key);
      FLstSoldiers.SetCellText(TitleRow, 0, wssCommendation);
      FLstSoldiers.SetRowColor(TitleRow, FLstSoldiers.GetSecondaryColor);
      TitleChosen := True;
    end;

    if Noun = 'noNoun' then Continue;
  end;
end;

destructor TCommendationState.Destroy;
begin
  inherited;
end;

procedure TCommendationState.BtnOkClick(Sender: TObject);
begin
  Game.PopState;
end;

end.