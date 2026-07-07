unit CommendationLateState;

interface

uses
  System.SysUtils, System.Generics.Collections,
  Engine.State, Engine.Game, Engine.Action,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Savegame.Soldier;

type
  TCommendationLateState = class(TState)
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

constructor TCommendationLateState.Create(Soldiers: TList<TSoldier>);
var
  CommendationsList: TDictionary<string, TRuleCommendations>;
  ModularCommendation: Boolean;
  Noun: string;
  S: TSoldier;
  CommList: TPair<string, TRuleCommendations>;
  SoldierComm: TSoldierCommendations;
  SkipCounter, LastInt, ThisInt, VectorIterator: Integer;
  wssCommendation: string;
  I: Integer;
begin
  inherited Create;
  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TTextButton.Create(288, 16, 16, 176);
  FTxtTitle := TText.Create(300, 16, 10, 8);
  FLstSoldiers := TTextList.Create(288, 128, 8, 32);

  SetInterface('commendationsLate');

  Add(FWindow, 'window', 'commendationsLate');
  Add(FBtnOk, 'button', 'commendationsLate');
  Add(FTxtTitle, 'text', 'commendationsLate');
  Add(FLstSoldiers, 'list', 'commendationsLate');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.GetMod.GetSurface('BACK02.SCR'));

  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.keyOk, BtnOkClick);
  FBtnOk.OnKeyboardPress(Options.keyCancel, BtnOkClick);

  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetText(Tr('STR_LOST_IN_SERVICE'));

  FLstSoldiers.SetColumns(5, 51, 51, 51, 51, 84);
  FLstSoldiers.SetSelectable(True);
  FLstSoldiers.SetBackground(FWindow);
  FLstSoldiers.SetMargin(8);
  FLstSoldiers.SetFlooding(True);

  CommendationsList := Game.GetMod.GetCommendationsList;

  for S in Soldiers do
  begin
    FLstSoldiers.AddRow(5, [S.GetName, '', Tr(S.GetRankString), '', Tr('STR_KILLS').Arg(S.GetDiary.GetKillTotal)]);

    for CommList in CommendationsList do
    begin
      ModularCommendation := False;
      Noun := 'noNoun';
      for SoldierComm in S.GetDiary.GetSoldierCommendations do
      begin
        if (SoldierComm.GetType = CommList.Key) and SoldierComm.IsNew then
        begin
          SoldierComm.MakeOld;
          if SoldierComm.GetNoun <> 'noNoun' then
          begin
            Noun := SoldierComm.GetNoun;
            ModularCommendation := True;
          end;
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
          wssCommendation := '   ';
          if ModularCommendation then
            wssCommendation := wssCommendation + Tr(CommList.Key).Arg(Tr(Noun))
          else
            wssCommendation := wssCommendation + Tr(CommList.Key);
          FLstSoldiers.AddRow(5, [wssCommendation, '', '', '', SoldierComm.GetDecorationLevelName(SkipCounter)]);
          Break;
        end;
      end;
      if Noun = 'noNoun' then Continue;
    end;
  end;
end;

destructor TCommendationLateState.Destroy;
begin
  inherited;
end;

procedure TCommendationLateState.BtnOkClick(Sender: TObject);
begin
  Game.PopState;
end;

end.