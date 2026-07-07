unit fmopl;

{$POINTERMATH ON}
{$WARN UNSAFE_CAST OFF}
{$WARN UNSAFE_CODE OFF}

interface

uses
  SysUtils, Math;

type
  // forward declarations
  P_OPL_SLOT = ^T_OPL_SLOT;
  P_OPL_CH   = ^T_OPL_CH;
  P_FM_OPL   = ^T_FM_OPL;

  // ---------- OPL one of slot ----------
  T_OPL_SLOT = record
    TL: Integer;        // total level :TL << 8
    TLL: Integer;       // adjusted now TL
    KSR: Byte;          // key scale rate :(shift down bit)
    AR: ^Integer;       // attack rate :&AR_TABLE[AR<<2]
    DR: ^Integer;       // decay rate  :&DR_TALBE[DR<<2]
    SL: Integer;        // sustin level :SL_TALBE[SL]
    RR: ^Integer;       // release rate :&DR_TABLE[RR<<2]
    ksl: Byte;          // keyscale level :(shift down bits)
    ksr: Byte;          // key scale rate :kcode>>KSR
    mul: Cardinal;      // multiple :ML_TABLE[ML]
    Cnt: Cardinal;      // frequency count
    Incr: Cardinal;     // frequency step
    // envelope generator state
    eg_typ: Byte;       // envelope type flag
    evm: Byte;          // envelope phase
    evc: Integer;       // envelope counter
    eve: Integer;       // envelope counter end point
    evs: Integer;       // envelope counter step
    evsa: Integer;      // envelope step for AR :AR[ksr]
    evsd: Integer;      // envelope step for DR :DR[ksr]
    evsr: Integer;      // envelope step for RR :RR[ksr]
    // LFO
    ams: Byte;          // ams flag
    vib: Byte;          // vibrate flag
    // wave selector
    wavetable: array[0..3] of ^Integer;
  end;

  // ---------- OPL one of channel ----------
  T_OPL_CH = record
    SLOT: array[0..1] of T_OPL_SLOT;
    CON: Byte;           // connection type
    FB: Byte;            // feed back :(shift down bit)
    connect1: ^Integer;  // slot1 output pointer
    connect2: ^Integer;  // slot2 output pointer
    op1_out: array[0..1] of Integer; // slot1 output for selfeedback
    // phase generator state
    block_fnum: Cardinal; // block+fnum
    kcode: Byte;          // key code : KeyScaleCode
    fc: Cardinal;         // Freq. Increment base
    ksl_base: Cardinal;   // KeyScaleLevel Base step
    keyon: Byte;          // key on/off flag
  end;

  // OPL state
  T_FM_OPL = record
    typ: Byte;            // chip type
    clock: Integer;       // master clock  (Hz)
    rate: Integer;        // sampling rate (Hz)
    freqbase: Double;     // frequency base
    TimerBase: Double;    // Timer base time (==sampling time)
    address: Byte;        // address register
    status: Byte;         // status flag
    statusmask: Byte;     // status mask
    mode: Cardinal;       // Reg.08 : CSM , notesel,etc.
    // Timer
    T: array[0..1] of Integer; // timer counter
    st: array[0..1] of Byte;   // timer enable
    // FM channel slots
    P_CH: ^T_OPL_CH;      // pointer of CH
    max_ch: Integer;      // maximum channel
    // Rythm section
    rythm: Byte;          // Rythm mode , key flag
    // time tables
    AR_TABLE: array[0..74] of Integer; // attack rate tables
    DR_TABLE: array[0..74] of Integer; // decay rate tables
    FN_TABLE: array[0..1023] of Cardinal; // fnumber -> increment counter
    // LFO
    ams_table: ^Integer;
    vib_table: ^Integer;
    amsCnt: Integer;
    amsIncr: Integer;
    vibCnt: Integer;
    vibIncr: Integer;
    // wave selector enable flag
    wavesel: Byte;
    // external event callback handler (stubs, we use procedure variables)
    TimerHandler: procedure(channel: Integer; interval_Sec: Double);
    TimerParam: Integer;
    IRQHandler: procedure(param: Integer; irq: Integer);
    IRQParam: Integer;
    UpdateHandler: procedure(param: Integer; min_interval_us: Integer);
    UpdateParam: Integer;
  end;

const
  OPL_TYPE_WAVESEL   = $01;
  OPL_TYPE_ADPCM     = $02;
  OPL_TYPE_KEYBOARD  = $04;
  OPL_TYPE_IO        = $08;

// External interface
function OPLCreate(typ: Integer; clock: Integer; rate: Integer): P_FM_OPL;
procedure OPLDestroy(OPL: P_FM_OPL);
procedure OPLResetChip(OPL: P_FM_OPL);
function OPLWrite(OPL: P_FM_OPL; a: Integer; v: Integer): Integer;
function OPLRead(OPL: P_FM_OPL; a: Integer): Byte;
function OPLTimerOver(OPL: P_FM_OPL; c: Integer): Integer;
procedure YM3812UpdateOne(OPL: P_FM_OPL; buffer: PSmallInt; length: Integer; stripe: Integer; volume: Single);

