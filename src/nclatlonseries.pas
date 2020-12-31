unit nclatlonseries;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLProc, SysUtils, Variants, Classes, Graphics, ExtCtrls,
  Controls, Forms, Dialogs, StdCtrls, Buttons, DateUtils, math,
  BufDataset, db;

type

  { Tfrmlatlonseries }

  Tfrmlatlonseries = class(TForm)
    Button1: TButton;
    btnPlot: TButton;
    btnSettings: TButton;
    cbClr1: TComboBox;
    cbLevel1: TComboBox;
    cbLvl1: TComboBox;
    chkAnomalies: TCheckBox;
    FloatField1: TFloatField;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    cbVariable: TComboBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    eAdditionalOffset: TEdit;
    eAdditionalScale: TEdit;
    btnGetTimeSeries: TButton;
    btnOpenFolder: TBitBtn;
    Label9: TLabel;
    rbSorting: TRadioGroup;

    procedure btnGetTimeSeriesClick(Sender: TObject);
    procedure btnPlotClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnOpenFolderClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmlatlonseries: Tfrmlatlonseries;
  fdat, fout1, fout2, fout3, fout4, fout5, fout6, fout7, fout8, fout9, fout10, fout11, fout12:text;
  nclatlon:string;
  nctslatloncds, latlonyycds:TBufDataSet;


implementation

{$R *.lfm}

uses ncmain, declarations_netcdf, ncprocedures, surfer_settings, surfer_ncfields,
     surfer_nclatlon;




procedure Tfrmlatlonseries.FormShow(Sender: TObject);
Var
  fdb:TSearchRec;
