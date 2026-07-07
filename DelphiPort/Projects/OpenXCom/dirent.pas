unit dirent;

{
 * Dirent interface for Microsoft Visual Studio
 * Version 1.21
 *
 * Copyright (C) 2006-2012 Toni Ronkko
 * This file is part of dirent.  Dirent may be freely distributed
 * under the MIT license.  For all details and documentation, see
 * https://github.com/tronkko/dirent
 *
 * Delphi translation by AI
}

interface

uses
  Windows, SysUtils;

{$IFDEF MSWINDOWS}

const
  _DIRENT_HAVE_D_TYPE = 1;
  _DIRENT_HAVE_D_NAMLEN = 1;

  // File type flags for d_type
  DT_UNKNOWN = 0;
  DT_REG     = S_IFREG;
  DT_DIR     = S_IFDIR;
  DT_FIFO    = S_IFIFO;
  DT_SOCK    = S_IFSOCK;
  DT_CHR     = S_IFCHR;
  DT_BLK     = S_IFBLK;
  DT_LNK     = S_IFLNK;

  // Macros for converting between st_mode and d_type
  // IFTODT(mode) = (mode) and S_IFMT
  // DTTOIF(type) = type

type
  // Wide-character version
  _wdirent = record
    d_ino: LongInt;          // Always zero
    d_reclen: Word;          // Structure size
    d_namlen: SIZE_T;        // Length of name without \0
    d_type: Integer;         // File type
    d_name: array[0..PATH_MAX-1] of WideChar; // File name
  end;
  P_wdirent = ^_wdirent;

  _WDIR = record
    ent: _wdirent;           // Current directory entry
    data: WIN32_FIND_DATAW;  // Private file data
    cached: Integer;         // True if data is valid
    handle: THandle;         // Win32 search handle
    patt: PWideChar;         // Initial directory name
  end;
  P_WDIR = ^_WDIR;

  // For compatibility with Symbian
  wdirent = _wdirent;
  WDIR = _WDIR;

  // Multi-byte character versions
  dirent = record
    d_ino: LongInt;
    d_reclen: Word;
    d_namlen: SIZE_T;
    d_type: Integer;
    d_name: array[0..PATH_MAX-1] of AnsiChar;
  end;
  Pdirent = ^dirent;

  DIR = record
    ent: dirent;
    wdirp: P_WDIR;
  end;
  PDIR = ^DIR;

// Function prototypes
function _wopendir(const dirname: PWideChar): P_WDIR;
function _wreaddir(dirp: P_WDIR): P_wdirent;
function _wclosedir(dirp: P_WDIR): Integer;
procedure _wrewinddir(dirp: P_WDIR);

function opendir(const dirname: PAnsiChar): PDIR;
function readdir(dirp: PDIR): Pdirent;
function closedir(dirp: PDIR): Integer;
procedure rewinddir(dirp: PDIR);

// Internal utility functions
function dirent_first(dirp: P_WDIR): PWin32FindDataW;
function dirent_next(dirp: P_WDIR): PWin32FindDataW;
function dirent_mbstowcs_s(var pReturnValue: SIZE_T; wcstr: PWideChar; sizeInWords: SIZE_T; const mbstr: PAnsiChar; count: SIZE_T): Integer;
function dirent_wcstombs_s(var pReturnValue: SIZE_T; mbstr: PAnsiChar; sizeInBytes: SIZE_T; const wcstr: PWideChar; count: SIZE_T): Integer;
procedure dirent_set_errno(error: Integer);

implementation

// Wide-character functions

function _wopendir(const dirname: PWideChar): P_WDIR;
var
  dirp: P_WDIR;
  error: Integer;
  n: DWORD;
  p: PWideChar;
