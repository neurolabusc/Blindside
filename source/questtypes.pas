unit questtypes;
// 7/7/10 cr ported to pascal


interface

const
 keps: double = 2.2204e-016;
  kNaN : double = 1/0;
  kINF : double = 1/0;
  kMaxTrials = 32000;
type
  TFloatType = double;
  TDblArray = array of TFloatType;
  TIntType = integer;
  TIntArray = array of integer;
  TQuest  = record
    ntrials,
    dim: integer;
    updatePdf,warnPdf,normalizePdf: boolean;
    range,tGuess,tGuessSd,pThreshold,beta,delta,gamma,grain,xThreshold,quantileorder: TFloatType;
    x,pdf,x2,p2,s2r1,s2r2:  TDblArray;
    i: TIntArray;
    intensity : array [1..kMaxTrials] of TFloatType; //indexed from 1!
    responseOK: array [1..kMaxTrials] of boolean;
  end;
function SumArray (var  v: TDblArray): TFloatType;
  //matlab p=sum(q.pdf) -> p := SumArray(q.pdf);
procedure DifferenceArray(var  v: TDblArray; offset: TFloatType);  overload;
procedure FlipLRArray(var  v: TDblArray; source: TDblArray);  overload;
procedure SetArray(var  v: TDblArray; min,max: integer);overload;
procedure SetArray(var  v: TIntArray; min,max: integer);overload;
    //matlab q.i:=-q.dim/2:q.dim/2; ->  SetArray(q.i,-dim div 2, dim div 2)
procedure MultArray(var  v: TDblArray; scale: TFloatType); overload;
    //matlab q.x =q.x*q.grain; ->  MultArray(q.x, q.grain)
procedure MultArray(var  v: TDblArray; source: TDblArray; scale: TFloatType);  overload;
procedure MultArray(var  v: TDblArray; source: TIntArray; scale: TFloatType);  overload;
    //matlab q.x =q.i*q.grain; ->  MultArray(q.x,q.i, q.grain)
procedure ExpArray (var  v: TDblArray; source: TDblArray; sd: single);
//matlab q.pdf=exp(-0.5*(q.x/q.tGuessSd).^2); ExpArray(q.pdf,q.tGuessSd)
//procedure Setii(var  q: TQuest; inten: TFloatType);
//matlab rii=size(q.pdf,2)+q.i-round((inten-q.tGuess)/q.grain); -> Setii (q,inten);
procedure SetP2(var  q: TQuest); overload
procedure SetP2(var  q: TQuest; offset: TFloatType); overload
//matlab q.p2=q.delta*q.gamma+(1-q.delta)*(1-(1-q.gamma)*exp(-10.^(q.beta*q.x2))); -> SetP2(Q,0);
//matlab q.p2=q.delta*q.gamma+(1-q.delta)*(1-(1-q.gamma)*exp(-10.^(q.beta*(q.x2+q.xThreshold)))); ->SetP2(Q,q.xThreshold);
function AnyNanINF (var  v: TDblArray): boolean;

procedure NormalizeArray (var  v: TDblArray);
//matlab q.pdf=q.pdf/sum(q.pdf); NormalizeArray(q.pdf);
function NumDiff (var  v: TDblArray): integer;
//reports number of items different from predecessor
function interp1 (x,y: TDblArray; x1: TFloatType): TFloatType;//returns estimate for y1

implementation
uses questinterface, math;

function LinPos(x1,x2,y1,y2,xt: TFloatType): TFloatType;
var
  slope,dx: TFloatType;
begin
  result := x1;
  dx := x2-x1;
  if dx=0 then
    exit;
  slope := (y2-y1);

  result := y1 + slope*(xt-x1)/dx;

end;

function interp1 (x,y: TDblArray; x1: TFloatType): TFloatType;//returns estimate for y1
var
  len, i: integer;
