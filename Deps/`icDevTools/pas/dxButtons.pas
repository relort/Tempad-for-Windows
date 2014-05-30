unit dxButtons;

interface

uses
  Windows, Classes, Graphics, Controls, Forms,
  dxCore, dxCoreUtils{, TypInfo}, pngimage
  , icClasses
  , icUtils;

type
    { TdxCustomButton }
    TdxLayout = ( blGlyphLeft,
                  blGlyphRight,
                  blGlyphTop,
                  blGlyphBottom
                );

    TdxCustomButton =
        class( TdxCustomControl)
            const
                c_dxButton_cl_Default_FROM = $f5f5f5;
                c_dxButton_cl_Default_TO   = $e8e8e8;

                c_dxButton_cl_Highlight_FROM = $ffffff;
                c_dxButton_cl_Highlight_TO   = $f5f5f5;

                c_dxButton_cl_Click_FROM = $e0e0e0;
                c_dxButton_cl_Click_TO   = $f5f5f5;

                c_dxButton_cl_Disabled_FROM = $e5e5e5;
                c_dxButton_cl_Disabled_TO   = $ededed;
            private
                FImage_Default : TPicture;
                procedure ___prop_set_imageDefault( _pic : TPicture);
            protected
                function IsSpecialDrawState(IgnoreDefault: Boolean = False): Boolean;
                procedure KeyDown(var Key: Word; Shift: TShiftState); override;
                procedure KeyUp(var Key: Word; Shift: TShiftState); override;
                procedure Paint; override;
            public
                constructor Create(AOwner: TComponent); override;
                destructor Destroy; override;
                procedure HookResized; override;
            published
                property Caption;
                property Enabled;
                property TabOrder;
                property TabStop  default True;
                property Height   default 24;
                property Width    default 90;
                property ModalResult;
                property Image_Default : TPicture read FImage_Default write ___prop_set_imageDefault;
        end;

    { TdxButton }
    TdxButton = class( TdxCustomButton);

implementation

{ TdxCustomButton }

constructor TdxCustomButton.Create(AOwner: TComponent);
begin
    inherited;

    // set default properties.
    ControlStyle := ControlStyle - [csDoubleClicks];
    Height       := 24;
    Width        := 75;
    TabStop      := True;

    // imgs
    FImage_Default := TPicture.Create();
end;

destructor TdxCustomButton.Destroy;
begin
    FImage_Default.Destroy;

    inherited;
end;

procedure TdxCustomButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Shift = []) and (Key = VK_SPACE) then
  begin
    DrawState := DrawState + [dsHighlight];
    HookMouseDown;
  end;
  inherited;
end;

procedure TdxCustomButton.KeyUp(var Key: Word; Shift: TShiftState);
var
  cPos: TPoint;
begin
  //
  // it's not possible to call the 'HookMouseUp' or 'HookMouseLeave' methods,
  // because we don't want to call there event handlers.
  //
  if dsClicked in DrawState then
  begin
    GetCursorPos(cPos);
    cPos := ScreenToClient(cPos);
    if not PtInRect(Bounds(0, 0, Width, Height), cPos) then
      DrawState := DrawState - [dsHighlight];
    DrawState := DrawState - [dsClicked];
    if not IsLocked then
      Invalidate;
    Click;
  end;
  inherited;
end;

procedure TdxCustomButton.___prop_set_imageDefault( _pic : TPicture);
begin
    FImage_Default.Assign( _pic);

    if not IsLocked
        then Invalidate;
end;

function TdxCustomButton.IsSpecialDrawState(IgnoreDefault: Boolean = False): Boolean;
begin
    if dsClicked in DrawState
        then Result := not (dsHighlight in DrawState)
        else Result := (dsHighlight in DrawState) or (dsFocused in DrawState);
end;

procedure TdxCustomButton.HookResized;
begin
    inherited;

    if not IsLocked
        then Invalidate;
end;

procedure TdxCustomButton.Paint;
var Rect        : TRect;
    tmpDS       : TdxDrawState;
    textRct     : TSize;
    fontColor   : TColor;
    shadowColor : TColor;
    pressed     : Boolean;
    offsetX     : SmallInt;
begin
    // params
    tmpDS := DrawState;

    fontColor   := Font.Color;
    shadowColor := clWhite;

    pressed     := false;

    // paint
    case Enabled of
        true
            : begin
                  if ( dsDefault in tmpDS) and not ( dsHighlight in tmpDS)
                      then begin
                               icUtils.DrawGradient( Canvas.Handle, 0, 0, Width, Height, c_dxButton_cl_Default_FROM, c_dxButton_cl_Default_To);
                           end
                      else if ( dsHighlight in tmpDS) and not ( dsClicked in tmpDS)
                               then begin
                                        icUtils.DrawGradient( Canvas.Handle, 0, 0, Width, Height, c_dxButton_cl_Highlight_FROM, c_dxButton_cl_Highlight_TO);
                                    end
                               else if ( dsClicked in tmpDS)
                                        then begin
                                                 icUtils.DrawGradient( Canvas.Handle, 0, 0, Width, Height, c_dxButton_cl_Click_FROM, c_dxButton_cl_Click_TO);
                                                 pressed := true;
                                             end;

                  if ( dsFocused in tmpDS)
                      then begin // focus rect
                               Canvas.Brush.Style := bsClear;
                               Canvas.Pen.Color := clWhite;
                               Canvas.Rectangle( 0, 0, Width, Height);
                               Canvas.Pen.Color := clSilver;
                               Canvas.Rectangle( 1, 1, Width - 1, Height - 1);
                           end
                      else begin // default border
                               Canvas.Brush.Style := bsClear;
                               Canvas.Pen.Color := clSilver;
                               Canvas.Rectangle( 0, 0, Width, Height);
                               Canvas.Pen.Color := clWhite;
                               Canvas.Rectangle( 1, 1, Width - 1, Height - 1);
                           end;
            end;
        ////////
        false
            : begin
                  icUtils.DrawGradient( Canvas.Handle, 0, 0, Width, Height, c_dxButton_cl_Disabled_FROM, c_dxButton_cl_Disabled_TO);

                  Canvas.Brush.Style := bsClear;
                  Canvas.Pen.Color := clWhite;
                  Canvas.Rectangle( 0, 0, Width, Height);
                  Canvas.Pen.Color := clSilver;
                  Canvas.Rectangle( 1, 1, Width - 1, Height - 1);

                  fontColor   := clSilver;
                  shadowColor := clWhite;//Darker( clWhite, 5);
              end;
    end;


    // calcs
    Canvas.Font       := Self.Font;
    Canvas.Font.Color := fontColor;
    SetBkMode(Handle, Transparent);

    Rect  := Bounds( 0, 1, Width, Height);
    textRct := Canvas.TextExtent( Caption);
    offsetX := 0;

    if FImage_Default.Graphic <> nil
        then begin // image
                 Rect.Left := Width  div 2 - ( FImage_Default.Width + textRct.cx) div 2;
                 if Caption <> '' then Rect.Left := Rect.Left - 5;

                 Rect.Top  := Height div 2 - FImage_Default.Height div 2;
                 if pressed then rect.Top := rect.Top + 1;
                 Canvas.Draw( Rect.Left, Rect.Top, FImage_Default.Graphic);

                 offsetX := FImage_Default.Width div 2;
             end;

    // draw text
    Rect.Left := Width  div 2 - textRct.cx div 2 + offsetX + 2 {div mistakes};
    Rect.Top  := Height div 2 - textRct.cy div 2;
    if pressed then rect.Top := rect.Top + 1;
    icUtils.DrawTextWithShadow( Canvas, Caption, Rect, shadowColor, 0);
end;

end.

