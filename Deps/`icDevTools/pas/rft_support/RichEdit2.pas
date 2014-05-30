{
  RichEdit2.pas

  Pascal version of richedit.h (version: 2005 platform SDK - only stuff missing
  from the original RichEdit.pas, verified for Delphi versions 5 to 2009).

  Version 1.3d - always find the most current version at
  http://flocke.vssd.de/prog/code/pascal/rtflabel/

  Copyright (C) 2001-2009 Volker Siebert <flocke@vssd.de>
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

// Already emitted in Delphi's RichEdit.pas
//{$HPPEMIT '#include <RichOle.h>'}

unit RichEdit2;

{$WEAKPACKAGEUNIT}
{$MINENUMSIZE 4}

interface

uses
  Messages, Windows, RichEdit;

(*
 *      RICHEDIT.H
 *
 *      Purpose:
 *              RICHEDIT v2.0/3.0/4.0 public definitions
 *              functionality available for v2.0 and 3.0 that is not in the original
 *              Windows 95 release.
 *
 *      Copyright (c) Microsoft Corporation. All rights reserved.
 *)

const
  // NOTE:  MSFTEDIT.DLL only registers MSFTEDIT_CLASS.  If an application wants
  // to use the following Richedit classes, it needs to load the riched20.dll.
  // Otherwise, CreateWindow with RICHEDIT_CLASS would fail.
  // This also applies to any dialog that uses RICHEDIT_CLASS,
  MSFTEDIT_CLASS = 'RICHEDIT50W';

  // RichEdit messages
  {$IFDEF CPPBUILDER}{$EXTERNALSYM WM_UNICHAR}{$ENDIF}
  WM_UNICHAR                    = $0109;

  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_SHOWSCROLLBAR}{$ENDIF}
  EM_SHOWSCROLLBAR              = WM_USER + 96;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_SETTEXTEX}{$ENDIF}
  EM_SETTEXTEX                  = WM_USER + 97;

  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_FINDTEXTW}{$ENDIF}
  EM_FINDTEXTW                  = WM_USER + 123;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_FINDTEXTEXW}{$ENDIF}
  EM_FINDTEXTEXW                = WM_USER + 124;

  // RE3.0 FE messages
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_RECONVERSION}{$ENDIF}
  EM_RECONVERSION               = WM_USER + 125;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_SETIMEMODEBIAS}{$ENDIF}
  EM_SETIMEMODEBIAS             = WM_USER + 126;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_GETIMEMODEBIAS}{$ENDIF}
  EM_GETIMEMODEBIAS             = WM_USER + 127;

  // BiDi specific messages
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_SETBIDIOPTIONS}{$ENDIF}
  EM_SETBIDIOPTIONS             = WM_USER + 200;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_GETBIDIOPTIONS}{$ENDIF}
  EM_GETBIDIOPTIONS             = WM_USER + 201;

  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_SETTYPOGRAPHYOPTIONS}{$ENDIF}
  EM_SETTYPOGRAPHYOPTIONS       = WM_USER + 202;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_GETTYPOGRAPHYOPTIONS}{$ENDIF}
  EM_GETTYPOGRAPHYOPTIONS       = WM_USER + 203;

  // Extended edit style specific messages
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_SETEDITSTYLE}{$ENDIF}
  EM_SETEDITSTYLE               = WM_USER + 204;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_GETEDITSTYLE}{$ENDIF}
  EM_GETEDITSTYLE               = WM_USER + 205;

  // Extended edit style masks
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_EMULATESYSEDIT}{$ENDIF}
  SES_EMULATESYSEDIT            = 1;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_BEEPONMAXTEXT}{$ENDIF}
  SES_BEEPONMAXTEXT             = 2;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_EXTENDBACKCOLOR}{$ENDIF}
  SES_EXTENDBACKCOLOR           = 4;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_MAPCPS}{$ENDIF}
  SES_MAPCPS                    = 8;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_EMULATE10}{$ENDIF}
  SES_EMULATE10                 = 16;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_USECRLF}{$ENDIF}
  SES_USECRLF                   = 32;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_USEAIMM}{$ENDIF}
  SES_USEAIMM                   = 64;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_NOIME}{$ENDIF}
  SES_NOIME                     = 128;

  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_ALLOWBEEPS}{$ENDIF}
  SES_ALLOWBEEPS                = 256;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_UPPERCASE}{$ENDIF}
  SES_UPPERCASE                 = 512;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_LOWERCASE}{$ENDIF}
  SES_LOWERCASE                 = 1024;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_NOINPUTSEQUENCECHK}{$ENDIF}
  SES_NOINPUTSEQUENCECHK        = 2048;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_BIDI}{$ENDIF}
  SES_BIDI                      = 4096;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_SCROLLONKILLFOCUS}{$ENDIF}
  SES_SCROLLONKILLFOCUS         = 8192;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_XLTCRCRLFTOCR}{$ENDIF}
  SES_XLTCRCRLFTOCR             = 16384;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_DRAFTMODE}{$ENDIF}
  SES_DRAFTMODE                 = 32768;

  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_USECTF}{$ENDIF}
  SES_USECTF                    = $0010000;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_HIDEGRIDLINES}{$ENDIF}
  SES_HIDEGRIDLINES             = $0020000;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_USEATFONT}{$ENDIF}
  SES_USEATFONT                 = $0040000;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_CUSTOMLOOK}{$ENDIF}
  SES_CUSTOMLOOK                = $0080000;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_LBSCROLLNOTIFY}{$ENDIF}
  SES_LBSCROLLNOTIFY            = $0100000;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_CTFALLOWEMBED}{$ENDIF}
  SES_CTFALLOWEMBED             = $0200000;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_CTFALLOWSMARTTAG}{$ENDIF}
  SES_CTFALLOWSMARTTAG          = $0400000;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SES_CTFALLOWPROOFING}{$ENDIF}
  SES_CTFALLOWPROOFING          = $0800000;

  // Options for EM_SETLANGOPTIONS and EM_GETLANGOPTIONS
  {$IFDEF CPPBUILDER}{$EXTERNALSYM IMF_AUTOFONTSIZEADJUST}{$ENDIF}
  IMF_AUTOFONTSIZEADJUST        = $0010;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM IMF_UIFONTS}{$ENDIF}
  IMF_UIFONTS                   = $0020;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM IMF_DUALFONT}{$ENDIF}
  IMF_DUALFONT                  = $0080;

  // Values for EM_GETIMECOMPMODE
  {$IFDEF CPPBUILDER}{$EXTERNALSYM ICM_CTF}{$ENDIF}
  ICM_CTF                       = $0005;

  // Options for EM_SETTYPOGRAPHYOPTIONS
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TO_ADVANCEDTYPOGRAPHY}{$ENDIF}
  TO_ADVANCEDTYPOGRAPHY         = 1;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TO_SIMPLELINEBREAK}{$ENDIF}
  TO_SIMPLELINEBREAK            = 2;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TO_DISABLECUSTOMTEXTOUT}{$ENDIF}
  TO_DISABLECUSTOMTEXTOUT       = 4;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM TO_ADVANCEDLAYOUT}{$ENDIF}
  TO_ADVANCEDLAYOUT             = 8;

  // Pegasus outline mode messages (RE 3.0)

  // Outline mode message
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_OUTLINE}{$ENDIF}
  EM_OUTLINE                    = WM_USER + 220;
  // Message for getting and restoring scroll pos
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_GETSCROLLPOS}{$ENDIF}
  EM_GETSCROLLPOS               = WM_USER + 221;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_SETSCROLLPOS}{$ENDIF}
  EM_SETSCROLLPOS               = WM_USER + 222;
  // Change fontsize in current selection by wParam
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_SETFONTSIZE}{$ENDIF}
  EM_SETFONTSIZE                = WM_USER + 223;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_GETZOOM}{$ENDIF}
  EM_GETZOOM                    = WM_USER + 224;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_SETZOOM}{$ENDIF}
  EM_SETZOOM                    = WM_USER + 225;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_GETVIEWKIND}{$ENDIF}
  EM_GETVIEWKIND                = WM_USER + 226;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_SETVIEWKIND}{$ENDIF}
  EM_SETVIEWKIND                = WM_USER + 227;

  // RichEdit 4.0 messages
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_GETPAGE}{$ENDIF}
  EM_GETPAGE                    = WM_USER + 228;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_SETPAGE}{$ENDIF}
  EM_SETPAGE                    = WM_USER + 229;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_GETHYPHENATEINFO}{$ENDIF}
  EM_GETHYPHENATEINFO           = WM_USER + 230;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_SETHYPHENATEINFO}{$ENDIF}
  EM_SETHYPHENATEINFO           = WM_USER + 231;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_GETPAGEROTATE}{$ENDIF}
  EM_GETPAGEROTATE              = WM_USER + 235;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_SETPAGEROTATE}{$ENDIF}
  EM_SETPAGEROTATE              = WM_USER + 236;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_GETCTFMODEBIAS}{$ENDIF}
  EM_GETCTFMODEBIAS             = WM_USER + 237;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_SETCTFMODEBIAS}{$ENDIF}
  EM_SETCTFMODEBIAS             = WM_USER + 238;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_GETCTFOPENSTATUS}{$ENDIF}
  EM_GETCTFOPENSTATUS           = WM_USER + 240;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_SETCTFOPENSTATUS}{$ENDIF}
  EM_SETCTFOPENSTATUS           = WM_USER + 241;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_GETIMECOMPTEXT}{$ENDIF}
  EM_GETIMECOMPTEXT             = WM_USER + 242;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_ISIME}{$ENDIF}
  EM_ISIME                      = WM_USER + 243;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_GETIMEPROPERTY}{$ENDIF}
  EM_GETIMEPROPERTY             = WM_USER + 244;

  // These messages control what rich edit does when it comes accross
  // OLE objects during RTF stream in.  Normally rich edit queries the client
  // application only after OleLoad has been called.  With these messages it is possible to
  // set the rich edit control to a mode where it will query the client application before
  // OleLoad is called
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_GETQUERYRTFOBJ}{$ENDIF}
  EM_GETQUERYRTFOBJ             = WM_USER + 269;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EM_SETQUERYRTFOBJ}{$ENDIF}
  EM_SETQUERYRTFOBJ             = WM_USER + 270;

  // EM_SETPAGEROTATE wparam values
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EPR_0}{$ENDIF}
  EPR_0                         = 0;    // Text flows left to right and top to bottom
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EPR_270}{$ENDIF}
  EPR_270                       = 1;    // Text flows top to bottom and right to left
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EPR_180}{$ENDIF}
  EPR_180                       = 2;    // Text flows right to left and bottom to top
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EPR_90}{$ENDIF}
  EPR_90                        = 3;    // Text flows bottom to top and left to right

  // EM_SETCTFMODEBIAS wparam values
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CTFMODEBIAS_DEFAULT}{$ENDIF}
  CTFMODEBIAS_DEFAULT                   = $0000;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CTFMODEBIAS_FILENAME}{$ENDIF}
  CTFMODEBIAS_FILENAME                  = $0001;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CTFMODEBIAS_NAME}{$ENDIF}
  CTFMODEBIAS_NAME                      = $0002;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CTFMODEBIAS_READING}{$ENDIF}
  CTFMODEBIAS_READING                   = $0003;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CTFMODEBIAS_DATETIME}{$ENDIF}
  CTFMODEBIAS_DATETIME                  = $0004;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CTFMODEBIAS_CONVERSATION}{$ENDIF}
  CTFMODEBIAS_CONVERSATION              = $0005;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CTFMODEBIAS_NUMERIC}{$ENDIF}
  CTFMODEBIAS_NUMERIC                   = $0006;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CTFMODEBIAS_HIRAGANA}{$ENDIF}
  CTFMODEBIAS_HIRAGANA                  = $0007;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CTFMODEBIAS_KATAKANA}{$ENDIF}
  CTFMODEBIAS_KATAKANA                  = $0008;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CTFMODEBIAS_HANGUL}{$ENDIF}
  CTFMODEBIAS_HANGUL                    = $0009;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CTFMODEBIAS_HALFWIDTHKATAKANA}{$ENDIF}
  CTFMODEBIAS_HALFWIDTHKATAKANA         = $000A;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CTFMODEBIAS_FULLWIDTHALPHANUMERIC}{$ENDIF}
  CTFMODEBIAS_FULLWIDTHALPHANUMERIC     = $000B;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CTFMODEBIAS_HALFWIDTHALPHANUMERIC}{$ENDIF}
  CTFMODEBIAS_HALFWIDTHALPHANUMERIC     = $000C;

  // EM_SETIMEMODEBIAS lparam values
  {$IFDEF CPPBUILDER}{$EXTERNALSYM IMF_SMODE_PLAURALCLAUSE}{$ENDIF}
  IMF_SMODE_PLAURALCLAUSE               = $0001;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM IMF_SMODE_NONE}{$ENDIF}
  IMF_SMODE_NONE                        = $0002;

type
  // EM_GETIMECOMPTEXT wparam structure
  {$IFDEF CPPBUILDER}{$EXTERNALSYM _IMECOMPTEXT}{$ENDIF}
  _IMECOMPTEXT = packed record
    cb: LongInt;     // count of bytes in the output buffer.
    flags: DWORD;    // value specifying the composition string type.
                     // Currently only support ICT_RESULTREADSTR
  end;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM IMECOMPTEXT}{$ENDIF}
  IMECOMPTEXT = _IMECOMPTEXT;
  TImeCompText = _IMECOMPTEXT;

const
  {$IFDEF CPPBUILDER}{$EXTERNALSYM ICT_RESULTREADSTR}{$ENDIF}
  ICT_RESULTREADSTR     = 1;

  // Outline mode wparam values
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EMO_EXIT}{$ENDIF}
  EMO_EXIT              = 0;    // Enter normal mode,  lparam ignored
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EMO_ENTER}{$ENDIF}
  EMO_ENTER             = 1;    // Enter outline mode, lparam ignored
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EMO_PROMOTE}{$ENDIF}
  EMO_PROMOTE           = 2;    // LOWORD(lparam) == 0 ==>
                                //  promote  to body-text
                                // LOWORD(lparam) != 0 ==>
                                //  promote/demote current selection
                                //  by indicated number of levels
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EMO_EXPAND}{$ENDIF}
  EMO_EXPAND            = 3;    // HIWORD(lparam) = EMO_EXPANDSELECTION
                                //  -> expands selection to level
                                //  indicated in LOWORD(lparam)
                                //  LOWORD(lparam) = -1/+1 corresponds
                                //  to collapse/expand button presses
                                //  in winword (other values are
                                //  equivalent to having pressed these
                                //  buttons more than once)
                                //  HIWORD(lparam) = EMO_EXPANDDOCUMENT
                                //  -> expands whole document to
                                //  indicated level
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EMO_MOVESELECTION}{$ENDIF}
  EMO_MOVESELECTION     = 4;    // LOWORD(lparam) != 0 -> move current
                                //  selection up/down by indicated amount
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EMO_GETVIEWMODE}{$ENDIF}
  EMO_GETVIEWMODE       = 5;    // Returns VM_NORMAL or VM_OUTLINE

  // EMO_EXPAND options
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EMO_EXPANDSELECTION}{$ENDIF}
  EMO_EXPANDSELECTION   = 0;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EMO_EXPANDDOCUMENT}{$ENDIF}
  EMO_EXPANDDOCUMENT    = 1;

  {$IFDEF CPPBUILDER}{$EXTERNALSYM VM_NORMAL}{$ENDIF}
  VM_NORMAL             = 4;    // Agrees with RTF \viewkindN
  {$IFDEF CPPBUILDER}{$EXTERNALSYM VM_OUTLINE}{$ENDIF}
  VM_OUTLINE            = 2;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM VM_PAGE}{$ENDIF}
  VM_PAGE               = 9;    // Screen page view (not print layout)

  // New notifications
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EN_PARAGRAPHEXPANDED}{$ENDIF}
  EN_PARAGRAPHEXPANDED  = $070d;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EN_PAGECHANGE}{$ENDIF}
  EN_PAGECHANGE         = $070e;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EN_LOWFIRTF}{$ENDIF}
  EN_LOWFIRTF           = $070f;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EN_ALIGNLTR}{$ENDIF}
  EN_ALIGNLTR           = $0710;        // BiDi specific notification
  {$IFDEF CPPBUILDER}{$EXTERNALSYM EN_ALIGNRTL}{$ENDIF}
  EN_ALIGNRTL           = $0711;        // BiDi specific notification

  // Event notification masks
  {$IFDEF CPPBUILDER}{$EXTERNALSYM ENM_PARAGRAPHEXPANDED}{$ENDIF}
  ENM_PARAGRAPHEXPANDED = $00000020;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM ENM_PAGECHANGE}{$ENDIF}
  ENM_PAGECHANGE        = $00000040;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM ENM_LOWFIRTF}{$ENDIF}
  ENM_LOWFIRTF          = $08000000;

type
  PCharFormatA = ^TCharFormatA;
  PCharFormatW = ^TCharFormatW;
  PCharFormat = ^TCharFormat;
  PParaFormat = ^TParaFormat;

type
  { !?! ATTENTION: The definition of CHARFORMAT2A and CHARFORMAT2W in
    !?! richedit.h (2005 SDK) has an error in the C part (not C++)!
    !?!
    !?! The fields `wWeight´ and `sSpacing´ are not aligned correctly in C.
    !?! The reason for this is the way the structure is defined for C++: the
    !?! base types CHARFORMAT[AW] have `real´ sizes of $3A resp. $52. These
    !?! are rounded to $3C resp. $54 due to a structure alignment of 4 (which
    !?! are the values you get with `sizeof´).
    !?!
    !?! For C++ these structures are expanded in an OOP-like way by
    !?!   struct CHARFORMAT2W : _charformatw ...
    !?!   struct CHARFORMAT2A : _charformata ...
    !?! which puts the next field `wWeight´ at offset $3C resp. $54.
    !?!
    !?! For C these structure are not expanded but all fields are redeclared.
    !?! Due to this fact, the field `wWeight´ gets the offset $3A resp. $52,
    !?! because a short field only needs an alignment of 2. The following
    !?! field `sSpacing´ is also badly aligned. The next field `crBackColor´
    !?! needs an alignment of 4, thus this and all following fields are
    !?! aligned correctly (as in C++).
    !?!
    !?! Following are the correct types to use with delphi. A new field
    !?! `_StructAlign´ has been added between the old structure CHARFORMAT[AW]
    !?! and the new 2.0 fields to get the required alignment.
  }
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CHARFORMAT2A}{$ENDIF}
  CHARFORMAT2A = packed record
    cbSize: UINT;
    dwMask: DWORD;
    dwEffects: DWORD;
    yHeight: LongInt;
    yOffset: LongInt;           // > 0 for superscript, < 0 for subscript
    crTextColor: TColorRef;
    bCharSet: Byte;
    bPitchAndFamily: Byte;
    szFaceName: array [0 .. LF_FACESIZE - 1] of AnsiChar;
    _StructAlign: Word;         // !?! Alignment padding (read note above)
    wWeight: Word;              // Font weight (LOGFONT value)
    sSpacing: SmallInt;         // Amount to space between letters
    crBackColor: TColorRef;     // Background color
    lid: LCID;                  // Locale ID
    dwReserved: DWORD;          // Reserved. Must be 0
    sStyle: SmallInt;           // Style handle
    wKerning: Word;             // Twip size above which to kern char pair
    bUnderlineType: Byte;       // Underline type
    bAnimation: Byte;           // Animated text like marching ants
    bRevAuthor: Byte;           // Revision author index
    bReserved1: Byte;           // Fill up to even size
  end;

  {$IFDEF CPPBUILDER}{$EXTERNALSYM CHARFORMAT2W}{$ENDIF}
  CHARFORMAT2W = packed record
    cbSize: UINT;
    dwMask: DWORD;
    dwEffects: DWORD;
    yHeight: LongInt;
    yOffset: LongInt;           // > 0 for superscript, < 0 for subscript
    crTextColor: TColorRef;
    bCharSet: Byte;
    bPitchAndFamily: Byte;
    szFaceName: array [0 .. LF_FACESIZE - 1] of WideChar;
    _StructAlign: Word;         // !?! Alignment padding (read note above)
    wWeight: Word;              // Font weight (LOGFONT value)
    sSpacing: SmallInt;         // Amount to space between letters
    crBackColor: TColorRef;     // Background color
    lid: LCID;                  // Locale ID
    dwReserved: DWORD;          // Reserved. Must be 0
    sStyle: SmallInt;           // Style handle
    wKerning: Word;             // Twip size above which to kern char pair
    bUnderlineType: Byte;       // Underline type
    bAnimation: Byte;           // Animated text like marching ants
    bRevAuthor: Byte;           // Revision author index
    bReserved1: Byte;           // Fill up to even size
  end;

  {$IFDEF CPPBUILDER}{$EXTERNALSYM CHARFORMAT2}{$ENDIF}
  CHARFORMAT2 = CHARFORMAT2A;

  TCharFormat2A = CHARFORMAT2A;
  TCharFormat2W = CHARFORMAT2W;
  TCharFormat2 = TCharFormat2A;

