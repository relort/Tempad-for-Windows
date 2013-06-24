unit unt_wnd_recentTabManager;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, dxCore, dxContainer, dxListBox, dxLabel,
  unt_wnd_main, icClasses, icUtils, pngimage, ExtCtrls, ComCtrls, unt_frame_ProgressNotifier;

type
  Twnd_recentTabManager = class(TForm)
    btn_SelectAll: TButton;
    btn_SelectNone: TButton;
    lst_RecentTabs: TdxListBox;
    btn_DeleteForever: TButton;
    dxLabel1: TdxLabel;
    img_Check_False: TImage;
    img_Check_True: TImage;
    btn_preview: TButton;
    btn_Close: TButton;
    btn_rename: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure lst_RecentTabsItemPaint( _sender: TObject; _itemIndex: Integer;
                                       _itemState: TdxListBox.iccItem.icsState;
                                       _itemData: TdxListBox.ictItemDataType;
                                       _canvas: TCanvas;
                                       _rect: TRect);
    procedure btn_SelectAllClick(Sender: TObject);
    procedure btn_SelectNoneClick(Sender: TObject);
    procedure btn_DeleteForeverClick(Sender: TObject);
    procedure lst_RecentTabsItemMouseDown( _sender: TObject;
                                           _itemIndex: Integer;
                                           _itemState: TdxListBox.iccItem.icsState;
                                           _itemData: TdxListBox.ictItemDataType;
                                           _x,
                                           _y: Integer;
                                           _shift: TShiftState
                                         );
    procedure lst_RecentTabsMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure btn_previewMouseEnter(Sender: TObject);
    procedure lst_RecentTabsMouseLeave(Sender: TObject);
    procedure btn_previewMouseLeave(Sender: TObject);
    procedure btn_previewClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure lst_RecentTabsPaint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
    procedure btn_CloseClick(Sender: TObject);
    procedure btn_renameClick(Sender: TObject);
  private
      FCounter_SelectedItems    : Cardinal;
      Ftmp_hoveredItemIndex     : Integer; // item index btn_preview is over
      Ftmp_btn_Preview_ShowHide : Boolean; // variable to be sure that MouseEnter was received by btn_Preview
      FFrame_Progress           : Tframe_ProgressNotifier;
  public
      procedure update_Counter_SelectedItems();

      procedure list_fill();

      procedure list_setEach( _bool : Boolean);
      procedure list_set( _index : Integer; _bool : Boolean);
      procedure list_inv( _index : Integer); // invert current value

      procedure list_SelectAll();
      procedure list_SelectNone();

      function list_get() : TArray<integer>;

      procedure update_btn_DeleteForever();
  end;

implementation

uses unt_wnd_preview;

{$R *.dfm}

procedure Twnd_recentTabManager.FormCreate(Sender: TObject);
begin
    gv_Config.routine_WindowParams_get( Self);
    OnPaint := wnd_main.OnPaint;
end;

procedure Twnd_recentTabManager.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
    if Key = VK_ESCAPE
        then Close();
end;

procedure Twnd_recentTabManager.lst_RecentTabsItemMouseDown(_sender: TObject; _itemIndex: Integer;
  _itemState: TdxListBox.iccItem.icsState; _itemData: TdxListBox.ictItemDataType; _x, _y: Integer; _shift: TShiftState);
begin
    list_inv( _itemIndex);
    update_btn_DeleteForever();
    lst_RecentTabs.Invalidate();
end;

procedure Twnd_recentTabManager.lst_RecentTabsItemPaint(_sender: TObject;
  _itemIndex: Integer; _itemState: TdxListBox.iccItem.icsState;
  _itemData: TdxListBox.ictItemDataType; _canvas: TCanvas; _rect: TRect);
var rec : iccRecentTab;
    tcs : iccTemplate_ColorScheme_ListBox_ItemPaint;
begin
   if _itemIndex >= lst_RecentTabs.Cnt
       then Exit;

    rec := wnd_main.RecentTabs[_itemIndex];
    if rec = nil
        then exit;


    tcs := v_tcllsit_Normal;
