unit surfer_climsections;

{$mode objfpc}{$H+}

interface

Uses sysutils, IniFiles, dialogs, ncmain, ncprocedures;


(* Sections for climatology *)
procedure GetClimSectionsScript(ncSectionsPath, IniDat, lvl, clr:string; kf_s, disttr_max:real;
            ncol, nrow, col:integer; climsectionauto:boolean; ncexportfile:string;
            polar_prj, plot_map, blank_data:boolean);

procedure GetSectionCoordinatesEmpty(SectionPath:string; Polar_prj:boolean);

implementation


(* Sections for climatology *)
procedure GetClimSectionsScript(ncSectionsPath, IniDat, lvl, clr:string; kf_s, disttr_max:real;
          ncol, nrow, col:integer; climsectionauto:boolean; ncexportfile:string;
          polar_prj, plot_map, blank_data:boolean);
var
Ini:TIniFile;
script:text;
c:integer;
IntMethod, IniSet, fout_name:string;
contour, polargrd, XL, YL: string;
begin
 IniSet:='climsections';

 //output file name
 fout_name:= ncSectionsPath+'srf'+PathDelim+ncExportfile+'.srf';

 AssignFile(script, ncSectionsPath+'tmp'+PathDelim+'script.bas'); rewrite(script);

 // showmessage('here');

  if (polar_prj=false) then begin
   Contour :=GlobalPath+lowercase('support\bln\World.bln');
  end;
  if (polar_prj=true) then begin
   Contour :=GlobalPath+lowercase('support\bln\Arctic_polar.bln');
   PolarGrd:=GlobalPath+lowercase('support\bln\Arctic_polar_net.bln');
  end;

 //  showmessage('here2');

 try
  Ini := TIniFile.Create(IniFileName); // settings from file
  IntMethod:=Ini.ReadString(IniSet, 'Algorithm', 'srfKriging');

    writeln(script, 'Sub Main');
    writeln(script, 'Dim Surf, Diagram, Doc, Var As Object');
    writeln(script, '');
    writeln(script, '  FileD    ="'+IniDat+'"');
    writeln(script, '  FileB    ="'+ncSectionsPath+'tmp\depth.bln'+'"');
    writeln(script, '  FileP    ="'+ncSectionsPath+'tmp\md.dat"');     //station labels
    writeln(script, '  FileBLL  ="'+ncSectionsPath+'tmp\data.bln"');  //бланковочный файл по станциям
    writeLn(script, '  FilePolar="' +polargrd+'"');
    if contour <>'' then
    writeLn(script, '  BlankMap ="' +contour +'"');
    writeln(script, '  PathGRD  ="'+ncSectionsPath+'tmp\grid.grd"');
    writeln(script, '  PathTR   ="'+ncSectionsPath+'tmp\grid_tr.grd"');
    writeln(script, '');

    writeln(script, '  Set Surf = CreateObject("Surfer.Application") ');
    writeln(script, '');

 //    showmessage('here3');

 if climsectionauto=false then
     writeLn(script, '  Surf.Visible = True') else
     writeln(script, '  Surf.Visible = False');
    writeln(script, '');

    writeln(script, '  Set Doc = Surf.Documents.Add ');
    writeln(script, '  Set Diagram = Doc.Windows(1)');
    writeln(script, '  Diagram.AutoRedraw = False');
    writeln(script, '  Doc.PageSetup.Orientation = srfLandscape');
    writeln(script, '  Doc.DefaultFill.Pattern="Solid"');
    writeln(script, '  Doc.DefaultFill.ForeColor=srfColorBlack20');
    writeln(script, '');

    writeln(script, '  Set Var=Surf.NewVarioComponent( _');
    writeln(script, '  VarioType:=srfVarLinear, _');
    writeln(script, '  AnisotropyRatio:=1, _');
    writeln(script, '  AnisotropyAngle:=0)');

//создание грида по трансформированным расстояниям
 (* Гридируем данные *)
    WriteLn(script, 'Surf.GridData(DataFile:=FileD, _');
    WriteLn(script, '       xCol:=1, _');
    WriteLn(script, '       yCol:=3, _');
    WriteLn(script, '       zCol:='+inttostr(col)+', _');
    WriteLn(script, '       Algorithm:='        +IntMethod+', _');
    WriteLn(script, '       NumCols:='          +inttostr(nCol)+', _');
    WriteLn(script, '       Numrows:='          +inttostr(nRow)+', _');

 //    showmessage('here4');

