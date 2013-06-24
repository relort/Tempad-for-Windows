object wnd_Search: Twnd_Search
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Searching for ...'
  ClientHeight = 119
  ClientWidth = 331
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
    331
    119)
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
    Width = 251
    Height = 18
    Anchors = [akLeft, akTop, akRight]
    DrawShadow = True
    ShadowColor = clWhite
  end
  object surface_main: TdxContainer
    Left = 8
    Top = 27
    Width = 315
    Height = 53
    Anchors = [akLeft, akTop, akRight, akBottom]
    BoundColor = clSilver
    BoundLines = [blLeft, blTop, blRight, blBottom]
    Caption = 'surface_main'
    object edt_Text: TEdit
      Left = 16
      Top = 16
      Width = 205
      Height = 21
      TabOrder = 0
      OnChange = edt_TextChange
    end
    object btn_FindNext: TButton
      Left = 227
      Top = 14
      Width = 75
      Height = 25
      Caption = 'Find next'
      Enabled = False
      TabOrder = 1
      OnClick = btn_FindNextClick
    end
  end
  object btn_Close: TButton
    Left = 248
    Top = 86
    Width = 75
    Height = 25
    Anchors = [akBottom]
    Caption = 'Close'
    TabOrder = 1
    OnClick = btn_CloseClick
  end
end
