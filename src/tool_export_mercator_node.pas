unit tool_export_mercator_node;

{$mode objfpc}{$H+}

interface

uses ncmain, declarations_netcdf, variants, SysUtils, dialogs, bufdataset, DB,
     math, dateutils;

procedure exportmercatornode_day;
procedure exportmercatornode_level;

implementation


procedure exportmercatornode_level;
Var
 ncid, varidpT, varidpS, varidpD, varnattsp:integer;
 status : integer;
 attname: array of pAnsiChar;

 ff, zz:integer;

 dat: text;

 date1:real;

 start: PArraySize_t;
 ft, fs:array of smallint;

 varndimsp: integer;
 vardimidsp:array of integer;

 DimTot, i, k, a:integer;
 zz_i, lt_i, ln_i: integer;
 lenp: size_t;

 val0t, val0s:variant;
 val1t, val1s:real;

 scaleT, offsetT, missingT: array [0..0] of single;
 scaleS, offsetS, missingS: array [0..0] of single;

 svan:real;
 SA, dens, p:double;

 coordinates, long_name, standard_name, units, unit_long: string;
 short_name, cell_methods, alg_name, history:string;
 fillvalue, scale_factor, add_offset: array of single;

 PathExport: string;

 yy, mn, dd:word;
 CDS:TBufDataset;
