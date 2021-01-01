unit quest;

interface
uses questtypes,questinterface,sysutils,classes,math;

function QuestBetaAnalysis(var q: TQuest; var s: TStrings): TFloatType;
procedure QuestCreate(var q: TQuest; tGuess,tGuessSd,pThreshold,beta,delta,gamma,grain,range: TFloatType); overload
procedure QuestCreate(var q: TQuest; tGuess,tGuessSd,pThreshold,beta,delta,gamma,grain: TFloatType); overload
procedure QuestCreate(var q: TQuest; tGuess,tGuessSd,pThreshold,beta,delta,gamma: TFloatType); overload
function QuestMean(q: TQuest): TFloatType;
function QuestPdf(q: TQuest; t: TFloatType): TFloatType;
function QuestQuantile(q: TQuest {,quantileOrder}): TFloatType;
procedure QuestRecompute(var q: TQuest);
function QuestSd(q: TQuest): TFloatType;
procedure QuestUpdateFromHistory(var q: TQuest; intensity: TFloatType; responseok: boolean);
procedure QuestUpdate(var q: TQuest; intensity: TFloatType; responseok: boolean);


implementation

function QuestBetaAnalysis1(var qi: TQuest; var s: TStrings): TFloatType;
const
  kq = 16;
  kgrain = 0.02;
  kdim = 250;
var
  nok,k,maxp2i,i: integer;
  q:  TQuest;
  sd,betaMean,ibetaMean,SumSqrp2beta2,Sump2beta2,betaSd,ibetaSd,maxp2,p,t2:  TFloatType;
  beta2,p2,sd2: TDblArray;
begin
  maxp2i := 0;
  if qi.ntrials < 1 then begin
      s.Add('Beta analysis failed: no history of trials');
      exit;
  end;
  setlength(p2,kq);
  setlength(beta2,kq);
  setlength(sd2,kq);
  nok := 0;
  for i :=1 to kq do begin
    QuestCreate(q,qi.tGuess,qi.tGuessSd,qi.pThreshold,power(2,i/4){qi.beta},qi.delta,qi.gamma,kgrain,kgrain*kdim);
    q.normalizePdf := false;
    q.ntrials := qi.ntrials;
    for k := 1 to q.ntrials do begin
      q.intensity[k] := qi.intensity[k];
      q.responseok[k] :=  qi.responseok[k];
    end;
    QuestRecompute(q); //restore original values
    p:=SumArray(q.pdf);
    if p = 0 then
        S.add('Omitting beta values for beta='+floattostr(q.beta)+ ' as this generates zero probability')
    else begin
        //sd2:=QuestSd(q); // get sd of threshold for each possible beta
        t2 :=QuestMean(q); // estimate threshold for each possible beta
        p2[nok]:=QuestPdf(q,t2); // get probability of each of these (threshold,beta) combinations
        sd2[nok]:=QuestSd(q);
        beta2[nok] := q.beta;
        //FPrintF('beta',i,t2,p2[nok]);
        if maxp2i = 0 then begin
          maxp2i := i;
          //ReportColumn('q2(1).x',q.x);
          //ReportArray('q2(1).pdf',q.pdf);
          //FPrintF('sum pdf',p);
        end else  if p2[nok]>maxp2 then
          maxp2i := i;
        if maxp2i = i then
          maxp2 := p2[nok];
        inc(nok); //do this last, as beta2 and p2 are indexed from 0
      end;
  end;
  if maxp2i < 1 then begin
    S.add('All possible values have zero probability');
    exit;
  end;
  i := maxp2i;
  //QuestCopyParams(q,power(2,i/4),kgrain,kdim);
  QuestCreate(q,qi.tGuess,qi.tGuessSd,qi.pThreshold,power(2,i/4){qi.beta},qi.delta,qi.gamma,kgrain,kgrain*kdim);
  q.normalizePdf := false;
  q.ntrials := qi.ntrials;
  QuestRecompute(q); //restore original values
  sd:=QuestSd(q); // get sd of threshold for each possible beta
  t2 :=QuestMean(q); // estimate threshold for each possible beta
  p:=SumArray(p2);//QuestPdf(q,t2);
  //betaMean=sum(p2.*beta2)/p;
  betaMean :=0;
  for i := 0 to nok-1 do
    betamean := betamean+ beta2[i]*p2[i] ;
  if betaMean < 0 then begin
      s.Add('Error computing beta mean');
      exit;
  end;
  betamean := betamean/p;
  //FPrintF('sd/t/p',sd,t2,betamean);
  //betaSd=sqrt(sum(p2.*beta2.^2)/p-(sum(p2.*beta2)/p).^2);
  SumSqrp2beta2 := 0;
  for i := 0 to nok-1 do //-1 as indexed from 0
    SumSqrp2beta2 := SumSqrp2beta2+ p2[i]*Sqr(beta2[i]);
  SumSqrp2beta2 := SumSqrp2beta2/p;
  Sump2beta2 := 0;
  for i := 0 to nok-1 do //-1 as indexed from 0
    Sump2beta2 := Sump2beta2+ p2[i]*beta2[i];
  Sump2beta2 := Sump2beta2/p;
  betaSd:=sqrt(SumSqrp2beta2-sqr(Sump2beta2));
  //FPrintF('beta mean:sd',betamean,betaSD);

