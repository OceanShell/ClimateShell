unit nctimeserieslayer;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Spin, FileUtil, Math, DateUtils;

type
  TfrmTimeSeriesLayers = class(TForm)
    GroupBox2: TGroupBox;
    cbVariable: TComboBox;
    btnGetTimeSeries: TButton;
    gbAveraging: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label4: TLabel;
    Label6: TLabel;
    seMnMin: TSpinEdit;
    seMnMax: TSpinEdit;
    seYYmin: TSpinEdit;
    seYYMax: TSpinEdit;
    btnAnomalies: TButton;
    btnOpenFolder: TBitBtn;
    eErr: TEdit;
    GroupBox5: TGroupBox;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    ePointLat: TEdit;
    ePointRad: TEdit;
    ePointLon: TEdit;
    GroupBox1: TGroupBox;
    cbLevel2: TComboBox;
    cbLevel1: TComboBox;
    Label3: TLabel;
    Label5: TLabel;
    GroupBox3: TGroupBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    rbDomain: TRadioButton;
    rbRadius: TRadioButton;


    procedure FormShow(Sender: TObject);
    procedure cbVariableSelect(Sender: TObject);
    procedure btnGetTimeSeriesClick(Sender: TObject);
    procedure GetValuesInLayers(fname:string);
    procedure btnAnomaliesClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmTimeSeriesLayers: TfrmTimeSeriesLayers;
  fout1, fout2:text;
  tsncUnload:string;
  tsYYMin, tsYYMax:integer;

implementation

{$R *.lfm}

uses ncmain, ncprocedures, declarations_netcdf, Bathymetry;


procedure TfrmTimeSeriesLayers.FormShow(Sender: TObject);
Var
  k:integer;
  LatMin, LatMax, LonMin, LonMax : real;
begin
 cbVariable.Items := frmmain.cbVariables.items; // copy variable names
 cbLevel1.Items    := frmmain.cbLevels.items; // levels
 cbLevel2.Items    := frmmain.cbLevels.items; // levels


 tsncUnload:=GlobalPath+'unload\nctimeseries\area averaging\';
 if not DirectoryExists(tsncUnload) { *Converted from DirectoryExists* } then CreateDir(tsncUnload); { *Converted from CreateDir* }

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

 // min and max years
 tsYYMin:= 9999;
 tsYYMax:=-9999;
end;



procedure TfrmTimeSeriesLayers.cbVariableSelect(Sender: TObject);
begin
  if cbVariable.ItemIndex<>-1 then btnGetTimeSeries.Enabled:=true;
end;


procedure TfrmTimeSeriesLayers.btnAnomaliesClick(Sender: TObject);
Var
  FileData, FileAnom:string;
  MnMin, MnMax:integer;
  yy, mn, dd, hh, mm, ss, ms:real;
  globcnt, c, cnt:integer;

  yy1, val1, globmean:real;
  yy_old:integer;
  Int_val, Mean:real;
begin
 MnMin := seMnMin.Value;
 MnMax := seMnMax.Value;

 try
 AssignFile(fout1, tsncUnload+cbVariable.Text+'.txt'); Reset(fout1); // file with values

 FileData:=tsncUnload+cbVariable.Text+'_'+seMnMin.Text+'_'+seMnMax.Text+'_data.txt';
 FileAnom:=tsncUnload+cbVariable.Text+'_'+seMnMin.Text+'_'+seMnMax.Text+'_anom.txt';

  AssignFile(fout2, FileData); Rewrite(fout2); // file for anomalies
  writeln(fout2, 'Year':5, 'Value':15); //write header
  readln(fout1);

   Int_val:=0; cnt:=0; mean:=0;
   globmean:=0; globcnt:=0; c:=0;
   repeat
    readln(fout1, yy, mn, dd, hh, val1);
     if c=0 then begin yy_old:=round(yy); inc(c); end;

     if ((MnMin<=MnMax) and (yy>yy_old)) or
        ((MnMin>MnMax) and ((yy=yy_old+1) and (mn>mnMax))) or
        (eof(fout1)) then begin
      if cnt<>0 then begin
         Mean:=Int_val/cnt;
          writeln(fout2, yy_old:5, mean:15:3); // write mean value for year
           // mean value for anomalies
           if (yy_old>=seYYMin.Value) and (yy_old<=seYYMax.Value) then begin
            globmean:=globmean+Mean;
            inc(globcnt);
           end; // eof mean value for anomalies
        end;
        Int_val:=0; cnt:=0; mean:=0; yy_old:=round(yy); // clear variables
        if eof(fout1) then break;
       end; // end of yearly mean

        if ((MnMin<=MnMax) and (yy=yy_old) and (mn>=MnMin) and (mn<=MnMax)) or
           ((MnMin> MnMax) and ((yy=yy_old) and (mn>=MnMin)) or ((yy=yy_old+1) and (mn<=MnMax))) then begin
           Int_val:=Int_val+Val1;
          inc(cnt);
        end;

   until eof(fout1);
 finally
  CloseFile(fout1);   // close files;
  CloseFile(fout2);
 end;


 try
 AssignFile(fout1, FileData); Reset(fout1); // file for anomalies
 AssignFile(fout2, FileAnom); Rewrite(fout2); // file for anomalies
  writeln(fout2, 'Year':5, 'Value':15); //write header
   readln(fout1);
   repeat
    readln(fout1, yy1, val1);
    writeln(fout2, yy1:5:0, (val1-(globmean/globcnt)):15:3); // write anomalies
   until eof(fout1);
 finally
   CloseFile(fout1);   // close files;
   CloseFile(fout2);
 end;

   OpenDocument(PChar(tsncunload)); { *Converted from ShellExecute* }
