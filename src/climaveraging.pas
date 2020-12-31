unit climaveraging;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, BufDataSet, Spin, ExtCtrls, ComCtrls, FileUtil;

type
  Tfrmclimaveraging = class(TForm)
    ListBox2: TListBox;
    ListBox1: TListBox;
    GroupBox1: TGroupBox;
    Edit1: TEdit;
    btnSurferPath: TButton;
    rbPeriods: TRadioGroup;
    GroupBox3: TGroupBox;
    Label8: TLabel;
    Label17: TLabel;
    eAvError: TEdit;
    seMinNods: TSpinEdit;
    rbParameters: TRadioGroup;
    GroupBox2: TGroupBox;
    Edit2: TEdit;
    Button1: TButton;
    btnStep1: TButton;
    btnStep2: TButton;

    procedure FormShow(Sender: TObject);
    procedure btnStep1Click(Sender: TObject);
    procedure btnStep2Click(Sender: TObject);

  private
    { Private declarations }
    Procedure CreateOutputNC(par:string; yy1, yy2, mn1, mn2:integer);

    Procedure GetMeanField1(param:string; mn:integer);
    Procedure GetMeanField2(param:string);

    Procedure GetFileList1(mn, ll:integer);
    Procedure GetFileList2;
  public
    { Public declarations }
  end;

var
  frmclimaveraging: Tfrmclimaveraging;
  ncVal_arr, ncErr_arr, ncSd_arr:array of single;
  dat1, out1:text;
  ncAvPath:string;
  step1:boolean;

implementation

{$R *.lfm}

uses ncmain, ncprocedures, declarations_netcdf;


procedure Tfrmclimaveraging.FormShow(Sender: TObject);
Var
 k, k_f, firstdot:integer;
 fname, par, dd, lev:string;
 yy, y1, y2, mm, m1, m2,  ll, l1, l2:integer;
begin
 y1:=9999; y2:=0;
 m1:=12;   m2:=1;
 l1:=99999; l2:=0;

 // Перебираем исходные файлы, определяем годы, месяцы и горизонты
  for k_f:=0 to frmmain.cbFiles.Count-1 do begin
  ncName:=frmmain.cbFiles.Items.Strings[k_f];

    //Temperature.19001900.0101.10029.10029.anl.nc
  firstdot:=Pos('.', fname);
   par:=copy(fname, 1, firstdot-1);
   yy:=strtoint(copy(fname,firstdot+1, 4));
     if yy<y1 then y1:=yy;
     if yy>y2 then y2:=yy;
   mm:=strtoint(copy(fname,firstdot+10, 2));
     if mm<m1 then m1:=mm;
     if mm>m2 then m2:=mm;
   dd:=copy(fname,(firstdot+15), 5);
    IndToDepth(dd, lev);
    ll:=strtoint(lev); //strtoint(dd);
     if ll<l1 then l1:=ll;
     if ll>l2 then l2:=ll;
 end;
end;


//Первый шаг
procedure Tfrmclimaveraging.btnStep1Click(Sender: TObject);
Var
years, m_str, fname, par:string;
yy1, yy2, mn, k_par, k_per, c:integer;
begin
 step1:=true;

// for k_par:=rbParameters.ItemIndex to rbParameters.Items.Count-1 do begin
  par:=rbParameters.Items.Strings[rbParameters.ItemIndex];
  c:=rbPeriods.ItemIndex;
  k_per:=6;
 // for k_per:=c to rbPeriods.Items.Count-1 do begin
   rbPeriods.ItemIndex:=k_per;
   application.ProcessMessages;

   years:=rbPeriods.Items.Strings[rbPeriods.ItemIndex];
     yy1:=StrToInt(copy(years, 1, 4));
     yy2:=StrToInt(copy(years, 6, 4));

    for mn:=1 to 12 do begin
      CreateOutputNC(par, yy1, yy2, mn, mn);
    end;// month

 // end; //periods