implementation

const
  OPL_ARRATE = 141280;
  OPL_DRRATE = 1956000;
  FREQ_BITS  = 24;
  FREQ_RATE  = (1 shl (FREQ_BITS - 20));
  TL_BITS    = (FREQ_BITS + 2);
  OPL_OUTSB  = (TL_BITS + 1 - 16);
  OPL_MAXOUT = $7fff shl OPL_OUTSB;
  OPL_MINOUT = -($8000 shl OPL_OUTSB);
  SIN_ENT    = 2048;
  ENV_BITS   = 16;
  EG_ENT     = 4096;
  EG_OFF     = ((2 * EG_ENT) shl ENV_BITS);
  EG_DED     = EG_OFF;
  EG_DST     = (EG_ENT shl ENV_BITS);
  EG_AED     = EG_DST;
  EG_AST     = 0;
  EG_STEP    = (96.0 / EG_ENT);
  VIB_ENT    = 512;
  VIB_SHIFT  = (32 - 9);
  AMS_ENT    = 512;
  AMS_SHIFT  = (32 - 9);
  VIB_RATE   = 256;
  ENV_MOD_RR = $00;
  ENV_MOD_DR = $01;
  ENV_MOD_AR = $02;

var
  // global tables (initialized once)
  TL_TABLE: array[0..2*EG_ENT-1] of Integer; // actually TL_MAX*2
  SIN_TABLE: array[0..SIN_ENT*4-1] of ^Integer;
  AMS_TABLE: array[0..AMS_ENT*2-1] of Integer;
  VIB_TABLE: array[0..VIB_ENT*2-1] of Integer;
  ENV_CURVE: array[0..2*EG_ENT] of Integer;
  MUL_TABLE: array[0..15] of Cardinal = (1,2,4,6,8,10,12,14,16,18,20,20,24,24,30,30); // ML=2 scaled
  SL_TABLE: array[0..15] of Integer;
  RATE_0: array[0..15] of Integer = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
  slot_array: array[0..31] of ShortInt = (
     0, 2, 4, 1, 3, 5,-1,-1,
     6, 8,10, 7, 9,11,-1,-1,
    12,14,16,13,15,17,-1,-1,
    18,20,22,19,21,23,-1,-1
  );
  KSL_TABLE: array[0..7*16-1] of Integer;
  num_lock: Integer = 0;
  cur_chip: Pointer = nil;
  S_CH, E_CH: ^T_OPL_CH;
  SLOT7_1, SLOT7_2, SLOT8_1, SLOT8_2: ^T_OPL_SLOT;
  outd: array[0..0] of Integer;
  ams, vib: Integer;
  ams_table, vib_table: ^Integer;
  amsIncr, vibIncr: Integer;
  feedback2: Integer;

// helper
function Limit(val, max, min: Integer): Integer; inline;
begin
  if val > max then Result := max
  else if val < min then Result := min
  else Result := val;
end;

procedure OPL_STATUS_SET(OPL: P_FM_OPL; flag: Integer); inline;
begin
  OPL.status := OPL.status or flag;
  if (OPL.status and $80) = 0 then
  begin
    if (OPL.status and OPL.statusmask) <> 0 then
    begin
      OPL.status := OPL.status or $80;
      if Assigned(OPL.IRQHandler) then
        OPL.IRQHandler(OPL.IRQParam, 1);
    end;
  end;
end;

procedure OPL_STATUS_RESET(OPL: P_FM_OPL; flag: Integer); inline;
begin
  OPL.status := OPL.status and (not flag);
  if (OPL.status and $80) <> 0 then
  begin
    if (OPL.status and OPL.statusmask) = 0 then
    begin
      OPL.status := OPL.status and $7f;
      if Assigned(OPL.IRQHandler) then
        OPL.IRQHandler(OPL.IRQParam, 0);
    end;
  end;
end;

procedure OPL_STATUSMASK_SET(OPL: P_FM_OPL; flag: Integer); inline;
begin
  OPL.statusmask := flag;
  OPL_STATUS_SET(OPL, 0);
  OPL_STATUS_RESET(OPL, 0);
end;

procedure OPL_KEYON(SLOT: P_OPL_SLOT); inline;
begin
  SLOT.Cnt := 0;
  SLOT.evm := ENV_MOD_AR;
  SLOT.evs := SLOT.evsa;
  SLOT.evc := EG_AST;
  SLOT.eve := EG_AED;
end;

procedure OPL_KEYOFF(SLOT: P_OPL_SLOT); inline;
begin
  if SLOT.evm > ENV_MOD_RR then
  begin
    SLOT.evm := ENV_MOD_RR;
    if (SLOT.evc and EG_DST) = 0 then
      SLOT.evc := (ENV_CURVE[SLOT.evc shr ENV_BITS] shl ENV_BITS) + EG_DST;
    SLOT.eve := EG_DED;
    SLOT.evs := SLOT.evsr;
  end;
end;