end;

procedure TfrmTimeSeriesLayers.btnGetTimeSeriesClick(Sender: TObject);
Var
  kf:integer;
begin
 if cbVariable.ItemIndex=-1 then exit; // exit if a variable isn't selected
 btnGetTimeSeries.Enabled:=false;
 btnAnomalies.Enabled:=false;

 AssignFile(fout1, tsncUnload+cbVariable.Text+'.txt');
  try
   Rewrite(fout1);
   writeln(fout1, 'YY':5, 'MN':5, 'DD':5, 'HH':5, 'Value':15);

  { ncCDSFiles.First;
    while not ncCDSFiles.Eof do begin
     ncName:=ncCDSFiles.FieldByName('fname').AsString;
      GetValuesInLayers(ncpath+ncname);
     ncCDSFiles.Next;
    end; }

   seYYMin.Value:=tsYYMin;
   seYYMax.Value:=tsYYMax;

   seYYMin.MinValue:=seYYMin.Value;  // set years range for year begin
   seYYMin.MaxValue:=seYYMax.Value;

   seYYMax.MinValue:=seYYMin.Value; // set years range for year end
   seYYMax.MaxValue:=seYYMax.Value;
  finally
   CloseFile(fout1);
  end;

 btnGetTimeSeries.Enabled:=true;
 gbAveraging.Visible:=true;
 btnAnomalies.Visible:=true;
 btnAnomalies.Enabled:=true;
Application.ProcessMessages;
end;




(* Averaged data from each specified file *)
procedure TfrmTimeSeriesLayers.GetValuesInLayers(fname: string);
Var
  status, ncid, varidp, varidp2, ndimsp, c:integer;
  tt, lt, ln, tp, zz, z:integer;
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
  LatMin, LatMax, LonMin, LonMax, Lat0, Lon0, Rad, Dist: real;
  val0, val1, yy1, Int_val, Val_err, d_c1, d_c0, de, d0:real;
  sum_pi, area_mean:real;
  yy, mn, dd, hh, mm, ss, ms:word;
  lat, lon, depth:real;
  Level_mean, Level_lvl: array[1..29] of real;
begin

 if rbDomain.Checked=true then begin
   LatMin:= StrToFloat(edit2.Text);
   LatMax:= StrToFloat(edit1.Text);
   LonMin:= StrToFloat(edit3.Text);
   LonMax:= StrToFloat(edit4.Text);
 end;

 if rbRadius.Checked=true then begin
   Lat0:=strtofloat(ePointLat.Text);
   Lon0:=strtofloat(ePointLon.Text);
   Rad :=strtofloat(ePointRad.Text);
 end;

