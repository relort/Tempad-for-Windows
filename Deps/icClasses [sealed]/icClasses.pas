unit icClasses;

{
    ©Бугаєвський Павло, 2009-2010. Всі права захищено.
    Декларація класу iccList є клоном TList і належить справжньому власнику.


    web-site:
               http://inline-coder.net

    e-mail:
               inline-coder@inbox.ru
               inlinecoder@gmail.com
}
{$DEFINE IncludeAbout}

interface

uses
    Windows     // WinAPI
  , Messages    // Windows Messages
  ,   mkObjInst // MakeObjectInstance and FreeObjectInstance, also AllocateHWND

  , SyncObjs

  , Variants
  , TypInfo
  , SysUtils    // ...
  , Classes     // Threads, Streams
  , RTLConsts   // Default Error Strings

  //, Graphics    // Extended functionality
  , ShellApi    // ShellNotifyIcon
  , Controls    // TControl for iccTweener
  , Math        // Easings

  , icUtils     // some string utils
  ;

type
    //    Object
    iccObject = TObject;

    //    Dynamic Object
    iccList = class;
    iccDynamicObject =
        class( iccObject)
             const
                 c_loadFromFile_ok            = 0; // data was read successfully
                 c_loadFromFile_fileNotFound  = 1; // file is missing
                 c_loadFromFile_corruptedData = 2; // file is present but data is not native or contain unsatisfied shit
                 c_loadFromFile_unknownError  = 3; // ...
             strict private const
                 c_item_delim          = ' | '; // values must be screened
                 c_item_idData_delim   = ' : '; //

                 c_screen_item_delim   = ' || '; // screens
                 c_screen_idData_delim = ' :: '; //
             strict private type
                 iccItem =
                     class
                         public
                             ID   : String;
                             DATA : Variant;
                         public
                             constructor Create( _id : String; _data : Variant);
                     end;
             strict private
                 function str_screen( _str : String) : String;
                 function str_escape( _str : String) : String;
             strict private
                 FItems : iccList;
                 function locate_result_item ( _id : String) : iccItem; // nil if item with _id not found in FItems
                 function locate_result_index( _id : String) : Integer; // -1 if not found
             public
                 procedure define( _id : String; _dta : Variant); // add new or set new value for existed. data is not copied, just uses pointer
                 function get( _ndx : Integer) : Variant; overload; // link to original data
                 function get( _id  : String ) : Variant; overload;

                 function del( _ndx : Integer) : Boolean; overload; virtual;
                 function del( _id  : String ) : Boolean; overload; virtual;
             public
                 constructor Create(); virtual;
                 destructor Destroy(); override;
             public
                 function clr() : Boolean; virtual;
                 function cnt() : Integer; inline;
             public
                 function getID     ( _ndx : Integer) : String;
                 function getID_safe( _ndx : Integer; out _exist : Boolean) : String;
             public
                 function IDExist( _ID : String) : Boolean;
             public
                 function ToString(                                        ) : String; overload; override;
                 function ToString( _onItemProcess : TFunc<Variant, String>) : String; reintroduce; overload; virtual;

                 function FromString( _str : String) : Boolean; overload; virtual; // true = success
                 function FromString( _str : String; _onItemProcess : TFunc<String, Variant>) : Boolean; overload; virtual;
             public
                 function loadFromFile( _filename : String) : Boolean; overload;
                 function loadFromFile( _filename : String; out _error : Byte) : Boolean; overload;
                 function saveToFile  ( _filename : String) : Boolean;
             public
                 property ID  [_ndx : Integer] : String  read getID;
                 property Item[_id  : String]  : Variant read get write define; default;
        end;

    //    Interfaced Object
    iccInterfacedObject =
        class( iccObject, IInterface)
            strict private
                FAutoDestroy : Boolean;
            public
                FRefCount    : Integer;
                function QueryInterface( const IID : TGUID; out Obj) : HResult; stdcall;
                function _AddRef  : Integer; virtual; stdcall;
                function _Release : Integer; virtual; stdcall;
            public
                constructor Create;// virtual;
                destructor Destroy; override;
            public
                class function NewInstance : TObject; override;
                procedure AfterConstruction; override;
                procedure BeforeDestruction; override;
            public
                property RefCount    : Integer read FRefCount;
                property AutoDestroy : Boolean read FAutoDestroy write FAutoDestroy;
        end;

    //    Exception
    iccException =
        class( Exception)
            const
                c_prior_None         = 0; // simple exception, do not influence overall run-time flow
                c_prior_Error        = 1; // error, need to handle
                c_prior_FATAL        = 5; // fatal exception, program must be halted.
            strict private
                FPriority : BYTE;
            public
                constructor Create( const _Msg : pchar); overload;
                constructor Create( const _Msg : pchar; _priority : BYTE); overload;
                //destructor Destroy; override;
            public
                property Priority : BYTE read FPriority;
        end;

    iccException_NotImplYet =
        class( Exception)
            public
                constructor Create();
        end;

    //    Exception Handler
    iccExceptionHandler =
        class( iccObject)
            type
                ictOnException = procedure ( _exc : Exception; _nativeException : Boolean = True; _otherObj : TObject = nil);
                // _exc = exception object     _nativeException = true
                // if ! _nativeException -> _exc = nil     and    _otherObj = some kind of class that raised an exception (may be nil, if object is not avail)

                ictOnUnhandledException = procedure ( _exc : Exception);
            strict private
                class var FOnException          : ictOnException;
                class var FOnUnhandledException : ictOnUnhandledException;
            strict private
                class var FOLD_ExceptProc         : pointer; // procedure ( _excObj : tObject; _excAddr : DWORD);
                                                             // Unhanled Error *confused*, needed becase if case of 0 / 0 both ( RaiseExceptionProc and RaiseExceptObjProc ) are not called
                class var FOLD_RaiseExceptionProc : pointer; // procedure ( _dwExcCode, _dwExcFlags, _nNumberOfAgrs : DWORD; _lpArguments : PDWORD {pointer to array[0..14] of longint});
                class var FOLD_RaiseExceptObjProc : pointer; // procedure ( _pExceptionRecord : pExceptionRecord);
            private
                class var clsvar_CreateAlready : Boolean;
                class constructor ___Initialize();
                class destructor  ___Finalize();
            public
                class procedure eh_ExceptProc( _excObject : TObject; _excAddr : DWORD); static;
                class procedure eh_RaiseExceptionProc( _dwExceptionCode,
                                                       _dwExceptionFlags,
                                                       _nNumberOfArguments : DWORD;
                                                       _lpArguments        : PDWORD
                                                     ); stdcall; static;
                class procedure eh_RaiseExceptObjProc( _pexcrecord : PExceptionRecord); static;
            public
                class property OnException          : ictOnException          read FOnException          write FOnException;
                class property OnUnhandledException : ictOnUnhandledException read FOnUnhandledException write FOnUnhandledException;
        end;

    //    List
    iccList =
        class( iccObject)
            const
               MaxListSize = Maxint div 16;
            type
               ictpPointerList      = ^ictPointerList;
               ictPointerList       = array[ 0..MaxListSize - 1] of Pointer;
               ictListSortCompare   = function ( _Item1, _Item2 : Pointer) : Integer;
               ictListNotification  = ( lnAdded, lnExtracted, lnDeleted);
               ictListAssignOp      = ( laCopy, laAnd, laOr, laXor, laSrcUnique, laDestUnique);

               iccListEnumerator =
                   class
                       strict private
                           FIndex : Integer;
                           FList  : iccList;
                       public
                           constructor Create( _List: iccList);
                           function GetCurrent : Pointer;
                           function MoveNext   : Boolean;
                       public
                           property Current : Pointer read GetCurrent;
                   end;
            protected
                function Get          ( _Index : Integer) : Pointer;
                procedure Put         ( _Index : Integer; _Item : Pointer);
                
                procedure Grow; virtual;
                procedure Notify      ( _Ptr : Pointer; _Action : ictListNotification); virtual;
                procedure SetCapacity ( _NewCapacity : Integer);
                procedure SetCount    ( _NewCount    : Integer);
            strict private
                FList     : ictpPointerList;
                FCount    : Integer;
                FCapacity : Integer;
            public
                destructor Destroy; override;

                class procedure Error( const Msg: string;   _Data: Integer); overload; virtual;
                class procedure Error( _Msg: PResStringRec; _Data: Integer); overload;

                function Add     ( _Item : Pointer) : Integer;
                function Remove  ( _Item : Pointer) : Integer;
                function Extract ( _Item : Pointer) : Pointer;
                procedure Delete ( _Index: Integer);
                procedure Clear; virtual;
                procedure Exchange( _Index1, _Index2: Integer);
                function Expand : iccList;
                function First  : Pointer;
                function Last   : Pointer;
                function GetEnumerator: iccListEnumerator;
                function IndexOf( _Item: Pointer): Integer;
                procedure Insert( _Index: Integer; _Item: Pointer);
                procedure Move( _CurIndex, _NewIndex: Integer);
                procedure Pack;
                procedure Sort( _Compare: ictListSortCompare);
                procedure Assign( _ListA: iccList; _Operator: ictListAssignOp = laCopy; _ListB: iccList = nil);
            public
                property Capacity : Integer                read FCapacity write SetCapacity;
                property Count    : Integer                read FCount    write SetCount;
                property Items[ Index : Integer] : Pointer read Get       write Put; default;
                property List     : ictpPointerList        read FList;
        end;

    //    xList
    // вдосконалена версія звичайного iccList
    // клас для зберігання данних по індексу (під данними мається на увазі 4байта(DWORD, pointer))
    // створений для підвищення швидкодії за рахунок виділення пам'яті блоками (10, 100, 100 за 1 раз)
    // і використання фрагментності списку (тобто при збільшенні виділеної пам'яті стара не перевиділяється
    // і не переміщається, для цього використовується список адрес фрагментів)
    iccxList =
        class sealed( iccObject)
            strict private
                type
                    icrpFragmentDescriptor = ^icrFragmentDescriptor;
                    icrFragmentDescriptor =
                        record
                            Address    : DWORD;    // де знаходиться фрагмент
                            StartIndex : Integer;  // з якого індекса в цьому сегменті починаються данні
                            Count      : WORD;     // скільки данних лежить в цьому сегменті
                        end;
            strict private
                var   c_AllocPerTime : WORD;          // almost constant
                const c_DataSize     : byte = sizeof( DWORD);
            strict private
                FCount                  : Integer; // загальна к-сть елементів в фрагментах
                FFragmentDescriptorsLen : WORD;
                FFragmentDescriptors    : array of icrFragmentDescriptor; // набагато швидше, якшо використовувати прост дин. масив замість iccList
            strict private
                function GetSegmentIndexByIndex( _ndx : Integer) : Integer; inline; // знайти в якому сегменті знаходиться потрібний індекс елемента | -1 - not found, other - found
            strict private
                function AllocBlock                   : pointer; overload; // виділити пам'ять для блока і записати адрес фрагменту в Список
                function DeallocBlock( _ndx : WORD)   : boolean; // звільнити пам'ять і стерти адресу фрагменту по індексу зі Списку
                function DeallocBlocks                : Boolean; // звільнити абсолютно всі блоки за 1 раз
            public
                constructor Create( _allocpertime : WORD = 32);
                destructor Destroy; override;
            public
                function Cnt() : Integer; inline; // ? :)
                //
                function Get   ( _ndx : Integer) : DWORD;
                function GetNdx( _dta : DWORD  ) : Integer; // index of FIRST matching
                //
                function Define( _ndx : Integer; _val : DWORD) : Boolean; // define
                //
                function Add( _dta : DWORD) : boolean;
                function Ins( _ndx : Integer; _data : DWORD) : boolean;
                //
                function Del   ( _ndx : Integer) : boolean;
                function DelRes( _ndx : Integer) : DWORD;
                function Rem( _dta : DWORD  ) : Boolean;  // delete FIRST matching
                //
                function Clr() : Boolean; inline; // ? :)
            private
                procedure ___prop_setItem( _ndx : Integer; _val : DWORD); inline;
            public
                property Count              : Integer read FCount;
                property Item[_ndx:Integer] : DWORD   read Get write ___prop_setItem; default;
        end;

    //    xList <_type>
    iccxList<_type> = // bounded by 4 bytes
        class( iccObject)
             private
                 FList : iccxList;
             public
                 constructor Create( _allocpertime : WORD = 32);
                 destructor Destroy; override;
             public
                 function Cnt() : Integer; inline;
                 //
                 function Get   ( _ndx : Integer) : _type;
                 function GetNdx( _dta : _type  ) : Integer; // index of FIRST matching
                 //
                 function Define( _ndx : Integer; _val : _type) : Boolean; overload; // define
                 function Define( _dta : _type  ; _val : _type) : Boolean; overload; //
                 //
                 function Add( _dta : _type              ) : Boolean;
                 function Ins( _ndx : DWORD; _dta : _type) : Boolean;
                 //
                 function Del   ( _ndx : Integer) : Boolean;
                 function DelRes( _ndx : Integer) : _type;
                 function Rem( _dta : _type  ) : Boolean; // delete FIRST matching
                 //
                 function Clr() : Boolean; inline;
             private
                 procedure ___prop_setItem( _ndx : Integer; _val : _type); inline;
             public
                 property Count : Integer read Cnt;
                 property Item[_ndx : Integer] : _type read Get write ___prop_setItem; default;
        end;

    // list with append functionality only. For Speed Purposes
    iccxList_append<_type> =
        class sealed
            private type
                arrType  = array[Word] of _type;
                parrType = ^arrType;
            private
                FAmountPerAlloc : Word;
                FDataSizeAlloc  : Cardinal;
                FFragmentsArr   : array[Word] of parrType;
                FFragmentsCnt   : Word;
                FOffset         : Word;
                FCount          : Cardinal;
            public
                constructor Create( _AmountPerAlloc : Word = 32);
                destructor Destroy(); override;
            public
                function cnt       () : Cardinal; // slower than property. compability purpose
                function add       ( _val : _type) : Boolean;
                function get       ( _ndx : Cardinal) : _type; // no bounds control
                function get_safe  ( _ndx : Cardinal) : _type; // safe
                procedure asg      ( _ndx : Cardinal; _val : _type); // no bounds control
                procedure asg_safe ( _ndx : Cardinal; _val : _type); // safe
            public
                property Count                 : Cardinal read FCount;
                property Item[_ndx : Cardinal] : _type    read get write asg; default;
        end;

    //    Typed list <_type>
    iccTypedList<_type> = // _type can be any size. if size = 4 it'll better to use iccxList<*>
        class( iccObject)
            private type
                ptr_type = ^ _type;
            private
                FList : iccxList;
                function translateTO  ( _tp : _type) : DWORD;
                function translateFROM( _dw : DWORD) : _type;
            public
                constructor Create();
                destructor Destroy(); override;
            public
                function Cnt() : DWORD;
                //
                function Get( _ndx : DWORD) : _type;
