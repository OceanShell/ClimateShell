unit surfer_climfields;

{$mode objfpc}{$H+}

interface


uses sysutils, IniFiles, dialogs, ncmain, ncprocedures;


(* Fields for climatology *)
procedure GetClimFieldsScript(inidat, src, lev1, lev2, clr1, clr2:string;
          XMin, XMax, Ymin, YMax:real;
          basemap, ncexportfile:string; ncFieldsAuto, legend:boolean; basemap2,
          period, avper, avpar:string; depth, stnum:integer;
          cvar:string; iceplot, polar:boolean);

implementation


(******************************** Fields for climatology **********************)
procedure GetClimFieldsScript(IniDat, src, lev1, lev2, clr1, clr2:string;
          XMin, XMax, Ymin, YMax:real;
          basemap, ncexportfile:string; ncFieldsAuto, legend:boolean; basemap2,
          period, avper, avpar:string; depth, stnum:integer;
          cvar:string; iceplot, polar:boolean);
(*
IniDat - initial data
   src1=source file 1 name
   src2=source file 2 name
   lev1=colour file for var1
   lev2=colour file for var2
   clr1=
   clr2=
   XMin=min longitude
   XMax=max longitude
   YMin=min latitude
   YMax=max latitude
   basemap= base map location
   ncexportfile=name of export *.png
   ncFieldsAuto=auto calculation flag
   basemap2=base map with NS region
   Projection: 0-merkator, 1-circumpolar
*)
Var
 Ini:TIniFile;
 f_scr, f_out:text;
 k, c:integer;
 FieldPath, IntMethod, contour, avunit, IniSet, levice, PolarGrd:string;
 lon, lat, x, y, val1, searchrad1, searchrad2:real;
 XL, YL: string;
