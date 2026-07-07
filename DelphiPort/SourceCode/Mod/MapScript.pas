unit MapScript;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, SDL_video, MapBlock, RuleTerrain, Engine.RNG;

type
  TMapDirection = (mdNone, mdVertical, mdHorizontal, mdBoth);

  TMCDReplacement = record
    SetIndex: Integer;
    Entry: Integer;
  end;

  TTunnelData = class
  public
    Replacements: TDictionary<string, TMCDReplacement>;
    Level: Integer;
    constructor Create;
    destructor Destroy; override;
    function GetMCDReplacement(const AType: string): PMCDReplacement;
  end;

  TMapScriptCommand = (mscUndefined, mscAddBlock, mscAddLine, mscAddCraft,
                       mscAddUFO, mscDigTunnel, mscFillArea, mscCheckBlock,
                       mscRemove, mscResize);

  TMapScript = class
  private
    FType: TMapScriptCommand;
    FRects: TArray<TSDL_Rect>;
    FGroups: TArray<Integer>;
    FBlocks: TArray<Integer>;
    FFrequencies: TArray<Integer>;
    FMaxUses: TArray<Integer>;
    FConditionals: TArray<Integer>;
    FGroupsTemp: TArray<Integer>;
    FBlocksTemp: TArray<Integer>;
    FFrequenciesTemp: TArray<Integer>;
    FMaxUsesTemp: TArray<Integer>;
    FSizeX, FSizeY, FSizeZ: Integer;
    FExecutionChances: Integer;
    FExecutions: Integer;
    FCumulativeFrequency: Integer;
    FLabel: Integer;
    FDirection: TMapDirection;
    FTunnelData: TTunnelData;
    FUFOName: string;
    function GetGroupNumber: Integer;
    function GetBlockNumber: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    procedure Init;
    function GetType: TMapScriptCommand;
    function GetRects: TArray<TSDL_Rect>;
    function GetSizeX: Integer;
    function GetSizeY: Integer;
    function GetSizeZ: Integer;
    function GetChancesOfExecution: Integer;
    function GetLabel: Integer;
    function GetExecutions: Integer;
    function GetConditionals: TArray<Integer>;
    function GetGroups: TArray<Integer>;
    function GetBlocks: TArray<Integer>;
    function GetDirection: TMapDirection;
    function GetTunnelData: TTunnelData;
    function GetNextBlock(Terrain: TRuleTerrain): TMapBlock;
    function GetUFOName: string;
  end;

implementation

{ TTunnelData }

constructor TTunnelData.Create;
begin
  inherited Create;
  Replacements := TDictionary<string, TMCDReplacement>.Create;
  Level := 0;
end;

destructor TTunnelData.Destroy;
begin
  Replacements.Free;
  inherited;
end;

function TTunnelData.GetMCDReplacement(const AType: string): PMCDReplacement;
var
  rec: TMCDReplacement;
begin
  if Replacements.TryGetValue(AType, rec) then
    Result := @rec
  else
    Result := nil;
end;

{ TMapScript }

constructor TMapScript.Create;
begin
  inherited Create;
  FType := mscUndefined;
  FSizeX := 1; FSizeY := 1; FSizeZ := 0;
  FExecutionChances := 100;
  FExecutions := 1;
  FCumulativeFrequency := 0;
  FLabel := 0;
  FDirection := mdNone;
  FTunnelData := nil;
end;

destructor TMapScript.Destroy;
begin
  FTunnelData.Free;
  inherited;
end;

procedure TMapScript.Load(const Node: TYamlNode);
var
  cmd: string;
  dir: Char;
