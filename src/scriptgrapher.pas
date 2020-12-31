unit scriptgrapher;

{$mode objfpc}{$H+}

interface

uses
{$IFDEF WINDOWS}
  ComObj,
{$ENDIF}
  Classes, SysUtils, IniFiles, ncmain, nctimeseries;

procedure PlotTimeSeries(fname, title, par, units, xtitle:string; col:integer);

implementation

procedure PlotTimeSeries(fname, title, par, units, xtitle:string; col:integer);
Var
 Ini:TIniFile;
 Script:text;
 running, linear:boolean;
 run_wnd:integer;
 ExportFile:string;
begin

 try
 Ini := TIniFile.Create(IniFileName);
   running:=Ini.ReadBool   ( 'Grapher', 'Running',    true);
   run_wnd:=Ini.ReadInteger( 'Grapher', 'RunWindow',    5);
   linear :=Ini.ReadBool   ( 'Grapher', 'Linear',     true);
 finally
  ini.Free;
 end;

ExportFile:=copy(fname, 1, length(fname)-3);

AssignFile(script, ExtractFilePath(fname)+'script.bas'); rewrite(script);

Writeln(script, 'Sub Main');
Writeln(script, '');
Writeln(script, ' Dim Grapher, Plot, Graph As Object');
Writeln(script, '');
Writeln(script, ' Set Grapher = CreateObject("Grapher.Application")');
if ncTimeSeriesAuto=false then
Writeln(script, ' Grapher.Visible = True');
Writeln(script, '');
Writeln(script, ' Set Plot = Grapher.Documents.Add(grfPlotDoc)');
Writeln(script, '     Plot.PageSetup.Orientation = grfLandscape');
Writeln(script, '');
Writeln(script, 'Set Diagram = Plot.Windows(1)');
Writeln(script, '');
Writeln(script, ' Set Graph = Plot.Shapes.AddLinePlotGraph("'+fname+'", 1, '+inttostr(col)+', "'+Utf8ToAnsi(par)+'")');
Writeln(script, '');
Writeln(script, ' Set Text1 = Plot.Shapes.AddText(3.5,23.5, "'+Utf8ToAnsi(title)+'")');
Writeln(script, '     Text1.Font.Bold = True');
Writeln(script, '');
Writeln(script, ' Graph.Plots.Item(1).Name = '+Utf8ToAnsi('"Time series"'));
Writeln(script, ' Graph.Plots.Item(1).Line.ForeColor = grfColorBlack60');
Writeln(script, '');
 if linear=true then begin
  Writeln(script, ' Set FitCurve1 = Graph.Plots.Item(1).AddFit(0, '+Utf8ToAnsi('"Linear")'));
  Writeln(script, '       FitCurve1.Line.ForeColor=grfColorRed');
  Writeln(script, '       FitCurve1.Line.Width = 6E-2');
  Writeln(script, '');
 end;
 if running=true then begin
  Writeln(script, ' Set FitCurve2 = Graph.Plots.Item(1).AddFit(8, '+Utf8ToAnsi('"Running average")'));
  Writeln(script, '       FitCurve2.Option = '+InttoStr(run_wnd));
  Writeln(script, '       FitCurve2.Line.ForeColor=grfColorBlue');
  Writeln(script, '       FitCurve2.Line.Width = 6E-2');
  Writeln(script, '');
 end;
Writeln(script, 'Set Axes = Graph.Axes');
Writeln(script, '');
Writeln(script, 'Set Axis1 = Axes.Item(1)');
Writeln(script, 'Axis1.Title.Text = '+Utf8ToAnsi('"'+xtitle+'"'));
Writeln(script, 'Axis1.Grid.AtMajorTicks = False');
Writeln(script, 'Axis1.Grid.MajorLine.ForeColor = srfColorBlack30');
Writeln(script, 'Axis1.Ticklabels.MajorOn = True');
//Writeln(script, 'Axis1.TickLabels.mode = grfLabelsDateTime');
//Writeln(script, 'Axis1.TickLabels.DateTime.CustomFormat ="yyyy-MM-ddThh:mm:ss"');
Writeln(script, 'Axis1.Ticklabels.MajorFont.Size=10');
Writeln(script, 'Axis1.Tickmarks.MajorLength = 0.25');
Writeln(script, 'Axis1.Grid.AtMinorTicks = False');
Writeln(script, 'Axis1.Grid.MinorLine.ForeColor = srfColorBlack30');
Writeln(script, 'Axis1.Ticklabels.MinorOn = True');
Writeln(script, 'Axis1.Ticklabels.MinorFont.Size=10');
Writeln(script, 'Axis1.Tickmarks.MinorLength = 0.25');
Writeln(script, '');
Writeln(script, 'Set Axis2 = Axes.Item(2)');
if units<>'' then
Writeln(script, 'Axis2.Title.Text = "'+Utf8ToAnsi(par)+', ['+Utf8ToAnsi(units)+']"');
Writeln(script, 'Axis2.Grid.AtMajorTicks = False');
Writeln(script, 'Axis2.Grid.MajorLine.ForeColor = srfColorBlack30');
Writeln(script, 'Axis2.Ticklabels.MajorOn = True');
Writeln(script, 'Axis2.Ticklabels.MajorFont.Size=10');
Writeln(script, 'Axis2.Tickmarks.MajorLength = 0.25');
Writeln(script, 'Axis2.Grid.AtMinorTicks = False');
Writeln(script, 'Axis2.Grid.MinorLine.ForeColor = srfColorBlack30');
Writeln(script, 'Axis2.Ticklabels.MinorOn = True');
Writeln(script, 'Axis2.Ticklabels.MinorFont.Size=10');
Writeln(script, 'Axis2.Tickmarks.MinorLength = 0.25');
Writeln(script, '');

Writeln(script, 'Diagram.zoom(grfZoomFitToWindow)');
Writeln(script, '');
WriteLn(script, 'Plot.SaveAs("'+Exportfile+'grf")');
Writeln(script, '');

 if ncTimeseriesAuto=true then begin
  WriteLn(script, 'Plot.Close(grfSaveChangesNo) ');
 end;

Writeln(script, 'End Sub');

CloseFile(script);
end;


end.

