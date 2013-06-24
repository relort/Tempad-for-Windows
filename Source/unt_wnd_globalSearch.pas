unit unt_wnd_globalSearch;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, dxLabel, dxCore, dxContainer, unt_wnd_main, pngimage, ExtCtrls, icClasses, icUtils, dxListBox,
  unt_frame_progressNotifier, unt_tabManager;

type
    iccResult_Item =
        class
            private
            public
                FID      : DWORD;
                FTitle   : String;
                FDeleted : Boolean;

        end;

    Twnd_globalSearch =
        class(TForm)
                surface_main: TdxContainer;
                dxLabel2: TdxLabel;
                edt_Text: TEdit;
                btn_Close: TButton;
                dxLabel1: TdxLabel;
                Image1: TImage;
                lst_result: TdxListBox;
                img_tabActive: TImage;
                chk_lookupTheRecents: TCheckBox;
                dxLabel3: TdxLabel;
                lbl_resultAmount: TdxLabel;
                img_tabRecent: TImage;
                procedure FormCreate(Sender: TObject);
                procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
                procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
                procedure edt_TextKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
                procedure lst_resultPaint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
                procedure btn_CloseClick(Sender: TObject);
                procedure edt_TextKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
                procedure lst_resultItemPaint(_sender: TObject; _itemIndex: Integer; _itemState: TdxListBox.iccItem.icsState; _itemData: TdxListBox.ictItemDataType; _canvas: TCanvas; _rect: TRect);
                procedure chk_lookupTheRecentsClick(Sender: TObject);
                procedure lst_resultDblClick(Sender: TObject);
                procedure lst_resultKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
            const
                c_cfg_globalSearch_prefix = 'wnd_globalSearch_';
                c_cfg_checkTheRecents     = c_cfg_globalSearch_prefix + 'checkTheRecents';
            private
                FFrame_Progress : TFrame_ProgressNotifier;
                procedure wm_sync( var _msg : iccThread.icr_wm_sync); message iccThread.wm_sync;
            private
                FTimeout_performSearch : DWORD;
                FStr_LastSearch        : String;
                FPos_LastCaret         : Integer;

                FUI_Enabled            : Boolean;

                FThread                : iciThread;
            public
                procedure timeout_Set( _set : Boolean = true);

                procedure checkAndDelaySearch( _forceDoSearch : Boolean = false);

                procedure ui_enabled( _enabled : Boolean = true);
                procedure do_search( _str : String);
                procedure list_clear();
                procedure sync_fillList( _thread : iciThread; _lst : iccList);

                procedure tabOpenOrFocus( _focusIfOpened : Boolean = false);
        end;

var
    wnd_globalSearch: Twnd_globalSearch;

implementation

{$R *.dfm}

procedure Twnd_globalSearch.btn_CloseClick(Sender: TObject);
begin
    Close();
end;

procedure Twnd_globalSearch.checkAndDelaySearch;
begin
    if ( edt_Text.Text = FStr_LastSearch) and ( not _forceDoSearch)
        then exit;
    FStr_LastSearch := edt_Text.Text;

    // do not search with the empty string
    if edt_Text.Text = ''
        then begin
                 timeout_Set( false);
                 list_clear();
                 exit;
             end;

    timeout_Set();
end;

procedure Twnd_globalSearch.chk_lookupTheRecentsClick(Sender: TObject);
begin
    checkAndDelaySearch( true);
end;

procedure Twnd_globalSearch.do_search(_str: String);
var tout_Progress : DWORD; // timeout for progress panel
    tour_Overload : DWORD; // timeout for canceling thread execution

    list : iccList;

    proc_body     : iccThread.ictThreadStagingProc;
    proc_excp     : iccThread.ictThreadOnErrorProc;
    proc_done     : TProc;
    proc_itcb     : iccTabManager.ictSearchItemCallbackFunc; // item callback
    proc_void     : TProc;

    str : String;
    gar : iccTabManager.ictSearchRequest;