begin
 cbVariable.Items := frmmain.cbVariables.items; // copy variable names
 cbLevel1.Items    := frmmain.cbLevels.items;    // levels

 // enable/disable levels - if there are some
 if cbLevel1.Items.Count=0 then cbLevel1.Enabled:=false;

 if not DirectoryExists(GlobalPath+'unload'+PathDelim+'latlonseries'+PathDelim) then
   CreateDir(GlobalPath+'unload'+PathDelim+'latlonseries'+PathDelim);

 nclatlon:=GlobalPath+'unload'+PathDelim+'latlonseries'+PathDelim;
 if not DirectoryExists(nclatlon) then CreateDir(nclatlon);
 if not DirectoryExists(nclatlon+'\png\') then CreateDir(nclatlon+'\png\');
 if not DirectoryExists(nclatlon+'\srf\') then CreateDir(nclatlon+'\srf\');
 if not DirectoryExists(nclatlon+'\grd\') then CreateDir(nclatlon+'\grd\');

 (* загружаем список *.lvl файлов *)
 fdb.Name:='';
 cblvl1.Clear;
  FindFirst(GlobalPath+'support\lvl\*.lvl',faAnyFile, fdb);
   if fdb.Name<>'' then begin
     cbLvl1.Items.Add(ExtractFileName(fdb.Name));
      while findnext(fdb)=0 do cbLvl1.Items.Add(ExtractFileName(fdb.Name));
   end;
  FindClose(fdb);
  if cbLvl1.Items.Count=0 then cbLvl1.Enabled:=false;

 (* загружаем список *.clr файлов *)
 fdb.Name:='';
 cbclr1.Clear;
  FindFirst(GlobalPath+'support\clr\*.clr',faAnyFile, fdb);
   if fdb.Name<>'' then begin
    cbclr1.Items.Add(ExtractFileName(fdb.Name));
     while findnext(fdb)=0 do cbclr1.Items.Add(ExtractFileName(fdb.Name));
   end;
  FindClose(fdb);
  if cbclr1.Items.Count=0 then cbclr1.Enabled:=false;

end;


procedure Tfrmlatlonseries.btnGetTimeSeriesClick(Sender: TObject);
Var
  status, ncid, varidp, ndimsp, mni:integer;
  tt, ll, lati, loni, kf, cnt, i, yy_min, yy_max:integer;
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
 // LatMin, LatMax, LonMin, LonMax: real;
  val0, val1, Int_val:real;
  yy, mn, dd, hh, mm, ss, ms:word;
  mn_str, f_name:string;
begin
// btnPlot.Enabled:=false;
 btnGetTimeSeries.Enabled:=false;
 btnOpenFolder.Enabled:=false;


 nctslatloncds:=TBufDataSet.Create(nil);
 with nctslatloncds.FieldDefs do begin
  Add('yy'   ,ftinteger, 0, false);
  Add('mn'   ,ftinteger, 0, false);
  Add('axis' ,ftFloat  , 0, false);
  Add('val'  ,ftFloat  , 0, false);
  Add('anom' ,ftFloat  , 0, false);
 end;
 nctslatloncds.CreateDataSet;


 (* Запускаем цикл по всем файлам *)
 yy_max:=-9999; yy_min:=9999;
 for kf:=0 to frmmain.cbFiles.Count-1 do begin
     ncName:=frmmain.cbFiles.Items.Strings[kf];
 // showmessage(ncname);
   try
  (* nc_open*)
   status:=nc_open(pchar(ncpath+ncname), NC_NOWRITE, ncid); // only for reading
    if status>0 then showmessage(pansichar(nc_strerror(status)));

   nc_inq_varid (ncid, pChar(cbVariable.Text), varidp); // variable ID
   nc_inq_vartype (ncid, varidp, vtype);
   nc_inq_varndims (ncid, varidp, ndimsp);

   nc_get_att_float(ncid, varidp, pchar('add_offset'),    offset);
   nc_get_att_float(ncid, varidp, pchar('scale_factor'),  scale);
   nc_get_att_float(ncid, varidp, pchar('missing_value'), missing);

   if scale[0]=0 then scale[0]:=1; // if there's no scale in the file

   nc_inq_dimlen (ncid, timeDid, lenp);
    setlength(ncTime_arr, lenp);
    nc_get_var_double (ncid, timeVid, ncTime_arr);

   nc_inq_attlen (ncid, timeVid, pchar('units'), attlenp);
   setlength(atttext, attlenp);
   nc_get_att_text (ncid, timeVid, pchar('units'), atttext);

    GetDates(pansichar(atttext));

    // additional user defined conversion - if needed
   if eAdditionalScale.Text<>''  then AddScale := StrToFloat(eAdditionalScale.Text)  else AddScale:=1;
   if eAdditionalOffset.Text<>'' then AddOffset:= StrToFloat(eAdditionalOffset.Text) else AddOffset:=0;

   start:=GetMemory(SizeOf(TArraySize_t)*ndimsp); // get memory for start pointer


   for tt:=0 to high(ncTime_arr) do begin
    DecodeDateTime(StrToDateTime(frmmain.cbDates.Items.Strings[tt]), yy, mn, dd, hh, mm, ss, ms);

    if yy>yy_max then yy_max:=yy;  //max year
    if yy<yy_min then yy_min:=yy;  //min year

    start^[0]:=tt; //time

  // Считаем для ШИРОТ
  if rbSorting.ItemIndex=0 then begin
     for lati:=0 to high(ncLat_arr) do begin
      if ndimsp=3 then start^[1]:=lati;  //lat
      if ndimsp=4 then begin
       start^[1]:=cbLevel1.ItemIndex; //level
       start^[2]:=lati;  //lat
      end;

      int_val:=0; cnt:=0;
      for loni:=0 to high(ncLon_arr) do begin
       if ndimsp=3 then start^[2]:=loni;  //longitude
       if ndimsp=4 then start^[3]:=loni;

        // get latitude mean
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

            if (Val0<>missing[0]) then begin  // if value is not missing
                val1:=scale[0]*Val0+offset[0]; // scale and offset from netcdf
                val1:=addscale*val1+AddOffset;  // user defined conversion

                Int_val:=Int_val+Val1;
                inc(cnt);
           end; // end of missing value loop
     end; // end of lon loop

     if cnt>0 then begin
       val1:=int_val/cnt;
       with nctslatloncds do begin
        Append;
          FieldByName('yy').AsInteger:=yy;
          FieldByName('mn').AsInteger:=mn;
          FieldByName('axis').AsFloat :=ncLat_arr[lati];
          FieldByName('val').AsFloat :=val1;
        Post;
       end;
      end;
     end; // end of lat loop
   end; // конец расчета для ШИРОТ



   // Считаем для ДОЛГОТ
  if rbSorting.ItemIndex=1 then begin
   for loni:=0 to high(ncLon_arr) do begin
    start^[2]:=loni;

     int_val:=0; cnt:=0;
      for lati:=0 to high(ncLat_arr) do begin
       start^[1]:=lati;  //lat

        // get longitude mean
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

            if (Val0<>missing[0]) then begin  // if value is not missing
                val1:=scale[0]*Val0+offset[0]; // scale and offset from netcdf
                val1:=addscale*val1+AddOffset;  // user defined conversion

                Int_val:=Int_val+Val1;
                inc(cnt);
           end; // end of missing value loop
     end; // end of lat loop

     if cnt>0 then begin
       val1:=int_val/cnt;
       with nctslatloncds do begin
        Append;
          FieldByName('yy').AsInteger:=yy;
          FieldByName('mn').AsInteger:=mn;
          FieldByName('axis').AsFloat :=ncLon_arr[loni];
          FieldByName('val').AsFloat :=val1;
        Post;
       end;
     end;
    end; // end of lon loop
   end; // конец расчета для ДОЛГОТ
 end; // end of time loop

 finally
  status:=nc_close(ncid);  // Close file
   if status>0 then showmessage(pansichar(nc_strerror(status)));
  FreeMemory(start);
 end;
end;// end of all files

 //showmessage('выгрузка ок');

  //showmessage(inttostr(yy_min)+'   '+inttostr(yy_max));

 (* объявляем набор данных для среднегодовых *)
 latlonyycds:=TBufDataSet.Create(nil);
 with latlonyycds.FieldDefs do begin
  Add('yy'   ,ftinteger, 0, false);
  Add('axis' ,ftFloat  , 0, false);
  Add('val'  ,ftFloat  , 0, false);
  Add('anom' ,ftFloat  , 0, false);
 end;
 latlonyycds.CreateDataSet;

 (* Считаем среднее за каждый год *)
  for i:=yy_min to yy_max do begin
   if rbSorting.ItemIndex=0 then begin
     for lati:=0 to high(ncLat_arr) do begin

      nctslatloncds.Filtered:=false;
      nctslatloncds.Filter:='axis=' +Floattostr(ncLat_arr[lati])+' and yy='+inttostr(i);
      nctslatloncds.Filtered:=true;

      nctslatloncds.First;
      int_val:=0; cnt:=0;
       while not nctslatloncds.Eof do begin
        int_val:=int_val+nctslatloncds.FieldByName('val').AsFloat;
        inc(cnt);
       nctslatloncds.Next;
      end;
      with latlonyycds do begin
       Append;
        FieldByName('yy').asInteger:=i;
        FieldByName('axis').asFloat:=ncLat_arr[lati];
        FieldByName('val').asFloat:=(int_val/cnt);
       Post;
     end;
      nctslatloncds.Filtered:=false;
     end; //lati


   end; //sorting=0

   if rbSorting.ItemIndex=1 then begin
    for loni:=0 to high(ncLon_arr) do begin

    nctslatloncds.Filtered:=false;
     nctslatloncds.Filter:='axis='+Floattostr(ncLon_arr[loni])+' and yy='+inttostr(i);
    nctslatloncds.Filtered:=true;

    nctslatloncds.First;
    int_val:=0; cnt:=0;
     while not nctslatloncds.Eof do begin
       int_val:=int_val+nctslatloncds.FieldByName('val').AsFloat;
       inc(cnt);
      nctslatloncds.Next;
     end;
      with latlonyycds do begin
      Append;
       FieldByName('yy').asInteger:=i;
       FieldByName('axis').asFloat:=ncLon_arr[loni];
       FieldByName('val').asFloat:=(int_val/cnt);
      Post;
     end;
    nctslatloncds.Filtered:=false;
   end; //loni
  end; //sorting=1
 end; //years
(* конец расчета среднегодовых *)

showmessage('годовые значения ок');


(* Считаем аномалии по годам *)
 if rbSorting.ItemIndex=0 then begin
   for lati:=0 to high(ncLat_arr) do begin

    latlonyycds.Filtered:=false;
    latlonyycds.Filter:='axis=' +Floattostr(ncLat_arr[lati]);
    latlonyycds.Filtered:=true;

   latlonyycds.First;
   int_val:=0; cnt:=0;
   while not latlonyycds.Eof do begin
     int_val:=int_val+latlonyycds.FieldByName('val').AsFloat;
     inc(cnt);
    latlonyycds.Next;
   end;

   latlonyycds.First;
   while not latlonyycds.Eof do begin
    val1:=latlonyycds.FieldByName('val').AsFloat;
     latlonyycds.Edit;
      latlonyycds.FieldByName('anom').AsFloat:=val1-(int_val/cnt);
     latlonyycds.Post;
    latlonyycds.Next;
   end;
     latlonyycds.Filtered:=false;
   end;
  end;


  if rbSorting.ItemIndex=1 then begin
   for loni:=0 to high(ncLon_arr) do begin

    latlonyycds.Filtered:=false;
     latlonyycds.Filter:='axis='+Floattostr(ncLon_arr[loni]);
    latlonyycds.Filtered:=true;

   latlonyycds.First;
   int_val:=0; cnt:=0;
   while not latlonyycds.Eof do begin
     int_val:=int_val+latlonyycds.FieldByName('val').AsFloat;
     inc(cnt);
   latlonyycds.Next;
   end;

   latlonyycds.First;
   while not latlonyycds.Eof do begin
    val1:=latlonyycds.FieldByName('val').AsFloat;
     latlonyycds.Edit;
      latlonyycds.FieldByName('anom').AsFloat:=val1-(int_val/cnt);
     latlonyycds.Post;
    latlonyycds.Next;
   end;
    latlonyycds.Filtered:=false;
   end;
  end;

  showmessage('годовые аномалии ок');

(* Считаем аномалии по месяцам *)
  for mni:=1 to 12 do begin
   if mni<10 then mn_str:='0'+inttostr(mni) else mn_str:=inttostr(mni);

 if rbSorting.ItemIndex=0 then begin
   for lati:=0 to high(ncLat_arr) do begin

    nctslatloncds.Filtered:=false;
    nctslatloncds.Filter:='axis=' +Floattostr(ncLat_arr[lati])+' and mn='+inttostr(mni);
    nctslatloncds.Filtered:=true;

   nctslatloncds.First;
   int_val:=0; cnt:=0;
   while not nctslatloncds.Eof do begin
     int_val:=int_val+nctslatloncds.FieldByName('val').AsFloat;
     inc(cnt);
    nctslatloncds.Next;
   end;

   nctslatloncds.First;
   while not nctslatloncds.Eof do begin
    val1:=nctslatloncds.FieldByName('val').AsFloat;
     nctslatloncds.Edit;
      nctslatloncds.FieldByName('anom').AsFloat:=val1-(int_val/cnt);
     nctslatloncds.Post;
    nctslatloncds.Next;
   end;
    nctslatloncds.Filtered:=false;
   end;
  end;


  if rbSorting.ItemIndex=1 then begin
   for loni:=0 to high(ncLon_arr) do begin

    nctslatloncds.Filtered:=false;
     nctslatloncds.Filter:='axis='+Floattostr(ncLon_arr[loni])+' and mn='+inttostr(mni);
    nctslatloncds.Filtered:=true;

   nctslatloncds.First;
   int_val:=0; cnt:=0;
   while not nctslatloncds.Eof do begin
     int_val:=int_val+nctslatloncds.FieldByName('val').AsFloat;
     inc(cnt);
    nctslatloncds.Next;
   end;

   nctslatloncds.First;
   while not nctslatloncds.Eof do begin
    val1:=nctslatloncds.FieldByName('val').AsFloat;
     nctslatloncds.Edit;
      nctslatloncds.FieldByName('anom').AsFloat:=val1-(int_val/cnt);
     nctslatloncds.Post;
    nctslatloncds.Next;
   end;
    nctslatloncds.Filtered:=false;
   end;
  end;
  end; //mni

 showmessage('аномалии по месяцам ок');


  if rbSorting.ItemIndex=0 then begin
   cnt:=high(ncLat_arr);
   f_name:='Lat';
  end;
  if rbSorting.ItemIndex=1 then begin
   cnt:=high(ncLon_arr);
   f_name:='Lon';
  end;

   (* пишем годовые файлы *)
    (* unloading data for plotting in Surfer as yy->Lat/Lon->Val->anom *)
    AssignFile(fout1,  nclatlon+cbVariable.Text+'_yy_'+f_name+'.txt'); rewrite(fout1);
    writeln(fout1,   'year':5, 'Axis':15, 'Value':12, 'Anomaly':12);
    latlonyycds.First;
    while not latlonyycds.Eof do begin
      writeln(fout1,  latlonyycds.FieldByName('yy').AsInteger:5,
                      latlonyycds.FieldByName('axis').AsFloat:15:5,
                      latlonyycds.FieldByName('val').AsFloat:12:3,
                      latlonyycds.FieldByName('anom').AsFloat:12:3);
      latlonyycds.Next;
     end;
   closefile(fout1);
   (* end of unloading *)

   (* unloading data as # of columns = # of Lat/Lon, per yer *)
   AssignFile(fout1,  nclatlon+cbVariable.Text+'_yy_'+f_name+'_val.txt'); rewrite(fout1);
   AssignFile(fout2,  nclatlon+cbVariable.Text+'_yy_'+f_name+'_an.txt' ); rewrite(fout2);
    // Title
     write(fout1, 'Year':5);
     write(fout2, 'Year':5);
      for i:=0 to cnt do begin
        write(fout1, (f_name+'_'+FloatToStr(ncLat_arr[i])):12);
        write(fout2, (f_name+'_'+FloatToStr(ncLat_arr[i])):12);
      end;
     writeln(fout1);
     writeln(fout2);

    // Values
    latlonyycds.First;
    while not latlonyycds.Eof do begin
     write(fout1, latlonyycds.FieldByName('yy').AsInteger:5);
     write(fout2, latlonyycds.FieldByName('yy').AsInteger:5);
      for i:=1 to cnt+1 do begin
        write(fout1, latlonyycds.FieldByName('val').AsFloat:12:3);
        write(fout2, latlonyycds.FieldByName('anom').AsFloat:12:3);
       latlonyycds.Next;
      end;
      writeln(fout1);
      writeln(fout2);
     end;
   closefile(fout1);
   closefile(fout2);
  (* end of unloading *)


  (* пишем файлы месячные*)
  for mni:=1 to 12 do begin
   if mni<10 then mn_str:='0'+inttostr(mni) else mn_str:=inttostr(mni);

     nctslatloncds.Filtered:=false;
     nctslatloncds.Filter:='mn='+inttostr(mni);
     nctslatloncds.Filtered:=true;

    (* unloading data for plotting in Surfer as yy->Lat/Lon->Val->anom *)
    AssignFile(fout1,  nclatlon+cbVariable.Text+'_'+mn_str+'_'+f_name+'.txt'); rewrite(fout1);
    writeln(fout1,   'year':5, 'Axis':15, 'Value':12, 'Anomaly':12);
    nctslatloncds.First;
    while not nctslatloncds.Eof do begin
      writeln(fout1,  nctslatloncds.FieldByName('yy').AsInteger:5,
                      nctslatloncds.FieldByName('axis').AsFloat:15:5,
                      nctslatloncds.FieldByName('val').AsFloat:12:3,
                      nctslatloncds.FieldByName('anom').AsFloat:12:3);
      nctslatloncds.Next;
     end;
   closefile(fout1);
   (* end of unloading *)

   (* unloading data as # of columns = # of Lat/Lon, per yer *)
   AssignFile(fout1,  nclatlon+cbVariable.Text+'_'+mn_str+'_'+f_name+'_val.txt'); rewrite(fout1);
   AssignFile(fout2,  nclatlon+cbVariable.Text+'_'+mn_str+'_'+f_name+'_an.txt' ); rewrite(fout2);
    // Title
     write(fout1, 'Year':5);
     write(fout2, 'Year':5);
      for i:=0 to cnt do begin
        write(fout1, (f_name+'_'+FloatToStr(ncLat_arr[i])):12);
        write(fout2, (f_name+'_'+FloatToStr(ncLat_arr[i])):12);
      end;
     writeln(fout1);
     writeln(fout2);

    // Values
    nctslatloncds.First;
    while not nctslatloncds.Eof do begin
     write(fout1, nctslatloncds.FieldByName('yy').AsInteger:5);
     write(fout2, nctslatloncds.FieldByName('yy').AsInteger:5);
      for i:=1 to cnt+1 do begin
        write(fout1, nctslatloncds.FieldByName('val').AsFloat:12:3);
        write(fout2, nctslatloncds.FieldByName('anom').AsFloat:12:3);
       nctslatloncds.Next;
      end;
      writeln(fout1);
      writeln(fout2);
     end;
   closefile(fout1);
   closefile(fout2);
  (* end of unloading *)

 nctslatloncds.Filtered:=false; // clear filter
end;

// btnPlot.Enabled:=true;
// nctslatloncds.Free;
// latlonyycds.Free;;
 btnGetTimeSeries.Enabled:=true;
 btnOpenFolder.Enabled:=true;
end;


(* Plotting *)
procedure Tfrmlatlonseries.btnPlotClick(Sender: TObject);
Var
  mni, col: integer;
  mn_str, src, f_name, lvl1, clr1:string;
begin
 if chkAnomalies.Checked=false then col:=3 else col:=4;

 if rbSorting.ItemIndex=0 then f_name:='Lat' else f_name:='Lon';

 if (cbLvl1.ItemIndex>-1) then lvl1:=GlobalPath+'support\lvl\'+cbLvl1.Text else lvl1:='';
 if (cbclr1.ItemIndex>-1) then clr1:=GlobalPath+'support\clr\'+cbclr1.Text else clr1:='';

 for mni:=1 to 13 do begin
  if mni<10 then mn_str:='0'+inttostr(mni) else mn_str:=inttostr(mni);
   if mni<=12 then
     src:=nclatlon+cbVariable.Text+'_'+mn_str+'_'+f_name+'.txt' else
     src:=nclatlon+cbVariable.Text+'_yy_'+f_name+'.txt';
   GetLatLonScript(src, Col, lvl1, clr1);
   {$IFDEF WINDOWS}
      frmmain.RunScript(2, '"'+nclatlon+'tmp'+PathDelim+'script.bas"', nil);
   {$ENDIF}
 end;
end;


procedure Tfrmlatlonseries.btnOpenFolderClick(Sender: TObject);
begin
  OpenDocument(PChar(nclatlon)); { *Converted from ShellExecute* }
end;

procedure Tfrmlatlonseries.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
   nctslatloncds.Free;
end;


(*
Осредняем уже полученные результаты по широтным областям
В коде заданы 8 регионов
*)
procedure Tfrmlatlonseries.Button1Click(Sender: TObject);
Var
  path, fname, st:string;
  lst:TStringList;
  fdb:tsearchrec;
  z, c, yy, lti:integer;
  lat, val1 :real;
  glob, north, south, s20n30, n325n625, n65n90, s65s90, s225s625:real;
  glob_cnt, north_cnt, south_cnt, s20n30_cnt, n325n625_cnt: integer;
  n65n90_cnt, s65s90_cnt, s225s625_cnt:integer;

begin
path:='x:\Results\Meteo2\Interim_total_column_water\2014\lat_series\all\';

lst:=TStringList.Create;

fdb.Name:='';
 FindFirst(path+'*.txt',faAnyFile, fdb);
  if fdb.Name<>'' then lst.add(fdb.Name);
  while findnext(fdb)=0 do if fdb.Name<>'' then lst.add(fdb.Name);
 FindClose(fdb);

 For z:=0 to lst.Count-1 do begin
   fname:=lst.Strings[z];
 // showmessage(path+fname);

  AssignFile(fdat, Path + fname); reset(fdat);
  readln(fdat, st);

  AssignFile(fout1, Path +'1\'+ fname); rewrite(fout1);
  writeln(fout1, 'Year':5, 'Glob':12, 'North':12, 'South':12, '20s-30n':12,
               '32.5n-62.5n':12, '65n-90n':12, '22.5s-62.5s':12, '65s-90s':12);
   repeat
    readln(fdat, st);

    glob:=0; north:=0; south:=0; s20n30:=0; n325n625:=0; n65n90:=0; s65s90:=0; s225s625:=0;
    glob_cnt:=0; north_cnt:=0; south_cnt:=0; s20n30_cnt:=0; n325n625_cnt:=0;
    n65n90_cnt:=0; s65s90_cnt:=0; s225s625_cnt:=0;

    yy:=strtoint(trim(copy(st, 1, 5)));

    c:=6; lat:=92.5;
    for lti:=1 to 73 do begin
     lat:=lat-2.5;
      val1:=StrToFloat(trim(copy(st, c, 12)));
     c:=c+12;
   //  showmessage(floattostr(lat)+'   '+floattostr(val1));
    //memo1.Lines.add(floattostr(lat));
   //global
    glob:=glob+val1;
    inc(glob_cnt);

   //northern hemisphere
   if lat>=0 then begin
    north:=north+val1;
    inc(north_cnt);
   end;

   //southern hemisphere
   if lat<=0 then begin
    south:=south+val1;
    inc(south_cnt);
   end;

   //20S-30N
   if (lat>=-20) and (lat<=30) then begin
    s20n30:=s20n30+val1;
    inc(s20n30_cnt);
   end;

   //32.5N-62.5N
   if (lat>=32.5) and (lat<=62.5) then begin
    n325n625:=n325n625+val1;
    inc(n325n625_cnt);
   end;

   //65N-90N
   if (lat>=65) and (lat<=90) then begin
    n65n90:=n65n90+val1;
    inc(n65n90_cnt);
   end;

   //65S-90S
   if (lat>=-90) and (lat<=-65) then begin
    s65s90:=s65s90+val1;
    inc(s65s90_cnt);
   end;

   //22.5S-62.5S
   if (lat>=-62.5) and (lat<=-22.5) then begin
    s225s625:=s225s625+val1;
    inc(s225s625_cnt);
   end;
  end;


   writeln(fout1, yy:5,
                  (glob/glob_cnt):12:3,
                  (north/north_cnt):12:3,
                  (south/south_cnt):12:3,
                  (s20n30/s20n30_cnt):12:3,
                  (n325n625/n325n625_cnt):12:3,
                  (n65n90/n65n90_cnt):12:3,
                  (s225s625/s225s625_cnt):12:3,
                  (s65s90/s65s90_cnt):12:3);

   until eof(fdat);
   closefile(fdat);
   closefile(fout1);
 end; //end of file list
lst.Free;
end;


procedure Tfrmlatlonseries.btnSettingsClick(Sender: TObject);
begin
  btnOpenFolder.Enabled:=false;
  //btnOpenScript.Enabled:=false;

   frmSurferSettings := TfrmSurferSettings.Create(Self);
   frmSurferSettings.LoadSettings('nclatlon');
    try
     if not frmSurferSettings.ShowModal = mrOk then exit;
    finally
      frmSurferSettings.Free;
      frmSurferSettings := nil;
    end;
end;


end.
