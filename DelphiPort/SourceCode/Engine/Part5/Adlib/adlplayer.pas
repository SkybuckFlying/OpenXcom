unit adlplayer;

{$POINTERMATH ON}
{$WARN UNSAFE_CAST OFF}
{$WARN UNSAFE_CODE OFF}

interface

uses
  SysUtils, Math, fmopl;

type
  Pstruc_adlib_channels = ^Tstruc_adlib_channels;
  Pstruc_instruments = ^Tstruc_instruments;
  Pstruc_sample = ^Tstruc_sample;

  Tstruc_adlib_channels = record
    cur_note: Byte;
    cur_instrument: Byte;
    cur_sample: Byte;
    cur_freq: Byte;
    hifreq: Byte;
    cur_volume: Byte;
    duration: Integer;
    pan: Integer;
  end;

  Tstruc_instruments = record
    sample_id: Byte;
    prev_cmd: Byte;
    volume: Byte;
    cur_pitchbend: SmallInt;
    cur_delay: Integer;
    cur_address: PByte;
    start_address: PByte;
    return_address: PByte;
  end;

  Tstruc_sample = record
    reg20_op1: Byte;
    reg20_op2: Byte;
    reg40_op1: Byte;
    reg40_op2: Byte;
    reg60_op1: Byte;
    reg60_op2: Byte;
    reg80_op1: Byte;
    reg80_op2: Byte;
    regE0_op1: Byte;
    regE0_op2: Byte;
    regC0: Byte;
  end;

var
  adl_gv_master_music_volume: Integer = 127;
  adl_gv_tmp_music_volume: Integer = 127;
  adl_gv_want_fade: Boolean = False;
  adl_gv_music_playing: Boolean = False;
  adl_gv_tempo: Integer = 120;
  adl_gv_tempo_run: Integer = 60;
  adl_gv_tempo_inc: Integer = 70;
  adl_gv_samples_addr: PByte = nil;
  adl_gv_subtracks: array[0..127] of PByte;
  adl_gv_instruments_count: Cardinal = 0;
  adl_gv_subtracks_count: Cardinal = 0;
  adl_gv_polyphony_level: Integer = 0;
  adl_gv_chorus_instruments: array[0..15] of Byte;
  adl_gv_FORMAT: Integer = 0;
  iFMReg: array[0..255] of Byte;
  iTweakedFMReg: array[0..255] of Byte;
  iCurrentTweakedBlock: array[0..11] of Byte;
  iCurrentFNum: array[0..11] of Byte;
  saved_instruments: array[0..1, 0..15] of Tstruc_instruments;
  opl: array[0..1] of P_FM_OPL = (nil, nil);

  adlib_channels: array[0..11] of Tstruc_adlib_channels;
  instruments: array[0..15] of Tstruc_instruments;

procedure func_mute;
procedure func_play_tick;
procedure func_setup_music(music_ptr: PByte; length: Integer);
procedure func_fade;
function func_is_music_playing: Boolean;
procedure func_set_music_tempo(value: Integer);
procedure func_set_music_volume(value: Integer);
function func_get_polyphony: Integer;
procedure func_save_music_state(i: Integer);
procedure func_load_music_state(i: Integer);

implementation

