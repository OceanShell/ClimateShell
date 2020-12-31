unit nctimeseries;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Math, Spin, DateUtils, BufDataset, Buttons, ComCtrls, ExtCtrls,
  CheckLst, LazFileUtils, IniFiles;

type

  { Tfrmtimeseries }

  Tfrmtimeseries = class(TForm)
    btnAnomalies: TButton;
    btnExportAsMatrix: TButton;
    btnPlot: TButton;
    btnOpenFolder: TBitBtn;
    btnSeasonalCircleRemoval: TButton;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    cbLat: TComboBox;
    cbLevel1: TComboBox;
    cbLevel2: TComboBox;
    cbLon: TComboBox;
    cbSeaBorders: TComboBox;
    cbVariable: TComboBox;
    chklSelLev: TCheckListBox;
    ePointLat: TEdit;
    ePointLon: TEdit;
    ePointRad: TEdit;
    gbAddConv: TGroupBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    PageControl1: TPageControl;
    pgMain: TPageControl;
    pgMain1: TPageControl;
    rgOver: TRadioGroup;
    seLatMax: TFloatSpinEdit;
    eAdditionalScale: TFloatSpinEdit;
    eAdditionalOffset: TFloatSpinEdit;
    seLonMax: TFloatSpinEdit;
    seLatMin: TFloatSpinEdit;
    seLonMin: TFloatSpinEdit;
    seMnMax: TSpinEdit;
    seMnMin: TSpinEdit;
    sePrecision: TSpinEdit;
    seYYMax: TSpinEdit;
    seYYmin: TSpinEdit;
    TabSheet1: TTabSheet;
    TabSheet10: TTabSheet;
    TabSheet11: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheet5: TTabSheet;
    TabSheet6: TTabSheet;
    TabSheet7: TTabSheet;
    TabSheet8: TTabSheet;
    TabSheet9: TTabSheet;

    procedure FormShow(Sender: TObject);
    procedure btnExportAsMatrixClick(Sender: TObject);
    procedure btnOpenScriptClick(Sender: TObject);
    procedure btnPlotClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure cbVariableSelect(Sender: TObject);
    procedure btnAnomaliesClick(Sender: TObject);
    procedure btnOpenFolderClick(Sender: TObject);
    procedure btnSeasonalCircleRemovalClick(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);

  private
    { Private declarations }
    procedure GetValues(fname:string; Var par_st, units:string);
  public
    { Public declarations }
  end;

var
  frmtimeseries: Tfrmtimeseries;
  fin, fout1, fout2, fout3, fout4, fout5, fout6, fout7, fout8, fout9, fout10, fout11, fout12:text;
  tsncUnload, tsfilename:string;
  tsYYMin, tsYYMax:integer;
  coordonetime:boolean=false;

  Num_point_BLN:array[1..1] of integer;
  Coord_BLN:array[1..2,1..200] of real;
  Long_min_BLN,Lat_min_BLN, lat_p, lon_p:real;

  ncTimeSeriesAuto:boolean=false;

implementation

{$R *.lfm}

uses ncmain, declarations_netcdf, ncprocedures, Bathymetry, scriptgrapher,
     surfer_settings;


Function Point_Status(Long_p,Lat_p:real):byte;
Label
  Lab_1;
Const
  {Задание сдвига базовой точки от минимальных значений координат в BLN-файле}
  Shift=0.123456789;
var
  Long_Point,Long_Base,Lat_Point,Lat_Base:real;
  K_Base,B_Base,K_BLN,B_BLN:real;
  Current_Max_Long,Current_Min_Long,Current_Max_Lat,Current_Min_Lat:real;
  ci4,ci3,First_Point,Num_Transsect:integer;

Function Verify:Boolean;
begin
  {Проверка на принадлежность точки пересечения !!!!отрезку!!! базовой прямой}
  Verify:=False;

  if ((Long_point>Long_Base) and (Lat_point>Lat_Base)
    and (Long_point<=Long_p) and (Lat_point<=Lat_p)) then
  begin
    Current_Min_Long:=Coord_BLN[1,ci4];
    Current_Max_Long:=Coord_BLN[1,ci4+1];
    Current_Min_Lat:=Coord_BLN[2,ci4];
    Current_Max_Lat:=Coord_BLN[2,ci4+1];
    if Current_Max_Long<Current_Min_Long then
    begin
      Current_Max_Long:=Coord_BLN[1,ci4];
      Current_Min_Long:=Coord_BLN[1,ci4+1];
    end;
    if Current_Max_Lat<Current_Min_Lat then
    begin
      Current_Max_Lat:=Coord_BLN[2,ci4];
      Current_Min_Lat:=Coord_BLN[2,ci4+1];
    end;

    {Не забыть о равенстве значений на границе}
    if (Long_point>=Current_Min_Long) and (Lat_point>=Current_Min_Lat)
      and (Long_point<=Current_Max_Long) and (Lat_point<=Current_Max_Lat) then
      begin
      Verify:=True
     end;
  end;
end;

begin
  {Определение координат узловой точки отсчета}
