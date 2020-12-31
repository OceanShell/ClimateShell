unit nctsdiagram;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  IniFiles, Math, LCLIntf, Spin;

type

  { Tfrmtsdiagram }

  Tfrmtsdiagram = class(TForm)
    btnGetData: TButton;
    btnOpenBLN: TButton;
    btnOpenFolder: TBitBtn;
    btnPlotPython: TButton;
    cbVariableS: TComboBox;
    cbVariableT: TComboBox;
    eSection: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Limits: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    seTmax: TFloatSpinEdit;
    seSmin: TFloatSpinEdit;
    seSmax: TFloatSpinEdit;
    seTmin: TFloatSpinEdit;
    seDens: TSpinEdit;

    procedure btnOpenBLNClick(Sender: TObject);
    procedure btnGetDataClick(Sender: TObject);
    procedure btnOpenFolderClick(Sender: TObject);
    procedure btnPlotPythonClick(Sender: TObject);
    procedure cbVariableTSelect(Sender: TObject);
    procedure FormShow(Sender: TObject);

  private
    procedure GetPythonScript;
  public

  end;

var
  frmtsdiagram: Tfrmtsdiagram;
  nctsdiagrampath: string;

implementation

{$R *.lfm}

uses ncmain, declarations_netcdf, GibbsSeaWater, ncprocedures;

{ Tfrmtsdiagram }

procedure Tfrmtsdiagram.FormShow(Sender: TObject);
Var
  Ini:TIniFile;
begin
  cbVariableT.Items  := frmmain.cbVariables.items;
  cbVariableS.Items  := frmmain.cbVariables.items;

  Ini := TIniFile.Create(IniFileName);
  try
   eSection.Text:=Ini.ReadString('main', 'LastUsedSection', '');
  finally
    ini.Free;
  end;

  nctsdiagrampath:=globalUnloadPath+'tsdiagram'+PathDelim;
    if not DirectoryExists(nctsdiagrampath) then CreateDir(nctsdiagrampath);
end;

procedure Tfrmtsdiagram.cbVariableTSelect(Sender: TObject);
begin
    if (cbVariableT.ItemIndex<>-1) and
       (cbVariableS.ItemIndex<>-1) then btnGetData.Enabled:=true;
end;

procedure Tfrmtsdiagram.btnOpenBLNClick(Sender: TObject);
begin
  frmmain.OD.Filter:='bln|*.bln';
  frmmain.OD.InitialDir:=GlobalSupportPath+'sections'+PathDelim;
   if frmmain.OD.Execute then begin
     eSection.Text:=frmmain.OD.FileName;
     btnGetData.Enabled:=true;
   end;
end;

procedure Tfrmtsdiagram.btnGetDataClick(Sender: TObject);
Var
  Ini: TIniFile;
  fncsecdat, tsout:text;
  fcoord,st: string;
  stnum, k_d, ll, i: integer;

  t_min, t_max, s_min, s_max:real;


  lat_arr, lon_arr: array of real;

    ncid, varidpT, varidpS, varidpD, varnattsp:integer;
    status : integer;
    attname: array of pAnsiChar;

    start: PArraySize_t;
    ft, fs:array of single;
    fd:array of single;

    varndimsp: integer;
    vardimidsp:array of integer;

    DimTot, k, a:integer;
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
begin
 // saving last used section
 Ini := TIniFile.Create(IniFileName);
  try
   Ini.WriteString('main', 'LastUsedSection', eSection.Text);
  finally
    ini.Free;
  end;

if (cbVariableT.ItemIndex=-1) or (cbVariableS.ItemIndex=-1) then
  if MessageDlg(SSelectParameters, mtWarning, [mbOk], 0)=mrOk then exit;

// assign coord file, checking the size
if trim(eSection.Text)='' then
  if MessageDlg(SSelectSection, mtWarning, [mbOk], 0)=mrOk then exit;

fcoord:=eSection.Text; //section coordinates

stnum:=0;
AssignFile(fncsecdat, fcoord); reset(fncsecdat);
readln(fncsecdat, st);
stnum:=StrToInt(Copy(st, 1, Pos(',', st)-1))-1;

setlength(lat_arr,  stnum);  // minus title sting
setlength(lon_arr,  stnum);

