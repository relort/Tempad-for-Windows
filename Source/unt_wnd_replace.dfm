object wnd_replace: Twnd_replace
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Search and replace...'
  ClientHeight = 180
  ClientWidth = 325
  Color = 15790320
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poDesigned
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  DesignSize = (
    325
    180)
  PixelsPerInch = 96
  TextHeight = 13
  object dxLabel1: TdxLabel
    Left = 8
    Top = 8
    Width = 65
    Height = 18
    Caption = 'Searching in'
    DrawShadow = True
    ShadowColor = clWhite
  end
  object lbl_tabName: TdxLabel
    Left = 70
    Top = 8
    Width = 247
    Height = 18
    Anchors = [akLeft, akTop, akRight]
    DrawShadow = True
    ShadowColor = clWhite
  end
  object surface_main: TdxContainer
    Left = 8
    Top = 27
    Width = 309
    Height = 114
    Anchors = [akLeft, akTop, akRight, akBottom]
    BoundColor = clSilver
    BoundLines = [blLeft, blTop, blRight, blBottom]
    Caption = 'surface_main'
    object dxLabel2: TdxLabel
      Left = 16
      Top = 48
      Width = 65
      Height = 18
      Caption = 'Replace with'
      DrawShadow = True
      ShadowColor = clWhite
    end
    object edt_Text: TEdit
      Left = 16
      Top = 16
      Width = 276
      Height = 21
      TabOrder = 0
      OnChange = edt_TextChange
      OnKeyDown = edt_TextKeyDown
    end
    object btn_FindNext: TButton
      Left = 136
      Top = 72
      Width = 75
      Height = 25
      Caption = 'Find next'
      Enabled = False
      TabOrder = 2
      OnClick = btn_FindNextClick
    end
    object edt_ReplaceText: TEdit
      Left = 87
      Top = 45
      Width = 205
      Height = 21
      TabOrder = 1
      OnChange = edt_TextChange
    end
    object btn_ReplaceAll: TButton
      Left = 217
      Top = 72
      Width = 75
      Height = 25
      Caption = 'Replace all'
      Enabled = False
      TabOrder = 3
      OnClick = btn_ReplaceAllClick
    end
  end
  object btn_Close: TButton
    Left = 242
    Top = 147
    Width = 75
    Height = 25
    Anchors = [akBottom]
    Caption = 'Close'
    TabOrder = 1
    OnClick = btn_CloseClick
  end
end
