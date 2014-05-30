{
  ThiscallWrapper.pas

  Pascal unit to wrap stdcall around incoming (foreign) and outgoing (own)
  interfaces that use the MS Visual C++ `thiscall´ calling convention.

  Both functions below allow up to 207 virtual methods (including
  QueryInterface, AddRef and Release, which are handled in a special way).

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

unit ThiscallWrapper;

{$I DelphiVersion.inc}

{$RANGECHECKS OFF}
{$TYPEDADDRESS OFF}
{$LONGSTRINGS ON}
{$EXTENDEDSYNTAX ON}

interface

uses
  SysUtils, Windows;

{ Use `QueryThiscallInterface´ instead of `QueryInterface´ or the `as´
  operator to get an `stdcall´ proxy for a `thiscall´ interface. Example:

  Instead of   Svc := Obj as ITextServices;
  simply use   QueryThiscallInterface(Obj, IID_ITextServices, Svc);

  After that, just use the returned interface like the original one (using
  `stdcall´).

  Note: you should *NOT* pass such an interface back to a C/C++ function
  that expects it to be `thiscall´. You must use the original object for
  this instead.
}
function QueryThiscallInterface(const Intf: IUnknown; const IID: TGUID;
  out Obj): HRESULT;

{ Use `CreateThiscallInterface´ to build a proxy around an `stdcall´ interface
  created with Delphi and a foreign caller that expects a `thiscall´ interface.
  Example:

  Instead of

    Host := Obj as ITextHost;
    CreateTextServices(nil, Host, Unk);

  simply use

    CreateThiscallInterface(Obj, IID_ITextHost, Host);
    CreateTextServices(nil, Host, Unk);

  If `Obj´ itself is an independent interface, you can use it just like this
  and the final `Release´ on `Host´ will also do a `Release´ on `Obj´.

  If `Obj´ itself controls the `Host´ variable's lifetime, you should pass
  TRUE as additional parameter and use `FreeThiscallInterface´ to free `Host´.
  Otherwise setting `Host´ to NIL will cause `Obj´s destruction in its own
  destructor.
}
function CreateThiscallInterface(const Intf: IUnknown; const IID: TGUID;
  out Obj; Controlled: Boolean {= False}): HRESULT;

procedure FreeThiscallInterface(var Intf);

implementation

{$IFNDEF DELPHI_6_UP}
uses
  ActiveX;
{$ENDIF}

{------------------------------------------------------------}
{ Common things for both, incoming and outgoing interfaces }

type
  // Classless types of IUnknown methods
  TInterfaceQuery = function(This: Pointer; const IID: TGUID; out Obj): HRESULT;
    stdcall;
  TInterfaceAddRef = function(This: Pointer): LongInt; stdcall;
  TInterfaceRelease = function(This: Pointer): LongInt; stdcall;

  // The base VMT for IUnknown
  PUnknownVMT = ^TUnknownVMT;
  TUnknownVMT = packed record
    // IUnknown interface (stdcall)
    QueryInterface: TInterfaceQuery;
    AddRef: TInterfaceAddRef;
    Release: TInterfaceRelease;
  end;

  // The base wrapper class we use for both wrappers
  PUnknownWrapper = ^TUnknownWrapper;
  TUnknownWrapper = packed record
    VMT: PUnknownVMT;                           // Virtual method table
    Intf: PUnknownWrapper;                      // Original interface pointer
    RefCount: LongInt;                          // Reference counter
    GUID: PGUID;                                // Pointer to GUID
  end;

{ Wrapper for `AddRef´: first call the original interface and additionally
  increment our own reference counter.
}
function Unk_AddRef(This: PUnknownWrapper): LongInt; stdcall;
begin
  Result := InterlockedIncrement(This^.RefCount);
end;

{ Wrapper for `QueryInterface´, just replaces `this´ and jumps to the original
  procedure. Note that this function will always return our own interface
  (AddRef'd) when asked for our own GUID.
}
function Unk_QueryInterface(This: PUnknownWrapper; const IID: TGUID;
  out Obj): HRESULT; stdcall;
begin
  if IsEqualGUID(This^.GUID^, IID) then
  begin
    Unk_AddRef(This);
    Pointer(Obj) := This;
    Result := S_OK;
  end
  else
  begin
    { Note that interfaces returned by QueryInterface are automatically
      AddRef'fed, but since the foreign QueryInterface will never return
      our interface, we do not increment our reference counter in that case.
    }
    Result := This^.Intf^.VMT^.QueryInterface(This^.Intf, IID, Obj);
  end;
end;

{ Wrapper for `Release´: first call the original interface and additionally
  decrement our own reference counter. If it becomes zero, free the whole
  structure
}
function Unk_Release(This: PUnknownWrapper): LongInt; stdcall;
begin
  Result := InterlockedDecrement(This^.RefCount);
  if Result = 0 then
  begin
    This^.Intf^.VMT^.Release(This^.Intf);
    This^.Intf := nil;
    This^.VMT := nil;
    FreeMem(This);
  end;
end;

{------------------------------------------------------------}
{ Incoming (foreign) `thiscall´ interfaces.

  The following assembler code fragment is used to build a proxy between
  Delphi expecting an `stdcall´ interface and a foreign `thiscall´ interface.

  Each VMT index needs its own fragment with exactly the same offset in
  `Index´ as in the original VMT, but *ALL* such interfaces can share the same
  function for the same index.
}

type
  TCallingWrapper = packed record
    Before: packed array [0 .. 9] of Byte;
    Index: Integer;
    After: packed array [0 .. 1] of Byte;
  end;

const
  CCallingWrapper: TCallingWrapper = (
    Before: (
      // Get `Self´ from the stack -> ECX
      $58,                      // 00: pop  eax    ; return address
      $59,                      // 01: pop  ecx    ; Self
      $50,                      // 02: push eax    ; return address
      // Dereference This := Self^.Intf
      $8B,$49,$04,              // 03: mov  ecx, [ecx + 4]
      // Now call This^.VMT^.proc_XX(This)
      $8B,$01,                  // 06: mov  eax, [ecx]
      $FF,$A0{,xx,xx,xx,xx}     // 08: jmp  [eax + *]
    );
    Index: 0;
    After: (
      $90,$90                   // 0E: nop, nop
    )
  );

const
  // 4096 Bytes -> 207 Entries (including the 3 IUnknown methods)
  CNumCallingMethods = 3 + (4096 - 12) div (SizeOf(TCallingWrapper) + 4);

type
  PCallingWrapperVMT = ^TCallingWrapperVMT;
  TCallingWrapperVMT = packed record
    BaseVMT: array [0 .. 2] of Pointer;
    DynVMT: array [0 .. CNumCallingMethods - 4] of Pointer;
    _Pad: Pointer;  // Align on 16 byte boundaries
    Wraps: array [0 .. CNumCallingMethods - 4] of TCallingWrapper;
  end;

var
  CallingWrapperVMT: PCallingWrapperVMT;

function GetCallingWrapperVMT: PUnknownVMT;
var
  p: PCallingWrapperVMT;
  k: Integer;
begin
  if CallingWrapperVMT = nil then
  begin
    p := VirtualAlloc(nil, SizeOf(TCallingWrapperVMT),
      MEM_COMMIT, PAGE_EXECUTE_READWRITE);
    if p = nil then
      {$IFDEF DELPHI_6_UP}
      RaiseLastOSError;
      {$ELSE}
      RaiseLastWin32Error;
      {$ENDIF}

    p^.BaseVMT[0] := @Unk_QueryInterface;
    p^.BaseVMT[1] := @Unk_AddRef;
    p^.BaseVMT[2] := @Unk_Release;

    for k := 0 to CNumCallingMethods - 4 do
    begin
      p^.Wraps[k] := CCallingWrapper;
      p^.Wraps[k].Index := 4 * (k + 3);
      p^.DynVMT[k] := @p^.Wraps[k];
    end;

    CallingWrapperVMT := p;
  end;

  Result := PUnknownVMT(CallingWrapperVMT);
end;

function QueryThiscallInterface(const Intf: IUnknown; const IID: TGUID;
  out Obj): HRESULT;
var
  Res: PUnknownWrapper;
begin
  Res := AllocMem(SizeOf(TUnknownWrapper));
  Res^.VMT := GetCallingWrapperVMT;
  Result := Intf.QueryInterface(IID, Res^.Intf);
  if Result = S_OK then
  begin
    Res^.RefCount := 1;
    Res^.GUID := @IID;
    PUnknownWrapper(Obj) := Res;
  end
  else
  begin
    FreeMem(Res);
    Pointer(Obj) := nil;
  end;
end;

{------------------------------------------------------------}
{ Outgoing (own) `thiscall´ interfaces.

  The following assembler code fragment is used to build a proxy between
  a foreign caller expecting a `thiscall´ interface and an `stdcall´
  interface built using Delphi.

  Each VMT index needs its own fragment with exactly the same offset in
  `Index´ as in the original VMT, but *ALL* such interfaces can share the same
  function for the same index.
}

type
  TCalledWrapper = packed record
    Before: packed array [0 .. 9] of Byte;
    Index: Integer;
    After: packed array [0 .. 1] of Byte;
  end;

const
  CCalledWrapper: TCalledWrapper = (
    Before: (
      // Dereference Self := This^.Intf
      $8B,$49,$04,              // 00: mov  ecx, [ecx + 4]
      // Push `Self´ onto the stack
      $58,                      // 03: pop  eax
      $51,                      // 04: push ecx
      $50,                      // 05: push eax
      // Now call Self^.VMT^.proc_XX(Self)
      $8B,$01,                  // 06: mov  eax, [ecx]
      $FF,$A0{,xx,xx,xx,xx}     // 08: jmp  [eax + *]
    );
    Index: 0;
    After: (
      $90,$90                   // 0C: nop, nop
    )
  );

const
  // 4096 Bytes -> 207 Entries (including the 3 IUnknown methods)
  CNumCalledMethods = 3 + (4096 - 12) div (SizeOf(TCalledWrapper) + 4);

type
  PCalledWrapperVMT = ^TCalledWrapperVMT;
  TCalledWrapperVMT = packed record
    BaseVMT: array [0 .. 2] of Pointer;
    DynVMT: array [0 .. CNumCalledMethods - 4] of Pointer;
    _Pad: Pointer;  // Align on 16 byte boundaries
    Wraps: array [0 .. CNumCalledMethods - 4] of TCalledWrapper;
  end;

var
  CalledWrapperVMT: PCalledWrapperVMT;

function GetCalledWrapperVMT: PUnknownVMT;
var
  p: PCalledWrapperVMT;
  k: Integer;
begin
  if CalledWrapperVMT = nil then
  begin
    p := VirtualAlloc(nil, SizeOf(TCalledWrapperVMT),
      MEM_COMMIT, PAGE_EXECUTE_READWRITE);
    if p = nil then
      {$IFDEF DELPHI_6_UP}
      RaiseLastOSError;
      {$ELSE}
      RaiseLastWin32Error;
      {$ENDIF}

    p^.BaseVMT[0] := @Unk_QueryInterface;
    p^.BaseVMT[1] := @Unk_AddRef;
    p^.BaseVMT[2] := @Unk_Release;

    for k := 0 to CNumCalledMethods - 4 do
    begin
      p^.Wraps[k] := CCalledWrapper;
      p^.Wraps[k].Index := 4 * (k + 3);
      p^.DynVMT[k] := @p^.Wraps[k];
    end;

    CalledWrapperVMT := p;
  end;

  Result := PUnknownVMT(CalledWrapperVMT);
end;

function CreateThiscallInterface(const Intf: IUnknown; const IID: TGUID;
  out Obj; Controlled: Boolean): HRESULT;
var
  Res: PUnknownWrapper;
begin
  Res := AllocMem(SizeOf(TUnknownWrapper));
  Res^.VMT := GetCalledWrapperVMT;
  Result := Intf.QueryInterface(IID, Res^.Intf);
  if Result = S_OK then
  begin
    Res^.RefCount := 1;
    Res^.GUID := @IID;
    if Controlled then
    begin
      Intf._Release;
      inc(Res^.RefCount);
    end;
    PUnknownWrapper(Obj) := Res;
  end
  else
  begin
    FreeMem(Res);
    Pointer(Obj) := nil;
  end;
end;

procedure FreeThiscallInterface(var Intf);
begin
  if Pointer(Intf) <> nil then
    if PUnknownWrapper(Intf)^.Intf <> nil then
    begin
      PUnknownWrapper(Intf)^.Intf := nil;
      PUnknownWrapper(Intf)^.VMT := nil;
      FreeMem(Pointer(Intf));
      Pointer(Intf) := nil;
    end;
end;

end.