//    if _itemIndex mod 2 = 1
//        then tcs := v_tcllsit_Normal2;

    if ( tdxListBox.iccItem.ictState.isFocused in _itemState )
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
    if rec.Checked
        then _canvas.Draw( 15, _rect.Top + 15, img_Check_True.Picture.Graphic)
        else _canvas.Draw( 15, _rect.Top + 15, img_Check_False.Picture.Graphic);

    // index
    _canvas.Font.Color := tcs.Fn2;
    drawTextWithShadow( _canvas, IntToStr( _itemIndex + 1), Bounds( 40, _rect.Top + 19, 20, 20), tcs.TextShadow, dt_left or DT_END_ELLIPSIS);

    // title
    _canvas.Font.Color := tcs.Fn1;
    drawTextWithShadow( _canvas, rec.Title, Bounds( 80, _rect.Top + 18, 200, 20), tcs.TextShadow, dt_left or DT_END_ELLIPSIS or DT_NOPREFIX);
end;

procedure Twnd_recentTabManager.lst_RecentTabsMouseLeave(Sender: TObject);
begin
    if not Ftmp_btn_Preview_ShowHide
        then begin
                 // forget item index
                 Ftmp_hoveredItemIndex := -1;

                 btn_preview.Hide();
                 btn_rename .Hide();
             end;
end;

procedure Twnd_recentTabManager.lst_RecentTabsMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var titm : tdxListbox.iccItem;
    ipos : Integer;
    iof0 : Integer;
begin
    ipos := y;
    titm := lst_RecentTabs.GetItemAtPos_viewport( ipos, iof0);
    if titm = nil
        then ipos := -1;

    if ipos >= 0
        then begin // проводжу дебільні перевірки, вдруг компоненти тупі і оновлюють стан при тому, шо перебувають в тому самому
                 // remember item index
                 Ftmp_hoveredItemIndex := ipos;

                 ipos := iof0 + ( titm.Height div 2) - ( btn_preview.Height div 2);
                 if ipos <> btn_preview.Top
                     then btn_preview.Top := ipos;

//                 ipos := lst_RecentTabs.Width - btn_preview.Width - 35;
//                 if ipos <> btn_preview.Left
//                     then btn_preview.Left := ipos;

                 if not btn_preview.Visible
                     then btn_preview.Show();

                 //
                 btn_rename.Top := btn_preview.Top;
                 btn_rename.Visible := btn_preview.Visible;
             end
        else begin
                 // forget item index
                 Ftmp_hoveredItemIndex := -1;

                 btn_preview.Hide();
                 btn_rename .Hide();
             end;
end;

