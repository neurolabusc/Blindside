unit tms_u;

interface
uses sysutils, adu,Prefs, dialogs,deb;
const
  kMaxEvent = 10000;
type


TEvent = record
         OnsetMS,Cond: integer;
         Port: TIO;
  end;
EventRA = array  of TEvent;

procedure BuildEvents (lPrefs: TPrefs);
procedure ValidTMSSequence (var lSequence: string);

var gEventRA: EventRA;

implementation

procedure ValidTMSSequence (var lSequence: string);

label 777;

var
  s: string;
  i,len: integer;
begin
  len := length(lSequence);
  if len < 1 then
    goto 777;
  for i := 1 to len do
    if upcase(lSequence[i]) in ['S','A','C'] then
      s := s + upcase(lSequence[i]);
  if s = '' then
    goto 777;
  lSequence := s;
  exit;
  777:
  lSequence := kDefSeq;
  Showmessage('Unable to interpret TMSsequence. Reverting to '+kDefSeq);
end;

procedure BuildEvents (lPrefs:TPrefs);
label
  999;
var
  lCurrentPort : TIO;
  Event,TotalMS, ltime,condpos, replen : integer;
  seq: string;
begin
  lCurrentPort := Sham;
  TotalMS := lPrefs.StimSec * 1000;
  seq := lPrefs.TMSSequence;
  ValidTMSSequence (seq);
  replen := length(seq);
  if replen < 1 then begin
    showmessage('Unable to interpret this sequence.');
    exit;
  end;
  if (lPrefs.TMSinterlockms < 1) or (lPrefs.TMSratems < 100) then begin
    Showmessage('TMS rate or interlock are too fast.');
    exit;
  end;
  if (lPrefs.TMSinterlockms *3) > lPrefs.TMSratems then begin
    Showmessage('TMS interlock too long.');
    exit;
  end;
  Event :=  (TotalMS div lPrefs.TMSratems);
  if Event < 1 then begin
    Showmessage('Experiment duration too short.');
    exit;
  end;
  //get worst case scenario memory....
  SetLength (gEventRA,(Event*4)+1);//each block has onset,interlock,tms,interlock
  for condpos := 0 to (Event*4) do
    gEventRA[Event].Cond := 0;
  condpos := 1;
  Event := 0;
  ltime := 0;
  while true do begin

      if (condpos < 2) or (seq[condpos]<>seq[condpos-1]) then begin
        //new block type
        //if condpos > 0 then
        //owmessage(seq[condpos]+':'+seq[condpos-1]);


        //owmessage(seq[condpos]+'  '+inttostr(lTime) );
        case seq[condpos] of
          'A': lCurrentPort := StandardPolarity;
          'C': lCurrentPort := ReversedPolarity;
          else lCurrentPort := Sham;
        end;
        gEventRA[Event].OnsetMS := lTime;
        gEventRA[Event].Port := lCurrentPort;

        inc(Event);
      end;

      //add TMS pulses...
      gEventRA[Event].OnsetMS := lTime+(lPrefs.TMSratems div 2)-lPrefs.TMSinterlockms ;
      gEventRA[Event].Port := Sham;
      inc(Event);

      gEventRA[Event].OnsetMS := lTime+(lPrefs.TMSratems div 2);
      gEventRA[Event].Port := TMS;
      gEventRA[Event].Cond := condpos;
      inc(Event);

      gEventRA[Event].OnsetMS := lTime+(lPrefs.TMSratems div 2)+lPrefs.TMSinterlockms ;
      gEventRA[Event].Port := lCurrentPort;
      inc(Event);

      inc(condpos);
      if condpos > replen then
        condpos := 1;
      //increment time
      lTime := lTime + lPrefs.TMSratems;
      if lTime >= TotalMS then
        goto 999;
    end; //while true .... forever
    999:
    gEventRA[Event].OnsetMS := lTime;
    gEventRA[Event].Port := Sham;
    inc(Event);
  SetLength (gEventRA,Event);//each block has onset,interlock,tms,interlock


end;

