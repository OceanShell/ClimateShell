unit climtdd;

{$mode objfpc}{$H+}

interface

uses
  Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Spin, StdCtrls, Math, DateUtils, ExtCtrls, CheckLst, DB, BufDataSet;

type

  { Tfrmclimtdd }

  Tfrmclimtdd = class(TForm)
    GroupBox1: TGroupBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    GroupBox2: TGroupBox;
    cbVariable: TComboBox;
    btnGetTimeSeries: TButton;
    GroupBox3: TGroupBox;
    Label4: TLabel;
    Label6: TLabel;
    seYYmin: TSpinEdit;
    seYYMax: TSpinEdit;
    btnPlot: TButton;
    GroupBox5: TGroupBox;
    btnSettings: TButton;
    rbPlot: TRadioGroup;
    Label1: TLabel;
    seMnMin: TSpinEdit;
    seMnMax: TSpinEdit;

    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure GetTLDValues(fname: string);
    procedure btnGetTimeSeriesClick(Sender: TObject);
    procedure btnPlotClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
 //   procedure FormClose(Sender: TObject; var Action: TCloseAction);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmclimtdd: Tfrmclimtdd;
  tldUnload, IniDataFile:string;
  tldYYMin, tldYYMax:integer;
  fout1, fout2:text;
  nctldCDS:TBufDataSet;
  nctldDS:TDataSource;

implementation

{$R *.lfm}

uses ncmain, ncprocedures, surfer_settings, declarations_netcdf;


procedure Tfrmclimtdd.FormShow(Sender: TObject);
Var
  k:integer;
  LatMin, LatMax, LonMin, LonMax : real;
begin
 tldUnload:=GlobalPath+'unload\nctldiagrams\'+ncname+'\';
  if not DirectoryExists(tldUnload) then CreateDir(tldUnload);

 if ncName='' then begin
   btnGetTimeSeries.Enabled:=false;
   exit;
 end;

 cbVariable.Items := frmmain.cbVariables.items; // copy variable names

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

  nctldCDS:=TBufDataSet.Create(nil);
   with  nctldCDS.FieldDefs do begin
    Add('YY'  ,ftInteger, 0, true);
    Add('MN'  ,ftInteger, 0, true);
    Add('LEV' ,ftFloat  , 0, true);
    Add('VAL' ,ftFloat  , 0, true);
   end;
  nctldCDS.CreateDataSet;
 // nctldCDS.LogChanges:=false;

  nctldDS:=TDataSource.Create(nil);
  nctldDS.DataSet:=nctldCDS;

   //dbgrideh1.DataSource:=nctldDS;
end;




procedure Tfrmclimtdd.btnGetTimeSeriesClick(Sender: TObject);
Var
  kf, fl, lv:integer;
  vals:real;
begin

 if cbVariable.ItemIndex=-1 then exit; // exit if a variable isn't selected

// fl:=0;
//  for kf:=0 to clbMN.Count-1 do if clbMN.Checked[kf] then fl:=1;
// if fl=0 then exit; //exit if no month is selected


 btnGetTimeSeries.Enabled:=false;
 //nctldCDS.EmptyDataSet;


  tldYYMin:=3000;
  tldYYMax:=1000;
  try
   { ncCDSFiles.First;
    while not ncCDSFiles.Eof do begin
     ncName:=ncCDSFiles.FieldByName('fname').AsString;
      GetTLDValues(ncpath+ncname);
     ncCDSFiles.Next;
    end;    }
   seYYMin.Value:=tldYYMin;
   seYYMax.Value:=tldYYMax;

   seYYMin.MinValue:=seYYMin.Value;  // set years range for year begin
   seYYMin.MaxValue:=seYYMax.Value;

   seYYMax.MinValue:=seYYMin.Value; // set years range for year end
   seYYMax.MaxValue:=seYYMax.Value;

    AssignFile(fout1, tldUnload+'Ini.txt');  Rewrite(fout1);
    writeln(fout1, 'YY':5, 'Lev':6, 'Val':15);

        for kf:=tldYYMin to tldYYMax do begin
         for lv:=0 to high(ncLev_arr)  do begin


           nctldcds.Filtered:=false;
            if seMnMin.Value<=seMnMax.Value then begin
              nctldcds.Filter:='YY='+inttostr(kf)+' and LEV='+floattostr(ncLev_arr[lv]);
            end;

            if seMnMin.Value>seMnMax.Value then begin
              nctldcds.Filter:='LEV='+floattostr(ncLev_arr[lv])+
              ' and ((YY='+inttostr(kf)  +' and MN>='+inttostr(seMnMin.Value)+')'+
              ' or  (YY='+inttostr(kf+1)+' and MN<='+inttostr(seMnMax.Value)+'))';
           //   showmessage(nctldcds.Filter);
            end;

           nctldcds.Filtered:=true;

           nctldcds.First;
           vals:=0;
           while not nctldcds.Eof do begin
            vals:=vals+nctldcds.FieldByName('Val').AsFloat;
            nctldcds.Next;
           end;

          if nctldcds.RecordCount>0 then begin
              writeln(fout1, kf:5,   ncLev_arr[lv]:6:0, (vals/nctldcds.RecordCount):15:3);
          end;
        end;
    end;

  finally
   CloseFile(fout1);
  end;
 btnGetTimeSeries.Enabled:=true;
 btnPlot.Enabled:=true;

