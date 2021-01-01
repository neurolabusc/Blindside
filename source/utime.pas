
unit utime;
interface
uses Windows, mmsystem;
type
TTicks = record
  PerformanceCounter: Int64;
  Ticks: DWord;
  end;
var
   gUsePerformanceCounter: boolean = false;

procedure GetTimeFreq (var Freq: int64; var Time: TTicks);
function MSelapsed (Freq: int64; StartTime: TTicks): Int64;



implementation

procedure GetTimeFreq (var Freq: int64; var Time: TTicks);
begin
  QueryPerformanceFrequency(Freq);
  QueryPerformanceCounter(Time.PerformanceCounter);
  Time.Ticks := timeGetTime;//GetTickCount;
end;

function MSelapsed (Freq: int64; StartTime: TTicks): Int64;
var
    endTime64: Int64;
begin
  if gUsePerformanceCounter then begin
     QueryPerformanceCounter(endTime64);
     result := round((endTime64 - StartTime.PerformanceCounter) / (Freq/1000));
  end else begin
     result := timeGetTime{GetTickCount}-StartTime.Ticks;
  end;
end;

initialization
 {initialization code goes here}
 timeBeginPeriod(1);
finalization
 {finalization code goes here}
  timeEndPeriod(1);
//Using timeGetTime is just like GetTickCount, but you will need to call timeBeginPeriod and timeEndPeriod if you need a resolution less than 10ms (the default).
//  sec := (timeGetTime-gStartTick)/1000;
end.
