unit ncprofiles;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, Buttons, Spin, ExtCtrls, Math, Variants, IniFiles;

type

  { TfrmncUnloadProfiles }

  TfrmncUnloadProfiles = class(TForm)
    btnOpenFolder: TBitBtn;
    btnPlot: TButton;
    cbDate: TComboBox;
    cbVariable: TComboBox;
    chkDensity: TCheckBox;
    eAddOffset: TFloatSpinEdit;
    eAddScale: TFloatSpinEdit;
    eLatMax: TFloatSpinEdit;
    eLatMin: TFloatSpinEdit;
    eLev1: TFloatSpinEdit;
    eLev2: TFloatSpinEdit;
    eLonMax: TFloatSpinEdit;
    eLonMin: TFloatSpinEdit;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    Label1: TLabel;
    Label7: TLabel;
    Label8: TLabel;

    procedure btnOpenFolderClick(Sender: TObject);
    procedure btnPlotClick(Sender: TObject);
    procedure FormShow(Sender: TObject);

  private
    { private declarations }
  public
    { public declarations }
    procedure GetProfile(fname, par:string; k_d:integer);
    procedure GetProfileDensity(fname:string; k_d:integer);
  end;

var
  frmncUnloadProfiles: TfrmncUnloadProfiles;
  f_dat:text;
  ncProfilePath:string;

implementation

{$R *.lfm}

uses ncmain, declarations_netcdf, ncprocedures;

{ TfrmncUnloadProfiles }

procedure TfrmncUnloadProfiles.FormShow(Sender: TObject);
Var
  k:integer;
  LatMin, LatMax, LonMin, LonMax: real;
begin
  cbVariable.Items:=frmmain.cbVariables.Items;
  if (timevid>-1) and (timedid>-1) then begin
  cbDate.Items:= frmmain.cbDates.items;
  end else cbDate.Enabled:=false;

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
   eLatMax.Text:=floattostr(LatMax);
   eLatMin.Text:=floattostr(LatMin);
   eLonMin.Text:=floattostr(LonMin);
   eLonMax.Text:=floattostr(LonMax);
end;


procedure TfrmncUnloadProfiles.btnPlotClick(Sender: TObject);
Var
  k, k_d:integer;
begin
  ncProfilePath:=GlobalPath+'unload'+PathDelim+'profiles'+PathDelim;
    if not DirectoryExists(ncProfilePath) then CreateDir(ncProfilePath);

  (* перебираем все выбранные nc файлы *)
 for k:=0 to frmmain.cbFiles.count-1 do begin
  ncName:=frmmain.cbFiles.Items.strings[k];
  frmmain.cbFiles.ItemIndex:=k;
  frmmain.cbFiles.OnClick(self);
   cbDate.Items:= frmmain.cbDates.items;
  Application.ProcessMessages;
   for k_d:=0 to frmmain.cbDates.Items.Count-1 do begin // Перебираем даты
     cbDate.ItemIndex:=k_d;
     Application.ProcessMessages;
      if chkDensity.Checked=false then GetProfile(ncPath+ncName, cbVariable.Text, k_d);
      if chkDensity.Checked=true  then GetProfileDensity(ncPath+ncName, k_d);
   end; //конец перебора дат
 end; // Конец перебора nc файлов
end;


procedure TfrmncUnloadProfiles.btnOpenFolderClick(Sender: TObject);
begin
OpenDocument(PChar(ncProfilePath));
end;


procedure TfrmncUnloadProfiles.GetProfile(fname, par:string; k_d:integer);
Var
  k, i, a:integer;
  lt_i, ln_i, ll_i, tp, fl:integer;
  status, ncid, varidp, varidp2, ndimsp, varnattsp, dimid:integer;
  varxid, varyid:integer;
  start, start2: PArraySize_t;
   fp:array of single;
   sp:array of smallint;
   ip:array of integer;
   dp:array of double;
  vtype: nc_type;
  attlenp, lenp: size_t;
  attname:    array of pAnsiChar;
  scale, offset, missing: array [0..0] of single;
  val0, val_err:variant;
  val1, firstval1, lat1, lon1, x, y:real;
  scale_ex, offset_ex, missing_ex: boolean;
  date_st:string;
begin