end;



procedure Tfrmclimtdd.btnPlotClick(Sender: TObject);
Var
  k:integer;
  yy, mn, dd, hh, mm, ss, ms:real;
  cnt, Col, NCols, NRows:integer;
  DFile, lev_s,  tldtsUnload:string;
  val1, lev1, sum, koef, lev_m:real;
  IntLev,tldMaxLev, tldMinLev:integer;
  LevMean:array of real;
begin
  SetLength(LevMean, frmmain.cbLevels.Count); // length of mean array

  tldMaxLev:=StrToInt(frmmain.cbLevels.Items.Strings[frmmain.cbLevels.Count-1]);
  tldMinLev:=StrToInt(frmmain.cbLevels.Items.Strings[0]);

  (* Calculate mean values for each level *)
  for k:=0 to frmmain.cbLevels.Count-1 do begin  //loop for levels
   IntLev:=StrToInt(frmmain.cbLevels.Items.Strings[k]);

   AssignFile(fout1, tldUnload+'Ini.txt'); Reset(fout1); // file with values
   readln(fout1); // skip header

   sum:=0; cnt:=0;
   repeat
    readln(fout1, yy, lev1, val1);
    if (yy>=seYYMin.Value) and (yy<=seYYMax.Value) and
       (IntLev=lev1) then begin
       sum:=sum+val1;
      inc(cnt);
    end;
   until eof(fout1);
   if cnt>0 then LevMean[k]:=sum/cnt;
  CloseFile(fout1);   // close initial file;
 end;

 tldtsUnload:=tldUnload+'ts\';
  if not DirectoryExists(tldtsUnload) then CreateDir(tldtsUnload);

 (* Create time series for each level *)
  for k:=0 to frmmain.cbLevels.Count-1 do begin  //loop for levels
   IntLev:=StrToInt(frmmain.cbLevels.Items.Strings[k]);

   AssignFile(fout1, tldUnload+'Ini.txt'); Reset(fout1); // file with values
   readln(fout1); // skip header

   // Файлы для временных серий
    lev_s:=IntToStr(IntLev);
     Case length(lev_s) of
      1: lev_s:='000'+Lev_s;
      2: lev_s:='00'+lev_s;
      3: lev_s:='0'+lev_s
     end;

    AssignFile(fout2, tldtsUnload+lev_s+'.txt'); rewrite(fout2);
    WriteLn(fout2, 'YY':5, 'Value':15, 'Anomaly':15);

    repeat
     readln(fout1, yy, lev1, val1);
      if (IntLev=lev1) then begin
         writeln(fout2, YY:5:0, val1:15:3, (val1-levMean[k]):15:3);
      end;
    until eof(fout1);
  CloseFile(fout2);
  CloseFile(fout1);
 end;

 (* Create common file for plotting *)
 AssignFile(fout1, tldUnload+'Ini.txt'); Reset(fout1); // initial file
 readln(fout1); // skip header

