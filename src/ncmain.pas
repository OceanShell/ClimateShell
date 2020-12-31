unit ncmain;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Menus, ComCtrls, ExtCtrls, Buttons, Math,
  IniFiles, DateUtils, Process, sqlite3conn, sqldb, LazFileUtils,
  LCLTranslator, Clipbrd;

type

{$IFDEF CPU386}
   PtrUInt = DWORD;
   PtrInt = longint;
{$ENDIF}
{$IFDEF CPUX64}
   PtrUInt = QWORD;
   PtrInt = int64;
{$ENDIF}

{ Tfrmmain }
  Tfrmmain = class(TForm)
    ASCII1: TMenuItem;
    btnExit: TMenuItem;
    btnOpenFolder: TToolButton;
    btnOpenNC: TMenuItem;
    btnSettings: TMenuItem;
    cbAllVars: TListBox;
    cbDates: TListBox;
    cbFiles: TListBox;
    cbFiles1: TListBox;
    cbLat: TListBox;
    cbLevels: TListBox;
    cbLon: TListBox;
    cbVariables: TListBox;
    iAbout: TMenuItem;
    iClimAnomalies: TMenuItem;
    iClimatology: TMenuItem;
    iClimAveraging: TMenuItem;
    iClimEmpty1: TMenuItem;
    iClimFields: TMenuItem;
    iClimProfiles: TMenuItem;
    iClimSections: TMenuItem;
    iClimTimeSeries: TMenuItem;
    iDownload: TMenuItem;
    iExport: TMenuItem;
    iexportnceplev: TMenuItem;
    iFields: TMenuItem;
    iFile: TMenuItem;
    iHelp: TMenuItem;
    iHovmoeller: TMenuItem;
    IL1: TImageList;
    iLatLonSeries: TMenuItem;
    iMap: TMenuItem;
    iMetadataCorrection: TMenuItem;
    iProfiles: TMenuItem;
    iSections: TMenuItem;
    ishfwchc: TMenuItem;
    iTDD: TMenuItem;
    iTimeSeries: TMenuItem;
    itld: TMenuItem;
    iTools: TMenuItem;
    iHelpContent: TMenuItem;
    iSaveListAs: TMenuItem;
    iIsolatAnomalies: TMenuItem;
    iTimeSeriesNodes: TMenuItem;
    iDataInventory: TMenuItem;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    iCopyValueToClipboard: TMenuItem;
    iCopyListToClipboard: TMenuItem;
    iTailoredTools: TMenuItem;
    iantarcticfront: TMenuItem;
    iweatherhazards: TMenuItem;
    icats: TMenuItem;
    MenuItem5: TMenuItem;
    iT_0: TMenuItem;
    iExportKML: TMenuItem;
    iTSDiagram: TMenuItem;
    iTopography3D: TMenuItem;
    iDownloadMercator: TMenuItem;
    iDownloadERA5: TMenuItem;
    iNetTransport: TMenuItem;
    iSections_nodes: TMenuItem;
    iNetTransportSection: TMenuItem;
    iNetTransportNodes: TMenuItem;
    iMercatorExport: TMenuItem;
    iCDO: TMenuItem;
    iAnomalies: TMenuItem;
    iAveraging: TMenuItem;
    iCompressnetcdf4: TMenuItem;
    iExtractSubset: TMenuItem;
    iSplit: TMenuItem;
    iRemapGrid: TMenuItem;
    iSplitDataset: TMenuItem;
    iFreshWaterContent: TMenuItem;
    iDeleteParameter: TMenuItem;
    iHeatContent: TMenuItem;
    MenuItem6: TMenuItem;
    icalculatedensity: TMenuItem;
    icalculatefreezingtemp: TMenuItem;
    mLog: TMemo;
    MM: TMainMenu;
    OD: TOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    PM1: TPopupMenu;
    ProgressBar1: TProgressBar;
    SD: TSaveDialog;
    SDD: TSelectDirectoryDialog;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Splitter3: TSplitter;
    Splitter4: TSplitter;
    Splitter5: TSplitter;
    Splitter6: TSplitter;
    StatusBar1: TStatusBar;

    procedure btnExitClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure icalculatefreezingtempClick(Sender: TObject);
    procedure iCompressnetcdf4Click(Sender: TObject);
    procedure icalculatedensityClick(Sender: TObject);
    procedure iDeleteParameterClick(Sender: TObject);
    procedure iDownloadERA5Click(Sender: TObject);
    procedure iDownloadMercatorClick(Sender: TObject);
    procedure iExportKMLClick(Sender: TObject);
    procedure iExtractSubsetClick(Sender: TObject);
    procedure iFreshWaterContentClick(Sender: TObject);
    procedure iHeatContentClick(Sender: TObject);
    procedure iMercatorExportClick(Sender: TObject);
    procedure iNetTransportNodesClick(Sender: TObject);
    procedure iNetTransportSectionClick(Sender: TObject);
    procedure iRemapGridClick(Sender: TObject);
    procedure iSaveListAsClick(Sender: TObject);
    procedure iAnomaliesClick(Sender: TObject);
    procedure iantarcticfrontClick(Sender: TObject);
    procedure iCopyValueToClipboardClick(Sender: TObject);
    procedure iDataInventoryClick(Sender: TObject);
    procedure iFieldsClick(Sender: TObject);
    procedure iHelpContentClick(Sender: TObject);
    procedure iMapClick(Sender: TObject);
    procedure iProfilesClick(Sender: TObject);
    procedure iSectionsClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure icatsClick(Sender: TObject);
    procedure iSections_nodesClick(Sender: TObject);
    procedure iSplitClick(Sender: TObject);
    procedure iSplitDatasetClick(Sender: TObject);
    procedure iTopography3DClick(Sender: TObject);
    procedure iTSDiagramClick(Sender: TObject);
    procedure iT_0Click(Sender: TObject);
    procedure iWeatherHazardsClick(Sender: TObject);
    procedure cbFilesClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnOpenNCClick(Sender: TObject);
    procedure ASCII1Click(Sender: TObject);
    procedure iAboutClick(Sender: TObject);
    procedure iAveragingClick(Sender: TObject);
    procedure iClimAnomaliesClick(Sender: TObject);
    procedure iClimAveragingClick(Sender: TObject);
    procedure iClimFieldsClick(Sender: TObject);
    procedure iClimProfilesClick(Sender: TObject);
    procedure iClimSectionsClick(Sender: TObject);
    procedure iClimTimeSeriesClick(Sender: TObject);
    procedure iexportnceplevClick(Sender: TObject);
    procedure iHovmoellerClick(Sender: TObject);
    procedure iLatLonSeriesClick(Sender: TObject);
    procedure iMetadataCorrectionClick(Sender: TObject);
    procedure itldClick(Sender: TObject);
    procedure ishfwchcClick(Sender: TObject);
    procedure iTDDClick(Sender: TObject);
    procedure iTimeSeriesClick(Sender: TObject);
    procedure iIsolatAnomaliesClick(Sender: TObject);
    procedure iTimeSeriesNodesClick(Sender: TObject);
 //   procedure iDownload_InterimClick(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure iCopyListToClipboardClick(Sender: TObject);
    procedure MenuItem6Click(Sender: TObject);
    procedure StatusBar1DrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel;
      const Rect: TRect);

  private
    { Private declarations }
  public
    { Public declarations }
    procedure ItemsVisibility;
    procedure RunScript(ExeFlag:integer; cmd:string; Sender:TMemo);
  end;


