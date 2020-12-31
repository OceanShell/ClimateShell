unit ncheatcontent;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  Buttons, LCLIntf, FileUtil, DateUtils;

type

  { Tfrmheatcontent }

  Tfrmheatcontent = class(TForm)
    btnCalculate: TButton;
    btnOpenFolder: TBitBtn;
    cbSeaBorders: TComboBox;
    cbVariableT: TComboBox;
    cbVariableS: TComboBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    Memo1: TMemo;
    chkLastLevel: TRadioButton;
    chkBottom: TRadioButton;
    seBotLimit: TFloatSpinEdit;
    seTopLimit: TFloatSpinEdit;
    seTRef: TFloatSpinEdit;

    procedure btnCalculateClick(Sender: TObject);
    procedure btnOpenFolderClick(Sender: TObject);
    procedure FormShow(Sender: TObject);

  private
    procedure GetHC(fname:string);

  public

  end;

var
  frmheatcontent: Tfrmheatcontent;
  upath: string;
  hc_dat: text;

implementation

{$R *.lfm}

uses ncmain, declarations_netcdf, GibbsSeaWater, arbytraryregion,
     bathymetry;

{ Tfrmheatcontent }


procedure Tfrmheatcontent.FormShow(Sender: TObject);
var
  fdb:TSearchRec;
begin
  cbVariableT.Items  := frmmain.cbVariables.items;
  cbVariableS.Items  := frmmain.cbVariables.items;

  uPath:=GlobalUnloadPath+'HC'+PathDelim;
  if not DirectoryExists(uPath) then CreateDir(uPath);

  (* list of arbitraty regions *)
   fdb.Name:='';
   cbSeaBorders.Clear;
     FindFirst(GlobalSupportPath+'sea_borders'+PathDelim+'*.bln',faAnyFile, fdb);
     if fdb.Name<>'' then begin
      cbSeaBorders.Items.Add(ExtractFileNameWithoutExt(fdb.Name));
       while findnext(fdb)=0 do cbSeaBorders.Items.Add(ExtractFileNameWithoutExt(fdb.Name));
     end;
    FindClose(fdb);
end;


procedure Tfrmheatcontent.btnCalculateClick(Sender: TObject);
Var
  k: integer;
begin

 if (cbVariableT.ItemIndex=-1) or (cbVariableS.ItemIndex=-1) then exit;
 if not GetArbirtaryRegion(cbSeaBorders.Text) then exit;

  //  showmessage(floattostr(high(ncLat_arr)*high(ncLon_arr)));
 AssignFile(hc_dat, uPath+'HC.txt'); rewrite(hc_dat);

 btnCalculate.Enabled:=false;
   frmmain.ProgressBar1.Position:=0;
   frmmain.ProgressBar1.Max:=frmmain.cbFiles.count;
    for k:=0 to frmmain.cbFiles.count-1 do begin
      frmmain.cbFiles.ItemIndex:=k;
      frmmain.cbFiles.OnClick(self);

      GetHC(ncname); // else break;
     frmmain.ProgressBar1.Position:=k+1;
     Application.ProcessMessages;
    end;

   CloseFile(hc_dat);

   if MessageDlg(SDone, mtInformation, [mbOk], 0)=mrOk then exit;
end;


Procedure Tfrmheatcontent.GetHC(fname:string);
 Var
   ncid, varidpT, varidpS, varidpHC, varnattsp:integer;
   cnt_tot: integer;
   attname: array of pAnsiChar;

   start: PArraySize_t;
   ft:array of smallint;
   fs:array of smallint;

   f_hc:array of single;

   varndimsp: integer;
   vardimidsp:array of integer;

   k, c:integer;
   zz_i, lt_i, ln_i, min_lev_ind, max_lev_ind: integer;


  val0t, val0s, TLev, SLev:variant;
  val1t, val1s, val1t_old, val1s_old:real;

  scaleT, offsetT, missingT: array [0..0] of single;
  scaleS, offsetS, missingS: array [0..0] of single;


  SA, dens, p:double;

  Cp, CT, A, CT_lev: real;

  CT_arr, Lev_arr:array of double;

  HC: double;

  x_step, y_step: double;


   Gebco, tref:real;
   dif1, sref, SMean, lev_old:real;
   x, y, dx, dy: real;

   coordinates, long_name, standard_name, units, unit_long: string;
   short_name, cell_methods, alg_name, history:string;
   fillvalue, scale_factor, add_offset: array of single;

   yy, mn, dd, hh, mm, ss, ms:word;
