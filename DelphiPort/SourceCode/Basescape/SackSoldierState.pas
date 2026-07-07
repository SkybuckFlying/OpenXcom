unit SackSoldierState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Interface.TextButton, Interface.Window, Interface.Text,
  Savegame.Base, Savegame.ItemContainer, Savegame.Soldier,
  Mod.Armor;

type
  TSackSoldierState = class(TState)
  private
    FBase: TBase;
    FSoldierId: Integer;
    FBtnOk, FBtnCancel: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtSoldier: TText;
  public
    constructor Create(AOwner: TComponent; Base: TBase; SoldierId: Integer);
    destructor Destroy; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure BtnCancelClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TSackSoldierState.Create(AOwner: TComponent; Base: TBase; SoldierId: Integer);
begin
  inherited Create(AOwner);
  FBase := Base;
  FSoldierId := SoldierId;
  Screen := False;

  FWindow := TWindow.Create(Self, 152, 80, 84, 60);
  FBtnOk := TTextButton.Create(44, 16, 100, 115);
  FBtnCancel := TTextButton.Create(44, 16, 176, 115);
  FTxtTitle := TText.Create(142, 9, 89, 75);
  FTxtSoldier := TText.Create(142, 9, 89, 85);

  SetInterface('sackSoldier');
  Add(FWindow, 'window', 'sackSoldier');
  Add(FBtnOk, 'button', 'sackSoldier');
  Add(FBtnCancel, 'button', 'sackSoldier');
  Add(FTxtTitle, 'text', 'sackSoldier');
  Add(FTxtSoldier, 'text', 'sackSoldier');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK13.SCR'));
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  FBtnCancel.SetText(Translate('STR_CANCEL_UC'));
  FBtnCancel.OnMouseClick := BtnCancelClick;
  FBtnCancel.OnKeyboardPress := BtnCancelClick;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetText(Translate('STR_SACK'));
  FTxtSoldier.SetAlign(ALIGN_CENTER);
  FTxtSoldier.SetText(FBase.GetSoldiers[SoldierId].GetName(True) + '?');
end;

destructor TSackSoldierState.Destroy;
begin
  inherited;
end;

procedure TSackSoldierState.BtnOkClick(Sender: TObject; Action: TAction);
var
  soldier: TSoldier;
begin
  soldier := FBase.GetSoldiers[FSoldierId];
  if soldier.GetArmor.GetStoreItem <> Armor.NONE then
    FBase.GetStorageItems.AddItem(soldier.GetArmor.GetStoreItem);
  FBase.GetSoldiers.Delete(FSoldierId);
  soldier.Free;
  FGame.PopState;
end;

procedure TSackSoldierState.BtnCancelClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

end.