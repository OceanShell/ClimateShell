unit ncaveraging;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, Classes, SysUtils, FileUtil, Forms, Controls, Graphics, IniFiles,
  Dialogs, StdCtrls, Spin, Buttons, ExtCtrls, Variants;

type

  { Tfrmncaveraging }

  Tfrmncaveraging = class(TForm)
    btnOpenFolder: TBitBtn;
    btnOpenScript: TBitBtn;
    btnPlot: TButton;
    btnSettings: TButton;
    btnUnloadData: TButton;
    cbClr1: TComboBox;
    cbLevel: TComboBox;
    cbLvl1: TComboBox;
    cbVariable1: TComboBox;
    chkAnomalies: TCheckBox;
    eAdditionalOffset1: TEdit;
    eAdditionalScale1: TEdit;
    eMaxLat: TEdit;
    eMaxLon: TEdit;
    eMinLat: TEdit;
    eMinLon: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    GroupBox6: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label9: TLabel;
    rgProjection: TRadioGroup;
    semm1: TSpinEdit;
    semm2: TSpinEdit;
    semm3: TSpinEdit;
    semm4: TSpinEdit;
    seyy1: TSpinEdit;
    seyy2: TSpinEdit;
    seyy3: TSpinEdit;
    seyy4: TSpinEdit;

    procedure btnOpenFolderClick(Sender: TObject);
    procedure btnOpenScriptClick(Sender: TObject);
    procedure btnPlotClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure btnUnloadDataClick(Sender: TObject);
    procedure cbVariable1Select(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure GetMeanField(mn1, yy1, mn2, yy2:integer);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmncaveraging: Tfrmncaveraging;
  f_dat, f_dat2, f_dat3:text;
  navdimsp:integer;
  ncAvgPath, avgfname:string;

implementation

{$R *.lfm}

uses ncmain, declarations_netcdf, surfer_settings, surfer_ncfields;

{ Tfrmncaveraging }



{   ws:=sqrt(u*u+v*v);
        if not eof(ufile) then write(out1, ws:5:1, ' ') else write(out1, ws:5:1);

       if (v>0)           then wd:=((180/pi)*arctan(u/v)+180);
       if (u<0) and (v<0) then wd:=((180/pi)*arctan(u/v)+0);
       if (u>0) and (v<0) then wd:=((180/pi)*arctan(u/v)+360);}



procedure Tfrmncaveraging.FormShow(Sender: TObject);
Var
  Ini:TIniFile;
begin
 cbVariable1.Items := frmmain.cbVariables.items;
 cbLevel.Items := frmmain.cbLevels.items;

 if not DirectoryExists(GlobalPath+'unload'+PathDelim+'averaging'+PathDelim) then
   CreateDir(GlobalPath+'unload'+PathDelim+'averaging'+PathDelim);

 ncAvgPath:=GlobalPath+'unload\averaging\'+ncname+'\';
 if not DirectoryExists(ncAvgPath) then CreateDir(ncAvgPath);
 if not DirectoryExists(ncAvgPath+'\png\') then CreateDir(ncAvgPath+'\png\');
 if not DirectoryExists(ncAvgPath+'\srf\') then CreateDir(ncAvgPath+'\srf\');

  seyy1.text:=copy(frmmain.cbDates.Items.Strings[0], 7, 4);
  seyy2.text:=copy(frmmain.cbDates.Items.Strings[frmmain.cbDates.Count-1], 7, 4);

  seyy3.text:=seyy1.Text;
  seyy4.text:=seyy2.Text;

 Ini := TIniFile.Create(IniFileName);
 try
  eMinLat.Text  := Ini.ReadString('ncaveraging', 'MinLat',   '-90');
  eMinLon.Text  := Ini.ReadString('ncaveraging', 'MinLon',  '-180');
  eMaxLat.Text  := Ini.ReadString('ncaveraging', 'MaxLat',    '90');
  eMaxLon.Text  := Ini.ReadString('ncaveraging', 'MaxLon',   '180');
 finally
   Ini.Free;
 end;
end;


procedure Tfrmncaveraging.btnUnloadDataClick(Sender: TObject);
Var
  mn_str1, mn_str2:string;
  Lat, lon, y, x, Value:real;
  Lat2, lon2, y2, x2, Value2:real;
begin
 if semm1.Value<10 then mn_str1:='0'+semm1.Text else mn_str1:=semm1.Text;
 if semm2.Value<10 then mn_str2:='0'+semm2.Text else mn_str2:=semm2.Text;

 avgfname:=mn_str1+'_'+mn_str2+'_'+seyy1.Text+'_'+seyy2.Text;

 GetMeanField(semm1.Value, seyy1.Value, semm2.Value, seyy2.Value);

 if chkAnomalies.Checked then begin
  avgfname:='mean';
  GetMeanField(semm3.Value, seyy3.Value, semm4.Value, seyy4.Value);

  avgfname:=mn_str1+'_'+mn_str2+'_'+seyy1.Text+'_'+seyy2.Text+'_anom';

  AssignFile(f_dat,  ncAvgPath+mn_str1+'_'+mn_str2+'_'+seyy1.Text+'_'+seyy2.Text+'.txt'); Reset(f_dat); readln(f_dat);
  AssignFile(f_dat2, ncAvgPath+'mean.txt'); Reset(f_dat2); readln(f_dat2);
  AssignFile(f_dat3, ncAvgPath+avgfname+'.txt'); Rewrite(f_dat3);
  writeln(f_dat3,  'Lat':15, 'Lon':15, 'y':15, 'x':15, 'Value':15);

  repeat
   readln(f_dat, Lat, lon, y, x, Value);
   readln(f_dat2, Lat2, lon2, y2, x2, Value2);
   writeln(f_dat3,  Lat:15:5, Lon:15:5, y:15:5, x:15:5, (Value-Value2):15:5);
  until eof(f_dat2) ;
  Closefile(f_dat);
  Closefile(f_dat2);
  Closefile(f_dat3);

 end;

 btnOpenFolder.Enabled:=true;
 btnOpenScript.Enabled:=true;
 btnPlot.Enabled:=true;
end;


procedure Tfrmncaveraging.GetMeanField(mn1, yy1, mn2, yy2:integer);
Var
  k, i:integer;
   lt_i, ln_i, tp, fl, tt, cnt, k_mn, a:integer;
   status, ncid, varidp, varidp2, ndimsp, varnattsp, dimid:integer;
   start: PArraySize_t;
    fp:array of single;
    sp:array of smallint;
    ip:array of integer;
    dp:array of double;
   vtype: nc_type;
   attname:    array of pAnsiChar;
   attlenp, lenp: size_t;
   scale, offset, missing: array [0..0] of single;
   val0, val_err:variant;
   val1, firstval1, sum, addscale, addoffset, minv, maxv, x, y:real;
   Lat1, Lon1:real;
   mn, yy:word;
   scale_ex, offset_ex, missing_ex: boolean;
 begin

   // assign output file
    AssignFile(f_dat,  ncAvgPath+avgfname+'.txt'); Rewrite(f_dat);
    writeln(f_dat,  'Lat':15, 'Lon':15, 'y':15, 'x':15, 'Value':15, 'Count':10);

    AssignFile(f_dat2, ncAvgPath+avgfname+'_min.txt'); Rewrite(f_dat2);
    writeln(f_dat2, 'Lat':15, 'Lon':15, 'y':15, 'x':15, 'Value':15, 'Count':10);

    AssignFile(f_dat3, ncAvgPath+avgfname+'_max.txt'); Rewrite(f_dat3);
    writeln(f_dat3, 'Lat':15, 'Lon':15, 'y':15, 'x':15, 'Value':15, 'Count':10);

    start:=GetMemory(SizeOf(TArraySize_t)*navdimsp); // get memory for start pointer

    addscale :=StrToFloat(eAdditionalScale1.Text);
    addoffset:=StrToFloat(eAdditionalOffset1.Text);

  for lt_i:=0 to high(ncLat_arr) do begin  // Latitude
   if navdimsp=2 then start^[0]:=lt_i;
   if navdimsp=3 then start^[1]:=lt_i;  //lat
   if navdimsp=4 then begin
       start^[1]:=cbLevel.ItemIndex;  //level
       start^[2]:=lt_i;  //lat
   end;
   lat1:=ncLat_arr[lt_i];

   for ln_i:=0 to high(ncLon_arr) do begin //Longitude
     if navdimsp=2 then start^[1]:=ln_i;
     if navdimsp=3 then start^[2]:=ln_i;
     if navdimsp=4 then start^[3]:=ln_i;
       lon1:=ncLon_arr[ln_i];

      if  (lat1>=StrToFloat(eMinLat.Text)) and
          (lat1<=StrToFloat(eMaxLat.Text)) and
          (lon1>=StrToFloat(eMinLon.Text)) and
          (lon1<=StrToFloat(eMaxLon.Text)) then begin

    try
   (* nc_open*)
    nc_open(pansichar(AnsiString(ncpath+ncname)), NC_NOWRITE, ncid); // only for reading

     nc_inq_varid    (ncid, pAnsiChar(AnsiString(cbVariable1.Text)), varidp); // variable ID
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
         if pAnsiChar(attname)='_FillValue' then begin
            nc_get_att_float(ncid, varidp, pansichar(pansichar(AnsiString('_FillValue'))), missing);
            missing_ex:=true;
         end;
      end;

      if scale_ex   = false then scale[0]:=1;
      if offset_ex  = false then offset[0]:=0;
      if missing_ex = false then missing[0]:=-9999;
     (*конец чтения коэффициентов *)

    sum:=0; cnt:=0;  minv:=9999; maxv:=-9999;
    for tt:=0 to frmmain.cbDates.Count-1 do begin
     mn:=StrToInt(copy(frmmain.cbDates.Items.Strings[tt], 4, 2));
     yy:=StrToInt(copy(frmmain.cbDates.Items.Strings[tt], 7, 4));

     if (mn>=mn1) and (mn<=mn2) and
        (yy>=yy1) and (yy<=yy2) then begin

   //    showmessage(frmmain.cbDates.Items.Strings[tt]);
        if ndimsp>2 then start^[0]:=tt; //time

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
          //  showmessage(vartostr(fp[0]));
           end;

           // NC_DOUBLE
           if VarToStr(vtype)='6' then begin
            SetLength(dp, 1);
             nc_get_var1_double(ncid, varidp, start^, dp);
            Val0:=dp[0];
           end;

         if (val0<>missing[0]) and (val0<>-9999) and (val0<>-1000) then begin
         //  showmessage(floattostr(val0)+'   '+floattostr(scale[0])+'   '+floattostr(offset[0]));
              val1:=scale[0]*val0+offset[0]; // scale and offset from nc file
              val1:=addscale*val1+AddOffset;  // additional conversion
              sum:=sum+val1;

            //  showmessage(floattostr(val1)+'   '+floattostr(sum));

              if val1<minv then minv:=val1;
              if val1>maxv then maxv:=val1;

              inc(cnt);
          end;
       end; //time loop
    end;  //if month



  finally
   fp:=nil;
    status:=nc_close(ncid);  // Close file
     if status>0 then showmessage(pansichar(nc_strerror(status)));
  end;

 { showmessage(floattostr(ncLat_arr[lt_i])+'   '+
              floattostr(ncLon_arr[ln_i])+'   '+
              floattostr(sum)+'   '+
              inttostr(cnt)+'   '+
              floattostr(sum/cnt));  }

    x:= (90-ncLat_arr[lt_i])*111.12*sin((ncLon_arr[ln_i])*Pi/180);
    y:=-(90-ncLat_arr[lt_i])*111.12*cos((ncLon_arr[ln_i])*Pi/180);

    if cnt>0 then begin
      writeln(f_dat,  ncLat_arr[lt_i]:15:5, ncLon_arr[ln_i]:15:5, y:15:5, x:15:5, (sum/cnt):15:5, cnt:10);
      writeln(f_dat2, ncLat_arr[lt_i]:15:5, ncLon_arr[ln_i]:15:5, y:15:5, x:15:5, (minv):15:5,    cnt:10);
      writeln(f_dat3, ncLat_arr[lt_i]:15:5, ncLon_arr[ln_i]:15:5, y:15:5, x:15:5, (maxv):15:5,    cnt:10);
    end;
    end; //region

  end; //Lon
 end; //Lat
 FreeMemory(start);

 Closefile(f_dat);
 Closefile(f_dat2);
 Closefile(f_dat3);
end;


procedure Tfrmncaveraging.btnOpenFolderClick(Sender: TObject);
begin
  OpenDocument(PChar(ncAvgPath));
end;

procedure Tfrmncaveraging.btnOpenScriptClick(Sender: TObject);
Var
Ini:TIniFile;
ScriptFile, Scripter:string;
begin
Ini := TIniFile.Create(IniFileName); // settings from file
  try
   scripter:=Ini.ReadString('main', 'SurferPath', '');
  finally
    Ini.Free;
  end;

 ScriptFile:=ExtractFilePath(ncAvgPath)+'Script.bas';
  if FileExists(ScriptFile) then OpenDocument(PChar('"'+Scripter+'" "'+ScriptFile+'"'));
end;

procedure Tfrmncaveraging.btnPlotClick(Sender: TObject);
Var
  k, i, stnum, ll, mn:integer;
  IniDat, src1, src2, lev1, lev2, clr1, clr2, buf_str, par, yrs, mns, lev, grd1:string;
  levstr_val, levstr_err:string;
  IndStr, DepStr, ncexportfile, ncTime, ncLvl, basemap2, period, stradd, mn_str_txt:string;
  avper, contour:string;
  XMin, XMax, YMin, YMax:real;
  polar_prj:boolean;
begin
src1:=ncAvgPath+avgfname+'.txt';
grd1:=ncAvgPath+avgfname+'.grd';

if (cbLvl1.ItemIndex>-1) then Lev1:=GlobalPath+'support\lvl\'+cbLvl1.Text else Lev1:='';
if (cbclr1.ItemIndex>-1) then clr1:=GlobalPath+'support\clr\'+cbclr1.Text else clr1:='';

XMin:=StrToFloat(eMinLon.Text);
XMax:=StrToFloat(eMaxLon.Text);
YMin:=StrToFloat(eMinLat.Text);
YMax:=StrToFloat(eMaxLat.Text);

Contour:=lowercase(GlobalPath+'support\bln\World.bln');

ncexportfile:=avgfname;

//if cbLevel.enabled=true then ncexportfile:=ncexportfile+'_'+cbLevel.Text;

  GetncFieldScript(ncAvgPath, src1, '', '', grd1, '', '', lev1, clr1, contour, '',
                   high(ncLon_arr)+1, high(ncLat_arr)+1, true,
                   XMin, XMax, YMin, YMax, ncexportfile, false,
                   rgProjection.ItemIndex, '', false, curve);

   {$IFDEF Windows}
     frmmain.RunScript(2, '"'+ncAvgPath+'script.bas"', nil);
   {$ENDIF}
end;


procedure Tfrmncaveraging.btnSettingsClick(Sender: TObject);
begin
  btnOpenFolder.Enabled:=false;
  btnOpenScript.Enabled:=false;

   frmSurferSettings := TfrmSurferSettings.Create(Self);
   frmSurferSettings.LoadSettings('ncfields');
    try
     if not frmSurferSettings.ShowModal = mrOk then exit;
    finally
      frmSurferSettings.Free;
      frmSurferSettings := nil;
    end;
end;



procedure Tfrmncaveraging.cbVariable1Select(Sender: TObject);
Var
  ncid, varidp:integer;
begin
  try
   nc_open(pansichar(AnsiString(ncpath+ncname)), NC_NOWRITE, ncid); // only for reading
   nc_inq_varid    (ncid, pAnsiChar(AnsiString(cbVariable1.Text)), varidp); // variable ID
   nc_inq_varndims (ncid, varidp, navdimsp);
  finally
    nc_close(ncid);  // Close file
  end;
end;

procedure Tfrmncaveraging.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
  Var
  Ini:TIniFile;
begin
 Ini := TIniFile.Create(IniFileName);
 try
  Ini.WriteString('ncaveraging', 'MinLat',  eMinLat.Text);
  Ini.WriteString('ncaveraging', 'MinLon',  eMinLon.Text);
  Ini.WriteString('ncaveraging', 'MaxLat',  eMaxLat.Text);
  Ini.WriteString('ncaveraging', 'MaxLon',  eMaxLon.Text);
 finally
   Ini.Free;
 end;
end;

end.

