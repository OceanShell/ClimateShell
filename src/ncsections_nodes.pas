unit ncsections_nodes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  Buttons, IniFiles, Variants;

type

  { Tfrmncsections_nodes }

  Tfrmncsections_nodes = class(TForm)
    btnPlot: TButton;
    btnOpenFolder: TBitBtn;
    cbVariable: TComboBox;
    eAddOffset: TEdit;
    eAddScale: TEdit;
    gbCoords: TGroupBox;
    GroupBox5: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    rgLatitudinal: TRadioButton;
    rgLongitudinal: TRadioButton;
    seLon0: TFloatSpinEdit;
    seLat0: TFloatSpinEdit;
    seLat1: TFloatSpinEdit;
    seLon1: TFloatSpinEdit;

    procedure btnPlotClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure rgLatitudinalChange(Sender: TObject);
    procedure seLat0Change(Sender: TObject);

  private
    procedure RunSection;
    procedure CreateSectionBLN(coord0, coord1:integer);
    procedure CreateGebcoBLN(cnt:integer; Var dist_max, g_max:real;
      Var dist_arr:array of real);
  public

  end;

var
  frmncsections_nodes: Tfrmncsections_nodes;
  SectionPath: string;

implementation

{$R *.lfm}

{ Tfrmncsections_nodes }

uses ncmain, declarations_netcdf, bathymetry, ncprocedures, surfer_climsections;


procedure Tfrmncsections_nodes.FormShow(Sender: TObject);
begin
  cbVariable.Items := frmmain.cbVariables.items;

    if not DirectoryExists(GlobalUnloadPath+'sections'+PathDelim) then
           CreateDir(GlobalUnloadPath+'sections'+PathDelim);

    SectionPath:=GlobalUnloadPath+'sections'+PathDelim+ncname+PathDelim;

    if not DirectoryExists(SectionPath) then CreateDir(SectionPath);
    if not DirectoryExists(SectionPath+'png'+PathDelim) then CreateDir(SectionPath+'png'+PathDelim);
    if not DirectoryExists(SectionPath+'srf'+PathDelim) then CreateDir(SectionPath+'srf'+PathDelim);
    if not DirectoryExists(SectionPath+'dat'+PathDelim) then CreateDir(SectionPath+'dat'+PathDelim);
    if not DirectoryExists(SectionPath+'tmp'+PathDelim) then CreateDir(SectionPath+'tmp'+PathDelim);


  rgLatitudinal.OnChange(self);
end;

procedure Tfrmncsections_nodes.rgLatitudinalChange(Sender: TObject);
begin
  seLat1.Enabled:=rgLatitudinal.Checked;
  seLon1.Enabled:=rgLongitudinal.Checked;
end;

procedure Tfrmncsections_nodes.seLat0Change(Sender: TObject);
begin
  if not seLat1.Enabled then seLat1.Value:=seLat0.Value;
  if not seLon1.Enabled then seLon1.Value:=seLon0.Value;
end;

procedure Tfrmncsections_nodes.btnPlotClick(Sender: TObject);
begin
   RunSection;
end;


procedure Tfrmncsections_nodes.RunSection;
Var
  Ini: TIniFile;
  out_f1: text;
  k, i, c, stnum, col:integer;
  lt, ln, tp, fl, ll, d1:integer;

  par, st, lvl, clr, fcoord, ncexportfile, ncnorma, buf_str:string;
  dist_max, dist, gebco, g_max, g_first, dist_sum, addscale, addoffset:real;
  diff_lat, diff_lon, latd, lond, kf_s:real;

  MinLev, MaxLev:real;

  pp, coord0, coord1, ind_var:integer;
  status, ncid, varidp, varidpt, ndimsp:integer;
  start: PArraySize_t;

  vtype: nc_type;

  fp:array of single;
  sp:array of smallint;
  ip:array of integer;
  td:array of double;

  val0, valt:variant;
  step, val1, dl, dz, r, net_tr, net_tr_t, ind_val, lat, lon:real;
  scale, offset, missing: array [0..0] of single;

  dist_arr:array of real;
