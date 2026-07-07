unit SoundDefinition;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml;

type
  TSoundDefinition = class
  private
    FType: string;
    FCatFile: string;
    FSoundList: TArray<Integer>;
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function GetSoundList: TArray<Integer>;
    function GetCATFile: string;
  end;

implementation

{ TSoundDefinition }

constructor TSoundDefinition.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
end;

destructor TSoundDefinition.Destroy;
begin
  inherited;
end;

procedure TSoundDefinition.Load(const Node: TYamlNode);
begin
  var rangeNode := Node['soundRanges'];
  if not rangeNode.IsNull then
  begin
    for var item in rangeNode do
    begin
      var range := item.As<TPair<Integer,Integer>>;
      for var j := range.Key to range.Value do
        FSoundList := FSoundList + [j];
    end;
  end;
  var soundNode := Node['sounds'];
  if not soundNode.IsNull then
    for var item in soundNode do
      FSoundList := FSoundList + [item.AsInteger];
  FCatFile := Node['file'].AsString(FCatFile);
end;

function TSoundDefinition.GetSoundList: TArray<Integer>;
begin
  Result := FSoundList;
end;

function TSoundDefinition.GetCATFile: string;
begin
  Result := FCatFile;
end;

end.