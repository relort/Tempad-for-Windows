unit dxCore;

interface

uses
    Windows
  , Messages
  , Classes
  , Controls
  , Graphics
  , Forms;

const
  { color constants.

    these constants are used as default colors for descendant controls
    and may be replaced with other (common) values.

    syntax: dxColor_[Control]_[Enabled: Enb, Dis]_[Type]_[Theme: WXP, OXP]     }

  { button colors - WindowsXP }
  dxColor_Btn_Enb_Border_WXP   = $00733800; // border line
  dxColor_Btn_Dis_Border_WXP   = $00BDC7CE; // border line (disabled)
  dxColor_Btn_Enb_Edges_WXP    = $00AD9E7B; // border edges
  dxColor_Btn_Dis_Edges_WXP    = $00BDC7CE; // border edges (disabled)
  dxColor_Btn_Enb_BgFrom_WXP   = $00FFFFFF; // background from
  dxColor_Btn_Enb_BgTo_WXP     = $00E7EBEF; // background to
  dxColor_Btn_Enb_CkFrom_WXP   = $00C6CFD6; // clicked from
  dxColor_Btn_Enb_CkTo_WXP     = $00EBF3F7; // clicked to
  dxColor_Btn_Enb_FcFrom_WXP   = $00FFE7CE; // focused from
  dxColor_Btn_Enb_FcTo_WXP     = $00EF846D; // focused to
  dxColor_Btn_Enb_HlFrom_WXP   = $00CEF3FF; // highlight from
  dxColor_Btn_Enb_HlTo_WXP     = $000096E7; // highlight to

  { checkbox colors - WindowsXP }
  dxColor_Chk_Enb_Border_WXP   = $00845118; // border line
  dxColor_Chk_Enb_NmSymb_WXP   = $0021A621; // symbol normal

  { misc colors - WindowsXP }
  dxColor_Msc_Dis_Caption_WXP  = $0094A6A5; // caption color (disabled)

  dxColor_DotNetFrame          = $00F7FBFF; // $00E7EBEF;
  dxColor_BorderLineOXP        = $00663300;
  dxColor_BgOXP                = $00D6BEB5;
  dxColor_BgCkOXP              = $00CC9999;

type

{ TdxBoundLines }

  TdxBoundLines = set of (
    blLeft,                             // left line
    blTop,                              // top line
    blRight,                            // right line
    blBottom                            // bottom line
  );

{ TdxControlStyle }

  TdxControlStyle = set of (
    csRedrawCaptionChanged,             // (default)
    csRedrawBorderChanged,              //
    csRedrawEnabledChanged,             // (default)
    csRedrawFocusedChanged,             // (default)
    csRedrawMouseDown,                  // (default)
    csRedrawMouseEnter,                 // (default)
    csRedrawMouseLeave,                 // (default)
    csRedrawMouseMove,                  //
    csRedrawMouseUp,                    // (default)
    csRedrawParentColorChanged,         // (default)
    csRedrawParentFontChanged,          //
    csRedrawPosChanged,                 //
    csRedrawResized                     //
  );

{ TdxDrawState }

  TdxDrawState = set of (
    dsDefault,                          // default
    dsHighlight,                        // highlighted
    dsClicked,                          // clicked
    dsFocused                           // focused
  );

{ TdxGlyphLayout }

  TdxGlyphLayout = (
    glBottom,                           // bottom glyph
    glCenter,                           // centered glyph
    glTop                               // top glyph
  );

{ TdxCustomComponent

  baseclass for non-focusable component descendants. }

    TdxCustomComponent =
        class( TComponent)
            constructor Create( AOwner : TComponent); override;
        end;

{ TdxWinControl }

    TdxWinControl =
        class( TWinControl)
            published
                property Color;
        end;

