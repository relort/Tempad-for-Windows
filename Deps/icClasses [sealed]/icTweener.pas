unit icTweener;

interface

uses
    Windows,
    Messages,

    Classes,
    Controls,

    icClasses,
    icTweenerEasings;


type
    //    iccTweener  -> static class
    iccTweener =
        class sealed( iccObject)
            type
                ictEasingFunc     = function ( _p : Extended; _firstNum : integer; _diff : integer) : Extended;
                ictTweenEvent     = reference to procedure ();
                ictTweenTickEvent = reference to procedure ( _val : Extended);
            type
                iciTween =
                    interface( IInterface)
                        function ID(): DWORD; // get tween ID

                        procedure reset();
                        procedure start();
                        procedure stop();
                    end;
            strict private type
                iccTween =
                    class( iccInterfacedObject, iciTween)
                        private const
                            c_FrameDataTick = 100;
                        protected type
                            iccTweenEventObjectEventData =
                                class
                                    public
                                        tween : iccTween; // tween
                                        index : WORD;     // value to pass into iccTween(*).process( _ndx)
                                    public
                                        constructor Create( _tween : iccTween; _index : WORD);
                                end;

                            ictTweenState = ( tsCreating,
                                              tsCreated,

                                              tsDestroying,
                                              tsDestroyed,

                                              tsStopped,
                                              tsStarted,

                                              tsClearingData
                                            );
                            icsTweenState = set of ictTweenState;

                        public
                            function _Release() : Integer; override;

                        strict private
                            FID : DWORD; // UID
                            FState : icsTweenState; // ictTweenState;

                            FEventNotifier : iccEventNotifier;
                            FEventObject   : iccEventNotifier.iciEventObject;

                            FControl  : TControl; // operate with
                            FProperty : String;   // property of FControl to be changed

                            FFrom,
                            FTo       : SmallInt;  // from -> to values

                            FTime,
                            FDelay    : WORD;     // time and delay in ms.

                            FFPS      : Byte;     // fps

                            FEasingFunc : ictEasingFunc;

                            FOnStart,
                            FOnFinish : ictTweenEvent;

                            FOnTick   : ictTweenTickEvent;


                            FFrameDataList : iccxList;
                            FCurrentIndex  : WORD;
                        strict private
                            procedure deploy();
                        protected
                            procedure process( _ndx : WORD); // frame index to process
                            procedure clearData(); // clear allocated TweenEventObjectEventDatas
                        public
                            constructor Create( _eventNotifier : iccEventNotifier;
                                                _receiver      : HWND;
                                                _control       : TControl;
                                                _property      : String;
                                                _from          : SmallInt;
                                                _to            : SmallInt;
                                                _time          : WORD = 1000;
                                                _delay         : WORD = 0;
                                                _fps           : Byte = 60;
                                                _easingFunc    : ictEasingFunc = nil;
                                                _onStart       : ictTweenEvent = nil;
                                                _onFinish      : ictTweenEvent = nil;
                                                _onTick        : ictTweenTickEvent = nil
                                              );
                            destructor Destroy(); override;
                        public
                            function ID() : DWORD;

                            procedure reset();
                            procedure start();  // start from begin
                            procedure stop();   // stop execution. reset -> currentIndex := 0;
                    end;
            strict private
                class var TWEENING_ENABLED : Boolean;

                class var MsgReceiver   : HWND;
                procedure MsgReceiver_wndMethod( var _msg : TMessage);

                class var EventNotifier : iccEventNotifier;
                class var TweenList     : iccxList;

                class function locateTweenInList( _tweenID : DWORD) : DWORD; // FFFFFFFF, not present. not 0, because 0 is a first item in list

            strict private                          // This section intended for
                class var FLastUID : DWORD;         // 0 is default   // providing unique id
            protected                               // for iccTween
                class function getUID : DWORD;      //

            protected // functions to be calles from iccTween when needed: addToList at Create & DelFromList when object gonna be deleted
                class function addToList( _tween : iccTween) : Boolean;
                class function DelFromList( _tween : iccTween) : Boolean;

            public
                constructor Create(); // throw error. static class
                destructor Destroy(); override; // throw error. static class
            public
                class function EnableTWEENING()   : Boolean;
                class function DisableTWEENING()  : Boolean;
                class function IsTWEENINGEnabled() : Boolean;

                class function checkIfAvail( _tweenID : DWORD) : Boolean; // be sure that we can operate with _tween
                class function checkStopAndNil( var _iTween : iciTween) : Boolean; // if not nil then _iTween.stop and _iTween := nil

                class function addTween( _control    : TControl;
                                         _property   : String;
                                         _from       : SmallInt;
                                         _to         : SmallInt;
                                         _time       : WORD = 1000; // ms
                                         _delay      : WORD = 0;    // ms
                                         _fps        : Byte = 60;
                                         _easingFunc : ictEasingFunc = nil;
                                         _onStart    : ictTweenEvent = nil;
                                         _onFinish   : ictTweenEvent = nil;
                                         _onTick     : ictTweenTickEvent = nil
                                       ) : iciTween; // Tween ID
        end;

