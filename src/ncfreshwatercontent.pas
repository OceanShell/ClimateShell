unit ncfreshwatercontent;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  ExtCtrls, IniFiles, Math;

type

  { Tfrmfreshwatercontent }

  Tfrmfreshwatercontent = class(TForm)
    btnCalculate: TButton;
    cbVariableS: TComboBox;
    seSRef: TFloatSpinEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    seTopLimit: TFloatSpinEdit;
    seBotLimit: TFloatSpinEdit;

    procedure FormShow(Sender: TObject);
    procedure btnCalculateClick(Sender: TObject);

  private
    procedure GetFWC(fname:string);
  public

  end;

var
  frmfreshwatercontent: Tfrmfreshwatercontent;
  uPath: string;

implementation

{$R *.lfm}

uses ncmain, declarations_netcdf, bathymetry;

{ Tfrmfreshwatercontent }

procedure Tfrmfreshwatercontent.FormShow(Sender: TObject);
begin
  cbVariableS.Items  := frmmain.cbVariables.items;

  uPath:=GlobalUnloadPath+'FWC'+PathDelim;
  if not DirectoryExists(uPath) then CreateDir(uPath);
end;



procedure Tfrmfreshwatercontent.btnCalculateClick(Sender: TObject);
Var
  k: integer;
begin
 btnCalculate.Enabled:=false;
   frmmain.ProgressBar1.Position:=0;
   frmmain.ProgressBar1.Max:=frmmain.cbFiles.count;
    for k:=0 to frmmain.cbFiles.count-1 do begin
      ncName:=frmmain.cbFiles.Items.strings[k];
      Application.ProcessMessages;

      GetFWC(ncname); // else break;
     frmmain.ProgressBar1.Position:=k+1;
     Application.ProcessMessages;
    end;

   if MessageDlg(SDone, mtInformation, [mbOk], 0)=mrOk then begin
     frmmain.cbFiles.ItemIndex:=0;
     frmmain.cbFiles.OnClick(self);
    Close;
   end;
end;



Procedure Tfrmfreshwatercontent.GetFWC(fname:string);
 Var
   ncid, varidpS, varidpFWC, varnattsp:integer;
   cnt_tot: integer;
   attname: array of pAnsiChar;

   start: PArraySize_t;
   fs:array of smallint;
   f_fwc:array of single;

   varndimsp: integer;
   vardimidsp:array of integer;

   k, a:integer;
   zz_i, lt_i, ln_i, min_lev_ind, max_lev_ind: integer;

   scaleS, offsetS, missingS: array [0..0] of single;

   Gebco, val0s, val1s:real;
   dif1, sref, SMean, FWC, val1s_old, lev_old:real;
   x, y: real;

   coordinates, long_name, standard_name, units, unit_long: string;
   short_name, cell_methods, alg_name, history:string;
   fillvalue, scale_factor, add_offset: array of single;