k:=-1;
repeat
  inc(k);

  // reading coordinates
  readln(fncsecdat, st);

  lon_arr[k]:=StrToFloat(Copy(st, 1, Pos(',', st)-1));
  lat_arr[k]:=StrToFloat(Copy(st, Pos(',', st)+1, length(st)));
until eof(fncsecdat);
Closefile(fncsecdat);


     nc_open(pansichar(AnsiString(ncpath+ncname)), NC_WRITE, ncid); // only for reading


     nc_inq_varid (ncid, pChar(cbVariableT.Text), varidpT);
     nc_inq_varid (ncid, pChar(cbVariableS.Text), varidpS);

     nc_inq_varndims (ncid, varidpT, varndimsp); //dimensions for variable

     SetLength(vardimidsp, varndimsp); //number of dimensions
     nc_inq_vardimid (ncid, varidpT, vardimidsp); // Dimention ID's

     DimTot:=1;
     for i:=0 to varndimsp-1 do begin  // Loop for variable dimensions
       nc_inq_dimlen(ncid, vardimidsp[i], lenp);
       DimTot:=DimTot*lenp;
     end;

     SetLength(fd, DimTot);

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

   AssignFile(tsout, nctsdiagrampath+'data_i.csv'); rewrite(tsout);
   t_min:=999; t_max:=-999;
   s_min:=999; s_max:=-999;

   start:=GetMemory(SizeOf(TArraySize_t)*4); // get memory for start pointer

   start^[0]:=0; //time
   for k_d:=0 to stnum-1 do begin

  {   showmessage(floattostr(Lat_arr[k_d])+'   '+
                 inttostr(GetLatIndex(Lat_arr[k_d]))+'   '+
                 floattostr(Lon_arr[k_d])+'   '+
                 inttostr(GetLonIndex(Lon_arr[k_d])));  }

    start^[2]:=GetLatIndex(Lat_arr[k_d]);
    start^[3]:=GetLonIndex(Lon_arr[k_d]);

  //  showmessage('here');

     for ll:=0 to high(ncLev_arr) do begin
      start^[1]:=ll;  //level

      SetLength(ft, 1);
      SetLength(fs, 1);
        nc_get_var1_float(ncid, varidpT, start^, ft);
        nc_get_var1_float(ncid, varidpS, start^, fs);
      Val0t:=ft[0];
      Val0s:=fs[0];

      if (val0t<>missingT[0]) and (val0T<>-9999) and
         (val0s<>missingT[0]) and (val0s<>-9999) then begin
             val1t:=scaleT[0]*val0t+offsetT[0];
             val1s:=scaleS[0]*val0s+offsetS[0];

              t_min:=min(t_min, val1t);
              t_max:=max(t_max, val1t);
              s_min:=min(s_min, val1s);
              s_max:=max(s_max, val1s);

              p:=10.1325;
              SA  := gsw_SA_from_SP(val1s, p, nclon_arr[k_d], nclat_arr[k_d]);
              dens:= gsw_rho_t_exact(val1s, val1t, p)-1000;

              writeln(tsout, Floattostr(val1t), ',',
                             Floattostr(val1s), ',',
                             Floattostr(dens),',',
                             Floattostr(ncLev_arr[ll]));
         end;
        end; //Lev
    end; // Time
    FreeMemory(start);
    Closefile(tsout);

    seTmin.Value:=t_min;
    seTmax.Value:=t_max;
    seSmin.Value:=s_min;
    seSmax.Value:=s_max;

 btnPlotPython.Enabled:=true;
end;

procedure Tfrmtsdiagram.btnOpenFolderClick(Sender: TObject);
begin
  OpenDocument(PChar(nctsdiagrampath));
end;

procedure Tfrmtsdiagram.btnPlotPythonClick(Sender: TObject);
Var
  tsin, tsout:text;
  i, j, c, k: integer;
  si, ti, x_step, y_step: real;
  t, s, d, t_min, t_max, s_min, s_max, p, dens:real;
  st, buf_str:string;
