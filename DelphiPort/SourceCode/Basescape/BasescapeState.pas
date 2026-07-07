unit BasescapeState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options, Engine.Unicode,
  Interface.TextButton, Interface.Text, Interface.TextEdit,
  BaseView, MiniBaseView, Savegame.SavedGame, Savegame.Base,
  Savegame.BaseFacility, Mod.RuleBaseFacility, Savegame.Region,
  Mod.RuleRegion, Menu.ErrorMessageState, DismantleFacilityState,
  Geoscape.BuildNewBaseState, BaseInfoState, SoldiersState,
  CraftsState, BuildFacilitiesState, ResearchState,
  ManageAlienContainmentState, ManufactureState, PurchaseState,
  SellState, TransferBaseState, CraftInfoState,
  Geoscape.AllocatePsiTrainingState, Mod.RuleInterface,
  Globe;

type
  TBasescapeState = class(TState)
  private
    FView: TBaseView;
    FMini: TMiniBaseView;
    FTxtFacility, FTxtLocation, FTxtFunds: TText;
    FEdtBase: TTextEdit;
    FBtnNewBase, FBtnBaseInfo, FBtnSoldiers, FBtnCrafts,
    FBtnFacilities, FBtnResearch, FBtnManufacture, FBtnTransfer,
    FBtnPurchase, FBtnSell, FBtnGeoscape: TTextButton;
    FBase: TBase;
    FGlobe: TGlobe;

    procedure EdtBaseChange(Sender: TObject; Action: TAction);
    procedure ViewLeftClick(Sender: TObject; Action: TAction);
    procedure ViewRightClick(Sender: TObject; Action: TAction);
    procedure ViewMouseOver(Sender: TObject; Action: TAction);
    procedure ViewMouseOut(Sender: TObject; Action: TAction);
    procedure MiniClick(Sender: TObject; Action: TAction);
    procedure HandleKeyPress(Sender: TObject; Action: TAction);
    procedure BtnNewBaseClick(Sender: TObject; Action: TAction);
    procedure BtnBaseInfoClick(Sender: TObject; Action: TAction);
    procedure BtnSoldiersClick(Sender: TObject; Action: TAction);
    procedure BtnCraftsClick(Sender: TObject; Action: TAction);
    procedure BtnFacilitiesClick(Sender: TObject; Action: TAction);
    procedure BtnResearchClick(Sender: TObject; Action: TAction);
    procedure BtnManufactureClick(Sender: TObject; Action: TAction);
    procedure BtnTransferClick(Sender: TObject; Action: TAction);
    procedure BtnPurchaseClick(Sender: TObject; Action: TAction);
    procedure BtnSellClick(Sender: TObject; Action: TAction);
    procedure BtnGeoscapeClick(Sender: TObject; Action: TAction);
  public
    constructor Create(AOwner: TComponent; Base: TBase; Globe: TGlobe);
    destructor Destroy; override;
    procedure Init; override;
    procedure SetBase(Base: TBase);
  end;

implementation

uses Mod.Mod;

