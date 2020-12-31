unit ncnettransport;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Spin, Buttons, Variants;

type

  { Tfrmnettransport }

  Tfrmnettransport = class(TForm)
    btnOpenFolder: TBitBtn;
    btnYearlyAveraging: TButton;
    btncalculate: TButton;
    lbCoord1: TLabel;
    lbCoord2: TLabel;
    seCoordFixed: TFloatSpinEdit;
    seCoordFrom: TFloatSpinEdit;
    seCoordFrom1: TFloatSpinEdit;
    seCoordTo: TFloatSpinEdit;
    GroupBox1: TGroupBox;
    gbCoords: TGroupBox;
    Label2: TLabel;
    rgNorthward: TRadioButton;
    rgEastward: TRadioButton;

    procedure btnOpenFolderClick(Sender: TObject);
    procedure btnYearlyAveragingClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btncalculateClick(Sender: TObject);
    procedure rgNorthwardChange(Sender: TObject);

  private
    procedure Average_years(fname:string);
  public

  end;

var
  frmnettransport: Tfrmnettransport;
  NetTransportPath: string;

implementation

{$R *.lfm}

{ Tfrmnettransport }

uses ncmain, declarations_netcdf;

procedure Tfrmnettransport.FormShow(Sender: TObject);
begin
  NetTransportPath:=GlobalUnloadPath+'nettransport'+PathDelim;
    if not DirectoryExists(NetTransportPath) then CreateDir(NetTransportPath);

  rgNorthward.OnChange(self);
end;

procedure Tfrmnettransport.rgNorthwardChange(Sender: TObject);
begin
  if rgNorthward.Checked then begin
    lbCoord1.Caption:=SLongitude;
    lbCoord2.Caption:=SLatitude;
  end;
  if rgEastward.Checked  then begin
    lbCoord1.Caption:=SLatitude;
    lbCoord2.Caption:=SLongitude;
  end;
end;

procedure Tfrmnettransport.btncalculateClick(Sender: TObject);
Var
 // Ini:TIniFile;
  out_f1, out_f2, out_f3, out_f4, out_f5, out_f6:text;
  ll, pp, k, coord0, coord1, ind_var:integer;
  status, ncid, varidp, varidpt, ndimsp:integer;
  start: PArraySize_t;

 // timidp, lonidp, latidp, depidp: integer;

  vtype: nc_type;

  sp:array of smallint;
  td:array of double;

  val0, valt:variant;
  step, val1, dl, dz, r: real;
  net_tr, net_tr_t, net_tr25, net_tr100, net_tr_N, net_tr_S:real;
  scale, scale_t, offset, offset_t, missing, missing_t: array [0..0] of single;

  par, yy, mn, dd: string;
