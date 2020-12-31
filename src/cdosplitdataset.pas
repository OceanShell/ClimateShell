unit cdosplitdataset;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, LazFileUtils, lclintf;

type

  { Tfrmsplitdataset }

  Tfrmsplitdataset = class(TForm)
    btnOpenFolder: TBitBtn;
    btnInfo: TBitBtn;
    btnSplit: TButton;
    rgSplit: TRadioGroup;

    procedure btnInfoClick(Sender: TObject);
    procedure btnOpenFolderClick(Sender: TObject);
    procedure btnSplitClick(Sender: TObject);

  private

  public

  end;

var
  frmsplitdataset: Tfrmsplitdataset;
  upath: string;

implementation

{$R *.lfm}

uses ncmain, ncprocedures;

{ Tfrmsplitdataset }

procedure Tfrmsplitdataset.btnSplitClick(Sender: TObject);
Var
  dat:text;
  lst: TStringList;
  cmd, fname, obase: string;
  ff: integer;
  fdb: TSearchRec;
begin

// Path to output folder
 upath:=GlobalUnloadPath+'split_dataset'+PathDelim;
   if not DirectoryExists(upath) then CreateDir(upath);


  AssignFile(dat, upath+'split.cmd'); rewrite(dat);
  for ff:=0 to frmmain.cbFiles.Count-1 do begin
    fname:=frmmain.cbFiles.Items.Strings[ff];
    obase:=ExtractFileNameWithoutExt(fname);

      //  ClearDir(AveragingPath);
    case rgSplit.ItemIndex of
     0: cmd:='splitcode ';
     1: cmd:='splitparam ';
     2: cmd:='splitname ';
     3: cmd:='splitlevel ';
     4: cmd:='splitgrid ';
     5: cmd:='splitzaxis ';
     6: cmd:='splittabnum ';
    end;

    cmd:=cmd+ncPath+fname+' '+obase;
    writeln(dat, cmd);
   frmmain.RunScript(4, cmd, nil);
  end;
  Closefile(dat);

  lst:=TStringList.Create;
  fdb.Name:='';
  FindFirst(GlobalPath+'*.nc',faAnyFile, fdb);
   if fdb.Name<>'' then lst.add(fdb.Name);
   while findnext(fdb)=0 do  if fdb.Name<>'' then lst.add(fdb.Name);
  FindClose(fdb);

  for ff:=0 to lst.Count-1 do
   RenameFile(GlobalPath+lst.Strings[ff], upath+lst.Strings[ff]);


  OpenDocument(upath);
end;

procedure Tfrmsplitdataset.btnOpenFolderClick(Sender: TObject);
begin
  OpenDocument(upath);
end;

procedure Tfrmsplitdataset.btnInfoClick(Sender: TObject);
Var
  s_text: string;
begin
  s_text:='splitcode:   Split code numbers'+#13+
          'Splits a dataset into pieces, one for each different code number.'+#13+
          'xxx will have three digits with the code number.'+#13+
          #13+
          'splitparam:  Split parameter identifiers'+#13+
          'Splits a dataset into pieces, one for each different parameter identifier.'+#13+
          'xxx will bea string with the parameter identifier.'+#13+
          #13+
          'splitname:   Split variable names'+#13+
          'Splits a dataset into pieces, one for each variable name.'+#13+
          'xxx will be a string with the variable name.'+#13+
          #13+
          'splitlevel:  Split levels'+#13+
          'Splits a dataset into pieces, one for each different level.'+#13+
          'xxx will have six digits with the level.'+#13+
          #13+
          'splitgrid:   Split grids'+#13+
          'Splits a dataset into pieces, one for each different grid.'+#13+
          'xxx will have two digits with the grid number.'+#13+
          #13+
          'splitzaxis:  Split z-axes'+#13+
          'Splits a dataset into pieces, one for each different z-axis.'+#13+
          'xxx will have two digits with the z-axis number.'+#13+
          #13+
          'splittabnum: Split parameter table numbers'+#13+
          'Splits a dataset into pieces, one for each GRIB1 parameter table number.'+#13+
          'xxx will have three digits with the GRIB1 parameter table number.';

  If MessageDlg(s_text, mtInformation, [mbOk], 0)=mrOk then exit;
end;

end.

