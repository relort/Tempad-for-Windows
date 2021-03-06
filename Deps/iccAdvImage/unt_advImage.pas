unit unt_advImage;

interface

uses
    Windows,
    Messages,
    Classes,
    Controls,
    ExtCtrls,
    graphics;

type
    ictAdvImageState = ( isNone,
                       isEntered,
                       isPressed
                     );

    icsAdvImageStateSet = set of ictAdvImageState;

type
    iccAdvImagePictures =
        class( TPersistent)
            private
                FPictureEntered : TPicture;
                FPicturePressed : TPicture;
                FOnChange       : TNotifyEvent;
                procedure SetPictureEntered(const pv_Picture : TPicture);
                procedure SetPicturePressed(const pv_Picture : TPicture);
                procedure Changed();
            public
                constructor Create();
                destructor Destroy(); override;
            published
                property Entered  : TPicture read FPictureEntered write SetPictureEntered;
                property Pressed  : TPicture read FPicturePressed write SetPicturePressed;
                property OnChange : TNotifyEvent read FOnChange write FOnChange;
        end;

type
    iccAdvImage =
        class( TImage)
            private
                FOnMouseEnter : TNotifyEvent;
                FOnMouseLeave : TNotifyEvent;
                FTmpPicture   : TPicture;
                FImageState   : icsAdvImageStateSet;
                FPictures     : iccAdvImagePictures;
            protected
                procedure MouseDown(Button: TMouseButton;Shift: TShiftState; X, Y: Integer); override;
                procedure MouseUp(Button: TMouseButton;Shift: TShiftState; X, Y: Integer); override;
            public
                constructor Create(AOwner : TComponent); override;
                destructor Destroy; override;
                procedure  cm_MouseEnter(out pv_Msg : TMessage); message cm_MouseEnter;
            protected
                procedure  cm_MouseLeave(out pv_Msg : TMessage); message cm_MouseLeave;
            public
                property ImageState   : icsAdvImageStateSet read FImageState   write FImageState;
            public
                property SimpleImage  : TPicture          read FTmpPicture   write FTmpPicture;
            published
                property Pictures     : iccAdvImagePictures read FPictures     write FPictures;
                property OnMouseEnter : TNotifyEvent      read FOnMouseEnter write FOnMouseEnter;
                property OnMouseLeave : TNotifyEvent      read FOnMouseLeave write FOnMouseLeave;
        end;

procedure Register;

implementation

procedure Register;
begin
    RegisterComponents('Inline-CODER''s unplugged components', [iccAdvImage]);
end;

{ iccAdvImage }

constructor iccAdvImage.Create(AOwner : TComponent);
begin
    inherited Create(AOwner);
    FImageState := [isNone];
    FPictures := iccAdvImagePictures.Create;
end;

destructor iccAdvImage.Destroy;
begin
    FTmpPicture.Free;
    FPictures.Free;
    inherited Destroy;
end;

procedure iccAdvImage.cm_MouseEnter(out pv_Msg: TMessage);
begin
    // We are in IDE
    if csDesigning in ComponentState then exit;

    // Setting a new cursor
    //Screen.Cursor := Cursor;

    // Let value the ImageState
    if FImageState = [isNone]
        then FImageState := [isEntered];

    if FImageState = [isPressed]
        then FImageState := [isEntered, isPressed];

    // chosing the right "prey"
    if FImageState = [isEntered]
        then begin
                 if FTmpPicture = nil
                     then FTmpPicture := TPicture.Create;

                 FTmpPicture.Assign(Picture);

                 if Assigned(Pictures.Entered.Graphic)
                     then Picture := FPictures.FPictureEntered;
             end;

    if FImageState = [isEntered, isPressed]
        then begin
                 if Assigned(Pictures.Pressed.Graphic)
                     then Picture := FPictures.FPicturePressed;
             end;

    // event
    if Assigned(FOnMouseEnter)
        then FOnMouseEnter(Self);
end;

procedure iccAdvImage.cm_MouseLeave(out pv_Msg: TMessage);
begin
    // We are in IDE
    if csDesigning in ComponentState
        then exit;

    // Setting a new cursor
    //Screen.Cursor := crDefault;

    // Let value the ImageState
    if FImageState = [isEntered]
        then FImageState := [isNone];

    if FImageState = [isEntered, isPressed]
        then FImageState := [isPressed];

    // Drawing
    if FImageState = [isNone   ]
        then if FTmpPicture <> nil
                 then Picture.Assign(FTmpPicture);

    if FImageState = [isPressed]
        then begin {Do not change anything} end;

    // event
    if Assigned(FOnMouseLeave)
        then FOnMouseLeave(Self);
end;

procedure iccAdvImage.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
    // We are in IDE
    if csDesigning in ComponentState
        then exit;

    // Let value the ImageState
    if FImageState = [isEntered]
        then FImageState := [isEntered, isPressed];

    // Drawing
    if assigned(Pictures.FPicturePressed.Graphic)
        then begin
                 if FImageState = [isEntered, isPressed]
                     then Picture := FPictures.FPicturePressed;
             end;

    inherited;
end;

procedure iccAdvImage.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
    // We are in IDE
    if csDesigning in ComponentState
        then exit;

    // Let value the ImageState
    if FImageState = [isPressed           ]
        then FImageState := [isNone];
    if FImageState = [isEntered, isPressed]
        then FImageState := [isEntered];

    // Drawing
    if FImageState = [isNone   ]
        then if FTmpPicture <> nil
                 then Picture.Assign(FTmpPicture);

    if FImageState = [isEntered]
        then begin
                 if Assigned(Pictures.Entered.Graphic)
                     then Picture.Assign(Pictures.FPictureEntered)
                     else if FTmpPicture <> nil
                              then Picture.Assign(FTmpPicture);
             end;

    inherited;
end;

{ iccAdvImagePictures }

procedure iccAdvImagePictures.Changed;
begin
    if Assigned( FOnChange)
        then FOnChange(Self);
end;

constructor iccAdvImagePictures.Create;
begin
    inherited;
    FPictureEntered := TPicture.Create;
    FPicturePressed := TPicture.Create;
end;

destructor iccAdvImagePictures.Destroy;
begin
    FPictureEntered.Free;
    FPicturePressed.Free;
    inherited;
end;

procedure iccAdvImagePictures.SetPictureEntered(const pv_Picture: TPicture);
begin
    FPictureEntered.Assign( pv_Picture);
    Changed;
end;

procedure iccAdvImagePictures.SetPicturePressed(const pv_Picture: TPicture);
begin
    FPicturePressed.Assign( pv_Picture);
    Changed;
end;

end.