// end; //parameters
  OpenDocument(PChar(GlobalPath+'unload\ncaveraging\'));
 step1:=false;
end;


Procedure  Tfrmclimaveraging.GetFileList1(mn, ll:integer);
Var
 fdb:TSearchRec;
 ll_str, mn_str, fname, par, years:string;
 k, yy, mn2, firstdot:integer;
 yy1, yy2:integer;
begin
  if ll<10 then ll_str:='0'+inttostr(ll) else ll_str:=inttostr(ll);
  if mn<10 then mn_str:='0'+inttostr(mn) else mn_str:=inttostr(mn);

  years:=rbPeriods.Items.Strings[rbPeriods.ItemIndex];
  yy1:=StrToInt(copy(years, 1, 4));
  yy2:=StrToInt(copy(years, 6, 4));

  if ncAvPath<>'' then begin
   fdb.Name:='';
   listbox1.Clear;
    FindFirst(ncAvPath+'\'+ll_str+'\*.nc',faAnyFile,fdb); { *Converted from FindFirst* }
   if fdb.Name<>'' then listbox1.Items.Add(fdb.Name);
  while FindNext(fdb) { *Converted from FindNext* }=0 do Listbox1.Items.Add(fdb.Name);
   FindClose(fdb); { *Converted from FindClose* }
  end;

  ListBox2.Clear;
  for k:=0 to ListBox1.Count-1 do begin
   fname:=ListBox1.Items.Strings[k];
      //Temperature.19001900.0101.10029.10029.anl.nc
     firstdot:=Pos('.', fname);
     par:=copy(fname, 1, firstdot-1);
      yy:=strtoint(copy(fname,firstdot+1, 4));
      mn2:=strtoint(copy(fname, firstdot+10, 2));
     // showmessage(inttostr(mn2));
    if (yy>=yy1) and (yy<=yy2) and
       (mn=mn2) then
       ListBox2.Items.Add(fname);
  end;
end;



procedure Tfrmclimaveraging.GetMeanField1(param:string; mn:integer);
Var
ncAvCDS:TBufDataSet;

i, j, id, lev, ff, lt, ln, ll: integer;
k, ncid2, varidp, c_glob_arr, cnt, tp: integer;
varidp1, varidp3, ndimsp:integer;
fp, er:array of single;
start: PArraySize_t;
fname, fdataname:string;
lat1, lon1, val1, val2, dsd:real;
vmin, vmax, vavs, vav:real;
lat, lon:real;
ll_str:string;
begin


 ncAvCDS:=TBufDataSet.Create(nil);
   with ncAvCDS.FieldDefs do begin
    Add('ID',      ftInteger, 0, false);
    Add('lat',     ftfloat,   0, false);
    Add('lon',     ftfloat,   0, false);
    Add('val',     ftFloat,   0, false);
    Add('val2',    ftFloat,   0, false);
    Add('cnt',     ftInteger, 0, false);
     for k := 1 to 12 do Add(Inttostr(k), ftboolean, 0, false);
   end;
  ncAvCDS.CreateDataSet;

 // frmmain.ProgressBar1.Position:=0;
//  frmmain.ProgressBar1.Max:=29;

 SetLength(ncVal_arr, 0);
 SetLength(ncErr_arr, 0);
 SetLength(ncSd_arr,  0);

 SetLength(ncVal_arr, (104*476*29)); //массивы переменных
 SetLength(ncErr_arr, (104*476*29));
 SetLength(ncSd_arr,  (104*476*29));


  c_glob_arr:=0;
  for ll := 1 to 29  do begin  //levels loop

  if ll<10 then ll_str:='0'+inttostr(ll) else ll_str:=inttostr(ll);

  GetFileList1(mn, ll);

  Application.ProcessMessages;


 // ncAvCDS.EmptyDataSet; !!!

   lat:=58;
    for i:=0 to 104-1 do begin
      lon:=-47;
       for j:=0 to 476-1 do begin
         inc(id);
          ncAvCDS.Append;
           ncAvCDS.FieldByName('ID').AsInteger:=ID;
           ncAvCDS.FieldByName('lat').AsFloat:=lat;
           ncAvCDS.FieldByName('lon').AsFloat:=lon;
            for k := 1 to 12 do  ncAvCDS.FieldByName(inttostr(k)).AsBoolean:=false;
           ncAvCDS.Post;
        lon:=lon+0.25;
       end;
       lat:=lat+0.25;
    end;



 for ff:=0 to ListBox2.Count-1 do begin

   fName    :=ncAvPath+'\'+ll_str+'\'+ListBox2.Items.Strings[ff];
   fdataname:=ncAvPath+'\'+ll_str+'\Data\'+copy(ListBox2.Items.Strings[ff],1, length(ListBox2.Items.Strings[ff])-13);



 (* берем границы изменчивости из начальных данных *)
  AssignFile(dat1, fdataname); reset(dat1);
  vmin:=9999; vmax:=-9999; vavs:=0; vav:=0; cnt:=0;
  repeat
   readln(dat1, lat1, lon1, val1);
    if val1<vmin then vmin:=val1;
    if val1>vmax then vmax:=val1;
     vavs:=vavs+val1;
      inc(cnt);
  until eof(dat1);
  vav:=vavs/cnt;
  vmin:=vmin-(vmin*10/100);
  vmax:=vmax+(vmax*10/100);
  CloseFile(dat1);
 (* конец определения границ физической изменчивости *)

  try
   nc_open(pansichar(AnsiString(fname)), NC_NOWRITE, ncid2); // only for reading

    nc_inq_varid (ncid2, pAnsiChar(AnsiString(param)), varidp1); // variable
    nc_inq_varid (ncid2, pAnsiChar(AnsiString(param+'_relerr')), varidp3); // relative error

    tp:=varidp1;
     nc_inq_varndims (ncid2, tp, ndimsp);
     start:=GetMemory(SizeOf(TArraySize_t)*ndimsp); // get memory for start pointer
    varidp:=tp;

  //  showmessage(inttostr(ndimsp));

   ncAvCDS.First;
    for lt:=0 to 104-1 do begin

       for ln:=0 to 476-1 do begin
        start^[0]:=0;
        start^[1]:=0;  //lon
        start^[2]:=lt;
        start^[3]:=ln;

          SetLength(fp, 1);
          SetLength(er, 1);

           nc_get_var1_float(ncid2, varidp1, start^, fp);     //2
           nc_get_var1_float(ncid2, varidp3, start^, er);     //3

        //    showmessage(floattostr(fp[0])+'   '+floattostr(er[0]));

           if (fp[0]<>-9999) and (er[0]<=Strtofloat(eAvError.Text)) then begin
            if (fp[0]>=vmin) and (fp[0]<=vmax) then begin
             ncAvCDS.edit;
              ncAvCDS.FieldByName('val').AsFloat:=ncAvCDS.FieldByName('val').AsFloat+fp[0];
              ncAvCDS.FieldByName('val2').AsFloat:=ncAvCDS.FieldByName('val2').AsFloat+(fp[0]*fp[0]);
              ncAvCDS.FieldByName('cnt').AsInteger:=ncAvCDS.FieldByName('cnt').AsInteger+1;
              ncAvCDS.FieldByName(inttostr(mn)).AsBoolean:=true;
             // if (ncLon_arr[ln]>=60) then showmessage(inttostr(mn)+'   '+floattostr(ep[0]));

             ncAvCDS.Post;
            end;

            if  (fp[0]<vmin) or (fp[0]>vmax) then begin
            // writeln(out1, fname, ncLat_arr[lt]:15:5, ncLon_arr[ln]:15:5, vmin:10:3, vmax:10:3, fp[0]:10:3);
            end;
           end;

         ncAvCDS.Next;
         end;
      end;
  FreeMemory(start);

 finally
  fp:=nil;
  er:=nil;
   nc_close(ncid2);  // Close file
 end;
 end;

  ncAvCDS.First;
  val1:=0; val2:=0; dsd:=0; cnt:=0;
    for lt:=0 to 104-1 do begin
       for ln:=0 to 476-1 do begin
         val1:=ncAvCDS.FieldByName('val').AsFloat;
         val2:=ncAvCDS.FieldByName('val2').AsFloat;
         cnt :=ncAvCDS.FieldByName('cnt').AsInteger;

          if cnt>=seMinNods.Value then begin
             ncVal_arr[c_glob_arr]:=val1/cnt;
             dsd:=(Val2-Val1*Val1/cnt)/(cnt); //Дисперсия
              if dsd>0 then begin
                ncSd_arr[c_glob_arr] :=sqrt(dsd); // Теперь это Средне Квадратичное отклонение
                ncErr_arr[c_glob_arr]:=dsd/sqrt(cnt); // Ошибка среднего !!! *** Standard Error of the Mean ***
              end;
          end else begin //если условие не прошло
           ncVal_arr[c_glob_arr]:=-9999;
           ncErr_arr[c_glob_arr]:=-9999;
           ncSD_arr[c_glob_arr] :=-9999;
          end;

          inc(c_glob_arr);
         ncAvCDS.Next;
         end;

      end;
   // frmncmain.ProgressBar1.Position:=ll;
  //  Application.ProcessMessages;
  end; //конец цикла по горизонтам
end;



//Второй шаг
procedure Tfrmclimaveraging.btnStep2Click(Sender: TObject);
Var
years, m_str, fname, par:string;
yy1, yy2, mn, k_par, k_per:integer;
begin
step1:=false;
 if not DirectoryExists(GlobalPath+'unload\ncAveraging\') { *Converted from DirectoryExists* } then CreateDir(GlobalPath+'unload\ncAveraging\'); { *Converted from CreateDir* }

  par:=rbParameters.Items.Strings[rbParameters.ItemIndex];

 // k_per:=2;  //тестовый период  1950-2000
  for k_per:=rbPeriods.ItemIndex to rbPeriods.Items.Count-1 do begin
   rbPeriods.ItemIndex:=k_per;

   years:=rbPeriods.Items.Strings[rbPeriods.ItemIndex];
     yy1:=StrToInt(copy(years, 1, 4));
     yy2:=StrToInt(copy(years, 6, 4));

      CreateOutputNC(par, yy1, yy2, 1, 12);

  end; //periods
// end; //parameters
  OpenDocument(PChar(GlobalPath+'unload\ncAveraging\')); { *Converted from ShellExecute* }
 step1:=false;
end;


Procedure  Tfrmclimaveraging.GetFileList2;
Var
 fdb:TSearchRec;
 ll_str, mn_str, fname, par, years:string;
 k, yy, mn2, firstdot:integer;
 yy01, yy02, yy11, yy12:integer;
begin

  par:=rbParameters.Items.Strings[rbParameters.ItemIndex];

  years:=rbPeriods.Items.Strings[rbPeriods.ItemIndex];
  yy01:=StrToInt(copy(years, 1, 4));
  yy02:=StrToInt(copy(years, 6, 4));

  if ncAvPath<>'' then begin
   fdb.Name:='';
   listbox1.Clear;
    FindFirst(edit2.Text+Par+'\*.nc',faAnyFile,fdb); { *Converted from FindFirst* }
   if fdb.Name<>'' then listbox1.Items.Add(fdb.Name);
  while FindNext(fdb) { *Converted from FindNext* }=0 do Listbox1.Items.Add(fdb.Name);
   FindClose(fdb); { *Converted from FindClose* }
  end;

  ListBox2.Clear;
  for k:=0 to ListBox1.Count-1 do begin
   fname:=ListBox1.Items.Strings[k];
      //Temperature.19001900.0101.10029.10029.anl.nc
     firstdot:=Pos('.', fname);
     par:=copy(fname, 1, firstdot-1);
      yy11:=strtoint(copy(fname,firstdot+1, 4));
      yy12:=strtoint(copy(fname,firstdot+5, 4));

    {  showmessage(inttostr(yy01)+'   '+inttostr(yy02)+#13+
                  inttostr(yy11)+'   '+inttostr(yy12)); }

    if (yy01=yy11) and (yy02=yy12) then ListBox2.Items.Add(fname);
  end;
end;




procedure Tfrmclimaveraging.GetMeanField2(param:string);
Var
ncAvCDS:TBufDataSet;
ncAvDS:TDataSource;

i, j, id, lev, ff, lt, ln, ll, mn: integer;
k, ncid2, varidp2, c_glob_arr, cnt, tp: integer;
ndimsp2, firstdot:integer;
fp:array of single;
start: PArraySize_t;
fname, fdataname:string;
lat1, lon1, val1, val2, dsd:real;
vmin, vmax, vavs, vav:real;
lat, lon:real;
val0:variant;
ll_str:string;
begin


 ncAvCDS:=TBufDataSet.Create(nil);
   with ncAvCDS.FieldDefs do begin
    Add('ID',      ftInteger, 0, false);
    Add('lat',     ftfloat,   0, false);
    Add('lon',     ftfloat,   0, false);
    Add('val',     ftFloat,   0, false);
    Add('val2',    ftFloat,   0, false);
    Add('cnt',     ftInteger, 0, false);
     for k := 1 to 12 do Add(Inttostr(k), ftboolean, 0, false);
   end;
  ncAvCDS.CreateDataSet;


//  main.ProgressBar1.Position:=0;
//  main.ProgressBar1.Max:=29;


 SetLength(ncVal_arr, 0);
 SetLength(ncErr_arr, 0);
 SetLength(ncSd_arr,  0);

 SetLength(ncVal_arr, (104*476*29)); //массивы переменных
 SetLength(ncErr_arr, (104*476*29));
 SetLength(ncSd_arr,  (104*476*29));


  GetFileList2;
  Application.ProcessMessages;


  c_glob_arr:=0;
  for ll := 0 to 29-1  do begin  //levels loop
 // ll:=28;

  if ll<10 then ll_str:='0'+inttostr(ll) else ll_str:=inttostr(ll);

 // ncAvCDS.EmptyDataSet;  !!!!!

   lat:=58;
    for i:=0 to 104-1 do begin
      lon:=-47;
       for j:=0 to 476-1 do begin
         inc(id);
          ncAvCDS.Append;
           ncAvCDS.FieldByName('ID').AsInteger:=ID;
           ncAvCDS.FieldByName('lat').AsFloat:=lat;
           ncAvCDS.FieldByName('lon').AsFloat:=lon;
            for k := 1 to 12 do  ncAvCDS.FieldByName(inttostr(k)).AsBoolean:=false;
           ncAvCDS.Post;
        lon:=lon+0.25;
       end;
       lat:=lat+0.25;
    end;



 for ff:=0 to ListBox2.Count-1 do begin

   fName    :=edit2.Text+Param+'\'+ListBox2.Items.Strings[ff];
 //  showmessage(fname);

   firstdot:=Pos('.', ListBox2.Items.Strings[ff]);
   mn:=StrToInt(copy(ListBox2.Items.Strings[ff], firstdot+10, 2));

 //  showmessage(inttostr(mn));


  try
   nc_open(pansichar(AnsiString(fname)), NC_NOWRITE, ncid2); // only for reading

   nc_inq_varid (ncid2, pAnsiChar(AnsiString(param)), varidp2); // variable ID

   //КОСТЫЛЬ УБРАТЬ!!!
    tp:=varidp2;
    nc_inq_varndims (ncid2, tp, ndimsp2);
    varidp2:=tp;


   SetLength(fp, 1);
   start:=GetMemory(SizeOf(TArraySize_t)*ndimsp2); // get memory for start pointer
   ncAvCDS.First;

   if ndimsp2>2 then start^[0]:=0; //time
    for lt:=0 to 104-1 do begin
     if ndimsp2=2 then start^[0]:=lt;
     if ndimsp2=3 then start^[1]:=lt;  //lat
     if ndimsp2=4 then begin
      start^[1]:=ll;  //level
      start^[2]:=lt;  //lat
     end;

       for ln:=0 to 476-1 do begin
        if ndimsp2=2 then start^[1]:=ln;  //lon
        if ndimsp2=3 then start^[2]:=ln;  //lon
        if ndimsp2=4 then start^[3]:=ln;

       { showmessage(inttostr(ndimsp)+':'+
                    inttostr(start^[0])+#9+
                    inttostr(start^[1])+#9+
                    inttostr(start^[2]));   }


                 SetLength(fp, 1);
                  nc_get_var1_float(ncid2, varidp2, start^, fp);
                 Val0:=fp[0];

              //   if val0>0 then showmessage(floattostr(val0));


          if (Val0<>-9999) then begin
             ncAvCDS.edit;
              ncAvCDS.FieldByName('val').AsFloat:=ncAvCDS.FieldByName('val').AsFloat+fp[0];
              ncAvCDS.FieldByName('val2').AsFloat:=ncAvCDS.FieldByName('val2').AsFloat+(fp[0]*fp[0]);
              ncAvCDS.FieldByName('cnt').AsInteger:=ncAvCDS.FieldByName('cnt').AsInteger+1;
              ncAvCDS.FieldByName(inttostr(mn)).AsBoolean:=true;

            //  if (ncLon_arr[ln]>=60) then showmessage(inttostr(mn)+'   '+floattostr(fp[0]));

             ncAvCDS.Post;
            end;


         ncAvCDS.Next;
         end;
      end;
  FreeMemory(start);

 finally
  fp:=nil;
  //er:=nil;
   nc_close(ncid2);  // Close file
 end;
 end;  //lopp for files

//  dbgrideh1.DataSource:=ncAvDS;
//  exit;


  ncAvCDS.First;
  val1:=0; val2:=0; dsd:=0; cnt:=0;
    for lt:=0 to 104-1 do begin
       for ln:=0 to 476-1 do begin
         val1:=ncAvCDS.FieldByName('val').AsFloat;
         val2:=ncAvCDS.FieldByName('val2').AsFloat;
         cnt :=ncAvCDS.FieldByName('cnt').AsInteger;

        // Осреднение по годам - в общем
        { if   (ncAvCDS.FieldByName('1').AsBoolean =true or
               ncAvCDS.FieldByName('2').AsBoolean =true or
               ncAvCDS.FieldByName('3').AsBoolean =true) and
              (ncAvCDS.FieldByName('4').AsBoolean =true or
               ncAvCDS.FieldByName('5').AsBoolean =true or
               ncAvCDS.FieldByName('6').AsBoolean =true) and
              (ncAvCDS.FieldByName('7').AsBoolean =true or
               ncAvCDS.FieldByName('8').AsBoolean =true or
               ncAvCDS.FieldByName('9').AsBoolean =true) and
              (ncAvCDS.FieldByName('10').AsBoolean=true or
               ncAvCDS.FieldByName('11').AsBoolean=true or
               ncAvCDS.FieldByName('12').AsBoolean=true) then begin }

         if   (ncAvCDS.FieldByName('4').AsBoolean =true or
               ncAvCDS.FieldByName('5').AsBoolean =true or
               ncAvCDS.FieldByName('6').AsBoolean =true or
               ncAvCDS.FieldByName('7').AsBoolean =true or
               ncAvCDS.FieldByName('8').AsBoolean =true or
               ncAvCDS.FieldByName('9').AsBoolean =true) and

              (ncAvCDS.FieldByName('10').AsBoolean=true or
               ncAvCDS.FieldByName('11').AsBoolean=true or
               ncAvCDS.FieldByName('12').AsBoolean=true or
               ncAvCDS.FieldByName('1').AsBoolean =true or
               ncAvCDS.FieldByName('2').AsBoolean =true or
               ncAvCDS.FieldByName('3').AsBoolean =true) then begin
         // if cnt>1 then begin

             ncVal_arr[c_glob_arr]:=val1/cnt;
             dsd:=(Val2-Val1*Val1/cnt)/(cnt); //Дисперсия
              if dsd>0 then begin
                ncSd_arr[c_glob_arr] :=sqrt(dsd); // Теперь это Средне Квадратичное отклонение
                ncErr_arr[c_glob_arr]:=dsd/sqrt(cnt); // Ошибка среднего !!! *** Standard Error of the Mean ***
              end;
          end else begin //если условие не прошло
           ncVal_arr[c_glob_arr]:=-9999;
           ncErr_arr[c_glob_arr]:=-9999;
           ncSD_arr[c_glob_arr] :=-9999;
          end;


          inc(c_glob_arr);
         ncAvCDS.Next;
         end;
      end;
 //   main.ProgressBar1.Position:=ll+1;
 //   Application.ProcessMessages;

  end; //конец цикла по горизонтам

end;



// Создание выходного файла
procedure Tfrmclimaveraging.CreateOutputNC(par:string; yy1, yy2, mn1, mn2:integer);
Var
k, ncid, status, latidp, lonidp, i, j, ll: integer;
rh_dimids: PArraySize_t;
lonvaridp, latvaridp, valid, errid, sdid, timidp, depidp:integer;
timvaridp, depvaridp:integer;
lat_arr, Lon_arr, dep_arr, tim_arr: array of single;
lt, ln:real;
param, units, add_name, clim_name, years:string;
m_str1, m_str2, lstr1, lstr2, e_mails:string;
start: PArraySize_t;
fp, ep:array of single;
fname:string;
av_title, av_comment:string;
begin

if mn1<10 then m_str1:='0'+inttostr(mn1) else m_str1:=inttostr(mn1);
if mn2<10 then m_str2:='0'+inttostr(mn2) else m_str2:=inttostr(mn2);

fname:=Par+'.'+inttostr(yy1)+IntToStr(yy2)+'.'+m_str1+m_str2+'.nc';

assignfile(out1, GlobalPath+'unload\ncAveraging\'+fname+'_errors.dat'); rewrite(out1);
 writeln(out1, 'fname', 'Lat':15, 'Lon':15, 'vmin':10, 'vmax':10, 'val':10);


//showmessage(fname);

 try

  if rbParameters.ItemIndex=0 then begin
    param:='Temperature';
    units:='degree_C';
     if FileExists(pansichar('climt.nc')) then DeleteFile(pansichar('climt.nc')); { *Converted from DeleteFile* }
      status:=nc_create(pansichar('climt.nc'), 0, ncid); // only for reading
  end;
  if rbParameters.ItemIndex=1 then begin
    param:='Salinity';
    units:='';
     if FileExists(pansichar('clims.nc')) then DeleteFile(pansichar('clims.nc')); { *Converted from DeleteFile* }
      status:=nc_create(pansichar('clims.nc'), 0, ncid); // only for reading
  end;
  if rbParameters.ItemIndex=2 then begin
    param:='Density';
    units:='kg/m3';
     if FileExists(pansichar('climd.nc')) then DeleteFile(pansichar('climd.nc')); { *Converted from DeleteFile* }
      status:=nc_create(pansichar('climd.nc'), 0, ncid); // only for reading
  end;
  ncAvPath:=edit1.Text+param;

 {
   nc_def_dim (ncid, pansichar(AnsiString('lat')),  104, latidp);
   nc_def_dim (ncid, pansichar(AnsiString('lon')),  476, lonidp);
   nc_def_dim (ncid, pansichar(AnsiString('time')),   1, timidp);
   nc_def_dim (ncid, pansichar(AnsiString('depth')), 29, depidp);  //?

  rh_dimids:=GetMemory(SizeOf(TArraySize_t));
  // lon
  rh_dimids^[0]:= lonidp;
   nc_def_var(ncid, pansichar(AnsiString('lon')), NC_FLOAT, 1, rh_dimids^, lonvaridp);
   nc_put_att_text (ncid, lonvaridp, pansichar(AnsiString('units')), 12, pansichar(AnsiString('degrees_east')));

  // lat
  rh_dimids^[0]:= latidp;
   nc_def_var(ncid, pansichar(AnsiString('lat')), NC_FLOAT, 1, rh_dimids^, latvaridp);
   nc_put_att_text (ncid, latvaridp, pansichar(AnsiString('units')), 13, pansichar(AnsiString('degrees_north')));

   (* Depth *)
  rh_dimids^[0]:= depidp;
   nc_def_var(ncid, pansichar(AnsiString('depth')), NC_FLOAT, 1, rh_dimids^, depvaridp);
   nc_put_att_text (ncid, depvaridp, pansichar(AnsiString('units')), 6, pansichar(AnsiString('meters')));
   nc_put_att_text (ncid, depvaridp, pansichar(AnsiString('positive')), 4, pansichar(AnsiString('down')));


   (* Time *)
  rh_dimids^[0]:= timidp;
   nc_def_var(ncid, pansichar(AnsiString('time')), NC_FLOAT, 1, rh_dimids^, timvaridp);
   nc_put_att_text (ncid, timvaridp, pansichar(AnsiString('units')), 23, pansichar(AnsiString('Months since 1900-01-01')));

  rh_dimids:=GetMemory(SizeOf(TArraySize_t)*4);

  rh_dimids^[0]:= timidp;
  rh_dimids^[1]:= depidp;
  rh_dimids^[2]:= latidp;
  rh_dimids^[3]:= lonidp;


  nc_def_var(ncid, pansichar(AnsiString(param)), NC_FLOAT, 4, rh_dimids^, valid);
  nc_put_att_text  (ncid, valid, pansichar(AnsiString('long_name')),     length(param), pansichar(AnsiString(param)));
  nc_put_att_text  (ncid, valid, pansichar(AnsiString('units')),         length(units),  pansichar(AnsiString(units)));
 // nc_put_att_text  (ncid, valid, pansichar(AnsiString('_FillValue')),    5,  '-9999');
 // nc_put_att_text  (ncid, valid, pansichar(AnsiString('missing_value')), 5,  '-9999');

  nc_def_var(ncid, pansichar(AnsiString(param+'_err')), NC_FLOAT, 4, rh_dimids^, errid);
  add_name:='Standard error of the mean';
  nc_put_att_text  (ncid, errid, pansichar(AnsiString('long_name')),     length(add_name), pansichar(AnsiString(add_name)));
//  nc_put_att_text  (ncid, temeid, pansichar(AnsiString('units')),         length(units), pansichar(AnsiString(units)));
//  nc_put_att_text (ncid, errid, pansichar(AnsiString('_FillValue')),    5, '-9999');
//  nc_put_att_text (ncid, errid, pansichar(AnsiString('missing_value')), 5, '-9999');

  nc_def_var(ncid, pansichar(AnsiString(param+'_sd')), NC_FLOAT, 4, rh_dimids^, sdid);
  add_name:='Standard deviation';
  nc_put_att_text  (ncid, sdid, pansichar(AnsiString('long_name')),     length(add_name), pansichar(AnsiString(add_name)));
//  nc_put_att_text  (ncid, temeid, pansichar(AnsiString('units')),         length(units), pansichar(AnsiString(units)));
//  nc_put_att_text (ncid, sdid, pansichar(AnsiString('_FillValue')),    5, '-9999');
//  nc_put_att_text (ncid, sdid, pansichar(AnsiString('missing_value')), 5, '-9999');
}

  // global attributes
  e_mails:='alexandera.korablev@gmail.com; alexander.vic.smirnov@gmail.com';
  av_title  :='Mean field of '+par+' for '+IntToStr(yy1)+'-'+IntToStr(yy2);
  av_comment:='mn:'+m_str1+'-'+m_str2;

  nc_put_att_text (ncid, NC_GLOBAL, pansichar(AnsiString('project')),      length('GODAR'), pansichar(AnsiString('GODAR')));
  nc_put_att_text (ncid, NC_GLOBAL, pansichar(AnsiString('institution')),  length('AARI'), pansichar(AnsiString('AARI')));
  nc_put_att_text (ncid, NC_GLOBAL, pansichar(AnsiString('production')),   length(e_mails), pansichar(AnsiString(e_mails)));
  nc_put_att_text (ncid, NC_GLOBAL, pansichar(AnsiString('date')),         length(DateToStr(now)), pansichar(AnsiString(DateToStr(now))));
  nc_put_att_text (ncid, NC_GLOBAL, pansichar(AnsiString('title')),        length(param+' 4D analysis'), pansichar(AnsiString(param+' 4D analysis')));
  nc_put_att_text (ncid, NC_GLOBAL, pansichar(AnsiString('source')),       length('ODB_NA'), pansichar(AnsiString('ODB_NA')));
  nc_put_att_text (ncid, NC_GLOBAL, pansichar(AnsiString('comment')),      length('No comment'), pansichar(AnsiString('No comment')));
  nc_put_att_text (ncid, NC_GLOBAL, pansichar(AnsiString('history')),      length('No history'), pansichar(AnsiString('No history')));

  nc_enddef(ncid);  // change to data mode

   setlength(lat_arr, 104);
   lt:=58;
    for k:=0 to 104-1 do begin
     lat_arr[k]:=lt;
     lt:=lt+0.25;
    end;
     nc_put_var_float(ncid, latvaridp, lat_arr);

    setlength(lon_arr, 476);
   ln:=-47;
    for k:=0 to 476-1 do begin
     lon_arr[k]:=ln;
     ln:=ln+0.25;
    end;
     nc_put_var_float(ncid, lonvaridp, lon_arr);


    setlength(tim_arr, 1);

    // количество месяцев с 01.01.1900
    tim_arr[0]:=(((yy2+yy1)/2)-1900)*12+mn1-1;
    nc_put_var_float(ncid, timvaridp, tim_arr);

    setlength(dep_arr, 29);
    for k:=1 to 29 do begin
      case k of
       29: dep_arr[k-1]:=0;
       28: dep_arr[k-1]:=10;
       27: dep_arr[k-1]:=20;
       26: dep_arr[k-1]:=30;
       25: dep_arr[k-1]:=50;
       24: dep_arr[k-1]:=75;
       23: dep_arr[k-1]:=100;
       22: dep_arr[k-1]:=125;
       21: dep_arr[k-1]:=150;
       20: dep_arr[k-1]:=200;
       19: dep_arr[k-1]:=250;
       18: dep_arr[k-1]:=300;
       17: dep_arr[k-1]:=400;
       16: dep_arr[k-1]:=500;
       15: dep_arr[k-1]:=600;
       14: dep_arr[k-1]:=700;
       13: dep_arr[k-1]:=800;
       12: dep_arr[k-1]:=900;
       11: dep_arr[k-1]:=1000;
       10: dep_arr[k-1]:=1100;
       9:  dep_arr[k-1]:=1200;
       8:  dep_arr[k-1]:=1300;
       7:  dep_arr[k-1]:=1400;
       6:  dep_arr[k-1]:=1500;
       5:  dep_arr[k-1]:=1750;
       4:  dep_arr[k-1]:=2000;
       3:  dep_arr[k-1]:=2500;
       2:  dep_arr[k-1]:=3000;
       1:  dep_arr[k-1]:=3500;
      end;
    end;
    nc_put_var_float(ncid, depvaridp, dep_arr);

    if step1=true  then GetMeanField1(param, mn1);
    if step1=false then GetMeanField2(param);

     nc_put_var_float(ncid, valid,  ncVal_arr);
     nc_put_var_float(ncid, errid,  ncErr_arr);
     nc_put_var_float(ncid, sdid,   ncSD_arr);


 finally
  nc_close(ncid);  // Close file
   if rbParameters.ItemIndex=0 then begin
    if copyfile(pchar('climt.nc'), pchar(GlobalPath+'unload\ncaveraging\'+fname))=true then
       deletefile(pchar('climt.nc'));
   end;
   if rbParameters.ItemIndex=1 then begin
    if copyfile(pchar('clims.nc'), pchar(GlobalPath+'unload\ncaveraging\'+fname))=true then
       deletefile(pchar('clims.nc'));
   end;
   if rbParameters.ItemIndex=2 then begin
    if copyfile(pchar('climd.nc'), pchar(GlobalPath+'unload\ncaveraging\'+fname))=true then
       deletefile(pchar('climd.nc'));
   end;

   closefile(out1);
 end;
end;


end.