begin
 IniSet:='climfields';

 Contour:=GlobalPath+lowercase('support\bln\'+basemap);

     if (polar=true) then begin
       Contour :=GlobalPath+lowercase('support\bln\Arctic_polar.bln');
       PolarGrd:=GlobalPath+lowercase('support\bln\Arctic_polar_net.bln');
       XMin:=-5000;
       XMax:= 5000;
       YMin:=-5000;
       YMax:= 5000;
     end;

     levice:=GlobalPath+'support\lvl\ice.lvl';

   //  showmessage(inidat);
     (* transforming initial data to polar coordinates *)
     if (FileExists(IniDat)) and (polar=true) then begin
      AssignFile(f_scr, IniDat); reset(f_scr);
      AssignFile(f_out, IniDat+'_c'); rewrite(f_out);
      repeat
        readln(f_scr, lon, lat, val1);
        x:= (90-Lat)*111.12*sin((Lon)*Pi/180);
        y:=-(90-Lat)*111.12*cos((Lon)*Pi/180);
       writeln(f_out, y:15:5, x:15:5, val1:10:3);
      until eof(f_scr);
      CloseFile(f_scr);
      CloseFile(f_out);
      IniDat:=IniDat+'_c';
     end;

//showmessage(floattostr(xmin)+'   '+floattostr(xmax));
 FieldPath:=ExtractFilePath(src); //Path to data

 if avpar='Temperature' then avunit:='('+#176+'C)';
 if avpar='Salinity'    then avunit:='';//avunit:=#137;
 if avpar='Density'     then avunit:='(kg/m3)';


 AssignFile(f_scr, FieldPath+'script.bas'); rewrite(f_scr);  // script file
 Ini := TIniFile.Create(IniFileName); // settings from file

 IntMethod:=Ini.ReadString   (IniSet, 'Algorithm', 'srfKriging');
 try
   WriteLn(f_scr, 'Sub Main');
   WriteLn(f_scr, 'Dim Surfer, Diagram, Doc As Object');
   WriteLn(f_scr, 'pathBlankMap="' +contour+'"');
   WriteLn(f_scr, 'pathPolarGrd="' +polargrd+'"');
   WriteLn(f_scr, 'pathBlankMap2="'+basemap2+'"');
   WriteLn(f_scr, 'pathDataFile ="'+src+'"');
   WriteLn(f_scr, 'pathIniData="'  +IniDat+'"');
   WriteLn(f_scr, 'pathIceData="'  +FieldPath+'ice.dat"');
   WriteLn(f_scr, 'PathGRDVal = "' +FieldPath+'grd\'+ncExportfile+'_val.grd"');
   WriteLn(f_scr, 'PathGRDErr = "' +FieldPath+'grd\'+ncExportfile+'_err.grd"');
   WriteLn(f_scr, 'PathGRDIce = "' +FieldPath+'grd\'+ncExportfile+'_ice.grd"');
   WriteLn(f_scr, '');

   WriteLn(f_scr, 'Set Surfer=CreateObject("Surfer.Application")');

   if ncFieldsAuto=false then
     WriteLn(f_scr, '    Surfer.Visible=True');


   WriteLn(f_scr, 'Set Doc=Surfer.Documents.Add');
   WriteLn(f_scr, '    Doc.PageSetup.Orientation = srfPortrait'); // two plots
   WriteLn(f_scr, 'Set Diagram = Doc.Windows(1)');
   WriteLn(f_scr, '    Diagram.AutoRedraw = False');
   WriteLn(f_scr, '');

   (* Создаем прозрачный прямоугольник, чтобы задать размеры листа *)
   if polar=false then begin
     SearchRad1:=Ini.ReadFloat(IniSet, 'SearchRad1', 1);
     SearchRad2:=Ini.ReadFloat(IniSet, 'SearchRad2', 1);
      WriteLn(f_scr, '    Set Rectangle = Doc.Shapes.AddRectangle(Left:=1, Top:=27, Right:=20, Bottom:=8)');
   end;
   if polar=true then begin
     SearchRad1:=50*Ini.ReadFloat(IniSet, 'SearchRad1', 1);
     SearchRad2:=50*Ini.ReadFloat(IniSet, 'SearchRad2', 1);
      WriteLn(f_scr, '    Set Rectangle = Doc.Shapes.AddRectangle(Left:=4, Top:=27.5, Right:=19.5, Bottom:=0.5)');
      WriteLn(f_scr, '    Rectangle.Fill.Transparent = True');
      WriteLn(f_scr, '    Rectangle.Fill.Pattern = "None" ');
      WriteLn(f_scr, '    Rectangle.Line.Style = "Invisible"');
      WriteLn(f_scr, '');
   end;

   (* Гридируем данные *)
    WriteLn(f_scr, 'Surfer.GridData(DataFile:=pathDataFile, _');
    WriteLn(f_scr, '       xCol:=2, _');
    WriteLn(f_scr, '       yCol:=1, _');
    WriteLn(f_scr, '       zCol:=3, _');
    WriteLn(f_scr, '       Algorithm:='        +IntMethod+', _');
    WriteLn(f_scr, '       NumCols:='          +inttostr(high(ncLon_arr)+1)+', _');
    WriteLn(f_scr, '       Numrows:='          +inttostr(high(ncLat_arr)+1)+', _');

(* Настройки для различных методов интерполяции *)
  if IntMethod='srfKriging'  then begin
    WriteLn(f_scr, '       KrigType:='         +Ini.ReadString(IniSet, 'KrigType',          'srfKrigPoint')+', _');
    WriteLn(f_scr, '       KrigDriftType:='    +Ini.ReadString(IniSet, 'KrigDriftType',     'srfDriftNone')+', _');
    if Ini.ReadBool(IniSet, 'SearchEnable', true)=true then begin
     WriteLn(f_scr, '       SearchEnable:=1, _');  //not Ini.ReadBool(IniSet, 'SearchEnable',       true);
     WriteLn(f_scr, '       SearchNumSectors:=' +Ini.ReadString(IniSet, 'SearchNumSectors',  '4')  +', _');
     WriteLn(f_scr, '       SearchMinData:='    +Ini.ReadString(IniSet, 'SearchMinData',     '16') +', _');
     WriteLn(f_scr, '       SearchMaxData:='    +Ini.ReadString(IniSet, 'SearchMaxData',     '64') +', _');
     WriteLn(f_scr, '       SearchDataPerSect:='+Ini.ReadString(IniSet, 'SearchDataPerSect', '8')  +', _');
     WriteLn(f_scr, '       SearchMaxEmpty:='   +Ini.ReadString(IniSet, 'SearchMaxEmpty',    '3')  +', _');
     WriteLn(f_scr, '       SearchRad1:='       +FloattoStr(SearchRad1)    +', _');
     WriteLn(f_scr, '       SearchRad2:='       +FloattoStr(SearchRad2)    +', _');
     WriteLn(f_scr, '       SearchAngle:='      +Ini.ReadString(IniSet, 'SearchAngle',       '0')  +', _');
    end;
  end;
  if IntMethod='srfInverseDistanse' then begin
    WriteLn(f_scr, '       SearchEnable:='       +Ini.ReadString(IniSet, 'SearchEnable',      '0')  +', _');
    WriteLn(f_scr, '       SearchNumSectors:='   +Ini.ReadString(IniSet, 'SearchNumSectors',  '4')  +', _');
    WriteLn(f_scr, '       SearchMinData:='      +Ini.ReadString(IniSet, 'SearchMinData',     '16') +', _');
    WriteLn(f_scr, '       SearchMaxData:='      +Ini.ReadString(IniSet, 'SearchMaxData',     '64') +', _');
    WriteLn(f_scr, '       SearchDataPerSect:='  +Ini.ReadString(IniSet, 'SearchDataPerSect', '8')  +', _');
    WriteLn(f_scr, '       SearchMaxEmpty:='     +Ini.ReadString(IniSet, 'SearchMaxEmpty',    '3')  +', _');
    WriteLn(f_scr, '       SearchRad1:='         +FloattoStr(SearchRad1)    +', _');
    WriteLn(f_scr, '       SearchRad2:='         +FloattoStr(SearchRad2)    +', _');
    WriteLn(f_scr, '       SearchAngle:='        +Ini.ReadString(IniSet, 'SearchAngle',       '0')  +', _');
    WriteLn(f_scr, '       AnisotropyRatio:='    +Ini.ReadString(IniSet, 'AnisotropyRatio',   '1')  +', _');
    WriteLn(f_scr, '       AnisotropyAngle:='    +Ini.ReadString(IniSet, 'AnisotropyAngle',   '0')  +', _');
    WriteLn(f_scr, '       IDPower:='            +Ini.ReadString(IniSet, 'IDPower',           '2')  +', _');
    WriteLn(f_scr, '       IDSmoothing:='        +Ini.ReadString(IniSet, 'IDSmoothing',       '0')  +', _');
  end;
  if IntMethod='srfNaturalNeighbor' then begin
    WriteLn(f_scr, '       AnisotropyRatio:='    +Ini.ReadString(IniSet, 'AnisotropyRatio',   '1')  +', _');
    WriteLn(f_scr, '       AnisotropyAngle:='    +Ini.ReadString(IniSet, 'AnisotropyAngle',   '0')  +', _');
  end;
  if IntMethod='srfNearestNeighbor' then begin
    WriteLn(f_scr, '       SearchRad1:='         +FloattoStr(SearchRad1)  +', _');
    WriteLn(f_scr, '       SearchRad2:='         +FloattoStr(SearchRad2)  +', _');
    WriteLn(f_scr, '       SearchAngle:='        +Ini.ReadString(IniSet, 'SearchAngle',       '0')  +', _');
  end;
  if IntMethod='srfMinCurvature' then begin
    WriteLn(f_scr, '       MCMaxResidual:='      +Ini.ReadString(IniSet, 'MCMaxResidual',     '1E-9')+', _');
    WriteLn(f_scr, '       MCMaxIterations:='    +Ini.ReadString(IniSet, 'MCMaxIterations',   '1E+5')+', _');
    WriteLn(f_scr, '       MCInternalTension:='  +Ini.ReadString(IniSet, 'MCInternalTension', '1')  +', _');
    WriteLn(f_scr, '       MCBoundaryTension:='  +Ini.ReadString(IniSet, 'MCBoundaryTension', '0')  +', _');
    WriteLn(f_scr, '       MCRelaxationFactor:=' +Ini.ReadString(IniSet, 'MCRelaxationFactor','0')  +', _');
    WriteLn(f_scr, '       AnisotropyRatio:='    +Ini.ReadString(IniSet, 'AnisotropyRatio',   '1')  +', _');
    WriteLn(f_scr, '       AnisotropyAngle:='    +Ini.ReadString(IniSet, 'AnisotropyAngle',   '0')  +', _');
  end;
  if IntMethod='srfRadialBasis' then begin
    WriteLn(f_scr, '       AnisotropyRatio:='    +Ini.ReadString(IniSet, 'AnisotropyRatio',   '1')  +', _');
    WriteLn(f_scr, '       AnisotropyAngle:='    +Ini.ReadString(IniSet, 'AnisotropyAngle',   '0')  +', _');
  end;
  if IntMethod='srfTriangulation' then begin
    WriteLn(f_scr, '       AnisotropyRatio:='    +Ini.ReadString(IniSet, 'AnisotropyRatio',   '1')  +', _');
    WriteLn(f_scr, '       AnisotropyAngle:='    +Ini.ReadString(IniSet, 'AnisotropyAngle',   '0')  +', _');
  end;
  if IntMethod='srfInverseDistanse' then begin
    WriteLn(f_scr, '       SearchMinData:='      +Ini.ReadString(IniSet, 'SearchMinData',     '16') +', _');
    WriteLn(f_scr, '       SearchRad1:='         +FloattoStr(SearchRad1)    +', _');
    WriteLn(f_scr, '       SearchRad2:='         +FloattoStr(SearchRad2)    +', _');
    WriteLn(f_scr, '       SearchAngle:='        +Ini.ReadString(IniSet, 'SearchAngle',       '0')  +', _');
  end;
    WriteLn(f_scr, '       DupMethod:=srfDupNone, _');
    WriteLn(f_scr, '       ExclusionFilter:="z=' +Ini.ReadString(IniSet, 'MissingVal', '-9999')+'", _');
    WriteLn(f_scr, '       ShowReport:=False, _');
    WriteLn(f_scr, '       OutGrid:=PathGRDVal)');
    WriteLn(f_scr, '');

    (* Бланкуем по берегам *)
    WriteLn(f_scr, 'Surfer.GridBlank(InGrid:=PathGRDVal, _');
    WriteLn(f_scr, '       BlankFile:=pathBlankMap, _');
    WriteLn(f_scr, '       OutGrid:=PathGRDVal, _');
    WriteLn(f_scr, '       OutFmt:=1)');
    WriteLn(f_scr, '');

   (* Бланкуем по доп. топографии *)
  {  if basemap2<>'' then begin
    WriteLn(f_scr, 'Surfer.GridBlank(InGrid:=PathGRD, _');
    WriteLn(f_scr, '       BlankFile:=pathBlankMap2, _');
    WriteLn(f_scr, '       OutGrid:=PathGRD, _');
    WriteLn(f_scr, '       OutFmt:=1)');
    WriteLn(f_scr, '');
    end; }

    (* Filtering *)
   if Ini.ReadInteger(IniSet, 'Filter', 10)>0 then begin
    WriteLn(f_scr, 'Surfer.GridFilter(InGrid:=PathGRDVal, _');
		WriteLn(f_scr, '  Filter:=srfFilterGaussian, _');
		WriteLn(f_scr, '  NumPasses:='+Ini.ReadString(IniSet, 'Filter', '10')+', _');    //число прогонов из формы
		WriteLn(f_scr, '  OutGrid:=PathGRDVal)');
    WriteLn(f_scr, '');
   end;

   (* Вставляем основной контур *)
   WriteLn(f_scr, 'Set ContourMap=Doc.Shapes.AddContourMap(PathGRDVal)');
   WriteLn(f_scr, 'Set Axes = ContourMap.Axes');

   if polar=false then begin
   (* Убираем верхние и боковые метки с основного плота*)
   WriteLn(f_scr, 'Set Axis = Axes("top axis")');
   WriteLn(f_scr, 'Axis.ShowLabels=False');
   WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
   WriteLn(f_scr, 'Axis.MajorTickLength=0');
   WriteLn(f_scr, 'Axis.LabelFont.Size=8');
   WriteLn(f_scr, 'Axis.LabelFormat.Postfix="'+#176+'"');
   WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack');
   WriteLn(f_scr, 'Axis.SetScale('+
     floattostr(XMin)+','+
     floattostr(XMax)+','+
     '20,'+
     floattostr(XMin)+','+
     floattostr(XMax)+','+
     floattostr(YMax)+','+
     '0)');
   WriteLn(f_scr, '');

   WriteLn(f_scr, 'Set Axis = Axes("bottom axis")');
   WriteLn(f_scr, 'Axis.ShowLabels=True');
   WriteLn(f_scr, 'Axis.MajorGridLine.ForeColorRGBA.Color =srfColorBlack');
   WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
   WriteLn(f_scr, 'Axis.MajorTickLength=1E-1');
   WriteLn(f_scr, 'Axis.LabelFont.Size=8');
   WriteLn(f_scr, 'Axis.LabelFormat.Postfix="'+#176+'"');
   WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack');
   WriteLn(f_scr, 'Axis.SetScale('+
     floattostr(XMin)+','+
     floattostr(XMax)+','+
     '20,'+
     floattostr(XMin)+','+
     floattostr(XMax)+','+
     floattostr(YMin)+','+
     '0)');
   WriteLn(f_scr, '');

   WriteLn(f_scr, 'Set Axis = Axes("right axis")');
   WriteLn(f_scr, 'Axis.ShowLabels=False');
   WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
   WriteLn(f_scr, 'Axis.MajorTickLength=0');
   WriteLn(f_scr, 'Axis.LabelFont.Size=8');
   WriteLn(f_scr, 'Axis.LabelFormat.Postfix="'+#176+'"');
   WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack');   //srfColorBlack50
   WriteLn(f_scr, 'Axis.SetScale('+
     floattostr(YMin)+','+
     floattostr(YMax)+','+
     '5,'+
     // '5,'+
     floattostr(YMin)+','+
     floattostr(YMax)+','+
     floattostr(XMax)+','+
     '0)');
   WriteLn(f_scr, '');

   WriteLn(f_scr, 'Set Axis = Axes("left axis")');
   WriteLn(f_scr, 'Axis.ShowLabels=True');
   WriteLn(f_scr, 'Axis.MajorGridLine.ForeColorRGBA.Color =srfColorBlack');
   WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
   WriteLn(f_scr, 'Axis.MajorTickLength=1E-1');
   WriteLn(f_scr, 'Axis.LabelFont.Size=8');
   WriteLn(f_scr, 'Axis.LabelFormat.Postfix="'+#176+'"');
   WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack');
   WriteLn(f_scr, 'Axis.SetScale('+
     floattostr(YMin)+','+
     floattostr(YMax)+','+
     '5,'+
     // '5,'+
     floattostr(YMin)+','+
     floattostr(YMax)+','+
     floattostr(XMin)+','+
     '0)');
   end;

   if polar=true then begin
    WriteLn(f_scr, 'Set Axis = Axes("top axis")');
    WriteLn(f_scr, 'Axis.Visible=False');
    WriteLn(f_scr, '');
    WriteLn(f_scr, 'Set Axis = Axes("bottom axis")');
    WriteLn(f_scr, 'Axis.Visible=False');
    WriteLn(f_scr, '');
    WriteLn(f_scr, 'Set Axis = Axes("right axis")');
    WriteLn(f_scr, 'Axis.Visible=False');
    WriteLn(f_scr, '');
    WriteLn(f_scr, 'Set Axis = Axes("left axis")');
    WriteLn(f_scr, 'Axis.Visible=False');
   end;
   WriteLn(f_scr, '');

    (* Пост со значениями*)
   WriteLn(f_scr, 'Set PostMap=Doc.Shapes.AddPostMap(DataFileName:=pathDataFile, _');
   WriteLn(f_scr, 'xCol:=2, _');
   WriteLn(f_scr, 'yCol:=1)');
   WriteLn(f_scr, 'Set sampleMarks = PostMap.Overlays(1)');
   WriteLn(f_scr, 'With SampleMarks');
   WriteLn(f_scr, '  .Visible=False');
   WriteLn(f_scr, '  .LabelFont.Size=2');
   WriteLn(f_scr, '  .Symbol.Index=12');
   WriteLn(f_scr, '  .Symbol.Size=0.02');
   WriteLn(f_scr, '  .Symbol.Color=srfColorPurple');
   WriteLn(f_scr, '  .LabelAngle=0');
   WriteLn(f_scr, 'End With');
   WriteLn(f_scr, '');

   (* Пост со льдом *)
   if iceplot=true then begin
   WriteLn(f_scr, 'Set PostMap=Doc.Shapes.AddPostMap(DataFileName:=pathIceData, _');
   WriteLn(f_scr, 'xCol:=2, _');
   WriteLn(f_scr, 'yCol:=1)');
   WriteLn(f_scr, 'Set sampleMarks = PostMap.Overlays(1)');
   WriteLn(f_scr, 'With SampleMarks');
   WriteLn(f_scr, '  .Visible=False');
   WriteLn(f_scr, '  .Symbol.Index=10');
   WriteLn(f_scr, '  .Symbol.Size=0.2');
   WriteLn(f_scr, '  .Symbol.Color=srfColorWhite');
   WriteLn(f_scr, '  .LabelAngle=0');
   WriteLn(f_scr, 'End With');
   WriteLn(f_scr, '');

    WriteLn(f_scr, 'Surfer.GridData(DataFile:=pathIceData, _');
    WriteLn(f_scr, '       xCol:=2, _');
    WriteLn(f_scr, '       yCol:=1, _');
    WriteLn(f_scr, '       zCol:=3, _');
    WriteLn(f_scr, '       Algorithm:=srfKriging, _');
    WriteLn(f_scr, '       NumCols:=360, _');
    WriteLn(f_scr, '       Numrows:=180, _');
    WriteLn(f_scr, '       KrigType:=srfKrigPoint, _');
    WriteLn(f_scr, '       KrigDriftType:=srfDriftNone, _');
    WriteLn(f_scr, '       DupMethod:=srfDupNone, _');
    WriteLn(f_scr, '       ShowReport:=False, _');
    WriteLn(f_scr, '       OutGrid:=PathGRDIce)');
    WriteLn(f_scr, '');

    WriteLn(f_scr, 'Set IceContour=Doc.Shapes.AddContourMap(PathGRDIce)');
    WriteLn(f_scr, 'Set IceContour1 = IceContour.Overlays(1) ');
    WriteLn(f_scr, '    IceContour1.Levels.LoadFile("'+levice+'")');
    WriteLn(f_scr, '');
   end;

   (* Определяем размеры поля *)
   WriteLn(f_scr, 'Doc.Shapes.SelectAll');
   WriteLn(f_scr, 'Set Border = Doc.Selection.OverlayMaps');
   WriteLn(f_scr, 'X1='+Floattostr(XMin));
   WriteLn(f_scr, 'X2='+Floattostr(XMax));
   WriteLn(f_scr, 'Y1='+Floattostr(YMin));
   WriteLn(f_scr, 'Y2='+Floattostr(YMax));
   WriteLn(f_scr, '');

  (* Карта - подложка: дополнительный контур с топографией *)
  if basemap2<>'' then begin
   WriteLn(f_scr, 'Set BaseMap=Doc.Shapes.AddBaseMap(pathBlankMap2)');
   WriteLn(f_scr, 'Set BaseMap2 = BaseMap.Overlays(1)');
    if Ini.ReadBool(IniSet, 'ContBackground', true)=true then begin
     WriteLn(f_scr, 'BaseMap2.Fill.Pattern="Solid"');
     WriteLn(f_scr, 'BaseMap2.Line.Style = "Invisible"');
     WriteLn(f_scr, 'BaseMap2.Fill.ForeColor=srfColorBlack10');
     WriteLn(f_scr, '');
    end;
  end;

   (* Карта - подложка: берега на нулевой изобате *)
  if Contour<>'' then begin
   WriteLn(f_scr, 'Set BaseMap=Doc.Shapes.AddBaseMap(pathBlankMap)');
   WriteLn(f_scr, 'Set BaseMap1 = BaseMap.Overlays(1)');
    if Ini.ReadBool(IniSet, 'ContBackground', true)=true then begin
     WriteLn(f_scr, 'BaseMap1.Fill.Pattern="Solid"');
     WriteLn(f_scr, 'BaseMap1.Fill.ForeColor=srfColorBlack40');
     WriteLn(f_scr, 'BaseMap1.Line.ForeColorRGBA.Color=srfColorBlack80');
     WriteLn(f_scr, '');
    end;
  end;

  if Polar=true then begin
   WriteLn(f_scr, 'Set BaseMap=Doc.Shapes.AddBaseMap(pathPolarGrd)');
   WriteLn(f_scr, 'Set BaseMap1 = BaseMap.Overlays(1)');
   WriteLn(f_scr, 'BaseMap1.Line.ForeColorRGBA.Color=srfColorBlack50');
   WriteLn(f_scr, '');
  end;

   (* Объединяем и задаём общие свойства *)
   WriteLn(f_scr, 'Doc.Shapes.SelectAll');
   WriteLn(f_scr, 'Set NewMap = Doc.Selection.OverlayMaps');
   WriteLn(f_scr, 'With NewMap');
   WriteLn(f_scr, '  .SetLimits(xMin:=X1, xMax:=X2, yMin:=Y1, yMax:=Y2)');
   if polar=false then begin
     WriteLn(f_scr, '  .xLength= 15');
     WriteLn(f_scr, '  .yLength= 8');
     WriteLn(f_scr, '  .Top= 26');
     WriteLn(f_scr, '  .Left= 2');
     WriteLn(f_scr, '  .BackgroundFill.Pattern = "10 Percent"');
     WriteLn(f_scr, '  .BackgroundFill.ForeColor = srfGold');
   end;
   if polar=true then begin
    WriteLn(f_scr, '  .xLength= 12');
    WriteLn(f_scr, '  .yLength= 12');
    WriteLn(f_scr, '  .Top= 26.5');
    WriteLn(f_scr, '  .Left= 5');
   end;
   WriteLn(f_scr, '    L = .Left');
   WriteLn(f_scr, '    B = .Top-.Height');
   WriteLn(f_scr, 'End With');
   WriteLn(f_scr, '');

   WriteLn(f_scr, 'Set ContourMap = NewMap.Overlays(1)');
   WriteLn(f_scr, 'With ContourMap');
   WriteLn(f_scr, '  .FillContours = True');
   WriteLn(f_scr, '  .ShowColorScale = True');
   WriteLn(f_scr, '  .ColorScale.Top = NewMap.Top-1');
   if polar=false then begin
     WriteLn(f_scr, '  .ColorScale.Left = NewMap.Left+NewMap.Width+0.4');
     WriteLn(f_scr, '  .ColorScale.Height = NewMap.Height-0.8');
   end;
   if polar=true  then begin
     WriteLn(f_scr, '  .ColorScale.Left = NewMap.Left+NewMap.Width+1');
   end;

   WriteLn(f_scr, '  .ColorScale.FrameLine.Style = "Invisible"');
   WriteLn(f_scr, '  .ColorScale.LabelFrequency=20');
   (* Заливаем контур *)
   if lev1<>'' then
   WriteLn(f_scr, '  .Levels.LoadFile("'+lev1+'")');
   (* Добавляем цвет в контуры *)
   if clr1<>'' then
   WriteLn(f_scr, '  .FillForegroundColorMap.LoadFile("'+clr1+'")');
   WriteLn(f_scr, '  .LabelLabelDist ='+Ini.ReadString(IniSet, 'LevelToEdgeDist',  '1'));
   WriteLn(f_scr, '  .LabelEdgeDist  ='+Ini.ReadString(IniSet, 'LevelToLevelDist', '1'));
   WriteLn(f_scr, '  .LabelTolerance ='+Ini.ReadString(IniSet, 'CurveTolerance',   '15E-1'));
   WriteLn(f_scr, '  .LabelFont.Size = 6');
   WriteLn(f_scr, '  .Levels.SetLabelFrequency('+
                     'FirstIndex  :='+Ini.ReadString(IniSet, 'LevelFirst', '1')+','+
                     'NumberToSet :='+Ini.ReadString(IniSet, 'LevelSet',   '1')+','+
                     'NumberToSkip:='+Ini.ReadString(IniSet, 'LevelSkip',  '9')+')');
   WriteLn(f_scr, 'End With');
   WriteLn(f_scr, '');

(****************************  ERROR FIELD  ***********************************)
   WriteLn(f_scr, 'Set Doc2=Surfer.Documents.Add');
   WriteLn(f_scr, 'Set Diagram2 = Doc2.Windows(1)');
   WriteLn(f_scr, '    Diagram2.AutoRedraw = False');

 (* Гридируем данные *)
    WriteLn(f_scr, 'Surfer.GridData(DataFile:=pathDataFile, _');
    WriteLn(f_scr, '       xCol:=2, _');
    WriteLn(f_scr, '       yCol:=1, _');
    WriteLn(f_scr, '       zCol:=4, _');
    WriteLn(f_scr, '       Algorithm:='        +IntMethod+', _');
    WriteLn(f_scr, '       NumCols:='          +inttostr(high(ncLon_arr)+1)+', _');
    WriteLn(f_scr, '       Numrows:='          +inttostr(high(ncLat_arr)+1)+', _');

(* Настройки для различных методов интерполяции *)
  if IntMethod='srfKriging'  then begin
    WriteLn(f_scr, '       KrigType:='         +Ini.ReadString(IniSet, 'KrigType',          'srfKrigPoint')+', _');
    WriteLn(f_scr, '       KrigDriftType:='    +Ini.ReadString(IniSet, 'KrigDriftType',     'srfDriftNone')+', _');
     if Ini.ReadBool(IniSet, 'SearchEnable', true)=true then begin
      WriteLn(f_scr, '       SearchEnable:=1, _');
      WriteLn(f_scr, '       SearchNumSectors:=' +Ini.ReadString(IniSet, 'SearchNumSectors',  '4')  +', _');
      WriteLn(f_scr, '       SearchMinData:='    +Ini.ReadString(IniSet, 'SearchMinData',     '16') +', _');
      WriteLn(f_scr, '       SearchMaxData:='    +Ini.ReadString(IniSet, 'SearchMaxData',     '64') +', _');
      WriteLn(f_scr, '       SearchDataPerSect:='+Ini.ReadString(IniSet, 'SearchDataPerSect', '8')  +', _');
      WriteLn(f_scr, '       SearchMaxEmpty:='   +Ini.ReadString(IniSet, 'SearchMaxEmpty',    '3')  +', _');
      WriteLn(f_scr, '       SearchRad1:='       +FloattoStr(SearchRad1)    +', _');
      WriteLn(f_scr, '       SearchRad2:='       +FloattoStr(SearchRad2)    +', _');
      WriteLn(f_scr, '       SearchAngle:='      +Ini.ReadString(IniSet, 'SearchAngle',       '0')  +', _');
     end;
  end;
  if IntMethod='srfInverseDistanse' then begin
    WriteLn(f_scr, '       SearchEnable:='       +Ini.ReadString(IniSet, 'SearchEnable',      '0')  +', _');
    WriteLn(f_scr, '       SearchNumSectors:='   +Ini.ReadString(IniSet, 'SearchNumSectors',  '4')  +', _');
    WriteLn(f_scr, '       SearchMinData:='      +Ini.ReadString(IniSet, 'SearchMinData',     '16') +', _');
    WriteLn(f_scr, '       SearchMaxData:='      +Ini.ReadString(IniSet, 'SearchMaxData',     '64') +', _');
    WriteLn(f_scr, '       SearchDataPerSect:='  +Ini.ReadString(IniSet, 'SearchDataPerSect', '8')  +', _');
    WriteLn(f_scr, '       SearchMaxEmpty:='     +Ini.ReadString(IniSet, 'SearchMaxEmpty',    '3')  +', _');
    WriteLn(f_scr, '       SearchRad1:='         +FloattoStr(SearchRad1)    +', _');
    WriteLn(f_scr, '       SearchRad2:='         +FloattoStr(SearchRad2)    +', _');
    WriteLn(f_scr, '       SearchAngle:='        +Ini.ReadString(IniSet, 'SearchAngle',       '0')  +', _');
    WriteLn(f_scr, '       AnisotropyRatio:='    +Ini.ReadString(IniSet, 'AnisotropyRatio',   '1')  +', _');
    WriteLn(f_scr, '       AnisotropyAngle:='    +Ini.ReadString(IniSet, 'AnisotropyAngle',   '0')  +', _');
    WriteLn(f_scr, '       IDPower:='            +Ini.ReadString(IniSet, 'IDPower',           '2')  +', _');
    WriteLn(f_scr, '       IDSmoothing:='        +Ini.ReadString(IniSet, 'IDSmoothing',       '0')  +', _');
  end;
  if IntMethod='srfNaturalNeighbor' then begin
    WriteLn(f_scr, '       AnisotropyRatio:='    +Ini.ReadString(IniSet, 'AnisotropyRatio',   '1')  +', _');
    WriteLn(f_scr, '       AnisotropyAngle:='    +Ini.ReadString(IniSet, 'AnisotropyAngle',   '0')  +', _');
  end;
  if IntMethod='srfNearestNeighbor' then begin
    WriteLn(f_scr, '       SearchRad1:='         +FloattoStr(SearchRad1)    +', _');
    WriteLn(f_scr, '       SearchRad2:='         +FloattoStr(SearchRad2)    +', _');
    WriteLn(f_scr, '       SearchAngle:='        +Ini.ReadString(IniSet, 'SearchAngle',       '0')  +', _');
  end;
  if IntMethod='srfMinCurvature' then begin
    WriteLn(f_scr, '       MCMaxResidual:='      +Ini.ReadString(IniSet, 'MCMaxResidual',     '1E-9')+', _');
    WriteLn(f_scr, '       MCMaxIterations:='    +Ini.ReadString(IniSet, 'MCMaxIterations',   '1E+5')+', _');
    WriteLn(f_scr, '       MCInternalTension:='  +Ini.ReadString(IniSet, 'MCInternalTension', '1')  +', _');
    WriteLn(f_scr, '       MCBoundaryTension:='  +Ini.ReadString(IniSet, 'MCBoundaryTension', '0')  +', _');
    WriteLn(f_scr, '       MCRelaxationFactor:=' +Ini.ReadString(IniSet, 'MCRelaxationFactor','0')  +', _');
    WriteLn(f_scr, '       AnisotropyRatio:='    +Ini.ReadString(IniSet, 'AnisotropyRatio',   '1')  +', _');
    WriteLn(f_scr, '       AnisotropyAngle:='    +Ini.ReadString(IniSet, 'AnisotropyAngle',   '0')  +', _');
  end;
  if IntMethod='srfRadialBasis' then begin
    WriteLn(f_scr, '       AnisotropyRatio:='    +Ini.ReadString(IniSet, 'AnisotropyRatio',   '1')  +', _');
    WriteLn(f_scr, '       AnisotropyAngle:='    +Ini.ReadString(IniSet, 'AnisotropyAngle',   '0')  +', _');
  end;
  if IntMethod='srfTriangulation' then begin
    WriteLn(f_scr, '       AnisotropyRatio:='    +Ini.ReadString(IniSet, 'AnisotropyRatio',   '1')  +', _');
    WriteLn(f_scr, '       AnisotropyAngle:='    +Ini.ReadString(IniSet, 'AnisotropyAngle',   '0')  +', _');
  end;
  if IntMethod='srfInverseDistanse' then begin
    WriteLn(f_scr, '       SearchMinData:='      +Ini.ReadString(IniSet, 'SearchMinData',     '16') +', _');
    WriteLn(f_scr, '       SearchRad1:='         +FloattoStr(SearchRad1)    +', _');
    WriteLn(f_scr, '       SearchRad2:='         +FloattoStr(SearchRad2)    +', _');
    WriteLn(f_scr, '       SearchAngle:='        +Ini.ReadString(IniSet, 'SearchAngle',       '0')  +', _');
  end;
    WriteLn(f_scr, '       DupMethod:=srfDupNone, _');
    WriteLn(f_scr, '       ExclusionFilter:="z='+Ini.ReadString(IniSet, 'MissingVal', '-9999')+'", _');
    WriteLn(f_scr, '       ShowReport:=False, _');
    WriteLn(f_scr, '       OutGrid:=PathGRDErr)');
    WriteLn(f_scr, '');

    (* Бланкуем по берегам *)
    WriteLn(f_scr, 'Surfer.GridBlank(InGrid:=PathGRDErr, _');
    WriteLn(f_scr, '       BlankFile:=pathBlankMap, _');
    WriteLn(f_scr, '       OutGrid:=PathGRDErr, _');
    WriteLn(f_scr, '       OutFmt:=1)');

    (* Бланкуем по доп. топографии *)
  {  if basemap2<>'' then begin
    WriteLn(f_scr, 'Surfer.GridBlank(InGrid:=PathGRD, _');
    WriteLn(f_scr, '       BlankFile:=pathBlankMap2, _');
    WriteLn(f_scr, '       OutGrid:=PathGRD, _');
    WriteLn(f_scr, '       OutFmt:=1)');
    WriteLn(f_scr, '');
    end;   }

    (* Filtering *)
   if Ini.ReadInteger(IniSet, 'Filter', 0)>0 then begin
    WriteLn(f_scr, 'Surfer.GridFilter(InGrid:=PathGRDErr, _');
		WriteLn(f_scr, '  Filter:=srfFilterGaussian, _');
		WriteLn(f_scr, '  NumPasses:='+Ini.ReadString(IniSet, 'Filter', '1')+', _');    //число прогонов из формы
		WriteLn(f_scr, '  OutGrid:=PathGRDErr)');
    WriteLn(f_scr, '');
   end;

   (* Вставляем основной контур *)
   WriteLn(f_scr, 'Set ContourMap=Doc2.Shapes.AddContourMap(PathGRDErr)');
   WriteLn(f_scr, 'Set Axes = ContourMap.Axes');

   if polar=false then begin
   (* Убираем верхние и боковые метки с основного плота*)
   WriteLn(f_scr, 'Set Axis = Axes("top axis")');
   WriteLn(f_scr, 'Axis.ShowLabels=False');
   WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
   WriteLn(f_scr, 'Axis.MajorTickLength=0'); //1E-1
   WriteLn(f_scr, 'Axis.LabelFont.Size=8');
   WriteLn(f_scr, 'Axis.LabelFormat.Postfix="'+#176+'"');
   WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack');
   WriteLn(f_scr, 'Axis.SetScale('+
     floattostr(XMin)+','+
     floattostr(XMax)+','+
     '20,'+
     floattostr(XMin)+','+
     floattostr(XMax)+','+
     floattostr(YMax)+','+
     '0)');
   WriteLn(f_scr, '');

   WriteLn(f_scr, 'Set Axis = Axes("bottom axis")');
   WriteLn(f_scr, 'Axis.ShowLabels=True');
   WriteLn(f_scr, 'Axis.MajorGridLine.ForeColorRGBA.Color =srfColorBlack');
   WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
   WriteLn(f_scr, 'Axis.MajorTickLength=1E-1');
   WriteLn(f_scr, 'Axis.LabelFont.Size=8');
   WriteLn(f_scr, 'Axis.LabelFormat.Postfix="'+#176+'"');
   WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack');
   WriteLn(f_scr, 'Axis.SetScale('+
     floattostr(XMin)+','+
     floattostr(XMax)+','+
     '20,'+
     floattostr(XMin)+','+
     floattostr(XMax)+','+
     floattostr(YMin)+','+
     '0)');
   WriteLn(f_scr, '');

   WriteLn(f_scr, 'Set Axis = Axes("right axis")');
   WriteLn(f_scr, 'Axis.ShowLabels=False');
   WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
   WriteLn(f_scr, 'Axis.MajorTickLength=0');
   WriteLn(f_scr, 'Axis.LabelFont.Size=8');
   WriteLn(f_scr, 'Axis.LabelFormat.Postfix="'+#176+'"');
   WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack');
   WriteLn(f_scr, 'Axis.SetScale('+
     floattostr(YMin)+','+
     floattostr(YMax)+','+
     '5,'+
     floattostr(YMin)+','+
     floattostr(YMax)+','+
     floattostr(XMax)+','+
     '0)');
   WriteLn(f_scr, '');

   WriteLn(f_scr, 'Set Axis = Axes("left axis")');
   WriteLn(f_scr, 'Axis.ShowLabels=True');
   WriteLn(f_scr, 'Axis.MajorGridLine.ForeColorRGBA.Color =srfColorBlack');
   WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
   WriteLn(f_scr, 'Axis.MajorTickLength=1E-1');
   WriteLn(f_scr, 'Axis.LabelFont.Size=8');
   WriteLn(f_scr, 'Axis.LabelFormat.Postfix="'+#176+'"');
   WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack');
   WriteLn(f_scr, 'Axis.SetScale('+
     floattostr(YMin)+','+
     floattostr(YMax)+','+
     '5,'+
     floattostr(YMin)+','+
     floattostr(YMax)+','+
     floattostr(XMin)+','+
     '0)');
   end;

   if polar=true then begin
    WriteLn(f_scr, 'Set Axes = ContourMap.Axes');
    WriteLn(f_scr, 'Set Axis = Axes("top axis")');
    WriteLn(f_scr, 'Axis.Visible=False');
    WriteLn(f_scr, '');
    WriteLn(f_scr, 'Set Axis = Axes("bottom axis")');
    WriteLn(f_scr, 'Axis.Visible=False');
    WriteLn(f_scr, '');
    WriteLn(f_scr, 'Set Axis = Axes("right axis")');
    WriteLn(f_scr, 'Axis.Visible=False');
    WriteLn(f_scr, '');
    WriteLn(f_scr, 'Set Axis = Axes("left axis")');
    WriteLn(f_scr, 'Axis.Visible=False');
   end;
   WriteLn(f_scr, '');

    (* Пост со значениями*)
   WriteLn(f_scr, 'Set PostMap=Doc2.Shapes.AddPostMap(DataFileName:=pathDataFile, _');
   WriteLn(f_scr, 'xCol:=2, _');
   WriteLn(f_scr, 'yCol:=1)');
   WriteLn(f_scr, 'Set sampleMarks = PostMap.Overlays(1)');
   WriteLn(f_scr, 'With SampleMarks');
   WriteLn(f_scr, '  .Visible=False');
   WriteLn(f_scr, '  .LabelFont.Size=2');
   WriteLn(f_scr, '  .Symbol.Index=12');
   WriteLn(f_scr, '  .Symbol.Size=0.02');
   WriteLn(f_scr, '  .Symbol.Color=srfColorBlue');
   WriteLn(f_scr, '  .LabelAngle=0');
   WriteLn(f_scr, 'End With');
   WriteLn(f_scr, '');

   (* Вставляем дополнительный грид с начальными данными *)
   if IniDat<>'' then begin
   WriteLn(f_scr, 'Set AuxPostMap=Doc2.Shapes.AddPostMap(DataFileName:=pathIniData, _');
   WriteLn(f_scr, 'xCol:=1, _');
   WriteLn(f_scr, 'yCol:=2)');
   WriteLn(f_scr, 'Set sampleMarks = AuxPostMap.Overlays(1)');
   WriteLn(f_scr, 'With SampleMarks');
   WriteLn(f_scr, '  .Visible=False');
   WriteLn(f_scr, '  .LabelFont.Size=2');
   WriteLn(f_scr, '  .Symbol.Index=12');
   WriteLn(f_scr, '  .Symbol.Size=0.02');
   WriteLn(f_scr, '  .Symbol.Color=srfColorRubyRed');
   WriteLn(f_scr, 'End With');
   WriteLn(f_scr, '');
   end;

   (* Определяем размеры поля *)
   WriteLn(f_scr, 'Doc2.Shapes.SelectAll');
   WriteLn(f_scr, 'Set Border = Doc2.Selection.OverlayMaps');
   WriteLn(f_scr, 'X1='+Floattostr(XMin));
   WriteLn(f_scr, 'X2='+Floattostr(XMax));
   WriteLn(f_scr, 'Y1='+Floattostr(YMin));
   WriteLn(f_scr, 'Y2='+Floattostr(YMax));
   WriteLn(f_scr, '');

  (* Карта - подложка: дополнительный контур с топографией *)
  if basemap2<>'' then begin
   WriteLn(f_scr, 'Set BaseMap=Doc2.Shapes.AddBaseMap(pathBlankMap2)');
   WriteLn(f_scr, 'Set BaseMap2 = BaseMap.Overlays(1)');
    if Ini.ReadBool(IniSet, 'ContBackground', true)=true then begin
     WriteLn(f_scr, 'BaseMap2.Fill.Pattern="Solid"');
     WriteLn(f_scr, 'BaseMap2.Line.Style = "Invisible"');
     WriteLn(f_scr, 'BaseMap2.Fill.ForeColor=srfColorBlack10');
    // WriteLn(f_scr, 'BaseMap2.Line.ForeColorRGBA.Color =RGB(76,121,150)');
     WriteLn(f_scr, '');
    end;
  end;

   (* Карта - подложка: берега на нулевой изобате *)
  if Contour<>'' then begin
   WriteLn(f_scr, 'Set BaseMap=Doc2.Shapes.AddBaseMap(pathBlankMap)');
   WriteLn(f_scr, 'Set BaseMap1 = BaseMap.Overlays(1)');
    if Ini.ReadBool(IniSet, 'ContBackground', true)=true then begin
     WriteLn(f_scr, 'BaseMap1.Fill.Pattern="Solid"');
     WriteLn(f_scr, 'BaseMap1.Fill.ForeColor=srfColorBlack40');
     WriteLn(f_scr, 'BaseMap1.Line.ForeColorRGBA.Color=srfColorBlack80');
     WriteLn(f_scr, '');
    end;
  end;

  if Polar=true then begin
   WriteLn(f_scr, 'Set BaseMap=Doc2.Shapes.AddBaseMap(pathPolarGrd)');
   WriteLn(f_scr, 'Set BaseMap1 = BaseMap.Overlays(1)');
   WriteLn(f_scr, 'BaseMap1.Line.ForeColorRGBA.Color=srfColorBlack50');
   WriteLn(f_scr, '');
  end;

    (* Объединяем и задаём общие свойства *)
   WriteLn(f_scr, 'Doc2.Shapes.SelectAll');
   WriteLn(f_scr, 'Set NewMap = Doc2.Selection.OverlayMaps');
   WriteLn(f_scr, 'With NewMap');
   WriteLn(f_scr, '  .SetLimits(xMin:=X1, xMax:=X2, yMin:=Y1, yMax:=Y2)');
   if polar=false then begin
     WriteLn(f_scr, '  .xLength= 15');
     WriteLn(f_scr, '  .yLength= 8');
     WriteLn(f_scr, '  .BackgroundFill.Pattern = "10 Percent"');
     WriteLn(f_scr, '  .BackgroundFill.ForeColor = srfGold');
   end;
   if polar=true then begin
    WriteLn(f_scr, '  .xLength= 12');
    WriteLn(f_scr, '  .yLength= 12');
   end;
   WriteLn(f_scr, '    L = .Left');
   WriteLn(f_scr, '    B = .Top-.Height');
   WriteLn(f_scr, 'End With');
   WriteLn(f_scr, '');

   WriteLn(f_scr, 'Set ContourMap = NewMap.Overlays(1)');
   WriteLn(f_scr, 'With ContourMap');
   WriteLn(f_scr, '  .FillContours = True');
   WriteLn(f_scr, '  .ShowColorScale = True');
   WriteLn(f_scr, '  .ColorScale.Top = NewMap.Top-0.4');
   if polar=false then begin
     WriteLn(f_scr, '  .ColorScale.Left = NewMap.Left+NewMap.Width+0.4');
     WriteLn(f_scr, '  .ColorScale.Height = NewMap.Height-0.8');
   end;
   if polar=true  then begin
     WriteLn(f_scr, '  .ColorScale.Left = NewMap.Left+NewMap.Width+1');
   end;

   WriteLn(f_scr, '  .ColorScale.FrameLine.Style = "Invisible"');
   WriteLn(f_scr, '  .ColorScale.LabelFrequency=10 '); //label frequency
   (* Заливаем контур *)
   if lev1<>'' then
   WriteLn(f_scr, '  .Levels.LoadFile("'+lev2+'")');

   (* Добавляем цвет в контуры *)
   if clr1<>'' then
   WriteLn(f_scr, '  .FillForegroundColorMap.LoadFile("'+clr2+'")');
   WriteLn(f_scr, '    .LabelLabelDist =1');
   WriteLn(f_scr, '    .LabelEdgeDist  =1');
   WriteLn(f_scr, '    .LabelTolerance =15E-1');
   WriteLn(f_scr, '    .LabelFont.Size = 6');
 //  WriteLn(f_scr, '    .Levels.SetLabelFrequency(FirstIndex  :=1,NumberToSet :=1,NumberToSkip:=9)');
   WriteLn(f_scr, 'End With');
   WriteLn(f_scr, '');

  WriteLn(f_scr, ' Doc2.Shapes.SelectAll');
  WriteLn(f_scr, ' Doc2.Selection.Copy');

  WriteLn(f_scr, ' Set selection2 =Doc.Shapes.Paste(Format:=srfPasteBest)');
  WriteLn(f_scr, ' With selection2');
  if polar=false then begin
    WriteLn(f_scr, '  .Top  = 17');
    WriteLn(f_scr, '  .Left = 2');
  end;
  if polar=true then begin
    WriteLn(f_scr, '  .Top  = 13.25');
    WriteLn(f_scr, '  .Left = 5');
  end;
  WriteLn(f_scr, ' End With');
 WriteLn(f_scr, 'Doc2.Close(SaveChanges:=srfSaveChangesNo)');
 WriteLn(f_scr, '');

 (***********************Окончание второго плота********************************)



  // Вставляем легенду
 if legend=true then begin
   WriteLn(f_scr, '');
   WriteLn(f_scr, ' Set Rectangle = Doc.Shapes.AddRectangle(Left:=13.8, Top:=19.8, Right:=17.45, Bottom:=18.10)');
   WriteLn(f_scr, '     Rectangle.Fill.Transparent = False');
   WriteLn(f_scr, '     Rectangle.Fill.Pattern = "Solid"');
   WriteLn(f_scr, '     Rectangle.Fill.ForeColorRGBA.Color = srfColorWhite');
   WriteLn(f_scr, '     Rectangle.Line.Style = "Solid"');
   WriteLn(f_scr, '     Rectangle.Line.ForeColorRGBA.Color = srfColorBlack50');
   WriteLn(f_scr, '');
   WriteLn(f_scr, ' Set Rectangle = Doc.Shapes.AddRectangle(Left:=13.85, Top:=19.75, Right:=17.40, Bottom:=18.15)');
   WriteLn(f_scr, '     Rectangle.Fill.Transparent = False');
   WriteLn(f_scr, '     Rectangle.Fill.Pattern = "Solid"');
   WriteLn(f_scr, '     Rectangle.Fill.ForeColorRGBA.Color = srfColorWhite');
   WriteLn(f_scr, '     Rectangle.Line.Style = "Solid"');
   WriteLn(f_scr, '     Rectangle.Line.ForeColorRGBA.Color = srfColorBlack50');
   WriteLn(f_scr, '');
   WriteLn(f_scr, ' Set Label =Doc.Shapes.AddText(x:=14.77, y:=19.70, Text:="'+avpar+' '+avunit+'")');
   WriteLn(f_scr, '     Label.Font.Face = "Arial"');
   WriteLn(f_scr, '     Label.Font.Size=7');
   WriteLn(f_scr, '     Label.Font.Bold=true');
   WriteLn(f_scr, '     Label.Font.ForeColorRGBA.Color = srfColorBlack80');
   WriteLn(f_scr, '');
   WriteLn(f_scr, ' Set Label =Doc.Shapes.AddText(x:=14.55, y:=19.40, Text:="'+avper+' mean: var. '+cvar+'")');
   WriteLn(f_scr, '     Label.Font.Face = "Arial"');
   WriteLn(f_scr, '     Label.Font.Size=7');
   WriteLn(f_scr, '     Label.Font.ForeColorRGBA.Color = srfColorBlack80');
   WriteLn(f_scr, '');
   WriteLn(f_scr, ' Set Label =Doc.Shapes.AddText(x:=14.10, y:=19.10, Text:="Time period: '+period+'")');
   WriteLn(f_scr, '     Label.Font.Face = "Arial"');
   WriteLn(f_scr, '     Label.Font.Size=7');
   WriteLn(f_scr, '     Label.Font.ForeColorRGBA.Color = srfColorBlack80');
   WriteLn(f_scr, '');
   WriteLn(f_scr, ' Set Label =Doc.Shapes.AddText(x:=14.95, y:=18.80, Text:="Depth: '+inttostr(depth)+' m")');
   WriteLn(f_scr, '     Label.Font.Face = "Arial"');
   WriteLn(f_scr, '     Label.Font.Size=7');
   WriteLn(f_scr, '     Label.Font.ForeColorRGBA.Color = srfColorBlack80');
   WriteLn(f_scr, '');
    if cvar='A' then begin
      WriteLn(f_scr, ' Set Label =Doc.Shapes.AddText(x:=14.25, y:=18.50, Text:="Number of stations: '+inttostr(stnum)+'")');
      WriteLn(f_scr, '     Label.Font.Face = "Arial"');
      WriteLn(f_scr, '     Label.Font.Size=7');
      WriteLn(f_scr, '     Label.Font.ForeColorRGBA.Color = srfColorBlack80');
    end;
 end;


 // legend for the second plot
 if (legend=true) then begin
   WriteLn(f_scr, ' Set Rectangle = Doc.Shapes.AddRectangle(Left:=13.80, Top:=10.8, Right:=17.45, Bottom:=9.1)');
   WriteLn(f_scr, '     Rectangle.Fill.Transparent = False');
   WriteLn(f_scr, '     Rectangle.Fill.Pattern = "Solid"');
   WriteLn(f_scr, '     Rectangle.Fill.ForeColorRGBA.Color = srfColorWhite');
   WriteLn(f_scr, '     Rectangle.Line.Style = "Solid"');
   WriteLn(f_scr, '     Rectangle.Line.ForeColorRGBA.Color = srfColorBlack50');
   WriteLn(f_scr, '');
   WriteLn(f_scr, ' Set Rectangle = Doc.Shapes.AddRectangle(Left:=13.85, Top:=10.75, Right:=17.40, Bottom:=9.15)');
   WriteLn(f_scr, '     Rectangle.Fill.Transparent = False');
   WriteLn(f_scr, '     Rectangle.Fill.Pattern = "Solid"');
   WriteLn(f_scr, '     Rectangle.Fill.ForeColorRGBA.Color = srfColorWhite');
   WriteLn(f_scr, '     Rectangle.Line.Style = "Solid"');
   WriteLn(f_scr, '     Rectangle.Line.ForeColorRGBA.Color = srfColorBlack50');
   WriteLn(f_scr, '');
    if cvar='A' then
       WriteLn(f_scr, ' Set Label =Doc.Shapes.AddText(x:=14.35, y:=10.70, Text:="Interpolation error '+avunit+'")');
    if cvar='B' then begin
     if (avpar='Temperature') then  WriteLn(f_scr, ' Set Label =Doc.Shapes.AddText(x:=14.60, y:=10.70, Text:="Error of mean '+avunit+'")');
     if (avpar='Salinity')    then  WriteLn(f_scr, ' Set Label =Doc.Shapes.AddText(x:=14.70, y:=10.70, Text:="Error of mean '+avunit+'")');
     if (avpar='Density')     then  WriteLn(f_scr, ' Set Label =Doc.Shapes.AddText(x:=14.35, y:=10.70, Text:="Error of mean '+avunit+'")');
    end;
   WriteLn(f_scr, '     Label.Font.Face = "Arial"');
   WriteLn(f_scr, '     Label.Font.Size=7');
   WriteLn(f_scr, '     Label.Font.Bold=true');
   WriteLn(f_scr, '     Label.Font.ForeColorRGBA.Color = srfColorBlack80');
   WriteLn(f_scr, '');
   WriteLn(f_scr, ' Set Label =Doc.Shapes.AddText(x:=14.55, y:=10.40, Text:="'+avper+' mean: var.  '+cvar+'")');
   WriteLn(f_scr, '     Label.Font.Face = "Arial"');
   WriteLn(f_scr, '     Label.Font.Size=7');
   WriteLn(f_scr, '     Label.Font.ForeColorRGBA.Color = srfColorBlack80');
   WriteLn(f_scr, '');
   WriteLn(f_scr, ' Set Label =Doc.Shapes.AddText(x:=14.10, y:=10.10, Text:="Time period: '+period+'")');
   WriteLn(f_scr, '     Label.Font.Face = "Arial"');
   WriteLn(f_scr, '     Label.Font.Size=7');
   WriteLn(f_scr, '     Label.Font.ForeColorRGBA.Color = srfColorBlack80');
   WriteLn(f_scr, '');
   WriteLn(f_scr, ' Set Label =Doc.Shapes.AddText(x:=14.95, y:=9.80, Text:="Depth: '+inttostr(depth)+' m")');
   WriteLn(f_scr, '     Label.Font.Face = "Arial"');
   WriteLn(f_scr, '     Label.Font.Size=7');
   WriteLn(f_scr, '     Label.Font.ForeColorRGBA.Color = srfColorBlack80');
   WriteLn(f_scr, '');
    if cvar='A' then begin
      WriteLn(f_scr, ' Set Label =Doc.Shapes.AddText(x:=14.25, y:=9.50, Text:="Number of stations:'+inttostr(stnum)+'")');
      WriteLn(f_scr, '     Label.Font.Face = "Arial"');
      WriteLn(f_scr, '     Label.Font.Size=7');
      WriteLn(f_scr, '     Label.Font.ForeColorRGBA.Color = srfColorBlack80');
    end;
 end;


 // captions for polar grid
 if polar=true then begin
  for k:=1 to 2 do begin
   if k=1 then begin XL:='5'; YL:='26.5'; end;
   if k=2 then begin XL:='5'; YL:='13.25'; end;
    For c:=1 to 18 do begin
     WriteLn(f_scr, '');
     case c of
      1 : WriteLn(f_scr, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+5.75,  y:='+YL+'+0.5,   Text:="180" )');
      2 : WriteLn(f_scr, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+3.5,   y:='+YL+'+0.25,  Text:="-160")');
      3 : WriteLn(f_scr, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+1.25,  y:='+YL+'-1,     Text:="-140")');
      4 : WriteLn(f_scr, 'Set Label =Doc.Shapes.AddText(x:='+XL+',       y:='+YL+'-2.55,  Text:="-120")');
      5 : WriteLn(f_scr, 'Set Label =Doc.Shapes.AddText(x:='+XL+'-0.75,  y:='+YL+'-4.75,  Text:="-100")');
      6 : WriteLn(f_scr, 'Set Label =Doc.Shapes.AddText(x:='+XL+'-0.75,  y:='+YL+'-7,     Text:="-80" )');
      7 : WriteLn(f_scr, 'Set Label =Doc.Shapes.AddText(x:='+XL+',       y:='+YL+'-9,     Text:="-60" )');
      8 : WriteLn(f_scr, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+1.25,  y:='+YL+'-10.75, Text:="-40" )');
      9 : WriteLn(f_scr, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+3.5,   y:='+YL+'-11.75, Text:="-20" )');
      10: WriteLn(f_scr, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+5.9,   y:='+YL+'-12.25, Text:="0"   )');
      11: WriteLn(f_scr, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+8,     y:='+YL+'-11.75, Text:="20"  )');
      12: WriteLn(f_scr, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+10,    y:='+YL+'-10.75, Text:="40"  )');
      13: WriteLn(f_scr, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+11.5,  y:='+YL+'-9,     Text:="60"  )');
      14: WriteLn(f_scr, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+12.25, y:='+YL+'-7,     Text:="80"  )');
      15: WriteLn(f_scr, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+12,    y:='+YL+'-4.75,  Text:="100" )');
      16: WriteLn(f_scr, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+11.25, y:='+YL+'-2.55,  Text:="120" )');
      17: WriteLn(f_scr, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+10,    y:='+YL+'-1,     Text:="140" )');
      18: WriteLn(f_scr, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+8,     y:='+YL+'+0.25,  Text:="160" )');
     end;
     WriteLn(f_scr, '     Label.Font.Face = "Arial"');
     WriteLn(f_scr, '     Label.Font.Size=10');
     WriteLn(f_scr, '     Label.Font.Bold=True');
     WriteLn(f_scr, '     Label.Font.ForeColorRGBA.Color = srfColorBlack80');
    end; //18
   end; // 1 and 2
 end; // polar=true


 if ncExportFile<>'' then begin
   WriteLn(f_scr, 'Doc.Export(FileName:="'+FieldPath+'png\'+ncExportfile+'.png", _');
   WriteLn(f_scr, 'SelectionOnly:=False , Options:="Width=720; KeepAspect=1; HDPI=300; VDPI=300")');
 //  WriteLn(f_scr, 'SelectionOnly:=False , Options:="Width=720; Height=720; KeepAspect=1")');
   WriteLn(f_scr, '');
 end;

   WriteLn(f_scr, 'Diagram.Zoom(srfZoomFitToWindow)');
   WriteLn(f_scr, 'Diagram.AutoRedraw = True');


  WriteLn(f_scr, 'Doc.SaveAs(FileName:="'+FieldPath+'srf\'+ncExportfile+'.srf")');
 if ncFieldsAuto=true then begin
  WriteLn(f_scr, 'Doc.Close(SaveChanges:=srfSaveChangesNo) ');
 end;

  WriteLn(f_scr, 'End Sub');

 finally
   Ini.Free; // close settings file
   CloseFile(f_scr); // close script file
 end;
end;


end.

