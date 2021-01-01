unit tmstest;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls,utime,adu,questtypes,quest;

type
  TTMSTestForm = class(TForm)
    IntenLabel: TLabel;
    TMSsetup: TPanel;
    HotKeyBtn: TButton;
    TMSTestbtn: TButton;
    InitialEstEdit: TEdit;
    Label2: TLabel;
    GuessEdit: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    ThreshEdit: TEdit;
    SDEdit: TEdit;
    Label5: TLabel;
    StartStairBtn: TButton;
    OKBtn: TButton;
    CancelBtn: TButton;
    HitBtn: TButton;
    MissBtn: TButton;
    PulseBtn: TButton;
    procedure TMSpulse;
    procedure HotKeyBtnClick(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure StaircaseBtnsClick(Sender: TObject);
    procedure StartStairBtnClick(Sender: TObject);
    procedure TMSTestbtnClick(Sender: TObject);
  private
    { Private declarations }
        FHookStarted : Boolean; 
  public
    { Public declarations }
  end;

var
  TMSTestForm: TTMSTestForm;

implementation

uses setkey;

{$R *.dfm}

var
   gFreqX: int64;
   gXStartX: tTicks;
  gLastKey: integer;//UINT;
  JHook: THandle;
const
  kMinPulseRep = 1000;

Procedure Pause (lMS: integer);
var
  lendtime : DWord;
  nowTime64, endTime64, frequency64: Int64;
begin
  if not gUsePerformanceCounter then begin
    lEndTime := GetTickCount+ lMS;
    repeat
      Application.processmessages;
      sleep(1);
    until GetTickCount >= lEndTime;
    exit;
  end;
  QueryPerformanceFrequency(frequency64);
  QueryPerformanceCounter(nowTime64);
  endTime64 := lMS;
  endTime64 :=  nowTime64 + round(frequency64/1000*endTime64);
  repeat
    Application.processmessages;
    sleep(1);
    QueryPerformanceCounter(nowTime64);
  until nowTime64 >= endTime64;
end;

function JournalProc(Code, wParam: Integer; var EventStrut: TEventMsg): Integer; stdcall;
var
  //Char1: PChar;
  s: string;
begin
  {this is the JournalRecordProc}
  Result := CallNextHookEx(JHook, Code, wParam, Longint(@EventStrut));
  {the CallNextHookEX is not really needed for journal hook since it it not
  really in a hook chain, but it's standard for a Hook}
  if Code < 0 then Exit;
  {you should cancel operation if you get HC_SYSMODALON}
  if Code = HC_SYSMODALON then Exit;
  if Code = HC_ACTION then
  begin
    s := '';
    if EventStrut.message = WM_KEYDOWN THEN begin
      //s := intToStr(EventStrut.paraml)+'kEY= '+intToStr(EventStrut.paramH)+'  '+inttostr(TMSTestForm.HotKeyBtn.tag);
      gLastKey := EventStrut.paraml;
      //TMSTestForm.caption := inttostr(gLastKey)+' '+inttostr(EventStrut.paraml)+'  '+inttostr(TMSTestForm.HotKeyBtn.tag);

      if {EventStrut.paraml}gLastKey = TMSTestForm.PulseBtn.tag then
        TMSTestForm.TMSpulse;
    end;
  end;
end;

procedure TTMSTestForm.TMSpulse;
var
  r: integer;
begin
   if MSelapsed(gFreqX,gXStartX) < kMinPulseRep then begin
    caption := 'Too fast';
    beep;
    exit;
   end;
   beep;
   GetTimeFreq(gFreqX,gXStartX);

     PortOutX(Sham);
     pause(5);
     PortOutX(TMS);
     if random(2)=1 then
      r := 5
     else
      r := 500;
     caption := inttostr(r)+'  '+inttostr(random(888));
      pause(r);
     PortOutX(Sham);
end;

procedure TTMSTestForm.HotKeyBtnClick(Sender: TObject);
label
  111,222;
begin
  setkeyform.Label1.caption := 'Press TMS key';
  setkeyform.showmodal;
  PulseBtn.Tag := gLastKey;
  //showmessage(inttostr(gLastKey)+' ' +inttostr(HotKeyBtn.Tag));
  //showmessage(inttostr(gLastKey)+' ' +inttostr(HotKeyBtn.Tag));
111:

  setkeyform.Label1.caption := 'Press hit key';
  setkeyform.showmodal;
  if (gLastKey = PulseBtn.Tag) then
    goto 111;
  HitBtn.Tag := gLastKey;
222:
  setkeyform.Label1.caption := 'Press miss key';
  setkeyform.showmodal;
  if (gLastKey = PulseBtn.Tag) or (gLastKey = HitBtn.Tag) then
    goto 222;

  MissBtn.Tag := gLastKey;
  //showmessage(inttostr(gLastKey)+' ' +inttostr(HotKeyBtn.Tag));
end;

procedure TTMSTestForm.FormHide(Sender: TObject);
begin
     if FHookStarted then
    UnhookWindowsHookEx(JHook);
    FHookStarted := false;
end;

procedure TTMSTestForm.FormShow(Sender: TObject);
begin
     GetTimeFreq(gFreqX,gXStartX);
  if FHookStarted then
    Exit;
  JHook := SetWindowsHookEx(WH_JOURNALRECORD, @JournalProc, hInstance, 0);
  {SetWindowsHookEx starts the Hook}
  if JHook > 0 then
  begin
    FHookStarted := True;
  end else
    ShowMessage('No Journal Hook availible');
end;

procedure TTMSTestForm.StaircaseBtnsClick(Sender: TObject);
begin
  gLastKey := (Sender as TButton).Tag;
end;

procedure TTMSTestForm.StartStairBtnClick(Sender: TObject);
label
  666;
var
  s: tstrings;
  str: string;
mean,prevmean,sd,tTest,beta,delta: TFloatType;
  q: TQuest;
  i,n: integer;
begin
TMSSetup.visible := false;

  n := 60;//strtoint(NumEdit.text);

  if n < 1 then
    exit;
  beta:=3.5;delta:=0.01;
  QuestCreate(q,strtofloat(InitialEstEdit.text)/100,strtofloat(SDEdit.text),strtofloat(ThreshEdit.text),beta,delta,strtofloat(GuessEdit.text));

  tTest:=0.8;
  QuestUpdate(q,tTest,true);
  tTest:=0.2;
  QuestUpdate(q,tTest,false);
  prevmean := (QuestMean(q))* 100;
  for i := 1 to n do begin
      gLastKey := -666;
      tTest:=QuestQuantile(q);
      //if MsgOK('Was trial '+inttostr(i)+' at intensity '+inttostr(round(tTest*100))+' detected?') then begin
      //next show trial
      beep;
      IntenLabel.caption := inttostr(round(tTest*100));
      repeat
        sleep(1);
        application.processmessages;
      until (gLastKey = HitBtn.Tag) or (gLastKey = MissBtn.Tag) or (gLastKey = CancelBtn.Tag);
      if (gLastKey = CancelBtn.Tag) then
        goto 666;
      if (gLastKey = HitBtn.Tag) then begin
        QuestUpdate(q,tTest,true);
        Str := '+';
      end else begin
        QuestUpdate(q,tTest,false);
        Str := '-';
      end;
      sd :=  QuestSd(q)* 100;
      mean := (QuestMean(q))* 100;

      caption := (inttostr(i)+'@'+inttostr(round(tTest*100))+str+' SD:'+inttostr(round(sd))  +' Mean:'+floattostr(round(mean)));
      if (sd < 1) or (abs(prevmean-mean)< 1.5) then
        goto 666;
      prevmean := mean;
  end;

666:
s:= TStringList.create;
QuestBetaAnalysis(q,s);
//Memo1.lines.AddStrings(s);
s.free;
TMSSetup.visible := true;
end;

procedure TTMSTestForm.TMSTestbtnClick(Sender: TObject);
begin
TMSpulse;
end;

end.
