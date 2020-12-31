unit surfer_nclatlon;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, ncmain;

(* Lat/Lon timeseries for common NetCDF *)
procedure GetLatLonScript(src:string; Col:integer; lvl, clr:string);

implementation

(* Lat/Lon timeseries for common NetCDF *)
procedure GetLatLonScript(src:string; Col:integer; lvl, clr:string);
Var
  Ini: TIniFile;
  f_scr:text;
  FilePath, FileName, IniSet, IntMethod:string;
begin
FilePath:=ExtractFilePath(src); //Path to data
FileName:=ExtractFileName(src);
FileName:=copy(FileName, 1, length(FileName)-4);

IniSet:='nclatlon';

Ini := TIniFile.Create(IniFileName); // settings from file
IntMethod:=Ini.ReadString(IniSet, 'Algorithm', 'srfKriging');

AssignFile(f_scr, FilePath+'script.bas'); rewrite(f_scr);

try
  WriteLn(f_scr, 'Sub Main');
  WriteLn(f_scr, 'Dim Surfer, Diagram, Doc As Object');
  WriteLn(f_scr, 'pathDataFile ="'+src+'"');
  WriteLn(f_scr, 'PathGRDVal = "' +FilePath+'grd\'+FileName+'.grd"');
  WriteLn(f_scr, '');
  WriteLn(f_scr, 'Set Surfer=CreateObject("Surfer.Application")');
  WriteLn(f_scr, '    Surfer.Visible=False');
  WriteLn(f_scr, '');
  WriteLn(f_scr, 'Set Doc=Surfer.Documents.Add');
  WriteLn(f_scr, '    Doc.PageSetup.Orientation = srfLandscape'); // two plots
  WriteLn(f_scr, 'Set Diagram = Doc.Windows(1)');
  WriteLn(f_scr, '    Diagram.AutoRedraw = False');
  WriteLn(f_scr, '');

  (* Гридируем данные *)
   WriteLn(f_scr, 'Surfer.GridData(DataFile:=pathDataFile, _');
   WriteLn(f_scr, '       xCol:=1, _');
   WriteLn(f_scr, '       yCol:=2, _');
   WriteLn(f_scr, '       zCol:='+inttostr(Col)+', _');
   WriteLn(f_scr, '       Algorithm:='        +IntMethod+', _');
   WriteLn(f_scr, '       NumCols:='          +inttostr(100)+', _');
   WriteLn(f_scr, '       Numrows:='          +inttostr(100)+', _');

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
    WriteLn(f_scr, '       SearchRad1:='       +Ini.ReadString(IniSet, 'SearchRad1',        '1')  +', _');
    WriteLn(f_scr, '       SearchRad2:='       +Ini.ReadString(IniSet, 'SearchRad2',        '1')  +', _');
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
   WriteLn(f_scr, '       SearchRad1:='         +Ini.ReadString(IniSet, 'SearchRad1',        '1')  +', _');
   WriteLn(f_scr, '       SearchRad2:='         +Ini.ReadString(IniSet, 'SearchRad2',        '1')  +', _');
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
   WriteLn(f_scr, '       SearchRad1:='         +Ini.ReadString(IniSet, 'SearchRad1',        '1')  +', _');
   WriteLn(f_scr, '       SearchRad2:='         +Ini.ReadString(IniSet, 'SearchRad2',        '1')  +', _');
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
   WriteLn(f_scr, '       SearchRad1:='         +Ini.ReadString(IniSet, 'SearchRad1',        '1')  +', _');
   WriteLn(f_scr, '       SearchRad2:='         +Ini.ReadString(IniSet, 'SearchRad2',        '1')  +', _');
   WriteLn(f_scr, '       SearchAngle:='        +Ini.ReadString(IniSet, 'SearchAngle',       '0')  +', _');
 end;
   WriteLn(f_scr, '       DupMethod:=srfDupNone, _');
   WriteLn(f_scr, '       ExclusionFilter:="z=' +Ini.ReadString(IniSet, 'MissingVal', '-9999')+'", _');
   WriteLn(f_scr, '       ShowReport:=False, _');
   WriteLn(f_scr, '       OutGrid:=PathGRDVal)');
   WriteLn(f_scr, '');

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

  (* Убираем верхние и боковые метки с основного плота*)
  WriteLn(f_scr, 'Set Axis = Axes("top axis")');
  WriteLn(f_scr, 'Axis.ShowLabels=False');
  WriteLn(f_scr, 'Axis.MajorTickLength=0');
  WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
  WriteLn(f_scr, '');

  WriteLn(f_scr, 'Set Axis = Axes("bottom axis")');
  WriteLn(f_scr, 'Axis.ShowLabels=True');
  WriteLn(f_scr, 'Axis.MajorGridLine.ForeColorRGBA.Color =srfColorBlack');
  WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
  WriteLn(f_scr, 'Axis.MajorTickLength=1E-1');
  WriteLn(f_scr, 'Axis.LabelFont.Size=8');
  WriteLn(f_scr, 'Axis.SetScale(1979, 2014, 2, 1980, 2014, -90, 0)');
  WriteLn(f_scr, '');

  WriteLn(f_scr, 'Set Axis = Axes("right axis")');
  WriteLn(f_scr, 'Axis.ShowLabels=False');
  WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
  WriteLn(f_scr, 'Axis.MajorTickLength=0');
  WriteLn(f_scr, '');

  WriteLn(f_scr, 'Set Axis = Axes("left axis")');
  WriteLn(f_scr, 'Axis.ShowLabels=True');
  WriteLn(f_scr, 'Axis.MajorGridLine.ForeColorRGBA.Color =srfColorBlack');
  WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
  WriteLn(f_scr, 'Axis.MajorTickLength=1E-1');
  WriteLn(f_scr, 'Axis.LabelFont.Size=8');
  //WriteLn(f_scr, 'Axis.LabelFormat.Postfix="°"');
  WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack');
  WriteLn(f_scr, 'Axis.SetScale(-90, 90, 10, -90, 90, 1979, 0)');
  WriteLn(f_scr, '');

  WriteLn(f_scr, 'Set PostMap2=Doc.Shapes.AddPostMap(DataFileName:=pathDataFile, _');
  WriteLn(f_scr, '   xCol:=1, _');
  WriteLn(f_scr, '   yCol:=2)');
  WriteLn(f_scr, 'Set sampleMarks = PostMap2.Overlays(1)');
  WriteLn(f_scr, '    With SampleMarks');
  WriteLn(f_scr, '        .LabCol=0');
  WriteLn(f_scr, '        .LabelFont.Size=4');
  WriteLn(f_scr, '        .Symbol.Index=15');
  WriteLn(f_scr, '        .Symbol.Size=0.03');
  WriteLn(f_scr, '        .Symbol.Color=srfColorBlue');
  WriteLn(f_scr, '        .Visible=False');
  WriteLn(f_scr, '        .LabelAngle=0');
  WriteLn(f_scr, '    End With');
  WriteLn(f_scr, '');

  WriteLn(f_scr, 'Doc.Shapes.SelectAll');
  WriteLn(f_scr, 'Set NewMap = Doc.Selection.OverlayMaps');
  WriteLn(f_scr, 'With NewMap');
  WriteLn(f_scr, '.xLength=20');
  WriteLn(f_scr, '.yLength=10');
  WriteLn(f_scr, 'End With');
  WriteLn(f_scr, '');

  WriteLn(f_scr, 'Set ContourMap = NewMap.Overlays(1)');
  WriteLn(f_scr, 'With ContourMap');
  WriteLn(f_scr, '.FillContours = True');
  WriteLn(f_scr, '.ShowColorScale = True');
  WriteLn(f_scr, '.ColorScale.Top = NewMap.Top-0.2');
  WriteLn(f_scr, '.ColorScale.Height = NewMap.Height-0.4');
  WriteLn(f_scr, '.ColorScale.Left = NewMap.Left+NewMap.Width+0.2');
  WriteLn(f_scr, '.ColorScale.FrameLine.Style = "Invisible"');
  WriteLn(f_scr, '.ColorScale.LabelFrequency=5');
  (* Заливаем контур *)
   if lvl<>'' then
   WriteLn(f_scr, '  .Levels.LoadFile("'+lvl+'")');
   (* Добавляем цвет в контуры *)
   if clr<>'' then
   WriteLn(f_scr, '  .FillForegroundColorMap.LoadFile("'+clr+'")');
  WriteLn(f_scr, 'End With');
  WriteLn(f_scr, '');

  WriteLn(f_scr, 'Doc.Export(FileName:="'+FilePath+'png\'+FileName+'.png", _');
  WriteLn(f_scr, 'SelectionOnly:=False , Options:="Width=720; KeepAspect=1; HDPI=300; VDPI=300")');
  WriteLn(f_scr, '');
  WriteLn(f_scr, 'Diagram.Zoom(srfZoomFitToWindow)');
  WriteLn(f_scr, 'Diagram.AutoRedraw = True');
  WriteLn(f_scr, '');
  WriteLn(f_scr, 'Doc.SaveAs(FileName:="'+FilePath+'srf\'+FileName+'.srf")');
  WriteLn(f_scr, 'Doc.Close(SaveChanges:=srfSaveChangesNo) ');
  WriteLn(f_scr, 'End Sub');
 finally
  closefile(f_scr);
 end;
end;

end.

