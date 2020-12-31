unit cdoanomalies;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, lclintf;

procedure GetAnomalies;

implementation

uses ncmain;

procedure GetAnomalies;
Var
  dat: text;
  upath, nname, npath, fout, cmd:string;
  k:integer;
  lst:TStringList;
begin
 // Path to output folder
 upath:=GlobalUnloadPath+'anomalies'+PathDelim;
   if not DirectoryExists(upath) then CreateDir(upath);

 AssignFile(dat, upath+'cdo_script.bat'); rewrite(dat);

 // open dialog for Norma
 frmmain.OD.Filter:='NetCDF|*.nc';
 frmmain.OD.Title:=SOpenNorma;

 if frmmain.OD.Execute then begin
   nname:=ExtractFileName(frmmain.OD.FileName); // file name of norma
   npath:=ExtractFilePath(frmmain.OD.FileName); // path to norma's folder

    lst:=TStringList.Create; // creating a list for output files
     frmmain.ProgressBar1.Min:=0;
     frmmain.ProgressBar1.Max:=frmmain.cbFiles.count;

     for k:=0 to frmmain.cbFiles.count-1 do begin
       ncName:=frmmain.cbFiles.Items.strings[k]; // selected files, one by one
       if (ncpath+ncname)<>(npath+nname) then begin // if file<>norma
        fout:=ncname+'-'+nname;
        fout:=StringReplace(fout, '.nc', '', [rfReplaceAll, rfIgnoreCase])+'.nc';
          if fileExists(upath+fout) then DeleteFile(upath+fout); //removing old file;

          cmd:='-b F64 sub '+ncPath+ncname+' '+npath+nname+' '+upath+fout; //command line

          writeln(dat, 'cdo '+cmd);
          flush(dat);

        frmmain.RunScript(4, cmd, nil); // calling CDO
        lst.Add(fout); // adding output file name into list

        frmmain.ProgressBar1.Position:=k+1;
       end;
     end;
    CloseFile(Dat);

    if (lst.Count>0) then // if list isn't empty
       with frmmain.cbFiles do begin
        Clear;
         Items:=lst;
         ItemIndex:=0;
         ncname:=Items.Strings[0];
         ncpath:=upath;
       end;
    lst.Free;
   OpenDocument(upath);
  end;
end;

end.

