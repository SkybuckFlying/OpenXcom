unit EquipmentLayoutItem;

interface

uses
  Classes, SysUtils, YAML;

type
  TEquipmentLayoutItem = class
  private
    FItemType: string;
    FSlot: string;
    FSlotX: Integer;
    FSlotY: Integer;
    FAmmoItem: string;
    FFuseTimer: Integer;
  public
    constructor Create(const Node: TYamlNode); overload;
    constructor Create(const ItemType, Slot: string; SlotX, SlotY: Integer; const AmmoItem: string; FuseTimer: Integer); overload;
    destructor Destroy; override;
    property ItemType: string read FItemType;
    property Slot: string read FSlot;
    property SlotX: Integer read FSlotX;
    property SlotY: Integer read FSlotY;
    property AmmoItem: string read FAmmoItem;
    property FuseTimer: Integer read FFuseTimer;
    procedure Load(const Node: TYamlNode);
    function Save: TYamlNode;
  end;

implementation

constructor TEquipmentLayoutItem.Create(const Node: TYamlNode);
begin
  Load(Node);
end;

constructor TEquipmentLayoutItem.Create(const ItemType, Slot: string; SlotX, SlotY: Integer; const AmmoItem: string; FuseTimer: Integer);
begin
  FItemType := ItemType;
  FSlot := Slot;
  FSlotX := SlotX;
  FSlotY := SlotY;
  FAmmoItem := AmmoItem;
  FFuseTimer := FuseTimer;
end;

destructor TEquipmentLayoutItem.Destroy;
begin
  inherited;
end;

procedure TEquipmentLayoutItem.Load(const Node: TYamlNode);
begin
  FItemType := Node['itemType'].AsString(FItemType);
  FSlot := Node['slot'].AsString(FSlot);
  FSlotX := Node['slotX'].AsInteger(FSlotX);
  FSlotY := Node['slotY'].AsInteger(FSlotY);
  FAmmoItem := Node['ammoItem'].AsString(FAmmoItem);
  FFuseTimer := Node['fuseTimer'].AsInteger(FFuseTimer);
end;

function TEquipmentLayoutItem.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['itemType'] := FItemType;
  Result['slot'] := FSlot;
  if FSlotX <> 0 then Result['slotX'] := FSlotX;
  if FSlotY <> 0 then Result['slotY'] := FSlotY;
  if FAmmoItem <> 'NONE' then Result['ammoItem'] := FAmmoItem;
  if FFuseTimer >= 0 then Result['fuseTimer'] := FFuseTimer;
end;

end.