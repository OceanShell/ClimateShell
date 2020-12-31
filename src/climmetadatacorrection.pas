unit climmetadatacorrection;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls
 {$IFDEF Windows}
  ,windows
 {$ENDIF}
  ;

type

  { Tfrmclimmetadatacorrection }

  Tfrmclimmetadatacorrection = class(TForm)
    btnmonthlyfieldscorrection: TButton;
    btnvariantbcorrection: TButton;
    procedure btnmonthlyfieldscorrectionClick(Sender: TObject);
    procedure btnvariantbcorrectionClick(Sender: TObject);

  private
    { private declarations }
  public
    { public declarations }
    // mode=1 for month-to-month firlds, 2- for variant B
    procedure CreateMDCorrectionScript(ftitle, varcor:string; mode:integer);
    procedure IndexToMonth(mn:integer; Var mn_str:string);
  end;

var
  frmclimmetadatacorrection: Tfrmclimmetadatacorrection;
  fdat:text;


implementation

{$R *.lfm}

uses ncmain;

procedure Tfrmclimmetadatacorrection.btnmonthlyfieldscorrectionClick(Sender: TObject);
Var
  ftitle, varcor, par, yy, mn_str:string;
  kf, ll, mn:integer;
begin

 AssignFile(fdat, ncpath+'script.cmd'); rewrite(fdat);
 try

 for kf:=0 to frmmain.cbFiles.Count-1 do begin
  ncName:=frmmain.cbFiles.Items.Strings[kf];
  par:=copy(ncname, 1, pos('.', ncname)-1);
  yy :=copy(ncname, pos('.', ncname)+1, 4);
  mn :=StrToInt(copy(ncname, pos('.', ncname)+6, 2));
  ll :=StrToInt(copy(ncname, pos('.', ncname)+9, 4));

  IndexToMonth(mn, mn_str);

 ftitle:='Monthly '+lowercase(par)+' for '+mn_str+' '+yy+', '+IntToStr(ll)+' m';

 VarCor:=UpperCase(copy(par,1,1))+copy(par,2,length(par));

 CreateMDCorrectionScript(ftitle, varcor, 1);
 end;
 finally
  CloseFile(fdat);
 end;
end;



procedure Tfrmclimmetadatacorrection.btnvariantbcorrectionClick(Sender: TObject
  );
Var
  ftitle, varcor, par, yy1, yy2, mnf, mn_str:string;
  kf, ll, mn:integer;
begin
 //title = Nordic Seas Atlas: Temperature monthly mean for January 1900 - 2012 ;
 //time_coverage_duration = P10Y ;
 //time_coverage_resolution = P1Y ;

 //title = Nordic Seas Atlas: Temperature annual mean for 1900 - 2012 ;
 //time_coverage_duration = P10Y ;
 //time_coverage_resolution = P1Y ;

 //Temperature:cell_methods = time: mean within month time: mean over years ;
 //Density.19002012.0112.nc
 AssignFile(fdat, ncpath+'script.cmd'); rewrite(fdat);
 try

 for kf:=0 to frmmain.cbFiles.Count-1 do begin
  ncName:=frmmain.cbFiles.Items.Strings[kf];
  par:=copy(ncname, 1, pos('.', ncname)-1);
  VarCor:=UpperCase(copy(par,1,1))+copy(par,2,length(par));

  yy1 :=copy(ncname, pos('.', ncname)+1,  4);
  yy2 :=copy(ncname, pos('.', ncname)+5,  4);
  mnf :=copy(ncname, pos('.', ncname)+10, 4);

  if mnf='0112' then  ftitle:=VarCor+' annual mean for '+yy1+' - '+yy2;
  if mnf<>'0112' then  begin
   mn:=StrToInt(copy(ncname, pos('.', ncname)+10, 2));
   IndexToMonth(mn, mn_str);
   ftitle:=VarCor+' monthly mean for '+mn_str+' '+yy1+' - '+yy2;
  end;

  CreateMDCorrectionScript(ftitle, varcor, 2);
 end;
 finally
  CloseFile(fdat);
 end;
end;


procedure Tfrmclimmetadatacorrection.CreateMDCorrectionScript(ftitle, varcor:string; mode:integer);
begin
writeln(fdat, 'ncatted -a ,global,d,, -h '+ncname);
writeln(fdat, 'ncatted -a "cell_methods","'+VarCor+'",d,, -h '+ncname);