const
  {!?! CHECK THIS: If the underline color is stored in the upper 4 bits
   !?! of "bUnderlineType", how can we have underline types above 15?
   !?!}
  // Underline types. RE 1.0 displays only CFU_UNDERLINE
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CFU_UNDERLINETHICKLONGDASH}{$ENDIF}
  CFU_UNDERLINETHICKLONGDASH    = 18;   // (*) display as dash
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CFU_UNDERLINETHICKDOTTED}{$ENDIF}
  CFU_UNDERLINETHICKDOTTED      = 17;   // (*) display as dot
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CFU_UNDERLINETHICKDASHDOTDOT}{$ENDIF}
  CFU_UNDERLINETHICKDASHDOTDOT  = 16;   // (*) display as dash dot dot
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CFU_UNDERLINETHICKDASHDOT}{$ENDIF}
  CFU_UNDERLINETHICKDASHDOT     = 15;   // (*) display as dash dot
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CFU_UNDERLINETHICKDASH}{$ENDIF}
  CFU_UNDERLINETHICKDASH        = 14;   // (*) display as dash
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CFU_UNDERLINELONGDASH}{$ENDIF}
  CFU_UNDERLINELONGDASH         = 13;   // (*) display as dash
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CFU_UNDERLINEHEAVYWAVE}{$ENDIF}
  CFU_UNDERLINEHEAVYWAVE        = 12;   // (*) display as wave
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CFU_UNDERLINEDOUBLEWAVE}{$ENDIF}
  CFU_UNDERLINEDOUBLEWAVE       = 11;   // (*) display as wave
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CFU_UNDERLINEHAIRLINE}{$ENDIF}
  CFU_UNDERLINEHAIRLINE         = 10;   // (*) display as single
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CFU_UNDERLINETHICK}{$ENDIF}
  CFU_UNDERLINETHICK            = 9;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CFU_UNDERLINEWAVE}{$ENDIF}
  CFU_UNDERLINEWAVE             = 8;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CFU_UNDERLINEDASHDOTDOT}{$ENDIF}
  CFU_UNDERLINEDASHDOTDOT       = 7;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CFU_UNDERLINEDASHDOT}{$ENDIF}
  CFU_UNDERLINEDASHDOT          = 6;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM CFU_UNDERLINEDASH}{$ENDIF}
  CFU_UNDERLINEDASH             = 5;

  // EM_SETCHARFORMAT wParam masks
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SCF_ASSOCIATEFONT}{$ENDIF}
  SCF_ASSOCIATEFONT     = $0010;  // Associate fontname with bCharSet (one
                                  //  possible for each of Western, ME, FE, Thai)
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SCF_NOKBUPDATE}{$ENDIF}
  SCF_NOKBUPDATE        = $0020;  // Do not update KB layput for this change
                                  //  even if autokeyboard is on
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SCF_ASSOCIATEFONT2}{$ENDIF}
  SCF_ASSOCIATEFONT2    = $0040;  // Associate plane-2 (surrogate) font

