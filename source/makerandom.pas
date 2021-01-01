unit makerandom;

interface
uses prefs,adu, dialogs, sysutils;

function RandomDesign (lPrefs: TPrefs): TIO;
function MaxSession (lPrefs: TPrefs): integer;

implementation
type
	ByteRA = array [1..1] of byte;
	Bytep = ^ByteRA;
const
 kStdSham = 0;//2 Sessions: [++,--]; Sham
 kStdRev = 1;//2 Sessions: [++,--]; [+-,-+]
 kStdShamRev = 2;//3 Sessions: [++,--]; Sham; [+-,-+]
function StdShamRev (lOrder,lSession: integer): TIO;
//order 1..5,0: abc, acb, bac, bca, cab, cba
begin
     if lSession = 1 then begin
        case lOrder of
             1,2: result := StandardPolarity;
             3,4: result := Sham;
             else result := ReversedPolarity;
        end;
     end else if lSession = 2 then begin
        case lOrder of
             3,5: result := StandardPolarity;
             2,4: result := ReversedPolarity;
             else result := Sham;
        end;
     end else begin
        case lOrder of
             2,5: result := Sham;
             1,3: result := ReversedPolarity;
             else result := StandardPolarity;
        end;
     end;
end;


function StdSham (lOrder,lSession: integer): TIO;  //order ab or ba
begin
    if ((lSession = 1) and (lOrder = 1)) or ((lSession <> 1) and (lOrder <> 1)) then
       result := StandardPolarity
    else
        result := Sham;
end;

function StdRev (lOrder,lSession: integer): TIO;  //order ab or ba
begin
    if ((lSession = 1) and (lOrder = 1)) or ((lSession <> 1) and (lOrder <> 1)) then
       result := StandardPolarity
    else
        result := ReversedPolarity;
end;

function MaxSession (lPrefs: TPrefs): integer;
begin
    Case lPrefs.Design of
         kStdSham,kStdRev: result := 2;
         kStdShamRev: result := 3;
         else begin
              Showmessage('Error: unknown design '+inttostr(lPrefs.Design));
              exit;
         end;
    end;//case
end;

function RandomDesign (lPrefs: TPrefs): TIO;
//TIO = (StandardPolarity,ReversedPolarity, Sham,Off);
var
   lRand,lSwap,lS,lnSess,lnOrder: integer;
   lOrderRA:  bytep;
begin
    result := Off; //error....
    //Design,nSubj,Seed,Subj,Session,StimSec,ShamSec
    lnSess := MaxSession(lPrefs);
    if (lPrefs.Session < 1) or (lPrefs.Session > lnSess) then begin
              Showmessage('Error: this design only describes 1..'+inttostr(lnSess)+' sessions.');
              exit;
    end;
    if (lPrefs.Subj < 1) or (lPrefs.Subj > lPrefs.nSubj) then begin
              Showmessage('Error: this design was counterbalanced for a maximum of '+inttostr(lPrefs.nSubj)+' participants.');
              exit;
    end;
    Case lnSess of
         2: lnOrder := 2;// ab, ba
         3: lnOrder := 6;//abc acb bac bca cab cba
         else begin
              Showmessage('Error with RandomDesign');
              exit;
         end;
    end;//case
    if (lPrefs.nSubj mod lnOrder) <> 0 then begin
       Showmessage('Error: for this design to be balanced the number of participants must be evenly divisible by '+inttostr(lnOrder));
       exit;
    end;
    randseed := lPrefs.Seed;
    getmem(lOrderRA,lPrefs.nSubj);
    //set up orders
    for lS := 1 to lPrefs.nSubj do
        lOrderRA^[lS] := lS mod lnOrder; // e.g. if lnOrder = 6 then 1,2,3,4,5,0
    //randomize orders
    for lS := lPrefs.nSubj downto 2 do begin
        lRand := (Random(lS)) + 1;
        lSwap := lOrderRA^[lRand];
        lOrderRA^[lRand] := lOrderRA^[lS];
        lOrderRA^[lS] := lSwap;
    end;
    Case lPrefs.Design of
         kStdSham : result := StdSham (lOrderRA^[lPrefs.Subj],lPrefs.Session);
         kStdRev : result := StdRev (lOrderRA^[lPrefs.Subj],lPrefs.Session);
         kStdShamRev: result := StdShamRev (lOrderRA^[lPrefs.Subj],lPrefs.Session);
    end;//case
    freemem(lOrderRA);
end;

end.
 