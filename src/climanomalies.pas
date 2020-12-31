unit climanomalies;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, Buttons, ComCtrls, ExtCtrls, CheckLst,
  FileUtil, DB, IniFiles, BufDataset;

type

  { Tfrmclimanomalies }

  Tfrmclimanomalies = class(TForm)
    btnOpenFolder: TBitBtn;
    btnOpenScript: TBitBtn;
    btnSettings: TButton;
    btnNorma: TButton;
    btnPlot: TButton;
    cbClr1: TComboBox;
    cbLvl1: TComboBox;
    cgLevels: TCheckListBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label9: TLabel;
    lbVariable1: TLabel;
    lbVariable2: TLabel;
    rgProjection: TRadioGroup;

    procedure cbClr1DropDown(Sender: TObject);
    procedure cbLvl1DropDown(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnOpenFolderClick(Sender: TObject);
    procedure btnOpenScriptClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure btnNormaClick(Sender: TObject);
    procedure btnPlotClick(Sender: TObject);
    procedure Label2Click(Sender: TObject);

  private
    { Private declarations }
    procedure GetField1(lev:integer);
    procedure GetField2(lev:integer);
  public
    { Public declarations }
  end;

var
  frmclimanomalies: Tfrmclimanomalies;
  ncAnName2, ncanFieldPath:string;
  ncAnCDS:TBufDataSet;
  fdat:text;

implementation

{$R *.lfm}

uses ncmain, ncprocedures, surfer_settings, surfer_ncfields, declarations_netcdf;


procedure Tfrmclimanomalies.FormShow(Sender: TObject);
Var
fdb:TSearchRec;
begin
 if frmmain.cbVariables.Count=3 then
 lbVariable1.Caption := frmmain.cbVariables.items.Strings[0] else
 lbVariable1.Caption := frmmain.cbVariables.items.Strings[4];

 if frmmain.cbLevels.Count>0 then begin
   cgLevels.Items  := frmmain.cbLevels.items;
 end;

 (* загружаем список *.lvl файлов *)
  cbLvl1.onDropDown(self);
  if cbLvl1.Items.Count=0 then cbLvl1.Enabled:=false;

 (* загружаем список *.clr файлов *)
  cbClr1.onDropDown(self);
  if cbclr1.Items.Count=0 then cbclr1.Enabled:=false;

  if not DirectoryExists(GlobalPath+'unload'+PathDelim+'anomalies'+PathDelim) then
    CreateDir(GlobalPath+'unload'+PathDelim+'anomalies'+PathDelim);

  ncanFieldPath:=GlobalPath+'unload\anomalies\';
  if not DirectoryExists(ncanFieldPath+'png\') then CreateDir(ncanFieldPath+'png\');
  if not DirectoryExists(ncanFieldPath+'srf\') then CreateDir(ncanFieldPath+'srf\');
end;

procedure Tfrmclimanomalies.cbLvl1DropDown(Sender: TObject);
Var
fdb:TSearchRec;
begin
fdb.Name:='';
cblvl1.Clear;
 FindFirst(GlobalPath+'support\lvl\*.lvl',faAnyFile, fdb);
  if fdb.Name<>'' then begin
    cbLvl1.Items.Add(ExtractFileName(fdb.Name));
     while findnext(fdb)=0 do cbLvl1.Items.Add(ExtractFileName(fdb.Name));
  end;
 FindClose(fdb);
end;


procedure Tfrmclimanomalies.cbClr1DropDown(Sender: TObject);
Var
fdb:TSearchRec;
begin
fdb.Name:='';
cbclr1.Clear;
 FindFirst(GlobalPath+'support\clr\*.clr',faAnyFile, fdb);
  if fdb.Name<>'' then begin
    cbclr1.Items.Add(ExtractFileName(fdb.Name));
     while findnext(fdb)=0 do cbclr1.Items.Add(ExtractFileName(fdb.Name));
  end;
 FindClose(fdb);
end;


procedure Tfrmclimanomalies.btnPlotClick(Sender: TObject);
Var
 klev, k_f:integer;
 Lat, Lon, val1, val2:real;
 lvl1, clr1, ncExportFile, lev_str, basemap2, levstr_val:string;
 contour, src1, grd1:string;
 XMin, XMax, YMin, YMax, x, y: real;
 ncols, nrows:integer;
begin
  btnOpenFolder.Enabled:=false;
  btnOpenScript.Enabled:=false;
  btnSettings.Enabled:=false;
  btnPlot.Enabled:=false;
  Application.ProcessMessages;

  if (cbLvl1.ItemIndex>-1) then Lvl1:=GlobalPath+'support\lvl\'+cbLvl1.Text else Lvl1:='';
  if (cbclr1.ItemIndex>-1) then clr1:=GlobalPath+'support\clr\'+cbclr1.Text else clr1:='';

try
(* перебираем все выбранные nc файлы *)
 for k_f:=0 to frmmain.cbFiles.Count-1 do begin
  ncName:=frmmain.cbFiles.Items.Strings[k_f];

  for klev:=0 to cgLevels.Items.Count-1 do begin
   if cgLevels.Checked[klev] then begin //checked level

   if length(cgLevels.Items.Strings[klev])=1 then lev_str:='000'+cgLevels.Items.Strings[klev];
   if length(cgLevels.Items.Strings[klev])=2 then lev_str:='00'+cgLevels.Items.Strings[klev];
   if length(cgLevels.Items.Strings[klev])=3 then lev_str:='0'+cgLevels.Items.Strings[klev];
   if length(cgLevels.Items.Strings[klev])=4 then lev_str:=cgLevels.Items.Strings[klev];

 // t_20002012_19002012_0000.png
  ncExportfile:=LowerCase(copy(ncName, 1, 1))+'_'+
  copy(ncName,   Pos('.', ncName)+1, 8)+'_'+
  copy(ncAnName2,Pos('.', ncAnName2)+1, 8)+'_'+
  lev_str;


  if (StrToInt(cgLevels.Items.Strings[klev])=0) then levstr_val:='0000_0000';
  if (StrToInt(cgLevels.Items.Strings[klev])>=10)   and (StrToInt(cgLevels.Items.Strings[klev])<=50)    then levstr_val:='0010_0050';
  if (StrToInt(cgLevels.Items.Strings[klev])>=75)   and (StrToInt(cgLevels.Items.Strings[klev])<=800)   then levstr_val:='0075_0800';
  if (StrToInt(cgLevels.Items.Strings[klev])>=900)   then levstr_val:='0900_3500';
  lvl1:=GlobalPath+'support\lvl\anom\'+levstr_val+'.lvl';
  clr1:=GlobalPath+'support\clr\anom\'+levstr_val+'.clr';


  ncAnCDS:=TBufDataSet.Create(nil);
   with ncAnCDS.FieldDefs do begin
    Add('Lat',  ftFloat, 0, false);
    Add('Lon',  ftFloat, 0, false);
    Add('Val1', ftFloat, 0, false);
    Add('Val2', ftFloat, 0, false);
   end;
  ncAnCDS.CreateDataSet;

     GetField1(klev); // вытаскиваем первое поле, пишем в CDS
     GetField2(klev); // вытаскиваем второе поле

     AssignFile(fdat, ncanFieldPath+ncExportFile+'.dat'); rewrite(fdat);

     ncAnCDS.first;
      while not ncAnCDS.eof do begin
       lat := ncAnCDS.FieldByName('Lat').AsFloat;
       lon := ncAnCDS.FieldByName('Lon').AsFloat;
       val1:= ncAnCDS.FieldByName('Val1').AsFloat;

        if not VarIsNull(ncAnCDS.FieldByName('Val2').AsVariant) then begin
         val2:= ncAnCDS.FieldByName('Val2').AsFloat;

          if rgProjection.ItemIndex<2 then begin
            x:= (90-Lat)*111.12*sin((Lon)*Pi/180);
            y:=-(90-Lat)*111.12*cos((Lon)*Pi/180);
          end;
          if rgProjection.ItemIndex=2 then begin
            x:=(Lat+90)*sin((Lon)*pi/180);
            y:=(Lat+90)*cos((Lon)*pi/180);
          end;

         writeln(fdat, Lat:9:5, Lon:11:5, y:13:5, x:13:5, val1-val2:13:5);
        end;
     ncAnCDS.Next;
    end;
    CloseFile(fdat);
    ncAnCDS.Free;

    (* Nordic Seas *)
    if (ncLat_arr[high(ncLat_arr)]=83.75) and
       (ncLat_arr[low (ncLat_arr)]=58)    and
       (ncLon_arr[high(ncLon_arr)]=71.75) and
       (ncLon_arr[low (ncLon_arr)]=-47)   then begin
      basemap2:=GlobalPath+'support\bln\NS_'+lev_str+'.bln';
      contour:=lowercase(GlobalPath+'support\bln\NordicSeas.bln');

      XMin:=-45;
      XMax:=70;
      YMin:=60;
      YMax:=82;
    end;


    (* Labrador *)
    if (ncLat_arr[high(ncLat_arr)]= 82) and
       (ncLat_arr[low (ncLat_arr)]= 50) and
       (ncLon_arr[high(ncLon_arr)]= 70) and
       (ncLon_arr[low (ncLon_arr)]=-80) then begin
      basemap2:=GlobalPath+'support\bln\labrador_'+lev_str+'.bln';
      contour:=lowercase(GlobalPath+'support\bln\World.bln');

      XMin:=-80;
      XMax:=70;
      YMin:=50;
      YMax:=82;
    end;

    ncols:=high(ncLon_arr)+1;
    nrows:=high(ncLat_arr)+1;

    src1:= ncanFieldPath+ncExportFile+'.dat';
    grd1:= ncanFieldPath+ncExportFile+'.grd';

    GetncFieldScript(ncanFieldPath, src1 , '', '', grd1, '', '', lvl1, clr1,
                     contour, basemap2, ncols, nrows, true, XMin, XMax, YMin,
                     YMax, ncExportFile, false, rgProjection.ItemIndex,
                     '', false, curve);

   {$IFDEF Windows}
     frmmain.RunScript(2, '"'+ncanFieldPath+'tmp'+PathDelim+'script.bas"', nil);
   {$ENDIF}

   end; // end of checked level
  end; // end of levels loop
 end; // Конец перебора nc файлов

finally
 btnOpenFolder.Enabled:=true;
 btnOpenScript.Enabled:=true;
 btnSettings.Enabled:=true;
 btnPlot.Enabled:=true;
end;
end;


(* извлекаем данные первого поля *)
procedure Tfrmclimanomalies.GetField1(lev:integer);
Var
 Ini:TIniFile;
 RelErr:real;
 UseRE:boolean;

 lt_i, ln_i:integer;
 status, ncid, varidp, varidp2, varidp3:integer;
 start: PArraySize_t;
 va, ve, vr:array of single;
 val0, vale, valr:real;
 par:string;
begin
try
  par:=lbVariable1.Caption;

  try
   Ini := TIniFile.Create(IniFileName);
   RelErr:=Ini.ReadFloat('main', 'RelativeError',    0.25);
   UseRE :=Ini.ReadBool ('main', 'UseRelativeError', true);
  finally
    ini.Free;
  end;

  (* nc_open*)
   nc_open(pchar(ncpath+ncname), NC_NOWRITE, ncid); // only for reading

   nc_inq_varid (ncid, pchar(par), varidp); // variable ID
   nc_inq_varid (ncid, pchar(par+'_err'), varidp2); // variable 2 ID
   nc_inq_varid (ncid, pchar(par+'_relerr'), varidp3); // variable 2 ID

   start:=GetMemory(SizeOf(TArraySize_t)*4); // get memory for start pointer

   start^[0]:=0; //time
   start^[1]:=lev;  //level
    for lt_i:=0 to high(ncLat_arr) do begin
     start^[2]:=lt_i;  //lat
     for ln_i:=0 to high(ncLon_arr) do begin
      start^[3]:=ln_i; //lon

       SetLength(va, 1);
        nc_get_var1_float(ncid, varidp, start^, va);
       Val0:=va[0];

       SetLength(ve, 1);
        nc_get_var1_float(ncid, varidp2, start^, ve);
       Vale:=ve[0];

       SetLength(vr, 1);
        nc_get_var1_float(ncid, varidp3, start^, vr);
       Valr:=vr[0];

         if (val0<>-9999) then begin
            if  (UseRE=false) or
               ((UseRE=true) and (valr<=RelErr)) then begin
          (* для температуры ниже -1.8 *)
           if (par='Temperature') and (val0>-9999) and (val0<-1.8) then Val0:=-1.99;
              ncAnCDS.Append;
                ncAnCDS.FieldByName('Lat').AsFloat:=ncLat_arr[lt_i];
                ncAnCDS.FieldByName('Lon').AsFloat:=ncLon_arr[ln_i];
                ncAnCDS.FieldByName('Val1').AsFloat:=val0;
               ncAnCDS.Post;
              ncAnCDS.Next;
          end;
         end;

     end;
   end;
  FreeMemory(start);
 finally
  va:=nil;
  ve:=nil;
  vr:=nil;
  nc_close(ncid);  // Close file
 end;
end;



(* извлекаем данные второго поля *)
procedure Tfrmclimanomalies.GetField2(lev:integer);
Var
 Ini:TIniFile;
 RelErr:real;
 UseRE:boolean;

 lt_i, ln_i:integer;
 status, ncid, varidp, varidp2, varidp3:integer;
 start: PArraySize_t;
 va, ve, vr:array of single;
 val0, vale, valr:real;
 par:string;
 LVar:array[0..1] of Variant;
begin
try
  par:=lbVariable1.Caption;

  try
   Ini := TIniFile.Create(IniFileName);
   RelErr:=Ini.ReadFloat('main', 'RelativeError',    0.25);
   UseRE :=Ini.ReadBool ('main', 'UseRelativeError', true);
  finally
    ini.Free;
  end;


  (* nc_open*)
   nc_open(pchar(ncAnName2), NC_NOWRITE, ncid); // only for reading

   nc_inq_varid (ncid, pchar(par), varidp); // variable ID
   nc_inq_varid (ncid, pchar(par+'_err'), varidp2); // variable 2 ID
   nc_inq_varid (ncid, pchar(par+'_relerr'), varidp3); // variable 2 ID

   start:=GetMemory(SizeOf(TArraySize_t)*4); // get memory for start pointer

   start^[0]:=0; //time
   start^[1]:=lev;  //level
    for lt_i:=0 to high(ncLat_arr) do begin
     start^[2]:=lt_i;  //lat
     for ln_i:=0 to high(ncLon_arr) do begin
      start^[3]:=ln_i; //lon

       SetLength(va, 1);
        nc_get_var1_float(ncid, varidp, start^, va);
       Val0:=va[0];

       SetLength(ve, 1);
        nc_get_var1_float(ncid, varidp2, start^, ve);
       Vale:=ve[0];

       SetLength(vr, 1);
        nc_get_var1_float(ncid, varidp3, start^, vr);
       Valr:=vr[0];

       if (val0<>-9999) then begin
          if  (UseRE=false) or
             ((UseRE=true) and (valr<=RelErr)) then begin
          (* для температуры ниже -1.8 *)
           if (par='Temperature') and (val0>-9999) and (val0<-1.8) then Val0:=-1.99;
             LVar[0]:=ncLat_arr[lt_i];
             LVar[1]:=ncLon_arr[ln_i];


              if not VarIsNull(ncAnCDS.Locate('lat;lon', VarArrayOf(LVar), []))=true then begin
                   ncAnCDS.Edit;
                    ncAnCDS.FieldByName('Val2').AsFloat:=val0;
                   ncAnCDS.Post;
              end;
          end;
         end;


     end;
   end;
  FreeMemory(start);

 finally
  va:=nil;
  ve:=nil;
  vr:=nil;
  nc_close(ncid);  // Close file
 end;
end;



// Открываем второй netcdf
procedure Tfrmclimanomalies.btnNormaClick(Sender: TObject);
Var
 Ini:TIniFile;
begin
 Ini := TIniFile.Create(IniFileName);
  try
   frmmain.OD.InitialDir:=Ini.ReadString( 'NetCDF', 'AnomaliesMainPath', ExtractFilePath(Application.ExeName));
  finally
    Ini.Free;
  end;

 frmmain.OD.Filter:='NetCDF|*.nc';
 if frmmain.OD.Execute then begin
  ncAnName2:=frmmain.OD.FileName;

  Ini := TIniFile.Create(IniFileName);
  try
   Ini.WriteString( 'NetCDF', 'AnomaliesMainPath', ExtractFilePath(frmmain.OD.FileName));
  finally
    Ini.Free;
  end;

 end;

 GetHeader(ncAnName2, 1);

 lbVariable2.Caption := ExtractFileName(frmmain.OD.FileName);
 lbVariable2.Visible:=true;
 btnPlot.Enabled:=true;
end;


procedure Tfrmclimanomalies.btnSettingsClick(Sender: TObject);
begin
  frmSurferSettings := TfrmSurferSettings.Create(Self);
  frmSurferSettings.LoadSettings('ncfields');
   try
    if not frmSurferSettings.ShowModal = mrOk then exit;
   finally
     frmSurferSettings.Free;
     frmSurferSettings := nil;
   end;
end;


procedure Tfrmclimanomalies.btnOpenFolderClick(Sender: TObject);
begin
  OpenDocument(PChar(ncanFieldPath));
end;


procedure Tfrmclimanomalies.btnOpenScriptClick(Sender: TObject);
Var
  ScriptFile:string;
begin
 ScriptFile:=ExtractFilePath(ncanFieldPath)+'Script.bas';
  if FileExists(ScriptFile) then OpenDocument(PChar(ScriptFile));
end;


procedure Tfrmclimanomalies.Label2Click(Sender: TObject);
Var
  k:integer;
  chk:boolean;
begin
  chk:=not cgLevels.Checked[0];
  For k:=0 to cgLevels.Items.Count-1 do cgLevels.Checked[k]:=chk;
end;


end.