implementation

{ iccTweenEventObjectEventData }

constructor iccTweener.iccTween.iccTweenEventObjectEventData.Create( _tween : iccTween; _index : WORD);
begin
    tween := _tween;
    index := _index;
end;

{ iccTween }

function iccTweener.iccTween._Release() : Integer;
begin
    if self = nil
        then raise iccException.Create('SELF = NIL');

    if ( tsStarted in FState) and ( FRefCount = 1) // FRefCount = 1. do not stop animation if any variable is referencing this one
        then begin
                 Include( FState, tsStopped);
                 Exclude( FState, tsStarted);
             end;

    result := inherited;
end;

procedure iccTweener.iccTween.deploy();
var ndx      : integer;
    tmpDelay : WORD;
    frmCount : WORD;
    tmp      : iccTweenEventObjectEventData;
begin
    if self = nil
        then raise iccException.Create('SELF = NIL');

    if tsClearingData in FState
        then raise iccException.Create( 'tsClearingData');
    if FEventObject = nil
        then raise iccException.Create( 'Event object is not avail.');
    if FFrameDataList = nil
        then raise iccException.Create( 'List = nil.');
    if FFrameDataList.Count = 0
        then raise iccException.Create( 'Count = 0.');




    tmpDelay := 0;
    if FCurrentIndex = 0 // if starting from 1 frame use delay
        then tmpDelay := FDelay;

    frmCount := c_FrameDataTick; // default count of frames to add at time
    if frmCount + FCurrentIndex > round( FFps / 1000 * Ftime)
        then frmCount := round( FFps / 1000 * Ftime) - FCurrentIndex; // limit frame count at the end


    FEventObject.Lock();

    for ndx := FCurrentIndex to FCurrentIndex + frmCount - 1 do
        begin
            tmp := iccTweenEventObjectEventData( FFrameDataList[ ndx]);
            FEventObject.AddEvent( DWORD( tmp), round( ( 1000 / FFps ) * (ndx-FCurrentIndex)) + tmpDelay);
        end;

    FEventObject.Unlock();
end;

procedure iccTweener.iccTween.process( _ndx : WORD);
var tmpVal : Extended;
begin
    if self = nil
        then begin
//                 writeln( 'process() -> self = nil.');
                 exit;
             end;


    if tsStopped in FState
        then //raise iccException.Create( 'tsStopped');
             begin
//                 writeln( 'iccTween( self).process() -> tsStopped');
                 exit;
             end;
    if FEventObject = nil
        then //raise iccException.Create( 'Event object is not avail.');
             begin
//                 writeln( 'iccTween( self).process() -> EventObject is not avail.');
                 exit;
             end;
    if FFrameDataList = nil
        then //raise iccException.Create( 'List = nil.');
             begin
//                 writeln( 'iccTween( self).process() -> FFrameDataList = nil');
                 exit;
             end;
    if FFrameDataList.Count = 0
        then //raise iccException.Create( 'Count = 0.');
             begin