resourcestring
  SOpenFile = 'Open file?';
  SErrorOccured = 'Something went wrong. Check the output';
  SFilesTheSame = 'Files are the same';
  SYes = 'Yes';
  SNo  = 'No';
  SDone = 'Done!';
  SSelectParameters = 'Please, select parameters';
  SSelectLevels = 'Please, select levels';
  SSelectTime = 'Please, select time';
  SSelectSteps = 'Please, select step';
  SSelectSection = 'Please, select file with section coordinates';
  SDirNotEmpty = 'Output directory is not empty. Clean it now?';
  SNoPython = 'Python is not found';
  SNoSurfer = 'Surfer is not found';
  SNoGrapher = 'Grapher is not found';
  SNoCDO = 'CDO is not found';
  SPlot = 'Plot';
  SGetData = 'Get Data';
  SOutOfRange = 'Data is out of range';
  SHadISSTOutdated = 'There is no ice edge data for the selected region and date';
  SDateCannotPrecede = 'Date cannot preceed ';
  SDateCannotExceed = 'Date cannot exceed ';
  SBigDataset = 'Selected file is big. Proceed anyway?';
  SSelectSubset = 'Would you like to select a subset?';
  SPredefinedArea = 'Select predefined area...';
  SUnloadedFileEmpty = 'Unloaded file is empty';
  SOpenNC = 'Select netCDF file(s)';
  SOpenNorma = 'Select file with norma';

  SJan = 'January';  SFeb = 'February'; SMar = 'March'; SApr = 'April';
  SMay = 'May'; SJun = 'Jun'; SJul = 'July'; SAug = 'August';
  SSep = 'September'; SOct ='October'; SNov = 'November'; SDec = 'December';

  SLongitude = 'Longitude';
  SLatitude  = 'Latitude';

  SAutomationON = 'Automation: ON';
  SAutomationOFF = 'Automation: OFF';
  SAutoAllFilesDatesLevels = 'All files, all dates, all levels';
  SSelectedFileLevelAllDates = 'Selected file, selected level, all dates';
  SSelectedFileDateAllLevels = 'Selected file, selected date, all levels';
  SAllFilesDatesSelectedLevel = 'All files, all dates, selected level';
  SSelectedFileLevelMonth = 'Selected file, selected level, month =';
  SAllFilesSelectedDateLevels = 'All files, selected date, levels from the list';

  SKMLNodes = 'nodes have been exported';


