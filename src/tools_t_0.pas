unit tools_t_0;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TfrmtoolsT_0 }

  TfrmtoolsT_0 = class(TForm)
    btnPrepartT_0: TButton;
    btnPrepareFWC: TButton;
    btnT_0_norma: TButton;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
//   procedure btnPrepareFWCClick(Sender: TObject);
    procedure btnPrepartT_0Click(Sender: TObject);
    procedure btnT_0_normaClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private

  public

  end;

var
  frmtoolsT_0: TfrmtoolsT_0;

implementation

{$R *.lfm}

uses ncmain, bathymetry;

{ TfrmtoolsT_0 }

procedure TfrmtoolsT_0.btnPrepartT_0Click(Sender: TObject);
Var
dat, outf:text;
fpath, yy_str, yy_end:string;
k: integer;
yy, mn, dd, lat, lon, val, gebco, x, y: real;
begin
fpath:='X:\Results\GV\fresh_water\T_0_updated\data\';

for k:=1 to 6 do begin
 case k of
  1: yy_str:='1960';
  2: yy_str:='1970';
  3: yy_str:='1980';
  4: yy_str:='1990';
  5: yy_str:='2000';
  6: yy_str:='2010';
 end;

 yy_end:=Inttostr(strtoint(yy_str)+9);

AssignFile(dat, fpath+'T_0_'+yy_str+'.dat'); reset(dat);
AssignFile(outf, fpath+'T_0_'+yy_str+yy_end+'.dat'); rewrite(outf);

repeat
  readln(dat, yy, mn, dd, lon, lat, val);

  gebco:=-GetBathymetry(lon, lat);

  x:= (90-Lat)*111.12*sin((Lon)*Pi/180);
  y:=-(90-Lat)*111.12*cos((Lon)*Pi/180);

  if (((lon<=-100) or (lon>=100)) or (lat>=80)) and
     (gebco >=800) then begin
  writeln(outf, trunc(yy), ' ',
                trunc(mn), ' ',
                trunc(dd), ' ',
                Floattostr(lon), ' ',
                Floattostr(lat), ' ',
                Floattostr(val), ' ',
                Floattostr(x), ' ',
                Floattostr(y));

     end;
until eof(dat);

CloseFile(dat);
CloseFile(outf);
end;
end;



procedure TfrmtoolsT_0.btnT_0_normaClick(Sender: TObject);
Var
dat, outn:text;
fpath, yy_str, yy_end:string;
k: integer;
yy, mn, dd, lat, lon, val, gebco, x, y: real;
begin
fpath:='X:\Results\GV\fresh_water\T_0_updated\data\';

AssignFile(outn, fpath+'T_0_19602019.dat'); rewrite(outn);

for k:=1 to 6 do begin
 case k of
  1: yy_str:='19601969';
  2: yy_str:='19701979';
  3: yy_str:='19801989';
  4: yy_str:='19901999';
  5: yy_str:='20002009';
  6: yy_str:='20102019';
 end;

AssignFile(dat, fpath+'T_0_'+yy_str+'.dat'); reset(dat);
repeat
  readln(dat, yy, mn, dd, lon, lat, val, x, y);

  writeln(outn, trunc(yy), ' ',
                trunc(mn), ' ',
                trunc(dd), ' ',
                Floattostr(lon), ' ',
                Floattostr(lat), ' ',
                Floattostr(val), ' ',
                Floattostr(x), ' ',
                Floattostr(y));
until eof(dat);
CloseFile(dat);
end;
CloseFile(outn);
end;





procedure TfrmtoolsT_0.Button1Click(Sender: TObject);
Var
dat, outn:text;
fpath, yy_str, yy_end:string;
k: integer;
yy, mn, dd, lat, lon, val, gebco, x, y: real;
begin
fpath:='X:\Results\GV\fresh_water\FWC\data\';

AssignFile(outn, fpath+'FWC_19602019.dat'); rewrite(outn);

for k:=1 to 6 do begin
 case k of
  1: yy_str:='19601969';
  2: yy_str:='19701979';
  3: yy_str:='19801989';
  4: yy_str:='19901999';
  5: yy_str:='20002009';
  6: yy_str:='20102019';
 end;

AssignFile(dat, fpath+'FWC_'+yy_str+'.dat'); reset(dat);
repeat
  readln(dat, yy, mn, dd, lon, lat, val, x, y);

  writeln(outn, trunc(yy), ' ',
                trunc(mn), ' ',
                trunc(dd), ' ',
                Floattostr(lon), ' ',
                Floattostr(lat), ' ',
                Floattostr(val), ' ',
                Floattostr(x), ' ',
                Floattostr(y));
until eof(dat);
CloseFile(dat);
end;
CloseFile(outn);
end;


procedure TfrmtoolsT_0.Button2Click(Sender: TObject);
Var
dat, outf:text;
fpath, fname, yy_str, yy_end:string;
k: integer;
yy, mn, dd, lat, lon, val, gebco, x, y: real;
begin
fpath:='X:\Publications\_Papers\_Unpublished\2019_GV\data Andrey\BSAW_2000_2018\';

for k:=1 to 2 do begin

if k=1 then fname:=fpath+'T_0_20002009.txt';
if k=2 then fname:=fpath+'T_0_20102016.txt';

AssignFile(dat, fname); reset(dat);
AssignFile(outf, fname+'_'); rewrite(outf);

repeat
  readln(dat, yy, mn, dd, lon, lat, val);

  gebco:=-GetBathymetry(lon, lat);

  x:= (90-Lat)*111.12*sin((Lon)*Pi/180);
  y:=-(90-Lat)*111.12*cos((Lon)*Pi/180);

  if (((lon<=-100) or (lon>=100)) or (lat>=80)) and
     (gebco >=800) then begin
  writeln(outf, trunc(yy), ' ',
                trunc(mn), ' ',
                trunc(dd), ' ',
                Floattostr(lon), ' ',
                Floattostr(lat), ' ',
                Floattostr(val), ' ',
                Floattostr(x), ' ',
                Floattostr(y));

     end;
  until eof(dat);

  CloseFile(dat);
  CloseFile(outf);
end;
end;

procedure TfrmtoolsT_0.Button3Click(Sender: TObject);
Var
dat, outf:text;
fpath, fname, yy_str, yy_end:string;
k: integer;
yy, mn, dd, lat, lon, val, gebco, x, y: real;
begin
fpath:='X:\Publications\_Papers\_Unpublished\2019_GV\pictures\_Andrey\FWC\';

for k:=1 to 2 do begin

if k=1 then fname:=fpath+'FWC_20002009.txt';
if k=2 then fname:=fpath+'FWC_20102017.txt';

AssignFile(dat, fname); reset(dat);
AssignFile(outf, fname+'_'); rewrite(outf);

repeat
  readln(dat, yy, mn, dd, lon, lat, val);

  gebco:=-GetBathymetry(lon, lat);

  x:= (90-Lat)*111.12*sin((Lon)*Pi/180);
  y:=-(90-Lat)*111.12*cos((Lon)*Pi/180);

  if (((lon<=-100) or (lon>=100)) or (lat>=80)) and
     (gebco >=800) then begin
  writeln(outf, trunc(yy), ' ',
                trunc(mn), ' ',
                trunc(dd), ' ',
                Floattostr(lon), ' ',
                Floattostr(lat), ' ',
                Floattostr(val), ' ',
                Floattostr(x), ' ',
                Floattostr(y));

     end;
  until eof(dat);

  CloseFile(dat);
  CloseFile(outf);
end;
end;

end.