try
 (* nc_open*)
   status:=nc_open(pansichar(AnsiString(ncpath+ncname)), NC_NOWRITE, ncid); // only for reading
    if status>0 then showmessage(pansichar(nc_strerror(status)));

   nc_inq_varid (ncid, pAnsiChar(AnsiString(cbVariable.Text)), varidp); // variable ID
   nc_inq_vartype (ncid, varidp, vtype);
   nc_inq_varndims (ncid, varidp, ndimsp);

    //ID для относительной ошибки

   nc_inq_varid (ncid, pAnsiChar(AnsiString(cbVariable.Text+'_relerr')), varidp2); // variable ID

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



   start:=GetMemory(SizeOf(TArraySize_t)*ndimsp); // get memory for start pointer

   for tt:=0 to high(ncTime_arr) do begin
    DecodeDateTime(StrToDateTime(frmmain.cbDates.Items.Strings[tt]), yy, mn, dd, hh, mm, ss, ms);
     tsYYMin:=min(yy, tsYYMin); // min year
     tsYYMax:=max(yy, tsYYMax); // max year
     start^[0]:=tt; //time

    z:=1;
   for zz := cbLevel1.ItemIndex to cbLevel2.ItemIndex do begin
     start^[1]:=zz;

    for lt:=0 to high(ncLat_arr) do begin
       start^[2]:=lt;  //lat

     for ln:=0 to high(ncLon_arr) do begin
       start^[3]:=ln;


        Distance(Lon0, ncLon_arr[ln], Lat0, ncLat_arr[lt], Dist);

        // get area mean
        if ((rbDomain.Checked=true) and
           (ncLat_arr[lt]>=LatMin) and (ncLat_arr[lt]<=LatMax) and
           (ncLon_arr[ln]>=LonMin) and (ncLon_arr[ln]<=LonMax)) or

           ((rbRadius.Checked=true) and (Dist<=Rad)) then begin

                 SetLength(fp, 1);
                  nc_get_var1_float(ncid, varidp, start^, fp);
                 Val0:=fp[0];

                 SetLength(dp, 1);
                  nc_get_var1_double(ncid, varidp2, start^, dp);
                 Val_err:=dp[0];


            depth:=GetBathymetry(ncLon_arr[ln], ncLat_arr[lt]);

            if (Val0<>missing[0]) and (depth>0) then begin  // if value is not missing

                val1:=scale[0]*Val0+offset[0]; // scale and offset from netcdf
               // val1:=addscale*val1+AddOffset;  // user defined conversion
              //  showmessage(floattostr(val1));
                if val_err<=StrtoFloat(eErr.Text) then begin
                  Int_val:=Int_val+Val1*cos(Pi*ncLat_arr[lt]/180);
                  Sum_pi:=Sum_pi+cos(Pi*ncLat_arr[lt]/180);
                end;
           end; // end of missing value loop
         end; //ограничение в радиусе поиска

        end; // end of lon loop
       end; // end of lat loop

     if Sum_pi<>0 then begin
      Level_mean[z]:=Int_val/Sum_pi;
      Level_lvl[z]:=StrToFloat(cbLevel1.Items.Strings[zz]);
     // showmessage('level: '+floattostr(level_mean[z]));
      inc(z);
     end;
     Int_val:=0; sum_pi:=0; area_mean:=0;  // clear variables
     end; // eof level

      (* Расчет средневзвешенного значения в слое *)
     if (z>1) then begin
      Area_mean:=0;
      d0:=StrToFloat(cbLevel1.Text);
      de:=StrToFloat(cbLevel2.Text);

      // showmessage(floattostr(level_mean[1])+'   '+floattostr(level_lvl[1]));
       For c:=2 to z-1 do begin
        Area_mean:=Area_mean+((Level_mean[c]+Level_mean[c-1])/2)*((level_lvl[c]-level_lvl[c-1])/(de-d0));
       // showmessage(floattostr(level_mean[c])+'   '+floattostr(level_lvl[c]));
       end;
      // showmessage(floattostr(area_mean));

       if (Area_mean<>0) and (level_lvl[1]<=d0) and (level_lvl[z-1]>=de) then begin
           writeln(fout1, yy:5, mn:5, dd:5, hh:5, Area_mean:15:3); // write mean value for year
       end;

       for c:=1 to 29 do begin
        Level_mean[c]:=0;
        Level_lvl[c]:=0;
       end;
      // z:=1;
      end;


   end; // end of time loop

 finally
  status:=nc_close(ncid);  // Close file
   if status>0 then showmessage(pansichar(nc_strerror(status)));
  FreeMemory(start);
 end;
end;

end.