(* Настройки для различных методов интерполяции *)
  if IntMethod='srfKriging'  then begin
    WriteLn(script, '       KrigType:='         +Ini.ReadString(IniSet, 'KrigType',          'srfKrigPoint')+', _');
    WriteLn(script, '       KrigDriftType:='    +Ini.ReadString(IniSet, 'KrigDriftType',     'srfDriftNone')+', _');
    if Ini.ReadBool(IniSet, 'SearchEnable', false)=true then begin
     WriteLn(script, '       SearchEnable:=1, _');  //not Ini.ReadBool(IniSet, 'SearchEnable',       true);
     WriteLn(script, '       SearchNumSectors:=' +Ini.ReadString(IniSet, 'SearchNumSectors',  '4')    +', _');
     WriteLn(script, '       SearchMinData:='    +Ini.ReadString(IniSet, 'SearchMinData',     '16')   +', _');
     WriteLn(script, '       SearchMaxData:='    +Ini.ReadString(IniSet, 'SearchMaxData',     '64')   +', _');
     WriteLn(script, '       SearchDataPerSect:='+Ini.ReadString(IniSet, 'SearchDataPerSect', '8')    +', _');
     WriteLn(script, '       SearchMaxEmpty:='   +Ini.ReadString(IniSet, 'SearchMaxEmpty',    '3')    +', _');
     WriteLn(script, '       SearchRad1:='       +Ini.ReadString(IniSet, 'SearchRad1',        '300') +', _');
     WriteLn(script, '       SearchRad2:='       +Ini.ReadString(IniSet, 'SearchRad2',        '30') +', _');
     WriteLn(script, '       SearchAngle:='      +Ini.ReadString(IniSet, 'SearchAngle',       '90')    +', _');
    end;
  end;
    writeln(script, '  KrigVariogram:=Var, _');
    writeln(script, '  xMin:=0, _'); //трансформация
    writeln(script, '  xMax:='+floattostr(disttr_max)+', _');
    writeln(script, '  AnisotropyRatio:='+Ini.ReadString(IniSet, 'AnisotropyRatio', '1')+', _');
    writeln(script, '  AnisotropyAngle:='+Ini.ReadString(IniSet, 'AnisotropyAngle', '0')+', _');
    writeln(script, '  DupMethod:=srfDupNone, _');
    writeln(script, '  ShowReport:=False, _');
    writeln(script, '  OutGrid:=PathGRD)');
    writeln(script, '');

 //    showmessage('here5');

//создание трансформированного грида
    writeln(script, 'Surf.GridTransform(InGrid:=PathGRD, _');
    writeln(script, '  Operation:=srfGridTransScale, _');
    writeln(script, '  XScale:='+floattostr(1/kf_s)+', _');  //коэффициент трансформации
    writeln(script, '  YScale:=1, _');
    writeln(script, '  OutGrid:=PathTR)');
    writeln(script, '');

  //   showmessage('here6');
//сглаживание
  if Ini.ReadInteger(IniSet, 'Filter', 0)>0 then begin
    WriteLn(script, 'Surf.GridFilter(InGrid:=PathTR, _');
		WriteLn(script, '  Filter:=srfFilterGaussian, _');
		WriteLn(script, '  NumPasses:='+Ini.ReadString(IniSet, 'Filter', '0')+', _');    //число прогонов из формы
		WriteLn(script, '  OutGrid:=PathTR)');
    WriteLn(script, '');
   end;

 //  showmessage('here7');

//бланковка внутри рельефа -стояло после создания трансформированного грида
    writeln(script, 'Surf.GridBlank(InGrid:=PathTR, _');
    writeln(script, '  BlankFile:=FileB, _');
    writeln(script, '  Outgrid:=PathGRD, _');
    writeln(script, '  outfmt:=1)');
    writeln(script, '');

