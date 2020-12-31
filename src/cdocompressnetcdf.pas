unit cdocompressnetcdf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, lclintf;

procedure CompressFiles;

implementation


uses ncmain;

procedure CompressFiles;
Var
  fout, cmd:string;
  k:integer;
begin

frmmain.ProgressBar1.Min:=0;
frmmain.ProgressBar1.Max:=frmmain.cbFiles.count;

  for k:=0 to frmmain.cbFiles.count-1 do begin
    ncName:=frmmain.cbFiles.Items.strings[k]; // selected files, one by one
    fout:=copy(ncname, 1, length(ncname)-3)+'_c.nc';

    cmd:='-z zip copy '+ncPath+ncname+' '+ncpath+fout; //command line

    frmmain.RunScript(4, cmd, nil); // calling CDO

    frmmain.ProgressBar1.Position:=k+1;
  end;
OpenDocument(ncpath);
end;

end.