{ TdxCustomControl

  baseclass for focusable control descendants. }

    TdxCustomControl =
        class( TCustomControl)
            private
                // inline-coder
                FOnDestroy : TNotifyEvent;
                //

                FClicking     : Boolean;
                FDrawState    : TdxDrawState;
                FIsLocked     : Boolean;
                FIsSibling    : Boolean;
                FModalResult  : TModalResult;
                FOnMouseLeave : TNotifyEvent;
                FOnMouseEnter : TNotifyEvent;
                procedure CMDialogChar(var Message: TCMDialogChar); message CM_DIALOGCHAR;
                procedure CMBorderChanged(var Message: TMessage); message CM_BORDERCHANGED;
                procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
                procedure CMFocusChanged(var Message: TMessage); message CM_FOCUSCHANGED;
                procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
                procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
                procedure CMParentColorChanged(var Message: TMessage); message CM_PARENTCOLORCHANGED;
                procedure CMParentFontChanged(var Message: TMessage); message CM_PARENTFONTCHANGED;
                procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
                procedure WMMouseMove(var Message: TWMMouse); message WM_MOUSEMOVE;
                procedure WMSize(var Message: TWMSize); message WM_SIZE;
                procedure WMWindowPosChanged(var Message: TWMWindowPosChanged); message WM_WINDOWPOSCHANGED;
            protected
                ExControlStyle: TdxControlStyle;
                procedure InternalRedraw; dynamic;
                procedure HookBorderChanged; dynamic;
                procedure HookEnabledChanged; dynamic;
                procedure HookFocusedChanged; dynamic;
                procedure HookMouseDown; dynamic;
                procedure HookMouseEnter; dynamic;
                procedure HookMouseLeave; dynamic;
                procedure HookMouseMove(X: Integer = 0; Y: Integer = 0); dynamic;
                procedure HookMouseUp; dynamic;
                procedure HookParentColorChanged; dynamic;
                procedure HookParentFontChanged; dynamic;
                procedure HookPosChanged; dynamic;
                procedure HookResized; dynamic;
                procedure HookTextChanged; dynamic;
                procedure MouseDown(Button:TMouseButton; Shift: TShiftState; X, Y: Integer); override;
                procedure MouseUp(Button:TMouseButton; Shift:TShiftState; X, Y: Integer); override;
                property ModalResult: TModalResult read FModalResult write FModalResult default 0;
            public
                constructor Create(AOwner: TComponent); override;
                destructor Destroy(); override;
                procedure Click; override;
                procedure BeginUpdate; dynamic;
                procedure EndUpdate; dynamic;
                property Canvas;
                property DrawState: TdxDrawState read FDrawState write FDrawState;
                property IsLocked: Boolean read FIsLocked write FIsLocked;
                property IsSibling: Boolean read FIsSibling write FIsSibling;
            published
                //property BevelInner;
                //property BevelOuter;
                //property BevelWidth;
                //property BiDiMode;
                //property Ctl3D;
                //property DockSite;
                //property ParentBiDiMode;
                //property ParentCtl3D;
                //property TabOrder;
                //property TabStop;
                //property UseDockManager default True;
                property Align;
                property Anchors;
                //property AutoSize;
                property Constraints;
                property DragCursor;
                property DragKind;
                property DragMode;
                //property Enabled;
                property Font;
                property ParentFont;
                property ParentShowHint;
                property PopupMenu;
                property ShowHint;
                property Visible;
                //property OnDockDrop;
                //property OnDockOver;
                //property OnEndDock;
                //property OnGetSiteInfo;
                //property OnStartDock;
                //property OnUnDock;
                property OnCanResize;
                property OnClick;
                property OnConstrainedResize;
              {$IFDEF VER140} // Borland Delphi 6.0
                property OnContextPopup;
              {$ENDIF}
                property OnDragDrop;
                property OnDragOver;
                property OnEndDrag;
                property OnEnter;
                property OnExit;
                property OnKeyDown;
                property OnKeyPress;
                property OnKeyUp;
                property OnMouseDown;
                property OnMouseEnter: TNotifyEvent read FOnMouseEnter write FOnMouseEnter;
                property OnMouseLeave: TNotifyEvent read FOnMouseLeave write FOnMouseLeave;
                property OnMouseMove;
                property OnMouseUp;
                property OnStartDrag;

                //
                property OnDestroy : TNotifyEvent read FOnDestroy write FOnDestroy;
        end;