//                 writeln( 'iccTween( self).process() -> FFrameDataList.Count = 0.');
                 exit;
             end;




    // _ndx is a frame index, so (index 0) = (frame 1)

    FCurrentIndex := _ndx;

    //
    if FCurrentIndex = 0
        then if Assigned( FOnStart)
                 then FOnStart();


    if @FEasingFunc <> nil
        then tmpVal := FEasingFunc( ( 1 / (Ffps / 1000 * Ftime)) * (_ndx+1), FFrom, FTo - FFrom) // ndx + 1, because indexes starts from 0, but frame starts from 1
        else tmpVal := FTo;

    // do smth with control
    if FProperty = 'left'
       then FControl.Left   := round( tmpVal)
       else
    if FProperty = 'top'
       then FControl.Top    := round( tmpVal)
       else
    if FProperty = 'width'
       then FControl.width  := round( tmpVal)
       else
    if FProperty = 'height'
       then FControl.height := round( tmpVal);

    //
    if FFrameDataList <> nil
        then if FCurrentIndex = FFrameDataList.Cnt - 1
             then if Assigned( FOnFinish)
                      then FOnFinish()
                      else
             else
        else exit();


    // add items to EventObject if needed
    if (FCurrentIndex <> 0) and ( (FCurrentIndex mod (c_FrameDataTick - 1)) = 0)
        then begin
                 FCurrentIndex := FCurrentIndex + 1; // !!!
                 deploy();
             end;

    /////
    if FFrameDataList = nil
        then raise iccException.Create( 'FFrameDataList = nil');

    if FCurrentIndex = FFrameDataList.Cnt - 1
        then stop();
end;

procedure iccTweener.iccTween.clearData();
var ndx : integer;
    tmp : iccxList;
begin
    if self = nil
        then raise iccException.Create('SELF = NIL');

//    if tsDestroyed in FState
//        then //raise iccException.Create( 'destroyed... mother fuck!');
//             begin
//                 writeln( 'iccTween( self).clearData() -> tsDestroyed');
//                 exit;
//             end;

//    if tsClearingData in FState
//        then //raise iccException.Create( 'clearData() -> Fuck off!');
//             begin
//                 writeln( 'iccTween( self).clearData() -> tsClearingData');
//                 exit;
//             end;
    Include( FState, tsClearingData);

    if FEventObject = nil
        then //raise iccException.Create( 'Event object is not avail.');
             begin
//                 writeln( 'iccTween( self).clearData() -> EventObject is not avail.');
                 exit;
             end;
    if FFrameDataList = nil
        then //raise iccException.Create( 'List = nil.');
             begin
//                 writeln( 'iccTween( self).clearData() -> FFrameDataList = nil');
                 exit;
             end;



    FEventObject.ClrQueue;

    // delete all
    tmp := FFrameDataList; // push
    FFrameDataList := nil; // secure
    for ndx := 0 to tmp.Cnt - 1 do
        iccTweenEventObjectEventData( tmp[ndx]).Destroy();
//    for ndx := 0 to FFrameDataList.Cnt - 1 do
//        iccTweenEventObjectEventData( FFrameDataList[ndx]).Destroy;
//    FFrameDataList.Clr;

    tmp.Destroy();


    FFrameDataList := iccxList.Create(); // create new for security purposes

    // say that we were cleared
    Exclude( FState, tsClearingData);
end;

constructor iccTweener.iccTween.create( _eventNotifier : iccEventNotifier;
                                        _receiver      : HWND;
                                        _control       : TControl;
                                        _property      : String;
                                        _from          : SmallInt;
                                        _to            : SmallInt;
                                        _time          : WORD = 1000;
                                        _delay         : WORD = 0;
                                        _fps           : Byte = 60;
                                        _easingFunc    : ictEasingFunc = nil;
                                        _onStart       : ictTweenEvent = nil;
                                        _onFinish      : ictTweenEvent = nil;
                                        _onTick        : ictTweenTickEvent = nil
                                      );
