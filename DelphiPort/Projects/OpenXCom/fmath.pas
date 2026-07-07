unit fmath;

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
 * Delphi translation of fmath.h
}

interface

uses
  Math, SysUtils;

// Float operations
function AreSame(l, r: Single): Boolean; overload;
function AreSame(l, r: Double): Boolean; overload;
function RoundFloat(x: Single): Single; overload; // renamed to avoid conflict with System.Round
function RoundFloat(x: Double): Double; overload;

// Number operations
function Sqr<T>(const x: T): T;
function Sign<T>(const x: T): T;
function Clamp<T>(const x, min, max: T): T;

// Degree operations
function Deg2Rad(deg: Double): Double;
function Rad2Deg(rad: Double): Double;
function Xcom2Rad(deg: Integer): Double;
function Nautical(x: Double): Double;

implementation

// Float operations
function AreSame(l, r: Single): Boolean;
begin
  Result := Abs(l - r) <= FLT_EPSILON * Max(1.0, Max(Abs(l), Abs(r)));
end;

function AreSame(l, r: Double): Boolean;
begin
  Result := Abs(l - r) <= DBL_EPSILON * Max(1.0, Max(Abs(l), Abs(r)));
end;

function RoundFloat(x: Single): Single;
begin
  if x < 0.0 then
    Result := Ceil(x - 0.5)
  else
    Result := Floor(x + 0.5);
end;

function RoundFloat(x: Double): Double;
begin
  if x < 0.0 then
    Result := Ceil(x - 0.5)
  else
    Result := Floor(x + 0.5);
end;

// Number operations
function Sqr<T>(const x: T): T;
begin
  Result := x * x;
end;

function Sign<T>(const x: T): T;
begin
  if x > 0 then Result := 1
  else if x < 0 then Result := -1
  else Result := 0;
end;

function Clamp<T>(const x, min, max: T): T;
begin
  if x < min then Result := min
  else if x > max then Result := max
  else Result := x;
end;

// Degree operations
function Deg2Rad(deg: Double): Double;
begin
  Result := deg * PI / 180.0;
end;

function Rad2Deg(rad: Double): Double;
begin
  Result := rad / PI * 180.0;
end;

function Xcom2Rad(deg: Integer): Double;
begin
  Result := deg * 0.125 * PI / 180.0;
end;

function Nautical(x: Double): Double;
begin
  Result := x * (1 / 60.0) * (PI / 180.0);
end;

end.