begin

 btnPlot.Enabled:=false;

 AssignFile(out_f1, SectionPath+'dat'+PathDelim+'data.dat'); Rewrite(out_f1);
 writeln(out_f1, 'Dist_tr':10, 'Dist':10, 'Level':10, 'Value':10, 'STN':5, 'Latitude':10, 'Longitude':10);


  try
    nc_open(pchar(ncpath+ncname), NC_NOWRITE, ncid);
    nc_inq_varid (ncid, pChar(cbVariable.Text), varidp);
    nc_inq_varndims (ncid, varidp, ndimsp);  // dimentions quantity
    nc_inq_vartype  (ncid, varidp, vtype);   // variable type

    (* Читаем коэффициенты из файла *)
    nc_get_att_float(ncid, varidp, pansichar(pansichar(AnsiString('add_offset'))),    offset);
    nc_get_att_float(ncid, varidp, pansichar(pansichar(AnsiString('scale_factor'))),  scale);
    nc_get_att_float(ncid, varidp, pansichar(pansichar(AnsiString('_FillValue'))),    missing);
    (*конец чтения коэффициентов *)


    start:=GetMemory(SizeOf(TArraySize_t)*4); // get memory for start pointer
    start^[0]:=0; //time

      // Longitudes
      if rgLongitudinal.Checked then begin;
        step:=abs(nclon_arr[0]-nclon_arr[1]);
        coord0:=abs(trunc((nclon_arr[0]-seLon0.Value)/step)); // lon min index
        coord1:=abs(trunc((nclon_arr[0]-seLon1.value)/step)); // lon max index

        start^[2]:=abs(trunc((nclat_arr[0]-seLat0.Value)/step));
        ind_var:=3;
        Lat:=seLat0.Value;
      end;

      if rgLatitudinal.Checked then begin;
        step:=abs(nclat_arr[0]-nclat_arr[1]);
        coord0:=abs(trunc((nclat_arr[0]-seLat0.Value)/step)); // lat min index
        coord1:=abs(trunc((nclat_arr[0]-seLat1.value)/step)); // lat max index

        start^[3]:=abs(trunc((nclon_arr[0]-seLon0.Value)/step));
        ind_var:=2;
        Lon:=seLon0.Value;
      end;

 // showmessage(floattostr(coord0)+'   '+floattostr(coord1));
  CreateSectionBLN(coord0, coord1);

  setlength(dist_arr, (coord1-coord0));
  CreateGebcoBLN((coord1-coord0), dist_max, g_max, dist_arr);

 // showmessage(floattostr(g_max)+'   '+floattostr(dist_max));


  kf_s:=g_max/dist_max;


    for ll:=0 to high(nclev_arr) do begin //levels
     start^[1]:=ll;  //level

     k:=-1;
     for pp:=coord0 to coord1 do begin
        start^[ind_var]:=pp;
        inc(k);

        if rgLatitudinal.Checked  then Lat:=ncLat_arr[pp];
        if rgLongitudinal.Checked then Lon:=ncLon_arr[pp];

        // NC_SHORT
                 if VarToStr(vtype)='3' then begin
                  SetLength(sp, 1);
                   nc_get_var1_short(ncid, varidp, start^, sp);
                  Val0:=sp[0];
                 end;

                 // NC_INT
                 if VarToStr(vtype)='4' then begin
                  SetLength(ip, 1);
                   nc_get_var1_int(ncid, varidp, start^, ip);
                  Val0:=ip[0];
                 end;

                 // NC_FLOAT
                 if VarToStr(vtype)='5' then begin
                  SetLength(fp, 1);
                   nc_get_var1_float(ncid, varidp, start^, fp);
                  Val0:=fp[0];
               //    showmessage(inttostr(varidp)+'   '+vartostr(fp[0]));
                 end;

                 // NC_DOUBLE
                 if VarToStr(vtype)='6' then begin
                  SetLength(td, 1);
                   nc_get_var1_double(ncid, varidp, start^, td);
                  Val0:=td[0];
                 end;                                      // showmessage(vartostr(vtype));

       if (val0<>missing[0]) and (val0<>-9999) then begin
        val1:=scale[0]*val0+offset[0]; // scale and offset from nc file

        addscale:=StrToFloat(eAddScale.Text);
        addoffset:=StrToFloat(eAddOffset.Text);

        val1:=addscale*val1+AddOffset;  // additional conversion

       // valt:=scale_t[0]*valt+offset_t[0]; // scale and offset for temperature
     //  'Dist_tr':10, 'Dist':10, 'Level':10, 'Value':10, 'STN':5, 'Latitude':10, 'Longitude':10);

         writeln(out_f1, (kf_s*dist_arr[k]):10:3, dist_arr[k]:10:3,
                 ncLev_arr[ll]:10:2, val1:10:3, pp:5, Lat:10:5, Lon:10:5);
       end; //-9999

     end; //range of coordinates
    end; //lon



  FreeMemory(start);
  finally
   sp:=nil;
    status:=nc_close(ncid);  // Close file
     if status>0 then showmessage(pansichar(nc_strerror(status)));
  end;
 CloseFile(out_f1);


 GetClimSectionsScript(SectionPath, SectionPath+'dat'+PathDelim+'data.dat',
 '' , '', kf_s, (kf_s*dist_max), 100, 100, 4, false,
                         'section_nodes', false,
                         false);

   {$IFDEF Windows}
     frmmain.RunScript(2, '-x "'+SectionPath+'tmp'+PathDelim+'script.bas"', nil);
   {$ENDIF}

 btnPlot.Enabled:=true;
end;

procedure Tfrmncsections_nodes.CreateSectionBLN(coord0, coord1:integer);
var
  dat:text;
  lat, lon:real;
  pp:integer;
