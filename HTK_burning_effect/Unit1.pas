// HTK Burning Effect
// mail me at: htk@carrier.com.br

unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics,
  Forms, FastBMP,fastrgb, ExtCtrls, Controls ;


type
  TForm1 = class(TForm)
    htkimg: TImage;
    Timer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TimerTimer(Sender: TObject);
  private
    { Private declarations }
  public
    PRocedure Burn;
  end;

Const
  Sw= 255;
  Sh= 255;

  RootRand     =  40;   { Max/Min decrease of the root of the flames }
  Decay        =  4;   { How far should the flames go up on the screen? }
                        { This MUST be positive - JF }
  MinY         =1;   { Startingline of the flame routine.
                          (should be adjusted along with MinY above) }
  Smooth       =   1;   { How descrete can the flames be?}
  MinFire      =  40;   { limit between the "starting to burn" and
                          the "is burning" routines }
  XStart       = 1;    { Startingpos on the screen, should be divideable by 4 without remain!}
  XEnd         = 255;   { Guess! }
  Width        = XEnd-XStart; {Well- }
  MaxColor     = 125;   { Constant for the MakePal procedure }
  FireIncrease  :byte =   255;{3 = Wood, 90 = Gazolin}

  detailw      = 40;
  detailh      = 40;
  details      =  2;  //Detail Size
  detailp      = 150; // Detail Power
  detailspeed  = 0.1;

var
  Form1: TForm1;
  bmp:tfastbmp;
  Pal : array[0..255] of TFColor;
  Scr,scr2 : Array[0..Sh,0..Sw] Of Byte;
  stop:boolean;

  fog:integer=0;
  fog2:integer=0;

  Fmore,Fless:boolean;

  bla,bla2,b,bb:real;
  bbb,bbb2:byte;

  cltmp:pfcolor;
  tmpbmp:TFastBMP;
  htkx,htky,htktmp:integer;

  sceneint:integer;



  htkreal: real;
implementation

{$R *.DFM}
procedure DrawInFlame(x,y:integer;intensity:integer);
var   cltmp:pfcolor; xx,yy,tmp:integer;
begin
cltmp:=tmpbmp.Bits;
     for yy:=y to y+tmpbmp.height-1  do
     for xx:=x to x+tmpbmp.width-1 do
     begin
     inc(cltmp);
     tmp:=scr2[xx,yy]+(((cltmp.r+cltmp.g+cltmp.b) div 3) div intensity);
     if tmp > 255 then tmp:=255;
     if (yy < sw) and (xx < sh) and (xx>0) and (yy > 0 ) then
     scr2[xx,yy]:=tmp;
     end;
end;

procedure DrawColor(x,y:integer; ri,gi,bi:real);
var   cltmp:pfcolor; xx,yy,tmp:integer;
begin
cltmp:=tmpbmp.Bits;
     for yy:=y to y+tmpbmp.height-1  do
     for xx:=x to x+tmpbmp.width-1 do
     begin
     inc(cltmp);
     if (yy < sw) and (xx < sh) and (xx>0) and (yy > 0 ) then
     begin
     if ri <> 0 then
     begin
     tmp:=bmp.Pixels[yy,xx].r+(round(cltmp.r / ri));
     if tmp > 255 then tmp:=255;
     bmp.Pixels[yy,xx].r:=tmp;
     end;

     if gi <> 0 then
     begin
     tmp:=bmp.Pixels[yy,xx].g+(round(cltmp.g / gi));
     if tmp > 255 then tmp:=255;
     bmp.Pixels[yy,xx].g:=tmp;
     end;

     if bi <> 0 then
     begin
     tmp:=bmp.Pixels[yy,xx].b+(round(cltmp.b / bi));
     if tmp > 255 then tmp:=255;
     bmp.Pixels[yy,xx].b:=tmp;
     end;
     end;

     end;
end;


Function Rand(R:Integer):Integer;{ Return a random number between -R And R}
begin
  Rand:=Random(R*2+1)-R;
end;

Procedure Hsi2Rgb(H, S, I : Real; var C : TFcolor);
{Convert (Hue, Saturation, Intensity) -> (RGB)}
var
  T : Real;
  Rv, Gv, Bv : Real;
begin
  T := H;
  Rv := 1 + S * Sin(T - 2 * Pi / 3);
  Gv := 1 + S * Sin(T);
  Bv := 1 + S * Sin(T + 2 * Pi / 3);
  T := 63.999 * I / 2;
  with C do
  begin
    R := trunc(Rv * T);
    G := trunc(Gv * T);
    B := trunc(Bv * T);
  end;
end; { Hsi2Rgb }



Procedure MakePal;
Var
  I : Byte;