var
  frmmain: Tfrmmain;
  ProgressBar1:TProgressbar;
  ncname, IniFileName:string;
  GlobalPath, GlobalUnloadPath, GlobalSupportPath:string;

  (* NetCDF variables *)
  ncpath:string; // global NetCDF file name
  timeVid, timeDid:integer;
  curve:boolean=false; //flag for curvelinear coordinates

  ncLat_arr  : array of single; // global arrays of latitude
  ncLon_arr  : array of single; // global arrays of longitude
  ncLev_arr  : array of single; // global array  of levels
  ncTime_arr : array of double; // global array  of time

  dat, out1:text;

const
   NC_NOWRITE   = 0;    // file for reading
   NC_WRITE     = 1;    // file for writing
   NC_GLOBAL    = -1;   // global attributes ID
   NC_MAX_NAME  = 1024; // value from netcdf.h
   NC_UNLIMITED = 0;
   WS_EX_STATICEDGE = $20000;
   buf_len      = 3000;

implementation

{$R *.lfm}

uses
  (* common *)
  ncprocedures, settings,  bathymetry, ncdatainventory, about,
  GibbsSeaWater,

  (* export *)
  ncexportascii,
  tool_export_mercator_node,
  export_KML,
  ncexportncep,

  (* calculated parameters *)
  nccalculatedensity,
  nccalculatefreezingtemp,

  (* CDO *)
  cdoaveraging,
  cdoextractsubset,
  cdocompressnetcdf,
  cdoanomalies,
  cdosplittime,
  cdosplitdataset,
  cdoremapgrid,
  cdodeleteparameter,

  (* Climatology *)
  climfields, climanomalies, climaveraging, climsections,
  climhovmoeller, climprofiles, climtimeseries, climtdd,
  climmetadatacorrection, climshfwchc,

  (* tools - common *)
  ncfields, nctimeseries, nctimedepthdiagram, nclatlonseries,
  ncsections, nctsdiagram, ncsections_nodes,
  ncnettransport, ncsections_new,  nctopography3d, nclatmap,
  nctimeseriesnodes, ncprofiles, ncfreshwatercontent,
  ncheatcontent,

  (* tools - custom *)
  tools_weatherhazards, tools_cats, tools_T_0, tools_nettransport_nodes,
  ncantarcticfront;

procedure Tfrmmain.FormCreate(Sender: TObject);
begin
StatusBar1.Panels[2].Style := psOwnerDraw;
ProgressBar1.Parent:=StatusBar1;
end;

procedure Tfrmmain.FormResize(Sender: TObject);
begin
 statusbar1.Panels[1].Width:=Width-(statusbar1.Panels[0].Width+statusbar1.Panels[2].Width+75);
end;

procedure Tfrmmain.StatusBar1DrawPanel(StatusBar: TStatusBar;
  Panel: TStatusPanel; const Rect: TRect);
begin
  if Panel = StatusBar.Panels[2] then
    with ProgressBar1 do begin
      Top := Rect.Top;
      Left := Rect.Left;
      Width := Rect.Right - Rect.Left;
      Height := Rect.Bottom - Rect.Top;
    end;
end;


procedure Tfrmmain.FormShow(Sender: TObject);
Var
  Ini:TIniFile;
begin
 mLog.Clear; //clean the log memo

  (* Define settings file, unique for every user*)
  IniFileName:=GetUserDir+'.climateshell';
  if not FileExists(IniFileName) then begin
    Ini:=TIniFile.Create(IniFileName);
    Ini.WriteInteger('main', 'Language', 0);
    Ini.Free;
  end;

  (* Define global path to the *.exe file *)
  GlobalPath:=ExtractFilePath(Application.ExeName);

  (* Define global delimiter *)
//  DefaultFormatSettings.DecimalSeparator := '.';

 (* Check for existing essencial program folders *)
  Ini := TIniFile.Create(IniFileName);
  try
    GlobalSupportPath := Ini.ReadString('main', 'SupportPath', GlobalPath+'support'+PathDelim);
      if not DirectoryExists(GlobalSupportPath) then CreateDir(GlobalSupportPath);
    GlobalUnloadPath  := Ini.ReadString('main', 'UnloadPath', GlobalPath+'unload'+PathDelim);
      if not DirectoryExists(GlobalUnloadPath) then CreateDir(GlobalUnloadPath);
  finally
    Ini.Free;
  end;

  (* Open assiciated *.nc file *)
  If ParamCount<>0 then begin
       ncname:=ExtractFileName(ParamStr(1));
       ncPath:=ExtractFilePath(ParamStr(1));
       cbFiles.Clear;
       cbFiles.Items.Add(ncname);
       cbFiles.ItemIndex:=0;
       cbFiles.OnClick(self);
  end;

  ItemsVisibility;
