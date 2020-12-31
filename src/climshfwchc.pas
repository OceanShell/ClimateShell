unit climshfwchc;

{$mode objfpc}{$H+}

interface

uses

LCLIntf, SysUtils, Variants, Classes, Graphics, Controls, Forms, StdCtrls,
FileUtil, Dialogs, IniFiles;


//Dialogs, , IniFiles, Buttons, DateUtils;     LCLIntf, LCLType, LMessages, Messages,

type

  { Tfrmshfwchc }

  Tfrmshfwchc = class(TForm)
    btnStart: TButton;
    btnOpenSal: TButton;
    btnOpenTempN: TButton;
    btnOpenSalN: TButton;
    cbDate: TComboBox;
    eSal: TEdit;
    eTempN: TEdit;
    eSalN: TEdit;
    GroupBox1: TGroupBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    Label3: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    mLog: TMemo;
    GroupBox2: TGroupBox;
    Label4: TLabel;
    Label5: TLabel;
    cbTopLimit: TComboBox;
    cbBotLimit: TComboBox;
    GroupBox3: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    eTref: TEdit;
    eSref: TEdit;

    procedure btnStartClick(Sender: TObject);
//    procedure cbLevelsSelect(Sender: TObject);
    procedure FormShow(Sender: TObject);
 ////   procedure cbTopLimitChange(Sender: TObject);
//    procedure cbBotLimitChange(Sender: TObject);
 //   procedure cbQCflagChange(Sender: TObject);
 //   procedure eTrefChange(Sender: TObject);
//    procedure eSrefChange(Sender: TObject);

  private
    { Private declarations }
    Procedure UnloadData;
    Procedure CalculateParameters;
  //  Procedure RemoveSeasonalCircle;

  public
    { Public declarations }
  end;

var
  frmshfwchc: Tfrmshfwchc;
  sthPath:string;
  sth_in, sth_out:text;

implementation

{$R *.lfm}

uses ncmain, surfer_settings, ncprocedures, declarations_netcdf;


procedure Tfrmshfwchc.FormShow(Sender: TObject);
Var
k:integer;
begin
mLog.clear;
cbDate.Items := frmmain.cbDates.items;
cbTopLimit.Items:= frmmain.cbLevels.items;
cbBotLimit.Items:= frmmain.cbLevels.items;
if ncname<>'' then Label9.Caption:=ncpath+ncname;

esal.Text:='x:\DIVA\climatologies\Nordic Seas v2 web\DATA\VAR_A\annual-per-decade\salinity\salinity.20012012.0112.nc';


