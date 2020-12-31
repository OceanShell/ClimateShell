unit surfer_climhovmoeller;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, ncmain;

(* Hovmoeller diagram script *)
procedure GetClimHovmoellerScript(HovmoellerPath, lvl, clr:string; ncol, nrow, col:integer);

implementation

(* Скрипт для диаграмм Hovemoller*)
procedure GetClimHovmoellerScript(HovmoellerPath, lvl, clr:string; ncol, nrow, col:integer);
Var
Ini:TIniFile;
script:text;
IntMethod, IniSet:string;
begin

 IniSet:='climhovmoeller';

 AssignFile(script, HovmoellerPath+'script.bas'); rewrite(script);

 try
  Ini := TIniFile.Create(IniFileName); // settings from file
  IntMethod:=Ini.ReadString(IniSet, 'Algorithm', 'srfKriging');

  writeln(script, 'Sub Main');
  writeln(script, 'Dim Surf, Diagram, Doc As Object');
  writeln(script, '');
  writeln(script, 'pathDataFile ="' + HovmoellerPath+'Temp.dat"');
  writeln(script, 'PathGRD = "'     + HovmoellerPath+'Grid.grd"');
  WriteLn(Script, 'pathBlnFile ="'  + HovmoellerPath+'Temp.bln"');
  writeln(script, '');
  writeln(script, 'Set Surf = CreateObject("Surfer.Application") ');
  writeln(script, '');
  writeln(script, 'Surf.Visible = True');
  writeln(script, '  Set Doc = Surf.Documents.Add ');
  writeln(script, '  Set Diagram = Doc.Windows(1)');
  writeln(script, '  Diagram.AutoRedraw = False');
  writeln(script, '  Doc.PageSetup.Orientation = srfLandscape');
  writeln(script, '  Doc.DefaultFill.Pattern="Solid"');
  writeln(script, '  Doc.DefaultFill.ForeColor=srfColorBlack20');
  writeln(script, '');

  // создание грида
  writeln(script, 'Surf.GridData(DataFile:=pathDataFile, _');
  writeln(script, '  xCol:=2, _'); // 1 для трансформированных значений
  writeln(script, '  yCol:=3, _');
  writeln(script, '  zCol:='+inttostr(col)+', _');
  writeln(script, '  numRows:=' + inttostr(nrow) + ', _');
  writeln(script, '  numCols:=' + inttostr(ncol) + ', _');
  writeln(script, '  Algorithm:=' + IntMethod + ', _');
