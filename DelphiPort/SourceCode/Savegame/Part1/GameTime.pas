unit GameTime;

interface

uses
  Classes, SysUtils, YAML;

type
  TTimeTrigger = (tt5Sec, tt10Min, tt30Min, tt1Hour, tt1Day, tt1Month);

  TGameTime = class
  private
    FSecond: Integer;
    FMinute: Integer;
    FHour: Integer;
    FWeekday: Integer;
    FDay: Integer;
    FMonth: Integer;
    FYear: Integer;
  public
    constructor Create(AWeekday, ADay, AMonth, AYear, AHour, AMinute, ASecond: Integer);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function Save: TYamlNode;
    function Advance: TTimeTrigger;
    property Second: Integer read FSecond;
    property Minute: Integer read FMinute;
    property Hour: Integer read FHour;
    property Weekday: Integer read FWeekday;
    function WeekdayString: string;
    property Day: Integer read FDay;
    function DayString(Lang: TLanguage): string;
    property Month: Integer read FMonth;
    function MonthString: string;
    property Year: Integer read FYear;
    function Daylight: Double;
  end;

implementation

uses
  Math;

constructor TGameTime.Create(AWeekday, ADay, AMonth, AYear, AHour, AMinute, ASecond: Integer);
begin
  FSecond := ASecond;
  FMinute := AMinute;
  FHour := AHour;
  FWeekday := AWeekday;
  FDay := ADay;
  FMonth := AMonth;
  FYear := AYear;
end;

destructor TGameTime.Destroy;
begin
  inherited;
end;

procedure TGameTime.Load(const Node: TYamlNode);
begin
  FSecond := Node['second'].AsInteger(FSecond);
  FMinute := Node['minute'].AsInteger(FMinute);
  FHour := Node['hour'].AsInteger(FHour);
  FWeekday := Node['weekday'].AsInteger(FWeekday);
  FDay := Node['day'].AsInteger(FDay);
  FMonth := Node['month'].AsInteger(FMonth);
  FYear := Node['year'].AsInteger(FYear);
end;

function TGameTime.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['second'] := FSecond;
  Result['minute'] := FMinute;
  Result['hour'] := FHour;
  Result['weekday'] := FWeekday;
  Result['day'] := FDay;
  Result['month'] := FMonth;
  Result['year'] := FYear;
end;

function TGameTime.Advance: TTimeTrigger;
var
  monthDays: array[1..12] of Integer;
begin
  Result := tt5Sec;
  monthDays := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  if ((FYear mod 4 = 0) and not ((FYear mod 100 = 0) and (FYear mod 400 <> 0))) then
    Inc(monthDays[2]);

  Inc(FSecond, 5);
  if FSecond >= 60 then
  begin
    Inc(FMinute);
    FSecond := 0;
    if FMinute mod 10 = 0 then
      Result := tt10Min;
    if FMinute mod 30 = 0 then
      Result := tt30Min;
  end;
  if FMinute >= 60 then
  begin
    Inc(FHour);
    FMinute := 0;
    Result := tt1Hour;
  end;
  if FHour >= 24 then
  begin
    Inc(FDay);
    Inc(FWeekday);
    FHour := 0;
    Result := tt1Day;
  end;
  if FWeekday > 7 then
    FWeekday := 1;
  if FDay > monthDays[FMonth] then
  begin
    FDay := 1;
    Inc(FMonth);
    Result := tt1Month;
  end;
  if FMonth > 12 then
  begin
    FMonth := 1;
    Inc(FYear);
  end;
end;

function TGameTime.WeekdayString: string;
var
  weekdays: array[0..6] of string;
begin
  weekdays := ['STR_SUNDAY', 'STR_MONDAY', 'STR_TUESDAY', 'STR_WEDNESDAY', 'STR_THURSDAY', 'STR_FRIDAY', 'STR_SATURDAY'];
  Result := weekdays[FWeekday - 1];
end;

function TGameTime.DayString(Lang: TLanguage): string;
var
  s: string;
begin
  case FDay of
    1, 21, 31: s := 'STR_DATE_FIRST';
    2, 22: s := 'STR_DATE_SECOND';
    3, 23: s := 'STR_DATE_THIRD';
  else
    s := 'STR_DATE_FOURTH';
  end;
  Result := Lang.GetString(s).Format([FDay]);
end;

function TGameTime.MonthString: string;
var
  months: array[0..11] of string;
begin
  months := ['STR_JAN', 'STR_FEB', 'STR_MAR', 'STR_APR', 'STR_MAY', 'STR_JUN',
             'STR_JUL', 'STR_AUG', 'STR_SEP', 'STR_OCT', 'STR_NOV', 'STR_DEC'];
  Result := months[FMonth - 1];
end;

function TGameTime.Daylight: Double;
begin
  Result := (((((FHour + 18) mod 24) * 60 + FMinute) * 60 + FSecond) / (60 * 60 * 24));
end;

end.