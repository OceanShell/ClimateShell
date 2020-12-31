unit ncdatainventory;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, sqlite3conn, sqldb, FileUtil, Forms, Controls,
  Graphics, Dialogs, ExtCtrls, StdCtrls, DBGrids, DbCtrls, ComCtrls;

type

  { Tfrmncdatainventory }

  Tfrmncdatainventory = class(TForm)
    DS1: TDataSource;
    DS2: TDataSource;
    DBGrid1: TDBGrid;
    DBGrid2: TDBGrid;
    Panel1: TPanel;
    Panel2: TPanel;
    Q1: TSQLQuery;
    Q2: TSQLQuery;
    Splitter1: TSplitter;
    SQL3: TSQLite3Connection;
    ToolBar1: TToolBar;
    ToolBar2: TToolBar;
    btnMDAdd: TToolButton;
    btnMDDelete: TToolButton;
    btnMDCommit: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    TR: TSQLTransaction;

    procedure btnMDAddClick(Sender: TObject);
    procedure btnMDCommitClick(Sender: TObject);
    procedure btnMDDeleteClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Panel1Resize(Sender: TObject);

  private
    procedure CreateNewDB(DBName:string);
  public

  end;

var
  frmncdatainventory: Tfrmncdatainventory;
  DataInventoryDBName: String;

implementation

{$R *.lfm}

{ Tfrmncdatainventory }

procedure Tfrmncdatainventory.FormShow(Sender: TObject);
begin
 DataInventoryDBName:=GetAppConfigDir(false)+'datainventory.db';
 if not FileExists(DataInventoryDBName) then CreateNewDB(DataInventoryDBName);

 SQL3.DatabaseName:=DataInventoryDBName;
 SQL3.Open;
 Q1.Open;
end;

procedure Tfrmncdatainventory.Panel1Resize(Sender: TObject);
begin
  DBGrid1.Columns[0].Width:=panel1.Width-20;
end;

procedure Tfrmncdatainventory.btnMDAddClick(Sender: TObject);
Var
 Qt:TSQLQuery;
begin
 Qt :=TSQLQuery.Create(self);
 Qt.Database:=SQL3;
 Qt.Transaction:=TR;

 Q1.Append;
   Qt.Close;
   Qt.SQL.Text:=' Select max(ID) from METADATA ';
   Qt.Open;
    Q1.FieldByName('ID').Value:=Qt.Fields[0].AsInteger+1;
   Qt.Close;
   TR.CommitRetaining;
 Qt.free;
end;

procedure Tfrmncdatainventory.btnMDDeleteClick(Sender: TObject);
begin
 Q1.Delete;
 TR.CommitRetaining;
end;

procedure Tfrmncdatainventory.btnMDCommitClick(Sender: TObject);
begin
 if Q1.Modified then Q1.Post;
   Q1.ApplyUpdates(-1);
   TR.CommitRetaining;
end;


procedure Tfrmncdatainventory.CreateNewDB(DBName:string);
begin
   SQL3.DatabaseName:=DBName;
   SQL3.Open;
   TR.Active := true;

   SQL3.ExecuteDirect('CREATE TABLE "METADATA"('+
                    ' "ID" Integer NOT NULL PRIMARY KEY AUTOINCREMENT,'+
                    ' "VARNAME" Char(128) NOT NULL);');
   SQL3.ExecuteDirect('CREATE UNIQUE INDEX "Data_id_idx" ON "METADATA"( "ID" );');

   TR.CommitRetaining;

   SQL3.ExecuteDirect('CREATE TABLE "PARAMETERS"('+
                    ' "ID" Integer NOT NULL,'+
                    ' "PARNAME" Char(128) NOT NULL,'+
                    ' "LINK" Char(256) NOT NULL);');

    TR.Commit;
end;

end.

