object XmlEditForm: TXmlEditForm
  Left = 0
  Top = 0
  Caption = 'XmlEditForm'
  ClientHeight = 487
  ClientWidth = 642
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    642
    487)
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 8
    Top = 8
    Width = 626
    Height = 436
    Anchors = [akLeft, akTop, akRight, akBottom]
    Lines.Strings = (
      'Memo1')
    TabOrder = 0
    WordWrap = False
    ExplicitWidth = 624
    ExplicitHeight = 441
  end
  object OkButton: TButton
    Left = 477
    Top = 454
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
    ExplicitLeft = 475
    ExplicitTop = 459
  end
  object Button2: TButton
    Left = 559
    Top = 454
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
    ExplicitLeft = 557
    ExplicitTop = 459
  end
end
