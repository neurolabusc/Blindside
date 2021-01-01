unit test;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls,adu,utime, ExtCtrls;

type
  TtDCSTestForm = class(TForm)
    OffRadio: TRadioButton;
    StdRadio: TRadioButton;
    OKbtn: TButton;
    RevRadio: TRadioButton;
    ShamRadio: TRadioButton;
    procedure OffRadioClick(Sender: TObject);
    procedure StdRadioClick(Sender: TObject);
    procedure RevRadioClick(Sender: TObject);
    procedure ShamRadioClick(Sender: TObject);
  private
   { Private declarations } 
    //FHookStarted : Boolean; 
    { Private declarations }



  public
    { Public declarations }
  end;

var
  tDCSTestForm: TtDCSTestForm;



implementation

{$R *.DFM}



procedure TtDCSTestForm.OffRadioClick(Sender: TObject);
begin
     PortOutx(Off);
end;

procedure TtDCSTestForm.StdRadioClick(Sender: TObject);
begin
     PortOutx(StandardPolarity)
end;

procedure TtDCSTestForm.RevRadioClick(Sender: TObject);
begin
     PortOutx(ReversedPolarity)
end;

procedure TtDCSTestForm.ShamRadioClick(Sender: TObject);
begin
PortOutx(Sham)
end;


end.
