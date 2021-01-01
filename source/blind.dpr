program blind;

uses
  Forms,
  uxtn in 'uxtn.pas' {MainForm},
  settings in 'settings.pas' {SettingsForm},
  hwtest in 'hwtest.pas' {HardwareForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Bisection';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TSettingsForm, SettingsForm);
  Application.CreateForm(THardwareForm, HardwareForm);
  Application.Run;
end.
