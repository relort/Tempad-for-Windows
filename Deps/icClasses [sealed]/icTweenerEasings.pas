unit icTweenerEasings;

interface

uses
    Math;


    function easing_Back_In    ( p: Extended; firstNum: integer; diff: integer) : Extended;
    function easing_Back_Out   ( p: Extended; firstNum: integer; diff: integer) : Extended;
    function easing_Back_InOut ( p: Extended; firstNum: integer; diff: integer) : Extended;

    function easing_Bounce_In  ( p: Extended; firstNum: integer; diff: integer) : Extended;
    function easing_Bounce_Out ( p: Extended; firstNum: integer; diff: integer) : Extended;

    function easing_Circ_In    ( p: Extended; firstNum: integer; diff: integer) : Extended;
    function easing_Circ_Out   ( p: Extended; firstNum: integer; diff: integer) : Extended;
    function easing_Circ_InOut ( p: Extended; firstNum: integer; diff: integer) : Extended;

    function easing_Cubic_In   ( p: Extended; firstNum: integer; diff: integer) : Extended;
    function easing_Cubic_Out  ( p: Extended; firstNum: integer; diff: integer) : Extended;
    function easing_Cubic_InOut( p: Extended; firstNum: integer; diff: integer) : Extended;

    function easing_Elastic_In ( p: Extended; firstNum: integer; diff: integer) : Extended;
    function easing_Elastic_Out( p: Extended; firstNum: integer; diff: integer) : Extended;

    function easing_Expo_In    ( p: Extended; firstNum: integer; diff: integer) : Extended;
    function easing_Expo_Out   ( p: Extended; firstNum: integer; diff: integer) : Extended;
    function easing_Expo_InOut ( p: Extended; firstNum: integer; diff: integer) : Extended;

    function easing_Quad_In    ( p: Extended; firstNum: integer; diff: integer) : Extended;
    function easing_Quad_Out   ( p: Extended; firstNum: integer; diff: integer) : Extended;
    function easing_Quad_InOut ( p: Extended; firstNum: integer; diff: integer) : Extended;

    function easing_Quart_In   ( p: Extended; firstNum: integer; diff: integer) : Extended;
    function easing_Quart_Out  ( p: Extended; firstNum: integer; diff: integer) : Extended;
    function easing_Quart_InOut( p: Extended; firstNum: integer; diff: integer) : Extended;

    function easing_Quint_In   ( p: Extended; firstNum: integer; diff: integer) : Extended;
    function easing_Quint_Out  ( p: Extended; firstNum: integer; diff: integer) : Extended;
    function easing_Quint_InOut( p: Extended; firstNum: integer; diff: integer) : Extended;

    function easing_Sine_In    ( p: Extended; firstNum: integer; diff: integer) : Extended;
    function easing_Sine_Out   ( p: Extended; firstNum: integer; diff: integer) : Extended;
    function easing_Sine_InOut ( p: Extended; firstNum: integer; diff: integer) : Extended;

implementation

{$REGION '   Easing functions   '}
function easing_Back_In   ( p : Extended; firstNum : integer; diff : integer) : Extended;
var
    c, s: Extended;
begin
    c := diff;
    s := 1.70158;
    result :=  c*p*p*((s+1)*p - s) + firstNum;
end;

function easing_Back_Out  ( p : Extended; firstNum : integer; diff : integer) : Extended;
var
    c, s : Extended;
begin
    c      := diff;
    s      := 1.70158;
    p      := p - 1;
    result := c*(p*p*((s+1)*p + s) + 1) + firstNum;
end;

function easing_Back_InOut( p : Extended; firstNum : integer; diff : integer) : Extended;
var
    c, s : Extended;
begin
    c  := diff;
    s  := 1.70158 * 1.525;
    p  := p / 0.5;
    if ( p < 1)
        then result := c/2*(p*p*((s + 1)*p - s)) + firstNum
        else begin
                 p := p - 2;
                 result := c/2*(p*p*((s + 1)*p + s) + 2) + firstNum;
             end;
end;

function easing_Bounce_In(p: Extended; firstNum: integer; diff: integer) : Extended;
var
    c, inv: Extended;
begin
    c := diff;
    inv := easing_Bounce_Out(1 - p, 0, diff);
    result := c - inv + firstNum;
end;

function easing_Bounce_Out(p: Extended; firstNum: integer; diff: integer): Extended;
var
    c: Extended;
begin
    c := diff;
    if ( p < 1/2.75)
        then result := c*(7.5625*p*p) + firstNum
        else if (p < 2/2.75)
                 then begin
                          p := p - (1.5/2.75);
                          result := c*(7.5625*p*p + 0.75) + firstNum;
                      end
                 else if (p < 2.5/2.75)
                          then begin
                                   p := p - (2.25/2.75);
                                   result := c*(7.5625*p*p + 0.9375) + firstNum;
                               end
                          else begin
                                   p := p - (2.625/2.75);
                                   result := c*(7.5625*p*p + 0.984375) + firstNum;
                               end;
end;