Lab_1:

  Long_Base:=Long_min_BLN-Shift*random;
  Lat_base:=Lat_min_BLN-Shift*random;

  {Определение коээфициентов уравнения прямой от базовой точки до исследуемой.
  Уравнение прямой в виде y=kx+b}

  K_Base:=(Lat_p-Lat_base)/(Long_p-Long_base);

  B_Base:=Lat_p-K_Base*Long_p;
  {Если в контуре всего один объект}
  First_Point:=1;
  ci3:=1;

  Num_Transsect:=0;
  for ci4:=First_Point to First_Point+Num_point_BLN[ci3]-2 do
  begin
    if Coord_BLN[1,ci4]<>Coord_BLN[1,ci4+1] then
    begin
      K_BLN:=(Coord_BLN[2,ci4+1]-Coord_BLN[2,ci4])/
       (Coord_BLN[1,ci4+1]-Coord_BLN[1,ci4]);
      B_BLN:=Coord_BLN[2,ci4]-Coord_BLN[1,ci4]*K_BLN;

      if K_BLN=K_Base then
      begin
       goto Lab_1
      end
      else
      begin
        Long_point:=(B_BLN-B_Base)/(K_Base-K_BLN);
        Lat_Point:=K_BLN*Long_point+B_BLN;
      end;

    end
    else
    begin
      Long_Point:=Coord_BLN[1,ci4];
      Lat_Point:=K_Base*Long_point+B_Base;
    end;

    if Verify then
    begin
      Inc(Num_Transsect);
    end;
  end;
  Point_Status:=Num_Transsect;
end;



procedure Tfrmtimeseries.FormShow(Sender: TObject);
Var
  k:integer;
  LatMin, LatMax, LonMin, LonMax, depth: real;
  fdb:TSearchRec;
  fname:string;
begin
 if not DirectoryExists(GlobalUnloadPath+'timeseries'+PathDelim) then
    CreateDir(GlobalUnloadPath+'timeseries'+PathDelim);

// frmtimeseries.Height:=300;

 cbVariable.Items  := frmmain.cbVariables.items; // copy variable names
 cbLevel1.Items    := frmmain.cbLevels.items;    // levels
 cbLevel2.Items    := frmmain.cbLevels.items;    // levels
 cbLat.Items       := frmmain.cbLat.items;       // latitude
 cbLon.Items       := frmmain.cbLon.items;       // longitude


 chklSelLev.Items  := frmmain.cbLevels.items;
 for k:=0 to chklSelLev.Count-1 do chklSelLev.Checked[k]:=true;

 // enable/disable levels - for 3D and 4D netCDF
 if cbLevel1.Items.Count=0 then cbLevel1.Enabled:=false;

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
 seLonMin.Value:=LonMin;
 seLonMax.Value:=LonMax;
 seLatMin.Value:=LatMin;
 seLatMax.Value:=LatMax;


 // min and max years
 tsYYMin:= 9999;
 tsYYMax:=-9999;

  (* list of arbitraty regions *)
   fdb.Name:='';
   cbSeaBorders.Clear;
     FindFirst(GlobalSupportPath+'sea_borders'+PathDelim+'*.bln',faAnyFile, fdb);
     if fdb.Name<>'' then begin
      cbSeaBorders.Items.Add(ExtractFileNameWithoutExt(fdb.Name));
       while findnext(fdb)=0 do cbSeaBorders.Items.Add(ExtractFileNameWithoutExt(fdb.Name));
     end;
    FindClose(fdb);

 depth:=GetBathymetry(2, 66);
 if depth=-999 then begin
  rgOver.ItemIndex:=2;
  rgOver.Enabled:=false;
 end;

 PageControl1.OnChange(self);
  gbAddConv.Enabled:=true;
  rgOver.Visible:=true;
  cbVariable.Enabled:=true;
end;


(* getting data from netcdf *)
procedure Tfrmtimeseries.btnPlotClick(Sender: TObject);
Var
  kf, cnt:integer;
  lat, lon:real;
  ltmin, ltmax, lnmin, lnmax:real;
  ci1:integer;
  st, par_st, units:string;
begin
  // exit if variable isn't selected
 if (cbVariable.Enabled=true) and (cbVariable.ItemIndex=-1) then
  if messagedlg('Please, select variable', mtwarning, [mbOk], 0)=mrOk then exit;
  // exit if level isn't selected
 if (cbLevel1.Enabled=true) and (cbLevel1.ItemIndex=-1) then
  if messagedlg('Please, select level', mtwarning, [mbOk], 0)=mrOk then exit;
 // exit if sea border file isn't selected
 if (pgMain.PageIndex=2) and (cbSeaBorders.ItemIndex=-1) then
  if messagedlg('Please, select sea borders file', mtwarning, [mbOk], 0)=mrOk then exit;
  // exit if coordinates of a node aren't selected
 if (pgMain.PageIndex=3) and ((cbLat.ItemIndex=-1) or (cbLon.ItemIndex=-1)) then
  if messagedlg('Please, select both latitude and longitude', mtwarning, [mbOk], 0)=mrOk then exit;

 btnPlot.Enabled:=false;

