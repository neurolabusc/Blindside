object SetkeyForm: TSetkeyForm
  Left = 341
  Top = 195
  BorderStyle = bsDialog
  Caption = 'Define key'
  ClientHeight = 105
  ClientWidth = 277
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnKeyPress = FormKeyPress
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 16
    Width = 230
    Height = 33
    Caption = 'Press desired key'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -29
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
  end
end