{ TdxUnlimitedControl }

    TdxUnlimitedControl =
        class(TdxCustomControl);

{ TdxGradient }

    TdxGradientColors = 2..255;

    TdxGradientStyle = (gsLeft, gsTop, gsRight, gsBottom);

    TdxGradient =
        class( TPersistent)
            private
                FColors        : TdxGradientColors;
                FDithered      : Boolean;
                FEnabled       : Boolean;
                FEndColor      : TColor;
                FStartColor    : TColor;
                FGradientStyle : TdxGradientStyle;
           protected
                Parent: TdxCustomControl;
                procedure SetDithered(Value: Boolean); virtual;
                procedure SetColors(Value: TdxGradientColors); virtual;
                procedure SetEnabled(Value: Boolean); virtual;
                procedure SetEndColor(Value: TColor); virtual;
                procedure SetGradientStyle(Value: TdxGradientStyle); virtual;
                procedure SetStartColor(Value: TColor); virtual;
           public
                Bitmap: TBitmap;
                constructor Create(AOwner: TControl);
                destructor Destroy; override;
                procedure RecreateBands; virtual;
           published
                property Dithered: Boolean read FDithered write SetDithered default True;
                property Colors: TdxGradientColors read FColors write SetColors default 16;
                property Enabled: Boolean read FEnabled write SetEnabled default False;
                property EndColor: TColor read FEndColor write SetEndColor default clSilver;
                property StartColor: TColor read FStartColor write SetStartColor default clGray;
                property Style: TdxGradientStyle read FGradientStyle write SetGradientStyle default gsLeft;
        end;

{$R ./../res/dxCore.res}

implementation

uses
  dxCoreUtils;

{ TdxCustomComponent }

constructor TdxCustomComponent.Create(AOwner: TComponent);
begin
  inherited;
end;

{ TdxCustomControl }

constructor TdxCustomControl.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque, csReplicatable];
  DoubleBuffered := True;
  ExControlStyle := [csRedrawEnabledChanged, csRedrawFocusedChanged,
    csRedrawMouseDown, csRedrawMouseEnter, csRedrawMouseLeave, csRedrawMouseUp,
    csRedrawParentColorChanged, csRedrawCaptionChanged];
  FClicking := False;
  FDrawState := [dsDefault];
  FIsLocked := False;
  FIsSibling := False;
  FModalResult := 0;
end;

destructor tdxCustomControl.Destroy();
begin
    if Assigned( FOnDestroy)
        then FOnDestroy( self);
    inherited;
end;

procedure TdxCustomControl.BeginUpdate;
begin
  FIsLocked := True;
end;

procedure TdxCustomControl.EndUpdate;
begin
  FIsLocked := False;
  InternalRedraw;
end;

procedure TdxCustomControl.InternalRedraw;
begin
  if not FIsLocked then
    Invalidate;
end;

procedure TdxCustomControl.CMDialogChar(var Message: TCMDialogChar);
begin
  with Message do
  if IsAccel(CharCode, Caption) and CanFocus and (Focused or
    ((GetKeyState(VK_MENU) and $8000) <> 0)) then
  begin
    Click;
    Result := 1;
  end
  else
    inherited;
end;

procedure TdxCustomControl.CMBorderChanged(var Message: TMessage);
begin
  // deligate message "BorderChanged" to hook.
  inherited;
  HookBorderChanged;
end;

procedure TdxCustomControl.CMEnabledChanged(var Message: TMessage);
begin
  // deligate message "EnabledChanged" to hook.
  inherited;
  HookEnabledChanged;
end;

procedure TdxCustomControl.CMFocusChanged(var Message: TMessage);
begin
  // deligate message "FocusChanged" to hook.
  inherited;
  HookFocusedChanged;
end;

procedure TdxCustomControl.CMMouseEnter(var Message: TMessage);
begin
  // deligate message "MouseEnter" to hook.
  inherited;
  HookMouseEnter;
end;