// showmessage('1');

 // predefined area
 if pgMain.PageIndex=2 then begin
  AssignFile(fin, GlobalSupportPath+'sea_borders'+PathDelim+cbSeaBorders.Text+'.bln'); reset(fin);
  readln(fin, st);

   ci1:=1;
   Ltmin:=-90;
   Ltmax:=ltmin;
   lnmin:=180;
   lnmax:=lnmin;

  repeat
   readln(fin, st);

 //  showmessage(st);

   lon:=StrToFloat(trim(copy(st, 1, pos(',', st)-1)));
   lat:=StrToFloat(trim(copy(st, pos(',', st)+1, length(st))));

      Coord_BLN[1,ci1]:=lon;
      Coord_BLN[2,ci1]:=lat;

      if Coord_BLN[1,ci1]<lnmin then
        lnmin:=Coord_BLN[1,ci1];
      if Coord_BLN[1,ci1]>lnmax then
        lnmax:=Coord_BLN[1,ci1];
      if Coord_BLN[2,ci1]<ltmin then
        ltmin:=Coord_BLN[2,ci1];
      if Coord_BLN[2,ci1]>ltmax then
        ltmax:=Coord_BLN[2,ci1];
      inc(ci1);
  until eof(fin);
  CloseFile(fin);

    Coord_BLN[1,ci1]:=Coord_BLN[1,1];
    Coord_BLN[2,ci1]:=Coord_BLN[2,1];
    Num_point_BLN[1]:=ci1;

    Long_min_BLN:=lnmin;
    Lat_min_bln:=ltmin;
end;

 //showmessage('2');

 if cbLevel1.Enabled=true then
   tsfilename:= tsncUnload+cbVariable.Text+'_'+cbLevel1.text+'.txt' else
   tsfilename:= tsncUnload+cbVariable.Text+'.txt';

// showmessage(tsfilename);

  try
   AssignFile(fout1, tsfilename);
   AssignFile(fout3, tsncUnload+'area_coordinates.dat'); rewrite(fout3);

   Rewrite(fout1);
   writeln(fout1, 'Date_dec':20, 'Date':25, 'YY':5, 'MN':5, 'DD':5, 'HH':5, 'MM':5, 'SS':5, 'Value':15);

 //  showmessage('ok');
  try
   frmmain.panel1.Visible:=false;
    for kf:=0 to frmmain.cbFiles.Count-1 do begin
     frmmain.cbFiles.ItemIndex:=kf;
   //   showmessage('here 2');
     frmmain.cbFiles.OnClick(self);
   //  showmessage('here 3');
        GetValues(ncpath+ncname, par_st, units);
       // showmessage('here 4');
      coordonetime:=true;
    end;
  finally
   frmmain.panel1.Visible:=true;
  end;
 //   showmessage('ok2');


   seYYMin.Value:=tsYYMin;
   seYYMax.Value:=tsYYMax;

   seYYMin.MinValue:=seYYMin.Value;  // set years range for year begin
   seYYMin.MaxValue:=seYYMax.Value;

   seYYMax.MinValue:=seYYMin.Value; // set years range for year end
   seYYMax.MaxValue:=seYYMax.Value;

  finally
   CloseFile(fout1);
   CloseFile(fout3);
   btnPlot.Enabled:=true;
   coordonetime:=false;
  end;

   AssignFile(fout1, tsfilename); reset(fout1);
   cnt:=0;
   repeat
    readln(fout1);
    inc(cnt);
   until eof(fout1) or (cnt>3);
   CloseFile(fout1);

   if cnt<=2 then begin
    if ncTimeseriesAuto=true then begin
      DeleteFile(tsfilename);
      ncTimeseriesAuto:=false;
    end;
    if ncTimeseriesAuto=false then
      if MessageDlg(SUnloadedFileEmpty, mtwarning, [mbOk], 0)=mrOk then exit;
   end;


 if ncTimeseriesAuto=false then begin
  PlotTimeSeries(tsfilename, '', par_st, units, 'Years', 9);
   {$IFDEF WINDOWS}
     frmmain.RunScript(3, '-x "'+ExtractFilePath(tsfilename)+'script.bas"', nil);
   {$ENDIF}
 end;
end;


(* Averaged data from each specified file *)
procedure Tfrmtimeseries.GetValues(fname: string; Var par_st, units:string);
Var
  status, ncid, varidp, varidp2, ndimsp, varnattsp:integer;
  tt, lt_i, ln_i, tp, a:integer;
  AddScale, AddOffset:real;
  scale, offset, missing: array [0..0] of single;
  scale_ex, offset_ex, missing_ex: boolean;
  atttext: array of pchar;
  attlenp, lenp:size_t;
  vtype :nc_type;
   fp:array of single;
   sp:array of smallint;
   ip:array of integer;
   dp:array of double;

  attname:    array of pAnsiChar;
  start: PArraySize_t;
  LatMin, LatMax, LonMin, LonMax, Lat0, Lon0, Rad, Dist: real;
  val0, val1, valr, yy1, Int_val, Val_err, date1:real;
  sum_pi, area_mean, depth:real;
  yy, mn, dd, hh, mm, ss, ms:word;

  clr_str: string;
  date_str, mn_str, dd_str:string;
begin

 //   showmessage('before1');

 LonMin:= seLonMin.Value;
 LonMax:= seLonMax.Value;
 LatMin:= seLatMin.Value;
 LatMax:= seLatMax.Value;


 Lat0:=strtofloat(ePointLat.Text);
 Lon0:=strtofloat(ePointLon.Text);
 Rad :=strtofloat(ePointRad.Text);