procedure Twnd_recentTabManager.lst_RecentTabsPaint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
begin
    if lst_RecentTabs.Cnt = 0
        then begin
                 ACanvas.Font.Color := v_tcllsit_Normal.Fn1;
                 drawTextWithShadow( acanvas, 'List is empty', Bounds( 0, 0, Rect.Right, Rect.Bottom), v_tcllsit_Normal.TextShadow, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
             end;
end;

procedure Twnd_recentTabManager.btn_CloseClick(Sender: TObject);
begin
    Close();
end;

procedure Twnd_recentTabManager.btn_DeleteForeverClick(Sender: TObject);
var ndx : integer;
    tmp : iccRecentTab;
begin
    if MessageBox( Handle, c_wnd_recentTabManager_confirmation, pchar( caption), MB_YESNO or MB_ICONQUESTION) <> ID_YES
        then exit;

    Enabled := false;
    Tframe_ProgressNotifier.checkCreate( FFrame_Progress, Self, Self);

    ndx := 0;
    while ndx < wnd_main.RecentTabs.Count do
        begin
            tmp := wnd_main.RecentTabs[ndx];
            if tmp.Checked
                then begin
                         FFrame_Progress.Status_Set( tmp.Title);

                         // delete assoc. meta
                         wnd_main.TabMetaData.delByLinkId( tmp.TID);

                         if not wnd_main.TabManager.Del( tmp.TID)
                             then begin
                                      MessageBox( Handle, c_wnd_recentTabManager_deleting_Failed, pchar( caption), 0);
                                      BREAK;
                                  end;

                         wnd_main.recent_Del( ndx);
                         lst_RecentTabs.Del( ndx);
                         lst_RecentTabs.Update();

                         Continue;
                     end;

            ndx := ndx + 1;
        end;

    update_Counter_SelectedItems();
    update_btn_DeleteForever();


    Tframe_ProgressNotifier.release( FFrame_Progress);
    Enabled := True;
end;

procedure Twnd_recentTabManager.btn_previewClick(Sender: TObject);
var item : iccRecentTab;
begin
    if Ftmp_hoveredItemIndex = -1
        then MessageBox( Handle, 'Hey, hey. Nothing is focused. Move cursor once again.', c_app_name, 0);

    item := wnd_main.RecentTabs[Ftmp_hoveredItemIndex];

    Twnd_preview.preview( self, item.TID, item.Title);
end;

procedure Twnd_recentTabManager.btn_previewMouseEnter(Sender: TObject);
begin
    Ftmp_btn_Preview_ShowHide := True;
end;

procedure Twnd_recentTabManager.btn_previewMouseLeave(Sender: TObject);
begin
    Ftmp_btn_Preview_ShowHide := False;
end;

procedure Twnd_recentTabManager.btn_renameClick(Sender: TObject);
var item : iccRecentTab;
    str : String;
begin
    if Ftmp_hoveredItemIndex = -1
        then MessageBox( Handle, 'Hey, hey. Nothing is focused. Move cursor once again.', c_app_name, 0);

    item := wnd_main.RecentTabs[Ftmp_hoveredItemIndex];

//    Twnd_preview.preview( self, item.TID, item.Title);
    ///
    str := InputBox( 'Rename', 'Specify new name to the selected tab', item.Title);

    if item.Title = str
        then exit;

    item.Title := str;
    wnd_main.TabManager.setInfo( item.TID, item.Title, -1);

    lst_RecentTabs.Invalidate();
    wnd_main.lst_recentTabs.Invalidate();
end;

procedure Twnd_recentTabManager.btn_SelectAllClick(Sender: TObject);
begin
    list_SelectAll();
end;

procedure Twnd_recentTabManager.btn_SelectNoneClick(Sender: TObject);
begin
    list_SelectNone();
end;

procedure Twnd_recentTabManager.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
    gv_Config.routine_WindowParams_set( Self);
end;

procedure Twnd_recentTabManager.update_Counter_SelectedItems();
var ndx : integer;
begin
    FCounter_SelectedItems := 0;
    for ndx := 0 to lst_RecentTabs.Cnt - 1 do
        FCounter_SelectedItems := FCounter_SelectedItems + Byte( iccRecentTab( wnd_main.RecentTabs[ndx]).Checked);
end;

procedure Twnd_recentTabManager.list_setEach( _bool : Boolean);
var ndx : integer;
begin
    for ndx := 0 to lst_RecentTabs.Cnt - 1 do
       wnd_main.RecentTabs[ndx].Checked := _bool;

    if _bool
        then FCounter_SelectedItems := lst_RecentTabs.Cnt
        else FCounter_SelectedItems := 0;
end;

procedure Twnd_recentTabManager.list_set( _index : Integer; _bool : Boolean);
begin
    iccRecentTab( lst_RecentTabs[_index].Data.ptr).Checked := _bool;
    if _bool
       then FCounter_SelectedItems := FCounter_SelectedItems + 1
       else FCounter_SelectedItems := FCounter_SelectedItems - 1;
end;

procedure Twnd_recentTabManager.list_inv( _index : Integer);
var itm : iccRecentTab;
begin
    itm := wnd_main.RecentTabs[_index];

    itm.Checked := not itm.Checked;

    if itm.Checked
       then FCounter_SelectedItems := FCounter_SelectedItems + 1
       else FCounter_SelectedItems := FCounter_SelectedItems - 1;
end;

procedure Twnd_recentTabManager.list_SelectAll();
begin
    list_setEach( true);
    lst_RecentTabs.Invalidate;
    update_btn_DeleteForever();
end;

procedure Twnd_recentTabManager.list_SelectNone();
begin
    list_setEach( false);
    lst_RecentTabs.Invalidate;
    update_btn_DeleteForever();
end;

procedure Twnd_recentTabManager.list_fill;
var ndx : integer;
begin
    for ndx := 0 to wnd_main.RecentTabs.Count - 1 do
        lst_recentTabs.Add( ndx, iccRecentTab.c_height);
end;

function Twnd_recentTabManager.list_get() : TArray<integer>;
var ndx : integer;
    cnt : integer;
begin
    cnt := 0;

    for ndx := 0 to lst_RecentTabs.Cnt - 1 do
        if wnd_main.RecentTabs[ndx].Checked
            then cnt := cnt + 1;

    SetLength( result, cnt);

    for ndx := 0 to lst_RecentTabs.Cnt - 1 do
        if wnd_main.RecentTabs[ndx].Checked
            then result[ndx] := wnd_main.RecentTabs[ndx].TID;
end;

procedure Twnd_recentTabManager.update_btn_DeleteForever();
begin
    btn_DeleteForever.Enabled := FCounter_SelectedItems <> 0;
end;

end.


