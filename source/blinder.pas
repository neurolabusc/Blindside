unit blinder;

interface

uses
  prefs,adu,Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Buttons, ToolWin, ComCtrls, StdCtrls, ExtCtrls, Spin,utime, makerandom, Clipbrd,
  ThdTimer, tms_u, ucopydata;

type
  TMainForm = class(TForm)
    ToolBar1: TToolBar;
    Label3: TLabel;
    SubjEdit: TSpinEdit;
    Label4: TLabel;
    SessionEdit: TSpinEdit;
    StartBtn: TButton;
    SettingsBtn: TButton;
    PowerPanel: TPanel;
    Timer1: TTimer;
    TDCSBtn: TButton;
    ThreadedTimerold: TThreadedTimer;
    TMSBtn: TButton;
    //procedure ReadPrefs (var lPrefs: TPrefs);
    procedure SaveCore;
    procedure HaltStudy;
    procedure StartStandard;
    procedure StartTMS;
    procedure StartBtnClick(Sender: TObject);
    procedure SettingsBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TDCSBtnClick(Sender: TObject);
    procedure StartStop (lXRunning: boolean);
    procedure PowerPanelClick(Sender: TObject);
    procedure ThreadedTimeroldTimer(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure TMSBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses test, tmstest;



{$R *.DFM}
const
     kParticiapnts = 12;

var
   gXrunning: boolean = false;
   (*gDemoRA: array[1..kParticiapnts,1..2] of boolean =
    (
    (false,true), //1
    (true,false), //2
    (true,false), //3
    (true,false),//4
    (false,true),//5
    (true,false),//6
    (false,true),//7
    (false,true),//8
    (false,true),//9
    (true,false),//10
    (false,true),//11
   (true,false)

    );
   gRA: array[1..kParticiapnts,1..2] of boolean =
    (
    (true,false), //1   tdcs 1st
    (false,true), //2
    (false,true), //3
    (true,false),//4   tdcs first
    (false,true),//5
    (true,false),//6  tdcs first
    (true,false),//7  tdcs first
    (false,true),//8
    (true,false),//9  tdcs first
    (false,true),//10
    (true,false),//11
   (false,true)

    );  *)
   gStimEndMSec,gXEndMSec,gFreq: int64;
   gXStart: tTicks;

   function AppDir: string; //e.g. c:\folder\ for c:\folder\myapp.exe, but /folder/myapp.app/ for /folder/myapp.app/app
begin
 result := extractfilepath(paramstr(0));
end;

function AppIniFilename: string;
//var lPath,lName,lExt: string;
begin
  //FilenameParts (Paramstr(0), lPath,lName,lExt );
  result := AppDir+ 'tdcs.ini'
end;


procedure ReadPrefs(var lPrefs: TPrefs);
begin
     SettingsForm.SetDefaultPrefs(lPrefs);
     lPrefs.Subj := MainForm.SubjEdit.value;
     lPrefs.Session := MainForm.SessionEdit.value;
     lPrefs.StimSec := SettingsForm.StimSecEdit.value;
     lPrefs.ShamSec := SettingsForm.ShamSecEdit.value;
     lPrefs.Design := SettingsForm.DesignDrop.ItemIndex;
     lPrefs.Seed :=    SettingsForm.SeedEdit.value;
     lPrefs.nSubj := SettingsForm.nSubjEdit.value;
     lPrefs.Mode := SettingsForm.ModeEdit.value;
     lPrefs.TMSratems := SettingsForm.TMSratemsEdit.value;
     lPrefs.TMSinterlockms := SettingsForm.TMSinterlockmsEdit.value;
     //lPrefs.TMSphasems := SettingsForm.TMSphasemsEdit.value;
     //lPrefs.TMSOnms := SettingsForm.TMSOnmsEdit.value;
     //lPrefs.TMSOffms := SettingsForm.TMSOffmsEdit.value;
     lPrefs.UsePerformanceCounter :=  SettingsForm.UsePerformanceCounterCheck.Checked;
     lPrefs.TMSHotKey := TMSTestForm.PulseBtn.tag;
     lPrefs.HitHotKey := TMSTestForm.HitBtn.tag;
     lPrefs.MissHotKey := TMSTestForm.MissBtn.tag;
     lPrefs.TMSSequence := SettingsForm.TMSSequenceEdit.text;
     ValidTMSSequence (lPrefs.TMSSequence);
     SettingsForm.TMSSequenceEdit.text := lPrefs.TMSSequence;
     
end;

procedure WritePrefs(lPrefs: TPrefs);
begin
    TMSTestForm.PulseBtn.tag := lPrefs.TMSHotKey ;
    TMSTestForm.HitBtn.tag := lPrefs.HitHotKey ;
    TMSTestForm.MissBtn.tag := lPrefs.MissHotKey ;

    MainForm.SubjEdit.value := lPrefs.Subj;
    MainForm.SessionEdit.value := lPrefs.Session;
    with SettingsForm do begin
         SettingsForm.DesignDrop.ItemIndex := lPrefs.Design;
         SettingsForm.StimSecEdit.value := lPrefs.StimSec;
         SettingsForm.ShamSecEdit.value := lPrefs.ShamSec;
         SeedEdit.value := lPrefs.Seed;
         nSubjEdit.value := lPrefs.nSubj;
         ModeEdit.value := lPrefs.Mode;
         TMSratemsEdit.value := lPrefs.TMSratems;
         TMSinterlockmsEdit.value := lPrefs.TMSinterlockms;
         //TMSphasemsEdit.value := lPrefs.TMSphasems;
         //TMSOnmsEdit.value := lPrefs.TMSOnms;
         //TMSOffmsEdit.value := lPrefs.TMSOffms;
         SettingsForm.TMSSequenceEdit.text := lPrefs.TMSSequence;
         UsePerformanceCounterCheck.Checked := lPrefs.UsePerformanceCounter;
    end;
    gUsePerformanceCounter := lPrefs.UsePerformanceCounter;
end;

procedure TMainForm.SettingsBtnClick(Sender: TObject);
var
   lPrefs: TPrefs;
begin
     ReadPrefs(lPrefs);
     SettingsForm.TMSpanel.visible := (lPrefs.Mode =  kTMSMode);
     SettingsForm.showmodal;
     if SettingsForm.ModalResult = mrCancel then
        WritePrefs(lPrefs);
     ReadPrefs(lPrefs);
     RandomDesign (lPrefs);
end;

procedure TMainForm.StartStop (lXRunning: boolean);
begin
     TDCSBtn.enabled := not lXRunning;
     TMSBtn.enabled := not lXRunning;
     SettingsBtn.enabled := not lXRunning;
     SubjEdit.enabled := not lXRunning;
     SessionEdit.enabled := not lXRunning;
     if lXRunning then
        StartBtn.Caption := 'Halt study'
     else
         StartBtn.Caption := 'Start study';
     if lXRunning then
        PowerPanel.Color := clYellow
     else
         PowerPanel.Color := clBtnFace;
     if not lXRunning then
         PowerPanel.Caption := 'Study not started';
end;

procedure TMainForm.SaveCore;
var
 lSec: integer;
 lFilename: string;
 lPrefs: TPrefs;
begin
     lSec := round(MSelapsed(gFreq,gXStart) / 1000);
     ReadPrefs(lPrefs);
     lFilename :=  extractfiledir(paramstr(0))+'\'+inttostr(lPrefs.Subj)+'_'+inttostr(lPrefs.Session)+'_'+ (FormatDateTime('yyyymmdd_hhnnss', (now)))+'_'+inttostr(lSec)+'.txt';
  SettingsForm.IniFilex(false, lFilename, lPrefs);
end;

procedure TMainForm.HaltStudy;
var lTMS: boolean;
i: integer;
begin
     //lTMS := ThreadedTimer1.Enabled;
     Timer1.enabled := false;
     //ThreadedTimer1.Enabled := false;
     (*if lTMS then begin
              //stop previous recording...
        i := SendDataDigit(kStopRecording, MainForm);
        if i < 0 then
          Showmessage('Please manually stop EMG acquisition.');
     end;*)
     if (gXrunning) and (MSelapsed(gFreq,gXStart) > 10000) then
        SaveCore;
     gXrunning := false;
     StartStop(gXRunning);
     PortOutx(off);
end;

procedure TMainForm.StartStandard;
var
   lCond: TIO;
   lPrefs: TPrefs;
   lMax: integer;
begin
     ReadPrefs(lPrefs);
     if gXrunning then begin
        HaltStudy;
        exit;
     end;
     lCond := RandomDesign (lPrefs);
     if lCond = off then
        exit;
     //check session number is in range...
     if lPrefs.Design = 2 then
        lMax := 3
     else
         lMax := 2;
     if (lPrefs.Session < 1) or (lPrefs.Session > 3) then begin
        showmessage('Error: Participant session must be between 1 and '+inttostr(lMax));
        exit;
     end;
     if (lPrefs.Subj < 1) or (lPrefs.Subj > lPrefs.nSubj) then begin
        showmessage('Error: Participant number must be 1 to'+inttostr(lPrefs.nSubj));
        exit;
     end;
     if lPrefs.StimSec < 1 then begin
        showmessage('At least 1 second of stimulation required.');
        exit;
     end;
     gXrunning := true;
     StartStop(gXRunning);
     gStimEndMSec := lPrefs.StimSec*1000;
     gXEndMSec := lPrefs.StimSec*1000;
     if lCond = Sham then
        gStimEndMSec := lPrefs.ShamSec * 1000;
     if lCond = ReversedPolarity then
          PortOutx(ReversedPolarity)
     else if (lCond = Sham) and (lPrefs.ShamSec < 1) then
        PortOutx(Sham)
     else
        PortOutx(StandardPolarity);
     GetTimeFreq(gFreq,gXStart);
     Timer1.enabled := true;
     Timer1.tag := 999;
end;

procedure TMainForm.StartBtnClick(Sender: TObject);
var
   lPrefs: TPrefs;
begin
     ReadPrefs(lPrefs);
     if lPrefs.Mode = kTMSmode then
        StartTMS
     else
         StartStandard;
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
var
   lElapsedMsec: Int64;
begin
     lElapsedMsec := MSelapsed(gFreq,gXStart);
     if (lElapsedMsec > gStimEndMSec) and (lElapsedMsec <= gXEndMSec) then
        PortOutx(sham);

     Timer1.tag := Timer1.tag + Timer1.interval;
     if Timer1.tag >= 1000 then begin
        POwerPanel.Caption := inttostr((gXEndMSec-lElapsedMsec) div 1000);
        Timer1.tag := 0;
     end;
     if lElapsedMsec > gXEndMSec then
        HaltStudy;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
   lPrefs: TPrefs;
begin
     Portoutx(off);
     SettingsForm.IniFilex(true, AppIniFilename, lPrefs);
     if lPrefs.Mode <> 1 then
      TMSbtn.visible := false;
     WritePrefs(lPrefs);

end;


procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
var
   lPrefs: TPrefs;
begin
     ReadPrefs (lPrefs);
  SettingsForm.IniFilex(false, AppIniFilename, lPrefs);
end;

procedure TMainForm.TDCSBtnClick(Sender: TObject);
var
   lPrefs: TPrefs;
begin
     ReadPrefs(lPrefs);
  tDCSTestForm.Top := MainForm.Top;
  tDCSTestForm.Left := MainForm.Left;

     tDCSTestForm.showmodal;
end;

procedure TMainForm.PowerPanelClick(Sender: TObject);
const
 kT = chr(9);
var
   lPrefs: TPrefs;
   lStrings: TStrings;
   lSL: TStringList;
   lS: string;
   Count,lSubj,lSess: integer;
   lCond: TIO;
begin
     lS := '42';
     InputQuery('Enter passcode', 'Enter passcode to decrypt trial order', lS);
     if lS <> 'abba' then
        exit;
     ReadPrefs(lPrefs);
     lStrings := TStringList.Create;
     for lSubj := 1 to lPrefs.nSubj do begin
         lS := inttostr(lSubj);
         for lSess := 1 to MaxSession(lPrefs) do begin
             lPrefs.Subj := lSubj;
             lPrefs.Session := lSess;
             lCond := RandomDesign(lPrefs);
             case lCond of
                  StandardPolarity: lS := lS+kT+'StandardPolarity';
                  ReversedPolarity: lS := lS+kT+'ReversedPolarity';
                  Sham : lS := lS+kT+'Sham';
             end;
         end;//for nSess
         lStrings.Add(lS);
     end;//for nSubj
     Clipboard.AsText:= lStrings.Text;
     lStrings.Free;
end;

//var gElapsedMsec: integer;

(*procedure TMainForm.StartTMS;
const
  kTab = chr(9);
var
   i: integer;
   lPrefs: TPrefs;
   lStrings: TStringList;
   lFilename: string;
begin
     if gXrunning then begin
        HaltStudy;
        exit;
     end;
     ReadPrefs(lPrefs);
     //stop previous recording...
     i := SendDataDigit(kStopRecording, MainForm);
     if i < 0 then
        Showmessage('Unable to communicate with '+kReceiverName+'. Please make sure '+kReceiverName+' is running before starting this program.');
     PortOutx(sham);
     Showmessage('TMS mode: OnMS='+lPrefs.TMSSequence+' TMSrateMS='+inttostr(lPrefs.TMSratems)+ ' Start the tDCS/open MobiRecord and then click OK.');
     //start new recording...
     i := SendDataDigit(kStartRecording, MainForm);
     if i < 0 then
        Showmessage('Unable to enable Mobi recorder');
     BuildEvents (lPrefs);
     if length(gEventRA) < 1 then begin
      showmessage('Error with setup.');
      exit;
     end;
     lStrings := TStringList.Create;
     for i := 0 to  length(gEventRA)-1 do begin
        lStrings.Add(inttostr(gEventRA[i].OnsetMS)+ kTab+ PortToStr (gEventRA[i].Port)+kTab+inttostr(gEventRA[i].Cond));
     end;

     lFilename :=  extractfiledir(paramstr(0))+'\tms_'+inttostr(lPrefs.Subj)+'_'+inttostr(lPrefs.Session)+'_'+ (FormatDateTime('yyyymmdd_hhnnss', (now)))+'.tab';
     lStrings.SaveToFile(lFilename);
     Clipboard.AsText := lStrings.Text; //
     lStrings.free;
     gXrunning := true;
     StartStop(gXRunning);
     ThreadedTimer1.Tag := 0;
      PortOutx(sham);
           GetTimeFreq(gFreq,gXStart);
                gXEndMSec := lPrefs.StimSec*1000;
     ThreadedTimer1.Enabled := true;
     gElapsedMSec := 0;
end;*)

procedure TMainForm.StartTMS;
var
  lSecCount, lEvent: integer;
function TimeToQuit : boolean;
var
   lElapsedMsec: Int64;
begin
     result := true;
     lElapsedMsec := MSelapsed(gFreq,gXStart);
     if (not gXRunning) or (lEvent >= length(gEventRA)) or (lElapsedMsec > gXEndMSec) then
        exit;//make sure we do not read beyond end of array
     result := false;
     if lElapsedMsec >= gEventRA[lEvent].OnsetMS then begin
      PortOutx(gEventRA[lEvent].Port);
      //caption := inttostr(lElapsedMSec);
      if gEventRA[lEvent].Cond > 0 then begin
        //Caption := inttostr(gEventRA[ThreadedTimer1.tag].Cond)+'  '+inttostr(lElapsedMsec);
        SendDataDigit(gEventRA[lEvent].Cond, MainForm);
      end;
      //Caption := PortToStr (gEventRA[ThreadedTimer1.tag].Port);
      inc(lEvent);
     end;
     //if (lElapsedMsec mod 50) = 0 then
     // application.ProcessMessages;
     if (lElapsedMsec - lSecCount) > 999 then begin
        lSecCount := lElapsedMsec;
        POwerPanel.Caption := inttostr((gXEndMSec-lElapsedMsec) div 1000);
     end;
end;
const
  kTab = chr(9);
var
   i: integer;
   lPrefs: TPrefs;
   lStrings: TStringList;
   lFilename: string;
begin
     if gXrunning then begin
        HaltStudy;
        exit;
     end;
     ReadPrefs(lPrefs);
     //stop previous recording...
     i := SendDataDigit(kStopRecording, MainForm);
     if i < 0 then
        Showmessage('Unable to communicate with '+kReceiverName+'. Please make sure '+kReceiverName+' is running before starting this program.');
     PortOutx(sham);
     Showmessage('TMS mode: OnMS='+lPrefs.TMSSequence+' TMSrateMS='+inttostr(lPrefs.TMSratems)+ ' Start the tDCS/open MobiRecord and then click OK.');
     //start new recording...
     i := SendDataDigit(kStartRecording, MainForm);
     if i < 0 then
        Showmessage('Unable to enable Mobi recorder');
     BuildEvents (lPrefs);
     if length(gEventRA) < 1 then begin
      showmessage('Error with setup.');
      exit;
     end;
     lStrings := TStringList.Create;
     for i := 0 to  length(gEventRA)-1 do begin
        lStrings.Add(inttostr(gEventRA[i].OnsetMS)+ kTab+ PortToStr (gEventRA[i].Port)+kTab+inttostr(gEventRA[i].Cond));
     end;
     lFilename :=  extractfiledir(paramstr(0))+'\tms_'+inttostr(lPrefs.Subj)+'_'+inttostr(lPrefs.Session)+'_'+ (FormatDateTime('yyyymmdd_hhnnss', (now)))+'.tab';
     lStrings.SaveToFile(lFilename);
     Clipboard.AsText := lStrings.Text; //
     lStrings.free;
     gXrunning := true;
     StartStop(gXRunning);
     lEvent := 0;
     PortOutx(sham);
     GetTimeFreq(gFreq,gXStart);
     gXEndMSec := lPrefs.StimSec*1000;
     lSecCount := 0;
     //ThreadedTimer1.Enabled := true;
     //gElapsedMSec := 0;
     while (not TimeToQuit) do begin
        sleep(1);
        application.ProcessMessages;
     end;
     HaltStudy;
        i := SendDataDigit(kStopRecording, MainForm);
        if i < 0 then
          Showmessage('Please manually stop EMG acquisition.');
end;

procedure TMainForm.ThreadedTimeroldTimer(Sender: TObject);
begin
(*var
   i,lElapsedMsec: Int64;
begin
     lElapsedMsec := MSelapsed(gFreq,gXStart);
      if ThreadedTimer1.tag >= length(gEventRA) then
        HaltStudy;//make sure we do not read beyond end of array
     if lElapsedMsec >= gEventRA[ThreadedTimer1.tag].OnsetMS then begin
      PortOutx(gEventRA[ThreadedTimer1.tag].Port);
      if gEventRA[ThreadedTimer1.tag].Cond > 0 then begin
        Caption := inttostr(gEventRA[ThreadedTimer1.tag].Cond)+'  '+inttostr(lElapsedMsec);
        SendDataDigit(gEventRA[ThreadedTimer1.tag].Cond, MainForm);
      end;
      ThreadedTimer1.tag := ThreadedTimer1.tag + 1;
     end;
     if (lElapsedMsec > gXEndMSec) then  begin
        HaltStudy;
     end;
     if (lElapsedMsec - gElapsedMsec) > 999 then begin
        gElapsedMSec := lElapsedMsec;
        //if (gXx mod 1000) = 10 then// {(lElapsedMsec mod 1000) = 10 then
        POwerPanel.Caption := inttostr((gXEndMSec-lElapsedMsec) div 1000);
     end;*)
end;

procedure TMainForm.Button1Click(Sender: TObject);
var
  i: integer;
begin
     i := SendDataDigit(kStopRecording, MainForm);
     if i < 1 then
      showmessage('Unable to contact '+kReceiverName);
end;

procedure TMainForm.TMSBtnClick(Sender: TObject);
var
   lPrefs: TPrefs;
begin
  ReadPrefs(lPrefs);
  TMSTestForm.Top := MainForm.Top;
  TMSTestForm.Left := MainForm.Left;
  TMSTestForm.showmodal;
end;

end.
