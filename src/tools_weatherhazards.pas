(*
RH: =100*(EXP((17.625*TD)/(243.04+TD))/EXP((17.625*T)/(243.04+T)))
TD: =243.04*(LN(RH/100)+((17.625*T)/(243.04+T)))/(17.625-LN(RH/100)-((17.625*T)/(243.04+T)))
 T: =243.04*(((17.625*TD)/(243.04+TD))-LN(RH/100))/(17.625+LN(RH/100)-((17.625*TD)/(243.04+TD)))
 (• replace "T", "TD", and "RH" with your actual cell references)
 (• T and TD inputs/outputs to the equations are in Celcius)
*)

unit tools_weatherhazards;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  BufDataset, DB, IniFiles;

type

  { Tfrmweatherhazards }

  Tfrmweatherhazards = class(TForm)
    btnSettings: TButton;
    btnWindSpeed: TButton;
    btnPlot: TButton;
    btndifference: TButton;
    btnW: TButton;
    btnT: TButton;
    cbClr1: TComboBox;
    cbLvl1: TComboBox;
    Edit1: TEdit;
    Edit2: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label9: TLabel;

    procedure btndifferenceClick(Sender: TObject);
    procedure btnPlotClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure btnWindSpeedClick(Sender: TObject);
    procedure btnWClick(Sender: TObject);
    procedure btnTClick(Sender: TObject);
    procedure FormShow(Sender: TObject);

  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmweatherhazards: Tfrmweatherhazards;
  f_dat, f_dat2, f_out: text;
  cds:TBufDataSet;
  ncWeatherHazardsPath:string;

implementation

{$R *.lfm}

{ Tfrmweatherhazards }

uses ncmain, surfer_ncfields, surfer_settings, ncprocedures, declarations_netcdf;


procedure Tfrmweatherhazards.FormShow(Sender: TObject);
Var
  fdb:TSearchRec;