procedure TdxCustomControl.CMMouseLeave(var Message: TMessage);
begin
  // deligate message "MouseLeave" to hook.
  inherited;
  HookMouseLeave;
end;

procedure TdxCustomControl.CMParentColorChanged(var Message: TMessage);
begin
  // deligate message "ParentColorChanged" to hook.
  inherited;
  HookParentColorChanged;
end;

procedure TdxCustomControl.CMParentFontChanged(var Message: TMessage);
begin
  // deligate message "ParentFontChanged" to hook.
  inherited;
  HookParentFontChanged;
end;

procedure TdxCustomControl.CMTextChanged(var Message: TMessage);
begin
  // deligate message "TextChanged" to hook.
  inherited;
  HookTextChanged;
end;

procedure TdxCustomControl.WMMouseMove(var Message: TWMMouse);
begin
  // deligate message "MouseMove" to hook.
  inherited;
  HookMouseMove(Message.XPos, Message.YPos);
end;

procedure TdxCustomControl.WMSize(var Message: TWMSize);
begin
  // deligate message "Size" to hook.
  inherited;
  HookResized;
end;

procedure TdxCustomControl.WMWindowPosChanged(var Message: TWMWindowPosChanged);
begin
  // deligate message "WindowPosChanged" to hook.
  inherited;
  HookPosChanged;
end;

procedure TdxCustomControl.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  // deligate message "MouseDown" to hook.
  inherited;
  if Button = mbLeft then
  begin
    FClicking := True;
    HookMouseDown;
  end;
end;

procedure TdxCustomControl.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  // deligate message "MouseUp" to hook.
  inherited;
  if FClicking then
  begin
    FClicking := False;
    HookMouseUp;
  end;
end;

procedure TdxCustomControl.Click;
var
  Form: TCustomForm;
begin
  Form := GetParentForm(Self);
  if Form <> nil then
    Form.ModalResult := ModalResult;
  inherited Click;
end;

//
// hooks are used to interrupt default windows messages in an easier
// way - it's possible to override them in descedant classes.
// Beware of multiple redraw calls - if you know that the calling
// hooks always redraws the component, use the lock i.e. unlock methods.
//

procedure TdxCustomControl.HookBorderChanged;
begin
  // this hook is called, if the border property was changed.
  // in that case we normaly have to redraw the control.
  if csRedrawBorderChanged in ExControlStyle then
    InternalRedraw;
end;

procedure TdxCustomControl.HookEnabledChanged;
begin
  // this hook is called, if the enabled property was switched.
  // in that case we normaly have to redraw the control.
  if csRedrawEnabledChanged in ExControlStyle then
    InternalRedraw;
end;

procedure TdxCustomControl.HookFocusedChanged;
begin
  // this hook is called, if the currently focused control was changed.
  if Focused then
    Include(FDrawState, dsFocused)
  else
  begin
    Exclude(FDrawState, dsFocused);
    Exclude(FDrawState, dsClicked);
  end;
  FIsSibling := GetParentForm(Self).ActiveControl is TdxCustomControl;
  if csRedrawFocusedChanged in ExControlStyle then
    InternalRedraw;
end;

procedure TdxCustomControl.HookMouseEnter;
begin
  // this hook is called, if the user moves (hover) the mouse over the control.
  Include(FDrawState, dsHighlight);
  if csRedrawMouseEnter in ExControlStyle then
    InternalRedraw;
  if Assigned(FOnMouseEnter) then
    FOnMouseEnter(Self);
end;

procedure TdxCustomControl.HookMouseLeave;
begin
  // this hook is called, if the user moves the mouse away (unhover) from
  // the control.
  Exclude(FDrawState, dsHighlight);
  if csRedrawMouseLeave in ExControlStyle then
    InternalRedraw;
  if Assigned(FOnMouseLeave) then
    FOnMouseLeave(Self);
end;

procedure TdxCustomControl.HookMouseMove(X: Integer = 0; Y: Integer = 0);
begin
  // this hook is called if the user moves the mouse inside the control.
  if csRedrawMouseMove in ExControlStyle then
    InternalRedraw;
