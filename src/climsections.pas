unit climsections;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, IniFiles, BufDataSet, DB, Variants;

type

  { Tfrmclimsections }

  Tfrmclimsections = class(TForm)
    btnOpenFolder: TBitBtn;
    btnOpenNorma: TButton;
    btnOpenScript: TBitBtn;
    btnPlotAll: TButton;
    cbClr1: TComboBox;
    cbcoord: TComboBox;
    cbLvl1: TComboBox;
    chkAnomalies: TCheckBox;
    GroupBox1: TGroupBox;
    btnPlot: TButton;
    btnSettings: TButton;
    GroupBox2: TGroupBox;
    eNorma: TEdit;
    GroupBox4: TGroupBox;
    Label4: TLabel;
    Label9: TLabel;

    procedure btnOpenFolderClick(Sender: TObject);
    procedure btnOpenNormaClick(Sender: TObject);
    procedure btnOpenScriptClick(Sender: TObject);
    procedure btnPlotAllClick(Sender: TObject);
    procedure eNormaChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnPlotClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure GetSection(Fl:integer; fname, par:string);
    procedure RunSection;

  private
    { Private declarations }
    function FilterRecordCount(dataset : TDataset) : integer;
  public
    { Public declarations }
  end;

var
  frmclimsections: Tfrmclimsections;
  fncsec, fncsecdat, fncbln1, fncbln2, fncmd:text;
  SecCDS:TBufDataSet;
  ClimSectionPath, ClimSectionPar:string;
  lat_arr, lon_arr:array of single;
  dist_arr:array of integer;
  climsectionsauto:boolean=false;

implementation

{$R *.lfm}

uses ncmain, Bathymetry, surfer_settings, ncprocedures,
     surfer_climsections, declarations_netcdf;


function Tfrmclimsections.FilterRecordCount(dataset : TDataset) : integer;
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



procedure Tfrmclimsections.FormShow(Sender: TObject);
Var
  Ini:TIniFile;
  fdb:TSearchRec;
