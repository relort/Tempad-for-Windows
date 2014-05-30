{
  TextServ.pas

  Pascal version of TextServ.h (version: 2005 platform SDK).

  ATTENTION: Though the interfaces here are declared as `stdcall´, they are
  lacking any calling convention in the original C/C++ header file. So the
  Microsoft Visual C++ compiler assumes the `thiscall´ convention, which means
  the instance pointer is passed in ECX and all parameters are passed on the
  stack like with `stdcall´.

  Unfortunately, Delphi does not support this calling convention, so one cannot
  call any of those interfaces directly. Additionally, you cannot easily
  implement the ITextHost interface with Delphi. Use my unit
  `ThiscallWrapper.pas´ resp. the unit `DelphiTextServ.pas´ for a workaround.

  Version 1.3d - always find the most current version at
  http://flocke.vssd.de/prog/code/pascal/rtflabel/

  Copyright (C) 2005-2009 Volker Siebert <flocke@vssd.de>
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
}

//{$I DelphiVersion.inc}

{$IFDEF CPPBUILDER}
{$HPPEMIT '#include <TextServ.h>'}
{$ENDIF}

unit TextServ;

{$WEAKPACKAGEUNIT}
{$MINENUMSIZE 4}

interface

uses
  Windows, ActiveX, ComObj, RichEdit, RichEdit2;

(*  @doc EXTERNAL
 *
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *
 *  @module TEXTSRV.H  Text Service Interface |
 *
 *  Define interfaces between the Text Services component and the host
 *
 *  Original Author: <nl>
 *      Christian Fortini
 *
 *  History: <nl>
 *      8/1/95  ricksa  Revised interface definition
 *)

const
  {$IFDEF CPPBUILDER}{$EXTERNALSYM IID_ITextServices}{$ENDIF}
  IID_ITextServices: TGUID = '{8D33F740-CF58-11CE-A89D-00AA006CADC5}';
  {$IFDEF CPPBUILDER}{$EXTERNALSYM IID_ITextHost}{$ENDIF}
  IID_ITextHost: TGUID = '{13E670F4-1A5A-11CF-ABEB-00AA00B65EA1}';

  // Note: error code is first outside of range reserved for OLE.
  {$IFDEF CPPBUILDER}{$EXTERNALSYM S_MSG_KEY_IGNORED}{$ENDIF}
  S_MSG_KEY_IGNORED = (SEVERITY_SUCCESS shl 31) + (FACILITY_ITF shl 16) + $201;

// Enums used by property methods

(*
 *  TXTBACKSTYLE
 *
 *  @enum   Defines different background styles control
 *)
const
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBACK_TRANSPARENT}{$ENDIF}
  TXTBACK_TRANSPARENT           = 0;    //@emem background should show through
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBACK_OPAQUE}{$ENDIF}
  TXTBACK_OPAQUE                = 1;    //@emem erase background

type
  PTxtBackStyle = ^TTxtBackStyle;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBACKSTYLE}{$ENDIF}
  TXTBACKSTYLE = Integer; // TXTBACK_TRANSPARENT .. TXTBACK_OPAQUE; (*1)
  TTxtBackStyle = TXTBACKSTYLE;

(*
 *  TXTHITRESULT
 *
 *  @enum   Defines different hitresults
 *)
const
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTHITRESULT_NOHIT}{$ENDIF}
  TXTHITRESULT_NOHIT            = 0;    //@emem no hit
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTHITRESULT_TRANSPARENT}{$ENDIF}
  TXTHITRESULT_TRANSPARENT      = 1;    //@emem point is within the text's
                                        //rectangle, but in a transparent region
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTHITRESULT_CLOSE}{$ENDIF}
  TXTHITRESULT_CLOSE            = 2;    //@emem point is close to the text
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTHITRESULT_HIT}{$ENDIF}
  TXTHITRESULT_HIT              = 3;    //@emem dead-on hit

type
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTHITRESULT}{$ENDIF}
  TXTHITRESULT = Integer; // TXTHITRESULT_NOHIT .. TXTHITRESULT_HIT; (*1)

(*
 *  TXTNATURALSIZE
 *
 *  @enum   useful values for TxGetNaturalSize.
 *
 *  @xref <mf CTxtEdit::TxGetNaturalSize>
 *)
const
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTNS_FITTOCONTENT}{$ENDIF}
  TXTNS_FITTOCONTENT            = 1;    //@emem Get a size that fits the content
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTNS_ROUNDTOLINE}{$ENDIF}
  TXTNS_ROUNDTOLINE             = 2;    //@emem Round to the nearest whole line.

type
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTNATURALSIZE}{$ENDIF}
  TXTNATURALSIZE = Integer; // TXTNS_FITTOCONTENT .. TXTNS_ROUNDTOLINE; (*1)

(*
 *  TXTVIEW
 *
 *  @enum   useful values for TxDraw lViewId parameter
 *
 *  @xref <mf CTxtEdit::TxDraw>
 *)
const
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTVIEW_ACTIVE}{$ENDIF}
  TXTVIEW_ACTIVE                = 0;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTVIEW_INACTIVE}{$ENDIF}
  TXTVIEW_INACTIVE              = -1;

type
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTVIEW}{$ENDIF}
  TXTVIEW = Integer; // TXTVIEW_INACTIVE .. TXTVIEW_ACTIVE; {1}

(*
 *  CHANGETYPE
 *
 *  @enum   used for CHANGENOTIFY.dwChangeType; indicates what happened
 *          for a particular change.
 *)
const
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CN_GENERIC}{$ENDIF}
  CN_GENERIC                    = 0;    //@emem Nothing special happened
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CN_TEXTCHANGED}{$ENDIF}
  CN_TEXTCHANGED                = 1;    //@emem the text changed
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CN_NEWUNDO}{$ENDIF}
  CN_NEWUNDO                    = 2;    //@emem A new undo action was added
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CN_NEWREDO}{$ENDIF}
  CN_NEWREDO                    = 4;    //@emem A new redo action was added

type
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CHANGETYPE}{$ENDIF}
  CHANGETYPE = Integer; // CN_GENERIC .. CN_TEXTCHANGED + CN_NEWUNDO + CN_NEWREDO; (*1)

(*
 *  @struct CHANGENOTIFY  |
 *
 *  passed during an EN_CHANGE notification; contains information about
 *  what actually happened for a change.
 *)
type
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CHANGENOTIFY}{$ENDIF}
  CHANGENOTIFY = packed record
    dwChangeType: DWORD;                //@field TEXT changed, etc
    pvCookieData: Pointer;              //@field cookie for the undo action
                                        // associated with the change.
  end;

// The TxGetPropertyBits and OnTxPropertyBitsChange methods can pass the
// following bits:

// NB!!! Do NOT rely on the ordering of these bits yet; the are subject
// to change.
const
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_RICHTEXT}{$ENDIF}
  TXTBIT_RICHTEXT           = 1;        // rich-text control
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_MULTILINE}{$ENDIF}
  TXTBIT_MULTILINE          = 2;        // single vs multi-line control
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_READONLY}{$ENDIF}
  TXTBIT_READONLY           = 4;        // read only text
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_SHOWACCELERATOR}{$ENDIF}
  TXTBIT_SHOWACCELERATOR    = 8;        // underline accelerator character
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_USEPASSWORD}{$ENDIF}
  TXTBIT_USEPASSWORD        = $10;      // use password char to display text
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_HIDESELECTION}{$ENDIF}
  TXTBIT_HIDESELECTION      = $20;      // show selection when inactive
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_SAVESELECTION}{$ENDIF}
  TXTBIT_SAVESELECTION      = $40;      // remember selection when inactive
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_AUTOWORDSEL}{$ENDIF}
  TXTBIT_AUTOWORDSEL        = $80;      // auto-word selection
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_VERTICAL}{$ENDIF}
  TXTBIT_VERTICAL           = $100;     // vertical
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_SELBARCHANGE}{$ENDIF}
  TXTBIT_SELBARCHANGE       = $200;     // notification that the selection bar
                                        // width has changed.
                                        // FUTURE: move this bit to the end to
                                        // maintain the division between
                                        // properties and notifications.
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_WORDWRAP}{$ENDIF}
  TXTBIT_WORDWRAP           = $400;     // if set, then multi-line controls
                                        // should wrap words to fit the
                                        // available display
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_ALLOWBEEP}{$ENDIF}
  TXTBIT_ALLOWBEEP          = $800;     // enable/disable beeping
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_DISABLEDRAG}{$ENDIF}
  TXTBIT_DISABLEDRAG        = $1000;    // disable/enable dragging
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_VIEWINSETCHANGE}{$ENDIF}
  TXTBIT_VIEWINSETCHANGE    = $2000;    // the inset changed
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_BACKSTYLECHANGE}{$ENDIF}
  TXTBIT_BACKSTYLECHANGE    = $4000;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_MAXLENGTHCHANGE}{$ENDIF}
  TXTBIT_MAXLENGTHCHANGE    = $8000;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_SCROLLBARCHANGE}{$ENDIF}
  TXTBIT_SCROLLBARCHANGE    = $10000;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_CHARFORMATCHANGE}{$ENDIF}
  TXTBIT_CHARFORMATCHANGE   = $20000;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_PARAFORMATCHANGE}{$ENDIF}
  TXTBIT_PARAFORMATCHANGE   = $40000;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_EXTENTCHANGE}{$ENDIF}
  TXTBIT_EXTENTCHANGE       = $80000;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_CLIENTRECTCHANGE}{$ENDIF}
  TXTBIT_CLIENTRECTCHANGE   = $100000;  // the client rectangle changed
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TXTBIT_USECURRENTBKG}{$ENDIF}
  TXTBIT_USECURRENTBKG      = $200000;  // tells the renderer to use the current
                                        // background color rather than the
                                        // system default for an entire line

(*
 *  ITextServices
 *
 *  @class  An interface extending Microsoft's Text Object Model to provide
 *          extra functionality for windowless operation.  In conjunction
 *          with ITextHost, ITextServices provides the means by which the
 *          the RichEdit control can be used *without* creating a window.
 *
 *  @base   public | IUnknown
 *)
type
  TTxDrawContinue = function(code: DWORD): BOOL; stdcall;

  (*
   * ATTENTION: The methods are not really `stdcall´ but `thiscall´ - see
   * comment above in the header.
   *)

  {$IFDEF CPPBUILDER}{$EXTERNALSYM ITextServices}{$ENDIF}
  ITextServices = interface(IUnknown)
    ['{8D33F740-CF58-11CE-A89D-00AA006CADC5}']
    //@cmember Generic Send Message interface
    function TxSendMessage(msg: UINT; wparam: WPARAM; lparam: LPARAM;
      out plresult: LRESULT): HRESULT; stdcall;
    //@cmember Rendering
    function TxDraw(dwDrawAspect: DWORD; lindex: LongInt; pvAspect: Pointer;
      ptd: PDVTargetDevice; hdcDraw, hicTargetDev: HDC;
      lprcBounds, lprcWBounds, lprcUpdate: PRect;
      pfnContinue: TTxDrawContinue; dwContinue: DWORD;
      lViewId: LongInt): HRESULT; stdcall;
    //@cmember Horizontal scrollbar support
    function TxGetHScroll(plMin, plMax, plPos, plPage: PLongInt;
      pfEnable: PBool): HRESULT; stdcall;
    //@cmember Horizontal scrollbar support
    function TxGetVScroll(plMin, plMax, plPos, plPage: PLongInt;
      pfEnable: PBool): HRESULT; stdcall;
    //@cmember Setcursor
    function OnTxSetCursor(dwDrawAspect: DWORD; lindex: LongInt;
      pvAspect: Pointer; ptd: PDVTargetDevice; hdcDraw, hicTargetDev: HDC;
      prcClient: PRect; x, y: Integer): HRESULT; stdcall;
    //@cmember Hit-test
    function TxQueryHitPoint(dwDrawAspect: DWORD; lindex: LongInt;
      pvAspect: Pointer; ptd: PDVTargetDevice; hdcDraw, hicTargetDev: HDC;
      prcClient: PRect; x, y: Integer;
      out HitResult: DWORD): HRESULT; stdcall;
    //@cmember Inplace activate notification
    function OnTxInPlaceActivate(const rcClient: TRect): HRESULT; stdcall;
    //@cmember Inplace deactivate notification
    function OnTxInPlaceDeactivate: HRESULT; stdcall;
    //@cmember UI activate notification
    function OnTxUIActivate: HRESULT; stdcall;
    //@cmember UI deactivate notification
    function OnTxUIDeactivate: HRESULT; stdcall;
    //@cmember Get text in control
    function TxGetText(pbstrText: TBStr): HRESULT; stdcall;
    //@cmember Set text in control
    function TxSetText(pszText: PWideChar): HRESULT; stdcall;
    //@cmember Get x position of
    function TxGetCurTargetX(out lCurTargetX: LongInt): HRESULT; stdcall;
    //@cmember Get baseline position
    function TxGetBaseLinePos(out lBaseLinePos: LongInt): HRESULT; stdcall;
    //@cmember Get Size to fit / Natural size
    function TxGetNaturalSize(dwAspect: DWORD; hdcDraw, hicTargetDev: HDC;
      var ptd: PDVTargetDevice; dwMode: DWORD; psizelExtent: PSize;
      var width, height: LongInt): HRESULT; stdcall;
    //@cmember Drag & drop
    function TxGetDropTarget(out ppDropTarget: IDropTarget): HRESULT; stdcall;
    //@cmember Bulk bit property change notifications
    function OnTxPropertyBitsChange(dwMask, dwBits: DWORD): HRESULT; stdcall;
    //@cmember Fetch the cached drawing size
    function TxGetCachedSize(out dwWidth, dwHeight: DWORD): HRESULT; stdcall;
  end;

(*
 *  ITextHost
 *
 *  @class  Interface to be used by text services to obtain text host services
 *
 *  @base   public | IUnknown
 *)
type

  (*
   * ATTENTION: The methods are not really `stdcall´ but `thiscall´ - see
   * comment above in the header.
   *)

  {$IFDEF CPPBUILDER}{$EXTERNALSYM ITextHost}{$ENDIF}
  ITextHost = interface(IUnknown)
    ['{13E670F4-1A5A-11CF-ABEB-00AA00B65EA1}']
    //@cmember Get the DC for the host
    function TxGetDC: HDC; stdcall;
    //@cmember Release the DC gotten from the host
    function TxReleaseDC(dc: HDC): integer; stdcall;
    //@cmember Show the scroll bar
    function TxShowScrollBar(fnBar: Integer; fShow: BOOL): BOOL; stdcall;
    //@cmember Enable the scroll bar
    function TxEnableScrollBar(fuSBFlags, fuArrowflags: Integer): BOOL; stdcall;
    //@cmember Set the scroll range
    function TxSetScrollRange(fnBar, nMinPos, nMaxPos: Integer;
      fRedraw: BOOL): BOOL; stdcall;
    //@cmember Set the scroll position
    function TxSetScrollPos(fnBar, nPos: Integer; fRedraw: BOOL): BOOL; stdcall;
    //@cmember InvalidateRect
    procedure TxInvalidateRect(prc: PRect; fMode: BOOL); stdcall;
    //@cmember Send a WM_PAINT to the window
    procedure TxViewChange(fUpdate: BOOL); stdcall;
    //@cmember Create the caret
    function TxCreateCaret(bmp: HBITMAP; xWidth, yHeight: Integer): BOOL;
      stdcall;
    //@cmember Show the caret
    function TxShowCaret(fShow: BOOL): BOOL; stdcall;
    //@cmember Set the caret position
    function TxSetCaretPos(x, y: Integer): BOOL; stdcall;
    //@cmember Create a timer with the specified timeout
    function TxSetTimer(idTimer, uTimeout: UINT): BOOL; stdcall;
    //@cmember Destroy a timer
    procedure TxKillTimer(idTimer: UINT); stdcall;
    //@cmember Scroll the content of the specified window's client area
    procedure TxScrollWindowEx(dx, dy: Integer; prcScroll, prcClip: PRect;
      hrgnUpdate: HRGN; lprcUpdate: PRect; fuScroll: UINT); stdcall;
    //@cmember Get mouse capture
    procedure TxSetCapture(fCapture: BOOL); stdcall;
    //@cmember Set the focus to the text window
    procedure TxSetFocus; stdcall;
    //@cmember Establish a new cursor shape
    procedure TxSetCursor(hcur: HCURSOR; fText: BOOL); stdcall;
    //@cmember Converts screen coordinates of a specified point to the client
    // coordinates
    function TxScreenToClient(var pt: TPoint): BOOL; stdcall;
    //@cmember Converts the client coordinates of a specified point to screen
    // coordinates
    function TxClientToScreen(var pt: TPoint): BOOL; stdcall;
    //@cmember Request host to activate text services
    function TxActivate(out lOldState: LongInt): HRESULT; stdcall;
    //@cmember Request host to deactivate text services
    function TxDeactivate(lNewState: LongInt): HRESULT; stdcall;
    //@cmember Retrieves the coordinates of a window's client area
    function TxGetClientRect(out rc: TRect): HRESULT; stdcall;
    //@cmember Get the view rectangle relative to the inset
    function TxGetViewInset(out rc: TRect): HRESULT; stdcall;
    //@cmember Get the default character format for the text
    function TxGetCharFormat(out ppCF: PCharFormatW): HRESULT; stdcall;
    //@cmember Get the default paragraph format for the text
    function TxGetParaFormat(out ppPF: PParaFormat): HRESULT; stdcall;
    //@cmember Get the background color for the window
    function TxGetSysColor(nIndex: Integer): COLORREF; stdcall;
    //@cmember Get the background(either opaque or transparent)
    function TxGetBackStyle(out style: TTxtBackStyle): HRESULT; stdcall;
    //@cmember Get the maximum length for the text
    function TxGetMaxLength(out llength: DWORD): HRESULT; stdcall;
    //@cmember Get the bits representing requested scroll bars for the window
    function TxGetScrollBars(out dwScrollBar: DWORD): HRESULT; stdcall;
    //@cmember Get the character to display for password input
    function TxGetPasswordChar(out ch: WideChar): HRESULT; stdcall;
    //@cmember Get the accelerator character
    function TxGetAcceleratorPos(out cp: LongInt): HRESULT; stdcall;
    //@cmember Get the native size
    function TxGetExtent(out Extent: TSize): HRESULT; stdcall;
    //@cmember Notify host that default character format has changed
    function OnTxCharFormatChange(const pcf: TCharFormatW): HRESULT; stdcall;
    //@cmember Notify host that default paragraph format has changed
    function OnTxParaFormatChange(const ppf: TParaFormat): HRESULT; stdcall;
    //@cmember Bulk access to bit properties
    function TxGetPropertyBits(dwMask: DWORD;
      out dwBits: DWORD): HRESULT; stdcall;
    //@cmember Notify host of events
    function TxNotify(iNotify: DWORD; pv: Pointer): HRESULT; stdcall;
    // Far East Methods for getting the Input Context
//{$IFDEF WIN95_IME}
    function TxImmGetContext: THandle; stdcall;
    procedure TxImmReleaseContext(imc: THandle); stdcall;
//{$ENDIF}
    //@cmember Returns HIMETRIC size of the control bar.
    function TxGetSelectionBarWidth(out sbWidth: LongInt): HRESULT; stdcall;
  end;

//+-----------------------------------------------------------------------
//  Factories
//------------------------------------------------------------------------

// Text Services factory
function CreateTextServices3(const punkOuter: IUnknown;
  const pITextHost: ITextHost; out ppUnk: IUnknown): HRESULT; stdcall;

function CreateTextServices4(const punkOuter: IUnknown;
  const pITextHost: ITextHost; out ppUnk: IUnknown): HRESULT; stdcall;

type
  PCreateTextServices = function(const punkOuter: IUnknown;
    const pITextHost: ITextHost; out ppUnk: IUnknown): HRESULT; stdcall;

implementation

function CreateTextServices3;
  external 'RICHED20.DLL' name 'CreateTextServices';
function CreateTextServices4;
  external 'MSFTEDIT.DLL' name 'CreateTextServices';

end.

