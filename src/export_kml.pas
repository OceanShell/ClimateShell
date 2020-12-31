unit export_KML;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin, Math,
  IniFiles, LCLIntf, ExtCtrls;

type

  { Tfrmexport_KML }

  Tfrmexport_KML = class(TForm)
    btnExport: TButton;
    chkOpenAfterExport: TCheckBox;
    eMaxLat: TFloatSpinEdit;
    eMaxLon: TFloatSpinEdit;
    eMinLat: TFloatSpinEdit;
    eMinLon: TFloatSpinEdit;
    seScale: TFloatSpinEdit;
    GroupBox4: TGroupBox;
    Label1: TLabel;
    rgOver: TRadioGroup;

    procedure btnExportClick(Sender: TObject);
    procedure FormShow(Sender: TObject);

  private

  public
    procedure ExportKML_(DataFile:string; MinLon, MaxLon,
      MinLat, MaxLat:real; Var cnt:integer);
  end;

var
  frmexport_KML: Tfrmexport_KML;

implementation

{$R *.lfm}

uses ncmain, declarations_netcdf, bathymetry;

procedure Tfrmexport_KML.FormShow(Sender: TObject);
begin
  eMinLat.Value := MinValue(ncLat_arr);
  eMinLon.Value := MinValue(ncLon_arr);
  eMaxLat.Value := MaxValue(ncLat_arr);
  eMaxLon.Value := MaxValue(ncLon_arr);
end;


procedure Tfrmexport_KML.btnExportClick(Sender: TObject);
Var
  DataFile: string;
  cnt:integer;
begin
 DataFile:=GlobalUnloadPath+'kml'+PathDelim+'stations.kml';

 try
 btnExport.Enabled:=false;
   ExportKML_(DataFile, eMinLon.Value, eMaxLon.Value, eMinLat.Value, eMaxLat.Value, cnt);
 if chkOpenAfterExport.Checked=true then begin
  OpenDocument(DataFile);
  Showmessage(inttostr(cnt)+' '+SKMLNodes);
 end;
 finally
   btnExport.Enabled:=true;
 end;
end;


procedure Tfrmexport_KML.ExportKML_(DataFile:string; MinLon, MaxLon,
  MinLat, MaxLat:real; Var cnt:integer);
Var
Ini:TIniFile;
f_out:text;
descr, coord, sep: string;
lt_i, ln_i, dep:integer;

ncid, dimid, varxid, varyid:integer;
ncols, nrows :size_t;
start2: PArraySize_t;

