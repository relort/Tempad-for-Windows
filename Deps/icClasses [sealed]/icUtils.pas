unit icUtils;

interface

uses
    Windows
  , Messages
  , Types
  , SysUtils
  , Graphics

  , DrawRichText // юзаю цей модуль, бо він виконує свою роботу. кода багато, колупать його впадляк.
                 // як на мене, там забагато написано :)
  ;

    function ValInVal( _FullVal, _SubVal : DWORD): Boolean; inline;
    function Min( a, b : Integer) : Integer; inline;
    function Max( a, b : Integer) : Integer; inline;
    function Color32(R, G, B: Byte; A: Byte = $FF): DWORD;

    procedure rect_modify( var _rect : TRect; _l, _t, _r, _b : Integer); inline; // rect_modify( r, 100, -20, -2, +200) -> r.top = r.top+100, etc...

    //   29,03,2010 20:51
    function color_darker( _cl : TColor; _percent : byte) : TColor;
    function color_lighter( _cl : TColor; _percent : byte) : TColor;
    function drawGradient( _hdc : HDC; _x1, _y1, _x2, _y2 : SmallInt; _1cl, _2cl : TColor; _mode : byte = GRADIENT_FILL_RECT_V) : boolean;
    function drawTextWithShadow( _canvas : TCanvas; _text: string; _rect: TRect; _shadowColor : TColor; _Format: UINT = DT_LEFT or DT_VCENTER or DT_SINGLELINE) : Integer;

    // complex means rtf
    function drawComplexText( _canvas      : TCanvas;
                              _str         : String;
                              _rect        : TRect;
                              _shadow      : Boolean = true;
                              _shadowColor : TColor  = clWhite;
                              _wordWrap    : Boolean = True
                            ) : Boolean;

    function drawComplexTextEx( _canvas      : TCanvas;
                                _str         : String;
                                _rect        : TRect;
                                _colors      : array of TColor; // _colors[0] is accessed by \cf1
                                _fonts       : array of String; // _fonts[0]  is accessed by \fn1
                                _shadow      : Boolean = true;
                                _shadowColor : TColor  = clWhite;
                                _wordWrap    : Boolean = true
                              ) : Boolean;

    function complexTextToPlainText( _canvas : TCanvas; _str : String) : String;

    // str encode and decode
    const
        c_Key = 23;

    function str_encode( _src : string) : string;
    function str_decode( _src : string) : string;

    //
    function str_getSubstring( _str, _delimiter : string; _strindex : Integer) : string;

    function str_split     ( const _separator, _string: String; _max: Integer = 0) : TArray<String>;
    function str_screening ( _str : String; _initial : String = '"'; _destination : String = '""') : String;
    function str_capitalize( _str : string) : string;