(*procedure BuildEvents (lPrefs: TPrefs);
const
  kMaxCond = 2;
var
  TMScond, TMSOffTime,Event,Time,Cond,Loop,NextTMS,NextTDCS,o,TotalMS: integer;
  lCurrentPort : TIO;
begin

  TotalMS := lPrefs.StimSec * 1000;
  if (TotalMS < 1000) then begin
    Showmessage('Experiment too short.');
    exit;
  end;
  if (lPrefs.TMSinterlockms < 1) or (lPrefs.TMSratems < 100) then begin
    Showmessage('TMS rate or interlock are too fast.');
    exit;
  end;
  if (lPrefs.TMSphasems < 0) or (lPrefs.TMSphasems >= lPrefs.TMSratems) then begin
    Showmessage('TMS phase does not make sense.');
    exit;
  end;
  if (lPrefs.TMSOnMS < 100) or (lPrefs.TMSOffMS < 100) then begin
      showmessage('tDCS periods too brief');
      exit;
  end;

  for Loop := 1 to 2 do begin
    Event := 0;
    Cond := kMaxCond;
    TMScond := 18;//yuck - this is not flexible for first sequence
    lCurrentPort := Sham;
    NextTMS :=  lPrefs.TMSphasems-(lPrefs.TMSinterlockms div 2);
    NextTDCS := lPrefs.TMSOffMS;
    for Time := 0 to TotalMS do begin

      if Time > NextTDCS then begin
        inc(Cond);
        if Cond > kMaxCond then begin
          Cond := 1;
          TMSCond := 1;
        end;
        case Cond of
          1,3: lCurrentPort := StandardPolarity;
          5,7: lCurrentPort := ReversedPolarity;
          else lCurrentPort := Sham;
        end;
        if lCurrentPort = Sham then
          NextTDCS := NextTDCS + lPrefs.TMSOffMS
        else
          NextTDCS := NextTDCS + lPrefs.TMSOnMS;
        if Loop = 2 then begin
          gEventRA[Event].OnsetMS := Time;
          gEventRA[Event].Port := lCurrentPort;
          case lCurrentPort of
            StandardPolarity:  gEventRA[Event].Cond := -2;
            ReversedPolarity:  gEventRA[Event].Cond := -3;
            else  gEventRA[Event].Cond := -1;
           end;//case
        end;
        inc(Event);
      end; //new tDCS
      if Time > NextTMS then begin
        inc(TMScond);
        //fx(666, NextTMS,lPrefs.TMSratems);
        NextTMS := NextTMS + lPrefs.TMSratems;
        //check for errors on first pass ....
        TMSOffTime := Time+({Cond*}lPrefs.TMSinterlockms);
        if TMSOffTime < (Time+1) then begin
            showmessage('Error calculating experiment');
            exit;
        end;
        if (TMSOffTime >= NextTDCS) then begin
            showmessage('TMS pulses overlap TDCS transitions.');
            exit;
        end;
        //load data on 2nd pass
        if Loop = 2 then begin
          //first - stop tDCS prior to TMS
          gEventRA[Event].OnsetMS := Time;
          gEventRA[Event].Port := Sham;
          //second - send TMS pulse
          gEventRA[Event+1].OnsetMS := Time+(lPrefs.TMSinterlockms div 2);
          gEventRA[Event+1].Port := TMS;
          gEventRA[Event+1].Cond := TMScond;
          //third - turn back on tDCS
          gEventRA[Event+2].OnsetMS := Time+(lPrefs.TMSinterlockms)-1;
          gEventRA[Event+2].Port := AddOpticalTrigger(lCurrentPort);
          //fourth - switch off trigger
          gEventRA[Event+3].OnsetMS := TMSOffTime;
          gEventRA[Event+3].Port := lCurrentPort;
        end; //2nd loop
        Event := Event + 4;
      end;//New TMS
    end; //for time
    if Loop = 1 then begin
      SetLength (gEventRA,Event);
      for o := 0 to (Event-1) do
        gEventRA[o].Cond := 0;
    end;
  end;

end;*)



end.
 