constructor TBasescapeState.Create(AOwner: TComponent; Base: TBase; Globe: TGlobe);
begin
  inherited Create(AOwner);
  FBase := Base;
  FGlobe := Globe;

  FTxtFacility := TText.Create(192, 9, 0, 0);
  FView := TBaseView.Create(192, 192, 0, 8);
  FMini := TMiniBaseView.Create(128, 16, 192, 41);
  FEdtBase := TTextEdit.Create(Self, 127, 17, 193, 0);
  FTxtLocation := TText.Create(126, 9, 194, 16);
  FTxtFunds := TText.Create(126, 9, 194, 24);
  FBtnNewBase := TTextButton.Create(128, 12, 192, 58);
  FBtnBaseInfo := TTextButton.Create(128, 12, 192, 71);
  FBtnSoldiers := TTextButton.Create(128, 12, 192, 84);
  FBtnCrafts := TTextButton.Create(128, 12, 192, 97);
  FBtnFacilities := TTextButton.Create(128, 12, 192, 110);
  FBtnResearch := TTextButton.Create(128, 12, 192, 123);
  FBtnManufacture := TTextButton.Create(128, 12, 192, 136);
  FBtnTransfer := TTextButton.Create(128, 12, 192, 149);
  FBtnPurchase := TTextButton.Create(128, 12, 192, 162);
  FBtnSell := TTextButton.Create(128, 12, 192, 175);
  FBtnGeoscape := TTextButton.Create(128, 12, 192, 188);

  SetInterface('basescape');
  Add(FView, 'baseView', 'basescape');
  Add(FMini, 'miniBase', 'basescape');
  Add(FTxtFacility, 'textTooltip', 'basescape');
  Add(FEdtBase, 'text1', 'basescape');
  Add(FTxtLocation, 'text2', 'basescape');
  Add(FTxtFunds, 'text3', 'basescape');
  Add(FBtnNewBase, 'button', 'basescape');
  Add(FBtnBaseInfo, 'button', 'basescape');
  Add(FBtnSoldiers, 'button', 'basescape');
  Add(FBtnCrafts, 'button', 'basescape');
  Add(FBtnFacilities, 'button', 'basescape');
  Add(FBtnResearch, 'button', 'basescape');
  Add(FBtnManufacture, 'button', 'basescape');
  Add(FBtnTransfer, 'button', 'basescape');
  Add(FBtnPurchase, 'button', 'basescape');
  Add(FBtnSell, 'button', 'basescape');
  Add(FBtnGeoscape, 'button', 'basescape');
  CenterAllSurfaces;

  FView.SetTexture(FGame.GetMod.GetSurfaceSet('BASEBITS.PCK'));
  FView.OnMouseClick := ViewLeftClick;
  FView.OnMouseRightClick := ViewRightClick;
  FView.OnMouseOver := ViewMouseOver;
  FView.OnMouseOut := ViewMouseOut;

  FMini.SetTexture(FGame.GetMod.GetSurfaceSet('BASEBITS.PCK'));
  FMini.SetBases(FGame.GetSavedGame.GetBases);
  FMini.OnMouseClick := MiniClick;
  FMini.OnKeyboardPress := HandleKeyPress;

  FEdtBase.SetBig;
  FEdtBase.OnChange := EdtBaseChange;

  FBtnNewBase.SetText(Translate('STR_BUILD_NEW_BASE_UC'));
  FBtnNewBase.OnMouseClick := BtnNewBaseClick;
  FBtnBaseInfo.SetText(Translate('STR_BASE_INFORMATION'));
  FBtnBaseInfo.OnMouseClick := BtnBaseInfoClick;
  FBtnSoldiers.SetText(Translate('STR_SOLDIERS_UC'));
  FBtnSoldiers.OnMouseClick := BtnSoldiersClick;
  FBtnCrafts.SetText(Translate('STR_EQUIP_CRAFT'));
  FBtnCrafts.OnMouseClick := BtnCraftsClick;
  FBtnFacilities.SetText(Translate('STR_BUILD_FACILITIES'));
  FBtnFacilities.OnMouseClick := BtnFacilitiesClick;
  FBtnResearch.SetText(Translate('STR_RESEARCH'));
  FBtnResearch.OnMouseClick := BtnResearchClick;
  FBtnManufacture.SetText(Translate('STR_MANUFACTURE'));
  FBtnManufacture.OnMouseClick := BtnManufactureClick;
  FBtnTransfer.SetText(Translate('STR_TRANSFER_UC'));
  FBtnTransfer.OnMouseClick := BtnTransferClick;
  FBtnPurchase.SetText(Translate('STR_PURCHASE_RECRUIT'));
  FBtnPurchase.OnMouseClick := BtnPurchaseClick;
  FBtnSell.SetText(Translate('STR_SELL_SACK_UC'));
  FBtnSell.OnMouseClick := BtnSellClick;
  FBtnGeoscape.SetText(Translate('STR_GEOSCAPE_UC'));
  FBtnGeoscape.OnMouseClick := BtnGeoscapeClick;
  FBtnGeoscape.OnKeyboardPress := BtnGeoscapeClick;
end;

destructor TBasescapeState.Destroy;
var
  Exists: Boolean;
  i: Integer;
begin
  Exists := False;
  for i := 0 to FGame.GetSavedGame.GetBases.Count - 1 do
    if FGame.GetSavedGame.GetBases[i] = FBase then
    begin
      Exists := True;
      Break;
    end;
  if not Exists then
    FBase.Free;
  inherited;