// showmessage('1'+'   '+floattostr(tldMaxLev));
 {if chkmbarconv.Checked=true then begin
  tldMaxLev:=trunc((-ln(tldMinLev/1013.25)/0.00012)/1000);
 end;  }

// showmessage('2'+'   '+floattostr(tldMaxLev));

 DFile := inttostr(tldYYMin) + '_' + inttostr(tldYYMax) + '_' +
          inttostr(seMnMin.Value)+ '_' + inttostr(seMnMax.Value) + '_' +
          floattostr(tldMaxLev) + '_.txt';

 koef:=(tldYYMax-tldYYMin)/tldMaxLev;

 AssignFile(fout2, tldUnload+DFile); Rewrite(fout2); // data file
 writeln(fout2, 'YY':5, 'YY_tr':10, 'Lev':10, 'Val':15, 'Anom':15);
  repeat
    readln(fout1, yy, lev1, val1);
   // if chkmbarconv.Checked=true then lev_m:=(-ln(Lev1/1013.25)/0.00012)/1000 else lev_m:=lev1;
     k:=frmmain.cbLevels.Items.IndexOf(floattostr(lev1));
  //    if chkInverseY.Checked=false then
     //  writeln(fout2, yy:5:0, ((yy-tldYYMin)/koef):10:3,  lev_m:10:3, val1:15:3, (val1-levMean[k]):15:3) else
       writeln(fout2, yy:5:0, ((yy-tldYYMin)/koef):10:3, -lev_m:10:3, val1:15:3, (val1-levMean[k]):15:3);
   until eof(fout1);
 CloseFile(fout2);
 CloseFile(fout1);

 NCols:=tldYYMax-tldYYMin;
 NRows:=frmmain.cbLevels.Items.Count-1;

 if rbPlot.ItemIndex=0 then Col:=4;
 if rbPlot.ItemIndex=1 then Col:=5;

 //GetTLDScript((tldUnload+DFile), Col, NCols, NRows);

 {$IFDEF Windows}
   frmmain.RunScript(2, '"'+tldUnload+'script.bas"', nil);
 {$ENDIF}

end;


procedure Tfrmclimtdd.btnSettingsClick(Sender: TObject);
begin
 frmSurferSettings := TfrmSurferSettings.Create(Self);
 frmSurferSettings.LoadSettings('ncTLD');
  try
   if not frmSurferSettings.ShowModal = mrOk then exit;
  finally
    frmSurferSettings.Free;
    frmSurferSettings := nil;
  end;
end;


(* Averaged data from each specified file *)
procedure Tfrmclimtdd.GetTLDValues(fname: string);
Var
  status, ncid, varidp, ndimsp:integer;
  tt, lv, lt, ln, tp:integer;
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
  LatMin, LatMax, LonMin, LonMax : real;
  MnMin, MnMax:integer;
  val0, val1, yy1, Int_val:real;
  sum_pi, Area_Mean:real;
  yy, mn, dd, hh, mm, ss, ms:word;
begin
 LatMin:= StrToFloat(edit2.Text);
 LatMax:= StrToFloat(edit1.Text);

 LonMin:= StrToFloat(edit3.Text);
 LonMax:= StrToFloat(edit4.Text);

 MNMin := seMnMin.Value;
 MNMax := seMnMax.Value;
