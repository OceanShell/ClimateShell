unit cdoextractsubset;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LazFileUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Spin, Math;

type

  { Tfrmcdoextractsubset }

  Tfrmcdoextractsubset = class(TForm)
    btnExtract: TButton;
    eMaxLat: TFloatSpinEdit;
    eMaxLon: TFloatSpinEdit;
    eMinLat: TFloatSpinEdit;
    eMinLon: TFloatSpinEdit;
    GroupBox4: TGroupBox;

    procedure btnExtractClick(Sender: TObject);
    procedure FormShow(Sender: TObject);


  private

  public

  end;

var
  frmcdoextractsubset: Tfrmcdoextractsubset;

implementation

{$R *.lfm}

{ Tfrmcdoextractsubset }

uses ncmain, ncprocedures;

procedure Tfrmcdoextractsubset.FormShow(Sender: TObject);
begin
  eMinLat.Value := MinValue(ncLat_arr);
  eMinLon.Value := MinValue(ncLon_arr);
  eMaxLat.Value := MaxValue(ncLat_arr);
  eMaxLon.Value := MaxValue(ncLon_arr);
end;

procedure Tfrmcdoextractsubset.btnExtractClick(Sender: TObject);
Var
  k:integer;
  cmd, upath, uname:string;
begin
upath:=GlobalUnloadPath+'subset'+PathDelim;
  if not DirectoryExists(upath) then CreateDir(upath);

// if directory is not empty - cleaning.
if not DirectoryIsEmpty(upath) then
 if MessageDlg(SDirNotEmpty, mtWarning, [mbYes, mbNo], 0)=mrYes then
   ClearDir(upath) else exit;

  frmmain.ProgressBar1.Min:=0;
  frmmain.ProgressBar1.Max:=frmmain.cbFiles.count;
  for k:=0 to frmmain.cbFiles.count-1 do begin
   ncName:=frmmain.cbFiles.Items.strings[k]; // selected files, one by one
   uname:=copy(ncname,1,length(ncname)-3)+'_'+
          FloatToStrF(eMinLat.Value, ffgeneral, 5, 2)+'_'+
          FloatToStrF(eMaxLat.Value, ffgeneral, 5, 2)+'_'+
          FloatToStrF(eMinLon.Value, ffgeneral, 5, 2)+'_'+
          FloatToStrF(eMaxLon.Value, ffgeneral, 5, 2)+'.nc';

   cmd:='sellonlatbox,'+
         eMinLon.Text+','+eMaxLon.Text+','+
         eMinLat.Text+','+eMaxLat.Text+' '+
         ncpath+ncname+' '+
         upath+uname;

    frmmain.RunScript(4, cmd, nil); // calling CDO

    frmmain.ProgressBar1.Position:=k+1;
    Application.ProcessMessages;
  end;
end;


end.