try
 (* nc_open*)
   status:=nc_open(pchar(fname), NC_NOWRITE, ncid); // only for reading
    if status>0 then showmessage(pchar(nc_strerror(status)));

   //    showmessage('before3');

   nc_inq_varid (ncid, pChar(cbVariable.Text), varidp); // variable ID
   nc_inq_vartype  (ncid, varidp, vtype);
   nc_inq_varndims (ncid, varidp, ndimsp);


   //showmessage('before');

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
      if pAnsiChar(attname)='long_name' then begin
         nc_inq_attlen (ncid, timeVid, pAnsiChar('long_name'), attlenp);
         setlength(atttext, 0);
         setlength(atttext, attlenp);
          nc_get_att_text(ncid, varidp, pansichar(pansichar(AnsiString('long_name'))), atttext);
         if pAnsiChar(atttext)<>'' then par_st:=pAnsiChar(atttext) else par_st:='';
      end;
      if pAnsiChar(attname)='units' then begin
         nc_inq_attlen (ncid, timeVid, pAnsiChar('units'), attlenp);
         setlength(atttext, 0);
         setlength(atttext, attlenp);
          nc_get_att_text(ncid, varidp, pansichar(pansichar(AnsiString('units'))), atttext);
         if pAnsiChar(atttext)<>'' then units:=pAnsiChar(atttext) else units:='';
      end;
    end;

 //   showmessage('after');

   if scale_ex   = false then scale[0]:=1;
   if offset_ex  = false then offset[0]:=0;
   if missing_ex = false then missing[0]:=-9999;


    // additional user defined conversion - if needed
   if eAdditionalScale.Text<>''  then AddScale := StrToFloat(eAdditionalScale.Text)  else AddScale:=1;
   if eAdditionalOffset.Text<>'' then AddOffset:= StrToFloat(eAdditionalOffset.Text) else AddOffset:=0;

   start:=GetMemory(SizeOf(TArraySize_t)*ndimsp); // get memory for start pointer

 //  showmessage('ok7');

   for tt:=0 to high(ncTime_arr) do begin
  //   showmessage(frmmain.cbDates.Items.Strings[tt]);

     DecodeDateTime(StrToDateTime(frmmain.cbDates.Items.Strings[tt]), yy, mn, dd, hh, mm, ss, ms);

  //  showmessage('ok8');

    date1:=yy+((mn-1)/12)+((dd-1)/(daysinayear(yy)))+((hh)/(24*12*daysinayear(yy)))+
               ((mm)/(24*12*60*daysinayear(yy)))+((ss)/(24*12*3600*daysinayear(yy)));

     tsYYMin:=min(yy, tsYYMin); // min year
     tsYYMax:=max(yy, tsYYMax); // max year

 //    showmessage('here');

    (* for a single node *)
    if pgMain.PageIndex=3 then begin
      if ndimsp=2 then begin
       start^[0]:=cbLat.ItemIndex;  //lat
       start^[1]:=cbLon.ItemIndex;  //lon
      end;
      if ndimsp=3 then begin
       start^[0]:=tt;    //time
       start^[1]:=cbLat.ItemIndex;  //lat
       start^[2]:=cbLon.ItemIndex;  //lon
      end;
      if ndimsp=4 then begin
       start^[0]:=tt;    //time
       start^[1]:=cbLevel1.ItemIndex; //level
       start^[2]:=cbLat.ItemIndex;   //lat
       start^[3]:=cbLon.ItemIndex;   //lon
      end;
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
        //   showmessage(floattostr(val0));
          end;

          // NC_DOUBLE
          if VarToStr(vtype)='6' then begin
           SetLength(dp, 1);
            nc_get_var1_double(ncid, varidp, start^, dp);
           Val0:=dp[0];
          end;

       //   showmessage(floattostr(val0));
       if (Val0<>missing[0]) and
         (((rgOver.ItemIndex=0) and (depth>0)) or  //water
          ((rgOver.ItemIndex=1) and (depth<=0)) or //land
           (rgOver.ItemIndex=2)) then begin //both

          //  showmessage(floattostr(val0)+'   '+floattostr(scale[0]));
            val1:=scale[0]*Val0+offset[0]; // scale and offset from netcdf
            val1:=addscale*val1+AddOffset;  // user defined conversion
           // showmessage(floattostr(val1));

          writeln(fout1, date1:20:15, StrToDateTime(frmmain.cbDates.Items.Strings[tt]):25,
          yy:5, mn:5, dd:5, hh:5, mm:5, ss:5, Val1:15:sePrecision.Value);
        end;
    end;


    (* Area averaging *)
   if  pgMain.PageIndex<3 then begin // not for a single node
 //   showmessage('here1');
    Int_val:=0; sum_pi:=0; area_mean:=0;
    start^[0]:=tt;  //time
    for lt_i:=0 to high(ncLat_arr) do begin
      if ndimsp=3 then start^[1]:=lt_i;  //lat
      if ndimsp=4 then begin
       start^[1]:=cbLevel1.ItemIndex; //level
       start^[2]:=lt_i;  //lat
      end;

    ////  showmessage('here2');

     for ln_i:=0 to high(ncLon_arr) do begin
       if ndimsp=3 then start^[2]:=ln_i;  //longitude
       if ndimsp=4 then start^[3]:=ln_i;

       Distance(Lon0, ncLon_arr[ln_i], Lat0, ncLat_arr[lt_i], Dist);

   //    showmessage('here3');

        // get area mean
       if ((pgMain.PageIndex=0) and (ncLat_arr[lt_i]>=LatMin) and (ncLat_arr[lt_i]<=LatMax) and
            (((LonMin<=LonMax) and (ncLon_arr[ln_i]>=LonMin) and (ncLon_arr[ln_i]<=LonMax)) or
             ((LonMin> LonMax) and
              (((ncLon_arr[ln_i]>=LonMin) and (ncLon_arr[ln_i]<=180)) or
               ((ncLon_arr[ln_i]>=-180)   and (ncLon_arr[ln_i]<=LonMax))))))

           or ((pgMain.PageIndex=1) and (Dist<=Rad))

           or ((pgMain.PageIndex=2) and (Odd(Point_Status(ncLon_arr[ln_i],ncLat_arr[lt_i]))=true)) then begin

     //       showmessage('here4');

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
          end;

          // NC_DOUBLE
          if VarToStr(vtype)='6' then begin
           SetLength(dp, 1);
            nc_get_var1_double(ncid, varidp, start^, dp);
           Val0:=dp[0];
          end;

            depth:=-999;

       //     showmessage('here5');
            depth:=GetBathymetry(ncLon_arr[ln_i], ncLat_arr[lt_i]);
         //   showmessage('here6');

             if (Val0<>missing[0]) and (Val0<>-999) and
                (((rgOver.ItemIndex=0) and (depth>0)) or
                 ((rgOver.ItemIndex=1) and (depth<=0)) or
                  (rgOver.ItemIndex=2)) then begin  // if value is not missing

                 if (tt=0) and (coordonetime=false) then
                   writeln(fout3, floattostr(ncLat_arr[lt_i])+','+floattostr(ncLon_arr[ln_i]));

                  val1:=scale[0]*Val0+offset[0]; // scale and offset from netcdf
                  val1:=addscale*val1+AddOffset;  // user defined conversion

          //       showmessage(floattostr(nclat_arr[lt_i])+'   '+floattostr(nclon_arr[ln_i])+'   '+floattostr(val0)+'   '+floattostr(val1));

                  Int_val:=Int_val+Val1*cos(Pi*ncLat_arr[lt_i]/180);
                  Sum_pi:=Sum_pi+cos(Pi*ncLat_arr[lt_i]/180);
           end; // end of missing value loop

       end; // end same year
     end; // end of lon loop
    end; // end of lat loop
     if Sum_pi<>0 then begin
      Area_Mean:=Int_val/Sum_pi;
    //  2014-09-17T15:30:00

      if mn<10 then mn_str:='0'+inttostr(mn) else mn_str:=inttostr(mn);
      if dd<10 then dd_str:='0'+inttostr(dd) else dd_str:=inttostr(dd);

      date_str:=inttostr(yy)+'-'+mn_str+'-'+dd_str; {+'T00:00:00';}
      if area_mean<0 then clr_str:='blue' else clr_str:='red';
       writeln(fout1, date1:20:15, date_str:25,
          yy:5, mn:5, dd:5, hh:5, mm:5, ss:5, Area_mean:15:sePrecision.Value, clr_str:10);
     end;
      Int_val:=0; sum_pi:=0; area_mean:=0;  // clear variables
     end;
   end; // end of time loop
 finally
  status:=nc_close(ncid);  // Close file
   if status>0 then showmessage(pansichar(nc_strerror(status)));
  FreeMemory(start);
 end;