begin
 PathExport:='x:\ClimateShell\unload\export\mercator\';

  CDS:=TBufDataset.Create(nil);
   with  CDS.FieldDefs do begin
    Add('lev' ,ftFloat,   0, false);
    Add('yy'  ,ftInteger, 0, false);
    Add('mn'  ,ftInteger, 0, false);
    Add('dd'  ,ftInteger, 0, false);
    Add('val1t' ,ftFloat  , 0, false);
    Add('val1s' ,ftFloat  , 0, false);
   end;
  CDS.CreateDataSet;


 for ff:=0 to frmmain.cbFiles.count-1 do begin
   ncName:=frmmain.cbFiles.Items.strings[ff];

   yy:=StrToInt(copy(ncname, 1, 4));
   mn:=StrToInt(copy(ncname, 6, 2));
   dd:=StrToInt(copy(ncname, 9, 2));

 //  AssignFile(dat, PathExport+yy+mn+dd+'.txt'); rewrite(dat);

   try
      nc_open(pansichar(AnsiString(ncpath+ncname)), NC_NOWRITE, ncid); // открываем файл

      nc_inq_varid (ncid, pChar('thetao'), varidpT);
      nc_inq_varid (ncid, pChar('so'), varidpS);


   (* Читаем коэффициенты из файла *)
   scaleT[0]:=1;
   offsetT[0]:=0;
   missingT[0]:=-9999;
   nc_inq_varnatts (ncid, varidpT, varnattsp); // count of attributes for variable
   setlength(attname, NC_MAX_NAME); // задаем длину названия аттрибута
    for a:=0 to varnattsp-1 do begin
      nc_inq_attname(ncid, varidpT, a, attname); // имя аттрибута
         if pAnsiChar(attname)='add_offset'    then begin
            nc_get_att_float(ncid, varidpT, pansichar(pansichar(AnsiString('add_offset'))),    offsetT);
         end;
         if pAnsiChar(attname)='scale_factor'  then begin
            nc_get_att_float(ncid, varidpT, pansichar(pansichar(AnsiString('scale_factor'))),  scaleT);
             if scalet[0]=0 then scalet[0]:=1;
         end;
         if pAnsiChar(attname)='missing_value' then begin
            nc_get_att_float(ncid, varidpT, pansichar(pansichar(AnsiString('missing_value'))), missingT);
         end;
         if pAnsiChar(attname)='_FillValue' then begin
            nc_get_att_float(ncid, varidpT, pansichar(pansichar(AnsiString('_FillValue'))), missingT);
         end;
    end;

    scaleS[0]:=1;
    offsetS[0]:=0;
    missingS[0]:=-9999;
    nc_inq_varnatts (ncid, varidpS, varnattsp); // count of attributes for variable
    setlength(attname, NC_MAX_NAME); // задаем длину названия аттрибута
     for a:=0 to varnattsp-1 do begin
       nc_inq_attname(ncid, varidpS, a, attname); // имя аттрибута
          if pAnsiChar(attname)='add_offset'    then begin
             nc_get_att_float(ncid, varidpS, pansichar(pansichar(AnsiString('add_offset'))),    offsetS);
          end;
          if pAnsiChar(attname)='scale_factor'  then begin
             nc_get_att_float(ncid, varidpS, pansichar(pansichar(AnsiString('scale_factor'))),  scaleS);
              if scaleS[0]=0 then scaleS[0]:=1;
          end;
          if pAnsiChar(attname)='missing_value' then begin
             nc_get_att_float(ncid, varidpS, pansichar(pansichar(AnsiString('missing_value'))), missingS);
          end;
          if pAnsiChar(attname)='_FillValue' then begin
             nc_get_att_float(ncid, varidpS, pansichar(pansichar(AnsiString('_FillValue'))), missingS);
          end;
     end;
   (*конец чтения коэффициентов *)

 //  showmessage('coeff ok');


   start:=GetMemory(SizeOf(TArraySize_t)*4); // get memory for start pointer

    start^[0]:=0;
    start^[2]:=0;
    start^[3]:=0;
    for zz_i:=0 to high(ncLev_arr) do begin //Levels
     start^[1]:=zz_i;

  //   showmessage(inttostr(zz_i));
     if  ncLev_arr[zz_i]<1200 then begin
           SetLength(ft, 1);
           SetLength(fs, 1);
             nc_get_var1_short(ncid, varidpT, start^, ft);
             nc_get_var1_short(ncid, varidpS, start^, fs);
           Val0t:=ft[0];
           Val0s:=fs[0];

       //   showmessage(vartostr(val0t)+'   '+vartostr(val0s));

    if (val0t<>missingT[0]) and (val0T<>-9999) and
       (val0s<>missingT[0]) and (val0s<>-9999) then begin
           val1t:=scaleT[0]*val0t+offsetT[0];
           val1s:=scaleS[0]*val0s+offsetS[0];

        //   showmessage(vartostr(val1t)+'   '+vartostr(val1s));
       // CDS.Locate('Lev', nclev_arr[zz_i], [loCaseInsensitive]);
        With CDS do begin
         Append;
           FieldByName('lev').AsFloat:=nclev_arr[zz_i];
           FieldByName('yy').AsInteger:=yy;
           FieldByName('mn').AsInteger:=mn;
           FieldByName('dd').AsInteger:=dd;
           FieldByName('val1t').AsFloat:=val1t;
           FieldByName('val1s').AsFloat:=val1s;
         Post;
        end;
      //  showmessage(floattostr(CDS.FieldByName('val1t').AsFloat));

      //  end;

      //  writeln(dat, nclev_arr[zz_i]:10:5, val1t:10:5, val1s:10:5);
       end;

    end;

    end;

   finally
    ft:=nil;
    fs:=nil;
    FreeMemory(start);
    nc_close(ncid);
   end;

 //  CloseFile(dat);
  end;


   for zz_i:=0 to high(ncLev_arr) do begin //Levels
     AssignFile(dat, PathExport+Floattostr(ncLev_arr[zz_i])+'.txt'); rewrite(dat);
    { CDS.Filtered:=false;
     CDS.Filter:='lev='+floattostr(roundto(ncLev_arr[zz_i], -2));
     CDS.Filtered:=true;
     CDS.IndexFieldNames:='yy;mn;dd'; }

   //  showmessage(CDS.Filter);

     CDS.First;
  //   showmessage(floattostr(CDS.FieldByName('val1t').AsFloat));


      While not CDS.EOF do begin
   //    showmessage(floattostr(CDS.FieldByName('val1t').AsFloat));
       yy:=CDS.FieldByName('yy').AsInteger;
       mn:=CDS.FieldByName('mn').AsInteger;
       dd:=CDS.FieldByName('dd').AsInteger;

       date1:=yy+((mn-1)/12)+((dd-1)/(daysinayear(yy)));
       if CDS.FieldByName('lev').AsFloat=ncLev_arr[zz_i] then
        writeln(dat, date1:15:10,
                     CDS.FieldByName('yy').AsInteger:5,
                     CDS.FieldByName('mn').AsInteger:3,
                     CDS.FieldByName('dd').AsInteger:3,
                     CDS.FieldByName('val1t').AsFloat:10:5,
                     CDS.FieldByName('val1s').AsFloat:10:5);

        CDS.Next;
      end;
     Closefile(dat);
   end;
 CDS.Free;
end;


procedure exportmercatornode_day;
Var
 ncid, varidpT, varidpS, varidpD, varnattsp:integer;
 status : integer;
 attname: array of pAnsiChar;

 ff, zz:integer;

 dat: text;

 start: PArraySize_t;
 ft, fs:array of smallint;

 varndimsp: integer;
 vardimidsp:array of integer;

 DimTot, i, k, a:integer;
 zz_i, lt_i, ln_i: integer;
 lenp: size_t;

 val0t, val0s:variant;
 val1t, val1s:real;

 scaleT, offsetT, missingT: array [0..0] of single;
 scaleS, offsetS, missingS: array [0..0] of single;

 svan:real;
 SA, dens, p:double;

 coordinates, long_name, standard_name, units, unit_long: string;
 short_name, cell_methods, alg_name, history:string;
 fillvalue, scale_factor, add_offset: array of single;

 PathExport: string;

 yy, mn, dd:string;
