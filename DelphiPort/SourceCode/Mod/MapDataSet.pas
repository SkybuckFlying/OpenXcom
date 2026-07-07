unit MapDataSet;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, MapData, MCDPatch, Engine.SurfaceSet, Engine.FileMap;

type
  TMapDataSet = class
  private
    FName: string;
    FObjects: TArray<TMapData>;
    FSurfaceSet: TSurfaceSet;
    FLoaded: Boolean;
    class var FBlankTile: TMapData;
    class var FScorchedTile: TMapData;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;
    class procedure LoadLOFTEMPS(const FileName: string; var VoxelData: TArray<Word>); static;
    function GetName: string;
    function GetSize: Integer;
    function GetObject(Index: Integer): TMapData;
    function GetSurfaceset: TSurfaceSet;
    procedure LoadData(Patch: TMDCPatch);
    procedure UnloadData;
    class function GetBlankFloorTile: TMapData; static;
    class function GetScorchedEarthTile: TMapData; static;
  end;

implementation

{ TMapDataSet }

constructor TMapDataSet.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FSurfaceSet := nil;
  FLoaded := False;
end;

destructor TMapDataSet.Destroy;
begin
  UnloadData;
  inherited;
end;

class procedure TMapDataSet.LoadLOFTEMPS(const FileName: string; var VoxelData: TArray<Word>);
var
  fs: TFileStream;
  value: Word;
begin
  fs := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    while fs.Position < fs.Size do
    begin
      fs.ReadBuffer(value, SizeOf(Word));
      VoxelData := VoxelData + [value];
    end;
  finally
    fs.Free;
  end;
end;

function TMapDataSet.GetName: string;
begin
  Result := FName;
end;

function TMapDataSet.GetSize: Integer;
begin
  Result := Length(FObjects);
end;

function TMapDataSet.GetObject(Index: Integer): TMapData;
begin
  if (Index < 0) or (Index >= Length(FObjects)) then
    raise Exception.CreateFmt('MCD %s has no object %d', [FName, Index]);
  Result := FObjects[Index];
end;

function TMapDataSet.GetSurfaceset: TSurfaceSet;
begin
  Result := FSurfaceSet;
end;

procedure TMapDataSet.LoadData(Patch: TMDCPatch);
type
  TMCD = packed record
    Frame: array[0..7] of Byte;
    LOFT: array[0..11] of Byte;
    ScanG: Word;
    u23, u24, u25, u26, u27, u28, u29, u30: Byte;
    UFO_Door: Byte;
    Stop_LOS: Byte;
    No_Floor: Byte;
    Big_Wall: Byte;
    Gravlift: Byte;
    Door: Byte;
    Block_Fire: Byte;
    Block_Smoke: Byte;
    u39: Byte;
    TU_Walk: Byte;
    TU_Slide: Byte;
    TU_Fly: Byte;
    Armor: Byte;
    HE_Block: Byte;
    Die_MCD: Byte;
    Flammable: Byte;
    Alt_MCD: Byte;
    u48: Byte;
    T_Level: ShortInt;
    P_Level: Byte;
    u51: Byte;
    Light_Block: Byte;
    Footstep: Byte;
    Tile_Type: Byte;
    HE_Type: Byte;
    HE_Strength: Byte;
    Smoke_Blockage: Byte;
    Fuel: Byte;
    Light_Source: Byte;
    Target_Type: Byte;
    Xcom_Base: Byte;
    u62: Byte;
  end;

var
  fs: TFileStream;
  mcd: TMCD;
  objNumber: Integer;
begin
  if FLoaded then Exit;
  FLoaded := True;
  objNumber := 0;

  var fname := 'TERRAIN/' + FName + '.MCD';
  fs := TFileStream.Create(TFileMap.GetFilePath(fname), fmOpenRead or fmShareDenyWrite);
  try
    while fs.Position < fs.Size do
    begin
      fs.ReadBuffer(mcd, SizeOf(TMCD));
      var toObj := TMapData.Create(Self);
      SetLength(FObjects, Length(FObjects)+1);
      FObjects[High(FObjects)] := toObj;

      for var frame := 0 to 7 do
        toObj.SetSprite(frame, mcd.Frame[frame]);
      toObj.SetYOffset(mcd.P_Level);
      toObj.SetSpecialType(mcd.Target_Type, TTilePart(mcd.Tile_Type));
      toObj.SetTUCosts(mcd.TU_Walk, mcd.TU_Fly, mcd.TU_Slide);
      toObj.SetFlags(mcd.UFO_Door <> 0, mcd.Stop_LOS <> 0, mcd.No_Floor <> 0,
                     mcd.Big_Wall, mcd.Gravlift <> 0, mcd.Door <> 0,
                     mcd.Block_Fire <> 0, mcd.Block_Smoke <> 0, mcd.Xcom_Base <> 0);
      toObj.SetTerrainLevel(mcd.T_Level);
      toObj.SetFootstepSound(mcd.Footstep);
      toObj.SetAltMCD(mcd.Alt_MCD);
      toObj.SetDieMCD(mcd.Die_MCD);
      toObj.SetBlockValue(mcd.Light_Block, mcd.Stop_LOS, mcd.HE_Block,
                          mcd.Block_Smoke, mcd.Flammable, mcd.HE_Block);
      toObj.SetLightSource(mcd.Light_Source);
      toObj.SetArmor(mcd.Armor);
      toObj.SetFlammable(mcd.Flammable);
      toObj.SetFuel(mcd.Fuel);
      toObj.SetExplosiveType(mcd.HE_Type);
      toObj.SetExplosive(mcd.HE_Strength);
      mcd.ScanG := Swap(mcd.ScanG);
      toObj.SetMiniMapIndex(mcd.ScanG);
      for var layer := 0 to 11 do
        toObj.SetLoftID(mcd.LOFT[layer], layer);

      if FName = 'BLANKS' then
      begin
        if objNumber = 0 then
          FBlankTile := toObj
        else if objNumber = 1 then
          FScorchedTile := toObj;
      end;
      Inc(objNumber);
    end;
  finally
    fs.Free;
  end;

  if Patch <> nil then
    Patch.ModifyData(Self);

  // Validate
  for var i := 0 to Length(FObjects)-1 do
  begin
    var obj := FObjects[i];
    if (obj.GetDieMCD < 0) or (obj.GetDieMCD >= Length(FObjects)) then
      // Log warning
    if (obj.GetAltMCD < 0) or (obj.GetAltMCD >= Length(FObjects)) then
      // Log warning
    if obj.GetArmor = 0 then
      // Log warning
  end;

  FSurfaceSet := TSurfaceSet.Create(32, 40);
  FSurfaceSet.LoadPck(TFileMap.GetFilePath('TERRAIN/' + FName + '.PCK'),
                      TFileMap.GetFilePath('TERRAIN/' + FName + '.TAB'));
end;

procedure TMapDataSet.UnloadData;
begin
  if FLoaded then
  begin
    for var obj in FObjects do
      obj.Free;
    FObjects := [];
    FSurfaceSet.Free;
    FSurfaceSet := nil;
    FLoaded := False;
  end;
end;

class function TMapDataSet.GetBlankFloorTile: TMapData;
begin
  Result := FBlankTile;
end;

class function TMapDataSet.GetScorchedEarthTile: TMapData;
begin
  Result := FScorchedTile;
end;

end.