begin

 AssignFile(tsin, nctsdiagrampath+'data_i.csv'); reset(tsin);
 AssignFile(tsout, nctsdiagrampath+'data.csv'); rewrite(tsout);
 repeat
   readln(tsin, st);
   c:=0;
    for k:=1 to 2 do begin
     buf_str:='';
     repeat
      inc(c);
        if st[c]<>',' then buf_str:=buf_str+st[c];
     until st[c]=',';
     if k=1 then t:=StrToFloat(buf_str);
     if k=2 then s:=StrToFloat(buf_str);
    end;

    if (t>=seTmin.Value) and (t<=seTmax.Value) and
       (s>=seSmin.Value) and (s<=seSmax.Value) then
         writeln(tsout, Floattostr(t), ',',
                  Floattostr(s), ',',
                  Floattostr(d));
 until eof(tsin);
 Closefile(tsout);
 Closefile(tsin);

// output file for density
 AssignFile(tsout, nctsdiagrampath+'density.csv'); rewrite(tsout);

 //Figure out boudaries (mins and maxs)
 s_min:=seSmin.Value-0.1;
 s_max:=seSmax.Value+0.1;
 t_min:=seTmin.Value-0.1;
 t_max:=seTmax.Value+0.1;

 // step in x and y
 x_step := abs(s_max-s_min)/10;
 y_step := abs(t_max-t_min)/10;

for j:=0 to 10 do begin
 if j=0 then ti:=t_min else ti:= ti+y_step;

 for i:=0 to 10 do begin
  if i=0 then si:=s_min else si:= si+x_step;

   p:=10.1325;
   dens:= gsw_rho_t_exact(si, ti, p)-1000;

   writeln(tsout, Floattostr(ti), ',',
                  Floattostr(si), ',',
                  Floattostr(dens));
 end;
end;
Closefile(tsout);

  GetPythonScript;
  frmmain.RunScript(1, nctsdiagrampath+'tsdiagram.py', nil);
end;


Procedure Tfrmtsdiagram.GetPythonScript;
Var
  tsout:text;
  conv_path, file_name: string;
begin
AssignFile(tsout, nctsdiagrampath+'tsdiagram.py'); rewrite(tsout);

conv_path:=StringReplace(nctsdiagrampath, '\', '/', [rfReplaceAll]);
file_name:=copy(ncname,1, length(ncname)-3)+'_tsdiagram.png';

writeln(tsout, 'import os');
writeln(tsout, 'import numpy as np');
writeln(tsout, 'import matplotlib.pyplot as plt');
writeln(tsout, '');
writeln(tsout, '# Extract data from file *********************************');
writeln(tsout, 'data_path = "'+conv_path+'"');
writeln(tsout, 'file_name = "'+conv_path+file_name+'"');
writeln(tsout, 'f = open(os.path.join(data_path,"data.csv"), "r")');
writeln(tsout, 'data = np.genfromtxt(f, delimiter=",")');
writeln(tsout, '');
writeln(tsout, '# Create arrays for real temperature and salinity');
writeln(tsout, 'temp = data[1:, 0]');
writeln(tsout, 'salt = data[1:, 1]');
writeln(tsout, 'f.close()');
writeln(tsout, '');
writeln(tsout, 'f = open(os.path.join(data_path,"density.csv"), "r")');
writeln(tsout, 'data_i = np.genfromtxt(f, delimiter=",")');
writeln(tsout, '');
writeln(tsout, 'temp_i = data_i[1:, 0]');
writeln(tsout, 'salt_i = data_i[1:, 1]');
writeln(tsout, 'dens_i = data_i[1:, 2]');
writeln(tsout, 'f.close()');
writeln(tsout, '');
writeln(tsout, '# Plot data ***********************************************');
writeln(tsout, 'fig1 = plt.figure()');
writeln(tsout, 'ax1 = fig1.add_subplot(111)');
writeln(tsout, '');
writeln(tsout, 'CS=ax1.tricontour(salt_i, temp_i, dens_i, '+seDens.Text+', colors="gray", linewidths=1/2)');
writeln(tsout, 'plt.clabel(CS, fontsize=10, colors="black", inline=1, fmt="%1.1f")');
writeln(tsout, '');
writeln(tsout, 'ax1.plot(salt, temp, "or", markersize=1)');
writeln(tsout, '');
writeln(tsout, 'ax1.set_xlabel("Salinity")');
writeln(tsout, 'ax1.set_ylabel("Potential temperature (C)")');
writeln(tsout, 'plt.savefig(os.path.join(data_path,file_name),, bbox_inches="tight")');
writeln(tsout, 'plt.show()');
CloseFile(tsout);

end;

end.

