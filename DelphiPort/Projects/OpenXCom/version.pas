unit version;

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
 * Delphi translation of version.h
}

interface

const
  OPENXCOM_VERSION_ENGINE = '';
  OPENXCOM_VERSION_SHORT = '1.0';
  OPENXCOM_VERSION_LONG = '1.0.0.0';
  OPENXCOM_VERSION_NUMBER: array[0..3] of Word = (1, 0, 0, 0);

{$IFDEF GIT_BUILD}
  // This would be defined in git_version.h
  // We'll add a placeholder
  {$INCLUDE git_version.inc}
{$ENDIF}

{$IFNDEF OPENXCOM_VERSION_GIT}
  OPENXCOM_VERSION_GIT = ' Dev';
{$ENDIF}

implementation

end.