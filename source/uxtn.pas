unit uxtn;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, Buttons, ToolWin, ComCtrls, StdCtrls, Spin, Menus,adu, MMTimer;

type
  TMainForm = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    Settings1: TMenuItem;
    Adjust1: TMenuItem;
    Experiment1: TMenuItem;
    ResponseMenu: TMenuItem;
    NextTrial1: TMenuItem;
	SaveDialog1: TSaveDialog;
    Help1: TMenuItem;
    About1: TMenuItem;
    HardwareTest1: TMenuItem;
    Showtrialtypes1: TMenuItem;
    RespTimer: TMMTimer;
    Left1: TMenuItem;
    Right1: TMenuItem;
    Abort1: TMenuItem;
    Statisitics1: TMenuItem;
    OpenDialog1: TOpenDialog;
    Eyemove1: TMenuItem;
    Image1: TImage;
    ResponseMemo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure ShowTrial(lPort: integer) ;
    procedure SaveCore;
    procedure Adjust1Click(Sender: TObject);
    procedure StartStudy(Sender: TObject);
    procedure ShowStats;
    procedure PresentTrial(lBlock,lTrial,lCond,lTarTime: integer);
    procedure Exit1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure HardwareTest1Click(Sender: TObject);
    procedure Showtrialtypes1Click(Sender: TObject);
    procedure NextTrial1Click(Sender: TObject);
    procedure RespTimerTimer(Sender: TObject);
    procedure Left1Click(Sender: TObject);
    procedure Right1Click(Sender: TObject);
    procedure AbortClick(Sender: TObject);
    procedure Statisitics1Click(Sender: TObject);
    procedure Eyemove1Click(Sender: TObject);
    //function ExperimentRunning: boolean;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses settings, hwtest;

{$R *.DFM}

const
     kMaxTrial = 1024;
     kHdr = '#Name, Trial,  Cond,  Time,  Resp,   lRT,   rRT,  lVal,  rVal,  Block,   Eye';
     gAbort: boolean = true;
var gLeftBtn,gRightBtn,gStartTime,gTargetOffTime: DWord;
    gEyeMove : integer;
    gNextTrial: boolean;
    gCondOrderRA: array [1..kMaxTrial] of integer;

function ExperimentRunning: boolean;
begin
     result := false;
     if gAbort then exit; //no X running
     Showmessage('You must finish or abort the experiment before completing other actions.');
     result := true;
end;

function PadStr (lValIn, lPadLenIn: integer): string;
var lOrigLen,lPad : integer;
begin
 lOrigLen := length(inttostr(lValIn));
 result := inttostr(lValIn);
 if lOrigLen < lPadLenIn then begin
    lOrigLen := lPadLenIn-lOrigLen;
    for lPad := 1 to lOrigLen do
        result := ' '+result;
 end;
end;

function PadStrComma(lValIn,lPadLenIn: integer): string;
begin
    result := PadStr(lValIn,lPadLenIn)+',';
end;

function InitBlock : integer; //returns number of trials in block
var
	lCond,lTrial, lTcount, lSwap, lRand: integer;
begin
        result := 0;
        for lCond := 1 to knCond do begin
            if gCondRA[lCond].RepsPerBlock > 0 then begin
               if (Result+gCondRA[lCond].RepsPerBlock) > kMaxTrial then begin
                   result := -1;
                   Showmessage('Too many trials per block.');
                   exit;
               end;
               for lTrial := (result + 1) to (result+gCondRA[lCond].RepsPerBlock) do
                   gCondOrderRA[lTrial] := lCond;
               result := result + gCondRA[lCond].RepsPerBlock;
            end; //>0 trials
        end;
	for lTCount := Result downto 1 do begin
		lRand := (Random(lTCount)) + 1;
		lSwap := gCondOrderRA[lRand];
		gCondOrderRA[lRand] := gCondOrderRA[lTCount];
		gCondOrderRA[lTCount] := lSwap;
	end;
end;

procedure ClearStats;
var
   lCond: integer;
begin
     for lCond := 1 to knCond do begin
         gCondRA[lCond].nTrials := 0;
         gCondRA[lCond].nLeftValid := 0;
         gCondRA[lCond].nRightValid := 0;
     end;
end;

procedure CompileStats(lCond,lResp: integer; var lValidLeft,lValidRight: integer);
begin
     inc (gCondRA[lCond].nTrials);
     if (lResp and 1) = (1 and gCondRA[lCond].CorrectResp) then begin
        inc (gCondRA[lCond].nLeftValid);
        lValidLeft := 1
     end else
         lValidLeft := 0;
     //MainForm.responsememo.Lines.add(inttostr(
     if (lResp and 2) = (2 and gCondRA[lCond].CorrectResp) then begin
        inc (gCondRA[lCond].nRightValid);
        lValidRight := 1
     end else
         lValidRight := 0;