begin
    inherited Create;
        INCLUDE( FSTATE, tsCreating);



    FID    := iccTweener.getUID();
    FState := [tsStopped]; //tsStopped;

    // link reference
    FEventNotifier := _eventNotifier;
    FEventObject   := FEventNotifier.RegisterEventObject;
    if FEventObject = nil
        then raise iccException.Create('Could not RegisterEventObject.');
    FEventObject.setReceiver( _receiver);

    FControl     := _control;
    FProperty    := _property;
    FFrom        := _from;
    FTo          := _to;
    FTime        := _time;
    FDelay       := _delay;
    FFPS         := _fps;
    if @_easingFunc = nil
        then FEasingFunc  := easing_Back_In
        else FEasingFunc  := _easingFunc;
    FOnStart     := _onStart;
    FOnFinish    := _onFinish;
    FOnTick      := _onTick;

    // create list
    FFrameDataList := iccxList.Create();


    iccTweener.addToList( self); // iccTweener add me to list pls.



        INCLUDE( FSTATE, tsCreated);
        EXCLUDE( FSTATE, tsCreating);
end;

destructor iccTweener.iccTween.destroy();
begin
    if self = nil
        then raise iccException.Create('Destroying while self = nil. WTF?');


        INCLUDE( FSTATE, tsDestroying);


    iccTweener.DelFromList( self); // iccTweener remover me from list pls.


    stop();

    // unregister
    if not FEventNotifier.UnregisterEventObject( FEventObject)
        then raise iccException.Create( 'Could not UnregisterEventObject');

    // destroy list
    FFrameDataList.Destroy;


        INCLUDE( FSTATE, tsDestroyed);
        EXCLUDE( FSTATE, tsDestroying);
    inherited;
end;

function iccTweener.iccTween.ID() : DWORD;
begin
    result := FID;
end;

procedure iccTweener.iccTween.reset();
begin
    stop();
    FCurrentIndex := 0;
end;

procedure iccTweener.iccTween.start();
var ndx : integer;
    tmp : iccTweenEventObjectEventData;
begin
    if not ( tsStopped in FState)
        then Stop();

    if tsStopped in FState // _AddRef(); to be sure that object will be alive all the animation time
        then _AddRef;

    reset(); // <-- !!!


    // add frames data, but not add them all to EventObject (performance)
    for ndx := FCurrentIndex to round( FFps / 1000 * Ftime) - 1 do
        begin
            tmp := iccTweenEventObjectEventData.Create( self, ndx);

            if not FFrameDataList.add( DWORD( tmp))
                then raise iccException.Create('iccTween.start() -> Adding item to list failed.');
        end;

    deploy();

    // SET NEW STATE
    Include( FState, tsStarted);
    Exclude( FState, tsStopped);
end;

procedure iccTweener.iccTween.stop();
begin
    clearData();

    if tsStarted in FState {FState = tsStarted} // if Tween was started, then we must _Release, because Start() -> _AddRef();
        then _Release;

    // SET NEW STATE
    Include( FState, tsStopped);
    Exclude( FState, tsStarted);
end;

{ iccTweener }

class function iccTweener.locateTweenInList( _tweenID : DWORD) : DWORD; // FFFFFFFF, not present
var ndx : DWORD;
begin
    // this search is linear without any optimization, but
    // it is more than enough, because not so many iccTween
    // will be present in list at time

    result := $FFFFFFFF; // not found
    if (TweenList = nil) or (TweenList.Cnt = 0)
        then exit;

    for ndx := 0 to TweenList.Cnt - 1 do
        if iccTween( TweenList[ndx]).ID = _tweenID
            then exit( ndx);
end;

class function iccTweener.getUID() : DWORD;
begin
    inc( FLastUID); // not 0
    result := FLastUID;
end;

class function iccTweener.addToList( _tween : iccTween) : Boolean;
begin
    result := TweenList.Add( DWORD( _tween));
end;

