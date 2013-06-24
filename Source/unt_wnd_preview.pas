unit unt_wnd_preview;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, SynEdit, unt_wnd_main, dxLabel, icClasses, pngimage, ExtCtrls, ComCtrls, dxCore, dxContainer, Menus,
  unt_frame_ProgressNotifier, SynEditHighlighter, SynHighlighterURI, SynURIOpener;

type
  Twnd_Preview = class(TForm)
    Button1: TButton;
    edt_data: TSynEdit;
    lbl_title: TdxLabel;
    Image1: TImage;
    dxLabel1: TdxLabel;
    edit_menu: TPopupMenu;
    item_edit_menu_Copy: TMenuItem;
    N4: TMenuItem;
    item_edit_menu_SelectAll: TMenuItem;
    editor_links_opener: TSynURIOpener;
    editor_links_highlight: TSynURISyn;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Button1Click(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure item_edit_menu_CopyClick(Sender: TObject);
    procedure item_edit_menu_SelectAllClick(Sender: TObject);
    procedure edit_menuPopup(Sender: TObject);
  private
      FState     : icsWindowState;
      FThread    : iciThread;
      FProc_Sync_Init  : TProc;
      FProc_Sync_Finit : TProc;

      FFrame_Progress  : Tframe_ProgressNotifier;

      FId     : Integer;
      procedure msg_wm_sync( var _msg : iccthread.icr_wm_sync); message iccThread.wm_sync;
  public
      class function preview( _owner : TComponent; _id : Integer; _title : String = '') : Boolean;
  end;

implementation

{$R *.dfm}

procedure Twnd_Preview.Button1Click(Sender: TObject);
begin
    Close();
end;

procedure Twnd_Preview.edit_menuPopup(Sender: TObject);
begin
    item_edit_menu_Copy.Enabled := edt_data.SelLength > 0;
end;

procedure Twnd_Preview.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
    CanClose := false;

    if wsInitInProgress in FState
        then begin
                 MessageBox( 0, c_wnd_preview_InterruptAlert, pchar( caption), MB_OK or MB_ICONINFORMATION);
                 exit;
             end;

    if wsFinitInProgress in FState
        then exit;
    Include( FState, wsFinitInProgress);

    //

    gv_Config.routine_WindowParams_set( Self);

    Tframe_ProgressNotifier.checkCreate( FFrame_Progress, Self, Self);
    edt_data.Text := ''; // moved here to avoid bugs and memory leaks

    FThread := iccThread.threadAdd
    ( procedure ()
      begin
          //edt_data.Text := ''; // causes bugs.... REALLY!

          FThread.doSync( Handle, FProc_Sync_Finit);
      end,
      procedure ( _e : Exception)
      begin
          MessageBox( 0, '123', '', 0);
      end
    );

    FThread.resume();
end;

procedure Twnd_Preview.FormCreate(Sender: TObject);

begin
    // ready to work
    FState := [wsInitInProgress];

    gv_Config.routine_WindowParams_get( Self);
    OnPaint := wnd_main.OnPaint;

    Tframe_ProgressNotifier.checkCreate( FFrame_Progress, Self, Self);

    edt_data.OnSpecialLineColors := wnd_main.___event_synEditSpecialLineColors;

    FProc_Sync_Init :=
        procedure ()
        begin
            edt_data.Enabled := True;
            Tframe_ProgressNotifier.release( FFrame_Progress);
        end;

    FProc_Sync_Finit :=
        procedure ()
        begin
            OnCloseQuery := nil;
            Close();
        end;
end;

procedure Twnd_Preview.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
    if Key = VK_ESCAPE
        then Close();
end;

procedure Twnd_Preview.FormShow(Sender: TObject);
var tmpStr  : String;

    proc_setText : TProc;
begin
    if ( wsInitDone in FState )
        then exit;
    onShow := nil; // do not allow dup call


    Tframe_ProgressNotifier.checkCreate( FFrame_Progress, Self, Self);
    FFrame_Progress.Show();
    FFrame_Progress.Update();

    editor_links_opener.Editor := edt_data;


    proc_setText := procedure ()
                    begin
                        edt_data.Text := tmpStr;
                    end;

    FThread := iccThread.threadAdd
    ( procedure ()
      begin
          //wnd_main.TabManager.getData( FId, edt_data.Lines);
          wnd_main.TabManager.getData( FId, tmpStr);

          //
          FFrame_Progress.Status_Set_threadContext( FThread, 'Setting text. Thats right, need to wait. Thx to VCL...');
          FThread.doSync( Handle, proc_setText);
          proc_setText := nil; // do not forget to nil ref
          //


          FThread.doSync( Handle, FProc_Sync_Init);

          Exclude( FState, wsInitInProgress);
          Include( FState, wsInitDone);
      end,
      procedure ( _e : Exception)
      begin
          Exclude( FState, wsInitInProgress);
          Include( FState, wsInitFailed);
      end
    );

    FThread.resume();
end;

procedure Twnd_Preview.item_edit_menu_CopyClick(Sender: TObject);
begin
    edt_data.CopyToClipboard();
end;

procedure Twnd_Preview.item_edit_menu_SelectAllClick(Sender: TObject);
begin
    edt_data.SelectAll();
end;

procedure Twnd_Preview.msg_wm_sync(var _msg: iccthread.icr_wm_sync);
begin
    try
        try
            //TProc( pointer( _msg.WParam))();
            _msg.Proc^();
//            raise Exception.Create('Error Message');
        except
            // nothing special. Just error. Notify about this shit
            MessageBox( Handle, c_wnd_preview_dataLoading_failed, pchar( caption), MB_OK or MB_ICONINFORMATION);
        end;

        DefaultHandler( _msg);
    except
        raise iccException.Create( 'thread sync -> failed.', iccException.c_prior_FATAL);
    end;
end;

class function Twnd_Preview.preview( _owner : TComponent; _id: Integer; _title: String): Boolean;
var wnd_preview : Twnd_Preview;
begin
    wnd_preview := Twnd_Preview.Create( _owner);

    wnd_preview.FId    := _id;

    wnd_preview.Caption := wnd_preview.Caption + ' - ' + _title;
    wnd_preview.lbl_title.Caption := _title;

    wnd_preview.ShowModal();
    wnd_preview.Destroy();

    result := true;
end;

end.
