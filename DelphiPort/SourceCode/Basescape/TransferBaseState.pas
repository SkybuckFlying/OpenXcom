unit TransferBaseState;

interface

uses
  Classes, SysUtils, Generics.Collections,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options, Engine.Unicode,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Savegame.SavedGame, Savegame.Base, Savegame.Region,
  Mod.RuleRegion, TransferItemsState;

type
  TTransferBaseState = class(TState)
  private
    FBase: TBase;
    FBtnCancel: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtFunds, FTxtName, FTxtArea: TText;
    FLstBases: TTextList;
    FBases: TList<TBase>;
  public
    constructor Create(AOwner: TComponent; Base: TBase);
    destructor Destroy; override;
    procedure BtnCancelClick(Sender: TObject; Action: TAction);
    procedure LstBasesClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TTransferBaseState.Create(AOwner: TComponent; Base: TBase);
var
  i: Integer;
  region: TRegion;
  area: string;
begin
  inherited Create(AOwner);
  FBase := Base;
  FBases := TList<TBase>.Create;

  FWindow := TWindow.Create(Self, 280, 140, 20, 30);
  FBtnCancel := TTextButton.Create(264, 16, 28, 146);
  FTxtTitle := TText.Create(270, 17, 25, 38);
  FTxtFunds := TText.Create(250, 9, 30, 54);
  FTxtName := TText.Create(130, 17, 28, 64);
  FTxtArea := TText.Create(130, 17, 160, 64);
  FLstBases := TTextList.Create(248, 64, 28, 80);

  SetInterface('transferBaseSelect');
  Add(FWindow, 'window', 'transferBaseSelect');
  Add(FBtnCancel, 'button', 'transferBaseSelect');
  Add(FTxtTitle, 'text', 'transferBaseSelect');
  Add(FTxtFunds, 'text', 'transferBaseSelect');
  Add(FTxtName, 'text', 'transferBaseSelect');
  Add(FTxtArea, 'text', 'transferBaseSelect');
  Add(FLstBases, 'list', 'transferBaseSelect');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK13.SCR'));
  FBtnCancel.SetText(Translate('STR_CANCEL'));
  FBtnCancel.OnMouseClick := BtnCancelClick;
  FBtnCancel.OnKeyboardPress := BtnCancelClick;

  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetText(Translate('STR_SELECT_DESTINATION_BASE'));
  FTxtFunds.SetText(Translate('STR_CURRENT_FUNDS').Arg(Unicode.FormatFunding(FGame.GetSavedGame.GetFunds)));
  FTxtName.SetText(Translate('STR_NAME'));
  FTxtName.SetBig;
  FTxtArea.SetText(Translate('STR_AREA'));
  FTxtArea.SetBig;

  FLstBases.SetColumns([130, 116]);
  FLstBases.SetSelectable(True);
  FLstBases.SetBackground(FWindow);
  FLstBases.SetMargin(2);
  FLstBases.OnMouseClick := LstBasesClick;

  for i := 0 to FGame.GetSavedGame.GetBases.Count - 1 do
  begin
    var b := FGame.GetSavedGame.GetBases[i];
    if b <> FBase then
    begin
      area := '';
      for region in FGame.GetSavedGame.GetRegions do
        if region.GetRules.InsideRegion(b.GetLongitude, b.GetLatitude) then
        begin
          area := Translate(region.GetRules.GetType);
          Break;
        end;
      FLstBases.AddRow([b.GetName, Unicode.TOK_COLOR_FLIP + area]);
      FBases.Add(b);
    end;
  end;
end;

destructor TTransferBaseState.Destroy;
begin
  FBases.Free;
  inherited;
end;

procedure TTransferBaseState.BtnCancelClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TTransferBaseState.LstBasesClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TTransferItemsState.Create(Self, FBase, FBases[FLstBases.GetSelectedRow]));
end;

end.