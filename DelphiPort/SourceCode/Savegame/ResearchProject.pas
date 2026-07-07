unit ResearchProject;

interface

uses
  Classes, SysUtils, YAML, RuleResearch;

type
  TResearchProject = class
  private
    FProject: TRuleResearch;
    FAssigned: Integer;
    FSpent: Integer;
    FCost: Integer;
  public
    constructor Create(Project: TRuleResearch; Cost: Integer = 0);
    function Step: Boolean;
    function IsFinished: Boolean;
    property Assigned: Integer read FAssigned write FAssigned;
    property Spent: Integer read FSpent write FSpent;
    property Cost: Integer read FCost write FCost;
    property Rules: TRuleResearch read FProject;
    procedure Load(const Node: TYamlNode);
    function Save: TYamlNode;
    function GetResearchProgress: string;
  end;

implementation

const
  PROGRESS_LIMIT_UNKNOWN = 0.333;
  PROGRESS_LIMIT_POOR = 0.07;
  PROGRESS_LIMIT_AVERAGE = 0.13;
  PROGRESS_LIMIT_GOOD = 0.25;

constructor TResearchProject.Create(Project: TRuleResearch; Cost: Integer);
begin
  FProject := Project;
  FAssigned := 0;
  FSpent := 0;
  FCost := Cost;
end;

function TResearchProject.Step: Boolean;
begin
  FSpent := FSpent + FAssigned;
  Result := IsFinished;
end;

function TResearchProject.IsFinished: Boolean;
begin
  Result := FSpent >= FCost;
end;

procedure TResearchProject.Load(const Node: TYamlNode);
begin
  FAssigned := Node['assigned'].AsInteger(FAssigned);
  FSpent := Node['spent'].AsInteger(FSpent);
  FCost := Node['cost'].AsInteger(FCost);
end;

function TResearchProject.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['project'] := FProject.Name;
  Result['assigned'] := FAssigned;
  Result['spent'] := FSpent;
  Result['cost'] := FCost;
end;

function TResearchProject.GetResearchProgress: string;
var
  progress: Double;
  rating: Double;
begin
  progress := FSpent / FProject.Cost;
  if FAssigned = 0 then
    Result := 'STR_NONE'
  else if progress <= PROGRESS_LIMIT_UNKNOWN then
    Result := 'STR_UNKNOWN'
  else
  begin
    rating := FAssigned / FProject.Cost;
    if rating <= PROGRESS_LIMIT_POOR then
      Result := 'STR_POOR'
    else if rating <= PROGRESS_LIMIT_AVERAGE then
      Result := 'STR_AVERAGE'
    else if rating <= PROGRESS_LIMIT_GOOD then
      Result := 'STR_GOOD'
    else
      Result := 'STR_EXCELLENT';
  end;
end;

end.