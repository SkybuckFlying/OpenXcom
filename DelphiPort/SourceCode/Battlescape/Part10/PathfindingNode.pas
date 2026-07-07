unit PathfindingNode;

interface

uses
  Classes,
  Battlescape.Position;

type
  TPathfindingNode = class
  private
    FPos: TPosition;
    FChecked: Boolean;
    FTuCost: Integer;
    FPrevNode: TPathfindingNode;
    FPrevDir: Integer;
    FTuGuess: Integer;
    FOpenEntry: Pointer; // invasive for PathfindingOpenSet
  public
    constructor Create(Pos: TPosition);
    destructor Destroy; override;
    function GetPosition: TPosition;
    procedure Reset;
    function IsChecked: Boolean;
    procedure SetChecked;
    function GetTUCost(Missile: Boolean): Integer;
    function GetPrevNode: TPathfindingNode;
    function GetPrevDir: Integer;
    function InOpenSet: Boolean;
    function GetTUGuess: Integer;
    procedure Connect(TuCost: Integer; PrevNode: TPathfindingNode; PrevDir: Integer; Target: TPosition); overload;
    procedure Connect(TuCost: Integer; PrevNode: TPathfindingNode; PrevDir: Integer); overload;
    property PrevNode: TPathfindingNode read GetPrevNode;
    property PrevDir: Integer read GetPrevDir;
    property Checked: Boolean read FChecked write SetChecked;
    property Position: TPosition read FPos;
  end;

  TMinNodeCosts = class
  public
    class function Compare(A, B: TPathfindingNode): Integer; static;
  end;

implementation

uses
  Math;

{ TPathfindingNode }

constructor TPathfindingNode.Create(Pos: TPosition);
begin
  FPos := Pos;
  FChecked := False;
  FTuCost := 0;
  FPrevNode := nil;
  FPrevDir := 0;
  FTuGuess := 0;
  FOpenEntry := nil;
end;

destructor TPathfindingNode.Destroy;
begin
  inherited;
end;

function TPathfindingNode.GetPosition: TPosition;
begin
  Result := FPos;
end;

procedure TPathfindingNode.Reset;
begin
  FChecked := False;
  FOpenEntry := nil;
end;

function TPathfindingNode.IsChecked: Boolean;
begin
  Result := FChecked;
end;

procedure TPathfindingNode.SetChecked;
begin
  FChecked := True;
end;

function TPathfindingNode.GetTUCost(Missile: Boolean): Integer;
begin
  if Missile then Result := 0
  else Result := FTuCost;
end;

function TPathfindingNode.GetPrevNode: TPathfindingNode;
begin
  Result := FPrevNode;
end;

function TPathfindingNode.GetPrevDir: Integer;
begin
  Result := FPrevDir;
end;

function TPathfindingNode.InOpenSet: Boolean;
begin
  Result := FOpenEntry <> nil;
end;

function TPathfindingNode.GetTUGuess: Integer;
begin
  Result := FTuGuess;
end;

procedure TPathfindingNode.Connect(TuCost: Integer; PrevNode: TPathfindingNode; PrevDir: Integer; Target: TPosition);
var
  D: TPosition;
begin
  FTuCost := TuCost;
  FPrevNode := PrevNode;
  FPrevDir := PrevDir;
  if not InOpenSet then
  begin
    D := Target - FPos;
    D.X := D.X * D.X;
    D.Y := D.Y * D.Y;
    D.Z := D.Z * D.Z;
    FTuGuess := Round(4 * Sqrt(D.X + D.Y + D.Z));
  end;
end;

procedure TPathfindingNode.Connect(TuCost: Integer; PrevNode: TPathfindingNode; PrevDir: Integer);
begin
  FTuCost := TuCost;
  FPrevNode := PrevNode;
  FPrevDir := PrevDir;
  FTuGuess := 0;
end;

class function TMinNodeCosts.Compare(A, B: TPathfindingNode): Integer;
begin
  Result := A.GetTUCost(False) - B.GetTUCost(False);
end;

end.