begin
  AssignFile(dat, SectionPath+'tmp'+PathDelim+'section_nodes.bln'); rewrite(dat);

  lat:=seLat0.Value;
  lon:=seLon0.Value;

 // showmessage( inttostr(coord1-coord0+1));
  writeln(dat, inttostr(coord1-coord0+1), ',1');
  for pp:=coord0 to coord1 do begin
    if rgLatitudinal.Checked  then lat:=ncLat_arr[pp];
    if rgLongitudinal.Checked then lon:=ncLon_arr[pp];

  //  showmessage(Floattostr(lon)+ ','+ Floattostr(lat));

    writeln(dat, Floattostr(lon), ',', Floattostr(lat));
  end;
  CloseFile(dat);
end;


procedure Tfrmncsections_nodes.CreateGebcoBLN(cnt: integer; Var dist_max,
  g_max:real; Var dist_arr:array of real);
var
  dat1, dat2, dat3:text;
  lat_arr, lon_arr, dep_arr: array of single;
  k, d1, i, c:integer;
  gebco, g_first, dist, dist_sum, diff_lat, diff_lon, latd, lond:real;
  st, buf_str:string;
begin
 setlength(lat_arr,  cnt);
 setlength(lon_arr,  cnt);
 setlength(dep_arr,  cnt);

 AssignFile(dat1, SectionPath+'tmp'+PathDelim+'section_nodes.bln');  Reset(dat1);
 readln(dat1, st);

 AssignFile(dat2, SectionPath+'tmp'+PathDelim+'depth.bln');  Rewrite(dat2);
 writeln(dat2, (50*(cnt)+4):5, 1:5);

 AssignFile(dat3, SectionPath+'tmp'+PathDelim+'md.dat'); Rewrite(dat3);
 writeln(dat3, 'x':10,  'y':10, 'Lat':15, 'Lon':15, 'Lat_p':15, 'Lon_p':15, 'Depth':15, 'ID':10);


// showmessage('here');

  k:=-1; dist_max:=0; g_max:=0;
  repeat
   inc(k);

   readln(dat1, st);

     i:=0;
     for c:=1 to 2 do begin
      buf_str:='';
       repeat
        inc(i);
         if st[i]<>',' then buf_str:=buf_str+st[i];
       until st[i]=',';
    //   showmessage(trim(buf_str));
       if c=1 then lon_arr[k]:=strtofloat(trim(buf_str));
       if c=2 then lat_arr[k]:=strtofloat(trim(buf_str));
     end;

   //  showmessage(floattostr(lon_arr[k])+'   '+floattostr(lat_arr[k]));

   Gebco:=-GetBathymetry(lon_arr[k],lat_arr[k]);
   dep_arr[k]:=gebco;

   // showmessage(floattostr(gebco));

   if gebco>g_max then g_max:=gebco;

   if k=0 then begin
      dist_sum:=0;
      dist_arr[k]:=0;
      G_first:=Gebco;
        writeln(dat2,  0:10, gebco:10:3);
   end;

   if k>0 then begin
      Distance(lon_arr[k-1],lon_arr[k],lat_arr[k-1],lat_arr[k], dist);
    //  showmessage(floattostr(dist));
      dist_arr[k]:=dist_arr[k-1]+dist;

      writeln(dat3, dist_arr[k]:10:3, -12:10, lat_arr[k]:15:5, lon_arr[k]:15:5,
          ((90- lat_arr[k])*111.12*sin((lon_arr[k])*Pi/180)):15:5,
          (-(90- lat_arr[k])*111.12*cos((lon_arr[k])*Pi/180)):15:5,
          gebco:15:3,
          k:10);


      diff_lat:=abs(lat_arr[k]-lat_arr[k-1])/50;
      diff_lon:=abs(lon_arr[k]-lon_arr[k-1])/50;
      latd:=lat_arr[k-1]; Lond:=lon_arr[k-1];
       for d1:=1 to 50 do begin
        if lat_arr[k]>lat_arr[k-1] then latd:=latd+diff_lat else latd:=latd-diff_lat;
        if lon_arr[k]>lon_arr[k-1] then lond:=lond+diff_lon else lond:=lond-diff_lon;
         gebco:=-GetBathymetry(lond,latd);
          if gebco>g_max then g_max:=gebco;

         dist_sum:=dist_sum+(dist/50);
        writeln(dat2, dist_sum:10:3, gebco:10:3);
       end;
   end;

   if dist_arr[k]>dist_max then dist_max:=dist_arr[k];

  until eof(dat1);
  Closefile(dat1);
  Closefile(dat3);

 // showmessage(inttostr(dist_arr[k]));

    writeln(dat2, dist_sum:10:3, (g_max+(g_max/100)):10:3);
    writeln(dat2, 0:10, (g_max+(g_max/100)):10:3);
    writeln(dat2, 0:10, g_first:10:3);
  CloseFile(dat2);
 // showmessage('done');
end;

end.

