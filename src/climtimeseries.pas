unit climtimeseries;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Math, Spin, DateUtils, BufDataset, db, Buttons, ComCtrls, ExtCtrls,
  FileUtil, IniFiles;

type

  { Tfrmclimtimeseries }

  Tfrmclimtimeseries = class(TForm)
    btnAnomalies: TButton;
    btnGetSimpleTimeSeries: TButton;
    btnOpenFolder: TBitBtn;
    btnSeasonalCircleRemoval: TButton;
    cbLat: TComboBox;
    cbLevel: TComboBox;
    cbLon: TComboBox;
    cbSeaBorders: TComboBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    ePointLat: TEdit;
    ePointLon: TEdit;
    ePointRad: TEdit;
    gbAnomalies: TGroupBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lbVariable: TLabel;
    pgMain: TPageControl;
    seMnMin: TSpinEdit;
    seMnMax: TSpinEdit;
    Label2: TLabel;
    seYYmin: TSpinEdit;
    seYYMax: TSpinEdit;
    Label6: TLabel;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;

    procedure FormShow(Sender: TObject);
    procedure btnGetSimpleTimeSeriesClick(Sender: TObject);
    procedure btnAnomaliesClick(Sender: TObject);
    procedure btnOpenFolderClick(Sender: TObject);
    procedure btnSeasonalCircleRemovalClick(Sender: TObject);

  private
    { Private declarations }
    procedure GetValues(fname:string);
  //  procedure GetValues_exp(fname:string);
  public
    { Public declarations }
  end;

var
  frmclimtimeseries: Tfrmclimtimeseries;
  fin, fout1, fout2, fout3, fout4, fout5, fout6, fout7, fout8, fout9, fout10, fout11, fout12:text;
  tsncUnload:string;
  tsYYMin, tsYYMax:integer;
  coordonetime:boolean=false;

  Num_point_BLN:array[1..1] of integer;
  Coord_BLN:array[1..2,1..200] of real;
  Long_min_BLN,Lat_min_BLN, lat_p, lon_p:real;

implementation

{$R *.lfm}

uses ncmain, ncprocedures, declarations_netcdf, Bathymetry;

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



procedure Tfrmclimtimeseries.FormShow(Sender: TObject);
Var
  k:integer;
  LatMin, LatMax, LonMin, LonMax: real;
  fdb:TSearchRec;
  fname:string;
begin

 if frmmain.cbVariables.Count=3 then
 lbVariable.Caption := frmmain.cbVariables.items.Strings[0] else
 lbVariable.Caption := frmmain.cbVariables.items.Strings[4];

 cbLevel.Items     := frmmain.cbLevels.items;    // levels
 cbLat.Items       := frmmain.cbLat.items;       // latitude
 cbLon.Items       := frmmain.cbLon.items;       // longitude

 // enable/disable levels - depends on existing
 if cbLevel.Items.Count=0 then cbLevel.Enabled:=false;

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
 edit1.Text:=floattostr(LatMax);
 edit2.Text:=floattostr(LatMin);
 edit3.Text:=floattostr(LonMin);
 edit4.Text:=floattostr(LonMax);

 // min and max years
 tsYYMin:= 9999;
 tsYYMax:=-9999;

  (* загружаем список файлов с границами морей*)
 fdb.Name:=''; cbSeaBorders.Clear;
 cbSeaBorders.Text:='Select predefined area...';
  if FindFirst(GlobalPath+'support\sea_borders\*.sb',faAnyFile, fdb)<>0 then begin
    fname:=ExtractFileName(fdb.Name);
   cbSeaBorders.Items.Add(Copy(fname, 1, length(fname)-3));
  end;
  while FindNext(fdb)=0 do begin
    fname:=ExtractFileName(fdb.Name);
   cbSeaBorders.Items.Add(Copy(fname, 1, length(fname)-3));
  end;
 FindClose(fdb);
end;


(* getting data from netcdf *)
procedure Tfrmclimtimeseries.btnGetSimpleTimeSeriesClick(Sender: TObject);
Var
  kf, cnt:integer;
  lat, lon, depth:real;
  ltmin, ltmax, lnmin, lnmax:real;
  ci1:integer;
  st:string;
