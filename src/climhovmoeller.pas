unit climhovmoeller;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, BufDataSet, DB, ComCtrls, Math, Buttons, ExtCtrls,
  FileUtil;

type

  { Tfrmclimhovmoeller }

  Tfrmclimhovmoeller = class(TForm)
    btnGetData: TButton;
    btnOpenFolder: TBitBtn;
    btnOpenScript: TBitBtn;
    btnSettings: TButton;
    cbClr1: TComboBox;
    cbHov: TComboBox;
    cbLvl1: TComboBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    Label3: TLabel;
    eYY1: TEdit;
    Label4: TLabel;
    eYY2: TEdit;
    Label5: TLabel;
    Label9: TLabel;
    rgCol: TRadioGroup;

    procedure btnGetDataClick(Sender: TObject);
    procedure btnOpenFolderClick(Sender: TObject);
    procedure btnOpenScriptClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnGetNormaClick(Sender: TObject);

  private
    { Private declarations }
    procedure GetData;
    procedure CreateBlanc;
    procedure GetNorma;
  public
    { Public declarations }
  end;

var
  frmclimhovmoeller: Tfrmclimhovmoeller;
  CDSStream:TBufDataSet; //Датасет для начального файла для потока
  DatF, out1, script:text;  //Текстовые файлы
  HovmoellerPath, LvlPath:string; //Пути
  koef, YYMin:real;  //Параметры для скрипта


implementation

{$R *.lfm}

Uses ncmain, surfer_settings, surfer_climhovmoeller, ncprocedures, declarations_netcdf;


procedure Tfrmclimhovmoeller.FormShow(Sender: TObject);
Var
  fdb:TSearchRec;
begin
 if not DirectoryExists(GlobalPath+'unload'+PathDelim+'hovmoeller'+PathDelim) then
   CreateDir(GlobalPath+'unload'+PathDelim+'hovmoeller'+PathDelim);

 HovmoellerPath:=GlobalPath+'unload\hovmoeller\'+ncname+'\';
 if not DirectoryExists(HovmoellerPath) then CreateDir(HovmoellerPath);

 (* загружаем список файлов с координатами *)
 fdb.Name:='';
  FindFirst(GlobalPath+'support\hovemoller\*.hov',faAnyFile, fdb);
   if fdb.name<>'' then begin
     cbhov.Items.Add(fdb.name);
    while FindNext(fdb)=0 do cbhov.Items.Add(fdb.name);
  end;
 FindClose(fdb);

  (* загружаем список *.lvl файлов *)
 fdb.Name:='';
  FindFirst(GlobalPath+'support\lvl\*.lvl',faAnyFile,fdb);
   if fdb.Name<>'' then begin
    cbLvl1.Items.Add(fdb.Name);
    while FindNext(fdb)=0 do cbLvl1.Items.Add(fdb.Name);
   end;
  FindClose(fdb);
 if cbLvl1.Items.Count=0 then cbLvl1.Enabled:=false;

 (* загружаем список *.clr файлов *)
 fdb.Name:='';
  FindFirst(GlobalPath+'support\clr\*.clr',faAnyFile,fdb);
   if fdb.Name<>'' then begin
    cbclr1.Items.Add(fdb.Name);
    while FindNext(fdb)=0 do cbclr1.Items.Add(fdb.Name);
   end;
  FindClose(fdb);
 if cbclr1.Items.Count=0 then cbclr1.Enabled:=false;

end;

procedure Tfrmclimhovmoeller.btnGetNormaClick(Sender: TObject);
begin

end;



procedure Tfrmclimhovmoeller.btnGetDataClick(Sender: TObject);
Var
 K, col:integer;
 Lat, LonBeg, LonEnd, DepBeg, DepEnd:real;
 lvl, clr: string;
