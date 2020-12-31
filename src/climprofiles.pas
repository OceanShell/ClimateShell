unit climprofiles;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, TAGraph,  Forms, Controls, Graphics,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, Math, IniFiles, TASeries;

type

  { Tfrmclimprofiles }

  Tfrmclimprofiles = class(TForm)
    btnGetProfile: TButton;
    btnInterpolation: TButton;
    cbLat: TComboBox;
    cbLon: TComboBox;
    cbSeaBorders: TComboBox;
    Chart1: TChart;
    Chart2: TChart;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    eIntLev: TEdit;
    eIntVal: TEdit;
    ePointLat: TEdit;
    ePointLon: TEdit;
    ePointRad: TEdit;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lbMethod: TLabel;
    lbVariable: TLabel;
    Memo1: TMemo;
    PageControl1: TPageControl;
    Panel1: TPanel;
    pgMain: TPageControl;
    Splitter1: TSplitter;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheet5: TTabSheet;
    TabSheet6: TTabSheet;

    procedure btnGetProfileClick(Sender: TObject);
    procedure btnInterpolationClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);

  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmclimprofiles: Tfrmclimprofiles;
  va: array [1..29] of real;
  da: array [1..29] of integer;

  fin:text;
  Num_point_BLN:array[1..1] of integer;
  Coord_BLN:array[1..2,1..200] of real;
  Long_min_BLN,Lat_min_BLN, lat_p, lon_p:real;


implementation

{$R *.lfm}

uses ncmain, declarations_netcdf, ncprocedures, Bathymetry;

Function Point_Status(Long_p,Lat_p:real):byte;
Label
  Lab_1;
Const
  {Задание сдвига базовой точки от минимальных значений координат в BLN-файле}
  Shift=0.123456789;
var
  Long_Point,Long_Base,Lat_Point,Lat_Base:real;
  K_Base,B_Base,K_BLN,B_BLN:real;
  Current_Max_Long,Current_Min_Long,Current_Max_Lat,Current_Min_Lat:real;
  ci4,ci3,First_Point,Num_Transsect:integer;

Function Verify:Boolean;
begin
  {Проверка на принадлежность точки пересечения !!!!отрезку!!! базовой прямой}
  Verify:=False;

  if ((Long_point>Long_Base) and (Lat_point>Lat_Base)
    and (Long_point<=Long_p) and (Lat_point<=Lat_p)) then
  begin
    Current_Min_Long:=Coord_BLN[1,ci4];
    Current_Max_Long:=Coord_BLN[1,ci4+1];
    Current_Min_Lat:=Coord_BLN[2,ci4];
    Current_Max_Lat:=Coord_BLN[2,ci4+1];
    if Current_Max_Long<Current_Min_Long then
    begin
      Current_Max_Long:=Coord_BLN[1,ci4];
      Current_Min_Long:=Coord_BLN[1,ci4+1];
    end;
    if Current_Max_Lat<Current_Min_Lat then
    begin
      Current_Max_Lat:=Coord_BLN[2,ci4];
      Current_Min_Lat:=Coord_BLN[2,ci4+1];
    end;

    {Не забыть о равенстве значений на границе}
    if (Long_point>=Current_Min_Long) and (Lat_point>=Current_Min_Lat)
      and (Long_point<=Current_Max_Long) and (Lat_point<=Current_Max_Lat) then
      begin
      Verify:=True
     end;
  end;
end;

begin
  {Определение координат узловой точки отсчета}
