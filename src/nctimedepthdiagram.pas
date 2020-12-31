unit nctimedepthdiagram;

{$mode objfpc}{$H+}

interface

uses
  Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs,
  Spin, StdCtrls, Math, DateUtils, ExtCtrls, CheckLst, ComCtrls, Buttons, DB,
  BufDataSet, LazFileUtils;

type

  { Tfrmnctld }

  Tfrmnctld = class(TForm)
    btnOpenFolder: TBitBtn;
    btnOpenScript: TBitBtn;
    Button2: TButton;
    cbClr1: TComboBox;
    cbLat: TComboBox;
    cbLon: TComboBox;
    cbLvl1: TComboBox;
    cbSeaBorders: TComboBox;
    eAdditionalOffset: TFloatSpinEdit;
    seLatMax: TFloatSpinEdit;
    seLatMin: TFloatSpinEdit;
    seLonMax: TFloatSpinEdit;
    seLonMin: TFloatSpinEdit;
    eAdditionalScale: TFloatSpinEdit;
    GroupBox2: TGroupBox;
    cbVariable: TComboBox;
    btnGetData: TButton;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    Label12: TLabel;
    Label13: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    btnPlot: TButton;
    btnSettings: TButton;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    pgMain: TPageControl;
    ePointLat: TFloatSpinEdit;
    ePointLon: TFloatSpinEdit;
    ePointRad: TFloatSpinEdit;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;

    procedure cbClr1DropDown(Sender: TObject);
    procedure cbLvl1DropDown(Sender: TObject);
    procedure cbSeaBordersDropDown(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure GetTLDValues(fname: string);
    procedure btnGetDataClick(Sender: TObject);
    procedure btnPlotClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);

  private
    { Private declarations }
    procedure GetValues(ll:integer);
  public
    { Public declarations }
  end;

var
  frmnctld: Tfrmnctld;
  dat:text;
  tldUnload, IniDataFile:string;
  tldYYMin, tldYYMax:integer;
  fout1, fout2:text;
  nctldCDS:TBufDataSet;

  tsYYMin, tsYYMax:integer;

  Num_point_BLN:array[1..1] of integer;
  Coord_BLN:array[1..2,1..200] of real;
  Long_min_BLN,Lat_min_BLN, lat_p, lon_p:real;

implementation

{$R *.lfm}

uses ncmain, declarations_netcdf, ncprocedures, surfer_settings, bathymetry,
     surfer_nctld;


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



procedure Tfrmnctld.FormShow(Sender: TObject);
Var
  k:integer;
  LatMin, LatMax, LonMin, LonMax : real;
begin
 if not DirectoryExists(GlobalUnloadPath+'tldiagrams'+PathDelim) then
        CreateDir(GlobalUnloadPath+'tldiagrams'+PathDelim);

 tldUnload:=GlobalUnloadPath+'tldiagrams'+PathDelim+ncname+PathDelim;
  if not DirectoryExists(tldUnload) then CreateDir(tldUnload);

 cbVariable.Items  := frmmain.cbVariables.items; // variable
 cbLat.Items       := frmmain.cbLat.items;       // latitude
 cbLon.Items       := frmmain.cbLon.items;       // longitude

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

  nctldCDS:=TBufDataSet.Create(nil);
   with  nctldCDS.FieldDefs do begin
    Add('YY'  ,ftInteger, 0, true);
    Add('MN'  ,ftInteger, 0, true);
    Add('LEV' ,ftFloat  , 0, true);
    Add('VAL' ,ftFloat  , 0, true);
   end;
  nctldCDS.CreateDataSet;
end;


procedure Tfrmnctld.cbLvl1DropDown(Sender: TObject);
Var
 fdb:TSearchRec;
begin
 (* загружаем список *.lvl файлов *)
fdb.Name:='';
cbLvl1.Clear;
 FindFirst(GlobalPath+'support\lvl\*.lvl',faAnyFile,fdb);
  if fdb.Name<>'' then cbLvl1.Items.Add(fdb.Name);
   while FindNext(fdb)=0 do cbLvl1.Items.Add(fdb.Name);
 FindClose(fdb);
 if cbLvl1.Items.Count=0 then cbLvl1.Enabled:=false;
 if cbLvl1.Items.Count<=20 then
    cbLvl1.DropDownCount:=cbLvl1.Items.Count else
    cbLvl1.DropDownCount:=20;
