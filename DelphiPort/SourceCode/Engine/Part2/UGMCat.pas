unit UGMCat;

interface

uses
  UCatFile, UMusic;

type
  TGMCatFile = class(TCatFile)
  public
    function LoadMIDI(Index: Integer): TMusic;
  end;

implementation

function TGMCatFile.LoadMIDI(Index: Integer): TMusic;
var
  Data: TBytes;
begin
  Result := TMusic.Create;
  try
    Data := Load(Index, False);
    if Data <> nil then
      Result.Load(@Data[0], Length(Data));
  except
    Result.Free;
    raise;
  end;
end;

end.