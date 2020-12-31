unit climfields;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, SysUtils, Variants, Classes, Graphics, Controls, Forms, IniFiles, StdCtrls,
  Dialogs, Buttons, ComCtrls, ExtCtrls, DateUtils;

type

  { Tfrmclimfields }

  Tfrmclimfields = class(TForm)
    btnAllFiles: TButton;
    btnAllLevels: TButton;
    btnOpenFolder: TBitBtn;
    btnOpenScript: TBitBtn;
    btnPlot: TButton;
    btnSettings: TButton;
    Button1: TButton;
    cbLevel: TComboBox;
    cbBase: TComboBox;
    cbType: TComboBox;
    chkLegend: TCheckBox;
    chkpolar: TCheckBox;
    chkIce: TCheckBox;
    chkVarB: TCheckBox;
    eMaxLat: TEdit;
    eMinLat: TEdit;
    eMinLon: TEdit;
    eMaxLon: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    GroupBox6: TGroupBox;
    GroupBox7: TGroupBox;
    lbVariable: TLabel;
    PageControl1: TPageControl;
    Fields: TTabSheet;
    Automation: TTabSheet;

    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure eAdditionalScale1KeyPress(Sender: TObject; var Key: Char);
    procedure btnPlotClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure btnOpenFolderClick(Sender: TObject);
    procedure btnOpenScriptClick(Sender: TObject);
    procedure btnAllFilesClick(Sender: TObject);
    procedure btnAllLevelsClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);

  private
    { Private declarations }
    procedure GetParam(par:string);
    procedure RunField;

  public
    { Public declarations }
  end;

var
  frmclimfields: Tfrmclimfields;
  ClimFieldPath:string;
  f_scr, f_dat:text;
  ncFieldsAuto:boolean=false;


implementation


{$R *.lfm}


uses ncmain, ncprocedures, surfer_climfields,
     surfer_settings, nciceedge, declarations_netcdf;


procedure Tfrmclimfields.FormShow(Sender: TObject);
Var
 Ini:TIniFile;
 fdb:TSearchRec;
