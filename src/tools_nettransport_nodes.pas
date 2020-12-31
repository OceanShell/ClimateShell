unit tools_nettransport_nodes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, DateUtils;

Procedure NetTransportNodes;

implementation

uses ncmain, declarations_netcdf, GibbsSeaWater;

Procedure NetTransportNodes;
Var
  dat1, dat2, dat3:text;
  k, i, ll, pp, f_par:integer;
  yy, mn, dd: word;
  lat0, lon0, step, lat, lon: real;
  T_Lat, B_Lat, L_Lon, R_lon: real;
  lat0_i, lon0_i: integer;

  start: PArraySize_t;
  status, ncid, varidp, varidpu, varidpt, varidps:integer;
  td:array of double;
  missing: array [0..0] of single;
  scale_u, offset_u, missing_u: array [0..0] of single;
  scale_t, offset_t, missing_t: array [0..0] of single;
  scale_s, offset_s, missing_s: array [0..0] of single;

  H_point, Sum_dist, Dist, val0, u0, t0, s0, u0_old, t0_old, s0_old:real;
  hlt, hrt, hlb, hrb, Cp, Dw, Dh, Ds, Tref, Sref, Tm, Sm, p, SA, Dens:real;

  date1: real;
begin

   lat0:=ncLat_arr[0];  // first latitude
   lon0:=ncLon_arr[0]; // first longitude
   step  := 1/12;  // 15"

   // Cp:=4218;
   Cp:=3850;// J/(kg C)

   Tref:=-1.8;
   Sref:=0;

   AssignFile(dat1, GlobalUnloadPath+'net_tr_u0.txt');     rewrite(dat1);
   AssignFile(dat2, GlobalUnloadPath+'net_tr_thetao.txt'); rewrite(dat2);
   AssignFile(dat3, GlobalUnloadPath+'net_tr_s0.txt');     rewrite(dat3);

   frmmain.ProgressBar1.Position:=0;
   frmmain.ProgressBar1.Max:=frmmain.cbFiles.count;
    for k:=0 to frmmain.cbFiles.count-1 do begin
     ncName:=frmmain.cbFiles.Items.strings[k];

     yy:=StrToInt(Copy(ncName, 1, 4));
     mn:=StrToInt(Copy(ncName, 6, 2));
     dd:=StrToInt(Copy(ncName, 9, 2));

     date1:=yy+(mn-1)/12+(dd-1)/(12*DaysInAMonth(yy,mn));

     write(dat1, date1:10:5);
     write(dat2, date1:10:5);
     write(dat3, date1:10:5);

    try
     nc_open(pansichar(ncpath+ncname), NC_NOWRITE, ncid);

     nc_inq_varid (ncid, pChar('uo'),     varidpu);
     nc_inq_varid (ncid, pChar('thetao'), varidpt);
     nc_inq_varid (ncid, pChar('so'),     varidps);

   //  showmessage(inttostr(varidp));

     nc_get_att_float(ncid, varidpu, pansichar(pansichar(AnsiString('add_offset'))),    offset_u);
     nc_get_att_float(ncid, varidpu, pansichar(pansichar(AnsiString('scale_factor'))),  scale_u);
     nc_get_att_float(ncid, varidpu, pansichar(pansichar(AnsiString('_FillValue'))),    missing_u);

     nc_get_att_float(ncid, varidpt, pansichar(pansichar(AnsiString('add_offset'))),    offset_t);
     nc_get_att_float(ncid, varidpt, pansichar(pansichar(AnsiString('scale_factor'))),  scale_t);
     nc_get_att_float(ncid, varidpt, pansichar(pansichar(AnsiString('_FillValue'))),    missing_t);

     nc_get_att_float(ncid, varidps, pansichar(pansichar(AnsiString('add_offset'))),    offset_s);
     nc_get_att_float(ncid, varidps, pansichar(pansichar(AnsiString('scale_factor'))),  scale_s);
     nc_get_att_float(ncid, varidps, pansichar(pansichar(AnsiString('_FillValue'))),    missing_s);

     for i:=1 to 6 do begin
      case i of
        1: begin lat:=77+04.25247/60; lon:=125+48.2878/60; end;
        2: begin lat:=77+10.37610/60; lon:=125+47.5155/60; end;
        3: begin lat:=77+39.28600/60; lon:=125+48.4014/60; end;
        4: begin lat:=78+27.54310/60; lon:=125+53.7583/60; end;
        5: begin lat:=80+00.19860/60; lon:=125+59.6729/60; end;
        6: begin lat:=81+08.18237/60; lon:=125+42.6732/60; end;
      end;


     // search by indexes
     lat0_i:=abs(trunc((lat0-lat)/step)); // lat index
     lon0_i:=abs(trunc((lon0-lon)/step)); // lon index

     T_Lat:=nclat_arr[lat0_i];
     B_Lat:=nclat_arr[lat0_i+1];
     L_Lon:=nclon_arr[lon0_i];
     R_Lon:=nclon_arr[lon0_i+1];


   {  showmessage(floattostr(T_Lat)+'   '+
                 floattostr(B_Lat)+'   '+
                 floattostr(L_Lon)+'   '+
                 floattostr(R_Lon));  }

    start:=GetMemory(SizeOf(TArraySize_t)*4);

     Dw:=0; Dh:=0; Ds:=0;
     start^[0]:=0;
      for ll:=0 to high(nclev_arr)-1 do begin //levels
       if nclev_arr[ll]<=780 then begin
       start^[1]:=ll;  //level

       u0:=9999; T0:=9999; S0:=9999;
       for f_par:=1 to 3 do begin
        case f_par of
          1: begin varidp:=varidpu; missing[0]:=missing_u[0]; end;
          2: begin varidp:=varidpt; missing[0]:=missing_t[0]; end;
          3: begin varidp:=varidps; missing[0]:=missing_s[0]; end;
        end;

         start^[2]:=lat0_i;
         start^[3]:=lon0_i;
          SetLength(td, 1);
           nc_get_var1_double(ncid, varidp, start^, td);
          hlt:=td[0];

         start^[2]:=lat0_i;
         start^[3]:=lon0_i+1;
          SetLength(td, 1);
           nc_get_var1_double(ncid, varidp, start^, td);
          hrt:=td[0];

         start^[2]:=lat0_i+1;
         start^[3]:=lon0_i;
          SetLength(td, 1);
           nc_get_var1_double(ncid, varidp, start^, td);
          hlb:=td[0];

         start^[2]:=lat0_i+1;
         start^[3]:=lon0_i+1;
          SetLength(td, 1);
           nc_get_var1_double(ncid, varidp, start^, td);
          hrb:=td[0];

   if (hlt<>missing[0]) and (hrt<>missing[0]) and
      (hlb<>missing[0]) and (hrb<>missing[0]) then begin
    H_Point:=0;
    Sum_Dist:=0;

    Dist:=111.3*sqrt(sqr(Lat-T_lat)+sqr(cos(Pi/360*(Lat+T_Lat))*(Lon-L_Lon)));
    If Dist=0 then
     Dist:=1E-10;
    H_point:=H_point+HLT/Dist;
    Sum_Dist:=Sum_Dist+1/Dist;

    Dist:=111.3*sqrt(sqr(Lat-T_lat)+sqr(cos(Pi/360*(Lat+T_Lat))*(Lon-R_Lon)));
    If Dist=0 then
     Dist:=1E-10;
    H_point:=H_point+HRT/Dist;
    Sum_Dist:=Sum_Dist+1/Dist;

    Dist:=111.3*sqrt(sqr(Lat-B_lat)+sqr(cos(Pi/360*(Lat+B_Lat))*(Lon-L_Lon)));
    If Dist=0 then
     Dist:=1E-10;
    H_point:=H_point+HLB/Dist;
    Sum_Dist:=Sum_Dist+1/Dist;

    Dist:=111.3*sqrt(sqr(Lat-B_lat)+sqr(cos(Pi/360*(Lat+B_Lat))*(Lon-R_Lon)));
    If Dist=0 then
     Dist:=1E-10;
    H_point:=H_point+HRB/Dist;
    Sum_Dist:=Sum_Dist+1/Dist;

    val0:=round(H_point/Sum_Dist);
     case f_par of
      1: u0:=scale_u[0]*val0+offset_u[0];
      2: t0:=scale_t[0]*val0+offset_t[0];
      3: s0:=scale_s[0]*val0+offset_s[0];
     end;
    end; // missing
   end; //3 param

   if (u0<>9999) and (t0<>9999) and (s0<>9999) then begin
   {  showmessage(floattostr(u0)+'   '+
                 floattostr(t0)+'   '+
                 floattostr(s0)); }

    if ll=0 then begin
      u0_old:=u0;
      t0_old:=t0;
      s0_old:=s0;
    end;

    if ll>0 then begin
      Tm:=(t0+t0_old)/2;
      Sm:=(s0+s0_old)/2;

       p:=10.1325;
       SA  := gsw_SA_from_SP(Sm, p, lon, lat);
       dens:= gsw_rho_t_exact(sa, Tm, p); //-1000;

        Dw:=Dw+1/2*(u0+u0_old)*(nclev_arr[ll+1]-nclev_arr[ll]);
        Dh:=Dh+dens*Cp*u0_old*(Tm-TRef)*(nclev_arr[ll+1]-nclev_arr[ll]);
        Ds:=Ds+1/1000*dens*u0_old*(Sm-Sref)*(nclev_arr[ll+1]-nclev_arr[ll]);  // g/kg->kg/kg

      u0_old:=u0;
      t0_old:=t0;
      s0_old:=s0;
    end;
    end;

{    showmessage(floattostr(hlt)+'   '+
                 floattostr(hrt)+'   '+
                 floattostr(hlb)+'   '+
                 floattostr(hrb)+'   '+
                 floattostr(u0_ini)+'   '+
                 floattostr(u0)); }
   end; //780m
  end; // levels

   write(dat1, DW:15:5);
   write(dat2, (Dh/1E6):15:5);
   write(dat3, Ds:15:5);
  end;
  writeln(dat1);
  writeln(dat2);
  writeln(dat3);

    finally
      td:=nil;
       status:=nc_close(ncid);  // Close file
        if status>0 then showmessage(pansichar(nc_strerror(status)));
     end;
    end;

Closefile(dat1);
Closefile(dat2);
Closefile(dat3);
end;

end.