// beta has a very skewed distribution, with a long tail out to very large value of beta, whereas 1/beta is
// more symmetric, with a roughly normal distribution. Thus it is statistically more efficient to estimate the
// parameter as 1/average(1/beta) than as average(beta). "iBeta" stands for inverse beta, 1/beta.
// The printout takes the conservative approach of basing the mean on 1/beta, but reporting the sd of beta.
//iBetaMean=sum(p2./beta2)/p;
//iBetaSd=sqrt(sum(p2./beta2.^2)/p-(sum(p2./beta2)/p).^2);
  ibetaMean :=0;
  for i := 0 to nok-1 do
    ibetamean := ibetamean+ p2[i]/beta2[i] ;
  ibetamean := ibetamean/p;
  SumSqrp2beta2 := 0;
  for i := 0 to nok-1 do //-1 as indexed from 0
    SumSqrp2beta2 := SumSqrp2beta2+ p2[i]/Sqr(beta2[i]);
  SumSqrp2beta2 := SumSqrp2beta2/p;
  Sump2beta2 := 0;
  for i := 0 to nok-1 do //-1 as indexed from 0
    Sump2beta2 := Sump2beta2+ p2[i]/beta2[i];
  Sump2beta2 := Sump2beta2/p;
  ibetaSd:=sqrt(SumSqrp2beta2-sqr(Sump2beta2));
  //FPrintF('ibeta mean:sd',ibetamean,ibetaSD);
 (* s.Add(Format('Decimal          = %d', [-123]));
  s.Add(format('Threshold %f ± %f; Beta mode %f mean %f ± %f imean 1/%f ± %f; Gamma %f',[t,sd,q.beta,betaMean,betaSd,1/iBetaMean,iBetaSd,q.gamma]));
	s.Add(format('Threshold %4.2f ± %.2f; Beta mode %.1f mean %.1f ± %.1f imean 1/%.1f ± %.1f; Gamma %.2f\n',[t,sd,q.beta,betaMean,betaSd,1/iBetaMean,iBetaSd,q.gamma]));
	s.Add(format('%5.2f	%4.1f	%5.2f',[t,1/iBetaMean,q.gamma]));
  *)

	s.Add(format('%5.3f	%5.3f	%4.2f	%4.2f	%6.3f',[t2,sd,1/iBetaMean,betaSd,q.gamma]));
  result := 1/iBetaMean;//betaEstimate=1/iBetaMean;
end;

