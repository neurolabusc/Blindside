object TMSTestForm: TTMSTestForm
  Left = 403
  Top = 283
  Width = 280
  Height = 192
  Caption = 'TMS test'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnHide = FormHide
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object IntenLabel: TLabel
    Left = 0
    Top = 0
    Width = 142
    Height = 143
    Caption = '99'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -128
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
  end
  object CancelBtn: TButton
    Tag = -1
    Left = 176
    Top = 104
    Width = 75
    Height = 25
    Caption = 'Cancel'
    TabOrder = 1
    OnClick = StaircaseBtnsClick
  end
  object HitBtn: TButton
    Left = 176
    Top = 40
    Width = 75
    Height = 25
    Caption = 'Detected'
    TabOrder = 2
    OnClick = StaircaseBtnsClick
  end
  object MissBtn: TButton
    Left = 176
    Top = 72
    Width = 75
    Height = 25
    Caption = 'Missed'
    TabOrder = 3
    OnClick = StaircaseBtnsClick
  end
  object PulseBtn: TButton
    Left = 176
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Pulse'
    TabOrder = 4
  end
  object TMSsetup: TPanel
    Left = 0
    Top = 0
    Width = 272
    Height = 165
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object Label2: TLabel
      Left = 16
      Top = 8
      Width = 92
      Height = 13
      Caption = 'Estimated threshold'
    end
    object Label3: TLabel
      Left = 16
      Top = 56
      Width = 74
      Height = 13
      Caption = 'False alarm rate'
    end
    object Label4: TLabel
      Left = 16
      Top = 80
      Width = 82
      Height = 13
      Caption = 'Desired threshold'
    end
    object Label5: TLabel
      Left = 16
      Top = 32
      Width = 64
      Height = 13
      Caption = 'Estimated SD'
    end
    object HotKeyBtn: TButton
      Left = 2
      Top = 100
      Width = 88
      Height = 25
      Caption = 'Set hotkeys'
      TabOrder = 0
      OnClick = HotKeyBtnClick
    end
    object TMSTestbtn: TButton
      Left = 92
      Top = 100
      Width = 88
      Height = 25
      Caption = 'Test pulse'
      TabOrder = 1
      OnClick = TMSTestbtnClick
    end
    object InitialEstEdit: TEdit
      Left = 118
      Top = 2
      Width = 72
      Height = 21
      Hint = 'Prior estimate of threshold'
      TabOrder = 2
      Text = '43'
    end
    object GuessEdit: TEdit
      Left = 118
      Top = 50
      Width = 72
      Height = 21
      Hint = 'Chance of detecting behavior when there is no pulse (0..1)'
      TabOrder = 3
      Text = '0.0'
    end
    object ThreshEdit: TEdit
      Left = 118
      Top = 74
      Width = 72
      Height = 21
      Hint = 'Attempt to have this fraction of TMS pulses detected (0..1)'
      TabOrder = 4
      Text = '0.5'
    end
    object SDEdit: TEdit
      Left = 118
      Top = 26
      Width = 72
      Height = 21
      Hint = 'Small numbers only test near estimated threshold'
      TabOrder = 5
      Text = '0.5'
    end
    object StartStairBtn: TButton
      Left = 182
      Top = 100
      Width = 88
      Height = 25
      Caption = 'Start threshold'
      TabOrder = 6
      OnClick = StartStairBtnClick
    end
    object OKBtn: TButton
      Left = 182
      Top = 134
      Width = 88
      Height = 25
      Caption = 'OK'
      ModalResult = 1
      TabOrder = 7
    end
  end
end