end;

function Pct (lValid,lN: integer): integer;
begin
    result := 0;
    if lN < 1 then
       exit;
    result := round(100*lValid/lN);
end;

procedure TMainForm.ShowStats;
var
   lCond: integer;
   lStr: string;
begin
     ResponseMemo.lines.add('#Cond  n   Lv   Rv    L%    R%');
     for lCond := 1 to knCond do begin
         if gCondRA[lCond].nTrials > 0 then begin
            lStr := '#'+gCondRA[lCond].CondName+ PadStr(gCondRA[lCond].nTrials, 5)+
                 PadStr(gCondRA[lCond].nLeftValid,5)+PadStr(gCondRA[lCond].nRightValid,5)+
                  PadStr(Pct(gCondRA[lCond].nLeftValid,gCondRA[lCond].nTrials),5)+'%'+PadStr(Pct(gCondRA[lCond].nRightValid,gCondRA[lCond].nTrials),5)+'%' ;
            ResponseMemo.lines.add(lStr);
         end;
     end;
end;

procedure Staircase (var lTrialTime: integer);
var
   lChange,lNum,lUniCorrect,lBilatCorrect: integer;
begin
     if lTrialTime = 0 then exit;
     lChange := 0;
     lUniCorrect := gCondRA[kGx].nLeftValid;
     lNum := gCondRA[kGx].nTrials;
     if (lNum > 1) and ((lUniCorrect/lNum) < 0.40) then
         lChange := lChange + round(lTrialTime * 0.10);
     lUniCorrect := gCondRA[kxG].nRightValid;
     lNum :=  gCondRA[kxG].nTrials;
     if (lNum > 1) and ((lUniCorrect/lNum) < 0.40) then
         lChange := lChange + round(lTrialTime * 0.10);
     lNum := gCondRA[kGG].nTrials;
     lBilatCorrect := gCondRA[kGG].nLeftValid;
     if gCondRA[kGG].nRightValid < lBilatCorrect then
        lBilatCorrect := gCondRA[kGG].nRightValid;
     if (lNum > 1) and ((lBilatCorrect/lNum) > 0.50) then
         lChange := lChange - round(lTrialTime * 0.20);
     lTrialTime := lTrialTime + lChange;
     if lTrialTime < 10 then
        lTrialTime := 10;
end;

function RealToStr(lR: double {was extended}; lDec: integer): string;
begin
     Result := FloatToStrF(lR, ffFixed,7,lDec);
end;


function ReadNextCSV (var lStr: string; var lPos: integer): integer;
var
   lLen: integer;
   lOutStr: string;
begin
     result := 0;
     lLen := length(lStr);
     if lPos > lLen then
        exit;
     while (lStr[lPos] = ',') and (lPos <= lLen) do
           inc(lPos);
     lOutStr := '';
     while (lStr[lPos] <> ',') and (lPos <= lLen) do begin
           if lStr[lPos] in ['0'..'9'] then
              lOutStr := lOutStr+(lStr[lPos]);
           inc(lPos);
     end;
     if length(lOutStr) > 0 then
        result := StrToInt(lOutStr);
end;

procedure ParseStat (var lStr: string);
var
 lPos,lTrial,lCond,lTime,lResp,lLRT,lRRT,lValidLeft,lValidRight{,lEye}: integer;
begin
     //result := false;
     lPos := 1;
     //kHdr = '#Name, Trial,  Cond,  Time,  Resp,   lRT,   rRT,  lVal,  rVal,   Eye';
     lTrial := ReadNextCSV(lStr,lPos);//condition name
     lTrial := ReadNextCSV(lStr,lPos);
     lCond := ReadNextCSV(lStr,lPos);
     lTime := ReadNextCSV(lStr,lPos);
     lResp :=ReadNextCSV(lStr,lPos);
     lLRT := ReadNextCSV(lStr,lPos);
     lRRT := ReadNextCSV(lStr,lPos);
     lValidLeft := ReadNextCSV(lStr,lPos);
     lValidRight := ReadNextCSV(lStr,lPos);
     CompileStats(lCond,lResp, lValidLeft,lValidRight);
end;

procedure AnalyzeStat(var lFilename: string);
var
   lStr ,lStr1: string;
   lF0: textfile;
   lLines: integer;