end;

procedure TBasescapeState.Init;
var
  Region: TRegion;
begin
  inherited;
  SetBase(FBase);
  FView.SetBase(FBase);
  FMini.Draw;
  FEdtBase.SetText(FBase.GetName);

  for Region in FGame.GetSavedGame.GetRegions do
    if Region.GetRules.InsideRegion(FBase.GetLongitude, FBase.GetLatitude) then
    begin
      FTxtLocation.SetText(Translate(Region.GetRules.GetType));
      Break;
    end;

  FTxtFunds.SetText(Translate('STR_FUNDS').Arg(Unicode.FormatFunding(FGame.GetSavedGame.GetFunds)));

  FBtnNewBase.Visible := FGame.GetSavedGame.GetBases.Count < TMiniBaseView.MAX_BASES;
end;

procedure TBasescapeState.SetBase(Base: TBase);
var
  i: Integer;
  Exists: Boolean;
begin
  if FGame.GetSavedGame.GetBases.Count > 0 then
  begin
    Exists := False;
    for i := 0 to FGame.GetSavedGame.GetBases.Count - 1 do
      if FGame.GetSavedGame.GetBases[i] = Base then
      begin
        FBase := Base;
        FMini.SetSelectedBase(i);
        FGame.GetSavedGame.SetSelectedBase(i);
        Exists := True;
        Break;
      end;
    if not Exists then
    begin
      FBase := FGame.GetSavedGame.GetBases[0];
      FMini.SetSelectedBase(0);
      FGame.GetSavedGame.SetSelectedBase(0);
    end;
  end
  else
  begin
    FBase := TBase.Create(FGame.GetMod);
    FMini.SetSelectedBase(0);
    FGame.GetSavedGame.SetSelectedBase(0);
  end;
end;

procedure TBasescapeState.EdtBaseChange(Sender: TObject; Action: TAction);
begin
  FBase.SetName(FEdtBase.GetText);
end;

procedure TBasescapeState.ViewLeftClick(Sender: TObject; Action: TAction);
var
  Fac: TBaseFacility;
begin
  Fac := FView.GetSelectedFacility;
  if Fac <> nil then
  begin
    if Fac.InUse then
      FGame.PushState(TErrorMessageState.Create(Self, Translate('STR_FACILITY_IN_USE'), FPalette,
        FGame.GetMod.GetInterface('basescape').GetElement('errorMessage').Color, 'BACK13.SCR',
        FGame.GetMod.GetInterface('basescape').GetElement('errorPalette').Color))
    else if not FBase.GetDisconnectedFacilities(Fac).IsEmpty then
      FGame.PushState(TErrorMessageState.Create(Self, Translate('STR_CANNOT_DISMANTLE_FACILITY'), FPalette,
        FGame.GetMod.GetInterface('basescape').GetElement('errorMessage').Color, 'BACK13.SCR',
        FGame.GetMod.GetInterface('basescape').GetElement('errorPalette').Color))
    else
      FGame.PushState(TDismantleFacilityState.Create(Self, FBase, FView, Fac));
  end;
end;

procedure TBasescapeState.ViewRightClick(Sender: TObject; Action: TAction);
var
  f: TBaseFacility;
  craft: Integer;
begin
  f := FView.GetSelectedFacility;
  if f = nil then
    FGame.PushState(TBaseInfoState.Create(Self, FBase, Self))
  else if f.GetRules.GetCrafts > 0 then
  begin
    if f.GetCraft = nil then
      FGame.PushState(TCraftsState.Create(Self, FBase))
    else
      for craft := 0 to FBase.GetCrafts.Count - 1 do
        if f.GetCraft = FBase.GetCrafts[craft] then
        begin
          FGame.PushState(TCraftInfoState.Create(Self, FBase, craft));
          Break;
        end;
  end
  else if f.GetRules.GetStorage > 0 then
    FGame.PushState(TSellState.Create(Self, FBase))
  else if f.GetRules.GetPersonnel > 0 then
    FGame.PushState(TSoldiersState.Create(Self, FBase))
  else if f.GetRules.GetPsiLaboratories > 0 and Options.AnytimePsiTraining and (FBase.GetAvailablePsiLabs > 0) then
    FGame.PushState(TAllocatePsiTrainingState.Create(Self, FBase))
  else if f.GetRules.GetLaboratories > 0 then
    FGame.PushState(TResearchState.Create(Self, FBase))
  else if f.GetRules.GetWorkshops > 0 then
    FGame.PushState(TManufactureState.Create(Self, FBase))
  else if f.GetRules.GetAliens > 0 then
    FGame.PushState(TManageAlienContainmentState.Create(Self, FBase, OPT_GEOSCAPE))
  else if f.GetRules.IsLift or (f.GetRules.GetRadarRange > 0) then
    FGame.PopState;
