unit RuleBaseFacility;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, ModUnit;

type
  TRuleBaseFacility = class
  private
    FType: string;
    FRequires: TArray<string>;
    FSpriteShape: Integer;
    FSpriteFacility: Integer;
    FLift: Boolean;
    FHyper: Boolean;
    FMind: Boolean;
    FGrav: Boolean;
    FSize: Integer;
    FBuildCost: Integer;
    FBuildTime: Integer;
    FMonthlyCost: Integer;
    FStorage: Integer;
    FPersonnel: Integer;
    FAliens: Integer;
    FCrafts: Integer;
    FLabs: Integer;
    FWorkshops: Integer;
    FPsiLabs: Integer;
    FRadarRange: Integer;
    FRadarChance: Integer;
    FDefense: Integer;
    FHitRatio: Integer;
    FFireSound: Integer;
    FHitSound: Integer;
    FMapName: string;
    FListOrder: Integer;
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode; ModObj: TMod; AListOrder: Integer);
    function GetType: string;
    function GetRequirements: TArray<string>;
    function GetSpriteShape: Integer;
    function GetSpriteFacility: Integer;
    function GetSize: Integer;
    function IsLift: Boolean;
    function IsHyperwave: Boolean;
    function IsMindShield: Boolean;
    function IsGravShield: Boolean;
    function GetBuildCost: Integer;
    function GetBuildTime: Integer;
    function GetMonthlyCost: Integer;
    function GetStorage: Integer;
    function GetPersonnel: Integer;
    function GetAliens: Integer;
    function GetCrafts: Integer;
    function GetLaboratories: Integer;
    function GetWorkshops: Integer;
    function GetPsiLaboratories: Integer;
    function GetRadarRange: Integer;
    function GetRadarChance: Integer;
    function GetDefenseValue: Integer;
    function GetHitRatio: Integer;
    function GetMapName: string;
    function GetHitSound: Integer;
    function GetFireSound: Integer;
    function GetListOrder: Integer;
  end;

implementation

{ TRuleBaseFacility }

constructor TRuleBaseFacility.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FSpriteShape := -1;
  FSpriteFacility := -1;
  FLift := False;
  FHyper := False;
  FMind := False;
  FGrav := False;
  FSize := 1;
  FBuildCost := 0;
  FBuildTime := 0;
  FMonthlyCost := 0;
  FStorage := 0;
  FPersonnel := 0;
  FAliens := 0;
  FCrafts := 0;
  FLabs := 0;
  FWorkshops := 0;
  FPsiLabs := 0;
  FRadarRange := 0;
  FRadarChance := 0;
  FDefense := 0;
  FHitRatio := 0;
  FFireSound := 0;
  FHitSound := 0;
  FListOrder := 0;
end;

destructor TRuleBaseFacility.Destroy;
begin
  inherited;
end;

procedure TRuleBaseFacility.Load(const Node: TYamlNode; ModObj: TMod; AListOrder: Integer);
begin
  FType := Node['type'].AsString(FType);
  FRequires := Node['requires'].AsArray<string>(FRequires);
  ModObj.LoadSpriteOffset(FType, FSpriteShape, Node['spriteShape'], 'BASEBITS.PCK');
  ModObj.LoadSpriteOffset(FType, FSpriteFacility, Node['spriteFacility'], 'BASEBITS.PCK');
  FLift := Node['lift'].AsBoolean(FLift);
  FHyper := Node['hyper'].AsBoolean(FHyper);
  FMind := Node['mind'].AsBoolean(FMind);
  FGrav := Node['grav'].AsBoolean(FGrav);
  FSize := Node['size'].AsInteger(FSize);
  FBuildCost := Node['buildCost'].AsInteger(FBuildCost);
  FBuildTime := Node['buildTime'].AsInteger(FBuildTime);
  FMonthlyCost := Node['monthlyCost'].AsInteger(FMonthlyCost);
  FStorage := Node['storage'].AsInteger(FStorage);
  FPersonnel := Node['personnel'].AsInteger(FPersonnel);
  FAliens := Node['aliens'].AsInteger(FAliens);
  FCrafts := Node['crafts'].AsInteger(FCrafts);
  FLabs := Node['labs'].AsInteger(FLabs);
  FWorkshops := Node['workshops'].AsInteger(FWorkshops);
  FPsiLabs := Node['psiLabs'].AsInteger(FPsiLabs);
  FRadarRange := Node['radarRange'].AsInteger(FRadarRange);
  FRadarChance := Node['radarChance'].AsInteger(FRadarChance);
  FDefense := Node['defense'].AsInteger(FDefense);
  FHitRatio := Node['hitRatio'].AsInteger(FHitRatio);
  ModObj.LoadSoundOffset(FType, FFireSound, Node['fireSound'], 'GEO.CAT');
  ModObj.LoadSoundOffset(FType, FHitSound, Node['hitSound'], 'GEO.CAT');
  FMapName := Node['mapName'].AsString(FMapName);
  FListOrder := Node['listOrder'].AsInteger(FListOrder);
  if FListOrder = 0 then FListOrder := AListOrder;