begin

 Dif1:=seBotLimit.Value-seTopLimit.Value;
 SRef:=seSRef.Value;


  for zz_i:=0 to high(ncLev_arr) do begin //Levels
   if ncLev_arr[zz_i]>=seTopLimit.Value then begin
    min_lev_ind:=zz_i;
    break;
   end;
  end;
  for zz_i:=0 to high(ncLev_arr) do begin //Levels
   if ncLev_arr[zz_i]>seBotLimit.Value then begin
    max_lev_ind:=zz_i-1; // one level before the limit
    break;
   end;
  end;

  try

    nc_open(pansichar(AnsiString(ncpath+fname)), NC_WRITE, ncid); // only for reading
    nc_inq_varid (ncid, pChar(cbVariableS.Text), varidpS);


    (* Читаем коэффициенты из файла *)
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

    SetLength(f_fwc, 0);
    SetLength(f_fwc, (high(ncLat_arr)+1)*(high(ncLon_arr)+1));

    start:=GetMemory(SizeOf(TArraySize_t)*4); // get memory for start pointer

 //  showmessage(floattostr(high(ncLat_arr)*high(ncLon_arr)));
  //    AssignFile(dat, uPath+'FWC_log.txt'); rewrite(dat);

     cnt_tot:=0;
     start^[0]:=0;
      for lt_i:=0 to high(ncLat_arr) do begin //Latitude
       start^[2]:=lt_i;
       for ln_i:=0 to high(ncLon_arr) do begin  //Longitude
        start^[3]:=ln_i;

       // Gebco:=-GetBathymetry(nclon_arr[ln_i], nclat_arr[lt_i]);


    {   writeln(dat, Floattostr(ncLat_arr[lt_i]),'   ',
                       Floattostr(ncLon_arr[ln_i])); //,'   ',
                       //Floattostr(ncLev_arr[high(ncLev_arr)]),'   ',
                      // Floattostr(Gebco)); }

          start^[1]:=max_lev_ind;
           SetLength(fs, 1);
            nc_get_var1_short(ncid, varidpS, start^, fs);
           Val0s:=fs[0];

       (* only if profile exceed bottom limit *)
        if Val0s<>missingS[0] then begin

         k:=0;
         for zz_i:=min_lev_ind to max_lev_ind do begin //Levels
           start^[1]:=zz_i;
           SetLength(fs, 1);
            nc_get_var1_short(ncid, varidpS, start^, fs);
           Val0s:=fs[0];

           if (Val0s<>missingS[0]) and (Val0s<>-9999) then begin
            val1s:=scaleS[0]*val0s+offsetS[0];



           if (k>0) then begin

                 //  SMean:=SMean+((val1s+val1s_old)/2)*((ncLev_arr[zz_i]-lev_old)/Dif1);

                  (*Carmack, E., F. McLaughlin, M. Yamamoto‐Kawai, M. Itoh,
                   K. Shimada, R. Krishfield, and A. Proshutinsky (2008),
                   Freshwater storage in the Northern Ocean and the special
                   role of the Beaufort Gyre, in Arctic‐Subarctic Ocean Fluxes:
                   Defining the Role of the Northern Seas in Climate,
                   edited by R. R. Dickson et al., pp. 145–169, Springer,
                   New York.*)

                   FWC:=FWC+((sref-val1s)/sref)*(ncLev_arr[zz_i]-lev_old); //Carmack, 2008

                //   writeln(dat, floattostr(val1s),'   ',floattostr(ncLev_arr[zz_i]),'    ',floattostr(lev_old),'   ',floattostr(FWC));

                   val1s_old:=val1s;
                   lev_old:=ncLev_arr[zz_i];
                   inc(k);
                  end;

                  if k=0 then begin
                   FWC:=0;
                   val1s_old:=val1s;
                   lev_old:=ncLev_arr[zz_i];
                   inc(k);
                  end;


                  if zz_i=max_lev_ind then begin
                    f_fwc[cnt_tot]:=FWC;
                  //  writeln(dat, floattostr(f_fwc[cnt_tot]));
                  //  writeln(dat, '===================');
                  end;

              end; // sal<>-9999
             end;// level limit
            // if (ncLev_arr[zz_i]>=seBotLimit.Value) or (zz_i=high(ncLev_arr)) then begin

            //   break;
            // end;
             //end;
            end else begin
             f_fwc[cnt_tot]:=missingS[0];
             //writeln(dat, floattostr(f_fwc[cnt_tot]));
            // writeln(dat, '===================');
            end;
           inc(cnt_tot);
         //  if cnt_tot>2 then exit;
        end; //Lon
       end; //Lat
      // if FWC=-9999 then f_fwc[cnt_tot]:=missingS[0];
     // closefile(dat);
  //   showmessage('here'+'   '+floattostr(f_fwc[cnt_tot-1]));

//   showmessage(inttostr(cnt_tot)+'  '+floattostr(f_fwc[cnt_tot-1]));

 {   AssignFile(dat, uPath+'FWC.txt'); rewrite(dat);
    cnt_tot:=0;
      for lt_i:=0 to high(ncLat_arr) do begin //Latitude
       for ln_i:=0 to high(ncLon_arr) do begin  //Longitude
         writeln(dat,  ncLat_arr[lt_i]:9:5, ncLon_arr[ln_i]:11:5, f_fwc[cnt_tot]:13:5);
            //  showmessage(floattostr(FWC));
       inc(cnt_tot);
       end;
      end;
    CloseFile(dat);   }

  //  showmessage('done');

  SetLength(vardimidsp, 3);
  vardimidsp[0]:=0;
  vardimidsp[1]:=2;
  vardimidsp[2]:=1;

  short_name    := 'fwc_'+FloattoStr(SRef)+'_'+seTopLimit.Text+'_'+seBotLimit.Text;
  long_name     := 'Fresh water content';
  standard_name := 'fresh_water_content';
  units         := 'm';
  unit_long     := 'Meters' ;
  cell_methods  := 'area: mean' ;
  history       := 'Algorithm: Carmack et al., 2008';

  setlength(fillvalue, 1);
  fillvalue[0]:=missingS[0];

  setlength(add_offset, 1);
  add_offset[0]:=0;

  setlength(scale_factor, 1);
  scale_factor[0]:=1;


  nc_redef(ncid);
  nc_def_var(ncid, pChar(short_name), NC_FLOAT, 3, vardimidsp, varidpFWC);
    nc_put_att_text  (ncid, varidpFWC, pChar('long_name'),       length(long_name),     pansichar(AnsiString(long_name)));
    nc_put_att_text  (ncid, varidpFWC, pChar('standard_name'),   length(standard_name), pansichar(AnsiString(standard_name)));
    nc_put_att_text  (ncid, varidpFWC, pChar('units'),           length(units),         pansichar(AnsiString(units)));
    nc_put_att_text  (ncid, varidpFWC, pChar('unit_long'),       length(unit_long),     pansichar(AnsiString(unit_long)));
    nc_put_att_float (ncid, varidpFWC, pChar('_FillValue'),      NC_FLOAT, 1, fillvalue);
    nc_put_att_float (ncid, varidpFWC, pChar('missing_value'),   NC_FLOAT, 1, fillvalue);
    nc_put_att_float (ncid, varidpFWC, pChar('add_offset'),      NC_FLOAT, 1, add_offset);
    nc_put_att_float (ncid, varidpFWC, pChar('scale_factor'),    NC_FLOAT, 1, scale_factor);
    nc_put_att_text  (ncid, varidpFWC, pChar('cell_methods'),    length(cell_methods),  pansichar(AnsiString(cell_methods)));
    nc_put_att_text  (ncid, varidpFWC, pChar('history'),         length(history),       pansichar(AnsiString(history)));
  nc_enddef(ncid);  // change to data mode

 // showmessage('1');
  nc_put_var_float(ncid, varidpFWC, f_fwc);
//  showmessage('2');


   finally
     FreeMemory(start);
     fs:=nil;
     f_fwc:=nil;
     nc_close(ncid);  // Close file
   end;

 frmmain.cbFiles.OnClick(self);
end;


end.

