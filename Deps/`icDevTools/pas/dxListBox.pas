unit dxListBox;

// 10.05.10 started.
// ©Pavel Bugaevskiy aka InlineCODER, 2010.
// Inline-CODER@inbox.ru

interface

uses
    Windows,
    Messages,
    SysUtils,
    Variants,
    Classes,
    Graphics,
    Controls,
    StdCtrls,
    Forms,
    Dialogs,
    dxCore,
    dxCoreUtils,
    dxContainer,

    icClasses,
    icUtils;

type
    TdxListBox =
        class( TdxCustomContainer)
            type
                ictItemDataType =
                    record case byte of
                        0: ( ptr : pointer );
                        1: ( dwr : DWORD   );
                    end;

                iccItem =
                    class
                        type
                            ictState = ( isFocused, isSelected);
                            icsState = set of ictState;
                        private
                            FHeight  : WORD;
                            FState   : icsState;
                            FData    : ictItemDataType;
                        public
                            property Height : WORD            read FHeight;
                            property State  : icsState        read FState;
                            property Data   : ictItemDataType read FData;
                    end;

                ictCapturedElements = (
//                                        ceItem,       // нажалась мишка, захват пропадає відразу при mousemove.
                                        ceContent,    //
                                        ceScrollBar   //
                                      );
                icsCapturedElements = set of ictCapturedElements;

                ictOnItemPaintProc     = procedure ( _sender : TObject; _itemIndex : Integer; _itemState : iccItem.icsState; _itemData : ictItemDataType; _canvas : TCanvas; _rect : TRect) of object;
                ictOnItemFocusSetProc  = procedure ( _sender : Tobject;
                                                     _itemIndex : Integer;
                                                     _itemState : iccItem.icsState;
                                                     _itemData : ictItemDataType
                                                   ) of object;
                ictOnItemFocusOffProc  = procedure ( _sender : Tobject;
                                                     _cur_itemIndex : Integer;
                                                     _cur_itemState : iccItem.icsState;
                                                     _cur_itemData  : ictItemDataType;
                                                     _new_itemIndex : Integer;
                                                     _new_itemState : iccItem.icsState;
                                                     _new_itemData  : ictItemDataType
                                                   ) of object;

                ictOnItemMouseDownProc = procedure ( _sender : TObject;
                                                     _itemIndex : Integer;
                                                     _itemState : iccItem.icsState;
                                                     _itemData : ictItemDataType;
                                                     _x : Integer;
                                                     _y : Integer;
                                                     _shift : TShiftState
                                                   ) of object;


                ictOnItemMouseUpProc   = ictOnItemMouseDownProc;

//                ictOnItemMouseMove     = ;
            const
                c_def_itemheight     = 20;

                c_def_ScrollBarWidth = 19;
                c_def_ScrollWidth    = 16;
                c_def_ScrollHeight   = 55;
                c_def_ScrollMargin   = 0;  // top + bottom ( ex: 4 = 2top + 2bottom)
            public //private
                FVScroll : TScrollBar;
                procedure event_VScroll_onScroll( _sender: TObject; _scrollCode: TScrollCode; var _scrollPos: Integer);

                function  prop_get_DoubleClickEnabled() : Boolean;
                procedure prop_set_DoubleClickEnabled( _b : Boolean);

                var
                FList            : iccxList;

                FLOCKED          : Boolean; // <- призначене для того, шоб вказувати певним обработчікам, шо вони можуть не
                                            // виконувати свої дії (наприклад багатократне видалення елементів, немає
                                            // понта 100 раз перемальовути весь компонент. Lock; del 100; Unlock; Paint; )

                FShiftState      : TShiftState; // temporary holder

                FCaptureElements : icsCapturedElements;
                FCaptureMousePos : TPoint;      // координати курсора, при mousedown
                FCaptureKeyState : TShiftState; // клавіши, з якими робився mousedown

                FTopItem         : iccItem;
                FTopItemIndex    : Integer;
                FTopItemOffset   : SmallInt;

                FItemIndex       : Integer;

                FOffset          : Integer;
                FContentHeight   : Integer;

                FOnItemPaint     : ictOnItemPaintProc;
                FOnItemFocusSet  : ictOnItemFocusSetProc;
                FOnItemFocusOff  : ictOnItemFocusOffProc;

                FOnItemMouseDown : ictOnItemMouseDownProc;
                FOnItemMouseUp   : ictOnItemMouseUpProc;

                FSmoothScroll    : Boolean; // CPU Expensive

                FEnabled_StealFocus : Boolean; // setFocus on MouseOver immediately
            public
                procedure msg_DoubleClick( var _msg : TMessage); message WM_LBUTTONDBLCLK; // this method intended for removing Focus bug
            public
                constructor Create( _AOwner : TComponent); override;
                destructor Destroy(); override;
            public
                function Cnt() : Integer;
                //
                function Get     ( _indx : Integer) : iccItem;
                function Get_safe( _indx : Integer) : iccItem; // returns nil on range overflows or other shit
                //
                function Add( _data : DWORD; _height : WORD = c_def_itemheight) : iccItem;
                function Ins( _indx : Integer; _data : DWORD; _height : WORD = c_def_itemheight) : iccItem;
                function Del( _indx : Integer) : Boolean;
                function Clr() : boolean;
            public
                procedure item_focus_SET( _itemIndex : Integer);
                procedure item_MouseDown( _itemIndex : Integer; _itemState : iccItem.icsState; _itemData : ictItemDataType;_x, _y : Integer);
                procedure item_MouseUp  ( _itemIndex : Integer; _itemState : iccItem.icsState; _itemData : ictItemDataType;_x, _y : Integer);
            public
                procedure WMMouseWheel(var Message: TWMMouseWheel); message WM_MOUSEWHEEL;

                procedure Lock;
                procedure Unlock( _paint : boolean = true); // paint content after unlocking

                procedure Paint; override;
                procedure UpdateScrollbar();

                function FindFirstInViewport() : Integer;

                function GetItemPos( var _InIndexOutPosition : Integer; out _item : iccItem) : Boolean; // true is ok, false - not

                // вхідні данні позиція, вихідні - індекс(0, якшо не знайшлося & result=nil) , в іншому випадку все ок. _itemOffsetFrom0 - абсолютна позиція з самого початку
                function GetItemAtPos( var _InPosOutIndex : Integer; out _itemOffsetFrom0 : Integer) : iccItem;
                // видрать айтіма відносно того, що бачимо у в'юпорті.
                function GetItemAtPos_viewport( var _InPosOutIndex : Integer; out _itemOffsetFrom0 : Integer) : iccItem;

                function SetItemHeight( _indx : Integer; _val : WORD) : boolean;

                function ScrollTo( _val : integer; _paint : boolean = true) : Integer; // результат = px, скільки було прокручено в реалі
                function ScrollBy( _val : integer; _paint : boolean = true) : Integer; //

                function ScrollToAbsolute( _val : integer; _paint : boolean = true) : Integer;

                procedure MouseDown(Button:TMouseButton; Shift: TShiftState; X, Y: Integer); override;
                procedure MouseUp(Button:TMouseButton; Shift:TShiftState; X, Y: Integer); override;

                // we want to capture arrow keys and other
                procedure WMGetDlgCode(var message: TMessage); message WM_GETDLGCODE;

                procedure KeyDown  (var Key: Word; Shift: TShiftState); override;
                procedure KeyUp    (var Key: Word; Shift: TShiftState); override;
                procedure KeyPress (var Key: Char); override;

                procedure HookMouseDown; override;
                procedure HookMouseUp; override;
                procedure HookMouseEnter; override;
                procedure HookMouseLeave; override;
                procedure HookMouseMove(X: Integer = 0; Y: Integer = 0); override;
                procedure HookResized(); override;
            public
                property Item[_indx:Integer]:iccItem read Get; default;
                property ItemIndex : Integer read FItemIndex write item_focus_SET;
            published
                property Alignment;
                property BorderWidth;
                property BoundColor;
                property BoundLines;
                property Caption;
                property Color;
                property Enabled;
                property Layout;
                property ParentColor;
                property ShowBoundLines;
                property Left;
                property Top;
                property Width;
                property Height;
                property OnDblClick;
                property OnPaint;
                property OnResize;
            published
                property DoubleClickEnabled : Boolean read prop_get_DoubleClickEnabled write prop_set_DoubleClickEnabled;
                property FocusStealEnabled  : Boolean read FEnabled_StealFocus write FEnabled_StealFocus;

                property OnItemPaint     : ictOnItemPaintProc     read FOnItemPaint     write FOnItemPaint;
                property OnItemFocusSet  : ictOnItemFocusSetProc  read FOnItemFocusSet  write FOnItemFocusSet;
                property OnItemFocusOff  : ictOnItemFocusOffProc  read FOnItemFocusOff  write FOnItemFocusOff;
                property OnItemMouseDown : ictOnItemMouseDownProc read FOnItemMouseDown write FOnItemMouseDown;
                property OnItemMouseUp   : ictOnItemMouseUpProc   read FOnItemMouseUp   write FOnItemMouseUp;
            published
                property SmoothScroll   : Boolean               read FSmoothScroll   write FSmoothScroll default True;
        end;

implementation

{ tdxListBox }

procedure tdxListBox.event_VScroll_onScroll( _sender: TObject; _scrollCode: TScrollCode; var _scrollPos: Integer);
begin
    ScrollTo( _scrollPos);
end;

function  tdxListBox.prop_get_DoubleClickEnabled() : Boolean;
begin
    result := csDoubleClicks in ControlStyle;
end;

procedure tdxListBox.prop_set_DoubleClickEnabled( _b : Boolean);
begin
    if prop_get_DoubleClickEnabled and _b
        then exit;

    if _b
        then ControlStyle := ControlStyle + [csDoubleClicks]
        else ControlStyle := ControlStyle - [csDoubleClicks];
end;

procedure tdxListBox.msg_DoubleClick( var _msg : TMessage);
begin
    HookMouseUp;
    DblClick;
end;

constructor tdxListBox.Create(_AOwner: TComponent);
begin
    inherited;
    Focusable := True;

    FList         := iccxList.Create( 32);

    FCaptureElements   := [];
    FCaptureMousePos.X := 0;
    FCaptureMousePos.Y := 0;
    FCaptureKeyState   := [];

    FTopItem       := nil;
    FTopItemIndex  := 0;
    FTopItemOffset := 0;

    FItemIndex     := -1;

    FOffset        := 0;
    FContentHeight := 0;

    FSmoothScroll  := True;

    FEnabled_StealFocus := True; // gain focus

    // adding scrollbar
    FVScroll                := TScrollBar.Create( self);
    FVScroll.Parent         := Self;
    FVScroll.OnScroll       := event_VScroll_onScroll;
    FVScroll.DoubleBuffered := FALSE; // !
    FVScroll.Kind           := sbVertical;

    FVScroll.Margins.Left   := 1;
    FVScroll.Margins.Top    := 1;
    FVScroll.Margins.Right  := 1;
    FVScroll.Margins.Bottom := 1;

    FVScroll.AlignWithMargins := True;
    FVScroll.Align            := alRight;
end;

destructor tdxListBox.Destroy;
begin
    FOnItemPaint    := nil; // nulling events to avoid problems with calling them
    FOnItemFocusSet := nil; //
    FOnItemFocusOff := nil; //

    Clr;
    FList.Destroy;
    inherited;
end;

function tdxListBox.Cnt() : Integer;
begin
    Result := FList.Cnt;
end;

function tdxListBox.Get( _indx : Integer) : iccItem;
begin
    pDWORD( @result)^ := FList[_indx];
end;

function tdxListBox.Get_safe( _indx : Integer) : iccItem;
begin
    result := nil;

    if    ( _indx < 0)
       or ( _indx >= FList.Count)
        then exit;

    result := Get( _indx);
end;

function tdxListBox.Add( _data : DWORD; _height : WORD = c_def_itemheight) : iccItem;
begin
    result           := iccItem.Create;
    result.FHeight   := _height;
    result.FState    := [];
    result.FData.dwr := _data;
    FList.Add( pDWORD(@result)^ );

    FContentHeight := FContentHeight + result.Height;

    UpdateScrollbar(); // revalidate

    // update content
    if not FLOCKED
        then Invalidate;
end;

function tdxListBox.Ins( _indx : Integer; _data : DWORD; _height : WORD = c_def_itemheight) : iccItem;
begin
    Result           := iccItem.Create;
    Result.FHeight   := _height;
    Result.FState    := [];
    Result.FData.dwr := _data;
    FList.Ins( _indx, pDWORD(@result)^ );

    FContentHeight := FContentHeight + Result.Height;

    // take care about FItemIndex
    if _indx <= FItemIndex
        then FItemIndex := FItemIndex + 1;

    UpdateScrollbar(); // revalidate

    // update content
    if not FLOCKED
        then Invalidate
end;

function tdxListBox.Del( _indx : Integer) : Boolean;
begin
    ScrollTo( 0, false); // temporarily defaults scroll position on 0 after deleting

    ////focus_OFF( FItemIndex);
    //item_focus_SET( _indx);
    if FItemIndex <> -1
        then if _indx <= FItemIndex
                 then FItemIndex := FItemIndex - 1;


    with Get(_indx) do
        begin
            FList.Del( _indx);
            FContentHeight := FContentHeight - Height;
            Destroy;
        end;

    // set default item state
    if FList.Cnt > 0
        then for _indx := 0 to FList.Cnt - 1 do
                 Get( _indx).FState := [];


    //FItemIndex := -1;
    if FItemIndex <> -1
        then ItemIndex := FItemIndex;
    UpdateScrollbar(); // revalidate


    // update content
    if not FLOCKED
        then Invalidate;

    result := true;
end;

function tdxListBox.Clr() : boolean;
var ndx : Integer;
begin
    //focus_OFF( FItemIndex);
    item_focus_SET( -1);
    for ndx := FList.Cnt - 1 downto 0 do
        Get( ndx).Destroy;
    FList.Clr;

    FItemIndex     := -1;
    FTopItem       := nil;
    FTopItemIndex  := 0;
    FTopItemOffset := 0;
    FOffset        := 0;
    FContentHeight := 0;

    UpdateScrollbar(); // revalidate

    // update content
    if not FLOCKED
        then Invalidate;

    result := true;
end;

procedure TdxListBox.item_focus_SET( _itemIndex : Integer);
var cur_item : iccItem;
    new_item : iccItem;

    new_item_state : iccItem.icsState;
    new_item_data  : ictItemDataType;

    // ensure focus
    tmpPos : Integer;
    tmpItm : iccItem;
begin
    // old item should be unfocused as first

    // ensure safezone
//    if _itemIndex < 0
//        then _itemIndex := 0;
    if _itemIndex >= FList.Cnt
        then _itemIndex := FList.Cnt - 1;
//    if _itemIndex = FItemIndex
//        then exit;



    cur_item := Get_safe( FItemIndex);
    new_item := Get_safe( _itemIndex);
    if new_item = nil
        then begin
                 new_item_state    := [];
                 new_item_data.ptr := nil;

                 _itemIndex    := -1;
             end
        else begin
                 new_item_state := new_item.State;
                 new_item_data  := new_item.Data;

                 //_itemIndex := _itemIndex; :)
             end;

    //// FOCUS OFF
    if (cur_item <> nil) and (isFocused in cur_item.State)
        then begin
                 Exclude( cur_item.FState, isFocused);
                 if Assigned( FOnItemFocusOff)
                     then FOnItemFocusOff( self,
                                           FItemIndex,
                                           cur_item.State,
                                           cur_item.Data,
                                           _itemIndex,
                                           new_item_state,
                                           new_item_data
                                         );
             end;

    FItemIndex := -1; // important!

    //// FOCUS ON
    if (new_item <> nil) and not ( isFocused in new_item.State)
        then begin
                 FItemIndex := _itemIndex;
                 Include( new_item.FState, isFocused);
                 if Assigned( FOnItemFocusSet)
                     then FOnItemFocusSet( self, _itemIndex, new_item.State, new_item.Data);
             end;



    // Ensure item is visible
    tmpPos := FItemIndex;
    GetItemPos( tmpPos, tmpItm);

    if ( tmpPos = -1) or ( tmpItm = nil)
        then exit;

    if     ( tmpPos - tmpItm.Height < FOffset + FTopItemOffset)
       or  ( tmpPos + tmpItm.Height > FOffset + FTopItemOffset + Height)
        then ScrollTo( tmpPos, false);
end;

procedure tdxListBox.item_MouseDown( _itemIndex : Integer; _itemState : iccItem.icsState; _itemData : ictItemDataType;_x, _y : Integer);
begin
    if Assigned( FOnItemMouseDown)
        then FOnItemMouseDown( self, _itemIndex, _itemState, _itemData, _x, _y, FShiftState);
end;

procedure tdxListBox.item_MouseUp  ( _itemIndex : Integer; _itemState : iccItem.icsState; _itemData : ictItemDataType;_x, _y : Integer);
begin
    if Assigned( FOnItemMouseUp)
        then FOnItemMouseDown( self, _itemIndex, _itemState, _itemData, _x, _y, FShiftState);
end;

procedure tdxListBox.Paint;
var rct     : trect;

    drawn   : WORD;
    drawnpx : WORD;

    item    : iccItem;
begin
    rct := GetClientRect;

    canvas.Brush.Color := Self.Color;
    canvas.FillRect(rct);
    if csDesigning in ComponentState
        then canvas.DrawFocusRect(rct);


    ///////////////
    drawn   := 0;
    drawnpx := 0;

    while (drawnpx < Height-FTopItemOffset) and (drawn+FTopItemIndex < FList.Cnt) do
        begin
            item := Get(drawn+FTopItemIndex);

             if drawnpx + item.Height + FTopItemOffset > 0
                 then if Assigned( FOnItemPaint)
                          then FOnItemPaint( self, drawn+FTopItemIndex, item.State, item.Data, canvas, bounds( 0, drawnpx+FTopItemOffset, width-c_def_ScrollBarWidth, item.Height));

             drawn   := drawn   + 1;
             drawnpx := drawnpx + item.Height;
        end;

    ///////////////
    ///
    //inherited;
    if Assigned( OnPaint)
        then OnPaint( Self, rct, Canvas, Font);

    if ( showboundlines) and ( boundlines <> [])
        then dxDrawBoundLines( self.canvas, boundlines, boundColor, rct);
end;

procedure tdxListBox.UpdateScrollbar();
begin
    if FContentHeight < Height
        then begin
                 FVScroll.Enabled := False;
                 exit;
             end
        else if not FVScroll.Enabled
                 then begin
                          FVScroll.Enabled := True;
                      end;

    FVScroll.Max      := FContentHeight;
    FVScroll.PageSize := Height;
    FVScroll.Position := FOffset;
end;

procedure tdxListBox.MouseDown(Button:TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
    FShiftState := Shift; // push

    if Button = mbLeft
        then begin
                 // define captured elements
                 if X < Width - c_def_ScrollBarWidth
                     then FCaptureElements := [ ceContent]
                     else FCaptureElements := [ ceScrollBar];

                 FCaptureMousePos.X := X;
                 FCaptureMousePos.Y := Y;

                 FCaptureKeyState   := Shift;
             end;

    inherited;
end;

procedure tdxListBox.MouseUp(Button:TMouseButton; Shift:TShiftState; X, Y: Integer);
begin
    inherited;
end;

procedure tdxListBox.WMGetDlgCode(var message: TMessage);
begin
    message.Result := DLGC_WANTARROWS or DLGC_WANTCHARS;
end;

procedure tdxListBox.KeyDown(var Key: Word; Shift: TShiftState);
begin
    case Key of
       VK_UP
           : begin
                  if ItemIndex - 1 >= 0
                      then ItemIndex := ItemIndex - 1;
                  Invalidate();
             end;
       VK_DOWN
           : begin
                  ItemIndex := ItemIndex + 1;
                  Invalidate();
             end;
//       VK_LEFT
//           : begin
//             end;
//       VK_LEFT
//           : begin
//             end;
    end;


    inherited;
end;

procedure tdxListBox.KeyUp(var Key: Word; Shift: TShiftState);
begin
    inherited;
end;

procedure tdxListBox.KeyPress(var Key: Char);
begin
    inherited;
end;

procedure tdxListBox.HookMouseDown;
var excs : TdxControlStyle;
    ipos : Integer;
    iof0 : Integer;

    item1 : iccItem;

    procedure MouseDown_Content();
    begin
        ipos := FOffset + FTopItemOffset + FCaptureMousePos.Y;
        item1 := GetItemAtPos( ipos, iof0);

        if item1 = nil then ipos := -1;

        // here we have all needed data
        item_focus_SET( ipos);

        //
        if ipos <> -1
            then item_MouseDown( ipos, item1.State, item1.Data, FCaptureMousePos.X, FCaptureMousePos.Y - iof0);
    end;

    procedure MouseDown_ScrollBar();
    var pos : integer;
    begin
        pos := Height - c_def_ScrollHeight - c_def_ScrollMargin;
        pos := round( ( (FContentHeight-height) / pos) * (FCaptureMousePos.Y - c_def_ScrollHeight div 2));

        ScrollTo( pos);
    end;

begin
    excs := ExControlStyle;
    Exclude( ExControlStyle, csRedrawMouseDown); // do not redraw in inherited
    inherited;      // <- COMMENTED, in case of BringingToFront parent windows on Double Click
    ExControlStyle := excs;

    //////////////////////////////
    ///  set capture
    if ceContent   in FCaptureElements
        then MouseDown_Content;

    if ceScrollBar in FCaptureElements
        then MouseDown_ScrollBar;
    //////////////////////////////

    if csRedrawMouseDown in ExControlStyle // standart behavior
        then InternalRedraw;
end;

procedure tdxListBox.HookMouseUp;
var excs : TdxControlStyle;
begin
    excs := ExControlStyle;
    Exclude( ExControlStyle, csRedrawMouseUp); // do not redraw in inherited
    inherited;
    ExControlStyle := excs;


    //////////////////////////////
    ///  release everything

    if FContentHeight > Height then
    if FOffset < 0
        then begin
                 ScrollTo( 0);

//                 tmp := FOffset div 2 * -1;
//                 while FOffset < 0 do
//                     begin
//                         ScrollToAbsolute( FOffset + tmp, false);
//                         tmp := tmp div 2; if tmp = 0 then tmp := 1;
//                         Repaint;
//                         sleep(16);
//                     end;
             end
        else begin
                 if FOffset + height > FContentHeight
                     then ScrollTo( FContentHeight); // overflow will be cut

//                 tmp := (FOffset + Height - FContentHeight) div 2;
//                 while FOffset + height > FContentHeight do
//                     begin
//                         ScrollToAbsolute( FOffset - tmp, false);
//                         tmp := tmp div 2; if tmp = 0 then tmp := 1;
//                         repaint;
//                         sleep(16);
//                     end;
             end;

    FCaptureElements := [];

    //ScrollBy(0, false);
    //////////////////////////////

    if csRedrawMouseDown in ExControlStyle // standart behavior
        then InternalRedraw;
end;

procedure tdxListBox.HookMouseEnter;
begin
//    SetFocus();
    if FEnabled_StealFocus
        then Windows.SetFocus( Handle);
    inherited;
end;

procedure tdxListBox.HookMouseLeave;
begin
    inherited;
end;

var ic : dword;
procedure tdxListBox.HookMouseMove(X: Integer = 0; Y: Integer = 0);
var pos : integer;
    tmp : DWORD;
begin
    if FCaptureElements = []
        then exit;

    tmp := GetTickCount;
    if tmp - ic > 32   // perfomance improve
        then ic := tmp
        else exit;

    if ceContent    in FCaptureElements
        then begin
//                 pos := Height;
//                 pos := round( ( (FContentHeight-height) / pos) * ( FCaptureMousePos.Y - Y));


                 pos := FCaptureMousePos.Y - Y;
                 FCaptureMousePos.Y := Y;

                 if pos = 0
                     then exit; // small optimize

                 if ( (pos + FOffset < 0) and (pos<0) ) or
                    ( (pos + FOffset > FContentHeight - Height) and (pos>0) )
                     then pos := pos div 2;


                 //ScrollBy( pos);
                 ScrollToAbsolute( pos + FOffset);
             end;


     if ceScrollBar in FCaptureElements
        then begin
                 pos := Height - c_def_ScrollHeight - c_def_ScrollMargin;
                 pos := round( ( (FContentHeight-height) / pos) * (Y - c_def_ScrollHeight div 2));

                 ScrollTo( pos);
             end;
end;

function tdxListBox.FindFirstInViewport() : Integer;
var off : integer;
    ith : WORD;
begin
    result := 0;
    off    := -FOffset;
    while (result < Cnt) do
        begin
            ith := Get( result).Height;

            if off + ith >= 0
                then begin
                         FTopItemOffset := off;
                         break;
                     end;

            off    := off + ith;
            result := result + 1;
        end;
end;

function tdxListBox.GetItemPos( var _InIndexOutPosition : Integer; out _item : iccItem) : Boolean;
var ndx : integer;

    item   : iccItem;
    offset : integer;
begin
    result := false;
    _item  := nil;

    // check
    if     ( _InIndexOutPosition < 0)
       or  ( _InIndexOutPosition >= FList.Count)
        then begin
                 _InIndexOutPosition := -1;
                 exit;
             end;


    // search
    offset := 0;
    for ndx := 0 to FList.Count - 1 do
        begin
            item := iccItem( FList.Item[ndx]);

            if ndx = _InIndexOutPosition
                then begin
                         _InIndexOutPosition := offset;
                         _item := item;
                         exit( true);
                     end;

            offset := offset + item.Height;
        end;
end;

function tdxListBox.GetItemAtPos( var _InPosOutIndex : Integer; out _itemOffsetFrom0 : Integer) : iccItem;
var indx : Integer;
    lndx : Integer;   // limit index
    tmp  : Integer;
    item : iccitem;
begin
    result := nil;
    if ( cnt = 0) or ( _InPosOutIndex > Integer(FContentHeight) ) or ( FOffset + _InPosOutIndex < 0)
        then exit;

    _InPosOutIndex := _InPosOutIndex - FTopItemOffset;

    item  := nil;
    tmp   := 0;
    indx  := 0;

    if _InPosOutIndex >= FOffset
        then begin
                 indx := FTopItemIndex;
                 item := Get(indx);
                 tmp  := FTopItemOffset;
                 _InPosOutIndex := _InPosOutIndex - FOffset;

                 lndx := Cnt - 1;
                 while indx < lndx do
                     begin
                         if ( tmp <= _InPosOutIndex) and ( tmp + item.Height >= _InPosOutIndex)
                             then break;

                         tmp  := tmp + item.Height;

                         indx := indx + 1;
                         item := Get( indx);
                     end;
             end
        else begin
                 //raise iccException.Create( 'tdxListBox.GetItemAtPos() -> Item index beyond visible area not implemented yet...');
             end;

    _InPosOutIndex   := indx;
    _itemOffsetFrom0 := tmp;
    result         := item;
end;

function tdxListBox.GetItemAtPos_viewport( var _InPosOutIndex : Integer; out _itemOffsetFrom0 : Integer) : iccItem;
begin
    _InPosOutIndex := _InPosOutIndex + FOffset + FTopItemOffset;
    Result := GetItemAtPos( _InPosOutIndex, _itemOffsetFrom0);
end;

function tdxListBox.SetItemHeight( _indx : Integer; _val : WORD) : boolean;
var item : iccItem;
begin
    item := Get( _indx);
    FContentHeight := FContentHeight + _val - item.Height;
    item.FHeight   := _val;

    // update content
    if not FLOCKED
        then Invalidate;

    Result := true;
end;

function tdxListBox.ScrollTo( _val : integer; _paint : boolean = true) : Integer;
var ndx : byte;
    tmp : integer;
begin
    if FContentHeight < Height
        then begin
                 FTopItemOffset := 0;
                 exit(0);
             end;

    if _val < 0
        then begin
                 _val := 0;
                 FTopItemOffset := 0;
             end;

    if _val > FContentHeight - Height
        then _val := FContentHeight - Height;// - FOffset;

    if _val = FOffset
        then exit( 0); // nothing to draw

    if _paint and FSmoothScroll
        then begin
                 tmp := _val;
                 if Abs(tmp - FOffset) > 5
                     then begin
                              tmp := trunc( (tmp - FOffset) / 5);

                              for ndx := 1 to 4 do
                              begin
                                  FOffset := FOffset + tmp + trunc(0.2 * ndx);
                                  FTopItemIndex := FindFirstInViewport;

                                  Repaint;
                                  UpdateScrollbar();
                                  sleep( 10);
                              end;
                          end;
             end;

    FOffset       := _val;
    FTopItemIndex := FindFirstInViewport;

    UpdateScrollbar();

    if ( _paint) and ( not FLOCKED)
        then Invalidate;

    result := 0;
end;

function tdxListBox.ScrollBy( _val : integer; _paint : boolean = true) : Integer;
begin
    Result := ScrollTo( FOffset + _val, _paint);
end;

function tdxListBox.ScrollToAbsolute( _val : integer; _paint : boolean = true) : Integer;
var ndx : byte;
    tmp : Integer;
begin
    if FContentHeight < Height
        then begin
                 FTopItemOffset := 0;
                 exit(0);
             end;

    if _val < 0
        then FTopItemOffset := 0;

    if _paint and FSmoothScroll
        then begin
                 tmp := _val;
                 if Abs(tmp - FOffset) > 5
                     then begin
                              tmp := trunc( (tmp - FOffset) / 5);

                              for ndx := 1 to 4 do
                              begin
                                  FOffset := FOffset + tmp + trunc(0.2 * ndx);
                                  FTopItemIndex := FindFirstInViewport;

                                  Repaint;
                                  UpdateScrollbar();
                                  sleep( 4);
                              end;
                          end;
             end;

    FOffset       := _val;
    FTopItemIndex := FindFirstInViewport;


    UpdateScrollbar();


    if ( _paint) and ( not FLOCKED)
        then Invalidate;

    result := 0;
end;

procedure tdxListBox.HookResized();
begin
    if FContentHeight > Height
        then begin
                 if Height + FOffset > FContentHeight
                     then FOffset := FContentHeight - Height;
                 FTopItemIndex := FindFirstInViewport;
             end
        else begin
                 FOffset        := 0;
                 FTopItemOffset := 0;
             end;


    UpdateScrollbar();


    inherited;
end;

procedure tdxListBox.WMMouseWheel(var Message: TWMMouseWheel);
var val : integer;
begin
    val := -Message.WheelDelta div 2;

    if Message.Keys = 4 // shift
        then val := val * 20
        else if Message.Keys = 8 // control
                 then val := val * 5;

    ScrollBy( val);

    Message.Result := 0;
end;

procedure tdxListBox.Lock;
begin
    FLOCKED := True;
end;

procedure tdxListBox.Unlock( _paint : boolean = true);
begin
    FLOCKED := False;
    if _paint
        then Invalidate;
end;

end.
