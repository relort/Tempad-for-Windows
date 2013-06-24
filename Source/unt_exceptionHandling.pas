unit unt_exceptionHandling;

interface

uses
    Windows,
    Messages,
    SysUtils,
    Classes,
    Forms,

    icUtils,
    icClasses,

    unt_wnd_main;


const
    exc_Threshold : Byte = 5; // work until...

var
    exc_Monitor : Integer = 0;
    exc_Locked  : Boolean = false;


type
    iccInAppExceptionHandler =
        class
            private
                class var FInstance  : iccInAppExceptionHandler;
            private
                procedure ___event_app_onException( _sender : TObject; _exc : Exception);
            private
                class function ___prop_get_OnException() : TExceptionEvent; static;
            public
                class constructor ___cr();
                class destructor  ___de();
            public
                class property onException : TExceptionEvent read ___prop_get_onException;
        end;


    ////
    procedure excHandler( _exc : Exception; _nativeException : Boolean= true; _otherObject : TObject = nil);
    procedure excHandler_Unhandled( _exc : Exception);
    ////


implementation

    procedure excHandler( _exc : Exception; _nativeException : Boolean= true; _otherObject : TObject = nil);
    var str : String;

        procedure notifyAndDie();
        begin
            if exc_Locked
                then exit;
            exc_Locked := true;

            try
                MessageBox( 0, pchar( str), c_app_name, MB_OK or MB_ICONINFORMATION or MB_TASKMODAL);
            finally
                ExitProcess( 0);
            end;
        end;

        procedure Die();
        begin
            ExitProcess( 0);
        end;

    begin
        // якшо ексепшени сиплятся навіть після того, як я визвав notifyAndDie(), то просто вмирать...
        if exc_Monitor - 1 >= exc_Threshold
           then die();

        InterlockedIncrement( exc_Monitor);

        if _exc is iccException
            then if iccException( _exc).Priority = iccException.c_prior_FATAL
                     then begin
                              str := c_app_crash + #13'Add. info: ' +  _exc.Message + #13#13 + c_app_crash_pleaseReport;
                              notifyAndDie();
                          end;

        if ( exc_Monitor >= exc_Threshold )
           or ( _exc is EExternal)
           or ( _exc is EAbstractError)
            then begin
                     str := c_app_exceptionThresholdReached + #13#13 + c_app_crash_pleaseReport;
                     notifyAndDie();
                 end;
    end;

    procedure excHandler_Unhandled( _exc : Exception);
    begin
        MessageBox( 0, 'Congrats! Now you are seeing the miracle. Terrible miracle. I added this messagebox as joke when Unhandled exception is occured.', c_app_name, 0);
        ExitProcess( 0);
    end;

{ iccExceptionHandling }

class constructor iccInAppExceptionHandler.___cr;
var ins : iccInAppExceptionHandler;
begin
    ins := iccInAppExceptionHandler.Create();

    iccInAppExceptionHandler.FInstance := ins;
end;

class destructor iccInAppExceptionHandler.___de;
begin
    iccInAppExceptionHandler.FInstance.Destroy();
end;

procedure iccInAppExceptionHandler.___event_app_onException(_sender: TObject; _exc: Exception);
begin
    MessageBox( 0, pchar( 'Unhandled exception has occured.' + #13 + _exc.Message), c_app_name, MB_TASKMODAL or MB_ICONINFORMATION or MB_OK);
end;

class function iccInAppExceptionHandler.___prop_get_OnException: TExceptionEvent;
begin
    result := FInstance.___event_app_onException;
end;

end.
