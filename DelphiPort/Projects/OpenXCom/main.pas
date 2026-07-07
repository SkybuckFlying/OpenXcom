program OpenXcom;

{
 * Copyright 2010-2016 OpenXcom Developers.
 *
 * This file is part of OpenXcom.
 *
 * OpenXcom is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * OpenXcom is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with OpenXcom.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Delphi translation of main.cpp (simplified)
}

{$APPTYPE CONSOLE}

uses
  SysUtils,
  version,
  // Assume Engine units are translated separately
  Engine.Logger,
  Engine.CrossPlatform,
  Engine.Game,
  Engine.Options,
  Menu.StartState;

var
  Game: TGame;

{$IFDEF MSWINDOWS}
function CrashLogger(ExceptionInfo: PExceptionPointers): LongInt; stdcall;
begin
  CrossPlatform.CrashDump(ExceptionInfo, '');
  Result := EXCEPTION_CONTINUE_SEARCH;
end;
{$ELSE}
procedure SignalLogger(Sig: Integer);
begin
  CrossPlatform.CrashDump(@Sig, '');
  Halt(1);
end;

procedure ExceptionLogger;
var
  Error: string;
begin
  try
    raise;
  except
    on E: Exception do
      Error := E.Message;
    else
      Error := 'Unknown exception';
  end;
  CrossPlatform.CrashDump(nil, Error);
  Abort;
end;
{$ENDIF}

var
  Title: string;

begin
{$IFDEF MSWINDOWS}
  SetUnhandledExceptionFilter(@CrashLogger);
{$ELSE}
  Signal(SIGSEGV, @SignalLogger);
  SetExceptionHandler(@ExceptionLogger);
{$ENDIF}

  CrossPlatform.GetErrorDialog;

{$IFNDEF NDEBUG}
  Logger.ReportingLevel := LOG_DEBUG;
{$ELSE}
  Logger.ReportingLevel := LOG_INFO;
{$ENDIF}

  if not Options.Init(ParamCount, ParamStr) then
    Halt(0);

  Title := 'OpenXcom ' + OPENXCOM_VERSION_SHORT + OPENXCOM_VERSION_GIT;
  if Options.VerboseLogging then
    Logger.ReportingLevel := LOG_VERBOSE;

  Options.BaseXResolution := Options.DisplayWidth;
  Options.BaseYResolution := Options.DisplayHeight;

  Game := TGame.Create(Title);
  Game.SetState(TStartState.Create);
  Game.Run;

  Game.Free;
end.