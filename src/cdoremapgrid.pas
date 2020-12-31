unit cdoremapgrid;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  LazFileUtils;

type

  { Tfrmcdoremap }

  Tfrmcdoremap = class(TForm)
    btnRemap: TButton;
    cbGridType: TComboBox;
    Label6: TLabel;
    Label7: TLabel;
    seXfirst: TFloatSpinEdit;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    seXinc: TFloatSpinEdit;
    seYsize: TSpinEdit;
    seYfirst: TFloatSpinEdit;
    seYinc: TFloatSpinEdit;
    seXsize: TSpinEdit;
    procedure btnRemapClick(Sender: TObject);
  private

  public

  end;

var
  frmcdoremap: Tfrmcdoremap;

implementation

{$R *.lfm}

uses ncmain, ncprocedures;


{ Tfrmcdoremap }

procedure Tfrmcdoremap.btnRemapClick(Sender: TObject);
Var
  k:integer;
  cmd, upath, uname:string;
  dat:text;
begin
  if cbGridType.ItemIndex=-1 then
   if MessageDlg('Select grid type', mtWarning, [mbOk], 0)=mrOk then exit;

  upath:=GlobalUnloadPath+'remap'+PathDelim;
    if not DirectoryExists(upath) then CreateDir(upath);

  // if directory is not empty - cleaning.
  if not DirectoryIsEmpty(upath) then
   if MessageDlg(SDirNotEmpty, mtWarning, [mbYes, mbNo], 0)=mrYes then
     ClearDir(upath) else exit;

  AssignFile(dat, upath+'newgrid.txt'); rewrite(dat);
    writeln(dat, 'gridtype = '+cbGridType.Text);
    writeln(dat, 'xsize    = '+seXsize.Text);
    writeln(dat, 'xfirst   = '+seXfirst.Text);
    writeln(dat, 'xinc     = '+seXinc.Text);
    writeln(dat, 'ysize    = '+seYsize.Text);
    writeln(dat, 'yfirst   = '+seYfirst.Text);
    writeln(dat, 'yinc     = '+seYinc.Text);
  CloseFile(dat);


    frmmain.ProgressBar1.Min:=0;
    frmmain.ProgressBar1.Max:=frmmain.cbFiles.count;
    for k:=0 to frmmain.cbFiles.count-1 do begin
     ncName:=frmmain.cbFiles.Items.strings[k]; // selected files, one by one
     uname:=ExtractFileNameWithoutExt(ncname)+'_remapped.nc';

     //cdo remapbil,mygrid NEMO_SLO_5d_2008_grid_ice.nc out.nc

     cmd:='remapbil,'+upath+'newgrid.txt '+ncpath+ncname+' '+upath+uname;
     showmessage(cmd);

      frmmain.RunScript(4, cmd, nil); // calling CDO

      frmmain.ProgressBar1.Position:=k+1;
      Application.ProcessMessages;
    end;
end;

end.

