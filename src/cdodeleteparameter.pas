unit cdodeleteparameter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  LCLIntf, CheckLst;

type

  { Tfrmcdodeleteparam }

  Tfrmcdodeleteparam = class(TForm)
    btnDelete: TButton;
    CheckListBox1: TCheckListBox;
    GroupBox1: TGroupBox;

    procedure btnDeleteClick(Sender: TObject);
    procedure FormShow(Sender: TObject);

  private

  public

  end;

var
  frmcdodeleteparam: Tfrmcdodeleteparam;

implementation

{$R *.lfm}

uses ncmain;

{ Tfrmcdodeleteparam }

procedure Tfrmcdodeleteparam.FormShow(Sender: TObject);
begin
 CheckListBox1.Items  := frmmain.cbVariables.items;
end;


procedure Tfrmcdodeleteparam.btnDeleteClick(Sender: TObject);
Var
  pp:integer;
 cmd, upath: string;
begin
// Path to output folder
upath:=GlobalUnloadPath+'modified_netcdf'+PathDelim;
  if not DirectoryExists(upath) then CreateDir(upath);

   cmd:='delete,name=';

   for pp:=0 to CheckListBox1.Count-1 do
     if CheckListBox1.Checked[pp] then
      cmd:=cmd+CheckListBox1.Items.Strings[pp]+',';

   cmd:=copy(cmd, 1, length(cmd)-1);
   cmd:=cmd+' '+ncPath+ncname+' '+uPath+ncname;

   frmmain.RunScript(4, cmd, nil);

 OpenDocument(upath);
end;

end.

