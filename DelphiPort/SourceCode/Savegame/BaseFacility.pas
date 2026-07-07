unit BaseFacility;

interface

uses
  Classes, SysUtils, YAML, RuleBaseFacility, Base, Craft;

type
  TBaseFacility = class
  private
    FRules: TRuleBaseFacility;
    FBase: TBase;
    FX: Integer;
    FY: Integer;
    FBuildTime: Integer;
    FCraftForDrawing: TCraft;
  public
    constructor Create(Rules: TRuleBaseFacility; Base: TBase);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function Save: TYamlNode;
    property Rules: TRuleBaseFacility read FRules;
    property X: Integer read FX write FX;
    property Y: Integer read FY write FY;
    property BuildTime: Integer read FBuildTime write FBuildTime;
    procedure Build;
    function InUse: Boolean;
    property Craft: TCraft read FCraftForDrawing write FCraftForDrawing;
  end;

implementation

constructor TBaseFacility.Create(Rules: TRuleBaseFacility; Base: TBase);
begin
  FRules := Rules;
  FBase := Base;
  FX := -1;
  FY := -1;
  FBuildTime := 0;
  FCraftForDrawing := nil;
end;

destructor TBaseFacility.Destroy;
begin
  inherited;
end;

procedure TBaseFacility.Load(const Node: TYamlNode);
begin
  FX := Node['x'].AsInteger(FX);
  FY := Node['y'].AsInteger(FY);
  FBuildTime := Node['buildTime'].AsInteger(FBuildTime);
end;

function TBaseFacility.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['type'] := FRules.Type;
  Result['x'] := FX;
  Result['y'] := FY;
  if FBuildTime <> 0 then Result['buildTime'] := FBuildTime;
end;

procedure TBaseFacility.Build;
begin
  Dec(FBuildTime);
end;

function TBaseFacility.InUse: Boolean;
begin
  if FBuildTime > 0 then Exit(False);
  Result := (FRules.Personnel > 0) and (FBase.AvailableQuarters - FRules.Personnel < FBase.UsedQuarters) or
            (FRules.Storage > 0) and (FBase.AvailableStores - FRules.Storage < FBase.UsedStores) or
            (FRules.Laboratories > 0) and (FBase.AvailableLaboratories - FRules.Laboratories < FBase.UsedLaboratories) or
            (FRules.Workshops > 0) and (FBase.AvailableWorkshops - FRules.Workshops < FBase.UsedWorkshops) or
            (FRules.Crafts > 0) and (FBase.AvailableHangars - FRules.Crafts < FBase.UsedHangars) or
            (FRules.PsiLaboratories > 0) and (FBase.AvailablePsiLabs - FRules.PsiLaboratories < FBase.UsedPsiLabs) or
            (FRules.Aliens > 0) and (FBase.AvailableContainment - FRules.Aliens < FBase.UsedContainment);
end;

end.