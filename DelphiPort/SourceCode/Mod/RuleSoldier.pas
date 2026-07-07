unit RuleSoldier;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, UnitStats, ModUnit, SoldierNamePool, Engine.FileMap;

type
  TRuleSoldier = class
  private
    FType: string;
    FRequires: TArray<string>;
    FMinStats: TUnitStats;
    FMaxStats: TUnitStats;
    FStatCaps: TUnitStats;
    FArmor: string;
    FCostBuy: Integer;
    FCostSalary: Integer;
    FStandHeight: Integer;
    FKneelHeight: Integer;
    FFloatHeight: Integer;
    FFemaleFrequency: Integer;
    FValue: Integer;
    FTransferTime: Integer;
    FDeathSoundMale: TArray<Integer>;
    FDeathSoundFemale: TArray<Integer>;
    FNames: TArray<TSoldierNamePool>;
    procedure AddSoldierNamePool(const NamFile: string);
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode; ModObj: TMod);
    function GetType: string;
    function GetRequirements: TArray<string>;
    function GetMinStats: TUnitStats;
    function GetMaxStats: TUnitStats;
    function GetStatCaps: TUnitStats;
    function GetArmor: string;
    function GetBuyCost: Integer;
    function GetSalaryCost: Integer;
    function GetStandHeight: Integer;
    function GetKneelHeight: Integer;
    function GetFloatHeight: Integer;
    function GetFemaleFrequency: Integer;
    function GetMaleDeathSounds: TArray<Integer>;
    function GetFemaleDeathSounds: TArray<Integer>;
    function GetNames: TArray<TSoldierNamePool>;
    function GetValue: Integer;
    function GetTransferTime: Integer;
  end;

implementation

{ TRuleSoldier }

constructor TRuleSoldier.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  if FType = 'XCOM' then FType := 'STR_SOLDIER';
  FCostBuy := 0; FCostSalary := 0; FStandHeight := 0; FKneelHeight := 0;
  FFloatHeight := 0; FFemaleFrequency := 50; FValue := 20; FTransferTime := 0;
end;

destructor TRuleSoldier.Destroy;
begin
  for var pool in FNames do pool.Free;
  inherited;
end;

procedure TRuleSoldier.AddSoldierNamePool(const NamFile: string);
var
  pool: TSoldierNamePool;
begin
  pool := TSoldierNamePool.Create;
  pool.Load(TFileMap.GetFilePath(NamFile));
  FNames := FNames + [pool];
end;

procedure TRuleSoldier.Load(const Node: TYamlNode; ModObj: TMod);
begin
  FType := Node['type'].AsString(FType);
  if FType = 'XCOM' then FType := 'STR_SOLDIER';
  FRequires := Node['requires'].AsArray<string>(FRequires);
  FMinStats.Merge(Node['minStats'].As<TUnitStats>(FMinStats));
  FMaxStats.Merge(Node['maxStats'].As<TUnitStats>(FMaxStats));
  FStatCaps.Merge(Node['statCaps'].As<TUnitStats>(FStatCaps));
  FArmor := Node['armor'].AsString(FArmor);
  FCostBuy := Node['costBuy'].AsInteger(FCostBuy);
  FCostSalary := Node['costSalary'].AsInteger(FCostSalary);
  FStandHeight := Node['standHeight'].AsInteger(FStandHeight);
  FKneelHeight := Node['kneelHeight'].AsInteger(FKneelHeight);
  FFloatHeight := Node['floatHeight'].AsInteger(FFloatHeight);
  FFemaleFrequency := Node['femaleFrequency'].AsInteger(FFemaleFrequency);
  FValue := Node['value'].AsInteger(FValue);
  FTransferTime := Node['transferTime'].AsInteger(FTransferTime);
  ModObj.LoadSoundOffset(FType, FDeathSoundMale, Node['deathMale'], 'BATTLE.CAT');
  ModObj.LoadSoundOffset(FType, FDeathSoundFemale, Node['deathFemale'], 'BATTLE.CAT');

  var nameNode := Node['soldierNames'];
  if not nameNode.IsNull then
  begin
    for var item in nameNode do
    begin
      var fileName := item.AsString;
      if fileName = 'delete' then
      begin
        for var pool in FNames do pool.Free;
        FNames := [];
      end
      else
      begin
        if fileName[fileName.Length] = '/' then
        begin
          var contents := TFileMap.GetVFolderContents(fileName);
          for var sub in contents do
            if ExtractFileExt(sub).ToUpper = '.NAM' then
              AddSoldierNamePool(fileName + sub);
        end
        else
          AddSoldierNamePool(fileName);
      end;
    end;
  end;
end;

// Getters
function TRuleSoldier.GetType: string; begin Result := FType; end;
function TRuleSoldier.GetRequirements: TArray<string>; begin Result := FRequires; end;
function TRuleSoldier.GetMinStats: TUnitStats; begin Result := FMinStats; end;
function TRuleSoldier.GetMaxStats: TUnitStats; begin Result := FMaxStats; end;
function TRuleSoldier.GetStatCaps: TUnitStats; begin Result := FStatCaps; end;
function TRuleSoldier.GetArmor: string; begin Result := FArmor; end;
function TRuleSoldier.GetBuyCost: Integer; begin Result := FCostBuy; end;
function TRuleSoldier.GetSalaryCost: Integer; begin Result := FCostSalary; end;
function TRuleSoldier.GetStandHeight: Integer; begin Result := FStandHeight; end;
function TRuleSoldier.GetKneelHeight: Integer; begin Result := FKneelHeight; end;
function TRuleSoldier.GetFloatHeight: Integer; begin Result := FFloatHeight; end;
function TRuleSoldier.GetFemaleFrequency: Integer; begin Result := FFemaleFrequency; end;
function TRuleSoldier.GetMaleDeathSounds: TArray<Integer>; begin Result := FDeathSoundMale; end;
function TRuleSoldier.GetFemaleDeathSounds: TArray<Integer>; begin Result := FDeathSoundFemale; end;
function TRuleSoldier.GetNames: TArray<TSoldierNamePool>; begin Result := FNames; end;
function TRuleSoldier.GetValue: Integer; begin Result := FValue; end;
function TRuleSoldier.GetTransferTime: Integer; begin Result := FTransferTime; end;

end.