unit unt_wnd_preferences;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, dxCore, dxContainer, dxLabel, StdCtrls, icUtils;

type
  Twnd_preferences = class(TForm)
    dxContainer2: TdxContainer;
    dxLabel3: TdxLabel;
    Button1: TButton;
    Button3: TButton;
    CheckBox1: TCheckBox;
    ListBox1: TListBox;
    dxLabel5: TdxLabel;
    dxLabel6: TdxLabel;
    ComboBox1: TComboBox;
    procedure dxContainer1Paint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  wnd_preferences: Twnd_preferences;

implementation

uses unt_wnd_main;

{$R *.dfm}

procedure Twnd_preferences.dxContainer1Paint(Sender: TObject; Rect: TRect; ACanvas: TCanvas; AFont: TFont);
begin
    drawGradient( ACanvas.Handle, 1, 1, Rect.Right, 50, clWhite, $F0F0F0);
end;

procedure Twnd_preferences.FormCreate(Sender: TObject);
begin
    OnPaint := wnd_main.onPaint;
end;

end.