begin
 //global parameter
 if frmmain.cbVariables.Count=3 then
  ClimSectionPar:=frmmain.cbVariables.items.Strings[0] else
  ClimSectionPar:=frmmain.cbVariables.items.Strings[4];

  ClimSectionPath:=GlobalPath+'unload\sections\'+ncname+'\';
  if not DirectoryExists(ClimSectionPath) then CreateDir(ClimSectionPath);
  if not DirectoryExists(ClimSectionPath+'tmp\') then CreateDir(ClimSectionPath+'tmp\');
  if not DirectoryExists(ClimSectionPath+'png\') then CreateDir(ClimSectionPath+'png\');
  if not DirectoryExists(ClimSectionPath+'srf\') then CreateDir(ClimSectionPath+'srf\');

 (* загружаем список файлов с координатами разрезов*)
 fdb.Name:='';
  FindFirst(GlobalPath+'support\sections\climate\*.bln',faAnyFile, fdb);
   if fdb.name<>'' then cbcoord.Items.Add(copy(fdb.name, 1, length(fdb.name)-4));
    while FindNext(fdb)=0 do  cbcoord.Items.Add(copy(fdb.name, 1, length(fdb.name)-4));
  FindClose(fdb);
  if cbcoord.Items.Count<=20 then
     cbcoord.DropDownCount:=cbcoord.Items.Count else
     cbcoord.DropDownCount:=20;

  (* загружаем список *.lvl файлов *)
 fdb.Name:='';
  FindFirst(GlobalPath+'support\lvl\*.lvl',faAnyFile,fdb);
   if fdb.Name<>'' then cbLvl1.Items.Add(fdb.Name);
    while FindNext(fdb)=0 do cbLvl1.Items.Add(fdb.Name);
  FindClose(fdb);
  if cbLvl1.Items.Count=0 then cbLvl1.Enabled:=false;
  if cbLvl1.Items.Count<=20 then
     cbLvl1.DropDownCount:=cbLvl1.Items.Count else
     cbLvl1.DropDownCount:=20;

 (* загружаем список *.clr файлов *)
 fdb.Name:='';
  FindFirst(GlobalPath+'support\clr\*.clr',faAnyFile, fdb);
   if fdb.Name<>'' then cbclr1.Items.Add(fdb.Name);
    while FindNext(fdb)=0 do cbclr1.Items.Add(fdb.Name);
  FindClose(fdb);
 if cbclr1.Items.Count=0 then cbclr1.Enabled:=false;
 if cbclr1.Items.Count<=20 then
    cbclr1.DropDownCount:=cbclr1.Items.Count else
    cbclr1.DropDownCount:=20;

 Ini := TIniFile.Create(IniFileName);
 try
  eNorma.Text  := Ini.ReadString('climsections', 'norma', '');
  cbLvl1.Text  := Ini.ReadString('climsections', 'lvl',   '');
  cbclr1.Text  := Ini.ReadString('climsections', 'clr',   '');
  chkAnomalies.Checked := Ini.ReadBool   ('climsections', 'anom', true);
 finally
   Ini.Free;
 end;

 eNorma.OnChange(self);
end;


procedure Tfrmclimsections.btnPlotClick(Sender: TObject);
begin
 RunSection;
end;


procedure Tfrmclimsections.RunSection;
Var
  Ini: TIniFile;
  k, i, c, stnum, col:integer;
  lt, ln, tp, fl, ll, d1:integer;

  par, st, lvl, clr, fcoord, ncexportfile, ncnorma, buf_str:string;
  dist_max, dist, gebco, g_max, g_first, dist_sum:real;
  diff_lat, diff_lon, latd, lond, kf_s:real;

  cdsBlankData: TBufDataSet;
  MinLev, MaxLev:real;
begin
par:=ClimSectionPar;

 if eNorma.Text=ncpath+ncname then begin
  MessageDlg('The data file and the norma file are identical', mtWarning, [mbOk], 0);
  exit;
 end;

 if (chkAnomalies.Checked=true) and ((eNorma.Text='') or (eNorma.Font.Color=clred)) then begin
  MessageDlg('The norma file cannot be found', mtWarning, [mbOk], 0);
  exit;
 end;

try
 btnPlot.Enabled       :=false;
 btnSettings.Enabled   :=false;
 btnOpenScript.Enabled :=false;
 btnOpenFolder.Enabled :=false;
 btnPlotAll.Enabled    :=false;
 chkAnomalies.Enabled  :=false;

// assign coord file, checking the size
fcoord:=GlobalPath+'support\sections\climate\'+cbcoord.Text+'.bln'; //section coordinates

 stnum:=0;
 AssignFile(fncsecdat, fcoord); reset(fncsecdat);
 readln(fncsecdat,st);
 stnum:=StrToInt(Copy(st, 1, Pos(',', st)-1))-1;

 setlength(lat_arr,  stnum);  // minus title sting
 setlength(lon_arr,  stnum);
 setlength(dist_arr, stnum);

 AssignFile(fncbln1, ClimSectionPath+'tmp\depth.bln');  Rewrite(fncbln1);
 writeln(fncbln1, (50*(stnum)+4):5, 1:5);

 AssignFile(fncmd, ClimSectionPath+'tmp\md.dat'); Rewrite(fncmd);
 writeln(fncmd, 'x':10,  'y':10, 'Lat':15, 'Lon':15, 'Depth':15);


  k:=-1; dist_max:=0; g_max:=0;
  repeat
   inc(k);

   // reading coordinates
   readln(fncsecdat, st);

   lon_arr[k]:=StrToFloat(Copy(st, 1, Pos(',', st)-1));
   lat_arr[k]:=StrToFloat(Copy(st, Pos(',', st)+1, length(st)));

   Gebco:=-GetBathymetry(lon_arr[k],lat_arr[k]);
   if gebco>g_max then g_max:=gebco;

   if k=0 then begin
      dist_sum:=0;
      dist_arr[k]:=0;
      G_first:=Gebco;
    writeln(fncbln1,  0:10, -gebco:10:3);
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
        writeln(fncbln1, dist_sum:10:3, -gebco:10:3);
       end;
   end;

       writeln(fncmd,dist_arr[k]:10,
                12:10,
                lat_arr[k]:15:5,
                lon_arr[k]:15:5,
                -gebco:15:3);

   if dist_arr[k]>dist_max then dist_max:=dist_arr[k];

  until eof(fncsecdat);
  Closefile(fncsecdat);
  CloseFile(fncmd);

    writeln(fncbln1, dist_sum:10:3, -(g_max+(g_max/100)):10:3);
    writeln(fncbln1, 0:10, -(g_max+(g_max/100)):10:3);
    writeln(fncbln1, 0:10, -g_first:10:3);
  CloseFile(fncbln1);

 kf_s:=g_max/dist_max;

try
   SecCDS:=TBufDataSet.Create(nil);
    with SecCDS.FieldDefs do begin
     Add('dist' ,ftInteger ,0 ,false);
     Add('lev' , ftInteger ,0 ,false);
     Add('val1' ,ftFloat   ,0 ,false);
     Add('val2' ,ftFloat   ,0 ,false);
    end;
   SecCDS.CreateDataSet;
   SecCDS.IndexFieldNames:='dist;lev';

 GetSection(1, ncpath+ncname, par);

 if chkAnomalies.Checked=true then begin
  fl:=2;
  GetSection(2, enorma.Text, par);
 end else fl:=1;

 try
  // cds for top and bottom levels
   cdsBlankData:=TBufDataSet.Create(nil);
   with cdsBlankData.FieldDefs do begin
    Add('dist',ftFloat,0,true);
    Add('ulev',ftInteger,0,true);
    Add('dlev',ftInteger,0,true);
   end;
  cdsBlankData.CreateDataSet;

  for ll:=0 to high(dist_arr)+1 do begin
   SecCDS.Filtered:=false;
   SecCDS.Filter:='Dist='+Inttostr(dist_arr[ll]);
   SecCDS.Filtered:=true;

   if FilterRecordCount(SecCDS)>0 then begin
    with cdsBlankData do begin
     Append;
      FieldByName('dist').AsFloat:=dist_arr[ll];
      SecCDS.First;
       FieldByName('ULev').AsFloat:=SecCDS.FieldByName('lev').AsInteger;
      SecCDS.Last;
       FieldByName('DLev').AsFloat:=SecCDS.FieldByName('lev').AsInteger;
     Post;
     end;

   AssignFile(fncbln2, ClimSectionPath+'tmp\data.bln');  Rewrite(fncbln2);
   writeln(fncbln2,(cdsBlankData.RecordCount*2+1):12, 0:5);

   //1. последовательно верхние горизонты
   cdsBlankData.First;
   while not cdsBlankData.Eof do begin
    writeln(fncbln2,cdsBlankData.FieldByName('dist').AsInteger:12,
                    cdsBlankData.FieldByName('ULev').AsInteger:12);
    cdsBlankData.Next;
   end;

   //2. последние горизонты в обратном порядке
    cdsBlankData.Last;
    MinLev:=999; MaxLev:=-999;
   while not cdsBlankData.Bof do begin
    if cdsBlankData.FieldByName('DLev').AsInteger<MinLev then MinLev:=cdsBlankData.FieldByName('DLev').AsInteger;
    if cdsBlankData.FieldByName('DLev').AsInteger>MaxLev then MaxLev:=cdsBlankData.FieldByName('DLev').AsInteger;
     writeln(fncbln2,cdsBlankData.FieldByName('dist').AsInteger:12,
                     cdsBlankData.FieldByName('DLev').AsInteger:12);
    cdsBlankData.Prior;
   end;

    //3. первая станция верхний горизонт
    writeln(fncbln2,cdsBlankData.FieldByName('dist').AsInteger:12,
                    cdsBlankData.FieldByName('ULev').AsInteger:12);
    cdsBlankData.Last;
    closefile(fncbln2);
   end; // SecCDS isn't empty

  end;
  finally
    cdsBlankData.Free;
  end;


 // file with data
 AssignFile(fncsec, ClimSectionPath+'tmp\data.dat'); Rewrite(fncsec);
 if fl=1 then writeln(fncsec, 'Dist_tr':10, 'Dist':10, 'Level':10, 'Value':10);
 if fl=2 then writeln(fncsec, 'Dist_tr':10, 'Dist':10, 'Level':10, 'Value1':10, 'Value2':10, 'Anom':10);

 SecCDS.Filtered:=false; SecCDS.First;
 while not SecCDS.Eof do begin

 if fl=1 then writeln(fncsec,
                  (kf_s*SecCDS.FieldByName('Dist').AsFloat):10:2,
                  (SecCDS.FieldByName('Dist').AsInteger):10,
                  (SecCDS.FieldByName('Lev').AsInteger):10,
                  (SecCDS.FieldByName('Val1').AsFloat):10:3);

 if fl=2 then writeln(fncsec,
                  (kf_s*SecCDS.FieldByName('Dist').AsFloat):10:2,
                  (SecCDS.FieldByName('Dist').AsInteger):10,
                  (SecCDS.FieldByName('Lev').AsInteger):10,
                  (SecCDS.FieldByName('Val1').AsFloat):10:3,
                  (SecCDS.FieldByName('Val2').AsFloat):10:3,
                  (SecCDS.FieldByName('Val1').AsFloat-
                   SecCDS.FieldByName('Val2').AsFloat):10:3);

  SecCDS.Next;
 end;
finally
 Closefile(fncsec);
 SecCDS.Free;
end;


 if fl=1 then col:=4 else col:=6;

 if cblvl1.text<>'' then lvl:=GlobalPath+'support\lvl\'+cblvl1.text else lvl:='';
 if cbclr1.text<>'' then clr:=GlobalPath+'support\clr\'+cbclr1.text else clr:='';

 ncexportfile:=cbcoord.Text+'_'+copy(ncname, 1, length(ncname)-3);
 ncnorma:=Copy(ExtractFileName(eNorma.Text), 1, length(ExtractFileName(eNorma.Text))-3);
   if chkAnomalies.Checked=true then ncexportfile:=ncexportfile+'_'+ncnorma;

 GetClimSectionsScript(ClimSectionPath, ClimSectionPath+'tmp\data.dat', lvl , clr, kf_s, (kf_s*dist_max),
 100, 100, col, climsectionsauto, ncexportfile, false, false, true);

   {$IFDEF Windows}
     frmmain.RunScript(2, '-x "'+ClimSectionPath+'tmp'+PathDelim+'script.bas"', nil);
   {$ENDIF}

finally
 btnPlot.Enabled       :=true;
 btnSettings.Enabled   :=true;
 btnOpenScript.Enabled :=true;
 btnOpenFolder.Enabled :=true;
 btnPlotAll.Enabled    :=true;
 chkAnomalies.Enabled  :=true;
end;
end;


procedure Tfrmclimsections.GetSection(Fl:integer; fname, par: string);
Var
  Ini:TIniFile;
  k_d, ll:integer;
  status, ncid, varidp, varidp2, ndimsp:integer;
  start: PArraySize_t;
  fp:array of single;
  val0, val_err:variant;
  val1, firstval1:real;
  LVar:array[0..1] of Variant;
  RelErr:real;
  UseRE:boolean;
begin

 try
  Ini := TIniFile.Create(IniFileName);
  RelErr:=Ini.ReadFloat('main', 'RelativeError',    25E-2);
  UseRE :=Ini.ReadBool ('main', 'UseRelativeError', true);
 finally
   ini.Free;
 end;

try
 (* nc_open*)
   status:=nc_open(pchar(fname), NC_NOWRITE, ncid); // only for reading
    if status>0 then showmessage(pansichar(nc_strerror(status)));

   nc_inq_varid (ncid, pChar(par), varidp);
   nc_inq_varid (ncid, pChar(par+'_relerr'), varidp2);

   SetLength(fp, 1);
   start:=GetMemory(SizeOf(TArraySize_t)*4); // get memory for start pointer

   start^[0]:=0; //time
   for k_d:=0 to high(dist_arr)+1 do begin
    start^[2]:=GetLatIndex(Lat_arr[k_d]);
    start^[3]:=GetLonIndex(Lon_arr[k_d]);

     for ll:=0 to high(ncLev_arr) do begin
      start^[1]:=ll;  //level

      SetLength(fp, 1);
       nc_get_var1_float(ncid, varidp, start^, fp);
      Val1:=fp[0];

      SetLength(fp, 1);
       nc_get_var1_float(ncid, varidp2, start^, fp);
      Val_err:=fp[0];

      if (val1<>-9999) then begin
      if  (UseRE=false) or
         ((UseRE=true) and (val_err<=RelErr)) then begin

         (* для температуры ниже -1.8 *)
       if (par='Temperature') and (val1<-1.8) then Val1:=-1.99;

        if fl=1 then begin
         With SecCDS do begin
          Append;
           FieldByName('Dist').AsFloat:=dist_arr[k_d];
           FieldByName('Lev').AsInteger:=trunc(-ncLev_arr[ll]);
           FieldByName('Val1').AsFloat:=val1;
          Post;
         end;
        end; //fl=1

        if fl=2 then begin
         LVar[0]:=dist_arr[k_d];
         LVar[1]:=-ncLev_arr[ll];
         if not VarIsNull(SecCDS.Locate('dist;lev', VarArrayOf(LVar), [locaseinsensitive])) then begin
          With SecCDS do begin
           Edit;
            FieldByName('Val2').AsFloat:=val1;
           Post;
          end; //post
         end; //not null
        end; //fl=2
       end; //0.25
      end; // val<>-9999
    end; //ll
   end;
 FreeMemory(start);

 finally
  fp:=nil;
   status:=nc_close(ncid);  // Close file
    if status>0 then showmessage(pansichar(nc_strerror(status)));
 end;
end;


procedure Tfrmclimsections.btnSettingsClick(Sender: TObject);
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


procedure Tfrmclimsections.btnOpenFolderClick(Sender: TObject);
begin
   OpenDocument(PChar(ClimSectionPath));
end;


procedure Tfrmclimsections.btnOpenScriptClick(Sender: TObject);
Var
ScriptFile:string;
begin
 ScriptFile:=ClimSectionPath+'tmp\script.bas';
  if FileExists(ScriptFile) then OpenDocument(PChar(ScriptFile));
end;

procedure Tfrmclimsections.btnPlotAllClick(Sender: TObject);
Var
 k_f:integer;
begin
climsectionsauto:=true;

(* перебираем все выбранные nc файлы *)
 For k_f:=0 to frmmain.cbFiles.Count-1 do begin
  ncName:=frmmain.cbFiles.Items.Strings[k_f];
   RunSection;
 end; // Конец перебора nc файлов

 climsectionsauto:=false;
end;


procedure Tfrmclimsections.eNormaChange(Sender: TObject);
begin
  if FileExists(eNorma.Text) then eNorma.Font.Color:=clGreen else eNorma.Font.Color:=clRed;
end;


procedure Tfrmclimsections.btnOpenNormaClick(Sender: TObject);
begin
 frmmain.OD.Filter:='NetCDF|*.nc'; ;
 if frmmain.OD.Execute then begin
   eNorma.Text:=frmmain.OD.FileName;
   eNorma.Font.Color:=clgreen;
 end;
end;


procedure Tfrmclimsections.FormClose(Sender: TObject;
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
 Ini.WriteString ('climsections', 'norma', eNorma.Text );
 Ini.WriteString ('climsections', 'coord', cbcoord.Text);
 Ini.WriteString ('climsections', 'lvl',   cbLvl1.Text );
 Ini.WriteString ('climsections', 'clr',   cbclr1.Text );
 Ini.WriteBool   ('climsections', 'anom',  chkAnomalies.Checked);
finally
  Ini.Free;
end;
end;

end.