end;

procedure Tfrmnctld.cbSeaBordersDropDown(Sender: TObject);
Var
   fdb:TSearchRec;
begin
    (* list of arbitraty regions *)
   fdb.Name:='';
   cbSeaBorders.Clear;
     FindFirst(GlobalSupportPath+'sea_borders'+PathDelim+'*.bln',faAnyFile, fdb);
     if fdb.Name<>'' then begin
      cbSeaBorders.Items.Add(ExtractFileNameWithoutExt(fdb.Name));
       while findnext(fdb)=0 do cbSeaBorders.Items.Add(ExtractFileNameWithoutExt(fdb.Name));
     end;
    FindClose(fdb);
end;


procedure Tfrmnctld.cbClr1DropDown(Sender: TObject);
Var
 fdb:TSearchRec;
begin
 (* загружаем список *.clr файлов *)
 fdb.Name:='';
 cbclr1.Clear;
  FindFirst(GlobalPath+'support\clr\*.clr',faAnyFile, fdb);
   if fdb.Name<>'' then cbclr1.Items.Add(fdb.Name);
    while FindNext(fdb)=0 do cbclr1.Items.Add(fdb.Name);
  FindClose(fdb);
 if cbclr1.Items.Count=0 then cbclr1.Enabled:=false;
 if cbclr1.Items.Count<=20 then
    cbclr1.DropDownCount:=cbclr1.Items.Count else
    cbclr1.DropDownCount:=20;
end;



procedure Tfrmnctld.btnGetDataClick(Sender: TObject);
Var
  ll, ff, cnt, gebco, depth_max, lt_i, ln_i:integer;
  lat, lon:real;
  ltmin, ltmax, lnmin, lnmax, dist:real;
  ci1:integer;
  st, par_st, units:string;
begin
 // exit if variable isn't selected
 if (cbVariable.Enabled=true) and (cbVariable.ItemIndex=-1) then
  if messagedlg('Please, select variable', mtwarning, [mbOk], 0)=mrOk then exit;

 // exit if sea border file isn't selected
 if (pgMain.PageIndex=2) and (cbSeaBorders.ItemIndex=-1) then
  if messagedlg('Please, select sea borders file', mtwarning, [mbOk], 0)=mrOk then exit;

 // exit if coordinates of a node aren't selected
 if (pgMain.PageIndex=3) and ((cbLat.ItemIndex=-1) or (cbLon.ItemIndex=-1)) then
  if messagedlg('Please, select both latitude and longitude', mtwarning, [mbOk], 0)=mrOk then exit;

 btnPlot.Enabled:=false;

 // predefined area
 if pgMain.PageIndex=2 then begin
  AssignFile(dat, GlobalSupportPath+'sea_borders'+PathDelim+cbSeaBorders.Text+'.bln'); reset(dat);
  readln(dat, st);

   ci1:=1;
   Ltmin:=-90;
   Ltmax:=ltmin;
   lnmin:=180;
   lnmax:=lnmin;

  repeat
   readln(dat, st);

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
  until eof(dat);
  CloseFile(dat);

    Coord_BLN[1,ci1]:=Coord_BLN[1,1];
    Coord_BLN[2,ci1]:=Coord_BLN[2,1];
    Num_point_BLN[1]:=ci1;

    Long_min_BLN:=lnmin;
    Lat_min_bln:=ltmin;
 end;  // end predefined area


 (* looking for max depth in the area *)
  depth_max:=-9999;
   for lt_i:=0 to high(ncLat_arr) do begin
     for ln_i:=0 to high(ncLon_arr) do begin

       Distance(ePointLon.Value, ncLon_arr[ln_i], ePointLat.Value, ncLat_arr[lt_i], Dist);

         if ((pgMain.PageIndex=0) and
              (ncLat_arr[lt_i]>=seLatMin.Value) and
              (ncLat_arr[lt_i]<=seLatMax.Value) and
              (((seLonMin.Value<=seLonMax.Value) and
                (ncLon_arr[ln_i]>=seLonMin.Value) and
                (ncLon_arr[ln_i]<=seLonMax.Value)) or
               ((seLonMin.Value>seLonMax.Value) and
                (((ncLon_arr[ln_i]>=seLonMin.Value) and (ncLon_arr[ln_i]<=180)) or
               ((ncLon_arr[ln_i]>=-180)   and (ncLon_arr[ln_i]<=seLonMax.Value))))))
           or ((pgMain.PageIndex=1) and (Dist<=ePointRad.Value))
           or ((pgMain.PageIndex=2) and (Odd(Point_Status(ncLon_arr[ln_i],ncLat_arr[lt_i]))=true)) then begin
              gebco:=-GetBathymetry(ncLon_arr[ln_i], ncLat_arr[lt_i]);
           //   showmessage(floattostr(gebco));
             if gebco>depth_max then depth_max:=gebco;
           end;
     end;
   end;
