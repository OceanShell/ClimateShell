unit ncfields;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, ComCtrls, ExtCtrls, Spin, CheckLst, Variants, IniFiles, declarations_netcdf,
  dateutils, Math;

type

  { Tfrmfields }

  Tfrmfields = class(TForm)
    btnOpenFolder: TBitBtn;
    btnOpenScript: TBitBtn;
    btnGetData: TButton;
    btnCancel: TButton;
    btnAutomation: TButton;
    btnSettings: TButton;
    btnPlot: TButton;
    cbClr1: TComboBox;
    cbDate: TComboBox;
    cbLevel: TComboBox;
    cbLvl1: TComboBox;
    cbVariable: TComboBox;
    cbU: TComboBox;
    cbV: TComboBox;
    chkIce: TCheckBox;
    chkPlot: TCheckBox;
    chklSelLev: TCheckListBox;
    eAdditionalOffset: TFloatSpinEdit;
    eAdditionalScale: TFloatSpinEdit;
    eMaxLon: TFloatSpinEdit;
    eMinLon: TFloatSpinEdit;
    eMinLat: TFloatSpinEdit;
    eMaxLat: TFloatSpinEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    Label11: TLabel;
    Label12: TLabel;
    Label2: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    PageControl1: TPageControl;
    pcFieldType: TPageControl;
    rgAutomation: TRadioGroup;
    rgProjection: TRadioGroup;
    semn: TSpinEdit;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheet5: TTabSheet;

    procedure btnAutomationClick(Sender: TObject);
    procedure btnPlotClick(Sender: TObject);
    procedure cbVariableSelect(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnOpenFolderClick(Sender: TObject);
    procedure btnOpenScriptClick(Sender: TObject);
    procedure btnGetDataClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure cbClr1DropDown(Sender: TObject);
    procedure cbLvl1DropDown(Sender: TObject);
    procedure chkpolarClick(Sender: TObject);
    procedure rgAutomationClick(Sender: TObject);
    procedure rgProjectionClick(Sender: TObject);

  private
    { private declarations }
    procedure RunField;
    procedure SaveSettings;
  public
    { public declarations }
    procedure GetField(fname, par:string; addscale, addoffset, LatMin, LatMax,
                       LonMin, LonMax:real; Var ncols, nrows:size_t);
  end;

var
  frmfields: Tfrmfields;
  ncFieldPath, IceEdgePath:string;
  f_dat, dat1, dat2:text;
  ncFieldsAuto:boolean=false;
  ncols, nrows:size_t;
  Cancel_fl:boolean=false;

implementation

{$R *.lfm}

{ Tfrmfields }

uses ncmain, surfer_settings, surfer_ncfields, nciceedge,
     GibbsSeaWater;

procedure Tfrmfields.FormShow(Sender: TObject);
Var
  Ini: TIniFile;
begin
{$IFDEF UNIX}
   chkPlot.Checked:=false;
{$ENDIF}

 cbVariable.Items  := frmmain.cbVariables.items;
 cbU.Items         := frmmain.cbVariables.items;
 cbV.Items         := frmmain.cbVariables.items;
 cbLevel.Items     := frmmain.cbLevels.items;
 chklSelLev.Items  := frmmain.cbLevels.items;

 if cblevel.Items.Count=0 then cblevel.Enabled:=false;

 if not DirectoryExists(GlobalUnloadPath+'fields'+PathDelim) then
        CreateDir(GlobalUnloadPath+'fields'+PathDelim);

 ncFieldPath:=GlobalUnloadPath+'fields'+PathDelim+ncname+PathDelim;

(* загружаем список *.lvl файлов *)
  cbLvl1.onDropDown(self);
  if cbLvl1.Items.Count=0 then cbLvl1.Enabled:=false;

 (* загружаем список *.clr файлов *)
  cbClr1.onDropDown(self);
  if cbclr1.Items.Count=0 then cbclr1.Enabled:=false;

 if (timevid>-1) and (timedid>-1) then begin
  cbDate.Items:= frmmain.cbDates.items;
  end else cbDate.Enabled:=false;

 Ini := TIniFile.Create(IniFileName);
 try
  rgProjection.ItemIndex := Ini.ReadInteger('ncfields', 'Projection', 0);
 finally
   Ini.Free;
 end;

 with rgAutomation do begin
   Items.add(SAutoAllFilesDatesLevels);
   Items.add(SSelectedFileLevelAllDates);
   Items.add(SSelectedFileDateAllLevels);
   Items.add(SAllFilesDatesSelectedLevel);
   Items.add(SSelectedFileLevelMonth);
   Items.add(SAllFilesSelectedDateLevels);
   ItemIndex:=0;
 end;

 rgProjection.OnClick(self);
 chkIce.Enabled:=FileExists(GlobalSupportPath+'ice'+PathDelim+'HadISST_ice.nc');
end;


procedure Tfrmfields.cbVariableSelect(Sender: TObject);
begin

end;


procedure Tfrmfields.SaveSettings;
Var
  Ini:TIniFile;
begin
 Ini := TIniFile.Create(IniFileName);
 try
  Ini.WriteInteger('ncfields', 'Projection', rgProjection.ItemIndex);
 finally
   Ini.Free;
 end;
end;


procedure Tfrmfields.cbLvl1DropDown(Sender: TObject);
Var
fdb:TSearchRec;
begin
fdb.Name:='';
cblvl1.Clear;
 FindFirst(GlobalSupportPath+'lvl'+PathDelim+'*.lvl',faAnyFile, fdb);
  if fdb.Name<>'' then begin
    cbLvl1.Items.Add(ExtractFileName(fdb.Name));
     while findnext(fdb)=0 do cbLvl1.Items.Add(ExtractFileName(fdb.Name));
  end;
 FindClose(fdb);
end;


procedure Tfrmfields.cbClr1DropDown(Sender: TObject);
Var
fdb:TSearchRec;
begin
fdb.Name:='';
cbclr1.Clear;
 FindFirst(GlobalSupportPath+'clr'+PathDelim+'*.clr',faAnyFile, fdb);
  if fdb.Name<>'' then begin
   cbclr1.Items.Add(ExtractFileName(fdb.Name));
    while findnext(fdb)=0 do cbclr1.Items.Add(ExtractFileName(fdb.Name));
  end;
 FindClose(fdb);
end;


procedure Tfrmfields.btnAutomationClick(Sender: TObject);
Var
 k, k_f, k_d, mn:integer;
begin
 try
  ncFieldsAuto:=true;
  rgAutomation.Enabled:=false;
  btnAutomation.Enabled:=false;
  chklSelLev.Enabled:=false;
  case rgAutomation.ItemIndex of
    // all files, all dates, all levels
    0: begin
        for k:=0 to frmmain.cbFiles.count-1 do begin
          ncName:=frmmain.cbFiles.Items.strings[k];
            for k_d:=0 to cbDate.Items.Count-1 do begin
             cbDate.ItemIndex:=k_d;
              for k_f:=0 to cbLevel.Items.Count-1 do begin
               cblevel.ItemIndex:=k_f;
               Application.ProcessMessages;
                if cancel_fl=false then btnGetData.OnClick(self) else break;
              end;
            if cancel_fl=true then break;
         end;
        if cancel_fl=true then break;
       end;
    end;
    // Selected file, selected level, all dates
    1: begin
        for k_f:=0 to cbDate.Items.Count-1 do begin
         cbDate.ItemIndex:=k_f;
         Application.ProcessMessages;
          if cancel_fl=false then btnGetData.OnClick(self) else break;
        end;
    end;
    // Selected file, selected date, all levels
    2: begin
        for k_f:=0 to cbLevel.Items.Count-1 do begin
         cblevel.ItemIndex:=k_f;
         Application.ProcessMessages;
          if cancel_fl=false then btnGetData.OnClick(self) else break;
        end;
    end;
    // All files, all dates, selected level
    3: begin
        for k:=0 to frmmain.cbFiles.count-1 do begin
          ncName:=frmmain.cbFiles.Items.strings[k];
          frmmain.cbFiles.ItemIndex:=k;
          frmmain.cbFiles.OnClick(self);
           for k_d:=0 to cbDate.Items.Count-1 do begin
             cbDate.ItemIndex:=k_d;
             cblevel.ItemIndex:=k_f;
             Application.ProcessMessages;
              if cancel_fl=false then btnGetData.OnClick(self) else break;
              if cancel_fl=true then break;
           end;
           if cancel_fl=true then break;
        end;
    end;
    // Selected file, selected level, selected month
    4: begin
        for k_d:=0 to cbDate.Items.Count-1 do begin
         cbDate.ItemIndex:=k_d;
         mn:=strtoint(copy(cbDate.Text, 4, 2));
          if mn=semn.Value then
           if cancel_fl=false then btnGetData.OnClick(self) else break;
           if cancel_fl=true then break;
        end;
    end;
    // All files, selected date, levels from the list
    5: begin
       for k:=0 to frmmain.cbFiles.count-1 do begin
        ncName:=frmmain.cbFiles.Items.strings[k];
        frmmain.cbFiles.ItemIndex:=k;
        frmmain.cbFiles.OnClick(self);
          for k_d:=0 to cbDate.Items.Count-1 do begin
            cbDate.ItemIndex:=k_d;
            for k_f:=0 to cbLevel.Items.Count-1 do begin
              cblevel.ItemIndex:=k_f;
              Application.ProcessMessages;
               if chklSelLev.Checked[k_f]=true then begin
                 cblevel.ItemIndex:=k_f;
                 Application.ProcessMessages;
                 if cancel_fl=false then btnGetData.OnClick(self) else break;
               end;
            end;
           if cancel_fl=true then break;
         end;
         if cancel_fl=true then break;
       end;
    end;
  end;

 finally
   ncFieldsAuto:=false;
   rgAutomation.Enabled:=true;
   chklSelLev.Enabled:=true;
   btnAutomation.Enabled:=true;
   cancel_fl:=false;
 end;

  if MessageDlg(SDone, mtInformation, [mbOk], 0)=mrOk then begin
    OpenDocument(ncFieldPath);
   Exit;
  end;
end;

procedure Tfrmfields.rgAutomationClick(Sender: TObject);
begin
  if rgAutomation.Itemindex=4 then semn.Enabled:=true else semn.Enabled:=false;
  if rgAutomation.Itemindex=5 then chklSelLev.Enabled:=true else chklSelLev.Enabled:=false;
end;

procedure Tfrmfields.btnCancelClick(Sender: TObject);
begin
 Cancel_fl:=true;
end;


procedure Tfrmfields.btnSettingsClick(Sender: TObject);
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


procedure Tfrmfields.chkpolarClick(Sender: TObject);
begin
  if rgProjection.ItemIndex>0 then
   if StrToFloat(eminLat.text)<45 then eminLat.text:='45';
end;


procedure Tfrmfields.btnOpenFolderClick(Sender: TObject);
begin
  OpenDocument(PChar(ncFieldPath));
end;

procedure Tfrmfields.btnOpenScriptClick(Sender: TObject);
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
 ScriptFile:=ExtractFilePath(ncFieldPath)+'Script.bas';

 SysUtils.ExecuteProcess('"'+Scripter+'" "'+ScriptFile+'"', '', []);
end;


procedure Tfrmfields.btnGetDataClick(Sender: TObject);
Var
  fname, ncexportfile :string;
  yy, mn:integer;
  outd:text;
  lat, lon, u, v, w, d, x, y:real;
begin
 SaveSettings; //saving current settings;

 if not DirectoryExists(ncFieldPath) then CreateDir(ncFieldPath);
 if not DirectoryExists(ncFieldPath+PathDelim+'grd'+PathDelim) then CreateDir(ncFieldPath+PathDelim+'grd'+PathDelim);
 if not DirectoryExists(ncFieldPath+PathDelim+'dat'+PathDelim) then CreateDir(ncFieldPath+PathDelim+'dat'+PathDelim);
 if not DirectoryExists(ncFieldPath+PathDelim+'png'+PathDelim) then CreateDir(ncFieldPath+PathDelim+'png'+PathDelim);
 if not DirectoryExists(ncFieldPath+PathDelim+'srf'+PathDelim) then CreateDir(ncFieldPath+PathDelim+'srf'+PathDelim);

if (pcFieldType.ActivePageIndex=0) and (cbVariable.ItemIndex=-1) then
 if MessageDlg('Select variable', mtWarning, [mbOk], 0)=mrOk then exit;

if (pcFieldType.ActivePageIndex=1) and
   ((cbU.ItemIndex=-1) or (cbV.ItemIndex=-1)) then
 if MessageDlg('Select both variables', mtWarning, [mbOk], 0)=mrOk then exit;

if (cbDate.ItemIndex=-1) and (timevid>0) then
 if MessageDlg('Select date', mtWarning, [mbOk], 0)=mrOk then exit;

if (cbLevel.ItemIndex=-1) and (cbLevel.Enabled=true) then
 if MessageDlg('Select level', mtWarning, [mbOk], 0)=mrOk then exit;

 fname:=ncpath+ncname;

 if pcFieldType.ActivePageIndex=0 then begin
   GetField(fname, cbVariable.Text, eAdditionalScale.Value, eAdditionalOffset.Value,
            eMinLat.Value, eMaxLat.Value, eMinLon.Value, eMaxLon.Value, ncols, nrows);
 end;

 if pcFieldType.ActivePageIndex=1 then begin
   GetField(fname, cbU.Text, eAdditionalScale.Value, eAdditionalOffset.Value,
            eMinLat.Value, eMaxLat.Value, eMinLon.Value, eMaxLon.Value, ncols, nrows);
   GetField(fname, cbV.Text, eAdditionalScale.Value, eAdditionalOffset.Value,
            eMinLat.Value, eMaxLat.Value, eMinLon.Value, eMaxLon.Value, ncols, nrows);

 ncexportfile:=copy(ncname,1, length(ncname)-3);
 if cbDate.enabled=true  then ncexportfile:=ncexportfile+'_'+StringReplace(cbDate.Text, ':', '_', [rfReplaceAll, rfIgnoreCase]);
 if cbLevel.enabled=true then ncexportfile:=ncexportfile+'_'+cbLevel.Text;

    Assignfile(dat1, ncFieldPath+'dat'+PathDelim+ncexportfile+'_'+cbU.text+'.dat'); reset(dat1);
    Assignfile(dat2, ncFieldPath+'dat'+PathDelim+ncexportfile+'_'+cbV.text+'.dat'); reset(dat2);

    Assignfile(outd, ncFieldPath+'dat'+PathDelim+ncexportfile+'.dat'); rewrite(outd);
    writeln(outd, 'X':13, 'Y':13, 'Speed':10, 'Dir':13, 'u':10, 'v':10, 'Lon':11, 'Lat':9);

    Assignfile(out1, ncFieldPath+'dat'+PathDelim+'scalar.dat'); rewrite(out1);
    writeln(out1, 'Lat':9, 'Lon':11, 'Y':13, 'X':13, 'Value':13);

    readln(dat1);
    readln(dat2);
    repeat
      readln(dat1, lat, lon, y, x, u);
      readln(dat2, lat, lon, y, x, v);

      if (u=-9999) or (v=-9999) then begin
        w:=-9999;
        d:=-9999;
      end else begin
        w:=sqrt(u*u+v*v);
        d:=arctan2(v,u)*(180/Pi);
        if d<0 then d:=360+d;

        writeln(outd, x:13:5, y:13:5, w:10:5, d:13:5, u:10:5, v:10:5, Lon:11:5, Lat:11:5);
      end;
        writeln(out1, Lat:9:5, Lon:11:5, y:13:5, x:13:5, w:13:5);
    until eof(dat1);
    closefile(dat1);
    closefile(dat2);
    closefile(out1);
    closefile(outd);
 end;

  if chkIce.Checked then begin
    mn:=StrToInt(copy(cbDate.Items.Strings[cbDate.ItemIndex], 4, 2));
    yy:=StrToInt(copy(cbDate.Items.Strings[cbDate.ItemIndex], 7, 4));
   GetIce(ncFieldPath, yy, mn, eMinLat.Value, eMaxLat.Value, eMinLon.Value,
          eMaxLon.Value, rgProjection.ItemIndex);
    if FileExists(ncFieldPath+'ice.dat')=false then begin
     chkIce.Checked:=false;
     Showmessage(SHadISSTOutdated);
    end;
  end;

  if (ncFieldsAuto=true) and (chkPlot.Checked=true) then RunField;

  btnPlot.Enabled:=true;
  btnOpenScript.Enabled:=true;
  btnOpenFolder.Enabled:=true;
end;


procedure Tfrmfields.btnPlotClick(Sender: TObject);
begin
 try
  btnPlot.Enabled:=false;
   RunField;
 finally
  btnPlot.Enabled:=true;
 end;
end;


procedure Tfrmfields.RunField;
Var
  src1, src2, src3, grd1, grd2, grd3, lev1, clr1, ncexportfile, contour:string;
  XMin, XMax, YMin, YMax: real;
begin
if (cbLvl1.ItemIndex>-1) then Lev1:=GlobalSupportPath+'lvl'+PathDelim+cbLvl1.Text else Lev1:='';
if (cbclr1.ItemIndex>-1) then clr1:=GlobalSupportPath+'clr'+PathDelim+cbclr1.Text else clr1:='';

XMin:=StrToFloat(eMinLon.Text);
XMax:=StrToFloat(eMaxLon.Text);
YMin:=StrToFloat(eMinLat.Text);
YMax:=StrToFloat(eMaxLat.Text);

Contour:=lowercase(GlobalSupportPath+'bln'+PathDelim+'World.bln');

ncexportfile:=copy(ncname,1, length(ncname)-3);
if cbDate.enabled=true  then ncexportfile:=ncexportfile+'_'+StringReplace(cbDate.Text, ':', '_', [rfReplaceAll, rfIgnoreCase]);
if cbLevel.enabled=true then ncexportfile:=ncexportfile+'_'+cbLevel.Text;

if pcFieldType.ActivePageIndex=0 then begin
  ncexportfile:=ncexportfile+'_'+cbVariable.text;
  src1:=ncFieldPath+'dat'+PathDelim+ncexportfile+'.dat';
  grd1:=ncFieldPath+'grd'+PathDelim+ncexportfile+'.grd';
  GetncFieldScript(ncfieldpath, src1, '', '', grd1, '', '', lev1, clr1, contour, '',
                   ncols, nrows, true, XMin, XMax, YMin, YMax,
                   ncexportfile, ncFieldsAuto, rgProjection.ItemIndex,
                   cbLevel.Text, chkIce.Checked, curve);
end;

if pcFieldType.ActivePageIndex=1 then begin
  src1:=ncFieldPath+'dat'+PathDelim+'scalar.dat';
  src2:=ncFieldPath+'dat'+PathDelim+ncexportfile+'_'+cbU.text+'.dat';
  src3:=ncFieldPath+'dat'+PathDelim+ncexportfile+'_'+cbV.text+'.dat';

  grd1:=ncFieldPath+'grd'+PathDelim+ncexportfile+'_''scalar.dat';
  grd2:=ncFieldPath+'grd'+PathDelim+ncexportfile+'_'+cbU.text+'.grd';
  grd3:=ncFieldPath+'grd'+PathDelim+ncexportfile+'_'+cbV.text+'.grd';

    GetncFieldScript(ncfieldpath, src1, src2, src3, grd1, grd2, grd3, lev1,
                     clr1, contour, '', ncols, nrows, true, XMin, XMax, YMin,
                     YMax, ncexportfile, ncFieldsAuto, rgProjection.ItemIndex,
                     cbLevel.Text, chkIce.Checked, curve);
end;

{$IFDEF Windows}
    frmmain.RunScript(2, '-x "'+ncFieldPath+'script.bas"', nil);
{$ENDIF}
end;



procedure Tfrmfields.GetField(fname, par:string; addscale, addoffset,
LatMin, LatMax, LonMin, LonMax:real; Var ncols, nrows:size_t);
Var
  k, i, a:integer;
  lt_i, ln_i, tp, fl:integer;
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
  val1, firstval1, lat1, lon1, x, y, int_val, sum_pi:real;
  scale_ex, offset_ex, missing_ex: boolean;
  ncexportfile, nodes_str:string;
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

   // assign output file
   ncexportfile:=copy(ncname,1, length(ncname)-3);
   if cbDate.enabled=true  then ncexportfile:=ncexportfile+'_'+StringReplace(cbDate.Text, ':', '_', [rfReplaceAll, rfIgnoreCase]);
   if cbLevel.enabled=true then ncexportfile:=ncexportfile+'_'+cbLevel.Text;
   ncexportfile:=ncexportfile+'_'+par;


 //  showmessage(ncFieldPath+'dat'+PathDelim+ncexportfile+'.dat');

   AssignFile(f_dat, ncFieldPath+'dat'+PathDelim+ncexportfile+'.dat'); Rewrite(f_dat);
   writeln(f_dat, 'Lat':9, 'Lon':11, 'Y':13, 'X':13, 'Value':13, 'Nodes':15);

   (* количество строк и столбцов для обычного файла *)
   if curve=false then begin
     ncols:=high(ncLon_arr)+1;
     nrows:=high(ncLat_arr)+1;
   end;

   (* Если файл с криволинейными координатами - запрашиваем размерности из значения*)
   if curve=true then begin
      nc_inq_dimid (ncid, pAnsiChar(AnsiString('x')), dimid);
      nc_inq_dimlen(ncid, dimid, ncols);
      nc_inq_dimid (ncid, pAnsiChar(AnsiString('y')), dimid);
      nc_inq_dimlen(ncid, dimid, nrows);

      nc_inq_varid(ncid, pAnsiChar(AnsiString('nav_lon')), varxid); // longitude
      nc_inq_varid(ncid, pAnsiChar(AnsiString('nav_lat')), varyid); // latitude

      start2:=GetMemory(SizeOf(TArraySize_t)*2); // get memory for curvelinear coordinates
   end;

 //  showmessage('here6');
  start:=GetMemory(SizeOf(TArraySize_t)*ndimsp); // get memory for start pointer

  fl:=0; int_val:=0; sum_pi:=0;
  if ndimsp>2 then begin
   if cbDate.Enabled then start^[0]:=cbDate.ItemIndex else start^[0]:=cbLevel.ItemIndex;

    for lt_i:=0 to nrows-1 do begin //Latitude

     if ndimsp=2 then start^[0]:=lt_i;
     if ndimsp=3 then
       start^[1]:=lt_i;  //lat
     if ndimsp=4 then begin
      start^[1]:=cbLevel.ItemIndex;  //level
      start^[2]:=lt_i;  //lat
     end;

     for ln_i:=0 to ncols-1 do begin  //Longitude
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

      if (lat1>=LatMin) and (lat1<=LatMax) and
         (((LonMin<=LonMax) and (lon1>=LonMin) and (lon1<=LonMax)) or
          ((LonMin>LonMax) and
           (((lon1>=LonMin) and (lon1<=180)) or ((lon1>=-180) and (lon1<=LonMax)))))
         then begin
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

          if rgProjection.ItemIndex<2 then begin
            x:= (90-Lat1)*111.12*sin((Lon1)*Pi/180);
            y:=-(90-Lat1)*111.12*cos((Lon1)*Pi/180);
          end;
          if rgProjection.ItemIndex=2 then begin
            x:=(Lat1+90)*sin((Lon1)*pi/180);
            y:=(Lat1+90)*cos((Lon1)*pi/180);
          end;

         if (val0<>missing[0]) and (val0<>-9999) then begin
           val1:=scale[0]*val0+offset[0]; // scale and offset from nc file
           val1:=addscale*val1+AddOffset;  // additional conversion

           (* для температуры ниже -1.8 *)
           if ((par='sst') or
               (par='Temperature')) and
              (val1<-1.8) then Val1:=-9999;
         end else val1:=-9999;

         nodes_str:='"'+inttostr(ln_i)+';'+inttostr(lt_i)+'"';
          writeln(f_dat,  Lat1:9:5, Lon1:11:5, y:13:5, x:13:5, val1:13:5, nodes_str:15);

          if val1<>-9999 then begin
             Int_val:=Int_val+Val1*cos(Pi*ncLat_arr[lt_i]/180);
             Sum_pi:=Sum_pi+cos(Pi*ncLat_arr[lt_i]/180);
          end;
      end; // end of region
    end;
   end;
  end;
  FreeMemory(start);
  if curve then FreeMemory(Start2);

 Closefile(f_dat);

 if Sum_pi<>0 then begin
  AssignFile(f_dat, ncFieldPath+'dat'+PathDelim+ncexportfile+'_mean.dat'); Rewrite(f_dat);
    writeln(f_dat,  FloattoStrF((Int_val/Sum_pi), fffixed, 8, 3));
  ClosefIle(f_dat);
 end;


 finally
  fp:=nil;
  sp:=nil;
  ip:=nil;
  dp:=nil;

   status:=nc_close(ncid);  // Close file
    if status>0 then showmessage(pansichar(nc_strerror(status)));
 end;
end;


procedure Tfrmfields.rgProjectionClick(Sender: TObject);
begin
btnGetData.Enabled:=true;

eMinLat.Value := MinValue(ncLat_arr);
eMinLon.Value := MinValue(ncLon_arr);
eMaxLat.Value := MaxValue(ncLat_arr);
eMaxLon.Value := MaxValue(ncLon_arr);

emaxLat.Value.MinValue:=eMinLat.Value;
emaxLat.Value.MaxValue:=eMaxLat.Value;
eminLat.Value.MinValue:=eMinLat.Value;
eminLat.Value.MaxValue:=eMaxLat.Value;

emaxLon.Value.MinValue:=eMinLon.Value;
emaxLon.Value.MaxValue:=eMaxLon.Value;
eminLon.Value.MinValue:=eMinLon.Value;
eminLon.Value.MaxValue:=eMaxLon.Value;


 case rgProjection.ItemIndex of
   1: begin
       if eMaxLat.Value<=45 then
         if MessageDlg(SOutOfRange, mtError, [mbOk], 0)=mrOk then begin
           btnGetData.Enabled:=false;
           exit;
         end;
       if eMinLat.Value<45 then begin
          eminLat.Value:=45;
          eminLat.Value.MinValue:=eminLat.Value;
       end;
   end;
   2: begin
       if eMinLat.Value>=-30 then
         if MessageDlg(SOutOfRange, mtError, [mbOk], 0)=mrOk then begin
           btnGetData.Enabled:=false;
           exit;
         end;
       if eMaxLat.Value>-30 then begin
          eMaxLat.Value := -30;
          eMaxLat.Value.MaxValue:=eMaxLat.Value;
       end;
   end;
 end;

end;


end.