begin
 if (cbLevel.Enabled=true) and (cbLevel.ItemIndex=-1) then
  if messagedlg('Please, select level', mtwarning, [mbOk], 0)=mrOk then exit;
 // exit if sea border file isn't selected
 if (pgMain.PageIndex=2) and (cbSeaBorders.ItemIndex=-1) then
  if messagedlg('Please, select sea_borders file', mtwarning, [mbOk], 0)=mrOk then exit;
  // exit if coordinates of a node aren't selected
 if (pgMain.PageIndex=3) and ((cbLat.ItemIndex=-1) or (cbLon.ItemIndex=0)) then
  if messagedlg('Please, select both latitude and longitude', mtwarning, [mbOk], 0)=mrOk then exit;

 btnGetSimpleTimeSeries.Enabled:=false;

 // define and create output directory
 if pgMain.PageIndex=0 then tsncUnload:=GlobalPath+'unload\timeseries\area_averaging\';
 if pgMain.PageIndex=1 then tsncUnload:=GlobalPath+'unload\timeseries\around_fixed_point\';
 if pgMain.PageIndex=2 then tsncUnload:=GlobalPath+'unload\timeseries\predefined_area\';
 if pgMain.PageIndex=3 then tsncUnload:=GlobalPath+'unload\timeseries\single_node\';
 if not DirectoryExists(tsncUnload) then CreateDir(tsncUnload);

 // predefined area
 if pgMain.PageIndex=2 then begin
  AssignFile(fin, GlobalPath+'support\sea_borders\'+cbSeaBorders.Text+'.sb'); reset(fin);
  readln(fin, st);

   ci1:=1;
   Ltmin:=-90;
   Ltmax:=ltmin;
   lnmin:=180;
   lnmax:=lnmin;

  repeat
   readln(fin, st);

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

  try
   AssignFile(fout1, tsncUnload+lbVariable.Caption+'.txt');
   AssignFile(fout3, tsncUnload+'AreaCoordinates.txt'); rewrite(fout3);

   Rewrite(fout1);
   writeln(fout1, 'YY':5, 'MN':5, 'DD':5, 'HH':5, 'Value':15);

    for kf:=0 to frmmain.cbFiles.Count-1 do begin
     ncName:=frmmain.cbFiles.Items.Strings[kf];
      GetValues(ncpath+ncname);
      coordonetime:=true;
    end;

   seYYMin.Value:=tsYYMin;
   seYYMax.Value:=tsYYMax;

   seYYMin.MinValue:=seYYMin.Value;  // set years range for year begin
   seYYMin.MaxValue:=seYYMax.Value;

   seYYMax.MinValue:=seYYMin.Value; // set years range for year end
   seYYMax.MaxValue:=seYYMax.Value;

  finally
   CloseFile(fout1);
   CloseFile(fout3);
   btnGetSimpleTimeSeries.Enabled:=true;
   coordonetime:=false;
  end;

   AssignFile(fout1, tsncUnload+lbVariable.Caption+'.txt'); reset(fout1);
   cnt:=0;
   repeat
    readln(fout1);
    inc(cnt);
   until eof(fout1) or (cnt>3);
   CloseFile(fout1);

    if cnt<=2 then
    if MessageDlg('Unloaded file is empty', mtwarning, [mbOk], 0)=mrOk then exit;
end;


procedure Tfrmclimtimeseries.btnOpenFolderClick(Sender: TObject);
begin
  OpenDocument(PChar(tsncUnload));
end;


(* Averaging *)
procedure Tfrmclimtimeseries.btnAnomaliesClick(Sender: TObject);
Var
  FileData, FileAnom, clr1:string;
  MnMin, MnMax:integer;
  yy, mn, dd, hh, mm, ss, ms:real;
  globcnt, c, cnt:integer;

  yy1, val1, globmean:real;
  yy_old:integer;
  Int_val, Mean:real;
begin
 MnMin := seMnMin.Value;
 MnMax := seMnMax.Value;

 if pgMain.PageIndex=0 then tsncUnload:=GlobalPath+'unload\timeseries\area_averaging\';
 if pgMain.PageIndex=1 then tsncUnload:=GlobalPath+'unload\timeseries\around_fixed_point\';
 if pgMain.PageIndex=2 then tsncUnload:=GlobalPath+'unload\timeseries\predefined_area\';
 if pgMain.PageIndex=3 then tsncUnload:=GlobalPath+'unload\timeseries\single_node\';

 try
 AssignFile(fout1, tsncUnload+lbVariable.Caption+'.txt'); Reset(fout1); // file with values

 FileData:=tsncUnload+lbVariable.Caption+'_'+seMnMin.Text+'_'+seMnMax.Text+'_data_yearly.txt';
 FileAnom:=tsncUnload+lbVariable.Caption+'_'+seMnMin.Text+'_'+seMnMax.Text+'_anom_yearly.txt';

  AssignFile(fout2, FileData); Rewrite(fout2); // file for anomalies
  writeln(fout2, 'Year':5, 'Value':15); //write header
  readln(fout1);

   Int_val:=0; cnt:=0; mean:=0;
   globmean:=0; globcnt:=0; c:=0;
   repeat
    readln(fout1, yy, mn, dd, hh, val1);
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


(* Averaged data from each specified file *)
procedure Tfrmclimtimeseries.GetValues(fname: string);
Var
  Ini:TIniFile;
  status, ncid, varidp, varidp2, ndimsp:integer;
  tt, lt_i, ln_i, tp:integer;
  fp:array of single;
  start: PArraySize_t;
  atttext: array of pchar;
  attlenp, lenp:size_t;

  LatMin, LatMax, LonMin, LonMax, Lat0, Lon0, Rad, Dist: real;
  val0, val1, valr, yy1, Int_val, Val_err:real;
  sum_pi, area_mean, depth:real;
  yy, mn, dd, hh, mm, ss, ms:word;

  RelErr:real;
  UseRE:boolean;
begin

  try
   Ini := TIniFile.Create(IniFileName);
   RelErr:=Ini.ReadFloat('main', 'RelativeError',    0.25);
   UseRE :=Ini.ReadBool ('main', 'UseRelativeError', true);
  finally
    ini.Free;
  end;

 LatMin:= StrToFloat(edit2.Text);
 LatMax:= StrToFloat(edit1.Text);
 LonMin:= StrToFloat(edit3.Text);
 LonMax:= StrToFloat(edit4.Text);

 Lat0:=strtofloat(ePointLat.Text);
 Lon0:=strtofloat(ePointLon.Text);
 Rad :=strtofloat(ePointRad.Text);

try
 (* nc_open*)
   status:=nc_open(pchar(ncpath+ncname), NC_NOWRITE, ncid); // only for reading
    if status>0 then showmessage(pchar(nc_strerror(status)));

   nc_inq_varid (ncid, pChar(lbVariable.Caption), varidp); // variable ID
   nc_inq_varid (ncid, pChar(lbVariable.Caption+'_relerr'), varidp2); // variable ID


   nc_inq_dimlen (ncid, timeDid, lenp);
    setlength(ncTime_arr, lenp);
    nc_get_var_double (ncid, timeVid, ncTime_arr);

   nc_inq_attlen (ncid, timeVid, pansichar(AnsiString('units')), attlenp);
   setlength(atttext, attlenp);
   nc_get_att_text (ncid, timeVid, pansichar(AnsiString('units')), atttext);

   GetDates(pansichar(atttext));

   start:=GetMemory(SizeOf(TArraySize_t)*4); // get memory for start pointer

   for tt:=0 to high(ncTime_arr) do begin
    DecodeDateTime(StrToDateTime(frmmain.cbDates.Items.Strings[tt]), yy, mn, dd, hh, mm, ss, ms);
     tsYYMin:=min(yy, tsYYMin); // min year
     tsYYMax:=max(yy, tsYYMax); // max year

    (* for a single node *)
    if pgMain.PageIndex=3 then begin
       start^[0]:=tt;    //time
       start^[1]:=cbLevel.ItemIndex; //level
       start^[2]:=cbLat.ItemIndex;   //lat
       start^[3]:=cbLon.ItemIndex;   //lon

       SetLength(fp, 1);
        nc_get_var1_float(ncid, varidp, start^, fp);
       Val0:=fp[0];

       SetLength(fp, 1);
        nc_get_var1_float(ncid, varidp2, start^, fp);
       Valr:=fp[0];

          if (val0<>-9999) then begin
            if  (UseRE=false) or
               ((UseRE=true) and (valr<=RelErr)) then begin
            val1:=val0;
         (* для температуры ниже -1.8 *)
           if (lbVariable.Caption='Temperature') and (val1>-9999) and (val1<-1.8) then Val1:=-1.99;
          writeln(fout1, yy:5, mn:5, dd:5, hh:5, Val1:15:3); // write mean value for year
       end;  //end use RE
      end;  // end val<>-9999
    end;
   (* end for a single node *)



    (* Area averaging *)
   if  pgMain.PageIndex<3 then begin // not for a single node
    Int_val:=0; sum_pi:=0; area_mean:=0;
    start^[0]:=tt;  //time
    for lt_i:=0 to high(ncLat_arr) do begin
       start^[1]:=cbLevel.ItemIndex; //level
       start^[2]:=lt_i;  //lat
     for ln_i:=0 to high(ncLon_arr) do begin
       start^[3]:=ln_i;

       Distance(Lon0, ncLon_arr[ln_i], Lat0, ncLat_arr[lt_i], Dist);

        // get area mean
       if ((pgMain.PageIndex=0) and (ncLat_arr[lt_i]>=LatMin) and (ncLat_arr[lt_i]<=LatMax) and

            (((LonMin<=LonMax) and (ncLon_arr[ln_i]>=LonMin) and (ncLon_arr[ln_i]<=LonMax)) or
             ((LonMin> LonMax) and
              (((ncLon_arr[ln_i]>=LonMin) and (ncLon_arr[ln_i]<=180)) or
               ((ncLon_arr[ln_i]>=-180)   and (ncLon_arr[ln_i]<=LonMax))))))

           or ((pgMain.PageIndex=1) and (Dist<=Rad))

           or ((pgMain.PageIndex=2) and (Odd(Point_Status(ncLon_arr[ln_i],ncLat_arr[lt_i]))=true)) then begin

           SetLength(fp, 1);
            nc_get_var1_float(ncid, varidp, start^, fp);
           Val0:=fp[0];

            SetLength(fp, 1);
             nc_get_var1_float(ncid, varidp2, start^, fp);
            Valr:=fp[0];

            depth:=GetBathymetry(ncLon_arr[ln_i], ncLat_arr[lt_i]);

             if (val0<>-9999) then begin
               if  (UseRE=false) or
                  ((UseRE=true) and (valr<=RelErr)) then begin
               val1:=val0;
               (* для температуры ниже -1.8 *)
               if (lbVariable.Caption='Temperature') and (val1>-9999) and (val1<-1.8) then Val1:=-1.99;
                Int_val:=Int_val+Val1*cos(Pi*ncLat_arr[lt_i]/180);
                Sum_pi:=Sum_pi+cos(Pi*ncLat_arr[lt_i]/180);
              end;
           end;

       end; // end same year
     end; // end of lon loop
    end; // end of lat loop
     if Sum_pi<>0 then begin
      Area_Mean:=Int_val/Sum_pi;
       writeln(fout1, yy:5, mn:5, dd:5, hh:5, Area_mean:15:3); // write mean value for year
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



(* removing seasonal circle *)
procedure Tfrmclimtimeseries.btnSeasonalCircleRemovalClick(Sender: TObject);
Var
  FileData, FileAnom:string;
  MnMin, MnMax, i:integer;
  yy, mn, dd, hh, mm, ss, ms:real;
  globcnt, c, cnt:integer;

  yy1, val1, globmean:real;
  yy_old:integer;
  Int_val, Mean:real;
  mean_arr:array[1..12] of real;
begin

 if pgMain.PageIndex=0 then tsncUnload:=GlobalPath+'unload\timeseries\area_averaging\';
 if pgMain.PageIndex=1 then tsncUnload:=GlobalPath+'unload\timeseries\around_fixed_point\';
 if pgMain.PageIndex=2 then tsncUnload:=GlobalPath+'unload\timeseries\predefined_area\';
 if pgMain.PageIndex=3 then tsncUnload:=GlobalPath+'unload\timeseries\single_node\';

 for i:=1 to 12 do begin
  cnt:=0; int_val:=0;
  try
   AssignFile(fout1, tsncUnload+lbVariable.Caption+'.txt'); Reset(fout1); // file with values
   readln(fout1);
   repeat
    readln(fout1, yy, mn, dd, hh, val1);
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
   FileAnom:=tsncUnload+lbVariable.Caption+'_'+seMnMin.Text+'_'+seMnMax.Text+'_anom_monthly.txt';
   AssignFile(fout2, FileAnom); Rewrite(fout2); // file for anomalies
   writeln(fout2, 'Year':5, 'Month':5, 'Date':15, 'Value':15); //write header

   AssignFile(fout1, tsncUnload+lbVariable.Caption+'.txt'); Reset(fout1); // file with values
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


end.