end;


procedure Tfrmmain.iHelpContentClick(Sender: TObject);
begin
  OpenDocument(GlobalPath+'help'+PathDelim+'help.pdf');
end;


procedure Tfrmmain.iAboutClick(Sender: TObject);
begin
 if messagedlg(AboutProgram, mtInformation, [mbOk], 0)=mrOk then exit;
end;


procedure Tfrmmain.btnOpenNCClick(Sender: TObject);
Var
  Ini: TIniFile;
  k:integer;
  DataPath:string;
begin

 Ini := TIniFile.Create(IniFileName);
 try
  DataPath := Ini.ReadString('main', 'data path', GlobalPath);
 finally
   Ini.Free;
 end;

 OD.Filter:='NetCDF|*.nc';
 OD.InitialDir:=DataPath;
 OD.Title:=SOpenNC;
 if OD.Execute then begin
  if OD.FileName='' then exit;

  cbFiles.clear;
  for k:=1 to OD.Files.Count do begin
    cbFiles.Items.Add(ExtractFileName(OD.Files.Strings[k-1]));
    Application.ProcessMessages;
  end;

   if cbFiles.Count>0 then begin
     ncPath:=ExtractFilePath(OD.Files.Strings[0]);
      cbFiles.ItemIndex:=0;
      cbFiles.OnClick(self);

      Ini := TIniFile.Create(IniFileName);
       try
        Ini.WriteString('main', 'data path', ncPath);
       finally
        Ini.Free;
       end;
    end;
 end;
end;


procedure Tfrmmain.iDataInventoryClick(Sender: TObject);
begin
 frmncdatainventory := Tfrmncdatainventory.Create(Self);
  try
   if not frmncdatainventory.ShowModal = mrOk then exit;
  finally
    frmncdatainventory.Free;
    frmncdatainventory := nil;
  end;
end;


procedure Tfrmmain.cbFilesClick(Sender: TObject);
begin
 if cbFiles.ItemIndex>-1 then begin
   ncname:= cbFiles.Items.Strings[cbFiles.ItemIndex];
    mLog.Clear;
     if FileExists(ncpath+ncname)=true then ncProcedures.GetHeader(ncpath+ncname, 1);
   ItemsVisibility;
 end;
end;


procedure Tfrmmain.ItemsVisibility;
Var
  Ini:TIniFile;
begin
 Ini := TIniFile.Create(IniFileName);
  try
   if Ini.ReadInteger( 'main', 'Language', 0)=0 then SetDefaultLang('en') else SetDefaultLang('ru');
  finally
   ini.Free;
  end;

 iMap.Enabled:=checkKML;
 //iDownload_Mercator.Enabled:=DirectoryExists(GlobalSupportPath+'motu-client-python');
 iAnomalies.Enabled:=FileExists(GlobalSupportPath+PathDelim+'cdo'+PathDelim+'cdo.exe');
 iDownloadMercator.Enabled:=FileExists(GlobalPath+'dl_mercator.exe');
 iDownloadERA5.Enabled:=FileExists(GlobalPath+'dl_era5.exe');


 {if cbFiles.Count=0 then begin
    iTools.Enabled:=false;
    iExport.Enabled:=false;
   end else begin
    iTools.Enabled:=true;
    iExport.Enabled:=true;
 end; }

 if cbLevels.Count=0 then begin
    iSections.Enabled:=false;
    itld.Enabled:=false;
 end else begin
    iSections.Enabled:=true;
    itld.Enabled:=true;
 end;
end;


procedure Tfrmmain.ASCII1Click(Sender: TObject);
begin
 frmexport := Tfrmexport.Create(Self);
  try
   if not frmexport.ShowModal = mrOk then exit;
  finally
    frmexport.Free;
    frmexport := nil;
  end;
end;

procedure Tfrmmain.iexportnceplevClick(Sender: TObject);
begin
  ncexportncep.exportncep;
end;

procedure Tfrmmain.iExportKMLClick(Sender: TObject);
begin
 frmexport_KML := Tfrmexport_KML.Create(Self);
  try
   if not frmexport_KML.ShowModal = mrOk then exit;
  finally
    frmexport_KML.Free;
    frmexport_KML := nil;
  end;
end;

procedure Tfrmmain.iFieldsClick(Sender: TObject);
begin
  frmfields := Tfrmfields.Create(Self);
   try
    if not frmfields.ShowModal = mrOk then exit;
   finally
    frmfields.Free;
    frmfields:= nil;
  end;
end;

procedure Tfrmmain.iMapClick(Sender: TObject);
Var
  DataFile: string;
  cnt:integer;
