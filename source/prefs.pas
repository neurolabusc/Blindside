unit prefs;
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Spin, IniFiles, ExtCtrls;
type
  TPrefs = record
         UsePerformanceCounter: boolean;
         TMSSequence: String;
         Mode,Design,nSubj,Seed,Subj,Session,StimSec,ShamSec,
         HitHotKey,MissHotKey,TMSHotKey,TMSratems,TMSinterlockms//TMSphasems,TMSOnMS,TMSOffMS
         : integer;
  end;

type
  TSettingsForm = class(TForm)
    Label1: TLabel;
    StimSecEdit: TSpinEdit;
    Label2: TLabel;
    ShamSecEdit: TSpinEdit;
    Label3: TLabel;
    SeedEdit: TSpinEdit;
    nSubjEdit: TSpinEdit;
    Label4: TLabel;
    DesignDrop: TComboBox;
    Label5: TLabel;
    OKbtn: TButton;
    CancelBtn: TButton;
    ModeEdit: TSpinEdit;
    Label6: TLabel;
    TMSPanel: TPanel;
    Label7: TLabel;
    TMSratemsEdit: TSpinEdit;
    TMSinterlockmsEdit: TSpinEdit;
    Label8: TLabel;
    Label9: TLabel;
    UsePerformanceCounterCheck: TCheckBox;
    TMSSequenceEdit: TEdit;


  private
    { Private declarations }
  public
function IniFileX(lRead: boolean; lFilename: string; var lPrefs: TPrefs): boolean;
procedure SetDefaultPrefs (var lPrefs: TPrefs);
    { Public declarations }
  end;

var
  SettingsForm: TSettingsForm;
  const
  kVersion ='6May2010 Chris Rorden www.mricro.com';
  kStdMode = 0;
  kTMSMode = 1;
  //kDefSeq = 'SSAAASSAAASSCCCSSCCC';
  kDefSeq = 'SSSSAAAAAASSSSAAAAAASSSSCCCCCCSSSSCCCCCC';

implementation
{$R *.DFM}

procedure TSettingsForm.SetDefaultPrefs (var lPrefs: TPrefs);
var
  i: integer;
begin
  with lPrefs do begin
         //ADU:= 2;
         TMSHotKey := 33;
         MissHotKey := 32;
         HitHotKey := 32;
         TMSSequence := kDefSeq;
         Design := 0;
         nSubj := 20;
         Seed := 1492;
         Subj := 1;
         Session := 1;
         StimSec := 1200;
         ShamSec:= 20;
         Mode := kStdMode;
         TMSratems := 5000;
         TMSinterlockms := 1;
         //TMSphasems := TMSratems div 2;
         //TMSOnMS := 30000;
         //TMSOffMS := 20000;
         UsePerformanceCounter := true;
  end;//with lPrefs
end; //Proc SetDefaultPrefs


procedure IniInt(lRead: boolean; lIniFile: TIniFile; lIdent: string;  var lValue: integer);
//read or write an integer value to the initialization file
var
	lStr: string;
begin
        if not lRead then begin
           lIniFile.WriteString('INT',lIdent,IntToStr(lValue));
           exit;
        end;
	lStr := lIniFile.ReadString('INT',lIdent, '');
	if length(lStr) > 0 then
		lValue := StrToInt(lStr);
end; //IniInt

function Bool2Char (lBool: boolean): char;
begin
	if lBool then
		result := '1'
	else
		result := '0';
end;

function Char2Bool (lChar: char): boolean;
begin
	if lChar = '1' then
		result := true
	else
		result := false;
end;

procedure IniBool(lRead: boolean; lIniFile: TIniFile; lIdent: string;  var lValue: boolean);
//read or write a boolean value to the initialization file
var
	lStr: string;
begin
        if not lRead then begin
           lIniFile.WriteString('BOOL',lIdent,Bool2Char(lValue));
           exit;
        end;
	lStr := lIniFile.ReadString('BOOL',lIdent, '');
	if length(lStr) > 0 then
		lValue := Char2Bool(lStr[1]);
end; //IniBool

procedure IniStr(lRead: boolean; lIniFile: TIniFile; lIdent: string; var lValue: string);
//read or write a string value to the initialization file
begin
  if not lRead then begin
    lIniFile.WriteString('STR',lIdent,lValue);
    exit;
  end;
	lValue := lIniFile.ReadString('STR',lIdent, '');
end; //IniStr

function TSettingsForm.IniFileX(lRead: boolean; lFilename: string; var lPrefs: TPrefs): boolean;
//Read or write initialization variables to disk
var
  lIniFile: TIniFile;
  lI: integer;
begin
  result := false;
  if lRead then
     SetDefaultPrefs(lPrefs);
  if (lRead) and (not Fileexists(lFilename)) then
        exit;
  lIniFile := TIniFile.Create(lFilename);
  lI := 1;
  IniStr(lRead,lIniFile,'TMSSequence',lPrefs.TMSSequence);
  IniInt(lRead,lIniFile, (FormatDateTime('yyyymmdd_hhnnss', (now))),lI);
	//IniInt(lRead,lIniFile, 'ADU',lPrefs.ADU);
  IniInt(lRead,lIniFile, 'Design',lPrefs.Design);
  IniInt(lRead,lIniFile, 'Seed',lPrefs.Seed);
  IniInt(lRead,lIniFile, 'nSubj',lPrefs.nSubj);
	IniInt(lRead,lIniFile, 'Subj',lPrefs.Subj);
	IniInt(lRead,lIniFile, 'Phase',lPrefs.Session);
	IniInt(lRead,lIniFile, 'StimSec',lPrefs.StimSec);
	IniInt(lRead,lIniFile, 'ShamSec',lPrefs.ShamSec);
	IniInt(lRead,lIniFile, 'Mode',lPrefs.Mode);

	IniInt(lRead,lIniFile, 'TMSratems',lPrefs.TMSratems);
	IniInt(lRead,lIniFile, 'TMSinterlockms',lPrefs.TMSinterlockms);
	//IniInt(lRead,lIniFile, 'TMSphasems',lPrefs.TMSphasems);
	IniInt(lRead,lIniFile, 'TMSHotKey',lPrefs.TMSHotKey);
	IniInt(lRead,lIniFile, 'HitHotKey',lPrefs.HitHotKey);
	IniInt(lRead,lIniFile, 'MissHotKey',lPrefs.MissHotKey);
	//IniInt(lRead,lIniFile, 'TMSOnms',lPrefs.TMSOnms);
	//IniInt(lRead,lIniFile, 'TMSOffms',lPrefs.TMSOffms);
  IniBool(lRead,lIniFile, 'UsePerformanceCounter',lPrefs.UsePerformanceCounter);

  lIniFile.Free;
end;

end.