function easing_Circ_In(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c: Extended;
begin
  c := diff;
  result := -c * (sqrt(1 - p*p) - 1 ) + firstNum;
end;

function easing_Circ_Out(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c: Extended;
begin
  c := diff;
  p := p - 1;
  result := c * sqrt(1 - p*p) + firstNum;
end;

function easing_Circ_InOut(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c: Extended;
begin
  c := diff;
  p := p / 0.5;
  if (p < 1) then
    result := -c/2 * (sqrt(1 - p*p) - 1) + firstNum
  else
  begin
    p := p - 2;
    result := c/2 * (sqrt(1 - p*p) + 1) + firstNum
  end;
end;

function easing_Cubic_In(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c: Extended;
begin
  c := diff;
  result := c * (p*p*p) + firstNum;
end;

function easing_Cubic_Out(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c: Extended;
begin
  c := diff;
  p := p -1;
  result := c * (p*p*p + 1) + firstNum;
end;

function easing_Cubic_InOut(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c: Extended;
begin
  c := diff;
  p := p / 0.5;
  if (p < 1) then
    result := c/2*p*p*p + firstNum
  else
  begin
    p := p - 2;
    result := c/2*(p*p*p + 2) + firstNum;
  end;
end;

function easing_Elastic_In(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c, period, s, amplitude: Extended;
begin
  c := diff;

  if p = 0 then Exit(firstNum);
  if p = 1 then Exit( diff + firstNum); // CORRECTED

  period := 0.25;
  amplitude := c;

  if (amplitude < abs(c)) then
  begin
    amplitude := c;
    s := period / 4;
  end
  else
  begin
    s := period/(2*PI) * Math.ArcSin(c/amplitude);
  end;
  p := p - 1;
  result := -(amplitude*Math.Power(2, 10*p) * sin( (p*1-s)*(2*PI)/period)) + firstNum;
end;

function easing_Elastic_Out(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c, period, s, amplitude: Extended;
begin
  c := diff;

  if diff = 0 then Exit(c);
  if p = 0 then Exit(firstNum);
  if p = 1 then
  Exit( diff + firstNum); // CORRECTED

  period := 0.25;
  amplitude := c;

  if (amplitude < abs(c)) then
  begin
    amplitude := c;
    s := period / 4;
  end
  else
  begin
    s := period/(2*PI) * Math.ArcSin(c/amplitude);
  end;
  result := -(amplitude*Math.Power(2, -10*p) * sin( (p*1-s)*(2*PI)/period)) + c + firstNum;
end;

function easing_Expo_In(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c: Extended;
begin
  c := diff;

  if (p = 0) then
    result := firstNum
  else
  begin
    p := p - 1;
    result := c * Math.Power(2, 10*p) + firstNum - c * 0.001;
  end;
end;

function easing_Expo_Out(p: Extended; firstNum: integer; diff: integer): Extended;
//var
//  c: Extended;
begin
//  c := diff;

  if (p = 1) then
    result := diff + firstNum // CORRECTED
  else
  begin
    result := diff * 1.001 * (-Math.Power(2, -10*p) + 1) + firstNum;
  end;
end;

function easing_Expo_InOut(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c: Extended;
begin
  c := diff;

  if (p = 0) then Exit(firstNum);
  if (p = 1) then Exit( diff + firstNum); // CORRECTED

  p := p / 0.5;
  if p < 1 then
    result := c/2 * Math.Power(2, 10 * (p-1)) + firstNum - c * 0.0005
  else
  begin
    p := p - 1;
    result := c/2 * 1.0005 * (-Math.Power(2, -10 * p) + 2) + firstNum;
  end;
end;

function easing_Quad_In(p: Extended; firstNum: integer; diff: integer): Extended;
var c: Extended;
begin
    c := diff;

    result := c * p * p + firstNum
end;

function easing_Quad_Out(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c: Extended;
begin
  c := diff;

  result := -c * p*(p-2) + firstNum;
end;

function easing_Quad_InOut(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c: Extended;
begin
  c := diff;

  p := p / 0.5;
  if p < 1 then
    result := c/2*p*p + firstNum
  else
  begin
    p := p - 1;
    result := -c/2 * (p*(p-2) - 1) + firstNum;
  end;
end;

function easing_Quart_In(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c: Extended;
begin
  c := diff;

  result := c * p*p*p*p + firstNum;
end;

function easing_Quart_Out(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c: Extended;
begin
  c := diff;

  p := p - 1;
  result := -c * (p*p*p*p - 1) + firstNum;
end;

function easing_Quart_InOut(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c: Extended;
begin
  c := diff;

  p := p / 0.5;
  if p < 1 then
    result := c/2*p*p*p*p + firstNum
  else
  begin
    p := p - 2;
    result := -c/2 * (p*p*p*p - 2) + firstNum;
  end;
end;

function easing_Quint_In(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c: Extended;
begin
  c := diff;

  result := c * p*p*p*p*p + firstNum;
end;

function easing_Quint_Out(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c: Extended;
begin
  c := diff;

  p := p - 1;
  result := c * (p*p*p*p*p + 1) + firstNum;
end;

function easing_Quint_InOut(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c: Extended;
begin
  c := diff;

  p := p / 0.5;
  if p < 1 then
    result := c/2*p*p*p*p*p + firstNum
  else
  begin
    p := p - 2;
    result := c/2 * (p*p*p*p*p + 2) + firstNum;
  end;
end;

function easing_Sine_In(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c: Extended;
begin
  c := diff;

  result := -c * cos(p*(PI/2)) + c + firstNum;
end;

function easing_Sine_Out(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c: Extended;
begin
  c := diff;

  result := c * sin(p*(PI/2)) + firstNum;
end;

function easing_Sine_InOut(p: Extended; firstNum: integer; diff: integer): Extended;
var
  c: Extended;
begin
  c := diff;

  result := -c/2 * (cos(PI*p) - 1) + firstNum;
end;
{$ENDREGION}

end.