end;

// Getters
function TRuleBaseFacility.GetType: string;
begin
  Result := FType;
end;

function TRuleBaseFacility.GetRequirements: TArray<string>;
begin
  Result := FRequires;
end;

function TRuleBaseFacility.GetSpriteShape: Integer;
begin
  Result := FSpriteShape;
end;

function TRuleBaseFacility.GetSpriteFacility: Integer;
begin
  Result := FSpriteFacility;
end;

function TRuleBaseFacility.GetSize: Integer;
begin
  Result := FSize;
end;

function TRuleBaseFacility.IsLift: Boolean;
begin
  Result := FLift;
end;

function TRuleBaseFacility.IsHyperwave: Boolean;
begin
  Result := FHyper;
end;

function TRuleBaseFacility.IsMindShield: Boolean;
begin
  Result := FMind;
end;

function TRuleBaseFacility.IsGravShield: Boolean;
begin
  Result := FGrav;
end;

function TRuleBaseFacility.GetBuildCost: Integer;
begin
  Result := FBuildCost;
end;

function TRuleBaseFacility.GetBuildTime: Integer;
begin
  Result := FBuildTime;
end;

function TRuleBaseFacility.GetMonthlyCost: Integer;
begin
  Result := FMonthlyCost;
end;

function TRuleBaseFacility.GetStorage: Integer;
begin
  Result := FStorage;
end;

function TRuleBaseFacility.GetPersonnel: Integer;
begin
  Result := FPersonnel;
end;

function TRuleBaseFacility.GetAliens: Integer;
begin
  Result := FAliens;
end;

function TRuleBaseFacility.GetCrafts: Integer;
begin
  Result := FCrafts;
end;

function TRuleBaseFacility.GetLaboratories: Integer;
begin
  Result := FLabs;
end;

function TRuleBaseFacility.GetWorkshops: Integer;
begin
  Result := FWorkshops;
end;

function TRuleBaseFacility.GetPsiLaboratories: Integer;
begin
  Result := FPsiLabs;
end;

function TRuleBaseFacility.GetRadarRange: Integer;
begin
  Result := FRadarRange;
end;

function TRuleBaseFacility.GetRadarChance: Integer;
begin
  Result := FRadarChance;
end;

function TRuleBaseFacility.GetDefenseValue: Integer;
begin
  Result := FDefense;
end;

function TRuleBaseFacility.GetHitRatio: Integer;
begin
  Result := FHitRatio;
end;

function TRuleBaseFacility.GetMapName: string;
begin
  Result := FMapName;
end;

function TRuleBaseFacility.GetHitSound: Integer;
begin
  Result := FHitSound;
end;

function TRuleBaseFacility.GetFireSound: Integer;
begin
  Result := FFireSound;
end;

function TRuleBaseFacility.GetListOrder: Integer;
begin
  Result := FListOrder;
end;

end.