unit dxLabel;

// 27.05.10 started.
// ©Pavel Bugaevskiy aka InlineCODER, 2010.
// Inline-CODER@inbox.ru

interface

uses
    Windows,
    Messages,
    SysUtils,
    Variants,
    Classes,
    Graphics,
    Controls,
    dxCore,
    dxCoreUtils,
    dxContainer,

    icClasses,
    icUtils;

type
    TdxLabel =
        class( TGraphicControl)
            type
                ictToken =
                    record
                        str : string;
                        stl : TFontStyles;
                        col : TColor;
                        wth : WORD;
                        hgt : WORD;
                        brl : byte; // breakLine Counter
                    end;

                ictTokenList =
                    array of ictToken;

            private
                FTokenList   : ictTokenList;

                FCaption     : string;
                FDrawShadow  : Boolean;
                FShadowColor : TColor;

                procedure ___prop_setCaption( _str : string);
                procedure ___prop_setDrawShadow( _drawShadow : boolean);
                procedure ___prop_setShadowColor( _shadowColor : TColor);
            private
                procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
            private
                procedure ParseToTokens( out _destTokenList : ictTokenList; _str : string; _defCol : TColor = clBlack);
                procedure ValidateWidth;
            public
                constructor Create( _Owner : TComponent); override;
                destructor Destroy; override;
            public
                procedure Paint; override;
            published
                property Left;
                property Top;
                property Width;
                property Height;
                property Font;
                property Color;
                property Visible;
                property Enabled;
                property Align;
                property Anchors;

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
            published
                property Caption     : string  read FCaption     write ___prop_setCaption;
                property DrawShadow  : Boolean read FDrawShadow  write ___prop_setDrawShadow;
                property ShadowColor : TColor  read FShadowColor write ___prop_setShadowColor;
        end;

implementation

{ TdxLabel }

constructor TdxLabel.Create(_Owner: TComponent);
begin
    inherited;
    FCaption     := Name;
    FDrawShadow  := True;
    FShadowColor := clGray;
end;

destructor TdxLabel.Destroy;
begin
    inherited;
end;

