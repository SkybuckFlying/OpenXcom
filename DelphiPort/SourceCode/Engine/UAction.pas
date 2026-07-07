unit UAction;

interface

uses
  SDL;

type
  TAction = class
  private
    FEvent: PSDL_Event;
    FScaleX, FScaleY: Double;
    FTopBlackBand, FLeftBlackBand: Integer;
    FMouseX, FMouseY, FSurfaceX, FSurfaceY: Integer;
    FSender: Pointer; // InteractiveSurface reference
  public
    constructor Create(Event: PSDL_Event; ScaleX, ScaleY: Double; TopBlackBand, LeftBlackBand: Integer);
    destructor Destroy; override;
    function GetXScale: Double;
    function GetYScale: Double;
    procedure SetMouseAction(MouseX, MouseY, SurfaceX, SurfaceY: Integer);
    function IsMouseAction: Boolean;
    function GetTopBlackBand: Integer;
    function GetLeftBlackBand: Integer;
    function GetXMouse: Integer;
    function GetYMouse: Integer;
    function GetAbsoluteXMouse: Double;
    function GetAbsoluteYMouse: Double;
    function GetRelativeXMouse: Double;
    function GetRelativeYMouse: Double;
    function GetSender: Pointer;
    procedure SetSender(Sender: Pointer);
    function GetDetails: PSDL_Event;
  end;

implementation

constructor TAction.Create(Event: PSDL_Event; ScaleX, ScaleY: Double; TopBlackBand, LeftBlackBand: Integer);
begin
  FEvent := Event;
  FScaleX := ScaleX;
  FScaleY := ScaleY;
  FTopBlackBand := TopBlackBand;
  FLeftBlackBand := LeftBlackBand;
  FMouseX := -1;
  FMouseY := -1;
  FSurfaceX := -1;
  FSurfaceY := -1;
  FSender := nil;
end;

destructor TAction.Destroy;
begin
  inherited;
end;

function TAction.GetXScale: Double;
begin
  Result := FScaleX;
end;

function TAction.GetYScale: Double;
begin
  Result := FScaleY;
end;

procedure TAction.SetMouseAction(MouseX, MouseY, SurfaceX, SurfaceY: Integer);
begin
  FMouseX := MouseX - FLeftBlackBand;
  FMouseY := MouseY - FTopBlackBand;
  FSurfaceX := SurfaceX;
  FSurfaceY := SurfaceY;
end;

function TAction.IsMouseAction: Boolean;
begin
  Result := FMouseX <> -1;
end;

function TAction.GetTopBlackBand: Integer;
begin
  Result := FTopBlackBand;
end;

function TAction.GetLeftBlackBand: Integer;
begin
  Result := FLeftBlackBand;
end;

function TAction.GetXMouse: Integer;
begin
  Result := FMouseX;
end;

function TAction.GetYMouse: Integer;
begin
  Result := FMouseY;
end;

function TAction.GetAbsoluteXMouse: Double;
begin
  if FMouseX = -1 then Result := -1
  else Result := FMouseX / FScaleX;
end;

function TAction.GetAbsoluteYMouse: Double;
begin
  if FMouseY = -1 then Result := -1
  else Result := FMouseY / FScaleY;
end;

function TAction.GetRelativeXMouse: Double;
begin
  if FMouseX = -1 then Result := -1
  else Result := FMouseX - FSurfaceX * FScaleX;
end;

function TAction.GetRelativeYMouse: Double;
begin
  if FMouseY = -1 then Result := -1
  else Result := FMouseY - FSurfaceY * FScaleY;
end;

function TAction.GetSender: Pointer;
begin
  Result := FSender;
end;

procedure TAction.SetSender(Sender: Pointer);
begin
  FSender := Sender;
end;

function TAction.GetDetails: PSDL_Event;
begin
  Result := FEvent;
end;

end.