begin
 if not DirectoryExists(GlobalPath+'unload'+PathDelim+'weatherhazards'+PathDelim) then
    CreateDir(GlobalPath+'unload'+PathDelim+'weatherhazards'+PathDelim);

 ncWeatherHazardsPath:=GlobalPath+'unload\weatherhazards\';
  if not DirectoryExists(ncWeatherHazardsPath) then CreateDir(ncWeatherHazardsPath);
  if not DirectoryExists(ncWeatherHazardsPath+'\png\') then CreateDir(ncWeatherHazardsPath+'\png\');
  if not DirectoryExists(ncWeatherHazardsPath+'\srf\') then CreateDir(ncWeatherHazardsPath+'\srf\');

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
end;


procedure Tfrmweatherhazards.btnWindSpeedClick(Sender: TObject);
Var
 k, i, a:integer;
  lt_i, ln_i, tp, fl, yy_i, mn, total, c:integer;
  mm, yy, dd:word;
  status, ncid,  ndimsp, varnattsp, dimid:integer;
  uidp, vidp, tidp, didp, sidp:integer;
  varxid, varyid : integer;
  start, start2: PArraySize_t;
   fp:array of single;
   sp:array of smallint;
   ip:array of integer;
   dp:array of double;
  vtype: nc_type;
  attlenp, lenp: size_t;
  attname:    array of pAnsiChar;
  u_scale, u_offset, u_missing: array [0..0] of single;
  v_scale, v_offset, v_missing: array [0..0] of single;
  t_scale, t_offset, t_missing: array [0..0] of single;
  d_scale, d_offset, d_missing: array [0..0] of single;
  s_scale, s_offset, s_missing: array [0..0] of single;

  cnt_u, cnt_t, cnt_i_s, cnt_i_m, cnt_i_f, cnt_f: array [1..12] of integer;
  lt_cnt, ln_cnt:integer;

  val0, val_err:variant;
  val1, firstval1, lat1, lon1:real;
  u, v, ws, t, d, s, rh:real;
  date1:TDateTime;
begin
  try
   (* nc_open*)
   nc_open(pansichar(AnsiString(ncpath+ncname)), NC_NOWRITE, ncid); // only for reading

   nc_inq_varid    (ncid, pAnsiChar(AnsiString('u10')), uidp); // variable ID
   nc_inq_varid    (ncid, pAnsiChar(AnsiString('v10')), vidp); // variable ID
   nc_inq_varid    (ncid, pAnsiChar(AnsiString('t2m')), tidp); // variable ID
 //  nc_inq_varid    (ncid, pAnsiChar(AnsiString('d2m')), didp); // variable ID
 //  nc_inq_varid    (ncid, pAnsiChar(AnsiString('sst')), sidp); // variable ID

   (* Читаем коэффициенты из файла *)
   u_scale[0]:=1;
   u_offset[0]:=0;
   u_missing[0]:=-9999;
   nc_inq_varnatts (ncid, uidp, varnattsp); // count of attributes for variable
   setlength(attname, NC_MAX_NAME); // задаем длину названия аттрибута
    for a:=0 to varnattsp-1 do begin
      nc_inq_attname(ncid, uidp, a, attname); // имя аттрибута
      if pAnsiChar(attname)='add_offset'    then nc_get_att_float(ncid, uidp, pansichar(pansichar(AnsiString('add_offset'))),    u_offset);
      if pAnsiChar(attname)='scale_factor'  then nc_get_att_float(ncid, uidp, pansichar(pansichar(AnsiString('scale_factor'))),  u_scale);
      if pAnsiChar(attname)='missing_value' then nc_get_att_float(ncid, uidp, pansichar(pansichar(AnsiString('missing_value'))), u_missing);
   end;
   if u_scale[0]=0 then u_scale[0]:=1; // if scale=0 then set it to be 1

   v_scale[0]:=1;
   v_offset[0]:=0;
   v_missing[0]:=-9999;
   nc_inq_varnatts (ncid, vidp, varnattsp); // count of attributes for variable
   setlength(attname, NC_MAX_NAME); // задаем длину названия аттрибута
    for a:=0 to varnattsp-1 do begin
      nc_inq_attname(ncid, vidp, a, attname); // имя аттрибута
      if pAnsiChar(attname)='add_offset'    then nc_get_att_float(ncid, vidp, pansichar(pansichar(AnsiString('add_offset'))),    v_offset);
      if pAnsiChar(attname)='scale_factor'  then nc_get_att_float(ncid, vidp, pansichar(pansichar(AnsiString('scale_factor'))),  v_scale);
      if pAnsiChar(attname)='missing_value' then nc_get_att_float(ncid, vidp, pansichar(pansichar(AnsiString('missing_value'))), v_missing);
   end;
   if v_scale[0]=0 then v_scale[0]:=1; // if scale=0 then set it to be 1

   t_scale[0]:=1;
   t_offset[0]:=0;
   t_missing[0]:=-9999;
   nc_inq_varnatts (ncid, tidp, varnattsp); // count of attributes for variable
   setlength(attname, NC_MAX_NAME); // задаем длину названия аттрибута
    for a:=0 to varnattsp-1 do begin
      nc_inq_attname(ncid, tidp, a, attname); // имя аттрибута
      if pAnsiChar(attname)='add_offset'    then nc_get_att_float(ncid, tidp, pansichar(pansichar(AnsiString('add_offset'))),    t_offset);
      if pAnsiChar(attname)='scale_factor'  then nc_get_att_float(ncid, tidp, pansichar(pansichar(AnsiString('scale_factor'))),  t_scale);
      if pAnsiChar(attname)='missing_value' then nc_get_att_float(ncid, tidp, pansichar(pansichar(AnsiString('missing_value'))), t_missing);
   end;
   if t_scale[0]=0 then t_scale[0]:=1; // if scale=0 then set it to be 1

 {  d_scale[0]:=1;
   d_offset[0]:=0;
   d_missing[0]:=-9999;
   nc_inq_varnatts (ncid, didp, varnattsp); // count of attributes for variable
   setlength(attname, NC_MAX_NAME); // задаем длину названия аттрибута
    for a:=0 to varnattsp-1 do begin
      nc_inq_attname(ncid, didp, a, attname); // имя аттрибута
      if pAnsiChar(attname)='add_offset'    then nc_get_att_float(ncid, didp, pansichar(pansichar(AnsiString('add_offset'))),    d_offset);
      if pAnsiChar(attname)='scale_factor'  then nc_get_att_float(ncid, didp, pansichar(pansichar(AnsiString('scale_factor'))),  d_scale);
      if pAnsiChar(attname)='missing_value' then nc_get_att_float(ncid, didp, pansichar(pansichar(AnsiString('missing_value'))), d_missing);
   end;
   if d_scale[0]=0 then d_scale[0]:=1; // if scale=0 then set it to be 1

   s_scale[0]:=1;
   s_offset[0]:=0;
   s_missing[0]:=-9999;
   nc_inq_varnatts (ncid, sidp, varnattsp); // count of attributes for variable
   setlength(attname, NC_MAX_NAME); // задаем длину названия аттрибута
    for a:=0 to varnattsp-1 do begin
      nc_inq_attname(ncid, sidp, a, attname); // имя аттрибута
      if pAnsiChar(attname)='add_offset'    then nc_get_att_float(ncid, sidp, pansichar(pansichar(AnsiString('add_offset'))),    s_offset);
      if pAnsiChar(attname)='scale_factor'  then nc_get_att_float(ncid, sidp, pansichar(pansichar(AnsiString('scale_factor'))),  s_scale);
      if pAnsiChar(attname)='missing_value' then nc_get_att_float(ncid, sidp, pansichar(pansichar(AnsiString('missing_value'))), s_missing);
   end;
   if v_scale[0]=0 then v_scale[0]:=1; // if scale=0 then set it to be 1  }
   (*конец чтения коэффициентов *)


   cds:=TBufDataSet.Create(nil);
    with cds.FieldDefs do begin
     Add('lat'   ,ftfloat, 0, false);
     Add('lon'   ,ftfloat, 0, false);
      for mn:=1 to 12 do begin
       Add(inttostr(mn)+'_cnt_u'     ,ftinteger, 0, false);
       Add(inttostr(mn)+'_cnt_t'     ,ftinteger, 0, false);
   //    Add(inttostr(mn)+'_cnt_i_s'   ,ftinteger, 0, false);
   //    Add(inttostr(mn)+'_cnt_i_m'   ,ftinteger, 0, false);
   //    Add(inttostr(mn)+'_cnt_i_f'   ,ftinteger, 0, false);
   //    Add(inttostr(mn)+'_cnt_f'     ,ftinteger, 0, false);
      end;
    end;
   cds.CreateDataSet;

   cds.first;
   for lt_i:=0 to high(ncLat_arr) do begin //Latitude
     for ln_i:=0 to high(ncLon_arr) do begin  //Longitude
       with cds do begin
        Append;
         FieldByName('Lat').AsFloat:=ncLat_arr[lt_i];
         FieldByName('Lon').AsFloat:=ncLon_arr[ln_i];
        Post;
        next;
       end;
    end;
   end;
  finally
    status:=nc_close(ncid);  // Close file
     if status>0 then showmessage(pansichar(nc_strerror(status)));
  end;

  Lt_cnt:=high(ncLat_arr);
  Ln_cnt:=high(ncLon_arr);

  start:=GetMemory(SizeOf(TArraySize_t)*3); // get memory for start pointer

  fl:=0; total:=0;
   cds.first;
    for lt_i:=0 to Lt_cnt do begin //Latitude
     start^[1]:=lt_i;  //lat
     for ln_i:=0 to Ln_cnt do begin  //Longitude
  //    showmessage(inttostr(ln_i));
      start^[2]:=ln_i;

     // showmessage('clean arrays');

      for c:=1 to 12 do begin
       cnt_u[c]:=0; cnt_t[c]:=0; // cnt_i_s[c]:=0;  cnt_i_m[c]:=0;  cnt_i_f[c]:=0;  cnt_f[c]:=0;
      end;

      for k:=0 to frmmain.cbFiles.count-1 do begin
        ncName:=frmmain.cbFiles.Items.strings[k];
     //   ncProcedures.GetHeader(ncpath+ncname, 1);

      //  showmessage('start1');
        try
        (* nc_open*)
        nc_open(pansichar(AnsiString(ncpath+ncname)), NC_NOWRITE, ncid); // only for reading



       for yy_i:=0 to high(ncTime_arr) do begin
        start^[0]:=yy_i; //time
        date1:=StrToDateTime(frmmain.cbDates.Items.Strings[yy_i]);
        DecodeDate(date1, yy, mm, dd);

      SetLength(fp, 1);
       nc_get_var1_float(ncid, uidp, start^, fp);
        u:=fp[0];
       nc_get_var1_float(ncid, vidp, start^, fp);
        v:=fp[0];
       nc_get_var1_float(ncid, tidp, start^, fp);
        t:=fp[0];
     //  nc_get_var1_float(ncid, didp, start^, fp);
     //   d:=fp[0];
     //  nc_get_var1_float(ncid, sidp, start^, fp);
     //   s:=fp[0];

        if (u<>-9999) and (v<>-9999) then begin
             u:=u_scale[0]*u+u_offset[0];
             v:=v_scale[0]*v+v_offset[0];
             ws:=sqrt(u*u+v*v);

            if ws>=15 then begin
             inc(cnt_u[mm]);
           end;
         end;

         if (t<>-9999)  then begin
             t:=t_scale[0]*t+t_offset[0]-273.1516;

            if t<=-30 then begin
             inc(cnt_t[mm]);
           end;
         end;

  (*       if (t<>-9999) and (u<>-9999) and (v<>-9999)  then begin
             t:=t_scale[0]*t+t_offset[0]-273.1516;
             u:=u_scale[0]*u+u_offset[0];
             v:=v_scale[0]*v+v_offset[0];
             ws:=sqrt(u*u+v*v);

(*Медленное обледенение - происходит при температуре -1>Ta≥ -3
и скорости ветра ua> 0 м/c и при Ta<-3 и скорости ветра ua≤ 9 м/c*)

             //slow
            if (((T<-1) and (T>-3) and (ws>0)) or ((t<-3) and (ws<=9))) then begin
              inc(cnt_i_s[mm]);
            end;
(*Быстрое обледенение - происходит при температуре -3оС >Ta≥ -8
и скорости ветра 9 м/c <ua≤ 15 м/c *)

           //fast
           if ((T<-3) and (T>-8) and (ws>9) and (ws<15)) then begin
             inc(cnt_i_m[mm]);
           end;

(*   Очень быстрое обледенение - происходит при температуре -3>Ta и
скорости ветра ua>15 м/c и при Ta< -8 и скорости ветра 9 м/c <ua< 15 м/c*)
           //very fast
            if (((T<-3) and (ws>15)) or ((t<-8) and (ws>9))) then begin
             inc(cnt_i_f[mm]);
           end;
         end;


         if (t<>-9999) and (s<>-9999) and (d<>-9999)  then begin
             t:=t_scale[0]*t+t_offset[0]-273.1516;
             d:=d_scale[0]*d+d_offset[0]-273.1516;
             s:=s_scale[0]*s+s_offset[0]-273.1516;
             rh:=100*(EXP((17.625*d)/(243.04+d))/EXP((17.625*T)/(243.04+T)));

            if ((s-t)>=10) and (rh>=70) then begin
             inc(cnt_f[mm]);
           end;
         end;         *)
          inc(total);

        end; //time

    //   showmessage('done');

       for c:=1 to 12 do begin
        with cds do begin
         Edit;
          FieldByName(inttostr(mn)+'_cnt_u').AsInteger   :=cnt_u[c];
          FieldByName(inttostr(mn)+'_cnt_t').AsInteger   :=cnt_t[c];
        //  FieldByName(inttostr(mn)+'_cnt_i_s').AsInteger :=cnt_i_s[c];
       //   FieldByName(inttostr(mn)+'_cnt_i_m').AsInteger :=cnt_i_m[c];
       //   FieldByName(inttostr(mn)+'_cnt_i_f').AsInteger :=cnt_i_f[c];
      //    FieldByName(inttostr(mn)+'_cnt_f').AsInteger   :=cnt_f[c];
         Post;
         Next;
        end;
      end;

       //   showmessage('done3');


       finally
       fp:=nil;
        status:=nc_close(ncid);  // Close file
       if status>0 then showmessage(pansichar(nc_strerror(status)));
      end;

     //  showmessage('next file');
     end;  // files

    //   showmessage('next lon');
      end; //lon
    //   showmessage('next lat');
   end; //lat
    FreeMemory(start);


 showmessage('done 4');
   for mn:=1 to 12 do begin

   AssignFile(f_dat,  ncWeatherHazardsPath+inttostr(mn)+'.dat'); Rewrite(f_dat);
   writeln(f_dat, 'Lat':15, 'Lon':15, 'cnt_u':15, '%_u':20, 'cnt_t':15, '%_t':20);
  // 'cnt_i_s':15, '%_i_s':20,'cnt_i_m':15, '%_i_m':20,'cnt_i_f':15, '%_i_f':20,
 //  'cnt_f':15, '%_f':20);

   cds.first;
    for lt_i:=0 to high(ncLat_arr) do begin //Latitude
     for ln_i:=0 to high(ncLon_arr) do begin  //Longitude
      writeln(f_dat, ncLat_arr[lt_i]:15:5, ncLon_arr[ln_i]:15:5,
                     cds.fieldbyname(inttostr(mn)+'_cnt_u').asinteger:15,
                    (cds.fieldbyname(inttostr(mn)+'_cnt_u').asinteger/total/12):20:10,
                     cds.fieldbyname(inttostr(mn)+'_cnt_t').asinteger:15,
                    (cds.fieldbyname(inttostr(mn)+'_cnt_t').asinteger/total/12):20:10);
                  //   cds.fieldbyname(inttostr(mn)+'_cnt_i_s').asinteger:15,
                  //  (cds.fieldbyname(inttostr(mn)+'_cnt_i_s').asinteger/total/12):20:10,
                 //    cds.fieldbyname(inttostr(mn)+'_cnt_i_m').asinteger:15,
                 //   (cds.fieldbyname(inttostr(mn)+'_cnt_i_m').asinteger/total/12):20:10,
                 //    cds.fieldbyname(inttostr(mn)+'_cnt_i_f').asinteger:15,
                 //   (cds.fieldbyname(inttostr(mn)+'_cnt_i_f').asinteger/total/12):20:10,
                 //    cds.fieldbyname(inttostr(mn)+'_cnt_f').asinteger:15,
                 //   (cds.fieldbyname(inttostr(mn)+'_cnt_f').asinteger/total/12):20:10);
        cds.next;
     end;
    end;
   Closefile(f_dat);
 end; //mn

 cds.free;
end;



procedure Tfrmweatherhazards.btnWClick(Sender: TObject);
Var
  k, a:integer;
  lt_i, ln_i, yy_i, mn0, lt0, ln0:integer;
  mm, yy, dd:word;
  status, ncid,  varnattsp:integer;
  uidp, vidp:integer;
  start: PArraySize_t;

  fp:array of single;

  attlenp, lenp: size_t;
  attname:    array of pAnsiChar;
  u_scale, u_offset, u_missing: array [0..0] of single;
  v_scale, v_offset, v_missing: array [0..0] of single;

  cnt_tot, cnt:integer;
  u, v, ws:real;
  date1:TDateTime;

  atttext: array of pansichar;
begin
  mn0:=1;
//for mn0:=1 to 12 do begin
 AssignFile(f_dat,  ncWeatherHazardsPath+inttostr(mn0)+'.dat'); Rewrite(f_dat);
 writeln(f_dat, 'Lat':15, 'Lon':15, 'cnt':15, '%':20);

 for lt_i:=0 to trunc(high(ncLat_arr)/8) do begin //Latitude
   lt0:=lt_i*8;
  for ln_i:=0 to trunc(high(ncLon_arr)/40) do begin  //Longitude
    ln0:=ln_i*40;

  cnt_tot:=0; cnt:=0;
  for k:=0 to frmmain.cbFiles.count-1 do begin
   ncName:=frmmain.cbFiles.Items.strings[k];

   try
   (* nc_open*)
   nc_open(pansichar(AnsiString(ncpath+ncname)), NC_NOWRITE, ncid); // only for reading

   nc_inq_varid    (ncid, pAnsiChar(AnsiString('u10')), uidp); // variable ID
   nc_inq_varid    (ncid, pAnsiChar(AnsiString('v10')), vidp); // variable ID

   (* Читаем коэффициенты из файла *)
   u_scale[0]:=1;
   u_offset[0]:=0;
   u_missing[0]:=-9999;
   nc_inq_varnatts (ncid, uidp, varnattsp); // count of attributes for variable
   setlength(attname, NC_MAX_NAME); // задаем длину названия аттрибута
    for a:=0 to varnattsp-1 do begin
      nc_inq_attname(ncid, uidp, a, attname); // имя аттрибута
      if pAnsiChar(attname)='add_offset'    then nc_get_att_float(ncid, uidp, pansichar(pansichar(AnsiString('add_offset'))),    u_offset);
      if pAnsiChar(attname)='scale_factor'  then nc_get_att_float(ncid, uidp, pansichar(pansichar(AnsiString('scale_factor'))),  u_scale);
      if pAnsiChar(attname)='missing_value' then nc_get_att_float(ncid, uidp, pansichar(pansichar(AnsiString('missing_value'))), u_missing);
   end;
   if u_scale[0]=0 then u_scale[0]:=1; // if scale=0 then set it to be 1

   v_scale[0]:=1;
   v_offset[0]:=0;
   v_missing[0]:=-9999;
   nc_inq_varnatts (ncid, vidp, varnattsp); // count of attributes for variable
   setlength(attname, NC_MAX_NAME); // задаем длину названия аттрибута
    for a:=0 to varnattsp-1 do begin
      nc_inq_attname(ncid, vidp, a, attname); // имя аттрибута
      if pAnsiChar(attname)='add_offset'    then nc_get_att_float(ncid, vidp, pansichar(pansichar(AnsiString('add_offset'))),    v_offset);
      if pAnsiChar(attname)='scale_factor'  then nc_get_att_float(ncid, vidp, pansichar(pansichar(AnsiString('scale_factor'))),  v_scale);
      if pAnsiChar(attname)='missing_value' then nc_get_att_float(ncid, vidp, pansichar(pansichar(AnsiString('missing_value'))), v_missing);
   end;
   if v_scale[0]=0 then v_scale[0]:=1; // if scale=0 then set it to be 1
   (*конец чтения коэффициентов *)

   nc_inq_dimlen (ncid, timeDid, lenp);
   setlength(ncTime_arr, lenp);
   nc_get_var_double (ncid, timeVid, ncTime_arr);
   nc_inq_attlen (ncid, timeVid, pansichar(AnsiString('units')), attlenp);
   setlength(atttext, attlenp);
   nc_get_att_text (ncid, timeVid, pansichar(AnsiString('units')), atttext);

   GetDates(pansichar(atttext));


   start:=GetMemory(SizeOf(TArraySize_t)*3); // get memory for start pointer

   for yy_i:=0 to high(ncTime_arr) do begin
    start^[0]:=yy_i; //time
    start^[1]:=lt0; //lat
    start^[2]:=ln0; //lon

    date1:=StrToDateTime(frmmain.cbDates.Items.Strings[yy_i]);
    DecodeDate(date1, yy, mm, dd);

    if mm=mn0 then begin

      SetLength(fp, 1);
       nc_get_var1_float(ncid, uidp, start^, fp);
        u:=fp[0];
       nc_get_var1_float(ncid, vidp, start^, fp);
        v:=fp[0];

        if (u<>-9999) and (v<>-9999) then begin
             u:=u_scale[0]*u+u_offset[0];
             v:=v_scale[0]*v+v_offset[0];
             ws:=sqrt(u*u+v*v);

            if ws>=15 then inc(cnt);
         end;
         inc(cnt_tot);
       end;
      end;

      finally
       fp:=nil;
        status:=nc_close(ncid);  // Close file
       if status>0 then showmessage(pansichar(nc_strerror(status)));
      end;
      // label1.Caption:=ncname;
       application.ProcessMessages;
       FreeMemory(start);
     end;  // files
      writeln(f_dat, ncLat_arr[lt0]:15:5, ncLon_arr[ln0]:15:5,cnt:15, ((cnt*100)/cnt_tot):20:10);
    end; //lon
   end; //lat
  closefile(f_dat);
 // end; // month

end;



procedure Tfrmweatherhazards.btnTClick(Sender: TObject);
Var
 k, a:integer;
 lt_i, ln_i, yy_i, mn0, lt0, ln0:integer;
 mm, yy, dd:word;
 status, ncid,  varnattsp:integer;
 tidp:integer;
 start: PArraySize_t;

 fp:array of single;

 attlenp, lenp: size_t;
 attname:    array of pAnsiChar;
 t_scale, t_offset, t_missing: array [0..0] of single;

 cnt_tot, cnt:integer;
 t:real;
 date1:TDateTime;

 atttext: array of pansichar;
begin

mn0:=1;
//for mn0:=1 to 12 do begin
 AssignFile(f_dat,  ncWeatherHazardsPath+inttostr(mn0)+'.dat'); Rewrite(f_dat);
 writeln(f_dat, 'Lat':15, 'Lon':15, 'cnt':15, '%':20);

 for lt_i:=0 to trunc(high(ncLat_arr)/8) do begin //Latitude
   lt0:=lt_i*8;
  for ln_i:=0 to trunc(high(ncLon_arr)/40) do begin  //Longitude
    ln0:=ln_i*40;

  cnt_tot:=0; cnt:=0;
  for k:=0 to frmmain.cbFiles.count-1 do begin
   ncName:=frmmain.cbFiles.Items.strings[k];

   try
   (* nc_open*)
   nc_open(pansichar(AnsiString(ncpath+ncname)), NC_NOWRITE, ncid); // only for reading

   nc_inq_varid    (ncid, pAnsiChar(AnsiString('t2m')), tidp); // variable ID

   (* Читаем коэффициенты из файла *)
   t_scale[0]:=1;
   t_offset[0]:=0;
   t_missing[0]:=-9999;
   nc_inq_varnatts (ncid, tidp, varnattsp); // count of attributes for variable
   setlength(attname, NC_MAX_NAME); // задаем длину названия аттрибута
    for a:=0 to varnattsp-1 do begin
      nc_inq_attname(ncid, tidp, a, attname); // имя аттрибута
      if pAnsiChar(attname)='add_offset'    then nc_get_att_float(ncid, tidp, pansichar(pansichar(AnsiString('add_offset'))),    t_offset);
      if pAnsiChar(attname)='scale_factor'  then nc_get_att_float(ncid, tidp, pansichar(pansichar(AnsiString('scale_factor'))),  t_scale);
      if pAnsiChar(attname)='missing_value' then nc_get_att_float(ncid, tidp, pansichar(pansichar(AnsiString('missing_value'))), t_missing);
   end;
   if t_scale[0]=0 then t_scale[0]:=1; // if scale=0 then set it to be 1
   (*конец чтения коэффициентов *)

   nc_inq_dimlen (ncid, timeDid, lenp);
   setlength(ncTime_arr, lenp);
   nc_get_var_double (ncid, timeVid, ncTime_arr);
   nc_inq_attlen (ncid, timeVid, pansichar(AnsiString('units')), attlenp);
   setlength(atttext, attlenp);
   nc_get_att_text (ncid, timeVid, pansichar(AnsiString('units')), atttext);

   GetDates(pansichar(atttext));


  start:=GetMemory(SizeOf(TArraySize_t)*3); // get memory for start pointer

   for yy_i:=0 to high(ncTime_arr) do begin
    start^[0]:=yy_i; //time
    start^[1]:=lt_i; //lat
    start^[2]:=ln_i; //lon

    date1:=StrToDateTime(frmmain.cbDates.Items.Strings[yy_i]);
    DecodeDate(date1, yy, mm, dd);

    if mm=mn0 then begin
      SetLength(fp, 1);
       nc_get_var1_float(ncid, tidp, start^, fp);
        t:=fp[0];

         if (t<>-9999)  then begin
             t:=t_scale[0]*t+t_offset[0]-273.1516;

            if t<=-20 then inc(cnt);
         end;
        inc(cnt_tot);
       end;
    end;

       finally
       fp:=nil;
        status:=nc_close(ncid);  // Close file
       if status>0 then showmessage(pansichar(nc_strerror(status)));
      end;
       // label1.Caption:=ncname;
       application.ProcessMessages;
       FreeMemory(start);
     end;  // files
      writeln(f_dat, ncLat_arr[lt0]:15:5, ncLon_arr[ln0]:15:5, cnt:15, ((cnt*100)/cnt_tot):20:10);
    end; //lon
   end; //lat
  closefile(f_dat);
 // end; // month
end;





procedure Tfrmweatherhazards.btnPlotClick(Sender: TObject);
 Var
  Ini:TIniFile;
  f_scr:text;
  FieldPath, IntMethod, avunit, IniSet:string;
  mn:integer;
  xmin, xmax, ymin, ymax:real;
 begin
//  FieldPath:=ExtractFilePath(src); //Path to data
  IniSet:='ncweatherhazards';

 for mn:=1 to 12 do begin

  try
  Ini := TIniFile.Create(IniFileName); // settings from file
  IntMethod:=Ini.ReadString   (IniSet, 'Algorithm', 'srfKriging');

  AssignFile(f_scr,  ncWeatherHazardsPath+'script.bas'); rewrite(f_scr);  // script file

    WriteLn(f_scr, 'Sub Main');
    WriteLn(f_scr, 'Dim Surfer, Diagram, Doc As Object');
    WriteLn(f_scr, 'PathGRD = "'+GlobalPath+'unload\fields\Grid.grd"');
    WriteLn(f_scr, 'pathBlankMap="'+GlobalPath+'support\bln\World.bln"');
    WriteLn(f_scr, '');

    WriteLn(f_scr, 'Set Surfer=CreateObject("Surfer.Application")');
    WriteLn(f_scr, '    Surfer.Visible=False');
    WriteLn(f_scr, 'Set Doc=Surfer.Documents.Add');
    WriteLn(f_scr, '    Doc.PageSetup.Orientation = srfLandscape');

    WriteLn(f_scr, 'Set Diagram = Doc.Windows(1)');
    WriteLn(f_scr, '    Diagram.AutoRedraw = False');
    WriteLn(f_scr, '');


   (* Гридируем данные *)
     WriteLn(f_scr, 'Surfer.GridData(DataFile:="'+ ncWeatherHazardsPath+inttostr(mn)+'.dat", _');
     WriteLn(f_scr, '       xCol:=2, _');
     WriteLn(f_scr, '       yCol:=1, _');
     WriteLn(f_scr, '       zCol:=3, _');
     WriteLn(f_scr, '       Algorithm:='        +IntMethod+', _');
     WriteLn(f_scr, '       NumCols:=100, _');
     WriteLn(f_scr, '       Numrows:=100, _');


 (* Настройки для различных методов интерполяции *)
   if IntMethod='srfKriging'  then begin
     WriteLn(f_scr, '       KrigType:='         +Ini.ReadString(IniSet, 'KrigType',          'srfKrigPoint')+', _');
     WriteLn(f_scr, '       KrigDriftType:='    +Ini.ReadString(IniSet, 'KrigDriftType',     'srfDriftNone')+', _');
     if Ini.ReadBool(IniSet, 'SearchEnable', false)=true then begin
      WriteLn(f_scr, '       SearchEnable:=1, _');
      WriteLn(f_scr, '       SearchNumSectors:=' +Ini.ReadString(IniSet, 'SearchNumSectors',  '4')  +', _');
      WriteLn(f_scr, '       SearchMinData:='    +Ini.ReadString(IniSet, 'SearchMinData',     '16') +', _');
      WriteLn(f_scr, '       SearchMaxData:='    +Ini.ReadString(IniSet, 'SearchMaxData',     '64') +', _');
      WriteLn(f_scr, '       SearchDataPerSect:='+Ini.ReadString(IniSet, 'SearchDataPerSect', '8')  +', _');
      WriteLn(f_scr, '       SearchMaxEmpty:='   +Ini.ReadString(IniSet, 'SearchMaxEmpty',    '3')  +', _');
      WriteLn(f_scr, '       SearchRad1:='       +Ini.ReadString(IniSet, 'SearchRad1',        '1')  +', _');
      WriteLn(f_scr, '       SearchRad2:='       +Ini.ReadString(IniSet, 'SearchRad2',        '1')  +', _');
      WriteLn(f_scr, '       SearchAngle:='      +Ini.ReadString(IniSet, 'SearchAngle',       '0')  +', _');
     end;
   end;

   if IntMethod='srfInverseDistanse' then begin
    if Ini.ReadBool(IniSet, 'SearchEnable', false)=true then begin
     WriteLn(f_scr, '       SearchEnable:='       +Ini.ReadString(IniSet, 'SearchEnable',      '0')  +', _');
     WriteLn(f_scr, '       SearchNumSectors:='   +Ini.ReadString(IniSet, 'SearchNumSectors',  '4')  +', _');
     WriteLn(f_scr, '       SearchMinData:='      +Ini.ReadString(IniSet, 'SearchMinData',     '16') +', _');
     WriteLn(f_scr, '       SearchMaxData:='      +Ini.ReadString(IniSet, 'SearchMaxData',     '64') +', _');
     WriteLn(f_scr, '       SearchDataPerSect:='  +Ini.ReadString(IniSet, 'SearchDataPerSect', '8')  +', _');
     WriteLn(f_scr, '       SearchMaxEmpty:='     +Ini.ReadString(IniSet, 'SearchMaxEmpty',    '3')  +', _');
     WriteLn(f_scr, '       SearchRad1:='         +Ini.ReadString(IniSet, 'SearchRad1',        '1')  +', _');
     WriteLn(f_scr, '       SearchRad2:='         +Ini.ReadString(IniSet, 'SearchRad2',        '1')  +', _');
     WriteLn(f_scr, '       SearchAngle:='        +Ini.ReadString(IniSet, 'SearchAngle',       '0')  +', _');
    end;
     WriteLn(f_scr, '       AnisotropyRatio:='    +Ini.ReadString(IniSet, 'AnisotropyRatio',   '1')  +', _');
     WriteLn(f_scr, '       AnisotropyAngle:='    +Ini.ReadString(IniSet, 'AnisotropyAngle',   '0')  +', _');
     WriteLn(f_scr, '       IDPower:='            +Ini.ReadString(IniSet, 'IDPower',           '2')  +', _');
     WriteLn(f_scr, '       IDSmoothing:='        +Ini.ReadString(IniSet, 'IDSmoothing',       '0')  +', _');
   end;
   if IntMethod='srfNaturalNeighbor' then begin
     WriteLn(f_scr, '       AnisotropyRatio:='    +Ini.ReadString(IniSet, 'AnisotropyRatio',   '1')  +', _');
     WriteLn(f_scr, '       AnisotropyAngle:='    +Ini.ReadString(IniSet, 'AnisotropyAngle',   '0')  +', _');
   end;
   if IntMethod='srfNearestNeighbor' then begin
     WriteLn(f_scr, '       SearchRad1:='         +Ini.ReadString(IniSet, 'SearchRad1',        '1')  +', _');
     WriteLn(f_scr, '       SearchRad2:='         +Ini.ReadString(IniSet, 'SearchRad2',        '1')  +', _');
     WriteLn(f_scr, '       SearchAngle:='        +Ini.ReadString(IniSet, 'SearchAngle',       '0')  +', _');
   end;
   if IntMethod='srfMinCurvature' then begin
     WriteLn(f_scr, '       MCMaxResidual:='      +Ini.ReadString(IniSet, 'MCMaxResidual',     '1E-9')+', _');
     WriteLn(f_scr, '       MCMaxIterations:='    +Ini.ReadString(IniSet, 'MCMaxIterations',   '1E+5')+', _');
     WriteLn(f_scr, '       MCInternalTension:='  +Ini.ReadString(IniSet, 'MCInternalTension', '1')  +', _');
     WriteLn(f_scr, '       MCBoundaryTension:='  +Ini.ReadString(IniSet, 'MCBoundaryTension', '0')  +', _');
     WriteLn(f_scr, '       MCRelaxationFactor:=' +Ini.ReadString(IniSet, 'MCRelaxationFactor','0')  +', _');
     WriteLn(f_scr, '       AnisotropyRatio:='    +Ini.ReadString(IniSet, 'AnisotropyRatio',   '1')  +', _');
     WriteLn(f_scr, '       AnisotropyAngle:='    +Ini.ReadString(IniSet, 'AnisotropyAngle',   '0')  +', _');
   end;
   if IntMethod='srfRadialBasis' then begin
     WriteLn(f_scr, '       AnisotropyRatio:='    +Ini.ReadString(IniSet, 'AnisotropyRatio',   '1')  +', _');
     WriteLn(f_scr, '       AnisotropyAngle:='    +Ini.ReadString(IniSet, 'AnisotropyAngle',   '0')  +', _');
   end;
   if IntMethod='srfTriangulation' then begin
     WriteLn(f_scr, '       AnisotropyRatio:='    +Ini.ReadString(IniSet, 'AnisotropyRatio',   '1')  +', _');
     WriteLn(f_scr, '       AnisotropyAngle:='    +Ini.ReadString(IniSet, 'AnisotropyAngle',   '0')  +', _');
   end;
   if IntMethod='srfInverseDistanse' then begin
     WriteLn(f_scr, '       SearchMinData:='      +Ini.ReadString(IniSet, 'SearchMinData',     '16') +', _');
     WriteLn(f_scr, '       SearchRad1:='         +Ini.ReadString(IniSet, 'SearchRad1',        '1')  +', _');
     WriteLn(f_scr, '       SearchRad2:='         +Ini.ReadString(IniSet, 'SearchRad2',        '1')  +', _');
     WriteLn(f_scr, '       SearchAngle:='        +Ini.ReadString(IniSet, 'SearchAngle',       '0')  +', _');
   end;
     WriteLn(f_scr, '       DupMethod:=srfDupNone, _');
     WriteLn(f_scr, '       ExclusionFilter:="z=' +Ini.ReadString(IniSet, 'MissingVal', '-9999')+'", _');
     WriteLn(f_scr, '       ShowReport:=False, _');
     WriteLn(f_scr, '       OutGrid:=PathGRD)');
     WriteLn(f_scr, '');

     (* Бланкуем по берегам *)
   {  WriteLn(f_scr, 'Surfer.GridBlank(InGrid:=PathGRD, _');
     WriteLn(f_scr, '       BlankFile:=pathBlankMap, _');
     WriteLn(f_scr, '       OutGrid:=PathGRD, _');
     WriteLn(f_scr, '       OutFmt:=1)');
     WriteLn(f_scr, '');    }

     (* Filtering *)
     WriteLn(f_scr, 'Surfer.GridFilter(InGrid:=PathGRD, _');
 		WriteLn(f_scr, '  Filter:=srfFilterGaussian, _');
 		WriteLn(f_scr, '  NumPasses:=5, _');    //число прогонов из формы
 		WriteLn(f_scr, '  OutGrid:=PathGRD)');
     WriteLn(f_scr, '');


    (* Вставляем основной контур *)
    WriteLn(f_scr, 'Set ContourMap=Doc.Shapes.AddContourMap(PathGRD)');

         (* Пост со значениями*)
    WriteLn(f_scr, 'Set PostMap=Doc.Shapes.AddPostMap(DataFileName:="'+ ncWeatherHazardsPath+inttostr(mn)+'.dat", _');
    WriteLn(f_scr, 'xCol:=2, _');
    WriteLn(f_scr, 'yCol:=1)');
    WriteLn(f_scr, 'Set sampleMarks = PostMap.Overlays(1)');
    WriteLn(f_scr, 'With SampleMarks');
    WriteLn(f_scr, '  .Visible=False');
    WriteLn(f_scr, '  .LabelFont.Size=2');
    WriteLn(f_scr, '  .Symbol.Index=12');
    WriteLn(f_scr, '  .Symbol.Size=0.02');
    WriteLn(f_scr, '  .Symbol.Color=srfColorBlue');
    WriteLn(f_scr, '  .LabelAngle=0');
    WriteLn(f_scr, 'End With');
    WriteLn(f_scr, '');

    xmin:=0;
    xmax:=100;
    ymin:=63;
    ymax:=83;

    (* Убираем верхние и боковые метки с основного плота*)
    WriteLn(f_scr, 'Set Axes = ContourMap.Axes');
    WriteLn(f_scr, 'Set Axis = Axes("top axis")');
    WriteLn(f_scr, 'Axis.ShowLabels=False');
    WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
    WriteLn(f_scr, 'Axis.MajorTickLength=0');
    WriteLn(f_scr, 'Axis.LabelFont.Size=8');
    WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack');
    WriteLn(f_scr, 'Axis.SetScale('+
                                        floattostr(XMin)+','+
                                        floattostr(XMax)+','+
                                        '20,'+
                                        floattostr(XMin)+','+
                                        floattostr(XMax)+','+
                                        floattostr(YMax)+','+
                                        '0)');
    WriteLn(f_scr, '');


    WriteLn(f_scr, 'Set Axis = Axes("bottom axis")');
    WriteLn(f_scr, 'Axis.ShowLabels=True');
    Writeln(f_scr, 'Axis.ShowMajorGridLines=True');
    WriteLn(f_scr, 'Axis.MajorGridLine.ForeColorRGBA.Color =srfColorBlack50');
    WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
    WriteLn(f_scr, 'Axis.MajorTickLength=1E-1');
    WriteLn(f_scr, 'Axis.LabelFont.Size=8');
 //   WriteLn(f_scr, 'Axis.LabelFormat.Postfix="°"');
    WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack');
    WriteLn(f_scr, 'Axis.SetScale('+
                                       floattostr(XMin)+','+
                                       floattostr(XMax)+','+
                                       '20,'+
                                       floattostr(XMin)+','+
                                       floattostr(XMax)+','+
                                       floattostr(YMin)+','+
                                       '0)');
    WriteLn(f_scr, '');

    WriteLn(f_scr, 'Set Axis = Axes("right axis")');
    WriteLn(f_scr, 'Axis.ShowLabels=False');
    WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
    WriteLn(f_scr, 'Axis.MajorTickLength=0');
    WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack');
    WriteLn(f_scr, 'Axis.SetScale('+
                                        floattostr(YMin)+','+
                                        floattostr(YMax)+','+
                                        '5,'+
                                       // '5,'+
                                        floattostr(YMin)+','+
                                        floattostr(YMax)+','+
                                        floattostr(XMax)+','+
                                        '0)');
    WriteLn(f_scr, '');

    WriteLn(f_scr, 'Set Axis = Axes("left axis")');
    WriteLn(f_scr, 'Axis.ShowLabels=True');
    Writeln(f_scr, 'Axis.ShowMajorGridLines=True');
    WriteLn(f_scr, 'Axis.MajorGridLine.ForeColorRGBA.Color =srfColorBlack50');
    WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
    WriteLn(f_scr, 'Axis.MajorTickLength=1E-1');
    WriteLn(f_scr, 'Axis.LabelFont.Size=8');
  //  WriteLn(f_scr, 'Axis.LabelFormat.Postfix="°"');
    WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack');
    WriteLn(f_scr, 'Axis.SetScale('+
                                        floattostr(YMin)+','+
                                        floattostr(YMax)+','+
                                        '5,'+
                                       // '5,'+
                                        floattostr(YMin)+','+
                                        floattostr(YMax)+','+
                                        floattostr(XMin)+','+
                                        '0)');
    WriteLn(f_scr, '');



    (* Определяем размеры поля *)
    WriteLn(f_scr, 'Doc.Shapes.SelectAll');
    WriteLn(f_scr, 'Set Border = Doc.Selection.OverlayMaps');

      WriteLn(f_scr, 'X1='+Floattostr(XMin));
      WriteLn(f_scr, 'X2='+Floattostr(XMax));
      WriteLn(f_scr, 'Y1='+Floattostr(YMin));
      WriteLn(f_scr, 'Y2='+Floattostr(YMax));

    WriteLn(f_scr, '');


    (* Карта - подложка: берега на нулевой изобате *)
    WriteLn(f_scr, 'Set BaseMap=Doc.Shapes.AddBaseMap(pathBlankMap)');
    WriteLn(f_scr, 'Set BaseMap1 = BaseMap.Overlays(1)');
    WriteLn(f_scr, 'BaseMap1.Fill.Pattern="Solid"');
    WriteLn(f_scr, 'BaseMap1.Fill.ForeColor=srfColorBlack40');
    WriteLn(f_scr, 'BaseMap1.Line.ForeColorRGBA.Color=srfColorBlack80');
    WriteLn(f_scr, '');

    (* Объединяем и задаём общие свойства *)
    WriteLn(f_scr, 'Doc.Shapes.SelectAll');
    WriteLn(f_scr, 'Set NewMap = Doc.Selection.OverlayMaps');
    WriteLn(f_scr, 'With NewMap');
    WriteLn(f_scr, '  .SetLimits(xMin:=X1, xMax:=X2, yMin:=Y1, yMax:=Y2)');
    WriteLn(f_scr, '  .xLength=20');
    WriteLn(f_scr, '  .yLength=10');

    WriteLn(f_scr, '  .BackgroundFill.Pattern = "10 Percent"');
    WriteLn(f_scr, '  .BackgroundFill.ForeColor = srfGold');
    WriteLn(f_scr, '    L = .Left');
    WriteLn(f_scr, '    B = .Top-.Height');
    WriteLn(f_scr, 'End With');
    WriteLn(f_scr, '');

    WriteLn(f_scr, 'Set ContourMap = NewMap.Overlays(1)');
    WriteLn(f_scr, 'With ContourMap');
    WriteLn(f_scr, '  .FillContours = True');
    WriteLn(f_scr, '  .ShowColorScale = True');
    WriteLn(f_scr, '  .ColorScale.Top = NewMap.Top');
    WriteLn(f_scr, '  .ColorScale.Height = NewMap.Height');
    WriteLn(f_scr, '  .ColorScale.Left = NewMap.Left+NewMap.Width+0.4');
    WriteLn(f_scr, '  .ColorScale.FrameLine.Style = "Invisible"');
    WriteLn(f_scr, '  .ColorScale.LabelFrequency=10');

    (* Заливаем контур *)
   if cblvl1.text<>'' then
   WriteLn(f_scr, '  .Levels.LoadFile("'+GlobalPath+'support\lvl\'+cblvl1.text+'")');

   (* Добавляем цвет в контуры *)
   if cbclr1.text<>'' then
   WriteLn(f_scr, '  .FillForegroundColorMap.LoadFile("'+GlobalPath+'support\clr\'+cbclr1.text+'")');
   WriteLn(f_scr, '  .LabelLabelDist ='+Ini.ReadString(IniSet, 'LevelToEdgeDist',  '1'));
   WriteLn(f_scr, '  .LabelEdgeDist  ='+Ini.ReadString(IniSet, 'LevelToLevelDist', '1'));
   WriteLn(f_scr, '  .LabelTolerance ='+Ini.ReadString(IniSet, 'CurveTolerance',   '15E-1'));
   WriteLn(f_scr, '  .LabelFont.Size = 6');
   WriteLn(f_scr, '  .Levels.SetLabelFrequency('+
                     'FirstIndex  :='+Ini.ReadString(IniSet, 'LevelFirst', '1')+','+
                     'NumberToSet :='+Ini.ReadString(IniSet, 'LevelSet',   '1')+','+
                     'NumberToSkip:='+Ini.ReadString(IniSet, 'LevelSkip',  '9')+')');
   WriteLn(f_scr, 'End With');
   WriteLn(f_scr, '');


    WriteLn(f_scr, 'Doc.Export(FileName:="'+ ncWeatherHazardsPath+'png\'+inttostr(mn)+'.png", _');
    WriteLn(f_scr, 'SelectionOnly:=False , Options:="Width=720; KeepAspect=1; HDPI=300; VDPI=300")');
    WriteLn(f_scr, '');

    WriteLn(f_scr, 'Diagram.Zoom(srfZoomFitToWindow)');
    WriteLn(f_scr, 'Diagram.AutoRedraw = True');


   WriteLn(f_scr, 'Doc.SaveAs(FileName:="'+ ncWeatherHazardsPath+'srf\'+inttostr(mn)+'.srf")');
   WriteLn(f_scr, 'Doc.Close(SaveChanges:=srfSaveChangesNo) ');

   WriteLn(f_scr, 'End Sub');


  finally
    Ini.Free; // close settings file
    CloseFile(f_scr); // close script file
  end;

  {$IFDEF WINDOWS}
    frmmain.RunScript(2, '"'+ncWeatherHazardsPath+'script.bas"', nil);
  {$ENDIF}
  end;  //mn

end;



procedure Tfrmweatherhazards.btnSettingsClick(Sender: TObject);
begin
 frmSurferSettings := TfrmSurferSettings.Create(Self);
 frmSurferSettings.LoadSettings('ncweatherhazards');
  try
   if not frmSurferSettings.ShowModal = mrOk then exit;
  finally
    frmSurferSettings.Free;
    frmSurferSettings := nil;
  end;
end;


procedure Tfrmweatherhazards.btndifferenceClick(Sender: TObject);
Var
 mn:integer;
 lat, lon, cnt1, cnt2, per1, per2:real;
begin
 //for mn:=1 to 12 do begin
mn:=1;
   AssignFile(f_dat,  edit1.text+inttostr(mn)+'.dat'); reset(f_dat);
   AssignFile(f_dat2, edit2.text+inttostr(mn)+'.dat'); reset(f_dat2);
   AssignFile(f_out,  ncWeatherHazardsPath+inttostr(mn)+'.dat'); Rewrite(f_out);

   readln(f_dat);
   readln(f_dat2);
   writeln(f_out, 'Lat':15, 'Lon':15, 'dif':15, 'dif_%':15);
   repeat
     readln(f_dat,  lat, lon, cnt1, per1);
     readln(f_dat2, lat, lon, cnt2, per2);
    writeln(f_out, lat:15:5, lon:15:5, (cnt1-cnt2):15:5, (per1-per2):15:5);
   until eof(f_dat);
   closefile(f_out);
   closefile(f_dat);
   closefile(f_dat2);
 //end;
 //btnPlot.OnClick(self);
end;

end.