function QuestBetaAnalysis(var q: TQuest; var s: TStrings): TFloatType;
// betaEstimate=QuestBetaAnalysis(q,[fid]);
//
// Analyzes the quest function with beta as a free parameter. It prints (in
// the file or files pointed to by fid) the mean estimates of alpha (as
// logC) and beta. Gamma is left at whatever value the user fixed it at.
//
// Note that normalization of the pdf, by QuestRecompute, is disabled because it
// would need to be done across the whole q vector. Without normalization,
// the pdf tends to underflow at around 1000 trials. You will have some warning
// of this because the printout mentions any values of beta that were dropped
// because they had zero probability. Thus you should keep the number of trials
// under around 1000, to avoid the zero-probability warnings.
//
// See Quest.

// Denis Pelli 5/6/99
// 8/23/99 dgp streamlined the printout
// 8/24/99 dgp add sd's to printout
// 10/13/04 dgp added comment explaining 1/beta
// 7/7/10 cr conversion to pascal
begin
 	s.add('Now re-analyzing with both threshold and beta as free parameters...');
 	s.add('logC 	 ±sd 	 beta	 ±sd	 gamma\n');
	result := QuestBetaAnalysis1(q,s);
end;

// q=QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma,[grain],[range])
//
// Create a struct q with all the information necessary to measure
// threshold. Threshold "t" is measured on an abstract "intensity"
// scale, which usually corresponds to log10 contrast.
//
// QuestCreate saves in struct q the parameters for a Weibull psychometric function:
// p2=delta*gamma+(1-delta)*(1-(1-gamma)*exp(-10.^(beta*(x2+xThreshold))));
// where x represents log10 contrast relative to threshold. The Weibull
// function itself appears only in QuestRecompute, which uses the
// specified parameter values in q to compute a psychometric function
// and store it in q. All the other Quest functions simply use the
// psychometric function stored in "q". QuestRecompute is called solely
// by QuestCreate and QuestBetaAnalysis (and possibly by a few user
// programs). Thus, if you prefer to use a different kind of
// psychometric function, called Foo, you need only create your own
// QuestCreateFoo, QuestRecomputeFoo, and (if you need it)
// QuestBetaAnalysisFoo, based on QuestCreate, QuestRecompute, and
// QuestBetaAnalysis, and you can use them with the rest of the Quest
// package unchanged. You would only be changing a few lines of code,
// so it would quite easy to do.
//
// Several users of Quest have asked questions on the Psychtoolbox forum
// about how to restrict themselves to a practical testing range. That is
// not what tGuessSd and "range" are for; they should be large, e.g. I
// typically set tGuessSd=3 and range=5 when intensity represents log
// contrast. If necessary, you should restrict the range yourself, outside
// of Quest. Here, in QuestCreate, you tell Quest about your prior beliefs,
// and you should try to be open-minded, giving Quest a generously large
// range to consider as possible values of threshold. For each trial you
// will later ask Quest to suggest a test intensity. It is important to
// realize that what Quest returns is just what you asked for, a
// suggestion. You should then test at whatever intensity you like, taking
// into account both the suggestion and any practical constraints (e.g. a
// maximum and minimum contrast that you can achieve, and quantization of
// contrast). After running the trial you should call QuestUpdate with the
// contrast that you actually used and the observer's response to add your
// new datum to the database. Don't restrict "tGuessSd" or "range" by the
// limitations of what you can display. Keep open the possibility that
// threshold may lie outside the range of contrasts that you can produce,
// and let Quest consider all possibilities.
//
// There is one exception to the above advice of always being generous with
// tGuessSd. Occasionally we find that we have a working Quest-based
// program that measures threshold, and we discover that we need to measure
// the proportion correct at a particular intensity. Instead of writing a
// new program, or modifying the old one, it is often more convenient to
// instead reduce tGuessSd to practically zero, e.g. a value like 0.001,
// which has the effect of restricting all threshold estimates to be
// practically identical to tGuess, making it easy to run any number of
// trials at that intensity. Of course, in this case, the final threshold
// estimate from Quest should be ignored, since it is merely parroting back
// to you the assertion that threshold is equal to the initial guess
// "tGuess". What's of interest is the final proportion correct; at the
// end, call QuestTrials or add an FPRINTF statement to report it.
//
// tGuess is your prior threshold estimate.
// tGuessSd is the standard deviation you assign to that guess. Be generous.
// pThreshold is your threshold criterion expressed as probability of
//	response==1. An intensity offset is introduced into the psychometric
//	function so that threshold (i.e. the midpoint of the table) yields
//	pThreshold.
// beta, delta, and gamma are the parameters of a Weibull psychometric function.
// beta controls the steepness of the psychometric function. Typically 3.5.
// delta is the fraction of trials on which the observer presses blindly.
//	Typically 0.01.
// gamma is the fraction of trials that will generate response 1 when
//	intensity==-inf.
// grain is the quantization (step size) of the internal table. E.g. 0.01.
// range is the intensity difference between the largest and smallest
// 	intensity that the internal table can store. E.g. 5. This interval will
// 	be centered on the initial guess tGuess, i.e.
// 	tGuess+(-range/2:grain:range/2). "range" is used only momentarily here,
// 	to determine "dim", which is retained in the quest struct. "dim" is the
// 	number of distinct intensities that the internal table can store, e.g.
// 	500. QUEST assumes that intensities outside of this interval have zero
// 	prior probability, i.e. they are impossible values for threshold. The
// 	cost of making "range" too big is some extra storage and computation,
// 	which are usually negligible. The cost of making "range" too small is
// 	that you prejudicially exclude what are actually possible values for
// 	threshold. Getting out-of-range warnings from QuestUpdate is one
// 	possible indication that your stated range is too small.
//
// See Quest.

