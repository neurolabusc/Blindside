unit adu;

interface
         uses SysUtils {StrToInt, IntToStr},Dialogs {error dialog};
type
   TIO = (StandardPolarity,ReversedPolarity, Sham,TMS,Off,StandardPolarityTrigger,ReversedPolarityTrigger, ShamTrigger);
function PortIn:integer;
procedure PortOutx (lOut: TIO);
function PortToStr (lPort: TIO): string;
function AddOpticalTrigger(lPort: TIO): TIO;
//procedure PortOut(lOut: integer);


var gaduHandle: Longint;

implementation

type
     ValAsLong = longint;
     RefAsLong = ^ValAsLong;
     CharRA = String[8];
     CharPtr = ^CharRA;
const
	kaduTimeout = 50;
function OpenAduDevice(iTimeOut: ValAsLong): Longint; stdcall; external 'AduHid.dll';
procedure WriteAduDevice( aduHandle: ValAsLong;   lpBuffer: CharPtr;  nNumberOfBytesToRead: ValAsLong;  lpNumberOfBytesRead: RefAsLong; iTimeout: ValAsLong  ); stdcall; external 'AduHid.dll';
procedure ReadAduDevice( aduHandle: ValAsLong;   lpBuffer: CharPtr;  nNumberOfBytesToRead: ValAsLong;  lpNumberOfBytesRead: RefAsLong; iTimeout: ValAsLong  ); stdcall; external 'AduHid.dll';
function CloseAduDevice(iHandle: ValAsLong): longint; stdcall; external 'AduHid.dll';

function AddOpticalTrigger(lPort: TIO): TIO;
begin
  result := lPort;
  case lPort of
    StandardPolarity,StandardPolarityTrigger :   result := StandardPolarityTrigger;
    ReversedPolarity,ReversedPolarityTrigger :   result :=ReversedPolarityTrigger;
    Sham,ShamTrigger :  result := ShamTrigger;
    else showmessage('Serious error with AddOpticalTrigger.');
  end;
end;
function PortToStr (lPort: TIO): string;
begin
  case lPort of
    StandardPolarity :   result := 'StandardPolarity';
    ReversedPolarity :   result := 'ReversedPolarity';
    Sham :  result := 'Sham';
    TMS : result := 'TMS';
    Off :  result := 'Off';
    StandardPolarityTrigger :   result := 'StandardPolarityTrigger';
    ReversedPolarityTrigger :   result := 'ReversedPolarityTrigger';
    ShamTrigger :  result := 'ShamTrigger';
    else result := '?';
  end;
end;
procedure PortOut(lOut: integer);
var
   lRead: ValAsLong;
   lnRead: RefAsLong;
   lStr: CharRA;
begin
     //showmessage (inttostr(lout));
     lnRead := @lRead;
     lStr := 'MK'+inttostr(lOut);
     WriteAduDevice(gaduHandle, @lStr[1], length(lStr), lnRead,kaduTimeout );
end;

procedure PortOutx (lOut: TIO);
begin
     case lOut of
          StandardPolarity : PortOut(6);
          ReversedPolarity : PortOut(9);
          Sham :  PortOut(16);
          TMS :  PortOut(16+64+128);//sham+gnd+vdd
          StandardPolarityTrigger : PortOut(6+128);
          ReversedPolarityTrigger: PortOut(9+128);
          ShamTrigger :  PortOut(16+128);
          else PortOut(0); //off
     end;
end;

function PortIn:integer;
var
   lStr : CharRA;
   lRead: ValAsLong;
   lnRead: RefAsLong;
begin
     result := 0;
     lnRead := @lRead;
     lStr := 'PA';
     WriteAduDevice(gaduHandle, @lStr[1], 2, lnRead,kaduTimeout );
     ReadAduDevice(gaduHandle, @lStr[1], 2, lnRead,kaduTimeout );
     if lRead < 1 then exit;
     result := StrToInt(lStr);
end;

initialization
   gaduHandle := OpenAduDevice(kaduTimeout );
   if gaduHandle < 1 then
      showmessage('Warning: ADU218 not connected - you must connect the input device before running this software.');

finalization
     CloseAduDevice(gaduHandle);
end.