//                function GetNdx( _dta : _type) : Integer;
                //
//                function Define( _ndx : DWORD) : Boolean; overload;
//                function Define( _dta : _type) : Boolean; overload;
                //
                function Add( _dta : _type) : Boolean;
//                function Ins( _ndx : DWORD; _dta : _type) : Boolean;
                //
                function Del( _ndx : DWORD) : Boolean;
//                function Rem( _dta : _type) : Boolean;
                //
                function Clr() : Boolean;
        end;

    //    Assocs
    iccAssocList<_type> = // internal class for iccAssocs. moved from in-class types in case of buggy delphi's generics
        class
            private
                FName : String;
                FList : iccTypedList<_type>; //iccxList;
            public
                constructor Create( _name : String);
                destructor Destroy(); override;
        end;

    iccAssocs<_type> =
        class( iccObject)
            private
                FAssocLists : iccxList<iccAssocList<_type>>;
                function getList     ( _name : String) : iccAssocList<_type>;
                function getListIndex( _name : String) : Integer;
            public
                constructor Create();
                destructor Destroy(); override;
            public
                function assocGet( _name : String) : iccTypedList<_type>; //iccxList; // result = copy of list with vals
                function assocAdd( _name : String; _val : _type) : Boolean;
                function assocRem( _name : String; _val : _type) : Boolean;
                function assocClr( _name : String) : Boolean;
        end;

    //    Event Dispatcher
                ict_ed_State = ( edsCreating,          // move to private in DELPHI update
                                 edsCreated,           //     http://forum.sources.ru/index.php?showtopic=308888&hl=
                                 edsDestroying,        //     проблема: модуль uTKList. класс TKList<T>. приватные типы.
                                 edsDestroyed,         //     решения: приватные типы TItemsType и PUser вынести в глобальную область видимости.
                                 edsLocked             //
                               );                      //
                ics_ed_State = set of ict_ed_State;    //

    iccEventDispatcher<_function> =
        class( iccObject)
            type
                ict_ed_forEachProc             = reference to procedure( _func : _function; _params : array of const);
                ict_ed_forEach_onExceptionProc = reference to procedure( _name : String; _func : _function; var _abortDispatching : Boolean);
            private
                FState : ics_ed_State;

                FForEachProc             : ict_ed_forEachProc;
                FForEach_onExceptionProc : ict_ed_forEach_onExceptionProc;
                FAssocs : iccAssocs<_function>;
            public
                constructor Create( _forEachProc : ict_ed_forEachProc);
                destructor Destroy(); override;
            public
                function addEventListener( _name : String; _func : _function) : Boolean;
                function remEventListener( _name : String; _func : _function) : Boolean;
                //
                function dispatchEvent( _name : String; _params : array of const) : Boolean;
                //
                function clrEventListeners( _name : String) : Boolean;
                function cpyEventListeners( _name : String; _destED : iccEventDispatcher<_function>) : Boolean;
            public
                property onException : ict_ed_forEach_onExceptionProc read FForEach_onExceptionProc write FForEach_onExceptionProc;
        end;


    //    Component
    iccComponent =
        class( iccObject)
            type
                ictComponentName = type string;
                iccComponents =
                    class( iccList)
                    end;
                ictpComponentNotify = ^ictComponentNotify;    
                ictComponentNotify =
                    packed record
                        Code     : WORD;
                        DataType : set of ( cndtPointer, cndtString, cndtInteger, cndtNone);
                        Data     : DWORD; // _Data may be used as Address, if DataType set to cndtPointer or cndtString
                    end;
            strict private
                FOwner      : iccComponent;
                FName       : ictComponentName;
                FComponents : iccComponents;

                procedure ___prop_SetName( _value : ictComponentName);
                function  ___prop_GetComponent( _index : Integer) : iccComponent;
                function  ___prop_GetComponentsCount : Integer;

                function  ValidateName( _Name : ictComponentName) : Boolean;
            public
                constructor Create( _Owner : iccComponent); virtual;
                destructor Destroy; override;

                procedure DestroyComponents;
                procedure Notify( _Sender : iccComponent; _Notify : ictpComponentNotify); virtual;{ abstract;}

                function  GetComponent( _Name : ictComponentName) : iccComponent;
            public
                property Owner      : iccComponent                   read FOwner;
                property Name       : ictComponentName               read FName write ___prop_SetName;
                property Components : iccComponents                  read FComponents;
                property Component[ index : Integer] : iccComponent  read ___prop_GetComponent; default;
                property ComponentsCount : Integer                   read ___prop_GetComponentsCount;
        end;

    //    Timer
    iccTimer =
        class( iccComponent)
            type
                ictTimerEvent = procedure( _Sender : iccObject) of object;
                ictTimerEventExternal = procedure ( _Sender : iccObject);
                {$IFDEF VER210}
                ictTimerEventReference = reference to procedure ( _Sender : iccObject);
                {$ENDIF}
            strict private
                FID : Cardinal;

                FMethodPTR : Pointer;
                procedure TimerProc( var _MSG : TMessage);
            strict private
                FEnabled  : Boolean;
                FInterval : WORD;
                FOnTimer  : ictTimerEvent;
                FOnTimerExternal : ictTimerEventExternal;
                {$IFDEF VER210}
                FOnTimerReference : ictTimerEventReference;
                {$ENDIF}

                procedure ___prop_SetEnabled ( _value : Boolean);
                procedure ___prop_SetInterval( _value : WORD);
                procedure ___prop_SetOnTimer ( _value : ictTimerEvent);
                procedure ___prop_SetOnTimerExternal( _value : ictTimerEventExternal);
                {$IFDEF VER210}
                procedure ___prop_SetOnTimerReference( _value : ictTimerEventReference);
                {$ENDIF}

                procedure Update;
            public
                constructor Create( _Owner : iccComponent); override;
                destructor Destroy; override;
            public
                property Enabled  : Boolean       read FEnabled  write ___prop_SetEnabled;
                property Interval : WORD          read FInterval write ___prop_SetInterval;
                property OnTimer          : ictTimerEvent          read FOnTimer          write ___prop_SetOnTimer;
                property OnTimerExternal  : ictTimerEventExternal  read FOnTimerExternal  write ___prop_SetOnTimerExternal;
                {$IFDEF VER210}
                property OnTimerReference : ictTimerEventReference read FOnTimerReference write ___prop_SetOnTimerReference;
                {$ENDIF}
        end;

    //    Timeout
    iccTimeout =
        class( iccObject)
            strict private type
                iccRecord =
                    class
                            id : DWORD;
                            pr : TProc;
                        public
                            constructor Create( _id : DWORD; _pr : TProc);
                    end;
            strict private
                class var FList : iccxList<iccRecord>;
                class procedure ___event( _hwnd : DWORD; _msg : DWORD; _id : DWORD; _getTickCount : DWORD); stdcall; static;

                class function list_Locate( _id : DWORD) : Integer;

                class constructor Create();
                class destructor ClearMem();
            public
                class function set__( _delay : Integer; _proc : TProc) : DWORD;
                class function unset( _id : DWORD; _callProc : Boolean = false) : Boolean;
        end;

    //    Event Notifier
    iccEventNotifier =
        class( iccObject)
            const
                c_EventNotifierMsg : DWORD = WM_USER + $CC;// WM_APP + 101;

            type
                iciEventObject =
                    interface( IInterface)
                        function  getReceiver : HWND;
                        procedure setReceiver( _hwnd : HWND);

                        // Set window will receive msgs
                        // with:
                        //     Handle   - handle
                        //     Message  - message ID
                        //     wParam   - currentTarget address
                        //     lParam   - param data

                        procedure Lock;
                        procedure Unlock;

                        function AddEvent( _param : DWORD; _ms : DWORD) : Boolean; // add delayed event to queue
                        function ClrQueue() : Boolean; // Clear queue
                    end;

            strict private const
                c_EventNotifierThreadLock = 'EventNotifierThreadLock';

            strict private type
                // PostMessage( FReciever, c_MessageID, i eventObject {sender}, param {event data})
                // для швидкодії і синхронізації введені виклик методів через змінні
                // коли об'єкт не зайнятий, максимальна швидкодія,
                // а коли з об'єктом хтось вже працює, то всі операції виконуються в безпечному режимі
                iccEventObject =
                    class( iccInterfacedObject, iciEventObject)
                        type
                            ictpItem = ^ictItem;
                            ictItem  =
                                object
                                    param : DWORD;
                                    ms    : Integer;
                                end;

                             ictState = ( eosReleased,   // to be destroyed
                                          eosLocked,     // locked
                                          eosDestroying  // entered destroyind state
                                        );
                             icsState = set of ictState;

                             ict_proc_Add = function( _param : DWORD; _ms : DWORD) : Boolean of object;
                             ict_proc_Del = function( _ndx  : DWORD) : Boolean of object;
                             ict_proc_Get = function( _ndx  : DWORD) : DWORD of object;
                        strict private
                            FState    : icsState;
                            FProc_Add : ict_proc_Add;
                            FProc_Del : ict_proc_Del;
                            FProc_Get : ict_proc_Get;
                            FList     : iccxList;
                        private
                            FReceiver : HWND;
                        public
                            constructor Create();
                            destructor Destroy(); override;
                        public
                            procedure CheckAvailability();
                            procedure Lock();
                            procedure Unlock();
                            procedure Release();
                        public
                            function  getReceiver : HWND;
                            procedure setReceiver( _hwnd : HWND);
                            function AddEvent( _param : DWORD; _ms : DWORD) : Boolean;
                            function ClrQueue() : Boolean;
                        public
                            function Cnt() : DWORD;

                            function _Add( _param : DWORD; _ms : DWORD) : Boolean; // unsafe, fast methods
                            function _Del( _ndx : DWORD) : Boolean;                //
                            function _Get( _ndx : DWORD) : DWORD;                  //

                            function safe_Add( _param : DWORD; _ms : DWORD) : Boolean; // safe methods
                            function safe_Del( _ndx : DWORD) : Boolean;                //
                            function safe_Get( _ndx : DWORD) : DWORD;                  //

                            function Clr() : Boolean;
                        public
                             property State    : icsState read FState;

                             property Add : ict_proc_Add read FProc_Add;
                             property Del : ict_proc_Del read FProc_Del;
                             property Get : ict_proc_Get read FProc_Get;
                    end;

                iccEventObjectManager =
                    class( iccObject)
                        strict private
                            FList : iccxList;
                        public
                            constructor Create;
                            destructor Destroy; override;
                        public
                            function Cnt() : DWORD;
                            function Add() : iccEventObject;
                            function Del( _ndx : DWORD) : boolean; overload;
                            function Del( _eobj : iccEventObject) : boolean; overload;
                            function Get( _ndx : DWORD) : iccEventObject;
                            function Clr() : Boolean;
                        public
                            property Item[_indx:DWORD]:iccEventObject read Get; default;
                    end;

                iccThreadWrapper =
                    class( TThread)
                        strict private
                            FParent  : iccEventNotifier;
                            FHWND    : HWND;
                            FEOMgr   : iccEventObjectManager;
                            FTimer   : iccTimer;
                            FCounter : DWORD;
                        strict private
                            procedure ThreadMessageProcessor( var _Msg : TMessage);
                            procedure ___event_onTimer( _Sender : iccObject);
                        protected
                            procedure Execute; override;
                        public
                            procedure setParent( _parent : iccEventNotifier);
                            function RegisterEventObject : iciEventObject;
                            function UnregisterEventObject( _eventObject : iciEventObject) : Boolean;
                        public
                            property WndHandle : HWND read FHWND;
                    end;
            strict private
                FThreadLock : DWORD; // event handle
                FThread     : iccThreadWrapper; // all work performs outside the main thread
            public
                constructor Create;
                destructor Destroy; override;
            public
                function RegisterEventObject : iciEventObject;
                function UnregisterEventObject( _eventObject : iciEventObject) : Boolean;
        end;

    //    ShellNotifyIcon
    iccShellNotifyIcon =
        class( iccComponent)
            type
                iceShellNotifyIconMouseButtons = ( snimbNone, snimbLeft, snimbMiddle, snimbRight);
                iceShellNotifyIconMouseActions = ( snimaMove, snimaDown, snimaUp, snimaClick, snimaDoubleClick);
                ictShellNotifyIconMouseEvent = procedure ( _Sender : iccObject; _Button : iceShellNotifyIconMouseButtons; _Action : iceShellNotifyIconMouseActions; _X, _Y : Smallint) of object;
            const WM_USER_ShellIcon = WM_USER + 1;
            class var TaskBarCreationMsg : DWORD;
            class constructor ___Initialize;
            protected       procedure ShellProc( var _Msg : TMessage);
            strict private
                FNotifyIconData : PNotifyIconData;

                FWindowHandle  : HWND;
                FEnabled : Boolean;
                FICON    : HICON;
                FVisible : Boolean;
                FTip     : pchar;

                procedure ___prop_SetEnabled( _value : Boolean);
                procedure ___prop_SetIcon( _value : HICON);
                procedure ___prop_SetVisible( _value : boolean);
                procedure ___prop_SetTip( _value : pchar);
            protected
                FLPressed,
                FMPressed,
                FRPressed : Boolean; // Just to know exactly mouse's button state

                FOnEvent : ictShellNotifyIconMouseEvent;
            public
                constructor Create( _Owner : iccComponent); override;
                destructor Destroy; override;

                procedure UpdateNotifyIconData;
            public
                function Update : Boolean; overload;
                function Update( _operation : Integer) : Boolean; overload;
            public
                property Handle  : HWND    read FWindowHandle;
                property Enabled : Boolean read FEnabled write ___prop_SetEnabled;
                property Icon    : HICON   read FICON    write ___prop_SetIcon;
                property Visible : Boolean read FVisible write ___prop_SetVisible;
                property Tip     : pchar   read FTip     write ___prop_SetTip;

                property OnEvent    : ictShellNotifyIconMouseEvent read FOnEvent    write FOnEvent;
        end;

    // Screen
    iccScreen =
        class( iccObject)
            public
                class function Width () : SmallInt;
                class function Height() : SmallInt;
        end;

    // Thread
    iciThread =
        interface
            function resume   () : Boolean;
            function suspend  () : Boolean;
            function terminate() : Boolean;
            //
            function waitFor  ( _timeout : DWORD) : Boolean;
            //function doSync   ( _hwnd : HWND; _wparam, _lparam : Integer; _post : Boolean = False) : Boolean; overload; // window handle to receive wm_app + 1 .PostMessage or SendMessage
            function doSync   ( _hwnd : HWND; _proc : TProc; _post : Boolean = False) : Boolean; overload;
            //
            function set_AutoDestroy( _autoDestroy : Boolean = true) : Boolean;
            function get_AutoDestroy() : Boolean;
        end;

    iccThread =
        class( iccInterfacedObject, iciThread)
            const
                wm_sync = wm_app + 1;
            type
                icr_wm_sync =
                    packed record
                        Msg: Cardinal;
                        case Integer of
                            0: (
                                  WParam : DWORD;
                                  LParam : DWORD;
                                  Result : DWORD;
                               );
                            1: (
                                  Proc   : ^TProc;
                               )
                    end;

            type
                ictThreadStagingProc = reference to procedure (); // start body finish
                ictThreadOnErrorProc = reference to procedure ( _e : Exception = nil); // on error in Staging procs
            private type
                ictState = ( tsCreating,
                             tsCreated,
                             tsDestroying,
                             tsDestroyed,

                             tsSuspended,
                             tsResumed,
                             tsTerminated,

                             tsError     // error occured
                           );
                icsState = set of ictState;

                ictpInternalThreadProcParams = ^ ictInternalThreadProcParams;
                ictInternalThreadProcParams =
                    record
                        Self         : iccThread;
                        proc_Body    : ictThreadStagingProc;
                        proc_onError : ictThreadOnErrorProc;
                    end;


            public
                function _AddRef () : Integer; override;
                function _Release() : Integer; override;

            strict private
                FState  : icsState;
                FHandle : DWORD;
                FID     : DWORD;
                FParams : ictInternalThreadProcParams;

                class var clsvar_CriticalSection : TCriticalSection;
                class var clsvar_ThreadList      : iccxList<iccThread>;
                class function internalThreadProc( _p : pointer) : Integer; stdcall; static;
            public
                class constructor ___init();
                class destructor  ___done();
            public
                constructor Create( _procBody    : ictThreadStagingProc;
                                    _procOnError : ictThreadOnErrorProc = nil
                                  );
                destructor Destroy(); override;
            protected
                function resume   () : Boolean;
                function suspend  () : Boolean;
                function terminate() : Boolean;
                //
                function waitFor( _timeout : DWORD) : Boolean;
                function doSync   ( _hwnd : HWND; _wparam, _lparam : Integer; _post : Boolean = False) : Boolean; overload; // window handle to receive wm_app + 1 .PostMessage or SendMessage
                function doSync   ( _hwnd : HWND; _proc : TProc; _post : Boolean = False) : Boolean; overload;
                //
                function set_AutoDestroy( _autoDestroy : Boolean = true) : Boolean;
                function get_AutoDestroy() : Boolean;
            public
                class function threadAdd( _procBody    : ictThreadStagingProc;
                                          _procOnError : ictThreadOnErrorProc = nil
                                        ) : iciThread; // allocating new thread
            public
                property State : icsState read FState;
        end;