end;

procedure TdxCustomControl.HookMouseDown;
begin
  // this hook is called, if the user presses the left mouse button over the
  // controls.
  if not Focused and CanFocus then
    SetFocus;
  Include(FDrawState, dsClicked);
  if csRedrawMouseDown in ExControlStyle then
    InternalRedraw;
end;

procedure TdxCustomControl.HookMouseUp;
var
  cPos: TPoint;
  NewControl: TWinControl;
begin
  // this hook is called, if the user releases the left mouse button.
  begin
    Exclude(FDrawState, dsClicked);
    if csRedrawMouseUp in ExControlStyle then
      InternalRedraw;

    // does the cursor is over another supported control?
    GetCursorPos(cPos);
    NewControl := FindVCLWindow(cPos);
    if (NewControl <> nil) and (NewControl <> Self) and
      (NewControl.InheritsFrom(TdxCustomControl)) then
      TdxCustomControl(NewControl).HookMouseEnter;
  end;
end;

procedure TdxCustomControl.HookParentColorChanged;
begin
  // this hook is called if, the parent color was changed.
  if csRedrawParentColorChanged in ExControlStyle then
    InternalRedraw;
end;

procedure TdxCustomControl.HookParentFontChanged;
begin
  // this hook is called if, the parent font was changed.
  if csRedrawParentFontChanged in ExControlStyle then
    InternalRedraw;
end;

procedure TdxCustomControl.HookPosChanged;
begin
  // this hook is called, if the window position was changed.
  if csRedrawPosChanged in ExControlStyle then
    InternalRedraw;
end;

procedure TdxCustomControl.HookResized;
begin
  // this hook is called, if the control was resized.
  if csRedrawResized in ExControlStyle then
    InternalRedraw;
end;

procedure TdxCustomControl.HookTextChanged;
begin
  // this hook is called, if the caption was changed.
  if csRedrawCaptionChanged in ExControlStyle then
    InternalRedraw;
end;

{ TdxGradient }

constructor TdxGradient.Create(AOwner: TControl);
begin
  inherited Create;
  Parent := TdxCustomControl(AOwner);
  Bitmap := TBitmap.Create;
  FColors := 16;
  FDithered := True;
  FEnabled := False;
  FEndColor := clSilver;
  FGradientStyle := gsLeft;
  FStartColor := clGray;
end;

destructor TdxGradient.Destroy;
begin
  Bitmap.Free;
  inherited Destroy;
end;

procedure TdxGradient.RecreateBands;
begin
  if Assigned(Bitmap) then
    dxCreateGradientRect(Parent.Width, Parent.Height, FStartColor, FEndColor,
      FColors, FGradientStyle, FDithered, Bitmap);
end;

procedure TdxGradient.SetDithered(Value: Boolean);
begin
  if FDithered <> Value then
  begin
    FDithered := Value;
    RecreateBands;
    Parent.InternalRedraw;
  end;
end;

procedure TdxGradient.SetColors(Value: TdxGradientColors);
begin
  if FColors <> Value then
  begin
    FColors := Value;
    RecreateBands;
    Parent.InternalRedraw;
  end;
end;

procedure TdxGradient.SetEnabled(Value: Boolean);
begin
  if FEnabled <> Value then
  begin
    FEnabled := Value;
    Parent.InternalRedraw;
  end;
end;

procedure TdxGradient.SetEndColor(Value: TColor);
begin
  if FEndColor <> Value then
  begin
    FEndColor := Value;
    RecreateBands;
    Parent.InternalRedraw;
  end;
end;

procedure TdxGradient.SetGradientStyle(Value: TdxGradientStyle);
begin
  if FGradientStyle <> Value then
  begin
    FGradientStyle := Value;
    RecreateBands;
    Parent.InternalRedraw;
  end;
end;

procedure TdxGradient.SetStartColor(Value: TColor);
begin
  if FStartColor <> Value then
  begin
    FStartColor := Value;
    RecreateBands;
    Parent.InternalRedraw;
  end;
end;

end.

