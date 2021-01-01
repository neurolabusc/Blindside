unit ucopydata;
{based on Zarko Gajic's project
    http://delphi.about.com/od/windowsshellapi/a/wm_copydata.htm
Declared in Windows.pas:
  TCopyDataStruct = packed record
    dwData: DWORD; //up to 32 bits of data to be passed to the receiving application
    cbData: DWORD; //the size, in bytes, of the data pointed to by the lpData member
    lpData: Pointer; //Points to data to be passed to the receiving application. This member can be nil.
  end;

ReceiverForm must have procedure
  private
    procedure WMCopyData(var Msg : TWMCopyData); message WM_COPYDATA;
  ...
  procedure TReceiverMainForm.WMCopyData(var Msg: TWMCopyData);
  var I,Resp: integer;
  begin
     Resp := 1; //could be used to report if receiver is ready...
     I := ReceiveDataDigit(Msg,Resp);
     Caption := inttostr(I);
  end;

  }


interface

uses Messages,Windows,Forms;

const
  kStartRecording = -1;
  kStopRecording = -2;
  kReceiverName =  'MobiRecordForm';
  kTReceiverName =  'TMobiRecordForm';

function SendDataDigit( I: integer; F: TForm): integer;
function ReceiveDataDigit(var Msg: TWMCopyData; Resp: integer): integer;

implementation



function SendDataDigit( I: integer; F: TForm): integer;
//returns -1 if error, otherwise returns response from receiver
var
  receiverHandle  : THandle;
  copyDataStruct : TCopyDataStruct;
begin
  result :=-1;
  copyDataStruct.dwData := I; //use it to identify the message contents
  copyDataStruct.cbData := 0;
  copyDataStruct.lpData := nil;
  receiverHandle := FindWindow(PChar(kTReceiverName),PChar(kReceiverName));
  if receiverHandle = 0 then
    Exit;
  result := SendMessage(receiverHandle, WM_COPYDATA, Integer(F.Handle), Integer(@copyDataStruct));
  //result :=   SendMessage(receiverHandle, WM_COPYDATA, Integer(F.Handle), Integer(@copyDataStruct));
end;

function ReceiveDataDigit(var Msg: TWMCopyData; Resp: integer): integer;
begin
  result := Msg.CopyDataStruct.dwData;
  //Send something back
  msg.Result := Resp;
end;




end.
 