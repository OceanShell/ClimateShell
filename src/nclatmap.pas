unit nclatmap;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, ExtCtrls, Spin, BufDataset, db, DateUtils, Variants;

type

  { Tfrmnclatmap }

  Tfrmnclatmap = class(TForm)
    btnGetTimeSeries: TButton;
    btnOpenFolder: TBitBtn;
    btnPlot: TButton;
    cbClr1: TComboBox;
    cbLevel1: TComboBox;
    cbLvl1: TComboBox;
    cbVariable: TComboBox;
    eAdditionalOffset: TEdit;
    eAdditionalScale: TEdit;
    eMaxLat: TEdit;
    eMaxLon: TEdit;
    eMinLat: TEdit;
    eMinLon: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label9: TLabel;
    semn1: TSpinEdit;
    semn2: TSpinEdit;

    procedure btnGetTimeSeriesClick(Sender: TObject);
    procedure btnPlotClick(Sender: TObject);
    procedure FormShow(Sender: TObject);

  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmnclatmap: Tfrmnclatmap;
  dat:text;
  ncLatMapPath:string;

implementation

{$R *.lfm}

uses ncmain, ncprocedures, surfer_ncfields, declarations_netcdf;

{ Tfrmnclatmap }

procedure Tfrmnclatmap.FormShow(Sender: TObject);
Var
  fdb:TSearchRec;
