unit unt_wnd_main;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, Menus, ImgList, ComCtrls, ExtCtrls, StdCtrls,
    ShellAPI,
    rkSmartTabs,
    SynEdit, SynEditTypes, SynEditSearch, SynEditRegexSearch, SynEditKeyCmds,
    pngimage,
    unt_tabmanager,
    icClasses,
    icUtils,
    dxLabel, dxCore, dxContainer, dxListBox, unt_advImage,
    unt_frame_progressNotifier, unt_frame_errorNotifier, SynEditHighlighter, SynHighlighterURI, SynURIOpener, SynEditTextBuffer,
    SynEditMiscClasses;

const
     c_app_name = 'Tempad';
     c_app_crash = 'Application has encountered a fatal error and should be terminated.';
     c_app_crash_pleaseReport = 'Please, report about this. It would be great to fix such issue.';

     c_app_exceptionThresholdReached = 'Omg! Something really unexpected has happened. I don''t really know where it comes from and how to handle such things. It''s like a fatal error. So application should be terminated.';


     c_configFile        = 'c.fg';
     c_database          = 'db.dat';
     c_database_autosave_Flow   = 5000;  // editor onChange
     c_database_autosave_Forced = 20000; // independent

     c_files_filter = 'Text files|*.txt|';// +
                      //'Info files|*.inf, *.info|' +
                      //'Configuration files|*.ini|' +
                      //'All allowed|*.txt, *.inf, *.info, *.ini'
                      //;

     c_link_prefix      = 'http://';
     c_link_prefix_mail = 'mailto:';
     c_link_gmail       = 'inlinecoder@gmail.com';
     c_link_site        = c_link_prefix + 'inline-coder.net';
     c_link_twitter     = c_link_prefix + 'twitter.com/#pavelbugaevskiy';
     c_link_linkedin    = c_link_prefix + 'linkedin.com/profile/view?id=176566865';
     c_link_deviantart  = c_link_prefix + 'inline-coder.deviantart.com';
     c_link_vk          = c_link_prefix + 'vk.com/inlinecoder';
     c_link_vk_group    = c_link_prefix + 'vk.com/tempad';

     c_operation_save_Error     = 'Could not save. Error occured while processing';
     c_operation_load_Error     = 'Could not load. Error occured while processing';
     c_operation_search_Error   = 'Could not find "%s"';
     c_prompt_saveChanges       = 'Data was modified. Do you want to apply it to file?';
     c_prompt_loadClarification = 'Do you really want to load?'; // 'Content is not empty. Do you really want to load?';//

     c_prompt_Replace    = 'Replace "%s" with "%s"?';
     c_prompt_ReplaceAll = 'Do you really want to replace all occurences of "%s" with "%s"?';

     c_tab_closing_confirm = 'Data was modified. Do you really want to close?';

     c_wnd_recentTabManager_confirmation = 'Do you really want to delete selected item(s)? It can not be undone';
     c_wnd_recentTabManager_deleting_Failed = 'Ooops! Something went wront while deleting data from database';

     c_wnd_preview_dataLoading_failed = 'Ooops! Something went wrong. Could not load data';
     c_wnd_preview_InterruptAlert = 'Due to specifical SQLite3 Interrupt method, query can''t be interrupted in correct way.' + #13 + 'If you know how to handle such thing, please, contact the author (Contacts are in About)';

     c_firstrun_exampleText = 'Hello and Welcome to ' + c_app_name + '!' + #13#13 +
                              '    Here you can see some editor features that can help you to visualize' + #13 +
                              '    your text and make reading more convenient.' + #13#13 +
                              '--- Just type "-" 3 times' + #13#13 +
                              'List items:' + #13 +
                              '    >> Nice thing' + #13 +
                              '    >> Double ">" and you will get it' + #13 +
                              '    >>> Done or whatever...' + #13#13 +
                              '---' + #13#13 +
                              '/! Dont forget to Share app with your friends \ people you love!' + #13#13#13#13 +
                              'Likes and Emails are appreciated.' + #13 +
                              '    Home                 :  ' + c_link_site       + #13 +
                              '    Email                :  ' + c_link_gmail      + #13 +
                              '    Vk (social network)  :  ' + c_link_vk         + #13 +
                              '    Vk Tempad Group      :  ' + c_link_vk_group   + #13 +
                              '    Twitter              :  ' + c_link_twitter    + #13 +
                              '    DeviantArt           :  ' + c_link_deviantart + #13 +
                              '    LinkedIn             :  ' + c_link_linkedin   + #13 +
                              #13 +
                              'Thx for using :)'
                            ;


