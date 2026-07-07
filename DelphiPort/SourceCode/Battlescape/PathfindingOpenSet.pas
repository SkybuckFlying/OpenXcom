unit PathfindingOpenSet;

interface

uses
  Classes, Contnrs;

type
  TPathfindingNode = class; // forward

  TPathfindingOpenSet = class
  private type
    POpenSetEntry = ^TOpenSetEntry;
    TOpenSetEntry = record
      Cost: Integer;
      Node: TPathfindingNode;
    end;
  private
    FQueue: TObjectList;
    procedure RemoveDiscarded;
  public
    destructor Destroy; override;
    function Pop: TPathfindingNode;
    procedure Push(Node: TPathfindingNode);
    function Empty: Boolean;
  end;

implementation

uses
  PathfindingNode;

destructor TPathfindingOpenSet.Destroy;
begin
  FQueue.Free;
  inherited;
end;

procedure TPathfindingOpenSet.RemoveDiscarded;
begin
  while (FQueue.Count > 0) and (POpenSetEntry(FQueue[0])^.Node = nil) do
  begin
    Dispose(POpenSetEntry(FQueue[0]));
    FQueue.Delete(0);
  end;
end;

function TPathfindingOpenSet.Pop: TPathfindingNode;
var
  Entry: POpenSetEntry;
begin
  RemoveDiscarded;
  if FQueue.Count = 0 then
    raise Exception.Create('OpenSet is empty');
  Entry := POpenSetEntry(FQueue[0]);
  Result := Entry^.Node;
  FQueue.Delete(0);
  Dispose(Entry);
  Result.FOpenEntry := nil;
  RemoveDiscarded;
end;

procedure TPathfindingOpenSet.Push(Node: TPathfindingNode);
var
  Entry: POpenSetEntry;
begin
  New(Entry);
  Entry^.Node := Node;
  Entry^.Cost := Node.GetTUCost(False) + Node.GetTUGuess;
  if Node.FOpenEntry <> nil then
    POpenSetEntry(Node.FOpenEntry)^.Node := nil;
  Node.FOpenEntry := Entry;
  FQueue.Add(Entry);
  // Simple heap insert (min-heap) - in Delphi we can just sort or use a priority queue
  // For simplicity we'll just keep it sorted on each push (inefficient but works for small sets)
  // In original C++ it uses std::priority_queue with custom comparator.
  // We'll implement a simple bubble-up.
  // Since we are not using a proper heap, we'll just sort the list by cost.
  // This is a simplification for demonstration.
  // For production, implement a proper heap.
  FQueue.Sort(TComparer<Pointer>.Construct(
    function(const A, B: Pointer): Integer
    begin
      Result := POpenSetEntry(A)^.Cost - POpenSetEntry(B)^.Cost;
    end
  ));
end;

function TPathfindingOpenSet.Empty: Boolean;
begin
  Result := FQueue.Count = 0;
end;

end.