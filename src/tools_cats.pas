unit tools_cats;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Math;

type

  { Tfrmcats }

  Tfrmcats = class(TForm)
    Button1: TButton;
    cbFilesS: TListBox;
    cbFilesT: TListBox;
    Memo1: TMemo;

    procedure Button1Click(Sender: TObject);

  private

  public

  end;

var
  frmcats: Tfrmcats;

implementation

{$R *.lfm}

{ Tfrmcats }

uses ncmain, GibbsSeaWater;


procedure Tfrmcats.Button1Click(Sender: TObject);
Var
  k, fl, yy, mn, c, i, ff:integer;
  datT, datS:text;
  out1, out2, out3, out4, out5, out6, out7, out8, out9, out10, out11, out12: text;
  dist_tr, dist0, dist, lev, valT, ValS, ValD, Tf, stn, stn_old, lat, lon:real;
  Cp, p, saturation_fraction, SA, lev0:real;
  Qt1, Qs1, Qt2, Qs2, Qt3, Qs3, Kt, Ks: real;
  upath, dpath, fpath, str:string;
  noQ3:boolean;
  Kt_arr, Ks_arr, L_arr, T_arr:array [1..100] of real;
  Kt1, Kt2, Kt3, Ks1, Ks2, Ks3:real;
  l_min1, l_min2, l_min3, l_max1, l_max2, l_max3:real;
  fdb:TSearchRec;
begin

  //ρcP(T-Tf), ρS
  p :=10.1325;
  saturation_fraction:=0;

  dpath:='C:\VV_cats\Data\';
  upath:='C:\VV_cats\Results\';

// Sections
For ff:=1 to 5  do begin

  case ff of
   1: fpath:='81.5_83_95_98\';
   2: fpath:='81.5_84_95_105\';
   3: fpath:='79.5_80.75_103_110\';
   4: fpath:='79.5_81.3_110_118\';
   5: fpath:='77_80_126_126\';
  end;

  fdb.Name:='';
   cbFilesT.Clear;
    FindFirst(dPath+fpath+'t\*.dat',faAnyFile, fdb);
     if fdb.Name<>'' then cbFilesT.Items.Add(fdb.Name);
   while findnext(fdb)=0 do cbFilesT.Items.Add(fdb.Name);

  fdb.Name:='';
   cbFilesS.Clear;
    FindFirst(dPath+fpath+'s\*.dat',faAnyFile, fdb);
     if fdb.Name<>'' then cbFilesS.Items.Add(fdb.Name);
   while findnext(fdb)=0 do cbFilesS.Items.Add(fdb.Name);


  AssignFile(out1,  upath+fpath+'01.dat'); rewrite(out1);
  AssignFile(out2,  upath+fpath+'02.dat'); rewrite(out2);
  AssignFile(out3,  upath+fpath+'03.dat'); rewrite(out3);
  AssignFile(out4,  upath+fpath+'04.dat'); rewrite(out4);
  AssignFile(out5,  upath+fpath+'05.dat'); rewrite(out5);
  AssignFile(out6,  upath+fpath+'06.dat'); rewrite(out6);
  AssignFile(out7,  upath+fpath+'07.dat'); rewrite(out7);
  AssignFile(out8,  upath+fpath+'08.dat'); rewrite(out8);
  AssignFile(out9,  upath+fpath+'09.dat'); rewrite(out9);
  AssignFile(out10, upath+fpath+'10.dat'); rewrite(out10);
  AssignFile(out11, upath+fpath+'11.dat'); rewrite(out11);
  AssignFile(out12, upath+fpath+'12.dat'); rewrite(out12);

