unit surfer_nctld;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, ncmain;

(* Time-Level diagrams for common NetCDF *)
procedure GetTLDScript(src:string; xCol, yCol, zCol, NCols, NRows:integer;
          mindate, maxdate, maxlev:real);


implementation


(* Time-Level diagrams for common NetCDF *)
procedure GetTLDScript(src:string; xCol, yCol, zCol, NCols, NRows:integer; mindate, maxdate, maxlev:real);
Var
  Ini:TIniFile;
  f_scr:text;
  c, k: integer;
  koef: real;
  DFile, DPath, buf_str, IntMethod: string;
  yy_min, yy_max, mn_min, mn_max: integer;
begin
 DFile:=ExtractFileName(src);
 DPath:=ExtractFilePath(src);

//  koef := (maxdate - mindate) / maxlev; // Определяем коэффициент

  Ini := TIniFile.Create(IniFileName); // settings from file
  IntMethod:=Ini.ReadString('ncTLD', 'Algorithm', 'srfKriging');

  AssignFile(f_scr, DPath+'script.bas');
  rewrite(f_scr);

  writeln(f_scr, 'Sub Main');
  writeln(f_scr, 'Dim Surf, Diagram, Doc As Object');
  writeln(f_scr, '');
  writeln(f_scr, 'pathDataFile ="' + src + '"');
  writeln(f_scr, 'PathGRD = "' + DPath + 'Grid.grd"');
  WriteLn(f_scr, 'pathBlnFile ="'+DPath+'Blank.bln"');
  writeln(f_scr, '');
  writeln(f_scr, 'Set Surf = CreateObject("Surfer.Application") ');
  writeln(f_scr, '');
  writeln(f_scr, 'Surf.Visible = True');
  writeln(f_scr, '  Set Doc = Surf.Documents.Add ');
  writeln(f_scr, '  Set Diagram = Doc.Windows(1)');
  writeln(f_scr, '  Diagram.AutoRedraw = False');
  writeln(f_scr, '  Doc.PageSetup.Orientation = srfPortrait');
  writeln(f_scr, '  Doc.DefaultFill.Pattern="Solid"');
  writeln(f_scr, '  Doc.DefaultFill.ForeColor=srfColorBlack20');
  writeln(f_scr, '');

  // создание грида
  writeln(f_scr, 'Surf.GridData(DataFile:=pathDataFile, _');
  writeln(f_scr, '   xCol:='+Inttostr(xCol)+', _');
  writeln(f_scr, '   yCol:='+Inttostr(yCol)+', _');
  writeln(f_scr, '   zCol:='+Inttostr(zCol)+', _');
  WriteLn(f_scr, '   Algorithm:='+IntMethod+', _');
  WriteLn(f_scr, '   NumCols:='+inttostr(NCols+1)+', _');
  WriteLn(f_scr, '   Numrows:='+inttostr(NRows+1)+', _');