type
  PTextRange = ^TTextRange;
  TTextRange = TTextRangeA;
  
const
  // Stream formats. Flags are all in low word, since high word
  // gives possible codepage choice.
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SF_USECODEPAGE}{$ENDIF}
  SF_USECODEPAGE        = $0020;  // CodePage given by high word
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SF_NCRFORNONASCII}{$ENDIF}
  SF_NCRFORNONASCII     = $0040;  // Output /uN for nonASCII
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SFF_WRITEXTRAPAR}{$ENDIF}
  SFF_WRITEXTRAPAR      = $0080;  // Output \par at end

  // Flag telling file stream output (SFF_SELECTION flag not set) to persist
  // \viewscaleN control word.
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SFF_PERSISTVIEWSCALE}{$ENDIF}
  SFF_PERSISTVIEWSCALE  = $2000;

  // Flag telling file stream input with SFF_SELECTION flag not set not to
  // close the document
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SFF_KEEPDOCINFO}{$ENDIF}
  SFF_KEEPDOCINFO       = $1000;

  // Flag telling stream operations to output in Pocket Word format
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SFF_PWD}{$ENDIF}
  SFF_PWD               = $0800;

  // 3-bit field specifying the value of N - 1 to use for \rtfN or \pwdN
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SF_RTFVAL}{$ENDIF}
  SF_RTFVAL             = $0700;

  // All paragraph measurements are in twips

  {$IFDEF CPPBUILDER}{$EXTERNALSYM MAX_TABLE_CELLS}{$ENDIF}
  MAX_TABLE_CELLS       = 63;

  // PARAFORMAT 2.0 masks and effects
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFM_TEXTWRAPPINGBREAK}{$ENDIF}
  PFM_TEXTWRAPPINGBREAK = $20000000;    // RE 3.0
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFM_TABLEROWDELIMITER}{$ENDIF}
  PFM_TABLEROWDELIMITER = $10000000;    // RE 4.0

  // The following three properties are read only
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFM_COLLAPSED}{$ENDIF}
  PFM_COLLAPSED         = $01000000;    // RE 3.0
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFM_OUTLINELEVEL}{$ENDIF}
  PFM_OUTLINELEVEL      = $02000000;    // RE 3.0
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFM_BOX}{$ENDIF}
  PFM_BOX               = $04000000;    // RE 3.0
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFM_RESERVED2}{$ENDIF}
  PFM_RESERVED2         = $08000000;    // RE 4.0

  //!?! VS: Added by me
  PFM_ALL3 = PFM_ALL2 or PFM_COLLAPSED or PFM_OUTLINELEVEL or PFM_BOX or
    PFM_TEXTWRAPPINGBREAK;
  PFM_ALL4 = PFM_ALL3 or PFM_TABLEROWDELIMITER;

  // New effects
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFE_TEXTWRAPPINGBREAK}{$ENDIF}
  PFE_TEXTWRAPPINGBREAK = PFM_TEXTWRAPPINGBREAK shr 16; // (*)

  // The following four effects are read only
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFE_COLLAPSED}{$ENDIF}
  PFE_COLLAPSED         = PFM_COLLAPSED shr 16; // (+)
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFE_BOX}{$ENDIF}
  PFE_BOX               = PFM_BOX shr 16;       // (+)
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFE_TABLE}{$ENDIF}
  PFE_TABLE             = PFM_TABLE shr 16;     // Inside table row. RE 3.0
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFE_TABLEROWDELIMITER}{$ENDIF}
  PFE_TABLEROWDELIMITER = PFM_TABLEROWDELIMITER shr 16; // Table row start. RE 4.0

  // PARAFORMAT2 wNumbering options
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFN_ARABIC}{$ENDIF}
  PFN_ARABIC            = 2;    // tomListNumberAsArabic:   0, 1, 2,    ...
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFN_LCLETTER}{$ENDIF}
  PFN_LCLETTER          = 3;    // tomListNumberAsLCLetter: a, b, c,    ...
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFN_UCLETTER}{$ENDIF}
  PFN_UCLETTER          = 4;    // tomListNumberAsUCLetter: A, B, C,    ...
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFN_LCROMAN}{$ENDIF}
  PFN_LCROMAN           = 5;    // tomListNumberAsLCRoman:  i, ii, iii, ...
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFN_UCROMAN}{$ENDIF}
  PFN_UCROMAN           = 6;    // tomListNumberAsUCRoman:  I, II, III, ...

  // PARAFORMAT2 wNumberingStyle options
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFNS_PAREN}{$ENDIF}
  PFNS_PAREN            = $000; // default, e.g.,                         1)
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFNS_PARENS}{$ENDIF}
  PFNS_PARENS           = $100; // tomListParentheses/256, e.g.,         (1)
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFNS_PERIOD}{$ENDIF}
  PFNS_PERIOD           = $200; // tomListPeriod/256, e.g.,               1.
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFNS_PLAIN}{$ENDIF}
  PFNS_PLAIN            = $300; // tomListPlain/256, e.g.,                1
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFNS_NONUMBER}{$ENDIF}
  PFNS_NONUMBER         = $400; // Used for continuation w/o number
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFNS_NEWNUMBER}{$ENDIF}
  PFNS_NEWNUMBER        = $8000;// Start new number with wNumberingStart
                                // (can be combined with other PFNS_xxx)

  // PARAFORMAT2 alignment options
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFA_JUSTIFY}{$ENDIF}
  PFA_JUSTIFY           = 4;    // New paragraph-alignment option 2.0 (*)
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFA_FULL_INTERWORD}{$ENDIF}
  PFA_FULL_INTERWORD    = 4;    // These are supported in 3.0 with advanced
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFA_FULL_INTERLETTER}{$ENDIF}
  PFA_FULL_INTERLETTER  = 5;    //  typography enabled
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFA_FULL_SCALED}{$ENDIF}
  PFA_FULL_SCALED       = 6;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFA_FULL_GLYPHS}{$ENDIF}
  PFA_FULL_GLYPHS       = 7;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM PFA_SNAP_GRID}{$ENDIF}
  PFA_SNAP_GRID         = 8;

