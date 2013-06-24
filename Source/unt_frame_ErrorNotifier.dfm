object frame_ErrorNotifier: Tframe_ErrorNotifier
  Left = 0
  Top = 0
  Width = 360
  Height = 200
  TabOrder = 0
  object surface_msgError: TdxContainer
    Left = 0
    Top = 0
    Width = 360
    Height = 200
    BoundColor = 4605695
    BoundLines = [blLeft, blTop, blRight, blBottom]
    Caption = 'surface_progress'
    OnPaint = surface_msgErrorPaint
    object lbl_msgError_title: TdxLabel
      Left = 48
      Top = 24
      Width = 289
      Height = 52
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 2895103
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      Caption = 
        'Fatal exception occurred and application could not initialize al' +
        'l needed data for usual workflow. Check another apps that can ca' +
        'use such issues and start again.'
      DrawShadow = True
      ShadowColor = clWhite
    end
    object lbl_msgError_caption: TdxLabel
      Left = 48
      Top = 82
      Width = 281
      Height = 71
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 2895103
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      Caption = '[b]Performing...[/b]'
      DrawShadow = True
      ShadowColor = clWhite
    end
    object btn_Close: TButton
      Left = 143
      Top = 159
      Width = 75
      Height = 25
      Caption = 'Close'
      TabOrder = 0
      OnClick = btn_CloseClick
    end
  end
end
