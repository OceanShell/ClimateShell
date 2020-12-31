unit nctimeseriesnodes;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Buttons, IniFiles, Variants, DateUtils, Math;

type

  { Tfrmncexportfield }

  Tfrmncexportfield = class(TForm)
    btnOpenFolder: TBitBtn;
    Button1: TButton;
    cbVariable1: TComboBox;
    eAdditionalOffset1: TEdit;
    eAdditionalScale1: TEdit;
    eMaxLat: TEdit;
    eMaxLon: TEdit;
    eMinLat: TEdit;
    eMinLon: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    rgOver: TRadioGroup;

    procedure FormShow(Sender: TObject);
    procedure btnOpenFolderClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);

  private
    { private declarations }
  public
    { public declarations }
  end;


var
  frmncexportfield: Tfrmncexportfield;
  ncexportfieldpath:string;
  f_dat:text;

implementation

{$R *.lfm}

{ Tfrmncexportfield }

uses ncmain, ncprocedures, declarations_netcdf, Bathymetry;

procedure Tfrmncexportfield.FormShow(Sender: TObject);
Var
  LatMin, LatMax, LonMin, LonMax, depth: real;
  k:integer;
begin
  ncexportfieldpath:=GlobalPath+'unload\export\fields\';
  if not DirectoryExists(ncexportfieldpath) then CreateDir(ncexportfieldpath);

 LatMin:=90; LatMax:=-90;
 for k:=0 to High(ncLat_arr) do begin // Latitude loop
  LatMin:=Min(LatMin, ncLat_arr[k]);
  LatMax:=Max(LatMax, ncLat_arr[k]);
 end;

 LonMin:=180; LonMax:=-180;
 for k:=0 to High(ncLon_arr) do begin // Latitude loop
  LonMin:=Min(LonMin, ncLon_arr[k]);
  LonMax:=Max(LonMax, ncLon_arr[k]);
 end;

 // min and max coordinates
 eMaxLat.Text:=floattostr(LatMax);
 eMinLat.Text:=floattostr(LatMin);
 eMinLon.Text:=floattostr(LonMin);
 eMaxLon.Text:=floattostr(LonMax);

 cbVariable1.Items := frmmain.cbVariables.items;
end;


procedure Tfrmncexportfield.Button1Click(Sender: TObject);
Var
  mn, lt_i, ln_i, node, k_d:integer;
  lat, lon:real;

  k, i, a:integer;
  tp, fl:integer;
  status, ncid, varidp, varidp2, ndimsp, varnattsp, dimid:integer;
  varxid, varyid : integer;
  start, start2: PArraySize_t;
   fp:array of single;
   sp:array of smallint;
   ip:array of integer;
   dp:array of double;
  vtype: nc_type;
  attlenp, lenp: size_t;
  attname:    array of pAnsiChar;
  scale, offset, missing: array [0..0] of single;
    scale_ex, offset_ex, missing_ex: boolean;
  val0, val_err:variant;
  val1, firstval1, lat1, lon1, depth:real;
    atttext: array of pchar;
    yy, dd, mn0, hh, mm, ss, ms:word;

    par:string;