try
 (* nc_open*)
   nc_open(pansichar(AnsiString(fname)), NC_NOWRITE, ncid); // only for reading

   nc_inq_varid    (ncid, pAnsiChar(AnsiString(par)), varidp); // variable ID

   nc_inq_vartype  (ncid, varidp, vtype);   // variable type
   nc_inq_varndims (ncid, varidp, ndimsp);  // dimentions quantity

   (* Читаем коэффициенты из файла *)
   scale[0]:=1;
   offset[0]:=0;
   missing[0]:=-9999;
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
         if pAnsiChar(attname)='_FillValue' then begin
            nc_get_att_float(ncid, varidp, pansichar(pansichar(AnsiString('_FillValue'))), missing);
            missing_ex:=true;
         end;
    end;
      if scale_ex   = false then scale[0]:=1;
      if offset_ex  = false then offset[0]:=0;
      if missing_ex = false then missing[0]:=-9999;
   (*конец чтения коэффициентов *)

   //     showmessage(cbDate.Text);

   // assign output file
   date_st:=StringReplace(cbDate.Text, ':', '_', [rfReplaceAll, rfIgnoreCase]);

   AssignFile(f_dat, ncProfilePath+par+'_'+date_st+'.txt'); Rewrite(f_dat);
   writeln(f_dat, 'Lat':8, 'Lon':10, 'Y':13, 'X':13, 'Level':12, 'Value':10);

   start:=GetMemory(SizeOf(TArraySize_t)*ndimsp); // get memory for start pointer

  fl:=0;
   start^[0]:=k_d;

    for lt_i:=0 to high(ncLat_arr) do begin //Latitude
      start^[2]:=lt_i;  //lat
     for ln_i:=0 to high(ncLon_arr) do begin  //Longitude
       start^[3]:=ln_i;

     for ll_i:=0 to high(ncLev_arr) do begin
       start^[1]:=ll_i;

      if  (ncLat_arr[lt_i]>=eLatMin.Value) and
          (ncLat_arr[lt_i]<=eLatMax.Value) and
          (ncLon_arr[ln_i]>=eLonMin.Value) and
          (ncLon_arr[ln_i]<=eLonMax.Value) and
          (ncLev_arr[ll_i]>=eLev1.Value)   and
          (ncLev_arr[ll_i]<=eLev2.Value)   then begin
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
        //    showmessage(inttostr(varidp)+'   '+vartostr(fp[0]));
          end;

          // NC_DOUBLE
          if VarToStr(vtype)='6' then begin
           SetLength(dp, 1);
            nc_get_var1_double(ncid, varidp, start^, dp);
           Val0:=dp[0];
          end;

         if (val0<>missing[0]) and (val0<>-9999) then begin
             val1:=scale[0]*val0+offset[0]; // scale and offset from nc file
             val1:=eaddscale.Value*val1+eAddOffset.Value;  // additional conversion
              x:= (90-ncLat_arr[lt_i])*111.12*sin((ncLon_arr[ln_i])*Pi/180);
              y:=-(90-ncLat_arr[lt_i])*111.12*cos((ncLon_arr[ln_i])*Pi/180);

             writeln(f_dat, ncLat_arr[lt_i]:8:5, ncLon_arr[ln_i]:10:5, y:13:5, x:13:5, ncLev_arr[ll_i]:12:5, val1:10:5);
         end; //end of missing
        end; // end of region
       end; // Level
      end; // Longitude
     end; // Latitude

  FreeMemory(start);
  Closefile(f_dat);

 finally
  fp:=nil;
   status:=nc_close(ncid);  // Close file
    if status>0 then showmessage(pansichar(nc_strerror(status)));
 end;
end;


procedure TfrmncUnloadProfiles.GetProfileDensity(fname:string; k_d:integer);
Var
  Ini:TIniFile;
  ll, lt_i, ln_i, ll_i, a, pp, fl:integer;
  status, ncid, varidpT, varidpS, varnattsp, ll_max:integer;
  attname:    array of pAnsiChar;
  start: PArraySize_t;
  ft, fs:array of smallint;
  val0t, val0s:variant;
  val1t, val1s, val1, gebco, lat_dif, lon_dif:real;
  scaleT, offsetT, missingT: array [0..0] of single;
  scaleS, offsetS, missingS: array [0..0] of single;
  str_lt, str_ln, py_path, st :string;
  ParT, ParS, date_st: string;

  svan:real;
  SA, CT, dens, p:double;
  h, lat, lon:double;
  yy, mn:word;
  x, y:real;
begin

   ParT:='thetao';
   ParS:='so';