//  showmessage(inttostr(depth_max));


 for ll:=0 to frmmain.cbLevels.Items.Count-1 do begin
 if ncLev_arr[ll]<=depth_max then begin
   AssignFile(dat, tldUnload+frmmain.cbLevels.Items.Strings[ll]+'.txt'); rewrite(dat);
   writeln(dat, 'Date_dec':20, 'Date':25, 'YY':5, 'MN':5, 'DD':5, 'HH':5, 'MM':5, 'SS':5, 'Value':15);
    for ff:=0 to frmmain.cbFiles.Count-1 do begin
     frmmain.cbFiles.ItemIndex:=ff;
     frmmain.cbFiles.OnClick(self);
      GetValues(ll);
    end; // files
   CloseFile(dat);
   end; //level;
 end;
btnPlot.Enabled:=true;
end;



procedure Tfrmnctld.btnPlotClick(Sender: TObject);
Var
  k, cnt:integer;
  lst:TStringList;
  fdb:TSearchRec;
  fname, st:string;
  lev, mindate, maxdate, maxlev:real;
  date1, date2, yy, mn, dd, hh, mm, ss, val1:real;
begin
try

 lst:=TStringList.Create;
 fdb.Name:='';
  FindFirst(tldUnload+'*.txt',faAnyFile, fdb);
   if fdb.Name<>'' then lst.add(fdb.Name);
   while findnext(fdb)=0 do  if fdb.Name<>'' then lst.add(fdb.Name);
  FindClose(fdb);

  cnt:=lst.Count;

  AssignFile(fout1, tldUnload+'tdd.dat'); rewrite(fout1);
  writeln(fout1, 'Date_dec':20, 'Date':10, 'YY':5, 'MN':5, 'DD':5, 'HH':5, 'MM':5, 'SS':5, 'Level':25, 'Value':15);

  mindate:=9999; maxdate:=-9999; maxlev:=0;
   For k:=0 to lst.Count-1 do begin
     fname:=lst.Strings[k];

     lev:=StrToFloat(ExtractFileNameWithoutExt(fname));
     if lev>maxlev then maxlev:=lev;

     AssignFile(dat, tldUnload+fname); reset (dat);
     readln(dat, st);
     repeat
       readln(dat, date1, date2, yy, mn, dd, hh, mm, ss, val1);
        if date1<mindate then mindate:=date1;
        if date1>maxdate then maxdate:=date1;
       writeln(fout1,  date1:20:15, date2:10:0, yy:5:0, mn:5:0, dd:5:0, hh:5:0, mm:5:0, ss:5:0, -lev:25:15, val1:15:3);
     until eof(dat);
     CloseFile(dat);
   end;
finally
 CloseFile(fout1);
 lst.Free;
end;

//showmessage('here2');

 GetTLDScript((tldUnload+'tdd.dat'), 1, 9, 10, high(ncLev_arr),
               cnt, mindate, maxdate, maxlev);

 {$IFDEF Windows}
    frmmain.RunScript(2, '-x "'+tldUnload+'script.bas"', nil);
 {$ENDIF}
end;


procedure Tfrmnctld.btnSettingsClick(Sender: TObject);
begin
 frmSurferSettings := TfrmSurferSettings.Create(Self);
 frmSurferSettings.LoadSettings('ncTLD');
  try
   if not frmSurferSettings.ShowModal = mrOk then exit;
  finally
    frmSurferSettings.Free;
    frmSurferSettings := nil;
  end;
end;