end;


procedure Tfrmtimeseries.btnOpenFolderClick(Sender: TObject);
begin
  OpenDocument(PChar(tsncUnload));
end;

procedure Tfrmtimeseries.btnOpenScriptClick(Sender: TObject);
Var
ScriptFile, Scripter:string;
Ini:TIniFile;
begin
 Ini := TIniFile.Create(IniFileName); // settings from file
  try
   scripter:=Ini.ReadString('main', 'SurferPath', '');
  finally
    Ini.Free;
  end;
 ScriptFile:=tsncUnload+'Script.bas';
 SysUtils.ExecuteProcess('"'+Scripter+'" "scripter.bas"', '', []);
end;


(* Averaging *)
procedure Tfrmtimeseries.btnAnomaliesClick(Sender: TObject);
Var
  FileData, FileAnom, clr1:string;
  MnMin, MnMax:integer;
  yy, mn, dd, hh, mm, ss, ms:real;
  globcnt, c, cnt:integer;

  yy1, val1, globmean, date1:real;
  yy_old:integer;
  Int_val, Mean:real;
begin
 MnMin := seMnMin.Value;
 MnMax := seMnMax.Value;

 if pgMain.PageIndex=0 then tsncUnload:=GlobalUnloadPath+'timeseries'+PathDelim+'area_averaging'+PathDelim;
 if pgMain.PageIndex=1 then tsncUnload:=GlobalUnloadPath+'timeseries'+PathDelim+'around_fixed_point'+PathDelim;
 if pgMain.PageIndex=2 then tsncUnload:=GlobalUnloadPath+'timeseries'+PathDelim+'predefined_area'+PathDelim;
 if pgMain.PageIndex=3 then tsncUnload:=GlobalUnloadPath+'timeseries'+PathDelim+'single_node'+PathDelim;

 try
 AssignFile(fout1, tsfilename); Reset(fout1); // file with values

 FileData:=tsncUnload+cbVariable.Text+'_'+seMnMin.Text+'_'+seMnMax.Text+'_data_yearly.txt';
 FileAnom:=tsncUnload+cbVariable.Text+'_'+seMnMin.Text+'_'+seMnMax.Text+'_anom_yearly.txt';

  AssignFile(fout2, FileData); Rewrite(fout2); // file for anomalies
  writeln(fout2, 'Year':5, 'Value':15); //write header
  readln(fout1);

   Int_val:=0; cnt:=0; mean:=0;
   globmean:=0; globcnt:=0; c:=0;
   repeat
    readln(fout1, date1, yy, mn, dd, hh, mm, ss, val1);
     if c=0 then begin
      yy_old:=round(yy);
      inc(c);
     end;

     if ((MnMin<=MnMax) and (yy>yy_old)) or
        ((MnMin>MnMax) and ((yy=yy_old+1) and (mn>mnMax))) or
        (eof(fout1)) then begin
      if cnt<>0 then begin
         Mean:=Int_val/cnt;

          writeln(fout2, yy_old:5, mean:15:3); // write mean value for year
           // mean value for anomalies
           if (yy_old>=seYYMin.Value) and (yy_old<=seYYMax.Value) then begin
            globmean:=globmean+Mean;
            inc(globcnt);
           end; // eof mean value for anomalies
        end;
        Int_val:=0; cnt:=0; mean:=0; yy_old:=round(yy); // clear variables
        if eof(fout1) then break;
       end; // end of yearly mean

        if ((MnMin<=MnMax) and (yy=yy_old) and (mn>=MnMin) and (mn<=MnMax)) or
           ((MnMin> MnMax) and ((yy=yy_old) and (mn>=MnMin)) or ((yy=yy_old+1) and (mn<=MnMax))) then begin
           Int_val:=Int_val+Val1;
          inc(cnt);
        end;

   until eof(fout1);
 finally
  CloseFile(fout1);   // close files;
  CloseFile(fout2);
 end;


 try
 AssignFile(fout1, FileData); Reset(fout1); // file for anomalies
 AssignFile(fout2, FileAnom); Rewrite(fout2); // file for anomalies
  writeln(fout2, 'Year':5, 'Value':15, 'Colour':10); //write header
   readln(fout1);
   repeat
    readln(fout1, yy1, val1);
     if (val1-(globmean/globcnt))>=0 then clr1:='red' else clr1:='blue';
    writeln(fout2, yy1:5:0, (val1-(globmean/globcnt)):15:3, clr1:10); // write anomalies
   until eof(fout1);
 finally
   CloseFile(fout1);   // close files;
   CloseFile(fout2);
 end;

 OpenDocument(PChar(tsncunload)); { *Converted from ShellExecute* }