const
  adl_gv_freq_table: array[0..107] of Word = (
    $0B5,$0C0,$0CC,$0D8,$0E5,$0F2,$101,$110,$120,$131,$143,$157,
    $16B,$181,$198,$1B0,$1CA,$1E5,$202,$220,$241,$263,$287,$2AE,
    $16B,$181,$198,$1B0,$1CA,$1E5,$202,$220,$241,$263,$287,$2AE,
    $16B,$181,$198,$1B0,$1CA,$1E5,$202,$220,$241,$263,$287,$2AE,
    $16B,$181,$198,$1B0,$1CA,$1E5,$202,$220,$241,$263,$287,$2AE,
    $16B,$181,$198,$1B0,$1CA,$1E5,$202,$220,$241,$263,$287,$2AE,
    $16B,$181,$198,$1B0,$1CA,$1E5,$202,$220,$241,$263,$287,$2AE,
    $16B,$181,$198,$1B0,$1CA,$1E5,$202,$220,$241,$263,$287,$2AE,
    $16B,$181,$198,$1B0,$1CA,$1E5,$202,$220,$241,$263,$287,$2AE
  );
  adl_gv_octave_table: array[0..107] of ShortInt = (
    0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,
    1,1,1,1,1,1,1,1,1,1,1,1,
    2,2,2,2,2,2,2,2,2,2,2,2,
    3,3,3,3,3,3,3,3,3,3,3,3,
    4,4,4,4,4,4,4,4,4,4,4,4,
    5,5,5,5,5,5,5,5,5,5,5,5,
    6,6,6,6,6,6,6,6,6,6,6,6,
    7,7,7,7,7,7,7,7,7,7,7,7
  );
  adl_gv_detune_table: array[0..107] of ShortInt = (
    3,3,3,3,4,4,4,4,4,5,5,5,
    3,3,3,3,4,4,4,4,4,5,5,5,
    3,3,3,3,4,4,4,4,4,5,5,5,
    3,3,3,3,4,4,4,4,4,5,5,5,
    3,3,3,3,4,4,4,4,4,5,5,5,
    3,3,3,3,4,4,4,4,4,5,5,5,
    3,3,3,3,4,4,4,4,4,5,5,5,
    3,3,3,3,4,4,4,4,4,5,5,5,
    3,3,3,3,4,4,4,4,4,5,5,5
  );
  adl_gv_instr_order: array[0..15] of ShortInt = (0,1,2,3,4,5,6,7,8,10,11,12,13,14,15,9);
  adl_gv_operators1: array[0..11] of ShortInt = (0,1,2,8,9,10,16,17,18,24,25,26);
  slot_array: array[0..31] of ShortInt = (
     0, 2, 4, 1, 3, 5,-1,-1,
     6, 8,10, 7, 9,11,-1,-1,
    12,14,16,13,15,17,-1,-1,
    18,20,22,19,21,23,-1,-1
  );

  NEWBLOCK_LIMIT = 32;
  FREQ_OFFSET = 128.0;

procedure Transpose(reg, val: Integer; var val2: Integer; var reg3: Integer; var val3: Integer);
var
  iChannel: Integer;
  iRegister: Integer;
  iValue: Integer;
  iBlock: Byte;
  iFNum: Word;
  dbOriginalFreq, dbNewFNum: Double;
  iNewBlock: Byte;
  iNewFNum: Word;
begin
  iChannel := -1;
  iRegister := reg;
  iValue := val;
  if ((iRegister shr 4 = $A) or (iRegister shr 4 = $B)) then iChannel := iRegister and $0F;
  iFMReg[iRegister] := iValue;
  if (iChannel >= 0) and (iChannel < 12) then
  begin
    iBlock := (iFMReg[$B0 + iChannel] shr 2) and $07;
    iFNum := ((iFMReg[$B0 + iChannel] and $03) shl 8) or iFMReg[$A0 + iChannel];
    dbOriginalFreq := 49716.0 * iFNum / Power(2.0, 20 - iBlock);
    iNewBlock := iBlock;
    dbNewFNum := (dbOriginalFreq + (dbOriginalFreq / FREQ_OFFSET)) / (49716.0 / Power(2.0, 20 - iNewBlock));
    if dbNewFNum > 1023 - NEWBLOCK_LIMIT then
    begin
      if iNewBlock > 6 then
      begin
        iNewBlock := iBlock;
        iNewFNum := iFNum;
      end
      else
      begin
        Inc(iNewBlock);
        iNewFNum := Round(dbNewFNum);
        dbNewFNum := (dbOriginalFreq + (dbOriginalFreq / FREQ_OFFSET)) / (49716.0 / Power(2.0, 20 - iNewBlock));
      end;
    end
    else if dbNewFNum < 0 + NEWBLOCK_LIMIT then
    begin
      if iNewBlock = 0 then
      begin
        iNewBlock := iBlock;
        iNewFNum := iFNum;
      end
      else
      begin
        Dec(iNewBlock);
        dbNewFNum := (dbOriginalFreq + (dbOriginalFreq / FREQ_OFFSET)) / (49716.0 / Power(2.0, 20 - iNewBlock));
        iNewFNum := Round(dbNewFNum);
      end;
    end
    else
      iNewFNum := Round(dbNewFNum);
    if iNewFNum > 1023 then
    begin
      iNewBlock := iBlock;
      iNewFNum := iFNum;
    end;
    if (iRegister >= $B0) and (iRegister <= $BC) then
    begin
      iValue := (iValue and not $1F) or (iNewBlock shl 2) or ((iNewFNum shr 8) and $03);
      iCurrentTweakedBlock[iChannel] := iNewBlock;
      iCurrentFNum[iChannel] := iNewFNum;
      if iTweakedFMReg[$A0 + iChannel] <> (iNewFNum and $FF) then
      begin
        reg3 := $A0 + iChannel;
        val3 := iNewFNum and $FF;
        iTweakedFMReg[reg3] := val3;
      end;
    end
    else if (iRegister >= $A0) and (iRegister <= $AC) then
    begin
      iValue := iNewFNum and $FF;
      val2 := iValue;
      iTweakedFMReg[iRegister] := iValue;
    end;
  end;
  val2 := iValue;
  iTweakedFMReg[iRegister] := iValue;
