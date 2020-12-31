program ClimateShell;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, Forms, ncmain, ncfreshwatercontent, cdodeleteparameter,
  ncheatcontent, arbytraryregion, ncmld, nccalculatefreezingtemp;

{$R *.res}

begin
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(Tfrmmain, frmmain);
  Application.Run;
end.