Lab_1:

  Long_Base:=Long_min_BLN-Shift*random;
  Lat_base:=Lat_min_BLN-Shift*random;

  {Определение коээфициентов уравнения прямой от базовой точки до исследуемой.
  Уравнение прямой в виде y=kx+b}

  K_Base:=(Lat_p-Lat_base)/(Long_p-Long_base);

  B_Base:=Lat_p-K_Base*Long_p;
  {Если в контуре всего один объект}
  First_Point:=1;
  ci3:=1;

  Num_Transsect:=0;
  for ci4:=First_Point to First_Point+Num_point_BLN[ci3]-2 do
  begin
    if Coord_BLN[1,ci4]<>Coord_BLN[1,ci4+1] then
    begin
      K_BLN:=(Coord_BLN[2,ci4+1]-Coord_BLN[2,ci4])/
       (Coord_BLN[1,ci4+1]-Coord_BLN[1,ci4]);
      B_BLN:=Coord_BLN[2,ci4]-Coord_BLN[1,ci4]*K_BLN;

      if K_BLN=K_Base then
      begin
       goto Lab_1
      end
      else
      begin
        Long_point:=(B_BLN-B_Base)/(K_Base-K_BLN);
        Lat_Point:=K_BLN*Long_point+B_BLN;
      end;

    end
    else
    begin
      Long_Point:=Coord_BLN[1,ci4];
      Lat_Point:=K_Base*Long_point+B_Base;
    end;

    if Verify then
    begin
      Inc(Num_Transsect);
    end;
  end;
  Point_Status:=Num_Transsect;
end;



procedure Tfrmclimprofiles.FormShow(Sender: TObject);
Var
  k:integer;
  LatMin, LatMax, LonMin, LonMax: real;
  fdb:TSearchRec;
begin
  if frmmain.cbVariables.Count=3 then
   lbVariable.Caption := frmmain.cbVariables.items.Strings[0] else
   lbVariable.Caption := frmmain.cbVariables.items.Strings[4];

   cbLat.Items       := frmmain.cbLat.items;       // latitude
   cbLon.Items       := frmmain.cbLon.items;       // longitude

   LatMin:=90; LatMax:=-90;
    for k:=0 to High(ncLat_arr) do begin // Latitude loop
     LatMin:=Min(LatMin, ncLat_arr[k]);
     LatMax:=Max(LatMax, ncLat_arr[k]);
   end;

  LonMin:=180; LonMax:=-180;
   for k:=0 to High(ncLon_arr) do begin // Latitude loop
    LonMin:=Min(LonMin, ncLon_arr[k]);
    LonMax:=Max(LonMax, ncLon_arr[k]);
   end;

   // min and max coordinates
   edit1.Text:=floattostr(LatMax);
   edit2.Text:=floattostr(LatMin);
   edit3.Text:=floattostr(LonMin);
   edit4.Text:=floattostr(LonMax);

(* загружаем список файлов с границами морей*)
 fdb.Name:=''; cbSeaBorders.Clear;
 cbSeaBorders.Text:='Select predefined area...';
  FindFirst(GlobalPath+'support\sea_borders\*.sb', faAnyFile, fdb);
   if fdb.Name<>'' then cbSeaBorders.Items.Add(fdb.Name);
    while FindNext(fdb)=0 do cbSeaBorders.Items.Add(fdb.Name);
  FindClose(fdb);
end;



procedure Tfrmclimprofiles.PageControl1Change(Sender: TObject);
Var
 lt_i, ln_i:integer;
begin
 { if (PageControl1.TabIndex=1) and (pointseries1.Count=0) then begin
  with pointseries1 do begin
   Clear;
    SeriesColor:=clblack;
    Pointer.Brush.Color:=clblack;
  //  ShowPoints:=true;
  //  ShowLines:=false;
    Pointer.HorizSize:=1;
    Pointer.VertSize:=1;
    LinePen.Width:=1;
  //  Pointer.Style:=psCircle;
  end; }

 for lt_i:=0 to high(ncLat_arr) do begin
  for ln_i:=0 to high(ncLon_arr) do begin
   if GetBathymetry(ncLon_arr[ln_i], ncLat_arr[lt_i])>0 then
   //pointseries1.AddXY(ncLon_arr[ln_i], ncLat_arr[lt_i]);
 // end;
 end;
  end;
end;



