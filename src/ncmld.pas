unit ncmld;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { Tfrmmld }

  Tfrmmld = class(TForm)
    btnMLDSettings: TButton;
    Button1: TButton;
    cbVariableS: TComboBox;
    cbVariableT: TComboBox;
    GroupBox1: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
  private

  public

  end;

var
  frmmld: Tfrmmld;

implementation

{$R *.lfm}

end.