function OPL_CALC_SLOT(SLOT: P_OPL_SLOT): Cardinal; inline;
begin
  SLOT.evc := SLOT.evc + SLOT.evs;
  if SLOT.evc >= SLOT.eve then
  begin
    case SLOT.evm of
      ENV_MOD_AR:
        begin
          SLOT.evm := ENV_MOD_DR;
          SLOT.evc := EG_DST;
          SLOT.eve := SLOT.SL;
          SLOT.evs := SLOT.evsd;
        end;
      ENV_MOD_DR:
        begin
          SLOT.evc := SLOT.SL;
          SLOT.eve := EG_DED;
          if SLOT.eg_typ <> 0 then
            SLOT.evs := 0
          else
          begin
            SLOT.evm := ENV_MOD_RR;
            SLOT.evs := SLOT.evsr;
          end;
        end;
      ENV_MOD_RR:
        begin
          SLOT.evc := EG_OFF;
          SLOT.eve := EG_OFF + 1;
          SLOT.evs := 0;
        end;
    end;
  end;
  Result := SLOT.TLL + ENV_CURVE[SLOT.evc shr ENV_BITS] + (SLOT.ams * ams);
end;

procedure set_algorythm(CH: P_OPL_CH);
var
  carrier: ^Integer;
begin
  carrier := @outd[0];
  if CH.CON <> 0 then
    CH.connect1 := carrier
  else
    CH.connect1 := @feedback2;
  CH.connect2 := carrier;
end;

procedure CALC_FCSLOT(CH: P_OPL_CH; SLOT: P_OPL_SLOT); inline;
var
  ksr: Integer;
begin
  SLOT.Incr := CH.fc * SLOT.mul;
  ksr := CH.kcode shr SLOT.KSR;
  if SLOT.ksr <> ksr then
  begin
    SLOT.ksr := ksr;
    SLOT.evsa := SLOT.AR[ksr];
    SLOT.evsd := SLOT.DR[ksr];
    SLOT.evsr := SLOT.RR[ksr];
  end;
  SLOT.TLL := SLOT.TL + (CH.ksl_base shr SLOT.ksl);
end;

procedure set_mul(OPL: P_FM_OPL; slot: Integer; v: Integer); inline;
var
  CH: P_OPL_CH;
  SLOT: P_OPL_SLOT;
begin
  CH := @OPL.P_CH[slot shr 1];
  SLOT := @CH.SLOT[slot and 1];
  SLOT.mul := MUL_TABLE[v and $0f];
  if (v and $10) <> 0 then SLOT.KSR := 0 else SLOT.KSR := 2;
  SLOT.eg_typ := (v and $20) shr 5;
  SLOT.vib := (v and $40);
  SLOT.ams := (v and $80);
  CALC_FCSLOT(CH, SLOT);
end;

procedure set_ksl_tl(OPL: P_FM_OPL; slot: Integer; v: Integer); inline;
var
  CH: P_OPL_CH;
  SLOT: P_OPL_SLOT;
  ksl: Integer;
begin
  CH := @OPL.P_CH[slot shr 1];
  SLOT := @CH.SLOT[slot and 1];
  ksl := v shr 6;
  if ksl <> 0 then SLOT.ksl := 3 - ksl else SLOT.ksl := 31;
  SLOT.TL := Round((v and $3f) * (0.75 / EG_STEP));
  if (OPL.mode and $80) = 0 then
    SLOT.TLL := SLOT.TL + (CH.ksl_base shr SLOT.ksl);
end;

procedure set_ar_dr(OPL: P_FM_OPL; slot: Integer; v: Integer); inline;
var
  CH: P_OPL_CH;
  SLOT: P_OPL_SLOT;
  ar, dr: Integer;
begin
  CH := @OPL.P_CH[slot shr 1];
  SLOT := @CH.SLOT[slot and 1];
  ar := v shr 4;
  dr := v and $0f;
  if ar <> 0 then SLOT.AR := @OPL.AR_TABLE[ar shl 2] else SLOT.AR := @RATE_0[0];
  SLOT.evsa := SLOT.AR[SLOT.ksr];
  if SLOT.evm = ENV_MOD_AR then SLOT.evs := SLOT.evsa;
  if dr <> 0 then SLOT.DR := @OPL.DR_TABLE[dr shl 2] else SLOT.DR := @RATE_0[0];
  SLOT.evsd := SLOT.DR[SLOT.ksr];
  if SLOT.evm = ENV_MOD_DR then SLOT.evs := SLOT.evsd;
end;

procedure set_sl_rr(OPL: P_FM_OPL; slot: Integer; v: Integer); inline;
var
  CH: P_OPL_CH;
  SLOT: P_OPL_SLOT;
  sl, rr: Integer;
begin
  CH := @OPL.P_CH[slot shr 1];
  SLOT := @CH.SLOT[slot and 1];
  sl := v shr 4;
  rr := v and $0f;
  SLOT.SL := SL_TABLE[sl];
  if SLOT.evm = ENV_MOD_DR then SLOT.eve := SLOT.SL;
  SLOT.RR := @OPL.DR_TABLE[rr shl 2];
  SLOT.evsr := SLOT.RR[SLOT.ksr];
  if SLOT.evm = ENV_MOD_RR then SLOT.evs := SLOT.evsr;