type
    iccTemplate_ColorScheme_ListBox_ItemPaint =
        class
            public
                Color1     : TColor;
                Color2     : TColor;

                Border     : TColor;
                Inner      : TColor;

                Fn1        : TColor;
                Fn2        : TColor;

                TextShadow : TColor;
        end;


    ictWindowState = ( wsInitInProgress,
                       wsFinitInProgress,
                       wsInitDone,
                       wsInitFailed,
                       wsFinitDone,
                       wsInteractReady, // when application fully loads and user can now interact with application
                       wsAcceptNativeClose
                     );
    icsWindowState = set of ictWindowState;

    iccRecentTab =
        class
            const
                c_height = 50;
            strict private
                FTID     : Integer;
                FTitle   : String;
                FChecked : Boolean;
            public
                constructor Create( _tid : Integer; _title : String); overload;
                constructor Create( _tid : Integer; _title : String; _checked : Boolean); overload;
            public
                property TID     : Integer read FTID;
                property Title   : String  read FTitle   write FTitle;
                property Checked : Boolean read FChecked write FChecked;
        end;

    iccSynEdit = class;

    iccTabObject =
        class( iccDynamicObject)
            strict private
                FLoaded           : Boolean; // default false. If data was loaded from database -> true

                FId               : Integer;
                FTitle            : String;
                FSynEdit          : iccSynEdit;

                FFile_Attached    : Boolean;
                FFile_DragDrop    : Boolean; // true means that file is opened by DragNDrop and it's not present in db. Even title and other...
                FFile_Fullpath    : String;
                FFile_Saved       : Boolean;
            public
                class function link( _obj : TObject) : iccTabObject; // if _obj is not iccTabObject -> result == nil
            public
                constructor Create(); override;
            public
                procedure file_attach( _str : String; _saved : Boolean = false);
            public
                property Loaded           : Boolean    read FLoaded           write FLoaded;

                property Id               : Integer    read FId               write FId;
                property Title            : String     read FTitle            write FTitle;
                property SynEdit          : iccSynEdit read FSynEdit          write FSynEdit;
                property FileAttached     : Boolean    read FFile_Attached    write FFile_Attached;
                property FileDragDrop     : Boolean    read FFile_DragDrop    write FFile_DragDrop;
                property FileFullpath     : String     read FFile_Fullpath    write FFile_Fullpath;
                property FileSaved        : Boolean    read FFile_Saved       write FFile_Saved;
        end;

    iccTabsMetaData =
        class( iccDynamicObject)
            const
                c_record = 'tabsMetaData'; // how we should be marked in Config
            type
                iccItem =
                    class( iccDynamicObject)
                        strict private const
                            c_linkId  = 'id';   c_ndx_linkId  = -1;
                            c_caretX  = 'cx';   c_ndx_caretX  = 0;
                            c_caretY  = 'cy';   c_ndx_caretY  = 1;
                            c_topLine = 'tl';   c_ndx_topLine = 2;
                            c_selStart = 'ss';  c_ndx_selStart = 3;
                            c_selEnd   = 'se';  c_ndx_selEnd   = 4;
                        strict private
                            function prop_getInt ( _index : Integer) : Integer;
                            procedure prop_setInt( _index : Integer; _value : Integer);
                        public
                            property linkId   : Integer index  c_ndx_linkId   read prop_getInt write prop_setInt;
                            property caretX   : Integer index  c_ndx_caretX   read prop_getInt write prop_setInt;
                            property caretY   : Integer index  c_ndx_caretY   read prop_getInt write prop_setInt;
                            property topLine  : Integer index  c_ndx_topLine  read prop_getInt write prop_setInt;
                            property selStart : Integer index  c_ndx_selStart read prop_getInt write prop_setInt;
                            property selEnd   : Integer index  c_ndx_selEnd   read prop_getInt write prop_setInt;
                    end;
            private
                function isClass( _v : Variant; _c : TClass) : Boolean; inline;
            public
                function clr() : Boolean; override;
                function del( _ndx : Integer) : Boolean; override;
            public
                function toString() : String; reintroduce;
                function fromString( _str : string) : Boolean; reintroduce;
            public
                function put( _linkId : Integer) : iccItem;
                function getByLinkId( _linkId : Integer) : iccItem; // nil if not found
                function getByIndex ( _index  : Integer) : iccItem;
                function delByLinkId( _linkId : Integer) : Boolean;
        end;

    iccSynEdit =
        class( TCustomSynEdit)
            private
                var FTabObject : iccTabObject; // linked object
            protected
                procedure adjustKeystrokes();
            public
                constructor Create( _owner : TComponent); override;
            public
                property TabObject : iccTabObject read FTabObject write FTabObject;
        end;

    iccConfig =
        class( iccDynamicObject)
            strict private
            public
                function retrieve( _param : String; _default : Integer) : Integer; overload;
                function retrieve( _param : String; _default : Boolean) : Boolean; overload;
                function retrieve( _param : String; _default : String ) : String;  overload;

                function write   ( _param : String; _value : Integer) : Boolean; overload; // ok or not ok
                function write   ( _param : String; _value : Boolean) : Boolean; overload; // ...
                function write   ( _param : String; _value : String ) : Boolean; overload; //
            public
                procedure routine_WindowParams_get( _sender : TCustomForm);
                procedure routine_WindowParams_set( _sender : TCustomForm);
        end;

    Twnd_main =
        class(TForm)
                surface_header: TdxContainer;
                tabs: TrkSmartTabs;
                surface_main: TdxContainer;
                imgs_pages: TImageList;
                tabMenu: TPopupMenu;
                Closetab1: TMenuItem;
                N1: TMenuItem;
                Newtab1: TMenuItem;
                Renametab1: TMenuItem;
                header_recent: TdxContainer;
                surface_recent: TdxContainer;
                dxLabel2: TdxLabel;
                lst_recentTabs: TdxListBox;
                img_recent: iccAdvImage;
                img_recent_edit: iccAdvImage;
                header_mainmenu: TdxContainer;
                img_mainmenu: iccAdvImage;
                lbl_recent_Total: TdxLabel;
                btn_recent_Restore: TButton;
                btn_recent_RestoreAll: TButton;
                img_tabRecent: TImage;
                dxLabel3: TdxLabel;
                edit_menu: TPopupMenu;
                item_edit_menu_Undo: TMenuItem;
                MenuItem2: TMenuItem;
                item_edit_menu_Cut: TMenuItem;
                item_edit_menu_Copy: TMenuItem;
                item_edit_menu_Paste: TMenuItem;
                item_edit_menu_Delete: TMenuItem;
                N4: TMenuItem;
                item_edit_menu_SelectAll: TMenuItem;
                surface_mainmenu: TdxContainer;
                iccAdvImage1: iccAdvImage;
                Image1: TImage;
                Image2: TImage;
                Image3: TImage;
                lbl_New: TLabel;
                Label2: TLabel;
                lbl_Close: TLabel;
                lbl_CloseAllButActive: TLabel;
                Shape1: TShape;
                Image4: TImage;
                Image5: TImage;
                Image6: TImage;
                lbl_Save: TLabel;
                Label6: TLabel;
                lbl_SaveAs: TLabel;
                lbl_LoadFrom: TLabel;
                Shape2: TShape;
                lbl_About: TLabel;
                Image7: TImage;
                Image8: TImage;
                lbl_Exit: TLabel;
                lbl_tabName: TdxLabel;
                Label1: TLabel;
                Label3: TLabel;
                Label4: TLabel;
                Label5: TLabel;
                Label7: TLabel;
                Label8: TLabel;
                editor_links_opener: TSynURIOpener;
                editor_links_highlight: TSynURISyn;
                img_globalSearch: iccAdvImage;
                procedure FormCreate(Sender: TObject);
                procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
                procedure surface_headerPaint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
                procedure surface_mainPaint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
                procedure FormDestroy(Sender: TObject);
                procedure tabsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
                procedure Closetab1Click(Sender: TObject);
                procedure Newtab1Click(Sender: TObject);
                procedure Renametab1Click(Sender: TObject);
                procedure surface_recentExit(Sender: TObject);
                procedure surface_msgErrorPaint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
                procedure img_recentClick(Sender: TObject);
                procedure tabsGetImageIndex(Sender: TObject; Tab: Integer; var Index: Integer);
                procedure lst_recentTabsDblClick(Sender: TObject);
                procedure img_recent_editClick(Sender: TObject);
                procedure btn_recent_RestoreClick(Sender: TObject);
                procedure btn_recent_RestoreAllClick(Sender: TObject);
                procedure lst_recentTabsItemPaint( _sender: TObject; _itemIndex: Integer;
                                                   _itemState: TdxListBox.iccItem.icsState;
                                                   _itemData: TdxListBox.ictItemDataType;
                                                   _canvas: TCanvas;
                                                   _rect: TRect
                                                 );
                procedure lst_recentTabsItemFocusOff(_sender: TObject;
                  _cur_itemIndex: Integer; _cur_itemState: TdxListBox.iccItem.icsState;
                  _cur_itemData: TdxListBox.ictItemDataType; _new_itemIndex: Integer;
                  _new_itemState: TdxListBox.iccItem.icsState;
                  _new_itemData: TdxListBox.ictItemDataType);
                procedure lst_recentTabsItemFocusSet( _sender: TObject; _itemIndex: Integer;
                                                      _itemState: TdxListBox.iccItem.icsState;
                                                      _itemData: TdxListBox.ictItemDataType
                                                    );
                procedure edit_menuPopup(Sender: TObject);
                procedure item_edit_menu_UndoClick(Sender: TObject);
                procedure item_edit_menu_CutClick(Sender: TObject);
                procedure item_edit_menu_CopyClick(Sender: TObject);
                procedure item_edit_menu_PasteClick(Sender: TObject);
                procedure item_edit_menu_DeleteClick(Sender: TObject);
                procedure item_edit_menu_SelectAllClick(Sender: TObject);
                procedure surface_mainmenuPaint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
                procedure img_mainmenuClick(Sender: TObject);
                procedure surface_mainmenuExit(Sender: TObject);
                procedure iccAdvImage1Click(Sender: TObject);
                procedure lbl_NewMouseEnter(Sender: TObject);
                procedure lbl_NewMouseLeave(Sender: TObject);
                procedure lbl_ExitClick(Sender: TObject);
                procedure lbl_AboutClick(Sender: TObject);
                procedure lbl_LoadFromClick(Sender: TObject);
                procedure lbl_SaveAsClick(Sender: TObject);
                procedure lbl_SaveClick(Sender: TObject);
                procedure lbl_CloseAllButActiveClick(Sender: TObject);
                procedure lbl_CloseClick(Sender: TObject);
                procedure lbl_NewClick(Sender: TObject);
                procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
                procedure FormPaint(Sender: TObject);
                procedure lst_recentTabsPaint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
                procedure img_recentMouseEnter(Sender: TObject);
                procedure img_recent_editMouseEnter(Sender: TObject);
                procedure img_mainmenuMouseEnter(Sender: TObject);
                procedure img_globalSearchMouseEnter(Sender: TObject);
                procedure img_globalSearchClick(Sender: TObject);
                procedure lst_recentTabsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
            const
                c_alias_activetab = 'activetab';
                c_alias_vacuum    = 'doVacuum';

                c_vacuum_frequency = 50; // perform vacuum operation every N-launch

                c_tabSwitch_Next = -1;
                c_tabSwitch_Prev = -2;
            private
                FState       : icsWindowState;
                FTab_Current : Integer;
                FTab_Last    : Integer;
                FTab_Popup    : Integer;
                FPopup_CurrentSynEdit : TSynEdit;

                FTabManager  : iccTabManager;

                FTabMetaData : iccTabsMetaData;

                FRecentTabs  : iccxList<iccRecentTab>;
            private
                FFrame_Progress : TFrame_ProgressNotifier;
                FFrame_Error    : Tframe_ErrorNotifier;
            private
                FSearch_Engine  : TSynEditSearch;
                FTempString_Search  : String;
                FTempString_Replace : String;
            private
                procedure ___event_tabAdd( _Sender : TObject);
                procedure ___event_tabClose( _Sender : TObject; _index : Integer; var _Close : Boolean);
                procedure ___event_tabSetActive( _Sender : TObject; _activeTab : Integer);
            private
                FInitThread : iciThread;
                procedure init ( _onDone : TProc; _onError : TProc<Exception>);
                procedure finit( _onDone : TProc; _onError : TProc<Exception>);
            private
                procedure msg_wm_sync     ( var _msg : iccthread.icr_wm_sync); message iccThread.wm_sync;
                procedure msg_wm_dropfiles( var _msg : TWMDropFiles); message wm_dropfiles;
            private
                FAutosave_Timeout_Flow   : DWORD;
                FAutosave_Timeout_Forced : DWORD;

                procedure autosave_do(); // autosaving everything: tabs, tabs` content and recent...
                procedure autosave_loop( _delay : Integer; _startOrStop : Boolean = true); // true - start, false - opposite

                procedure autosave_Flow( _set : Boolean = false); // set or unset
            public
                procedure ___event_synEditChange( _Sender : TObject);
                procedure ___event_synEditSpecialLineColors( _Sender: TObject; _Line: Integer; var _Special: Boolean; var _FG, _BG: TColor);
                procedure ___event_synEditOnReplaceText(       _Sender           : TObject;
                                                         const _Search, _Replace : string;
                                                               _Line  , _Column  : Integer;
                                                         var   _Action           : TSynReplaceAction
                                                       );
                procedure ___event_synEditGutterClick( _Sender: TObject;
                                                       _Button: TMouseButton;
                                                       _X,
                                                       _Y,
                                                       _Line: Integer;
                                                       _Mark: TSynEditMark
                                                     );


                procedure ___event_editOnKeyPress( _Sender: TObject; var _Key: Char);

                procedure key_Preview( _Sender: TObject; var _Key: Word; _Shift: TShiftState);
            public
                function tab_getObject( _ndx : Integer) : iccTabObject;

                // _loaded : true - means that we do not need to automatically load data from database according to ID
                function tab_New      ( _title : String = ''; _data : String = ''; _loaded : Boolean = false; _modified : Boolean = False; _focus : Boolean = false) : iccTabObject; // nil or tab's object
                function tab_Load     ( _id  : Integer) : Boolean; // loads data from and then tab_New
                function tab_Close    ( _ndx : Integer) : Boolean; //
                function tab_Switch   ( _ndx : Integer) : Boolean; // switch\show tabs by index or forward or backward direction ( c_tabSwtich_Next, ..._Prev)

                function tab_check_0AutoAdd( _firstRun : Boolean = false) : Boolean;
                function tab_check_AttachedToFileModified( _ndx : Integer) : Integer; // якшо прив'язані до файлу і в редакторі робились зміни - показать діалог. -1 - aborted, 0 - false(не зберігати), 1 - true (зберігати)

                //
                function tab_WriteToDB( _title : String; _data : String = '') : Integer; // result = id; -1 if error
                function tab_AddAndWriteToDB( _title : String = ''; _data : String = ''; _modified : Boolean = False) : iccTabObject;
                function tab_CloseAndMoveToRecent( _ndx : Integer) : Boolean;        // marking as deleted and saving all current data and title
                function tab_CloseAndMoveToRecent_AllBut( _exc : Integer) : Boolean;

                procedure tab_pushMetaData( _tabIndex : Integer);
                procedure tab_collectMetaData(); // save caretX, caretY, topline etc from all opened tabs

                // робота з вкладками, перевірка різних данних і тд. Закриваєм, і в рісент
                function do_tab_Close      ( _ndx : Integer) : Integer; // -1 aborted, false, true
                function do_tab_CloseAllBut( _exc : Integer) : Integer; // same as over
            public
                procedure recent_UpdateList();
                procedure recent_Open( _index : Integer; _focus : Boolean = true);

                procedure recent_Add( _tid : Integer; _title : String; _insertAt0 : Boolean = true);
                procedure recent_Del( _ndx : Integer);
            public
                procedure systemMenu( _enabled : Boolean = true); // enable or disabled system menu
            public
                procedure popupCheck();
            public
                function dialog_save_requestFile( out _str : String; _title : String = '') : Boolean; // filename as results
                function dialog_load_requestFile( out _str : String; _title : String = '') : Boolean; // same
                //
                procedure file_Save( _tabObj : iccTabObject; _saveAs : Boolean = false);
                procedure file_Load( _tabObj : iccTabObject = nil; _filename : String = '');
            public
                procedure ___event_container_paint_Generic( _Sender: TObject; _Rect: TRect; _ACanvas: TCanvas; _AFont: TFont);
            public
                procedure currentTab_check(); // set vars
                function currentTab_object() : iccTabObject;
                function currentTab_edit  () : iccSynEdit;
            public
                procedure ui_enabled( _enabled : boolean = true); // enabled or disabled whole form
                function ui_interactable() : Boolean; // check if we can do something with ui

                procedure do_search ( _useCurrent : Boolean = false; _string : String = ''); // performs search (find next) in current visible tab
                procedure do_replace( _source, _destination : String; _replaceAll : Boolean = false);

                procedure dialog_globalSearch();
                // if _useCurrent -> do not update FSearch_string by _string and performs search by existed value in FSearch_String
                procedure dialog_search();
                procedure dialog_replace();
            public
                property TabManager  : iccTabManager          read FTabManager;
                property RecentTabs  : iccxList<iccRecentTab> read FRecentTabs;
                property TabMetaData : iccTabsMetaData        read FTabMetaData;
        end;


    icc_wrapper_advImage =
        class
                FImg_Default : TPicture;
                FImg_Press   : TPicture;
                FText        : String;
                FTextWidth   : Integer;
                FSide        : Boolean; // false - left, other
                FContainer   : TDxContainer;
            strict private
                procedure ___event_onDestroy( _sender : TObject); // !important
                procedure ___event_onPaint( _sender: TObject; _rect: TRect; _canvas: TCanvas; _Font: TFont);
                procedure ___event_onMouseLeave( _sender : TObject);
                constructor Create( _owner : TComponent);
            public
                class function wrap( _ownerParent : TWinControl; _img : iccAdvImage; _text : String) : tdxContainer;
        end;




var
    wnd_main  : Twnd_main;
    gv_FirstRun : Boolean   = false; // is it a first apps` run?
    gv_Config   : iccConfig = nil;   // global config for all purpose

    //

    v_tcllsit_Normal  : iccTemplate_ColorScheme_ListBox_ItemPaint = nil;
    v_tcllsit_Normal2 : iccTemplate_ColorScheme_ListBox_ItemPaint = nil;
    v_tcllsit_Lighten : iccTemplate_ColorScheme_ListBox_ItemPaint = nil;
    v_tcllsit_Focused : iccTemplate_ColorScheme_ListBox_ItemPaint = nil;

    //

    function initiate_check( out _str : String) : Boolean;
    procedure do_initiate(); // here we can init anything before main form is created. Do not perform hard computing.
    procedure init_Template_ColorScheme_ListBox_ItemPaint;

    procedure do_finalize(); // here we can can dispose all create data in initiate_init();
    procedure finit_Template_ColorScheme_ListBox_ItemPaint;

    procedure localizePath();
    function util_FileToString( out _str : String; _filename : String) : Boolean;
    function util_StringToFile(     _str : String; _filename : String) : Boolean;
    function util_ValidateFilename( _str : String; _ext : String) : String; // t.txt -> t.txt  ;  t -> t.txt

    procedure fileTypes_make( _dest : TFileTypeItems);


    function savePos_X( _inX, _default : Integer) : Integer;
    function savePos_Y( _inY, _default : Integer) : Integer;

//    procedure draw_GenericSurface( _canvas : TCanvas);



implementation

uses
    unt_wnd_recentTabManager
  , unt_wnd_search
  , unt_wnd_replace
  , unt_wnd_about
  , unt_wnd_globalSearch
  ;

{$R *.dfm}

    function initiate_check( out _str : String) : Boolean;
    var path : String;
        file_DB  : Boolean;
//        file_Cfg : Boolean;
    begin
        result := false;

        path := ExtractFilePath( paramStr( 0));

        // network
        if not iccFile_Security.isLocalPath( path)
            then begin
                     _str := 'Launching over the network is prohibited. ( ' + path + '). To get rid of this notification, just move the app (with all supplied files, if there are) to a local folder (e.g: c:\' + c_app_name + '\).';
                     exit();
                 end;

        // do we have read-write access
//        if not iccFile_Security.check( path, iccFile_Security.FILE_ALL_ACCESS)
        if not iccFile_Security.check( path, iccFile_Security.FILE_READ_DATA or iccFile_Security.FILE_WRITE_DATA)
            then begin
                     _str := 'Lack of permissions. Destinated path (' + path + ') should be read-write-able. To fix this, move the app (with all supplied files, if there are) to a local READ-WRITE-able folder or change folder permissions manually.';
                     exit();
                 end;


        localizePath(); // focus on local dir

        file_DB  := true; // avail
//        file_Cfg := true; // .

        // what about db file?
        if not FileExists( c_database)
            then file_DB  := false;

        // what about config file?
