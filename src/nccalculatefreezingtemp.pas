unit nccalculatefreezingtemp;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls;

type

  { Tfrmcalculatefreezingtemp }

  Tfrmcalculatefreezingtemp = class(TForm)
    btnCalculate: TButton;
    cbVariableS: TComboBox;
    cbVariableT: TComboBox;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    rgAlgorythm: TRadioGroup;

    procedure btnCalculateClick(Sender: TObject);
    procedure cbVariableTSelect(Sender: TObject);
    procedure FormShow(Sender: TObject);

  private
    procedure CalculateFreezingTemperature(fname: string);
  public

  end;

var
  frmcalculatefreezingtemp: Tfrmcalculatefreezingtemp;

implementation

{$R *.lfm}

{ Tfrmcalculatefreezingtemp }

uses ncmain, declarations_netcdf, GibbsSeaWater, ncprocedures;


procedure Tfrmcalculatefreezingtemp.FormShow(Sender: TObject);
begin
  cbVariableT.Items  := frmmain.cbVariables.items;
  cbVariableS.Items  := frmmain.cbVariables.items;
end;

procedure Tfrmcalculatefreezingtemp.cbVariableTSelect(Sender: TObject);
begin
  if (cbVariableT.ItemIndex<>-1) and
     (cbVariableS.ItemIndex<>-1) then btnCalculate.Enabled:=true;
end;

procedure Tfrmcalculatefreezingtemp.btnCalculateClick(Sender: TObject);
Var
  k:integer;
begin
  btnCalculate.Enabled:=false;
  frmmain.ProgressBar1.Position:=0;
  frmmain.ProgressBar1.Max:=frmmain.cbFiles.count;
   for k:=0 to frmmain.cbFiles.count-1 do begin
     ncName:=frmmain.cbFiles.Items.strings[k];
     Application.ProcessMessages;
    CalculateFreezingTemperature(ncname); // else break;
    frmmain.ProgressBar1.Position:=k+1;
    Application.ProcessMessages;
   end;

  if MessageDlg(SDone, mtInformation, [mbOk], 0)=mrOk then begin
     frmmain.cbFiles.ItemIndex:=0;
     frmmain.cbFiles.OnClick(self);
   Close;
  end;
end;


procedure Tfrmcalculatefreezingtemp.CalculateFreezingTemperature(fname: string);
Var
  ncid, varidpT, varidpS, varidpD, varnattsp:integer;
  status : integer;
  attname: array of pAnsiChar;

  start: PArraySize_t;
  ft, fs:array of smallint;
  fd:array of single;

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
  saturation_fraction, t_freeze: real;
begin
 try
   nc_open(pansichar(AnsiString(ncpath+fname)), NC_WRITE, ncid); // only for reading

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


  start:=GetMemory(SizeOf(TArraySize_t)*4); // get memory for start pointer

    k:=0;
    start^[0]:=0;
    for zz_i:=0 to high(ncLev_arr) do begin //Levels
     start^[1]:=zz_i;
     for lt_i:=0 to high(ncLat_arr) do begin //Latitude
      start^[2]:=lt_i;
      for ln_i:=0 to high(ncLon_arr) do begin  //Longitude
       start^[3]:=ln_i;

           SetLength(ft, 1);
           SetLength(fs, 1);
             nc_get_var1_short(ncid, varidpT, start^, ft);
             nc_get_var1_short(ncid, varidpS, start^, fs);
           Val0t:=ft[0];
           Val0s:=fs[0];

    if (val0t<>missingT[0]) and (val0T<>-9999) and
       (val0s<>missingT[0]) and (val0s<>-9999) then begin
           val1t:=scaleT[0]*val0t+offsetT[0];
           val1s:=scaleS[0]*val0s+offsetS[0];

           p:=10.1325;
           saturation_fraction:=0;
           SA  := gsw_SA_from_SP(val1s, p, nclon_arr[ln_i], nclat_arr[lt_i]);

           if rgAlgorythm.ItemIndex=0 then
             t_freeze:=gsw_t_freezing(SA, p, saturation_fraction);
           if rgAlgorythm.ItemIndex=1 then
             t_freeze:=gsw_t_freezing_poly(SA, p, saturation_fraction);

          fd[k]:=t_freeze;

       end else fd[k]:=missingT[0];
       inc(k);
      end; //Lon
    end; //Lat
  end; // Lev
  FreeMemory(start);

  short_name    := 't_freezing';
  coordinates   := 'time depth latitude longitude' ;
  long_name     := 'freezing temperature';
  standard_name := 'sea_water_freezing_temperature';
  units         := 'degC';
  unit_long     := 'Degrees Centigrade' ;

  alg_name:='TEOS-10';
  history       := 'Algorithm: '+alg_name;

  setlength(fillvalue, 1);
  fillvalue[0]:=-32767;

  setlength(add_offset, 1);
  add_offset[0]:=0;

  setlength(scale_factor, 1);
  scale_factor[0]:=1;

  cell_methods  := 'area: mean' ;

  nc_redef(ncid);
  nc_def_var(ncid, pChar(short_name), NC_FLOAT, varndimsp, vardimidsp, varidpD);
    nc_put_att_text  (ncid, varidpD, pChar('_CoordinateAxes'), length(coordinates),   pansichar(AnsiString(coordinates)));
    nc_put_att_text  (ncid, varidpD, pChar('long_name'),       length(long_name),     pansichar(AnsiString(long_name)));
    nc_put_att_text  (ncid, varidpD, pChar('standard_name'),   length(standard_name), pansichar(AnsiString(standard_name)));
    nc_put_att_text  (ncid, varidpD, pChar('units'),           length(units),         pansichar(AnsiString(units)));
    nc_put_att_text  (ncid, varidpD, pChar('unit_long'),       length(unit_long),     pansichar(AnsiString(unit_long)));
    nc_put_att_float (ncid, varidpD, pChar('_FillValue'),      NC_FLOAT, 1, fillvalue);
    nc_put_att_float (ncid, varidpD, pChar('add_offset'),      NC_FLOAT, 1, add_offset);
    nc_put_att_float (ncid, varidpD, pChar('scale_factor'),    NC_FLOAT, 1, scale_factor);
    nc_put_att_text  (ncid, varidpD, pChar('cell_methods'),    length(cell_methods),  pansichar(AnsiString(cell_methods)));
    nc_put_att_text  (ncid, varidpD, pChar('history'),         length(history),       pansichar(AnsiString(history)));
  nc_enddef(ncid);  // change to data mode

  nc_put_var_float(ncid, varidpD, fd);

 finally
  ft:=nil;
  fs:=nil;
  fd:=nil;
  nc_close(ncid);
 end;
end;



end.