type
  PENDropFiles = ^TENDropFiles;
  TENDropFiles = TEndDropFiles;

  PENOleOpFailed = ^TENOleOpFailed;

  PObjectPositions = ^TObjectPositions;

  PENLink = ^TENLink;

  PENLowFiRTF = ^TENLowFiRTF;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM _enlowfirtf}{$ENDIF}
  _enlowfirtf = packed record
    nmhdr: TNMHdr;
    szControl: PChar;
  end;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM ENLOWFIRTF}{$ENDIF}
  ENLOWFIRTF = _enlowfirtf;
  TENLowFiRTF = ENLOWFIRTF;

  PENCorrectText = ^TENCorrectText;

  PPunctuation = ^TPunctuation;

  PCompColor = ^TCompColor;

type
  // UndoName info
  {$IFDEF CPPBUILDER}{$EXTERNALSYM UNDONAMEID2}{$ENDIF}
  UNDONAMEID2 = (UID_UNKNOWN, UID_TYPING, UID_DELETE, UID_DRAGDROP, UID_CUT,
    UID_PASTE, UID_AUTOCORRECT);

const
  // Flags for the SETEXTEX data structure
  {$IFDEF CPPBUILDER}{$EXTERNALSYM ST_DEFAULT}{$ENDIF}
  ST_DEFAULT            = 0;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM ST_KEEPUNDO}{$ENDIF}
  ST_KEEPUNDO           = 1;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM ST_SELECTION}{$ENDIF}
  ST_SELECTION          = 2;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM ST_NEWCHARS}{$ENDIF}
  ST_NEWCHARS           = 4;

