unit unt_wnd_search;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, dxCore, dxContainer, dxLabel, icUtils;

type
    Twnd_Search =
        class(TForm)
            public type
                ict_event_onFindNext = reference to procedure( _string : String);
            published
                surface_main: TdxContainer;
                btn_Close: TButton;
                edt_Text: TEdit;
                btn_FindNext: TButton;
                dxLabel1: TdxLabel;
                lbl_tabName: TdxLabel;
                procedure wnd_mainPaint(Sender: TObject);
                procedure FormCreate(Sender: TObject);
                procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
                procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
                procedure btn_CloseClick(Sender: TObject);
                procedure FormDestroy(Sender: TObject);
                procedure FormClose(Sender: TObject; var Action: TCloseAction);
                procedure edt_TextChange(Sender: TObject);
                procedure btn_FindNextClick(Sender: TObject);
            strict private
                class var cv_FInstance : Twnd_search;
                class var cv_event_onFindNext : ict_event_onFindNext;
            public
                class function isAvail() : Boolean;

                class procedure do_Create( _owner : TComponent); // create if not created yet
                class procedure do_Destroy(); // destroy if not destroyed yet

                class procedure do_Update_SearchString( _string : String);
                class procedure do_Update_TabName( _string : String);

                class procedure do_attachEvent_onFindNext( _event : ict_event_onFindNext);

                class procedure do_Show(); // show
                class procedure do_Hide(); // hide
        end;

implementation

uses unt_wnd_main;

{$R *.dfm}

class function Twnd_search.isAvail() : Boolean;
begin
    result := cv_FInstance <> nil;
end;

class procedure Twnd_search.do_Create( _owner : TComponent);
begin
    if cv_FInstance = nil
        then cv_FInstance := Twnd_Search.Create( _owner);
end;

class procedure Twnd_search.do_Destroy();
begin
    if cv_FInstance = nil
        then exit;

    cv_FInstance.Destroy();
    cv_FInstance := nil; // duplicated for sure
end;

class procedure Twnd_search.do_Update_SearchString( _string : String);
begin
    cv_FInstance.edt_Text.Text := _string;
end;

class procedure Twnd_search.do_Update_TabName( _string : String);
begin
    cv_FInstance.lbl_tabName.Caption := '[b]' + _string + '[/b]';
end;

procedure Twnd_Search.btn_FindNextClick(Sender: TObject);
begin
    if not btn_FindNext.Enabled
        then exit;

    if Assigned( cv_event_onFindNext)
        then cv_event_onFindNext( edt_Text.Text);
end;

class procedure Twnd_search.do_attachEvent_onFindNext( _event : ict_event_onFindNext);
begin
    cv_event_onFindNext := _event;
end;

class procedure Twnd_search.do_Show();
begin
    cv_FInstance.Show();
end;

class procedure Twnd_search.do_Hide();
begin
    cv_FInstance.Hide();
end;

procedure Twnd_Search.btn_CloseClick(Sender: TObject);
begin
    Close();
end;

procedure Twnd_Search.edt_TextChange(Sender: TObject);
begin
    btn_FindNext.Enabled := Length( edt_Text.Text) <> 0;
end;

procedure Twnd_Search.FormClose(Sender: TObject; var Action: TCloseAction);
begin
    Destroy();
end;

procedure Twnd_Search.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
   gv_Config.routine_WindowParams_set( Self);
end;

procedure Twnd_Search.FormCreate(Sender: TObject);
begin
    gv_Config.routine_WindowParams_get( Self);
    onPaint              := wnd_main.onPaint;
    surface_main.OnPaint := wnd_main.___event_container_paint_Generic;
    edt_Text.OnKeyPress  := wnd_main.___event_editOnKeyPress;
end;

procedure Twnd_Search.FormDestroy(Sender: TObject);
begin
    // nil instance
    cv_FInstance := nil;
end;

procedure Twnd_Search.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
    if Key = VK_RETURN
        then btn_FindNextClick( Self);

    if Key = VK_ESCAPE
        then Close();
end;

procedure Twnd_Search.wnd_mainPaint(Sender: TObject);
begin
    drawGradient( Canvas.Handle, 1, 1, ClientWidth, 50, clWhite, $F0F0F0);
end;

end.
