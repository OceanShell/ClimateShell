unit cdoaveraging;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, Classes, SysUtils, LazFileUtils, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Spin, Buttons;

type

  { Tfrmaveragingcdo }

  Tfrmaveragingcdo = class(TForm)
    btnAverage: TButton;
    btnOpenFolder: TBitBtn;
    GroupBox2: TGroupBox;
    rbAllFiles: TRadioButton;
    rbMonthByMonth: TRadioButton;
    rbSeason: TRadioButton;
    rbSeasonEveryYear: TRadioButton;
    rbSelectedMonth: TRadioButton;
    rbYearByYear: TRadioButton;
    seM: TSpinEdit;
    seM1: TSpinEdit;
    seM2: TSpinEdit;
    seM3: TSpinEdit;
    seM4: TSpinEdit;

    procedure btnOpenFolderClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnAverageClick(Sender: TObject);

  private

  public

  end;

var
  frmaveragingcdo: Tfrmaveragingcdo;
  AveragingPath:string;

implementation

{$R *.lfm}

uses ncmain, ncprocedures;

{ Tfrmaveragingcdo }

procedure Tfrmaveragingcdo.FormShow(Sender: TObject);
begin
  AveragingPath:=GlobalUnloadPath+'averaging'+PathDelim;
  if not DirectoryExists(AveragingPath) then CreateDir(AveragingPath);
end;


procedure Tfrmaveragingcdo.btnAverageClick(Sender: TObject);
Var
  dat:text;
  cmd0, cmd, buf:string;
  ff, mn, yy0, yy:integer;
begin
//  ClearDir(AveragingPath);

  cmd:='ensmean ';

  // All files
  if rbAllFiles.Checked then begin
     for ff:=0 to frmmain.cbFiles.Count-1 do
       cmd:=cmd+ncPath+frmmain.cbFiles.Items.Strings[ff]+' ';
     cmd:=cmd+AveragingPath+'average.nc';

     frmmain.RunScript(4, cmd, nil);
  end;

  // Month by month
  if rbMonthByMonth.Checked then begin
  frmmain.ProgressBar1.Min:=0;
  frmmain.ProgressBar1.Max:=12;
  frmmain.ProgressBar1.Position:=0;
   for mn:=1 to 12 do begin
    cmd:='ensmean ';
     for ff:=0 to frmmain.cbFiles.Count-1 do begin
       if StrToInt(copy(frmmain.cbFiles.Items.Strings[ff], 6, 2))=mn then begin
         cmd:=cmd+ncPath+frmmain.cbFiles.Items.Strings[ff]+' ';
       end;
     end; // files
    cmd:=cmd+AveragingPath+'average_'+inttostr(mn)+'.nc';
    frmmain.RunScript(4, cmd, nil);
    frmmain.ProgressBar1.Position:=mn;
   end; // mn
  end;


  // Year by year
  if rbYearByYear.Checked then begin
  frmmain.ProgressBar1.Min:=0;
  frmmain.ProgressBar1.Max:=frmmain.cbFiles.Count;
  frmmain.ProgressBar1.Position:=0;

  yy0:=StrToInt(copy(frmmain.cbFiles.Items.Strings[0], 1, 4));
  cmd:='ensmean ';
    for ff:=0 to frmmain.cbFiles.Count-1 do begin
      yy:=StrToInt(copy(frmmain.cbFiles.Items.Strings[ff], 1, 4));
       if yy=yy0 then cmd:=cmd+ncPath+frmmain.cbFiles.Items.Strings[ff]+' ';
       if (yy<>yy0) or (ff=frmmain.cbFiles.Count-1) then begin
         cmd:=cmd+AveragingPath+'average_'+inttostr(yy0)+'.nc';
           frmmain.RunScript(4, cmd, nil);
           frmmain.ProgressBar1.Position:=ff+1;
         yy0:= yy;
         cmd:='ensmean '+ncPath+frmmain.cbFiles.Items.Strings[ff]+' ';
         end;
     end; // files
  end;


  // Selected month
  if rbSelectedMonth.Checked then begin
  frmmain.ProgressBar1.Min:=0;
  frmmain.ProgressBar1.Max:=frmmain.cbFiles.Count;
  frmmain.ProgressBar1.Position:=0;
  //  cmd:='-b F64 ensmean ';
  cmd:='ensmean ';
     for ff:=0 to frmmain.cbFiles.Count-1 do begin
       if StrToInt(copy(frmmain.cbFiles.Items.Strings[ff], 6, 2))=seM.Value then
         cmd:=cmd+ncPath+frmmain.cbFiles.Items.Strings[ff]+' ';
      frmmain.ProgressBar1.Position:=ff+1;
     end;

     cmd:=cmd+AveragingPath+'average_'+seM.Text+'.nc';

    frmmain.RunScript(4, cmd, nil);
  end;


  // Season
  if rbSeason.Checked then begin
  frmmain.ProgressBar1.Visible:=false;

  cmd:='ensmean ';
     for ff:=0 to frmmain.cbFiles.Count-1 do begin
      mn:=StrToInt(copy(frmmain.cbFiles.Items.Strings[ff], 6, 2));
       if ((seM1.Value<=seM2.Value) and (mn>=seM1.Value) and (mn<=seM2.Value)) or
          ((seM1.Value>seM2.Value) and ((mn>=seM1.Value) or (mn<=seM2.Value))) then
         cmd:=cmd+ncPath+frmmain.cbFiles.Items.Strings[ff]+' ';
     end;

     AssignFile(dat, AveragingPath+'query.cmd'); rewrite(dat);
       cmd:=cmd+AveragingPath+'seasonal_average_'+seM1.Text+'_'+seM2.Text+'.nc';
       writeln(dat, cmd);
     CloseFile(dat);
    frmmain.RunScript(4, cmd, nil);
  end;


  // Season for every year
  if rbSeasonEveryYear.Checked then begin
  frmmain.ProgressBar1.Min:=0;
  frmmain.ProgressBar1.Max:=frmmain.cbFiles.Count;
  frmmain.ProgressBar1.Position:=0;

  AssignFile(dat, AveragingPath+'query.cmd'); rewrite(dat);

  yy0:=StrToInt(copy(frmmain.cbFiles.Items.Strings[0], 1, 4));
  cmd:='ensmean ';
    for ff:=0 to frmmain.cbFiles.Count-1 do begin
      yy:=StrToInt(copy(frmmain.cbFiles.Items.Strings[ff], 1, 4));
      mn:=StrToInt(copy(frmmain.cbFiles.Items.Strings[ff], 6, 2));
       if (yy=yy0) and (mn>=seM3.Value) and (mn<=seM4.Value) then
            cmd:=cmd+ncPath+frmmain.cbFiles.Items.Strings[ff]+' ';

       if (yy<>yy0) or (ff=frmmain.cbFiles.Count-1) then begin
         cmd:=cmd+AveragingPath+'seasonal_average_'+seM3.Text+'_'+seM4.Text+'_'+inttostr(yy0)+'.nc';
           writeln(dat, cmd);

           frmmain.RunScript(4, cmd, nil);
           frmmain.ProgressBar1.Position:=ff+1;
         yy0:= yy;
         if (mn>=seM3.Value) and (mn<=seM4.Value) then
           cmd:='ensmean '+ncPath+frmmain.cbFiles.Items.Strings[ff]+' ' else
           cmd:='ensmean ';
         end;
     end; // files
    CloseFile(dat);
  end;


  OpenDocument(AveragingPath);
end;


procedure Tfrmaveragingcdo.btnOpenFolderClick(Sender: TObject);
begin
  OpenDocument(AveragingPath);
end;

end.

