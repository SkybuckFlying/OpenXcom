unit OpenXcom.Savegame;

interface

type
  TSaveGame = class
  public
    procedure Save(const AFileName: string);
    procedure Load(const AFileName: string; AMod: TMod);
    function IsIronman: Boolean;
    function GetName: string;
    procedure SetName(const AName: string);
    function GetEnding: Integer;
    function GetDifficulty: Integer;
    procedure SetDifficulty(ADiff: Integer);
    procedure SetIronman(AIron: Boolean);
    function GetMonthsPassed: Integer;
    function GetSavedBattle: TSavedBattleGame;
    procedure SetBattleGame(ABattle: TSavedBattleGame);
  end;

  TSavedBattleGame = class
  end;

  TCraft = class
  end;

  TModInfo = class; // forward

  TSlideshowHeader = record end;
  TSlideshowSlide = record end;
  TSlideshowSlideList = TArray<TSlideshowSlide>;

implementation

end.