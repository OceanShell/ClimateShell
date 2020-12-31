unit nctopography3d;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Spin, Variants;

type

  { Tfrmtopography3D }

  Tfrmtopography3D = class(TForm)
    btnPlot: TButton;
    CheckBox1: TCheckBox;
    Label1: TLabel;
    seLatMax: TFloatSpinEdit;
    SeLonMin: TFloatSpinEdit;
    seLatMin: TFloatSpinEdit;
    seLonMax: TFloatSpinEdit;
    GroupBox1: TGroupBox;
    seSkip: TSpinEdit;
    procedure btnPlotClick(Sender: TObject);
    procedure FormShow(Sender: TObject);

  private
    { private declarations }
    procedure GetScript;
  public
    { public declarations }
  end;

var
  frmtopography3D: Tfrmtopography3D;


implementation

{$R *.lfm}

{ Tfrmtopography3D }

uses ncmain, declarations_netcdf;


procedure Tfrmtopography3D.FormShow(Sender: TObject);
begin
   if not DirectoryExists(GlobalUnloadPath+'topography\') then
    CreateDir(GlobalUnloadPath+'topography\');
end;

procedure Tfrmtopography3D.btnPlotClick(Sender: TObject);
Var
 dat:text;
 fname, fout: string;
 status, ncid, cnt :integer;
 start: PArraySize_t;
 sp:array of single;
 dp: array of double;
 lt0, ln0, lt1, ln1, i, j: integer;
 x, y, lat, lon, lat0, lon0, step, gebco:real;
begin

fout:=GlobalUnloadPath+'topography\'+
      selatmin.Text+'_'+selatmax.Text+'_'+
      selonmin.Text+'_'+selonmax.Text+'.dat';

lat0:=-(89+(59/60)+(525E-1/3600)); // first latitude
lon0:=-(179+(59/60)+(525E-1/3600)); // first longitude
step  := 1/240;

lt0:=abs(trunc((lat0-selatmin.Value)/step)); // lat index 0
ln0:=abs(trunc((lon0-selonmin.Value)/step)); // lon index 0

lt1:=abs(trunc((lat0-selatmax.Value)/step)); // lat index 1
ln1:=abs(trunc((lon0-selonmax.Value)/step)); // lon index 1

fname:=GlobalSupportPath+'bathymetry'+PathDelim+'GEBCO_2019.nc';

   if not FileExists(fname) then begin
    showmessage('Topography is not found');
    exit;
   end;

AssignFile(dat, fout); rewrite(dat);
 try
  // opening GEBCO_2019.nc
   nc_open(pansichar(fname), NC_NOWRITE, ncid);
     start:=GetMemory(SizeOf(TArraySize_t)*2);

  cnt:=0;
  for i:=lt0 to lt1 do begin
     start^[0]:=i;
     SetLength(dp, 1);
       nc_get_var1_double(ncid, 1, start^, dp);
     Lat:=dp[0];
      for j:=ln0 to ln1 do begin
        start^[0]:=j;
        SetLength(dp, 1);
         nc_get_var1_double(ncid, 0, start^, dp);
        Lon:=dp[0];

        // search by indexes
        start^[0]:=i;
        start^[1]:=j;

        SetLength(sp, 1); // setting an empty array
          nc_get_var1_float(ncid, 2, start^, sp);  // sending request to the file
        gebco:=round(sp[0]); // getting results

     //   showmessage(floattostr(gebco));

        x:= (90-Lat)*111.12*sin((Lon)*Pi/180);
        y:=-(90-Lat)*111.12*cos((Lon)*Pi/180);

         inc(cnt);
     //    if cnt=seSkip.value then begin
           if checkbox1.Checked then begin
            if gebco<0 then
             writeln(dat, floattostrF(Lat, fffixed, 10, 5), '   ',
                          floattostrF(Lon, fffixed, 10, 5), '   ',
                          floattostrF(y, fffixed, 15, 5), '   ',
                          floattostrF(x, fffixed, 15, 5), '   ',
                          floattostrF(gebco, fffixed, 10, 3)) else
             writeln(dat, floattostrF(Lat, fffixed, 10, 5), '   ',
                          floattostrF(Lon, fffixed, 10, 5), '   ',
                          floattostrF(y, fffixed, 15, 5), '   ',
                          floattostrF(x, fffixed, 15, 5), '   ',
                          1)
           end else
       writeln(dat, floattostrF(Lat, fffixed, 10, 5), '   ',
                    floattostrF(Lon, fffixed, 10, 5), '   ',
                    floattostrF(y, fffixed, 15, 5), '   ',
                    floattostrF(x, fffixed, 15, 5), '   ',
                    floattostrF(gebco, fffixed, 10, 3));
       cnt:=0;
     // end; //skip
     end;
   end;

    FreeMemory(start);

    Closefile(dat);
   finally
    sp:=nil;
     status:=nc_close(ncid);  // Close file
      if status>0 then showmessage(pansichar(nc_strerror(status)));

   end;
end;


procedure Tfrmtopography3D.GetScript;
begin
 //
end;

end.