begin
  Result := nil;
  error := 0;

  // Must have directory name
  if (dirname = nil) or (dirname^ = #0) then
  begin
    dirent_set_errno(ENOENT);
    Exit;
  end;

  // Allocate new _WDIR structure
  GetMem(dirp, SizeOf(_WDIR));
  if dirp <> nil then
  begin
    // Reset _WDIR structure
    dirp.handle := INVALID_HANDLE_VALUE;
    dirp.patt := nil;
    dirp.cached := 0;

    // Compute length of full path plus zero terminator
{$IFDEF WINAPI_FAMILY_PHONE_APP}
    n := Length(dirname);
{$ELSE}
    n := GetFullPathNameW(dirname, 0, nil, nil);
{$ENDIF}

    // Allocate room for absolute directory name and search pattern
    GetMem(dirp.patt, (n + 16) * SizeOf(WideChar));
    if dirp.patt <> nil then
    begin
{$IFDEF WINAPI_FAMILY_PHONE_APP}
      StrLCopy(dirp.patt, dirname, n);
{$ELSE}
      n := GetFullPathNameW(dirname, n, dirp.patt, nil);
{$ENDIF}
      if n > 0 then
      begin
        p := dirp.patt + n;
        if dirp.patt < p then
        begin
          case (p-1)^ of
            '\', '/', ':': ; // Directory ends in path separator
          else
            p^ := '\';
            Inc(p);
          end;
        end;
        p^ := '*';
        Inc(p);
        p^ := #0;

        // Open directory stream and retrieve the first entry
        if dirent_first(dirp) <> nil then
          error := 0
        else
        begin
          error := 1;
          dirent_set_errno(ENOENT);
        end;
      end
      else
      begin
        dirent_set_errno(ENOENT);
        error := 1;
      end;
    end
    else
      error := 1;
  end
  else
    error := 1;

  // Clean up in case of error
  if (error <> 0) and (dirp <> nil) then
  begin
    _wclosedir(dirp);
    dirp := nil;
  end;

  Result := dirp;
end;

function _wreaddir(dirp: P_WDIR): P_wdirent;
var
  datap: PWin32FindDataW;
  entp: P_wdirent;
  n: SIZE_T;
  attr: DWORD;
begin
  // Read next directory entry
  datap := dirent_next(dirp);
  if datap <> nil then
  begin
    entp := @dirp.ent;

    // Copy file name as wide-character string
    n := 0;
    while (n + 1 < PATH_MAX) and (datap.cFileName[n] <> #0) do
    begin
      entp.d_name[n] := datap.cFileName[n];
      Inc(n);
    end;
    entp.d_name[n] := #0;

    entp.d_namlen := n;

    // File type
    attr := datap.dwFileAttributes;
    if (attr and FILE_ATTRIBUTE_DEVICE) <> 0 then
      entp.d_type := DT_CHR
    else if (attr and FILE_ATTRIBUTE_DIRECTORY) <> 0 then
      entp.d_type := DT_DIR
    else
      entp.d_type := DT_REG;

    // Reset dummy fields
    entp.d_ino := 0;
    entp.d_reclen := SizeOf(_wdirent);

    Result := entp;
  end
  else
    Result := nil;
end;

function _wclosedir(dirp: P_WDIR): Integer;
begin
  if dirp <> nil then
  begin
    // Release search handle
    if dirp.handle <> INVALID_HANDLE_VALUE then
    begin
      FindClose(dirp.handle);
      dirp.handle := INVALID_HANDLE_VALUE;
    end;

    // Release search pattern
    if dirp.patt <> nil then
    begin
      FreeMem(dirp.patt);
      dirp.patt := nil;
    end;

    // Release directory structure
    FreeMem(dirp);
    Result := 0; // success
  end
  else
  begin
    dirent_set_errno(EBADF);
    Result := -1; // failure
  end;
end;

procedure _wrewinddir(dirp: P_WDIR);
begin
  if dirp <> nil then
  begin
    // Release existing search handle
    if dirp.handle <> INVALID_HANDLE_VALUE then
    begin
      FindClose(dirp.handle);
    end;

    // Open new search handle
    dirent_first(dirp);
  end;
end;

// Internal utility functions

function dirent_first(dirp: P_WDIR): PWin32FindDataW;
begin
  // Open directory and retrieve the first entry
  dirp.handle := FindFirstFileExW(dirp.patt, FindExInfoStandard, @dirp.data,
                                  FindExSearchNameMatch, nil, 0);
  if dirp.handle <> INVALID_HANDLE_VALUE then
  begin
    dirp.cached := 1;
    Result := @dirp.data;
  end
  else
  begin
    dirp.cached := 0;
    Result := nil;
  end;
end;

function dirent_next(dirp: P_WDIR): PWin32FindDataW;
begin
  if dirp.cached <> 0 then
  begin
    Result := @dirp.data;
    dirp.cached := 0;
  end
  else if dirp.handle <> INVALID_HANDLE_VALUE then
  begin
    if FindNextFileW(dirp.handle, @dirp.data) then
      Result := @dirp.data
    else
    begin
      FindClose(dirp.handle);
      dirp.handle := INVALID_HANDLE_VALUE;
      Result := nil;
    end;
  end
  else
    Result := nil;
end;

// Multi-byte character versions

function opendir(const dirname: PAnsiChar): PDIR;
var
  dirp: PDIR;
  error: Integer;
  wname: array[0..PATH_MAX-1] of WideChar;
  n: SIZE_T;
begin
  Result := nil;
  error := 0;

  // Must have directory name
  if (dirname = nil) or (dirname^ = #0) then
  begin
    dirent_set_errno(ENOENT);
    Exit;
  end;

  // Allocate memory for DIR structure
  GetMem(dirp, SizeOf(DIR));
  if dirp <> nil then
  begin
    // Convert directory name to wide-character string
    error := dirent_mbstowcs_s(n, wname, PATH_MAX, dirname, PATH_MAX);
    if error = 0 then
    begin
      // Open directory stream using wide-character name
      dirp.wdirp := _wopendir(wname);
      if dirp.wdirp <> nil then
        error := 0
      else
        error := 1;
    end
    else
      error := 1;
  end
  else
    error := 1;

  // Clean up in case of error
  if (error <> 0) and (dirp <> nil) then
  begin
    FreeMem(dirp);
    dirp := nil;
  end;

  Result := dirp;
end;

function readdir(dirp: PDIR): Pdirent;
var
  datap: PWin32FindDataW;
  entp: Pdirent;
  n: SIZE_T;
  error: Integer;
  attr: DWORD;
begin
  // Read next directory entry
  datap := dirent_next(dirp.wdirp);
  if datap <> nil then
  begin
    // Attempt to convert file name to multi-byte string
    error := dirent_wcstombs_s(n, dirp.ent.d_name, PATH_MAX, datap.cFileName, PATH_MAX);

    // If fails, try alternate file name
    if (error <> 0) and (datap.cAlternateFileName[0] <> #0) then
    begin
      error := dirent_wcstombs_s(n, dirp.ent.d_name, PATH_MAX, datap.cAlternateFileName, PATH_MAX);
    end;

    if error = 0 then
    begin
      entp := @dirp.ent;

      // Length of file name excluding zero terminator
      entp.d_namlen := n - 1;

      // File attributes
      attr := datap.dwFileAttributes;
      if (attr and FILE_ATTRIBUTE_DEVICE) <> 0 then
        entp.d_type := DT_CHR
      else if (attr and FILE_ATTRIBUTE_DIRECTORY) <> 0 then
        entp.d_type := DT_DIR
      else
        entp.d_type := DT_REG;

      // Reset dummy fields
      entp.d_ino := 0;
      entp.d_reclen := SizeOf(dirent);

      Result := entp;
    end
    else
    begin
      // Cannot convert file name, construct error entry
      entp := @dirp.ent;
      entp.d_name[0] := '?';
      entp.d_name[1] := #0;
      entp.d_namlen := 1;
      entp.d_type := DT_UNKNOWN;
      entp.d_ino := 0;
      entp.d_reclen := 0;
      Result := entp;
    end;
  end
  else
    Result := nil;
end;

function closedir(dirp: PDIR): Integer;
begin
  if dirp <> nil then
  begin
    // Close wide-character directory stream
    Result := _wclosedir(dirp.wdirp);
    dirp.wdirp := nil;

    // Release multi-byte character version
    FreeMem(dirp);
  end
  else
  begin
    dirent_set_errno(EBADF);
    Result := -1;
  end;
end;

procedure rewinddir(dirp: PDIR);
begin
  _wrewinddir(dirp.wdirp);
end;

// Convert multi-byte string to wide character string
function dirent_mbstowcs_s(var pReturnValue: SIZE_T; wcstr: PWideChar; sizeInWords: SIZE_T; const mbstr: PAnsiChar; count: SIZE_T): Integer;
var
  n: SIZE_T;
begin
  SetLocale(LC_ALL, '');
{$IF CompilerVersion >= 20} // Delphi 2009+
  Result := mbstowcs_s(pReturnValue, wcstr, sizeInWords, mbstr, count);
{$ELSE}
  n := mbstowcs(wcstr, mbstr, sizeInWords);
  if (wcstr = nil) or (n < count) then
  begin
    if (wcstr <> nil) and (sizeInWords > 0) then
    begin
      if n >= sizeInWords then
        n := sizeInWords - 1;
      wcstr[n] := #0;
    end;
    if @pReturnValue <> nil then
      pReturnValue := n + 1;
    Result := 0;
  end
  else
    Result := 1;
{$IFEND}
  SetLocale(LC_ALL, 'C');
end;

// Convert wide-character string to multi-byte string
function dirent_wcstombs_s(var pReturnValue: SIZE_T; mbstr: PAnsiChar; sizeInBytes: SIZE_T; const wcstr: PWideChar; count: SIZE_T): Integer;
var
  n: SIZE_T;
begin
  SetLocale(LC_ALL, '');
{$IF CompilerVersion >= 20}
  Result := wcstombs_s(pReturnValue, mbstr, sizeInBytes, wcstr, count);
{$ELSE}
  n := wcstombs(mbstr, wcstr, sizeInBytes);
  if (mbstr = nil) or (n < count) then
  begin
    if (mbstr <> nil) and (sizeInBytes > 0) then
    begin
      if n >= sizeInBytes then
        n := sizeInBytes - 1;
      mbstr[n] := #0;
    end;
    if @pReturnValue <> nil then
      pReturnValue := n + 1;
    Result := 0;
  end
  else
    Result := 1;
{$IFEND}
  SetLocale(LC_ALL, 'C');
end;

// Set errno variable
procedure dirent_set_errno(error: Integer);
begin
  SetLastError(error);
  // In Delphi, we can use SetLastError for Win32, but errno is not standard.
  // We'll just set it to the error code.
  // Many functions use GetLastError.
end;

{$ELSE} // not MSWINDOWS
  // Fallback include <sys/types.h> and <dirent.h>
  // This is just a stub
interface
  type
    DIR = record end;
    dirent = record end;
  function opendir(const dirname: PAnsiChar): PDIR; external;
  function readdir(dirp: PDIR): Pdirent; external;
  function closedir(dirp: PDIR): Integer; external;
  procedure rewinddir(dirp: PDIR); external;
implementation
{$ENDIF}

end.