begin
 if (high(ncLat_arr)>500) or (high(ncLon_arr)>500) then
   if Messagedlg(SBigDataset, mtInformation, [mbYes, mbNo], 0)=mrNo then
     if Messagedlg(SSelectSubset, mtInformation, [mbYes, mbNo], 0)=mrYes then begin
      iExportKML.OnClick(self);
      exit;
     end else exit;

     DataFile:=GlobalUnloadPath+'kml'+PathDelim+'stations.kml';
      if curve = false then
       frmexport_KML.ExportKML_(DataFile, MinValue(ncLon_arr), MaxValue(ncLon_arr),
                                MinValue(ncLat_arr), MaxValue(ncLat_arr), cnt);
      if curve = true then
       frmexport_KML.ExportKML_(DataFile, -180, 180, -90, 90, cnt);

     OpenDocument(DataFile);
end;


procedure Tfrmmain.iProfilesClick(Sender: TObject);
begin
 frmncUnloadProfiles := TfrmncUnloadProfiles.Create(Self);
  try
   if not frmncUnloadProfiles.ShowModal = mrOk then exit;
  finally
    frmncUnloadProfiles.Free;
    frmncUnloadProfiles := nil;
  end;
end;


procedure Tfrmmain.iSectionsClick(Sender: TObject);
begin
 frmsections := Tfrmsections.Create(Self);
  try
   if not frmsections.ShowModal = mrOk then exit;
  finally
    frmsections.Free;
    frmsections := nil;
  end;
end;

procedure Tfrmmain.iSections_nodesClick(Sender: TObject);
begin
 frmncsections_nodes := Tfrmncsections_nodes.Create(Self);
  try
   if not frmncsections_nodes.ShowModal = mrOk then exit;
  finally
    frmncsections_nodes.Free;
    frmncsections_nodes := nil;
  end;
end;


procedure Tfrmmain.iSplitClick(Sender: TObject);
begin
 frmcdosplit := Tfrmcdosplit.Create(Self);
  try
   if not frmcdosplit.ShowModal = mrOk then exit;
  finally
    frmcdosplit.Free;
    frmcdosplit := nil;
  end;
end;


procedure Tfrmmain.iSplitDatasetClick(Sender: TObject);
begin
 frmsplitdataset := Tfrmsplitdataset.Create(Self);
  try
   if not frmsplitdataset.ShowModal = mrOk then exit;
  finally
    frmsplitdataset.Free;
    frmsplitdataset := nil;
  end;
end;


procedure Tfrmmain.iAveragingClick(Sender: TObject);
begin
 frmaveragingcdo := Tfrmaveragingcdo.Create(Self);
  try
   if not frmaveragingcdo.ShowModal = mrOk then exit;
  finally
    frmaveragingcdo.Free;
    frmaveragingcdo := nil;
  end;
end;


procedure Tfrmmain.iCompressnetcdf4Click(Sender: TObject);
begin
  CompressFiles;
end;


procedure Tfrmmain.iAnomaliesClick(Sender: TObject);
begin
  GetAnomalies;
end;


procedure Tfrmmain.btnSettingsClick(Sender: TObject);
begin
 frmsettings := Tfrmsettings.Create(Self);
  try
   if not frmsettings.ShowModal = mrOk then exit;
  finally
    frmsettings.Free;
    frmsettings := nil;
  end;
end;

procedure Tfrmmain.icatsClick(Sender: TObject);
begin
 frmcats:= Tfrmcats.Create(Self);
  try
   if not frmcats.ShowModal = mrOk then exit;
  finally
    frmcats.Free;
    frmcats := nil;
  end;
end;



procedure Tfrmmain.iTopography3DClick(Sender: TObject);
begin
 frmtopography3D:= Tfrmtopography3D.Create(Self);
  try
   if not frmtopography3D.ShowModal = mrOk then exit;
  finally
    frmtopography3D.Free;
    frmtopography3D := nil;
  end;
end;

procedure Tfrmmain.iTSDiagramClick(Sender: TObject);
begin
 frmtsdiagram:= Tfrmtsdiagram.Create(Self);
  try
   if not frmtsdiagram.ShowModal = mrOk then exit;
  finally
    frmtsdiagram.Free;
    frmtsdiagram := nil;
  end;
end;

procedure Tfrmmain.iT_0Click(Sender: TObject);
begin
 frmtoolsT_0:= TfrmtoolsT_0.Create(Self);
  try
   if not frmtoolsT_0.ShowModal = mrOk then exit;
  finally
    frmtoolsT_0.Free;
    frmtoolsT_0 := nil;
  end;
end;

procedure Tfrmmain.iWeatherHazardsClick(Sender: TObject);
begin
 frmweatherhazards:= Tfrmweatherhazards.Create(Self);
  try
   if not frmweatherhazards.ShowModal = mrOk then exit;
  finally
    frmweatherhazards.Free;
    frmweatherhazards := nil;
  end;