procedure TdxLabel.___prop_setCaption(_str: string);
begin
    if FCaption = _str
        then Exit;
    _str := StringReplace( _str, #13#10, '[br]', [rfReplaceAll]);
    FCaption := _str;


    ParseToTokens( FTokenList, _str, font.Color);
    ValidateWidth;
    Invalidate;
end;

procedure TdxLabel.___prop_setDrawShadow( _drawShadow : boolean);
begin
    if FDrawShadow = _drawShadow
        then exit;
    FDrawShadow := _drawShadow;


    Invalidate;
end;

procedure TdxLabel.___prop_setShadowColor( _shadowColor : TColor);
begin
    if FShadowColor = _shadowColor
        then exit;
    FShadowColor := _shadowColor;


    Invalidate;
end;

procedure TdxLabel.CMFontChanged(var Message: TMessage);
begin
    Canvas.Font.Assign( Font);

    ValidateWidth();
    Invalidate();
end;

procedure TdxLabel.ParseToTokens(out _destTokenList: ictTokenList; _str: string; _defCol: TColor);
var ndx    : SmallInt;
    strLen : SmallInt;
    tmpStr : string;
    tmpStl : TFontStyles;
    tmpCol : TColor;
    tmpBrl : Byte;

    function CharPos( _str : string; _destChar : Char; _startPos : SmallInt) : SmallInt; inline;
    begin
        Result := -1;
        while (_str[_startPos] <> _destChar) and (_startPos <= Length( _str)) do
            _startPos := _startPos + 1;

        if _str[_startPos] = _destChar
            then Result := _startPos;
    end;

    procedure ProcessTag( _tag : string; _include : boolean = true);
    var strLen : SmallInt;
        tagPrm : string;
        delPos : SmallInt;
    begin
        strLen   := Length( _tag);
        delPos   := LastDelimiter( '=', _tag);
        if delPos <> 0
            then tagPrm  := Copy( _tag, delPos+1, strLen);
        if tagPrm <> ''
            then _tag    := Copy( _tag, 1, delPos-1); // extract param from tag

        if _include
            then begin
                     if _tag = 'b'
                         then Include( tmpStl, fsBold);

                     if _tag = 'i'
                         then Include( tmpStl, fsItalic);

                     if _tag = 'u'
                         then Include( tmpStl, fsUnderline);

                     if _tag = 's'
                         then Include( tmpStl, fsStrikeOut);

                     if _tag = 'br'            // only including
                         then tmpBrl := tmpBrl + 1;

                     if _tag = 'color'
                         then tmpCol := StrToInt( tagPrm);
                 end
            else begin
                     if _tag = 'b'
                         then Exclude( tmpStl, fsBold);

                     if _tag = 'i'
                         then Exclude( tmpStl, fsItalic);

                     if _tag = 'u'
                         then Exclude( tmpStl, fsUnderline);

                     if _tag = 's'
                         then Exclude( tmpStl, fsStrikeOut);

                     if _tag = 'color'
                         then tmpCol := _defCol;
                 end;

        ndx := ndx + strLen; // cover the tag length [i] - must be covered 1   |  [asdas] - 5
    end;

    procedure AddToken();
    var len : Integer;
    begin
        if tmpStr <> ''
            then begin
                     len := Length( _destTokenList);
                     SetLength( _destTokenList, Len + 1);

                     with _destTokenList[Len] do
                         begin
                             stl := tmpStl;
                             str := tmpStr;
                             col := tmpCol;
                             brl := tmpBrl;
                         end;

                     tmpStr := '';
                     tmpBrl := 0;
                 end;
    end;

begin
     SetLength( _destTokenList, 0);
     strLen := Length( _str);
     tmpStr := '';
     tmpStl := [];
     tmpCol := _defCol;
     tmpBrl := 0;

     if _str = ''
         then exit; // no need to process null-string

     ndx := 1;
     while ndx <= strLen+1 do // '+1' to catch the last token
         begin
             if ( ndx > strLen) or ( _str[ndx] = '[')
                 then begin // processing
                          ndx := ndx + 1 + Byte(_str[ndx+1] = '/'); // for '[' and '/' if encountered

                          AddToken;

                          //ProcessTag( _str[ndx], _str[ndx-1] <> '/'); // single char params, such as B I U
                          ProcessTag( Copy( _str, ndx, CharPos( _str, ']', ndx) - ndx), _str[ndx-1] <> '/'); // multichar params, such as COLOR
                      end
                 else begin // tmpStr grow
                          tmpStr := tmpStr + _str[ndx];
                      end;

             ndx := ndx + 1; // pass encountered symbol ( ']' or another one)
         end;
end;

procedure TdxLabel.ValidateWidth;
var //defaultHeight : Word;
    ndx : SmallInt;
    old : TFontStyles;

    tExt : TSize;

//    tmp    : Integer;
    tmpRct : TRect;
begin
    Canvas.Font.Assign( Font);

    old := Canvas.Font.Style;

    //defaultHeight := Canvas.TextHeight( 'gG');

    for ndx := 0 to Length( FTokenList) - 1 do
        begin
            Canvas.Font.Style := FTokenList[ndx].stl;

            tExt := Canvas.TextExtent( FTokenList[ndx].str);

            tmpRct := Bounds( 0, 0, Width, Height);
            //tmp := DrawTextEx( Canvas.Handle, pchar( FTokenList[ndx].str), -1, tmpRct, DT_LEFT or DT_WORDBREAK or DT_CALCRECT, nil);

            tExt := Canvas.TextExtent(FTokenList[ndx].str);
            FTokenList[ndx].wth := {tmpRct.Right; //}tExt.cx;
            FTokenList[ndx].hgt := tmpRct.Bottom;
        end;

    Canvas.Font.Style := old;
end;

procedure TdxLabel.Paint;
var defaultHeight : Word;

    ndx : SmallInt;
    rct : TRect;
    ofs : integer;
begin
    rct := ClientRect;
    Canvas.Font.Assign( Font);

    if GetBkMode( Canvas.Handle) <> TRANSPARENT
        then SetBkMode( Canvas.Handle, TRANSPARENT);

    defaultHeight := Canvas.TextHeight( 'gM');


    ofs := 0;
    for ndx := 0 to Length( FTokenList) - 1 do
        begin
            if FTokenList[ndx].brl > 0
                then begin
                         rct.Top := rct.Top + ( defaultHeight * FTokenList[ndx].brl);

                         rct.Left := 0;
                         ofs      := 0;
                     end;
            rct.Left := ofs + 1;


            Canvas.Font.Style := FTokenList[ndx].stl;
            Canvas.Font.Color := FTokenList[ndx].col;

            if FDrawShadow
                then DrawTextWithShadow( Canvas,
                                         FTokenList[ndx].str,
                                         rct,
                                         FShadowColor,
                                         DT_LEFT or DT_WORDBREAK
                                       )
                else DrawText( Canvas.Handle,
                               FTokenList[ndx].str,
                               Length( FTokenList[ndx].str),
                               rct,
                               DT_LEFT or DT_WORDBREAK
                             );

            ofs := ofs + FTokenList[ndx].wth;
        end;
end;

end.