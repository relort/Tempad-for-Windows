unit unt_frame_ErrorNotifier;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, StdCtrls, dxLabel, dxCore, dxContainer, icClasses, icUtils;

type
    Tframe_ErrorNotifier =
        class(TFrame)
                surface_msgError: TdxContainer;
                lbl_msgError_title: TdxLabel;
                lbl_msgError_caption: TdxLabel;
                btn_Close: TButton;
    procedure btn_CloseClick(Sender: TObject);
    procedure surface_msgErrorPaint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
            private
                procedure msg_wm_sync( var _msg : iccThread.icr_wm_sync); message iccThread.wm_sync;
            public
                class procedure checkCreate( var _instance : Tframe_ErrorNotifier;
                                             _Owner : TComponent;
                                             _Parent : TWinControl;
                                             _X : Integer = -65535;
                                             _Y : Integer = -65535
                                           );
                class procedure release( var _instance : Tframe_ErrorNotifier);
            public
                procedure Status_Set( _str : String);
                procedure Status_Set_threadContext( _it : iciThread; _str : String);
        end;

implementation

{$R *.dfm}

procedure Tframe_ErrorNotifier.msg_wm_sync(var _msg: iccthread.icr_wm_sync);
begin
    try
        // safe check
        //if iInterface( TProc( _msg.WParam)) is TInterfacedObject
        //    then TProc( _msg.WParam)();
        _msg.Proc^();

        DefaultHandler( _msg);
        _msg.Result := 1;
    except
        raise iccException.Create( 'thread sync -> failed', iccException.c_prior_FATAL);
    end;
end;

procedure Tframe_ErrorNotifier.btn_CloseClick(Sender: TObject);
begin
    Application.Terminate();
end;

class procedure Tframe_ErrorNotifier.checkCreate( var _instance: Tframe_ErrorNotifier;
                                                     _Owner: TComponent;
                                                     _Parent: TWinControl;
                                                     _X,
                                                     _Y: Integer
                                                   );
begin
    if _instance = nil
        then _instance := Tframe_ErrorNotifier.Create( _Owner);


    if _X = -65535
        then _X := _Parent.Width  div 2 - _instance.Width  div 2;
    if _Y = -65535
        then _Y := _Parent.Height div 2 - _instance.Height div 2 - 50;

    _instance.Left   := _X;
    _instance.Top    := _Y;
    _instance.Parent := _Parent;
    _instance.BringToFront();
end;

class procedure Tframe_ErrorNotifier.Release( var _instance : Tframe_ErrorNotifier);
begin
    if _instance = nil
        then exit;

    _instance.Destroy();
    _instance := nil;
end;

procedure Tframe_ErrorNotifier.Status_Set(_str: String);
begin
    lbl_msgError_caption.Caption := _Str;
    lbl_msgError_caption.Update();
end;

procedure Tframe_ErrorNotifier.Status_Set_threadContext(_it: iciThread; _str: String);
begin
    _it.doSync( Handle,
                procedure ()
                begin
                    Status_set( _str);
                end
              );
end;

procedure Tframe_ErrorNotifier.surface_msgErrorPaint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
begin
    drawGradient( ACanvas.Handle, 1, 1, Rect.Right, Rect.Bottom, clWhite, $efefff);
end;

end.
