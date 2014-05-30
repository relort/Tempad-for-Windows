unit dxExtLabel;

interface

uses
    Windows
  , Messages
  , SysUtils
  , Variants
  , Classes
  , Graphics
  , Controls
  , dxCore
  , dxCoreUtils
  , dxContainer

  , icClasses
  , icUtils
  ;

type
    TdxExtLabel =
        class( TGraphicControl)
            private
                FCaption        : String;
                FCaption_Plain  : String;
                FShadow_Enabled : Boolean;
                FShadow_Color   : TColor;
            private
                procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
            protected
                procedure ___prop_setCaption       ( _str : String);
                procedure ___prop_setShadow_Enabled( _val : Boolean);
                procedure ___prop_setShadow_Color  ( _col : TColor);
            public
                constructor Create( _owner : TComponent); override;
                destructor Destroy(); override;
            public
                procedure Paint(); override;
            published
                property Caption       : String  read FCaption        write ___prop_setCaption; // text that was set
                //property CaptionPlain  : String  read FCaption_Plain;                           // get text without formatting
                property ShadowEnabled : Boolean read FShadow_Enabled write ___prop_setShadow_Enabled;
                property ShadowColor   : TColor  read FShadow_Color   write ___prop_setShadow_Color;
            published
                property Font;
                property Color;
                property Visible;
                property Enabled;
                property Align;
                property Anchors;
                property Left;
                property Top;
                property Width;
                property Height;
            published
                property OnCanResize;
                property OnClick;
                property OnConstrainedResize;
                property OnContextPopup;
                property OnDblClick;
                property OnDragDrop;
                property OnDragOver;
                property OnEndDock;
                property OnEndDrag;
                property OnMouseActivate;
                property OnMouseDown;
                property OnMouseEnter;
                property OnMouseLeave;
                property OnMouseMove;
                property OnMouseUp;
                property OnMouseWheel;
                property OnMouseWheelDown;
                property OnMouseWheelUp;
                property OnResize;
                property OnStartDock;
                property OnStartDrag;
        end;

implementation

procedure TdxExtLabel.CMFontChanged(var Message: TMessage);
begin
    Canvas.Font.Assign( Font);
    Invalidate();
end;

procedure TdxExtLabel.___prop_setCaption       ( _str : String);
begin
    if FCaption = _str
        then exit;

    FCaption := _str;
    FCaption_Plain := complexTextToPlainText( Canvas, FCaption);

    Invalidate();
end;

procedure TdxExtLabel.___prop_setShadow_Enabled( _val : Boolean);
begin
    if _val = FShadow_Enabled
        then exit;

    FShadow_Enabled := _val;
    Invalidate();
end;

procedure TdxExtLabel.___prop_setShadow_Color  ( _col : TColor);
begin
    if _col = FShadow_Color
        then exit;

    FShadow_Color := _col;
    Invalidate();
end;

constructor TdxExtLabel.Create( _owner : TComponent);
begin
    if not ( _owner is TWinControl)
        then raise iccException.Create( 'TdxExtLabel.Create() -> _owner must be TWinControl.');


    inherited;
    Parent := TWinControl( _owner);


    FCaption        := '';
    FCaption_Plain  := '';
    FShadow_Enabled := True;
    FShadow_Color   := clWhite;

    Canvas.Font.Assign( Font);
end;

destructor TdxExtLabel.Destroy();
begin
    inherited;
end;

procedure TdxExtLabel.Paint();
begin
    drawComplexText( Canvas, FCaption, ClientRect, FShadow_Enabled, FShadow_Color);
end;

end.