begin
  result := kNaN;//NaN;
  len := length(x);
  if (len < 2) or  (len <> length(y)) then
    exit;
  if x[0] > x[len-1] then
    ErrorQ('interp designed for positive slope');
  //fx(x[0],x[len-1],x1);
  if x[0] > x1 then
    exit;
  if x[len-1] < x1 then
    exit;
  i := 0;
  while (i<len) and (x[i] < x1) do
    inc(i);
  result := x[i];
  if (x[i]=x1) or (i=0) then
    exit;
  result := LinPos(x[i-1],x[i],y[i-1],y[i],x1);
end;


procedure DifferenceArray(var  v: TDblArray; offset: TFloatType);  
//matlab x = 1-x -> DifferenceArray(x,1);
var
  i,len: integer;
begin
  len := length(v);
  if len < 1 then exit;
  for i := 0 to len-1 do
    v[i] := offset - v[i];
end;

FUNCTION specialsingle (var s:TFloatType): boolean;
//returns true if s is Infinity, NAN or Indeterminate
//4byte IEEE: msb[31] = signbit, bits[23-30] exponent, bits[0..22] mantissa
//exponent of all 1s =   Infinity, NAN or Indeterminate
CONST kSpecialExponent = 255 shl 23;
VAR Overlay: LongInt ABSOLUTE s;
BEGIN
  IF ((Overlay AND kSpecialExponent) = kSpecialExponent) THEN
     RESULT := true
  ELSE
      RESULT := false;
END;

FUNCTION specialDouble (d:TFloatType): boolean;
//returns true if s is Infinity, NAN or Indeterminate
//8byte IEEE: msb[63] = signbit, bits[52-62] exponent, bits[0..51] mantissa
//exponent of all 1s =   Infinity, NAN or Indeterminate
CONST kSpecialExponent = 2047 shl 20;
VAR Overlay: ARRAY[1..2] OF LongInt ABSOLUTE d;
BEGIN
  IF ((Overlay[2] AND kSpecialExponent) = kSpecialExponent) THEN
     RESULT := true
  ELSE
      RESULT := false;
END;

FUNCTION specialTFloatType (d:TFloatType): boolean;
begin
  //not sure how to do this with extended types..
  if sizeof(TFloatType) = 8 then
    result := specialDouble(d)
  else if sizeof(TFloatType) = 4 then
    result := specialsingle(d)
  else
    result := true;//generate error - need to write new code if you want extended precision
end;

function NumDiff (var  v: TDblArray): integer;
var
  i,len: integer;
begin
  result := 0;
  len := length(v);
  if len < 2 then exit;
  for i := 1 to len-1 do
    if v[i] <> v[i-1] then
      inc(result);
end;

function AnyNanINF (var  v: TDblArray): boolean;
var
  i,len: integer;
begin
  result := false;
  len := length(v);
  if len < 1 then exit;
  for i := 0 to len-1 do
    if specialTFloatType(v[i]) then begin
      result := true;
      exit;
    end;
end;

procedure order (var lo,hi: integer);
var
  t: integer;
begin
  if hi >= lo then
    exit;
  t := lo;
  lo := hi;
  hi := t;
end;

procedure SetArray(var  v: TIntArray; min,max: integer);overload;
//matlab q.i=-dim/2:dim/2;  SetArray(q.i,min,max)
var
  i,lo,hi,len: integer;
begin
  lo := min;
  hi := max;
  order(lo,hi);
  len := hi-lo+1;
  setlength(v,len);
  for i := 0 to len-1 do
    v[i] := lo+i;
end;

procedure SetArray(var  v: TDblArray; min,max: integer);overload;
//matlab q.i=-dim/2:dim/2;  SetArray(q.i,min,max)
var
  i,lo,hi,len: integer;
begin
  lo := min;
  hi := max;
  order(lo,hi);
  len := hi-lo+1;
  setlength(v,len);
  for i := 0 to len-1 do
    v[i] := lo+i;
end;

procedure MultArray(var  v: TDblArray; scale: TFloatType); overload;
//matlab q.x =q.x*q.grain; ->  MultArray(q.x, q.grain)
var
  i,len: integer;
begin
  len := length(v);
  if len < 1 then exit;
  for i := 0 to len-1 do
    v[i] := v[i]*scale;
end;