(* Настройки для различных методов интерполяции *)
  if IntMethod='srfKriging'  then begin
    WriteLn(f_scr, '       KrigType:='         +Ini.ReadString('ncTLD', 'KrigType',          'srfKrigPoint')+', _');
    WriteLn(f_scr, '       KrigDriftType:='    +Ini.ReadString('ncTLD', 'KrigDriftType',     'srfDriftNone')+', _');
    if Ini.ReadBool('ncTLD', 'SearchEnable', true)=true then begin
     WriteLn(f_scr, '       SearchEnable:=1, _');  //not Ini.ReadBool(IniSet, 'SearchEnable',       true);
     WriteLn(f_scr, '       SearchNumSectors:=' +Ini.ReadString('ncTLD', 'SearchNumSectors',  '4')  +', _');
     WriteLn(f_scr, '       SearchMinData:='    +Ini.ReadString('ncTLD', 'SearchMinData',     '16') +', _');
     WriteLn(f_scr, '       SearchMaxData:='    +Ini.ReadString('ncTLD', 'SearchMaxData',     '64') +', _');
     WriteLn(f_scr, '       SearchDataPerSect:='+Ini.ReadString('ncTLD', 'SearchDataPerSect', '8')  +', _');
     WriteLn(f_scr, '       SearchMaxEmpty:='   +Ini.ReadString('ncTLD', 'SearchMaxEmpty',    '3')  +', _');
     WriteLn(f_scr, '       SearchRad1:='       +Ini.ReadString('ncTLD', 'SearchRad1',        '1')  +', _');
     WriteLn(f_scr, '       SearchRad2:='       +Ini.ReadString('ncTLD', 'SearchRad2',        '1')  +', _');
     WriteLn(f_scr, '       SearchAngle:='      +Ini.ReadString('ncTLD', 'SearchAngle',       '0')  +', _');
    end;
  end;
  if IntMethod='srfInverseDistanse' then begin
    WriteLn(f_scr, '       SearchEnable:='       +Ini.ReadString('ncTLD', 'SearchEnable',      '0')  +', _');
    WriteLn(f_scr, '       SearchNumSectors:='   +Ini.ReadString('ncTLD', 'SearchNumSectors',  '4')  +', _');
    WriteLn(f_scr, '       SearchMinData:='      +Ini.ReadString('ncTLD', 'SearchMinData',     '16') +', _');
    WriteLn(f_scr, '       SearchMaxData:='      +Ini.ReadString('ncTLD', 'SearchMaxData',     '64') +', _');
    WriteLn(f_scr, '       SearchDataPerSect:='  +Ini.ReadString('ncTLD', 'SearchDataPerSect', '8')  +', _');
    WriteLn(f_scr, '       SearchMaxEmpty:='     +Ini.ReadString('ncTLD', 'SearchMaxEmpty',    '3')  +', _');
    WriteLn(f_scr, '       SearchRad1:='         +Ini.ReadString('ncTLD', 'SearchRad1',        '1')  +', _');
    WriteLn(f_scr, '       SearchRad2:='         +Ini.ReadString('ncTLD', 'SearchRad2',        '1')  +', _');
    WriteLn(f_scr, '       SearchAngle:='        +Ini.ReadString('ncTLD', 'SearchAngle',       '0')  +', _');
    WriteLn(f_scr, '       AnisotropyRatio:='    +Ini.ReadString('ncTLD', 'AnisotropyRatio',   '1')  +', _');
    WriteLn(f_scr, '       AnisotropyAngle:='    +Ini.ReadString('ncTLD', 'AnisotropyAngle',   '0')  +', _');
    WriteLn(f_scr, '       IDPower:='            +Ini.ReadString('ncTLD', 'IDPower',           '2')  +', _');
    WriteLn(f_scr, '       IDSmoothing:='        +Ini.ReadString('ncTLD', 'IDSmoothing',       '0')  +', _');
  end;
  if IntMethod='srfNaturalNeighbor' then begin
    WriteLn(f_scr, '       AnisotropyRatio:='    +Ini.ReadString('ncTLD', 'AnisotropyRatio',   '1')  +', _');
    WriteLn(f_scr, '       AnisotropyAngle:='    +Ini.ReadString('ncTLD', 'AnisotropyAngle',   '0')  +', _');
  end;
  if IntMethod='srfNearestNeighbor' then begin
    WriteLn(f_scr, '       SearchRad1:='         +Ini.ReadString('ncTLD', 'SearchRad1',        '1')  +', _');
    WriteLn(f_scr, '       SearchRad2:='         +Ini.ReadString('ncTLD', 'SearchRad2',        '1')  +', _');
    WriteLn(f_scr, '       SearchAngle:='        +Ini.ReadString('ncTLD', 'SearchAngle',       '0')  +', _');
  end;
  if IntMethod='srfMinCurvature' then begin
    WriteLn(f_scr, '       MCMaxResidual:='      +Ini.ReadString('ncTLD', 'MCMaxResidual',     '1E-9')+', _');
    WriteLn(f_scr, '       MCMaxIterations:='    +Ini.ReadString('ncTLD', 'MCMaxIterations',   '1E+5')+', _');
    WriteLn(f_scr, '       MCInternalTension:='  +Ini.ReadString('ncTLD', 'MCInternalTension', '1')  +', _');
    WriteLn(f_scr, '       MCBoundaryTension:='  +Ini.ReadString('ncTLD', 'MCBoundaryTension', '0')  +', _');
    WriteLn(f_scr, '       MCRelaxationFactor:=' +Ini.ReadString('ncTLD', 'MCRelaxationFactor','0')  +', _');
    WriteLn(f_scr, '       AnisotropyRatio:='    +Ini.ReadString('ncTLD', 'AnisotropyRatio',   '1')  +', _');
    WriteLn(f_scr, '       AnisotropyAngle:='    +Ini.ReadString('ncTLD', 'AnisotropyAngle',   '0')  +', _');
  end;
  if IntMethod='srfRadialBasis' then begin
    WriteLn(f_scr, '       AnisotropyRatio:='    +Ini.ReadString('ncTLD', 'AnisotropyRatio',   '1')  +', _');
    WriteLn(f_scr, '       AnisotropyAngle:='    +Ini.ReadString('ncTLD', 'AnisotropyAngle',   '0')  +', _');
  end;
  if IntMethod='srfTriangulation' then begin
    WriteLn(f_scr, '       AnisotropyRatio:='    +Ini.ReadString('ncTLD', 'AnisotropyRatio',   '1')  +', _');
    WriteLn(f_scr, '       AnisotropyAngle:='    +Ini.ReadString('ncTLD', 'AnisotropyAngle',   '0')  +', _');
  end;
  if IntMethod='srfInverseDistanse' then begin
    WriteLn(f_scr, '       SearchMinData:='      +Ini.ReadString('ncTLD', 'SearchMinData',     '16') +', _');
    WriteLn(f_scr, '       SearchRad1:='         +Ini.ReadString('ncTLD', 'SearchRad1',        '1')  +', _');
    WriteLn(f_scr, '       SearchRad2:='         +Ini.ReadString('ncTLD', 'SearchRad2',        '1')  +', _');
    WriteLn(f_scr, '       SearchAngle:='        +Ini.ReadString('ncTLD', 'SearchAngle',       '0')  +', _');
  end;
    WriteLn(f_scr, '       DupMethod:=srfDupNone, _');
    WriteLn(f_scr, '       ExclusionFilter:="z='+Ini.ReadString('ncTLD', 'MissingVal', '-9999')+'", _');
    WriteLn(f_scr, '       ShowReport:=False, _');
    WriteLn(f_scr, '       OutGrid:=PathGRD)');
    WriteLn(f_scr, '');

    (* Filtering *)
   if Ini.ReadInteger('ncTLD', 'Filter', 0)>0 then begin
    WriteLn(f_scr, 'Surf.GridFilter(InGrid:=PathGRD, _');
		WriteLn(f_scr, '  Filter:=srfFilterGaussian, _');
		WriteLn(f_scr, '  NumPasses:='+Ini.ReadString('ncTLD', 'Filter', '0')+', _');
		WriteLn(f_scr, '  OutGrid:=PathGRD)');
    WriteLn(f_scr, '');
   end;

   {
  // трансформация
  writeln(f_scr, 'Surf.GridTransform(InGrid:=PathGRD, _');
  writeln(f_scr, '  Operation:=srfGridTransScale, _');
  writeln(f_scr, '  XScale:=' + floattostr(koef) + ', _');
  writeln(f_scr, '  YScale:=1, _');
  writeln(f_scr, '  OutGrid:=PathGRD)');
  writeln(f_scr, '');

  // добавление сдвига
  writeln(f_scr, 'Surf.GridTransform(InGrid:=PathGRD, _');
  writeln(f_scr, '  Operation:=srfGridTransOffset, _');
  writeln(f_scr, '  XOffset:=' + floattostr(mindate) + ', _');
  writeln(f_scr, '  YOffset:=1, _');
  writeln(f_scr, '  OutGrid:=PathGRD)');
  writeln(f_scr, '');
  }

  //бланковка по вернему/нижнему минимальному/максимальному горизонтам
  //внутри заданного временного интервала
 { if chkBlank.checked=true then begin

      BlankFile; (* Пишем бланковочный файл на диск *)

     WriteLn(f_scr, 'Surf.GridBlank(InGrid:=PathGRD, _');
     WriteLn(f_scr, '  BlankFile:=pathBlnFile, _');
     WriteLn(f_scr, '  Outgrid:=PathGRD, _');
     WriteLn(f_scr, '  outfmt:=1)');
     WriteLn(f_scr, '');
  end; }

  (* Строим основной плот, убираем верхние и боковые метки*)
  WriteLn(f_scr, 'Set ContourMapFrame=Doc.Shapes.AddContourMap(PathGRD)');
  WriteLn(f_scr, 'Set Axes = ContourMapFrame.Axes');
  WriteLn(f_scr, 'Set Axis = Axes("top axis")');
  WriteLn(f_scr, 'Axis.MajorTickType = srfTickNone');
  WriteLn(f_scr, 'Set Axis = Axes("right axis")');
  WriteLn(f_scr, 'Axis.MajorTickType = srfTickNone');
  WriteLn(f_scr, '');

 // writeln(f_scr, 'Set ContourMapFrame=Doc.Shapes.AddContourMap(PathGRD)');
 // writeln(f_scr, 'Set contour1 = ContourMapFrame.Overlays("Contours") ');
 // writeln(f_scr, '');

  // Набрасываем пост с точками
  writeln(f_scr,
    'Set PostMap2=Doc.Shapes.AddPostMap(DataFileName:=pathDataFile, _');
  writeln(f_scr, '   xCol:='+Inttostr(xCol)+', _');
  writeln(f_scr, '   yCol:='+Inttostr(yCol)+')');
  writeln(f_scr, 'Set sampleMarks = PostMap2.Overlays(1)');
  writeln(f_scr, '    With SampleMarks');
  writeln(f_scr, '        .Visible=false');
  writeln(f_scr, '        .LabelFont.Size=4');
  writeln(f_scr, '        .Symbol.Index=12');
  writeln(f_scr, '        .Symbol.Size=0.05');
  writeln(f_scr, '        .Symbol.Color=srfColorBlack');
  writeln(f_scr, '        .LabelAngle=0');
  writeln(f_scr, '    End With');
  writeln(f_scr, '');

     (* Определяем размеры поля *)
   WriteLn(f_scr, 'X1='+Floattostr(mindate));
   WriteLn(f_scr, 'X2='+Floattostr(maxdate));
   WriteLn(f_scr, 'Y1='+Floattostr(-maxlev));
   WriteLn(f_scr, 'Y2=0');
   WriteLn(f_scr, '');

  writeln(f_scr, 'Doc.Shapes.SelectAll');
  writeln(f_scr, 'Set NewMap = Doc.Selection.OverlayMaps');
  WriteLn(f_scr, 'NewMap.SetLimits(xMin:=X1, xMax:=X2, yMin:=Y1, yMax:=Y2)');
  writeln(f_scr, 'NewMap.xLength=15');
  writeln(f_scr, 'NewMap.yLength=8');
  writeln(f_scr, 'NewMap.Top = 24');
  writeln(f_scr, 'NewMap.Left = 2');
  writeln(f_scr, 'L = NewMap.Left');
  writeln(f_scr, 'B = NewMap.top-NewMap.Height');
  writeln(f_scr, '');

  writeln(f_scr, 'Set ContourMap = NewMap.Overlays(1)');
  writeln(f_scr, 'ContourMap.FillContours = True');
  if Ini.ReadString('ncTLD', 'LevelFile', '')<>'' then
  WriteLn(f_scr, 'ContourMap.Levels.LoadFile("'+GlobalPath+'support\lvl_files\'+
                     Ini.ReadString('ncTLD', 'LevelFile', '')+'")');
  writeln(f_scr, 'ContourMap.ShowColorScale = True');
  writeln(f_scr, 'contourMap.ColorScale.Top = NewMap.Top-0.2');
  writeln(f_scr, 'contourMap.ColorScale.Height = NewMap.Height-0.7');
  writeln(f_scr, 'contourMap.ColorScale.Left = NewMap.Left+NewMap.Width+0.4');
  writeln(f_scr, '');

