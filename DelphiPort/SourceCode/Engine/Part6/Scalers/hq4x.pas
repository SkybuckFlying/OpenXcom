unit hq4x;

{$POINTERMATH ON}
{$WARN UNSAFE_CAST OFF}

interface

uses
  SysUtils, common;

procedure hq4x_32_rb(src: PCardinal; src_rowBytes: Cardinal; dest: PCardinal; dest_rowBytes: Cardinal; width, height: Integer);
procedure hq4x_32(src: PCardinal; dest: PCardinal; width, height: Integer);

implementation

// Same as above, stub.

procedure hq4x_32_rb(src: PCardinal; src_rowBytes: Cardinal; dest: PCardinal; dest_rowBytes: Cardinal; width, height: Integer);
begin
  raise Exception.Create('HQ4x full implementation not included in this bundle. Request full code if needed.');
end;

procedure hq4x_32(src: PCardinal; dest: PCardinal; width, height: Integer);
begin
  hq4x_32_rb(src, width*4, dest, width*16, width, height);
end;

end.