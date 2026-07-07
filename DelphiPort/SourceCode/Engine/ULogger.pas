unit ULogger;

interface

uses
  SysUtils, Classes;

type
  TSeverityLevel = (LOG_FATAL, LOG_ERROR, LOG_WARNING, LOG_INFO, LOG_DEBUG, LOG_VERBOSE);

  TLogger = class
  private
    FStream: TStringStream;
    class var FReportingLevel: TSeverityLevel;
    class var FLogFile: string;
  public
    constructor Create;
    destructor Destroy; override;
    function Get(ALevel: TSeverityLevel = LOG_INFO): TLogger;
    class procedure SetReportingLevel(ALevel: TSeverityLevel);
    class function ReportingLevel: TSeverityLevel;
    class procedure SetLogFile(const AFile: string);
    class function LogFile: string;
    class function LevelToString(ALevel: TSeverityLevel): string;
  end;

implementation

uses
  UCrossPlatform;

constructor TLogger.Create;
begin
  FStream := TStringStream.Create('');
end;

destructor TLogger.Destroy;
var
  S: string;
  F: TextFile;
begin
  S := Format('[%s] %s', [UCrossPlatform.Now, FStream.DataString]);
  if FLogFile <> '' then
  begin
    AssignFile(F, FLogFile);
    if FileExists(FLogFile) then Append(F) else Rewrite(F);
    WriteLn(F, S);
    CloseFile(F);
  end;
  if (ReportingLevel >= LOG_DEBUG) or (FLogFile = '') then
    Writeln(S);
  FStream.Free;
  inherited;
end;

function TLogger.Get(ALevel: TSeverityLevel): TLogger;
begin
  FStream.WriteString('[' + LevelToString(ALevel) + ']'#9);
  Result := Self;
end;

class procedure TLogger.SetReportingLevel(ALevel: TSeverityLevel);
begin
  FReportingLevel := ALevel;
end;

class function TLogger.ReportingLevel: TSeverityLevel;
begin
  Result := FReportingLevel;
end;

class procedure TLogger.SetLogFile(const AFile: string);
begin
  FLogFile := AFile;
end;

class function TLogger.LogFile: string;
begin
  Result := FLogFile;
end;

class function TLogger.LevelToString(ALevel: TSeverityLevel): string;
const
  Names: array[TSeverityLevel] of string = ('FATAL','ERROR','WARN','INFO','DEBUG','VERB');
begin
  Result := Names[ALevel];
end;

initialization
  TLogger.SetReportingLevel(LOG_DEBUG);
  TLogger.SetLogFile('openxcom.log');
end.