begin
 PathExport:='x:\ClimateShell\unload\export\mercator\';

 for ff:=0 to frmmain.cbFiles.count-1 do begin
   ncName:=frmmain.cbFiles.Items.strings[ff];

   yy:=copy(ncname, 1, 4);
   mn:=copy(ncname, 6, 2);
   dd:=copy(ncname, 9, 2);

   AssignFile(dat, PathExport+yy+mn+dd+'.txt'); rewrite(dat);

   try
      nc_open(pansichar(AnsiString(ncpath+ncname)), NC_NOWRITE, ncid); // открываем файл

      nc_inq_varid (ncid, pChar('thetao'), varidpT);
      nc_inq_varid (ncid, pChar('so'), varidpS);


   (* Читаем коэффициенты из файла *)
   scaleT[0]:=1;
   offsetT[0]:=0;
   missingT[0]:=-9999;
   nc_inq_varnatts (ncid, varidpT, varnattsp); // count of attributes for variable
   setlength(attname, NC_MAX_NAME); // задаем длину названия аттрибута
    for a:=0 to varnattsp-1 do begin
      nc_inq_attname(ncid, varidpT, a, attname); // имя аттрибута
         if pAnsiChar(attname)='add_offset'    then begin
            nc_get_att_float(ncid, varidpT, pansichar(pansichar(AnsiString('add_offset'))),    offsetT);
         end;
         if pAnsiChar(attname)='scale_factor'  then begin
            nc_get_att_float(ncid, varidpT, pansichar(pansichar(AnsiString('scale_factor'))),  scaleT);
             if scalet[0]=0 then scalet[0]:=1;
         end;
         if pAnsiChar(attname)='missing_value' then begin
            nc_get_att_float(ncid, varidpT, pansichar(pansichar(AnsiString('missing_value'))), missingT);
         end;
         if pAnsiChar(attname)='_FillValue' then begin
            nc_get_att_float(ncid, varidpT, pansichar(pansichar(AnsiString('_FillValue'))), missingT);
         end;
    end;

    scaleS[0]:=1;
    offsetS[0]:=0;
    missingS[0]:=-9999;
    nc_inq_varnatts (ncid, varidpS, varnattsp); // count of attributes for variable
    setlength(attname, NC_MAX_NAME); // задаем длину названия аттрибута
     for a:=0 to varnattsp-1 do begin
       nc_inq_attname(ncid, varidpS, a, attname); // имя аттрибута
          if pAnsiChar(attname)='add_offset'    then begin
             nc_get_att_float(ncid, varidpS, pansichar(pansichar(AnsiString('add_offset'))),    offsetS);
          end;
          if pAnsiChar(attname)='scale_factor'  then begin
             nc_get_att_float(ncid, varidpS, pansichar(pansichar(AnsiString('scale_factor'))),  scaleS);
              if scaleS[0]=0 then scaleS[0]:=1;
          end;
          if pAnsiChar(attname)='missing_value' then begin
             nc_get_att_float(ncid, varidpS, pansichar(pansichar(AnsiString('missing_value'))), missingS);
          end;
          if pAnsiChar(attname)='_FillValue' then begin
             nc_get_att_float(ncid, varidpS, pansichar(pansichar(AnsiString('_FillValue'))), missingS);
          end;
     end;
   (*конец чтения коэффициентов *)

 //  showmessage('coeff ok');


   start:=GetMemory(SizeOf(TArraySize_t)*4); // get memory for start pointer

    start^[0]:=0;
    start^[2]:=0;
    start^[3]:=0;
    for zz_i:=0 to high(ncLev_arr) do begin //Levels
     start^[1]:=zz_i;

  //   showmessage(inttostr(zz_i));
     if  ncLev_arr[zz_i]<1200 then begin
           SetLength(ft, 1);
           SetLength(fs, 1);
             nc_get_var1_short(ncid, varidpT, start^, ft);
             nc_get_var1_short(ncid, varidpS, start^, fs);
           Val0t:=ft[0];
           Val0s:=fs[0];

       //   showmessage(vartostr(val0t)+'   '+vartostr(val0s));

    if (val0t<>missingT[0]) and (val0T<>-9999) and
       (val0s<>missingT[0]) and (val0s<>-9999) then begin
           val1t:=scaleT[0]*val0t+offsetT[0];
           val1s:=scaleS[0]*val0s+offsetS[0];

        //   showmessage(vartostr(val1t)+'   '+vartostr(val1s));

        writeln(dat, nclev_arr[zz_i]:10:5, val1t:10:5, val1s:10:5);
       end;

    end;

    end;

   finally
    ft:=nil;
    fs:=nil;
    FreeMemory(start);
    nc_close(ncid);
   end;

   CloseFile(dat);
  end;
end;

end.