end;

function OP_OUT(SLOT: P_OPL_SLOT; env, con: Integer): Integer; inline;
begin
  Result := SLOT.wavetable[((SLOT.Cnt + con) div (1 shl (24 - 11))) and (SIN_ENT - 1)][env];
end;

procedure OPL_CALC_CH(CH: P_OPL_CH);
var
  env_out: Integer;
  SLOT: P_OPL_SLOT;
  feedback1: Integer;
begin
  feedback2 := 0;
  SLOT := @CH.SLOT[0];
  env_out := OPL_CALC_SLOT(SLOT);
  if env_out < EG_ENT - 1 then
  begin
    if SLOT.vib <> 0 then SLOT.Cnt := SLOT.Cnt + (SLOT.Incr * vib div VIB_RATE)
    else SLOT.Cnt := SLOT.Cnt + SLOT.Incr;
    if CH.FB <> 0 then
    begin
      feedback1 := (CH.op1_out[0] + CH.op1_out[1]) shr CH.FB;
      CH.op1_out[1] := CH.op1_out[0];
      CH.op1_out[0] := OP_OUT(SLOT, env_out, feedback1);
      CH.connect1^ := CH.connect1^ + CH.op1_out[0];
    end
    else
    begin
      CH.connect1^ := CH.connect1^ + OP_OUT(SLOT, env_out, 0);
    end;
  end
  else
  begin
    CH.op1_out[1] := CH.op1_out[0];
    CH.op1_out[0] := 0;
  end;
  SLOT := @CH.SLOT[1];
  env_out := OPL_CALC_SLOT(SLOT);
  if env_out < EG_ENT - 1 then
  begin
    if SLOT.vib <> 0 then SLOT.Cnt := SLOT.Cnt + (SLOT.Incr * vib div VIB_RATE)
    else SLOT.Cnt := SLOT.Cnt + SLOT.Incr;
    outd[0] := outd[0] + OP_OUT(SLOT, env_out, feedback2);
  end;
end;

procedure OPL_CALC_RH(CH: P_OPL_CH);
var
  env_tam, env_sd, env_top, env_hh: Integer;
  whitenoise: Integer;
  tone8: Integer;
  SLOT: P_OPL_SLOT;
  env_out: Integer;
  feedback1: Integer;
begin
  whitenoise := (Random(2)) * Round(6.0 / EG_STEP);
  feedback2 := 0;
  SLOT := @CH[6].SLOT[0];
  env_out := OPL_CALC_SLOT(SLOT);
  if env_out < EG_ENT - 1 then
  begin
    if SLOT.vib <> 0 then SLOT.Cnt := SLOT.Cnt + (SLOT.Incr * vib div VIB_RATE)
    else SLOT.Cnt := SLOT.Cnt + SLOT.Incr;
    if CH[6].FB <> 0 then
    begin
      feedback1 := (CH[6].op1_out[0] + CH[6].op1_out[1]) shr CH[6].FB;
      CH[6].op1_out[1] := CH[6].op1_out[0];
      feedback2 := OP_OUT(SLOT, env_out, feedback1);
      CH[6].op1_out[0] := feedback2;
    end
    else
      feedback2 := OP_OUT(SLOT, env_out, 0);
  end
  else
  begin
    feedback2 := 0;
    CH[6].op1_out[1] := CH[6].op1_out[0];
    CH[6].op1_out[0] := 0;
  end;
  SLOT := @CH[6].SLOT[1];
  env_out := OPL_CALC_SLOT(SLOT);
  if env_out < EG_ENT - 1 then
  begin
    if SLOT.vib <> 0 then SLOT.Cnt := SLOT.Cnt + (SLOT.Incr * vib div VIB_RATE)
    else SLOT.Cnt := SLOT.Cnt + SLOT.Incr;
    outd[0] := outd[0] + OP_OUT(SLOT, env_out, feedback2) * 2;
  end;

  env_sd := OPL_CALC_SLOT(SLOT7_2) + whitenoise;
  env_tam := OPL_CALC_SLOT(SLOT8_1);
  env_top := OPL_CALC_SLOT(SLOT8_2);
  env_hh := OPL_CALC_SLOT(SLOT7_1) + whitenoise;

  if SLOT7_1.vib <> 0 then SLOT7_1.Cnt := SLOT7_1.Cnt + (2 * SLOT7_1.Incr * vib div VIB_RATE)
  else SLOT7_1.Cnt := SLOT7_1.Cnt + 2 * SLOT7_1.Incr;
  if SLOT7_2.vib <> 0 then SLOT7_2.Cnt := SLOT7_2.Cnt + ((CH[7].fc * 8) * vib div VIB_RATE)
  else SLOT7_2.Cnt := SLOT7_2.Cnt + (CH[7].fc * 8);
  if SLOT8_1.vib <> 0 then SLOT8_1.Cnt := SLOT8_1.Cnt + (SLOT8_1.Incr * vib div VIB_RATE)
  else SLOT8_1.Cnt := SLOT8_1.Cnt + SLOT8_1.Incr;
  if SLOT8_2.vib <> 0 then SLOT8_2.Cnt := SLOT8_2.Cnt + ((CH[8].fc * 48) * vib div VIB_RATE)
  else SLOT8_2.Cnt := SLOT8_2.Cnt + (CH[8].fc * 48);

  tone8 := OP_OUT(SLOT8_2, whitenoise, 0);

  if env_sd < EG_ENT - 1 then outd[0] := outd[0] + OP_OUT(SLOT7_1, env_sd, 0) * 8;
  if env_tam < EG_ENT - 1 then outd[0] := outd[0] + OP_OUT(SLOT8_1, env_tam, 0) * 2;
  if env_top < EG_ENT - 1 then outd[0] := outd[0] + OP_OUT(SLOT7_2, env_top, tone8) * 2;
  if env_hh < EG_ENT - 1 then outd[0] := outd[0] + OP_OUT(SLOT7_2, env_hh, tone8) * 2;