end;


procedure Tfrmmain.iTimeSeriesClick(Sender: TObject);
begin
 frmtimeseries:= Tfrmtimeseries.Create(Self);
  try
   if not frmtimeseries.ShowModal = mrOk then exit;
  finally
    frmtimeseries.Free;
    frmtimeseries := nil;
  end;
end;

procedure Tfrmmain.iIsolatAnomaliesClick(Sender: TObject);
begin
 frmnclatmap:= Tfrmnclatmap.Create(Self);
  try
   if not frmnclatmap.ShowModal = mrOk then exit;
  finally
    frmnclatmap.Free;
    frmnclatmap := nil;
  end;
end;



procedure Tfrmmain.MenuItem1Click(Sender: TObject);
var
  cdo_info: string;
begin
 // showmessage(inttostr(GetBathymetryNew(2.01, 65.99)));
 // showmessage(inttostr(GetBathymetry(2, 66)));
 // showmessage(floattostr(gsw_z_from_p(1000, 66)));

 if RunCommand('ncks', ['-r'], cdo_info, [poUsePipes, poWaitOnExit, poStderrToOutPut]) then mLog.Lines.add(cdo_info);
end;


procedure Tfrmmain.iLatLonSeriesClick(Sender: TObject);
begin
 frmlatlonseries:= Tfrmlatlonseries.Create(Self);
  try
   if not frmlatlonseries.ShowModal = mrOk then exit;
  finally
    frmlatlonseries.Free;
    frmlatlonseries := nil;
  end;
end;


procedure Tfrmmain.itldClick(Sender: TObject);
begin
 frmnctld:= Tfrmnctld.Create(Self);
  try
   if not frmnctld.ShowModal = mrOk then exit;
  finally
    frmnctld.Free;
    frmnctld := nil;
  end;
end;


(************************ UNITS FOR CLIMATOLOGY *******************************)
procedure Tfrmmain.iClimFieldsClick(Sender: TObject);
begin
 if cbFiles.Count=0 then
  if MessageDlg('Please, select *.nc files for plotting', mtInformation, [mbOk], 0)=mrOk
   then exit;

 frmclimfields := Tfrmclimfields.Create(Self);
  try
   if not frmclimfields.ShowModal = mrOk then exit;
  finally
    frmclimfields.Free;
    frmclimfields := nil;
  end;
end;


procedure Tfrmmain.iClimProfilesClick(Sender: TObject);
begin
 frmclimprofiles:= Tfrmclimprofiles.Create(Self);
  try
   if not frmclimprofiles.ShowModal = mrOk then exit;
  finally
    frmclimprofiles.Free;
    frmclimprofiles := nil;
  end;
end;


procedure Tfrmmain.iClimAnomaliesClick(Sender: TObject);
begin
 frmclimanomalies:= Tfrmclimanomalies.Create(Self);
  try
   if not frmclimanomalies.ShowModal = mrOk then exit;
  finally
    frmclimanomalies.Free;
    frmclimanomalies := nil;
  end;
end;


procedure Tfrmmain.iClimAveragingClick(Sender: TObject);
begin
 frmclimaveraging:= Tfrmclimaveraging.Create(Self);
  try
   if not frmclimaveraging.ShowModal = mrOk then exit;
  finally
    frmclimaveraging.Free;
    frmclimaveraging := nil;
  end;
end;


procedure Tfrmmain.iClimSectionsClick(Sender: TObject);
begin
  frmclimsections:= Tfrmclimsections.Create(Self);
 try
  if not frmclimsections.ShowModal = mrOk then exit;
 finally
    frmclimsections.Free;
    frmclimsections := nil;
 end;
end;

procedure Tfrmmain.iHovmoellerClick(Sender: TObject);
begin
 frmclimhovmoeller:= Tfrmclimhovmoeller.Create(Self);
 try
  if not frmclimhovmoeller.ShowModal = mrOk then exit;
 finally
    frmclimhovmoeller.Free;
    frmclimhovmoeller := nil;
 end;
end;


procedure Tfrmmain.iClimTimeSeriesClick(Sender: TObject);
begin
 frmclimtimeseries:= Tfrmclimtimeseries.Create(Self);
  try
   if not frmclimtimeseries.ShowModal = mrOk then exit;
  finally
    frmclimtimeseries.Free;
    frmclimtimeseries := nil;
  end;
end;


procedure Tfrmmain.iTDDClick(Sender: TObject);
begin
 frmclimtdd:= Tfrmclimtdd.Create(Self);
  try
   if not frmclimtdd.ShowModal = mrOk then exit;
  finally
    frmclimtdd.Free;
    frmclimtdd := nil;
  end;
end;