// 6/8/96   dgp  Wrote it.
// 6/11/96  dgp  Optimized the order of stuffing for faster unstuffing.
// 11/10/96 dhb  Added warning about correctness after DGP told me.
// 3/1/97   dgp  Fixed error in sign of xThreshold in formula for p2.
// 3/1/97   dgp  Updated to use Matlab 5 structs.
// 3/3/97   dhb  Added missing semicolon to first struct eval.
// 3/5/97   dgp  Fixed sd: use exp instead of 10^.
// 3/5/97   dgp  Added some explanation of the psychometric function.
// 6/24/97   dgp  For simulations, now allow specification of grain and dim.
// 9/30/98	dgp	Added "dim" fix from Richard Murray.
// 4/12/99 dgp dropped support for Matlab 4.
// 5/6/99 dgp Simplified "dim" calculation; just round up to even integer.
// 8/15/99   dgp  Explain how to use other kind of psychometric function.
// 2/10/02   dgp  Document grain and range.
// 9/11/04   dgp  Explain why supplied "range" should err on the high side.
// 10/13/04 	dgp  Explain why tGuesSd and range should be large, generous.
// 10/13/04 	dgp  Set q.normalizePdf to 1, to avoid underflow errors that otherwise accur after around 1000 trials.
//
// Copyright (c) 1996-2004 Denis Pelli
procedure QuestCreate(var q: TQuest; tGuess,tGuessSd,pThreshold,beta,delta,gamma,grain,range: TFloatType); overload
var
  dimf: TFloatType;
begin
	if range<=0 then
		errorq('"range" must be greater than zero.');
	dimf:=range/grain;
  q.range := range;
  q.nTrials := 0;
	q.dim:=2*ceil(dimf/2);	// round up to an even integer
  q.updatePdf:=true;//1;  boolean: 0 for no, 1 for yes
  q.warnPdf:= true; // // boolean
  q.normalizePdf:= true; //1; boolean. This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.
  q.tGuess:=tGuess;
  q.tGuessSd:=tGuessSd;
  q.pThreshold:=pThreshold;
  q.beta:=beta;
  q.delta:=delta;
  q.gamma:=gamma;
  q.grain:=grain;
  QuestRecompute(q);