type
    iccVersion_Windows =
        class
            strict private type
                ictWindowsVersions = ( wv2000, wvXp, wvVista, wv7, wv8);
                icsWindowsVersions = set of ictWindowsVersions;
            strict private
                class var FMajorVer    : Integer;
                class var FMinorVer    : Integer;
                class var FBuild       : Integer;
                class var FPlatformId  : Integer;
                class var FServicePack : string;
                class constructor ___init();
            strict private
                class var FWinVer : icsWindowsVersions;
                //
                class function ___prop_get_isWindows2000 () : Boolean; inline; static;
                class function ___prop_get_isWindowsXp   () : Boolean; inline; static;
                class function ___prop_get_isWindowsVista() : Boolean; inline; static;
                class function ___prop_get_isWindows7    () : Boolean; inline; static;
                class function ___prop_get_isWindows8    () : Boolean; inline; static;
            public
                class property Major       : Integer read FMajorVer;
                class property Minor       : Integer read FMinorVer;
                class property Build       : Integer read FBuild;
                class property PlatformId  : Integer read FPlatformId;
                class property ServicePack : String  read FServicePack;
            public
                class property isWindows2000  : Boolean read ___prop_get_isWindows2000;
                class property isWindowsXp    : Boolean read ___prop_get_isWindowsXp;
                class property isWindowsVista : Boolean read ___prop_get_isWindowsVista;
                class property isWindows7     : Boolean read ___prop_get_isWindows7;
                class property isWindows8     : Boolean read ___prop_get_isWindows8;
        end;

    iccVersion_Application =
        class
            strict private
                class var FFilename : String;

                class var F_CompanyName      : String;
                class var F_FileDescription  : String;
                class var F_FileVersion      : String;
                class var F_InternalName     : String;
                class var F_LegalCopyright   : String;
                class var F_LegalTrademark   : String;
                class var F_OriginalFilename : String;
                class var F_ProductName      : String;
                class var F_ProductVersion   : String;
                class var F_Comments         : String;

                class constructor ___init();
            public
                class property Filename : String read FFilename;

                class property CompanyName      : String read F_CompanyName;
                class property FileDescription  : String read F_FileDescription;
                class property FileVersion      : String read F_FileVersion;
                class property InternalName     : String read F_InternalName;
                class property LegalCopyright   : String read F_LegalCopyright;
                class property LegalTrademark   : String read F_LegalTrademark;
                class property OriginalFilename : String read F_OriginalFilename;
                class property ProductName      : String read F_ProductName;
                class property ProductVersion   : String read F_ProductVersion;
                class property Comments         : String read F_Comments;
        end;

    iccFile_Security =
        class // buggy over the network!!!
              // http://stackoverflow.com/questions/11157288/file-directory-security-permissions
            const
                FILE_READ_DATA        = $0001;
                FILE_WRITE_DATA       = $0002;
                FILE_APPEND_DATA      = $0004;
                FILE_READ_EA          = $0008;
                FILE_WRITE_EA         = $0010;
                FILE_EXECUTE          = $0020;
                FILE_READ_ATTRIBUTES  = $0080;
                FILE_WRITE_ATTRIBUTES = $0100;
                FILE_GENERIC_READ     = (    STANDARD_RIGHTS_READ
                                          or FILE_READ_DATA
                                          or FILE_READ_ATTRIBUTES
                                          or FILE_READ_EA
                                          or SYNCHRONIZE
                                        );
                FILE_GENERIC_WRITE    = (    STANDARD_RIGHTS_WRITE
                                          or FILE_WRITE_DATA
                                          or FILE_WRITE_ATTRIBUTES
                                          or FILE_WRITE_EA
                                          or FILE_APPEND_DATA
                                          or SYNCHRONIZE
                                        );
                FILE_GENERIC_EXECUTE  = (    STANDARD_RIGHTS_EXECUTE
                                          or FILE_READ_ATTRIBUTES
                                          or FILE_EXECUTE
                                          or SYNCHRONIZE
                                        );
                FILE_ALL_ACCESS       = (    STANDARD_RIGHTS_REQUIRED
                                          or SYNCHRONIZE
                                          or $1FF
                                        );
            strict private
            public
                class function isLocalPath( _filename : String) : Boolean;
                class function check( _filename : String; _desiredAccess : DWORD                       ) : Boolean; overload;
                class function check( _filename : String; _desiredAccess : DWORD; out _failed : Boolean) : Boolean; overload;
        end;

