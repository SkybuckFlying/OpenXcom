unit ImageButton;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics,
  Common;

type
  TImageButton = class(TInteractiveSurface)
  private
    FColor: TColor;
    FGroup: ^TImageButton;
    FInverted: Boolean;
  protected
    function IsButtonHandled(Button: TMouseButton): Boolean; override;
  public
    constructor Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent); reintroduce;
    destructor Destroy; override;
    procedure SetColor(Color: TColor);
    function GetColor: TColor;
    procedure SetGroup(Group: Pointer);
    procedure MousePress(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseRelease(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Toggle(Press: Boolean);
  end;

implementation

constructor TImageButton.Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := AWidth;
  Height := AHeight;
  Left := AX;
  Top := AY;
  FColor := 0;
  FGroup := nil;
  FInverted := False;
end;

destructor TImageButton.Destroy;
begin
  inherited;
end;

function TImageButton.IsButtonHandled(Button: TMouseButton): Boolean;
begin
  Result := True;
end;

procedure TImageButton.SetColor(Color: TColor);
begin
  FColor := Color;
end;

function TImageButton.GetColor: TColor;
begin
  Result := FColor;
end;

procedure TImageButton.SetGroup(Group: Pointer);
begin
  FGroup := Group;
  if (FGroup <> nil) and (FGroup^ = Self) then
    InvertColor(FColor + 3);
end;

procedure TImageButton.MousePress(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if FGroup <> nil then
  begin
    if Button = mbLeft then
    begin
      FGroup^.InvertColor(FGroup^.GetColor + 3);
      FGroup^ := Self;
      InvertColor(FColor + 3);
    end;
  end
  else if not FInverted and IsButtonHandled(Button) then
  begin
    FInverted := True;
    InvertColor(FColor + 3);
  end;
end;

procedure TImageButton.MouseRelease(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if FInverted and IsButtonHandled(Button) then
  begin
    FInverted := False;
    InvertColor(FColor + 3);
  end;
end;

procedure TImageButton.Toggle(Press: Boolean);
begin
  if FInverted <> Press then
  begin
    FInverted := not FInverted;
    InvertColor(FColor + 3);
  end;
end;

end.