fp:array of single;
Lat1, Lon1 :real;
begin
 if not DirectoryExists(GlobalUnloadPath+'kml'+PathDelim) then
    CreateDir(GlobalUnloadPath+'kml'+PathDelim);

 try
  AssignFile(f_out, DataFile); rewrite(f_out);
  Ini := TIniFile.Create(IniFileName);

  Writeln(f_out, '<?xml version="1.0" encoding="UTF-8"?>');
  Writeln(f_out, '<kml xmlns="http://earth.google.com/kml/2.2">');
  Writeln(f_out, ' <Document>');
  Writeln(f_out, '   <Style id="hideLabel">');
  Writeln(f_out, '    <BalloonStyle>');
  Writeln(f_out, '      <text><![CDATA[');
  Writeln(f_out, '      <p><b>Node=<font color="red">$[name]</b></font></p>]]>');
  Writeln(f_out, '       $[description]');
  Writeln(f_out, '       </text>');
  Writeln(f_out, '    </BalloonStyle>');
  Writeln(f_out, '    <IconStyle>');
  Writeln(f_out, '      <color>#FF0000FF</color>');
  Writeln(f_out, '      <scale>'+seScale.Text+'</scale>');
  Writeln(f_out, '      <Icon><href>http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png</href></Icon>');
  Writeln(f_out, '    </IconStyle>');
  Writeln(f_out, '    <LabelStyle>');
  Writeln(f_out, '     <scale>0</scale>');
  Writeln(f_out, '    </LabelStyle>');
  Writeln(f_out, '   </Style>');

  sep:=' &lt;br/&gt;';

 (* all files with coordinates inside *)

 //showmessage('here');

   (* количество строк и столбцов для обычного файла *)
   if curve=false then begin
     ncols:=high(ncLon_arr)+1;
     nrows:=high(ncLat_arr)+1;
   end;

   (* Если файл с криволинейными координатами - запрашиваем размерности из из значения*)
   if curve=true then begin
     nc_open(pansichar(AnsiString(ncpath+ncname)), NC_NOWRITE, ncid); // only for reading
      nc_inq_dimid (ncid, pAnsiChar(AnsiString('x')), dimid);
      nc_inq_dimlen(ncid, dimid, ncols);
      nc_inq_dimid (ncid, pAnsiChar(AnsiString('y')), dimid);
      nc_inq_dimlen(ncid, dimid, nrows);

      nc_inq_varid(ncid, pAnsiChar(AnsiString('nav_lon')), varxid); // longitude
      nc_inq_varid(ncid, pAnsiChar(AnsiString('nav_lat')), varyid); // latitude

      start2:=GetMemory(SizeOf(TArraySize_t)*2); // get memory for curvelinear coordinates
   end;

   //showmessage('1');

  cnt:=0;
   for lt_i:=0 to nrows-1  do begin //Latitude
     for ln_i:=0 to ncols-1  do begin  //Longitude

       if curve=false then begin
         Lat1:=ncLat_arr[lt_i];
         Lon1:=ncLon_arr[ln_i];
       end;

      (* для криволинейных координат *)
      if curve=true then begin
       start2^[0]:=lt_i;  //curvelinear lat
       start2^[1]:=ln_i;   //curvelinear lon

       SetLength(fp, 1);
        nc_get_var1_float(ncid, varyid, start2^, fp);
       Lat1:=fp[0];

       SetLength(fp, 1);
        nc_get_var1_float(ncid, varxid, start2^, fp);
       Lon1:=fp[0];
       if Lon1>180 then Lon1:=Lon1-360;
      end;
     (* конец для крив. координат *)

   //  showmessage(floattostr(lat1)+'   '+floattostr(maxlat)+'   '+floattostr(minlat)+'   '+
  //   floattostr(lon1)+'   '+floattostr(maxlon)+'   '+floattostr(minlon));

     if (lat1>=MinLat) and (lat1<=MaxLat) and
         (((MinLon<=MaxLon) and (lon1>=MinLon) and (lon1<=MaxLon)) or
          ((MinLon>MaxLon) and
           (((lon1>=MinLon) and (lon1<=180)) or
            ((lon1>=-180) and (lon1<=MaxLon)))))  then begin

       dep:=GetBathymetry(Lon1, Lat1);

       if (((rgOver.ItemIndex=0) and (dep<0)) or  //water
          ((rgOver.ItemIndex=1) and (dep>=0)) or //land
           (rgOver.ItemIndex=2)) then begin

            inc(cnt); //count for exported nodes
       descr:='Latitude = '  +FloattostrF(Lat1, fffixed, 8, 5) +sep+
              'Longitude = ' +FloattostrF(Lon1, fffixed, 9, 5) +sep+
              'Elevation = '     +Inttostr(dep);

       coord:=Floattostr(Lon1)+', '+Floattostr(Lat1);

       Writeln(f_out, '   <Placemark>');
       Writeln(f_out, '    <name>'+inttostr(cnt)+'</name>');
       Writeln(f_out, '    <styleUrl>#hideLabel</styleUrl>');
       Writeln(f_out, '    <description>'+descr+'</description>');
       Writeln(f_out, '     <Point>');
       Writeln(f_out, '      <coordinates>'+coord+', 0</coordinates>');
       Writeln(f_out, '     </Point>');
       Writeln(f_out, '   </Placemark>');

      end; // depth
     end; // region
   end; // longitude
  end; // latitude


 if curve=true then begin
  FreeMemory(start2);
  fp:=nil;
  nc_close(ncid);  // Close file
 end;

 Finally
  Writeln(f_out, ' </Document>');
  Writeln(f_out, '</kml>');
  Closefile(f_out);
  Ini.free;
 end;
end;

end.