type
  // EM_SETTEXTEX info; this struct is passed in the wparam of the message
  PSetTextEx = ^TSetTextEx;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM _settextex}{$ENDIF}
  _settextex = packed record
    flags: DWORD;       // Flags (see the ST_XXX defines)
    codepage: UINT;     // Code page for translation (CP_ACP for sys default,
                        //  1200 for Unicode, -1 for control default)
  end;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM SETTEXTEX}{$ENDIF}
  SETTEXTEX = _settextex;
  TSetTextEx = _settextex;

const
  // Flags for the GETEXTEX data structure
  {$IFDEF CPPBUILDER}{$EXTERNALSYM GT_SELECTION}{$ENDIF}
  GT_SELECTION          = 2;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM GT_RAWTEXT}{$ENDIF}
  GT_RAWTEXT            = 4;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM GT_NOHIDDENTEXT}{$ENDIF}
  GT_NOHIDDENTEXT       = 8;

type
  // BiDi specific features
  PBiDiOptions = ^TBiDiOptions;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM _bidioptions}{$ENDIF}
  _bidioptions = packed record
    cbSize: UINT;
    wMask: Word;
    wEffects: Word;
  end;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM BIDIOPTIONS}{$ENDIF}
  BIDIOPTIONS = _bidioptions;
  TBiDiOptions = BIDIOPTIONS;