begin
      if not Fileexists(lFilename) then
         exit;
      Assign(lF0, lFilename);
      Reset(lF0);
      //next - check header
      lStr1 := 'x';
      while (not EOF(lF0)) and (lStr1 <> kHdr) do begin
            lStr := lStr1;
            Readln(lF0, lStr1);
      end;
      if EOF(lF0) then begin
         Showmessage('File is of incorrect format to analyse: '+lFilename);
         exit;
      end;
      //now parse data
      lLines := 0;
      while not EOF(lF0) do begin
            Readln(lF0, lStr); {call final offset RT}
            if (Length(lStr) > 0) and (lStr[1]<>'#') then begin
               ParseStat(lStr);
               inc(lLines);
            end;
      end;   {EOF}
      Close(lF0);
      MainForm.ResponseMemo.Lines.Add(inttostr(lLines)+' trials in '+lFilename);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
	 Randomize;
	ResponseMemo.Lines.Clear;
	ResponseMemo.Lines.Add('#Version='+kVers);
end;

procedure TMainForm.Adjust1Click(Sender: TObject);
begin
     if ExperimentRunning then exit;
    	SettingsForm.ShowModal;
end;

procedure TMainForm.ShowTrial(lPort: integer) ;
var
	lMidX,lMidY,lnItems,lInc,lTarget,kMaxX,kMaxY: integer;
        gForeClr : TColor;
begin
	kMaxX := Image1.Width;
	kMaxY := Image1.Height;
	(*if (kMaxX < 640) or (kMaxY < 480) then begin
		showmessage('Please resize this program - the screen is too small to show the stimuli.');
		exit;
	end; *)
	Image1.Canvas.Brush.color := clWhite;
	Image1.Canvas.FillRect(rect(0,0,kMaxX,kMaxY));
        gForeClr := clRed;
	Image1.Canvas.Brush.color := gForeClr;
	Image1.Canvas.Pen.color := Image1.Canvas.Brush.color;
        lMidX := kMaxX div 2;
        lMidY := kMaxY div 2;
        Image1.Canvas.Rectangle(1,1,300,111);

end;

procedure TMainForm.PresentTrial(lBlock,lTrial,lCond,lTarTime: integer);
var
   lResp,lvalidLeft,lvalidRight: integer;
   lStr: string;
begin
     lStr := '    '+gCondRA[lCond].condName+',' +PadStrComma(lTrial,6)+ PadStrComma(lCond,6)+PadStrComma(lTarTime,6);
     MainForm.Caption := ('Press Fn6 for next trial :: '+lStr);
     gLeftBtn := 0;
     gRightBtn := 0;
     gTargetOffTime := lTarTime;
     RespTimer.enabled := true;
     gStartTime := GetTickCount;
     PortOut(gCondRA[lCond].OutPort);
     //ShowTrial(gCondRA[lCond].OutPort);
     gNextTrial := false;
     gEyeMove := 0;
     repeat
           application.ProcessMessages;
     until gNextTrial = true;
     RespTimer.enabled := false;

     if gLeftBtn = 0 then
        lResp := 0
     else
         lResp := 1;
     if gRightBtn <> 0 then
        lResp := lResp + 2;
     CompileStats(lCond,lResp,lValidLeft,lValidRight);
     lStr := lStr + PadStrComma(lResp,6)+PadStrComma(gLeftBtn,6)+PadStrComma(gRightBtn,6)+PadStrComma(lValidLeft,6)+PadStrComma(lValidRight,6)+PadStr(lBlock,6)+PadStr(gEyeMove,6) ;
     ResponseMemo.lines.add(lStr);
     //+',Resp,'+inttostr(lResp)+',rtL,'+inttostr(gLeftBtn)+',rtR,'+inttostr(gRightBtn)+',valL,'+inttostr(lValidLeft)+',valR,'+inttostr(lValidRight)  );
     MainForm.Caption := ('XTN');
end;

procedure TMainForm.SaveCore;
var
 lFilename: string;
begin
        lFilename :=  extractfiledir(paramstr(0))+'\'+ (FormatDateTime('yyyymmdd_hhnnss', (now)))+'.csv';
	ResponseMemo.Lines.Add('#Saved as '+lFileName);
        {$I-}
	ResponseMemo.Lines.SaveToFile(lFilename);
	{$I+}
	if (IOResult  <> 0) then begin
	   Showmessage('Unable to save data as '+lFilename+'. Perhaps disk is full. You may wish to save the data...');
	   if (SaveDialog1.Execute) then
              ResponseMemo.Lines.SaveToFile(SaveDialog1.Filename);
	end;