begin
  FillChar(Pal,SizeOf(Pal),0);
  For I:=1 To MaxColor Do
    HSI2RGB(4.6-1.5*I/MaxColor,I/MaxColor,I/MaxColor,Pal[I]);
  For I:=MaxColor To 255 Do
  begin
    Pal[I]:=Pal[I-1];
    With Pal[I] Do
    begin

      If R<63 Then Inc(R);
      If R<63 Then Inc(R);
      If (I Mod 2=0) And (G<53)  Then Inc(G);
      If (I Mod 2=0) And (B<63) Then Inc(B);
    end;
  end;

  for i:=0 to 255 do
  begin
  pal[i].r:=pal[i].r*4;
  pal[i].g:=pal[i].g*4;
  pal[i].b:=pal[i].b*4;

  if i<60 then
      begin
      pal[i].g:=pal[i].r;
      pal[i].b:=pal[i].r;
      end;
  end;



  end;

Procedure Tform1.Burn;
var
  FlameArray : Array[XStart..XEnd] Of Byte;
  I,J : Integer;
  X : Integer;
  MoreFire,
  V   : Integer;
  bmpx,bmpy:integer;



begin
timer.enabled:=false;
htkx:=50;
htktmp:=0;
sceneint:=0;
Stop:=false;
  RandomIze;
  MoreFire:=1;
  MakePal;




    { Initialize FlameArray }
  For I:=XStart To XEnd Do
    FlameArray[I]:=0;

  FillChar(Scr,SizeOf(Scr),0); { Clear Screen }
  FillChar(Scr2,SizeOf(Scr2),0); { Clear Screen }
  FillChar(FlameArray[XStart+Random(XEnd-XStart-5)],5,15);
  repeat


   { Put the values from FlameArray on the bottom line of the screen }
if htktmp > 400 then
    For I:=XStart To XEnd Do
    scr2[I,sh]:=FlameArray[I];

    { This loop makes the actual flames }

    For I:=XStart To XEnd Do
    For J:=MinY To sh Do
    begin
      V:=scr2[I,J];
      If (V=0) Or
         (V<Decay) Or
         (I<=XStart) Or
         (I>=XEnd) Then
        scr2[I,Pred(J)]:=0

      else
        scr2[I-Pred(Random(3)),Pred(J)]:=V-Random(Decay);

    end;

if ((htktmp > 600 ) and ( htktmp < 1500 )) or ((htktmp > 2400 ) and (htktmp < 5000))then
 begin
  bla:=bla+detailspeed;
  bla2:=bla2+detailspeed;
  b:=bmp.width div 2+sin(bla/3)*(bmp.width div 2 -detailw);
  bb:=bmp.Height div 2+sin(bla2/2)*(bmp.Height div 2 -detailh);
  for bbb:=0 to details do
  for bbb2:=0 to details do
  scr2[round(b)+bbb,round(bb)+bbb2]:=detailp;
 end;

if htktmp > 7000 then
   htktmp:= 600;

If (Random(150)=0)  Then
      FillChar(FlameArray[XStart+Random(XEnd-XStart-5)],5,255);


//Water effect
if (htktmp > 1000) and ( htktmp < 1500 ) then
    for I:=1 To 10 Do FlameArray[XStart+Random(xend)]:=0;




    {This loop controls the "root" of the
     flames ie. the values in FlameArray.}
    For I:=XStart To XEnd Do
    begin
      X:=FlameArray[I];

      If X<MinFire Then { Increase by the "burnability"}
      begin
        {Starting to burn:}
        If X>10 Then Inc(X,Random(FireIncrease));
      end
      else
      { Otherwise randomize and increase by intensity (is burning)}
        Inc(X,Rand(RootRand)+MoreFire);
      If X>255 Then X:=255; { X Too large ?}
      FlameArray[I]:=X;
    end;




    {Smoothen the values of FrameArray to avoid "descrete" flames}

    For I:=XStart+Smooth To XEnd-Smooth Do
    begin
      X:=0;
      For J:=-Smooth To Smooth Do Inc(X,FlameArray[I+J]);
      FlameArray[I]:=X Div (2*Smooth+1);
    end;
    for bmpx:=0 to sw do
    for bmpy:=0 to sh do
    bmp.Pixels[bmpx,bmpy]:=pal[scr2[bmpy,bmpx]];








    inc(htktmp);

    if (htktmp > 50) and (htktmp < 400 ) then
    begin
    htkreal:=htkreal+0.1;

       if htktmp < 80  then
       drawColor(50,htkx,htkreal,htkreal *3 ,htkreal*3);

      if htkreal > 1  then
       begin
       htkx:=round(htkreal *4)+46;
       drawinflame(50,htkx,round(htkreal*2));
       end;
    end;



    bmp.draw(Form1.canvas.handle,0,0);

    Application.processmessages;
    if stop then exit;

    inc(fog);
  Until Stop = true;



end;


procedure TForm1.FormCreate(Sender: TObject);
begin
tmpbmp:=tfastbmp.CreateFromhBmp(htkimg.Picture.bitmap.Handle);
bmp:=tfastbmp.create(256,256);

end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 tmpbmp.free;
 bmp.free;
 stop:=true;
 application.processmessages;
end;

procedure TForm1.TimerTimer(Sender: TObject);
begin
Burn;
timer.enabled:=false;
end;

end.