implementation

    function ValInVal( _FullVal, _SubVal : DWORD): Boolean;
    begin
        Result := _FullVal and _SubVal = _SubVal;
    end;

    function Min( a, b : Integer) : Integer;
    begin
        Result := a;
        if b < a
            then Result := b;
    end;

    function Max( a, b : Integer) : Integer;
    begin
        Result := a;
        if b > a
            then Result := b;
    end;

    function Color32(R, G, B: Byte; A: Byte = $FF): DWORD;
    asm
        MOV  AH,A
        SHL  EAX,16
        MOV  AH,DL
        MOV  AL,CL
    end;

    procedure rect_modify( var _rect : TRect; _l, _t, _r, _b : Integer);
    begin
        _rect.Left   := _rect.Left   + _l;
        _rect.Top    := _rect.Top    + _t;
        _rect.Right  := _rect.Right  + _r;
        _rect.Bottom := _rect.Bottom + _b;
    end;

    function color_Darker( _cl : TColor; _percent : byte) : TColor;
    var r, g, b : Byte;
    begin
        _cl := ColorToRGB( _cl);
        r   := GetRValue( _cl);
        g   := GetGValue( _cl);
        b   := GetBValue( _cl);
        r   := r - muldiv( r, _percent, 100);
        g   := g - muldiv( g, _percent, 100);
        b   := b - muldiv( b, _percent, 100);
        result := RGB( r, g, b);
    end;

    function color_Lighter( _cl : TColor; _percent : byte) : TColor;
    var r, g, b : Byte;
    begin
        _cl := ColorToRGB( _cl);
        r := GetRValue( _cl);
        g := GetGValue( _cl);
        b := GetBValue( _cl);
        r := r + muldiv( 255 - r, _percent, 100);
        g := g + muldiv( 255 - g, _percent, 100);
        b := b + muldiv( 255 - b, _percent, 100);
        result := RGB( r, g, b);
    end;

    function DrawGradient( _hdc : HDC; _x1, _y1, _x2, _y2 : SmallInt; _1cl, _2cl : TColor; _mode : byte = GRADIENT_FILL_RECT_V) : boolean;
    var
        vert : array[0..1] of TRIVERTEX;
        grad : GRADIENT_RECT;
    begin
        vert [0] .x      := _x1;
        vert [0] .y      := _y1;
        vert [0] .Red    := GetRValue( _1cl) shl 8;
        vert [0] .Green  := GetGValue( _1cl) shl 8;
        vert [0] .Blue   := GetBValue( _1cl) shl 8;
        vert [0] .Alpha  := $0000;

        vert [1] .x      := _x2;
        vert [1] .y      := _y2;
        vert [1] .Red    := GetRValue( _2cl) shl 8;
        vert [1] .Green  := GetGValue( _2cl) shl 8;
        vert [1] .Blue   := GetBValue( _2cl) shl 8;
        vert [1] .Alpha  := $0000;

        grad.UpperLeft  := 0;
        grad.LowerRight := 1;
        Result := GradientFill( _hdc, @vert, 2, @grad, 1, _mode);
    end;

    function DrawTextWithShadow( _canvas : TCanvas; _text: string; _rect: TRect; _shadowColor : TColor; _Format: UINT = DT_LEFT or DT_VCENTER or DT_SINGLELINE) : Integer;
    var tl : integer;
        oldColor : TColor;
    begin
        oldColor      := _canvas.Font.Color;

        tl := Length( _text);

        _canvas.Font.Color := _shadowColor;
        drawtext( _canvas.Handle, _text, tl, _rect, _Format);

        OffsetRect( _rect, -1, -1);

        _canvas.Font.Color := oldColor;
        result := drawtext( _canvas.Handle, _text, tl, _rect, _Format);
    end;

    function drawComplexText( _canvas      : TCanvas;
                              _str         : String;
                              _rect        : TRect;
                              _shadow      : Boolean = true;
                              _shadowColor : TColor  = clWhite;
                              _wordWrap    : Boolean = True
                            ) : Boolean;
    begin
        result := drawComplexTextEx( _canvas, _str, _Rect, [], [], _shadow, _shadowColor, _wordWrap);
    end;

        function generate_Header() : String;
        begin
            result := '{\rtf1\ansi\ansicpg1252';
        end;

        function generate_FontTable( _fontArr : array of String) : String;
        begin
            result := '';
        end;

        function generate_ColorTable( _colorArr : array of TColor) : String;
        var s : TStringBuilder;
            ndx : integer;
        begin
            s := TStringBuilder.Create( 1024, 204800);
            try
                s.Append( '{\colortbl;');

                for ndx := 0 to Length( _colorArr) - 1 do
                    begin
                        s.Append( '\red'   + IntToStr( GetRValue( _colorArr[ndx])) +
                                  '\green' + IntToStr( GetGValue( _colorArr[ndx])) +
                                  '\blue'  + IntToStr( GetBValue( _colorArr[ndx])) +
                                  ';'
                                );
                    end;


                s.Append( '}');

                // result
                result := s.ToString();
            finally
                s.Destroy();
            end;
        end;

        function generate_Content( _content : String) : String;
        begin
            if _content = ''
                then _content := ' \par';

            result := '{' + _content + '}';
        end;

        function generate_Footer() : String;
        begin
            result := '}';
        end;

        function wholeTextColor( _str : String) : String;
        begin
            result := StringReplace( _str, '\cf', '\fc', [rfReplaceAll]);
        end;

    function drawComplexTextEx( _canvas      : TCanvas;
                                _str         : String;
                                _rect        : TRect;
                                _colors      : array of TColor; // _colors[0] is accessed by \cf1
                                _fonts       : array of String; // _fonts[0]  is accessed by \fn1
                                _shadow      : Boolean = true;
                                _shadowColor : TColor  = clWhite;
                                _wordWrap    : Boolean = true
                              ) : Boolean;
    var txt : String;
        shd : String;
        old : TColor;
        fmt : TRtfTextFormat;
    begin
        // gen header
        // gen fonts
        // gen color tables
        // content
        // gen footer

        txt := generate_Header    () +
               generate_FontTable ( _fonts) +
               generate_ColorTable( _colors) +
               generate_Content   ( _str) +
               generate_Footer    ();

        if _shadow
            then shd := wholeTextColor( txt);

        fmt := [rtfWordBreak];

        // draw shadow
        old := _Canvas.Font.Color;
        if _shadow
            then begin
                     OffsetRect( _rect, 1, 1);
                     _canvas.Font.Color := _shadowColor;
                     RTFText_Draw( _canvas, _rect, shd, fmt);
                 end;

        // draw text
        if _shadow
            then begin
                     _Canvas.Font.Color := old;
                     OffsetRect( _rect, -1, -1);
                 end;


        result := RTFText_Draw( _canvas, _rect, txt, fmt);
    end;

    function complexTextToPlainText( _canvas : TCanvas; _str : String) : String;
    begin
        result := RTFText_Plain( _canvas,
                                 generate_Header    () +
                                 generate_Content   ( _str) +
                                 generate_Footer    ()
                               );
    end;


    function str_encode( _src : string) : string;
    var ndx : integer;
    begin
        Result := _src;
        for ndx := 1 to Length( Result) do
            Result[ndx] := char( WORD( Result[ndx]) + (ndx div 256) + c_Key * 2);
    end;

    function str_decode( _src : string) : string;
    var ndx : integer;
    begin
        Result := _src;
        for ndx := 1 to Length( Result) do
            Result[ndx] := char( WORD( Result[ndx]) - (ndx div 256) - c_Key * 2);
    end;

    function str_getSubstring( _str, _delimiter : string; _strindex : Integer) : string;
    var CurrIndex : Integer;
    begin
        _str := _str + _delimiter;
        if Pos( _delimiter, _str ) <> 0
            then begin
                     CurrIndex:=1;
                     while _strindex > CurrIndex do
                         begin
                             _str := Copy( _str,
                                           Pos( _delimiter, _str) + Length( _delimiter),
                                           MaxInt
                                         );
                             Inc( CurrIndex);
                         end;
                     Result := Copy( _str, 0, Pos( _delimiter, _str) - 1);
                 end;
    end;

    // taken from:
    //    http://stackoverflow.com/questions/2625707/delphi-how-do-i-split-a-string-into-an-array-of-strings-based-on-a-delimiter
    function str_split( const _separator, _string: String; _max: Integer = 0) : TArray<String>;
    var i,
        strt,
        cnt,
        sepLen : Integer;


        procedure AddString(aEnd: Integer = -1);
        var endPos: Integer;
        begin
            if (aEnd = -1)
                then endPos := i
                else endPos := aEnd + 1;

            if (strt < endPos)
                then result[cnt] := Copy(_string, strt, endPos - strt)
                else result[cnt] := '';

            Inc(cnt);
        end;

    begin
        if (_string = '') or (_max < 0)
            then begin
                     SetLength(result, 0);
                     EXIT();
                 end;

        if (_separator = '')
            then begin
                     SetLength(result, 1);
                     result[0] := _string;
                     EXIT;
                 end;

        sepLen := Length(_separator);
        SetLength(result, (Length(_string) div sepLen) + 1);

        i     := 1;
        strt  := i;
        cnt   := 0;

        while (i <= (Length(_string)- sepLen + 1)) do
            begin
                if (_string[i] = _separator[1])
                    then if (Copy(_string, i, sepLen) = _separator)
                             then begin
                                      AddString;

                                      if (cnt = _max)
                                          then begin
                                                   SetLength(result, cnt);
                                                   EXIT;
                                               end;

                                      Inc(i, sepLen - 1);
                                      strt := i + 1;
                                  end;

                Inc(i);
            end;

        AddString( Length( _string));
        SetLength( result, cnt);
    end;

    function str_screening( _str : String; _initial : String = '"'; _destination : String = '""') : String;
    begin
        result := StringReplace( _str, _initial, _destination, [rfReplaceAll]);
    end;

    function str_capitalize( _str : string) : string;
    var ndx : integer;
        len : integer;
        lst : char;
    begin
        result := _str;
        len := Length( _str);

        if len = 0
            then exit;

        lst := ' '; // force first char to be UpparCased
        for ndx := 1 to len do
            begin
                if lst = ' '
                    then result[ndx] := Char( CharUpper( pchar( result[ndx])));

                lst := result[ndx];
            end;
    end;

