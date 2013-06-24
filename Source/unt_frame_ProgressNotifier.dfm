object frame_ProgressNotifier: Tframe_ProgressNotifier
  Left = 0
  Top = 0
  Width = 361
  Height = 97
  TabOrder = 0
  object surface_progress: TdxContainer
    Left = 0
    Top = 0
    Width = 361
    Height = 97
    BoundColor = clSilver
    BoundLines = [blLeft, blTop, blRight, blBottom]
    Caption = 'surface_progress'
    OnPaint = surface_progressPaint
    object lbl_progressStatus: TdxLabel
      Left = 48
      Top = 24
      Width = 281
      Height = 20
      Caption = 'Performing...'
      DrawShadow = True
      ShadowColor = clWhite
    end
    object ProgressBar1: TProgressBar
      Left = 44
      Top = 50
      Width = 273
      Height = 17
      DoubleBuffered = False
      ParentDoubleBuffered = False
      Style = pbstMarquee
      TabOrder = 0
    end
  end
end