procedure Tfrmnctld.GetValues(ll:integer); //(fname: string; Var par_st, units:string);
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
begin

 //   showmessage('before1');

 LatMin:= seLatMin.Value;
 LatMax:= seLatMax.Value;
 LonMin:= seLonMin.Value;
 LonMax:= seLonMax.Value;

 Lat0:=strtofloat(ePointLat.Text);
 Lon0:=strtofloat(ePointLon.Text);
 Rad :=strtofloat(ePointRad.Text);


try
 (* nc_open*)
   status:=nc_open(pchar(ncpath+ncname), NC_NOWRITE, ncid); // only for reading
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
    {  if pAnsiChar(attname)='long_name' then begin
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
      end;  }
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
       start^[1]:=ll; //level
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
       if (Val0<>missing[0]) then begin //both

          //  showmessage(floattostr(val0)+'   '+floattostr(scale[0]));
            val1:=scale[0]*Val0+offset[0]; // scale and offset from netcdf
            val1:=addscale*val1+AddOffset;  // user defined conversion
           // showmessage(floattostr(val1));

          writeln(dat, date1:20:15, StrToDateTime(frmmain.cbDates.Items.Strings[tt]):25,
          yy:5, mn:5, dd:5, hh:5, mm:5, ss:5, Val1:15:3);
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
       start^[1]:=ll; //level
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


          if (Val0<>missing[0]) and (Val0<>-999) then begin  // if value is not missing

             //    if (tt=0) and (coordonetime=false) then
             //      writeln(fout3, floattostr(ncLat_arr[lt_i])+','+floattostr(ncLon_arr[ln_i]));

                  val1:=scale[0]*Val0+offset[0]; // scale and offset from netcdf
                  val1:=addscale*val1+AddOffset;  // user defined conversion

             //    showmessage(floattostr(nclat_arr[lt_i])+'   '+floattostr(nclon_arr[ln_i])+'   '+floattostr(val0)+'   '+floattostr(val1));

                  Int_val:=Int_val+Val1*cos(Pi*ncLat_arr[lt_i]/180);
                  Sum_pi:=Sum_pi+cos(Pi*ncLat_arr[lt_i]/180);
           end; // end of missing value loop

       end; // end same year
     end; // end of lon loop
    end; // end of lat loop
     if Sum_pi<>0 then begin
      Area_Mean:=Int_val/Sum_pi;
       writeln(dat, date1:20:15, StrToDateTime(frmmain.cbDates.Items.Strings[tt]):25,
          yy:5, mn:5, dd:5, hh:5, mm:5, ss:5, Area_mean:15:3);
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



(* Averaged data from each specified file *)
procedure Tfrmnctld.GetTLDValues(fname: string);
Var
  status, ncid, varidp, ndimsp:integer;
  tt, lv, lt, ln, tp:integer;
  AddScale, AddOffset:real;
  scale, offset, missing: array [0..0] of single;
  atttext: array of pansichar;
  attlenp, lenp:size_t;
  vtype :nc_type;
   fp:array of single;
   sp:array of smallint;
   ip:array of integer;
   dp:array of double;
  start: PArraySize_t;
  LatMin, LatMax, LonMin, LonMax : real;
  MnMin, MnMax:integer;
  val0, val1, yy1, Int_val:real;
  sum_pi, Area_Mean:real;
  yy, mn, dd, hh, mm, ss, ms:word;
begin
{ LatMin:= StrToFloat(.Text);
 LatMax:= StrToFloat(edit1.Text);

 LonMin:= StrToFloat(edit3.Text);
 LonMax:= StrToFloat(edit4.Text);

 MNMin := seMnMin.Value;
 MNMax := seMnMax.Value;  }
