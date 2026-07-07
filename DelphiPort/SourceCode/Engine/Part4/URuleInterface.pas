unit URuleInterface;

interface

uses
  SysUtils, Classes, Generics.Collections;

type
  TElement = record
    x, y, w, h: Integer;
    color, color2, border: Integer;
    TFTDMode: Boolean;
  end;

  TRuleInterface = class
  private
    FParent: string;
    FPalette: string;
    FMusic: string;
    FElements: TDictionary<string, TElement>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetParent(const Parent: string);
    procedure SetPalette(const Palette: string);
    procedure SetMusic(const Music: string);
    procedure AddElement(const ID: string; const Element: TElement);
    function GetParent: string;
    function GetPalette: string;
    function GetMusic: string;
    function GetElement(const ID: string): TElement;
    function HasElement(const ID: string): Boolean;
  end;

implementation

constructor TRuleInterface.Create;
begin
  FElements := TDictionary<string, TElement>.Create;
end;

destructor TRuleInterface.Destroy;
begin
  FElements.Free;
  inherited;
end;

procedure TRuleInterface.SetParent(const Parent: string);
begin
  FParent := Parent;
end;

procedure TRuleInterface.SetPalette(const Palette: string);
begin
  FPalette := Palette;
end;

procedure TRuleInterface.SetMusic(const Music: string);
begin
  FMusic := Music;
end;

procedure TRuleInterface.AddElement(const ID: string; const Element: TElement);
begin
  FElements.Add(ID, Element);
end;

function TRuleInterface.GetParent: string;
begin
  Result := FParent;
end;

function TRuleInterface.GetPalette: string;
begin
  Result := FPalette;
end;

function TRuleInterface.GetMusic: string;
begin
  Result := FMusic;
end;

function TRuleInterface.GetElement(const ID: string): TElement;
begin
  Result := FElements[ID];
end;

function TRuleInterface.HasElement(const ID: string): Boolean;
begin
  Result := FElements.ContainsKey(ID);
end;

end.