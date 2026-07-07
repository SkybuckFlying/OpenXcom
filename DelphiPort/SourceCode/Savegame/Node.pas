unit Node;

interface

uses
  Classes, SysUtils, Generics.Collections, YAML, Position;

type
  TNodeRank = (NR_SCOUT=0, NR_XCOM, NR_SOLDIER, NR_NAVIGATOR, NR_LEADER,
               NR_ENGINEER, NR_MISC1, NR_MEDIC, NR_MISC2);

  TNode = class
  private
    FId: Integer;
    FPos: TPosition;
    FSegment: Integer;
    FNodeLinks: TList<Integer>;
    FType: Integer;
    FRank: Integer;
    FFlags: Integer;
    FReserved: Integer;
    FPriority: Integer;
    FAllocated: Boolean;
    FDummy: Boolean;
  public
    class var NodeRank: array[0..7, 0..6] of Integer;
    class constructor CreateNodeRank;
    const CRAFTSEGMENT = 1000;
    const UFOSEGMENT = 2000;
    const TYPE_FLYING = $01;
    const TYPE_SMALL = $02;
    const TYPE_DANGEROUS = $04;
    constructor Create; overload;
    constructor Create(Id: Integer; Pos: TPosition; Segment, Typ, Rank, Flags, Reserved, Priority: Integer); overload;
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function Save: TYamlNode;
    property Id: Integer read FId;
    property Rank: TNodeRank read FRank;
    property Priority: Integer read FPriority;
    property Position: TPosition read FPos;
    property Segment: Integer read FSegment;
    property NodeLinks: TList<Integer> read FNodeLinks;
    property Typ: Integer read FType write FType;
    property Flags: Integer read FFlags;
    function IsAllocated: Boolean;
    procedure AllocateNode;
    procedure FreeNode;
    function IsTarget: Boolean;
    procedure SetDummy(Dummy: Boolean);
    function IsDummy: Boolean;
  end;

implementation

constructor TNode.Create;
begin
  FId := 0;
  FSegment := 0;
  FType := 0;
  FRank := 0;
  FFlags := 0;
  FReserved := 0;
  FPriority := 0;
  FAllocated := False;
  FDummy := False;
  FNodeLinks := TList<Integer>.Create;
end;

constructor TNode.Create(Id: Integer; Pos: TPosition; Segment, Typ, Rank, Flags, Reserved, Priority: Integer);
begin
  Create;
  FId := Id;
  FPos := Pos;
  FSegment := Segment;
  FType := Typ;
  FRank := Rank;
  FFlags := Flags;
  FReserved := Reserved;
  FPriority := Priority;
end;

destructor TNode.Destroy;
begin
  FNodeLinks.Free;
  inherited;
end;

class constructor TNode.CreateNodeRank;
begin
  NodeRank[0] := [4,3,5,8,7,2,0]; // commander
  NodeRank[1] := [4,3,5,8,7,2,0]; // leader
  NodeRank[2] := [5,4,3,2,7,8,0]; // engineer
  NodeRank[3] := [7,6,2,8,3,4,0]; // medic
  NodeRank[4] := [3,4,5,2,7,8,0]; // navigator
  NodeRank[5] := [2,5,3,4,6,8,0]; // soldier
  NodeRank[6] := [2,5,3,4,6,8,0]; // terrorist
  NodeRank[7] := [2,5,3,4,6,8,0]; // also terrorist
end;

procedure TNode.Load(const Node: TYamlNode);
begin
  FId := Node['id'].AsInteger(FId);
  FPos := Node['position'].As<TPosition>;
  // FSegment not saved in YAML? skip
  FType := Node['type'].AsInteger(FType);
  FRank := Node['rank'].AsInteger(FRank);
  FFlags := Node['flags'].AsInteger(FFlags);
  FReserved := Node['reserved'].AsInteger(FReserved);
  FPriority := Node['priority'].AsInteger(FPriority);
  FAllocated := Node['allocated'].AsBoolean(FAllocated);
  FNodeLinks.Clear;
  for var v in Node['links'] do FNodeLinks.Add(v.AsInteger);
  FDummy := Node['dummy'].AsBoolean(FDummy);
end;

function TNode.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['id'] := FId;
  Result['position'] := FPos.ToYaml;
  Result['type'] := FType;
  Result['rank'] := FRank;
  Result['flags'] := FFlags;
  Result['reserved'] := FReserved;
  Result['priority'] := FPriority;
  Result['allocated'] := FAllocated;
  Result['links'] := FNodeLinks.ToArray;
  Result['dummy'] := FDummy;
end;

function TNode.IsAllocated: Boolean;
begin
  Result := FAllocated;
end;

procedure TNode.AllocateNode;
begin
  FAllocated := True;
end;

procedure TNode.FreeNode;
begin
  FAllocated := False;
end;

function TNode.IsTarget: Boolean;
begin
  Result := FReserved = 5;
end;

procedure TNode.SetDummy(Dummy: Boolean);
begin
  FDummy := Dummy;
end;

function TNode.IsDummy: Boolean;
begin
  Result := FDummy;
end;

end.