try
 (* nc_open*)
   nc_open(pansichar(AnsiString(fname)), NC_NOWRITE, ncid); // only for reading

   nc_inq_varid (ncid, pChar(ParT), varidpT);
   nc_inq_varid (ncid, pChar(ParS), varidpS);

     (* Читаем коэффициенты из файла *)
   scaleT[0]:=1;
   offsetT[0]:=0;
   missingT[0]:=-9999;
   nc_inq_varnatts (ncid, varidpT, varnattsp); // count of attributes for variable
   setlength(attname, NC_MAX_NAME); // задаем длину названия аттрибута
    for a:=0 to varnattsp-1 do begin
      nc_inq_attname(ncid, varidpT, a, attname); // имя аттрибута
         if pAnsiChar(attname)='add_offset'    then begin
            nc_get_att_float(ncid, varidpT, pansichar(pansichar(AnsiString('add_offset'))),    offsetT);
         end;
         if pAnsiChar(attname)='scale_factor'  then begin
            nc_get_att_float(ncid, varidpT, pansichar(pansichar(AnsiString('scale_factor'))),  scaleT);
             if scalet[0]=0 then scalet[0]:=1;
         end;
         if pAnsiChar(attname)='missing_value' then begin
            nc_get_att_float(ncid, varidpT, pansichar(pansichar(AnsiString('missing_value'))), missingT);
         end;
         if pAnsiChar(attname)='_FillValue' then begin
            nc_get_att_float(ncid, varidpT, pansichar(pansichar(AnsiString('_FillValue'))), missingT);
         end;
    end;

    scaleS[0]:=1;
    offsetS[0]:=0;
    missingS[0]:=-9999;
    nc_inq_varnatts (ncid, varidpS, varnattsp); // count of attributes for variable
    setlength(attname, NC_MAX_NAME); // задаем длину названия аттрибута
     for a:=0 to varnattsp-1 do begin
       nc_inq_attname(ncid, varidpS, a, attname); // имя аттрибута
          if pAnsiChar(attname)='add_offset'    then begin
             nc_get_att_float(ncid, varidpS, pansichar(pansichar(AnsiString('add_offset'))),    offsetS);
          end;
          if pAnsiChar(attname)='scale_factor'  then begin
             nc_get_att_float(ncid, varidpS, pansichar(pansichar(AnsiString('scale_factor'))),  scaleS);
              if scaleS[0]=0 then scaleS[0]:=1;
          end;
          if pAnsiChar(attname)='missing_value' then begin
             nc_get_att_float(ncid, varidpS, pansichar(pansichar(AnsiString('missing_value'))), missingS);
          end;
          if pAnsiChar(attname)='_FillValue' then begin
             nc_get_att_float(ncid, varidpS, pansichar(pansichar(AnsiString('_FillValue'))), missingS);
          end;
     end;
   (*конец чтения коэффициентов *)

   //     showmessage(cbDate.Text);

   // assign output file
   date_st:=StringReplace(cbDate.Text, ':', '_', [rfReplaceAll, rfIgnoreCase]);

   AssignFile(f_dat, ncProfilePath+'d_'+date_st+'.txt'); Rewrite(f_dat);
   writeln(f_dat, 'Lat':8, 'Lon':10, 'Y':13, 'X':13, 'Level':12, 'Value':10);

   start:=GetMemory(SizeOf(TArraySize_t)*4); // get memory for start pointer

  fl:=0;
   start^[0]:=k_d;

    for lt_i:=0 to high(ncLat_arr) do begin //Latitude
      start^[2]:=lt_i;  //lat
     for ln_i:=0 to high(ncLon_arr) do begin  //Longitude
       start^[3]:=ln_i;

     for ll_i:=0 to high(ncLev_arr) do begin
       start^[1]:=ll_i;

      if  (ncLat_arr[lt_i]>=eLatMin.Value) and
          (ncLat_arr[lt_i]<=eLatMax.Value) and
          (ncLon_arr[ln_i]>=eLonMin.Value) and
          (ncLon_arr[ln_i]<=eLonMax.Value) and
          (ncLev_arr[ll_i]>=eLev1.Value)   and
          (ncLev_arr[ll_i]<=eLev2.Value)   then begin

       SetLength(ft, 1);
       SetLength(fs, 1);
       nc_get_var1_short(ncid, varidpT, start^, ft);
       nc_get_var1_short(ncid, varidpS, start^, fs);

       Val0t:=ft[0];
       Val0s:=fs[0];

      if (val0t<>missingt[0]) and (val0t<>-9999) and
         (val0s<>missings[0]) and (val0s<>-9999) then begin

           val1t:=scalet[0]*val0t+offsett[0]; // scale and offset from nc file
           val1s:=scales[0]*val0s+offsets[0]; // scale and offset from nc file

           Depth_to_Pressure(ncLev_arr[ll_i], nclat_arr[lt_i], 0, p);
           p:=0;
           IEOS80(p,val1t,val1s,svan,dens);

              x:= (90-ncLat_arr[lt_i])*111.12*sin((ncLon_arr[ln_i])*Pi/180);
              y:=-(90-ncLat_arr[lt_i])*111.12*cos((ncLon_arr[ln_i])*Pi/180);

             writeln(f_dat, ncLat_arr[lt_i]:8:5, ncLon_arr[ln_i]:10:5, y:13:5, x:13:5, ncLev_arr[ll_i]:12:5, dens:10:5);
         end; //end of missing
        end; // end of region
       end; // Level
      end; // Longitude
     end; // Latitude

  FreeMemory(start);
  Closefile(f_dat);

 finally
  ft:=nil;
  fs:=nil;
   status:=nc_close(ncid);  // Close file
    if status>0 then showmessage(pansichar(nc_strerror(status)));
 end;
end;

end.