procedure Tfrmmain.iMetadataCorrectionClick(Sender: TObject);
begin
 frmclimmetadatacorrection:= Tfrmclimmetadatacorrection.Create(Self);
  try
   if not frmclimmetadatacorrection.ShowModal = mrOk then exit;
  finally
    frmclimmetadatacorrection.Free;
    frmclimmetadatacorrection := nil;
  end;
end;

(******************** END OF UNITS FOR CLIMATOLOGY ****************************)


procedure Tfrmmain.ishfwchcClick(Sender: TObject);
begin
 frmshfwchc := Tfrmshfwchc.Create(Self);
  try
   if not frmshfwchc.ShowModal = mrOk then exit;
  finally
   frmshfwchc.Free;
   frmshfwchc := nil;
  end;
end;

procedure Tfrmmain.icalculatedensityClick(Sender: TObject);
begin
 frmdensity := Tfrmdensity.Create(Self);
  try
   if not frmdensity.ShowModal = mrOk then exit;
  finally
   frmdensity.Free;
   frmdensity := nil;
  end;
end;

procedure Tfrmmain.icalculatefreezingtempClick(Sender: TObject);
begin
 frmcalculatefreezingtemp := Tfrmcalculatefreezingtemp.Create(Self);
  try
   if not frmcalculatefreezingtemp.ShowModal = mrOk then exit;
  finally
   frmcalculatefreezingtemp.Free;
   frmcalculatefreezingtemp := nil;
  end;
end;


procedure Tfrmmain.iDownloadMercatorClick(Sender: TObject);
begin
  RunScript(0, GlobalPath+'dl_mercator.exe', nil);
end;

procedure Tfrmmain.iDownloadERA5Click(Sender: TObject);
begin
  RunScript(0, GlobalPath+'dl_era5.exe', nil);
end;


procedure Tfrmmain.iDeleteParameterClick(Sender: TObject);
begin
 frmcdodeleteparam := Tfrmcdodeleteparam.Create(Self);
  try
   if not frmcdodeleteparam.ShowModal = mrOk then exit;
  finally
   frmcdodeleteparam.Free;
   frmcdodeleteparam := nil;
  end;
end;


procedure Tfrmmain.iExtractSubsetClick(Sender: TObject);
begin
 frmcdoextractsubset := Tfrmcdoextractsubset.Create(Self);
  try
   if not frmcdoextractsubset.ShowModal = mrOk then exit;
  finally
   frmcdoextractsubset.Free;
   frmcdoextractsubset := nil;
  end;
end;

procedure Tfrmmain.iFreshWaterContentClick(Sender: TObject);
begin
 frmfreshwatercontent := Tfrmfreshwatercontent.Create(Self);
  try
   if not frmfreshwatercontent.ShowModal = mrOk then exit;
  finally
   frmfreshwatercontent.Free;
   frmfreshwatercontent := nil;
  end;
end;

procedure Tfrmmain.iHeatContentClick(Sender: TObject);
begin
 frmheatcontent := Tfrmheatcontent.Create(Self);
  try
   if not frmheatcontent.ShowModal = mrOk then exit;
  finally
   frmheatcontent.Free;
   frmheatcontent := nil;
  end;
end;

procedure Tfrmmain.iRemapGridClick(Sender: TObject);
begin
 frmcdoremap := Tfrmcdoremap.Create(Self);
  try
   if not frmcdoremap.ShowModal = mrOk then exit;
  finally
   frmcdoremap.Free;
   frmcdoremap := nil;
  end;
end;


(* Net transport *)
procedure Tfrmmain.iNetTransportSectionClick(Sender: TObject);
begin
 frmnettransport := Tfrmnettransport.Create(Self);
  try
   if not frmnettransport.ShowModal = mrOk then exit;
  finally
   frmnettransport.Free;
   frmnettransport := nil;
  end;
end;


procedure Tfrmmain.iNetTransportNodesClick(Sender: TObject);
begin
  NetTransportNodes;
end;


procedure Tfrmmain.iMercatorExportClick(Sender: TObject);
begin
// tool_export_mercator_node.exportmercatornode_day;
 tool_export_mercator_node.exportmercatornode_level;
end;


procedure Tfrmmain.iTimeSeriesNodesClick(Sender: TObject);
begin
 frmncexportfield:=Tfrmncexportfield.Create(Self);
  try
   if not frmncexportfield.ShowModal = mrOk then exit;
  finally
   frmncexportfield.Free;
   frmncexportfield := nil;
  end;
end;

(* Export dimentions into text files *)
procedure Tfrmmain.iSaveListAsClick(Sender: TObject);
Var
 k:integer;
 ListSender:TListBox;
begin
 SD.Filter:='Text|*.txt';
 if SD.Execute then begin
  ListSender := ((Sender as TMenuItem).Parent.Owner as TPopupMenu).PopupComponent as TListBox;
  AssignFile(dat, SD.FileName); Rewrite(dat);
   For k:=0 to (ListSender as TListBox).Items.Count-1 do
    writeln(dat, (ListSender as TListBox).Items.Strings[k]);
  CloseFile(dat);
 end;