begin
    ui_enabled( false);

    // timeout - progress
    Tframe_ProgressNotifier.checkCreate( FFrame_Progress, Self, Self);
    tout_Progress := iccTimeout.set__( 200, procedure () begin FFrame_Progress.Show(); end);
    //

    // timeout - thread
    tour_Overload := iccTimeout.set__( 4000, procedure ()
                                             begin
                                                 FThread.suspend;
                                                 FThread.doSync( handle, proc_done);

                                                 proc_void();

                                                 FThread.set_AutoDestroy(); // !!!
                                                 FThread.terminate();

                                                 MessageBox( Handle, 'took too long...', c_app_name, MB_OK or MB_ICONINFORMATION);
                                             end
                                     );
    //

    // initial
    str := edt_Text.Text;
    gar := garNotDeleted;
    if chk_lookupTheRecents.Checked
        then gar := garAll;

    list := iccList.Create();
    //

    // proc
    proc_body :=
        procedure ()
        begin
            //sleep( 5000);
            //
            wnd_main.TabManager.Search( str, gar, proc_itcb);

            sync_fillList( FThread, list);

            FThread.doSync( handle, proc_done);

            proc_void();

            //
            FThread.set_AutoDestroy(); // !!!
        end;

    proc_excp :=
        procedure ( _exc : Exception)
        begin
        end;

    proc_done :=
        procedure ()
        begin
            iccTimeout.unset( tout_Progress);
            Tframe_ProgressNotifier.release( FFrame_Progress);
            lst_result.ItemIndex := 0;
            lbl_resultAmount.Caption := inttostr( lst_result.Cnt);
            ui_enabled();
        end;

    proc_itcb :=
        procedure ( _id : DWORD; _title : String; _Deleted : Boolean; var _aborted : Boolean)
        begin
            list.Add( iccTabManager.iccSearchItem.Create( _id, _title, _deleted));
        end;

    proc_void :=
        procedure
        begin
            // we do not need search timeout anymore
            iccTimeout.unset( tour_Overload);

            // finit
            str := '';
            list.Free();

            proc_body := nil;
            proc_excp := nil;
            proc_done := nil;
            proc_itcb := nil;

            // and self clean
            proc_void := nil;
        end;
    //

    FThread := iccThread.threadAdd( proc_body, proc_excp);

    FThread.set_AutoDestroy( false);
    FThread.resume();
end;

procedure Twnd_globalSearch.list_clear();
var ndx : Integer;
begin
    lbl_resultAmount.Caption := '0';
    lst_result.Lock();

    for ndx := 0 to lst_result.Cnt - 1 do
        iccTabManager.iccSearchItem( lst_result[ndx].Data.ptr).Destroy();
    lst_result.Clr();

    lst_result.Unlock();
end;

procedure Twnd_globalSearch.edt_TextKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
    if Key = VK_DOWN
        then begin
                 Key := 0;
                 lst_result.ItemIndex := lst_result.ItemIndex + 1;
                 lst_result.Invalidate();
             end;

    if Key = VK_UP
        then begin
                 Key := 0;
                 if lst_result.ItemIndex = 0
                    then exit;

                 lst_result.ItemIndex := lst_result.ItemIndex - 1;
                 lst_result.Invalidate();
             end;

    if Key = VK_RETURN
        then begin
                 if Shift = [ssCtrl]
                     then begin
                              tabOpenOrFocus();
                          end
                     else begin
                              tabOpenOrFocus( true);
                              Close();
                          end;

                 Key := 0;
             end;

end;

procedure Twnd_globalSearch.edt_TextKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
    checkAndDelaySearch();
end;

procedure Twnd_globalSearch.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
    if not FUI_Enabled
        then begin
                 CanClose := false;
                 exit;
             end;


    timeout_Set( false);
    list_clear();
    gv_Config.routine_WindowParams_set( Self);

    // save
    gv_Config.write( c_cfg_checkTheRecents, chk_lookupTheRecents.Checked);
end;

procedure Twnd_globalSearch.FormCreate(Sender: TObject);
begin
    //
    FTimeout_performSearch := 0;
    FStr_LastSearch        := '';

    FUI_Enabled            := true;
    //

    gv_Config.routine_WindowParams_get( Self);
    onPaint                    := wnd_main.onPaint;
    surface_main.OnPaint       := wnd_main.___event_container_paint_Generic;
    edt_Text.OnKeyPress        := wnd_main.___event_editOnKeyPress;

    // load cfg
    chk_lookupTheRecents.Checked := gv_Config.retrieve( c_cfg_checkTheRecents, true);
end;

procedure Twnd_globalSearch.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
    if Key = VK_ESCAPE
        then begin
                 Key := 0;
                 Close();
             end;
end;

procedure Twnd_globalSearch.lst_resultDblClick(Sender: TObject);
begin
    tabOpenOrFocus( true);
    close();
end;

procedure Twnd_globalSearch.lst_resultItemPaint(_sender: TObject; _itemIndex: Integer; _itemState: TdxListBox.iccItem.icsState;
  _itemData: TdxListBox.ictItemDataType; _canvas: TCanvas; _rect: TRect);
var res : iccTabManager.iccSearchItem;
    tcs : iccTemplate_ColorScheme_ListBox_ItemPaint;
