unit ncxyz2grd;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ncmain;

procedure _XYZ2GRD(filein, fileout:string);

implementation

(* works ONLY with georgaphical coordinates and linear grid *)
procedure _XYZ2GRD(filein, fileout:string);
Var
  fout:text;
begin
   AssignFile(fout, ExtractFilePath(fileout)+'script.py'); rewrite(fout);
    writeln(fout, 'import pandas as pd');
    writeln(fout, 'import numpy as np');
    writeln(fout, '');
    writeln(fout, 'mat = pd.read_table(r"'+filein+'", delim_whitespace=True, usecols=(0,1,4))');
    writeln(fout, 'mat[mat <= -999] = None');
    writeln(fout, 'z_array = mat.pivot("Lat", "Lon", "Value")');
    writeln(fout, '');
    writeln(fout, 'f = open(r"'+fileout+'", "w")');
    writeln(fout, 'f.write("DSAA\n")');
    writeln(fout, 'f.write(str(z_array.shape[1])+" "+str(z_array.shape[0])+ "\n")');
    writeln(fout, 'f.write(str(min(mat["Lon"]))   + " " + str(max(mat["Lon"]))   + "\n")');
    writeln(fout, 'f.write(str(min(mat["Lat"]))   + " " + str(max(mat["Lat"]))   + "\n")');
    writeln(fout, 'f.write(str(np.nanmin(mat["Value"])) + " " + str(np.nanmax(mat["Value"])) + "\n")');
    writeln(fout, 'f.close()');
    writeln(fout, '');
    writeln(fout, 'z_array.to_csv(r"'+fileout+'", header=False, index=False, mode="a",'+
                  'sep=" ", float_format="%.3f", na_rep="1.71041e38")');
   CloseFile(fout);
end;

end.