begin
  var map := Node['type'];
  if not map.IsNull then
  begin
    cmd := map.AsString;
    if cmd = 'addBlock' then
      FType := mscAddBlock
    else if cmd = 'addLine' then
      FType := mscAddLine
    else if cmd = 'addCraft' then
    begin
      FType := mscAddCraft;
      FGroups := [1];
    end
    else if cmd = 'addUFO' then
    begin
      FType := mscAddUFO;
      FGroups := [1];
    end
    else if cmd = 'digTunnel' then
      FType := mscDigTunnel
    else if cmd = 'fillArea' then
      FType := mscFillArea
    else if cmd = 'checkBlock' then
      FType := mscCheckBlock
    else if cmd = 'removeBlock' then
      FType := mscRemove
    else if cmd = 'resize' then
    begin
      FType := mscResize;
      FSizeX := 0; FSizeY := 0;
    end
    else
      raise Exception.Create('Unknown command: ' + cmd);
  end
  else
    raise Exception.Create('Missing command type.');

  map := Node['rects'];
  if not map.IsNull then
  begin
    for var rectNode in map do
    begin
      var r: TSDL_Rect;
      r.x := rectNode[0].AsInteger;
      r.y := rectNode[1].AsInteger;
      r.w := rectNode[2].AsInteger;
      r.h := rectNode[3].AsInteger;
      SetLength(FRects, Length(FRects)+1);
      FRects[High(FRects)] := r;
    end;
  end;

  map := Node['tunnelData'];
  if not map.IsNull then
  begin
    FTunnelData := TTunnelData.Create;
    FTunnelData.Level := map['level'].AsInteger(0);
    var dataNode := map['MCDReplacements'];
    if not dataNode.IsNull then
    begin
      for var repNode in dataNode do
      begin
        var rep: TMCDReplacement;
        var typ := repNode['type'].AsString('');
        rep.Entry := repNode['entry'].AsInteger(-1);
        rep.SetIndex := repNode['set'].AsInteger(-1);
        FTunnelData.Replacements.Add(typ, rep);
      end;
    end;
  end;

  map := Node['conditionals'];
  if not map.IsNull then
  begin
    if map.IsSequence then
      FConditionals := map.AsArray<Integer>(FConditionals)
    else
      FConditionals := [map.AsInteger(0)];
  end;

  map := Node['size'];
  if not map.IsNull then
  begin
    if map.IsSequence then
    begin
      var sizes: array[0..2] of PInteger = (@FSizeX, @FSizeY, @FSizeZ);
      var idx := 0;
      for var szNode in map do
      begin
        if idx >= 3 then Break;
        sizes[idx]^ := szNode.AsInteger(1);
        Inc(idx);
      end;
    end
    else
    begin
      FSizeX := map.AsInteger(FSizeX);
      FSizeY := FSizeX;
    end;
  end;

  map := Node['groups'];
  if not map.IsNull then
  begin
    if map.IsSequence then
      FGroups := map.AsArray<Integer>(FGroups)
    else
      FGroups := [map.AsInteger(0)];
  end;
  var selectionSize := Length(FGroups);
  map := Node['blocks'];
  if not map.IsNull then
  begin
    if map.IsSequence then
      FBlocks := map.AsArray<Integer>(FBlocks)
    else
      FBlocks := [map.AsInteger(0)];
    selectionSize := Length(FBlocks);
  end;

  SetLength(FFrequencies, selectionSize);
  SetLength(FMaxUses, selectionSize);
  for var i := 0 to selectionSize-1 do
  begin
    FFrequencies[i] := 1;
    FMaxUses[i] := -1;
  end;

  map := Node['freqs'];
  if not map.IsNull then
  begin
    if map.IsSequence then
    begin
      var idx := 0;
      for var freqNode in map do
      begin
        if idx >= selectionSize then Break;
        FFrequencies[idx] := freqNode.AsInteger(1);
        Inc(idx);
      end;
    end
    else
      FFrequencies[0] := map.AsInteger(1);
  end;

  map := Node['maxUses'];
  if not map.IsNull then
  begin
    if map.IsSequence then
    begin
      var idx := 0;
      for var useNode in map do
      begin
        if idx >= selectionSize then Break;
        FMaxUses[idx] := useNode.AsInteger(-1);
        Inc(idx);
      end;
    end
    else
      FMaxUses[0] := map.AsInteger(-1);
  end;

  map := Node['direction'];
  if not map.IsNull then
  begin
    var direction := map.AsString('');
    if not direction.IsEmpty then
    begin
      dir := Char(UpCase(direction[1]));
      case dir of
        'V': FDirection := mdVertical;
        'H': FDirection := mdHorizontal;
        'B': FDirection := mdBoth;
      else
        raise Exception.Create('direction must be [V]ertical, [H]orizontal, or [B]oth');
      end;
    end;
  end;

  if (FDirection = mdNone) and ((FType = mscDigTunnel) or (FType = mscAddLine)) then
    raise Exception.Create('no direction defined for ' + cmd + ' command');

  FExecutionChances := Node['executionChances'].AsInteger(FExecutionChances);
  FExecutions := Node['executions'].AsInteger(FExecutions);
  FUFOName := Node['UFOName'].AsString(FUFOName);
  FLabel := Abs(Node['label'].AsInteger(FLabel));
