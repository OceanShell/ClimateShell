unit ncexportascii;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, CheckLst, Spin, Math;

type

  { Tfrmexport }

  Tfrmexport = class(TForm)
    chkHeader: TCheckBox;
    CheckListBox1: TCheckListBox;
    btnExport: TButton;
    lbCheckAll: TLabel;
    seRound: TSpinEdit;
    chkRounding: TCheckBox;
    chkSingleParam: TCheckBox;

    procedure btnExportClick(Sender: TObject);
    procedure lbCheckAllClick(Sender: TObject);
    procedure FormShow(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmexport: Tfrmexport;
  fout:text;

implementation

{$R *.lfm}

uses ncmain, declarations_netcdf, ncprocedures;

procedure Tfrmexport.FormShow(Sender: TObject);
begin
 CheckListBox1.Items:=frmmain.cbAllVars.Items;
end;


procedure Tfrmexport.lbCheckAllClick(Sender: TObject);
Var
  k:integer;
  lbchecked:boolean;
begin
 if CheckListBox1.Count>0 then begin
  lbchecked:=CheckListBox1.Checked[0];
   for k:=0 to CheckListBox1.Count-1 do CheckListBox1.Checked[k]:=not lbchecked;
 end;
end;


procedure Tfrmexport.btnExportClick(Sender: TObject);
Var
 k_par, i:integer;
 param:string;
 Status, ncid: integer;
 varidp, varndimsp:integer;
 vardimidsp: array of integer;
 vtype:nc_type;
 dlenp, flenp: size_t;

 SingleArray: array of single;
 DoubleArray: array of double;
 IntegArray : array of integer;
 ShortArray : array of smallint;
begin

 if not DirectoryExists(GlobalPath+'unload'+PathDelim+'export'+PathDelim) then
    CreateDir(GlobalPath+'unload'+PathDelim+'export'+PathDelim);

 frmmain.SD.InitialDir:=GlobalPath+'unload'+PathDelim+'export'+PathDelim;
 frmmain.SD.Filter:='*.txt|*.txt';
 frmmain.SD.DefaultExt:='.txt';

 if frmmain.SD.Execute then begin
  btnExport.Enabled:=false;

  AssignFile(fout, frmmain.SD.FileName); Rewrite(fout);

  if chkHeader.checked=true then GetHeader(ncpath+ncname, 2); // header unload

  writeln(fout, 'data:');
  try
   status:=nc_open(pchar(ncpath+ncname), NC_NOWRITE, ncid); // открываем файл
    if status>0 then showmessage(pansichar(nc_strerror(status)));

   for k_par:=0 to checklistbox1.Count-1 do
     if checklistbox1.Checked[k_par]=true then begin  // условие на отмеченный параметр
      param:=checklistbox1.Items.Strings[k_par];


       writeln(fout);
       write(fout, param, ' = ');
       writeln(fout);


       nc_inq_varid(ncid, pansichar(ansistring(param)), varidp); // id параметра
       nc_inq_vartype(ncid, varidp, vtype); // тип параметра
       nc_inq_varndims(ncid, varidp, varndimsp); // количество размерностей

       SetLength(vardimidsp, varndimsp); //number of dimensions
       nc_inq_vardimid (ncid, varidp, vardimidsp); // Dimention ID's

          dlenp:=1;
          for i:=0 to varndimsp-1 do begin
           nc_inq_dimlen(ncid, vardimidsp[i], flenp); //длина
            dlenp:=dlenp*flenp;
          end;


          // NC_FLOAT
          if VarToStr(vtype)='5'  then begin
           setlength(singlearray, 0);
           setlength(singlearray, dlenp);
           nc_get_var_float (ncid, varidp, singlearray);
             for i := 0 to High(singlearray) do begin

               if i=0 then write(fout,      Vartostr(singlearray[i])) else
                           write(fout, ' ', Vartostr(singlearray[i]));
             end;
           singlearray:=nil; // обнуляем массив
          end;


          // NC_DOUBLE
          if VarToStr(vtype)='6' then begin
           setlength(doublearray, 0);
           setlength(doublearray, dlenp);
           nc_get_var_double (ncid, varidp, doublearray);
             for i := 0 to High(doublearray) do begin
                if i=0 then write(fout,      Floattostr(doublearray[i])) else
                            write(fout, ' ', Floattostr(doublearray[i]));
             end;
           doublearray:=nil; // обнуляем массив
          end;


           // NC_INT
          if VarToStr(vtype)='4' then begin
           setlength(integarray, 0);
           setlength(integarray, dlenp);
            nc_get_var_int(ncid, varidp, integarray);
             for i := 0 to High(integarray) do begin
              if i=0 then write(fout, Vartostr(integarray[i])) else write(fout, ' ', Vartostr(integarray[i]));
             end;
           integarray:=nil; // обнуляем массив
          end;


          // NC_SHORT
          if VarToStr(vtype)='3' then begin
           setlength(shortarray, 0);
           setlength(shortarray, dlenp);
            nc_get_var_short(ncid, varidp, shortarray);
             for i := 0 to High(shortarray) do begin
              if i=0 then write(fout, Vartostr(shortarray[i])) else write(fout, ' ', Vartostr(shortarray[i]));
             end;
           shortarray:=nil; // обнуляем массив
          end;

    // if chkSingleParam.Checked=false then begin
      write(fout, ' ');
      writeln(fout);
    // end;
     end; // конец отмеченного параметра

     writeln(fout, '}');
     writeln(fout);

     CloseFile(fout);  // закрываем файл экспорта

     OpenDocument(PChar(ExtractFilePath(frmmain.SD.FileName)));
  finally
   status:=nc_close(ncid);  // закрываем файл netcdf
    if status>0 then showmessage(pansichar(nc_strerror(status)));
  end;
   btnExport.Enabled:=true;
 end;
end;



end.