procedure MultArray(var  v: TDblArray; source: TDblArray; scale: TFloatType); overload;
//matlab q.x4 =q.i*q.grain; ->  MultArray(q.x4,q.i, q.grain)
var
  i,len: integer;
begin
  len := length(source);
  if len < 1 then exit;
  setlength(v,len);
  for i := 0 to len-1 do
    v[i] := source[i]*scale;
end;

procedure MultArray(var  v: TDblArray; source: TIntArray; scale: TFloatType); overload;
//matlab q.x4 =q.i*q.grain; ->  MultArray(q.x4,q.i, q.grain)
var
  i,len: integer;
begin
  len := length(source);
  if len < 1 then exit;
  setlength(v,len);
  for i := 0 to len-1 do
    v[i] := source[i]*scale;
end;

procedure FlipLRArray(var  v: TDblArray; source: TDblArray);  overload;
//matlab tar=fliplr(1-src)  FlipLR(tar,src);
var
  i,len: integer;
begin
  len := length(source);
  if len < 1 then exit;
  setlength(v,len);
  for i := 0 to len-1 do
    v[i] := source[len-i-1];
end;


procedure AddMultArray(var  v: TDblArray; source: TDblArray; scale, offset: TFloatType); overload;
//matlab q.x4 =(q.i+offset)*q.grain; ->  MultArray(q.x4,q.i, q.grain)
var
  i,len: integer;
begin
  len := length(source);
  if len < 1 then exit;
  setlength(v,len);
  for i := 0 to len-1 do
    v[i] := (source[i]+offset)*scale;
end;

procedure ExpArray (var  v: TDblArray; source: TDblArray; sd: single);
//matlab q.pdf=exp(-0.5*(q.x/q.tGuessSd).^2); ExpArray(q.pdf,q.tGuessSd)
var
  i,len: integer;
begin
  len := length(source);
  if len < 1 then exit;
  setlength(v,len);
  if sd = 0 then begin
      ErrorQ('ExpArray: SD cannot equal 0');
      sd := 0.000000001;
  end;
  for i := 0 to len-1 do
    v[i] := exp(-0.5*sqr(source[i]/sd) );
end;

procedure NormalizeArray (var  v: TDblArray);
//matlab q.pdf=q.pdf/sum(q.pdf); NormalizeArray(q.pdf);
var
  i,len: integer;
  sum: TFloatType;
begin
  len := length(v);
  if len < 1 then exit;
  sum := 0;
  for i := 0 to len-1 do
    sum := sum+ v[i];
  if sum = 0 then
    exit; //divide by zero
  for i := 0 to len-1 do
    v[i] := v[i]/sum;
end;

function SumArray (var  v: TDblArray): TFloatType;
//p=sum(q.pdf) -> p := SumArray(q.pdf);
var
  i,len: integer;
begin
  result := 0;
  len := length(v);
  if len < 1 then exit;
  for i := 0 to len-1 do
    result := result+ v[i];
end;

procedure SetP2(var  q: TQuest; offset: TFloatType);  overload
//matlab q.p2=q.delta*q.gamma+(1-q.delta)*(1-(1-q.gamma)*exp(-10.^(q.beta*q.x2))); -> SetP2(Q,0);
//matlab q.p2=q.delta*q.gamma+(1-q.delta)*(1-(1-q.gamma)*exp(-10.^(q.beta*(q.x2+q.xThreshold)))); ->SetP2(Q,q.xThreshold);
var
  i,len: integer;
begin
  len := length(q.x2);
  if len < 1 then exit;
  AddMultArray(q.p2, q.x2, q.beta, offset);
  for i := 0 to len-1 do
    q.p2[i] :=  q.delta*q.gamma+(1-q.delta)*(1-(1-q.gamma) *exp(-1*power(10,q.p2[i])));
end;

procedure SetP2(var  q: TQuest); overload;
//matlab q.p2=q.delta*q.gamma+(1-q.delta)*(1-(1-q.gamma)*exp(-10.^(q.beta*q.x2))); delphi SetP2(Q);
begin
  SetP2(q,0);
end;


end.
