unit unt_wnd_replace;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, dxCore, dxContainer, dxLabel;

type
    Twnd_replace =
        class(TForm)
                procedure btn_ReplaceAllClick(Sender: TObject);
            public type
                ict_event_onFindNext   = reference to procedure( _source, _destination : String);
                ict_event_onReplaceAll = reference to procedure( _source, _destination : String);
            published
                dxLabel1: TdxLabel;
                lbl_tabName: TdxLabel;
                surface_main: TdxContainer;
                edt_Text: TEdit;
                btn_FindNext: TButton;
                btn_Close: TButton;
                edt_ReplaceText: TEdit;
                dxLabel2: TdxLabel;
                btn_ReplaceAll: TButton;
                procedure FormCreate(Sender: TObject);
                procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
                procedure FormClose(Sender: TObject; var Action: TCloseAction);
                procedure FormDestroy(Sender: TObject);
                procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
                procedure btn_FindNextClick(Sender: TObject);
                procedure edt_TextKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
                procedure edt_TextChange(Sender: TObject);
                procedure btn_CloseClick(Sender: TObject);
            strict private
                class var cv_FInstance : Twnd_replace;
                class var cv_event_onFindNext   : ict_event_onFindNext;
                class var cv_event_onReplaceAll : ict_event_onReplaceAll;
            public
                class function isAvail() : Boolean;

                class procedure do_Create( _owner : TComponent); // create if not created yet
                class procedure do_Destroy(); // destroy if not destroyed yet

                class procedure do_Update_String_Search ( _string : String);
                class procedure do_Update_String_Replace( _string : String);
                class procedure do_Update_TabName( _string : String);

                class procedure do_attachEvent_onFindNext  ( _event : ict_event_onFindNext);
                class procedure do_attachEvent_onReplaceAll( _event : ict_event_onReplaceAll);

                class procedure do_Show(); // show
                class procedure do_Hide(); // hide
        end;

implementation

uses
    unt_wnd_main;

{$R *.dfm}

class function Twnd_replace.isAvail() : Boolean;
begin
    result := cv_FInstance <> nil;
end;

class procedure Twnd_replace.do_Create( _owner : TComponent);
begin
    if cv_FInstance = nil
        then cv_FInstance := Twnd_Replace.Create( _owner);
end;

class procedure Twnd_replace.do_Destroy();
begin
    if cv_FInstance = nil
        then exit;

    cv_FInstance.Destroy();
    cv_FInstance := nil; // duplicated for sure
end;

class procedure Twnd_replace.do_Update_String_Search( _string : String);
begin
    cv_FInstance.edt_Text.Text := _string;
end;

class procedure Twnd_replace.do_Update_String_Replace( _string : String);
begin
    cv_FInstance.edt_ReplaceText.Text := _string;
end;

class procedure Twnd_replace.do_Update_TabName( _string : String);
begin
    cv_FInstance.lbl_tabName.Caption := '[b]' + _string + '[/b]';
end;

procedure Twnd_replace.edt_TextChange(Sender: TObject);
begin
    btn_FindNext.Enabled := ( edt_Text.Text <> '') and ( edt_Text.Text <> ' ');// and ( edt_ReplaceText.Text <> '');
    btn_ReplaceAll.Enabled := btn_FindNext.Enabled;
end;

procedure Twnd_replace.edt_TextKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
    if Key = VK_RETURN
        then SelectNext( TWinControl( Sender), true, true);
end;

procedure Twnd_replace.btn_CloseClick(Sender: TObject);
begin
    Close();
end;

procedure Twnd_replace.btn_FindNextClick(Sender: TObject);
begin
    if not btn_FindNext.Enabled
        then exit;

    if Assigned( cv_event_onFindNext)
        then cv_event_onFindNext( edt_Text.Text, edt_ReplaceText.Text);
end;

procedure Twnd_replace.btn_ReplaceAllClick(Sender: TObject);
begin
    if not btn_ReplaceAll.Enabled
        then exit;

    if Assigned( cv_event_onReplaceAll)
        then cv_event_onReplaceAll( edt_Text.Text, edt_ReplaceText.Text);
end;

class procedure Twnd_replace.do_attachEvent_onFindNext( _event : ict_event_onFindNext);
begin
    cv_event_onFindNext := _event;
end;

class procedure Twnd_replace.do_attachEvent_onReplaceAll( _event : ict_event_onReplaceAll);
begin
    Twnd_replace.cv_event_onReplaceAll := _event;
end;

class procedure Twnd_replace.do_Show();
begin
    cv_FInstance.Show();
end;

class procedure Twnd_replace.do_Hide();
begin
    cv_FInstance.Hide();
end;

procedure Twnd_replace.FormClose(Sender: TObject; var Action: TCloseAction);
begin
    Destroy();
end;

procedure Twnd_replace.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
    gv_Config.routine_WindowParams_set( Self);
end;

procedure Twnd_replace.FormCreate(Sender: TObject);
begin
    gv_Config.routine_WindowParams_get( Self);
    onPaint                    := wnd_main.onPaint;
    surface_main.OnPaint       := wnd_main.___event_container_paint_Generic;
    edt_Text.OnKeyPress        := wnd_main.___event_editOnKeyPress;
    edt_ReplaceText.OnKeyPress := wnd_main.___event_editOnKeyPress;
end;

procedure Twnd_replace.FormDestroy(Sender: TObject);
begin
    // nil instance
    cv_FInstance := nil;
end;

procedure Twnd_replace.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
    if Key = VK_RETURN
        then btn_FindNextClick( Self);

    if Key = VK_ESCAPE
        then Close();
end;

end.
