object wnd_preferences: Twnd_preferences
  Left = 0
  Top = 0
  Caption = 'Preferences'
  ClientHeight = 609
  ClientWidth = 437
  Color = 15790320
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object dxContainer2: TdxContainer
    Left = 8
    Top = 8
    Width = 421
    Height = 362
    BoundColor = clSilver
    BoundLines = [blLeft, blTop, blRight, blBottom]
    Caption = 'dxContainer1'
    Color = 15790320
    ParentColor = False
    OnPaint = dxContainer1Paint
    object dxLabel3: TdxLabel
      Left = 12
      Top = 12
      Width = 300
      Height = 15
      Caption = 'Editor'
      DrawShadow = True
      ShadowColor = clWhite
    end
    object dxLabel5: TdxLabel
      Left = 12
      Top = 42
      Width = 63
      Height = 16
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      Caption = 'Font'
      DrawShadow = True
      ShadowColor = clWhite
    end
    object dxLabel6: TdxLabel
      Left = 295
      Top = 42
      Width = 63
      Height = 16
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      Caption = 'Font size'
      DrawShadow = True
      ShadowColor = clWhite
    end
    object CheckBox1: TCheckBox
      Left = 295
      Top = 128
      Width = 97
      Height = 17
      Caption = 'Word Wrap'
      TabOrder = 0
    end
    object ListBox1: TListBox
      Left = 12
      Top = 64
      Width = 263
      Height = 201
      ItemHeight = 13
      TabOrder = 1
    end
    object ComboBox1: TComboBox
      Left = 296
      Top = 64
      Width = 113
      Height = 21
      Style = csDropDownList
      TabOrder = 2
      Items.Strings = (
        '9'
        '10'
        '11'
        '12'
        '13'
        '14'
        '15'
        '16')
    end
  end
  object Button1: TButton
    Left = 354
    Top = 576
    Width = 75
    Height = 25
    Caption = 'Cancel'
    TabOrder = 1
  end
  object Button3: TButton
    Left = 273
    Top = 576
    Width = 75
    Height = 25
    Caption = 'Ok'
    TabOrder = 2
  end
end