end;

procedure adlib_reg(i, v: Integer);
var
  v2, i3, v3: Integer;
begin
  if opl[0] = nil then Exit;
  v2 := v; i3 := -1;
  Transpose(i, v, v2, i3, v3);
  OPLWrite(opl[0], 0, i);
  OPLWrite(opl[0], 1, v);
  OPLWrite(opl[1], 0, i);
  if (i >= $20) and (i <= $3f) then v2 := v2 and $3F;
  if (i >= $E0) and (i <= $FC) then
    if (slot_array[i and $1f] and 1) = 1 then
      v2 := v2 and $02;
  OPLWrite(opl[1], 1, v2);
  if i3 <> -1 then
  begin
    OPLWrite(opl[1], 0, i3);
    OPLWrite(opl[1], 1, v3);
  end;
end;

procedure adlib_init;
var
  i: Integer;
begin
  for i := 1 to $f4 do adlib_reg(i, 0);
  adlib_reg($04, $60);
  adlib_reg($04, $80);
  adlib_reg($01, $20);
  adlib_reg($a8, $01);
  adlib_reg($08, $40);
  adlib_reg($bd, $C0);
end;

procedure adlib_set_amplitude(channel, value: Integer);
begin
  adlib_reg($43 + adl_gv_operators1[channel], not (value shr 1) and $3f);
end;

procedure clear_channels;
var
  i: Integer;
begin
  for i := 0 to 11 do
  begin
    adlib_channels[i].cur_sample := $ff;
    adlib_channels[i].cur_note := 0;
  end;
end;

procedure adlib_reset_channels;
var
  i: Integer;
begin
  clear_channels;
  for i := 0 to 11 do
  begin
    adlib_reg($B0 + i, 0);
    adlib_set_amplitude(i, 0);
  end;
end;

function get_pitched_freq_instr(note, instrument: Integer): Integer;
var
  pitch: Integer;
begin
  pitch := instruments[instrument].cur_pitchbend;
  if pitch = 0 then
    Result := adl_gv_freq_table[note]
  else if pitch > 0 then
    Result := adl_gv_freq_table[note] + adl_gv_detune_table[note] * pitch
  else
    Result := adl_gv_freq_table[note] + adl_gv_detune_table[note - 1] * pitch;
end;

procedure adlib_set_instrument_pitch(instrument, pitch: Integer);
var
  i, note, freq, hf: Integer;
begin
  instruments[instrument].cur_pitchbend := pitch;
  for i := 0 to 11 do
  begin
    note := adlib_channels[i].cur_note;
    if (note <> 0) and (adlib_channels[i].cur_instrument = instrument) then
    begin
      freq := get_pitched_freq_instr(note, instrument);
      adlib_channels[i].cur_freq := freq;
      adlib_reg($A0 + i, freq and $ff);
      hf := ((freq shr 8) and $03) or (adl_gv_octave_table[note] shl 2);
      adlib_channels[i].hifreq := hf;
      adlib_reg($B0 + i, hf or $20);
    end;
  end;
end;

function adlib_get_unused_channel(sample_id: Integer; var same_sample: Boolean): Integer;
var
  maxchan, maxdur, i: Integer;