begin

 Dif1:=seBotLimit.Value-seTopLimit.Value;


 (* The recommended value for the referencetemperature, when studying heat
    budgets for the ArcticOcean, is Tref=−0.1 °C (Simonsen and Haugan, 1996). *)

    TRef:=seTRef.Value;

    x_step:=abs(ncLon_arr[0]-ncLon_arr[1]);
    y_step:=abs(ncLat_arr[0]-ncLat_arr[1]);


  { looking for the first and the last indices }
  for zz_i:=0 to high(ncLev_arr) do begin //Levels
   if ncLev_arr[zz_i]>=seTopLimit.Value then begin
    min_lev_ind:=zz_i; // first level
    break;
   end;
  end;
  for zz_i:=0 to high(ncLev_arr) do begin //Levels
   if ncLev_arr[zz_i]>seBotLimit.Value then begin
    max_lev_ind:=zz_i; // last level (deeper than the limit)
    break;
   end;
  end;


  try

    nc_open(pansichar(AnsiString(ncpath+fname)), NC_WRITE, ncid); // only for reading


    nc_inq_varid (ncid, pChar(cbVariableT.Text), varidpT);
    nc_inq_varid (ncid, pChar(cbVariableS.Text), varidpS);


    (* Читаем коэффициенты из файла *)
      scaleT[0]:=1;
      offsetT[0]:=0;
      missingT[0]:=-9999;
      nc_inq_varnatts (ncid, varidpT, varnattsp); // count of attributes for variable
      setlength(attname, NC_MAX_NAME); // задаем длину названия аттрибута
       for c:=0 to varnattsp-1 do begin
         nc_inq_attname(ncid, varidpT, c, attname); // имя аттрибута
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
        for c:=0 to varnattsp-1 do begin
          nc_inq_attname(ncid, varidpS, c, attname); // имя аттрибута
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

    SetLength(f_hc, 0);
    SetLength(f_hc, (high(ncLat_arr)+1)*(high(ncLon_arr)+1));

    start:=GetMemory(SizeOf(TArraySize_t)*4); // get memory for start pointer

    DecodeDateTime(StrToDateTime(frmmain.cbDates.Items.Strings[0]), yy, mn, dd, hh, mm, ss, ms);

     HC:=0;
     cnt_tot:=0;
     start^[0]:=0;
      for lt_i:=0 to high(ncLat_arr) do begin //Latitude
       start^[2]:=lt_i;

             (*
             LM Bugayevskiy and JP Snyder, Map Projections--A Reference Manual.
             Taylor & Francis, 1995. (Appendix 2 and Appendix 4)

             JP Snyder, Map Projections--A Working Manual. USGS Professional
             Paper 1395, 1987. (Chapter 3)
             *)

             dx :=x_step*
                  111132.92-
                  559.82*cos(2*Pi*ncLat_arr[lt_i]/180)+
                  1.175 *cos(4*Pi*ncLat_arr[lt_i]/180)-
                  0.0023*cos(6*Pi*ncLat_arr[lt_i]/180);


             dy :=y_step*
                  111412.84*cos(Pi*ncLat_arr[lt_i]/180)-
                  93.5     *cos(3*Pi*ncLat_arr[lt_i]/180)+
                  0.118    *cos(5*Pi*ncLat_arr[lt_i]/180);

       for ln_i:=0 to high(ncLon_arr) do begin  //Longitude
        start^[3]:=ln_i;

        // if the node is within the specified area
        if Odd(Point_Status(ncLon_arr[ln_i],ncLat_arr[lt_i]))=true then begin
          Gebco:=-GetBathymetry(ncLon_arr[ln_i],ncLat_arr[lt_i]);

          if  Gebco>0 then begin

           CT_arr:=nil;
           Lev_arr:=nil;
           if nclev_arr[0]>seTopLimit.Value then c:=1 else c:=0; // in case of extrapolation
             SetLength(CT_arr,  high(ncLev_arr)+c);
             SetLength(Lev_arr, high(ncLev_arr)+c);

          k:=0;
          for zz_i:=0 to high(ncLev_arr) do begin //Levels
           start^[1]:=zz_i;

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
              SA  := gsw_SA_from_SP(val1s, p, nclon_arr[ln_i], nclat_arr[lt_i]);
              dens:= gsw_rho_t_exact(SA, val1t, p);  // kg/m3
              Cp  := gsw_cp_t_exact(SA, val1t, p);
              CT  := gsw_ct_from_pt(SA, val1t); //Conservative temperature from porential temp

             // showmessage('all good');

             if k>0 then begin

            // showmessage('k>0');
                CT_arr[k]:=CT;
                CT_lev:=(CT_arr[k]+CT_arr[k-1])/2;
                Lev_arr[k]:=nclev_arr[zz_i];

                (*Timmermans M.-L. Warming of the interior Arctic Ocean
                    linked to sea ice losses at the basin margins /
                    M.-L. Timmermans, J. Toole, R. Krishfield //
                    Science Advances. – 2018. – Vol. 4. – № 8. – P. eaat6773.*)

                 HC :=HC+dx*dy*dens*Cp*(tref-CT_lev)*(Lev_arr[k]-Lev_arr[k-1]);

             end;

             if k=0 then begin
            // showmessage('k=0');
               if nclev_arr[zz_i]>seTopLimit.Value then begin // extrapolation if the first level missing
                 CT_arr[0]:=CT;
                 CT_arr[1]:=CT;

                 Lev_arr[0]:=seTopLimit.Value;
                 Lev_arr[1]:=nclev_arr[zz_i];

                 HC :=HC+dx*dy*dens*Cp*(CT-tRef)*(Lev_arr[1]-Lev_arr[0]); //regarding to tref
               inc(k);
               end;

               if nclev_arr[zz_i]=seTopLimit.Value then begin
                CT_arr[0]:=CT;
                Lev_arr[0]:=nclev_arr[zz_i];
               end;
             end;

           {    writeln(dat, floattostr(lev_arr[k])+'   '+
                            floattostr(dens),'   ',
                            floattostr(Cp),'   ',
                            floattostr(dx)+'   '+
                            floattostr(dy)+'   '+
                            floattostr(HC));  }

             inc(k);
          end; // val<>-9999
         end; //levels
        end; //GEBCO
       end;// Region
      end; //Lon
     end; //Lat

    writeln(hc_dat, inttostr(yy),#9, floattostr(HC/1E22));
    memo1.lines.Add(inttostr(yy)+#9+floattostr(HC/1E22));
    finally
     FreeMemory(start);
     fs:=nil;
     ft:=nil;
     f_hc:=nil;
     nc_close(ncid);  // Close file
   end;


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

{  SetLength(vardimidsp, 3);
  vardimidsp[0]:=0;
  vardimidsp[1]:=2;
  vardimidsp[2]:=1;

  short_name    := 'hc_'+FloattoStr(SRef)+'_'+seTopLimit.Text+'_'+seBotLimit.Text;
  long_name     := 'Heat content';
  standard_name := 'heat_content';
  units         := 'J/m^2';
  unit_long     := 'J/m^2' ;
  cell_methods  := 'area: mean' ;
  history       := 'Algorithm: Timmermans et al., 2018';

  setlength(fillvalue, 1);
  fillvalue[0]:=missingS[0];

  setlength(add_offset, 1);
  add_offset[0]:=0;

  setlength(scale_factor, 1);
  scale_factor[0]:=1;


  nc_redef(ncid);
  nc_def_var(ncid, pChar(short_name), NC_FLOAT, 3, vardimidsp, varidpHC);
    nc_put_att_text  (ncid, varidpHC, pChar('long_name'),       length(long_name),     pansichar(AnsiString(long_name)));
    nc_put_att_text  (ncid, varidpHC, pChar('standard_name'),   length(standard_name), pansichar(AnsiString(standard_name)));
    nc_put_att_text  (ncid, varidpHC, pChar('units'),           length(units),         pansichar(AnsiString(units)));
    nc_put_att_text  (ncid, varidpHC, pChar('unit_long'),       length(unit_long),     pansichar(AnsiString(unit_long)));
    nc_put_att_float (ncid, varidpHC, pChar('_FillValue'),      NC_FLOAT, 1, fillvalue);
    nc_put_att_float (ncid, varidpHC, pChar('missing_value'),   NC_FLOAT, 1, fillvalue);
    nc_put_att_float (ncid, varidpHC, pChar('add_offset'),      NC_FLOAT, 1, add_offset);
    nc_put_att_float (ncid, varidpHC, pChar('scale_factor'),    NC_FLOAT, 1, scale_factor);
    nc_put_att_text  (ncid, varidpHC, pChar('cell_methods'),    length(cell_methods),  pansichar(AnsiString(cell_methods)));
    nc_put_att_text  (ncid, varidpHC, pChar('history'),         length(history),       pansichar(AnsiString(history)));
  nc_enddef(ncid);  // change to data mode

 // showmessage('1');
  nc_put_var_float(ncid, varidpHC, f_hc);
//  showmessage('2');
                      }

// frmmain.cbFiles.OnClick(self);
end;


procedure Tfrmheatcontent.btnOpenFolderClick(Sender: TObject);
begin
  OpenDocument(PChar(uPath));
end;

end.