begin
if frmmain.cbVariables.Count=3 then
 lbVariable.Caption := frmmain.cbVariables.items.Strings[0] else
 lbVariable.Caption := frmmain.cbVariables.items.Strings[4];

 cbLevel.Items := frmmain.cbLevels.items;

 Ini := TIniFile.Create(IniFileName);
 try
  eMinLat.Text := Ini.ReadString('climfields', 'MinLat',  '60' );
  eMinLon.Text := Ini.ReadString('climfields', 'MinLon',  '-45');
  eMaxLat.Text := Ini.ReadString('climfields', 'MaxLat',  '82' );
  eMaxLon.Text := Ini.ReadString('climfields', 'MaxLon',  '70' );
  cbType.Text  := Ini.ReadString('climfields', 'ftype',   'Monthly');
  cbBase.Text  := Ini.ReadString('climfields', 'basemap', 'world.bln');
 finally
   Ini.Free;
 end;

 ClimFieldPath:=GlobalPath+'unload\fields\'+ncname+'\';
  if not DirectoryExists(ClimFieldPath) then CreateDir(ClimFieldPath);
  if not DirectoryExists(ClimFieldPath+'\png\') then CreateDir(ClimFieldPath+'\png\');
  if not DirectoryExists(ClimFieldPath+'\srf\') then CreateDir(ClimFieldPath+'\srf\');
  if not DirectoryExists(ClimFieldPath+'\grd\') then CreateDir(ClimFieldPath+'\grd\');

 (* загружаем список *.bln файлов *)
 fdb.Name:='';
 cbBase.Clear;
  FindFirst(GlobalPath+'support\bln\*.bln',faAnyFile, fdb);
   if fdb.Name<>'' then begin
     cbBase.Items.Add(ExtractFileName(fdb.Name));
      while findnext(fdb)=0 do cbBase.Items.Add(ExtractFileName(fdb.Name));
   end;
  FindClose(fdb);
  cbBase.Text:='world.bln';
end;


procedure Tfrmclimfields.btnPlotClick(Sender: TObject);
begin
 if (cbLevel.ItemIndex=-1) then
  if MessageDlg('Select level', mtWarning, [mbOk], 0)=mrOk then exit;

  RunField;

  btnOpenScript.Enabled:=true;
  btnOpenFolder.Enabled:=true;
end;


procedure Tfrmclimfields.btnAllFilesClick(Sender: TObject);
Var
 k:integer;
begin
ncFieldsAuto:=true;
(* перебираем все выбранные nc файлы *)
 For k:=0 to frmmain.cbFiles.Count-1 do begin
  ncName:=frmmain.cbFiles.Items.Strings[k];
  RunField;
 end; // Конец перебора nc файлов
ncFieldsAuto:=false;
end;



procedure Tfrmclimfields.btnAllLevelsClick(Sender: TObject);
Var
 K_f:integer;
begin
ncFieldsAuto:=true;
(* перебираем все горизонты *)
 for k_f:=0 to cbLevel.Items.Count-1 do begin
  cblevel.ItemIndex:=k_f;
  RunField;
 end; // Конец перебора горизонтов
ncFieldsAuto:=false;
end;


procedure Tfrmclimfields.Button1Click(Sender: TObject);
Var
k_f, k_d, k_l:integer;
clim_fl:boolean;
begin
ncFieldsAuto:=true;

(* перебираем все выбранные nc файлы *)
 For k_f:=0 to frmmain.cbFiles.Count-1 do begin
  ncName:=frmmain.cbFiles.Items.Strings[k_f];
    for k_l:=0 to cbLevel.Items.Count-1 do begin // перебираем все горизонты
     cblevel.ItemIndex:=k_l;
       RunField;
   end; // Конец перебора горизонтов
 end; // Конец перебора nc файлов

ncFieldsAuto:=false;
end;


procedure Tfrmclimfields.RunField;
Var
  k, i, stnum, ll, mn:integer;
  IniDat, src, lev1, lev2, clr1, clr2, buf_str, par, yrs, mns, lev:string;
  levstr_val, levstr_err:string;
  IndStr, DepStr, ncexportfile, ncTime, ncLvl, basemap2, period, stradd, mn_str_txt:string;
  avper, st:string;
  climvar:char;
  ShowLegend:boolean=true;
  XMin, XMax, Ymin, YMax:real;
  prj:integer;
begin

  if chkVarB.Checked=false then climvar:='A';
  if chkVarB.Checked=true  then climvar:='B';

  GetParam(lbVariable.Caption);

  if chkPolar.Checked=false then prj:=0 else prj:=1;

  (* adding ice edge *)
//  if (chkIce.Checked=true) then GetIce(ClimFieldPath, StrToFloat(eMinLat.Text),
//  StrToFloat(eMaxLat.Text), StrToFloat(eMinLon.Text), StrToFloat(eMaxLon.Text),
//  prj);

  src:=ClimFieldPath+lbVariable.Caption+'.dat';

 (* TEMPERATURE *)
  if lbVariable.Caption='Temperature' then begin
   lev1:=GlobalPath+'support\lvl\atlas\t\t_val_0000_3500.lvl';
   clr1:=GlobalPath+'support\clr\atlas\t\t_val_0000_3500.clr';

   if chkVarB.Checked=false then begin
     lev2:=GlobalPath+'support\lvl\atlas\t\t_err_0000_3500.lvl';
     clr2:=GlobalPath+'support\clr\atlas\t\t_err_0000_3500.clr';
   end;

   if chkVarB.Checked=true then begin
     if (StrToInt(cbLevel.Text)=0)    then levstr_err:='0000_0000';
     if (StrToInt(cbLevel.Text)>=10)   and (StrToInt(cbLevel.Text)<=30)   then levstr_err:='0010_0030';
     if (StrToInt(cbLevel.Text)>=50)   and (StrToInt(cbLevel.Text)<=150)  then levstr_err:='0050_0150';
     if (StrToInt(cbLevel.Text)>=200)  and (StrToInt(cbLevel.Text)<=400 ) then levstr_err:='0200_0400';
     if (StrToInt(cbLevel.Text)>=500)  and (StrToInt(cbLevel.Text)<=800 ) then levstr_err:='0500_0800';
     if (StrToInt(cbLevel.Text)>=900)  then levstr_err:='0900_3500';
       lev2:=GlobalPath+'support\lvl\atlas\t\t_erm_'+levstr_err+'.lvl';
       clr2:=GlobalPath+'support\clr\atlas\t\t_erm_'+levstr_err+'.clr';
   end;
  end;


  (* SALINITY *)
  if lbVariable.Caption='Salinity' then begin
   // Для поля солености - 3 градации
     if (StrToInt(cbLevel.Text)<=150)   then levstr_val:='0000_0150';
     if (StrToInt(cbLevel.Text)>=200)   and (StrToInt(cbLevel.Text)<=300)   then levstr_val:='0200_0300';
     if (StrToInt(cbLevel.Text)>=400)   then levstr_val:='0400_3500';
       lev1:=GlobalPath+'support\lvl\atlas\s\s_val_'+levstr_val+'.lvl';
       clr1:=GlobalPath+'support\clr\atlas\s\s_val_'+levstr_val+'.clr';

   // Для ошибки
   if chkVarB.Checked=false then begin
     if (StrToInt(cbLevel.Text)<=20)   then levstr_err:='0000_0020';
     if (StrToInt(cbLevel.Text)>=30)   and (StrToInt(cbLevel.Text)<=50)   then levstr_err:='0030_0050';
     if (StrToInt(cbLevel.Text)>=75)   and (StrToInt(cbLevel.Text)<=150)  then levstr_err:='0075_0150';
     if (StrToInt(cbLevel.Text)>=200)  and (StrToInt(cbLevel.Text)<=800 ) then levstr_err:='0200_0800';
     if (StrToInt(cbLevel.Text)>=900)  then levstr_err:='0900_3500';
       lev2:=GlobalPath+'support\lvl\atlas\s\s_err_'+levstr_err+'.lvl';
       clr2:=GlobalPath+'support\clr\atlas\s\s_err_'+levstr_err+'.clr';
    end;

    if chkVarB.Checked=true then begin
     if (StrToInt(cbLevel.Text)=0)    then levstr_err:='0000_0000';
     if (StrToInt(cbLevel.Text)>=10)   and (StrToInt(cbLevel.Text)<=30)   then levstr_err:='0010_0030';
     if (StrToInt(cbLevel.Text)>=50)   and (StrToInt(cbLevel.Text)<=150)  then levstr_err:='0050_0150';
     if (StrToInt(cbLevel.Text)>=200)  and (StrToInt(cbLevel.Text)<=400 ) then levstr_err:='0200_0400';
     if (StrToInt(cbLevel.Text)>=500)  and (StrToInt(cbLevel.Text)<=800 ) then levstr_err:='0500_0800';
     if (StrToInt(cbLevel.Text)>=900)  then levstr_err:='0900_3500';
       lev2:=GlobalPath+'support\lvl\atlas\s\s_erm_'+levstr_err+'.lvl';
       clr2:=GlobalPath+'support\clr\atlas\s\s_erm_'+levstr_err+'.clr';
   end;
  end;


  (* DENSITY *)
  if lbVariable.Caption='Density' then begin
    // Для поля плотности - 3 градации
     if (StrToInt(cbLevel.Text)<=150)   then levstr_val:='0000_0150';
     if (StrToInt(cbLevel.Text)>=200)   and (StrToInt(cbLevel.Text)<=300)   then levstr_val:='0200_0300';
     if (StrToInt(cbLevel.Text)>=400)   then levstr_val:='0400_3500';
       lev1:=GlobalPath+'support\lvl\atlas\d\d_val_'+levstr_val+'.lvl';
       clr1:=GlobalPath+'support\clr\atlas\d\d_val_'+levstr_val+'.clr';

   // Для ошибки
   if chkVarB.Checked=false then begin
     if (StrToInt(cbLevel.Text)=0)     then levstr_err:='0000_0000';
     if (StrToInt(cbLevel.Text)>=10)   and (StrToInt(cbLevel.Text)<=20)   then levstr_err:='0010_0020';
     if (StrToInt(cbLevel.Text)>=30)   and (StrToInt(cbLevel.Text)<=50)   then levstr_err:='0030_0050';
     if (StrToInt(cbLevel.Text)>=75)   and (StrToInt(cbLevel.Text)<=150)  then levstr_err:='0075_0150';
     if (StrToInt(cbLevel.Text)>=200)  and (StrToInt(cbLevel.Text)<=800 ) then levstr_err:='0200_0800';
     if (StrToInt(cbLevel.Text)>=900)  then levstr_err:='0900_3500';
       lev2:=GlobalPath+'support\lvl\atlas\d\d_err_'+levstr_err+'.lvl';
       clr2:=GlobalPath+'support\clr\atlas\d\d_err_'+levstr_err+'.clr';
   end;

   if chkVarB.Checked=true then begin
     if (StrToInt(cbLevel.Text)=0)    then levstr_err:='0000_0000';
     if (StrToInt(cbLevel.Text)>=10)   and (StrToInt(cbLevel.Text)<=30)   then levstr_err:='0010_0030';
     if (StrToInt(cbLevel.Text)>=50)   and (StrToInt(cbLevel.Text)<=75 )  then levstr_err:='0050_0075';
     if (StrToInt(cbLevel.Text)>=100)  and (StrToInt(cbLevel.Text)<=150)  then levstr_err:='0100_0150';
     if (StrToInt(cbLevel.Text)>=200)  and (StrToInt(cbLevel.Text)<=400 ) then levstr_err:='0200_0400';
     if (StrToInt(cbLevel.Text)>=500)  and (StrToInt(cbLevel.Text)<=800 ) then levstr_err:='0500_0800';
     if (StrToInt(cbLevel.Text)>=900)  then levstr_err:='0900_3500';
       lev2:=GlobalPath+'support\lvl\atlas\d\d_erm_'+levstr_err+'.lvl';
       clr2:=GlobalPath+'support\clr\atlas\d\d_erm_'+levstr_err+'.clr';
   end;
 end;

  //разбираем название, ищем исходные данные
  //Salinity.19721972.0112.10025.10025.anl.nc
  i:=0;
  for k:=1 to 3 do begin
   buf_str:='';
   repeat
    inc(i);
     if ncname[i]<>'.' then buf_str:=buf_str+ncname[i];
   until (ncname[i]='.') or (i=length(ncname)) ;
   if k=1 then par:=trim(buf_str);
   if k=2 then yrs:=trim(buf_str);
   if k=3 then mns:=trim(buf_str);
   if k=4 then lev:=trim(buf_str);
  end;


  if cbLevel.ItemIndex>-1 then begin
   ll:=Strtoint(cbLevel.Text);
   Case Ll of
      0: stradd:='10029';
     10: stradd:='10028';
     20: stradd:='10027';
     30: stradd:='10026';
     50: stradd:='10025';
     75: stradd:='10024';
    100: stradd:='10023';
    125: stradd:='10022';
    150: stradd:='10021';
    200: stradd:='10020';
    250: stradd:='10019';
    300: stradd:='10018';
    400: stradd:='10017';
    500: stradd:='10016';
    600: stradd:='10015';
    700: stradd:='10014';
    800: stradd:='10013';
    900: stradd:='10012';
   1000: stradd:='10011';
   1100: stradd:='10010';
   1200: stradd:='10009';
   1300: stradd:='10008';
   1400: stradd:='10007';
   1500: stradd:='10006';
   1750: stradd:='10005';
   2000: stradd:='10004';
   2500: stradd:='10003';
   3000: stradd:='10002';
   3500: stradd:='10001';
   end;

  IniDat:=ncPath+'data\'+par+'.'+yrs+'.'+mns+'.'+stradd;

  if (FileExists(IniDat)=false) or (chkLegend.Checked=false) then begin
   IniDat:='';
   stnum:=-9;
   ShowLegend:=false;
  end;

  if (FileExists(IniDat)=True) and (chkLegend.Checked=true)  then begin
   stnum:=0;
    AssignFile(f_dat, IniDat); reset(f_dat);
     repeat
      readln(f_dat, st);
      if not eof(f_dat) then inc(stnum);
    until eof(f_dat);
    CloseFile(f_dat);
    ShowLegend:=true;
  end;

  //period
  period:=copy(yrs,1,4)+'-'+copy(yrs,5,4);
  if mns<>'0112' then begin
   mn:=StrToInt(copy(mns, 1, 2));
   case mn of
    1: mn_str_txt:='Jan';
    2: mn_str_txt:='Feb';
    3: mn_str_txt:='Mar';
    4: mn_str_txt:='Aprl';
    5: mn_str_txt:='May';
    6: mn_str_txt:='Jun';
    7: mn_str_txt:='Jul';
    8: mn_str_txt:='Aug';
    9: mn_str_txt:='Sep';
   10: mn_str_txt:='Oct';
   11: mn_str_txt:='Nov';
   12: mn_str_txt:='Dec';
   end;
  end else mn_str_txt:='';
  period:=mn_str_txt+' '+period;
  end else ll:=-9; //если нет глубины, строим так

  avper:=cbType.text;

//  if cbDate.Text<>''  then nctime:=StringReplace(cbDate.Text,  ':', '.',[rfReplaceAll, rfIgnoreCase]) else ncTime:='';
  if cbLevel.Text<>'' then nclvl :=StringReplace(cbLevel.Text, ':', '.',[rfReplaceAll, rfIgnoreCase]) else ncLvl:='';

   if ncLvl<>''  then begin
    if length(nclvl)=1 then nclvl:='000'+nclvl;
    if length(nclvl)=2 then nclvl:='00'+nclvl;
    if length(nclvl)=3 then nclvl:='0'+nclvl;

    ncexportfile:=lowercase(Copy(ncname, 1, 1))+'_'+yrs+'_'+mns+'_'+nclvl;

     XMin:=StrToFloat(eMinLon.Text);
     XMax:=StrToFloat(eMaxLon.Text);
     Ymin:=StrToFloat(eMinLat.Text);
     YMax:=StrToFloat(eMaxLat.Text);

    //имя второй карты с реальной глубиной
    if strtoint(nclvl)>0 then begin
      if XMin=-45 then
         basemap2:=GlobalPath+'support\bln\NS_'+nclvl+'.bln' else
         basemap2:=GlobalPath+'support\bln\labrador_'+nclvl+'.bln';
    end;
   end;

  // if ncTime<>'' then ncexportfile:=ncexportfile+'.'+ncTime;
  if (chkVarB.Checked=true) and (stnum>0) then
   if MessageDlg('You are probably trying to plot Var. A. Uncheck Var.B checkbox?',
     mtWarning, [mbYes, mbNo], 0)=mrYes then chkVarB.Checked:=false else
      begin
      //  ncFieldsExitFlag:=true;
        exit;
      end;


  (* !!!!!!!!!!!!!!!! *)
  basemap2:='';

     GetClimFieldsScript(IniDat, src, lev1, lev2, clr1, clr2,
                      XMin, XMax, Ymin, YMax,
                      cbBase.Text, ncexportfile, ncFieldsAuto, ShowLegend,
                      basemap2, period, avper, lbVariable.Caption, Ll, stnum,
                      climvar, chkIce.Checked, chkPolar.Checked);
   {$IFDEF Windows}
     frmmain.RunScript(2, '"'+ClimFieldPath+'tmp'+PathDelim+'script.bas"', nil);
   {$ENDIF}
end;



procedure Tfrmclimfields.GetParam(par:string);
Var
  Ini:TIniFile;
  lt_i, ln_i:integer;
  status, ncid, varidp, varidp2, varidp3:integer;
  start: PArraySize_t;
  va, ve, vr:array of single;
  val0, vale, valr, RelErr, x, y:real;
  UseRE:boolean;
begin

  try
   Ini := TIniFile.Create(IniFileName);
   RelErr:=Ini.ReadFloat('main', 'RelativeError',    0.25);
   UseRE :=Ini.ReadBool ('main', 'UseRelativeError', true);
  finally
    ini.Free;
  end;

try
  (* nc_open*)
   nc_open(pchar(ncpath+ncname), NC_NOWRITE, ncid); // only for reading

   nc_inq_varid (ncid, pchar(par), varidp); // variable ID
   nc_inq_varid (ncid, pchar(par+'_err'), varidp2); // variable 2 ID
   nc_inq_varid (ncid, pchar(par+'_relerr'), varidp3); // variable 2 ID


   // assign output file
   AssignFile(f_dat, ClimFieldPath+par+'.dat'); Rewrite(f_dat);
   writeln(f_dat, 'Lat':15, 'Lon':15, 'Value':10, 'Error':10, 'Rel.err':10);

   start:=GetMemory(SizeOf(TArraySize_t)*4); // get memory for start pointer

   start^[0]:=0; //time
   start^[1]:=cbLevel.ItemIndex;  //level
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

            if chkpolar.Checked=false then begin //Merkator
             writeln(f_dat, ncLat_arr[lt_i]:15:5, ncLon_arr[ln_i]:15:5, val0:10:3, vale:10:3, valr:10:3);
            end; //end merkator
            if chkpolar.Checked=true then begin //Circumpolar
             x:= (90-ncLat_arr[lt_i])*111.12*sin((ncLon_arr[ln_i])*Pi/180);
             y:=-(90-ncLat_arr[lt_i])*111.12*cos((ncLon_arr[ln_i])*Pi/180);
           //  x:= 2*6388.015*sin(Pi/4-ncLat_arr[lt_i]/2*Pi/180)*Sin(Pi/180*ncLon_arr[ln_i])/10;
          //   y:=-2*6388.015*sin(Pi/4-ncLat_arr[lt_i]/2*Pi/180)*Cos(Pi/180*ncLon_arr[ln_i])/10;
               writeln(f_dat, y:15:5, x:15:5, val0:10:3, vale:10:3, valr:10:3); ;
            end; //end circumpolar
           end; // UseRE
         end; //val<>-9999
      end; //ln_i
   end; //lt_i
  FreeMemory(start);
  Closefile(f_dat);
 finally
  va:=nil;
  ve:=nil;
  nc_close(ncid);  // Close file
 end;
end;


procedure Tfrmclimfields.btnSettingsClick(Sender: TObject);
begin
 frmSurferSettings := TfrmSurferSettings.Create(Self);
 frmSurferSettings.LoadSettings('climfields');
  try
   if not frmSurferSettings.ShowModal = mrOk then exit;
  finally
    frmSurferSettings.Free;
    frmSurferSettings := nil;
  end;
end;



procedure Tfrmclimfields.eAdditionalScale1KeyPress(Sender: TObject; var Key: Char);
begin
  if not (key in['0'..'9',decimalseparator,#8, Char('-')]) then key:=#0;
end;


procedure Tfrmclimfields.btnOpenScriptClick(Sender: TObject);
Var
ScriptFile:string;
begin
 ScriptFile:=ExtractFilePath(ClimFieldPath)+'script.bas';
  if FileExists(ScriptFile) then OpenDocument(PChar(ScriptFile));
end;

procedure Tfrmclimfields.btnOpenFolderClick(Sender: TObject);
begin
 OpenDocument(PChar(ClimFieldPath));
end;


procedure Tfrmclimfields.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
Var
  Ini:TIniFile;
begin
 Ini := TIniFile.Create(IniFileName);
 try
  Ini.WriteString('climfields', 'MinLat',  eMinLat.Text);
  Ini.WriteString('climfields', 'MinLon',  eMinLon.Text);
  Ini.WriteString('climfields', 'MaxLat',  eMaxLat.Text);
  Ini.WriteString('climfields', 'MaxLon',  eMaxLon.Text);
  Ini.WriteString('climfields', 'ftype',   cbType.Text);
  Ini.WriteString('climfields', 'basemap', cbBase.Text);
 finally
   Ini.Free;
 end;
end;

end.