try
 (* nc_open*)
   status:=nc_open(pansichar(AnsiString(ncpath+ncname)), NC_NOWRITE, ncid); // only for reading
    if status>0 then showmessage(pansichar(nc_strerror(status)));

   nc_inq_varid (ncid, pAnsiChar(AnsiString(cbVariable.Text)), varidp); // variable ID
   nc_inq_vartype (ncid, varidp, vtype);
   nc_inq_varndims (ncid, varidp, ndimsp);

   nc_get_att_float(ncid, varidp, pansichar(AnsiString('add_offset')),    offset);
   nc_get_att_float(ncid, varidp, pansichar(AnsiString('scale_factor')),  scale);
   nc_get_att_float(ncid, varidp, pansichar(AnsiString('missing_value')), missing);

   if scale[0]=0 then scale[0]:=1; // if there's no scale in the file

   nc_inq_dimlen (ncid, timeDid, lenp);
    setlength(ncTime_arr, lenp);
    nc_get_var_double (ncid, timeVid, ncTime_arr);

   nc_inq_attlen (ncid, timeVid, pansichar(AnsiString('units')), attlenp);
   setlength(atttext, attlenp);
   nc_get_att_text (ncid, timeVid, pansichar(AnsiString('units')), atttext);

   GetDates(pansichar(atttext));

    // additional user defined conversion - if needed
 //  if eAdditionalScale.Text<>''  then AddScale := StrToFloat(eAdditionalScale.Text)  else AddScale:=1;
 //  if eAdditionalOffset.Text<>'' then AddOffset:= StrToFloat(eAdditionalOffset.Text) else AddOffset:=0;

   start:=GetMemory(SizeOf(TArraySize_t)*ndimsp); // get memory for start pointer

   for lv:=0 to high(ncLev_arr) do begin
   start^[1]:=lv;

    for tt:=0 to high(ncTime_arr) do begin
    DecodeDateTime(StrToDateTime(frmmain.cbDates.Items.Strings[tt]), yy, mn, dd, hh, mm, ss, ms);

     tldYYMin:=min(yy, tldYYMin); // min year
     tldYYMax:=max(yy, tldYYMax); // max year

     start^[0]:=tt; //time

   if ((mnMin<=MnMax) and ((mn>=MnMin) and (mn<=MnMax))) or
      ((mnMin> MnMax) and ((mn>=MnMin) or (mn<=MnMax))) then begin

     for lt:=0 to high(ncLat_arr) do begin
      start^[2]:=lt;  //lat

      for ln:=0 to high(ncLon_arr) do begin
       start^[3]:=ln; //ln


        // get area mean
       if (ncLat_arr[lt]>=LatMin) and (ncLat_arr[lt]<=LatMax) and
          (ncLon_arr[ln]>=LonMin) and (ncLon_arr[ln]<=LonMax) then begin
             case vtype of
               NC_SHORT:
                begin
                 SetLength(sp, 1);
                  nc_get_var1_short(ncid, varidp, start^, sp);
                 Val0:=sp[0];
                end;
               NC_INT:
                begin
                 SetLength(ip, 1);
                  nc_get_var1_int(ncid, varidp, start^, ip);
                 Val0:=ip[0];
                end;
               NC_FLOAT:
                begin
                 SetLength(fp, 1);
                  nc_get_var1_float(ncid, varidp, start^, fp);
                 Val0:=fp[0];
                end;
               NC_DOUBLE:
                begin
                 SetLength(dp, 1);
                  nc_get_var1_double(ncid, varidp, start^, dp);
                 Val0:=dp[0];
                end;
             end;

            if Val0<>missing[0] then begin  // if value is not missing
             val1:=scale[0]*Val0+offset[0]; // scale and offset from netcdf
             val1:=addscale*val1+AddOffset;  // user defined conversion

             Int_val:=Int_val+Val1*cos(Pi*ncLat_arr[lt]/180);
             Sum_pi:=Sum_pi+cos(Pi*ncLat_arr[lt]/180);
           end; // end of missing value loop
       end; // end of get area mean
     end; // end of lon loop
    end; // end of lat loop

     if Sum_pi<>0 then begin
      Area_Mean:=Int_val/Sum_pi;

       with  nctldCDS do begin
        Append;
         FieldByName('YY').AsInteger:=yy;
         FieldByName('MN').AsInteger:=mn;
         FieldByName('LEV').AsFloat:=ncLev_arr[lv];
         FieldByName('VAL').AsFloat:=Area_mean;
        Post;
       end;
     Application.processMessages;
     //  writeln(fout1, yy:5, mn:5, ncLev_arr[lv]:6:0, Area_mean:15:3); // write mean value for year
     end;
      Int_val:=0; sum_pi:=0; area_mean:=0;  // clear variables

      end;// condition on month


    end; // and of time loop



   end; // end of level loop

 finally
  status:=nc_close(ncid);  // Close file
   if status>0 then showmessage(pansichar(nc_strerror(status)));
  FreeMemory(start);
 end;
end;

procedure Tfrmclimtdd.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
   nctldcds.Free;
 nctldds.Free;
end;


end.