procedure Tfrmclimprofiles.btnGetProfileClick(Sender: TObject);
Var
  Ini:TIniFile;

  status, ncid, varidp, varidp2, ndimsp:integer;
  ll, lt_i, ln_i, tp, c, ci1, cnt:integer;

  fp:array of single;
  start: PArraySize_t;
  LatMin, LatMax, LonMin, LonMax, Lat0, Lon0, Rad, Dist: real;
  val0, val1, valr, yy1, Int_val, Val_err:real;
  sum_pi, area_mean:real;
  RelErr:real;
  UseRE:boolean;
  st:string;
  ltmin, ltmax, lnmin, lnmax, lon, lat:real;
begin
 memo1.clear;

 LatMin:= StrToFloat(edit2.Text);
 LatMax:= StrToFloat(edit1.Text);
 LonMin:= StrToFloat(edit3.Text);
 LonMax:= StrToFloat(edit4.Text);

 Lat0:=strtofloat(ePointLat.Text);
 Lon0:=strtofloat(ePointLon.Text);
 Rad :=strtofloat(ePointRad.Text);

 {lineseries1.Clear;
 lineseries1.SeriesColor:=clred;
 lineseries1.LinePen.Width:=2;

 with pointseries2 do begin
  Clear;
   SeriesColor:=clred;
   Pointer.Brush.Color:=clred;
   //ShowPoints:=true;
  // ShowLines:=false;
   Pointer.Pen.Color:=clred;
   Pointer.Pen.Width:=1;
 //  Pointer.Style:=psStar;
 end;

  with pointseries3 do begin
  Clear;
   SeriesColor:=clgreen;
   Pointer.Brush.Color:=clgreen;
 //  ShowPoints:=true;
 //  ShowLines:=false;
   Pointer.Pen.Color:=clgreen;
   Pointer.Pen.Width:=2;
 //  Pointer.Style:=psCircle;
 end;     }

 //cleaning up arrays
 for ll:=1 to 29 do begin
  va[ll]:=0;
  da[ll]:=0;
 end;

 try
   Ini := TIniFile.Create(IniFileName);
   RelErr:=Ini.ReadFloat('main', 'RelativeError',    0.25);
   UseRE :=Ini.ReadBool ('main', 'UseRelativeError', true);
  finally
    ini.Free;
  end;


  // area around point
  if pgMain.PageIndex=1 then begin
    //pointseries3.AddXY(StrToFloat(ePointLon.Text), StrToFloat(ePointLat.Text));
  end;


  // predefined area
  if pgMain.PageIndex=2 then begin
    if cbSeaBorders.ItemIndex=-1 then begin
      Showmessage('Please, select area');
      exit;
    end;

    AssignFile(fin, GlobalPath+'support\sea_borders\'+cbSeaBorders.Text); reset(fin);
    readln(fin, st);

     ci1:=1;
     Ltmin:=-90;
     Ltmax:=ltmin;
     lnmin:=180;
     lnmax:=lnmin;

    repeat
     readln(fin, st);

     lon:=StrToFloat(trim(copy(st, 1, pos(',', st)-1)));
     lat:=StrToFloat(trim(copy(st, pos(',', st)+1, length(st))));

        Coord_BLN[1,ci1]:=lon;
        Coord_BLN[2,ci1]:=lat;

        if Coord_BLN[1,ci1]<lnmin then
          lnmin:=Coord_BLN[1,ci1];
        if Coord_BLN[1,ci1]>lnmax then
          lnmax:=Coord_BLN[1,ci1];
        if Coord_BLN[2,ci1]<ltmin then
          ltmin:=Coord_BLN[2,ci1];
        if Coord_BLN[2,ci1]>ltmax then
          ltmax:=Coord_BLN[2,ci1];
        inc(ci1);
    until eof(fin);
    CloseFile(fin);

  Coord_BLN[1,ci1]:=Coord_BLN[1,1];
  Coord_BLN[2,ci1]:=Coord_BLN[2,1];
  Num_point_BLN[1]:=ci1;

  Long_min_BLN:=lnmin;
  Lat_min_bln:=ltmin;
end; // end of predefined region


try
 (* nc_open*)
   nc_open(pchar(ncpath+ncname), NC_NOWRITE, ncid); // only for reading

   nc_inq_varid (ncid, pChar(lbVariable.Caption), varidp); // variable ID
   nc_inq_varid (ncid, pChar(lbVariable.Caption+'_relerr'), varidp2); // Rel. err ID

   start:=GetMemory(SizeOf(TArraySize_t)*4); // get memory for start pointer

   c:=0;
   for ll:=frmmain.cbLevels.count-1 downto 0 do begin
    inc(c);

    (* for a single node *)
    if pgMain.PageIndex=3 then begin
       start^[0]:=0; //time
       start^[1]:=ll; //level
       start^[2]:=cbLat.ItemIndex;   //lat
       start^[3]:=cbLon.ItemIndex;   //lon

       SetLength(fp, 1);
        nc_get_var1_float(ncid, varidp, start^, fp);
       Val0:=fp[0];

       SetLength(fp, 1);
        nc_get_var1_float(ncid, varidp2, start^, fp);
       Valr:=fp[0];

       if (val0<>-9999) then begin
         if  (UseRE=false) or
            ((UseRE=true) and (valr<=RelErr)) then begin
           val1:=val0;
         (* для температуры ниже -1.8 *)
           if (lbVariable.Caption='Temperature') and (val1>-9999) and (val1<-1.8) then Val1:=-1.99;
           da[c]:=StrToInt(frmmain.cbLevels.Items.strings[ll]);
           va[c]:=Val1;
            memo1.Lines.add(Inttostr(da[c])+#9+FloattostrF(va[c], fffixed, 8, 3)+#9+'1');
            //lineseries1.AddXY(va[c], -da[c]);
          //  pointseries2.AddXY(StrToFloat(cbLon.Text), StrToFloat(cbLat.text));
         end;
       end; //Val0<>null
    end; // end for a single node


    (* Area averaging *)
   if  pgMain.PageIndex<3 then begin // not for a single node
    Int_val:=0; sum_pi:=0; area_mean:=0; cnt:=0;
       start^[0]:=0;  //time
    for lt_i:=0 to high(ncLat_arr) do begin
       start^[1]:=ll; //level
       start^[2]:=lt_i;  //lat

     for ln_i:=0 to high(ncLon_arr) do begin
       start^[3]:=ln_i;

       Distance(Lon0, ncLon_arr[ln_i], Lat0, ncLat_arr[lt_i], Dist);

        // get area mean
       if ((pgMain.PageIndex=0) and (ncLat_arr[lt_i]>=LatMin) and (ncLat_arr[lt_i]<=LatMax) and

            (((LonMin<=LonMax) and (ncLon_arr[ln_i]>=LonMin) and (ncLon_arr[ln_i]<=LonMax)) or
             ((LonMin> LonMax) and
              (((ncLon_arr[ln_i]>=LonMin) and (ncLon_arr[ln_i]<=180)) or
               ((ncLon_arr[ln_i]>=-180)   and (ncLon_arr[ln_i]<=LonMax))))))

           or ((pgMain.PageIndex=1) and (Dist<=Rad))

           or ((pgMain.PageIndex=2) and (Odd(Point_Status(ncLon_arr[ln_i],ncLat_arr[lt_i]))=true)) then begin

           SetLength(fp, 1);
            nc_get_var1_float(ncid, varidp, start^, fp);
           Val0:=fp[0];

            SetLength(fp, 1);
             nc_get_var1_float(ncid, varidp2, start^, fp);
            Valr:=fp[0];

           if (val0<>-9999) then begin
             if  (UseRE=false) or
                ((UseRE=true) and (valr<=RelErr)) then begin
                val1:=val0;
               (* для температуры ниже -1.8 *)
               if (lbVariable.Caption='Temperature') and (val1>-9999) and (val1<-1.8) then Val1:=-1.99;
                Int_val:=Int_val+Val1*cos(Pi*ncLat_arr[lt_i]/180);
                Sum_pi:=Sum_pi+cos(Pi*ncLat_arr[lt_i]/180);

                //pointseries2.AddXY(ncLon_arr[ln_i], ncLat_arr[lt_i]);
               inc(cnt);
            end;
          end;

       end; // end of same year
     end; // end of lon loop
    end; // end of lat loop
     if Sum_pi<>0 then begin
      Area_Mean:=Int_val/Sum_pi;
        da[c]:=StrToInt(frmmain.cbLevels.Items.strings[ll]);
        va[c]:=Area_Mean;
      memo1.Lines.add(Inttostr(da[c])+#9+FloattostrF(va[c], fffixed, 8, 3)+#9+inttostr(cnt));
      //lineseries1.AddXY(va[c], -da[c]);
     end;
      Int_val:=0; sum_pi:=0; area_mean:=0;  cnt:=0;// clear variables
     end;  // end of area averaging



   end; // end of level loop
 finally
  status:=nc_close(ncid);  // Close file
   if status>0 then showmessage(pansichar(nc_strerror(status)));
  FreeMemory(start);
 end;
end;


procedure Tfrmclimprofiles.btnInterpolationClick(Sender: TObject);
Var
  i, IntMethod:integer;
  IntLev, IntVal:real;
  val_enabled:boolean;
begin

 IntLev:=StrToFloat(eIntLev.Text);

 IntVal:=-9999;
 for i:=1 to high(da) do begin
  val_enabled:=false;
  if da[i]=IntLev then begin
   IntVal:=va[i];
   val_enabled:=true;
   break;
  end;

  if (IntLev=0) and (da[i]<5) then begin
   IntVal:=va[i];
    val_enabled:=true;
   break;
  end;

  try
   if (IntLev>da[i]) and (IntLev<da[i+1]) then begin
             //c - number of levels at profile;  i - sequential number of level
                                                    //       LU1 LU2 X LD1 LD2     ->
     if (high(da)=2)                    then ODBPr_VertInt(IntLev, -9,      da[i], da[i+1], -9,       -9,      va[i], va[i+1], -9,       IntVal, val_enabled, IntMethod); //x + + x
     if (high(da)>2) and (i=1)          then ODBPr_VertInt(IntLev, -9,      da[i], da[i+1], da[i+2],  -9,      va[i], va[i+1], va[i+2],  IntVal, val_enabled, IntMethod); //x + + +
     if (high(da)>2) and (i=high(da)-1) then ODBPr_VertInt(IntLev, da[i-1], da[i], da[i+1], -9,       va[i-1], va[i], va[i+1], -9,       IntVal, val_enabled, IntMethod); //+ + + x
     if (high(da)>3) and (i<>1) and (i<>high(da)-1)
                                        then ODBPr_VertInt(IntLev, da[i-1], da[i], da[i+1], da[i+2],  va[i-1], va[i], va[i+1], va[i+2],  IntVal, val_enabled, IntMethod); //+ + + +
     if val_enabled=true then  break;
   end;
  except
   //
  end;
  end; // end of levels

  if (IntVal<>-9999) and (val_enabled=true) then begin
   eIntVal.Text:=FloattostrF(IntVal, fffixed, 8, 3);
    case IntMethod of
     1: lbMethod.Caption:='Method: None';
     3: lbMethod.Caption:='Method: Linear';
     4: lbMethod.Caption:='Method: Reiniger-Ross';
     5: lbMethod.Caption:='Method: Lagrange U';
     6: lbMethod.Caption:='Method: Lagrange D';
    end;
  end else begin
    eIntVal.Text;
    lbMethod.Caption:='Method: ERROR!';
  end;
end;



procedure Tfrmclimprofiles.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  finalize(va);
  finalize(da);
end;

end.