const
  // BIDIOPTIONS masks
  {$IFDEF CPPBUILDER}{$EXTERNALSYM BOM_DEFPARADIR}{$ENDIF}
  BOM_DEFPARADIR        = $0001; // [1.0] Default paragraph direction (implies alignment) (obsolete)
  {$IFDEF CPPBUILDER}{$EXTERNALSYM BOM_PLAINTEXT}{$ENDIF}
  BOM_PLAINTEXT         = $0002; // [1.0] Use plain text layout (obsolete)
  {$IFDEF CPPBUILDER}{$EXTERNALSYM BOM_NEUTRALOVERRIDE}{$ENDIF}
  BOM_NEUTRALOVERRIDE   = $0004; // Override neutral layout (obsolete)
  {$IFDEF CPPBUILDER}{$EXTERNALSYM BOM_CONTEXTREADING}{$ENDIF}
  BOM_CONTEXTREADING    = $0008; // Context reading order
  {$IFDEF CPPBUILDER}{$EXTERNALSYM BOM_CONTEXTALIGNMENT}{$ENDIF}
  BOM_CONTEXTALIGNMENT  = $0010; // Context alignment

  // BIDIOPTIONS effects
  {$IFDEF CPPBUILDER}{$EXTERNALSYM BOE_RTLDIR}{$ENDIF}
  BOE_RTLDIR            = $0001; // [1.0] Default paragraph direction (implies alignment) (obsolete)
  {$IFDEF CPPBUILDER}{$EXTERNALSYM BOE_PLAINTEXT}{$ENDIF}
  BOE_PLAINTEXT         = $0002; // [1.0] Use plain text layout (obsolete)
  {$IFDEF CPPBUILDER}{$EXTERNALSYM BOE_NEUTRALOVERRIDE}{$ENDIF}
  BOE_NEUTRALOVERRIDE   = $0004; // Override neutral layout (obsolete)
  {$IFDEF CPPBUILDER}{$EXTERNALSYM BOE_CONTEXTREADING}{$ENDIF}
  BOE_CONTEXTREADING    = $0008; // Context reading order
  {$IFDEF CPPBUILDER}{$EXTERNALSYM BOE_CONTEXTALIGNMENT}{$ENDIF}
  BOE_CONTEXTALIGNMENT  = $0010; // Context alignment