(* Создаем пути *)
if not DirectoryExists(GlobalPath+'unload\SH_FWC_HC\') then CreateDir(GlobalPath+'unload\SH_FWC_HC\');
 sthPath:=GlobalPath+'unload\SH_FWC_HC\'+ExtractFileName(ncname)+'\';
if not DirectoryExists(sthPath) then CreateDir(sthPath);


 //ODBDM.CDSMD.IndexFieldNames:='stdate;sttime'; //forced sorting
 //seRefYY1.Text:=Copy(Main.StatusBar3.Panels[5].Text, 7, 4);
// seRefYY2.Text:=Copy(Main.StatusBar3.Panels[6].Text, 7, 4);
end;


procedure Tfrmshfwchc.btnStartClick(Sender: TObject);
Var
 time1, val1, Lat, Lev1, r, svan, Val0, sth:real;
 Df, Dr:real;

  k, c, fl:integer;
 refsal, sum_t, sum_y, pres :real;
 date0, date1, fw: real;
begin

btnStart.Enabled:=false;

mLog.Clear;
mLog.Lines.Add('Start: '+TimeToStr(Now));
Application.ProcessMessages;

 
 mLog.Lines.Add('1. Unloading data...');
 UnloadData;

 {mLog.Lines.Add('2. Calculating parameters...');
 CalculateParameters;

 mLog.Lines.Add('3. Seasonal circle removal...');
 //RemoveSeasonalCircle;  }


 mLog.Lines.Add('=======');
 mLog.Lines.Add('Finish: '+TimeToStr(Now));

 btnStart.Enabled:=true;

  OpenDocument(PChar(sthPath));
end;


(*
1. Вытаскиваем полные профили по температуре и солености
2. Интерполируем их на стандартные горизонты
3. Записываем в файл с ограничением по глубине
*)
Procedure Tfrmshfwchc.UnloadData;
Var
 Ini:TIniFile;
 ID, k, i, c, m, stlevcnt:integer;
 T_arr, S_arr, Dep_arr:array[1..10000] of real;

 StDate, StTime:TDateTime;

 Year, month, day, hour, min, sec, msec:word;

 StLat, StLon, year_m, T_int, S_int, IntLev, TMean, SMean:real;
 TYear, SYear, svan, pres, dens:real;
 Densref, DensrefT, DensrefS, TRef, SRef:real;
 Ycnt:integer;
 T_enabled, S_enabled,  topfl, botfl:boolean;


  lt_i, ln_i, ll_i, tp, fl:integer;
  status, ncid, varidp, varidp2, ndimsp:integer;
  start: PArraySize_t;
   fp:array of single;
   sp:array of smallint;
   ip:array of integer;
   dp:array of double;
  vtype: nc_type;
  attlenp, lenp: size_t;
  scale, offset, missing: array [0..0] of single;
  val0, valr:variant;
  val1, firstval1:real;

  RelErr:real;
  UseRE:boolean;
begin
 Tref:=StrToFloat(eTRef.Text);
 Sref:=StrToFloat(eSRef.Text);

 try
   Ini := TIniFile.Create(IniFileName);
   RelErr:=Ini.ReadFloat('main', 'RelativeError',    0.25);
   UseRE :=Ini.ReadBool ('main', 'UseRelativeError', true);
  finally
    ini.Free;
  end;

  AssignFile(sth_out, sthPath+'initial_data.dat' ); rewrite(sth_out);
  writeln(sth_out, 'Lat':15, 'Lon':15, 'Lev':5, 'T':10, 'S':10, 'Dens':10,
                   'DensRef':10, 'DensRefT':10, 'DensRefS':10);

 try
  (* nc_open*)
   nc_open(pansichar(AnsiString(ncpath+ncname)), NC_NOWRITE, ncid); // only for reading

   nc_inq_varid (ncid, pchar('Temperature'), varidp); // variable ID
   nc_inq_varid (ncid, pchar('Temperature_relerr'), varidp2); // variable 2 ID

   start:=GetMemory(SizeOf(TArraySize_t)*4); // get memory for start pointer

   start^[0]:=cbDate.ItemIndex; //time
    for lt_i:=0 to high(ncLat_arr) do begin
      start^[2]:=lt_i;  //lat
      for ln_i:=0 to high(ncLon_arr) do begin
       start^[3]:=ln_i;

       // Чистим массивы
       for k:=1 to high(T_arr) do begin
        T_arr[k]:=0;   //температура
        S_arr[k]:=0;   //соленость
        Dep_arr[k]:=0; //глубина
       end;

       k:=0;
       for ll_i:=cbTopLimit.ItemIndex downto cbBotLimit.ItemIndex do begin
        start^[1]:=ll_i;  //level

        SetLength(fp, 1);
        nc_get_var1_float(ncid, varidp, start^, fp);
       Val0:=fp[0];
       Val1:=Val0;

       SetLength(fp, 1);
        nc_get_var1_float(ncid, varidp2, start^, fp);
       valr:=fp[0];

       if (val0<>-9999) then begin
          if  (UseRE=false) or
             ((UseRE=true) and (valr<=RelErr)) then begin
             inc(k);
              Dep_arr[k]:=ncLev_arr[ll_i];
              T_arr[k]:=Val1;
              //S_arr[k]:=ODBDM.ib1q2.FieldByName('value_1').AsFloat;

         end; // use of error
       end; //val<>-9999
    end;  //level

    if ((Dep_arr[1]<=StrToFloat(cbTopLimit.Text)) and  // write into file
        (Dep_arr[k]>=StrToFloat(cbBotLimit.Text))) then begin
          for i:=1 to k do begin
           Depth_to_Pressure(intlev, ncLat_arr[lt_i], 0, pres);

           IEOS80(pres, T_arr[k], S_arr[k], svan, dens);     // реальная плотность
           IEOS80(pres, tref,     sref,     svan, densref);  // относительная плотность
           IEOS80(pres, T_arr[k], sref,     svan, densrefT); // относительная плотность T
           IEOS80(pres, tref,     S_arr[k], svan, densrefS); // относительная плотность S


         dens     := dens     + 1000;
         densref  := densref  + 1000;
         densrefT := densrefT + 1000;
         densrefS := densrefS + 1000;
           writeln(sth_out, ncLat_arr[lt_i]:15:5, ncLon_arr[ln_i]:15:5,
           Dep_arr[i]:5:0, T_arr[i]:10:3, dens:10:3, densref:10:3, densreft:10:3,
           densrefs:10:3);
        end;
     end; // write into file
  end;
 end;
  FreeMemory(start);
  Closefile(sth_out);

 finally
  fp:=nil;
   status:=nc_close(ncid);  // Close file
    if status>0 then showmessage(pansichar(nc_strerror(status)));
 end;



{

    k:=0; // Заполняем массивы данными для интерполяции на ст. гор-ты
    m:=0; topfl:=false; botfl:=false;
    while not ODBDM.ib1q2.eof do begin
     inc(k);
      Dep_arr[k]:=ODBDM.ib1q2.FieldByName('level_').AsFloat;
      T_arr[k]:=ODBDM.ib1q2.FieldByName('value_').AsFloat;
      S_arr[k]:=ODBDM.ib1q2.FieldByName('value_1').AsFloat;
     ODBDM.ib1q2.Next;
    end;

    stlevcnt:=0;
    for c:=0 to cbTopLimit.Items.Count-1 do begin //считаем кол-во ст. гор-тов в слое
     if (strtoint(cbTopLimit.Items.Strings[c])>=StrToFloat(cbTopLimit.Text)) and
        (strtoint(cbTopLimit.Items.Strings[c])<=StrToFloat(cbBotLimit.Text)) then inc(stlevcnt);
    end;


    (* Выбираем только глубокие станции *)
    if (((StrToFloat(cbTopLimit.Text)=0) and (Dep_arr[1]<5)) or
        ((StrToFloat(cbTopLimit.Text)>0) and (Dep_arr[1]<=StrToFloat(cbTopLimit.Text)))) and
        (Dep_arr[k]>=StrToFloat(cbBotLimit.Text)) then begin

       (* интерполяция на стандартный горизонт *)
       for c:=0 to cbTopLimit.Items.Count-1 do begin //цикл по ст. горизонтам
        IntLev:=strtoint(cbTopLimit.Items.Strings[c]);
         T_int:=-999;
         S_int:=-999;

         for i:=1 to k do begin // цикл по горизонтам профиля
           T_enabled:=false;
           S_enabled:=false;

          if (IntLev=0) and (Dep_arr[i]<5) then begin
           T_int:=T_arr[i];
           S_int:=S_arr[i];
            T_enabled:=true;
            S_enabled:=true;
           break;
          end;

          if Dep_arr[i]=IntLev then begin
           T_int:=T_arr[i];
           S_int:=S_arr[i];
            T_enabled:=true;
            S_enabled:=true;
           break;
          end;


     try  // trying to interpolate  temperature
      if (IntLev>Dep_arr[i]) and (IntLev<Dep_arr[i+1]) then begin
       if (k=2)             then ODBPr_VertInt(IntLev, -9,           Dep_arr[i], Dep_arr[i+1], -9,            -9,         T_arr[i], T_arr[i+1], -9,          T_int, T_Enabled); //x + + x
       if (k>2) and (i=1)   then ODBPr_VertInt(IntLev, -9,           Dep_arr[i], Dep_arr[i+1], Dep_arr[i+2],  -9,         T_arr[i], T_arr[i+1], T_arr[i+2],  T_int, T_Enabled); //x + + +
       if (k>2) and (i=k-1) then ODBPr_VertInt(IntLev, Dep_arr[i-1], Dep_arr[i], Dep_arr[i+1], -9,            T_arr[i-1], T_arr[i], T_arr[i+1], -9,          T_int, T_Enabled); //+ + + x
       if (k>3) and (i<>1)  and (i<>k-1)
                            then ODBPr_VertInt(IntLev, Dep_arr[i-1], Dep_arr[i], Dep_arr[i+1], Dep_arr[i+2],  T_arr[i-1], T_arr[i], T_arr[i+1], T_arr[i+2],  T_int, T_Enabled); //+ + + +
      end;
     except
       T_enabled:=false;
     end;

     try  // trying to interpolate  salinity
      if (IntLev>Dep_arr[i]) and (IntLev<Dep_arr[i+1]) then begin
       if (k=2)             then ODBPr_VertInt(IntLev, -9,           Dep_arr[i], Dep_arr[i+1], -9,            -9,         S_arr[i], S_arr[i+1], -9,          S_int, S_Enabled); //x + + x
       if (k>2) and (i=1)   then ODBPr_VertInt(IntLev, -9,           Dep_arr[i], Dep_arr[i+1], Dep_arr[i+2],  -9,         S_arr[i], S_arr[i+1], S_arr[i+2],  S_int, S_Enabled); //x + + +
       if (k>2) and (i=k-1) then ODBPr_VertInt(IntLev, Dep_arr[i-1], Dep_arr[i], Dep_arr[i+1], -9,            S_arr[i-1], S_arr[i], S_arr[i+1], -9,          S_int, S_Enabled); //+ + + x
       if (k>3) and (i<>1)  and (i<>k-1)
                            then ODBPr_VertInt(IntLev, Dep_arr[i-1], Dep_arr[i], Dep_arr[i+1], Dep_arr[i+2],  S_arr[i-1], S_arr[i], S_arr[i+1], S_arr[i+2],  S_int, S_Enabled); //+ + + +
      end;
     except
       S_enabled:=false;
     end;
     if (T_enabled=true) and (S_enabled=true) then  break;
   end;

   (* Если интерполяция прошла успешно, то заполняем CDS *)
   if (T_Enabled=true) and (S_Enabled=true) and
      (IntLev>=StrToFloat(cbTopLimit.Text)) and
      (IntLev<=StrToFloat(cbBotLimit.Text)) then begin

      inc(m);

      Dint_arr[m]:=IntLev;
      Tint_arr[m]:=t_int;
      Sint_arr[m]:=s_int;

       if Dint_arr[m]=StrToFloat(cbTopLimit.Text) then topfl:=true;
       if Dint_arr[m]=StrToFloat(cbBotLimit.Text) then botfl:=true;
   end;
 end; //Конец цикла по стандартным горизонтам
 end;  // условие на полноту профиля

// showmessage(inttostr(m)+'   '+inttostr(stlevcnt));

 if (topfl=true) and (botfl=true) and (m=stlevcnt) then begin
   for k:=1 to m do begin

   IntLev:=Dint_arr[k];
   t_int :=Tint_arr[k];
   s_int :=Sint_arr[k];

   Depth_to_Pressure(intlev, StLat, 0, pres);

       IEOS80(pres, t_int, s_int, svan, dens);     // реальная плотность
       IEOS80(pres, tref,  sref,  svan, densref);  // относительная плотность
       IEOS80(pres, t_int, sref,  svan, densrefT); // относительная плотность T
       IEOS80(pres, tref,  s_int, svan, densrefS); // относительная плотность S

         dens     := dens     + 1000;
         densref  := densref  + 1000;
         densrefT := densrefT + 1000;
         densrefS := densrefS + 1000;

      writeln(sth_out, ID:8, StLat:10:5, StLon:10:5, year_m:12:5, year:6,
                       month:4, day:4, hour:4, min:4, IntLev:7:0, T_int:9:3,
                       S_Int:9:3, dens:10:3, densref:10:3, densreft:10:3,
                       densrefs:10:3);
   end;
 end;


  Main.ProgressBar1.Position:=Main.ProgressBar1.Position+1;
  Application.ProcessMessages;

 ODBDM.CDSMD.Next;
 end; // Конец цикла по станциям
 finally
  ODBDM.IBTransaction1.Commit;
  ODBDM.CDSMD.EnableControls;
   closefile(sth_out);
 end;  }
end;


(* Загружаем начальные данные из файла и считаем характеристики в слое *)
Procedure Tfrmshfwchc.CalculateParameters;
Var
k, c, fl:integer;
ID, ID0, Time_tr, Time0, lev1, t, s, Cp, Stlat0, StLon0:real;
yy, mn, dd, hh, mm, yy0, mn0, dd0, hh0, mm0:real;
Tref, Sref, Dens, Densref:real;
TLev, SLev, DensLev, DensRefLev, DensRefTLev, DensRefSLev, DensrefT, DensrefS:real;
StLat, StLon:real;
DH, DHt, DHs, HC, FWC, TMean, SMean, Dif1:real;
Dep_arr, T_arr, S_arr, Dens_arr, DensRef_arr, DensRefT_arr, DensRefS_arr:array [1..100] of real;
begin
 AssignFile(sth_in, sthPath+'initial_data.dat' ); reset(sth_in);
 readln(sth_in);

 AssignFile(sth_out, sthPath+'initial_results.dat' ); rewrite(sth_out);
 writeln(sth_out, 'Absnum':8, 'Lat':10, 'Lon':10, 'Time':12, 'YY':6, 'MN':4,
                  'DD':4, 'HH':4, 'MM':4,'DH [Cm]':10, 'DHt [Cm]':10, 'DHs [Cm]':10, 'HC [10^9 J/m2]':15,
                  'FWC':10, 'TMean':8, 'SMean':8);

 Tref:=StrToFloat(eTRef.Text);
 Sref:=StrToFloat(eSRef.Text);

 Cp:=4218;

 Dif1:=StrtoFloat(cbBotLimit.Text)-StrtoFloat(cbTopLimit.Text);

 time0:=-9999; c:=0; fl:=0; ID0:=0;
 yy0:=-9999; mn0:=-9999; dd0:=-9999; hh0:=-9999; mm0:=-9999;
 StLat0:=-9999; StLon0:=-9999;
 repeat
  readln(sth_in, ID, StLat, StLon, time_tr, yy, mn, dd, hh, mm, lev1, t, s, dens, densref, densrefT, densrefS);

   if fl=0 then begin
    ID0:=ID;
    time0:=time_tr; StLat0:=StLat; StLon0:=StLon;
     yy0:=yy; mn0:=mn; dd0:=dd; hh0:=hh; mm0:=mm;
    fl:=1;
   end;

     if ID=ID0 then begin
      inc(c);
       dep_arr[c]:=lev1;
       T_arr[c]:=t;
       S_arr[c]:=s;
       Dens_arr[c]:=dens;
       densref_arr[c]:=densref;
       densrefT_arr[c]:=densrefT;
       densrefS_arr[c]:=densrefS;
     end;

     if (ID<>ID0) or (eof(sth_in)) then begin
       DH:=0; DHt:=0; DHs:=0; HC:=0; FWC:=0;
       TMean:=0; SMean:=0;
       for k:=1 to c-1 do begin
        Tlev:=(T_arr[k+1]+T_arr[k])/2;         //температура на середину слоя
        Slev:=(S_arr[k+1]+S_arr[k])/2;         //соленость на середину слоя
        Denslev:=(Dens_arr[k+1]+Dens_arr[k])/2;  //плотность на середину слоя
        DensReflev:=(DensRef_arr[k+1]+DensRef_arr[k])/2;  //плотность на середину слоя
        DensRefTlev:=(DensRefT_arr[k+1]+DensRefT_arr[k])/2;  //плотность на середину слоя
        DensRefSlev:=(DensRefS_arr[k+1]+DensRefS_arr[k])/2;  //плотность на середину слоя

         TMean:=TMean+((T_arr[k+1]+T_arr[k])/2)*((dep_arr[k+1]-dep_arr[k])/Dif1);
         SMean:=SMean+((S_arr[k+1]+S_arr[k])/2)*((dep_arr[k+1]-dep_arr[k])/Dif1);


         DH :=DH +((densreflev-denslev)/densreflev)*(dep_arr[k+1]-dep_arr[k]);


        { showmessage(floattostr(densreflev)+#9+
                     floattostr(denslev)+#9+
                     floattostr(dep_arr[k])+#9+
                     floattostr(dep_arr[k+1])+#9+
                     floattostr(DH)); }

         DHt:=DHt+((densreflev-densrefTlev)/densreflev)*(dep_arr[k+1]-dep_arr[k]);
         DHs:=DHs+((densreflev-densrefSlev)/densreflev)*(dep_arr[k+1]-dep_arr[k]);

         HC :=HC +densreflev*Cp*(tref-Tlev)*(dep_arr[k+1]-dep_arr[k]);
         FWC:=FWC+((sref-slev)/sref)*(dep_arr[k+1]-dep_arr[k]);
     //  showmessage(floattostr(time0)+#9+floattostr(DH)+#9+floattostr(DHt)+#9+floattostr(DHs));
     end;

    // if DH=0 then  showmessage(floattostr(ID));

         {   mLog.Lines.Add(floattostr(time0)+#9+
                           floattostrF(DH,  fffixed, 8,  5)+#9+
                           floattostrF(DHt, fffixed, 8,  5)+#9+
                           floattostrF(DHs, fffixed, 8,  5)+#9+
                           floattostrF(HC,  fffixed, 8,  5)+#9+  }

       writeln(sth_out, ID0:8:0, StLat0:10:5, StLon0:10:5, time0:12:5, yy0:6:0,
                        mn0:4:0, dd0:4:0, hh0:4:0, mm0:4:0, (DH*100):10:5, (DHt*100):10:5,
                        (DHs*100):10:5, (HC*10E-9):15:5, FWC:10:5, TMean:8:3, SMean:8:3);
       //   mLog.Lines.Add('================');
       //   mLog.Lines.Add(floattostr(sum_t));

       // writeln(sth_out, date0:10:5, sum_t:15:5);



       time0:=time_tr; ID0:=ID; StLat0:=StLat; StLon0:=StLon;
       yy0:=yy; mn0:=mn; dd0:=dd; hh0:=hh; mm0:=mm;

       for c:=1 to 100 do begin
        dep_arr[c]:=0;
        t_arr[c]:=0;
        s_arr[c]:=0;
        Dens_arr[c]:=0;
        densref_arr[c]:=0;
        densrefT_arr[c]:=0;
        densrefS_arr[c]:=0;
       end;


       c:=1;
       dep_arr[c]:=lev1;
       t_arr[c]:=t;
       s_arr[c]:=s;
       Dens_arr[c]:=dens;
       densref_arr[c]:=densref;
       densrefT_arr[c]:=densrefT;
       densrefS_arr[c]:=densrefS;

       DH:=0; DHt:=0; DHs:=0; HC:=0; FWC:=0;
       TMean:=0; SMean:=0;
      end;

 until eof(sth_in);

 CloseFile(sth_in);
 CloseFile(sth_out);
end;



end.