//        if not FileExists( c_configFile)
//            then file_Cfg := false;

        gv_Config := iccConfig.Create();
        gv_Config.loadFromFile( c_configFile); // no need to check if success

        // if db file is not present, that means First Run
        if not file_DB// or not file_Cfg
            then gv_FirstRun := true;

        result := true;
    end;

    procedure do_initiate();
    begin
        init_Template_ColorScheme_ListBox_ItemPaint();
    end;

    procedure init_Template_ColorScheme_ListBox_ItemPaint;
    begin
        v_tcllsit_Normal := iccTemplate_ColorScheme_ListBox_ItemPaint.Create();
        v_tcllsit_Normal.Color1     := $ffffff;
        v_tcllsit_Normal.Color2     := $f5f5f5;
        v_tcllsit_Normal.Border     := $dfdedf;
        v_tcllsit_Normal.Inner      := $ffffff;
        v_tcllsit_Normal.Fn1        := $494949;
        v_tcllsit_Normal.Fn2        := clGray;
        v_tcllsit_Normal.TextShadow := clWhite;
        //
        v_tcllsit_Normal2 := iccTemplate_ColorScheme_ListBox_ItemPaint.Create();
        v_tcllsit_Normal2.Color1     := $f5f5f5;
        v_tcllsit_Normal2.Color2     := $f0f0f0;
        v_tcllsit_Normal2.Border     := $dfdedf;
        v_tcllsit_Normal2.Inner      := $ffffff;
        v_tcllsit_Normal2.Fn1        := $494949;
        v_tcllsit_Normal2.Fn2        := clGray;
        v_tcllsit_Normal2.TextShadow := clWhite;
        //
        v_tcllsit_Lighten := iccTemplate_ColorScheme_ListBox_ItemPaint.Create();
        v_tcllsit_Lighten.Color1     := color_darker( $f5f5f5, 5);
        v_tcllsit_Lighten.Color2     := color_darker( $f0f0f0, 5);
        v_tcllsit_Lighten.Border     := color_darker( $dfdedf, 5);
        v_tcllsit_Lighten.Inner      := color_darker( $ffffff, 5);
        v_tcllsit_Lighten.Fn1        := color_darker( $494949, 5);
        v_tcllsit_Lighten.Fn2        := color_darker( clGray, 5);
        v_tcllsit_Lighten.TextShadow := color_darker( clWhite, 5);
        //
        v_tcllsit_Focused := iccTemplate_ColorScheme_ListBox_ItemPaint.Create();
        v_tcllsit_Focused.Color1     := $f78263;
        v_tcllsit_Focused.Color2     := $f55527;
        v_tcllsit_Focused.Border     := $ea4716;
        v_tcllsit_Focused.Inner      := $fa803b;
        v_tcllsit_Focused.Fn1        := clWhite;
        v_tcllsit_Focused.Fn2        := $f5f5f5;
        v_tcllsit_Focused.TextShadow := $ea4716;
    end;

    procedure do_finalize();
    begin
        finit_Template_ColorScheme_ListBox_ItemPaint();

        //
        gv_Config.Destroy();
    end;

    procedure finit_Template_ColorScheme_ListBox_ItemPaint;
    begin
        v_tcllsit_Normal.Destroy();
        v_tcllsit_Normal2.Destroy();
        v_tcllsit_Lighten.Destroy();
        v_tcllsit_Focused.Destroy();
    end;

    procedure localizePath();
    begin
        SetCurrentDir( ExtractFilePath( Application.ExeName));
    end;

    function util_FileToString( out _str : String; _filename : String) : Boolean;
    var fs : TStringStream;
    begin
        fs := nil;
        try
            fs := TStringStream.Create( '', TEncoding.UTF8);
            fs.LoadFromFile( _filename);

            _str := fs.ReadString( fs.Size);

            result := true;
        finally
            fs.Free();
        end;
    end;

    function util_StringToFile( _str : String; _filename : String) : Boolean;
    var fs : TStringStream;
    begin
        fs := nil;
        try
            fs := TStringStream.Create( _str, TEncoding.UTF8);
            fs.SaveToFile( _filename);

            result := true;
        finally
            fs.Free();
        end;
    end;

    function util_ValidateFilename( _str : String; _ext : String) : String;
    begin
        result := _str;
        if LastDelimiter( _ext, _str) <> Length( _str)
            then result := result + _ext;
    end;

    procedure fileTypes_make( _dest : TFileTypeItems);
    begin
        with _dest.Add() do
            begin
                DisplayName := 'Text documents';
                FileMask    := '*.txt';
            end;
//        with _dest.Add() do
//            begin
//                DisplayName := 'Info files';
//                FileMask    := '*.inf, *.info';
//            end;
//        with _dest.Add() do
//            begin
//                DisplayName := 'Configuration files';
//                FileMask    := '*.ini';
//            end;
    end;

    function savePos_X( _inX, _default : Integer) : Integer;
    begin
        result := _inX;
        if _inX > Screen.DesktopWidth
            then result := _default;
    end;

    function savePos_Y( _inY, _default : Integer) : Integer;
    begin
        result := _inY;
        if _inY > Screen.DesktopHeight
            then result := _default;
    end;

{ iccSynEdit }

procedure iccSynEdit.adjustKeystrokes();
var ndx : integer;
begin
    // ENSURE CORRECT WE HAVE VALID KEYSTROKES


    // freeing Ctrl+T and remapping command to Ctrl+R
    ndx := Keystrokes.FindKeycode( Word( 'T'), [ssCtrl]);

    if ndx = -1
        then exit;

    Keystrokes.Items[ndx].Key := Word( 'U');
    //

    ///////////

    // freeing Ctrl+N and remapping command to Ctrl+Shift+N  // insert new line
    ndx := Keystrokes.FindKeycode( Word( 'N'), [ssCtrl]);

    if ndx = -1
        then exit;

    Keystrokes.Items[ndx].Key   := Word( 'N');
    Keystrokes.Items[ndx].Shift := [ssCtrl, ssShift];
    //
end;

constructor iccSynEdit.Create( _owner : TComponent);
begin
    if not ( _owner is TWinControl)
        then raise iccException.Create( 'iccSynEdit() -> Create() -> _owner is not a descendant of TWinControl');

    inherited Create( _owner);
    adjustKeystrokes();

    Left      := 5;
    Top       := 5;
    Width     := TWinControl( _owner).Width - 10;
    Height    := TWinControl( _owner).Height - 10;
    Anchors   := [ akLeft, akTop, akRight, akBottom];
    Visible   := False;
    Parent    := TWinControl( _owner);
    ActiveLineColor := $f4fcff;

    Gutter.ShowLineNumbers := true;
    Gutter.Color := clWhite;
    Gutter.Font.Color := $DFDFDF;
    gutter.Font.Size  := 8;
    Gutter.RightOffset := 10;
    Gutter.LeftOffset  := 0;
    Gutter.BorderStyle := gbsRight;
    Gutter.BorderColor := $F0F0F0;

//    gutterclick

    Options   := Options + [eoEnhanceHomeKey, eoTabIndent, eoTabsToSpaces, eoSmartTabs];
    TabWidth := 4;
    WantTabs := true;

    WordWrap  := true;
    RightEdge := 0;
    //syned.RightEdgeColor := clSilver;
    //syned.ExtraLineSpacing := 2;

    FTabObject := iccTabObject.Create();
    FTabObject.SynEdit := self; // self link
    //FTabObject.Title   := _title;
end;

{ Twnd_main }

procedure Twnd_main.FormCloseQuery(Sender: TObject; var CanClose: Boolean);

    procedure vacuumCheck();
    begin
        gv_Config[c_alias_vacuum] := gv_Config.retrieve( c_alias_vacuum, 0) + 1;

        if gv_Config[c_alias_vacuum] mod c_vacuum_frequency = 0
            then FTabManager.vacuumEnable();
    end;

begin
    CanClose := False;

    // if this condition if satisfied, that means, that we can finally close ourself
    if wsAcceptNativeClose in FState
        then begin
                 CanClose := True;
                 Exit();
             end;

    // interact ready, no? - Fuck off
    if not ( wsInteractReady in FState)
        then Exit();
    Exclude( FState, wsInteractReady); // we do not want to process any other messages

    // if we've failed, just save positions and exit
    if wsInitFailed in FState
        then begin
                 if gv_Config <> nil
                     then begin
                              gv_Config.routine_WindowParams_set( Self);
                              localizePath();
                              gv_Config.saveToFile( c_configFile);
                          end;

                 CanClose := True;
                 Exit();
             end;


    if ( not ( wsInitDone in FState) or ( wsInitInProgress in FState))
        then Exit();


    {$REGION '    '}
    if not ( ( wsFinitInProgress in FState) or ( wsFinitDone in FState))
        then begin
                 // autosave
                 autosave_loop( c_database_autosave_Forced, false);

                 // disable menu while loading
                 systemMenu( false);

                 // hide search if visible
                 Twnd_Search.do_Destroy();
                 Twnd_replace.do_Destroy();

                 Tframe_ProgressNotifier.checkCreate( FFrame_Progress, Self, Self);
                 iccTimeout.set__( 200, procedure () begin FFrame_Progress.Show(); end);

                 surface_header.Hide();
                 surface_main.Hide();
                 surface_recent.Hide();
                 surface_mainmenu.Hide();
                 menu := nil;
                 Update();


                 // app config
                 if gv_Config <> nil
                     then begin
                              //
                              vacuumCheck();

                              // save main window positions
                              gv_Config.routine_WindowParams_set( Self);

                              // active tab
                              currentTab_check();
                              gv_Config[c_alias_activetab] := tabs.ActiveTab;

                              // collect meta data
                              tab_collectMetaData();
                              gv_Config.write( iccTabsMetaData.c_record, FTabMetaData.ToString());

                              localizePath();
                              gv_Config.saveToFile( c_configFile);
                          end;

                 // clear events
                 tabs.OnAddClick     := nil;
                 tabs.OnCloseTab     := nil;
                 tabs.OnSetActiveTab := nil;


                 finit( procedure ()
                        begin
                            try
                                while tabs.Tabs.Count <> 0 do
                                    tab_Close( 0);
                            except
                            // silent
                            end;

                            FFrame_Progress.Status_Set( 'Done');

                            Include( FState, wsAcceptNativeClose);
                            Close();
                        end
                        ,
                        procedure ( _e : Exception)
                        begin
                            MessageBox( Handle, 'finit() -> _onDone() -> failed', c_app_name, MB_OK or MB_ICONWARNING or MB_TASKMODAL);

                            // Exit anyway
                            Include( FState, wsAcceptNativeClose);
                            Close();
                        end
                      );
             end;
  {$ENDREGION}
end;

procedure Twnd_main.FormCreate(Sender: TObject);

    procedure disableDblClick( _control : TControl);
    begin
        _control.ControlStyle := _control.ControlStyle - [csDoubleClicks];
    end;

