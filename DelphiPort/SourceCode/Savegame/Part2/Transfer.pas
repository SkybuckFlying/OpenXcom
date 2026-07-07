unit Transfer;

interface

uses
  Classes, SysUtils, YAML, Base, Soldier, Craft, Mod, SavedGame, Language;

type
  TTransferType = (TRANSFER_ITEM, TRANSFER_CRAFT, TRANSFER_SOLDIER, TRANSFER_SCIENTIST, TRANSFER_ENGINEER);

  TTransfer = class
  private
    FHours: Integer;
    FSoldier: TSoldier;
    FCraft: TCraft;
    FItemId: string;
    FItemQty: Integer;
    FScientists: Integer;
    FEngineers: Integer;
    FDelivered: Boolean;
  public
    constructor Create(Hours: Integer);
    destructor Destroy; override;
    function Load(const Node: TYamlNode; Base: TBase; Mod: TMod; Save: TSavedGame): Boolean;
    function Save: TYamlNode;
    property Soldier: TSoldier read FSoldier write FSoldier;
    property Craft: TCraft read FCraft write FCraft;
    property Items: string read FItemId write FItemId;
    property ItemQty: Integer read FItemQty write FItemQty;
    property Scientists: Integer read FScientists write FScientists;
    property Engineers: Integer read FEngineers write FEngineers;
    function GetName(Lang: TLanguage): string;
    property Hours: Integer read FHours;
    function Quantity: Integer;
    function Type_: TTransferType;
    procedure Advance(Base: TBase);
    property Delivered: Boolean read FDelivered;
  end;

implementation

constructor TTransfer.Create(Hours: Integer);
begin
  FHours := Hours;
  FSoldier := nil;
  FCraft := nil;
  FItemQty := 0;
  FScientists := 0;
  FEngineers := 0;
  FDelivered := False;
end;

destructor TTransfer.Destroy;
begin
  if not FDelivered then
  begin
    FSoldier.Free;
    FCraft.Free;
  end;
  inherited;
end;

function TTransfer.Load(const Node: TYamlNode; Base: TBase; Mod: TMod; Save: TSavedGame): Boolean;
begin
  FHours := Node['hours'].AsInteger(FHours);
  if Node['soldier'] <> nil then
  begin
    var soldierNode := Node['soldier'];
    var typ := soldierNode['type'].AsString(Mod.SoldiersList[0]);
    if Mod.GetSoldier(typ) <> nil then
    begin
      FSoldier := TSoldier.Create(Mod.GetSoldier(typ), nil);
      FSoldier.Load(soldierNode, Mod, Save);
    end
    else
    begin
      Result := False;
      Exit;
    end;
  end
  else if Node['craft'] <> nil then
  begin
    var craftNode := Node['craft'];
    var typ := craftNode['type'].AsString;
    if Mod.GetCraft(typ) <> nil then
    begin
      FCraft := TCraft.Create(Mod.GetCraft(typ), Base);
      FCraft.Load(craftNode, Mod, nil);
    end
    else
    begin
      Result := False;
      Exit;
    end;
  end
  else if Node['itemId'] <> nil then
  begin
    FItemId := Node['itemId'].AsString(FItemId);
    if Mod.GetItem(FItemId) = nil then
    begin
      Result := False;
      Exit;
    end;
  end;
  FItemQty := Node['itemQty'].AsInteger(FItemQty);
  FScientists := Node['scientists'].AsInteger(FScientists);
  FEngineers := Node['engineers'].AsInteger(FEngineers);
  FDelivered := Node['delivered'].AsBoolean(FDelivered);
  Result := True;
end;

function TTransfer.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['hours'] := FHours;
  if FSoldier <> nil then
    Result['soldier'] := FSoldier.Save
  else if FCraft <> nil then
    Result['craft'] := FCraft.Save
  else if FItemQty <> 0 then
  begin
    Result['itemId'] := FItemId;
    Result['itemQty'] := FItemQty;
  end
  else if FScientists <> 0 then
    Result['scientists'] := FScientists
  else if FEngineers <> 0 then
    Result['engineers'] := FEngineers;
  if FDelivered then Result['delivered'] := FDelivered;
end;

function TTransfer.GetName(Lang: TLanguage): string;
begin
  if FSoldier <> nil then Result := FSoldier.Name
  else if FCraft <> nil then Result := FCraft.GetName(Lang)
  else if FScientists <> 0 then Result := Lang.GetString('STR_SCIENTISTS')
  else if FEngineers <> 0 then Result := Lang.GetString('STR_ENGINEERS')
  else Result := Lang.GetString(FItemId);
end;

function TTransfer.Quantity: Integer;
begin
  if FItemQty <> 0 then Result := FItemQty
  else if FScientists <> 0 then Result := FScientists
  else if FEngineers <> 0 then Result := FEngineers
  else Result := 1;
end;

function TTransfer.Type_: TTransferType;
begin
  if FSoldier <> nil then Result := TRANSFER_SOLDIER
  else if FCraft <> nil then Result := TRANSFER_CRAFT
  else if FScientists <> 0 then Result := TRANSFER_SCIENTIST
  else if FEngineers <> 0 then Result := TRANSFER_ENGINEER
  else Result := TRANSFER_ITEM;
end;

procedure TTransfer.Advance(Base: TBase);
begin
  Dec(FHours);
  if FHours <= 0 then
  begin
    if FSoldier <> nil then
      Base.Soldiers.Add(FSoldier)
    else if FCraft <> nil then
    begin
      Base.Crafts.Add(FCraft);
      FCraft.SetBase(Base);
      FCraft.Checkup;
    end
    else if FItemQty <> 0 then
      Base.StorageItems.AddItem(FItemId, FItemQty)
    else if FScientists <> 0 then
      Base.Scientists := Base.Scientists + FScientists
    else if FEngineers <> 0 then
      Base.Engineers := Base.Engineers + FEngineers;
    FDelivered := True;
  end;
end;

end.