begin
  maxchan := 0; maxdur := 0;
  for i := 0 to 11 do Inc(adlib_channels[i].duration);
  for i := 0 to 11 do
  begin
    if adlib_channels[i].duration > maxdur then
    begin
      maxdur := adlib_channels[i].duration;
      maxchan := i;
    end;
    if adlib_channels[i].cur_note = 0 then
    begin
      maxchan := i;
      Break;
    end;
  end;
  if adlib_channels[maxchan].cur_sample = sample_id then
    same_sample := True
  else
    adlib_channels[maxchan].cur_sample := sample_id;
  adlib_channels[maxchan].duration := 0;
  Result := maxchan;
end;

procedure adlib_play_note(note, volume, instrument: Integer);
var
  cur_sample: Pstruc_sample;
  sample_id: Integer;
  channel, ampl, op1: Integer;
  same_sample: Boolean;
  freq, hf: Integer;
begin
  sample_id := instruments[instrument].sample_id;
  cur_sample := Pstruc_sample(adl_gv_samples_addr + sample_id * 24);
  Dec(note);
  if volume = 0 then
  begin
    for var i := 0 to 11 do
    begin
      if (adlib_channels[i].cur_note = note) and (adlib_channels[i].cur_instrument = instrument) then
      begin
        adlib_channels[i].cur_note := 0;
        adlib_reg($B0 + i, adlib_channels[i].hifreq);
      end;
    end;
    Exit;
  end;
  if volume > 127 then volume := 127;
  same_sample := False;
  channel := adlib_get_unused_channel(sample_id, same_sample);
  adlib_channels[channel].cur_volume := volume;
  adlib_channels[channel].cur_note := note;
  adlib_channels[channel].cur_instrument := instrument;
  op1 := adl_gv_operators1[channel];
  if not same_sample then
  begin
    adlib_reg($20 + op1, cur_sample.reg20_op1);
    adlib_reg($23 + op1, cur_sample.reg20_op2);
    ampl := cur_sample.reg40_op1;
    adlib_reg($40 + op1, ((not ampl) and $3f) or (ampl and $c0));
  end;
  adlib_reg($B0 + channel, adlib_channels[channel].hifreq);
  adlib_reg($43 + op1, (not ((adl_gv_tmp_music_volume * volume) shr 8)) and $3f);
  if not same_sample then
  begin
    adlib_reg($60 + op1, cur_sample.reg60_op1);
    adlib_reg($63 + op1, cur_sample.reg60_op2);
    adlib_reg($80 + op1, cur_sample.reg80_op1);
    adlib_reg($83 + op1, cur_sample.reg80_op2);
    adlib_reg($E0 + op1, cur_sample.regE0_op1);
    adlib_reg($E3 + op1, cur_sample.regE0_op2);
    adlib_reg($C0 + channel, cur_sample.regC0 xor $01);
  end;
  freq := get_pitched_freq_instr(note, instrument);
  adlib_channels[channel].cur_freq := freq;
  adlib_reg($A0 + channel, freq and $ff);
  hf := (freq shr 8) or (adl_gv_octave_table[note] shl 2);
  adlib_channels[channel].hifreq := hf;
  adlib_reg($B0 + channel, hf or $20);
end;

function get_numseq(var mus_ptr: PByte): Integer;
var
  c: Byte;
  v: Integer;
begin
  v := 0;
  repeat
    c := mus_ptr^;
    v := (v shl 7) + (c and $7f);
    Inc(mus_ptr);
  until (c and $80) = 0;
  Result := v;
end;

procedure func_mute;
begin
  adl_gv_polyphony_level := 0;
  adl_gv_music_playing := False;
  adlib_reset_channels;
end;

procedure fade_volume_if_need;
var
  i: Integer;
begin
  if not adl_gv_want_fade then Exit;
  Dec(adl_gv_tmp_music_volume);
  if adl_gv_tmp_music_volume = 0 then
  begin
    func_mute;
    adl_gv_want_fade := False;
    adl_gv_tmp_music_volume := adl_gv_master_music_volume;
    Exit;
  end;
  for i := 0 to 11 do
    adlib_set_amplitude(i, (adlib_channels[i].cur_volume * adl_gv_tmp_music_volume) shr 7);
end;

function free_channel_available: Boolean;
var
  i: Integer;
begin
  for i := 0 to 11 do
    if adlib_channels[i].cur_note = 0 then Exit(True);
  Result := False;
end;

