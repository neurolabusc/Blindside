program blindside;

uses
  Forms,
  blinder in 'blinder.pas' {MainForm},
  prefs in 'prefs.pas' {SettingsForm},
  test in 'test.pas' {tDCSTestForm},
  makerandom in 'makerandom.pas',
  tms_u in 'tms_u.pas',
  setkey in 'setkey.pas' {SetkeyForm},
  tmstest in 'tmstest.pas' {TMSTestForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TSettingsForm, SettingsForm);
  Application.CreateForm(TtDCSTestForm, tDCSTestForm);
  Application.CreateForm(TSetkeyForm, SetkeyForm);
  Application.CreateForm(TTMSTestForm, TMSTestForm);
  Application.Run;
end.