end;


procedure QuestCreate(var q: TQuest; tGuess,tGuessSd,pThreshold,beta,delta,gamma,grain: TFloatType); overload
begin
  QuestCreate(q,tGuess,tGuessSd,pThreshold,beta,delta,gamma,grain,grain*500 {range});
end;

procedure QuestCreate(var q: TQuest; tGuess,tGuessSd,pThreshold,beta,delta,gamma: TFloatType); overload
begin
  QuestCreate(q,tGuess,tGuessSd,pThreshold,beta,delta,gamma,0.01 {grain});
end;

function QuestMean(q: TQuest): TFloatType;
// t=QuestMean(q)
//
// Get the mean threshold estimate.
// If q is a vector, then the returned t is a vector of the same size.
// See Quest.
// Denis Pelli, 6/8/96
// 3/1/97 dgp updated to use Matlab 5 structs.
// 4/12/99 dgp dropped support for Matlab 4.
// Copyright (c) 1996-2002 Denis Pelli
var
  i,len: integer;
  sumpdfx: TFloatType;
begin
  result := 0;
  len := length(q.pdf);
  if (len < 1) or (len <> length(q.x)) then
    exit;
  //q.tGuess+sum(q.pdf.*q.x)/sumArray(q.pdf);
  sumpdfx := 0;
  for i := 0 to len -1 do
    sumpdfx := sumpdfx + (q.pdf[i]*q.x[i]);
  result := q.tGuess+sumpdfx/sumArray(q.pdf);
end;

function QuestPdf(q: TQuest; t: TFloatType): TFloatType;
//The (possibly unnormalized) probability density of candidate threshold "t".
// q and t may be vectors of the same size, in which case the returned p is a vector of that size.
// See Quest.
// Denis Pelli
// 5/6/99 dgp wrote it
// 7/7/10 cr ported to pascal
// Copyright (c) 1996-1999 Denis Pelli
var
  len,i: integer;
begin
  result := 0;
  len := length(q.pdf);
  if len = 0 then
    exit;
  //i=round((t-q.tGuess)/q.grain)+1+q.dim/2;
  i:=round((t-q.tGuess)/q.grain)+(q.dim div 2); //note: no +1, as indexed from 0
  //i:=min(length(q.pdf),max(1,i));
  if i < 0 then
    i := 0;
  if i > (len-1) then
    i := len-1;
  result:=q.pdf[i];
end;

function QuestQuantile(q: TQuest {,quantileOrder}): TFloatType;
// intensity=QuestQuantile(q,[quantileOrder])
//
// Gets a quantile of the pdf in the struct q. You may specify the desired
// quantileOrder, e.g. 0.5 for median, or, making two calls, 0.05 and 0.95
// for a 90// confidence interval. If the "quantileOrder" argument is not
// supplied, then it's taken from the "q" struct. QuestCreate uses
// QuestRecompute to compute the optimal quantileOrder and saves that in the
// "q" struct; this quantileOrder yields a quantile  that is the most
// informative intensity for the next trial.
//
// This is based on work presented at a conference, but otherwise unpublished:
// Pelli, D. G. (1987). The ideal psychometric procedure. Investigative
// Ophthalmology & Visual Science, 28(Suppl), 366.
//
// See Quest.

// Denis Pelli, 6/9/96
// 6/17/96 dgp, worked around "nonmonotonic" (i.e. not strictly monotonic)
//				interp1 error.
// 3/1/97 dgp updated to use Matlab 5 structs.
// 4/12/99 dgp removed support for Matlab 4.
//
// Copyright (c) 1996-1999 Denis Pelli
var
  len,i: integer;
  p: TDblArray;