//бланковка вокруг профилей по верхним и нижним горизонтам
  if blank_data= true then begin
    writeln(script, 'Surf.GridBlank(InGrid:=PathTR, _');
    writeln(script, '  BlankFile:=FileBLL, _');
    writeln(script, '  Outgrid:=PathTR, _');
    writeln(script, '  outfmt:=1)');
    writeln(script, '');
  end;

//построение контура
    writeln(script, 'Set ContourMapFrame=Doc.Shapes.AddContourMap(PathTR)');

 //    showmessage('here8');

 (* Настраиваем оси основного плота*)
   writeln(script, 'With ContourMapFrame');
   //Левая
   writeln(script, '   .Axes("Left Axis").Title="Depth [m]"');          //Название оси
   writeln(script, '   .Axes("Left Axis").TitleFont.Size = 10');        //Размер шрифта названия
   writeln(script, '   .Axes("Left Axis").TitleFont.Bold=True');        //Шрифт названия жирный
   writeln(script, '   .Axes("Left Axis").LabelFont.Bold=True');        //Шрифт меток жирный
   writeln(script, '   .Axes("Left Axis").LabelFont.Size=10');          //Размер меток
   writeln(script, '   .Axes("Left Axis").SetScale(Maximum:='+floattostr(distTr_max)+')'); //max
   writeln(script, '   .Axes("Left Axis").SetScale(Minimum:=0)');
   writeln(script, '   .Axes("Left Axis").SetScale(FirstMajorTick:=0)');  //Верхнее значение - 0
   writeln(script, '   .Axes("Left Axis").SetScale(LastMajorTick:='+floattostr(distTr_max)+')');
   writeln(script, '   .Axes("Left Axis").Reverse = True '); // reversed
   //Правая
   writeln(script, '   .Axes("Right axis").SetScale(Maximum:='+floattostr(distTr_max)+')'); //min
   writeln(script, '   .Axes("Right axis").SetScale(Minimum:=0)');
   writeln(script, '   .Axes("Right axis").SetScale(LastMajorTick:='+floattostr(distTr_max)+')'); //min
   writeln(script, '   .Axes("Right axis").MajorTickType = srfTickNone');  //Отключаем метки
   writeln(script, '   .Axes("Right Axis").Reverse = True '); // reversed
   //Нижняя
   writeln(script, '   .Axes("Bottom Axis").Title="Distance [km]"');
   writeln(script, '   .Axes("Bottom Axis").TitleFont.Size = 10');
   writeln(script, '   .Axes("Bottom Axis").TitleFont.Bold=True');
   writeln(script, '   .Axes("Bottom Axis").LabelFont.Bold=True');
   writeln(script, '   .Axes("Bottom Axis").LabelFont.Size=10');
   //Верхняя
   writeln(script, '   .Axes("Top Axis").MajorTickType = srfTickNone');    //Отключаем метки
   writeln(script, '   .Axes("Top Axis").SetScale(Cross1:=0)');
 //  writeln(script, '   .SetLimits(xMin:=xMin, xMax:=xMax+10, yMin:=yMin-10, yMax:=yMax+10)'); //Пределы плота
   writeln(script, 'End With');
   WriteLn(script, '');
//построение рельефа
    writeln(script, 'Set Basemap2 = Doc.Shapes.AddBaseMap(ImportFileName:=FileB)');
    writeln(script, '');

 //    showmessage('here10');

//post1->метки станций
    writeln(script, 'Set PostMap2=Doc.Shapes.AddPostMap(DataFileName:=FileP, _');
    writeln(script, '   xCol:=1, _'); //реальное расстояние
    writeln(script, '   yCol:=2)');
    writeln(script, 'Set sampleMarks = PostMap2.Overlays(1)');
    writeln(script, '    With SampleMarks');
    writeln(script, '        .Visible=true');
    writeln(script, '        .LabCol=8');                  //Дата по-умолчанию
    writeln(script, '        .LabelFont.Size=4');
    writeln(script, '        .LabelAngle=90'); // Поворот подписей относительно оси Х
    writeln(script, '        .LabelPos=srfPostPosBelow');
    writeln(script, '        .Symbol.Index=12');           // Символ - кружок
    writeln(script, '        .Symbol.Size=0.05');
    writeln(script, '        .Symbol.Color=srfColorBlack');
    writeln(script, '    End With');
    writeln(script, '');

