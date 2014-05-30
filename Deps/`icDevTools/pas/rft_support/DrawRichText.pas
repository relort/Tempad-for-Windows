{
  DrawRichText.pas

  Function to draw formatted text (RTF) onto a VCL canvas.

  Version 1.3d - always find the most current version at
  http://flocke.vssd.de/prog/code/pascal/rtflabel/

  Copyright (C) 2006-2009 Volker Siebert <flocke@vssd.de>
  All rights reserved.

  Permission is hereby granted, free of charge, to any person obtaining a
  copy of this software and associated documentation files (the "Software"),
  to deal in the Software without restriction, including without limitation
  the rights to use, copy, modify, merge, publish, distribute, sublicense,
  and/or sell copies of the Software, and to permit persons to whom the
  Software is furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
  DEALINGS IN THE SOFTWARE.


  ///////////////////////////////////////////////////////////////////////////
  /// refactor and update/bug-fixing: Inline-CODER, 2011.
}

unit DrawRichText;

interface

//{$I DelphiVersion.inc}
//{$I Rich3Conf.inc}

uses
    Windows
  , Messages
  , SysUtils
  , Graphics
  , Classes

  , ActiveX
  , ComObj
  , RichEditDll
  , RichEdit
  , RichEdit2
  , TextServ
  , DelphiTextServ
  ;

type
    TRtfTextFormats = ( rtfBottom,
                        rtfCalcRect,
                        rtfCenter,
                        rtfLeft,
                        rtfRight,
                        rtfTop,
                        rtfVerticalCenter,
                        rtfWordBreak
                      );

    TRtfTextFormat = set of TRtfTextFormats;

    TDrawRtfText =
        class( TTextServices)
            private
                FCalcRect   : TRect;
                FCanvas     : TCanvas;
                FCharFormat : TCharFormatW;
                FFormat     : TRtfTextFormat;
                FRect       : TRect;
            protected
                // ITextHost interface
                function TxGetDC: HDC; override; stdcall;
                function TxReleaseDC(dc: HDC): integer; override; stdcall;
                function TxGetCharFormat(out ppCF: PCharFormatW): HRESULT; override; stdcall;
                function TxGetClientRect(out rc: TRect): HRESULT; override; stdcall;
                function TxGetSysColor(nIndex: Integer): COLORREF; override; stdcall;
                function TxNotify(iNotify: DWORD; pv: Pointer): HRESULT; override; stdcall;
                procedure TxViewChange(fUpdate: BOOL); override; stdcall;
            public
                constructor Create( _Canvas: TCanvas;
                                    const _Rect: TRect;
                                    const _Text: AnsiString;
                                    _TextFormat: TRtfTextFormat;
                                    _Zoom: Integer
                                  ); overload;
                destructor Destroy; override;
            public
                function Draw( _Really : Boolean) : Boolean;
                function PlainText( _maxSize : SmallInt) : String;
            public
                property CalcRect : TRect read FCalcRect;
        end;


function RTFText_Draw( _Canvas     : TCanvas;
                       var _Rect   : TRect;
                       _Text       : String;
                       _TextFormat : TRtfTextFormat = [];
                       _Zoom       : Integer        = 100
                     ) : Boolean;

function RTFText_Plain( _canvas : TCanvas; _str : String) : String;


implementation

{ TDrawRFTText }

constructor TDrawRtfText.Create(_Canvas: TCanvas; const _Rect: TRect; const _Text: AnsiString; _TextFormat: TRtfTextFormat; _Zoom: Integer);
var FontName : WideString;
    stx      : TSetTextEx;
begin
    FCanvas   := _Canvas;
    FRect     := _Rect;
    FFormat   := _TextFormat;
    FCalcRect := _Rect;

    FillChar(FCharFormat, SizeOf(FCharFormat), 0);
    FCharFormat.cbSize := SizeOf(FCharFormat);
    FCharFormat.dwMask := Integer(CFM_ALL);

    if fsBold in _Canvas.Font.Style
        then FCharFormat.dwEffects := FCharFormat.dwEffects or CFE_BOLD;

    if fsItalic in _Canvas.Font.Style
        then FCharFormat.dwEffects := FCharFormat.dwEffects or CFE_ITALIC;

    if fsUnderline in _Canvas.Font.Style
        then FCharFormat.dwEffects := FCharFormat.dwEffects or CFE_UNDERLINE;

    FCharFormat.yHeight := 20 * _Canvas.Font.Size;
    FCharFormat.crTextColor := ColorToRGB(_Canvas.Font.Color);

    if _Canvas.Font.Color = clWindowText
        then FCharFormat.dwEffects := FCharFormat.dwEffects or CFE_AUTOCOLOR;

    FCharFormat.bCharSet := _Canvas.Font.Charset;
    FCharFormat.bPitchAndFamily := DEFAULT_PITCH;
    FontName := _Canvas.Font.Name;
    LStrCpyW(FCharFormat.szFaceName, PWideChar(FontName));

    inherited Create; // CREATING

    SendMsg(EM_SETEVENTMASK, 0, ENM_REQUESTRESIZE);

    if rtfWordbreak in FFormat
        then PropertyBits := TXTBIT_RICHTEXT or TXTBIT_MULTILINE or TXTBIT_WORDWRAP
        else PropertyBits := TXTBIT_RICHTEXT or TXTBIT_MULTILINE;

    if RichEditVersion >= rvRichEdit4
        then SendMsg( EM_SETTYPOGRAPHYOPTIONS,
                      TO_ADVANCEDTYPOGRAPHY or TO_ADVANCEDLAYOUT,
                      TO_ADVANCEDTYPOGRAPHY or TO_ADVANCEDLAYOUT);
                      SendMsg(EM_AUTOURLDETECT,
                      0,
                      0
                    );

    stx.flags    := ST_DEFAULT;
    stx.codepage := CP_ACP;
    SendMsg( EM_SETTEXTEX, LongInt(@stx), LongInt(PAnsiChar(_Text)));

    if (_Zoom >= 2) and (_Zoom <= 6400)
        then SendMsg( EM_SETZOOM, _Zoom, 100);

    // Force a size notification
    SendMsg( EM_REQUESTRESIZE, 0, 0);
end;

destructor TDrawRtfText.Destroy;
begin
  inherited;
end;

function TDrawRtfText.Draw( _Really: Boolean) : Boolean;
var dc      : HDC;
    rc, rc2 : TRect;
    pt, pt2 : TPoint;
    d       : Integer;
begin
    dc := FCanvas.Handle;

    SetWindowOrgEx( dc, 0, 0, @pt);
    OffsetViewportOrgEx( dc, -pt.x, -pt.y, pt2);

    try
        rc := FRect;
        rc2 := rc;

        if _Really
            then begin
                     with FCalcRect do
                         d := Right - Left;

                     if rtfRight in FFormat
                         then rc.Left := rc.Right - d
                         else if rtfCenter in FFormat
                                  then rc.Left := ( rc.Left + rc.Right - d) div 2;

                     rc.Right := rc.Left + d;

                     with FCalcRect do
                         d := Bottom - Top;

                     if rtfBottom in FFormat
                         then rc.Top := rc.Bottom - d
                         else if rtfVerticalCenter in FFormat
                                  then rc.Top := ( rc.Top + rc.Bottom - d) div 2;

                     rc.Bottom := rc.Top + d;
                 end
            else rc2.Bottom := rc2.Top;

        //OleCheck( IServices.TxDraw( DVASPECT_CONTENT, -1, nil, nil, dc, 0, @rc, nil, @rc2, nil, 0, TXTVIEW_ACTIVE));
        result := IServices.TxDraw( DVASPECT_CONTENT,
                                    -1,
                                    nil,
                                    nil,
                                    dc,
                                    0,
                                    @rc,
                                    nil,
                                    @rc2,
                                    nil,
                                    0,
                                    TXTVIEW_ACTIVE
                                  ) and $80000000 = 0;
    finally
        SetViewportOrgEx(dc, pt2.x, pt2.y, nil);
        SetWindowOrgEx(dc, pt.x, pt.y, nil);
    end;
end;

function TDrawRtfText.PlainText( _maxSize : SmallInt) : String;
var str : pChar;
    sze : Integer;
begin
    sze := _maxSize * sizeof( char);

    str := GetMemory( sze);
    SendMsg( WM_GETTEXT, sze, DWORD( str));
    result := str;
    FreeMemory( str);
end;

function TDrawRtfText.TxGetCharFormat(out ppCF: PCharFormatW): HRESULT;
begin
  ppCF := @FCharFormat;
  Result := S_OK;
end;

function TDrawRtfText.TxGetClientRect(out rc: TRect): HRESULT;
begin
  { Quote (MSDN): The client rectangle is the rectangle that the text services
    object is responsible for painting and managing. The host relies on the
    text services object for painting that area. And, the text services object
    must not paint or invalidate areas outside of that rectangle.

    The host forwards mouse messages to the text services object when the
    cursor is over the client rectangle.

    The client rectangle is expressed in client coordinates of the containing
    window.
  }
  rc := FRect;
  Result := S_OK;
end;

function TDrawRtfText.TxGetDC: HDC;
begin
  Result := FCanvas.Handle;
end;

function TDrawRtfText.TxGetSysColor(nIndex: Integer): COLORREF;
begin
  if nIndex = COLOR_WINDOW then
    Result := ColorToRGB(FCanvas.Brush.Color)
  else if nIndex = COLOR_WINDOWTEXT then
    Result := ColorToRGB(FCanvas.Font.Color)
  else
    Result := GetSysColor(nIndex);
end;

function TDrawRtfText.TxNotify(iNotify: DWORD; pv: Pointer): HRESULT;
begin
  if iNotify = EN_REQUESTRESIZE then
    FCalcRect := PReqSize(pv)^.rc;
  Result := S_OK;
end;

function TDrawRtfText.TxReleaseDC(dc: HDC): integer;
begin
  Result := 1;
end;

procedure TDrawRtfText.TxViewChange(fUpdate: BOOL);
begin
  if fUpdate then
    Draw(False);
end;

{ DrawRtfText }

function RTFText_Draw( _Canvas: TCanvas; var _Rect: TRect; _Text: String; _TextFormat: TRtfTextFormat; _Zoom: Integer) : Boolean;
var Drawer : TDrawRtfText;
begin
    Drawer := nil;
    try
       Drawer := TDrawRtfText.Create( _Canvas, _Rect, AnsiString( _Text), _TextFormat, _Zoom);

       if rtfCalcRect in _TextFormat
           then begin
                    _rect  := Drawer.CalcRect;
                    result := True;
                end
           else begin
                    result := Drawer.Draw( True);
                end;
    except // exception is swallowed
         result := false;
    end;

    Drawer.Free();
end;

function RTFText_Plain( _Canvas : TCanvas; _str : String) : String;
var Drawer : TDrawRtfText;
begin
    Drawer := nil;
    try
       Drawer := TDrawRtfText.Create( _canvas, Bounds( 0, 0, 1000, 1000), AnsiString( _str), [rtfLeft], 100);

       Result := Drawer.PlainText( 4096);
    except // exception is swallowed
         result := '';
    end;

    Drawer.Free();
end;

end.