end;

procedure init_timetables(OPL: P_FM_OPL; ARRATE, DRRATE: Integer);
var
  i: Integer;
  rate: Double;
begin
  for i := 0 to 3 do
  begin
    OPL.AR_TABLE[i] := 0;
    OPL.DR_TABLE[i] := 0;
  end;
  for i := 4 to 60 do
  begin
    rate := OPL.freqbase;
    if i < 60 then rate := rate * (1.0 + (i and 3) * 0.25);
    rate := rate * (1 shl ((i shr 2) - 1));
    rate := rate * (EG_ENT shl ENV_BITS);
    OPL.AR_TABLE[i] := Round(rate / ARRATE);
    OPL.DR_TABLE[i] := Round(rate / DRRATE);
  end;
  for i := 60 to 74 do
  begin
    OPL.AR_TABLE[i] := EG_AED - 1;
    OPL.DR_TABLE[i] := OPL.DR_TABLE[60];
  end;
end;

function OPLOpenTable: Integer;
var
  s, t, i, j: Integer;
  rate, pom: Double;
begin
  FillChar(TL_TABLE, SizeOf(TL_TABLE), 0);
  FillChar(SIN_TABLE, SizeOf(SIN_TABLE), 0);
  FillChar(AMS_TABLE, SizeOf(AMS_TABLE), 0);
  FillChar(VIB_TABLE, SizeOf(VIB_TABLE), 0);
  // Total level table
  for t := 0 to EG_ENT - 2 do
  begin
    rate := (1 shl TL_BITS) - 1;
    rate := rate / Power(10, EG_STEP * t / 20);
    TL_TABLE[t] := Round(rate);
    TL_TABLE[EG_ENT + t] := -TL_TABLE[t];
  end;
  for t := EG_ENT - 1 to 2 * EG_ENT - 1 do
    TL_TABLE[t] := 0;
  // Sin wave table
  SIN_TABLE[0] := @TL_TABLE[EG_ENT - 1];
  SIN_TABLE[SIN_ENT div 2] := @TL_TABLE[EG_ENT - 1];
  for s := 1 to SIN_ENT div 4 do
  begin
    pom := Sin(2 * Pi * s / SIN_ENT);
    pom := 20 * Log10(1 / pom);
    j := Round(pom / EG_STEP);
    SIN_TABLE[s] := @TL_TABLE[j];
    SIN_TABLE[SIN_ENT div 2 - s] := @TL_TABLE[j];
    SIN_TABLE[SIN_ENT div 2 + s] := @TL_TABLE[EG_ENT + j];
    SIN_TABLE[SIN_ENT - s] := @TL_TABLE[EG_ENT + j];
  end;
  for s := 0 to SIN_ENT - 1 do
  begin
    if s < (SIN_ENT div 2) then SIN_TABLE[SIN_ENT + s] := SIN_TABLE[s]
    else SIN_TABLE[SIN_ENT + s] := @TL_TABLE[EG_ENT];
    SIN_TABLE[2 * SIN_ENT + s] := SIN_TABLE[s mod (SIN_ENT div 2)];
    if (s div (SIN_ENT div 4) and 1) <> 0 then
      SIN_TABLE[3 * SIN_ENT + s] := @TL_TABLE[EG_ENT]
    else
      SIN_TABLE[3 * SIN_ENT + s] := SIN_TABLE[2 * SIN_ENT + s];
  end;
  // Envelope curve
  for i := 0 to EG_ENT - 1 do
  begin
    pom := Power((EG_ENT - 1 - i) / EG_ENT, 8) * EG_ENT;
    ENV_CURVE[i] := Round(pom);
    ENV_CURVE[(EG_DST shr ENV_BITS) + i] := i;
  end;
  ENV_CURVE[EG_OFF shr ENV_BITS] := EG_ENT - 1;
  // LFO AMS table
  for i := 0 to AMS_ENT - 1 do
  begin
    pom := (1.0 + Sin(2 * Pi * i / AMS_ENT)) / 2;
    AMS_TABLE[i] := Round((1.0 / EG_STEP) * pom);
    AMS_TABLE[AMS_ENT + i] := Round((4.8 / EG_STEP) * pom);
  end;
  // LFO VIB table
  for i := 0 to VIB_ENT - 1 do
  begin
    pom := VIB_RATE * 0.06 * Sin(2 * Pi * i / VIB_ENT);
    VIB_TABLE[i] := Round(VIB_RATE + (pom * 0.07));
    VIB_TABLE[VIB_ENT + i] := Round(VIB_RATE + (pom * 0.14));
  end;
  Result := 1;
