unit setkey;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, prefs;

type
  TSetkeyForm = class(TForm)
    Label1: TLabel;
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SetkeyForm: TSetkeyForm;

implementation

{$R *.dfm}
uses
  test, tmstest;

procedure TSetkeyForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
 //showmessage(Key);
 //TMSTestForm.HotKeyBtn.tag := ord((Key));
 Close;
end;

procedure TSetkeyForm.FormCreate(Sender: TObject);
begin
  //close;
end;

end.