var ExceptionHandler : iccExceptionHandler;

const
    c_default_Format : TFormatSettings = // формат дати | день, місяць, рік
    (
        ThousandSeparator : ',';
        DecimalSeparator  : '.';
        DateSeparator     : '.';
        TimeSeparator     : ':';

        ShortDateFormat   : 'dd.mm.yyyy';

        ShortTimeFormat : 'hh:mm';
        LongTimeFormat  : 'hh:mm:ss';
    );

implementation

{ iccInterfacedObject }

function iccInterfacedObject.QueryInterface( const IID : TGUID; out Obj) : HResult;
begin
    if GetInterface( IID, Obj)
        then Result := 0
        else Result := E_NOINTERFACE;
end;

function iccInterfacedObject._AddRef  : Integer;
begin
    Result := InterlockedIncrement( FRefCount);
end;

function iccInterfacedObject._Release : Integer;
begin
     Result := InterlockedDecrement( FRefCount);
     if (AutoDestroy) and (Result = 0)
         then Destroy;
end;

class function iccInterfacedObject.NewInstance : TObject;
begin
    result := inherited NewInstance;
end;

constructor iccInterfacedObject.Create;
begin
    inherited;
    AutoDestroy := True;
end;

destructor iccInterfacedObject.Destroy;
begin
    inherited;
end;

procedure iccInterfacedObject.AfterConstruction;
begin
end;

procedure iccInterfacedObject.BeforeDestruction;
begin
end;

{ iccDynamicObject }

constructor iccDynamicObject.iccItem.Create( _id : String; _data : Variant);
begin
    ID   := _id;
    DATA := _data;
end;

function iccDynamicObject.str_screen( _str : String) : String;
begin
    result := str_screening( _str  , c_item_delim       , c_screen_item_delim);
    result := str_screening( result, c_item_idData_delim, c_screen_idData_delim);
end;

function iccDynamicObject.str_escape( _str : String) : String;
begin
    result := str_screening( _str  , c_screen_item_delim  , c_item_delim);
    result := str_screening( result, c_screen_idData_delim, c_item_idData_delim);
end;

function iccDynamicObject.locate_result_item( _id : String) : iccItem;
var ndx : integer;
    tmp : iccItem;
begin
    result := nil;

    for ndx := 0 to FItems.Count - 1 do
        begin
            tmp := iccItem( FItems[ndx]);
            if tmp.ID = _id
                then exit( tmp);
        end;
end;

function iccDynamicObject.locate_result_index( _id : String) : Integer;
var ndx : integer;
    tmp : iccItem;
begin
    result := -1;

    for ndx := 0 to FItems.Count - 1 do
        begin
            tmp := iccItem( FItems[ndx]);
            if tmp.ID = _id
                then exit( ndx);
        end;
end;

constructor iccDynamicObject.Create();
begin
    inherited;
    FItems := iccList.Create();
end;

destructor iccDynamicObject.Destroy();
begin
    clr();
    FItems.Destroy();
    inherited;
end;