end;

procedure TMapScript.Init;
begin
  FCumulativeFrequency := 0;
  FGroupsTemp := FGroups;
  FBlocksTemp := FBlocks;
  FFrequenciesTemp := FFrequencies;
  FMaxUsesTemp := FMaxUses;
  for var freq in FFrequencies do
    Inc(FCumulativeFrequency, freq);
end;

function TMapScript.GetGroupNumber: Integer;
begin
  if Length(FGroups) = 0 then
    Exit(0); // MT_DEFAULT
  if FCumulativeFrequency > 0 then
  begin
    var pick := TRNG.Generate(0, FCumulativeFrequency-1);
    for var i := 0 to Length(FGroupsTemp)-1 do
    begin
      if pick < FFrequenciesTemp[i] then
      begin
        var retVal := FGroupsTemp[i];
        if FMaxUsesTemp[i] > 0 then
        begin
          Dec(FMaxUsesTemp[i]);
          if FMaxUsesTemp[i] = 0 then
          begin
            // Remove from temp arrays
            Delete(FGroupsTemp, i, 1);
            Dec(FCumulativeFrequency, FFrequenciesTemp[i]);
            Delete(FFrequenciesTemp, i, 1);
            Delete(FMaxUsesTemp, i, 1);
          end;
        end;
        Exit(retVal);
      end;
      Dec(pick, FFrequenciesTemp[i]);
    end;
  end;
  Result := -1; // MT_UNDEFINED
end;

function TMapScript.GetBlockNumber: Integer;
begin
  if FCumulativeFrequency > 0 then
  begin
    var pick := TRNG.Generate(0, FCumulativeFrequency-1);
    for var i := 0 to Length(FBlocksTemp)-1 do
    begin
      if pick < FFrequenciesTemp[i] then
      begin
        var retVal := FBlocksTemp[i];
        if FMaxUsesTemp[i] > 0 then
        begin
          Dec(FMaxUsesTemp[i]);
          if FMaxUsesTemp[i] = 0 then
          begin
            Delete(FBlocksTemp, i, 1);
            Dec(FCumulativeFrequency, FFrequenciesTemp[i]);
            Delete(FFrequenciesTemp, i, 1);
            Delete(FMaxUsesTemp, i, 1);
          end;
        end;
        Exit(retVal);
      end;
      Dec(pick, FFrequenciesTemp[i]);
    end;
  end;
  Result := -1;
end;

function TMapScript.GetNextBlock(Terrain: TRuleTerrain): TMapBlock;
begin
  if Length(FBlocks) = 0 then
  begin
    var group := GetGroupNumber;
    var block := Terrain.GetRandomMapBlock(FSizeX * 10, FSizeY * 10, group);
    Exit(block);
  end;
  var resultIdx := GetBlockNumber;
  if (resultIdx >= 0) and (resultIdx < Length(Terrain.GetMapBlocks)) then
    Result := Terrain.GetMapBlocks[resultIdx]
  else
    Result := nil;
end;

function TMapScript.GetUFOName: string;
begin
  Result := FUFOName;
end;

function TMapScript.GetType: TMapScriptCommand;
begin
  Result := FType;
end;

function TMapScript.GetRects: TArray<TSDL_Rect>;
begin
  Result := FRects;
end;

function TMapScript.GetSizeX: Integer;
begin
  Result := FSizeX;
end;

function TMapScript.GetSizeY: Integer;
begin
  Result := FSizeY;
end;

function TMapScript.GetSizeZ: Integer;
begin
  Result := FSizeZ;
end;

function TMapScript.GetChancesOfExecution: Integer;
begin
  Result := FExecutionChances;
end;

function TMapScript.GetLabel: Integer;
begin
  Result := FLabel;
end;

function TMapScript.GetExecutions: Integer;
begin
  Result := FExecutions;
end;

function TMapScript.GetConditionals: TArray<Integer>;
begin
  Result := FConditionals;
end;

function TMapScript.GetGroups: TArray<Integer>;
begin
  Result := FGroups;
end;

function TMapScript.GetBlocks: TArray<Integer>;
begin
  Result := FBlocks;
end;

function TMapScript.GetDirection: TMapDirection;
begin
  Result := FDirection;
end;

function TMapScript.GetTunnelData: TTunnelData;
begin
  Result := FTunnelData;
end;

end.