begin
    res := iccTabManager.iccSearchItem( _itemData.ptr);


    tcs := v_tcllsit_Normal;
    if res.Deleted
        then tcs := v_tcllsit_Lighten;


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
    if res.Deleted
        then _canvas.Draw( 18, _rect.Top + 18, img_tabRecent.Picture.Graphic)
        else _canvas.Draw( 18, _rect.Top + 18, img_tabActive.Picture.Graphic);

    // index
    _canvas.Font.Color := tcs.Fn2;
    drawTextWithShadow( _canvas, IntToStr( _itemIndex + 1), Bounds( 40, _rect.Top + 19, 20, 20), tcs.TextShadow, dt_left or DT_END_ELLIPSIS);

    // title
    _canvas.Font.Color := tcs.Fn1;
    drawTextWithShadow( _canvas, res.Title, Bounds( 80, _rect.Top + 18, 200, 20), tcs.TextShadow, dt_left or DT_END_ELLIPSIS or DT_NOPREFIX);
end;

procedure Twnd_globalSearch.lst_resultKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
    if Key <> VK_RETURN
        then exit;


    edt_TextKeyDown( sender, key, shift);
    Key := 0;
end;

procedure Twnd_globalSearch.lst_resultPaint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
begin
    if lst_result.Cnt = 0
        then begin
                 ACanvas.Font.Color := v_tcllsit_Normal.Fn1;
                 drawTextWithShadow( acanvas, 'List is empty', Bounds( 0, 0, Rect.Right, Rect.Bottom), v_tcllsit_Normal.TextShadow, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
             end;
end;

procedure Twnd_globalSearch.tabOpenOrFocus( _focusIfOpened : Boolean = false);
var res : iccTabManager.iccSearchItem;
    ndx : integer;

    tmpTO : iccTabObject;
    tmpRT : iccRecentTab;
begin
    if lst_result.ItemIndex = -1
        then exit;

    res := iccTabManager.iccSearchItem( lst_result[lst_result.ItemIndex].Data.ptr);

    if res.Deleted
        then begin
                 for ndx := 0 to wnd_main.RecentTabs.Cnt - 1 do
                     begin
                         tmpRT := wnd_main.RecentTabs[ndx];

                         if tmpRt.TID = res.ID
                             then begin
                                      wnd_main.recent_Del( ndx);
                                      wnd_main.tab_Load( res.ID);

                                      // validate string
                                      //do_search( edt_text.Text);
                                      res.Deleted := false;
                                      lst_result.Invalidate();
                                      //

                                      if _focusIfOpened
                                          then wnd_main.tab_Switch( wnd_main.tabs.Tabs.Count - 1);

                                      break;
                                  end;
                     end;
             end
        else begin
                 for ndx := 0 to wnd_main.tabs.Tabs.Count - 1 do
                     begin
                         tmpTO := wnd_main.tab_getObject( ndx);

                         if tmpTO.Id = res.ID
                             then begin
                                      wnd_main.tab_Switch( ndx);
                                      break;
                                  end;
                     end;
             end;
end;

procedure Twnd_globalSearch.timeout_Set(_set: Boolean);
begin
    iccTimeout.unset( FTimeout_performSearch);

    if not _set
        then exit;

    FTimeout_performSearch := iccTimeout.set__
        ( 400,
        procedure ()
        begin
            do_search( edt_Text.Text);
        end
        );
end;

procedure Twnd_globalSearch.ui_enabled(_enabled: Boolean);
begin
    if FUI_Enabled = _enabled
        then exit;
    FUI_Enabled := _enabled;


    case _enabled of
        false
         : begin
               FPos_LastCaret := edt_Text.SelStart;
           end;
        true
         : begin
           end;
    end;

    surface_main.Enabled := _enabled;
    edt_Text.Enabled     := _enabled;

    if _enabled
        then begin
                 edt_Text.SetFocus();
                 edt_Text.SelStart := FPos_LastCaret;
             end;
end;


procedure Twnd_globalSearch.wm_sync(var _msg: iccThread.icr_wm_sync);
begin
    try
        _msg.Proc^();
    except
        raise iccException.Create( 'sync() -> failed.', iccException.c_prior_FATAL);
    end;
end;

procedure Twnd_globalSearch.sync_fillList( _thread : iciThread; _lst: iccList);
begin
    _thread.doSync( Handle,
        procedure ()
        var ndx : integer;
        begin
            list_clear();

            lst_result.Lock();
            for ndx := 0 to _lst.Count - 1 do
                lst_result.Add( DWORD( _lst.Items[ndx]), 50);
            lst_result.Unlock();
        end
        )
end;

end.