begin
  len := length(q.pdf);
  if len < 2 then exit;
  setlength(p,len);
  //p:=cumsum(q.pdf);
  p[0] := q.pdf[0];
  for i := 1 to len-1 do
    p[i] := p[i-1]+q.pdf[i];
  if p[len-1]= kINF then
    ErrorQ('PDF is all zero');
  if p[len-1]<= 0 then
    ErrorQ('PDF is all zero');
  //ReportArray('cumulative p',p);
  //result=q.tGuess+interp1(p(index),q.x(index),quantileOrder*p(end)); // 40 ms
  result := q.tGuess+ interp1(p,q.x,q.quantileorder*p[len-1]);
end;

procedure QuestRecompute(var q: TQuest);

var
  i2: TDblArray;
  inten: TFloatType;
  ii,k: integer;
  pE,pL,pH: TFloatType;
begin

if q.gamma>q.pThreshold then begin
	ErrorQ('reducing gamma from '+floattostr(q.gamma)+' to 0.5');
	q.gamma:=0.5;
end;
// prepare all the arrays
//q.i=-q.dim/2:q.dim/2;
SetArray(q.i,-q.dim div 2, q.dim div 2);
//ReportArray('q.i',q.i);
//q.x =q.i*q.grain;

MultArray(q.x,q.i, q.grain);
//ReportArray('q.x',q.x);
//q.pdf=exp(-0.5*(q.x/q.tGuessSd).^2);
ExpArray (q.pdf, q.x, q.tGuessSd);
//ReportArray('q.pdf',q.pdf);

//q.pdf=q.pdf/sum(q.pdf);
NormalizeArray(q.pdf);
//ReportArray('q.pdf',q.pdf);

//i2=-q.dim:q.dim;
SetArray(i2,-q.dim , q.dim );
//ReportArray('i2',i2);

//q.x2=i2*q.grain;
MultArray(q.x2,i2, q.grain);
//ReportArray('qx2',q.x2);

//q.p2=q.delta*q.gamma+(1-q.delta)*(1-(1-q.gamma)*exp(-10.^(q.beta*q.x2)));

SetP2(q);

(*if q.p2(1)>=q.pThreshold | q.p2(end)<=q.pThreshold
	error(sprintf('psychometric function range [%.2f %.2f] omits %.2f threshold',q.p2(1),q.p2(end),q.pThreshold))
end*)

if (q.p2[1]>=q.pThreshold) or (q.p2[length(q.p2)-1] <= q.pThreshold) then
	errorq('psychometric function range does not include threshold') ;

(*if any(~isfinite(q.p2))
	error('psychometric function p2 is not finite')
end*)
if AnyNanINF(q.p2) then
	errorq('psychometric function p2 is not finite') ;


(*index=find(diff(q.p2)); 		% subset that is strictly monotonic
if length(index)<2
	error(sprintf('psychometric function has only %g strictly monotonic point(s)',length(index)))
end *)
if NumDiff(q.p2) < 2 then
  errorq('psychometric function has only '+inttostr(NumDiff(q.p2))+' strictly monotonic points') ;



(*q.xThreshold=interp1(q.p2(index),q.x2(index),q.pThreshold);
if ~isfinite(q.xThreshold)
	q
	error(sprintf('psychometric function has no %.2f threshold',q.pThreshold))
end*)

q.xThreshold:=interp1(q.p2,q.x2,q.pThreshold);
if q.xThreshold = kNaN then
  errorq('psychometric function p2 is not finite') ;

(* q.p2=q.delta*q.gamma+(1-q.delta)*(1-(1-q.gamma)*exp(-10.^(q.beta*q.x2))); SetP2(Q);
q.p2=q.delta*q.gamma+(1-q.delta)*(1-(1-q.gamma)*exp(-10.^(q.beta*(q.x2+q.xThreshold))));
if any(~isfinite(q.p2))
	q
	error('psychometric function p2 is not finite')
end *)
SetP2(Q, q.xThreshold);
if AnyNanINF(q.p2) then
	errorq('psychometric function p2 is not finite') ;
//ReportArray('q.p2',q.p2);

