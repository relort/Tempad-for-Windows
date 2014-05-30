{
  DelphiTextServ.pas

  `Naked´ implementation of ITextHost and IRichEditOleCallback for use with
  Delphi. Upon creation, the control uses `CreateTextServices´ to create an
  instance of a windowless richedit control. You can use `TTextServices´ as
  the base class for other classes by just overriding the virtual interface
  methods here (see `RtfLabel.pas´ for an example).

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

unit DelphiTextServ;

interface

//{$I Rich3Conf.inc}

uses
  Windows, SysUtils, ActiveX, RichEdit, RichEdit2, RichEditDll, RichOle,
  RichTom, TextServ;

const
  TXTBIT_ALL_PROPERTIES = TXTBIT_RICHTEXT or TXTBIT_MULTILINE or
    TXTBIT_READONLY or TXTBIT_SHOWACCELERATOR or TXTBIT_USEPASSWORD or
    TXTBIT_HIDESELECTION or TXTBIT_SAVESELECTION or TXTBIT_AUTOWORDSEL or
    TXTBIT_VERTICAL or TXTBIT_WORDWRAP or TXTBIT_ALLOWBEEP or
    TXTBIT_DISABLEDRAG or TXTBIT_USECURRENTBKG;

  TXTBIT_ALL_NOTIFICATIONS = TXTBIT_SELBARCHANGE or TXTBIT_VIEWINSETCHANGE or
    TXTBIT_BACKSTYLECHANGE or TXTBIT_MAXLENGTHCHANGE or
    TXTBIT_SCROLLBARCHANGE or TXTBIT_CHARFORMATCHANGE or
    TXTBIT_PARAFORMATCHANGE or TXTBIT_EXTENTCHANGE or TXTBIT_CLIENTRECTCHANGE;