{ iccWindowsVersion }

class constructor iccVersion_Windows.___init;
var osVerInfo     : TOSVersionInfoEx;
begin
    osVerInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfoEx);

    FMajorVer    := -1;
    FMinorVer    := -1;
    FBuild       := -1;
    FPlatformId  := -1;
    FWinVer      := [];

    if not GetVersionEx(osVerInfo)
        then exit;

    FMajorVer    := osVerInfo.dwMajorVersion;
    FMinorVer    := osVerINfo.dwMinorVersion;
    FBuild       := osVerInfo.dwBuildNumber;
    FPlatformId  := osVerInfo.dwPlatformId;
    FServicePack := osVerInfo.szCSDVersion;

    // set bits
    if ( FMajorVer = 5) and ( FMinorVer = 0)
        then include( FWinVer, wv2000);

    if ( FMajorVer = 5) and ( FMinorVer >= 1)
        then include( FWinVer, wvXp);

    if ( FMajorVer = 6) and ( FMinorVer = 0)
        then include( FWinVer, wvVista);

    if ( FMajorVer = 6) and ( FMinorVer >= 1)
        then include( FWinVer, wv7);

    if ( FMajorVer = 7) and ( FMinorVer >= 0)
        then include( FWinVer, wv8);
end;

class function iccVersion_Windows.___prop_get_isWindows2000() : Boolean;
begin
    result := wv2000 in FWinVer;
