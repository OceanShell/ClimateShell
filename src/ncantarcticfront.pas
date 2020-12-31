unit ncantarcticfront;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ncmain, ncprocedures, declarations_netcdf,
  dateutils, variants, dialogs;

procedure GetFrontPosition;
procedure Average(src: array of real; N: Integer; Var dest:array of real);

implementation

(* CHECK THE FINAL YEAR IN THE CODE!!! *)


procedure Average(src: array of real; N: Integer; Var dest:array of real);
Var
Count, k, i:integer;
Sum, Av:real;
begin
Count:=Length(Src);

Sum:=0;
For k:=0 to N-1 do Sum:=Sum+Src[k];
Dest[0]:=Sum/N;
k:=0;
For i:=N to Count do begin
 Sum:=Sum+Src[i]-Src[i-N];
  inc(k);
  Dest[k]:=Sum/N;
end;

end;


(* Data file HAS TO HAVE limitations: month=9, lat_max=-45, lat_min=-65 *)
procedure GetFrontPosition;
Var
  dat, dat2:text;
  ncid, varidp, ndimsp, c, k, lag, N2, i:integer;
  tt, lati, loni:integer;
  scale, offset, missing: array [0..0] of single;
  atttext: array of pansichar;
  attlenp, lenp:size_t;
  vtype :nc_type;
  sp:array of smallint;
  start: PArraySize_t;
  val0, val1, dep, val, vali:real;
  yy, mn, dd, hh, mm, ss, ms:word;
  old_val, dt, dt_max, lt_max, lon1:real;
  st:string;


  path:string;
  src_arr, dest_arr, lon_arr, val_arr, tmp_arr: array of real;
  lon, x, y:real;
begin

  Lag:=17; // шаг по долготам, сглаживаем до 1 градуса

  SetLength(val_arr,  high(ncLon_arr));

 try
   nc_open(pchar(ncpath+ncname), NC_NOWRITE, ncid); // only for reading

   nc_inq_varid (ncid, pChar('sst'), varidp); // variable ID
   nc_inq_vartype (ncid, varidp, vtype);
   nc_inq_varndims (ncid, varidp, ndimsp);

   nc_get_att_float(ncid, varidp, pchar('add_offset'),    offset);
   nc_get_att_float(ncid, varidp, pchar('scale_factor'),  scale);
   nc_get_att_float(ncid, varidp, pchar('missing_value'), missing);

   if scale[0]=0 then scale[0]:=1; // if there's no scale in the file

   nc_inq_dimlen (ncid, timeDid, lenp);
    setlength(ncTime_arr, lenp);
    nc_get_var_double (ncid, timeVid, ncTime_arr);

   nc_inq_attlen (ncid, timeVid, pchar('units'), attlenp);
   setlength(atttext, attlenp);
   nc_get_att_text (ncid, timeVid, pchar('units'), atttext);

   GetDates(pansichar(atttext));

   start:=GetMemory(SizeOf(TArraySize_t)*ndimsp); // get memory for start pointer

   for tt:=0 to high(ncTime_arr) do begin
   DecodeDateTime(StrToDateTime(frmmain.cbDates.Items.Strings[tt]), yy, mn, dd, hh, mm, ss, ms);

   AssignFile(dat2, GlobalPath+'unload\antarcticfront\'+inttostr(yy)+'.dat'); Rewrite(dat2);

   start^[0]:=tt; //time
   for loni:=0 to high(ncLon_arr) do begin
    start^[2]:=loni;

     old_val:=-999; dt:=-999; dt_max:=-999; lt_max:=0;
      for lati:=0 to high(ncLat_arr) do begin
       start^[1]:=lati;  //lat

              SetLength(sp, 1);
                nc_get_var1_short(ncid, varidp, start^, sp);
               Val0:=sp[0];

            if (Val0<>missing[0]) then begin  // if value is not missing
                val1:=scale[0]*Val0+offset[0]; // scale and offset from netcdf
                val1:=val1-273.1516;  // user defined conversion

                if old_val=-999 then old_val:=val1 else begin
                 dt:=val1-old_val;
                 if (dt>dt_max) and (val1>-1.6) and (val1<=-1) then begin
                  dt_max:=dt;
                  val_arr[loni]:=ncLat_arr[lati];
                 end;
                 old_val:=val1;
                // if (loni=0) then vali:=lt_max;
                end;
           end; // end of missing value loop
     end; // end of lat loop

   //   dep:=getgebcodepth(ncLon_arr[loni], lt_max);

  //  if (frac(ncLon_arr[loni])=0) and (trunc(ncLon_arr[loni]) mod 5=0) then begin

      writeln(dat2, ncLon_arr[loni]:12:3, val_arr[loni]:12:3);
 //   end;
   end;  // lon

   lon1:=180;
   for k:=0 to 8 do begin
     writeln(dat2, lon1:12:3, val_arr[k]:12:3);
     lon1:=lon1+0.125;
   end;
    closefile(dat2);
   end;
 finally
  nc_close(ncid);  // Close file
  FreeMemory(start);
 end;


 ////////////////////////////////// running average//////////////////////

 AssignFile(dat2, GlobalPath+'unload\antarcticfront\antarcticfront.dat'); Rewrite(dat2);
 write(dat2, '"YY"':5);
 for loni:=0 to 359 do write(dat2, '"'+Inttostr(loni)+'"':8);
 writeln(dat2);

 path:=GlobalPath+'unload\antarcticfront\';
 for yy:=1979 to 2017 do begin

  write(dat2, yy:5);

  SetLength(src_arr,  2889);
  SetLength(lon_arr,  2889);
  SetLength(dest_arr, 2889-lag+1);
  SetLength(tmp_arr,  360);

  AssignFile(dat,  path+inttostr(yy)+'.dat'); Reset(dat);
  k:=-1;
  repeat
   inc(k);
 //  showmessage('here0');
    readln(dat, lon_arr[k], src_arr[k]);
  until eof(dat);
  Closefile(dat);
 // showmessage('here');
  Average(src_arr, lag, dest_arr);

  AssignFile(dat, path+inttostr(yy)+'_s.dat'); Rewrite(dat);
  c:=0;
  for k:=0 to high(dest_arr) do begin
   if c=0 then begin
     //  x:= (90-dest_arr[k])*111.12*sin((lon_arr[k+trunc(lag/2)])*Pi/180);
    //   y:=-(90-dest_arr[k])*111.12*cos((lon_arr[k+trunc(lag/2)])*Pi/180);

     x:=(dest_arr[k]+90)*sin((lon_arr[k+trunc(lag/2)]-0)*pi/180);
     y:=(dest_arr[k]+90)*cos((lon_arr[k+trunc(lag/2)]-0)*pi/180);

     writeln(dat, lon_arr[k+trunc(lag/2)]:8:3, dest_arr[k]:8:3, x:8:3, y:8:3);

   end;
   inc(c);
   if c=8 then c:=0;
  end;
  Closefile(dat);

 c:=0; i:=0;
 for k:=0 to high(dest_arr) do begin
  if c=0 then begin
   tmp_arr[i]:=dest_arr[k];
   inc(i);
  end;
  inc(c);
  if c=8 then c:=0;
 end;

 for k:=179 to 359 do write(dat2, tmp_arr[k]:8:3);
 for k:=0   to 178 do write(dat2, tmp_arr[k]:8:3);
 writeln(dat2);
end; //years
Closefile(dat2);


 showmessage('done');
end;


end.

