unit ncsections;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, Classes, SysUtils, LazFileUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons, ComCtrls, ExtCtrls, Spin, IniFiles, BufDataSet, DB,
  Variants, Math;

type

  { Tfrmsections }

  Tfrmsections = class(TForm)
    btnGoogle: TButton;
    btnOpenBLN: TButton;
    btnOpenFolder: TBitBtn;
    btnOpenScript: TBitBtn;
    btnPlot: TButton;
    btnSaveSection: TButton;
    btnSettings: TButton;
    cbClr1: TComboBox;
    cbDate: TComboBox;
    cbLvl1: TComboBox;
    cbVariable: TComboBox;
    chkPlot: TCheckBox;
    chkBlank: TCheckBox;
    chkMap: TCheckBox;
    chkPolar: TCheckBox;
    eAddOffset: TEdit;
    eAddScale: TEdit;
    ebln: TEdit;
    eLat0: TFloatSpinEdit;
    eLon1: TFloatSpinEdit;
    eLat1: TFloatSpinEdit;
    eLon0: TFloatSpinEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    GroupBox7: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    PageControl1: TPageControl;
    rbPolarAntarctic: TRadioButton;
    rbMercator: TRadioButton;
    rbPolarArctic: TRadioButton;
    rgAutomation: TRadioGroup;
    eStep: TSpinEdit;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;

    procedure btnOpenFolderClick(Sender: TObject);
    procedure btnOpenScriptClick(Sender: TObject);
    procedure btnOpenBLNClick(Sender: TObject);
    procedure btnGoogleClick(Sender: TObject);
    procedure btnSaveSectionClick(Sender: TObject);
    procedure cbClr1DropDown(Sender: TObject);
    procedure cbLvl1DropDown(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnPlotClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure GetSection(fname, par:string; g_max:real);
    procedure GroupBox6Click(Sender: TObject);
    procedure rgAutomationSelectionChanged(Sender: TObject);
    procedure RunSection;

  private
    { Private declarations }
    function FilterRecordCount(dataset : TDataset) : integer;
  public
    { Public declarations }
  end;

var
  frmsections: Tfrmsections;
  dat_f, out_f, fncsec, fncsecdat, fncbln1, fncbln2, fncmd:text;
  ncSectionsAuto:boolean=false;
  SecCDS:TBufDataSet;
  SectionPath:string;
  lat_arr, lon_arr, dep_arr : array of single;
  dist_arr : array of integer;

implementation

{$R *.lfm}

uses ncmain, declarations_netcdf, ncprocedures, surfer_settings,
     surfer_climsections, GibbsSeaWater, Bathymetry;

function Tfrmsections.FilterRecordCount(dataset : TDataset) : integer;
begin
  try
    result := 0;
    dataset.disablecontrols;
    dataset.first;
    while not dataset.eof do
    begin
       result := result + 1;
       dataset.next
    end;
  finally
    dataset.enablecontrols;
  end;
end;


procedure Tfrmsections.FormShow(Sender: TObject);
Var
  Ini:TIniFile;
begin
  cbVariable.Items := frmmain.cbVariables.items;

  if not DirectoryExists(GlobalUnloadPath+'sections'+PathDelim) then
         CreateDir(GlobalUnloadPath+'sections'+PathDelim);

  SectionPath:=GlobalUnloadPath+'sections'+PathDelim+ncname+PathDelim;

  if not DirectoryExists(SectionPath) then CreateDir(SectionPath);
  if not DirectoryExists(SectionPath+'png'+PathDelim) then CreateDir(SectionPath+'png'+PathDelim);
  if not DirectoryExists(SectionPath+'srf'+PathDelim) then CreateDir(SectionPath+'srf'+PathDelim);
  if not DirectoryExists(SectionPath+'dat'+PathDelim) then CreateDir(SectionPath+'dat'+PathDelim);
  if not DirectoryExists(SectionPath+'tmp'+PathDelim) then CreateDir(SectionPath+'tmp'+PathDelim);

  if (timevid>-1) and (timedid>-1) then begin
  cbDate.Items:= frmmain.cbDates.items;
  end else cbDate.Enabled:=false;

 Ini := TIniFile.Create(IniFileName);
 try
  ebln.Text          := Ini.ReadString('sections', 'coord',       '');
  cbLvl1.Text        := Ini.ReadString('sections', 'lvl',         '');
  cbclr1.Text        := Ini.ReadString('sections', 'clr',         '');
  chkPolar.Checked   := Ini.ReadBool  ('sections', 'polar',    false);
 finally
   Ini.Free;
 end;

 btnGoogle.Enabled:=CheckKml;
end;


procedure Tfrmsections.cbLvl1DropDown(Sender: TObject);
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


procedure Tfrmsections.cbClr1DropDown(Sender: TObject);
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


procedure Tfrmsections.btnPlotClick(Sender: TObject);
Var
  k, k_f, k_d:integer;
begin
 if not FileExists(ebln.Text) then
    if MessageDlg('File with coordinated does not exist', mtWarning, [mbOk], 0)=mrOk then exit;

  if rgAutomation.ItemIndex=0 then begin
     cleardir(sectionpath+'tmp'+PathDelim);
     RunSection;
  end;

  if rgAutomation.ItemIndex=1 then begin
   try
    ncSectionsAuto:=true;
    (* перебираем все выбранные nc файлы *)
     for k:=0 to frmmain.cbFiles.count-1 do begin
       ncName:=frmmain.cbFiles.Items.strings[k];
        for k_d:=0 to cbDate.Items.Count-1 do begin // Перебираем даты
         cbDate.ItemIndex:=k_d;
          cleardir(sectionpath+'tmp'+PathDelim);
          RunSection;
          // if cancel_fl=true then break;
        end; //конец перебора дат
       // if cancel_fl=true then break;
     end; // Конец перебора nc файлов
   finally
     ncSectionsAuto:=false;
     // cancel_fl:=false
   end;
 end;
end;


procedure Tfrmsections.RunSection;
Var
  Ini: TIniFile;
  k, i, c, stnum, col:integer;
  lt, ln, tp, fl, ll, d1:integer;

  par, st, lvl, clr, fcoord, ncexportfile, ncnorma, buf_str:string;
  dist_max, dist, gebco, g_max, g_first, dist_sum, x, y, z:real;
  diff_lat, diff_lon, latd, lond, kf_s:real;

  cdsBlankData: TBufDataSet;
  MinLev, MaxLev:real;
begin
par:=cbVariable.Text;

try
 btnPlot.Enabled       :=false;
 btnSettings.Enabled   :=false;
 btnOpenScript.Enabled :=false;
 btnOpenFolder.Enabled :=false;

// assign coord file, checking the size
fcoord:=ebln.Text; //section coordinates

stnum:=0;
AssignFile(fncsecdat, fcoord); reset(fncsecdat);

 readln(fncsecdat,st);
 buf_str:=''; i:=0;
 repeat
  inc(i);
   if st[i]<>',' then buf_str:=buf_str+st[i];
 until st[i]=',';
 stnum:=strtoint(buf_str);
CloseFile(fncsecdat);

 setlength(lat_arr,  stnum);  // minus title sting
 setlength(lon_arr,  stnum);
 setlength(dist_arr, stnum);
 setlength(dep_arr,  stnum);

 AssignFile(fncsecdat, fcoord); reset(fncsecdat);
 readln(fncsecdat, st); //skip the first line

 AssignFile(fncbln1, SectionPath+'tmp'+PathDelim+'depth.bln');  Rewrite(fncbln1);
 writeln(fncbln1, (50*(stnum-1)+4):5, 1:5);

 AssignFile(fncmd, SectionPath+'tmp'+PathDelim+'md.dat'); Rewrite(fncmd);
 writeln(fncmd, 'x':10,  'y':10, 'Lat':15, 'Lon':15, 'Lat_p':15, 'Lon_p':15, 'Depth':15, 'ID':10);


  k:=-1; dist_max:=0; g_max:=0; dist_max:=0;
  repeat
   inc(k);

     readln(fncsecdat, st);
     i:=0;
     for c:=1 to 2 do begin
      buf_str:='';
       repeat
        inc(i);
         if st[i]<>',' then buf_str:=buf_str+st[i];
       until st[i]=',';
       if c=1 then lon_arr[k]:=strtofloat(trim(buf_str));
       if c=2 then lat_arr[k]:=strtofloat(trim(buf_str));
     end;


   if chkPolar.Checked=true then begin
     x:=lon_arr[k];
     y:=lat_arr[k];

    if y=0 then begin
      if x<0 then lon_arr[k]:=-90 else lon_arr[k]:=90;
    end else begin
      if y>=0 then lon_arr[k]:=-180*ArcTan(x/y)/Pi+180 else lon_arr[k]:=-180*ArcTan(x/y)/Pi;
    end;
    if lon_arr[k]>180 then lon_arr[k]:=lon_arr[k]-360;
    lat_arr[k]:=2*(Pi/4-arcsin(sqrt(x*x+y*y)/2/6388.015))*180/Pi;
  end;

   Gebco:=-GetBathymetry(lon_arr[k],lat_arr[k]);
   dep_arr[k]:=gebco;

   if gebco>g_max then g_max:=gebco;

   if k=0 then begin
      dist_sum:=0;
      dist_arr[k]:=0;
      G_first:=Gebco;
        writeln(fncbln1,  0:10, gebco:10:3);
   end;

   if k>0 then begin
      Distance(lon_arr[k-1],lon_arr[k],lat_arr[k-1],lat_arr[k], dist);
      dist_arr[k]:=dist_arr[k-1]+round(dist);

      diff_lat:=abs(lat_arr[k]-lat_arr[k-1])/50;
      diff_lon:=abs(lon_arr[k]-lon_arr[k-1])/50;
      latd:=lat_arr[k-1]; Lond:=lon_arr[k-1];
       for d1:=1 to 50 do begin
        if lat_arr[k]>lat_arr[k-1] then latd:=latd+diff_lat else latd:=latd-diff_lat;
        if lon_arr[k]>lon_arr[k-1] then lond:=lond+diff_lon else lond:=lond-diff_lon;
         gebco:=-GetBathymetry(lond,latd);
          if gebco>g_max then g_max:=gebco;

         dist_sum:=dist_sum+(round(dist)/50);
        writeln(fncbln1, dist_sum:10:3, gebco:10:3);
       end;
   end;

       writeln(fncmd,dist_arr[k]:10,
                12:10,
                lat_arr[k]:15:5,
                lon_arr[k]:15:5,
                ((90- lat_arr[k])*111.12*sin((lon_arr[k])*Pi/180)):15:5,
                (-(90- lat_arr[k])*111.12*cos((lon_arr[k])*Pi/180)):15:5,
                gebco:15:3,
                k:10);

   if dist_arr[k]>dist_max then dist_max:=dist_arr[k];

  until eof(fncsecdat);
  Closefile(fncsecdat);
  CloseFile(fncmd);

    writeln(fncbln1, dist_sum:10:3, (g_max+(g_max/100)):10:3);
    writeln(fncbln1, 0:10, (g_max+(g_max/100)):10:3);
    writeln(fncbln1, 0:10, g_first:10:3);
  CloseFile(fncbln1);

 kf_s:=g_max/dist_max;


 fl:=1;  //!!!!!!!!!!!!


// showmessage('CDS');
try
   SecCDS:=TBufDataSet.Create(nil);
    with SecCDS.FieldDefs do begin
     Add('dist' ,ftInteger ,0 ,false);
     Add('stn'  ,ftInteger ,0 ,false);
     Add('lat'  ,ftFloat   ,0 ,false);
     Add('lon'  ,ftFloat   ,0 ,false);
     Add('lev'  ,ftFloat   ,0 ,false);
     Add('val1' ,ftFloat   ,0 ,false);
     Add('val2' ,ftFloat   ,0 ,false);
    end;
   SecCDS.CreateDataSet;

 //   showmessage('get section');

   GetSection(ncpath+ncname, cbVariable.Text, g_max);

   SecCDS.IndexFieldNames:='dist;lev';

 //   showmessage('done section');

 try
  // cds for top and bottom levels
   cdsBlankData:=TBufDataSet.Create(nil);
   with cdsBlankData.FieldDefs do begin
    Add('dist',ftFloat,0,true);
    Add('ulev',ftFloat,0,true);
    Add('dlev',ftFloat,0,true);
   end;
  cdsBlankData.CreateDataSet;

  for ll:=0 to high(dist_arr) do begin
   SecCDS.Filtered:=false;
   SecCDS.Filter:='Dist='+Inttostr(dist_arr[ll]);
   SecCDS.Filtered:=true;

   if FilterRecordCount(SecCDS)>0 then begin
    with cdsBlankData do begin
     Append;
      FieldByName('dist').AsFloat:=dist_arr[ll];
      SecCDS.First;
       FieldByName('ULev').AsFloat:=SecCDS.FieldByName('lev').AsFloat;
      SecCDS.Last;
       FieldByName('DLev').AsFloat:=SecCDS.FieldByName('lev').AsFloat;
     Post;
     end;

   //   showmessage('here0');

   AssignFile(fncbln2, SectionPath+'tmp'+PathDelim+'data.bln');  Rewrite(fncbln2);
   writeln(fncbln2,(cdsBlankData.RecordCount*2+1):12, 0:5);

   //1. последовательно верхние горизонты
   cdsBlankData.First;
   while not cdsBlankData.Eof do begin
    writeln(fncbln2,cdsBlankData.FieldByName('dist').AsInteger:12,
                    cdsBlankData.FieldByName('ULev').AsFloat:12:3);
    cdsBlankData.Next;
   end;

   //2. последние горизонты в обратном порядке
    cdsBlankData.Last;
    MinLev:=999; MaxLev:=-999;
   while not cdsBlankData.Bof do begin
    if cdsBlankData.FieldByName('DLev').AsFloat<MinLev then MinLev:=cdsBlankData.FieldByName('DLev').AsFloat;
    if cdsBlankData.FieldByName('DLev').AsFloat>MaxLev then MaxLev:=cdsBlankData.FieldByName('DLev').AsFloat;
     writeln(fncbln2,cdsBlankData.FieldByName('dist').AsInteger:12,
                     cdsBlankData.FieldByName('DLev').AsFloat:12:3);
    cdsBlankData.Prior;
   end;

    //3. первая станция верхний горизонт
    writeln(fncbln2,cdsBlankData.FieldByName('dist').AsInteger:12,
                    cdsBlankData.FieldByName('ULev').AsFloat:12:3);
    cdsBlankData.Last;
    closefile(fncbln2);
   end; // SecCDS isn't empty

  end;
  finally
    cdsBlankData.Free;
  end;

 // showmessage('done blank');


  ncexportfile:=copy(ExtractFileName(ebln.Text), 1, length(ExtractFileName(ebln.Text))-4)+'_'+
                copy(ExtractFileName(ncname),    1, length(ExtractFileName(ncname))-3);
 // file with data
 AssignFile(fncsec, SectionPath+'dat'+PathDelim+ncexportfile+'.dat'); Rewrite(fncsec);
 if fl=1 then writeln(fncsec, 'Dist_tr':10, 'Dist':10, 'Level':10, 'Value':10, 'STN':5, 'Latitude':10, 'Longitude':10);
 if fl=2 then writeln(fncsec, 'Dist_tr':10, 'Dist':10, 'Level':10, 'Value1':10, 'Value2':10, 'Anom':10);

 SecCDS.Filtered:=false;
 SecCDS.First;

 while not SecCDS.Eof do begin
 if fl=1 then writeln(fncsec,
                  (kf_s*SecCDS.FieldByName('Dist').AsFloat):10:2,
                  (SecCDS.FieldByName('Dist').AsInteger):10,
                  (SecCDS.FieldByName('Lev').AsFloat):10:2,
                  (SecCDS.FieldByName('Val1').AsFloat):10:3,
                  (SecCDS.FieldByName('stn').AsInteger):5,
                  (SecCDS.FieldByName('Lat').AsFloat):10:5,
                  (SecCDS.FieldByName('Lon').AsFloat):10:5);

 if fl=2 then writeln(fncsec,
                  (kf_s*SecCDS.FieldByName('Dist').AsFloat):10:2,
                  (SecCDS.FieldByName('Dist').AsInteger):10,
                  (SecCDS.FieldByName('Lev').AsFloat):10:2,
                  (SecCDS.FieldByName('Val1').AsFloat):10:3,
                  (SecCDS.FieldByName('Val2').AsFloat):10:3,
                  (SecCDS.FieldByName('Val1').AsFloat-
                   SecCDS.FieldByName('Val2').AsFloat):10:3,
                  (SecCDS.FieldByName('stn').AsInteger):5,
                  (SecCDS.FieldByName('Lat').AsFloat):10:5,
                  (SecCDS.FieldByName('Lon').AsFloat):10:5);
  SecCDS.Next;
 end;
 Closefile(fncsec);

finally
 SecCDS.Free;
end;


 if fl=1 then col:=4 else col:=6;

 if cblvl1.text<>'' then lvl:=GlobalSupportPath+'lvl'+PathDelim+cblvl1.text else lvl:='';
 if cbclr1.text<>'' then clr:=GlobalSupportPath+'clr'+PathDelim+cbclr1.text else clr:='';

// ncnorma:=Copy(ExtractFileName(eNorma.Text), 1, length(ExtractFileName(eNorma.Text))-3);
//   if chkAnomalies.Checked=true then ncexportfile:=ncexportfile+'_'+ncnorma;

 if chkPlot.Checked then begin
   GetClimSectionsScript(SectionPath, SectionPath+'dat'+
                         PathDelim+ncexportfile+'.dat', lvl , clr, kf_s,
                         (kf_s*dist_max), 100, 100, col, ncSectionsAuto,
                         ncexportfile, chkMap.Checked,
                         chkBlank.Checked);

   {$IFDEF Windows}
     frmmain.RunScript(2, '-x "'+SectionPath+'tmp'+PathDelim+'script.bas"', nil);
   {$ENDIF}
 end;
finally
 btnPlot.Enabled       :=true;
 btnSettings.Enabled   :=true;
 btnOpenScript.Enabled :=true;
 btnOpenFolder.Enabled :=true;
end;
end;


procedure Tfrmsections.GetSection(fname, par: string; g_max:real);
Var
  Ini:TIniFile;
  ll, lt_i, ln_i, a, pp:integer;
  status, ncid, varidp, ndimsp, varnattsp:integer;
  varxid, varyid, ll_max:integer;
  attname:    array of pAnsiChar;
  start, start2: PArraySize_t;

  vtype: nc_type;
  fp:array of single;
  sp:array of smallint;
  ip:array of integer;
  dp:array of double;


  val0, addscale, addoffset:variant;
  val1, lat1, lon1, lat_dif, lon_dif:real;
  scale, offset, missing: array [0..0] of single;
  scale_ex, offset_ex, missing_ex: boolean;
  str_lt, str_ln, py_path, st :string;
  yy, mn:integer;
begin
 if curve=false then begin
   lat_dif:=abs(nclat_arr[0]-nclat_arr[1]);
   lon_dif:=abs(nclon_arr[0]-nclon_arr[1]);
 end;
 if curve=true then begin
   lat_dif:=1;
   lon_dif:=1;
 end;

 try
   nc_open(pchar(fname), NC_NOWRITE, ncid);
   nc_inq_varid (ncid, pChar(par), varidp);
   nc_inq_varndims (ncid, varidp, ndimsp);  // dimentions quantity
   nc_inq_vartype  (ncid, varidp, vtype);   // variable type


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

    (* Если файл с криволинейными координатами - запрашиваем размерности из значения*)
   if curve=true then begin
      nc_inq_varid(ncid, pAnsiChar(AnsiString('nav_lon')), varxid); // longitude
      nc_inq_varid(ncid, pAnsiChar(AnsiString('nav_lat')), varyid); // latitude

      start2:=GetMemory(SizeOf(TArraySize_t)*2); // get memory for curvelinear coordinates
   end;

   SetLength(fp, 1);
   start:=GetMemory(SizeOf(TArraySize_t)*4); // get memory for start pointer

   start^[0]:=0; //time
   ll_max:=0;
   for ll:=0 to high(nclev_arr) do begin

   if ncLev_arr[ll]<=g_max then begin
    inc(ll_max);
    AssignFile(out_f, SectionPath+'tmp\'+inttostr(ll)+'.tmp'); rewrite(out_f);

    for pp:=0 to high(dist_arr) do begin //just taking data around the section coordinates
     for lt_i:=0 to high(nclat_arr) do begin //Latitude

      if ndimsp=2 then start^[0]:=lt_i;
      if ndimsp=3 then
        start^[1]:=lt_i;  //lat
      if ndimsp=4 then begin
       start^[1]:=ll;  //level
       start^[2]:=lt_i;  //lat
      end;

      for ln_i:=0 to high(nclon_arr) do begin  //Longitude
        if ndimsp=2 then start^[1]:=ln_i;
        if ndimsp=3 then start^[2]:=ln_i;
        if ndimsp=4 then start^[3]:=ln_i;

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

      if (lat1>=lat_arr[pp]-lat_dif*2) and (lat1<=lat_arr[pp]+lat_dif*2) and
         (lon1>=lon_arr[pp]-lon_dif*2) and (lon1<=lon_arr[pp]+lon_dif*2) then begin

        // showmessage('here');
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

       //   showmessage(floattostr(val0));

      if (val0<>missing[0]) and (val0<>-9999) then begin
       val1:=scale[0]*val0+offset[0]; // scale and offset from nc file

      // showmessage(floattostr(val1));

       addscale:=StrToFloat(eAddScale.Text);
       addoffset:=StrToFloat(eAddOffset.Text);

       val1:=addscale*val1+AddOffset;  // additional conversion
        writeln(out_f, lon1:9:5, #9, lat1:8:5, #9, val1:8:3);

      //  showmessage('end');
      end; //-9999

    end; //range of coordinates
   end; //lon
  end; //lat
 end; // section coordinates
 CloseFile(out_f);
 end; // GEBCO max
 end; //level

 FreeMemory(start);
 finally
  fp:=nil;
   status:=nc_close(ncid);  // Close file
    if status>0 then showmessage(pansichar(nc_strerror(status)));
 end;

   str_lt:=''; str_ln:='';
   for lt_i:=0 to high(lat_arr) do str_lt:=str_lt+Floattostr(lat_arr[lt_i])+',';
   for ln_i:=0 to high(lon_arr) do str_ln:=str_ln+Floattostr(lon_arr[ln_i])+',';

  AssignFile(out_f, SectionPath+'tmp\script.py'); rewrite(out_f);
   writeln(out_f, 'from scipy import interpolate');
   writeln(out_f, 'from numpy import array');
   writeln(out_f, 'import numpy as np');
   writeln(out_f, '');
   writeln(out_f, 'xi = array(['+copy(str_ln, 1, length(str_ln)-1)+'], dtype=np.float)');
   writeln(out_f, 'yi = array(['+copy(str_lt, 1, length(str_lt)-1)+'], dtype=np.float)');
   writeln(out_f, '');


   for a:=0 to ll_max-1 do begin
     writeln(out_f, 'x, y, z = np.loadtxt(r"'+SectionPath+'tmp\'+inttostr(a)+'.tmp").T');
     writeln(out_f, '');
     writeln(out_f, 'GD = interpolate.griddata((x, y), z, (xi, yi), method="linear")');
     writeln(out_f, '');
     writeln(out_f, 'f=open(r"'+SectionPath+'tmp\'+inttostr(a)+'.txt", "w")');
     writeln(out_f, 'np.savetxt(f, GD.T)');
     writeln(out_f, 'f.close()');
     writeln(out_f, '');
   end;
  CloseFile(out_f);

  // run script
  frmmain.RunScript(1, SectionPath+'tmp'+PathDelim+'script.py', nil);

 For pp:=0 to ll_max-1 do begin
  if FileExists(SectionPath+'tmp\'+inttostr(pp)+'.txt') then begin
   AssignFile(out_f, SectionPath+'tmp\'+inttostr(pp)+'.txt'); reset(out_f);
   a:=-1;
   repeat
    readln(out_f, st);
    inc(a);

    if (trim(st)<>'nan') and (nclev_arr[pp]<dep_arr[a]) then begin
      With SecCDS do begin
       Append;
        FieldByName('Dist').AsFloat:=dist_arr[a];
        FieldByName('stn').Asinteger:=a;
        FieldByName('Lat').AsFloat:=lat_arr[a];
        FieldByName('Lon').AsFloat:=lon_arr[a];
        FieldByName('Lev').AsFloat:=roundto(ncLev_arr[pp], -2);
        FieldByName('Val1').AsFloat:=strtofloat(trim(st));
       Post;
      end;
    end; // end if
   until eof(out_f);
   CloseFile(out_f);
   end;
 //  showmessage(inttostr(pp));
 end;
end;

procedure Tfrmsections.GroupBox6Click(Sender: TObject);
begin

end;

procedure Tfrmsections.rgAutomationSelectionChanged(Sender: TObject);
begin
 if rgAutomation.ItemIndex=0 then
    TabSheet2.Caption:='Automation: OFF' else
    TabSheet2.Caption:='Automation: ON';
end;


procedure Tfrmsections.btnSettingsClick(Sender: TObject);
begin
 frmSurferSettings := TfrmSurferSettings.Create(Self);
 frmSurferSettings.LoadSettings('climsections');
  try
   if not frmSurferSettings.ShowModal = mrOk then exit;
  finally
    frmSurferSettings.Free;
    frmSurferSettings := nil;
  end;
end;


procedure Tfrmsections.btnOpenFolderClick(Sender: TObject);
begin
   OpenDocument(PChar(SectionPath));
end;


procedure Tfrmsections.btnOpenScriptClick(Sender: TObject);
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
 ScriptFile:=ExtractFilePath(SectionPath)+'tmp'+PathDelim+'Script.bas';
 SysUtils.ExecuteProcess('"'+Scripter+'" "'+ScriptFile+'"', '', []);
end;


procedure Tfrmsections.btnOpenBLNClick(Sender: TObject);
begin
frmmain.OD.Filter:='bln|*.bln';
//frmmain.OD.InitialDir:=GlobalSupportPath+'sections\';
 if frmmain.OD.Execute then ebln.Text:=frmmain.OD.FileName;
end;


procedure Tfrmsections.btnGoogleClick(Sender: TObject);
Var
Ini:TIniFile;
f_out:text;
descr, coord, sep, st, buf_str: string;
dep, k, c, i:integer;
Lat1, Lon1, x, y :real;
begin

 try
  AssignFile(f_out, SectionPath+'tmp'+PathDelim+'stations.kml'); rewrite(f_out);
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
  Writeln(f_out, '      <color>#FF14F0FF</color>');
  Writeln(f_out, '      <scale>'+Ini.ReadString( 'GE',   'SymbolSize',    '1')+'</scale>');
  Writeln(f_out, '      <Icon><href>http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png</href></Icon>');
  Writeln(f_out, '    </IconStyle>');
  Writeln(f_out, '    <LabelStyle>');
  Writeln(f_out, '     <scale>0</scale>');
  Writeln(f_out, '    </LabelStyle>');
  Writeln(f_out, '   </Style>');

  sep:=' &lt;br/&gt;';

  AssignFile(fncsecdat, ebln.Text); reset(fncsecdat);
  readln(fncsecdat);//skip the first line
  k:=0;
  repeat
   inc(k);

     readln(fncsecdat, st);
     i:=0;
     for c:=1 to 2 do begin
      buf_str:='';
       repeat
        inc(i);
         if st[i]<>',' then buf_str:=buf_str+st[i];
       until st[i]=',';
       if c=1 then lon1:=strtofloat(trim(buf_str));
       if c=2 then lat1:=strtofloat(trim(buf_str));
     end;


   if chkPolar.Checked=true then begin
     x:=lon1;
     y:=lat1;

    if y=0 then begin
      if x<0 then lon1:=-90 else lon1:=90;
    end else begin
      if y>=0 then lon1:=-180*ArcTan(x/y)/Pi+180 else lon1:=-180*ArcTan(x/y)/Pi;
    end;
    if lon1>180 then lon1:=lon1-360;
    lat1:=2*(Pi/4-arcsin(sqrt(x*x+y*y)/2/6388.015))*180/Pi;
  end;


    dep:=GetBathymetry(Lon1, Lat1);
    descr:='Latitude = '  +FloattostrF(Lat1, fffixed, 8, 5) +sep+
           'Longitude = ' +FloattostrF(Lon1, fffixed, 9, 5) +sep+
           'Depth = '     +Inttostr(dep);

  coord:=Floattostr(Lon1)+', '+Floattostr(Lat1);

  Writeln(f_out, '   <Placemark>');
  Writeln(f_out, '    <name>'+inttostr(k)+'</name>');
  Writeln(f_out, '    <styleUrl>#hideLabel</styleUrl>');
  Writeln(f_out, '    <description>'+descr+'</description>');
  Writeln(f_out, '     <Point>');
  Writeln(f_out, '      <coordinates>'+coord+', 0</coordinates>');
  Writeln(f_out, '     </Point>');
  Writeln(f_out, '   </Placemark>');

  until eof(fncsecdat);
//  end;


 Finally
  Writeln(f_out, ' </Document>');
  Writeln(f_out, '</kml>');
  Closefile(f_out);
  Ini.free;
 end;
OpenDocument(PChar(SectionPath+'tmp'+PathDelim+'stations.kml'));
end;

procedure Tfrmsections.btnSaveSectionClick(Sender: TObject);
Var
  dat: text;
  k: integer;
  Lat0, Lon0, Lat1, Lon1, Lat, Lon, diff_lat, diff_lon:real;
begin
  if rbMercator.Checked=true then begin;
   Lat0:=eLat0.Value;
   Lon0:=eLon0.Value;
   Lat1:=eLat1.Value;
   Lon1:=eLon1.Value;
  end;

  if rbPolarArctic.Checked=true then begin
   Lon0:= (90-eLat0.Value)*111.12*sin((eLon0.Value)*Pi/180);
   Lat0:=-(90-eLat0.Value)*111.12*cos((eLon0.Value)*Pi/180);

   Lon1:= (90-eLat1.Value)*111.12*sin((eLon1.Value)*Pi/180);
   Lat1:=-(90-eLat1.Value)*111.12*cos((eLon1.Value)*Pi/180);
  end;

  if rbPolarAntarctic.Checked=true then begin
   //
  end;

 // frmmain.SD.InitialDir:=GlobalSupportPath+'sections'+PathDelim;
  frmmain.SD.Filter:='*.bln|*.bln';
  if frmmain.SD.Execute then begin
    AssignFile(dat, frmmain.SD.FileName); rewrite(dat);


    writeln(dat, inttostr(eStep.Value+1), ',1');
    writeln(dat, Floattostr(Lon0), ',', Floattostr(Lat0));

      diff_lat:=(Lat0-Lat1)/eStep.Value;
      diff_lon:=(Lon0-Lon1)/eStep.Value;

      Lat:=Lat0;
      Lon:=Lon0;

       for k:=1 to eStep.Value-1 do begin
        lat:=lat-diff_lat;
        lon:=lon-diff_lon;

        writeln(dat, Floattostr(lon), ',', Floattostr(lat));
       end;
     writeln(dat, Floattostr(Lon1), ',', Floattostr(Lat1));
    CloseFile(dat);
  end;
end;


procedure Tfrmsections.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
Var
 Ini:TIniFile;
begin
 //clean up the arrays
 lat_arr:=nil;
 lon_arr:=nil;
 dist_arr:=nil;

 // save settings
Ini := TIniFile.Create(IniFileName);
try
 Ini.WriteString ('sections', 'coord',    ebln.Text);
 Ini.WriteString ('sections', 'lvl',      cbLvl1.Text );
 Ini.WriteString ('sections', 'clr',      cbclr1.Text );
 Ini.WriteBool   ('sections', 'polar',    chkPolar.Checked);
finally
  Ini.Free;
end;
end;

end.