end;



(* removing seasonal circle *)
procedure Tfrmtimeseries.btnSeasonalCircleRemovalClick(Sender: TObject);
Var
  FileData, FileAnom:string;
  MnMin, MnMax, i:integer;
  yy, mn, dd, hh, mm, ss, ms, date_dec:real;
  globcnt, c, cnt:integer;

  yy1, val1, globmean:real;
  yy_old:integer;
  Int_val, Mean, date1:real;
  mean_arr:array[1..12] of real;
begin
 case pgMain.PageIndex of
   0: tsncUnload:=GlobalUnloadPath+'timeseries'+PathDelim+'area_averaging'+PathDelim;
   1: tsncUnload:=GlobalUnloadPath+'timeseries'+PathDelim+'around_fixed_point'+PathDelim;
   2: tsncUnload:=GlobalUnloadPath+'timeseries'+PathDelim+'predefined_area'+PathDelim;
   3: tsncUnload:=GlobalUnloadPath+'timeseries'+PathDelim+'single_node'+PathDelim;
 end;

 // showmessage(tsfilename);

 for i:=1 to 12 do begin
  cnt:=0; int_val:=0;
  try
   AssignFile(fout1, tsfilename); Reset(fout1); // file with values
   readln(fout1);
   repeat
    readln(fout1, date_dec, date1, yy, mn, dd, hh, mm, ss, val1);
     if mn=i then begin
      Int_val:=Int_val+Val1;
      inc(cnt);
     end;
     if cnt<>0 then mean_arr[i]:=Int_val/cnt;
   until eof(fout1);
  finally
   CloseFile(fout1);   // close files;
  end;
 end;

  try
   FileAnom:=tsncUnload+cbVariable.Text+'_'+seMnMin.Text+'_'+seMnMax.Text+'_anom_monthly.txt';
   AssignFile(fout2, FileAnom); Rewrite(fout2); // file for anomalies
   writeln(fout2, 'YY':5, 'MN':5, 'Date':15, 'Value':15); //write header

   AssignFile(fout1, tsfilename); Reset(fout1); // file with values
   readln(fout1);
   repeat
    readln(fout1, date_dec, date1, yy, mn, dd, hh, mm, ss, val1);
     writeln(fout2, yy:5:0, mn:5:0, (yy+(mn-1)/12):15:5, (val1-mean_arr[trunc(mn)]):15:3); // write anomalies
   until eof(fout1);
  finally
   CloseFile(fout1);   // close files;
   CloseFile(fout2);
  end;

 OpenDocument(PChar(tsncunload));
end;



