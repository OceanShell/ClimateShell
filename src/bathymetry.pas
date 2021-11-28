unit bathymetry;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, Dialogs, ncmain, declarations_netcdf;

Function  GetBathymetry(Lon, Lat:real):integer;

implementation

Function  GetBathymetry(Lon, Lat:real):integer;
Var
Ini:TIniFile;
fname: string;
ncid, varidp:integer;
start: PArraySize_t;
sp:array of smallint;
lat0, lon0, step: real;
begin
 result:=-99999;

 Ini := TIniFile.Create(IniFileName);
 try
  fname:=Ini.ReadString('main', 'GEBCOPath', GlobalSupportPath+'bathymetry'+PathDelim+'GEBCO_2021.nc');
 finally
  Ini.Free;
 end;

 (* if full GEBCO_2021.nc is found *)
 if not FileExists(fname) then exit;

 lat0:=-(89+(59/60)+(525E-1/3600));  // first latitude
 lon0:=-(179+(59/60)+(525E-1/3600)); // first longitude
 step  := 1/240;  // 15"

 try
   nc_open(pansichar(fname), NC_NOWRITE, ncid);
   nc_inq_varid (ncid, pChar('elevation'), varidp);

     start:=GetMemory(SizeOf(TArraySize_t)*2);

     // search by indexes
     start^[0]:=abs(trunc((lat0-lat)/step)); // lat index
     start^[1]:=abs(trunc((lon0-lon)/step)); // lon index

     SetLength(sp, 1); // setting an empty array

      nc_get_var1_short(ncid, varidp, start^, sp);  // sending request to the file
     result:=sp[0]; // getting results
   finally
      sp:=nil;
      FreeMemory(start);
    nc_close(ncid);  // Close nc file
   end;
end;

end.