if mode=1 then // fror monthly fields
writeln(fdat, 'ncatted -O -h -a "cell_methods","'+VarCor+'",a,c,"time: mean within month" '+ncname);
if mode=2 then // fror monthly fields
writeln(fdat, 'ncatted -O -h -a "cell_methods","'+VarCor+'",a,c,"time: averaging  of  the monthly fields " '+ncname);

writeln(fdat, 'ncatted -O -h -a title,global,a,c,"Nordic Seas Atlas: '+ftitle+'" '+ncname);
writeln(fdat, 'ncatted -O -h -a time_coverage_start,global,a,c,"1900-01-01" '+ncname);
writeln(fdat, 'ncatted -O -h -a standard_name_vocabulary,global,a,c,"CF-1.6" '+ncname);
writeln(fdat, 'ncatted -O -h -a featureType,global,a,c,"Grid" '+ncname);
writeln(fdat, 'ncatted -O -h -a cdm_data_type,global,a,c,"Grid" '+ncname);
writeln(fdat, 'ncatted -O -h -a Conventions,global,a,c,"CF-1.6" '+ncname);
writeln(fdat, 'ncatted -O -h -a summary,global,a,c,"This Atlas is a result of an international collaboration between the Arctic and Antarctic Research Institute (Russia), Geophysical Institute, University of Bergen (Norway), and the National Oceanographic Data Center (USA). The Atlas is based on data collected from more than 500,000 stations between the years 1900 and 2012. It contains decadal, periodic, annual and monthly climatological fields for water temperature, salinity, and density on a 0.25-degree grid at different depths. In addition to the climatological maps, time-depth diagrams of all parameters, including oxygen, at twelve selected areas covered by long-term observational programs, are available." '+ncname);
writeln(fdat, 'ncatted -O -h -a references,global,a,c,"Korablev, A., A. Smirnov, and O. K. Baranova, 2014. Climatological Atlas of the Nordic Seas and Northern North Atlantic. D. Seidov, A. R. Parsons, Eds., NOAA Atlas NESDIS 77, 116 pp. http://www.nodc.noaa.gov/OC5/nordic-seas/" '+ncname);
writeln(fdat, 'ncatted -O -h -a institution,global,a,c,"Arctic and Antarctic Research Institute, Federal Service for Hydrometeorology and Environmental Monitoring of Russian Federation (Russia); Geophysical Institute, University of Bergen (Norway); National Oceanographic Data Center, NOAA/NESDIS (USA)" '+ncname);
writeln(fdat, 'ncatted -O -h -a comment,global,a,c,"Climatological Atlas of the Nordic Seas and Northern North Atlantic as part of regional climatology of international ocean atlas and information series" '+ncname);
writeln(fdat, 'ncatted -O -h -a id,global,a,c,"http://www.nodc.noaa.gov/OC5/nordic-seas/" '+ncname);
writeln(fdat, 'ncatted -O -h -a naming_authority,global,a,c,"ru.nw.aari" '+ncname);
writeln(fdat, 'ncatted -O -h -a time_coverage_duration,global,a,c,"P10Y" '+ncname);
writeln(fdat, 'ncatted -O -h -a time_coverage_resolution,global,a,c,"P1Y" '+ncname);
writeln(fdat, 'ncatted -O -h -a geospatial_lat_min,global,a,f,60 '+ncname);
writeln(fdat, 'ncatted -O -h -a geospatial_lat_max,global,a,f,82 '+ncname);
writeln(fdat, 'ncatted -O -h -a geospatial_lon_min,global,a,f,-45 '+ncname);
writeln(fdat, 'ncatted -O -h -a geospatial_lon_max,global,a,f,70 '+ncname);
writeln(fdat, 'ncatted -O -h -a geospatial_vertical_min,global,a,f,0 '+ncname);
writeln(fdat, 'ncatted -O -h -a geospatial_vertical_max,global,a,f,3500 '+ncname);
writeln(fdat, 'ncatted -O -h -a geospatial_lat_units,global,a,c,"degrees_north" '+ncname);
writeln(fdat, 'ncatted -O -h -a geospatial_lat_resolution,global,a,c,"0.25 degrees" '+ncname);
writeln(fdat, 'ncatted -O -h -a geospatial_lon_units,global,a,c,"degrees_east" '+ncname);
writeln(fdat, 'ncatted -O -h -a geospatial_lon_resolution,global,a,c,"0.25 degrees" '+ncname);
writeln(fdat, 'ncatted -O -h -a geospatial_vertical_units,global,a,c,"m" '+ncname);
writeln(fdat, 'ncatted -O -h -a geospatial_vertical_resolution,global,a,c," " '+ncname);
writeln(fdat, 'ncatted -O -h -a geospatial_vertical_positive,global,a,c,"down" '+ncname);
writeln(fdat, 'ncatted -O -h -a creator_name,global,a,c,"Arctic and Antarctic Research Institute, Federal Service for Hydrometeorology and Environmental Monitoring of Russian Federation (Russia)" '+ncname);
writeln(fdat, 'ncatted -O -h -a creator_email,global,a,c,"avsmir@aari.nw.ru" '+ncname);
writeln(fdat, 'ncatted -O -h -a creator_url,global,a,c,"http://www.aari.nw.ru/default_en.asp" '+ncname);
writeln(fdat, 'ncatted -O -h -a project,global,a,c,"International Climatological Atlas of the Nordic Seas and Northern North Atlantic" '+ncname);
writeln(fdat, 'ncatted -O -h -a processing_level,global,a,c,"processed" '+ncname);
writeln(fdat, 'ncatted -O -h -a keywords,global,a,c,"<ISO_TOPIC_Category> Oceans</ISO_TOPIC_Category>" '+ncname);
writeln(fdat, 'ncatted -O -h -a keywords_vocabulary,global,a,c,"ISO 19115" '+ncname);
writeln(fdat, 'ncatted -O -h -a contributor_name,global,a,c,"Arctic and Antarctic Research Institute, Federal Service for Hydrometeorology and Environmental Monitoring of Russian Federation (Russia)" '+ncname);
writeln(fdat, 'ncatted -O -h -a contributor_role,global,a,c,"Calculation of climatologies" '+ncname);
writeln(fdat, 'ncatted -O -h -a publisher_name,global,a,c,"National Oceanographic Data Center (USA)" '+ncname);
writeln(fdat, 'ncatted -O -h -a publisher_url,global,a,c,"http://www.nodc.noaa.gov/" '+ncname);
writeln(fdat, 'ncatted -O -h -a publisher_email,global,a,c,"NODC.Services@noaa.gov" '+ncname);
writeln(fdat, 'ncatted -O -h -a license,global,a,c,"These data are openly available to the public. Please acknowledge the use of these data with the text given in the acknowledgment attribute." '+ncname);
writeln(fdat, 'ncatted -O -h -a acknowledgment,global,a,c,"Climatological Atlas of the Nordic Seas and Northern North Atlantic. D. Seidov, A. R. Parsons, Eds., NOAA Atlas NESDIS 77, 116 pp. http://www.nodc.noaa.gov/OC5/nordic-seas/" '+ncname);
writeln(fdat, 'ncatted -O -h -a Metadata_Conventions,global,a,c,"Unidata Dataset Discovery v1.1" '+ncname);
writeln(fdat, 'ncatted -O -h -a metadata_link,global,a,c,"http://data.nodc.noaa.gov/woa/REGCLIM/NORDIC_SEAS/DOC/NESDIS77-hr.pdf" '+ncname);
writeln(fdat, 'ncatted -O -h -a date_issued,global,a,c,"20130802" '+ncname);
writeln(fdat, 'ncatted -O -h -a date_created,global,a,c,"20130802" '+ncname);
writeln(fdat, 'ncatted -O -h -a date_modified,global,a,c,"20140619" '+ncname);
writeln(fdat, 'ncatted -O -h -a history,global,a,c,"metadata modified 20140619" '+ncname);
end;


procedure Tfrmclimmetadatacorrection.IndexToMonth(mn:integer; Var mn_str:string);
begin
case mn of
 1:  mn_str:='January';
 2:  mn_str:='February';
 3:  mn_str:='March';
 4:  mn_str:='April';
 5:  mn_str:='May';
 6:  mn_str:='June';
 7:  mn_str:='July';
 8:  mn_str:='August';
 9:  mn_str:='September';
 10: mn_str:='October';
 11: mn_str:='November';
 12: mn_str:='December';
end;
end;

end.

