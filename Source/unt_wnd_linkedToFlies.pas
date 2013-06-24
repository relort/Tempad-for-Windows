unit unt_wnd_linkedToFlies;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, dxLabel, pngimage, ExtCtrls;

type
  Twnd_linkedToFiles = class(TForm)
    Image1: TImage;
    dxLabel1: TdxLabel;
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

uses unt_wnd_main;

{$R *.dfm}

procedure Twnd_linkedToFiles.Button1Click(Sender: TObject);
begin
    Close();
end;

procedure Twnd_linkedToFiles.FormCreate(Sender: TObject);
begin
    OnPaint := wnd_main.onPaint;
end;

end.
