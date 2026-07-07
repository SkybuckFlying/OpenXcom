unit UExtraStrings;

interface

uses
  SysUtils, Classes, Generics.Collections;

type
  TExtraStrings = class
  private
    FStrings: TDictionary<string, string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const ID, Text: string);
    function GetStrings: TDictionary<string, string>;
  end;

implementation

constructor TExtraStrings.Create;
begin
  FStrings := TDictionary<string, string>.Create;
end;

destructor TExtraStrings.Destroy;
begin
  FStrings.Free;
  inherited;
end;

procedure TExtraStrings.Add(const ID, Text: string);
begin
  FStrings.Add(ID, Text);
end;

function TExtraStrings.GetStrings: TDictionary<string, string>;
begin
  Result := FStrings;
end;

end.