unit surfer_ncfields;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, dialogs, ncmain, ncsections, ncxyz2grd;

procedure MakeGRD(IniSet, fieldpath, src, grd, contour, basemap2:string;
          ncols, nrows:integer; prj:integer; curv: boolean);

procedure GetncFieldScript(fieldpath, src1, src2, src3, grd1, grd2, grd3, lvl,
          clr, contour, basemap2:string; ncols,nrows:integer; RegEnabled:boolean;
          XMin, XMax, YMin, YMax: real; ncexportfile:string; ncFieldsAuto:boolean;
          prj:integer; Lev:string; ice:boolean; curv: boolean);

implementation


procedure MakeGRD(IniSet, fieldpath, src, grd, contour, basemap2:string;
          ncols, nrows:integer; prj:integer; curv: boolean);
Var
 Ini:TIniFile;
 f_scr:text;
 IntMethod:string;
begin
AssignFile(f_scr, FieldPath+'script.bas'); append(f_scr);  // script file
Ini := TIniFile.Create(IniFileName); // settings from file

contour:=StringReplace(contour, 'gsb', 'bln', []);

try
 (* If coordinates are curvelinear or projected then gridding *)
 if (curv=true) or (prj>0) then begin
  IntMethod:=Ini.ReadString(IniSet, 'Algorithm', 'srfKriging');

   WriteLn(f_scr, 'Surfer.GridData(DataFile:="'+src+'", _');
   if prj=0 then begin
     WriteLn(f_scr, '       xCol:=2, _');
     WriteLn(f_scr, '       yCol:=1, _');
   end;
   if prj>0 then begin
     WriteLn(f_scr, '       xCol:=4, _');
     WriteLn(f_scr, '       yCol:=3, _');
   end;
   WriteLn(f_scr, '       zCol:=5, _');
   WriteLn(f_scr, '       Algorithm:='        +IntMethod+', _');
   WriteLn(f_scr, '       NumCols:='          +inttostr(ncols)+', _');
   WriteLn(f_scr, '       Numrows:='          +inttostr(nrows)+', _');

(* Настройки для различных методов интерполяции *)
 if IntMethod='srfKriging'  then begin
   WriteLn(f_scr, '       KrigType:='         +Ini.ReadString(IniSet, 'KrigType',          'srfKrigPoint')+', _');
   WriteLn(f_scr, '       KrigDriftType:='    +Ini.ReadString(IniSet, 'KrigDriftType',     'srfDriftNone')+', _');
   if Ini.ReadBool(IniSet, 'SearchEnable', false)=true then begin
    WriteLn(f_scr, '       SearchEnable:=1, _');
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
  if Ini.ReadBool(IniSet, 'SearchEnable', false)=true then begin
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
  end;
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
   WriteLn(f_scr, '       OutGrid:="'+grd+'")');
   WriteLn(f_scr, '');
end;

 (* If coordinates are linear and on grid *)
  if (curv=false) and (prj=0) then begin
    _xyz2grd(src, grd);
     frmmain.RunScript(1, ExtractFilePath(grd)+'script.py', nil);
  end;

(* Filtering *)
   if Ini.ReadInteger(IniSet, 'Filter', 0)>0 then begin
    WriteLn(f_scr, 'Surfer.GridFilter(InGrid:="'+grd+'", _');
    WriteLn(f_scr, '  Filter:=srfFilterGaussian, _');
    WriteLn(f_scr, '  NumPasses:='+Ini.ReadString(IniSet, 'Filter', '0')+', _');    //число прогонов из формы
    WriteLn(f_scr, '  OutGrid:="'+grd+'")');
    WriteLn(f_scr, '');
   end;

   (* Бланкуем по берегам *)
    WriteLn(f_scr, 'Surfer.GridBlank(InGrid:="'+grd+'", _');
    WriteLn(f_scr, '       BlankFile:="'+contour+'", _');
    WriteLn(f_scr, '       OutGrid:="'+grd+'", _');
    WriteLn(f_scr, '       OutFmt:=1)');
    WriteLn(f_scr, '');

    (* Бланкуем по доп. топографии *)
 {  if basemap2<>'' then begin
    WriteLn(f_scr, 'Surfer.GridBlank(InGrid:="'+grd+'", _');
    WriteLn(f_scr, '       BlankFile:="'+basemap2+'", _');
    WriteLn(f_scr, '       OutGrid:="'+grd+'", _');
    WriteLn(f_scr, '       OutFmt:=1)');
    WriteLn(f_scr, '');
    end;  }

 finally
   Ini.free;
   CloseFile(f_scr);
 end;