procedure Tfrmtimeseries.PageControl1Change(Sender: TObject);
begin
   // define and create output directory
 if pgMain.PageIndex=0 then tsncUnload:=GlobalUnloadPath+'timeseries'+PathDelim+'area_averaging'+PathDelim;
 if pgMain.PageIndex=1 then tsncUnload:=GlobalUnloadPath+'timeseries'+PathDelim+'around_fixed_point'+PathDelim;
 if pgMain.PageIndex=2 then tsncUnload:=GlobalUnloadPath+'timeseries'+PathDelim+'predefined_area'+PathDelim;
 if pgMain.PageIndex=3 then tsncUnload:=GlobalUnloadPath+'timeseries'+PathDelim+'single_node'+PathDelim;
 if not DirectoryExists(tsncUnload) then CreateDir(tsncUnload);
end;


procedure Tfrmtimeseries.cbVariableSelect(Sender: TObject);
begin
  // btnPlot=enabled if a variable is selected
  if cbVariable.ItemIndex<>-1 then btnPlot.Enabled:=true;
end;


(* monthly mean *)
procedure Tfrmtimeseries.Button1Click(Sender: TObject);
Var
FileData, FileAnom:string;
 MnMin, MnMax, i:integer;
 yy, mn, dd, hh, mm, ss, ms:real;
 globcnt, c, cnt:integer;

 yy1, val1, globmean:real;
 yy_old:integer;
 Int_val, Mean, date1:real;
 mean_arr:array[1..12] of real;
begin

  if pgMain.PageIndex=0 then tsncUnload:=GlobalUnloadPath+'timeseries'+PathDelim+'area_averaging'+PathDelim;
  if pgMain.PageIndex=1 then tsncUnload:=GlobalUnloadPath+'timeseries'+PathDelim+'around_fixed_point'+PathDelim;
  if pgMain.PageIndex=2 then tsncUnload:=GlobalUnloadPath+'timeseries'+PathDelim+'predefined_area'+PathDelim;
  if pgMain.PageIndex=3 then tsncUnload:=GlobalUnloadPath+'timeseries'+PathDelim+'single_node'+PathDelim;

for i:=1 to 12 do begin
 cnt:=0; int_val:=0;
 try
  AssignFile(fout1, tsfilename); Reset(fout1); // file with values
  readln(fout1);
  repeat
   readln(fout1, date1, yy, mn, dd, hh, mm, ss, val1);
    if mn=i then begin
     Int_val:=Int_val+Val1;
     inc(cnt);
    end;
    if cnt<>0 then mean_arr[i]:=Int_val/cnt;
  until eof(fout1);
 finally
  CloseFile(fout1);   // close files;
 end;
end;

 try
  FileAnom:=tsncUnload+cbVariable.Text+'_'+seMnMin.Text+'_'+seMnMax.Text+'_anom_monthly.txt';
  AssignFile(fout2, FileAnom); Rewrite(fout2); // file for anomalies
  writeln(fout2, 'Year':5, 'Month':5, 'Date':15, 'Value':15); //write header

  AssignFile(fout1, tsfilename); Reset(fout1); // file with values
  readln(fout1);
  repeat
   readln(fout1, yy, mn, dd, hh, val1);
    writeln(fout2, yy:5:0, mn:5:0, (yy+(mn-1)/12):15:5, (val1-mean_arr[trunc(mn)]):15:3); // write anomalies
  until eof(fout1);
 finally
  CloseFile(fout1);   // close files;
  CloseFile(fout2);
 end;

OpenDocument(PChar(tsncunload));
end;


procedure Tfrmtimeseries.Button3Click(Sender: TObject);
Var
k_f:integer;
begin
try
ncTimeseriesAuto:=true;
ClearDir(tsncUnload);
 for k_f:=0 to cbLevel1.Items.Count-1 do begin
   if chklSelLev.Checked[k_f]=true then begin
       cblevel1.ItemIndex:=k_f;
       Application.ProcessMessages;
      if ncTimeseriesAuto=true then btnPlot.OnClick(self) else break;
   end; //level;
 end;
finally
 ncTimeSeriesAuto:=false;
end;
end;


(* export as matrix *)
procedure Tfrmtimeseries.btnExportAsMatrixClick(Sender: TObject);
Var
 i, cnt, cnt_p:integer;
 date1, date2, yy, mn, dd, hh, mm, ss, val1, sum, valn, mn_old:real;
 f_in:string;
begin

if pgMain.PageIndex=0 then tsncUnload:=GlobalPath+'unload\timeseries\area_averaging\';
if pgMain.PageIndex=1 then tsncUnload:=GlobalPath+'unload\timeseries\around_fixed_point\';
if pgMain.PageIndex=2 then tsncUnload:=GlobalPath+'unload\timeseries\predefined_area\';
if pgMain.PageIndex=3 then tsncUnload:=GlobalPath+'unload\timeseries\single_node\';

frmmain.OD.Filter:='Text|*.txt';
frmmain.OD.InitialDir:=tsncUnload;
if frmmain.OD.Execute then f_in:=frmmain.OD.FileName else exit;

AssignFile(fout1, f_in); Reset(fout1); // file with values
readln(fout1);

