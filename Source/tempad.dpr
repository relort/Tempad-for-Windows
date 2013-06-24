program tempad;

uses
  FastMM4,
  Windows,
  Messages,
  SysUtils,
  Classes,
  icClasses,
  Forms,
  unt_wnd_main in 'unt_wnd_main.pas' {wnd_main},
  unt_tabmanager in 'unt_tabmanager.pas',
  unt_wnd_recentTabManager in 'unt_wnd_recentTabManager.pas' {wnd_recentTabManager},
  unt_wnd_preview in 'unt_wnd_preview.pas' {wnd_Preview},
  unt_wnd_about in 'unt_wnd_about.pas' {wnd_about},
  unt_wnd_linkedToFlies in 'unt_wnd_linkedToFlies.pas' {wnd_linkedToFiles},
  unt_wnd_preferences in 'unt_wnd_preferences.pas' {wnd_preferences},
  unt_wnd_search in 'unt_wnd_search.pas' {wnd_Search},
  unt_frame_ProgressNotifier in 'unt_frame_ProgressNotifier.pas' {frame_ProgressNotifier: TFrame},
  unt_frame_ErrorNotifier in 'unt_frame_ErrorNotifier.pas' {frame_ErrorNotifier: TFrame},
  unt_wnd_replace in 'unt_wnd_replace.pas' {wnd_replace},
  unt_wnd_globalSearch in 'unt_wnd_globalSearch.pas' {wnd_globalSearch},
  unt_exceptionHandling in 'unt_exceptionHandling.pas';

{$R *.res}

var tmpStr : String;
begin
    try
        ExceptionHandler.OnException := excHandler;
        ExceptionHandler.OnUnhandledException := excHandler_Unhandled;

        //
        if not initiate_check( tmpStr)
            then begin
                     MessageBox( 0, pchar( tmpStr + #13#13 + 'Application will be closed automatically. Press ok.'), c_app_name, MB_OK or MB_ICONINFORMATION or MB_TASKMODAL);
                     exit();
                 end;
        //
        do_initiate(); //
        //
        Application.Initialize;
        Application.OnException := iccInAppExceptionHandler.onException;

        Application.MainFormOnTaskbar := True;
        Application.Title := c_app_name;
        Application.CreateForm(Twnd_main, wnd_main);
        //wnd_preferences := twnd_preferences.create( Application);
        //wnd_preferences.show();

        Application.Run;
        //
        do_finalize(); //
        //

        // trying to terminate app flawlessly
        try
            exc_Monitor := 0; // reset
            wnd_main.Destroy();
        finally
            if exc_Monitor <> 0 // if any exception was raised
                then ExitProcess( 0);
        end;
    except
        // excHandler will process this exception
        try
            raise iccException.Create( 'Unexpected error while running.', iccException.c_prior_FATAL);
        finally // in case if raising is unsuccessful
            ExitProcess( 0);
        end;
    end;
end.
