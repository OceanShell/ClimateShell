unit ncexportncep;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dialogs;

procedure exportncep;

implementation

uses ncmain, ncprocedures, declarations_netcdf;

procedure exportncep;
Var
 fout:text;
 param:string;
 ncid, varidp, varndimsp: integer;
 vardimidsp: array of integer;
 vtype:nc_type;
 fp:array of single;
 start: PArraySize_t;
 tt, ll, lnl, lt: Integer;
 scale, offset, missing: array [0..0] of single;
 val1:real;
begin
 if not DirectoryExists(GlobalPath+'unload'+PathDelim+'export'+PathDelim) then
    CreateDir(GlobalPath+'unload'+PathDelim+'export'+PathDelim);
 if not DirectoryExists(GlobalPath+'unload'+PathDelim+'export'+PathDelim+'levels'+PathDelim) then
    CreateDir(GlobalPath+'unload'+PathDelim+'export'+PathDelim+'levels'+PathDelim);

  try
   nc_open(pansichar(AnsiString(ncpath+ncname)), NC_NOWRITE, ncid); // открываем файл

      param:=frmmain.cbVariables.Items.Strings[0];

       nc_inq_varid(ncid, pansichar(ansistring(param)), varidp); // id параметра
       nc_inq_vartype(ncid, varidp, vtype); // тип параметра
       nc_inq_varndims(ncid, varidp, varndimsp); // количество размерностей

       SetLength(vardimidsp, varndimsp); //number of dimensions
       nc_inq_vardimid (ncid, varidp, vardimidsp); // Dimention ID's

       nc_get_att_float(ncid, varidp, pansichar(pansichar(AnsiString('add_offset'))),    offset);
       nc_get_att_float(ncid, varidp, pansichar(pansichar(AnsiString('scale_factor'))),  scale);
       nc_get_att_float(ncid, varidp, pansichar(pansichar(AnsiString('missing_value'))), missing);

       SetLength(fp, 1);
       start:=GetMemory(SizeOf(TArraySize_t)*varndimsp); // get memory for start pointer

    (* if there are NO levels in the file *)
    if varndimsp=3 then begin
     AssignFile(fout, GlobalPath+'unload'+PathDelim+'export'+PathDelim+ncname+'.txt'); rewrite(fout);
        for tt := 0 to high(ncTime_arr) do begin
         start^[0]:=tt; //time
          for lt:=0 to high(ncLat_arr) do begin
           start^[1]:=lt;  //lat
           write(fout, inttostr(tt+1):5);
            for lnl:=0 to high(ncLon_arr) do begin
             start^[2]:=lnl;
              SetLength(fp, 1);
               nc_get_var1_float(ncid, varidp, start^, fp);
                if fp[0]<>missing[0] then begin
                  val1:=scale[0]*fp[0]+offset[0]; // scale and offset from nc file
                  write(fout, ' ', val1:10:5);
                end else write(fout, ' ', '-9999':10);
             end; //lnl
            writeln(fout);
          end;  //lt
        end;  //tt
       Closefile(fout);
    end; //end varndimsp=3 (no levels)

   (* if there are levels in the file *)
    if varndimsp=4 then begin
     for ll := 0 to high(ncLev_arr) do begin
      AssignFile(fout, GlobalPath+'unload'+PathDelim+'export'+PathDelim+'levels'+
                       PathDelim+floattostr(ncLev_arr[ll])); rewrite(fout);
      start^[1]:=ll; //time
        for tt := 0 to high(ncTime_arr) do begin
         start^[0]:=tt; //time
          for lt:=0 to high(ncLat_arr) do begin
           start^[2]:=lt;  //lat
           write(fout, inttostr(tt+1):5);
            for lnl:=0 to high(ncLon_arr) do begin
             start^[3]:=lnl;
              SetLength(fp, 1);
               nc_get_var1_float(ncid, varidp, start^, fp);
                if fp[0]<>missing[0] then begin
                  val1:=scale[0]*fp[0]+offset[0]; // scale and offset from nc file
                  write(fout, ' ', val1:10:5);
                end else write(fout, ' ', '-9999':10);
             end; //lnl
            writeln(fout);
          end;  //lt
        end;  //tt
       Closefile(fout);
      end; //ll
    end; //end varndimsp=4
 finally
  fp:=nil;
  FreeMemory(start);
  nc_close(ncid);  // Close file
 end;
 if MessageDlg('Export has been completed', mtInformation, [mbOk], 0)=1 then exit;
end;

end.