end;



(* Fields for common NetCDF *)
procedure GetncFieldScript(fieldpath, src1, src2, src3, grd1, grd2, grd3, lvl,
          clr, contour, basemap2:string; ncols,nrows:integer; RegEnabled: boolean;
          XMin, XMax, YMin, YMax: real; ncexportfile:string; ncFieldsAuto:boolean;
          prj:integer; Lev:string; ice:boolean; curv:boolean);
(* IniDat - initial data
   src =source file
   lev =level to plot
   clr =colour file for Surfer
   ncexportfile=name of export *.png and *.srf
   ncFieldsAuto=auto calculation flag
*)
Var
 Ini:TIniFile;
 IniSet, PolarGrd, PolarAdd, extra_grid:string;
 f_scr:text;
 a, b, c, d:real;
begin
 IniSet:='ncfields';

    //projection: 0=Mercator, 1-Arctic, 2-Antarctic

     if (prj=0) then
       Contour:=GlobalSupportPath+'bln'+PathDelim+'World.gsb';

     if (prj=1) then begin
       Contour :=GlobalPath+lowercase('support\bln\Arctic_polar.bln');
       PolarGrd:=GlobalPath+lowercase('support\bln\Arctic_polar_net.bln');

       if RegEnabled=false then begin
        XMin:=-5000; XMax:= 5000;
        YMin:=-5000; YMax:= 5000;
       end;
       if RegEnabled=true then begin
        XMin:=-5000; XMax:= 5000;
        YMin:=-5000; YMax:= 5000;
      //   XMin:=-1500; XMax:= 2600;
      //   YMin:=-3000; YMax:= 500;

        // XMin:=-1000; XMax:= 1500;
      //   YMin:=-1700; YMax:= 0;

   {     a:=xmin; b:=xmax; c:=ymin; d:=ymax;
        XMin:=round( (90-c)*111.12*sin((a)*Pi/180));
        XMax:=round(-(90-c)*111.12*cos((b)*Pi/180));

        YMin:=round(-(90-c)*111.12*cos((b)*Pi/180));
        YMax:=round((90-d)*111.12*sin((a)*Pi/180));


      //  XMax:=round(-(90-YMin)*111.12*cos((XMax)*Pi/180));
      //  YMax:=round( (90-YMax)*111.12*sin((XMin)*Pi/180));
      //  YMin:=round(-(90-YMax)*111.12*cos((XMax)*Pi/180));  }
       end;
     end;

     if (prj=2) then begin
       Contour :=GlobalPath+lowercase('support\bln\Antarctic_polar.bln');
       PolarGrd:=GlobalPath+lowercase('support\bln\Antarctic_polar_net.bln');
       PolarAdd:=GlobalPath+lowercase('support\bln\Antarctic_polar_add.bln');

        XMin:=-60; XMax:= 60;
        YMin:=-60; YMax:= 60;
     end;

 try
  AssignFile(f_scr, FieldPath+'script.bas'); rewrite(f_scr);  // script file

   WriteLn(f_scr, 'Sub Main');
   WriteLn(f_scr, 'Dim Surfer, Diagram, Doc As Object');
   WriteLn(f_scr, '');

   WriteLn(f_scr, 'Set Surfer=CreateObject("Surfer.Application")');

   if ncFieldsAuto=false then
   WriteLn(f_scr, '    Surfer.Visible=True');

   WriteLn(f_scr, 'Set Doc=Surfer.Documents.Add');
   WriteLn(f_scr, '    Doc.PageSetup.Orientation = srfLandscape');

   WriteLn(f_scr, 'Set Diagram = Doc.Windows(1)');
   WriteLn(f_scr, '    Diagram.AutoRedraw = False');
   WriteLn(f_scr, '');
  CloseFile(f_scr);


  if src2='' then begin
   MakeGRD(iniset, fieldpath, src1, grd1, Contour, basemap2, ncols, nrows, prj, curv);
  end;

  if src2<>'' then begin
   MakeGRD(iniset, fieldpath, src1, grd1, Contour, basemap2, ncols, nrows, prj, curv);
   MakeGRD(iniset, fieldpath, src2, grd2, Contour, basemap2, ncols, nrows, prj, curv);
   MakeGRD(iniset, fieldpath, src3, grd3, Contour, basemap2, ncols, nrows, prj, curv);
  end;


  Ini := TIniFile.Create(IniFileName); // settings from file
  AssignFile(f_scr, FieldPath+'script.bas'); append(f_scr);  // script file


   (* Вставляем основной контур *)
   WriteLn(f_scr, 'Set ContourMap=Doc.Shapes.AddContourMap("'+grd1+'")');


   (* Убираем верхние и боковые метки с основного плота*)
   WriteLn(f_scr, 'Set Axes = ContourMap.Axes');

   if prj=0 then begin
    WriteLn(f_scr, 'Set Axis = Axes("top axis")');
    WriteLn(f_scr, 'Axis.ShowLabels=False');
    WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
    WriteLn(f_scr, 'Axis.MajorTickLength=0');
    WriteLn(f_scr, 'Axis.LabelFont.Size=8');
    WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack');
   end;
   if prj>0 then begin
    WriteLn(f_scr, 'Set Axis = Axes("top axis")');
    WriteLn(f_scr, 'Axis.Visible=False');
   end;

   if RegEnabled=true then WriteLn(f_scr, 'Axis.SetScale('+
                                       floattostr(XMin)+','+
                                       floattostr(XMax)+','+
                                       Ini.ReadString(IniSet, 'IntervalX', '20')+','+
                                       floattostr(XMin)+','+
                                       floattostr(XMax)+','+
                                       floattostr(YMax)+','+
                                       '0)');
   WriteLn(f_scr, '');

   if prj=0 then begin
    WriteLn(f_scr, 'Set Axis = Axes("bottom axis")');
    WriteLn(f_scr, 'Axis.ShowLabels=True');
    Writeln(f_scr, 'Axis.ShowMajorGridLines=True');
    WriteLn(f_scr, 'Axis.MajorGridLine.ForeColorRGBA.Color =srfColorBlack50');
    WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
    WriteLn(f_scr, 'Axis.MajorTickLength=1E-1');
    WriteLn(f_scr, 'Axis.LabelFont.Size=8');
    WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack');
   end;
   if prj>0 then begin
    WriteLn(f_scr, 'Set Axis = Axes("bottom axis")');
    WriteLn(f_scr, 'Axis.Visible=False');
   end;

   if RegEnabled=true then WriteLn(f_scr, 'Axis.SetScale('+
                                      floattostr(XMin)+','+
                                      floattostr(XMax)+','+
                                      Ini.ReadString(IniSet, 'IntervalX', '20')+','+
                                      floattostr(XMin)+','+
                                      floattostr(XMax)+','+
                                      floattostr(YMin)+','+
                                      '0)');
   WriteLn(f_scr, '');

   if prj=0 then begin
    WriteLn(f_scr, 'Set Axis = Axes("right axis")');
    WriteLn(f_scr, 'Axis.ShowLabels=False');
    WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
    WriteLn(f_scr, 'Axis.MajorTickLength=0');
    WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack');
   end;
   if prj>0 then begin
    WriteLn(f_scr, 'Set Axis = Axes("right axis")');
    WriteLn(f_scr, 'Axis.Visible=False');
   end;
   if RegEnabled=true then WriteLn(f_scr, 'Axis.SetScale('+
                                       floattostr(YMin)+','+
                                       floattostr(YMax)+','+
                                       Ini.ReadString(IniSet, 'IntervalY', '5')+','+
                                       floattostr(YMin)+','+
                                       floattostr(YMax)+','+
                                       floattostr(XMax)+','+
                                       '0)');
   WriteLn(f_scr, '');

   if prj=0 then begin
    WriteLn(f_scr, 'Set Axis = Axes("left axis")');
    WriteLn(f_scr, 'Axis.ShowLabels=True');
    Writeln(f_scr, 'Axis.ShowMajorGridLines=True');
    WriteLn(f_scr, 'Axis.MajorGridLine.ForeColorRGBA.Color =srfColorBlack50');
    WriteLn(f_scr, 'Axis.AxisLine.ForeColorRGBA.Color = srfColorBlack50');
    WriteLn(f_scr, 'Axis.MajorTickLength=1E-1');
    WriteLn(f_scr, 'Axis.LabelFont.Size=8');
   //  WriteLn(f_scr, 'Axis.LabelFormat.Postfix="°"');
    WriteLn(f_scr, 'Axis.LabelFont.Color= srfColorBlack');
   end;
   if prj>0 then begin
    WriteLn(f_scr, 'Set Axis = Axes("left axis")');
    WriteLn(f_scr, 'Axis.Visible=False');
   end;
   if RegEnabled=true then WriteLn(f_scr, 'Axis.SetScale('+
                                       floattostr(YMin)+','+
                                       floattostr(YMax)+','+
                                       Ini.ReadString(IniSet, 'IntervalY', '5')+','+
                                       floattostr(YMin)+','+
                                       floattostr(YMax)+','+
                                       floattostr(XMin)+','+
                                       '0)');


   WriteLn(f_scr, '');

   (* Заполняем горизонт для океанографических данных *)
  if Lev<>'' then begin
   if prj=1 then extra_grid:=GlobalPath+'support\grd\polar.grd';
   if prj=0 then extra_grid:=GlobalPath+'support\grd\mercator.grd';
    if FileExists(extra_grid) then begin
      WriteLn(f_scr, 'Set ContourMap=Doc.Shapes.AddContourMap("'+extra_grid+'")');
      WriteLn(f_scr, '');
    end;
  end;

  (* Добавляем векторное поле*)
  if src2<>'' then
   WriteLn(f_scr, 'Set VectorMap=Doc.Shapes.AddVectorMap("'+grd2+'", "'+grd3+'")');


  if ice=true then begin
   WriteLn(f_scr, 'Surfer.GridData(DataFile:="'+FieldPath+'ice.dat", _');
   WriteLn(f_scr, '       xCol:=4, _');
   WriteLn(f_scr, '       yCol:=3, _');
   WriteLn(f_scr, '       zCol:=5, _');
   WriteLn(f_scr, '       Algorithm:=srfKriging, _');
   WriteLn(f_scr, '       NumCols:=100, _');
   WriteLn(f_scr, '       Numrows:=100, _');
   WriteLn(f_scr, '       KrigType:=srfKrigPoint, _');
   WriteLn(f_scr, '       KrigDriftType:=srfDriftNone, _');
   WriteLn(f_scr, '       DupMethod:=srfDupNone, _');
   WriteLn(f_scr, '       ShowReport:=False, _');
   WriteLn(f_scr, '       OutGrid:="'+FieldPath+'ice.grd")');
   WriteLn(f_scr, '');
   WriteLn(f_scr, 'Surfer.GridBlank(InGrid:="'+FieldPath+'ice.grd", _');
   WriteLn(f_scr, '       BlankFile:="'+contour+'", _');
   WriteLn(f_scr, '       OutGrid:="'+FieldPath+'ice.grd", _');
   WriteLn(f_scr, '       OutFmt:=1)');
   WriteLn(f_scr, '');
   WriteLn(f_scr, 'Set ContourMapIce=Doc.Shapes.AddContourMap("'+FieldPath+'ice.grd")');
   WriteLn(f_scr, 'Set ContourMapIce1 = ContourMapIce.Overlays(1)');
   WriteLn(f_scr, '    ContourMapIce1.Levels.LoadFile("'+GlobalPath+'support\ice\ice.lvl")');
   WriteLn(f_scr, '');
  end;

    (* Пост со значениями*)
   WriteLn(f_scr, 'Set PostMap=Doc.Shapes.AddPostMap(DataFileName:="'+src1+'", _');
   if prj=0 then begin
     WriteLn(f_scr, 'xCol:=2, _');
     WriteLn(f_scr, 'yCol:=1)');
   end;
   if prj>0 then begin
     WriteLn(f_scr, 'xCol:=4, _');
     WriteLn(f_scr, 'yCol:=3)');
   end;
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


   (* Определяем размеры поля *)
   WriteLn(f_scr, 'Doc.Shapes.SelectAll');
   WriteLn(f_scr, 'Set Border = Doc.Selection.OverlayMaps');
   if RegEnabled=true then begin
     WriteLn(f_scr, 'X1='+Floattostr(XMin));
     WriteLn(f_scr, 'X2='+Floattostr(XMax));
     WriteLn(f_scr, 'Y1='+Floattostr(YMin));
     WriteLn(f_scr, 'Y2='+Floattostr(YMax));
   end else begin
     WriteLn(f_scr, 'X1=Border.xMin');
     WriteLn(f_scr, 'X2=Border.xMax');
     WriteLn(f_scr, 'Y1=Border.yMin');
     WriteLn(f_scr, 'Y2=Border.yMax');
   end;
   WriteLn(f_scr, '');

  (* Карта - подложка: дополнительный контур с топографией *)
  if basemap2<>'' then begin
   WriteLn(f_scr, 'Set BaseMap=Doc.Shapes.AddBaseMap("'+basemap2+'")');
   WriteLn(f_scr, 'Set BaseMap2 = BaseMap.Overlays(1)');
    if Ini.ReadBool(IniSet, 'ContBackground', true)=true then begin
     WriteLn(f_scr, 'BaseMap2.Fill.Pattern="Solid"');
     WriteLn(f_scr, 'BaseMap2.Line.Style = "Invisible"');
     WriteLn(f_scr, 'BaseMap2.Fill.ForeColor=srfColorBlack10');
     WriteLn(f_scr, '');
    end;
  end;

   (* Карта - подложка: берега на нулевой изобате *)
   WriteLn(f_scr, 'Set BaseMap=Doc.Shapes.AddBaseMap("'+Contour+'")');
   WriteLn(f_scr, 'Set BaseMap1 = BaseMap.Overlays(1)');
   WriteLn(f_scr, 'BaseMap1.Fill.Pattern="Solid"');
   WriteLn(f_scr, 'BaseMap1.Fill.ForeColor=srfColorBlack40');
   WriteLn(f_scr, 'BaseMap1.Line.ForeColorRGBA.Color=srfColorBlack80');
   WriteLn(f_scr, '');


  if prj=2 then begin
   WriteLn(f_scr, 'Set BaseMap=Doc.Shapes.AddBaseMap("'+PolarAdd+'")');
   WriteLn(f_scr, 'Set BaseMap1 = BaseMap.Overlays(1)');
   WriteLn(f_scr, 'BaseMap1.Line.ForeColorRGBA.Color=srfColorWhite');
   WriteLn(f_scr, 'BaseMap1.Fill.Pattern="Solid"');
   WriteLn(f_scr, 'BaseMap1.Fill.ForeColor=srfColorWhite');
   WriteLn(f_scr, '');
  end;

  if prj>0 then begin
   WriteLn(f_scr, 'Set BaseMap=Doc.Shapes.AddBaseMap("'+PolarGrd+'")');
   WriteLn(f_scr, 'Set BaseMap1 = BaseMap.Overlays(1)');
   WriteLn(f_scr, 'BaseMap1.Line.ForeColorRGBA.Color=srfColorBlack50');
   WriteLn(f_scr, '');
  end;

   (* Объединяем и задаём общие свойства *)
   WriteLn(f_scr, 'Doc.Shapes.SelectAll');
   WriteLn(f_scr, 'Set NewMap = Doc.Selection.OverlayMaps');
   WriteLn(f_scr, 'With NewMap');
   WriteLn(f_scr, '  .SetLimits(xMin:=X1, xMax:=X2, yMin:=Y1, yMax:=Y2)');
   if prj=0 then begin
     WriteLn(f_scr, '  .xLength= '+Ini.ReadString(IniSet, 'PlotWidth', '23'));
     WriteLn(f_scr, '  .yLength= '+Ini.ReadString(IniSet, 'PlotHeight', '10'));
     WriteLn(f_scr, '  .Top= 18');
     WriteLn(f_scr, '  .Left= 2');
     WriteLn(f_scr, '  .BackgroundFill.Pattern = "10 Percent"');
     WriteLn(f_scr, '  .BackgroundFill.ForeColor = srfGold');
   end;
   if prj>0 then begin
    WriteLn(f_scr, '  .xLength= 15');
    WriteLn(f_scr, '  .yLength= 15');
  //  WriteLn(f_scr, '  .Top= 26.5');
   // WriteLn(f_scr, '  .Left= 5');
   end;
   WriteLn(f_scr, '    L = .Left');
   WriteLn(f_scr, '    B = .Top-.Height');
   WriteLn(f_scr, 'End With');
   WriteLn(f_scr, '');

 //  showmessage('here8');

   WriteLn(f_scr, 'Set ContourMap = NewMap.Overlays(1)');
   WriteLn(f_scr, 'With ContourMap');
   WriteLn(f_scr, '  .FillContours = True');
   if Ini.ReadBool(IniSet, 'ColourScaleShow', true) =true then begin
     WriteLn(f_scr, '  .ShowColorScale = True');
    { WriteLn(f_scr, '  .ColorScale.Top = NewMap.Top');
      if prj=0 then begin
       WriteLn(f_scr, '  .ColorScale.Left = NewMap.Left+NewMap.Width+0.4');
       WriteLn(f_scr, '  .ColorScale.Height = NewMap.Height-0.8');
      end;
      if prj>0  then begin
       WriteLn(f_scr, '  .ColorScale.Left = NewMap.Left+NewMap.Width+1');
     end; }
    WriteLn(f_scr, '  .ColorScale.FrameLine.Style = "Invisible"');
    WriteLn(f_scr, '  .ColorScale.LabelFrequency='+Ini.ReadString(IniSet, 'ColourScaleLbFreq', '5'));
   end; // colour scale

 //  showmessage('here9');

   (* Заливаем контур *)
   if lvl<>'' then
   WriteLn(f_scr, '  .Levels.LoadFile("'+lvl+'")');

 //  showmessage('here10');

   (* Добавляем цвет в контуры *)
   if clr<>'' then
   WriteLn(f_scr, '  .FillForegroundColorMap.LoadFile("'+clr+'")');
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

 //  showmessage('here10');

   if (Lev<>'') and (FileExists(extra_grid)=true) then begin
    if src2='' then begin
      WriteLn(f_scr, 'Set ContourMap = NewMap.Overlays(2)');
      WriteLn(f_scr, 'With ContourMap');
      WriteLn(f_scr, '  .FillContours = True');
      WriteLn(f_scr, '  .ShowColorScale = False');
      WriteLn(f_scr, '  .Levels.SetLabelFrequency(FirstIndex:=1,NumberToSet :=1,NumberToSkip:=4)');
      WriteLn(f_scr, '  .Levels.AutoGenerate(MinLevel:=-'+Lev+', MaxLevel:=-'+Lev+', Interval:=1)');
      WriteLn(f_scr, 'End With');
      WriteLn(f_scr, 'Set Level = ContourMap.Levels.Item(Index:=1)');
      WriteLn(f_scr, 'Level.Line.Style = "Invisible"');
      WriteLn(f_scr, 'Level.Fill.Pattern="Solid"');
      WriteLn(f_scr, 'Level.Fill.ForeColorRGBA.Color = srfColorBlack20');
    end else WriteLn(f_scr, 'Set ContourMap = NewMap.Overlays(3)');
   end;

 // showmessage('here11');

   if ncExportFile<>'' then begin
     WriteLn(f_scr, 'Doc.Export(FileName:="'+FieldPath+'png\'+ncExportfile+'.png", _');
     WriteLn(f_scr, 'SelectionOnly:=False , Options:="Width=1920; KeepAspect=1; HDPI=300; VDPI=300")');
     WriteLn(f_scr, '');
   end;

   WriteLn(f_scr, 'Diagram.Zoom(srfZoomFitToWindow)');
   WriteLn(f_scr, 'Diagram.AutoRedraw = True');

 // showmessage('here12');

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