//  showmessage('here3');
 for k:=0 to cbFilesT.Count-1 do begin
  AssignFile(datT, dpath+fpath+'t\'+cbFilesT.Items.Strings[k]); reset(datT);
  readln(datT);

  AssignFile(datS, dpath+fpath+'s\'+cbFilesS.Items.Strings[k]); reset(datS);
  readln(datS);

  yy:=StrToInt(copy(cbFilesT.Items.Strings[k],1,4));
  mn:=StrToInt(copy(cbFilesT.Items.Strings[k],6,2));

  fl:=0;
  lev0:=0; c:=0;

  Qt1:=0; Qs1:=0; Qt2:=0; Qs2:=0; Qt3:=0; Qs3:=0;
  repeat
    readln(datT, dist_tr, dist, lev, valT, stn, lat, lon);
    readln(datS, dist_tr, dist, lev, valS, stn, lat, lon);

    SA  := gsw_SA_from_SP(ValS, p, Lon, Lat);
    ValD:= gsw_rho_t_exact(sa, ValT, p);
    Tf  := gsw_t_freezing(sa, p, saturation_fraction);

    Cp  := gsw_cp_t_exact(sa, valt, p);
 //   showmessage(floattostr(cp));

    Kt:=ValD*Cp*(ValT-Tf);
    Ks:=ValD*(ValS/1000);

  {  memo1.lines.add(floattostr(lev)+'   '+
                floattostr(valT)+'   '+
                floattostr(valS)+'   '+
                floattostr(valD)+'   '+
                floattostr(Tf)+'   '+
                floattostr(Kt)+'   '+
                floattostr(Ks));  }

    if stn=0 then begin
       stn_old:=stn;
       dist0:=dist;
    end;

    if stn=stn_old then begin
      inc(c);
      L_arr[c] :=-lev;
      T_arr[c] :=ValT;
      Kt_arr[c]:=Kt;
      Ks_arr[c]:=Ks;
    end;

    if stn<>stn_old then begin
     noQ3:=false;

     // layer 1
     Kt1:=0; Ks1:=0;
     l_min1:=9999; l_max1:=-9999;
     for i:=c downto 1 do begin
      if (L_arr[i]>=47) and (T_arr[i]>=0) then begin
        Kt1:=Kt1+(((Kt_arr[i]+Kt_arr[i-1])/2)*(L_arr[i-1]-L_arr[i]));
        Ks1:=Ks1+(((Ks_arr[i]+Ks_arr[i-1])/2)*(L_arr[i-1]-L_arr[i]));
        l_min1:=min(l_min1, L_arr[i]);
        l_max1:=max(l_max1, L_arr[i]);
      end;
     end;

     // layer 2
     Kt2:=0; Ks2:=0;
     l_min2:=9999; l_max2:=-9999;
     for i:=c downto 1 do begin
      if (L_arr[i]>200) and (L_arr[i]<1500) and (T_arr[i]<0) then begin
        Kt2:=Kt2+(((Kt_arr[i]+Kt_arr[i-1])/2)*(L_arr[i-1]-L_arr[i]));
        Ks2:=Ks2+(((Ks_arr[i]+Ks_arr[i-1])/2)*(L_arr[i-1]-L_arr[i]));
        l_min2:=min(l_min2, L_arr[i]);
        l_max2:=max(l_max2, L_arr[i]);
      end;
     end;

     // layer 3
     Kt3:=0; Ks3:=0;
     l_min3:=9999; l_max3:=-9999;
     for i:=c downto 1 do begin
      if (L_arr[i]>=47) and (L_arr[i]<200) and (T_arr[i]<0) then begin
        Kt3:=Kt3+(((Kt_arr[i]+Kt_arr[i-1])/2)*(L_arr[i-1]-L_arr[i]));
        Ks3:=Ks3+(((Ks_arr[i]+Ks_arr[i-1])/2)*(L_arr[i-1]-L_arr[i]));
        l_min3:=min(l_min3, L_arr[i]);
        l_max3:=max(l_max3, L_arr[i]);
      end;
     end;

       memo1.lines.add(floattostr(kt1)+'   '+
                     floattostr(ks1)+'   '+
                     floattostr(l_min1)+'   '+
                     floattostr(l_max1)+'   '+
                     floattostr(kt2)+'   '+
                     floattostr(ks2)+'   '+
                     floattostr(l_min2)+'   '+
                     floattostr(l_max2)+'   '+
                     floattostr(kt3)+'   '+
                     floattostr(ks3)+'   '+
                     floattostr(l_min3)+'   '+
                     floattostr(l_max3));


  {    memo1.lines.add(floattostr(kt1)+'   '+
                      floattostr(ks1)+'   '+
                      floattostr(kt2)+'   '+
                      floattostr(ks2)+'   '+
                      floattostr(kt3)+'   '+
                      floattostr(ks3)); }
 //   end;  // profile

//    showmessage(floattostr(dist-dist0));

    Qt1:=Qt1+Kt1*(dist-dist0);
    Qt2:=Qt2+Kt2*(dist-dist0);
    Qt3:=Qt3+Kt3*(dist-dist0);

    Qs1:=Qs1+Ks1*(dist-dist0);
    Qs2:=Qs2+Ks2*(dist-dist0);
    Qs3:=Qs3+Ks3*(dist-dist0);

          {      memo1.lines.add(floattostr(stn)+'   '+
                      floattostr(Qt1)+'   '+
                      floattostr(Qs1));  }

 {   memo1.lines.add('======');

  memo1.lines.add(floattostr(Qt1)+'  '+floattostr(Qs1)+'   '+
                  floattostr(Qt2)+'  '+floattostr(Qs2)+'   '+
                  floattostr(Qt3)+'  '+floattostr(Qs3));  }

    for i:=1 to 100 do begin
      L_arr[i] :=0;
      T_arr[i] :=0;
      Kt_arr[i]:=0;
      Ks_arr[i]:=0;
    end;

     stn_old:=stn;
     dist0:=dist;

     c:=1;
     L_arr[1]:=-lev;
     T_arr[1]:=ValT;
     Kt_arr[1]:=Kt;
     Ks_arr[1]:=Ks;

    end; //stn<>stn_old

  until eof(datT);
  CloseFile(datT);
  CloseFile(datS);

//  exit;

  Qt1:=RoundTo(Qt1/dist/10E+6, -3);
  Qt2:=RoundTo(Qt2/dist/10E+6, -3);
  Qt3:=RoundTo(Qt3/dist/10E+6, -3);

  Qs1:=RoundTo(Qs1/dist, -3);
  Qs2:=RoundTo(Qs2/dist, -3);
  Qs3:=RoundTo(Qs3/dist, -3);

  {  showmessage(floattostr(Qt1)+'  '+floattostr(Qs1)+#13+
              floattostr(Qt2)+'  '+floattostr(Qs2)+#13+
              floattostr(Qt3)+'  '+floattostr(Qs3)); }

  str:=inttostr(yy)+'   '+
       floattostrF(Qt1, fffixed, 20, 3)+'   '+
       floattostrF(Qs1, fffixed, 20, 3)+'   '+
       floattostrF(Qt2, fffixed, 20, 3)+'   '+
       floattostrF(Qs2, fffixed, 20, 3)+'   '+
       floattostrF(Qt3, fffixed, 20, 3)+'   '+
       floattostrF(Qs3, fffixed, 20, 3);

  // exit;
  case mn of
   1:  writeln(out1,  str);
   2:  writeln(out2,  str);
   3:  writeln(out3,  str);
   4:  writeln(out4,  str);
   5:  writeln(out5,  str);
   6:  writeln(out6,  str);
   7:  writeln(out7,  str);
   8:  writeln(out8,  str);
   9:  writeln(out9,  str);
   10: writeln(out10, str);
   11: writeln(out11, str);
   12: writeln(out12, str);
 end;

 end;

 CloseFile(out1);
 CloseFile(out2);
 CloseFile(out3);
 CloseFile(out4);
 CloseFile(out5);
 CloseFile(out6);
 CloseFile(out7);
 CloseFile(out8);
 CloseFile(out9);
 CloseFile(out10);
 CloseFile(out11);
 CloseFile(out12);
end;

end; //sections

end.

