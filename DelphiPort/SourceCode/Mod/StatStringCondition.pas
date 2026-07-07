unit StatStringCondition;

interface

uses
  System.Classes, System.SysUtils;

type
  TStatStringCondition = class
  private
    FName: string;
    FMinVal: Integer;
    FMaxVal: Integer;
  public
    constructor Create(const AName: string; AMinVal, AMaxVal: Integer);
    destructor Destroy; override;
    function GetConditionName: string;
    function GetMinVal: Integer;
    function GetMaxVal: Integer;
    function IsMet(Stat: Integer; Psi: Boolean): Boolean;
  end;

implementation

{ TStatStringCondition }

constructor TStatStringCondition.Create(const AName: string; AMinVal, AMaxVal: Integer);
begin
  inherited Create;
  FName := AName;
  FMinVal := AMinVal;
  FMaxVal := AMaxVal;
end;

destructor TStatStringCondition.Destroy;
begin
  inherited;
end;

function TStatStringCondition.GetConditionName: string;
begin
  Result := FName;
end;

function TStatStringCondition.GetMinVal: Integer;
begin
  Result := FMinVal;
end;

function TStatStringCondition.GetMaxVal: Integer;
begin
  Result := FMaxVal;
end;

function TStatStringCondition.IsMet(Stat: Integer; Psi: Boolean): Boolean;
begin
  if FName = 'psiTraining' then
    Exit(True);
  Result := (Stat >= FMinVal) and (Stat <= FMaxVal);
  if (FName = 'psiStrength') or (FName = 'psiSkill') then
    Result := Result and Psi;
end;

end.