class function iccTweener.DelFromList( _tween : iccTween) : Boolean;
var ndx : DWORD;
begin
    ndx := locateTweenInList( _tween.ID);
    if ndx <> $FFFFFFFF
        then result := TweenList.Del( ndx)
        else raise iccException.Create('Error Message');
end;

constructor iccTweener.Create;
begin
    raise iccException.Create('iccTweener is a static class and can not be instantiated.');
end;

destructor iccTweener.Destroy();
begin
    raise iccException.Create('iccTweener is a static class.');
end;

procedure iccTweener.MsgReceiver_wndMethod( var _msg : TMessage);
begin
    // self is not accessible here!!!

    if _msg.Msg <> iccEventNotifier.c_EventNotifierMsg
        then //DefaultHandler( _msg); // WindowsXp -> AccessViolations and other problems
             exit(); // good on both WindowsXp and Windows 7

    try
        with iccTween.iccTweenEventObjectEventData( _msg.LParam) do
            tween.process( index);
    except
        //writeln( _msg.LParam);
    end;
end;

class function iccTweener.IsTWEENINGEnabled() : Boolean;
begin
    result := TWEENING_ENABLED;
end;

class function iccTweener.checkIfAvail( _tweenID : DWORD) : Boolean;
begin
    result := locateTweenInList( _tweenId) <> $FFFFFFFF;
end;

class function iccTweener.checkStopAndNil( var _iTween : iciTween) : Boolean;
begin
    result := false;
    if _iTween = nil
        then exit;

    _iTween.stop();
    _iTween := nil;

    result := true;
end;

class function iccTweener.EnableTWEENING()  : Boolean;
begin
    result := true;
    if ( TWEENING_ENABLED)
        then exit; // already ENABLED

    // prepare list
    TweenList := iccxList.Create();

    // allocating message receiver
    MsgReceiver := AllocateHWnd( iccTweener(nil{!!!}).MsgReceiver_wndMethod);

    // creating Event Notifier
    EventNotifier := iccEventNotifier.Create();

    // set to TRUE
    TWEENING_ENABLED := true;


    // result
    result := TWEENING_ENABLED;
end;

class function iccTweener.DisableTWEENING() : Boolean;
var ndx : integer;
begin
    if ( not TWEENING_ENABLED)
        then raise iccException.Create('DisabledTWEENING() is a closure for EnableTWEENING().');

    // clear allocated Tweens
    for ndx := TweenList.Cnt - 1 downto 0 do
        iccTween( TweenList[ndx]).stop();

    if TweenList.Cnt <> 0
        then raise iccException.Create('DisableTWEENING() -> There some reference link left.');

    // destroy Event Notifier
    EventNotifier.Destroy();

    // deallocate message receiver
    DeallocateHWnd( MsgReceiver);

    // deallocate list
    TweenList.Destroy();

    // set to false
    TWEENING_ENABLED := false;

    // result
    result := TWEENING_ENABLED;
end;

class function iccTweener.addTween( _control    : TControl;
                                    _property   : String;
                                    _from       : SmallInt;
                                    _to         : SmallInt;
                                    _time       : WORD = 1000; // ms
                                    _delay      : WORD = 0;    // ms
                                    _fps        : Byte = 60;
                                    _easingFunc : ictEasingFunc = nil;
                                    _onStart    : ictTweenEvent = nil;
                                    _onFinish   : ictTweenEvent = nil;
                                    _onTick     : ictTweenTickEvent = nil
                                   ) : iciTween;
var tmp : iccTween;
begin
    result := nil; // default value
    if ( not TWEENING_ENABLED)
        then raise iccException.Create('Use EnableTWEENING() method before using addTween().');

    tmp      := iccTween.Create( EventNotifier,
                                 MsgReceiver,
                                 _control,
                                 _property,
                                 _from,
                                 _to,
                                 _time,
                                 _delay,
                                 _fps,
                                 _easingFunc,
                                 _onStart,
                                 _onFinish,
                                 _onTick
                               );

    if tmp = nil
        then raise iccException.Create('addTween() -> Tween could not be added.');

    // result
    result := tmp;
end;


end.