try
 (* nc_open*)
   status:=nc_open(pansichar(AnsiString(ncpath+ncname)), NC_NOWRITE, ncid); // only for reading
    if status>0 then showmessage(pansichar(nc_strerror(status)));

   nc_inq_varid (ncid, pAnsiChar(AnsiString(cbVariable.Text)), varidp); // variable ID
   nc_inq_vartype (ncid, varidp, vtype);
   nc_inq_varndims (ncid, varidp, ndimsp);

   nc_get_att_float(ncid, varidp, pansichar(AnsiString('add_offset')),    offset);
   nc_get_att_float(ncid, varidp, pansichar(AnsiString('scale_factor')),  scale);
   nc_get_att_float(ncid, varidp, pansichar(AnsiString('missing_value')), missing);

   if scale[0]=0 then scale[0]:=1; // if there's no scale in the file

   nc_inq_dimlen (ncid, timeDid, lenp);
    setlength(ncTime_arr, lenp);
    nc_get_var_double (ncid, timeVid, ncTime_arr);

   nc_inq_attlen (ncid, timeVid, pansichar(AnsiString('units')), attlenp);
   setlength(atttext, attlenp);
   nc_get_att_text (ncid, timeVid, pansichar(AnsiString('units')), atttext);

   GetDates(pansichar(atttext));

    // additional user defined conversion - if needed
   if eAdditionalScale.Text<>''  then AddScale := StrToFloat(eAdditionalScale.Text)  else AddScale:=1;
   if eAdditionalOffset.Text<>'' then AddOffset:= StrToFloat(eAdditionalOffset.Text) else AddOffset:=0;

   start:=GetMemory(SizeOf(TArraySize_t)*ndimsp); // get memory for start pointer

   for lv:=0 to high(ncLev_arr) do begin
   start^[1]:=lv;

    for tt:=0 to high(ncTime_arr) do begin
    DecodeDateTime(StrToDateTime(frmmain.cbDates.Items.Strings[tt]), yy, mn, dd, hh, mm, ss, ms);

     tldYYMin:=min(yy, tldYYMin); // min year
     tldYYMax:=max(yy, tldYYMax); // max year

     start^[0]:=tt; //time

   if ((mnMin<=MnMax) and ((mn>=MnMin) and (mn<=MnMax))) or
      ((mnMin> MnMax) and ((mn>=MnMin) or (mn<=MnMax))) then begin

     for lt:=0 to high(ncLat_arr) do begin
      start^[2]:=lt;  //lat

      for ln:=0 to high(ncLon_arr) do begin
       start^[3]:=ln; //ln


        // get area mean
       if (ncLat_arr[lt]>=LatMin) and (ncLat_arr[lt]<=LatMax) and
          (ncLon_arr[ln]>=LonMin) and (ncLon_arr[ln]<=LonMax) then begin
             case vtype of
               NC_SHORT:
                begin
                 SetLength(sp, 1);
                  nc_get_var1_short(ncid, varidp, start^, sp);
                 Val0:=sp[0];
                end;
               NC_INT:
                begin
                 SetLength(ip, 1);
                  nc_get_var1_int(ncid, varidp, start^, ip);
                 Val0:=ip[0];
                end;
               NC_FLOAT:
                begin
                 SetLength(fp, 1);
                  nc_get_var1_float(ncid, varidp, start^, fp);
                 Val0:=fp[0];
                end;
               NC_DOUBLE:
                begin
                 SetLength(dp, 1);
                  nc_get_var1_double(ncid, varidp, start^, dp);
                 Val0:=dp[0];
                end;
             end;

            if Val0<>missing[0] then begin  // if value is not missing
             val1:=scale[0]*Val0+offset[0]; // scale and offset from netcdf
             val1:=addscale*val1+AddOffset;  // user defined conversion

             Int_val:=Int_val+Val1*cos(Pi*ncLat_arr[lt]/180);
             Sum_pi:=Sum_pi+cos(Pi*ncLat_arr[lt]/180);
           end; // end of missing value loop
       end; // end of get area mean
     end; // end of lon loop
    end; // end of lat loop

     if Sum_pi<>0 then begin
      Area_Mean:=Int_val/Sum_pi;

       with  nctldCDS do begin
        Append;
         FieldByName('YY').AsInteger:=yy;
         FieldByName('MN').AsInteger:=mn;
         FieldByName('LEV').AsFloat:=ncLev_arr[lv];
         FieldByName('VAL').AsFloat:=Area_mean;
        Post;
       end;
     Application.processMessages;
     //  writeln(dat, yy:5, mn:5, ncLev_arr[lv]:6:0, Area_mean:15:3); // write mean value for year
     end;
      Int_val:=0; sum_pi:=0; area_mean:=0;  // clear variables

      end;// condition on month


    end; // and of time loop



   end; // end of level loop

 finally
  status:=nc_close(ncid);  // Close file
   if status>0 then showmessage(pansichar(nc_strerror(status)));
  FreeMemory(start);
 end;
end;


procedure Tfrmnctld.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  nctldcds.Free;
end;




end.