(* Настройки для различных методов интерполяции *)
  if IntMethod='srfKriging'  then begin
    WriteLn(script, '       KrigType:='         +Ini.ReadString(IniSet, 'KrigType',          'srfKrigPoint')+', _');
    WriteLn(script, '       KrigDriftType:='    +Ini.ReadString(IniSet, 'KrigDriftType',     'srfDriftNone')+', _');
    if Ini.ReadBool(IniSet, 'SearchEnable', false)=true then begin
     WriteLn(script, '       SearchEnable:=1, _');  //not Ini.ReadBool(IniSet, 'SearchEnable',       true);
     WriteLn(script, '       SearchNumSectors:=' +Ini.ReadString(IniSet, 'SearchNumSectors',  '4')  +', _');
     WriteLn(script, '       SearchMinData:='    +Ini.ReadString(IniSet, 'SearchMinData',     '16') +', _');
     WriteLn(script, '       SearchMaxData:='    +Ini.ReadString(IniSet, 'SearchMaxData',     '64') +', _');
     WriteLn(script, '       SearchDataPerSect:='+Ini.ReadString(IniSet, 'SearchDataPerSect', '8')  +', _');
     WriteLn(script, '       SearchMaxEmpty:='   +Ini.ReadString(IniSet, 'SearchMaxEmpty',    '3')  +', _');
     WriteLn(script, '       SearchRad1:='       +Ini.ReadString(IniSet, 'SearchRad1',        '1')  +', _');
     WriteLn(script, '       SearchRad2:='       +Ini.ReadString(IniSet, 'SearchRad2',        '1')  +', _');
     WriteLn(script, '       SearchAngle:='      +Ini.ReadString(IniSet, 'SearchAngle',       '0')  +', _');
    end;
  end;
  writeln(script, '  DupMethod:=srfDupNone, _');
  writeln(script, '  ShowReport:=False, _');
  writeln(script, '  OutGrid:=PathGRD)');
  writeln(script, '');

  //бланковка
  WriteLn(Script, 'Surf.GridBlank(InGrid:=PathGRD, _');
  WriteLn(Script, '  BlankFile:=pathBlnFile, _');
  WriteLn(Script, '  Outgrid:=PathGRD, _');
  WriteLn(Script, '  outfmt:=1)');
  WriteLn(Script, '');

  //сглаживание
  if Ini.ReadInteger(IniSet, 'Filter', 0)>0 then begin
    WriteLn(script, 'Surf.GridFilter(InGrid:=PathGRD, _');
		WriteLn(script, '  Filter:=srfFilterGaussian, _');
		WriteLn(script, '  NumPasses:='+Ini.ReadString(IniSet, 'Filter', '0')+', _'); //число прогонов из формы
		WriteLn(script, '  OutGrid:=PathGRD)');
    WriteLn(script, '');
   end;

 (*  // трансформация
  writeln(script, 'Surf.GridTransform(InGrid:=PathGRD, _');
  writeln(script, '  Operation:=srfGridTransScale, _');
  writeln(script, '  XScale:=' + floattostr(koef) + ', _');
  writeln(script, '  YScale:=1, _');
  writeln(script, '  OutGrid:=PathGRD)');
  writeln(script, '');

 // добавление сдвига
  writeln(script, 'Surf.GridTransform(InGrid:=PathGRD, _');
  writeln(script, '  Operation:=srfGridTransOffset, _');
  writeln(script, '  XOffset:=' + floattostr(YYMin) + ', _');
  writeln(script, '  YOffset:=1, _');
  writeln(script, '  OutGrid:=PathGRD)');
  writeln(script, '');  *)


  (* Строим основной плот, убираем верхние и боковые метки*)
  WriteLn(Script, 'Set ContourMapFrame=Doc.Shapes.AddContourMap(PathGRD)');
  WriteLn(Script, 'Set Axes = ContourMapFrame.Axes');
  WriteLn(Script, 'Set Axis = Axes("top axis")');
  WriteLn(Script, 'Axis.MajorTickType = srfTickNone');
  WriteLn(Script, 'Axis.MajorGridLine.ForeColorRGBA.Color =srfColorBlack');
  WriteLn(Script, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
  WriteLn(Script, '');
  WriteLn(Script, 'Set Axis = Axes("right axis")');
  WriteLn(Script, 'Axis.MajorTickType = srfTickNone');
  WriteLn(Script, 'Axis.MajorGridLine.ForeColorRGBA.Color =srfColorBlack');
  WriteLn(Script, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
  WriteLn(Script, '');
  WriteLn(Script, 'Set Axis = Axes("bottom axis")');
  WriteLn(Script, 'Axis.MajorGridLine.ForeColorRGBA.Color =srfColorBlack');
  WriteLn(Script, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
  WriteLn(Script, 'Axis.MajorTickLength=1E-1');
  WriteLn(Script, 'Axis.LabelFont.Size=10');
  WriteLn(Script, '');
  WriteLn(Script, 'Set Axis = Axes("left axis")');
  WriteLn(Script, 'Axis.ShowLabels=True');
  WriteLn(Script, 'Axis.MajorGridLine.ForeColorRGBA.Color =srfColorBlack');
  WriteLn(Script, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
  WriteLn(Script, 'Axis.MajorTickLength=1E-1');
  WriteLn(Script, 'Axis.LabelFont.Size=10');
  WriteLn(Script, 'Axis.LabelFormat.Postfix="°"');
  WriteLn(Script, 'Axis.LabelFont.Color= srfColorBlack');
  WriteLn(Script, '');

  // Набрасываем пост с точками
  writeln(script,
    'Set PostMap2=Doc.Shapes.AddPostMap(DataFileName:=pathDataFile, _');
  writeln(script, '   xCol:=2, _');
  writeln(script, '   yCol:=3)');
  writeln(script, 'Set sampleMarks = PostMap2.Overlays(1)');
  writeln(script, '    With SampleMarks');
  writeln(script, '        .Visible=false');
  writeln(script, '        .LabelFont.Size=4');
  writeln(script, '        .Symbol.Index=12');
  writeln(script, '        .Symbol.Size=0.05');
  writeln(script, '        .Symbol.Color=srfColorBlack');
  writeln(script, '        .LabelAngle=0');
  writeln(script, '    End With');
  writeln(script, '');

  writeln(script, 'Doc.Shapes.SelectAll');
  writeln(script, 'Set NewMap = Doc.Selection.OverlayMaps');
  writeln(script, 'NewMap.xLength=22');
  writeln(script, 'NewMap.yLength=15');
  writeln(script, 'NewMap.Top = 18');
  writeln(script, 'NewMap.Left = 2');
  writeln(script, 'NewMap.BackgroundFill.Pattern = "6.25% Black"');
  writeln(script, 'NewMap.BackgroundFill.ForeColor = srfColorBlack30');
  writeln(script, 'L = NewMap.Left');
  writeln(script, 'B = NewMap.top-NewMap.Height');
  writeln(script, '');

  writeln(script, 'Set ContourMap = NewMap.Overlays(1)');
  writeln(script, 'ContourMap.FillContours = True');
  (* Заливаем контур *)
  if lvl<>'' then WriteLn(script, 'contourMap.Levels.LoadFile("'+Lvl+'")');
  (* Добавляем цвет в контуры *)
  if clr<>'' then
  WriteLn(script, '  contourMap.FillForegroundColorMap.LoadFile("'+clr+'")');
  WriteLn(script, '  contourMap.LabelLabelDist ='+Ini.ReadString(IniSet, 'LevelToLevelDist', '1'));
  WriteLn(script, '  contourMap.LabelEdgeDist  ='+Ini.ReadString(IniSet, 'LevelToEdgeDist',  '1'));
  WriteLn(script, '  contourMap.LabelTolerance ='+Ini.ReadString(IniSet, 'CurveTolerance',   '15E-1'));
  WriteLn(script, '  contourMap.LabelFont.Size =10');
  WriteLn(script, '');
  writeln(script, 'ContourMap.ShowColorScale = True');
  writeln(script, 'contourMap.ColorScale.Top = NewMap.Top-0.2');
  writeln(script, 'contourMap.ColorScale.Height = NewMap.Height-0.7');
  writeln(script, 'contourMap.ColorScale.Left = NewMap.Left+NewMap.Width+0.4');
  writeln(script, '');

  writeln(script, 'Diagram.Zoom(srfZoomFitToWindow)');
  writeln(script, 'Diagram.AutoRedraw = True');
  writeln(script, '');
  writeln(script, 'End Sub');
 finally
   Ini.Free;
   CloseFile(script);
 end;
end;

end.