function decode_op(instrument: Integer; var another_loop: Boolean): Integer;
var
  instr1, instr2: Pstruc_instruments;
  music_ptr: PByte;
  opcode, arg1, arg2: Byte;
  delay: Integer;
begin
  instr1 := @instruments[instrument];
  music_ptr := instr1.cur_address;
  delay := 0;
  repeat
    opcode := music_ptr^; Inc(music_ptr);
    if opcode = $FE then
    begin
      arg1 := music_ptr^; Inc(music_ptr);
      instr1.return_address := music_ptr;
      music_ptr := adl_gv_subtracks[arg1];
    end
    else if opcode = $FD then
    begin
      if instr1.return_address = nil then
        // error
      else
      begin
        music_ptr := instr1.return_address;
        instr1.return_address := nil;
      end;
    end
    else if opcode = $FF then
    begin
      adl_gv_music_playing := False;
      delay := 0;
      Break;
    end
    else if opcode >= $80 then
    begin
      instr1.prev_cmd := opcode;
      opcode := music_ptr^; Inc(music_ptr);
    end;
    if opcode < $80 then
    begin
      arg1 := opcode;
      opcode := instr1.prev_cmd;
      case opcode and $F0 of
        $80: // note off
          begin
            arg2 := music_ptr^; Inc(music_ptr);
            adlib_play_note(arg1, 0, instrument);
            Dec(adl_gv_polyphony_level);
            if adl_gv_chorus_instruments[instrument] <> 0 then
            begin
              adlib_play_note(arg1, 0, adl_gv_chorus_instruments[instrument]);
              Dec(adl_gv_polyphony_level);
            end;
          end;
        $90: // note on
          begin
            arg2 := music_ptr^; Inc(music_ptr);
            if arg2 = 0 then
            begin
              adlib_play_note(arg1, 0, instrument);
              Dec(adl_gv_polyphony_level);
              if adl_gv_chorus_instruments[instrument] <> 0 then
              begin
                adlib_play_note(arg1, 0, adl_gv_chorus_instruments[instrument]);
                Dec(adl_gv_polyphony_level);
              end;
            end
            else
            begin
              var vol := (arg2 * instr1.volume) shr 7;
              if adl_gv_chorus_instruments[instrument] <> 0 then
              begin
                if free_channel_available then
                begin
                  instr2 := @instruments[adl_gv_chorus_instruments[instrument]];
                  instr2.sample_id := instr1.sample_id;
                  instr2.cur_pitchbend := instr1.cur_pitchbend - 1;
                  adlib_play_note(arg1, vol, adl_gv_chorus_instruments[instrument]);
                end;
                Inc(adl_gv_polyphony_level);
              end;
              adlib_play_note(arg1, vol, instrument);
              Inc(adl_gv_polyphony_level);
            end;
          end;
        $B0: // controller
          begin
            arg2 := music_ptr^; Inc(music_ptr);
            if (arg1 = 0) and (arg2 <> 0) then
              adl_gv_tempo := Round(arg2 * 0.8)
            else if arg1 = 7 then
              instr1.volume := arg2
            else if arg1 = $7E then
              adl_gv_chorus_instruments[instrument] := arg2 - 1
            else if arg1 = $7F then
              adl_gv_chorus_instruments[instrument] := 0;
          end;
        $C0: // set sample
          begin
            if arg1 = $7E then
              another_loop := True
            else
              instr1.sample_id := arg1;
          end;
        $E0: // pitch bend
          begin
            instr1.cur_pitchbend := arg1 - 16;
            adlib_set_instrument_pitch(instrument, arg1 - 16);
            if adl_gv_chorus_instruments[instrument] <> 0 then
              adlib_set_instrument_pitch(adl_gv_chorus_instruments[instrument], arg1 - 17);
          end;
      end;
    end;
    delay := get_numseq(music_ptr);
  until delay <> 0;
  instr1.cur_address := music_ptr;
  Result := delay;
end;

procedure init_music_data(music_ptr: PByte; length: Integer);
var
  i, to_add, j: Cardinal;
  start: PByte;