end;

class function iccVersion_Windows.___prop_get_isWindowsXp() : Boolean;
begin
    result := wvXp in FWinVer;
end;

class function iccVersion_Windows.___prop_get_isWindowsVista() : Boolean;
begin
    result := wvVista in FWinVer;
end;

class function iccVersion_Windows.___prop_get_isWindows7() : Boolean;
begin
    result := wv7 in FWinVer;
end;

class function iccVersion_Windows.___prop_get_isWindows8() : Boolean;
begin
    result := wv8 in FWinVer;
end;

{ iccFileVersion }

class constructor iccVersion_Application.___init;
var
    size   : integer;
    buffer : pchar;
    bufVal : pointer;
    bufLen : cardinal;
    handle : cardinal;

    key_prefix : String;

    function GetInfo( _str: string) : string;
    begin
        result := '';

        if VerQueryValue(buffer, pchar( key_prefix + _str), bufVal, bufLen)
            then Result := string( pchar( bufVal));
    end;

begin
    size   := 0;
    buffer := nil;
    try
        // default params
        fFileName := ParamStr( 0);

        size   := GetFileVersionInfoSize( pchar( FFilename), handle);
        buffer := AllocMem(size);

        // do key prefix
        if not (     GetFileVersionInfo( pchar( FFilename), handle, size, buffer)
                 and VerQueryValue(buffer, '\VarFileInfo\Translation', bufVal, bufLen)
               )
            then exit;

        key_prefix := '\StringFileInfo\' +
                      IntToHex(loword(integer(bufVal^)), 4) +
                      IntToHex(hiword(integer(bufVal^)), 4) + '\';

        // fill info
        F_CompanyName      := GetInfo( 'CompanyName');
        F_FileDescription  := GetInfo( 'FileDescription');
        F_FileVersion      := GetInfo( 'FileVersion');
        F_InternalName     := GetInfo( 'InternalName');
        F_LegalCopyright   := GetInfo( 'LegalCopyright');
        F_LegalTrademark   := GetInfo( 'LegalTrademark');
        F_OriginalFilename := GetInfo( 'OriginalFilename');
        F_ProductName      := GetInfo( 'ProductName');
        F_ProductVersion   := GetInfo( 'ProductVersion');
        F_Comments         := GetInfo( 'Comments');
    finally
        FreeMem( buffer, size);
    end;