(*q.s2=fliplr([1-q.p2;q.p2]);
if ~isfield(q,'intensity') | ~isfield(q,'response')
	q.intensity=[];
	q.response=[];
end
if any(~isfinite(q.s2(:)))
	error('psychometric function s2 is not finite')
end *)
FlipLRArray(q.s2r1,q.p2);
DifferenceArray(q.s2r1,1);
FlipLRArray(q.s2r2,q.p2);
//q.s2(1, :) ->ReportArray('q',q.s2r1);
//we use 1D arrays, so
// Matlab q.s2(1,497) -> q.s2r1[497]
// Matlab q.s2(2,497) -> q.s2r2[497]
if AnyNanINF(q.s2r1) then 
	errorq('psychometric function s2[1] is not finite') ;

if AnyNanINF(q.s2r2) then
	errorq('psychometric function s2[2] is not finite') ;

// Best quantileOrder depends only on min and max of psychometric function.
// For 2-interval forced choice, if pL=0.5 and pH=1 then best quantileOrder=0.60
// We write x*log(x+eps) in place of x*log(x) to get zero instead of NaN when x is zero.

(*pL=q.p2(1);
pH=q.p2(size(q.p2,2));
pE=pH*log(pH+eps)-pL*log(pL+eps)+(1-pH+eps)*log(1-pH+eps)-(1-pL+eps)*log(1-pL+eps);
pE=1/(1+exp(pE/(pL-pH)));
q.quantileOrder=(pE-pL)/(pH-pL);*)

pL := q.p2[0];
pH := q.p2[length(q.p2)-1];
pE :=pH*ln(pH+keps)-pL*ln(pL+keps)+(1-pH+keps)*ln(1-pH+keps)-(1-pL+keps)*ln(1-pL+keps);
pE :=1/(1+exp(pE/(pL-pH)));
q.quantileOrder :=(pE-pL)/(pH-pL);


(*if any(~isfinite(q.pdf))
	error('prior pdf is not finite')
end*)
if AnyNanINF(q.pdf) then
	errorq('prior pdf is not finite') ;
if q.nTrials > 0 then
  for k := 1 to q.ntrials do
    QuestUpdateFromHistory(q,q.intensity[k],q.responseok[k]);
if q.normalizePdf then
  NormalizeArray(q.pdf);
end;

function QuestSd(q: TQuest): TFloatType;
// sd=QuestSd(q)
//
// Get the sd of the threshold distribution.
// If q is a vector, then the returned t is a vector of the same size.
//
// See Quest.
// Denis Pelli, 6/8/96
// 3/1/97 dgp updated to use Matlab 5 structs.
// 4/12/99 dgp dropped support for Matlab 4.
// 7/7/10 cr ported to pascal
// Copyright (c) 1996-1999 Denis Pelli

var
  i,len: integer;
  SumPDFx,SumSqrPDFx,P : extended;
begin
  result := 0;
  p:=SumArray(q.pdf);
  if p <= 0 then begin
    ErrorQ('Error computing SD: p <= 0');
    exit;
  end;
  len := length(q.pdf); //-1 as indexed from 0
  if len <> length(q.x) then
    ErrorQ('Error computing SD');
  //sd=sqrt(sum(q.pdf.*q.x.^2)/p-(sum(q.pdf.*q.x)/p).^2);
  //sd= SumSqrPDFx-SumPDFx
  SumSqrPDFx := 0;
  for i := 0 to len-1 do //-1 as indexed from 0
    SumSqrPDFx := SumSqrPDFx+ q.pdf[i]*Sqr(q.x[i]);
  //FPrintf('sum(q.pdf.*q.x.^2) ',SumSqrPDFx);
  SumSqrPDFx := SumSqrPDFx / p;
  //FPrintf('sum(q.pdf.*q.x.^2)/p',SumSqrPDFx);
  SumPDFx := 0;
  for i := 0 to len-1 do //-1 as indexed from 0
    SumPDFx := SumPDFx+ q.pdf[i]*q.x[i];
  //FPrintf('(sum(q.pdf.*q.x) ',SumPDFx);
  SumPDFx := Sqr(SumPDFx / p);
  //FPrintf('(sum(q.pdf.*q.x)/p).^2',SumPDFx);
  //ReportArray('q.x',q.x);
  //Fprintf('sum(q.x)',SumArray(q.x));
  //Fprintf('sum(q.PDF)',SumArray(q.PDF));
  //Fprintf('sum(q.x)/p',SumArray(q.x)/p);
  //ReportArray('q.pdf',q.pdf);
  result := Sqrt(SumSqrPDFx-SumPDFx);
  //FPrintf('sqrt(sum(q.pdf.*q.x.^2)/p-(sum(q.pdf.*q.x)/p).^2)',result);
