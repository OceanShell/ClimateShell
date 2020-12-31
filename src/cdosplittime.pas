unit cdosplittime;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  LazFileUtils, lclintf, Buttons;

type

  { Tfrmcdosplit }

  Tfrmcdosplit = class(TForm)
    btnOpenFolder: TBitBtn;
    btnSplit: TButton;
    rgSplit: TRadioGroup;

    procedure btnOpenFolderClick(Sender: TObject);
    procedure btnSplitClick(Sender: TObject);

  private

  public

  end;

var
  frmcdosplit: Tfrmcdosplit;
  upath: string;

implementation

{$R *.lfm}

{ Tfrmcdosplit }

uses ncmain;

procedure Tfrmcdosplit.btnSplitClick(Sender: TObject);
Var
  dat:text;
  lst: TStringList;
  cmd, fname, obase: string;
  ff: integer;
  fdb: TSearchRec;
begin

// Path to output folder
 upath:=GlobalUnloadPath+'split_timesteps'+PathDelim;
   if not DirectoryExists(upath) then CreateDir(upath);


  AssignFile(dat, upath+'split.cmd'); rewrite(dat);
  for ff:=0 to frmmain.cbFiles.Count-1 do begin
    fname:=frmmain.cbFiles.Items.Strings[ff];
    obase:=ExtractFileNameWithoutExt(fname);

      //  ClearDir(AveragingPath);
    case rgSplit.ItemIndex of
     0: cmd:='splithour ';
     1: cmd:='splitday ';
     2: cmd:='splitseas ';
     3: cmd:='splityear ';
     4: cmd:='splityearmon ';
     5: cmd:='splitmon ';
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

procedure Tfrmcdosplit.btnOpenFolderClick(Sender: TObject);
begin
  OpenDocument(upath);
end;

end.

