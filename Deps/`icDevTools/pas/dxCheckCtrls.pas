
{*******************************************************************}
{                                                                   }
{   dxCheckControls (Design eXperience)                             }
{     - TdxCheckbox                                                 }
{                                                                   }
{   Copyright (c) 2002 APRIORI business solutions AG                }
{   (W)ritten by M. Hoffmann - ALL RIGHTS RESERVED.                 }
{                                                                   }
{   DEVELOPER NOTES:                                                }
{   ==========================================================      }
{   This file is part of a component suite called Design            }
{   eXperience and may be used in freeware- or commercial           }
{   applications. The package itself is distributed as              }
{   freeware with full sourcecodes.                                 }
{                                                                   }
{   Feel free to fix bugs or include new features if you are        }
{   familiar with component programming. If so, please email        }
{   me your modifications, so it will be possible for me to         }
{   include nice improvements in further releases:                  }
{                                                                   }
{*******************************************************************}

unit dxCheckCtrls;

interface

uses
    Windows
  , Messages
  , Graphics
  , Classes
  , Controls
  , dxCore
  , dxCoreUtils;


type
    { TdxCustomCheckControl }
    TdxCustomCheckControl =
        class( TdxCustomControl)
            private
                FBgGradient: TBitmap;
                FBoundColor : TColor;
                FBoundLines: TdxBoundLines;
                FChecked: Boolean;
                FCheckSize: Byte;
                FCkGradient: TBitmap;
                FHlGradient: TBitmap;
                FSpacing: Byte;
            protected
                procedure SetBoundColor(Value : TColor);
                procedure SetBoundLines(Value: TdxBoundLines); virtual;
                procedure SetChecked(Value: Boolean); virtual;
                procedure SetSpacing(Value: Byte); virtual;
                procedure DrawCheckSymbol(const R: TRect); virtual; abstract;
            public
                constructor Create(AOwner: TComponent); override;
                destructor Destroy; override;
                procedure Click; override;
                procedure Paint; override;
                procedure HookResized; override;
            published
                // common properties.
                property BoundColor : TColor read FBoundColor write SetBoundColor;
                property Caption;
                property Color;
                property Enabled;
                property TabOrder;
                property TabStop default True;

                // advanced properties.
                property BoundLines: TdxBoundLines read FBoundLines write SetBoundLines default [];
                property Checked: Boolean read FChecked write SetChecked default False;
                property Spacing: Byte read FSpacing write SetSpacing default 3;
        end;

    { TdxCheckbox }
    TdxCheckbox =
        class( TdxCustomCheckControl)
            private
                FCheck_Grayed,
                FCheck_Normal : TBitmap;
            protected
                procedure DrawCheckSymbol( const R : TRect); override;
            public
                constructor Create( AOwner : TComponent); override;
                destructor Destroy(); override;
            published
        end;

implementation

{ TdxCustomCheckControl }

constructor TdxCustomCheckControl.Create(AOwner: TComponent);
begin
  inherited;

  // set default properties.
  ControlStyle := ControlStyle - [csDoubleClicks];
  Height := 17;
  TabStop := True;
  Width := 161;

  // set custom properties.
  FBoundLines := [];
  FChecked := False;
  FCheckSize := 13;
  FSpacing := 3;

  // create ...
  FBgGradient := TBitmap.Create; // background gradient
  FCkGradient := TBitmap.Create; // clicked gradient
  FHlGradient := TBitmap.Create; // Highlight gradient
end;

destructor TdxCustomCheckControl.Destroy;
begin
  FBgGradient.Free;
  FCkGradient.Free;
  FHlGradient.Free;
  inherited;
end;

procedure TdxCustomCheckControl.Click;
begin
  FChecked := not FChecked;
  inherited;
end;

procedure TdxCustomCheckControl.HookResized;
begin
  //
  // create gradient rectangles for...
  //

  // background.
  dxCreateGradientRect(FCheckSize - 2, FCheckSize - 2, dxColor_Btn_Enb_BgFrom_WXP,
    dxColor_Btn_Enb_BgTo_WXP, 16, gsTop, False, FBgGradient);

  // clicked.
  dxCreateGradientRect(FCheckSize - 2, FCheckSize - 2, dxColor_Btn_Enb_CkFrom_WXP,
    dxColor_Btn_Enb_CkTo_WXP, 16, gsTop, True, FCkGradient);

  // highlight.
//  dxCreateGradientRect(FCheckSize - 2, FCheckSize - 2, dxColor_Btn_Enb_HlFrom_WXP,
//    dxColor_Btn_Enb_HlTo_WXP, 16, gsTop, True, FHlGradient);
  dxCreateGradientRect( FCheckSize - 2,
                        FCheckSize - 2,
                        clWhite {dxColor_Btn_Enb_BgTo_WXP} {dxColor_Btn_Enb_HlFrom_WXP},
                        clGray {dxColor_Btn_Enb_BgFrom_WXP} {dxColor_Btn_Enb_HlTo_WXP},
                        16,
                        gsTop,
                        True,
                        FHlGradient
                      );

  // redraw.
  if not IsLocked then
    Invalidate;
end;

procedure TdxCustomCheckControl.SetBoundColor(Value: TColor);
begin
  if Value <> Color then
  begin
    FBoundColor := Value;
    if not IsLocked then
      Invalidate;
  end;
end;

procedure TdxCustomCheckControl.SetBoundLines(Value: TdxBoundLines);
begin
  if Value <> FBoundLines then
  begin
    FBoundLines := Value;
    if not IsLocked then
      Invalidate;
  end;
end;

procedure TdxCustomCheckControl.SetChecked(Value: Boolean);
begin
  if Value <> FChecked then
  begin
    FChecked := Value;
    if not IsLocked then
      Invalidate;
  end;
end;

procedure TdxCustomCheckControl.SetSpacing(Value: Byte);
begin
  if Value <> FSpacing then
  begin
    FSpacing := Value;
    if not IsLocked then
      Invalidate;
  end;
end;

procedure TdxCustomCheckControl.Paint;
var  Rect: TRect;
begin
    with Canvas do
        begin
            // clear background.
            Rect := GetClientRect;
            Brush.Color := {TdxWinControl(Parent).}Color;
            FillRect(Rect);


            // draw designtime rect.
            if csDesigning in ComponentState
                then DrawFocusRect(Rect);

            // draw boundlines.
            if FBoundLines <> []
                then begin
                         dxDrawBoundLines(Self.Canvas, FBoundLines, BoundColor, Rect);
                     end;

            // draw check symbol.
            DrawCheckSymbol(Rect);

            // draw caption.
            SetBkMode(Handle, Transparent);
            Font.Assign(Self.Font);
            Inc(Rect.Left, FCheckSize + 4 + FSpacing);
            dxPlaceText(Self, Canvas, Caption, Font, Enabled, True, taLeftJustify, True, Rect);
        end;
end;

{ TdxCheckbox }

constructor TdxCheckbox.Create(AOwner: TComponent);
var tmp : TBitmap;
begin
    inherited;
    tmp        := TBitmap.Create;
    tmp.PixelFormat := pf24bit;
    tmp.Width  := 7;
    tmp.Height := 7;

    tmp.Canvas.Brush.Color := clGray;
    tmp.Canvas.Rectangle( 0,0,7,7);
//    tmp.Handle := LoadBitmap(hInstance, 'CHECKBOX');

    // 1
    FCheck_Grayed             := TBitmap.Create;
    FCheck_Grayed.PixelFormat := pfDevice;
    FCheck_Grayed.Width       := 7;
    FCheck_Grayed.Height      := 7;
    FCheck_Grayed.TransparentColor := clSilver;
    FCheck_Grayed.Transparent      := True;
    BitBlt( FCheck_Grayed.Canvas.Handle, 0, 0, 7, 7, tmp.Canvas.Handle, 0, 0, SRCCOPY);
    dxColorizeBitmap( FCheck_Grayed, clSkyBlue);

    // 2
    FCheck_Normal             := TBitmap.Create;
    FCheck_Normal.PixelFormat := pf8bit;
    FCheck_Normal.Width       := 7;
    FCheck_Normal.Height      := 7;
    FCheck_Normal.TransparentColor := clSilver;
    FCheck_Normal.Transparent      := True;
    BitBlt( FCheck_Normal.Canvas.Handle, 0, 0, 7, 7, tmp.Canvas.Handle, 0, 0, SRCCOPY);
    dxColorizeBitmap( FCheck_Normal, clWhite);

    tmp.Destroy;
end;

destructor TdxCheckbox.Destroy;
begin
    FCheck_Grayed.Destroy;
    FCheck_Normal.Destroy;
    inherited;
end;

procedure TdxCheckbox.DrawCheckSymbol(const R: TRect);

      procedure DrawGradient(const Bitmap: TBitmap);
      begin
          BitBlt(Canvas.Handle, R.Left + 3, (ClientHeight - FCheckSize) div 2 + 1, FCheckSize - 2, FCheckSize - 2, Bitmap.Canvas.Handle, 0, 0, SRCCOPY);
      end;

var ClipW  : Integer;
begin
    // check for highlight.
    ClipW := Integer(dsHighlight in DrawState);

    // draw border
    Canvas.Pen.Color := clSilver;
    Canvas.Rectangle(Bounds(R.Left + 2, (ClientHeight - FCheckSize) div 2, FCheckSize, FCheckSize));

    // draw background.
    if not ((ClipW <> 0) and (dsClicked in DrawState))
            then begin
                     if ClipW <> 0 // Hightight
                         then DrawGradient(FHlGradient);

                     BitBlt(Canvas.Handle, R.Left + 3 + ClipW, (ClientHeight - FCheckSize) div 2 + 1 + ClipW, FCheckSize - 2 - ClipW * 2, FCheckSize - 2 - ClipW * 2, FBgGradient.Canvas.Handle, 0, 0, SRCCOPY);
                 end
            else begin
                     DrawGradient(FCkGradient);
                 end;

        // draw checked.
    if FChecked
        then begin
                 Canvas.Draw( FCheckSize div 2 - 1, (ClientHeight - FCheckSize) div 2 + 4, FCheck_Normal);
                 Canvas.Draw( FCheckSize div 2 - 1, (ClientHeight - FCheckSize) div 2 + 3, FCheck_Grayed);
             end;
end;

end.