begin
  start := music_ptr;
  for i := 0 to 15 do instruments[i].start_address := nil;
  adl_gv_subtracks_count := 0;
  i := music_ptr^;
  if i > 56 then adl_gv_FORMAT := 0 else adl_gv_FORMAT := 1;
  if adl_gv_FORMAT = 1 then music_ptr := music_ptr + (music_ptr^) + 1;
  adl_gv_tempo := music_ptr^; Inc(music_ptr);
  adl_gv_samples_addr := music_ptr + 1;
  music_ptr := music_ptr + (music_ptr^) * 24 + 1;
  adl_gv_subtracks_count := music_ptr^; Inc(music_ptr);
  for i := 0 to adl_gv_subtracks_count - 1 do
  begin
    to_add := PUInt16(music_ptr)^; // 16bit length
    adl_gv_subtracks[i] := music_ptr + 4;
    music_ptr := music_ptr + to_add;
  end;
  adl_gv_instruments_count := music_ptr^; Inc(music_ptr);
  for i := 0 to adl_gv_instruments_count - 1 do
  begin
    to_add := PUInt16(music_ptr)^;
    if adl_gv_FORMAT = 1 then
    begin
      j := (music_ptr + 4)^;
      if j > 15 then j := 15;
      instruments[j].start_address := music_ptr + 5;
    end
    else
    begin
      j := i;
      instruments[j].start_address := music_ptr + 4;
    end;
    music_ptr := music_ptr + to_add;
    if (music_ptr - start) >= length then Break;
  end;
end;

procedure init_music;
var
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    instruments[i].cur_pitchbend := 0;
    adl_gv_chorus_instruments[i] := 0;
    if instruments[i].start_address <> nil then
    begin
      instruments[i].cur_address := instruments[i].start_address;
      instruments[i].cur_delay := get_numseq(instruments[i].cur_address);
    end
    else
    begin
      instruments[i].cur_address := nil;
      instruments[i].cur_delay := 0;
    end;
  end;
end;

procedure func_save_music_state(i: Integer);
begin
  saved_instruments[i] := instruments;
end;

procedure func_load_music_state(i: Integer);
begin
  adlib_reset_channels;
  instruments := saved_instruments[i];
end;

procedure func_play_tick;
var
  another_loop: Boolean;
  i, instr: Integer;
begin
  if not adl_gv_music_playing then Exit;
  fade_volume_if_need;
  adl_gv_tempo_run := adl_gv_tempo_run - adl_gv_tempo;
  if adl_gv_tempo_run > 0 then Exit;
  adl_gv_tempo_run := adl_gv_tempo_run + adl_gv_tempo_inc;
  repeat
    another_loop := False;
    for i := 0 to 15 do
    begin
      instr := adl_gv_instr_order[i];
      if instruments[instr].cur_address = nil then Continue;
      if instruments[instr].cur_delay = 0 then
      begin
        instruments[instr].cur_delay := decode_op(instr, another_loop);
        if not adl_gv_music_playing then Break;
      end;
      Dec(instruments[instr].cur_delay);
    end;
    if not another_loop and adl_gv_music_playing then Break;
    init_music;
    clear_channels;
  until another_loop;
end;

procedure func_setup_music(music_ptr: PByte; length: Integer);
begin
  adl_gv_music_playing := False;
  func_mute;
  adl_gv_polyphony_level := 0;
  adl_gv_want_fade := False;
  adl_gv_tmp_music_volume := adl_gv_master_music_volume;
  init_music_data(music_ptr, length);
  init_music;
  adlib_init;
  adlib_reset_channels;
  adl_gv_tempo := Round(adl_gv_tempo * 0.4);
  adl_gv_tempo_run := adl_gv_tempo;
  adl_gv_music_playing := True;
end;

procedure func_fade;
begin
  if adl_gv_tmp_music_volume = 0 then
    func_mute
  else
    adl_gv_want_fade := True;
end;

function func_is_music_playing: Boolean;
begin
  Result := adl_gv_music_playing;
end;

procedure func_set_music_tempo(value: Integer);
begin
  adl_gv_tempo_inc := value;
end;

procedure func_set_music_volume(value: Integer);
var
  i: Integer;
begin
  adl_gv_master_music_volume := value;
  adl_gv_tmp_music_volume := adl_gv_master_music_volume;
  for i := 0 to 11 do
    adlib_set_amplitude(i, (adlib_channels[i].cur_volume * adl_gv_tmp_music_volume) shr 7);
end;

function func_get_polyphony: Integer;
begin
  Result := adl_gv_polyphony_level;
end;

end.