begin
 For mn:=1 to 12 do begin

 AssignFile(f_dat, ncexportfieldpath+inttostr(mn)+'.dat'); Rewrite(f_dat);
 write(f_dat, 'year':5);

    for lt_i:=0 to high(ncLat_arr) do begin
     lat:=ncLat_arr[lt_i];
     for ln_i:=0 to high(ncLon_arr) do begin
       lon:=ncLon_arr[ln_i];
       depth:=GetBathymetry(Lon, Lat);

      if ((lat>=StrToFloat(eMinLat.Text)) and
          (lat<=StrToFloat(eMaxLat.Text)) and
          (lon>=StrToFloat(eMinLon.Text)) and
          (lon<=StrToFloat(eMaxLon.Text))) and
             (((rgOver.ItemIndex=0) and (depth<-10)) or  //water
              ((rgOver.ItemIndex=1) and (depth>=-10)) or //land
               (rgOver.ItemIndex=2)) then begin
          write(f_dat, ('"'+floattostr(Lat)+';'+floattostr(Lon)+'"'):15);
       end; // reg
    end; //lon
   end; //lat
  writeln(f_dat);


 (* перебираем все выбранные nc файлы *)
 for k:=0 to frmmain.cbFiles.count-1 do begin
  ncName:=frmmain.cbFiles.Items.strings[k];

  par:=cbVariable1.Text;

  try
 (* nc_open*)
   nc_open(pansichar(AnsiString(ncpath+ncname)), NC_NOWRITE, ncid); // only for reading

   nc_inq_varid    (ncid, pAnsiChar(AnsiString(par)), varidp); // variable ID
   nc_inq_vartype  (ncid, varidp, vtype);   // variable type
   nc_inq_varndims (ncid, varidp, ndimsp);  // dimentions quantity

   (* Читаем коэффициенты из файла *)
   scale[0]:=1; scale_ex:=false;
   offset[0]:=0; offset_ex:=false;
   missing[0]:=-9999; missing_ex:=false;

   nc_inq_varnatts (ncid, varidp, varnattsp); // count of attributes for variable
   setlength(attname, NC_MAX_NAME); // задаем длину названия аттрибута
    for a:=0 to varnattsp-1 do begin
      nc_inq_attname(ncid, varidp, a, attname); // имя аттрибута
      if pAnsiChar(attname)='add_offset'    then begin
         nc_get_att_float(ncid, varidp, pansichar(pansichar(AnsiString('add_offset'))),    offset);
         offset_ex:=true;
      end;
      if pAnsiChar(attname)='scale_factor'  then begin
         nc_get_att_float(ncid, varidp, pansichar(pansichar(AnsiString('scale_factor'))),  scale);
          if scale[0]=0 then scale[0]:=1;
         scale_ex:=true;
      end;
      if pAnsiChar(attname)='missing_value' then begin
         nc_get_att_float(ncid, varidp, pansichar(pansichar(AnsiString('missing_value'))), missing);
         missing_ex:=true;
      end;
    end;

   if scale_ex   = false then scale[0]:=1;
   if offset_ex  = false then offset[0]:=0;
   if missing_ex = false then missing[0]:=-9999;

   nc_inq_dimlen (ncid, timeDid, lenp);
    setlength(ncTime_arr, lenp);
    nc_get_var_double (ncid, timeVid, ncTime_arr);

   nc_inq_attlen (ncid, timeVid, pansichar(AnsiString('units')), attlenp);
   setlength(atttext, attlenp);
   nc_get_att_text (ncid, timeVid, pansichar(AnsiString('units')), atttext);

   GetDates(pansichar(atttext));

  start:=GetMemory(SizeOf(TArraySize_t)*ndimsp); // get memory for start pointer

  fl:=0;

  for k_d:=0 to high(ncTime_arr) do begin
   start^[0]:=k_d; //time

  DecodeDateTime(StrToDateTime(frmmain.cbDates.Items.Strings[k_d]), yy, mn0, dd, hh, mm, ss, ms);

  if mn0=mn then begin
   write(f_dat, yy:5);

    for lt_i:=0 to high(ncLat_arr) do begin //Latitude
     start^[1]:=lt_i;  //lat
      lat:=ncLat_arr[lt_i];
     for ln_i:=0 to high(ncLon_arr) do begin
       lon:=ncLon_arr[ln_i];
        start^[2]:=ln_i;

       depth:=GetBathymetry(Lon, Lat);

     if ((lat>=StrToFloat(eMinLat.Text)) and
         (lat<=StrToFloat(eMaxLat.Text)) and
         (lon>=StrToFloat(eMinLon.Text)) and
         (lon<=StrToFloat(eMaxLon.Text))) and
             (((rgOver.ItemIndex=0) and (depth<-10)) or //water
              ((rgOver.ItemIndex=1) and (depth>=10)) or //land
               (rgOver.ItemIndex=2)) then begin

          // NC_SHORT
          if VarToStr(vtype)='3' then begin
           SetLength(sp, 1);
            nc_get_var1_short(ncid, varidp, start^, sp);
           Val0:=sp[0];
          end;

          // NC_INT
          if VarToStr(vtype)='4' then begin
           SetLength(ip, 1);
            nc_get_var1_int(ncid, varidp, start^, ip);
           Val0:=ip[0];
          end;

          // NC_FLOAT
          if VarToStr(vtype)='5' then begin

           SetLength(fp, 1);
            nc_get_var1_float(ncid, varidp, start^, fp);
           Val0:=fp[0];
           // showmessage(vartostr(fp[0]));
          end;

          // NC_DOUBLE
          if VarToStr(vtype)='6' then begin
           SetLength(dp, 1);
            nc_get_var1_double(ncid, varidp, start^, dp);
           Val0:=dp[0];
          end;
        //  showmessage(floattostr(val0));

          //inc(node);
          if (val0<>missing[0]) and (val0<>-1000) then begin //both
                val1:=scale[0]*val0+offset[0]; // scale and offset from nc file
                val1:=StrToFloat(eAdditionalScale1.Text)*val1+StrToFloat(eAdditionalOffset1.Text);  // additional conversion
          end else val1:=-9999;
        write(f_dat, val1:15:3);

      end;  //reg
      end; //lon
   end; //lat
   writeln(f_dat);
    end; //mn

  end; //time

  FreeMemory(start);


 finally
  fp:=nil;
   status:=nc_close(ncid);  // Close file
    if status>0 then showmessage(pansichar(nc_strerror(status)));
 end;


 end; // Конец перебора nc файлов
 Closefile(f_dat);
 // cds.Free;
 end;//month
end;

procedure Tfrmncexportfield.btnOpenFolderClick(Sender: TObject);
begin
  OpenDocument(PChar(ncexportfieldpath));
end;

end.

