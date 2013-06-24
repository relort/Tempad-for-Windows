unit unt_frame_ProgressNotifier;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, ComCtrls, dxLabel, dxCore, dxContainer, icClasses, icUtils;

type
    Tframe_ProgressNotifier =
        class(TFrame)
                surface_progress: TdxContainer;
                lbl_progressStatus: TdxLabel;
                ProgressBar1: TProgressBar;
                procedure surface_progressPaint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
            private
                procedure msg_wm_sync( var _msg : iccthread.icr_wm_sync); message iccThread.wm_sync;
            public
                class procedure checkCreate( var _instance : TFrame_ProgressNotifier;
                                             _Owner : TComponent;
                                             _Parent : TWinControl;
                                             _X : Integer = -65535;
                                             _Y : Integer = -65535
                                           );
                class procedure release( var _instance : TFrame_ProgressNotifier);
            public
                procedure Status_Set( _str : String);
                procedure Status_Set_threadContext( _it : iciThread; _str : String);
        end;

implementation

{$R *.dfm}

procedure Tframe_ProgressNotifier.msg_wm_sync(var _msg: iccthread.icr_wm_sync);
begin
    try
        // safe check
        //if iInterface( TProc( _msg.WParam)) is TInterfacedObject
        //    then TProc( _msg.WParam)();
        _msg.Proc^();

        DefaultHandler( _msg);
        _msg.Result := 1;
//    except
    finally
        // swallow
        //raise iccException.Create( 'thread sync -> failed', iccException.c_prior_FATAL);
    end;
end;

class procedure Tframe_ProgressNotifier.checkCreate( var _instance: TFrame_ProgressNotifier;
                                                     _Owner: TComponent;
                                                     _Parent: TWinControl;
                                                     _X,
                                                     _Y: Integer
                                                   );
begin
    if _instance = nil
        then begin
                _instance := Tframe_ProgressNotifier.Create( _Owner);
                _instance.Name    := '';
                _instance.Visible := false;
                _instance.Anchors := [];
             end;


    if _X = -65535
        then _X := _Parent.Width  div 2 - _instance.Width  div 2;
    if _Y = -65535
        then _Y := _Parent.Height div 2 - _instance.Height div 2 - 50;

    _instance.Left   := _X;
    _instance.Top    := _Y;
    _instance.Parent := _Parent;
end;

class procedure Tframe_ProgressNotifier.Release( var _instance : Tframe_ProgressNotifier);
begin
    if _instance = nil
        then exit;

    _instance.Destroy();
    _instance := nil;
end;

procedure Tframe_ProgressNotifier.surface_progressPaint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
begin
    drawGradient( ACanvas.Handle, 1, 1, Rect.Right, Rect.Bottom, clWhite, $F0F0F0);
end;

procedure Tframe_ProgressNotifier.Status_Set(_str: String);
begin
    lbl_progressStatus.Caption := _Str;
    lbl_progressStatus.Update();
end;

procedure Tframe_ProgressNotifier.Status_Set_threadContext(_it: iciThread; _str: String);
begin
    _it.doSync( Handle,
                procedure ()
                begin
                    Status_set( _str);
                end
              );
end;


end.