begin
 cbVariable.Items :=  frmmain.cbVariables.items; // copy variable names
 cbLevel1.Items    := frmmain.cbLevels.items;    // levels

 // enable/disable levels - if there are some
 if cbLevel1.Items.Count=0 then cbLevel1.Enabled:=false;

 ncLatMapPath:=GlobalPath+'unload\isolatanomalies\';
 if not DirectoryExists(ncLatMapPath) then CreateDir(ncLatMapPath);
 if not DirectoryExists(ncLatMapPath+'\png\') then CreateDir(ncLatMapPath+'\png\');
 if not DirectoryExists(ncLatMapPath+'\srf\') then CreateDir(ncLatMapPath+'\srf\');
 if not DirectoryExists(ncLatMapPath+'\grd\') then CreateDir(ncLatMapPath+'\grd\');

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



procedure Tfrmnclatmap.btnGetTimeSeriesClick(Sender: TObject);
Var
  status, ncid, varidp, ndimsp, mni, a:integer;
  tt, ll, lati, loni, kf, cnt, i, yy_min, yy_max, lt_i, ln_i:integer;
  AddScale, AddOffset:real;
  attname:array of pAnsiChar;

  Lat1, Lon1, Val1, x, y: real;

  scale, offset, missing: array [0..0] of single;
  scale_ex, offset_ex, missing_ex: boolean;
  atttext: array of pansichar;
  varnattsp:integer;
  attlenp, lenp:size_t;
  vtype :nc_type;
   fp:array of single;
   sp:array of smallint;
   ip:array of integer;
   dp:array of double;
  start: PArraySize_t;

  val0, Int_val:real;

  yy, mn, dd, hh, mm, ss, ms:word;
  mn_str, f_name:string;
  nclatmapcds:TBufDataSet;
 lt_av:real;
begin
btnGetTimeSeries.Enabled:=false;
btnOpenFolder.Enabled:=false;

AssignFile(dat, nclatmappath+'data.dat'); rewrite(dat);
writeln(dat, 'Lat':15, 'Lon':15, 'Anom':15);

  for lt_i:=0 to high(ncLat_arr)-1 do begin

   if (ncLat_arr[lt_i]>=StrToFloat(eMinLat.Text)) and (ncLat_arr[lt_i]<=StrToFloat(eMaxLat.Text)) then begin

   nclatmapcds:=TBufDataSet.Create(nil);
     with nclatmapcds.FieldDefs do begin
      Add('ln'   ,ftFloat, 0, false);
      Add('val'  ,ftFloat, 0, false);
    end;
    nclatmapcds.CreateDataSet;


    nclatmapcds.First;
    for ln_i:=0 to high(nclon_arr)-1 do begin
      with nclatmapcds do begin
        Append;
          Fieldbyname('ln').asFloat:=ncLon_arr[ln_i];
        Post;
      end;
    end;


    for kf:=0 to frmmain.cbFiles.Count-1 do begin
     ncName:=frmmain.cbFiles.Items.Strings[kf];

     cnt:=0;
     try
      status:=nc_open(pchar(ncpath+ncname), NC_NOWRITE, ncid); // only for reading
       if status>0 then showmessage(pchar(nc_strerror(status)));

        nc_inq_varid (ncid, pChar(cbVariable.Text), varidp); // variable ID
        nc_inq_vartype  (ncid, varidp, vtype);
        nc_inq_varndims (ncid, varidp, ndimsp);

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
    end;

   if scale_ex   = false then scale[0]:=1;
   if offset_ex  = false then offset[0]:=0;
   if missing_ex = false then missing[0]:=-9999;
   nc_inq_dimlen (ncid, timeDid, lenp);
    setlength(ncTime_arr, lenp);
    nc_get_var_double (ncid, timeVid, ncTime_arr);

   nc_inq_attlen (ncid, timeVid, pansichar(AnsiString('units')), attlenp);
   setlength(atttext, attlenp);
   nc_get_att_text (ncid, timeVid, pansichar(AnsiString('units')), atttext);

   GetDates(pansichar(atttext));

   if eAdditionalScale.Text<>''  then AddScale := StrToFloat(eAdditionalScale.Text)  else AddScale:=1;
   if eAdditionalOffset.Text<>'' then AddOffset:= StrToFloat(eAdditionalOffset.Text) else AddOffset:=0;

   start:=GetMemory(SizeOf(TArraySize_t)*ndimsp); // get memory for start pointer

   for tt:=0 to high(ncTime_arr) do begin
    DecodeDateTime(StrToDateTime(frmmain.cbDates.Items.Strings[tt]), yy, mn, dd, hh, mm, ss, ms);

     if (mn>=semn1.Value) and (mn<=semn2.Value) then begin
     nclatmapcds.first;
     for ln_i:=0 to high(ncLon_arr)-1 do begin
      if ndimsp=2 then begin
       start^[0]:=lt_i;  //lat
       start^[1]:=ln_i;  //lon
      end;
      if ndimsp=3 then begin
       start^[0]:=tt;    //time
       start^[1]:=lt_i; //lat
       start^[2]:=ln_i;  //lon
      end;
      if ndimsp=4 then begin
       start^[0]:=tt;    //time
       start^[1]:=cbLevel1.ItemIndex; //level
       start^[2]:=lt_i;   //lat
       start^[3]:=ln_i;   //lon
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
         //   showmessage(floattostr(val1));
         with nclatmapcds do begin
           Edit;
            Fieldbyname('val').asFloat:=Fieldbyname('val').asFloat+Val1;
           Post;
          Next;
         end;
         inc(cnt);
       end;
     end; //lon
    end; // month
   end; // time

  finally
  status:=nc_close(ncid);  // Close file
   if status>0 then showmessage(pansichar(nc_strerror(status)));
  FreeMemory(start);
  end;

   end; //file;

   nclatmapcds.first;
   lt_av:=0;
   while not nclatmapcds.eof do begin
     lt_av:=lt_av+nclatmapcds.fieldbyname('Val').asfloat/cnt;
    nclatmapcds.next;
   end;
   lt_av:=lt_av/nclatmapcds.recordCount;

   nclatmapcds.first;
   while not nclatmapcds.eof do begin
     Lat1:=ncLat_arr[lt_i];
     Lon1:=nclatmapcds.fieldbyname('ln').asfloat;
     Val1:=(nclatmapcds.fieldbyname('Val').asfloat/cnt)-lt_av;

      x:= (90-Lat1)*111.12*sin((Lon1)*Pi/180);
      y:=-(90-Lat1)*111.12*cos((Lon1)*Pi/180);
      writeln(dat, Lat1:15:5, Lon1:15:5, y:15:5, x:15:5, val1:15:5);

    nclatmapcds.next;
   end;
   nclatmapcds.Free;

   end; //min-max latitude


  end; //lat
  CloseFile(dat);
  btnGetTimeSeries.Enabled:=true;
end;


procedure Tfrmnclatmap.btnPlotClick(Sender: TObject);
Var
 Contour, ncexportfile, src1, lev1, clr1, grd1:string;
 XMin, XMax, YMin, YMax:real;
begin
Contour:=lowercase(GlobalPath+'support\bln\World.bln');
ncexportfile:=copy(ncname,1, length(ncname)-4);

 src1:=ncLatMapPath+'data.dat';
 grd1:=ncLatMapPath+'data.grd';

 if (cbLvl1.ItemIndex>-1) then Lev1:=GlobalPath+'support\lvl\'+cbLvl1.Text else Lev1:='';
 if (cbclr1.ItemIndex>-1) then clr1:=GlobalPath+'support\clr\'+cbclr1.Text else clr1:='';

 XMin:=-90;
 XMax:= 90;
 YMin:=-180;
 YMax:= 180;

GetncFieldScript(ncLatMapPath, src1, '', '', grd1, '', '', lev1, clr1, contour,
                 '', 100, 100, false, XMin, XMax, YMin, YMax, ncexportfile,
                 false, 0, '', false, curve);

{$IFDEF WINDOWS}
  frmmain.RunScript(2, '"'+ncLatMapPath+'script.bas"', nil);
{$ENDIF}

end;




end.