end;

procedure OPLCloseTable;
begin
  // nothing to free, static arrays
end;

procedure OPL_initalize(OPL: P_FM_OPL);
var
  fn: Integer;
begin
  if OPL.rate <> 0 then
    OPL.freqbase := OPL.clock / OPL.rate / 72
  else
    OPL.freqbase := 0;
  OPL.TimerBase := 1.0 / (OPL.clock / 72.0);
  init_timetables(OPL, OPL_ARRATE, OPL_DRRATE);
  for fn := 0 to 1023 do
    OPL.FN_TABLE[fn] := Round(OPL.freqbase * fn * FREQ_RATE * (1 shl 7) / 2);
  if OPL.rate <> 0 then
    OPL.amsIncr := Round(AMS_ENT * (1 shl AMS_SHIFT) / OPL.rate * 3.7 * (OPL.clock / 3600000))
  else
    OPL.amsIncr := 0;
  if OPL.rate <> 0 then
    OPL.vibIncr := Round(VIB_ENT * (1 shl VIB_SHIFT) / OPL.rate * 6.4 * (OPL.clock / 3600000))
  else
    OPL.vibIncr := 0;
end;

procedure OPLWriteReg(OPL: P_FM_OPL; r, v: Integer);
var
  CH: P_OPL_CH;
  slot: Integer;
  block_fnum: Integer;
  keyon: Integer;
  feedback: Integer;
  rkey: Byte;
  i: Integer;
