unit UCrossPlatform;

interface

uses
  SysUtils, Classes, SDL;

type
  TCrossPlatform = class
  public
    class function Now: string;
    class function FindDataFolders: TArray<string>;
    class function FindUserFolders: TArray<string>;
    class function FindConfigFolder: string;
    class function SearchDataFile(const Filename: string): string;
    class function SearchDataFolder(const Foldername: string; Size: Integer = 0): string;
    class function CreateFolder(const Path: string): Boolean;
    class function EndPath(const Path: string): string;
    class function GetFolderContents(const Path, Ext: string): TArray<string>;
    class function FolderMinSize(const Path: string; Size: Integer): Boolean;
    class function FolderExists(const Path: string): Boolean;
    class function FileExists(const Path: string): Boolean;
    class function DeleteFile(const Path: string): Boolean;
    class function BaseFilename(const Path: string): string;
    class function SanitizeFilename(const Filename: string): string;
    class function NoExt(const Filename: string): string;
    class function GetExt(const Filename: string): string;
    class function CompareExt(const Filename, Extension: string): Boolean;
    class function GetLocale: string;
    class function IsQuitShortcut(const Event: TSDL_Event): Boolean;
    class function GetDateModified(const Path: string): TDateTime;
    class function TimeToString(ATime: TDateTime): TArray<string>;
    class function MoveFile(const Src, Dest: string): Boolean;
    class procedure FlashWindow;
    class function GetDosPath: string;
    class procedure SetWindowIcon(WinResource: Integer; const UnixPath: string);
    class procedure StackTrace(Context: Pointer);
    class procedure CrashDump(ExceptionData: Pointer; const ErrorMsg: string);
    class function OpenExplorer(const URL: string): Boolean;
    class function GetExeFolder: string;
  end;

implementation

uses
  UUnicode, ULogger, SysUtils, DateUtils, IOUtils;

class function TCrossPlatform.Now: string;
begin
  Result := FormatDateTime('dd-mm-yyyy_hh-nn-ss', SysUtils.Now);
end;

class function TCrossPlatform.FindDataFolders: TArray<string>;
begin
  // Return a list of candidate data folders (platform-specific)
  SetLength(Result, 1);
  Result[0] := ExtractFilePath(ParamStr(0)) + 'data' + PathDelim;
end;

class function TCrossPlatform.FindUserFolders: TArray<string>;
begin
  SetLength(Result, 1);
  Result[0] := ExtractFilePath(ParamStr(0)) + 'user' + PathDelim;
end;

class function TCrossPlatform.FindConfigFolder: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + 'config' + PathDelim;
end;

class function TCrossPlatform.SearchDataFile(const Filename: string): string;
begin
  // Simplified: just return Filename
  Result := Filename;
end;

class function TCrossPlatform.SearchDataFolder(const Foldername: string; Size: Integer): string;
begin
  Result := Foldername;
end;

class function TCrossPlatform.CreateFolder(const Path: string): Boolean;
begin
  Result := ForceDirectories(Path);
end;

class function TCrossPlatform.EndPath(const Path: string): string;
begin
  if (Path <> '') and (Path[Length(Path)] <> PathDelim) then
    Result := Path + PathDelim
  else
    Result := Path;
end;

class function TCrossPlatform.GetFolderContents(const Path, Ext: string): TArray<string>;
var
  Files: TArray<string>;
  S: string;
begin
  Result := [];
  if not FolderExists(Path) then Exit;
  Files := TDirectory.GetFiles(Path);
  for S in Files do
    if (Ext = '') or (CompareText(ExtractFileExt(S), Ext) = 0) then
    begin
      SetLength(Result, Length(Result)+1);
      Result[High(Result)] := ExtractFileName(S);
    end;
end;

class function TCrossPlatform.FolderMinSize(const Path: string; Size: Integer): Boolean;
var
  Files: TArray<string>;
begin
  Result := False;
  if not FolderExists(Path) then Exit;
  Files := TDirectory.GetFiles(Path);
  Result := Length(Files) >= Size;
end;

class function TCrossPlatform.FolderExists(const Path: string): Boolean;
begin
  Result := DirectoryExists(Path);
end;

class function TCrossPlatform.FileExists(const Path: string): Boolean;
begin
  Result := SysUtils.FileExists(Path);
end;

class function TCrossPlatform.DeleteFile(const Path: string): Boolean;
begin
  Result := SysUtils.DeleteFile(Path);
end;

class function TCrossPlatform.BaseFilename(const Path: string): string;
begin
  Result := ExtractFileName(Path);
end;

class function TCrossPlatform.SanitizeFilename(const Filename: string): string;
var
  I: Integer;
begin
  Result := Filename;
  for I := 1 to Length(Result) do
    if CharInSet(Result[I], ['<','>',':','"','/','?','\']) then
      Result[I] := '_';
end;

class function TCrossPlatform.NoExt(const Filename: string): string;
begin
  Result := ChangeFileExt(Filename, '');
end;

class function TCrossPlatform.GetExt(const Filename: string): string;
begin
  Result := ExtractFileExt(Filename);
end;

class function TCrossPlatform.CompareExt(const Filename, Extension: string): Boolean;
begin
  Result := CompareText(ExtractFileExt(Filename), Extension) = 0;
end;

class function TCrossPlatform.GetLocale: string;
begin
  Result := 'en-US'; // fallback
end;

class function TCrossPlatform.IsQuitShortcut(const Event: TSDL_Event): Boolean;
begin
  Result := False; // simplified
end;

class function TCrossPlatform.GetDateModified(const Path: string): TDateTime;
begin
  if FileExists(Path) then
    Result := FileAge(Path)
  else
    Result := 0;
end;

class function TCrossPlatform.TimeToString(ATime: TDateTime): TArray<string>;
begin
  SetLength(Result, 2);
  Result[0] := FormatDateTime('yyyy-mm-dd', ATime);
  Result[1] := FormatDateTime('hh:nn', ATime);
end;

class function TCrossPlatform.MoveFile(const Src, Dest: string): Boolean;
begin
  Result := SysUtils.RenameFile(Src, Dest);
end;

class procedure TCrossPlatform.FlashWindow;
begin
  // Platform-specific
end;

class function TCrossPlatform.GetDosPath: string;
begin
  Result := 'C:\GAMES\OPENXCOM';
end;

class procedure TCrossPlatform.SetWindowIcon(WinResource: Integer; const UnixPath: string);
begin
  // Not implemented for Delphi
end;

class procedure TCrossPlatform.StackTrace(Context: Pointer);
begin
  // Not implemented
end;

class procedure TCrossPlatform.CrashDump(ExceptionData: Pointer; const ErrorMsg: string);
begin
  Log(LOG_FATAL) << 'Crash: ' + ErrorMsg;
end;

class function TCrossPlatform.OpenExplorer(const URL: string): Boolean;
begin
  Result := ShellExecute(0, 'open', PChar(URL), '', '', SW_SHOWNORMAL) > 32;
end;

class function TCrossPlatform.GetExeFolder: string;
begin
  Result := ExtractFilePath(ParamStr(0));
end;

end.