//post->измеренные горизонты
    writeln(script, 'Set PostMap3=Doc.Shapes.AddPostMap(DataFileName:=FileD, _');
    writeln(script, '   xCol:=2, _'); //реальное расстояние
    writeln(script, '   yCol:=3)');
    writeln(script, 'Set sampleMarks = PostMap3.Overlays(1)');
    writeln(script, '    With SampleMarks');
    writeln(script, '        .LabCol=4'); //new labels for current plot
    writeln(script, '        .LabelFont.Size=4');
    writeln(script, '        .Symbol.Index=15');
    writeln(script, '        .Symbol.Size=0.03');
    writeln(script, '        .Symbol.Color=srfColorBlue');
    writeln(script, '        .LabelAngle=0');
    writeln(script, '        .Visible=false');
    writeln(script, '    End With');
    writeln(script, '');

  //   showmessage('here11');
//объединение объектов -> OverlayMaps
    writeln(script, 'Doc.Shapes.SelectAll');
    writeln(script, 'Set NewMap = Doc.Selection.OverlayMaps');
    writeln(script, 'NewMap.xLength=20');
    writeln(script, 'NewMap.yLength=10');

//фон->Background
 //   writeln(script, 'NewMap.BackgroundFill.Pattern = "6.25% Black"');
//    writeln(script, 'NewMap.BackgroundFill.ForeColor = srfColorBlack30');