begin
 btncalculate.Enabled:=false;

 AssignFile(out_f1, NetTransportPath+'nettransport.dat'); Rewrite(out_f1);
 writeln(out_f1, 'yy':5, 'mn':3, 'dd':3, 'Net_tr[Sv]':10);

 AssignFile(out_f2, NetTransportPath+'nettransport_t0.dat'); Rewrite(out_f2);
 writeln(out_f2, 'yy':5, 'mn':3, 'dd':3, 'Net_tr[Sv]':10);

 AssignFile(out_f3, NetTransportPath+'nettransport_25.dat'); Rewrite(out_f3);
 writeln(out_f3, 'yy':5, 'mn':3, 'dd':3, 'Net_tr[Sv]':10);

 AssignFile(out_f4, NetTransportPath+'nettransport_100.dat'); Rewrite(out_f4);
 writeln(out_f4, 'yy':5, 'mn':3, 'dd':3, 'Net_tr[Sv]':10);

 AssignFile(out_f5, NetTransportPath+'nettransport_N.dat'); Rewrite(out_f5);
 writeln(out_f5, 'yy':5, 'mn':3, 'dd':3, 'Net_tr[Sv]':10);

 AssignFile(out_f6, NetTransportPath+'nettransport_S.dat'); Rewrite(out_f6);
 writeln(out_f6, 'yy':5, 'mn':3, 'dd':3, 'Net_tr[Sv]':10);

 if rgNorthward.Checked then par:='vo';
 if rgEastward.Checked  then par:='uo';

 frmmain.ProgressBar1.Position:=0;
 frmmain.ProgressBar1.Max:=frmmain.cbFiles.count;
 for k:=0 to frmmain.cbFiles.count-1 do begin
  ncName:=frmmain.cbFiles.Items.strings[k];

  yy:=Copy(ncName, 1, 4);
  mn:=Copy(ncName, 6, 2);
  dd:=Copy(ncName, 9, 2);

  try
    nc_open(pchar(ncpath+ncname), NC_NOWRITE, ncid);
    nc_inq_varid (ncid, pChar(par), varidp);
    nc_inq_varid (ncid, pChar('thetao'), varidpt); // for temperature
    nc_inq_varndims (ncid, varidp, ndimsp);  // dimentions quantity
    nc_inq_vartype  (ncid, varidp, vtype);   // variable type


 {   timidp:=0;
    lonidp:=1;
    latidp:=2;
    depidp:=3;   }

 {   nc_inq_varid (ncid, pChar('time'), varidtt); // for time
    nc_inq_dimlen (ncid, timeDid, lenp);

                setlength(ncTime_arr, lenp);
                nc_get_var_double (ncid, timeVid, ncTime_arr);
                nc_inq_attlen (ncid, timeVid, pAnsiChar('units'), attlenp);
                setlength(atttext, attlenp);
                nc_get_att_text (ncid, timeVid, pAnsiChar('units'), atttext);
              end;

              GetDates(trim(pAnsiChar(atttext)));  // convert time to real dates!!!!!  }


     (* Читаем коэффициенты из файла *)
    nc_get_att_float(ncid, varidp, pansichar(pansichar(AnsiString('add_offset'))),    offset);
    nc_get_att_float(ncid, varidp, pansichar(pansichar(AnsiString('scale_factor'))),  scale);
    nc_get_att_float(ncid, varidp, pansichar(pansichar(AnsiString('_FillValue'))),    missing);

    nc_get_att_float(ncid, varidpt, pansichar(pansichar(AnsiString('add_offset'))),    offset_t);
    nc_get_att_float(ncid, varidpt, pansichar(pansichar(AnsiString('scale_factor'))),  scale_t);
    nc_get_att_float(ncid, varidpt, pansichar(pansichar(AnsiString('_FillValue'))),    missing_t);

    (*конец чтения коэффициентов *)

    net_tr:=0;
    net_tr_t:=0;
    net_tr25:=0;
    net_tr100:=0;
    net_tr_N:=0;
    net_tr_s:=0;


    start:=GetMemory(SizeOf(TArraySize_t)*4); // get memory for start pointer
    start^[0]:=0; //time

      // Longitudes
      if rgNorthward.Checked then begin;
        step:=abs(nclon_arr[0]-nclon_arr[1]);
      //  showmessage(floattostr(step)+'   '+floattostr((seCoordFrom.Value)));

        coord0:=abs(trunc((nclon_arr[0]-seCoordFrom.Value)/step)); // lon min index
        coord1:=abs(trunc((nclon_arr[0]-seCoordTo.value)/step)); // lon max index
     //   showmessage(inttostr(coord0)+'   '+inttostr(coord1));

        start^[2]:=abs(trunc((nclat_arr[0]-seCoordFixed.Value)/step));
        ind_var:=3;

         r:=(2*pi*6378.137/360)*cos(seCoordFixed.Value*(pi/180));  {equatorial radius Hayford 1909 [km] 6378.137}

      end;

      if rgEastward.Checked then begin;
        step:=abs(nclat_arr[0]-nclat_arr[1]);
        coord0:=abs(trunc((nclat_arr[0]-seCoordFrom.Value)/step)); // lat min index
        coord1:=abs(trunc((nclat_arr[0]-seCoordTo.value)/step)); // lat max index

        start^[3]:=abs(trunc((nclon_arr[0]-seCoordFixed.Value)/step));
        ind_var:=2;

        r:=2*pi*6378.137/360;
      end;

      dl:=1000*r*step; // step in meters;

    //  showmessage(floattostr(dl));

   for pp:=coord0 to coord1 do begin
    start^[ind_var]:=pp;

    for ll:=0 to high(nclev_arr)-1 do begin //levels
     start^[1]:=ll;  //level
     dz:=abs(nclev_arr[ll]-nclev_arr[ll+1]);

  //   showmessage(floattostr(dl)+'   '+floattostr(dz));
  {   showmessage(inttostr(start^[0])+'   '+
                 inttostr(start^[1])+'   '+
                 inttostr(start^[2])+'   '+
                 inttostr(start^[3]));  }

         // showmessage('here');
           // NC_SHORT
           if VarToStr(vtype)='3' then begin
            SetLength(sp, 1);
             nc_get_var1_short(ncid, varidp, start^, sp);
            Val0:=sp[0];
             nc_get_var1_short(ncid, varidpt, start^, sp);
            Valt:=sp[0];
           end;

     //    showmessage(floattostr(val0));

       if (val0<>missing[0]) and (val0<>-9999) then begin
        val1:=scale[0]*val0+offset[0]; // scale and offset from nc file
        valt:=scale_t[0]*valt+offset_t[0]; // scale and offset for temperature

        net_tr:=net_tr+(val1*dl*dz);
        if (valt>=0) then net_tr_t:=net_tr_t+(val1*dl*dz);
        if (nclev_arr[ll]>=25) then net_tr25:=net_tr25+(val1*dl*dz);
        if (nclev_arr[ll]>=100) then net_tr100:=net_tr100+(val1*dl*dz);

        if (nclev_arr[ll]>=25) and (val1>0) then net_tr_N:=net_tr_N+(val1*dl*dz);
        if (nclev_arr[ll]>=25) and (val1<0) then net_tr_S:=net_tr_S+abs(val1*dl*dz);

       end; //-9999

     end; //range of coordinates
    end; //lon

  writeln(out_f1, yy:5, mn:3, dd:3, (net_tr/1E6):10:5); //Sverdrups
  writeln(out_f2, yy:5, mn:3, dd:3, (net_tr_t/1E6):10:5);
  writeln(out_f3, yy:5, mn:3, dd:3, (net_tr25/1E6):10:5);
  writeln(out_f4, yy:5, mn:3, dd:3, (net_tr100/1E6):10:5);
  writeln(out_f5, yy:5, mn:3, dd:3, (net_tr_N/1E6):10:5);
  writeln(out_f6, yy:5, mn:3, dd:3, (net_tr_S/1E6):10:5);

  FreeMemory(start);

  frmmain.ProgressBar1.Position:=k+1;
  Application.ProcessMessages;
  finally
   sp:=nil;
    status:=nc_close(ncid);  // Close file
     if status>0 then showmessage(pansichar(nc_strerror(status)));
  end;
 end;
 CloseFile(out_f1);
 CloseFile(out_f2);
 CloseFile(out_f3);
 CloseFile(out_f4);
 CloseFile(out_f5);
 CloseFile(out_f6);

 btncalculate.Enabled:=true;
 OpenDocument(PChar(NetTransportPath));
end;


procedure Tfrmnettransport.Average_years(fname:string);
var
  cnt: integer;
  f_in, f_out1, f_out2: text;
  yy_old, yy, mn, dd, val1, Int_Val: real;
begin

 if not FileExists(fname) then exit;

  cnt:=0; int_val:=0;
  try
    AssignFile(f_in, fname); Reset(f_in); // file with values
    readln(f_in);

    AssignFile(f_out1, copy(fname, 1, length(fname)-4)+'_yearly.dat'); Rewrite(f_out1);
    writeln(f_out1, 'yy':5, 'Val[Sv]':10);

    AssignFile(f_out2, copy(fname, 1, length(fname)-4)+'_yearly_clr.dat'); Rewrite(f_out2);
    writeln(f_out2, 'yy':5, 'Val[Sv]':10, 'Clr':5);

     repeat
       readln(f_in, yy, mn, dd, val1);
       if cnt=0 then yy_old:=yy;
       if yy=yy_old then begin
         Int_val:=Int_val+Val1;
         inc(cnt);
        end;
       if (yy<>yy_old) or (eof(f_in)) then begin
         writeln(f_out1, yy_old:5:0, (Int_Val/cnt):10:5);
          if Int_val>=0 then writeln(f_out2, yy_old:5:0, (Int_Val/cnt):10:5, 'red':5);
          if Int_val<0  then writeln(f_out2, yy_old:5:0, (Int_Val/cnt):10:5, 'blue':5);
        cnt:=1;
        Int_Val:=val1;
        yy_old:=yy;
       end;
    until eof(f_in);
 finally
  CloseFile(f_in);   // close files;
  CloseFile(f_out1);
  CloseFile(f_out2);
 end;
end;


procedure Tfrmnettransport.btnYearlyAveragingClick(Sender: TObject);
begin
  Average_years(NetTransportPath+'nettransport.dat');
  Average_years(NetTransportPath+'nettransport_t0.dat');
  Average_years(NetTransportPath+'nettransport_25.dat');
  Average_years(NetTransportPath+'nettransport_100.dat');
  Average_years(NetTransportPath+'nettransport_N.dat');
  Average_years(NetTransportPath+'nettransport_S.dat');
end;

procedure Tfrmnettransport.btnOpenFolderClick(Sender: TObject);
begin
  OpenDocument(PChar(NetTransportPath));
end;

end.

