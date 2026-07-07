unit MapBlock;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, Battlescape.Position;

type
  TMapBlock = class
  private
    FName: string;
    FSizeX, FSizeY, FSizeZ: Integer;
    FGroups: TArray<Integer>;
    FRevealedFloors: TArray<Integer>;
    FItems: TDictionary<string, TArray<TPosition>>;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function GetName: string;
    function GetSizeX: Integer;
    function GetSizeY: Integer;
    procedure SetSizeZ(ASizeZ: Integer);
    function GetSizeZ: Integer;
    function IsInGroup(Group: Integer): Boolean;
    function IsFloorRevealed(Floor: Integer): Boolean;
    function GetItems: TDictionary<string, TArray<TPosition>>;
  end;

implementation

{ TMapBlock }

constructor TMapBlock.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FSizeX := 10; FSizeY := 10; FSizeZ := 4;
  FGroups := [0];
  FItems := TDictionary<string, TArray<TPosition>>.Create;
end;

destructor TMapBlock.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TMapBlock.Load(const Node: TYamlNode);
begin
  FName := Node['name'].AsString(FName);
  FSizeX := Node['width'].AsInteger(FSizeX);
  FSizeY := Node['length'].AsInteger(FSizeY);
  FSizeZ := Node['height'].AsInteger(FSizeZ);
  if (FSizeX mod 10 <> 0) or (FSizeY mod 10 <> 0) then
    raise Exception.Create('Error: MapBlock ' + FName + ': Size must be divisible by ten');

  var groupsNode := Node['groups'];
  if not groupsNode.IsNull then
  begin
    if groupsNode.IsSequence then
      FGroups := groupsNode.AsArray<Integer>(FGroups)
    else
      FGroups := [groupsNode.AsInteger(0)];
  end;

  var revealedNode := Node['revealedFloors'];
  if not revealedNode.IsNull then
  begin
    if revealedNode.IsSequence then
      FRevealedFloors := revealedNode.AsArray<Integer>(FRevealedFloors)
    else
      FRevealedFloors := [revealedNode.AsInteger(0)];
  end;

  var itemsNode := Node['items'];
  if not itemsNode.IsNull then
  begin
    FItems.Clear;
    for var kv in itemsNode do
    begin
      var key := kv.Key.AsString;
      var value := kv.Value.AsArray<TPosition>;
      FItems.Add(key, value);
    end;
  end;
end;

function TMapBlock.GetName: string;
begin
  Result := FName;
end;

function TMapBlock.GetSizeX: Integer;
begin
  Result := FSizeX;
end;

function TMapBlock.GetSizeY: Integer;
begin
  Result := FSizeY;
end;

procedure TMapBlock.SetSizeZ(ASizeZ: Integer);
begin
  FSizeZ := ASizeZ;
end;

function TMapBlock.GetSizeZ: Integer;
begin
  Result := FSizeZ;
end;

function TMapBlock.IsInGroup(Group: Integer): Boolean;
begin
  for var g in FGroups do
    if g = Group then
      Exit(True);
  Result := False;
end;

function TMapBlock.IsFloorRevealed(Floor: Integer): Boolean;
begin
  for var f in FRevealedFloors do
    if f = Floor then
      Exit(True);
  Result := False;
end;

function TMapBlock.GetItems: TDictionary<string, TArray<TPosition>>;
begin
  Result := FItems;
end;

end.