begin
  case r and $e0 of
    $00:
      begin
        case r and $1f of
          $01:
            begin
              if (OPL.typ and OPL_TYPE_WAVESEL) <> 0 then
              begin
                OPL.wavesel := v and $20;
                if OPL.wavesel = 0 then
                  for i := 0 to OPL.max_ch - 1 do
                  begin
                    OPL.P_CH[i].SLOT[0].wavetable := @SIN_TABLE[0];
                    OPL.P_CH[i].SLOT[1].wavetable := @SIN_TABLE[0];
                  end;
              end;
              Exit;
            end;
          $02: OPL.T[0] := (256 - v) * 4;
          $03: begin OPL.T[1] := (256 - v) * 16; Exit; end;
          $04:
            begin
              if (v and $80) <> 0 then
                OPL_STATUS_RESET(OPL, $7f)
              else
              begin
                OPL_STATUS_RESET(OPL, v and $78);
                OPL_STATUSMASK_SET(OPL, ((not v) and $78) or $01);
                if OPL.st[1] <> ((v shr 1) and 1) then
                begin
                  OPL.st[1] := (v shr 1) and 1;
                  // TimerHandler would be called
                end;
                if OPL.st[0] <> (v and 1) then
                begin
                  OPL.st[0] := v and 1;
                  // TimerHandler
                end;
              end;
              Exit;
            end;
        end;
      end;
    $20:
      begin
        slot := slot_array[r and $1f];
        if slot = -1 then Exit;
        set_mul(OPL, slot, v);
        Exit;
      end;
    $40:
      begin
        slot := slot_array[r and $1f];
        if slot = -1 then Exit;
        set_ksl_tl(OPL, slot, v);
        Exit;
      end;
    $60:
      begin
        slot := slot_array[r and $1f];
        if slot = -1 then Exit;
        set_ar_dr(OPL, slot, v);
        Exit;
      end;
    $80:
      begin
        slot := slot_array[r and $1f];
        if slot = -1 then Exit;
        set_sl_rr(OPL, slot, v);
        Exit;
      end;
    $a0:
      begin
        case r of
          $bd:
            begin
              rkey := OPL.rythm xor v;
              OPL.ams_table := @AMS_TABLE[0];
              if (v and $80) <> 0 then OPL.ams_table := @AMS_TABLE[AMS_ENT];
              OPL.vib_table := @VIB_TABLE[0];
              if (v and $40) <> 0 then OPL.vib_table := @VIB_TABLE[VIB_ENT];
              OPL.rythm := v and $3f;
              if (OPL.rythm and $20) <> 0 then
              begin
                if (rkey and $10) <> 0 then
                begin
                  if (v and $10) <> 0 then
                  begin
                    OPL.P_CH[6].op1_out[0] := 0;
                    OPL.P_CH[6].op1_out[1] := 0;
                    OPL_KEYON(@OPL.P_CH[6].SLOT[0]);
                    OPL_KEYON(@OPL.P_CH[6].SLOT[1]);
                  end
                  else
                  begin
                    OPL_KEYOFF(@OPL.P_CH[6].SLOT[0]);
                    OPL_KEYOFF(@OPL.P_CH[6].SLOT[1]);
                  end;
                end;
                if (rkey and $08) <> 0 then
                begin
                  if (v and $08) <> 0 then OPL_KEYON(@OPL.P_CH[7].SLOT[1])
                  else OPL_KEYOFF(@OPL.P_CH[7].SLOT[1]);
                end;
                if (rkey and $04) <> 0 then
                begin
                  if (v and $04) <> 0 then OPL_KEYON(@OPL.P_CH[8].SLOT[0])
                  else OPL_KEYOFF(@OPL.P_CH[8].SLOT[0]);
                end;
                if (rkey and $02) <> 0 then
                begin
                  if (v and $02) <> 0 then OPL_KEYON(@OPL.P_CH[8].SLOT[1])
                  else OPL_KEYOFF(@OPL.P_CH[8].SLOT[1]);
                end;
                if (rkey and $01) <> 0 then
                begin
                  if (v and $01) <> 0 then OPL_KEYON(@OPL.P_CH[7].SLOT[0])
                  else OPL_KEYOFF(@OPL.P_CH[7].SLOT[0]);
                end;
              end;
              Exit;
            end;
        end;
        if (r and $0f) > 11 then Exit;
        CH := @OPL.P_CH[r and $0f];
        if (r and $10) = 0 then
          block_fnum := (CH.block_fnum and $1f00) or v
        else
        begin
          keyon := (v shr 5) and 1;
          block_fnum := ((v and $1f) shl 8) or (CH.block_fnum and $ff);
          if CH.keyon <> keyon then
          begin
            CH.keyon := keyon;
            if CH.keyon <> 0 then
            begin
              CH.op1_out[0] := 0;
              CH.op1_out[1] := 0;
              OPL_KEYON(@CH.SLOT[0]);
              OPL_KEYON(@CH.SLOT[1]);
            end
            else
            begin
              OPL_KEYOFF(@CH.SLOT[0]);
              OPL_KEYOFF(@CH.SLOT[1]);
            end;
          end;
        end;
        if CH.block_fnum <> Cardinal(block_fnum) then
        begin
          CH.block_fnum := block_fnum;
          CH.ksl_base := KSL_TABLE[block_fnum shr 6];
          CH.fc := OPL.FN_TABLE[block_fnum and $3ff] shr (7 - (block_fnum shr 10));
          CH.kcode := CH.block_fnum shr 9;
          if (OPL.mode and $40) <> 0 then
            if (CH.block_fnum and $100) <> 0 then CH.kcode := CH.kcode or 1;
          CALC_FCSLOT(CH, @CH.SLOT[0]);
          CALC_FCSLOT(CH, @CH.SLOT[1]);
        end;
        Exit;
      end;
    $c0:
      begin
        if (r and $0f) > 11 then Exit;
        CH := @OPL.P_CH[r and $0f];
        feedback := (v shr 1) and 7;
        if feedback <> 0 then CH.FB := (8 + 1) - feedback
        else CH.FB := 0;
        CH.CON := v and 1;
        set_algorythm(CH);
        Exit;
      end;
    $e0:
      begin
        slot := slot_array[r and $1f];
        if slot = -1 then Exit;
        CH := @OPL.P_CH[slot shr 1];
        if OPL.wavesel <> 0 then
          CH.SLOT[slot and 1].wavetable := @SIN_TABLE[(v and 3) * SIN_ENT];
        Exit;
      end;
  end;
end;

function OPL_LockTable: Integer;
begin
  Inc(num_lock);
  if num_lock > 1 then Exit(0);
  cur_chip := nil;
  if OPLOpenTable = 0 then
  begin
    Dec(num_lock);
    Exit(-1);
  end;
  Result := 0;
end;

procedure OPL_UnLockTable;
begin
  if num_lock > 0 then Dec(num_lock);
  if num_lock > 0 then Exit;
  cur_chip := nil;
  OPLCloseTable;
end;

procedure YM3812UpdateOne(OPL: P_FM_OPL; buffer: PSmallInt; length, stripe: Integer; volume: Single);
var
  i: Integer;
  data: Integer;
  buf: PSmallInt;
  amsCnt, vibCnt: Cardinal;
  rythm: Byte;
  CH, R_CH: P_OPL_CH;
