unit nciceedge;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, declarations_netcdf, ncmain, DateUtils;

procedure GetIce(path:string; yy, mn: integer; MinLat, MaxLat, MinLon,
                 MaxLon:real; prj:integer);

implementation

procedure GetIce(path:string; yy, mn: integer; MinLat, MaxLat, MinLon,
                 MaxLon:real; prj:integer);
Var
  f_dat:text;
  ncid, varidp:integer;
  lt_i, ln_i, k, i, mn1, yy1:integer;
  start: PArraySize_t;
  va :array of single;
  val0, lon, lat:real;
 // yrs, mns, buf_str:string;

  IceTime_arr : array of double; // global array  of time
  idp:integer;
  lenp:size_t;
  IniDate, CurDate:TDateTime;
  cbIceDate:TStringList;
  x, y:real;
begin
 If FileExists(Path+'ice.dat') then DeleteFile(Path+'ice.dat');

 try
  (* nc_open*)
   cbIceDate:=TStringList.Create;

   nc_open(pchar(GlobalSupportPath+'ice'+PathDelim+'HadISST_ice.nc'), NC_NOWRITE, ncid); // only for reading

   nc_inq_dimid  (ncid, pAnsiChar('time'), idp);
   nc_inq_dimlen (ncid, idp, lenp);
   setlength(IceTime_arr, lenp);
   nc_get_var_double (ncid, idp, IceTime_arr);

   IniDate:=EncodeDate(1870, 1, 1);
    for k:=0 to high(IceTime_arr) do begin
     CurDate:=incday(IniDate, trunc(IceTime_arr[k]));
     cbIceDate.Add(datetostr(CurDate));
   end;
  finally
   nc_close(ncid);  // Close file
   IceTime_arr := nil;
  end;

try
(* nc_open*)
 nc_open(pchar(GlobalSupportPath+'ice'+PathDelim+'HadISST_ice.nc'), NC_NOWRITE, ncid); // only for reading
 nc_inq_varid (ncid, pansichar('sic'), varidp); // variable ID

  start:=GetMemory(SizeOf(TArraySize_t)*3); // get memory for start pointer

  (* looking for the right date for ICE *)
  start^[0]:=-9999;
  if cbIceDate.Count>0 then begin
     for k:=0 to cbIceDate.Count-1 do begin
      mn1:=StrToInt(copy(cbIceDate.Strings[k], 4, 2));
      yy1:=StrToInt(copy(cbIceDate.Strings[k], 7, 4));
      if (mn1=mn) and (yy1=yy) then start^[0]:=k;
    end;
  end;

  if start^[0]<>-9999 then begin
  // assign output file
  AssignFile(f_dat, Path+'ice.dat'); Rewrite(f_dat);
  writeln(f_dat, 'Lat':9, 'Lon':11, 'y':11, 'x':11, 'Ice':11);

  lon:=-180.5; //initial to be 179.5
    for ln_i:=0 to 360-1 do begin
     start^[2]:=ln_i; //lon
     lon:=lon+1;

     lat:=-90.5; //initial to be 89.5
     for lt_i:=180-1 downto 0 do begin
      start^[1]:=lt_i;  //lat
      lat:=lat+1;

      if (lat>=MinLat) and
         (lat<=MaxLat) and
         (lon>=MinLon) and
         (lon<=MaxLon) then begin
          SetLength(va, 1);
           nc_get_var1_float(ncid, varidp, start^, va);

          Val0:=va[0];

           if prj=0 then begin
            x:=Lon;
            y:=Lat;
           end;
           if prj=1 then begin
            x:= (90-Lat)*111.12*sin((Lon)*Pi/180);
            y:=-(90-Lat)*111.12*cos((Lon)*Pi/180);
           end;
           if prj=2 then begin
            x:=(Lat+90)*sin((Lon)*pi/180);
            y:=(Lat+90)*cos((Lon)*pi/180);
           end;

          if (val0>=0) and (val0<=1) then writeln(f_dat, Lat:9:5, Lon:11:5, y:13:5, x:13:5, Val0:13:5);
     end; // region
    end; // lat
   end; // lon
    Closefile(f_dat);
  end;

 FreeMemory(start);
finally
  va:=nil;
 nc_close(ncid);  // Close file
 cbIceDate.Free;
end;
end;

end.