(*********************** Начало второго плота********************************)
{ if chkKSD.Checked = true then begin
  WriteLn(f_scr, 'Set Doc2=Surf.Documents.Add');
  WriteLn(f_scr, 'Set Diagram2 = Doc2.Windows(1)');
  WriteLn(f_scr, '    Diagram2.AutoRedraw = False');

    // создание грида
  writeln(f_scr, 'Surf.GridData(DataFile:=pathDataFile, _');
  writeln(f_scr, '	 xCol:=2, _');
  writeln(f_scr, '  yCol:=3, _');
  writeln(f_scr, '  zCol:=7, _');
  writeln(f_scr, '  numRows:=' + inttostr(SpinEdit1.Value) + ', _');
  writeln(f_scr, '  numCols:=' + inttostr(SpinEdit2.Value) + ', _');
  writeln(f_scr, '  Algorithm:=' + cbMethod.text + ', _');

  if (cbMethod.text = 'srfKriging') then begin
    writeln(f_scr, '  KrigType:=' + cbKrigType.text + ', _');
    writeln(f_scr, '  KrigDriftType:=' + cbKrigDrift.text + ', _');
    writeln(f_scr, '  SearchEnable:=1, _');
    writeln(f_scr, '  SearchNumSectors:=' + inttostr(seSearchNumSect.Value) + ', _');
    writeln(f_scr, '  SearchMinData:=' + inttostr(seSearchMinData.Value)+ ', _');
    writeln(f_scr, '  SearchMaxData:=' + inttostr(seSearchMaxData.Value)+ ', _');
    writeln(f_scr, '  SearchDataPerSect:=' + inttostr(seSearchDataSect.Value) + ', _');
    writeln(f_scr, '  SearchMaxEmpty:=' + inttostr(seSearchMaxEmpty.Value)+ ', _');
    writeln(f_scr, '  SearchRad1:='  + eSearchEllipseRad1.text + ', _');
    writeln(f_scr, '  SearchRad2:='  + eSearchEllipseRad2.text + ', _');
    writeln(f_scr, '  SearchAngle:=' + seSearchEllipseAngle.Text+ ', _');
    WriteLn(f_scr, '  AnisotropyRatio:='  +eAnisRatio.Text+', _');
    WriteLn(f_scr, '  AnisotropyAngle:='  +seAnisAngle.Text+', _');
  end;

  writeln(f_scr, '  DupMethod:=srfDupNone, _');
  writeln(f_scr, '  ShowReport:=False, _');
  writeln(f_scr, '  OutGrid:=PathGRD)');
  writeln(f_scr, '');

  // фильтрация
  if seFilter.Value > 0 then begin
    writeln(f_scr, 'Surf.GridFilter(InGrid:=PathGRD, _');
    writeln(f_scr, '  Filter:=srfFilterGaussian, _');
    writeln(f_scr, '  NumPasses:=' + inttostr(seFilter.Value) + ', _');
    // число прогонов из формы
    writeln(f_scr, '  OutGrid:=PathGRD)');
    writeln(f_scr, '');
  end;

  // трансформация
  writeln(f_scr, 'Surf.GridTransform(InGrid:=PathGRD, _');
  writeln(f_scr, '  Operation:=srfGridTransScale, _');
  writeln(f_scr, '  XScale:=' + floattostr(koef) + ', _');
  writeln(f_scr, '  YScale:=1, _');
  writeln(f_scr, '  OutGrid:=PathGRD)');
  writeln(f_scr, '');

  // добавление сдвига
  writeln(f_scr, 'Surf.GridTransform(InGrid:=PathGRD, _');
  writeln(f_scr, '  Operation:=srfGridTransOffset, _');
  writeln(f_scr, '  XOffset:=' + floattostr(mindate) + ', _');
  writeln(f_scr, '  YOffset:=1, _');
  writeln(f_scr, '  OutGrid:=PathGRD)');
  writeln(f_scr, '');

  //бланковка по вернему/нижнему минимальному/максимальному горизонтам
  //внутри заданного временного интервала
  if chkBlank.checked=true then begin

      BlankFile; (* Пишем бланковочный файл на диск *)

     WriteLn(f_scr, 'Surf.GridBlank(InGrid:=PathGRD, _');
     WriteLn(f_scr, '  BlankFile:=pathBlnFile, _');
     WriteLn(f_scr, '  Outgrid:=PathGRD, _');
     WriteLn(f_scr, '  outfmt:=1)');
     WriteLn(f_scr, '');
  end;

  (* Строим основной плот, убираем верхние и боковые метки*)
  WriteLn(f_scr, 'Set ContourMapFrame=Doc2.Shapes.AddContourMap(PathGRD)');
  WriteLn(f_scr, 'Set Axes = ContourMapFrame.Axes');
  WriteLn(f_scr, 'Set Axis = Axes("top axis")');
  WriteLn(f_scr, 'Axis.MajorTickType = srfTickNone');
  WriteLn(f_scr, 'Set Axis = Axes("right axis")');
  WriteLn(f_scr, 'Axis.MajorTickType = srfTickNone');
  WriteLn(f_scr, '');

  // Набрасываем пост с точками
  writeln(f_scr,'Set PostMap2=Doc2.Shapes.AddPostMap(DataFileName:=pathDataFile, _');
  writeln(f_scr, '   xCol:=1, _');
  writeln(f_scr, '   yCol:=3)');
  writeln(f_scr, 'Set sampleMarks = PostMap2.Overlays(1)');
  writeln(f_scr, '    With SampleMarks');
  writeln(f_scr, '        .Visible=false');
  writeln(f_scr, '        .LabelFont.Size=4');
  writeln(f_scr, '        .Symbol.Index=12');
  writeln(f_scr, '        .Symbol.Size=0.05');
  writeln(f_scr, '        .Symbol.Color=srfColorBlack');
  writeln(f_scr, '        .LabelAngle=0');
  writeln(f_scr, '    End With');
  writeln(f_scr, '');

  writeln(f_scr, 'Doc2.Shapes.SelectAll');
  writeln(f_scr, 'Set NewMap2 = Doc2.Selection.OverlayMaps');
  writeln(f_scr, '    NewMap2.xLength=15');
  writeln(f_scr, '    NewMap2.yLength=8');
  writeln(f_scr, '    NewMap2.BackgroundFill.Pattern = "6.25% Black"');
  writeln(f_scr, '    NewMap2.BackgroundFill.ForeColor = srfColorBlack30');
  writeln(f_scr, '  L = NewMap2.Left');
  writeln(f_scr, '  B = NewMap2.top-NewMap2.Height');
  writeln(f_scr, '');

  writeln(f_scr, 'Set ContourMap2 = NewMap2.Overlays(1)');
  writeln(f_scr, 'ContourMap2.FillContours = True');
  if cbLvl.ItemIndex > -1 then
   writeln(f_scr,'ContourMap2.Levels.LoadFile("' + LvlPath + cbLvl2.text + '")');
  writeln(f_scr, 'ContourMap2.ShowColorScale = True');
  writeln(f_scr, 'contourMap2.ColorScale.Top = NewMap2.Top-0.2');
  writeln(f_scr, 'contourMap2.ColorScale.Height = NewMap2.Height-0.7');
  writeln(f_scr, 'contourMap2.ColorScale.Left = NewMap2.Left+NewMap2.Width+0.4');

  WriteLn(f_scr, ' Doc2.Shapes.SelectAll');
  WriteLn(f_scr, ' Doc2.Selection.Copy');
  WriteLn(f_scr, ' Set selection2 =Doc.Shapes.Paste(Format:=srfPasteBest)');

  WriteLn(f_scr, ' With selection2');
  WriteLn(f_scr, '   .Top  = 14');
  WriteLn(f_scr, '   .Left = 2.2');
  WriteLn(f_scr, ' End With');
  WriteLn(f_scr, 'Doc2.Close(SaveChanges:=srfSaveChangesNo)');
  WriteLn(f_scr, '');

 (***********************Окончание второго плота********************************)
  end;     }

  writeln(f_scr, 'Diagram.Zoom(srfZoomFitToWindow)');
  writeln(f_scr, 'Diagram.AutoRedraw = True');
  writeln(f_scr, '');
  writeln(f_scr, 'End Sub');
  CloseFile(f_scr);
end;

end.

