object wnd_Preview: Twnd_Preview
  Left = 0
  Top = 0
  Caption = 'Preview'
  ClientHeight = 560
  ClientWidth = 750
  Color = 15790320
  Constraints.MinHeight = 400
  Constraints.MinWidth = 500
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poDesigned
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  DesignSize = (
    750
    560)
  PixelsPerInch = 96
  TextHeight = 13
  object lbl_title: TdxLabel
    Left = 8
    Top = 8
    Width = 734
    Height = 16
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Title'
    DrawShadow = True
    ShadowColor = clWhite
  end
  object Image1: TImage
    Left = 8
    Top = 533
    Width = 16
    Height = 16
    Anchors = [akLeft, akBottom]
    AutoSize = True
    Picture.Data = {
      0954506E67496D61676589504E470D0A1A0A0000000D49484452000000100000
      001008060000001FF3FF610000001974455874536F6674776172650041646F62
      6520496D616765526561647971C9653C000002FB4944415478DA65936B485451
      10C7FFE7DE7D9ABAEAEA5A668562B649A154CB9299519885156AA25666450F83
      B63E1509511F823E141404B942197DA88D284B0B4A28C5C0A210A312CDAD8C22
      7BFA58F311BAABF7D19C5BC66E1D7660CF9D99DF99F933C3F0CF89DD5AEF9665
      75A7AAAA2695EE8C1B637E516497063C85AEE0588AD1FCDA892BBF9DAB67EC7E
      AE6326962FB4C16A3151044F060686FD78D4D187076D5F30A9AA6BFAAF143C08
      01F0E4788BF1FEA1D28518F2CB68F6FAE0FDFA1363010516B3887933C2B1C21E
      83289388D3D73BD03B1CD0207F0133B6DD51DD079C68F4FEC0E3EE41C80A706C
      43323639A7C37EE4314C7A9117836529D1583D3F1AAE73ADF876399F6900DEF3
      DEBCD47D3F051D9EBEFB0151609890141C5E9B8412473C328E3FC53483A8B529
      292A9612245C9170BEE16D3555E162315B6EF94FEC761AAFB57D878E374C3F0E
      18F14B50A892086AC14C151057BB4BF4EA66C7741CBDD81AF05DDD6862D62D75
      EA9EE20C3CFF300481A2C84FBDCB68A95CACBD9A75F219C28DE26F1F3844C5A2
      A428D4D4BEC4C0D542C662CBEAD4E2F50BF079D0AF09A270C0848C8AAC04943A
      6CC83EFD0291241E6F4D539E2C31C684DABB9DE8F71020AEAC5E5D9D63C7E4A4
      ACBDCE01E3F47F5766028A16C522E76C7B088077A9A7961A9B5EA3CF53C098AD
      AC2EB06AE53C834EA7A3F2943F00053B9CF128C8B022CFDD19021004019224A1
      F9E19B895E4FA191C516D55C4F4B4F2BB1CF8D2787A229CD2B285B62437EBA15
      EBAB5FC11226C2200A2424834E27E075772FBADABB6EF4DFDC5DCAB1B349878F
      79396988883062922079768B963C75B67BBAB559D053F2E868000D4D5D24E0C6
      3934073D5A5D51D9075DE6E4ECAA7539F311499000B5E02721656A47A40833CD
      81412F608492EF357931FEBE65FF50CB1977F02E4412A45C4CCCAC72A4CF426A
      8A0D1161064C2DD3E8D804DEBEEB435BFB27C89F9FF0E42BF47924649938846C
      AEB5F04225335BF3490AC394830FA73AEEBBE3ABAF3845D76E9EFCDF36069DD9
      645C0021E81BCD207C643DFFAEF32F9B7C46F08D28AF410000000049454E44AE
      426082}
  end
  object dxLabel1: TdxLabel
    Left = 30
    Top = 534
    Width = 163
    Height = 16
    Anchors = [akLeft, akBottom]
    Caption = 'Text is read-only.'
    DrawShadow = True
    ShadowColor = clWhite
  end
  object Button1: TButton
    Left = 667
    Top = 527
    Width = 75
    Height = 25
    Anchors = [akBottom]
    Caption = 'Close'
    TabOrder = 1
    OnClick = Button1Click
  end
  object edt_data: TSynEdit
    Left = 8
    Top = 27
    Width = 734
    Height = 494
    Anchors = [akLeft, akTop, akRight, akBottom]
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    PopupMenu = edit_menu
    TabOrder = 0
    Gutter.Font.Charset = DEFAULT_CHARSET
    Gutter.Font.Color = clWindowText
    Gutter.Font.Height = -11
    Gutter.Font.Name = 'Courier New'
    Gutter.Font.Style = []
    Highlighter = editor_links_highlight
    ReadOnly = True
    WordWrap = True
  end
  object edit_menu: TPopupMenu
    OnPopup = edit_menuPopup
    Left = 96
    Top = 56
    object item_edit_menu_Copy: TMenuItem
      Caption = 'Copy'
      OnClick = item_edit_menu_CopyClick
    end
    object N4: TMenuItem
      Caption = '-'
    end
    object item_edit_menu_SelectAll: TMenuItem
      Caption = 'Select All'
      OnClick = item_edit_menu_SelectAllClick
    end
  end
  object editor_links_opener: TSynURIOpener
    CtrlActivatesLinks = False
    URIHighlighter = editor_links_highlight
    Left = 96
    Top = 176
  end
  object editor_links_highlight: TSynURISyn
    Left = 96
    Top = 120
  end
end