end;


procedure Tfrmmain.iCopyValueToClipboardClick(Sender: TObject);
Var
 ListSender:TListBox;
begin
  ListSender := ((Sender as TMenuItem).Parent.Owner as TPopupMenu).PopupComponent as TListBox;
  Clipboard.AsText:=ListSender.Items.Strings[ListSender.ItemIndex];
end;

procedure Tfrmmain.iCopyListToClipboardClick(Sender: TObject);
Var
 ListSender:TListBox;
begin
  ListSender := ((Sender as TMenuItem).Parent.Owner as TPopupMenu).PopupComponent as TListBox;
  Clipboard.AsText:=ListSender.Items.Text;
end;

procedure Tfrmmain.MenuItem6Click(Sender: TObject);
begin

end;


procedure Tfrmmain.iantarcticfrontClick(Sender: TObject);
begin
  GetFrontPosition;
end;

procedure Tfrmmain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
   // Обнуляем массивы координат и времени
  ncLat_arr  := nil;
  ncLon_arr  := nil;
  ncTime_arr := nil;
end;


(* Launching scripts *)
procedure Tfrmmain.RunScript(ExeFlag:integer; cmd:string; Sender:TMemo);
Var
  Ini:TIniFile;
  P:TProcess;
  ExeName, buf, s: string;
  WaitOnExit:boolean;
  i, j: integer;
begin
(*
  ExeFlag = 0 /Random executable file
  ExeFlag = 1 /Python
  ExeFlag = 2 /Surfer
  ExeFlag = 3 /Grapher
  ExeFlag = 4 /CDO
  ExeFlag = 5 /NCO
*)

{$IFDEF WINDOWS}
  Ini := TIniFile.Create(IniFileName);
  try
    case ExeFlag of
     0: begin
        ExeName:='';
        WaitOnExit:=false;
     end;
     1: begin
        ExeName:=Ini.ReadString('main', 'PythonPath', '');
        WaitOnExit:=false;
        if not FileExists(ExeName) then
           if Messagedlg(SNoPython, mtwarning, [mbOk], 0)=mrOk then exit;
     end;
     2: begin
        ExeName:=Ini.ReadString('main', 'SurferPath',  '');
        WaitOnExit:=true;
        if not FileExists(ExeName) then
           if Messagedlg(SNoSurfer, mtwarning, [mbOk], 0)=mrOk then exit;
     end;
     3: begin
        ExeName:=Ini.ReadString('main', 'GrapherPath', '');
        WaitOnExit:=true;
        if not FileExists(ExeName) then
           if Messagedlg(SNoGrapher, mtwarning, [mbOk], 0)=mrOk then exit;
     end;
     4: begin
        ExeName:=GlobalSupportPath+PathDelim+'cdo'+PathDelim+'cdo.exe';
       // showmessage(exename);
        WaitOnExit:=true;
        if not FileExists(ExeName) then
           if Messagedlg(SNoCDO,    mtwarning, [mbOk], 0)=mrOk then exit;
     end;
    end;
  finally
   ini.Free;
  end;
{$ENDIF}

{$IFDEF UNIX}
  Case ExeFlag of
    1: ExeName :='python3';
    4: ExeName :='cdo';
    5: ExeName :='nco';
  end;
{$ENDIF}

 try
  P:=TProcess.Create(Nil);
  P.Commandline:=trim(ExeName+' '+cmd);
//  showmessage(P.CommandLine);
  P.Options:=[poUsePipes, poNoConsole];
  if WaitOnExit=true then P.Options:=P.Options+[poWaitOnExit];
  P.Execute;

  repeat
   SetLength(buf, buf_len);
   SetLength(buf, p.output.Read(buf[1], length(buf))); //waits for the process output
   // cut the incoming stream to lines:
   s:=s + buf; //add to the accumulator
   repeat //detect the line breaks and cut.
     i:=Pos(#13, s);
     j:=Pos(#10, s);
     if i=0 then i:=j;
     if j=0 then j:=i;
     if j = 0 then Break; //there are no complete lines yet.
     if (Sender<> nil) then begin
       Sender.Lines.Add(Copy(s, 1, min(i, j) - 1)); //return the line without the CR/LF characters
       Application.ProcessMessages;
     end;
     s:=Copy(s, max(i, j) + 1, length(s) - max(i, j)); //remove the line from accumulator
   until false;
 until buf = '';
 if (s <> '') and (Sender<>nil) then begin
   Sender.Lines.Add(s);
   Application.ProcessMessages;
 end;
finally
 P.Free;
end;
end;


procedure Tfrmmain.btnExitClick(Sender: TObject);
begin
  Close;
end;

end.
