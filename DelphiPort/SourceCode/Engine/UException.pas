unit UException;

interface

uses
  SysUtils;

type
  EOpenXcom = class(Exception)
  public
    constructor Create(const Msg: string);
  end;

implementation

constructor EOpenXcom.Create(const Msg: string);
begin
  inherited Create(Msg);
end;

end.