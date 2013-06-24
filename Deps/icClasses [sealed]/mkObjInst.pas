unit mkObjInst;

interface

uses Windows, Messages;

type
    ictWndMethod = procedure(var Message: TMessage) of object;

    PObjectInstance = ^icrObjectInstance;
    icrObjectInstance =
        packed record
            Code: Byte;
            Offset: Integer;
            case Integer of
                0: ( Next   : PObjectInstance);
                1: ( Method : ictWndMethod);
        end;

    PInstanceBlock = ^icrInstanceBlock;
    icrInstanceBlock =
        packed record
            Next       : PInstanceBlock;
            Code       : array[1..2] of Byte;
            WndProcPtr : Pointer;
            Instances  : array[0..313] of icrObjectInstance;
        end;


function CalcJmpOffset(Src, Dest: Pointer): Longint;
function StdWndProc(Window: HWND; Message, WParam: Longint; LParam: Longint): Longint; stdcall; assembler;
function MakeObjectInstance(Method: ictWndMethod): Pointer;
procedure FreeObjectInstance(ObjectInstance: Pointer);
function AllocateHWnd(Method: ictWndMethod): HWND;
procedure DeallocateHWnd(Wnd: HWND);

implementation

var  InstFreeList: PObjectInstance;
     InstBlockList: PInstanceBlock;

function CalcJmpOffset(Src, Dest: Pointer): Longint;
begin
    Result := Longint( Dest) - ( Longint( Src) + 5);
end;

function StdWndProc(Window: HWND; Message, WParam: Longint; LParam: Longint): Longint;
asm
        XOR     EAX,EAX
        PUSH    EAX
        PUSH    LParam
        PUSH    WParam
        PUSH    Message
        MOV     EDX,ESP
        MOV     EAX,[ECX].Longint[4]
        CALL    [ECX].Pointer
        ADD     ESP,12
        POP     EAX
end;

function MakeObjectInstance(Method: ictWndMethod): Pointer;
const
    BlockCode: array[1..2] of Byte = ( $59, { POP ECX }  $E9);      { JMP StdWndProc }
    PageSize = 4096;
var
    Block    : PInstanceBlock;
    Instance : PObjectInstance;
begin
    if InstFreeList = nil
        then begin
                 Block       := VirtualAlloc( nil, PageSize, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
                 Block^.Next := InstBlockList;

                 Move( BlockCode, Block^.Code, SizeOf( BlockCode));

                 Block^.WndProcPtr := Pointer( CalcJmpOffset( @Block^.Code[2], @StdWndProc));
                 Instance := @Block^.Instances;
                 repeat
                     Instance^.Code   := $E8;  { CALL NEAR PTR Offset }
                     Instance^.Offset := CalcJmpOffset(Instance, @Block^.Code);
                     Instance^.Next   := InstFreeList;
                     InstFreeList     := Instance;
                     Inc( Longint( Instance), SizeOf( icrObjectInstance));
                 until Longint(Instance) - Longint(Block) >= SizeOf(icrInstanceBlock);
                 InstBlockList := Block;
             end;
    Result           := InstFreeList;
    Instance         := InstFreeList;
    InstFreeList     := Instance^.Next;
    Instance^.Method := Method;
end;

procedure FreeObjectInstance(ObjectInstance: Pointer);
begin
    if ObjectInstance <> nil
        then begin
                 PObjectInstance( ObjectInstance)^.Next := InstFreeList;
                 InstFreeList := ObjectInstance;
             end;
end;

function AllocateHWnd(Method: ictWndMethod): HWND;
var
    UtilWindowClass : TWndClass;
    TempClass       : TWndClass;
    ClassRegistered : Boolean;
begin
    UtilWindowClass.style         := 0;
    UtilWindowClass.lpfnWndProc   := @DefWindowProc;
    UtilWindowClass.cbClsExtra    := 0;
    UtilWindowClass.cbWndExtra    := 0;
    UtilWindowClass.hInstance     := HInstance;
    UtilWindowClass.hIcon         := 0;
    UtilWindowClass.hCursor       := 0;
    UtilWindowClass.hbrBackground := 0;
    UtilWindowClass.lpszMenuName  := nil;
    UtilWindowClass.lpszClassName := 'icAllocWnd';

    ClassRegistered := GetClassInfo( HInstance, UtilWindowClass.lpszClassName, TempClass);

    if not ClassRegistered or ( TempClass.lpfnWndProc <> @DefWindowProc)
        then begin
                 if ClassRegistered
                     then Windows.UnregisterClass( UtilWindowClass.lpszClassName, HInstance);
                 Windows.RegisterClass( UtilWindowClass);
             end;

    Result := CreateWindowEx( WS_EX_TOOLWINDOW, UtilWindowClass.lpszClassName, '', WS_POPUP {+ 0}, 0, 0, 0, 0, 0, 0, HInstance, nil);
    if Assigned(Method)
        then SetWindowLong( Result, GWL_WNDPROC, Longint(MakeObjectInstance(Method)));
end;

procedure DeallocateHWnd(Wnd: HWND);
var
  Instance: Pointer;
begin
  Instance := Pointer(GetWindowLong(Wnd, GWL_WNDPROC));
  DestroyWindow(Wnd);
  if Instance <> @DefWindowProc then FreeObjectInstance(Instance);
end;

end.