end;

procedure TMainForm.StartStudy(Sender: TObject);
label
     666;
var
   lnTrials,lTrial,lTarTime,lBlock: integer;
begin
     if ExperimentRunning then exit;
     if gnBlock < 1 then exit;
     ResponseMenu.Enabled := true;
     gAbort := false;
     ClearStats;
     lTarTime := gTargetDuration;
     ResponseMemo.Lines.Clear;
     ResponseMemo.Lines.Add('#Version='+kVers);
     ResponseMemo.Lines.Add('#StartTime='+DateToStr(Date)+' - '+ TimeToStr(Time));
     ResponseMemo.Lines.Add(kHdr);
     MainForm.Caption := ('Press Fn6 for first trial ');
     gNextTrial := false;
     repeat
           application.ProcessMessages;
     until gNextTrial = true;
     for lBlock := 1 to gnBlock do begin
        lnTrials := InitBlock;
        if lnTrials < 1 then goto 666;
        for lTrial := 1 to lnTrials do begin
            PresentTrial(lBlock,lTrial,gCondOrderRA[lTrial],lTarTime);
            //ResponseMemo.lines.add(inttostr(lTrial)+','+inttostr(gCondOrderRA[lTrial])  );
            if gAbort then
               goto 666;
        end;
        Staircase (lTarTime);
     end; //for each block
666:
     ResponseMenu.Enabled := false;
     RespTimer.Enabled := false;
        ShowStats;
	ResponseMemo.Lines.Add('#EndTime='+DateToStr(Date)+' - '+ TimeToStr(Time));
        SaveCore;
        PortOut(0);
        gAbort := true;//Experiment not running
end;

procedure TMainForm.Exit1Click(Sender: TObject);
begin
     if ExperimentRunning then exit;
	MainForm.Close;
end;

procedure TMainForm.About1Click(Sender: TObject);
begin
     showmessage('Extinction task :: '+kVers)
end;

procedure TMainForm.HardwareTest1Click(Sender: TObject);
begin
     if ExperimentRunning then exit;
     HardwareForm.Showmodal;
end;

procedure TMainForm.Showtrialtypes1Click(Sender: TObject);
var
   lCond: integer;
   lStr: string;
begin
     if ExperimentRunning then exit;
     for lCond := 1 to knCond do begin
         lStr := ('Trial = '+inttostr(lCond) +','+gCondRA[lCond].CondName+',Trials Per Block = '+inttostr(gCondRA[lCond].RepsPerBlock)  );
         PortOut(gCondRA[lCond].OutPort);
         Showmessage(lStr);
     end;
     PortOut(0);
end;

procedure TMainForm.RespTimerTimer(Sender: TObject);
var
   lIn: integer;
begin
   lIn := PortIn;
   //record 1st left/right btn
   if odd(lIn) and (gLeftBtn = 0) then
      gLeftBtn := GetTickCount-gStartTime;
   if odd(lIn shr 1) and (gRightBtn = 0) then
      gRightBtn := GetTickCount-gStartTime;
   if (gTargetOffTime > 0) and ((GetTickCount-gStartTime)> gTargetOffTime) then begin
      gTargetOffTime := 0;
      PortOut(0);
   end;
end;

procedure TMainForm.Left1Click(Sender: TObject);
begin
    if (gLeftBtn = 0) then
      gLeftBtn := GetTickCount-gStartTime;
end;

procedure TMainForm.Right1Click(Sender: TObject);
begin
   if  (gRightBtn = 0) then
      gRightBtn := GetTickCount-gStartTime;
end;

procedure TMainForm.NextTrial1Click(Sender: TObject);
begin
     gNextTrial := true;
     RespTimer.Enabled := false;
end;

procedure TMainForm.AbortClick(Sender: TObject);
begin
     gNextTrial := true;
     RespTimer.Enabled := false;
     gAbort := true;
end;

procedure TMainForm.Statisitics1Click(Sender: TObject);
var
   lFilename: string;
   lnFiles,lC: integer;
begin
     if ExperimentRunning then exit;
     ResponseMemo.Lines.Clear;
     ClearStats;
     if not OpenDialog1.Execute then exit;
     lnFiles :=  OpenDialog1.files.count;
     if lnFiles < 1 then exit;
     for lC := 1 to lnFiles do begin
         lFileName := OpenDialog1.Files[lC-1];
         AnalyzeStat(lFilename);
     end;
      MainForm.ShowStats;
end;

procedure TMainForm.Eyemove1Click(Sender: TObject);
begin
     gEyeMove := 1;
end;

end.