const
  //+++++ ADDED FROM COMMDLG.H +++++
  {$IFDEF CPPBUILDER}{$EXTERNALSYM FR_DOWN}{$ENDIF}
  FR_DOWN               = $00000001;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM FR_WHOLEWORD}{$ENDIF}
  FR_WHOLEWORD          = $00000002;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM FR_MATCHCASE}{$ENDIF}
  FR_MATCHCASE          = $00000004;
  
  // Additional EM_FINDTEXT[EX] flags
  {$IFDEF CPPBUILDER}{$EXTERNALSYM FR_MATCHDIAC}{$ENDIF}
  FR_MATCHDIAC          = $20000000;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM FR_MATCHKASHIDA}{$ENDIF}
  FR_MATCHKASHIDA       = $40000000;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM FR_MATCHALEFHAMZA}{$ENDIF}
  FR_MATCHALEFHAMZA     = $80000000;

const
  // UNICODE embedding character
  {$IFDEF CPPBUILDER}{$EXTERNALSYM WCH_EMBEDDING}{$ENDIF}
  WCH_EMBEDDING         = WideChar($FFFC);

type
  // khyph - Kind of hyphenation
  TKHyph = (
    khyphNil,           // No Hyphenation
    khyphNormal,        // Normal Hyphenation
    khyphAddBefore,     // Add letter before hyphen
    khyphChangeBefore,  // Change letter before hyphen
    khyphDeleteBefore,  // Delete letter before hyphen
    khyphChangeAfter,   // Change letter after hyphen
    khyphDelAndChange   // Delete letter before hyphen and change
                        //  letter preceding hyphen
  );

  PHyphResult = ^THyphResult;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM HYPHRESULT}{$ENDIF}
  HYPHRESULT = packed record
    khyph: TKHyph;      // Kind of hyphenation
    ichHyph: LongInt;   // Character which was hyphenated
    chHyph: WideChar;   // Depending on hyphenation type, character added, changed, etc.
  end;
  THyphResult = HYPHRESULT;

  {$IFDEF CPPBUILDER}{$EXTERNALSYM HyphenateProc}{$ENDIF}
  HyphenateProc = procedure(pszWord: PWideChar; langid: LANGID; ichExceed: LongInt;
    var phyphresult: THyphResult); stdcall;
  THyphenateProc = HyphenateProc;

  PHyphenateInfo = ^THyphenateInfo;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM tagHyphenateInfo}{$ENDIF}
  tagHyphenateInfo = packed record
    cbSize: SmallInt;           // Size of HYPHENATEINFO structure
    dxHyphenateZone: SmallInt;  // If a space character is closer to the margin
                                //  than this value, don't hyphenate (in TWIPs)
    pfnHyphenate: THyphenateProc;
  end;
  {$IFDEF CPPBUILDER}{$EXTERNALSYM HYPHENATEINFO}{$ENDIF}
  HYPHENATEINFO = tagHyphenateInfo;
  THyphenateInfo = tagHyphenateInfo;

implementation

end.