AssignFile(fout2, tsncUnload+cbVariable.Text+'_matrix.txt'); Rewrite(fout2); // file with values
writeln(fout2, 'YY':5, 'JAN':10, 'FEB':10, 'MAR':10, 'APR':10,
                       'MAY':10, 'JUN':10, 'JUL':10, 'AUG':10,
                       'SEP':10, 'OCT':10, 'NOV':10, 'DEC':10, 'YEAR':10);


{Date   YY   MN   DD   HH   MM   SS          Value
1979.000028538810000 1979    1    1    3    0    0         43.190
1979.000142694060000 1979    1    1   15    0    0         43.067
1979.083361872150000 1979    2    1    3    0    0         38.599
1979.083476027400000 1979    2    1   15    0    0         38.701
1979.166695205480000 1979    3    1    3    0    0         42.606
1979.166809360730000 1979    3    1   15    0    0         42.652
1979.250028538810000 1979    4    1    3    0    0         47.261
1979.250142694060000 1979    4    1   15    0    0         47.273
1979.333361872150000 1979    5    1    3    0    0         57.812
1979.333476027400000 1979    5    1   15    0    0         58.084}

readln(fout1, date1, date2, yy, mn_old, dd, hh, mm, ss, valn);
cnt_p:=1;  sum:=0; cnt:=1;
 repeat
  readln(fout1, date1, date2, yy, mn, dd, hh, mm, ss, val1);

       if mn=mn_old then begin
         valn:=valn+val1;
         inc(cnt_p);
       end;

       if mn<>mn_old then begin
        if cnt=1 then write(fout2, yy:5:0);

         write(fout2, (valn/cnt_p):10:3);
         sum:=sum+(valn/cnt_p);
        inc(cnt);
        cnt_p:=1;
        valn:=val1;
        mn_old:=mn;
       end;

    if cnt=13 then begin
      write(fout2, (sum/12):10:3);
      writeln(fout2);
      cnt:=1;
      sum:=0;
    end;
  until eof(fout1);
 //end;

 write(fout2, (valn/cnt_p):10:3);
 if cnt=12 then begin
  sum:=sum+(valn/cnt_p);
  write(fout2, (sum/12):10:3);
 end;

{ repeat
   sum:=0; cnt:=0; mn_old:=0;
    for i:=1 to 12 do begin
     if not eof(fout1) then begin
      readln(fout1, date1, yy, mn, dd, hh, mm, ss, val1);

       if i=1 then write(fout2, yy:5:0);

       if mn=mn_old then begin
         val1:=val1+val_old;
         inc(cnt_p);
       end;
       write(fout2, val1:10:3);
        sum:=sum+Val1;
       inc(cnt);
       end; //not eof
      end;

    if cnt=12 then write(fout2, (sum/cnt):10:3);
    writeln(fout2);
 until eof(fout1);  }
 CloseFile(fout1);   // close files;
 CloseFile(fout2);   // close files;
end;



procedure Tfrmtimeseries.Button4Click(Sender: TObject);
Var
k:integer;
  lst:TStringList;
  fdb:TSearchRec;
  fpath, fname, st:string;
  lev, mindate, maxdate, maxlev:real;
  date1, date2, yy, mn, dd, hh, mm, ss, val1:string;
begin
 lst:=TStringList.Create;
 fdb.Name:='';
 fpath:='x:\Results\VV\global analysis\timeseries report\d\2007-2015\';
  FindFirst(fpath+'*.txt',faAnyFile, fdb);
   if fdb.Name<>'' then lst.add(fdb.Name);
   while findnext(fdb)=0 do  if fdb.Name<>'' then lst.add(fdb.Name);
  FindClose(fdb);

  For k:=0 to lst.Count-1 do begin
    fname:=lst.Strings[k];
    Assignfile(out1, fpath+fname); append(out1);

    Assignfile(fin, 'X:\Results\VV\global analysis\timeseries report\d\2015-2016\'+fname); reset(fin);
    readln(fin, st);
     repeat
        readln(fin, st);
         date1:=copy(st,  1, 20);
         date2:=copy(st, 21, 25);
         yy   :=copy(st, 46,  5);
         mn   :=copy(st, 51,  5);
         dd   :=copy(st, 56,  5);
         hh   :=copy(st, 61,  5);
         mm   :=copy(st, 66,  5);
         ss   :=copy(st, 71,  5);
         val1 :=copy(st, 76, 15);
        writeln(out1,  date1, date2, yy, mn, dd, hh, mm, ss, val1);
     until eof(fin);
    flush(out1);
    closefile(fin);

    Assignfile(fin, 'X:\Results\VV\global analysis\timeseries report\d\2017\'+fname); reset(fin);
    readln(fin, st);
     repeat
        readln(fin, st);
         date1:=copy(st,  1, 20);
         date2:=copy(st, 21, 25);
         yy   :=copy(st, 46,  5);
         mn   :=copy(st, 51,  5);
         dd   :=copy(st, 56,  5);
         hh   :=copy(st, 61,  5);
         mm   :=copy(st, 66,  5);
         ss   :=copy(st, 71,  5);
         val1 :=copy(st, 76, 15);
        writeln(out1,  date1, date2, yy, mn, dd, hh, mm, ss, val1);
     until eof(fin);
    flush(out1);
    closefile(fin);
  //  application.ProcessMessages;
  end;
  CloseFile(out1);
  lst.free;

  showmessage('done');
end;





end.
