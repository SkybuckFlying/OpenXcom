unit BattleState;

interface

uses
  System.SysUtils,
  Battlescape.BattlescapeGame;

type
  TBattleState = class
  protected
    FParent: TBattlescapeGame;
    FAction: TBattleAction;
  public
    constructor Create(AParent: TBattlescapeGame; AAction: TBattleAction); overload;
    constructor Create(AParent: TBattlescapeGame); overload;
    destructor Destroy; override;
    procedure Init; virtual;
    procedure Cancel; virtual;
    procedure Think; virtual;
    function GetAction: TBattleAction;
  end;

implementation

constructor TBattleState.Create(AParent: TBattlescapeGame; AAction: TBattleAction);
begin
  inherited Create;
  FParent := AParent;
  FAction := AAction;
end;

constructor TBattleState.Create(AParent: TBattlescapeGame);
begin
  Create(AParent, TBattleAction.Create);
end;

destructor TBattleState.Destroy;
begin
  FAction.Free;
  inherited;
end;

procedure TBattleState.Init;
begin
  // empty
end;

procedure TBattleState.Cancel;
begin
  // empty
end;

procedure TBattleState.Think;
begin
  // empty
end;

function TBattleState.GetAction: TBattleAction;
begin
  Result := FAction;
end;

end.