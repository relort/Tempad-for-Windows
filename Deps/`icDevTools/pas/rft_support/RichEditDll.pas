{
  RichEditDll.pas

  Managing the RichEdit 3.0+ RICHED20.DLL / MSFTEDIT.DLL modules.
  Also includes some code for debugging.

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
}

unit RichEditDll;

//{$I DelphiVersion.inc}
//{$I Rich3Conf.inc}

interface

uses
    Windows
  , SysUtils
  , RichEdit
  , RichEdit2;

type
  ERichEditDllNotFound = class(Exception);

  TRichEditModule = record
    DllName: string;
    WndClass: string;
    Version: Integer;
    Handle: THandle;
  end;

  TRichEditVersion = (rvNone, rvRichEdit3, rvRichEdit4);
  TRichEditVersions = set of TRichEditVersion;

var
  RichEditModules: array [TRichEditVersion] of TRichEditModule = (
    ( DllName: '';             WndClass: 'EDIT';          Version:  0 ),
    ( DllName: 'RICHED20.DLL'; WndClass: RICHEDIT_CLASSW; Version: -1 ),
    ( DllName: 'MSFTEDIT.DLL'; WndClass: MSFTEDIT_CLASS;  Version: -1 )
  );

var
  UseRichEditVersions: TRichEditVersions = [rvRichEdit3, rvRichEdit4];

function AvailableRichEditModules: TRichEditVersions;
function GetRichEditModuleEx(Versions: TRichEditVersions): TRichEditVersion;
function GetRichEditModule: TRichEditVersion;
procedure UnloadRichEditModules;

type
  TRichEditDebugOutputProc = procedure(const s: string);

var
  RichEditDebugOutputProc: TRichEditDebugOutputProc = nil;

procedure RichEditDebugOutput(const str: string);

implementation

procedure RichEditDebugOutput(const str: string);
begin
  {$IFDEF RICHEDIT_DEBUG}
  if Assigned(RichEditDebugOutputProc) then
    RichEditDebugOutputProc(str);
  {$ENDIF}
end;

resourcestring
{$IFDEF LANG_GERMAN}
  {$DEFINE LANG_DEFINED}
  SRichEditDllNotFound = 'RichEdit Bibliothek "%s" konnte nicht geladen werden';
{$ENDIF}

{$IFNDEF LANG_DEFINED}
  SRichEditDllNotFound = 'RichEdit library "%s" could not be loaded';
{$ENDIF}

function DllVersionNumber(const Name: string): Integer;
var
  fn: string;
  VerSize, VerMisc: DWORD;
  VerBuf: pointer;
  VerInfo: PVSFixedFileInfo;
begin
  Result := 0;
  fn := Name;
  UniqueString(fn);
  VerSize := GetFileVersionInfoSize(PChar(fn), VerMisc);
  if VerSize > 0 then
  begin
    Result := 20;
    GetMem(VerBuf, VerSize + 4);
    try
      if GetFileVersionInfo(PChar(fn), VerMisc, VerSize, VerBuf) then
        if VerQueryValue(VerBuf, '\', pointer(VerInfo), VerSize) then
          if Word(VerInfo^.dwFileVersionMS) > 20 then
            Result := Word(VerInfo^.dwFileVersionMS);
    finally
      FreeMem(VerBuf);
    end;
  end;
end;

function AvailableRichEditModules: TRichEditVersions;
var
  Ver: TRichEditVersion;
begin
  Result := [];

  for Ver := High(TRichEditVersion) downto Low(TRichEditVersion) do
    if Ver <> rvNone then
      with RichEditModules[Ver] do
      begin
        if Version = -1 then
        begin
          Version := DllVersionNumber(DllName);
          if Version < 30 then
            Version := 0;
        end;

        if Version > 0 then
          include(Result, Ver);
      end;
end;

{$IFNDEF DELPHI_5_UP}
function SafeLoadLibrary(const Name: string): THandle;
var
  oem: LongInt;
  cw: Word;
begin
  // Load the richedit library
  oem := SetErrorMode(SEM_NOOPENFILEERRORBOX);
  asm
    fnstcw cw
  end;
  try
    Result := LoadLibrary(PChar(Name));
  finally
    asm
      fnclex
      fldcw cw
    end;
    SetErrorMode(oem);
  end;
end;
{$ENDIF}

function GetRichEditModuleEx(Versions: TRichEditVersions): TRichEditVersion;
var
  Ver, MinVer: TRichEditVersion;
begin
  if Versions = [] then
    Versions := UseRichEditVersions;

  MinVer := rvNone;
  for Ver := High(TRichEditVersion) downto Low(TRichEditVersion) do
    if Ver in Versions then
    begin
      MinVer := Ver;
      if Ver <> rvNone then
        with RichEditModules[Ver] do
        begin
          if Version = -1 then
          begin
            Version := DllVersionNumber(DllName);
            if Version < 30 then
              Version := 0;
          end;

          if Version > 0 then
          begin
            if Handle = 0 then
            begin
              Handle := SafeLoadLibrary(DllName);
              if (Handle > 0) and (Handle <= HINSTANCE_ERROR) then
                Handle := 0;
            end;

            if Handle <> 0 then
            begin
              Result := Ver;
              Exit;
            end;
          end;
        end;
    end;

  if MinVer <> rvNone then
    raise ERichEditDllNotFound.CreateFmt(SRichEditDllNotFound,
      [RichEditModules[MinVer].DllName]);

  Result := rvNone;
end;

function GetRichEditModule: TRichEditVersion;
begin
  Result := GetRichEditModuleEx([]);
end;

procedure UnloadRichEditModules;
var
  Ver: TRichEditVersion;
begin
  for Ver := High(TRichEditVersion) downto Low(TRichEditVersion) do
    with RichEditModules[Ver] do
      if Handle <> 0 then
      begin
        FreeLibrary(Handle);
        Handle := 0;
      end;
end;

initialization
finalization
  UnloadRichEditModules;
end.

