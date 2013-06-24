unit unt_wnd_about;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, pngimage, ExtCtrls, dxCore, dxContainer, dxLabel, StdCtrls, icUtils, ShellAPI, Clipbrd;

type
  Twnd_about = class(TForm)
    dxContainer1: TdxContainer;
    Image1: TImage;
    dxLabel2: TdxLabel;
    dxLabel3: TdxLabel;
    btn_Close: TButton;
    dxLabel1: TdxLabel;
    lbl_da: TLabel;
    lbl_site: TLabel;
    lbl_twitter: TLabel;
    lbl_vk: TLabel;
    lbl_linkedin: TLabel;
    lbl_gmail: TLabel;
    dxLabel4: TdxLabel;
    lbl_gmail_copy: TLabel;
    lbl_version: TLabel;
    Shape1: TShape;
    Label1: TLabel;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure dxContainer1Paint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
    procedure btn_CloseClick(Sender: TObject);
    procedure lbl_gmailMouseEnter(Sender: TObject);
    procedure lbl_gmailMouseLeave(Sender: TObject);
    procedure lbl_gmailClick(Sender: TObject);
    procedure lbl_siteClick(Sender: TObject);
    procedure lbl_daClick(Sender: TObject);
    procedure lbl_twitterClick(Sender: TObject);
    procedure lbl_linkedinClick(Sender: TObject);
    procedure lbl_vkClick(Sender: TObject);
    procedure lbl_gmail_copyClick(Sender: TObject);
    procedure lbl_gmail_copyMouseLeave(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Label1Click(Sender: TObject);
  private
    { Private declarations }
  public
    procedure link_goto( _str : String);
  end;

implementation

{$R *.dfm}

uses
    unt_wnd_main;

procedure Twnd_about.btn_CloseClick(Sender: TObject);
begin
    Close();
end;

procedure Twnd_about.dxContainer1Paint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
begin
    drawGradient( ACanvas.Handle, 1, 1, Rect.Right, 100, clWhite, $F0F0F0);
    drawGradient( ACanvas.Handle, 1, Rect.Bottom - 100, Rect.Right, Rect.Bottom, $F0F0F0, clWhite);
end;

procedure Twnd_about.FormCreate(Sender: TObject);
begin
    OnPaint := wnd_main.OnPaint;
    lbl_version.Caption := iccVersion_Application.FileVersion;
end;

procedure Twnd_about.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
    if Key = VK_ESCAPE
        then Close();
end;

procedure Twnd_about.Label1Click(Sender: TObject);
begin
    link_goto( c_link_vk_group);
end;

procedure Twnd_about.lbl_gmailClick(Sender: TObject);
begin
    link_goto( c_link_prefix_mail + c_link_gmail);
end;

procedure Twnd_about.lbl_siteClick(Sender: TObject);
begin
    link_goto( c_link_site);
end;

procedure Twnd_about.lbl_twitterClick(Sender: TObject);
begin
    link_goto( c_link_twitter);
end;

procedure Twnd_about.lbl_daClick(Sender: TObject);
begin
    link_goto( c_link_deviantart);
end;

procedure Twnd_about.lbl_linkedinClick(Sender: TObject);
begin
    link_goto( c_link_linkedin);
end;

procedure Twnd_about.lbl_vkClick(Sender: TObject);
begin
    link_goto( c_link_vk);
end;

procedure Twnd_about.lbl_gmailMouseEnter(Sender: TObject);
begin
    TLabel( Sender).Font.Style := [fsUnderline];
end;

procedure Twnd_about.lbl_gmailMouseLeave(Sender: TObject);
begin
    TLabel( Sender).Font.Style := [];
end;

procedure Twnd_about.lbl_gmail_copyClick(Sender: TObject);
var cb : TClipboard;
begin
    cb := nil;
    try
        cb := TClipboard.Create();
        cb.AsText := c_link_gmail;

        lbl_gmail_copy.Caption := 'Copied';
    finally
        cb.Free();
    end;
end;

procedure Twnd_about.lbl_gmail_copyMouseLeave(Sender: TObject);
begin
    lbl_gmailMouseLeave( Sender);
    lbl_gmail_copy.Caption := 'Copy';
end;

procedure Twnd_about.link_goto(_str: String);
begin
    ShellExecute( Handle, 'open', pchar( _str), '', '', sw_show);
end;

end.