end;

procedure QuestUpdateFromHistory(var q: TQuest; intensity: TFloatType; responseok: boolean);
//From History does not increment the number of trials collected [nTrials]
//  Use 'QuestUpdate' to add new trials, 'QuestUpdateFromHistory' to refit previously collected data
var
  ii: array of integer;
  sub,i,len0,j: integer;
  low,high,inten: TFloatType;
begin
 if q.updatePdf then begin
  inten := intensity;
  //ii=size(q.pdf,2)+q.i-round((inten-q.tGuess)/q.grain);
  len0 := length(q.i)-1;
  if len0 < 0 then exit;
  setlength(ii,len0+1);
  sub := round((inten-q.tGuess)/q.grain);
  for i := 0 to len0 do
    ii[i]:=length(q.pdf)+q.i[i]-sub;
	if (ii[1]<1) or  (ii[length(ii)-1]>length(q.s2r1) ) then begin
		if q.warnPdf then begin
			low :=(1-length(q.pdf)-q.i[1])*q.grain+q.tGuess;
			high:=(length(q.s2r1)-length(q.pdf)-q.i[length(q.i)-1])*q.grain+q.tGuess;
			ErrorQ('QuestUpdate: intensity '+floattostr(intensity)+' out of range '+floattostr(low)+' to '+floattostr(high)+'. Pdf will be inexact. Suggest that you increase "range" in call to QuestCreate.');
		end;
    len0 := length(ii)-1;//-1 as indexed from 0
		if ii[1]<1 then begin
      for j := 0 to len0 do
			ii[j]:=ii[j]+1-ii[0]
		end else begin
      for j := 0 to len0 do
        ii[j]:=ii[j]+length(q.s2r1)-ii[len0];
		end;
	end;//if (q.ii[1]<1)...
 //ReportColumn('ii',ii);
 len0 := length(q.pdf)-1;//-1 as indexed from 0
 //ReportArray('q.s2(1, :)',q.s2r1);
 //ReportArray('q.s2(2, :)',q.s2r2);
 //	q.pdf=q.pdf.*q.s2(response+1,ii); % 4 ms
 if   responseOK then begin//response = 1 -> second row
  for j := 0 to len0 do
    q.pdf[j] := q.pdf[j]*q.s2r2[round(ii[j])-1]
 end else begin//response = 0 -> first row
  for j := 0 to len0 do
    q.pdf[j] := q.pdf[j]*q.s2r1[round(ii[j])-1];
 end;
 //ReportArray('q.pdfpre',q.pdf);
 if q.normalizePdf then
    NormalizeArray(q.pdf);
 end; //if q.updatePdf
  //ReportArray('q.pdf',q.pdf);
end; //if at least 1 trial

procedure QuestUpdate(var q: TQuest; intensity: TFloatType; responseok: boolean);
begin
    if q.ntrials >= kMaxTrials then begin
      ErrorQ('Unable to collect more than '+inttostr(kMaxTrials));
      exit;
    end;
    inc(q.ntrials);
    q.intensity[q.ntrials] := intensity;
    q.responseOK[q.ntrials] := responseok;
    QuestUpdateFromHistory(q,intensity,responseok);

end;

end.