type
  { Starting from version 1.1 I no longer inherit from `TInterfacedObject´ but
    from plain `TObject´, because it is too much hassle to handle the cross-
    referencing of the used interfaces.
  }

  TTextServices = class(TObject, IUnknown, ITextHost, IRichEditOleCallback)
  private
    FDocument: ITextDocument2;
    FHost: ITextHost;
    FPropertyBits: DWORD;
    FRefCount: LongInt;
    FRichOle: IRichEditOle;
    FServices: ITextServices;
    FServicesUnknown: IUnknown;
    FVersion: TRichEditVersion;
    procedure SetPropertyBits(Value: DWORD);
  protected
    // IUnknown interface
    function QueryInterface(const iid: TGUID; out Obj): HRESULT; stdcall;
    function _AddRef: LongInt; stdcall;
    function _Release: LongInt; stdcall;
    // ITextHost interface
    function TxGetDC: HDC; virtual; stdcall;
    function TxReleaseDC(dc: HDC): integer; virtual; stdcall;
    function TxShowScrollBar(fnBar: Integer; fShow: BOOL): BOOL;
      virtual; stdcall;
    function TxEnableScrollBar(fuSBFlags, fuArrowflags: Integer): BOOL;
      virtual; stdcall;
    function TxSetScrollRange(fnBar, nMinPos, nMaxPos: Integer;
      fRedraw: BOOL): BOOL; virtual; stdcall;
    function TxSetScrollPos(fnBar, nPos: Integer; fRedraw: BOOL): BOOL;
      virtual; stdcall;
    procedure TxInvalidateRect(prc: PRect; fMode: BOOL); virtual; stdcall;
    procedure TxViewChange(fUpdate: BOOL); virtual; stdcall;
    function TxCreateCaret(bmp: HBITMAP; xWidth, yHeight: Integer): BOOL;
      virtual; stdcall;
    function TxShowCaret(fShow: BOOL): BOOL; virtual; stdcall;
    function TxSetCaretPos(x, y: Integer): BOOL; virtual; stdcall;
    function TxSetTimer(idTimer, uTimeout: UINT): BOOL; virtual; stdcall;
    procedure TxKillTimer(idTimer: UINT); virtual; stdcall;
    procedure TxScrollWindowEx(dx, dy: Integer; prcScroll, prcClip: PRect;
      hrgnUpdate: HRGN; lprcUpdate: PRect; fuScroll: UINT); virtual; stdcall;
    procedure TxSetCapture(fCapture: BOOL); virtual; stdcall;
    procedure TxSetFocus; virtual; stdcall;
    procedure TxSetCursor(hcur: HCURSOR; fText: BOOL); virtual; stdcall;
    function TxScreenToClient(var pt: TPoint): BOOL; virtual; stdcall;
    function TxClientToScreen(var pt: TPoint): BOOL; virtual; stdcall;
    function TxActivate(out lOldState: LongInt): HRESULT; virtual; stdcall;
    function TxDeactivate(lNewState: LongInt): HRESULT; virtual; stdcall;
    function TxGetClientRect(out rc: TRect): HRESULT; virtual; stdcall;
    function TxGetViewInset(out rc: TRect): HRESULT; virtual; stdcall;
    function TxGetCharFormat(out ppCF: PCharFormatW): HRESULT; virtual; stdcall;
    function TxGetParaFormat(out ppPF: PParaFormat): HRESULT; virtual; stdcall;
    function TxGetSysColor(nIndex: Integer): COLORREF; virtual; stdcall;
    function TxGetBackStyle(out style: TTxtBackStyle): HRESULT;
      virtual; stdcall;
    function TxGetMaxLength(out llength: DWORD): HRESULT; virtual; stdcall;
    function TxGetScrollBars(out dwScrollBar: DWORD): HRESULT; virtual; stdcall;
    function TxGetPasswordChar(out ch: WideChar): HRESULT; virtual; stdcall;
    function TxGetAcceleratorPos(out cp: LongInt): HRESULT; virtual; stdcall;
    function TxGetExtent(out Extent: TSize): HRESULT; virtual; stdcall;
    function OnTxCharFormatChange(const pcf: TCharFormatW): HRESULT;
      virtual; stdcall;
    function OnTxParaFormatChange(const ppf: TParaFormat): HRESULT;
      virtual; stdcall;
    function TxGetPropertyBits(dwMask: DWORD;
      out dwBits: DWORD): HRESULT; virtual; stdcall;
    function TxNotify(iNotify: DWORD; pv: Pointer): HRESULT; virtual; stdcall;
    function TxImmGetContext: THandle; virtual; stdcall;
    procedure TxImmReleaseContext(imc: THandle); virtual; stdcall;
    function TxGetSelectionBarWidth(out sbWidth: LongInt): HRESULT;
      virtual; stdcall;
    // IRichEditOleCallback interface
    function GetNewStorage(out stg: IStorage): HRESULT; virtual; stdcall;
    function GetInPlaceContext(out Frame: IOleInPlaceFrame;
      out Doc: IOleInPlaceUIWindow;
      lpFrameInfo: POleInPlaceFrameInfo): HRESULT; virtual; stdcall;
    function ShowContainerUI(fShow: BOOL): HRESULT; virtual; stdcall;
    function QueryInsertObject(const clsid: TCLSID; const stg: IStorage;
      cp: LongInt): HRESULT; virtual; stdcall;
    function DeleteObject(const oleobj: IOleObject): HRESULT; virtual; stdcall;
    function QueryAcceptData(const dataobj: IDataObject;
      var cfFormat: TClipFormat; reco: DWORD; fReally: BOOL;
      hMetaPict: HGLOBAL): HRESULT; virtual; stdcall;
    function ContextSensitiveHelp(fEnterMode: BOOL): HRESULT; virtual; stdcall;
    function GetClipboardData(const chrg: TCharRange; reco: DWORD;
      out dataobj: IDataObject): HRESULT; virtual; stdcall;
    function GetDragDropEffect(fDrag: BOOL; grfKeyState: DWORD;
      var dwEffect: DWORD): HRESULT; virtual; stdcall;
    function GetContextMenu(seltype: Word; oleobj: IOleObject;
      const chrg: TCharRange; var menu: HMENU): HRESULT; virtual; stdcall;
  public
    constructor Create;
    constructor CreateEx(Versions: TRichEditVersions);
    destructor Destroy; override;
    procedure Notify(dwBits: DWORD);
    function SendMsg(Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
    property IDocument: ITextDocument2 read FDocument;
    property IRichOle: IRichEditOle read FRichOle;
    property IServices: ITextServices read FServices;
    property PropertyBits: DWORD read FPropertyBits write SetPropertyBits;
    property RichEditVersion: TRichEditVersion read FVersion;
  end;

implementation

uses
  Forms, ComObj, ThiscallWrapper
  {$IFDEF RICHEDIT_DEBUG}
  , RichEditDebugger
  {$ENDIF}
  ;

{------------------------------------------------------------}
{ TTextServices }

constructor TTextServices.Create;
begin
  CreateEx([]);
end;

constructor TTextServices.CreateEx(Versions: TRichEditVersions);
var
  Creator: PCreateTextServices;
  Host: ITextHost;
  Callback: IRichEditOleCallback;
  Rect: TRect;
begin
  inherited;

  Host := Self as ITextHost;
  {$IFDEF RICHEDIT_DEBUG}
  Host := ITextHost_Debugger(Host);
  {$ENDIF}

  // Wrap a `thiscall´ interface around us
  OleCheck(CreateThiscallInterface(Host, IID_ITextHost, FHost, True));

  // Create the text services object, using our ITextHost interface
  FVersion := GetRichEditModuleEx(Versions);
  Creator := GetProcAddress(RichEditModules[FVersion].Handle, 'CreateTextServices');
  OleCheck(Creator(nil, FHost, FServicesUnknown));

  // Wrap an `stdcall´ interface around the ITextServices object
  OleCheck(QueryThiscallInterface(FServicesUnknown, IID_ITextServices, FServices));
  {$IFDEF RICHEDIT_DEBUG}
  FServices := ITextServices_Debugger(FServices);
  {$ENDIF}

  // It also provides the ITextDocument2 interface
  FDocument := FServicesUnknown as ITextDocument2;

  // ...and it also supports the IRichEditOle interface
  FRichOle := FServicesUnknown as IRichEditOle;
  {$IFDEF RICHEDIT_DEBUG}
  FRichOle := IRichEditOle_Debugger(FRichOle);
  {$ENDIF}

  // Set the IRichEditOleCallback interface
  Callback := Self as IRichEditOleCallback;
  {$IFDEF RICHEDIT_DEBUG}
  Callback := IRichEditOleCallback_Debugger(Callback);
  {$ENDIF}
  SendMsg(EM_SETOLECALLBACK, 0, LongInt(Pointer(Callback)));

  SetRect(Rect, 0, 0, 128, 64);
  FServices.OnTxInPlaceActivate(Rect);
end;

destructor TTextServices.Destroy;
begin
  if FServices <> nil then
    FServices.OnTxInPlaceDeactivate;
  FRichOle := nil;
  FDocument := nil;
  FServices := nil;
  FServicesUnknown := nil;
  FreeThiscallInterface(FHost);
  inherited;
end;

function TTextServices.QueryInterface(const iid: TGUID; out Obj): HRESULT;
begin
  // IUnknown.QueryInterface
  if GetInterface(iid, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

function TTextServices._AddRef: LongInt;
begin
  // IUnknown._AddRef
  Result := InterlockedIncrement(FRefCount);
end;

function TTextServices._Release: LongInt;
begin
  // IUnknown._Release
  Result := InterlockedDecrement(FRefCount);
end;

function TTextServices.ContextSensitiveHelp(fEnterMode: BOOL): HRESULT;
begin
  // IRichEditOleCallback.ContextSensitiveHelp
  Result := S_OK;
end;

function TTextServices.DeleteObject(const oleobj: IOleObject): HRESULT;
begin
  // IRichEditOleCallback.DeleteObject
  if Assigned(oleobj) then
    oleobj.Close(OLECLOSE_NOSAVE);
  Result := S_OK;
end;

function TTextServices.GetClipboardData(const chrg: TCharRange;
  reco: DWORD; out dataobj: IDataObject): HRESULT;
begin
  // IRichEditOleCallback.GetClipboardData
  Result := E_NOTIMPL;
end;

function TTextServices.GetContextMenu(seltype: Word; oleobj: IOleObject;
  const chrg: TCharRange; var menu: HMENU): HRESULT;
begin
  // IRichEditOleCallback.GetContextMenu
  Result := E_NOTIMPL;
end;

function TTextServices.GetDragDropEffect(fDrag: BOOL; grfKeyState: DWORD;
  var dwEffect: DWORD): HRESULT;
begin
  // IRichEditOleCallback.GetDragDropEffect
  Result := E_NOTIMPL;
end;

function TTextServices.GetInPlaceContext(out Frame: IOleInPlaceFrame;
  out Doc: IOleInPlaceUIWindow; lpFrameInfo: POleInPlaceFrameInfo): HRESULT;
begin
  // IRichEditOleCallback.GetInPlaceContext
  Result := E_NOTIMPL;
end;

function TTextServices.GetNewStorage(out stg: IStorage): HRESULT;
var
  LockBytes: ILockBytes;
begin
  // IRichEditOleCallback.GetNewStorage
  Result := CreateILockBytesOnHGlobal(0, True, LockBytes);
  if Result = S_OK then
    Result := StgCreateDocfileOnILockBytes(LockBytes,
      STGM_READWRITE or STGM_SHARE_EXCLUSIVE or STGM_CREATE, 0, stg);
end;

procedure TTextServices.Notify(dwBits: DWORD);
begin
  dwBits := dwBits and TXTBIT_ALL_NOTIFICATIONS;
  FServices.OnTxPropertyBitsChange(dwBits, dwBits);
end;

function TTextServices.OnTxCharFormatChange(const pcf: TCharFormatW): HRESULT;
begin
  // ITextHost.OnTxCharFormatChange
  Result := S_OK;
end;

function TTextServices.OnTxParaFormatChange(const ppf: TParaFormat): HRESULT;
begin
  // ITextHost.OnTxParaFormatChange
  Result := S_OK;
end;

function TTextServices.QueryAcceptData(const dataobj: IDataObject;
  var cfFormat: TClipFormat; reco: DWORD; fReally: BOOL;
  hMetaPict: HGLOBAL): HRESULT;
begin
  // IRichEditOleCallback.QueryAcceptData
  Result := S_OK;
end;

function TTextServices.QueryInsertObject(const clsid: TCLSID;
  const stg: IStorage; cp: Integer): HRESULT;
begin
  // IRichEditOleCallback.QueryInsertObject
  Result := S_OK;
end;

function TTextServices.SendMsg(Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin
  OleCheck(FServices.TxSendMessage(Msg, wParam, lParam, Result));
end;

procedure TTextServices.SetPropertyBits(Value: DWORD);
var
  dwMask: DWORD;
begin
  Value := Value and TXTBIT_ALL_PROPERTIES;
  if FPropertyBits <> Value then
  begin
    dwMask := FPropertyBits xor Value;
    FPropertyBits := Value;
    FServices.OnTxPropertyBitsChange(dwMask, Value and dwMask);
  end;
end;

function TTextServices.ShowContainerUI(fShow: BOOL): HRESULT;
begin
  // IRichEditOleCallback.ShowContainerUI
  Result := E_NOTIMPL;
end;

function TTextServices.TxActivate(out lOldState: Integer): HRESULT;
begin
  // ITextHost.TxActivate
  Result := S_OK;
end;

function TTextServices.TxClientToScreen(var pt: TPoint): BOOL;
begin
  // ITextHost.TxClientToScreen
  Result := False;
end;

function TTextServices.TxCreateCaret(bmp: HBITMAP; xWidth,
  yHeight: Integer): BOOL;
begin
  // ITextHost.TxCreateCaret
  Result := False;
end;

function TTextServices.TxDeactivate(lNewState: Integer): HRESULT;
begin
  // ITextHost.TxDeactivate
  Result := S_OK;
end;

function TTextServices.TxEnableScrollBar(fuSBFlags,
  fuArrowflags: Integer): BOOL;
begin
  // ITextHost.TxEnableScrollBar
  Result := False;
end;

function TTextServices.TxGetAcceleratorPos(out cp: Integer): HRESULT;
begin
  // ITextHost.TxGetAcceleratorPos
  cp := -1;
  Result := S_OK;
end;

function TTextServices.TxGetBackStyle(out style: TTxtBackStyle): HRESULT;
begin
  // ITextHost.TxGetBackStyle
  style := TXTBACK_TRANSPARENT;
  Result := S_OK;
end;

function TTextServices.TxGetCharFormat(out ppCF: PCharFormatW): HRESULT;
begin
  // ITextHost.TxGetCharFormat
  Result := E_NOTIMPL;
end;

function TTextServices.TxGetClientRect(out rc: TRect): HRESULT;
begin
  // ITextHost.TxGetClientRect
  Result := E_NOTIMPL;
end;

function TTextServices.TxGetDC: HDC;
begin
  // ITextHost.TxGetDC
  // Note: a valid DC is absolutely necessary, otherwise RICHED20.DLL
  // crashes when you load a file with embedded pictures or objects.
  Result := GetDC(Application.Handle);
end;

function TTextServices.TxGetExtent(out Extent: TSize): HRESULT;
begin
  // ITextHost.TxGetExtent
  Result := E_NOTIMPL;
end;

function TTextServices.TxGetMaxLength(out llength: DWORD): HRESULT;
begin
  // ITextHost.TxGetMaxLength
  llength := $7fffffff;
  Result := S_OK;
end;

function TTextServices.TxGetParaFormat(out ppPF: PParaFormat): HRESULT;
begin
  // ITextHost.TxGetParaFormat
  Result := E_NOTIMPL;
end;

function TTextServices.TxGetPasswordChar(out ch: WideChar): HRESULT;
begin
  // ITextHost.TxGetPasswordChar
  ch := '*';
  Result := S_OK;
end;

function TTextServices.TxGetPropertyBits(dwMask: DWORD; out dwBits: DWORD): HRESULT;
begin
  // ITextHost.TxGetPropertyBits
  dwBits := FPropertyBits and dwMask;
  Result := S_OK;
end;

function TTextServices.TxGetScrollBars(out dwScrollBar: DWORD): HRESULT;
begin
  // ITextHost.TxGetScrollBars
  dwScrollBar := 0;
  Result := S_OK;
end;

function TTextServices.TxGetSelectionBarWidth(out sbWidth: Integer): HRESULT;
begin
  // ITextHost.TxGetSelectionBarWidth
  sbWidth := 0;
  Result := S_OK;
end;

function TTextServices.TxGetSysColor(nIndex: Integer): COLORREF;
begin
  // ITextHost.TxGetSysColor
  Result := GetSysColor(nIndex);
end;

function TTextServices.TxGetViewInset(out rc: TRect): HRESULT;
begin
  // ITextHost.TxGetViewInset
  rc.Left := 0;
  rc.Top := 0;
  rc.Right := 0;
  rc.Bottom := 0;
  Result := S_OK;
end;

function TTextServices.TxImmGetContext: THandle;
begin
  // ITextHost.TxImmGetContext
  Result := 0;
end;

procedure TTextServices.TxImmReleaseContext(imc: THandle);
begin
  // ITextHost.TxImmReleaseContext
end;

procedure TTextServices.TxInvalidateRect(prc: PRect; fMode: BOOL);
begin
  // ITextHost.TxInvalidateRect
end;

procedure TTextServices.TxKillTimer(idTimer: UINT);
begin
  // ITextHost.TxKillTimer
end;

function TTextServices.TxNotify(iNotify: DWORD; pv: Pointer): HRESULT;
begin
  // ITextHost.TxNotify
  Result := S_OK;
end;

function TTextServices.TxReleaseDC(dc: HDC): integer;
begin
  // ITextHost.TxReleaseDC
  // See note at TxGetDC
  Result := ReleaseDC(Application.Handle, dc);
end;

function TTextServices.TxScreenToClient(var pt: TPoint): BOOL;
begin
  // ITextHost.TxScreenToClient
  Result := False;
end;

procedure TTextServices.TxScrollWindowEx(dx, dy: Integer; prcScroll,
  prcClip: PRect; hrgnUpdate: HRGN; lprcUpdate: PRect; fuScroll: UINT);
begin
  // ITextHost.TxScrollWindowEx
end;

procedure TTextServices.TxSetCapture(fCapture: BOOL);
begin
  // ITextHost.TxSetCapture
end;

function TTextServices.TxSetCaretPos(x, y: Integer): BOOL;
begin
  // ITextHost.TxSetCaretPos
  Result := False;
end;

procedure TTextServices.TxSetCursor(hcur: HCURSOR; fText: BOOL);
begin
  // ITextHost.TxSetCursor
end;

procedure TTextServices.TxSetFocus;
begin
  // ITextHost.TxSetFocus
end;

function TTextServices.TxSetScrollPos(fnBar, nPos: Integer;
  fRedraw: BOOL): BOOL;
begin
  // ITextHost.TxSetScrollPos
  Result := False;
end;

function TTextServices.TxSetScrollRange(fnBar, nMinPos, nMaxPos: Integer;
  fRedraw: BOOL): BOOL;
begin
  // ITextHost.TxSetScrollRange
  Result := False;
end;

function TTextServices.TxSetTimer(idTimer, uTimeout: UINT): BOOL;
begin
  // ITextHost.TxSetTimer
  Result := False;
end;

function TTextServices.TxShowCaret(fShow: BOOL): BOOL;
begin
  // ITextHost.TxShowCaret
  Result := False;
end;

function TTextServices.TxShowScrollBar(fnBar: Integer; fShow: BOOL): BOOL;
begin
  // ITextHost.TxShowScrollBar
  Result := False;
end;

procedure TTextServices.TxViewChange(fUpdate: BOOL);
begin
  // ITextHost.TxViewChange
end;

end.