end;

procedure TBasescapeState.ViewMouseOver(Sender: TObject; Action: TAction);
var
  f: TBaseFacility;
  ss: TStringStream;
begin
  f := FView.GetSelectedFacility;
  ss := TStringStream.Create;
  try
    if f <> nil then
    begin
      if (f.GetRules.GetCrafts = 0) or (f.GetBuildTime > 0) then
        ss.WriteString(Translate(f.GetRules.GetType))
      else
      begin
        ss.WriteString(Translate(f.GetRules.GetType));
        if f.GetCraft <> nil then
          ss.WriteString(' ' + Translate('STR_CRAFT_').Arg(f.GetCraft.GetName(FGame.GetLanguage)));
      end;
    end;
    FTxtFacility.SetText(ss.DataString);
  finally
    ss.Free;
  end;
end;

procedure TBasescapeState.ViewMouseOut(Sender: TObject; Action: TAction);
begin
  FTxtFacility.SetText('');
end;

procedure TBasescapeState.MiniClick(Sender: TObject; Action: TAction);
var
  base: Integer;
begin
  base := FMini.GetHoveredBase;
  if base < FGame.GetSavedGame.GetBases.Count then
  begin
    FBase := FGame.GetSavedGame.GetBases[base];
    Init;
  end;
end;

procedure TBasescapeState.HandleKeyPress(Sender: TObject; Action: TAction);
var
  key: Integer;
  baseKeys: array[0..7] of Integer;
  i: Integer;
begin
  if Action.GetDetails.typ = SDL_KEYDOWN then
  begin
    baseKeys[0] := Options.KeyBaseSelect1;
    baseKeys[1] := Options.KeyBaseSelect2;
    baseKeys[2] := Options.KeyBaseSelect3;
    baseKeys[3] := Options.KeyBaseSelect4;
    baseKeys[4] := Options.KeyBaseSelect5;
    baseKeys[5] := Options.KeyBaseSelect6;
    baseKeys[6] := Options.KeyBaseSelect7;
    baseKeys[7] := Options.KeyBaseSelect8;
    key := Action.GetDetails.key.keysym.sym;
    for i := 0 to FGame.GetSavedGame.GetBases.Count - 1 do
      if key = baseKeys[i] then
      begin
        FBase := FGame.GetSavedGame.GetBases[i];
        Init;
        Break;
      end;
  end;
end;

procedure TBasescapeState.BtnNewBaseClick(Sender: TObject; Action: TAction);
var
  NewBase: TBase;
begin
  NewBase := TBase.Create(FGame.GetMod);
  FGame.PopState;
  FGame.PushState(TBuildNewBaseState.Create(Self, NewBase, FGlobe, False));
end;

procedure TBasescapeState.BtnBaseInfoClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TBaseInfoState.Create(Self, FBase, Self));
end;

procedure TBasescapeState.BtnSoldiersClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TSoldiersState.Create(Self, FBase));
end;

procedure TBasescapeState.BtnCraftsClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TCraftsState.Create(Self, FBase));
end;

procedure TBasescapeState.BtnFacilitiesClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TBuildFacilitiesState.Create(Self, FBase, Self));
end;

procedure TBasescapeState.BtnResearchClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TResearchState.Create(Self, FBase));
end;

procedure TBasescapeState.BtnManufactureClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TManufactureState.Create(Self, FBase));
end;

procedure TBasescapeState.BtnPurchaseClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TPurchaseState.Create(Self, FBase));
end;

procedure TBasescapeState.BtnSellClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TSellState.Create(Self, FBase));
end;

procedure TBasescapeState.BtnTransferClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TTransferBaseState.Create(Self, FBase));
end;

procedure TBasescapeState.BtnGeoscapeClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

end.