begin
   if (cbHov.ItemIndex=-1) then begin
      Showmessage('Please, select file with coordinate ');
     exit;
   end;

 try
   btnGetData.Enabled:=false;
   btnSettings.Enabled:=false;
   btnOpenFolder.Enabled:=false;
   btnOpenScript.Enabled:=false;
   Application.ProcessMessages;

   CDSStream:=TBufDataSet.Create(nil);
    with CDSStream.FieldDefs do begin
     Add('Lat'   , ftFloat    , 0, false);
     Add('LonBeg', ftFloat    , 0, false);
     Add('LonEnd', ftFloat    , 0, false);
     Add('DepBeg', ftFloat    , 0, false);
     Add('DepEnd', ftFloat    , 0, false);
     Add('Sum',    ftFloat    , 0, false);
     Add('Count',  ftInteger  , 0, false);
     Add('Mean',   ftFloat    , 0, false);
    end;
   CDSStream.CreateDataSet;

   AssignFile(datF, GlobalPath+'support\hovemoller\'+cbHov.Text); reset(datF);
   readln(datF); //пропускаем строку с заголовком
   (* Заполняем CDS с параметрами потока *)
    repeat
     readln(datF, Lat, LonBeg, LonEnd, DepBeg, DepEnd);
     with CDSStream do begin
      Append;
       FieldByName('Lat').AsFloat:=Lat;
       FieldByName('LonBeg').AsFloat:=LonBeg;
       FieldByName('LonEnd').AsFloat:=LonEnd;
       FieldByName('DepBeg').AsFloat:=DepBeg;
       FieldByName('DepEnd').AsFloat:=DepEnd;
      Post;
     end;
    until eof(DatF);
  CloseFile(DatF);

  btnGetData.Enabled:=true;


 AssignFile(DatF, HovmoellerPath+'Hov.dat'); rewrite(datF);
 writeln(DatF, 'Year':10, 'Lat':15, 'MeanLon':15, 'MeanDepth':10, 'Value':10);

 For k:=0 to frmmain.cbFiles.Count-1 do begin
  ncName:=frmmain.cbFiles.Items.Strings[k];
     GetData; //извлекаем данные
 end; // Конец перебора nc файлов
 Closefile(datf);

 GetNorma;
 CreateBlanc;

 if rgCol.ItemIndex=0 then col:=6 else col:=7;
 if trim(cblvl1.text)<>'' then lvl:=GlobalPath+'support\lvl\'+cbLvl1.text else lvl:='';
 if trim(cbclr1.text)<>'' then clr:=GlobalPath+'support\clr\'+cbClr1.text else clr:='';


 GetClimHovmoellerScript(HovmoellerPath, lvl, clr, 100, 100, col);

 {$IFDEF Windows}
    frmmain.RunScript(2, '"'+HovmoellerPath+'tmp'+PathDelim+'script.bas"', nil);
 {$ENDIF}

 Finally
  CDSStream.Free;
   btnGetData.Enabled:=true;
   btnSettings.Enabled:=true;
   btnOpenFolder.Enabled:=true;
   btnOpenScript.Enabled:=true;
  Application.ProcessMessages;
 end;
end;



procedure Tfrmclimhovmoeller.GetData;
Var
  k, ll, lt, ln, cnt, yy:integer;
  status, ncid, varidp, varidp2:integer;
  start: PArraySize_t;
  fp:array of single;
  val0, val_err:variant;
  val1, firstval1:real;

  Lat, LonB, LonE, DepB, DepE, val_sum:real;
  par:string;
begin
if frmmain.cbVariables.Count=3 then
    par := frmmain.cbVariables.items.Strings[0] else
    par := frmmain.cbVariables.items.Strings[4];
yy:=StrToInt(copy(ncname, pos('.', ncname)+1, 4));

try
 (* nc_open*)
   status:=nc_open(pansichar(AnsiString(ncpath+ncname)), NC_NOWRITE, ncid); // only for reading
    if status>0 then showmessage(pansichar(nc_strerror(status)));

   nc_inq_varid (ncid, pAnsiChar(AnsiString(par)), varidp);
   nc_inq_varid (ncid, pAnsiChar(AnsiString(par+'_relerr')), varidp2);

   SetLength(fp, 1);
   start:=GetMemory(SizeOf(TArraySize_t)*4); // get memory for start pointer


  start^[0]:=0; //time
  CDSStream.First;
  while not CDSStream.Eof  do begin
    Lat :=CDSStream.FieldByName('Lat').AsFloat;
    LonB:=CDSStream.FieldByName('LonBeg').AsFloat;
    LonE:=CDSStream.FieldByName('LonEnd').AsFloat;
    DepB:=CDSStream.FieldByName('DepBeg').AsFloat;
    DepE:=CDSStream.FieldByName('DepEnd').AsFloat;

    start^[2]:=GetLatIndex(Lat);
    val_sum:=0; cnt:=0;
     for ln:=0 to high(nclon_arr) do
      if (ncLon_arr[ln]>=LonB) and (ncLon_arr[ln]<=LonE) then begin
       start^[3]:=ln;
        for ll:=0 to high(ncLev_arr) do
         if (ncLev_arr[ll]>=DepB) and (ncLev_arr[ll]<=DepE) then begin
          start^[1]:=ll;  //level

           SetLength(fp, 1);
            nc_get_var1_float(ncid, varidp, start^, fp);
           Val1:=fp[0];

           SetLength(fp, 1);
            nc_get_var1_float(ncid, varidp2, start^, fp);
           Val_err:=fp[0];

           if (val1<>-9999) then begin
            (* для температуры ниже -1.8 *)
             if (par='Temperature') and (val1<-1.8) then Val1:=-1.99;

             if (val_err<=0.25) then begin
              Val_sum:=Val_sum+val1;
              inc(cnt);
             end;
           end; //-9999
        end; // end level
     end; // end lon

    if cnt>0 then
     writeln(DatF,
           YY:10,
           Lat:15:5,
           ((LonB+LonE)/2):15:5,
           ((DepB+DepE)/2):10:1,
           (val_sum/cnt):10:3);

    CDSStream.Next;
  end;
 FreeMemory(start);

 finally
  fp:=nil;
   status:=nc_close(ncid);  // Close file
    if status>0 then showmessage(pansichar(nc_strerror(status)));
 end;
end;



procedure Tfrmclimhovmoeller.GetNorma;
Var
CDSMean:TBufDataSet;
yy, lat, meanlon, meandep, val1, ValMean:real;
YYMax, latmin, latmax:real;
VarTemp:Variant;
begin
  CDSMean:=TBufDataSet.Create(nil);
    with  CDSMean.FieldDefs do begin
     Add('Lat',   ftFloat,   0, false);
     Add('Sum',   ftFloat,   0, false);
     Add('Count', ftInteger, 0, false);
    end;
  CDSMean.IndexFieldNames:='Lat';
  CDSMean.CreateDataSet;

 AssignFile(DatF, HovmoellerPath+'Hov.dat'); reset(datF);
 readln(DatF);

 YYMin:=9999; YYMax:=-9999; LatMin:=90; LatMax:=-90;
 repeat
   readln(DatF, yy, lat, meanlon, meandep, val1);

   if YY<YYMin then YYMin:=YY;
   if YY>YYMax then YYMax:=YY;

   if lat<latMin then latMin:=lat;
   if lat>latMax then latMax:=lat;

    VarTemp:=(CDSMean.Lookup('Lat', Lat, 'Lat'));
    if VarIsNull(VarTemp)=true then begin
     CDSMean.Append;
      CDSMean.FieldByName('Lat').AsFloat:=Lat;
      CDSMean.FieldByName('Sum').AsFloat:=0;
      CDSMean.FieldByName('Count').AsInteger:=0;
     CDSMean.Post;
    end;

   if (yy>=StrToFloat(eYY1.Text)) and (yy<=StrToFloat(eYY2.Text)) then begin
    CDSMean.Locate('Lat', Lat, [locaseinsensitive]);
     CDSMean.Edit;
      CDSMean.FieldByName('Sum').AsFloat:=CDSMean.FieldByName('Sum').AsFloat+Val1;
      CDSMean.FieldByName('Count').AsInteger:=CDSMean.FieldByName('Count').AsInteger+1;
     CDSMean.Post;
   end;
  until eof(datf);
 closefile(datf);

  koef:= (YYMax - YYMin) / (latmax-latmin);  //коэф. пересчета для годов

  AssignFile(DatF, HovmoellerPath+'Hov.dat'); reset(datF);

  AssignFile(out1, HovmoellerPath+'Temp.dat'); rewrite(out1);
  writeln(out1, 'YY_tr':15, 'YY':10, 'lat':15, 'meanlon':15, 'meandep':10, 'value':10, 'anomaly':10);

  readln(DatF);
  repeat
    readln(DatF, yy, lat, meanlon, meandep, val1);
    if CDSMean.Locate('Lat', lat, [])=true then begin
     Valmean:=CDSMean.FieldByName('Sum').AsFloat/CDSMean.FieldByName('Count').AsInteger;

     writeln(out1, ((yy-yyMin)/koef):15:5, yy:10:0, lat:15:5, meanlon:15:5,
                     meandep:10:1, val1:10:3, (val1-ValMean):10:3);
    end;
  until eof(datF);
 CloseFile(datF);
 CloseFile(out1);

 CDSMean.Free;
end;


procedure Tfrmclimhovmoeller.CreateBlanc;
Var
CDSbln:TBufDataSet;
YY, YY_tr, Lat:real;
VarTemp:variant;
begin
 AssignFile(DatF, HovmoellerPath+'Temp.dat'); reset(datF);
 readln(DatF);

 AssignFile(out1, HovmoellerPath+'Temp.bln'); rewrite(out1);

  CDSbln:=TBufDataSet.Create(nil);
    with  CDSbln.FieldDefs do begin
     Add('YY', ftFloat, 0, false);
     Add('LB',  ftFloat, 0, false);
     Add('LE',  ftFloat, 0, false);
    end;
  CDSbln.IndexFieldNames:='YY';
  CDSbln.CreateDataSet;

  repeat
   readln(DatF, yy_tr, yy, lat);

    VarTemp:=(CDSbln.Lookup('YY', yy, 'YY'));  //yy_tr  для трансформированного времени

    if VarIsNull(VarTemp)=true then begin
     CDSbln.Append;
      CDSbln.FieldByName('YY').AsFloat:=YY;  // yy_tr  для трансформированного времени
      CDSbln.FieldByName('LB').AsFloat:=9999;
      CDSbln.FieldByName('LE').AsFloat:=-9999;
     CDSbln.Post;
    end;

   CDSbln.Locate('YY', yy, [locaseinsensitive]); //yy_tr  для трансформированного времени
   if CDSbln.FieldByName('LB').AsFloat>Lat then begin
     CDSbln.Edit;
      CDSbln.FieldByName('LB').AsFloat:=Lat;
     CDSbln.Post;
   end;

   if CDSbln.FieldByName('LE').AsFloat<Lat then begin
     CDSbln.Edit;
      CDSbln.FieldByName('LE').AsFloat:=Lat;
     CDSbln.Post;
   end;
  until eof(datf) ;


  writeln(out1, ((CDSbln.recordCount*2)+1):15, '0':15);

  CDSbln.First;
  while not CDSbln.Eof do begin
    writeln(out1,
       CDSbln.FieldByName('YY').AsFloat:15:5,
       CDSbln.FieldByName('LB').AsFloat:15:5);
   CDSbln.Next;
  end;

  CDSbln.Last;
  repeat
    writeln(out1,
       CDSbln.FieldByName('YY').AsFloat:15:5,
       CDSbln.FieldByName('LE').AsFloat:15:5);
   CDSbln.Prior;
  until CDSbln.RecNo=1;

  CDSbln.First;
   writeln(out1,
       CDSbln.FieldByName('YY').AsFloat:15:5,
       CDSbln.FieldByName('LE').AsFloat:15:5);
   writeln(out1,
       CDSbln.FieldByName('YY').AsFloat:15:5,
       CDSbln.FieldByName('LB').AsFloat:15:5);

 closefile(datf);
 closefile(out1);
 CDSbln.Free;
end;


procedure Tfrmclimhovmoeller.btnSettingsClick(Sender: TObject);
begin
frmSurferSettings := TfrmSurferSettings.Create(Self);
frmSurferSettings.LoadSettings('climhovmoeller');
 try
  if not frmSurferSettings.ShowModal = mrOk then exit;
 finally
   frmSurferSettings.Free;
   frmSurferSettings := nil;
 end;
end;


procedure Tfrmclimhovmoeller.btnOpenFolderClick(Sender: TObject);
begin
 OpenDocument(PChar(HovmoellerPath));
end;


procedure Tfrmclimhovmoeller.btnOpenScriptClick(Sender: TObject);
Var
ScriptFile:string;
begin
 ScriptFile:=ExtractFilePath(HovmoellerPath)+'script.bas';
  if FileExists(ScriptFile) then OpenDocument(PChar(ScriptFile));
end;

end.
