unit ExtraSounds;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, Engine.SoundSet, Engine.Sound, Engine.FileMap, ModUnit;

type
  TExtraSounds = class
  private
    FType: string;
    FSounds: TDictionary<Integer, string>;
    FCurrent: TModData;
    procedure LoadSound(SetObj: TSoundSet; Index: Integer; const FileName: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode; const Current: TModData);
    function GetType: string;
    function GetSounds: TDictionary<Integer, string>;
    function LoadSoundSet(SetObj: TSoundSet): TSoundSet;
  end;

implementation

{ TExtraSounds }

constructor TExtraSounds.Create;
begin
  inherited Create;
  FSounds := TDictionary<Integer, string>.Create;
  FCurrent := nil;
end;

destructor TExtraSounds.Destroy;
begin
  FSounds.Free;
  inherited;
end;

procedure TExtraSounds.Load(const Node: TYamlNode; const Current: TModData);
begin
  FType := Node['type'].AsString(FType);
  FSounds.Clear;
  // Load map
  var dictNode := Node['files'];
  if not dictNode.IsNull then
  begin
    for var kv in dictNode do
      FSounds.Add(kv.Key.AsInteger, kv.Value.AsString);
  end;
  FCurrent := Current;
end;

function TExtraSounds.GetType: string;
begin
  Result := FType;
end;

function TExtraSounds.GetSounds: TDictionary<Integer, string>;
begin
  Result := FSounds;
end;

procedure TExtraSounds.LoadSound(SetObj: TSoundSet; Index: Integer; const FileName: string);
var
  indexWithOffset: Integer;
begin
  indexWithOffset := Index;
  if indexWithOffset >= SetObj.GetMaxSharedSounds then
  begin
    if indexWithOffset >= FCurrent.Size then
      raise Exception.CreateFmt('ExtraSounds ''%s'' sound ''%d'' exceeds mod ''%s'' size limit %d',
        [FType, indexWithOffset, FCurrent.Name, FCurrent.Size]);
    indexWithOffset := indexWithOffset + FCurrent.Offset;
  end;

  var FullPath := TFileMap.GetFilePath(FileName);
  var Sound := SetObj.GetSound(indexWithOffset);
  if Sound = nil then
    Sound := SetObj.AddSound(indexWithOffset);
  Sound.Load(FullPath);
end;

function TExtraSounds.LoadSoundSet(SetObj: TSoundSet): TSoundSet;
begin
  if SetObj = nil then
  begin
    // Log warning
    SetObj := TSoundSet.Create;
  end;
  for var kv in FSounds do
  begin
    var StartSound := kv.Key;
    var FileName := kv.Value;
    if FileName[FileName.Length] = '/' then
    begin
      var Offset := StartSound;
      var Contents := TFileMap.GetVFolderContents(FileName);
      for var SubFile in Contents do
      begin
        try
          LoadSound(SetObj, Offset, FileName + SubFile);
          Inc(Offset);
        except
          on E: Exception do
            // Log warning
        end;
      end;
    end
    else
      LoadSound(SetObj, StartSound, FileName);
  end;
  Result := SetObj;
end;

end.