var timeout : DWORD;
begin
    // show progress
    Tframe_ProgressNotifier.checkCreate( FFrame_Progress, Self, Self);
    timeout := iccTimeout.set__( 200, procedure () begin FFrame_Progress.Show(); end);

    // disable menu while loading
    systemMenu( false);

    FTab_Last  := -1;
    FTab_Popup := -1;

    disableDblClick( img_recent);
    disableDblClick( img_recent_edit);
    disableDblClick( img_mainmenu);

    // load params
    gv_Config.routine_WindowParams_get( Self);

    // connect events
    tabs.OnAddClick     := ___event_tabAdd;
    tabs.OnCloseTab     := ___event_tabClose;
    tabs.OnSetActiveTab := ___event_tabSetActive;

    // show main window
    Show();
    Update();

    // thread
    init( procedure ()
          begin
              surface_header.Show();
              surface_main.Show();

              iccTimeout.unset( timeout);
              Tframe_ProgressNotifier.Release( FFrame_Progress);

              DragAcceptFiles( Handle, True);

              // menu while loading
              systemMenu();

              // focus
              if TVarData( gv_Config[c_alias_activetab]).VType <> varNull
                  then tabs.ActiveTab := gv_Config[c_alias_activetab];

              // everything is done, user can interact now
              Include( FState, wsInteractReady);
          end
          ,
          procedure ( _e : Exception)
          begin
              Tframe_ProgressNotifier.release( FFrame_Progress);

              Tframe_ErrorNotifier.checkCreate( FFrame_Error, Self, Self);
              FFrame_Error.Status_Set( '[b]' + _e.Message + '[/b].[br]' + #13'Add. info: ' + _e.ClassName);
          end
        );
end;

procedure Twnd_main.FormDestroy(Sender: TObject);
begin
    //
end;

procedure Twnd_main.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
    key_Preview( sender, key, shift);
end;

procedure Twnd_main.FormPaint(Sender: TObject);
var frm : TCustomForm;
begin
    frm := TCustomForm( Sender);
    drawGradient( frm.Canvas.Handle, 1, 1, frm.ClientWidth, 50, clWhite, $F0F0F0);
end;

procedure Twnd_main.iccAdvImage1Click(Sender: TObject);
begin
    surface_mainmenu.Hide();
end;

procedure Twnd_main.img_globalSearchClick(Sender: TObject);
begin
    dialog_globalSearch();
end;

procedure Twnd_main.img_globalSearchMouseEnter(Sender: TObject);
begin
    icc_wrapper_advImage.wrap( self, img_globalSearch, 'Global search');
end;

procedure Twnd_main.img_mainmenuClick(Sender: TObject);
begin
    currentTab_check();
    lbl_tabName.Caption := currentTab_object.Title;
    if currentTab_object.FileAttached
        then lbl_Save.Caption := 'Save to ' + ExtractFileName( currentTab_object.FileFullpath)
        else lbl_Save.Caption := 'Save';

    surface_mainmenu.BringToFront();
    surface_mainmenu.Show();
    surface_mainmenu.SetFocus();
end;

procedure Twnd_main.img_recentClick(Sender: TObject);
begin
    surface_recent.Visible := not surface_recent.Visible;

    if surface_recent.Visible
        then lst_recentTabs.SetFocus()
        else surface_main.SetFocus();
end;

procedure Twnd_main.img_mainmenuMouseEnter(Sender: TObject);
begin
    icc_wrapper_advImage.wrap( self, img_mainmenu, 'Main menu');
end;

procedure Twnd_main.img_recentMouseEnter(Sender: TObject);
begin
    icc_wrapper_advImage.wrap( self, img_recent, 'Recent tabs');
end;

procedure Twnd_main.img_recent_editMouseEnter(Sender: TObject);
begin
    icc_wrapper_advImage.wrap( self, img_recent_edit, 'Edit recent tabs');
end;

procedure Twnd_main.img_recent_editClick(Sender: TObject);
var wnd : Twnd_recentTabManager;
begin
    wnd := Twnd_recentTabManager.Create( Self);
    //
    wnd.list_fill();
    wnd.update_Counter_SelectedItems();
    wnd.update_btn_DeleteForever();
    //
    wnd.ShowModal();
    wnd.Destroy();
    //
    recent_UpdateList();
    //
end;

procedure Twnd_main.init(_onDone: TProc; _onError : TProc<Exception>);
var obj     : iccTabObject;
    id      : Integer;
    title   : String;
    order   : Integer;
    deleted : Boolean;
begin
    Include( FState, wsInitInProgress);

    FInitThread := iccThread.threadAdd
    (
        procedure ()
        var lst : iccxList;
            ndx : integer;
        begin
            FTabManager  := iccTabManager.Create( c_database);

            FTabMetaData := iccTabsMetaData.Create();
            FTabMetaData.fromString( gv_Config.retrieve(iccTabsMetaData.c_record, ''));

            FRecentTabs  := iccxList<iccRecentTab>.Create();

            // creating search related object
            FSearch_Engine := TSynEditSearch.Create( Self);
            FTempString_Search := '';


            // retrieve opened tabs
            lst := FTabManager.GetAll( garNotDeleted);
            for ndx := 0 to lst.Cnt - 1 do
                begin
                    id := lst[ndx];

                    // updating status
                    FFrame_Progress.Status_Set_threadContext( FInitThread, 'Processing tab: [b]' + title + '[/b]');

                    if not FTabManager.getInfo( id, title, order, deleted)
                        then raise iccException.Create( 'init() -> getInfo() failed');

                    if not FInitThread.doSync( Handle,
                                               procedure ()
                                               begin
                                                   obj := tab_New( title, '');
                                                   obj.Id := id;
                                               end
                                             )
                        then raise iccexception.Create( 'doSync() -> failed');
                end;
            lst.Destroy();

            // retrieve recent tabs
            lst := FTabManager.GetAll( garDeleted);
            for ndx := 0 to lst.Cnt - 1 do
                begin
                    id := lst[ndx];
                    if not FTabManager.getInfo( id, title, order, deleted)
                        then raise iccException.Create( 'init() -> getInfo() failed');

                    // updating status
                    FFrame_Progress.Status_Set_threadContext( FInitThread, 'Recent tab: [b]' + title + '[/b]');

                    FInitThread.doSync( handle, procedure () begin recent_Add( id, title, false); end);
                    //recent_Add( id, title, false);
                end;
            lst.Destroy();

            // updating status
            FFrame_Progress.Status_Set_threadContext( FInitThread, 'Almost done');

            if not FInitThread.doSync( Handle,
                                       procedure ()
                                       begin
                                            // autosave    // ! Do it from the main thread
                                            autosave_loop( c_database_autosave_Forced);

                                            if not tab_check_0AutoAdd( gv_FirstRun)
                                               then raise iccException.Create( 'tab_check0Autoadd() -> failed');

                                            recent_UpdateList;
                                       end
                                     )
                then raise iccexception.Create( 'doSync() -> failed');

            Include( FState, wsInitDone);
            Exclude( FState, wsInitInProgress);

            // updating status
            FFrame_Progress.Status_Set_threadContext( FInitThread, 'Done');

            if TProc( _onDone) <> nil
                then if not FInitThread.doSync( Handle, procedure () begin _onDone(); end)
                         then raise iccexception.Create( 'doSync() -> failed');
        end
        ,
        procedure ( _e : Exception)
        begin
            Include( FState, wsInitFailed);
            Exclude( FState, wsInitInProgress);

            if TProc( _onError) <> nil
                then if not FInitThread.doSync( Handle, procedure () begin _onError( _e); end)
                         then raise iccexception.Create( 'doSync() -> failed');
        end
    );

    FInitThread.resume();
end;

procedure Twnd_main.item_edit_menu_CopyClick(Sender: TObject);
begin
    popupCheck();
    FPopup_CurrentSynEdit.CopyToClipboard();
end;

procedure Twnd_main.item_edit_menu_CutClick(Sender: TObject);
begin
    popupCheck();
    FPopup_CurrentSynEdit.CutToClipboard();
end;

procedure Twnd_main.item_edit_menu_DeleteClick(Sender: TObject);
begin
    popupCheck();
    FPopup_CurrentSynEdit.SelText := '';
end;

procedure Twnd_main.item_edit_menu_PasteClick(Sender: TObject);
begin
    popupCheck();
    FPopup_CurrentSynEdit.PasteFromClipboard();
end;

procedure Twnd_main.item_edit_menu_SelectAllClick(Sender: TObject);
begin
    popupCheck();
    FPopup_CurrentSynEdit.SelectAll();
end;

procedure Twnd_main.item_edit_menu_UndoClick(Sender: TObject);
begin
    popupCheck();
    FPopup_CurrentSynEdit.Undo();
end;

procedure Twnd_main.lbl_AboutClick(Sender: TObject);
var wnd : twnd_about;
begin
    surface_mainmenuExit( Self);

    wnd := twnd_about.Create( Self);
    wnd.ShowModal();
    wnd.Destroy();
end;

procedure Twnd_main.lbl_CloseAllButActiveClick(Sender: TObject);
var crtb : Integer;
begin
    crtb := FTab_Current;
    surface_mainmenuExit( Self);
    do_tab_CloseAllBut( crtb);
end;

procedure Twnd_main.lbl_CloseClick(Sender: TObject);
var crtb : Integer;
begin
    crtb := FTab_Current;
    surface_mainmenuExit( Self);

    do_tab_Close( crtb);
end;

procedure Twnd_main.lbl_ExitClick(Sender: TObject);
begin
    surface_mainmenuExit( Self);
    Close();
end;

procedure Twnd_main.lbl_LoadFromClick(Sender: TObject);
begin
    surface_mainmenuExit( Self);

    currentTab_check();
    file_Load( currentTab_object);
end;

procedure Twnd_main.lbl_NewClick(Sender: TObject);
begin
    surface_mainmenuExit( Self);
    tab_AddAndWriteToDB();
end;

procedure Twnd_main.lbl_NewMouseEnter(Sender: TObject);
begin
    //
    TLabel( Sender).Font.Style := [fsUnderline];
end;

procedure Twnd_main.lbl_NewMouseLeave(Sender: TObject);
begin
    //
    TLabel( Sender).Font.Style := [];
end;

procedure Twnd_main.lbl_SaveAsClick(Sender: TObject);
begin
    surface_mainmenuExit( Self);

    currentTab_check();
    file_Save( currentTab_object, true);
end;

procedure Twnd_main.lbl_SaveClick(Sender: TObject);
begin
    surface_mainmenuExit( Self);

    currentTab_check();
    file_Save( currentTab_object);
end;

procedure Twnd_main.lst_recentTabsDblClick(Sender: TObject);
begin
    if lst_recentTabs.ItemIndex = -1
        then exit;

    recent_Open( lst_recentTabs.ItemIndex);
end;

procedure Twnd_main.lst_recentTabsItemFocusOff(_sender: TObject;
  _cur_itemIndex: Integer; _cur_itemState: TdxListBox.iccItem.icsState;
  _cur_itemData: TdxListBox.ictItemDataType; _new_itemIndex: Integer;
  _new_itemState: TdxListBox.iccItem.icsState;
  _new_itemData: TdxListBox.ictItemDataType);
begin
    if _new_itemIndex = -1
        then btn_recent_Restore.Enabled := False;
end;

procedure Twnd_main.lst_recentTabsItemFocusSet(_sender: TObject;
  _itemIndex: Integer; _itemState: TdxListBox.iccItem.icsState;
  _itemData: TdxListBox.ictItemDataType);
begin
    btn_recent_Restore.Enabled := True;
end;

procedure Twnd_main.lst_recentTabsItemPaint(_sender: TObject; _itemIndex: Integer;
  _itemState: TdxListBox.iccItem.icsState; _itemData: TdxListBox.ictItemDataType; _canvas: TCanvas;
  _rect: TRect);
var rec : iccRecentTab;
    tcs : iccTemplate_ColorScheme_ListBox_ItemPaint;
begin
   if _itemIndex >= FRecentTabs.Cnt
       then Exit;

    rec := FRecentTabs[_itemIndex];
    if rec = nil
        then exit;


    tcs := v_tcllsit_Normal;
//    if _itemIndex mod 2 = 1
//        then tcs := v_tcllsit_Normal2;

    if isFocused in _itemState
        then tcs := v_tcllsit_Focused;

    _rect.Left   := 2;
    rect_modify( _rect, 0, 2, -1, 1);

    // frame
    _canvas.Brush.Style := bsClear;
    _canvas.Pen.Color   := tcs.Border;
    _canvas.Rectangle( _rect.Left, _rect.Top, _rect.Right - 1, _rect.Bottom - 1);

    _canvas.Pen.Color   := tcs.Inner;
    _canvas.Rectangle( _rect.Left + 1, _rect.Top + 1, _rect.Right - 2, _rect.Bottom - 2);

    DrawGradient( _canvas.handle, _rect.left+2, _rect.top+2, _rect.Right - 2, _rect.Bottom - 3, tcs.Color1, tcs.Color2);


    // img
    _canvas.Draw( 18, _rect.Top + 18, img_tabRecent.Picture.Graphic);

    // index
    _canvas.Font.Color := tcs.Fn2;
    drawTextWithShadow( _canvas, IntToStr( _itemIndex + 1), Bounds( 40, _rect.Top + 19, 20, 20), tcs.TextShadow, dt_left or DT_END_ELLIPSIS);

    // title
    _canvas.Font.Color := tcs.Fn1;
    drawTextWithShadow( _canvas, rec.Title, Bounds( 80, _rect.Top + 18, 200, 20), tcs.TextShadow, dt_left or DT_END_ELLIPSIS or DT_NOPREFIX);
end;

procedure Twnd_main.lst_recentTabsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
    if lst_recentTabs.ItemIndex = -1
        then exit;

    if Key = VK_RETURN
        then recent_Open( lst_recentTabs.ItemIndex, not( ssCtrl in Shift));
end;

procedure Twnd_main.lst_recentTabsPaint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
begin
    if lst_RecentTabs.Cnt = 0
        then begin
                 ACanvas.Font.Color := v_tcllsit_Normal.Fn1;
                 drawTextWithShadow( acanvas, 'List is empty', Bounds( 0, 0, Rect.Right, Rect.Bottom), v_tcllsit_Normal.TextShadow, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
             end;
end;

procedure Twnd_main.Newtab1Click(Sender: TObject);
begin
    if FTab_Popup = -1
       then exit;


    tab_AddAndWriteToDB();
    FTab_Popup := -1;
end;

procedure Twnd_main.Renametab1Click(Sender: TObject);
var str : String;
begin
    if FTab_Popup = -1
       then exit;

    str := InputBox( 'Rename tab', 'Specify new name to the selected tab', tabs.Tabs[FTab_Popup]);
    tab_getObject( FTab_Popup).Title := str;
    tabs.SetTabName( FTab_Popup, str);
    tabs.Invalidate();


    FTab_Popup := -1;
end;

procedure Twnd_main.Closetab1Click(Sender: TObject);
begin
    if FTab_Popup = -1
       then exit;


    tab_CloseAndMoveToRecent( FTab_Popup);
    FTab_Popup := -1;
end;

procedure Twnd_main.surface_mainmenuExit(Sender: TObject);
begin
    surface_mainmenu.Hide();
end;

procedure Twnd_main.surface_mainmenuPaint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
begin
    drawGradient( ACanvas.Handle, 0, 0, Rect.Right, 50, $F0F0F0, clWhite);
    drawGradient( ACanvas.Handle, 0, Rect.Bottom - 20, Rect.Right, Rect.Bottom, clWhite, $F0F0F0);
end;

procedure Twnd_main.edit_menuPopup(Sender: TObject);
begin
    popupCheck();

    // check if selected
    item_edit_menu_Paste.Enabled     := FPopup_CurrentSynEdit.CanPaste;
    item_edit_menu_Undo.Enabled      := FPopup_CurrentSynEdit.CanUndo;
    item_edit_menu_Cut.Enabled       := FPopup_CurrentSynEdit.SelLength <> 0;
    item_edit_menu_Copy.Enabled      := item_edit_menu_Cut.Enabled;
    item_edit_menu_Delete.Enabled    := item_edit_menu_Cut.Enabled;
    item_edit_menu_SelectAll.Enabled := not (    ( FPopup_CurrentSynEdit.BlockBegin.Line = 1)
                                             and ( FPopup_CurrentSynEdit.BlockBegin.Char = 1)
                                             and ( FPopup_CurrentSynEdit.BlockEnd.Line = FPopup_CurrentSynEdit.Lines.Count)
                                             and ( FPopup_CurrentSynEdit.BlockEnd.Char = Length( FPopup_CurrentSynEdit.Lines[FPopup_CurrentSynEdit.Lines.Count-1]) + 1)
                                            );
end;

procedure TWnd_main.finit(_onDone: TProc; _onError : TProc<Exception>);

        procedure _proc();
        var ndx : integer;
            obj : iccTabObject;
        begin
            Include( FState, wsFinitInProgress);

            for ndx := 0 to tabs.Tabs.Count - 1 do
                begin
                    obj := tab_getObject( ndx);
                    if obj = nil
                        then Continue;

                    if not FTabManager.setInfo( obj.Id, tabs.Tabs[ndx], ndx)
                        then raise iccException.Create( 'finit() -> _proc() -> setInfo() failed');

                    if obj.SynEdit.Modified
                        then if not FTabManager.setData( obj.Id, obj.SynEdit.Text)
                                 then raise iccException.Create( 'finit() -> _proc() -> setData() failed');
                end;

            FTabManager.Destroy();

            Include( FState, wsFinitDone);
            Exclude( FState, wsFinitInProgress);

            _onDone();
        end;

begin
    Include( FState, wsFinitInProgress);

    FInitThread := iccThread.threadAdd
    (
        procedure ()
        var ndx : integer;
            obj : iccTabObject;
        begin
            for ndx := 0 to tabs.Tabs.Count - 1 do
                begin
                    obj := tab_getObject( ndx);
                    if obj = nil
                        then Continue;

                    // updating status
                    FFrame_Progress.Status_Set_threadContext( FInitThread, 'Processing tab: [b]' + obj.Title + '[/b]');

                    if not FTabManager.setInfo( obj.Id, tabs.Tabs[ndx], ndx)
                        then raise iccException.Create( 'finit() -> setInfo() -> failed');

                    if obj.SynEdit.Modified
                        then if not FTabManager.setData( obj.id, obj.SynEdit.Text)
                                 then raise iccException.Create( 'finit() -> setData() -> failed');

                    // Clear text here
                    if not FInitThread.doSync( Handle,
                        procedure ()
                        begin
                            if obj.SynEdit.Parent = nil
                                then obj.SynEdit.Parent := surface_main;
                            obj.SynEdit.Text := '';
                        end)
                        then raise iccexception.Create( 'doSync() -> Clearing and Destroying TSynEdit -> failed');
                end;

            for ndx := 0 to FRecentTabs.Cnt - 1 do
                begin
                    // updating status
                    FFrame_Progress.Status_Set_threadContext( FInitThread, 'Processing recent: [b]' + FRecentTabs[ndx].Title + '[/b]');

                    FRecentTabs[ndx].Destroy();
                end;

            // updating status
            FFrame_Progress.Status_Set_threadContext( FInitThread, 'Syncing with database');
            FTabManager.session_End();

            // updating status
            FFrame_Progress.Status_Set_threadContext( FInitThread, 'Optimizing database');
            FTabManager.vacuumPerform();

            // updating status
            FFrame_Progress.Status_Set_threadContext( FInitThread, 'Almost done');


            //
            FRecentTabs.Destroy();
            FTabMetaData.Destroy();
            FTabManager.Destroy();


            Include( FState, wsFinitDone);
            Exclude( FState, wsFinitInProgress);

            if TProc( _onDone) <> nil
                then if not FInitThread.doSync( Handle,
                                                procedure ()
                                                begin
                                                    _onDone();
                                                end
                                               )
                         then raise iccexception.Create( 'doSync() -> _onDone() -> failed');
        end
        ,
        procedure ( _e : Exception)
        begin
            if TProc( _onError) <> nil
                then if not FInitThread.doSync( Handle, procedure () begin _onError( _e); end)
                         then raise iccexception.Create( 'doSync() -> failed');
        end
    );

    FInitThread.resume();
end;

procedure Twnd_main.msg_wm_sync     ( var _msg : iccthread.icr_wm_sync);
begin
    try
        // safe check
        if iInterface( _msg.Proc^) is TInterfacedObject
            then _msg.Proc^();

        DefaultHandler( _msg);
        _msg.Result := 1;
    finally
        // swallow
        //raise iccException.Create( 'thread sync -> failed', iccException.c_prior_FATAL);
    end;
end;

procedure Twnd_main.msg_wm_dropfiles( var _msg : TWMDropFiles);
var amount : Integer;
    ndx    : Integer;
    str    : pWideChar;
begin
    if not ( wsInteractReady in FState)
        then exit;
    ////

    str := AllocMem( 255 * sizeof( char));


    amount := DragQueryFile( _msg.Drop, $FFFFFFFF, str, 255);
    for ndx := 0 to amount - 1 do
        begin
            DragQueryFile( _msg.Drop, ndx, str, 255);
            file_Load( nil, str);
        end;


    DragFinish( _msg.Drop);
    FreeMemory( str);
end;

procedure Twnd_main.___event_synEditChange( _Sender : TObject);
var synEdit : iccSynEdit;
begin
    if not( _Sender is iccSynEdit)
        then exit;
    synEdit := iccSynEdit( _Sender);

    synEdit.TabObject.FileSaved := false;
    autosave_Flow(); // disable
    autosave_Flow( True); // renew
end;

procedure Twnd_main.___event_synEditSpecialLineColors( _Sender: TObject; _Line: Integer; var _Special: Boolean; var _FG, _BG: TColor);
var syn : TSynEdit;
    src : String;
    tmp2 : String;
    tmp3 : String;
begin
    syn := TSynEdit( _Sender);

    src := syn.Lines[_Line-1];
    tmp2 := Copy( src, 0, 2);
    tmp3 := Copy( src, 0, 3);

    if pos( '>>', src) <> 0
        then begin // todo
                 _FG := clGreen;
                 _Special := true;
             end;

    if     ( pos( '<<',  src) <> 0)
        or ( pos( '>>>', src) <> 0)
        then begin // done
                 _FG := clSilver;
                 _Special := true;
             end;


    if tmp2 = '//'
        then begin // like a comment
                 _FG := clSilver;
                 _Special := true;
             end;

    if tmp2 = '/!'
        then begin // some important
                 _FG := clRed;
                 _Special := true;
             end;

    if tmp3 = '---'
        then begin
                 _FG := clGray;
                 _BG := $DFDFDF;
                 _Special := true;
             end;
end;

procedure Twnd_main.___event_synEditOnReplaceText(       _Sender           : TObject;
                                                   const _Search, _Replace : string;
                                                         _Line  , _Column  : Integer;
                                                   var   _Action           : TSynReplaceAction
                                                 );
begin
    case MessageBox( Handle,
                     pchar( Format( c_prompt_Replace, [_Search, _Replace])),
                     c_app_name,
                     MB_YESNOCANCEL or MB_ICONQUESTION or MB_TASKMODAL
                   )
    of
        ID_YES
            : _Action := raReplace;
        ID_NO
            : begin
                  _Action := raSkip;
              end;
        ID_CANCEL
            : _Action := raCancel;
    end;
end;

procedure Twnd_main.___event_synEditGutterClick( _Sender: TObject;
                                                 _Button: TMouseButton;
                                                 _X,
                                                 _Y,
                                                 _Line: Integer;
                                                 _Mark: TSynEditMark
                                               );
var se : iccSynEdit;
    bc : TBufferCoord;
begin
    se := iccSynEdit( _sender);

    if se.SelAvail
        then exit;


    bc.Char := 0;
    bc.Line := _line;
    se.BlockBegin := bc;
    bc.Char := MaxInt;
    se.BlockEnd   := bc;
end;

procedure Twnd_main.___event_editOnKeyPress( _Sender: TObject; var _Key: Char);
begin
    // overwhelm beep sound
    if    ( _Key = #13)
       or ( _Key = #10)
        then _Key := #0;
end;

procedure Twnd_main.key_Preview( _Sender: TObject; var _Key: Word; _Shift: TShiftState);
type
    ictCharWORD =
        record
            case Boolean of
                False : ( C : Char );
                True  : ( W : Word );
        end;

    function mk( _c : Char) : ictCharWORD; overload; inline;
    begin
        result.C := _c;
    end;

    function mk( _w : Word) : ictCharWORD; overload; inline;
    begin
        result.W := _w;
    end;

    function checkExpression( const _k : Array of ictCharWORD; _s : TShiftState) : Boolean; overload;
    var len : byte;
    begin
        result := false;

        // shift mismatch -> get out of here
        if _shift <> _s
            then exit;

        // check keys matching
        for len := 0 to High( _k) do
            if _key = _k[len].W
                then exit( true);
    end;

begin
    if not ui_interactable()
        then exit();

    currentTab_check();

    // search
    if checkExpression( [mk(VK_F3)], [])
        then begin
                 do_search( true);
                 _key := 0;
                 exit;
             end;

    // global search
    if checkExpression( [mk('Q')], [ssCtrl])
        then begin
                 dialog_globalSearch();
                 _key := 0;
                 exit;
             end;


    // search dialog
    if checkExpression( [mk('F')], [ssCtrl])
        then begin
                 dialog_search();
                 _key := 0;
                 exit;
             end;

    // global search
    if checkExpression( [mk('E')], [ssCtrl])
        then begin
                 img_recentClick( self);
                 _key := 0;
                 exit;
             end;

    // replace dialog
    if checkExpression( [mk('R'), mk('H')], [ssCtrl])
        then begin
                 dialog_replace();
                 _key := 0;
                 exit;
             end;

    // new tab
    if checkExpression( [mk('T'), mk('N')], [ssCtrl])
        then begin
                 tab_AddAndWriteToDB();
                 _key := 0;
                 exit;
             end;

    // close tab
    if checkExpression( [mk('W'), mk(VK_F4)], [ssCtrl])
        then begin
                 do_tab_Close( FTab_Current);
                 _key := 0;
                 exit;
             end;

    // close all tabs
    if checkExpression( [mk('W'), mk(VK_F4)], [ssCtrl, ssAlt])
        then begin
                 do_tab_CloseAllBut( FTab_Current);
                 _key := 0;
                 exit;
             end;

    // save
    if checkExpression( [mk('S')], [ssCtrl])
        then begin
                 file_Save( currentTab_object);
                 _key := 0;
                 exit;
             end;

    // save as
    if checkExpression( [mk('S')], [ssCtrl, ssAlt])
        then begin
                 file_Save( currentTab_object, true);
                 _key := 0;
                 exit;
             end;

    // load
    if checkExpression( [mk('L')], [ssCtrl])
        then begin
                 file_Load( currentTab_object);
                 _key := 0;
                 exit;
             end;

    // switch tab
    if checkExpression( [mk(VK_TAB)], [ssCtrl])
        then begin
                 tab_Switch( c_tabSwitch_Next);
                 exit;
             end;

    // switch tab | backward
    if checkExpression( [mk(VK_TAB)], [ssCtrl, ssShift])
        then begin
                 tab_Switch( c_tabSwitch_Prev);
                 _key := 0;
                 exit;
             end;
end;

procedure Twnd_main.btn_recent_RestoreAllClick(Sender: TObject);
var ndx : integer;
begin
    for ndx := 0 to FRecentTabs.Cnt - 1 do
        begin
            tab_Load( FRecentTabs[0].TID);
            recent_Del( 0);
        end;
end;

procedure Twnd_main.btn_recent_RestoreClick(Sender: TObject);
begin
    lst_recentTabs.OnDblClick( Self);
end;

procedure Twnd_main.___event_tabAdd( _Sender : TObject);
begin
    tab_AddAndWriteToDB();
end;

procedure Twnd_main.___event_tabClose( _Sender : TObject; _index : Integer; var _Close : Boolean);
begin
    _Close := False;

    do_tab_Close( _index);
end;

procedure Twnd_main.___event_tabSetActive( _Sender : TObject; _activeTab : Integer);
var obj     : iccTabObject;
    strlst  : TSynEditStringList;
    thd     : iciThread;

    frmProgress : Tframe_ProgressNotifier;

    proc_body  : iccThread.ictThreadStagingProc;
    proc_error : iccThread.ictThreadOnErrorProc;

    proc_showTab : TProc;
    proc_setDataAndShowTab : TProc;

    timeout    : dword;

    meta       : iccTabsMetaData.iccItem;
begin
    // hide
    if FTab_Last <> -1
        then begin
                 obj := tab_getObject( FTab_Last);

                 // save meta data
                 tab_pushMetaData( FTab_Last);
                 //

                 obj.SynEdit.Hide();
                 obj.SynEdit.Parent := nil; // removing from surface
             end;

//    // show
//    if tabs.ActiveTab <> -1
//        then begin
    if tabs.ActiveTab = -1
        then exit;

    currentTab_check();
    obj := currentTab_object();

    //
    obj.SynEdit.Highlighter := editor_links_highlight;
    editor_links_opener.Editor := obj.SynEdit;
    //

    proc_showTab :=
        procedure()
        begin
            if obj.SynEdit.Parent <> surface_main
                then obj.SynEdit.Parent := surface_main; // adding to surface
            obj.SynEdit.Show();
            obj.SynEdit.BringToFront();

            ui_enabled(); // enabled

            if obj.SynEdit.CanFocus()
                then obj.SynEdit.SetFocus();

            windows.SetFocus( obj.SynEdit.Handle);


            // load meta data
            meta := FTabMetaData.getByLinkID( obj.Id);
            if meta <> nil
                then begin
                         obj.SynEdit.CaretX   := meta.caretX;
                         obj.SynEdit.CaretY   := meta.caretY;
                         obj.SynEdit.TopLine  := meta.topLine;
                         obj.SynEdit.SelStart := meta.selStart;
                         obj.SynEdit.SelEnd   := meta.selEnd;
                     end;
            //


            // search window
            if Twnd_Search.isAvail()
                then Twnd_Search.do_Update_TabName( obj.Title);

            // replace window
            if Twnd_Replace.isAvail()
                then Twnd_Replace.do_Update_TabName( obj.Title);

            FTab_Last := tabs.ActiveTab;

            //
            iccTimeout.unset( timeout);
            Tframe_ProgressNotifier.release( frmProgress);

            // nil ref
            proc_showTab := nil;
        end;


    if obj.Loaded
        then begin // just switch
                 proc_showTab();
                 exit;
             end;

    //
    ui_enabled( false); // disabled ui
    //

    proc_setDataAndShowTab :=
        procedure()
        begin
            // set loaded data
            obj.SynEdit.replaceLines( strlst);
            obj.Loaded := true; // we are loaded now

            proc_showTab();

            // nil ref
            proc_setDataAndShowTab := nil;
        end;


    ///////////////////////////////////////////////////////////////
    timeout := iccTimeout.set__( 200,
        procedure ()
        begin
            Tframe_ProgressNotifier.checkCreate( frmProgress, Self, Self);
            frmProgress.Status_Set_threadContext( thd, 'Loading content and setting it up...');
            frmProgress.Show();
            frmProgress.Update();
        end
    );
    //


    proc_body :=
        procedure ()
        var fs : TFileStream;
        begin
            strlst := TSynEditStringList.Create( obj.SynEdit.ExpandAtWideGlyphs);

            //
            if obj.FileAttached
                then begin // load from file
                         //strlst := TStringList.Create();
                         //strlst.LoadFromFile( obj.FileFullpath, TEncoding.UTF8);
                         fs := TFileStream.Create( obj.FileFullpath, fmOpenRead);

                         strlst.LoadFromStream( fs, TEncoding.UTF8);

                         fs.Destroy();
                     end
                else begin // load from db
                         FTabManager.getData( obj.Id, strlst);
                     end;
            //



            if not thd.doSync( handle, proc_setDataAndShowTab)
                then raise iccException.Create( '___event_tabSetActive() -> proc_body() -> doSync() failed');

            // nil ref
            proc_body := nil;
            proc_error := nil;

            //
            thd.set_AutoDestroy();
            thd := nil;
        end;

    proc_error :=
        procedure ( _exc : Exception)
        begin
            MessageBox( handle, pchar( _exc.Message), c_app_name, MB_TASKMODAL);
        end;


    thd := iccThread.threadAdd( proc_body, proc_error);
    thd.set_AutoDestroy( false);
    thd.resume();
end;

function Twnd_main.tab_getObject( _ndx : Integer) : iccTabObject;
begin
    result := nil;

    if _ndx >= tabs.Tabs.Count
        then exit;

    result := iccTabObject.link( tabs.Tabs.Objects[_ndx])
end;

function Twnd_main.tab_New( _title : String = ''; _data : String = ''; _loaded : Boolean = false; _modified : Boolean = False; _focus : Boolean = false) : iccTabObject;
var syned : iccSynEdit;
begin
    // creating synedit
    syned                 := iccSynEdit.Create( surface_main);
    syned.PopupMenu       := edit_menu;
    syned.SearchEngine    := FSearch_Engine;
    syned.Modified        := _modified;
    syned.Text            := _data;

    syned.TabObject.Title := _title;

    // monitor changes and some other event
    syned.OnChange            := ___event_synEditChange;
    syned.OnSpecialLineColors := ___event_synEditSpecialLineColors;
    syned.OnReplaceText       := ___event_synEditOnReplaceText;
    syned.OnGutterClick       := ___event_synEditGutterClick;


    //////
    result := syned.TabObject; // dont forget to retrieve valid result
    result.Loaded := _loaded;
    //////

    // reveal
    tabs.AddObject_focus( _title, result, _focus);
end;

function Twnd_main.tab_Load( _id : Integer) : Boolean;
var titl : String;
{
    data : String;
}
    orde : Integer;
    dele : Boolean;
    obje : iccTabObject;
begin
{
    result := false; // default
    if    not ( FTabManager.getInfo( _id, titl, orde, dele))
       or not ( FTabManager.getData( _id, data))
        then exit;


    obje := tab_New( titl, data);
    FTabManager.Mark( _id, false);
    obje.Id := _id;

    result := true;
}
    result := false;
    if not FTabManager.getInfo( _id, titl, orde, dele)
        then exit;

    obje := tab_New( titl);
    FTabManager.Mark( _id, false);
    obje.Id := _id;

    result := true;
end;

function Twnd_main.tab_Close( _ndx : Integer) : Boolean; // closed if true, false error occured
var obj : iccTabObject;
begin
    result := false; // default
    if _ndx >= tabs.Tabs.Count
        then exit;

    //
    obj := tab_getObject( _ndx);

    obj.SynEdit.Parent := surface_main; // Треба шоб було ці дві строкі, шоб можна було убить нормально сінедіт. Без цього крешиться. Вивалюється Invalid Window Handle або Access Denied
    obj.SynEdit.Show();                 // Шоб зловить цей баг - пишем шось в одній вкладці, переключаєм її і закриваєм прогу
    obj.SynEdit.Text := '';

        // remove events
        editor_links_opener.Editor := nil; // added here to avoid exceptions

    try
         if surface_main.CanFocus
             then surface_main.SetFocus();

         obj.SynEdit.Destroy();
    finally
    end;
    obj.Destroy();
    //

    FTab_Last := -1;
    tabs.DeleteTab( _ndx);

    result := true;
end;

function Twnd_main.tab_Switch( _ndx : Integer) : Boolean;
begin
    result := true;

    // cant move while there is only one tab
    if tabs.Tabs.Count = 1
        then exit;

    // cant move over the real tabs count
    if _ndx >= tabs.Tabs.Count
        then exit( false);

    case _ndx of
        c_tabSwitch_Next
         : begin
               _ndx := FTab_Current + 1;
               if _ndx >= tabs.Tabs.Count
                   then _ndx := 0;
           end;

        c_tabSwitch_Prev
         : begin
               _ndx := FTab_Current - 1;
               if _ndx < 0
                   then _ndx := tabs.Tabs.Count - 1;
           end;
    end;

    tabs.ActiveTab := _ndx;
    currentTab_check();
end;

function Twnd_main.tab_check_0AutoAdd( _firstRun : Boolean = false) : Boolean;
var obj : iccTabObject;
    tmp : Integer;
begin
    result := true;

    try
        if tabs.Tabs.Count = 0
            then begin
                     if _firstRun
                         then obj := tab_New( 'Welcome to ' + c_app_name, c_firstrun_exampleText, true, true, true)
                         else obj := tab_New( 'Empty', '', true, false, true);

                     if obj <> nil
                         then begin
                                  tmp := FTabManager.Add( 'Empty');
                                  if tmp = -1
                                      then Exit( false);

                                  //obj[c_alias_id] := tmp;
                                  obj.Id := tmp;
                              end;
                 end;
    except
        result := false;
    end;
end;

function Twnd_main.tab_check_AttachedToFileModified( _ndx : Integer) : Integer;
var obj : iccTabObject;
begin
    result := 0; // default
    obj := tab_getObject( _ndx);

    if     obj.FileAttached
       and not obj.FileSaved
           then case MessageBox( Handle, c_prompt_saveChanges, c_app_name, MB_YESNOCANCEL or MB_ICONQUESTION or MB_TASKMODAL) of
                    ID_YES // save changes
                     : result := 1; // робить зміни
                    ID_NO // ignore changes
                     : result := 0; // не робить зміни
                    ID_CANCEL // abort
                     : result := -1;
                end;
end;

procedure Twnd_main.tabsGetImageIndex(Sender: TObject; Tab: Integer; var Index: Integer);
var obj : iccTabObject;
begin
    Index := 0;

    obj := tab_getObject( tab);
    if obj = nil
        then exit;

    if obj.FileAttached
        then Index := 1;
end;

procedure Twnd_main.tabsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var ndx : integer;
begin
    ndx := tabs.GetTabAtXY( x, y);

    if ndx <> - 1
        then tabs.PopupMenu := tabMenu
        else tabs.PopupMenu := nil;

    FTab_Popup := ndx;
end;

function Twnd_main.tab_WriteToDB( _title : String; _data : String = '') : Integer;
begin
    try
        result := FTabManager.Add( _title);

        if _data <> ''
            then if not FTabManager.setData( result, _data)
                     then begin
                              // rollback
                              if not FTabManager.Del( result)
                                  then raise iccException.Create( 'tab_WriteToDB() -> setData() failed -> rollback failed.');

                              result := -1;
                          end;
    except
        result := -1;
    end;
end;

function Twnd_main.tab_AddAndWriteToDB( _title : String = ''; _data : String = ''; _modified : Boolean = False) : iccTabObject;
var id  : Integer;
begin
    if _title = ''
        then _title := DateToStr( Now, c_default_Format) + ' — ' + TimeToStr( Time, c_default_Format);

    id := tab_WriteToDB( _title);

    if id = -1
        then raise iccException.Create( 'tab_AddAndWriteToDB() -> id = -1');

    result := tab_New( _title, _data, true, _modified, true);
    if result = nil
        then raise iccException.Create( 'tab_AddAndWriteToDB() -> result = nil');

    result.Id := id;
end;

function Twnd_main.tab_CloseAndMoveToRecent( _ndx : Integer) : Boolean;
var obj : iccTabObject;
    edt : iccSynEdit;
    tid : Integer;
    tit : String;

    function checkModifiedWrite() : Boolean;
    begin
        result := not edt.Modified or FTabManager.setData( tid, edt.Text);
    end;

begin
    result := true;


    // save meta data
    tab_pushMetaData( _ndx);
    //


    obj := tab_getObject( _ndx);
    edt := obj.SynEdit;
    tid := obj.Id;
    tit := obj.Title;

    // should we write to db
    if checkModifiedWrite()
        then if not tab_Close( _ndx)
                 then exit( false);

    if    ( not FTabManager.Mark( tid))
       or ( not FTabManager.setInfo( tid, tit, -1))
       or ( not tab_check_0AutoAdd())
        then exit( false);

    recent_Add( tid, tit);
end;

function Twnd_main.tab_CloseAndMoveToRecent_AllBut( _exc : Integer) : Boolean;
var ndx : integer;
begin
    result := false;

    if tabs.Tabs.Count < 1
        then exit;

    for ndx := tabs.Tabs.Count - 1 downto 0 do
        if _exc <> ndx
            then if not tab_CloseAndMoveToRecent( ndx)
                     then exit;

    result := true;
end;

procedure Twnd_main.tab_pushMetaData( _tabIndex : Integer);
var obj : iccTabObject;
    itm : iccTabsMetaData.iccItem;
begin
    obj := tab_getObject( _tabIndex);
    itm := FTabMetaData.put( obj.Id);

    if not obj.Loaded
        then exit;

    itm.caretX   := obj.SynEdit.CaretX;
    itm.caretY   := obj.SynEdit.CaretY;
    itm.topLine  := obj.SynEdit.TopLine;
    itm.selStart := obj.SynEdit.SelStart;
    itm.selEnd   := obj.SynEdit.SelEnd;
end;

procedure Twnd_main.tab_collectMetaData();
var ndx : Integer;
    dob : iccDynamicObject;
    tob : iccTabObject;
    rob : iccRecentTab;
    itm : iccTabsMetaData.iccItem;
begin
//     FTabMetaData.clr(); // do not simply clear. find and remove nonexistent. In case of simple Clear(), I will lose all the data after launch


     dob := iccDynamicObject.Create();

     // generate IDs from tabs
     for ndx := 0 to tabs.Tabs.Count - 1 do
         begin
             tob := tab_getObject( ndx);

             dob[inttostr( tob.Id)] := dword( tob);
         end;

     // add IDs from recents
     for ndx := 0 to FRecentTabs.Cnt - 1 do
         begin
             rob := FRecentTabs[ndx];

             dob[inttostr( rob.TID)] := dword( rob);
         end;


     // filter
     for ndx := FTabMetaData.cnt - 1 downto 0 do
         begin
             itm := FTabMetaData.getByIndex( ndx);

             if not dob.IDExist( inttostr( itm.linkId))
                 then FTabMetaData.del( ndx);
         end;

     dob.Destroy();


     // fill
     for ndx := 0 to tabs.Tabs.Count - 1 do
         tab_pushMetaData( ndx);
end;

function Twnd_main.do_tab_Close   ( _ndx : Integer) : Integer;
var obj : iccTabObject;
begin
    result := 0;

    obj := tab_getObject( _ndx);
    if obj = nil
        then exit;

    if obj.FileAttached
        then begin // check if we should write changes to file
                 if not obj.FileSaved
                     then case MessageBox( Handle,
                                           pchar( 'Tab: "' + obj.Title + '"' +
                                                  #13 + 'Data was modified. Do you want to apply changes to file "' + ExtractFileName( obj.FileFullpath) + '"?' +
                                                  #13#13 + 'Path: "' + obj.FileFullpath + '"'
                                                ),
                                           c_app_name,
                                           MB_YESNOCANCEL or MB_ICONQUESTION or MB_TASKMODAL
                                         )
                          of
                              ID_YES
                                  : begin // save to file
                                        file_Save( obj);
                                    end;
                              ID_NO
                                  : begin // do nothing
                                    end;
                              ID_CANCEL
                                  : begin
                                        exit( -1);
                                    end;
                          end;
             end;

    if obj.FileDragDrop
        then begin // file opened by drag'n'drop.
                 case  MessageBox( Handle,
                                   pchar( 'Tab: "' + obj.Title + '"'#13 + 'Do you want to keep files'' content internally?'),
                                   c_app_name,
                                   MB_YESNOCANCEL or MB_ICONQUESTION or MB_TASKMODAL
                                 )
                 of
                     ID_YES
                        : begin // save to db and move to recent
                              obj.id := tab_WriteToDB( obj.Title, obj.SynEdit.Text); // !!!
                              if obj.id = -1
                                  then raise iccException.Create( 'tab_WriteToDB() -> failed');

                              if not tab_CloseAndMoveToRecent( _ndx)
                                  then raise iccException.Create( 'tab_CloseAndMoveToRecent() -> failed');
                          end;
                     ID_NO
                        : begin // just close the tab
                              if not tab_Close( _ndx)
                                  then raise iccException.Create( 'tab_Close() -> failed');
                          end;
                     ID_CANCEL
                        : begin // abort
                              exit( -1);
                          end;
                 end;


                 result := 1; // done
             end
        else begin
                 // just move to recent
//                 case tab_check_AttachedToFileModified( _ndx) of
//                     -1 : exit( -1); // aborted
//                      0 : ; // do not save
//                      1 : file_Save( tab_getObject( _ndx)); // save
//                 end;

                 if not tab_CloseAndMoveToRecent( _ndx)
                     then raise iccException.Create( 'tab_CloseAndMoveToRecent() -> failed');


                 result := 1; // everything is ok
             end;
end;

function Twnd_main.do_tab_CloseAllBut( _exc : Integer) : Integer;
var ndx : integer;
begin
    result := 1;

    if tabs.Tabs.Count = 1
        then exit;

    for ndx := tabs.Tabs.Count - 1 downto 0 do
        if ndx <> _exc
            then begin
                     result := do_tab_Close( ndx);
                     if result <> 1
                         then exit;
                 end;

end;

procedure Twnd_main.recent_UpdateList();
var ndx : integer;
begin
    lst_recentTabs.Clr;

    for ndx := 0 to FRecentTabs.Cnt - 1 do
        lst_recentTabs.Add( DWORD( FRecentTabs[ndx]), iccRecentTab.c_height);

    lbl_recent_Total.Caption := IntToStr( FRecentTabs.Count);
end;

procedure Twnd_main.recent_Open( _index : Integer; _focus : Boolean = true);
var tid : Integer;
begin
    tid := FRecentTabs[_index].TID;
    recent_Del( _index);

    tab_Load( tid);

    // focus
    if _focus
        then tabs.ActiveTab := tabs.Tabs.Count - 1;
end;

procedure Twnd_main.recent_Add( _tid : Integer; _title : String; _insertAt0 : Boolean = true);
var rec : iccRecentTab;
begin
    rec := iccRecentTab.Create( _tid, _title);

    if _insertAt0
        then begin
                 FRecentTabs.Ins( 0, rec);
                 lst_recentTabs.Ins( 0, DWORD( rec), iccRecentTab.c_height);
             end
        else begin
                 FRecentTabs.Add( rec);
                 lst_recentTabs.Add(    DWORD( rec), iccRecentTab.c_height);
             end;

    lbl_recent_Total.Caption := IntToStr( FRecentTabs.Count);
    btn_recent_RestoreAll.Enabled := True;
end;

procedure Twnd_main.recent_Del( _ndx : Integer);
begin
    lst_recentTabs.Del( _ndx);

    FRecentTabs[_ndx].Destroy();
    FRecentTabs.Del( _ndx);

    lbl_recent_Total.Caption := IntToStr( FRecentTabs.Count);
    if FRecentTabs.Count = 0
        then btn_recent_RestoreAll.Enabled := False;
end;

procedure Twnd_main.systemMenu( _enabled : Boolean = true);
begin
    if _enabled
        then BorderIcons := BorderIcons + [biSystemMenu, biMinimize, biMaximize]
        else BorderIcons := BorderIcons - [biSystemMenu, biMinimize, biMaximize];
end;

procedure Twnd_main.popupCheck();
var edit : TSynEdit;
begin
    edit := TSynEdit( edit_menu.PopupComponent);
    if not ( edit is TSynEdit)
        then raise iccException.Create( 'popupCheck() -> Class mismatch');

    // remember
    FPopup_CurrentSynEdit := edit;
end;

function Twnd_main.dialog_save_requestFile( out _str : String; _title : String = '') : Boolean;
var fDia    : TSaveDialog;
    FDia_ex : TFileSaveDialog;
begin
    if iccVersion_Windows.Major >= 6
        then begin // Vista and newer
                 FDia_ex := nil;
                 try
                     FDia_ex := TFileSaveDialog.Create( self);
                     FDia_ex.Title := _title;
                     fileTypes_make( FDia_ex.FileTypes);
                     FDia_ex.Options := FDia_ex.Options + [fdoOverWritePrompt, fdoPathMustExist];

                     result := FDia_ex.Execute( Handle);
                     if result
                         then _str := util_ValidateFilename( FDia_ex.FileName, '.txt');
                 finally
                     FDia_ex.Free();
                 end;
             end
        else begin // xp ? :)
                 FDia := nil;
                 try
                     FDia := TSaveDialog.Create( self);
                     FDia.Title := _title ;
                     FDia.Filter := c_files_filter;
                     FDia.Options := FDia.Options + [ofOverWritePrompt, ofPathMustExist];

                     result := FDia.Execute( Handle);
                     if result
                         then _str := util_ValidateFilename( FDia.FileName, '.txt');
                 finally
                     FDia.Free();
                 end;
             end;
end;

function Twnd_main.dialog_load_requestFile( out _str : String; _title : String = '') : Boolean; // same
var fDia    : TOpenDialog;
    fDia_ex : TFileOpenDialog;
begin
    if iccVersion_Windows.Major >= 6
        then begin // Vista and newer
                 fDia_ex := nil;
                 try
                     fDia_ex := TFileOpenDialog.Create( self);
                     fDia_ex.Title := _title;
                     fileTypes_make( fDia_ex.FileTypes);
                     //fDia_ex.Options

                     result := fDia_ex.Execute( Handle);
                     if result
                         then _str := fDia_ex.FileName;
                 finally
                     fDia_ex.Free();
                 end;
             end
        else begin // xp and lower
                 fDia := nil;
                 try
                     fDia := TOpenDialog.Create( self);
                     fDia.Title := _title;
                     fDia.Filter := c_files_filter;
                     //fDia.Options

                     result := fDia.Execute( Handle);
                     if result
                         then _str := fDia.FileName;
                 finally
                     fDia.Free();
                 end;
             end;
end;

procedure Twnd_main.file_Save( _tabObj : iccTabObject; _saveAs : Boolean = false);
var str : String;
begin
    // check if file is already attached
    if _tabObj.FileAttached and not _saveAs
        then begin // save
                 //raise Exception.Create('Error Message');
                 // do nothing :)
             end
        else begin // save as
                 if not dialog_save_requestFile( str)
                     then exit;

                 _tabObj.file_attach( str);
             end;

    if not util_StringToFile( _tabObj.SynEdit.Text, _tabObj.FileFullpath)
        then begin
                 MessageBox( Handle, c_operation_save_Error, c_app_name, MB_OK or MB_ICONWARNING or MB_TASKMODAL);
                 Exit();
             end;

    //
    _tabObj.FileSaved := true;
end;

procedure Twnd_main.file_Load( _tabObj : iccTabObject = nil; _filename : String = '');
var str : String;
begin
    if     ( _tabObj <> nil )
       and ( _tabObj.SynEdit.Modified or ( _tabObj.SynEdit.Text <> ''))
       and ( not _tabObj.FileSaved )
        then if messagebox( 0, c_prompt_loadClarification, c_app_name, MB_YESNO or MB_ICONQUESTION or MB_TASKMODAL) = ID_NO
                 then exit;


    if _filename = ''
        then if not dialog_load_requestFile( _filename)
                 then exit;


    if not util_FileToString( str, _filename)
        then begin
                 MessageBox( 0, c_operation_load_Error, c_app_name, mb_ok or MB_ICONWARNING or MB_TASKMODAL);
                 Exit();
             end;

    if _tabObj = nil
        then begin // create a new tab
                 _tabObj              := tab_New( ExtractFileName( _filename), str);
                 _tabObj.file_attach( _filename);
                 _tabObj.FileDragDrop := true;
                 _tabObj.FileSaved    := true; // default state.
             end
        else begin // use existing
                 _tabObj.SynEdit.Text := str;
                 _tabObj.SynEdit.Modified := true;

                 if _tabObj.FileAttached
                     then _tabObj.file_attach( _filename)
                     else _tabObj.file_attach( _filename, true);
             end;
end;

procedure Twnd_main.___event_container_paint_Generic( _Sender: TObject; _Rect: TRect; _ACanvas: TCanvas; _AFont: TFont);
begin
    if not ( _Sender is TdxContainer)
        then raise iccException.Create( '___event_container_paint_Generic() -> Class mismatch. _Sender is not valid');

    drawGradient( _ACanvas.Handle, 1, 1, _Rect.Right, 50, clWhite, $F0F0F0);
end;

procedure Twnd_main.currentTab_check();
begin
    FTab_Current := tabs.ActiveTab;
end;

function Twnd_main.currentTab_object() : iccTabObject;
begin
    result := iccTabObject.link( tabs.Tabs.Objects[FTab_Current]);
end;

function Twnd_main.currentTab_edit() : iccSynEdit;
begin
    result := currentTab_object().SynEdit;
end;

procedure Twnd_main.autosave_do();
var th : iciThread;
    timeout : DWORD;
    obj : iccTabObject;

    frmProgress : Tframe_ProgressNotifier;
begin
    Include( FState, wsInitInProgress);
    Exclude( FState, wsInteractReady);

    ui_enabled( false);
    Tframe_ProgressNotifier.checkCreate( frmProgress, Self, Self);
    timeout := iccTimeout.set__( 300,
        procedure ()
        begin
            frmProgress.Show();
            frmProgress.Update();
        end
    ); // show only on slow operations


    th := iccThread.threadAdd
    (
        procedure ()
        var ndx : integer;
        begin
            // updating tabs` content
            for ndx := 0 to tabs.Tabs.Count - 1 do
                begin
                    obj := tab_getObject( ndx);
                    if obj = nil
                        then Continue;

                    // updating status
//                    FFrame_Progress.Status_Set_threadContext( th, 'Processing tab: [b]' + obj.Title + '[/b]');

// походу це не треба робить кожен раз при автосейві
//                    if not FTabManager.setInfo( obj.Id, tabs.Tabs[ndx], ndx)
//                        then raise iccException.Create( 'autosave_do() -> (?) -> processTab() -> setInfo() -> failed');

                    if     ( not obj.FileAttached)
                       and ( obj.SynEdit.Modified)
                        then begin
                                 // updating status
                                 frmProgress.Status_Set_threadContext( th, 'Processing tab: [b]' + obj.Title + '[/b]');

                                 if not FTabManager.setData( obj.id, obj.SynEdit.Text)
                                     then raise iccException.Create( 'autosave_do() -> (?) -> processTab() -> setData() -> failed');

                                 obj.SynEdit.Modified := false; /// !!!
                             end;
                end;



            // flush all accumulated data if needee
            if FTabManager.isCommitNeeded()
                then begin
                         // updating status
                         frmProgress.Status_Set_threadContext( th, 'Syncing with database');
                             FTabManager.session_End();

                         // updating status
                         frmProgress.Status_Set_threadContext( th, 'Restoring session');
                             FTabManager.session_Start();
                     end;


            Exclude( FState, wsInitInProgress);
            Include( FState, wsInteractReady);

            th.doSync( Handle,
                procedure ()
                begin
                    iccTimeout.unset( timeout);
                    Tframe_ProgressNotifier.release( frmProgress);
                    ui_enabled();
                end
            );
        end
     );

     th.resume();
end;

procedure Twnd_main.autosave_loop( _delay : Integer; _startOrStop : Boolean = true);
begin
    if _startOrStop
        then begin
                 FAutosave_Timeout_Forced := iccTimeout.set__( _delay,
                                                                procedure ()
                                                                begin
                                                                    autosave_do();
                                                                    autosave_loop( _delay);
                                                                end
                                                            );
             end
        else begin
                 iccTimeout.unset( FAutosave_Timeout_Forced);
             end;
end;

procedure Twnd_main.autosave_Flow( _set : Boolean = false);
begin
    if _set
        then begin
                 FAutosave_Timeout_Flow := iccTimeout.set__
                     ( c_database_autosave_Flow,
                       procedure()
                       begin
                           autosave_do();
                       end
                     );
             end
        else begin
                 iccTimeout.unset( FAutosave_Timeout_Flow);
             end;
end;

procedure Twnd_main.ui_enabled( _enabled : boolean = true);
begin
    // fix annoying bug
    if Application.ModalLevel <> 0
        then exit;

    Self.Enabled := _enabled;
end;

function Twnd_main.ui_interactable() : Boolean;
begin
    result := true;

    if    ( not enabled )
       or ( not ( wsInteractReady in FState))
        then exit( false);
end;

procedure Twnd_main.do_search( _useCurrent : Boolean = false; _string : String = '');
begin
    if not _useCurrent
        then FTempString_Search := _string;

    if FTempString_Search = ''
        then exit;

    currentTab_check();
    if currentTab_edit.SearchReplace( FTempString_Search, '', []) = 0
        then MessageBox( 0, pchar( Format( c_operation_search_Error, [FTempString_Search])), c_app_name, MB_OK or MB_ICONINFORMATION or MB_TASKMODAL);
end;

procedure Twnd_main.do_replace( _source, _destination : String; _replaceAll : Boolean = false);
var opt : TSynSearchOptions;
begin
    FTempString_Search  := _source;
    FTempString_Replace := _destination;

    if FTempString_Search = ''
        then exit;

    opt := [ssoPrompt, ssoReplace];
    if _replaceAll
        then include( opt, ssoReplaceAll);

    currentTab_check();
    if currentTab_edit.SearchReplace( FTempString_Search, _destination, opt) = 0
        then begin
                 MessageBox( 0, pchar( Format( c_operation_search_Error, [FTempString_Search])), c_app_name, MB_OK or MB_ICONINFORMATION or MB_TASKMODAL);
             end;
end;

procedure Twnd_main.dialog_globalSearch();
begin
    wnd_globalSearch := Twnd_globalSearch.Create( self);
    wnd_globalSearch.ShowModal();
    wnd_globalSearch.Destroy();
end;

procedure Twnd_main.dialog_search();
begin
    currentTab_check();

    TWnd_Search.do_Create( Self);
    Twnd_Search.do_Update_SearchString( FTempString_Search);
    Twnd_Search.do_Update_TabName( currentTab_object.Title);
    Twnd_Search.do_attachEvent_onFindNext
        ( procedure ( _string : String)
          begin
              do_search( false, _string);
          end
        );
    TWnd_Search.do_Show();
end;

procedure Twnd_main.dialog_replace();
begin
    currentTab_check();

    TWnd_Replace.do_Create( Self);
    TWnd_Replace.do_Update_String_Search ( FTempString_Search);
    Twnd_replace.do_Update_String_Replace( FTempString_Replace);
    TWnd_Replace.do_Update_TabName( currentTab_object.Title);
    TWnd_Replace.do_attachEvent_onFindNext
        ( procedure ( _source, _destination : String)
          begin
              do_replace( _source, _destination);
          end
        );

    TWnd_Replace.do_attachEvent_onReplaceAll
        ( procedure ( _source, _destination : String)
          begin
              case MessageBox( Handle,
                               pchar( Format( c_prompt_ReplaceAll, [_source, _destination])),
                               c_app_name,
                               MB_YESNO or MB_ICONQUESTION or MB_TASKMODAL
                             )
              of
                  ID_YES
                      : ;
                  ID_NO
                      : exit;
              end;

              do_replace( _source, _destination, true);
          end
        );
    TWnd_Replace.do_Show();
end;

procedure Twnd_main.surface_headerPaint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
begin
    drawGradient( ACanvas.Handle, 0, 0, Rect.Right, Rect.Bottom, $F0F0F0, clWhite);
end;

procedure Twnd_main.surface_mainPaint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
begin
    drawGradient( ACanvas.Handle, 0, 0, Rect.Right, 100, clWhite, $F0F0F0);
end;

procedure Twnd_main.surface_msgErrorPaint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
begin
    drawGradient( ACanvas.Handle, 1, 1, Rect.Right, Rect.Bottom, clWhite, $efefff);
end;

procedure Twnd_main.surface_recentExit(Sender: TObject);
begin
    surface_recent.Hide();
end;

{ iccTabObject }

class function iccTabObject.link( _obj : TObject) : iccTabObject;
begin
    result := nil;
    if _obj is iccTabObject
        then result := iccTabObject( _obj);
end;

constructor iccTabObject.Create();
begin
    inherited;
    FLoaded           := false;
    //
    FId               := -1;
    //FTitle            := '';
    FSynEdit          := nil;
    FFile_Attached    := false;
    //FFile_Fullpath    := '';
    FFile_Saved       := false;
end;

procedure iccTabObject.file_attach( _str : String; _saved : Boolean = false);
begin
    FFile_Attached := true;
    FFile_Fullpath := _str;
    FFile_Saved    := _saved;
end;

{ iccTabsMetaData.iccItem }

function iccTabsMetaData.iccItem.prop_getInt(_index: Integer): Integer;
var ptr : variant;
begin
    ptr := self[inttostr( _index)];
    if Null = ptr
        then result := 0
        else result := ptr;

//    result := Self[inttostr(_index)];
//   result := 10;
end;

procedure iccTabsMetaData.iccItem.prop_setInt(_index, _value: Integer);
begin
    Self[inttostr(_index)] := _value;
end;

{ iccTabsMetaData }

function iccTabsMetaData.isClass( _v : Variant; _c : TClass) : Boolean;
begin
    result := TObject( DWORD( _v)) is _c;
end;

function iccTabsMetaData.clr(): Boolean;
var ndx : integer;
    itm : TObject;
begin
    for ndx := 0 to cnt - 1 do
        begin
            itm := TObject( dword( inherited get( ndx)));

            if itm is iccItem
                then itm.Destroy();
        end;

    result := inherited clr();
end;

function iccTabsMetaData.del( _ndx : Integer) : Boolean;
var itm : TObject;
begin
    itm := TObject( dword( inherited get( _ndx)));
    if itm is iccItem
        then itm.Destroy();

    result := inherited del( _ndx);
end;

function iccTabsMetaData.toString() : String;
begin
    result := inherited toString(
        function ( _v : variant) : string
        var itm : iccItem;
        begin
            if not isClass( _v, iccItem)
                then raise iccException.Create( 'iccTabsMetaData.toString() -> _onItemProcess() -> _v is not iccItem');

            itm := iccItem( dword( _v));

            result := itm.ToString();
        end
    );

    result := str_encode( result);
end;

function iccTabsMetaData.fromString( _str : String) : Boolean;
begin
    _str := str_decode( _str);

    result := inherited fromString( _str,
        function ( _s : String) : Variant
        var itm : iccItem;
        begin
            itm := iccItem.Create();
            itm.fromString( _s); /// _s , not _str :)

            result := dword( itm);
        end
    );
end;

function iccTabsMetaData.put(_linkId: Integer): iccItem;
begin
    result := getByLinkID( _linkId);
    if result = nil
        then Result := iccItem.Create();

    result.linkId := _linkId;

    self[inttostr( _linkId)] := DWORD( result);
end;

function iccTabsMetaData.getByLinkID(_linkId: Integer): iccItem;
begin
    if not IDExist( inttostr( _linkId))
        then exit( nil);

    result := iccItem( DWORD( self[inttostr( _linkId)]));
end;

function iccTabsMetaData.getByIndex( _index  : Integer) : iccItem;
begin
    result := iccItem( DWORD( inherited get( _index)));
end;

function iccTabsMetaData.delByLinkId( _linkId : Integer) : Boolean;
begin
    result := del( inttostr( _linkId));
end;

{ iccConfig }

function iccConfig.retrieve( _param : String; _default : Integer) : Integer;
var val   : variant;
    int   : integer;
begin
    result := _default;

    val := get( _param);
    if ( TVarData( val).VPointer <> nil)
        then if TryStrToInt( val, int)
                 then result := int;
end;

function iccConfig.retrieve( _param : String; _default : Boolean) : Boolean;
var val : variant;
begin
    result := _default;

    val := get( _param);
    if ( TVarData( val).VPointer <> nil)
        then result := val;
end;

function iccConfig.retrieve( _param : String; _default : String) : String;
var val : variant;
begin
    val := get( _param);
    if ( TVarData( val).vPointer <> nil)
        then result := val
        else result := _default;

    // in case of strings, it is better to check the expression and just then copy string
end;

function iccConfig.write( _param : String; _value : Integer) : Boolean;
begin
    result := true;

    try
        define( _param, _value);
    except
        result := false;
    end;
end;

function iccConfig.write   ( _param : String; _value : Boolean) : Boolean;
begin
    result := true;

    try
        define( _param, _value);
    except
        result := false;
    end;
end;

function iccConfig.write   ( _param : String; _value : String ) : Boolean;
begin
    result := true;

    try
        define( _param, _value);
    except
        result := false;
    end;
end;

procedure iccConfig.routine_WindowParams_get( _sender : TCustomForm);
var prefix : String;
begin
    prefix := _sender.ClassName + '_';

    _sender.left   := savePos_X( retrieve( prefix + 'x', Screen.Width div 2  - _sender.Width div 2 ), {default} Screen.Width div 2  - _sender.Width div 2);
    _sender.top    := savePos_Y( retrieve( prefix + 'y', Screen.Height div 2 - _sender.Height div 2), {default} Screen.Height div 2 - _sender.Height div 2);
    _sender.width  := retrieve( prefix + 'w', _sender.width);
    _sender.height := retrieve( prefix + 'h', _sender.height);
    _sender.WindowState := TWindowState( retrieve( prefix + 'ws', Integer( _sender.WindowState)));
end;

procedure iccConfig.routine_WindowParams_set( _sender : TCustomForm);
var prefix : String;
begin
    prefix := _sender.ClassName + '_';

    write( prefix + 'x',  _sender.Left);
    write( prefix + 'y',  _sender.Top);
    write( prefix + 'w',  _sender.Width);
    write( prefix + 'h',  _sender.Height);
    write( prefix + 'ws', Integer( _sender.WindowState));
end;

{ iccRecentTab }

constructor iccRecentTab.Create(_tid: Integer; _title: String);
begin
    FTID     := _tid;
    FTitle   := _title;
    FChecked := False;
end;

constructor iccRecentTab.Create( _tid : Integer; _title : String; _checked : Boolean);
begin
    FTID     := _tid;
    FTitle   := _title;
    FChecked := _checked;
end;

{ icc_wrapper_advImage }

constructor icc_wrapper_advImage.Create( _owner : TComponent);
begin
    inherited Create();
    FContainer := TdxContainer.Create( _owner);
    FContainer.ControlStyle := FContainer.ControlStyle - [csDoubleClicks];
    FContainer.Color := $F0F0F0;
    FContainer.BoundLines := [blLeft, blTop, blRight, blBottom];
    FContainer.BoundColor := clSilver;

    FContainer.OnDestroy    := ___event_onDestroy;
    FContainer.OnPaint      := ___event_onPaint;
    FContainer.OnMouseLeave := ___event_onMouseLeave;
end;

class function icc_wrapper_advImage.wrap( _ownerParent: TWinControl; _img: iccAdvImage; _text: String): tdxContainer;
var inn : icc_wrapper_advImage;
    absPos : TPoint;
begin
    inn := icc_wrapper_advImage.Create( _ownerParent);
    inn.FContainer.Left := - 1000;
    inn.FContainer.Top  := - 1000;
    inn.FContainer.Parent  := _ownerParent;
    inn.FContainer.BringToFront();
    inn.FContainer.OnClick := _img.OnClick;

    if _img.Pictures.Entered <> nil
        then inn.FImg_Default   := _img.Pictures.Entered
        else inn.FImg_Default   := _img.Picture;

    if _img.Pictures.Pressed <> nil
        then inn.FImg_Press     := _img.Pictures.Pressed;


    inn.FText      := _text;
    inn.FTextWidth := inn.FContainer.Canvas.TextWidth( _text);

    absPos := _img.ClientToParent( Point( 0, 0), _ownerParent);


    with inn.FContainer do
        begin
           Height := _img.Height + 4;
           Width  := _img.Width + inn.FTextWidth + 12;

           if absPos.X + Width > _ownerParent.Width
               then begin
                       Left   := absPos.X  - Width + _img.Width + 3;
                       Top    := absPos.Y  - 2;
                       inn.FSide := false;
                    end
               else begin
                       Left   := absPos.X  - 3;
                       Top    := absPos.Y  - 2;
                       inn.FSide := true;
                    end;
        end;

    // show the truth :)
    inn.FContainer.Show();

    result := inn.FContainer;
end;

procedure icc_wrapper_advImage.___event_onDestroy( _sender : TObject);
begin
    Destroy();
end;

procedure icc_wrapper_advImage.___event_onPaint(_sender: TObject; _rect: TRect; _canvas: TCanvas; _Font: TFont);
var img : TPicture;
begin
    _canvas.Pen.Color := v_tcllsit_Normal.TextShadow;
    _canvas.Brush.Style := bsClear;
    _canvas.Rectangle( 1, 1, _rect.Right, _rect.Bottom);
    drawGradient( _canvas.Handle, 2, 2, _rect.Right - 1, _rect.Bottom - 1, v_tcllsit_Normal.Color1, v_tcllsit_Normal.Color2);

    if dsClicked in FContainer.DrawState
        then img := FImg_Press
        else img := FImg_Default;

    //
    if FSide
        then begin
                 _canvas.Draw( 3, 2, img.Graphic);
                 _canvas.TextOut( img.Width + 2 + 4, 3, FText);
             end
        else begin
                 _canvas.Draw( _Rect.Right - img.Width - 2, 2, img.Graphic);
                 _canvas.TextOut( 6, 3, FText);
             end;
end;

procedure icc_wrapper_advImage.___event_onMouseLeave( _sender: TObject);
begin
    FContainer.Destroy();
end;

end.