begin
  buf := buffer;
  amsCnt := OPL.amsCnt;
  vibCnt := OPL.vibCnt;
  rythm := OPL.rythm and $20;
  if Pointer(OPL) <> cur_chip then
  begin
    cur_chip := Pointer(OPL);
    S_CH := OPL.P_CH;
    E_CH := @S_CH[9];
    SLOT7_1 := @S_CH[7].SLOT[0];
    SLOT7_2 := @S_CH[7].SLOT[1];
    SLOT8_1 := @S_CH[8].SLOT[0];
    SLOT8_2 := @S_CH[8].SLOT[1];
    amsIncr := OPL.amsIncr;
    vibIncr := OPL.vibIncr;
    ams_table := OPL.ams_table;
    vib_table := OPL.vib_table;
  end;
  if rythm <> 0 then R_CH := @S_CH[6] else R_CH := E_CH;
  for i := 0 to length - 1 do
  begin
    ams := ams_table[(amsCnt + amsIncr) shr AMS_SHIFT];
    vib := vib_table[(vibCnt + vibIncr) shr VIB_SHIFT];
    outd[0] := 0;
    CH := S_CH;
    while CH < R_CH do
    begin
      OPL_CALC_CH(CH);
      Inc(CH);
    end;
    if rythm <> 0 then
      OPL_CALC_RH(S_CH);
    outd[0] := Round(outd[0] * volume);
    data := Limit(outd[0], OPL_MAXOUT, OPL_MINOUT);
    buf^ := data shr OPL_OUTSB;
    Inc(buf);
  end;
  OPL.amsCnt := amsCnt;
  OPL.vibCnt := vibCnt;
end;

function OPLCreate(typ, clock, rate: Integer): P_FM_OPL;
var
  ptr: PByte;
  state_size: Integer;
  max_ch: Integer;
begin
  if OPL_LockTable = -1 then Exit(nil);
  max_ch := 12;
  state_size := SizeOf(T_FM_OPL) + SizeOf(T_OPL_CH) * max_ch;
  GetMem(ptr, state_size);
  if ptr = nil then Exit(nil);
  FillChar(ptr^, state_size, 0);
  Result := P_FM_OPL(ptr);
  Inc(ptr, SizeOf(T_FM_OPL));
  Result.P_CH := P_OPL_CH(ptr);
  Result.typ := typ;
  Result.clock := clock;
  Result.rate := rate;
  Result.max_ch := max_ch;
  OPL_initalize(Result);
  OPLResetChip(Result);
end;

procedure OPLDestroy(OPL: P_FM_OPL);
begin
  if OPL = nil then Exit;
  OPL_UnLockTable;
  FreeMem(OPL);
end;

procedure OPLResetChip(OPL: P_FM_OPL);
var
  c, s, i: Integer;
begin
  OPL.mode := 0;
  OPL_STATUS_RESET(OPL, $7f);
  OPLWriteReg(OPL, $01, 0);
  OPLWriteReg(OPL, $02, 0);
  OPLWriteReg(OPL, $03, 0);
  OPLWriteReg(OPL, $04, 0);
  for i := $ff downto $20 do
    OPLWriteReg(OPL, i, 0);
  for c := 0 to OPL.max_ch - 1 do
  begin
    for s := 0 to 1 do
    begin
      OPL.P_CH[c].SLOT[s].wavetable := @SIN_TABLE[0];
      OPL.P_CH[c].SLOT[s].evc := EG_OFF;
      OPL.P_CH[c].SLOT[s].eve := EG_OFF + 1;
      OPL.P_CH[c].SLOT[s].evs := 0;
    end;
  end;
end;

function OPLWrite(OPL: P_FM_OPL; a, v: Integer): Integer;
begin
  if (a and 1) = 0 then
    OPL.address := v and $ff
  else
  begin
    if Assigned(OPL.UpdateHandler) then
      OPL.UpdateHandler(OPL.UpdateParam, 0);
    OPLWriteReg(OPL, OPL.address, v);
  end;
  Result := OPL.status shr 7;
end;

function OPLRead(OPL: P_FM_OPL; a: Integer): Byte;
begin
  if (a and 1) = 0 then
    Result := OPL.status and (OPL.statusmask or $80)
  else
  begin
    case OPL.address of
      $05, $0f, $19, $1a: Result := 0;
      else Result := 0;
    end;
  end;
end;

function OPLTimerOver(OPL: P_FM_OPL; c: Integer): Integer;
var
  ch: Integer;
begin
  if c <> 0 then
    OPL_STATUS_SET(OPL, $20)
  else
  begin
    OPL_STATUS_SET(OPL, $40);
    if (OPL.mode and $80) <> 0 then
    begin
      if Assigned(OPL.UpdateHandler) then
        OPL.UpdateHandler(OPL.UpdateParam, 0);
      for ch := 0 to 8 do
        // CSMKeyControl stub
        ;
    end;
  end;
  if Assigned(OPL.TimerHandler) then
    OPL.TimerHandler(OPL.TimerParam + c, OPL.T[c] * OPL.TimerBase);
  Result := OPL.status shr 7;
end;

// Initialize static tables
procedure InitStaticTables;
var
  i: Integer;
  val: Double;
begin
  // SL_TABLE
  for i := 0 to 15 do
    SL_TABLE[i] := Round(((i*3) / EG_STEP) * (1 shl ENV_BITS)) + EG_DST;
  SL_TABLE[15] := Round((31 / EG_STEP) * (1 shl ENV_BITS)) + EG_DST;
  // KSL_TABLE
  for i := 0 to 127 do
  begin
    val := (i mod 16);
    // actual calculation simplified
    KSL_TABLE[i] := Round((val * 3) / EG_STEP / 2);
  end;
end;

initialization
  InitStaticTables;
  Randomize;
end.