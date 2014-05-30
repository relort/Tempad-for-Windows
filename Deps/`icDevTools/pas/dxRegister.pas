
{*******************************************************************}
{                                                                   }
{   dxRegister (Design eXperience)                                  }
{                                                                   }
{   Copyright (c) 2002 APRIORI business solutions AG                }
{   (W)ritten by M. Hoffmann - ALL RIGHTS RESERVED.                 }
{                                                                   }
{   DEVELOPER NOTES:                                                }
{   ==========================================================      }
{   This file is part of a component suite called Design            }
{   eXperience and may be used in freeware- or commercial           }
{   applications. The package itself is distributed as              }
{   freeware with full sourcecodes.                                 }
{                                                                   }
{   Feel free to fix bugs or include new features if you are        }
{   familiar with component programming. If so, please email        }
{   me your modifications, so it will be possible for me to         }
{   include nice improvements in further releases:                  }
{                                                                   }
{*******************************************************************}

unit dxRegister;

interface

uses
  Classes;

procedure Register;

implementation

uses
    dxContainer
  , dxButtons
  , dxCheckCtrls
  , dxListBox
  , dxLabel
  , dxExtLabel
  ;

procedure Register;
begin
  RegisterComponents( 'Design eXperience II [Inline-CODERs'' mod]',
                      [ TdxContainer,
                        TdxButton,
                        TdxCheckbox,
                        TdxListBox,
                        TdxLabel,
                        TdxExtLabel
                      ]
                    );
end;

end.