procedure iccDynamicObject.define( _id : String; _dta : Variant);
var tmp : iccItem;
begin
    if _id = ''
        then raise iccException.Create( 'iccDynamicObject.define() -> _id can not be ''''.');


    tmp := locate_result_item( _id);
    if tmp = nil
        then FItems.Add( iccItem.Create( _id, _dta) )
        else tmp.DATA := _dta;
end;

function iccDynamicObject.get( _ndx : Integer) : Variant;
begin
    if ( _ndx < 0) or ( _ndx >= FItems.Count)
        then begin
                 TVarData(result).VType    := varNull;
                 TVarData(result).vPointer := nil;
             end
        else result := iccItem( FItems[_ndx]).DATA;
end;

function iccDynamicObject.get( _id : String) : Variant;
var tmp : iccItem;
begin
    tmp := locate_result_item( _id);
    if tmp = nil
        then begin
                 TVarData(result).VType     := varNull;
                 TVarData( result).vPointer := nil;
             end
        else result := locate_result_item( _id).DATA;
end;

function iccDynamicObject.del( _ndx : Integer) : Boolean;
var itm : iccItem;
begin
    itm := FItems[_ndx];
    FItems.Delete( _ndx);
    itm.Destroy();

    result := true;
end;

function iccDynamicObject.del( _id  : String ) : Boolean;
var ndx : integer;
begin
    ndx := locate_result_index( _id);

    result := false;
    if ndx = -1
        then exit;

    result := del( ndx);
end;

function iccDynamicObject.clr() : Boolean;
var ndx : integer;
begin
    for ndx := 0 to FItems.Count - 1 do
        iccItem( FItems[ndx]).Destroy();


    FItems.Clear();

    // result
    result := true;
end;

function iccDynamicObject.cnt() : Integer;
begin
    result := FItems.Count;
end;

function iccDynamicObject.getID( _ndx : Integer) : String;
begin
    if ( _ndx < 0) or ( _ndx >= FItems.Count)
        then exit( '');

    result := iccItem( FItems[_ndx]).ID;
end;

function iccDynamicObject.getID_safe( _ndx : Integer; out _exist : Boolean) : String;
begin
    _exist := false; // default result

    if ( _ndx < 0) or ( _ndx >= FItems.Count)
        then exit( '');


    result := iccItem( FItems[_ndx]).ID;
    _exist := true;
end;

function iccDynamicObject.IDExist( _ID : String) : Boolean;
begin
    result := locate_result_item( _ID) <> nil;
end;

function iccDynamicObject.toString() : String;
{
var ndx : integer;
    sbl : TStringBuilder;
    itm : iccItem;
begin
    sbl := TStringBuilder.Create( FItems.Count);

    for ndx := 0 to FItems.Count - 1 do
        begin
            itm := iccItem( FItems[ndx]);


            sbl.Append( str_screen( itm.ID) +
                        c_item_idData_delim +
                        str_screen( itm.DATA) +
                        c_item_delim
                      );
        end;

    // result
    result := sbl.ToString();

    sbl.Destroy();
}
begin
    result := toString( function ( _v : Variant) : string begin result := _v; end);
end;

function iccDynamicObject.toString( _onItemProcess : TFunc<Variant, String>) : String;
var ndx : integer;
    sbl : TStringBuilder;
    itm : iccItem;
begin
    if TFunc<Variant, String>( _onItemProcess) = nil
        then raise iccException.Create( 'iccDynamicObject.toString() -> _onItemProcess = nil');

    sbl := TStringBuilder.Create( FItems.Count);

    for ndx := 0 to FItems.Count - 1 do
        begin
            itm := iccItem( FItems[ndx]);


            sbl.Append( str_screen( itm.ID) +
                        c_item_idData_delim +
                        str_screen( _onItemProcess( itm.DATA)) +
                        c_item_delim
                      );
        end;

    // result
    result := sbl.ToString();

    sbl.Destroy();
end;

function iccDynamicObject.fromString( _str : String) : Boolean; // true = success
var ndx : integer;
    arr : TArray<String>;
    itm : TArray<String>;

    len : Integer;
begin
    if not clr() // clear data
        then exit( false);

    if _str = '' // empty? -> fuck off
        then exit( true);


    // parse
    arr := str_split( c_item_delim, _str);

    for ndx := 0 to Length( arr) - 1 do
        begin
            itm := str_split( c_item_idData_delim, arr[ndx]);

            len := Length( itm);

            if len = 0
                then Continue;

            // validate data
            if ( len < 2) or
               ( itm[0] = '')
                then begin
                         clr();
                         exit( false);
                     end;

            define( str_escape( itm[0]), str_escape( itm[1]));
        end;

    // result
    result := true;
end;

function iccDynamicObject.fromString( _str : String; _onItemProcess : TFunc<String, Variant>) : Boolean;
var ndx : integer;
    arr : TArray<String>;
    itm : TArray<String>;

    len : Integer;
begin
    if TFunc<String, Variant>( _onItemProcess) = nil
        then raise iccException.Create( 'iccDynamicObject.fromString() -> _onItemProcess = nil');

    if not clr() // clear data
        then exit( false);

    if _str = '' // empty? -> fuck off
        then exit( true);


    // parse
    arr := str_split( c_item_delim, _str);

    for ndx := 0 to Length( arr) - 1 do
        begin
            itm := str_split( c_item_idData_delim, arr[ndx]);

            len := Length( itm);

            if len = 0
                then Continue;

            // validate data
            if ( len < 2) or
               ( itm[0] = '')
                then begin
                         clr();
                         exit( false);
                     end;

            define( str_escape( itm[0]),  _onItemProcess( str_escape( itm[1])));
        end;

    // result
    result := true;
end;

function iccDynamicObject.loadFromFile( _filename : String) : Boolean;
var err : Byte;
begin
    result := loadFromFile( _filename, err);
end;

function iccDynamicObject.loadFromFile( _filename : String; out _error : Byte) : Boolean;
var fs : TFileStream;
    ts : TStringStream;
begin
    fs := nil;
    ts := nil;
    try
        result := false;

        try
            if not FileExists( _filename)
                then begin
                         _error := c_loadFromFile_fileNotFound;
                         exit;
                     end;

            fs := TFileStream.Create( _filename, fmOpenRead);
            //
            ts := TStringStream.Create( '', TEncoding.UTF8);
            ts.LoadFromStream( fs);

            result := fromString( str_decode( ts.DataString));

            if not result
                then _error := c_loadFromFile_corruptedData
        except // swallow
            _error := c_loadFromFile_unknownError;
            result := false;
        end;
    finally
        ts.Free();
        fs.Free();
    end;
end;

function iccDynamicObject.saveToFile( _filename : String) : Boolean;
var fs : TFileStream;
    ts : TStringStream;
begin
    fs := nil;
    ts := nil;
    try
        try
            fs := TFileStream.Create( _filename, fmCreate or fmOpenReadWrite);

            ts := TStringStream.Create( str_encode( toString()), TEncoding.UTF8);
            ts.SaveToStream( fs);

            result := true;
        except
            result := false;
        end;
    finally
        ts.Free();
        fs.Free();
    end;
end;

{ iccException }

constructor iccException.Create( const _Msg: pchar);
begin
    inherited Create( _Msg);
    FPriority := c_prior_None;

//    ExceptionHandler.HandleException( Self, _Msg);
end;

constructor iccException.Create( const _Msg : pchar; _priority : BYTE);
begin
    inherited Create( _Msg);
    FPriority := _priority;

//    ExceptionHandler.HandleException( self, _Msg);
end;

{ iccException_NotImplYet }

constructor iccException_NotImplYet.Create();
begin
    inherited Create( 'Not implemented yet');
end;

{ iccExceptionHandler }

class constructor iccExceptionHandler.___Initialize();
begin
    // push
    FOLD_ExceptProc         := ExceptProc;
    FOLD_RaiseExceptionProc := RaiseExceptionProc;
    FOLD_RaiseExceptObjProc := RaiseExceptObjProc;

    ExceptProc         := @eh_ExceptProc;
    RaiseExceptionProc := @eh_RaiseExceptionProc;
    RaiseExceptObjProc := @eh_RaiseExceptObjProc;

    clsvar_CreateAlready := true;
end;

class destructor iccExceptionHandler.___Finalize;
begin
    if not clsvar_CreateAlready
        then exit;

    // pop
    RaiseExceptionProc := FOLD_RaiseExceptionProc;
    RaiseExceptObjProc := FOLD_RaiseExceptObjProc;
end;

class procedure iccExceptionHandler.eh_ExceptProc( _excObject : TObject; _excAddr : DWORD);
begin
    //raise EInvalidOp.Create( 'Not implemented!');
    // this shit...
    try
        MessageBox( 0, pchar( 'eh_ExceptpProc() -> Handling is not implemented. Critical.' + #13#13 + 'Application is closing right now.'), 'Exception Handler.', MB_OK or MB_ICONERROR);
    finally
        ExitProcess( 0);
    end;
end;

class procedure iccExceptionHandler.eh_RaiseExceptionProc( _dwExceptionCode, _dwExceptionFlags, _nNumberOfArguments: DWORD; _lpArguments: PDWORD);
type
    pArgsInterpret = ^ ArgsInterpret;
    ArgsInterpret =
        record
            case { IsOsException: } Boolean of
                True
                     :  ( ExceptionInformation : array [0..14] of Longint);
                False
                     :  ( ExceptAddr   : Pointer;
                          ExceptObject : Pointer
                        );
        end;
const
  cDelphiException    = $0EEDFADE;
  cDelphiReRaise      = $0EEDFADF;
  cDelphiExcept       = $0EEDFAE0;
  cDelphiFinally      = $0EEDFAE1;
  cDelphiTerminate    = $0EEDFAE2;
  cDelphiUnhandled    = $0EEDFAE3;
  cNonDelphiException = $0EEDFAE4;
  cDelphiExitFinally  = $0EEDFAE5;
  cCppException       = $0EEFFACE;

//  ---> from System.pas
// These values are Delphi's magic codes :)

{
var obj : TObject;
begin
    if _dwExceptionCode <> $EEDFADE // cDelphiException
        then case _dwExceptionCode of
                 $0EEDFADF : writeln( 'cDelphiReRaise');
                 $0EEDFAE0 : writeln( 'cDelphiExcept');
                 $0EEDFAE1 : writeln( 'cDelphiFinally');
                 $0EEDFAE2 : writeln( 'cDelphiTerminate');
                 $0EEDFAE3 : writeln( 'cDelphiUnhandled');
                 $0EEDFAE4 : writeln( 'cNonDelphiException');
                 $0EEDFAE5 : writeln( 'cDelphiExitFinally');
                 $0EEFFACE : writeln( 'cCppException');

                 else writeln( 'UNIDENTIFIED COMMAND');
             end
        else begin
                 obj := TObject( pArgsInterpret( _lpArguments).ExceptObject);
                 if obj <> nil
                     then writeln( obj.ClassName)
                     else writeln( 'exception object = nil');
             end;
}
var obj             : TObject;
    exc             : Exception;
    nativeException : Boolean;

    procedure process();
    begin
        try
            if _dwExceptionCode = cDelphiException
                then begin
                         obj := ExceptObject();
                         if obj is Exception
                             then begin
                                      exc := Exception( obj);
                                      nativeException := True;

                                      obj := nil; // no need
                                  end
                             else begin
                                      exc := nil;
                                      nativeException := False;
                                  end;

                         if Assigned( FOnException)
                             then FOnException( exc, nativeException, obj);
                     end;


            ///    DEBUG SUPPORT
            ///////////////////////////////////////////////////////////////////////
            if _dwExceptionCode = cDelphiExcept // HANDLED EXCEPTIONS
                then begin // notify DELPHI exception
                         obj := ExceptObject();
                         if obj is Exception
                             then begin
                                      exc := Exception( obj);
                                      nativeException := True;

                                      obj := nil; // no need
                                  end
                             else begin
                                      exc := nil;

                                      nativeException := False;
                                  end;

                         if Assigned( FOnException)
                             then FOnException( exc, nativeException, obj);
                     end
                else if _dwExceptionCode = cDelphiUnhandled // UNHANDLED EXCEPTIONS
                         then begin
                                  if Assigned( FOnUnhandledException)
                                      then FOnUnhandledException( pArgsInterpret( _lpArguments).ExceptObject);
                              end
                         else if _dwExceptionCode = cNonDelphiException
                                  then begin // notify NON-DELPHI exception
                                           if Assigned( FOnException)
                                              then FOnException( nil, false, pArgsInterpret( _lpArguments).ExceptObject);
                                       end;
        finally
        end;
    end;

begin
    try
        ///////////////
        RaiseException( _dwExceptionCode, _dwExceptionFlags, _nNumberOfArguments, _lpArguments);
        ///////////////
    finally // this block is present here to provide error handling in run-time
        ///    RUN-TIME SUPPORT
        ///////////////////////////////////////////////////////////////////////
        process();
    end;
end;

class procedure iccExceptionHandler.eh_RaiseExceptObjProc( _pexcrecord : PExceptionRecord);
begin
//    writeln( TObject( _pexcrecord.ExceptionInformation[1]).className);
//    writeln( TObject( _pexcrecord.ExceptObject).className);

    // remember exception object if needed
end;

{ iccListEnumerator }

constructor iccList.iccListEnumerator.Create( _List: iccList);
begin
    inherited Create;
    FIndex  := -1;
    FList   := _List;
end;

function iccList.iccListEnumerator.GetCurrent: Pointer;
begin
    Result := FList[ FIndex];
end;

function iccList.iccListEnumerator.MoveNext: Boolean;
begin
    Result := FIndex < FList.Count - 1;
    if Result
        then Inc( FIndex);
end;

{ iccList }

destructor iccList.Destroy;
begin
    Clear;
    inherited;
end;

function iccList.Add( _Item: Pointer): Integer;
begin
    Result := FCount;
    if Result = FCapacity
        then Grow;
    FList^[ Result] := _Item;
    Inc( FCount);
    if _Item <> nil
        then Notify( _Item, lnAdded);
end;

procedure iccList.Clear;
begin
    SetCount(0);
    SetCapacity(0);
end;

procedure iccList.Delete( _Index: Integer);
var Temp : Pointer;
begin
    if ( _Index < 0) or ( _Index >= FCount)
        then Error( @SListIndexError, _Index);
    Temp := Items[ _Index];
    Dec( FCount);
    if _Index < FCount
        then System.Move( FList^[ _Index + 1], FList^[ _Index], ( FCount - _Index) * SizeOf( Pointer));
    if Temp <> nil
        then Notify( Temp, lnDeleted);
end;

class procedure iccList.Error(const Msg: string; _Data: Integer);

  function ReturnAddr: Pointer;
  asm
          MOV     EAX,[EBP+4]
  end;

begin
    raise iccException.Create( pchar( Msg)) at ReturnAddr;
end;

class procedure iccList.Error(_Msg: PResStringRec; _Data: Integer);
begin
    //
end;

procedure iccList.Exchange( _Index1, _Index2: Integer);
var Item: Pointer;
begin
    if ( _Index1 < 0) or ( _Index1 >= FCount)
        then Error( @SListIndexError, _Index1);
    if ( _Index2 < 0) or ( _Index2 >= FCount)
        then Error( @SListIndexError, _Index2);
    Item := FList^[ _Index1];
    FList^[ _Index1] := FList^[ _Index2];
    FList^[ _Index2] := Item;
end;

function iccList.Expand: iccList;
begin
    if FCount = FCapacity
        then Grow;
    Result := Self;
end;

function iccList.First: Pointer;
begin
    Result := Get( 0);
end;

function iccList.Get( _Index: Integer): Pointer;
begin
    if ( _Index < 0) or ( _Index >= FCount)
        then Error( @SListIndexError, _Index);
    Result := FList^[ _Index];
end;

function iccList.GetEnumerator: iccListEnumerator;
begin
    Result := iccListEnumerator.Create( Self);
end;

procedure iccList.Grow;
var Delta: Integer;
begin
    if FCapacity > 64
        then Delta := FCapacity div 4
        else if FCapacity > 8
                 then Delta := 16
                 else Delta := 4;
    SetCapacity( FCapacity + Delta);
end;

function iccList.IndexOf( _Item: Pointer): Integer;
begin
    Result := 0;
    while ( Result < FCount) and ( FList^[ Result] <> _Item) do Inc(Result);
    if Result = FCount
        then Result := -1;
end;

procedure iccList.Insert( _Index: Integer; _Item: Pointer);
begin
    if ( _Index < 0) or ( _Index > FCount)
        then Error( @SListIndexError, _Index);
    if FCount = FCapacity
        then Grow;
    if _Index < FCount
        then System.Move( FList^[ _Index], FList^[ _Index + 1], ( FCount - _Index) * SizeOf( Pointer));
    FList^[ _Index] := _Item;
    Inc( FCount);
    if _Item <> nil
        then Notify( _Item, lnAdded);
end;

function iccList.Last: Pointer;
begin
    Result := Get(FCount - 1);
end;

procedure iccList.Move( _CurIndex, _NewIndex: Integer);
var Item: Pointer;
begin
    if _CurIndex <> _NewIndex
        then begin
                 if ( _NewIndex < 0) or ( _NewIndex >= FCount)
                     then Error( @SListIndexError, _NewIndex);
                 Item := Get( _CurIndex);
                 FList^[ _CurIndex] := nil;
                 Delete( _CurIndex);
                 Insert( _NewIndex, nil);
                 FList^[ _NewIndex] := Item;
             end;
end;

procedure iccList.Put( _Index: Integer; _Item: Pointer);
var Temp: Pointer;
begin
    if ( _Index < 0) or ( _Index >= FCount)
        then Error(@SListIndexError, _Index);
    if _Item <> FList^[ _Index]
        then begin
                 Temp := FList^[ _Index];
                 FList^[ _Index] := _Item;
                 if Temp <> nil
                     then Notify(Temp, lnDeleted);
                 if _Item <> nil
                     then Notify( _Item, lnAdded);
             end;
end;

function iccList.Remove( _Item: Pointer): Integer;
begin
    Result := IndexOf( _Item);
    if Result >= 0
       then Delete( Result);
end;

procedure iccList.Pack;
var PackedCount : Integer;
    StartIndex  : Integer;
    EndIndex    : Integer;
begin
    if FCount = 0 then Exit;

    PackedCount := 0;
    StartIndex  := 0;

    repeat
    // Locate the first/next non-nil element in the list
        while ( FList^[ StartIndex] = nil) and ( StartIndex < FCount) do Inc( StartIndex);

        if StartIndex < FCount // There is nothing more to do
            then begin
                     // Locate the next nil pointer
                     EndIndex := StartIndex;
                     while ( FList^[ EndIndex] <> nil) and ( EndIndex < FCount) do Inc( EndIndex);
                     Dec( EndIndex);

                     // Move this block of non-null items to the index recorded in PackedToCount:
                     // If this is a contiguous non-nil block at the start of the list then
                     // StartIndex and PackedToCount will be equal (and 0) so don't bother with the move.
                     if StartIndex > PackedCount
                         then System.Move( FList^[ StartIndex], FList^[ PackedCount], ( EndIndex - StartIndex + 1) * SizeOf( Pointer));

                     // Set the PackedToCount to reflect the number of items in the list
                     // that have now been packed.
                     Inc( PackedCount, EndIndex - StartIndex + 1);

                     // Reset StartIndex to the element following EndIndex
                     StartIndex := EndIndex + 1;
                 end;
    until StartIndex >= FCount;

    // Set Count so that the 'free' item
    FCount := PackedCount;
end;

procedure iccList.SetCapacity( _NewCapacity: Integer);
begin
    if ( _NewCapacity < FCount) or ( _NewCapacity > MaxListSize)
        then Error( @SListCapacityError, _NewCapacity);
    if _NewCapacity <> FCapacity
        then begin
                 ReallocMem( FList, _NewCapacity * SizeOf( Pointer));
                 FCapacity := _NewCapacity;
             end;
end;

procedure iccList.SetCount( _NewCount: Integer);
var index : Integer;
begin
    if (_NewCount < 0) or (_NewCount > MaxListSize)
        then Error( @SListCountError, _NewCount);
    if _NewCount > FCapacity
        then SetCapacity( _NewCount);
    if _NewCount > FCount
        then FillChar( FList^[ FCount], ( _NewCount - FCount) * SizeOf( Pointer), 0)
        else for index := FCount - 1 downto _NewCount do Delete( index);
    FCount := _NewCount;
end;

procedure QuickSort( SortList: iccList.ictpPointerList; L, R: Integer; SCompare: iccList.ictListSortCompare);
var I, J: Integer;
    P, T: Pointer;
begin
    repeat
        I := L;
        J := R;
        P := SortList^[(L + R) shr 1];
        repeat
            while SCompare( SortList^[I], P) < 0 do Inc( I);
            while SCompare( SortList^[J], P) > 0 do Dec( J);
            if I <= J
                then begin
                         T := SortList^[ I];
                         SortList^[ I] := SortList^[ J];
                         SortList^[ J] := T;
                         Inc( I);
                         Dec( J);
                     end;
        until I > J;
        if L < J
            then QuickSort( SortList, L, J, SCompare);
        L := I;
    until I >= R;
end;

procedure iccList.Sort( _Compare: ictListSortCompare);
begin
    if (FList <> nil) and (Count > 0)
        then QuickSort( FList, 0, Count - 1, _Compare);
end;

function iccList.Extract( _Item: Pointer): Pointer;
var index: Integer;
begin
    Result := nil;
    index := IndexOf( _Item);
    if index >= 0
        then begin
                 Result := _Item;
                 FList^[ index] := nil;
                 Delete( index);
                 Notify( Result, lnExtracted);
             end;
end;

procedure iccList.Notify( _Ptr: Pointer; _Action: ictListNotification);
begin
end;

procedure iccList.Assign( _ListA: iccList; _Operator: ictListAssignOp; _ListB: iccList);
var index : Integer;
    LTemp, LSource: iccList;
begin
    // _ListB given?
    if _ListB <> nil
        then begin
                LSource := _ListB;
                Assign(_ListA);
             end
        else LSource := _ListA;

    // on with the show
    case _Operator of
        // 12345, 346 = 346 : only those in the new list
        laCopy:
            begin
                Clear;
                Capacity := LSource.Capacity;
                for index := 0 to LSource.Count - 1 do
                    Add(LSource[index]);
            end;
        // 12345, 346 = 34 : intersection of the two lists
        laAnd:
            for index := Count - 1 downto 0 do
                if LSource.IndexOf(Items[index]) = -1
                    then Delete(index);
        // 12345, 346 = 123456 : union of the two lists
        laOr:
            for index := 0 to LSource.Count - 1 do
                if IndexOf(LSource[index]) = -1
                    then Add(LSource[index]);
        // 12345, 346 = 1256 : only those not in both lists
        laXor:
            begin
                LTemp := iccList.Create; // Temp holder of 4 byte values
                try
                    LTemp.Capacity := LSource.Count;
                    for index := 0 to LSource.Count - 1 do
                        if IndexOf(LSource[index]) = -1
                            then LTemp.Add(LSource[index]);
                    for index := Count - 1 downto 0 do
                        if LSource.IndexOf(Items[index]) <> -1
                            then Delete(index);
                    index := Count + LTemp.Count;
                    if Capacity < index
                        then Capacity := index;
                    for index := 0 to LTemp.Count - 1 do
                        Add(LTemp[index]);
                finally
                    LTemp.Free;
                end;
            end;
        // 12345, 346 = 125 : only those unique to source
        laSrcUnique:
            for index := Count - 1 downto 0 do
                if LSource.IndexOf(Items[index]) <> -1
                    then Delete(index);
        // 12345, 346 = 6 : only those unique to dest
        laDestUnique:
            begin
                LTemp := iccList.Create;
                try
                   LTemp.Capacity := LSource.Count;
                   for index := LSource.Count - 1 downto 0 do
                       if IndexOf(LSource[index]) = -1
                           then LTemp.Add(LSource[index]);
                   Assign(LTemp);
                finally
                    LTemp.Free;
                end;
            end;
    end;
end;

{ iccxList }

constructor iccxList.Create( _allocpertime : WORD = 32);
begin
    inherited Create;
    FCount         := 0;
    FFragmentDescriptorsLen := 0;

    if _allocpertime <> 0
       then c_AllocPerTime := _allocpertime
       else c_AllocPerTime := 32;
end;

destructor iccxList.Destroy;
begin
    DeallocBlocks;
    inherited;
end;

function iccxList.GetSegmentIndexByIndex( _ndx : Integer) : Integer;
var c,         // current
    l,         // left  border
    r,         // right border
    i1,
    i2 : Integer; // speed up!
begin
//    result := -1;

    l := 0;
    r := FFragmentDescriptorsLen - 1;
    while true do begin
        c := (l + r) div 2;

        i1 := FFragmentDescriptors[c].StartIndex; // speed up!
        i2 := FFragmentDescriptors[c].Count;

        if ( _ndx >= i1) and ( _ndx < i1 + i2)
            then exit( c);

        if _ndx < i1
            then r := c
            else if _ndx >= i1 + i2
                     then l := c + 1;

        if l > r
            then exit( -1); // for overflows
    end;
end;

function iccxList.AllocBlock : pointer;
var sdx : DWORD; // start index;
begin
    if FFragmentDescriptorsLen >= 65535
        then raise iccException.Create( pchar( 'iccxList.AllocBlock() => Block limit exceeded'));

    result := GetMemory( c_AllocPerTime * c_DataSize);
    SetLength( FFragmentDescriptors, FFragmentDescriptorsLen + 1);

    if FFragmentDescriptorsLen = 0
        then sdx := 0
        else sdx := FFragmentDescriptors[FFragmentDescriptorsLen-1].StartIndex + FFragmentDescriptors[FFragmentDescriptorsLen-1].Count; // початковий індекс поперднього + його к-сть + 1

    // просто вносимо данні, не переживаючи за індекси і тому подібне
    FFragmentDescriptors[FFragmentDescriptorsLen].Address    := DWORD( result);
    FFragmentDescriptors[FFragmentDescriptorsLen].StartIndex := sdx;
    FFragmentDescriptors[FFragmentDescriptorsLen].Count      := 0;

    FFragmentDescriptorsLen := FFragmentDescriptorsLen + 1;
end;

function iccxList.DeallocBlock( _ndx : WORD) : boolean;
var ndx : WORD;
begin
    FreeMem( pointer( FFragmentDescriptors[_ndx].Address), c_AllocPerTime * c_DataSize);
    for ndx := _ndx+1 to FFragmentDescriptorsLen - 1 do
        FFragmentDescriptors[ndx-1] := FFragmentDescriptors[ndx];
    FFragmentDescriptorsLen := FFragmentDescriptorsLen - 1;
    SetLength( FFragmentDescriptors, FFragmentDescriptorsLen);
    Result := true;
end;

function iccxList.DeallocBlocks : Boolean;
var ndx : WORD;
begin
    ndx := FFragmentDescriptorsLen;
    while ndx <> 0 do
        begin
            FreeMem( pointer( FFragmentDescriptors[ndx-1].Address), c_AllocPerTime * c_DataSize);
            dec(ndx);
        end;
    FCount                  := 0;
    FFragmentDescriptorsLen := 0;
    SetLength( FFragmentDescriptors, 0);
    Result := true;
end;

function iccxList.Cnt() : Integer;
begin
    Result := FCount;
end;

function iccxList.Add( _dta : DWORD) : boolean;
var tmp : icrpFragmentDescriptor;
begin
    if ( FFragmentDescriptorsLen = 0) or ( FFragmentDescriptors[FFragmentDescriptorsLen-1].Count = c_AllocPerTime)
        then AllocBlock;
    tmp := @FFragmentDescriptors[FFragmentDescriptorsLen-1];

    //PDWORD( pointer( tmp.Address + (FCount - tmp.StartIndex) * c_DataSize))^ := _data;
    PDWORD( pointer( tmp.Address + tmp.Count * c_DataSize))^ := _dta;

    inc( tmp.Count);
    inc( FCount);
    result := true;
end;

function iccxList.Ins( _ndx : Integer; _data : DWORD) : boolean;
var tmp,
    new : icrpFragmentDescriptor;
    ndx,
    lop : DWORD;
    aba : pointer;
begin
    if FCount = 0
        then Exit( add( _data));


    if ( _ndx < 0) or ( _ndx < FCount)
        then begin
                 ndx := GetSegmentIndexByIndex( _ndx);
                 tmp := @FFragmentDescriptors[ndx];

                 // localize _ndx
                 _ndx := _ndx - tmp.StartIndex;

                 if tmp.Count = c_AllocPerTime
                     then begin // not enought space, need to allocate new
                              aba := AllocBlock; // <- important!

                              // shifting values and indexes
                              for lop := FFragmentDescriptorsLen - 1 downto ndx + 1 do
                                  begin
                                      FFragmentDescriptors[lop] := FFragmentDescriptors[lop-1];
                                      with FFragmentDescriptors[lop] do StartIndex := StartIndex + 1;
                                  end;

                              // validating
                              tmp            := @FFragmentDescriptors[ndx];
                              tmp.Count      := _ndx + 1;

                              new            := @FFragmentDescriptors[ndx+1];
                              new.Count      := c_AllocPerTime - _ndx;
                              new.StartIndex := tmp.StartIndex + tmp.Count;
                              new.Address    := DWORD( aba); // <- fucking place I forgot (all the night long wasted to find the bug)

                              // split
                              for lop := 0 to new.Count - 1 do
                                  PDWORD( pointer( new.Address + lop * c_DataSize))^ := PDWORD( pointer( tmp.Address + (lop+DWORD( _ndx)) * c_DataSize))^;

                              // insert
                              PDWORD( pointer( tmp.Address + DWORD( _ndx) * c_DataSize))^ := _data;
                          end
                     else begin // add new element to existing fragment
                              // shift indexes
                              for ndx := ndx + 1 to FFragmentDescriptorsLen - 1 do
                                  with FFragmentDescriptors[ndx] do StartIndex := StartIndex + 1;

                              // shift values
                              for ndx := tmp.Count downto _ndx + 1 do
                                  PDWORD( pointer( tmp.Address + ndx * c_DataSize))^ := PDWORD( pointer( tmp.Address + (ndx-1) * c_DataSize))^;

                              // insert needed value
                              PDWORD( pointer( tmp.Address + DWORD( _ndx) * c_DataSize))^ := _data;

                              inc( tmp.Count);
                          end;

                 inc( FCount);
                 result := true;
             end
        else raise iccException.Create( pchar( 'iccxList.Ins( ' + IntToStr( _ndx) + ') => Index is out of bounds'));
end;

function iccxList.Del( _ndx : Integer) : boolean;
begin
    DelRes( _ndx);
    result := true;
end;

function iccxList.DelRes( _ndx : Integer) : DWORD;
var tmp : icrpFragmentDescriptor;
    ndx : Integer;
    i   : DWORD;
begin
    //result := 0;
    if ( _ndx < 0) or ( _ndx < FCount)
        then begin
                 ndx          := GetSegmentIndexByIndex( _ndx);
                 tmp          := @FFragmentDescriptors[ndx];

                 result := PDWORD( pointer( tmp.Address + DWORD( _ndx - tmp.StartIndex) * c_DataSize))^;

                 dec( tmp.Count);
                 dec( FCount);

                 for i := _ndx - tmp.StartIndex to c_AllocPerTime - 1 do
                     PDWORD( tmp.Address + i*c_DataSize)^ := PDWORD(tmp.Address + (i+1)*c_DataSize)^;

                 for i := ndx + 1 to FFragmentDescriptorsLen - 1 do
                     FFragmentDescriptors[i].StartIndex := FFragmentDescriptors[i].StartIndex - 1;

                 if tmp.Count = 0
                     then DeallocBlock( ndx);
             end
        else raise iccException.Create( pchar( 'iccxList.Del( ' + IntToStr( _ndx) + ') => Index is out of bounds'));
end;

function iccxList.Rem( _dta : DWORD) : Boolean;
var ndx : integer;
begin
    ndx := GetNdx( _dta);
    if ndx = -1
        then exit( false);

    result := Del( ndx);
end;

function iccxList.Get( _ndx : Integer) : DWORD;
var tmp : icrpFragmentDescriptor;
//    ndx : Integer;
begin
    if ( _ndx >= 0) and ( _ndx < FCount)
        then begin
//                 ndx    := GetSegmentIndexByIndex( _ndx);
//                 tmp    := @FFragmentDescriptors[ndx];
//                 result := PDWORD( pointer( tmp.Address + (_ndx - tmp.StartIndex) * c_DataSize))^

                 tmp := @FFragmentDescriptors[GetSegmentIndexByIndex( _ndx)];
                 result := PDWORD( pointer( tmp.Address + DWORD( _ndx - tmp.StartIndex) * c_DataSize))^
             end
        else raise iccException.Create( pchar( 'iccxList.Get( ' + IntToStr( _ndx) + ') => Index is out of bounds'));
end;

function iccxList.GetNdx( _dta : DWORD) : Integer;
var ndx : integer;
begin
    result := -1;
    if FCount = 0
        then exit();

    for ndx := 0 to FCount - 1 do
        if Get( ndx) = _dta
            then exit( ndx);
end;

function iccxList.Define( _ndx : Integer; _val : DWORD) : Boolean; // define
var tmp : icrpFragmentDescriptor;
//    ndx : Integer;
begin
    if _ndx < FCount
        then begin
//                 ndx    := GetSegmentIndexByIndex( _ndx);
//                 tmp    := @FFragmentDescriptors[ndx];
//                 PDWORD( pointer( tmp.Address + (_ndx - tmp.StartIndex) * c_DataSize))^ := _val;

                 tmp    := @FFragmentDescriptors[GetSegmentIndexByIndex( _ndx)];
                 PDWORD( pointer( tmp.Address + DWORD(_ndx - tmp.StartIndex) * c_DataSize))^ := _val;

                 result := true;
             end
        else raise iccException.Create( pchar( 'iccxList.Def( ' + IntToStr( _ndx) + ') => Index is out of bounds'));
end;

function iccxList.Clr() : Boolean;
begin
    Result := DeallocBlocks;
end;

procedure iccxList.___prop_setItem( _ndx : Integer; _val : DWORD);
begin
    Define( _ndx, _val);
end;

{ iccxList<_type> }

constructor iccxList<_type>.Create( _allocpertime : WORD = 32);
begin
    if sizeof( _type) > 4
        then raise iccException.Create( 'iccxList<_type>.Create() -> _type size bigger that 4 bytes. Use <= 4.');

    FList := iccxList.Create( _allocpertime);
end;

destructor iccxList<_type>.Destroy;
begin
    FList.Destroy();
    inherited;
end;

function iccxList<_type>.Cnt() : Integer;
begin
    result := FList.Cnt();
end;

function iccxList<_type>.Add( _dta : _type) : Boolean;
begin
    result := FList.Add( DWORD( (@_dta)^));
end;

function iccxList<_type>.Ins( _ndx : DWORD; _dta : _type) : Boolean;
begin
    result := FList.Ins( _ndx, DWORD( (@_dta)^  ));
end;

function iccxList<_type>.Del( _ndx : Integer) : Boolean;
begin
    result := FList.Del( _ndx);
end;

function iccxList<_type>.DelRes( _ndx : Integer) : _type;
begin
    PDWORD( @result)^ := FList.DelRes( _ndx);
end;

function iccxList<_type>.Rem( _dta : _type) : Boolean;
var ndx : integer;
begin
    ndx := GetNdx( _dta);
    if ndx = -1
        then exit( false);

    result := Del( ndx);
end;

function iccxList<_type>.Get( _ndx : Integer) : _type;
begin
    PDWORD( @result)^ := FList.Get( _ndx);
end;

function iccxList<_type>.GetNdx( _dta : _type) : Integer;
begin
    result := FList.GetNdx( PDWORD(@_dta)^ );
end;

function iccxList<_type>.Define( _ndx : Integer; _val : _type) : Boolean;
begin
    if ( _ndx < 0) or ( _ndx >= FList.Cnt())
        then exit( false);

    FList[_ndx] := PDWORD( @_val)^;
    result := true;
end;

function iccxList<_type>.Define( _dta : _type; _val : _type) : Boolean;
begin
    result := Define( GetNdx( _dta), _val);
end;

function iccxList<_type>.Clr() : Boolean;
begin
    result := FList.Clr();
end;

procedure iccxList<_type>.___prop_setItem( _ndx : Integer; _val : _type);
begin
    Define( _ndx, _val);
end;

{ iccxList_append<_type> }

constructor iccxList_append<_type>.Create(_AmountPerAlloc: Word = 32);
begin
    FAmountPerAlloc := _AmountPerAlloc;
    FDataSizeAlloc  := _AmountPerAlloc * SizeOf( _type);
    FFragmentsCnt   := 0;
    FOffset         := 0;
    FCount          := 0;
end;

destructor iccxList_append<_type>.Destroy;
begin
    while FFragmentsCnt <> 0 do
        begin
            dec( FFragmentsCnt);
            FreeMem( FFragmentsArr[FFragmentsCnt]);
        end;

    inherited;
end;

function iccxList_append<_type>.cnt() : Cardinal;
begin
    result := FCount;
end;

function iccxList_append<_type>.add( _val : _type) : Boolean;
begin
    FOffset := FOffset and not FAmountPerAlloc;

    if FOffset = 0
        then begin
                 FFragmentsArr[FFragmentsCnt] := GetMemory( FDataSizeAlloc);
                 Inc( FFragmentsCnt);
             end;

    FFragmentsArr[FFragmentsCnt-1][FOffset] := _val;
    inc( FOffset);
    inc( FCount);
end;

function iccxList_append<_type>.get( _ndx: Cardinal): _type;
var tmp : Word;
begin
    tmp    := _ndx div FAmountPerAlloc;
    _ndx   := _ndx - tmp * FAmountPerAlloc;
    result := FFragmentsArr[tmp][_ndx];
    // too slow
//    result := FFragmentsArr[_ndx div FAmountPerAlloc][_ndx mod FAmountPerAlloc];
end;

function iccxList_append<_type>.get_safe( _ndx : Cardinal) : _type;
var tmp : Word;
begin
    if _ndx >= FCount
        then raise Exception.Create( 'iccxLis_append<_type>.get() -> Out of bounds');

    tmp    := _ndx div FAmountPerAlloc;
    _ndx   := _ndx - tmp * FAmountPerAlloc;
    result := FFragmentsArr[tmp][_ndx];
    // too slow
//    result := FFragmentsArr[_ndx div FAmountPerAlloc][_ndx mod FAmountPerAlloc];
end;

procedure iccxList_append<_type>.asg( _ndx : Cardinal; _val : _type);
var tmp : Word;
begin
    tmp    := _ndx div FAmountPerAlloc;
    _ndx   := _ndx - tmp * FAmountPerAlloc;
    FFragmentsArr[tmp][_ndx] := _val;
    // too slow
//    FFragmentsArr[_ndx div FAmountPerAlloc][_ndx mod FAmountPerAlloc] := _val;
end;

procedure iccxList_append<_type>.asg_safe( _ndx : Cardinal; _val : _type);
var tmp : Word;
begin
    if _ndx >= FCount
        then raise Exception.Create( 'iccxLis_append<_type>.get() -> Out of bounds');

    tmp    := _ndx div FAmountPerAlloc;
    _ndx   := _ndx - tmp * FAmountPerAlloc;
    FFragmentsArr[tmp][_ndx] := _val;
    // too slow
//    FFragmentsArr[_ndx div FAmountPerAlloc][_ndx mod FAmountPerAlloc] := _val;
end;

{ iccTypedList<_type> }

function iccTypedList<_type>.translateTO( _tp : _type) : DWORD;
var ptr : ptr_type;
begin
    ptr := GetMemory( sizeof( _type));      // ALLOC MEM! do not forget to dealloc
    CopyMemory( ptr, @_tp, sizeof( _type));
    result := DWORD( ptr);
end;

function iccTypedList<_type>.translateFROM( _dw : DWORD) : _type;
begin
    result := ptr_type( _dw)^;
end;

constructor iccTypedList<_type>.Create;
begin
    FList := iccxList.Create();
end;

destructor iccTypedList<_type>.Destroy;
begin
    Clr;
    FList.Destroy;
    inherited;
end;

function iccTypedList<_type>.cnt: DWORD;
begin
    result := FList.Cnt;
end;

function iccTypedList<_type>.get(_ndx: DWORD): _type;
begin
    result := translateFROM( FList[_ndx]);
end;

function iccTypedList<_type>.add(_dta: _type): Boolean;
begin
//    if ptr_type( pointer( @_dta)^) = nil
//        then exit( false);
    if ptr_type( @_dta) = nil
        then exit( false);

    result := FList.Add( translateTO( _dta));

    if result
        then if pTypeInfo( TypeInfo( _type)).Kind = tkInterface
                 then IInterface( _dta)._AddRef;
end;

function iccTypedList<_type>.Del( _ndx : DWORD) : Boolean;
var ptr : ptr_type;
begin
    ptr := ptr_type( FList[_ndx]);
    result := FList.Del( _ndx);

    if result
        then begin // _release and free mem
                 if pTypeInfo( TypeInfo( _type)).Kind = tkInterface
                     then IInterface( ptr^)._Release;

                 dispose( ptr);
             end;
end;

function iccTypedList<_type>.Clr() : Boolean;
var ndx : integer;
begin
    while FList.Cnt <> 0 do
        if not Del( 0)
            then raise iccException.Create( 'iccTypedList<_type>.Clr() -> Delete loop returned False.');

    result := FList.Clr;
end;

{ iccAssocs }

constructor iccAssocList<_type>.Create( _name : String);
begin
    FName := _name;
    FList := iccTypedList<_type>.Create();
end;

destructor iccAssocList<_type>.Destroy();
begin
    FList.Destroy;
    inherited;
end;

function iccAssocs<_type>.getList( _name : String) : iccAssocList<_type>;
var ndx : integer;
begin
    result := nil;
    ndx := getListIndex( _name);
    if ndx <> -1
        then result := FAssocLists[ndx];
end;

function iccAssocs<_type>.getListIndex( _name : String) : Integer;
var tmpCnt : integer;
begin
    tmpCnt := FAssocLists.Cnt;
    result := 0;
    while result < tmpCnt do
        begin
            if FAssocLists[result].FName = _name
                then exit;
            result := result + 1;
        end;

    if result = tmpCnt
        then exit( -1);
end;

constructor iccAssocs<_type>.Create();
begin
     FAssocLists := iccxList<iccAssocList<_type>>.Create();
end;

destructor iccAssocs<_type>.Destroy();
var ndx : integer;
begin
    // clear all
    for ndx := FAssocLists.Cnt - 1 downto 0 do
        assocClr( FAssocLists[ndx].FName);


    FAssocLists.Destroy();
    inherited;
end;

function iccAssocs<_type>.assocGet( _name : String) : iccTypedList<_type>;
var ndx : integer;
    tmp : integer;
    asc : iccAssocList<_type>;
begin
    tmp := -1;

    for ndx := 0 to FAssocLists.Cnt - 1 do
        if FAssocLists[ndx].FName = _name
            then begin
                     tmp := ndx;
                     break;
                 end;

    if tmp = - 1
        then exit( nil);

    result := iccTypedList<_type>.Create();
    asc    := FAssocLists[tmp];


    for ndx := 0 to asc.FList.Cnt - 1 do
        result.Add( asc.FList.Get(ndx));
end;

function iccAssocs<_type>.assocAdd( _name : String; _val : _type) : Boolean;
var tmp : iccAssocList<_type>;
begin
    tmp := getList( _name);
    if tmp = nil
        then begin
                 tmp := iccAssocList<_type>.Create( _name);
                 FAssocLists.Add( tmp);
             end;

    result := tmp.FList.Add( _val);
end;

function iccAssocs<_type>.assocRem( _name : String; _val : _type) : Boolean;
var ndx : integer;
    tmp : iccAssocList<_type>;
begin
    result := false;

    tmp := getList( _name);
    if tmp = nil
        then exit;

//    for ndx := 0 to tmp.FList.Cnt - 1 do
//        if tmp.FList.Get(ndx) = _val
//            then begin
//                     tmp.FList.Del( ndx);
//                     if tmp.FList.Cnt = 0
//                         then begin
//                                  tmp.Destroy;
//                                  FAssocLists.Rem( tmp);
//                              end;
//                     exit( true);
//                 end;
    result := false;
end;

function iccAssocs<_type>.assocClr( _name : String) : Boolean;
var ndx : integer;
begin
    ndx := getListIndex( _name);

    if ndx = -1
        then exit( false);

    FAssocLists[ndx].Destroy();
    result := FAssocLists.Del( ndx);
end;

{ iccEventDispatcher }

constructor iccEventDispatcher<_function>.Create( _forEachProc : ict_ed_forEachProc);
begin
    if ict_ed_forEachProc( _forEachProc) = nil
        then raise iccException.Create( 'iccEventDispatcher<_function>.Create() -> not need to create this class with _forEachProc = nil.');

    FForEachProc := _forEachProc;
    FAssocs := iccAssocs<_function>.Create();
end;

destructor iccEventDispatcher<_function>.Destroy;
begin
    FAssocs.Destroy();
    inherited;
end;

function iccEventDispatcher<_function>.addEventListener( _name : String; _func : _function) : Boolean;
begin
    if edsLocked in FState
        then exit( false);

    result := FAssocs.assocAdd( _name, _func);
end;

function iccEventDispatcher<_function>.remEventListener( _name : String; _func : _function) : Boolean;
begin
    if edsLocked in FState
        then exit( false);

    result := FAssocs.assocRem( _name, _func);
end;

function iccEventDispatcher<_function>.dispatchEvent( _name : String; _params : array of const) : Boolean;
var lst : iccTypedList<_function>;
    ndx : integer;
    abortDispatching : Boolean;
begin
    result := false;
    //
    if edsLocked in FState
        then exit;
    Include( FState, edsLocked);
    //
    lst := FAssocs.assocGet( _name);
    if lst = nil
        then begin
                 exclude( FState, edsLocked);
                 exit;
             end;

    abortDispatching := false;

    for ndx := 0 to lst.Cnt - 1 do
        if not abortDispatching
            then try
                     FForEachProc( lst.get(ndx), _params);
                 except
                     if Assigned( FForEach_onExceptionProc)
                         then FForEach_onExceptionProc( _name, lst.get(ndx), abortDispatching);
                 end;

    lst.Destroy();
    //
    result := true;
    //
    exclude( FState, edsLocked);
end;

function iccEventDispatcher<_function>.clrEventListeners( _name : String) : Boolean;
begin
    result := false;
end;

function iccEventDispatcher<_function>.cpyEventListeners( _name : String; _destED : iccEventDispatcher<_function>) : Boolean;
var lst : iccTypedList<_function>;
    ndx : integer;
begin
    result := false;
    if _destED = nil
        then exit;


    if edsLocked in FState
        then exit;
    Include( FState, edsLocked);
    //
    lst := FAssocs.assocGet( _name);
    if lst = nil
        then begin
                 exclude( FState, edsLocked);
                 exit( true); // exit if nothing to copy and return TRUE, we did that ought to be done
             end;


    for ndx := 0 to lst.Cnt - 1 do
        _destED.addEventListener( _name, lst.get(ndx));


    lst.Destroy();
    //
    result := true;
    //
    Exclude( FState, edsLocked);
end;

{ iccComponent }

constructor iccComponent.Create( _Owner : iccComponent);
begin
    inherited Create;
    if _Owner <> nil
        then if     ( _Owner is iccComponent)
                and ( _Owner <> Self)
                 then begin
                          FOwner := _Owner;
                          FOwner.FComponents.Add( Self);
                      end
                 else raise iccException.Create( 'iccComponent.Create() -> _Owner must not be nil or self. _Owner must be iccComponent.');

    FComponents := iccComponents.Create;
end;

destructor iccComponent.Destroy;
begin
    DestroyComponents;
    FComponents.Free;

    if FOwner <> nil
        then FOwner.FComponents.Remove( Self);
    inherited;
end;

procedure iccComponent.DestroyComponents;
begin
     if FComponents = nil
         then Exit;

     if FComponents.Count > 0
         then while FComponents.Count <> 0 do
                  begin
                      iccComponent( FComponents.Last).Destroy;
                  end;
end;

procedure iccComponent.Notify( _Sender : iccComponent; _Notify : ictpComponentNotify);
begin
    // abstract
end;

procedure iccComponent.___prop_SetName(_value: ictComponentName);
begin
    if _Value = FName then EXIT;


    if Owner <> nil
        then if Owner.ValidateName( _Value)
                 then FName := _Value
                 else raise iccException.Create( pchar( 'iccComponent => Component name "' + _Value + '" already exist.'))
        else FName := _Value;
end;

function iccComponent.___prop_GetComponent(_index: Integer): iccComponent;
begin
    Result := nil;
    if ( _index >= 0 ) and ( _index < FComponents.Count)
        then Result := FComponents[ _index];
end;

function iccComponent.___prop_GetComponentsCount: Integer;
begin
    Result := FComponents.Count;
end;

function iccComponent.GetComponent( _Name : ictComponentName) : iccComponent;
var index : Integer;
begin
    for index := 0 to FComponents.Count -1 do
        begin
            Result := iccComponent( FComponents[ index]);
            if Result.Name = _Name
                then Exit;
        end;
    Result := nil;
end;

function iccComponent.ValidateName(_Name: ictComponentName): Boolean;
var index : Integer;
begin
    // True  - can be changed
    // False - forbidden
    if FComponents = nil
        then iccException.Create( pchar( 'iccList = NIL'));


    Result := True;    
    for index := 0 to FComponents.Count -1 do
        if UpperCase( iccComponent( FComponents[ index]).Name) = UpperCase( _Name)
            then begin
                     Result := False;
                     BREAK;
                 end;
end;

{ iccEventNotifier }

procedure iccEventNotifier.iccEventObject.CheckAvailability;
begin
    if eosDestroying in FState
        then raise iccException.Create( 'Object has just entered Destroying state.');
    if eosReleased in FState
        then raise iccException.Create( 'Inteface link is obselete. Linked object does not exist.');
end;

procedure iccEventNotifier.iccEventObject.Lock;
begin
    Include( FState, eosLocked);
end;

procedure iccEventNotifier.iccEventObject.Unlock;
begin
    Exclude( FState, eosLocked);
end;

constructor iccEventNotifier.iccEventObject.Create;
begin
    inherited;
    AutoDestroy := False; // do not allow outside deleting

    FState  := [];

    FProc_Add := safe_Add;
    FProc_Del := safe_Del;
    FProc_Get := safe_Get;

    FList   := iccxList.Create( 16);
end;

destructor iccEventNotifier.iccEventObject.Destroy;
begin
    FState  := [eosDestroying];

    Clr;
    FList.Destroy;
    inherited;
end;

procedure iccEventNotifier.iccEventObject.Release;
begin
    Include( FState, eosReleased);
end;

function  iccEventNotifier.iccEventObject.getReceiver : HWND;
begin
    Result := FReceiver;
end;

procedure iccEventNotifier.iccEventObject.setReceiver( _hwnd : HWND);
begin
    FReceiver := _hwnd;
end;

function iccEventNotifier.iccEventObject.AddEvent( _param : DWORD; _ms : DWORD) : Boolean;
begin
    if DWORD( _param) = 1
        then raise iccException.Create( 'What the fuck?');

    Result := Add( _param, _ms);
end;

function iccEventNotifier.iccEventObject.ClrQueue() : Boolean;
begin
    Result := Clr;
end;

function iccEventNotifier.iccEventObject.Cnt() : DWORD;
begin
    Result := FList.Count;
end;

function  iccEventNotifier.iccEventObject._Add( _param : DWORD; _ms : DWORD) : Boolean;
var tmp : ictpItem;
begin
    new( tmp);
    tmp.param := _param;
    tmp.ms    := _ms;

    result := FList.Add( DWORD( tmp) );
end;

function iccEventNotifier.iccEventObject._Del( _ndx : DWORD) : Boolean;
var tmp : ictpItem;
begin
    tmp := pointer( FList[_ndx]);
    Dispose( tmp);

    result := FList.Del( _ndx);
end;

function iccEventNotifier.iccEventObject._Get( _ndx : DWORD) : DWORD;
begin
    Result := FList[_ndx];
end;

function iccEventNotifier.iccEventObject.safe_Add( _param : DWORD; _ms : DWORD) : Boolean;
var tmp : ictpItem;
begin
    if not ( eosLocked in FState)
        then raise iccException.Create( 'EventObject is not locked.');


    new( tmp);
    tmp.param := _param;
    tmp.ms    := _ms;

    result := FList.Add( DWORD( tmp) );
end;

function iccEventNotifier.iccEventObject.safe_Del( _ndx : DWORD) : Boolean;
var tmp : ictpItem;
begin
    if not ( eosLocked in FState)
        then raise iccException.Create( 'EventObject is not locked.');


    tmp := pointer( FList[_ndx]);
    Dispose( tmp);

    result := FList.Del( _ndx);
end;

function iccEventNotifier.iccEventObject.safe_Get( _ndx : DWORD) : DWORD;
begin
    if not ( eosLocked in FState)
        then raise iccException.Create( 'EventObject is not locked.');

    Result := FList[_ndx];
end;

function  iccEventNotifier.iccEventObject.Clr() : Boolean;
var ndx : Integer;
begin
    if eosLocked in FState
        then begin
                 writeln( 'WAITING!!!');

                 ndx := 0;
                 while (eosLocked in FState) or (ndx <> 100) do
                     begin
                         sleep( 10); //raise iccException.Create('locked');
                         inc( ndx);
                     end;

                 writeln( 'END WAITING...');

                 if (ndx = 100) and ( eosLocked in FState) // recheck
                      then begin
                               writeln( 'wait abandon');
                               exit( false); // do not perform any Clr
                           end;
        end;

    Include( FState, eosLocked);
    for ndx := FList.Count - 1 downto 0 do
        _Del( ndx);

    result := FList.Clr;
    Exclude( FState, eosLocked);
end;

{ iccEventNotifier.iccEventObjectManager }

constructor iccEventNotifier.iccEventObjectManager.Create;
begin
    inherited;
    FList     := iccxList.Create( 8);
end;

destructor iccEventNotifier.iccEventObjectManager.Destroy;
begin
    Clr;
    FList.Destroy;
    inherited;
end;

function iccEventNotifier.iccEventObjectManager.Cnt() : DWORD;
begin
    result := FList.Count;
end;

function iccEventNotifier.iccEventObjectManager.Add() : iccEventObject;
begin
    result := iccEventObject.Create;
    FList.Add( DWORD(result) );
end;

function iccEventNotifier.iccEventObjectManager.Del( _ndx : DWORD) : boolean;
var tmp : iccEventObject;
begin
    tmp := iccEventObject( FList[_ndx]);
    result := Flist.Del( _ndx);
    tmp.Destroy;
end;

function iccEventNotifier.iccEventObjectManager.Del( _eobj : iccEventObject) : boolean;
var ndx : Integer;
begin
    result := false;
    for ndx := 0 to FList.Count - 1 do
        if _eobj = tobject( flist[ndx])
            then exit( Del( ndx));
end;

function iccEventNotifier.iccEventObjectManager.Get( _ndx : DWORD) : iccEventObject;
begin
    result := iccEventObject( FList[_ndx] );
end;

function iccEventNotifier.iccEventObjectManager.Clr() : Boolean;
var ndx : Integer;
begin
    for ndx := 0 to FList.Count - 1 do
        iccEventObject( FList[ndx] ).Destroy;

    result := FList.Clr;
end;

{ iccEventNotifier.iccThread }

procedure iccEventNotifier.iccThreadWrapper.ThreadMessageProcessor( var _Msg : TMessage);
begin
    Dispatch( _Msg);
end;

procedure iccEventNotifier.iccThreadWrapper.___event_onTimer( _Sender : iccObject);
type
    tmprec =
        packed record
            ebjreceiver : THANDLE;
            ebjaddr     : DWORD;
            param       : DWORD;
        end;

var ndx : Integer;
    lop : Integer;
    ebj : iccEventObject;
    tmp : iccEventObject.ictpItem;

    lst : iccList;
    tsl : ^tmprec;

    processed : WORD;
begin
    FCounter := GetTickCount - FCounter; // time from the last timer proc


    try


    if FEOMgr.Cnt = 0
        then exit; // do finally



    ndx := 0;

    while ndx < Integer( FEOMgr.Cnt) do
        begin
            ebj := FEOMgr[ndx];
            if eosLocked in ebj.State // if object is locked, let it be locked and not touched
                then begin
                         ndx := ndx + 1; // next
                         Continue;
                     end;

            // create lst
            lst := iccList.Create;
            //

            lop := 0;
            processed := 0;
            while lop <= Integer( ebj.Cnt - 1) do
                begin
                    if processed = 1000
                        then BREAK; // 1000 item at cycle

                    if eosReleased in ebj.State
                        then BREAK; // released? - fuck off!

                    tmp := pointer( ebj._Get(lop));
                    if tmp.ms > 0
                        then tmp.ms := DWORD( tmp.ms) - FCounter;

                    if tmp.ms <= 0
                        then begin // notify and del
                                 if eosLocked in ebj.State
                                     then raise iccException.Create( 'Це бидло вийожується ще!!!');

                                 // alloc
                                 tsl := GetMemory( sizeof( tmprec));
                                 tsl.ebjreceiver := ebj.FReceiver;
                                 tsl.ebjaddr     := DWORD( ebj);
                                 tsl.param       := tmp.param;
                                 // add to defer list
                                 lst.Add( tsl);


                                 // del record from queue
                                 //ebj._Del( lop);
                                 ebj._Del( 0);
                             end
                        else lop := lop + 1;


                    processed := processed + 1;
                end;

            // so now we can post messages
            for lop := 0 to lst.Count - 1 do
                begin
                    // post
                    with tmprec( lst[lop]^) do
                    if not PostMessage( ebjreceiver,
                                        c_EventNotifierMsg,
                                        ebjaddr,
                                        param
                                      )
                        then raise iccException.Create( 'PostMsg failed.');
                    // free
                    FreeMem( lst[lop]);
                end;

            // destroy list
            lst.Destroy;
            //


            if eosReleased in ebj.State
                then begin
                         FEOMgr.Del( ndx);
                         Continue; // continue processing on the same ndx
                      end;

            // inc index
            inc( ndx);
        end;


    //
    finally
        FCounter := GetTickCount; // set up new value for FCounter
    end;
end;

procedure iccEventNotifier.iccThreadWrapper.Execute;
var msg : tagMSG;
begin
    FHWND := AllocateHWnd( ThreadMessageProcessor);
    //
    FEOMgr := iccEventObjectManager.Create;
    //
    FTimer          := iccTimer.Create( nil);
    FTimer.Interval := 1;
    FTimer.OnTimer  := ___event_onTimer;
    FTimer.Enabled  := True;

    FCounter        := GetTickCount; // initial counter state

    // unlock ///////////////////////////////////////////////////
    SetEvent( FParent.FThreadLock); // all needed vars were initialized, so tell the parent thread that we can proceed
    /////////////////////////////////////////////////////////////
    while GetMessage( msg, 0, 0, 0) do
        begin
            {
            if msg.message = WM_TIMER                           // reduce delta cycles from 7kk to 5kk
                then if FEOMgr.Cnt = 0                          //
                         then begin                             //
                                  FCounter := GetTickCount();   //
                                  Continue;                     //
                              end;                              //
            }

            TranslateMessage( msg);

            if ( Terminated) and ( msg.message = 123456)
                then BREAK;

            DispatchMessage( msg);
        end;
    /////////////////////////////////////////////////////////////

    FTimer.Destroy;
    //
    FEOMgr.Destroy;
    //
    DeallocateHWnd( FHWND);



    // unlock ///////////////////////////////////////////////////
    SetEvent( FParent.FThreadLock); // all need vars were freed, so tell the parent thread that we can proceed
    /////////////////////////////////////////////////////////////
end;

procedure iccEventNotifier.iccThreadWrapper.setParent( _parent : iccEventNotifier);
begin
    FParent := _parent;
end;

function iccEventNotifier.iccThreadWrapper.RegisterEventObject : iciEventObject;
begin
    Result := FEOMgr.Add;
    Result._AddRef;
end;

function iccEventNotifier.iccThreadWrapper.UnregisterEventObject( _eventObject : iciEventObject) : Boolean;
begin
    iccEventObject( _eventObject).Release;

    result := True;
end;

{ iccEventNotifier }

constructor iccEventNotifier.Create;
begin
    inherited;

    // ініціалізація івента, який в свою чергу є Lock між потоками
    FThreadLock := CreateEvent( nil, true, false, c_EventNotifierThreadLock);
    //


    // створення потоку і запуск
    FThread                 := iccThreadWrapper.Create( true);
    FThread.setParent( Self);
    FThread.Start;
    //


    // чекаємо, поки дочерний поток сам скаже, шо він стартанув. якшо таймаут - пшов на* :)
    if WaitForSingleObject( FThreadLock, 5000) <> WAIT_OBJECT_0
        then raise iccException.Create( 'iccEventNotifier.Create() -> Thread initialization took too long to wait');

    // лочім знову, бо цей лок використовується також для завершення потоку
    ResetEvent( FThreadLock);
end;

destructor iccEventNotifier.Destroy;
begin
    FThread.Terminate;
    PostMessage( FThread.WndHandle, 123456, 0, 0);

    // Wait for terminating
    if WaitForSingleObject( FThreadLock, 5000) <> WAIT_OBJECT_0
        then TerminateThread( FThread.Handle, 0);
        //raise iccException.Create( 'iccEventNotifier.Destroy() -> Thread termination took too long to wait');

    // закриваєм лок
    CloseHandle( FThreadLock);

    // убиваєм поток
    FThread.Destroy;

    inherited;
end;

function iccEventNotifier.RegisterEventObject : iciEventObject;
begin
    result := FThread.RegisterEventObject;
end;

function iccEventNotifier.UnregisterEventObject( _eventObject : iciEventObject) : Boolean;
begin
    result := FThread.UnregisterEventObject( _eventObject);
end;

{ Timer }

constructor iccTimer.Create( _Owner : iccComponent);
begin
    inherited;
    FID       := 0;
    FOnTimer  := nil;
    FInterval := 1000;

    FEnabled  := False;

    FMethodPTR := MakeObjectInstance( TimerProc);
end;
destructor iccTimer.Destroy;
begin
    FEnabled := False;
    Update;

    FreeObjectInstance( FMethodPTR);
    inherited;
end;

procedure iccTimer.TimerProc( var _MSG : TMessage);
begin
    if Assigned( FOnTimer)
        then FOnTimer( Self);
    if Assigned( FOnTimerExternal)
        then FOnTimerExternal( Self);
    if Assigned( FOnTimerReference)
        then FOnTimerReference( Self);
end;

procedure iccTimer.___prop_SetEnabled ( _value : Boolean);
begin
    if _value = FEnabled
        then EXIT;

    FEnabled := _value;
    Update;
end;

procedure iccTimer.___prop_SetInterval( _value : WORD);
begin
    if _value = FInterval
        then EXIT;

    FInterval := _value;
    Update;    
end;

procedure iccTimer.___prop_SetOnTimer ( _value : ictTimerEvent);
begin
    FOnTimer := _value;
    Update;    
end;

procedure iccTimer.___prop_SetOnTimerExternal(_value: ictTimerEventExternal);
begin
    FOnTimerExternal := _value;
    Update;
end;

{$IFDEF VER210}
procedure iccTimer.___prop_SetOnTimerReference(_value: iccTimer.ictTimerEventReference);
begin
    FOnTimerReference := _value;
    Update;
end;
{$ENDIF}

procedure iccTimer.Update;
begin
    KillTimer( 0, FID);

    if not Enabled
        then EXIT;
    if Interval < 1
        then FInterval := 1;


    FID := SetTimer( 0, 0, FInterval, FMethodPTR);
    if FID = 0
        then iccException.Create( 'Not enough timers available');
end;


{ iccTimeout }

constructor iccTimeout.iccRecord.Create( _id : DWORD; _pr : TProc);
begin
    id := _id;
    pr := _pr;
end;

class procedure iccTimeout.___event( _hwnd : DWORD; _msg : DWORD; _id : DWORD; _getTickCount : DWORD);
begin
    unset( _id, true);
end;

class function iccTimeout.list_Locate( _id : DWORD) : Integer;
var ndx : integer;
begin
    result := -1;
    for ndx := 0 to flist.Count - 1 do
        if flist[ndx].id = _id
             then exit( ndx);
end;

class constructor iccTimeout.Create();
begin
    FList := iccxList<iccRecord>.Create();
end;

class destructor iccTimeout.ClearMem;
var ndx : integer;
    rec : iccRecord;
begin
    if FList = nil
        then exit;

    for ndx := 0 to FList.Count - 1 do
        begin
            rec := FList[ndx];
            KillTimer( 0, rec.id); // dont forget to kill all remaing timers
            rec.Destroy();
        end;

    FList.Destroy();
end;

class function iccTimeout.set__( _delay : Integer; _proc : TProc) : DWORD;
begin
    result := setTimer( 0, 0, _delay, @___event);

    if result = 0
        then exit;

    FList.Add( iccRecord.Create( result, _proc));
end;

class function iccTimeout.unset( _id : DWORD; _callProc : Boolean = false) : Boolean;
var rec : iccRecord;
    proc : TProc;
begin
    result := KillTimer( 0, _id);

    if not result
        then exit;

    rec := FList.DelRes( list_Locate( _id));
    proc := rec.pr;
    rec.Destroy(); // moved here to avoid memory leaks
    if _callProc
         then proc();
    //rec.Destroy(); // causes memory leaks... ! Why? I dont know
end;


{ iccShellNotifyIcon }

class constructor iccShellNotifyIcon.___Initialize();
begin
    inherited;
    TaskBarCreationMsg := RegisterWindowMessage( 'TaskbarCreated');
    if TaskBarCreationMsg = 0
        then iccException.Create( 'ShellNotify may work incorrectly.');
end;

constructor iccShellNotifyIcon.Create(_Owner: iccComponent);
begin
    inherited;
    FWindowHandle  := AllocateHWnd( ShellProc); // Creating Message Processor
    FEnabled       := True;
    FICON          := LoadIcon( HInstance, 'MainIcon');
    FVisible       := False;
    FTip           := '';

    FLPressed := False;
    FMPressed := False;
    FRPressed := False;

    UpdateNotifyIconData;
    Update( NIM_DELETE);
end;

destructor iccShellNotifyIcon.Destroy;
begin
    Update( NIM_DELETE);
    DeallocateHWnd( FWindowHandle);
    FreeMem( FNotifyIconData); // Finally I got to free allocated memory for FNotifyIconData, otherwise MemoryManager should raise exception
    inherited;
end;

procedure iccShellNotifyIcon.ShellProc(var _Msg: TMessage);
var Point : TPoint;
begin
    if _Msg.Msg = TaskBarCreationMsg
        then begin
                 Update( NIM_ADD);
             end
        else if _Msg.Msg = WM_ENABLE
                 then begin
                          Enabled := Boolean( _Msg.WParam);
                      end
                 else if      ( Enabled)
                          and ( _Msg.Msg = WM_USER_ShellIcon)
                          then begin
                                   GetCursorPos( Point);
                                   {$Region ' MSG PROCESS '}
                                   case _Msg.LParam of
                                       WM_LBUTTONDOWN
                                          :begin
                                               if Assigned( FOnEvent)
                                                   then FOnEvent( Self, snimbLeft, snimaDown, Point.X, Point.Y);
                                               FLPressed := True;
                                           end;
                                       WM_LBUTTONUP
                                          :begin
                                               if Assigned( FOnEvent)
                                                   then FOnEvent( Self, snimbLeft, snimaUp ,Point.X, Point.Y);
                                               if FLPressed
                                                   then begin
                                                            FLPressed := False;
                                                            if Assigned( FOnEvent)
                                                                then FOnEvent( Self, snimbLeft, snimaClick, Point.X, Point.Y);
                                                        end;
                                           end;
                                       WM_LBUTTONDBLCLK
                                          :begin
                                               if Assigned( FOnEvent)
                                                   then FOnEvent( Self, snimbLeft, snimaDoubleClick, Point.X, Point.Y)
                                           end;
                                       WM_MBUTTONDOWN
                                          :begin
                                               if Assigned( FOnEvent)
                                                   then FOnEvent( Self, snimbMiddle, snimaDown, Point.X, Point.Y);
                                               FMPressed := True;
                                           end;
                                       WM_MBUTTONUP
                                          :begin
                                               if Assigned( FOnEvent)
                                                   then FOnEvent( Self, snimbMiddle, snimaUp, Point.X, Point.Y);
                                               if FMPressed
                                                   then begin
                                                            FMPressed := False;
                                                            if Assigned( FOnEvent)
                                                                then FOnEvent( Self, snimbMiddle, snimaClick, Point.X, Point.Y);
                                                        end;
                                           end;
                                       WM_MBUTTONDBLCLK
                                          :begin
                                               if Assigned( FOnEvent)
                                                   then FOnEvent( Self, snimbMiddle, snimaDoubleClick, Point.X, Point.Y)
                                           end;
                                       WM_RBUTTONDOWN
                                          :begin
                                               if Assigned( FOnEvent)
                                                   then FOnEvent( Self, snimbRight, snimaDown, Point.X, Point.Y);
                                               FRPressed := True;
                                           end;
                                       WM_RBUTTONUP
                                          :begin
                                               if Assigned( FOnEvent)
                                                   then FOnEvent( Self, snimbRight, snimaUp, Point.X, Point.Y);
                                               if FRPressed
                                                   then begin
                                                            FRPressed := False;
                                                            if Assigned( FOnEvent)
                                                                then FOnEvent( Self, snimbRight, snimaClick, Point.X, Point.Y);
                                                        end;
                                           end;
                                       WM_RBUTTONDBLCLK
                                          :begin
                                               if Assigned( FOnEvent)
                                                   then FOnEvent( Self, snimbRight, snimaDoubleClick, Point.X, Point.Y)
                                           end;
                                   end;
                                   {$ENDREGION}
                               end;
//                          else begin
//                                   RemoveMessageFromQueue( Handle);
//                                   EXIT;
//                               end;

    _Msg.Result := DefWindowProc( Handle, _Msg.Msg, _Msg.WParam, _Msg.LParam);
end;

procedure iccShellNotifyIcon.___prop_SetEnabled( _value : Boolean);
begin
    if FEnabled = _value then EXIT;

    FEnabled := _value;
end;

procedure iccShellNotifyIcon.___prop_SetIcon( _value: HICON);
begin
    if _value = FICON then Exit;

    FICON := _value;
    UpdateNotifyIconData;
    Update;
end;

procedure iccShellNotifyIcon.___prop_SetVisible( _value : boolean);
begin
    if _value = FVisible then Exit;

    FVisible := _value;
    case FVisible of
        True  : Update( NIM_ADD);
        False : Update( NIM_DELETE);
    end;
end;

procedure iccShellNotifyIcon.___prop_SetTip( _value : pchar);
begin
    if _value = FTip then Exit;

    FTip := _value;
    UpdateNotifyIconData;
    Update;
end;

procedure iccShellNotifyIcon.UpdateNotifyIconData;
var Size : DWORD;
begin
    FreeMemory( FNotifyIconData);
    Size := SizeOf( _NOTIFYICONDATA){ + Length( Tip) * SizeOf( Char)};
    FNotifyIconData := AllocMem( Size);

    /////////////////////////////////////////
    FNotifyIconData.cbSize           := Size;
    FNotifyIconData.Wnd              := Handle;
    FNotifyIconData.uID              := FNotifyIconData.Wnd;
    FNotifyIconData.uFlags           := NIF_ICON or NIF_MESSAGE or NIF_TIP;
    FNotifyIconData.uCallbackMessage := WM_USER_ShellIcon;
    FNotifyIconData.hIcon            := Icon;
    StrPCopy( FNotifyIconData.szTip, Tip);
end;

function iccShellNotifyIcon.Update : Boolean;
begin
    Result := False;
    if not Visible then Exit;

    result := Update( NIM_MODIFY);
end;

function iccShellNotifyIcon.Update( _operation : Integer) : Boolean;
begin
    result := Shell_NotifyIcon( _operation, FNotifyIconData);
end;

{ Screen }
class function iccScreen.Width()  : SmallInt;
begin
    Result := GetSystemMetrics( SM_CXSCREEN);
end;

class function iccScreen.Height() : SmallInt;
begin
    Result := GetSystemMetrics( SM_CYSCREEN);
end;

{ iccThread }

class constructor iccThread.___init;
begin
    clsvar_CriticalSection := TCriticalSection.Create();
end;

class destructor iccThread.___done;
var ndx : integer;

    cth : iccThread;
begin
    // here we can kill all the threads left
    clsvar_CriticalSection.Enter();
    try
        if ( clsvar_threadList <> nil) and ( clsvar_threadList.Cnt <> 0)
            then begin
                     for ndx := clsvar_threadList.Cnt - 1 downto 0 do
                         begin
                             cth := clsvar_threadList[ndx];
                             if ( tsDestroying in cth.State) or ( tsDestroyed in cth.State)
                                 then Continue;

                             // RefCount --> 0
                             while cth._Release() <> 0 do ;
                         end;

                     // TODO: add Termination proc. Proc to handle unexpected or early shutting down
                 end;
    finally
        clsvar_CriticalSection.Leave();
        clsvar_CriticalSection.Destroy();
    end;
end;

function iccThread._AddRef () : Integer;
begin
    result := inherited;
end;

function iccThread._Release() : Integer;
begin
    result := inherited;
end;

class function iccThread.internalThreadProc( _p : pointer) : Integer;
var params : ictpInternalThreadProcParams;
begin
    params := _p;

    if params.Self = nil
        then exit( 0);

    // !!! DO NOT ALLOW THREAD TO CRASH BY ITSELF.

    try
               try
                   if params.proc_Body <> nil
                       then params.proc_Body();
               except
                   try
                       if params.proc_onError <> nil
                           then if ( ExceptObject <> nil) and ( ExceptObject is Exception)
                                    then params.proc_onError( Exception( ExceptObject))
                                    else params.proc_onError( nil);
                   except
                       // if error processing has failed - continue to work...
                       // SWALLOW
                   end;
               end;
    finally
    end;

    result := 0;
end;

class function iccThread.threadAdd( _procBody    : ictThreadStagingProc;
                                    _procOnError : ictThreadOnErrorProc = nil
                                  ) : iciThread;
begin
    result := iccThread.Create( _procBody, _procOnError);
    iccThread( result).AutoDestroy := True;
end;

constructor iccThread.Create( _procBody    : ictThreadStagingProc;
                              _procOnError : ictThreadOnErrorProc = nil
                            );
begin
    clsvar_CriticalSection.Enter();
    try
        Include( FState, tsCreating);

        Include( FState, tsSuspended);


        FParams.Self := Self;
        FParams.proc_Body    := _procBody;
        FParams.proc_onError := _procOnError;


        // INIT
        FHandle := CreateThread( nil,
                                 0,
                                 @internalThreadProc,
                                 @FParams,
                                 CREATE_SUSPENDED,
                                 FID
                               );



        // add to list
        if clsvar_ThreadList = nil
            then clsvar_ThreadList := iccxList<iccThread>.Create();

        if not clsvar_ThreadList.Add( Self)
            then raise iccException.Create( 'iccThread.Create() -> clsvar_ThreadList.Add = false.');


        Include( FState, tsCreated);
        Exclude( FState, tsCreating);
    finally
        clsvar_CriticalSection.Leave();
    end;
end;

destructor iccThread.Destroy();
begin
    clsvar_CriticalSection.Enter();
    try
        if ( tsDestroying in FState) or ( tsDestroyed in FState)
            then raise iccException.Create( 'iccThread.Destroy() -> ( tsDestroying in FState) or ( tsDestroyed in FState) evaluates to true.');

        Include( FState, tsDestroying);



        suspend();
        terminate();
        CloseHandle( FHandle);



        // remove from list
        if not clsvar_ThreadList.Rem( Self)
            then raise iccException.Create( 'iccThread.Destroy() -> clsvar_ThreadList.Rem = false.');

        if clsvar_ThreadList.Cnt = 0
            then begin
                     clsvar_ThreadList.Destroy();
                     clsvar_ThreadList := nil;
                 end;

        Include( FState, tsDestroyed);
        Exclude( FState, tsDestroying);
    finally
        inherited;
        clsvar_CriticalSection.Leave();
    end;

    // закінчити роботу потоку. тру лише тоді, коли виклик стається з того самого потоку, яким володієм
    if GetCurrentThreadId = FID
        then begin
                 FreeInstance();

                 ExitThread( 0);
             end;
end;

function iccThread.resume   () : Boolean;
begin
    clsvar_CriticalSection.Enter();
    result := false;
    try
        if       ( tsCreating   in FState) // якшо створюється
          or     ( tsDestroying in FState) // якшо знищується
          or     ( tsDestroyed  in FState) // якшо вже знищений
          or not ( tsSuspended  in FState) // якшо НЕ зупинений
           then exit();

        // resuming
        result := ResumeThread( FHandle) <> DWORD( -1);

        if result
            then begin
                     Exclude( FState, tsSuspended);
                     Include( FState, tsResumed);
                 end;
    finally
        clsvar_CriticalSection.Leave();
    end;
end;

function iccThread.suspend  () : Boolean;
var cfw : Boolean; // процедура визвана із потока, який хочемо знищити
begin
    clsvar_CriticalSection.Enter();
    result := false;
    try
        if   ( tsCreating  in FState) // якшо створюється
          or ( tsDestroyed in FState) // якшо вже знищений
          or ( tsSuspended in FState) // якшо вже зупинений
           then exit();


        cfw := GetCurrentThreadId = FID;

        if cfw // якшо хочемо призупинити самі себе - шлем нах :)
            then exit
            else result := SuspendThread( FHandle) <> DWORD( -1);

        if result
            then begin
                     Exclude( FState, tsResumed);
                     Include( FState, tsSuspended);
                 end;
    finally
        clsvar_CriticalSection.Leave();
    end;
end;

function iccThread.terminate() : Boolean;
var cfw : Boolean; // процедура визвана із потока, який хочемо знищити
begin
    clsvar_CriticalSection.Enter();
    result := false;
    try
        cfw := GetCurrentThreadId = FID;

        if cfw // якшо хочемо зупинити самі себе - шлем нах :)
            then exit
            else result := TerminateThread( FHandle, 0);

        if result
            then begin
                     Exclude( FState, tsSuspended);
                     Exclude( FState, tsResumed);

                     Include( FState, tsTerminated); // !
                 end;
    finally
        clsvar_CriticalSection.Leave();
    end;
end;

function iccThread.waitFor( _timeout : DWORD) : Boolean;
var waitResult : DWORD;
begin
    result := false;

    if    ( tsCreating   in FState)
       or ( tsDestroying in FState)
       or ( tsDestroyed  in FState)
       or ( tsTerminated in FState)
        then exit();

    if GetCurrentThreadId = FID
        then exit;  // we cant wait ourself, only from other thread

    waitResult := WaitForSingleObject( FHandle, _timeout);

    result := ( waitResult <> WAIT_FAILED    ) and
              ( waitResult <> WAIT_ABANDONED ) and
              ( waitResult <> WAIT_TIMEOUT   );
end;

function iccThread.doSync( _hwnd : HWND; _wparam, _lparam : Integer; _post : Boolean = False) : Boolean;
var res : LongBool;
begin
    //clsvar_CriticalSection.Enter();
    try
        if _post
            then res := Boolean( PostMessage( _hwnd, wm_sync, _wparam, _lparam))
            else res := Boolean( SendMessage( _hwnd, wm_sync, _wparam, _lparam));
    finally
        //clsvar_CriticalSection.Leave();
    end;

    // preprocess res
    // ...

    // temp
    result := res;
end;

function iccThread.doSync( _hwnd : HWND; _proc : TProc; _post : Boolean = False) : Boolean;
begin
    result := doSync( _hwnd, Integer( Pointer( @TProc( _proc))), 0);
end;

function iccThread.set_AutoDestroy( _autoDestroy : Boolean = true) : Boolean;
begin
    try
        clsvar_CriticalSection.Enter();
        AutoDestroy := _autoDestroy;
    finally
        result := AutoDestroy; // to be sure
        clsvar_CriticalSection.Leave();
    end;
end;

function iccThread.get_AutoDestroy() : Boolean;
begin
    try
        clsvar_CriticalSection.Enter();
    finally
        result := AutoDestroy; // to be sure
        clsvar_CriticalSection.Leave();
    end;
end;


var
    c_AboutText : String
                = 'This program was written by Pavel Bugaevskiy.' + #13 +
                  '©' + 'Pavel Bugaevskiy, %YEAR%.' + #13#13 +
                  'This application was developed as order by somebody or for private purposes. (Anonymous for conspiracy)' + #13#13 +
                  '        Also you can visit:        http://inline-coder.net/' + #13 +
                  '        or e-mail me:              inlinecoder@gmail.com';

initialization
    {$IFDEF IncludeAbout}
    if WideLowerCase( ParamStr( 1)) = '/about'
        then begin
                 c_AboutText := StringReplace( c_AboutText, '%YEAR%', IntToStr( CurrentYear), [rfReplaceAll]);
                 MessageBox( 0, pchar( c_AboutText), pchar( 'About the author'), MB_OK or MB_ICONINFORMATION);
             end;
    {$ENDIF}

end.