//определение положения левого нижнего угла
    writeln(script, 'L = NewMap.Left');
    writeln(script, 'B = NewMap.top-NewMap.Height');
    writeln(script, 'Set ContourMap = NewMap.Overlays(1)');

    //цветная заливка->FillContours
    writeln(script, 'contourMap.FillContours = True');
    writeln(script, 'contourMap.ShowColorScale = True');

    // Colour scale orientation
    if Ini.ReadInteger(IniSet, 'ColourScaleOrient', 0)=0 then begin //horizontal
      writeln(script, 'contourMap.ColorScale.Rotation=-90');  //scale rotation
      writeln(script, 'contourMap.ColorScale.LabelAngle=90'); //label angle
      writeln(script, 'contourMap.ColorScale.Top = B-5E-1');
      writeln(script, 'contourMap.ColorScale.Left = L+6');
    end;
    if Ini.ReadInteger(IniSet, 'ColourScaleOrient', 0)=1 then begin //vertical
      writeln(script, 'contourMap.ColorScale.Top = NewMap.Top-115E-2');
      writeln(script, 'contourMap.ColorScale.Height = NewMap.Height-16E-1');
      writeln(script, 'contourMap.ColorScale.Left = NewMap.Left+NewMap.Width+4E-1');
    end;

    writeln(script, 'contourMap.ColorScale.LabelFrequency='+Ini.ReadString(IniSet, 'ColourScaleLbFreq', '1')); //label frequency
    writeln(script, 'contourMap.ColorScale.FrameLine.Style = "Invisible"');

   (* Заливаем контур *)
    if lvl<>'' then WriteLn(script, 'contourMap.Levels.LoadFile("'+Lvl+'")');

    (* Добавляем цвет в контуры *)
    if clr<>'' then WriteLn(script, '  contourMap.FillForegroundColorMap.LoadFile("'+clr+'")');
    WriteLn(script, '  contourMap.LabelLabelDist ='+Ini.ReadString(IniSet, 'LevelToLevelDist', '1'));
    WriteLn(script, '  contourMap.LabelEdgeDist  ='+Ini.ReadString(IniSet, 'LevelToEdgeDist',  '1'));
    WriteLn(script, '  contourMap.LabelTolerance ='+Ini.ReadString(IniSet, 'CurveTolerance',   '15E-1'));
    WriteLn(script, '  contourMap.LabelFont.Size =6');
    WriteLn(script, '');

    if ncExportFile<>'' then begin
      writeln(script, 'Diagram.Zoom(srfZoomFitToWindow)');
      writeln(script, 'Diagram.AutoRedraw = True');
      WriteLn(script, '');
      WriteLn(script, 'Doc.Export(FileName:="'+ncSectionsPath+'png\'+ncExportfile+'.png", _');
      WriteLn(script, 'SelectionOnly:=False , Options:="Width=1920; KeepAspect=1; HDPI=300; VDPI=300")');
      WriteLn(script, '');
      writeln(script, 'Diagram.AutoRedraw = False');
      WriteLn(script, '');
    end;

(***********************************  SECTION MAP  ***********************************)
 if plot_map=true then begin
   WriteLn(script, 'Set Doc2=Surf.Documents.Add');
   WriteLn(script, 'Set Diagram2 = Doc2.Windows(1)');
   WriteLn(script, '    Diagram2.AutoRedraw = False');
   WriteLn(script, '');

    (* Пост со значениями*)
   WriteLn(script, 'Set PostMap=Doc2.Shapes.AddPostMap(DataFileName:=FileP, _');
   if polar_prj=false then begin
    WriteLn(script, 'xCol:=4, _');
    WriteLn(script, 'yCol:=3)');
   end;
   if polar_prj=true then begin
    WriteLn(script, 'xCol:=5, _');
    WriteLn(script, 'yCol:=6)');
   end;
   WriteLn(script, 'Set sampleMarks = PostMap.Overlays(1)');
   WriteLn(script, 'With SampleMarks');
   WriteLn(script, '  .Visible=True');
   writeln(script, '  .LabCol=8');
   WriteLn(script, '  .LabelFont.Size=0.2');
   WriteLn(script, '  .Symbol.Index=12');
   WriteLn(script, '  .Symbol.Size=0.01');
   WriteLn(script, '  .Symbol.Color=srfColorRed');
   WriteLn(script, '  .LabelAngle=0');
   WriteLn(script, 'End With');
   WriteLn(script, '');

   (* Карта - подложка: берега на нулевой изобате *)
   WriteLn(script, 'Set BaseMap=Doc2.Shapes.AddBaseMap(BlankMap)');

   WriteLn(script, 'Set BaseMap1 = BaseMap.Overlays(1)');
   WriteLn(script, 'BaseMap1.Fill.Pattern="Solid"');
   WriteLn(script, 'BaseMap1.Fill.ForeColor=srfColorBlack40');
   WriteLn(script, 'BaseMap1.Line.ForeColorRGBA.Color=srfColorBlack80');
   WriteLn(script, '');

  if Polar_prj=true then begin
   WriteLn(script, 'Set BaseMap=Doc2.Shapes.AddBaseMap(FilePolar)');
   WriteLn(script, 'Set BaseMap1 = BaseMap.Overlays(1)');
   WriteLn(script, 'BaseMap1.Line.ForeColorRGBA.Color=srfColorBlack50');
   WriteLn(script, '');
  end;


   (* Объединяем и задаём общие свойства *)
   WriteLn(script, 'Doc2.Shapes.SelectAll');
   WriteLn(script, 'Set NewMap = Doc2.Selection.OverlayMaps');
   WriteLn(script, '');

   if polar_prj=false then begin
    WriteLn(script, 'Set Axes = NewMap.Axes');
    WriteLn(script, 'Set Axis = Axes("top axis")');
    WriteLn(script, 'Axis.ShowLabels=False');
    WriteLn(script, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
    WriteLn(script, 'Axis.MajorTickLength=0');
    WriteLn(script, 'Axis.LabelFont.Size=8');
    WriteLn(script, 'Axis.LabelFont.Color= srfColorBlack');
    WriteLn(script, '');
    WriteLn(script, 'Set Axis = Axes("bottom axis")');
    WriteLn(script, 'Axis.ShowLabels=True');
    WriteLn(script, 'Axis.ShowMajorGridLines=True');
    WriteLn(script, 'Axis.MajorGridLine.ForeColorRGBA.Color =srfColorBlack50');
    WriteLn(script, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
    WriteLn(script, 'Axis.MajorTickLength=1E-1');
    WriteLn(script, 'Axis.LabelFont.Size=8');
    WriteLn(script, 'Axis.LabelFont.Color= srfColorBlack');
    WriteLn(script, 'Axis.SetScale(-180, 180, 10, -180, 180, -90, 0)');
    WriteLn(script, '');
    WriteLn(script, 'Set Axis = Axes("right axis")');
    WriteLn(script, 'Axis.ShowLabels=False');
    WriteLn(script, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
    WriteLn(script, 'Axis.MajorTickLength=0');
    WriteLn(script, 'Axis.LabelFont.Color= srfColorBlack');
    WriteLn(script, '');
    WriteLn(script, 'Set Axis = Axes("left axis")');
    WriteLn(script, 'Axis.ShowLabels=True');
    WriteLn(script, 'Axis.ShowMajorGridLines=True');
    WriteLn(script, 'Axis.MajorGridLine.ForeColorRGBA.Color =srfColorBlack50');
    WriteLn(script, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
    WriteLn(script, 'Axis.MajorTickLength=1E-1');
    WriteLn(script, 'Axis.LabelFont.Size=8');
    WriteLn(script, 'Axis.LabelFont.Color= srfColorBlack ');
    WriteLn(script, 'Axis.SetScale(-90, 90, 10, -90, 90, -180, 0)');
    WriteLn(script, '');
   end;

   if polar_prj=true then begin
    WriteLn(script, 'Set Axes = NewMap.Axes');
    WriteLn(script, 'Set Axis = Axes("top axis")');
    WriteLn(script, 'Axis.Visible=False');
    WriteLn(script, '');
    WriteLn(script, 'Set Axis = Axes("bottom axis")');
    WriteLn(script, 'Axis.Visible=False');
    WriteLn(script, '');
    WriteLn(script, 'Set Axis = Axes("right axis")');
    WriteLn(script, 'Axis.Visible=False');
    WriteLn(script, '');
    WriteLn(script, 'Set Axis = Axes("left axis")');
    WriteLn(script, 'Axis.Visible=False');
    WriteLn(script, '');
   end;


   WriteLn(script, 'With NewMap');
   if polar_prj=false then begin
     WriteLn(script, '  .SetLimits(-180, 180, -90, 90)');
     WriteLn(script, '  .xLength= 15');
     WriteLn(script, '  .yLength= 8');
   end;
   if polar_prj=true then begin
    WriteLn(script, '  .xLength= 12');
    WriteLn(script, '  .yLength= 12');
   end;
   WriteLn(script, 'End With');
   WriteLn(script, '');

   WriteLn(script, ' Doc2.Shapes.SelectAll');
   WriteLn(script, ' Doc2.Selection.Copy');
   WriteLn(script, '');

   WriteLn(script, ' Set selection2 =Doc.Shapes.Paste(Format:=srfPasteBest)');
   WriteLn(script, ' With selection2');
   WriteLn(script, '  .Top  = 15');
   WriteLn(script, '  .Left = 29');
   WriteLn(script, ' End With');
   WriteLn(script, '');

   if polar_prj=true then begin
    XL:='29'; YL:='15';
    For c:=1 to 18 do begin
     WriteLn(script, '');
     case c of
      1 : WriteLn(script, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+5.75,  y:='+YL+'+0.5,   Text:="180" )');
      2 : WriteLn(script, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+3.5,   y:='+YL+'+0.25,  Text:="-160")');
      3 : WriteLn(script, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+1.25,  y:='+YL+'-1,     Text:="-140")');
      4 : WriteLn(script, 'Set Label =Doc.Shapes.AddText(x:='+XL+',       y:='+YL+'-2.55,  Text:="-120")');
      5 : WriteLn(script, 'Set Label =Doc.Shapes.AddText(x:='+XL+'-0.75,  y:='+YL+'-4.75,  Text:="-100")');
      6 : WriteLn(script, 'Set Label =Doc.Shapes.AddText(x:='+XL+'-0.75,  y:='+YL+'-7,     Text:="-80" )');
      7 : WriteLn(script, 'Set Label =Doc.Shapes.AddText(x:='+XL+',       y:='+YL+'-9,     Text:="-60" )');
      8 : WriteLn(script, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+1.25,  y:='+YL+'-10.75, Text:="-40" )');
      9 : WriteLn(script, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+3.5,   y:='+YL+'-11.75, Text:="-20" )');
      10: WriteLn(script, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+5.9,   y:='+YL+'-12.25, Text:="0"   )');
      11: WriteLn(script, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+8,     y:='+YL+'-11.75, Text:="20"  )');
      12: WriteLn(script, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+10,    y:='+YL+'-10.75, Text:="40"  )');
      13: WriteLn(script, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+11.5,  y:='+YL+'-9,     Text:="60"  )');
      14: WriteLn(script, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+12.25, y:='+YL+'-7,     Text:="80"  )');
      15: WriteLn(script, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+12,    y:='+YL+'-4.75,  Text:="100" )');
      16: WriteLn(script, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+11.25, y:='+YL+'-2.55,  Text:="120" )');
      17: WriteLn(script, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+10,    y:='+YL+'-1,     Text:="140" )');
      18: WriteLn(script, 'Set Label =Doc.Shapes.AddText(x:='+XL+'+8,     y:='+YL+'+0.25,  Text:="160" )');
     end;
     WriteLn(script, '     Label.Font.Face = "Arial"');
     WriteLn(script, '     Label.Font.Size=10');
     WriteLn(script, '     Label.Font.Bold=True');
     WriteLn(script, '     Label.Font.ForeColorRGBA.Color = srfColorBlack80');
    end; //18
   end; // polar=true

  WriteLn(script, 'Doc2.Close(SaveChanges:=srfSaveChangesNo)');
  WriteLn(script, '');
 end; // end of plotting map
(******************************** END OF SECTION MAP  ********************************)

//масштабирование
    writeln(script, 'Diagram.Zoom(srfZoomFitToWindow)');
    writeln(script, 'Diagram.AutoRedraw = True');
    writeLn(script, 'Doc.SaveAs(FileName:="'+fout_name+'")');

    if climsectionauto=true then begin
      writeLn(script, 'Doc.Close(SaveChanges:=srfSaveChangesNo)');
    end;

    writeln(script, '');
    writeln(script, 'End Sub');

 finally
   Ini.Free; // close settings file
   CloseFile(script);
 end;
end;



procedure GetSectionCoordinatesEmpty(SectionPath:string; Polar_prj:boolean);
Var
 f_scr:text;
 path, contour, polargrd:string;
begin
AssignFile(f_scr, ExtractFilePath(SectionPath)+'script.bas'); rewrite(f_scr);  // script file
 if (polar_prj=false) then begin
  Contour :=GlobalPath+lowercase('support\bln\World.bln');
 end;
 if (polar_prj=true) then begin
  Contour :=GlobalPath+lowercase('support\bln\Arctic_polar.bln');
  PolarGrd:=GlobalPath+lowercase('support\bln\Arctic_polar_net.bln');
 end;

 try
   WriteLn(f_scr, 'Sub Main');
   WriteLn(f_scr, 'Dim Surfer, Diagram, Doc As Object');
   WriteLn(f_scr, 'pathPolarGrd="' +polargrd+'"');
   WriteLn(f_scr, 'pathBlankMap="' +contour +'"');
   WriteLn(f_scr, 'SectionPath="'  +SectionPath +'"');
   WriteLn(f_scr, '');

   WriteLn(f_scr, 'Set Surfer=CreateObject("Surfer.Application")');
   WriteLn(f_scr, '    Surfer.Visible=True');

   WriteLn(f_scr, 'Set Doc=Surfer.Documents.Add');
   WriteLn(f_scr, '    Doc.PageSetup.Orientation = srfLandscape');

   WriteLn(f_scr, 'Set Diagram = Doc.Windows(1)');
   WriteLn(f_scr, '    Diagram.AutoRedraw = False');
   WriteLn(f_scr, '');


   (* Карта - подложка: берега на нулевой изобате *)
   WriteLn(f_scr, 'Set BaseMap=Doc.Shapes.AddBaseMap(pathBlankMap)');
   WriteLn(f_scr, 'Set BaseMap1 = BaseMap.Overlays(1)');
   WriteLn(f_scr, 'BaseMap1.Fill.Pattern="Solid"');
   WriteLn(f_scr, 'BaseMap1.Fill.ForeColor=srfColorBlack40');
   WriteLn(f_scr, 'BaseMap1.Line.ForeColorRGBA.Color=srfColorBlack80');
   WriteLn(f_scr, '');

   WriteLn(f_scr, 'Set BaseMap=Doc.Shapes.AddBaseMap(SectionPath)');
   WriteLn(f_scr, 'Set BaseMap1 = BaseMap.Overlays(1)');
   WriteLn(f_scr, 'BaseMap1.Fill.Pattern="Solid"');
   WriteLn(f_scr, 'BaseMap1.Line.ForeColorRGBA.Color=srfColorRed');
   WriteLn(f_scr, '');



  if Polar_prj=true then begin
   WriteLn(f_scr, 'Set BaseMap=Doc.Shapes.AddBaseMap(pathPolarGrd)');
   WriteLn(f_scr, 'Set BaseMap1 = BaseMap.Overlays(1)');
   WriteLn(f_scr, 'BaseMap1.Line.ForeColorRGBA.Color=srfColorBlack50');
   WriteLn(f_scr, '');
  end;

  if polar_prj=false then begin
    WriteLn(f_scr, 'Set Axes = Basemap.Axes');
    WriteLn(f_scr, 'Set Axis = Axes("top axis")');
    WriteLn(f_scr, 'Axis.ShowLabels=False');
    WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
    WriteLn(f_scr, 'Axis.MajorTickLength=0');
    WriteLn(f_scr, 'Axis.LabelFont.Size=8');
    WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack');
    WriteLn(f_scr, '');
    WriteLn(f_scr, 'Set Axis = Axes("bottom axis")');
    WriteLn(f_scr, 'Axis.ShowLabels=True');
    WriteLn(f_scr, 'Axis.ShowMajorGridLines=True');
    WriteLn(f_scr, 'Axis.MajorGridLine.ForeColorRGBA.Color =srfColorBlack50');
    WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
    WriteLn(f_scr, 'Axis.MajorTickLength=1E-1');
    WriteLn(f_scr, 'Axis.LabelFont.Size=8');
    WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack');
    WriteLn(f_scr, '');
    WriteLn(f_scr, 'Set Axis = Axes("right axis")');
    WriteLn(f_scr, 'Axis.ShowLabels=False');
    WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
    WriteLn(f_scr, 'Axis.MajorTickLength=0');
    WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack');
    WriteLn(f_scr, '');
    WriteLn(f_scr, 'Set Axis = Axes("left axis")');
    WriteLn(f_scr, 'Axis.ShowLabels=True');
    WriteLn(f_scr, 'Axis.ShowMajorGridLines=True');
    WriteLn(f_scr, 'Axis.MajorGridLine.ForeColorRGBA.Color =srfColorBlack50');
    WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
    WriteLn(f_scr, 'Axis.MajorTickLength=1E-1');
    WriteLn(f_scr, 'Axis.LabelFont.Size=8');
    WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack ');
   WriteLn(f_scr, '');
  end;

   (* Объединяем и задаём общие свойства *)
   WriteLn(f_scr, 'Doc.Shapes.SelectAll');
   WriteLn(f_scr, 'Set NewMap = Doc.Selection.OverlayMaps');
   WriteLn(f_scr, 'With NewMap');
   if polar_prj=false then begin
     WriteLn(f_scr, '  .xLength= 15');
     WriteLn(f_scr, '  .yLength= 8');
     WriteLn(f_scr, '  .Top= 26');
     WriteLn(f_scr, '  .Left= 2');
     WriteLn(f_scr, '  .BackgroundFill.Pattern = "10 Percent"');
     WriteLn(f_scr, '  .BackgroundFill.ForeColor = srfGold');
   end;
   WriteLn(f_scr, '    L = .Left');
   WriteLn(f_scr, '    B = .Top-.Height');
   WriteLn(f_scr, 'End With');
   WriteLn(f_scr, '');

   WriteLn(f_scr, 'Diagram.Zoom(srfZoomFitToWindow)');
   WriteLn(f_scr, 'Diagram.AutoRedraw = True');
   WriteLn(f_scr, 'End Sub');

 finally
   CloseFile(f_scr); // close script file
 end;
end;


end.

