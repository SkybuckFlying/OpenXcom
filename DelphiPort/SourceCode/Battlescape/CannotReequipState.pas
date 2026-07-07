unit CannotReequipState;

interface

uses
  System.SysUtils, System.Generics.Collections,
  Engine.State, Engine.Game, Engine.Action,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Battlescape.DebriefingState;

type
  TReequipStat = record
    Item: string;
    Qty: Integer;
    Craft: string;
  end;

  TCannotReequipState = class(TState)
  private
    FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle: TText;
    FTxtItem: TText;
    FTxtQuantity: TText;
    FTxtCraft: TText;
    FLstItems: TTextList;
    procedure BtnOkClick(Sender: TObject);
  public
    constructor Create(MissingItems: TList<TReequipStat>);
    destructor Destroy; override;
  end;

implementation

uses
  Engine.Options, Engine.LocalizedText, Mod.Mod;

constructor TCannotReequipState.Create(MissingItems: TList<TReequipStat>);
var
  Stat: TReequipStat;
begin
  inherited Create;
  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TTextButton.Create(120, 18, 100, 174);
  FTxtTitle := TText.Create(220, 32, 50, 8);
  FTxtItem := TText.Create(142, 9, 10, 50);
  FTxtQuantity := TText.Create(88, 9, 152, 50);
  FTxtCraft := TText.Create(74, 9, 218, 50);
  FLstItems := TTextList.Create(288, 112, 8, 58);

  SetInterface('cannotReequip');

  Add(FWindow, 'window', 'cannotReequip');
  Add(FBtnOk, 'button', 'cannotReequip');
  Add(FTxtTitle, 'heading', 'cannotReequip');
  Add(FTxtItem, 'text', 'cannotReequip');
  Add(FTxtQuantity, 'text', 'cannotReequip');
  Add(FTxtCraft, 'text', 'cannotReequip');
  Add(FLstItems, 'list', 'cannotReequip');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.GetMod.GetSurface('BACK01.SCR'));

  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.keyOk, BtnOkClick);
  FBtnOk.OnKeyboardPress(Options.keyCancel, BtnOkClick);

  FTxtTitle.SetText(Tr('STR_NOT_ENOUGH_EQUIPMENT_TO_FULLY_RE_EQUIP_SQUAD'));
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetBig;
  FTxtTitle.SetWordWrap(True);

  FTxtItem.SetText(Tr('STR_ITEM'));
  FTxtQuantity.SetText(Tr('STR_QUANTITY_UC'));
  FTxtCraft.SetText(Tr('STR_CRAFT'));

  FLstItems.SetColumns(3, 162, 46, 80);
  FLstItems.SetSelectable(True);
  FLstItems.SetBackground(FWindow);
  FLstItems.SetMargin(2);

  for Stat in MissingItems do
    FLstItems.AddRow(3, [Tr(Stat.Item), IntToStr(Stat.Qty), Stat.Craft]);
end;

destructor TCannotReequipState.Destroy;
begin
  inherited;
end;

procedure TCannotReequipState.BtnOkClick(Sender: TObject);
begin
  Game.PopState;
end;

end.