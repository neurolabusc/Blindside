unit questinterface;

interface
uses Dialogs, SysUtils, Windows, Messages, Variants, Classes, Graphics, Controls, Forms,questtypes;

//procedure FPrintF (S: String; F1,F2,F3: TFloatType); overload;
//procedure FPrintF (S: String; F1,F2: TFloatType); overload;
//procedure FPrintF (S: String; F1: TFloatType); overload;
//procedure FPrintF (S: String); overload;
//function Input (Caption: string; default: TFloatType): TFloatType;
procedure ErrorQ (S: string);
function MsgOK(S: string): boolean;
//procedure ReportArray (caption: string; v: TDblArray);
//procedure ReportColumn(caption: string;v: TDblArray);

implementation
(*uses questdemo;
procedure FPrintF (S: String); overload;
begin
  form1.memo1.lines.add(S);
end;

procedure FPrintF (S: String; F: TFloatType); overload;
begin
  form1.memo1.lines.add(S+' '+floattostr(F));
end;

const kSep = chr(9);

procedure ReportColumn(caption: string;v: TDblArray);
var
  i,len: integer;
begin
  len := length(v);
  if len < 1 then begin
       FPrintF(Caption+' is empty');
       exit;
  end;
  FPrintF(Caption);
  for i := 0 to len-1 do
    FPrintF(FloatToStrF(v[i], fffixed, 15, 15));
end;

procedure ReportArray (caption: string; v: TDblArray);
const
  ColPerLine = 7;
  kSep = chr(9);
var
  i,lineend,len: integer;
  s: string;
begin
  len := length(v);
  if len < 1 then begin
       FPrintF(Caption+' is empty');
       exit;
  end;
  i := 1;
  repeat
    lineend := i+ ColPerLine-1;
    if lineend > len then
      lineend := len;
    s := ' :: Columns '+inttostr(i)+' to '+inttostr(lineend);
    FPrintF(Caption+s);
    s := '';
    for i := i to lineend do begin
      s := s + FloatToStrF(v[i-1], fffixed, 15, 15); //floattostr(v.ra[i-1]);
      if i < lineend then
        s := s + kSep;
    end;
    FPrintF(s);
  until i >= len;
end;   *)

function MsgOK(S: string): boolean;
var
  buttonSelected : Integer;
begin
  buttonSelected := MessageDlg(S,mtConfirmation, mbOKCancel, 0);
  result :=  (buttonSelected = mrOK);
end;

procedure ErrorQ (S: string);
begin
  showmessage(S);
end;

(*procedure FPrintF (S: String); overload;
begin
  form1.memo1.lines.add(S);
end;

procedure FPrintF (S: String; F1,F2,F3: TFloatType); overload;
begin
    FPrintF(S+' '+floattostr(F1)+kSep+floattostr(F2)+kSep+floattostr(F3));
end;

procedure FPrintF (S: String; F1,F2: TFloatType); overload;
begin
    FPrintF(S+kSep+floattostr(F1)+kSep+floattostr(F2));
end;

procedure FPrintF (S: String; F1: TFloatType); overload;
begin
    FPrintF(S+kSep+floattostr(F1));
end;     *)

(*function Input (Caption: string; default: TFloatType): TFloatType;
var
  value: string;
begin
     value := floattostr(default);
     InputQuery('Quest interface', Caption, value);
     result := strtofloat(value);
end;*)

end.
 