end;

{ iccFile_Security }

class function iccFile_Security.isLocalPath( _filename : String) : Boolean;
begin
    result := _filename[2] = ':';  {drive delim}
end;

class function iccFile_Security.check( _filename: String; _desiredAccess: DWORD) : Boolean;
var _failed : Boolean;
begin
    result := check( _filename, _desiredAccess, _failed) and not _failed;
end;

class function iccFile_Security.check( _filename : String; _desiredAccess : DWORD; out _failed : Boolean) : Boolean;
var Token       : DWORD;
    Status      : LongBool;
    Access      : DWORD;
    SecDescSize : DWORD;
    PrivSetSize : DWORD;
    PrivSet     : PRIVILEGE_SET;
    Mapping     : GENERIC_MAPPING;
    SecDesc     : PSECURITY_DESCRIPTOR;
begin
    Result := False;

    if not isLocalPath( _filename)
        then exit; // do not allow smth other that local filesystem


    SecDesc     := nil;
    SecDescSize := 0;

    try
        GetFileSecurity( pchar( _filename),
                            OWNER_SECURITY_INFORMATION
                         or GROUP_SECURITY_INFORMATION
                         or DACL_SECURITY_INFORMATION,
                         nil,
                         0,
                         SecDescSize
                       );

        SecDesc := GetMemory( SecDescSize);

        if not GetFileSecurity( pchar( _filename),
                                   OWNER_SECURITY_INFORMATION
                                or GROUP_SECURITY_INFORMATION
                                or DACL_SECURITY_INFORMATION,
                                SecDesc,
                                SecDescSize,
                                SecDescSize
                              )
            then begin
                     _failed := true;
                     exit;
                 end;


        ImpersonateSelf( SecurityImpersonation);
        OpenThreadToken( GetCurrentThread, TOKEN_QUERY, False, Token);

        if Token = 0
            then begin
                     _failed := true;
                     exit;
                 end;

        Mapping.GenericRead    := FILE_GENERIC_READ;
        Mapping.GenericWrite   := FILE_GENERIC_WRITE;
        Mapping.GenericExecute := FILE_GENERIC_EXECUTE;
        Mapping.GenericAll     := FILE_ALL_ACCESS;

        MapGenericMask( Access, Mapping);
        PrivSetSize := SizeOf( PrivSet);
        AccessCheck( SecDesc, Token, _desiredAccess, Mapping, PrivSet, PrivSetSize, Access, Status);
        CloseHandle( Token);

        if _desiredAccess = Access
            then result := Status;
    finally
        FreeMem( SecDesc, SecDescSize);
    end;
end;

end.
