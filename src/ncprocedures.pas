unit ncprocedures;

{$mode objfpc}{$H+}

interface

uses
{$ifdef WINDOWS}
  Windows, Registry,
{$endif}
  SysUtils, Variants, Dialogs, DateUtils, ncmain, declarations_netcdf, ncexportascii;


function CheckKML:boolean;
function ClearDir(Dir:string ): boolean;

(* Заголовок файла. Определяем вывод данных: мемо (1) или файл (2) *)
procedure GetHeader(fpath:string; outputid:integer);
function  GetLatIndex(Lat:real): integer; // индекс широты
function  GetLonIndex(Lon:real): integer; // индекс долготы
procedure GetDates(ncDate:string); //начальная дата
procedure IndToDepth(Ind:string; var lev:string);

procedure Distance(ln0,ln1,lt0,lt1:real; var Dist:real);

{vertical interpolation}
procedure ODBPr_VertInt(IntLev,LU1,LU2,LD1,LD2,VU1,VU2,VD1,VD2:real;
      var IntVal:real; var Enable:boolean; Var IntMethod: integer);
function  ODBPr_Line(x0,x1,x2,px1,px2:real) :real;
procedure ODBPr_Lag(x,x1,x2,x3,px1,px2,px3:real; var value:real);
procedure ODBPr_RR(level:real; l_arr,p_arr:array of real;    var value:real);

procedure Depth_to_Pressure(z,lt_real:real; m:integer; var press:real);
procedure IEOS80(press,t,s:real;var svan,dens:real);

function  LinesCount(const Filename: string): Integer;
function  DirectoryIsEmpty(Directory: string): Boolean;

implementation


{$IFDEF WINDOWS}
function CheckKML:boolean;
var
  FileClass: string;
  Reg: TRegistry;
begin
  Reg := TRegistry.Create(KEY_EXECUTE);
  Reg.RootKey := HKEY_CLASSES_ROOT;
  FileClass := '';
  if Reg.OpenKeyReadOnly('.kml') then
  begin
    FileClass := Reg.ReadString('');
    Reg.CloseKey;
  end;
  if FileClass <> '' then begin
    if Reg.OpenKeyReadOnly(FileClass + '\Shell\Open\Command') then
    begin
      if trim(Reg.ReadString(''))<>'' then Result := true else Result := false;
      Reg.CloseKey;
    end;
  end;
  Reg.Free;
end;

function LinesCount(const Filename: string): Integer;
var
  HFile: THandle;
  FSize, WasRead, i: Cardinal;
  Buf: array[1..4096] of byte;
begin
  Result := 0;
  HFile := CreateFile(Pchar(FileName), GENERIC_READ, FILE_SHARE_READ, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if HFile <> INVALID_HANDLE_VALUE then
  begin
    FSize := GetFileSize(HFile, nil);
    if FSize > 0 then
    begin
      Inc(Result);
      ReadFile(HFile, Buf, 4096, WasRead, nil);
      repeat
        for i := WasRead downto 1 do
          if Buf[i] = 10 then
            Inc(Result);
        ReadFile(HFile, Buf, 4096, WasRead, nil);
      until WasRead = 0;
    end;
  end;
  CloseHandle(HFile);
end;
{$ENDIF}

{$IFDEF LINUX}
function CheckKML:boolean;
begin
   Result:=false;
end;

function LinesCount(const Filename: string): Integer;
begin
  Result:=0;
end;
{$ENDIF}


function ClearDir( Dir: string ): boolean;
var
 isFound: boolean;
 sRec: TSearchRec;
begin
 Result := false;
 ChDir( Dir );
  if IOResult <> 0 then Exit;
  if Dir[Length(Dir)] <> PathDelim then Dir := Dir + PathDelim;

  isFound := FindFirst( Dir + '*.*', faAnyFile, sRec ) = 0;
  while isFound do  begin
   if ( sRec.Name <> '.' ) and ( sRec.Name <> '..' ) then
    if ( sRec.Attr and faDirectory ) = faDirectory then  begin
     if not ClearDir( Dir + sRec.Name ) then  Exit;
     if ( sRec.Name <> '.' ) and ( sRec.Name <> '..' ) then
      if ( Dir + sRec.Name ) <> Dir then  begin  ChDir( '..' );
        RmDir( Dir + sRec.Name );
      end;
    end else if not SysUtils.DeleteFile(Dir + sRec.Name) then Exit;
   isFound := FindNext( sRec ) = 0;
  end;
 SysUtils.FindClose(sRec);
 Result := IOResult = 0;
end;


procedure GetHeader(fpath:string; outputid:integer);
Var
k, i, c, ln_i, lt_i, tt:integer;
status, ncid:integer;                         //nc_open
nvarsp, ngattsp, unlimdimidp, formatp:integer; //nc_inq

(* Dimensions *)
unlimdim: array of integer; isUnlim:boolean;
DimName: array of pAnsiChar; lenp: size_t;     //nc_inq_dim
time_arr_float: array of single;

(* Variables *)
Varname: array of pAnsiChar;
Vtype: nc_type; //nc_inq_var
varidp, ndimsp, varndimsp, varnattsp:integer;
vardimidsp:array of integer;
VarTypeStr, DimStr, ncformat:string;
dlenp, flenp: size_t;

shufflep, deflatep, deflate_levelp, comp_ratio:integer; // compression
comp_str:string;

(* Attributes *)
attname:    array of pAnsiChar;
atttext:    array of pAnsiChar;
attfloat:   array of single;
attdouble:  array of double;
attshort:   array of smallint;
attinteger: array of integer;
atttype: nc_type;
attstr:string;
attnum:integer;
attlenp:size_t;

(* Global attributes *)
globname:    array of pAnsiChar;
globtext:    array of pAnsiChar;
globfloat:   array of single;
globdouble:  array of double;
globshort:   array of smallint;
globinteger: array of integer;
globtype: nc_type;
globstr:string;
globlenp:size_t;
begin
 //Clear lists
 if outputId=1 then begin
  frmmain.mLog.Clear;
  frmmain.cbAllVars.Clear;   // параметры и оси
  frmmain.cbVariables.Clear; // только параметры
  frmmain.cbLat.Clear;       // latitude
  frmmain.cbLon.Clear;       // longitude
  frmmain.cbDates.Clear;     // date and/or time
  frmmain.cbLevels.Clear;    // levels
 end;

 timevid:=-1;
 timedid:=-1;

 try
 (* nc_open*)

 // showmessage(fpath);

   status:=nc_open(pAnsiChar(fpath), NC_NOWRITE, ncid); // only for reading
    if status>0 then showmessage(pAnsiChar(nc_strerror(status))) else begin

      if outputid=1 then frmmain.mLog.Lines.Add('netcdf '+Copy(ExtractFileName(fpath), 1,
                     length(ExtractFileName(fpath))-3)+' {');
      if outputid=2 then writeln(fout, 'netcdf '+Copy(ExtractFileName(fpath), 1,
                     length(ExtractFileName(fpath))-3)+' {');
    end;

    // showmessage('1');

  (* nc_inq *)
   //ndimsp - dimensions
   //nvarsp - variables
   //ngattsp - global attributes
   //unlimdimidp - ID of the unlimited dimension.
   //If no unlimited length dimension has been defined, -1 is returned.

   status:=nc_inq (ncid, ndimsp, nvarsp, ngattsp, unlimdimidp);
    if status>0 then showmessage(pAnsiChar(nc_strerror(status)));

    // seek for unlimited variables, write 'em to the array
    if unlimdimidp>-1 then begin
     setLength(unlimdim, unlimdimidp);
      for k:=0 to unlimdimidp-1 do nc_inq_unlimdim (ncid, unlimdim[k]);
      //showmessage(inttostr(unlimdim[0]));
    end;

   (* nc_inq_dim *) //get dimension names, lengths
     if outputid=1 then frmmain.mLog.Lines.Add('dimensions:');
     if outputid=2 then writeln(fout, 'dimensions:');

    setlength(dimname, NC_MAX_NAME); //длина имени размерности
    for k:=0 to ndimsp-1 do begin
     status:=nc_inq_dimname(ncid, k, dimname); // имя размерности
      if status>0 then showmessage(pAnsiChar(nc_strerror(status)));

  //    showmessage(pAnsiChar(dimname)+'  '+inttostr(k));

     status:=nc_inq_dimlen(ncid, k, lenp); //длина размерности
      if status>0 then showmessage(pAnsiChar(nc_strerror(status)));

       // Заполняем массивы для координат и времени - они доступны
       // везде и всегда до закрытия программы
      if outputid=1 then begin
         status:=nc_inq_varid (ncid, pAnsiChar(dimname), varidp); // переменная
         if status>0 then nc_inq_dimid (ncid, pAnsiChar(dimname), varidp); // размерность

       //  showmessage(lowercase(pAnsiChar(dimname)));

       (* Longitude *)
       if (Copy(lowercase(pAnsiChar(dimname)), 1, 3)='lon') or
          (trim(lowercase(pAnsiChar(dimname)))='x') then begin
           //Проверка для NEMO
            status:=nc_inq_varid (ncid, pAnsiChar('nav_lon'), varidp);
             if status=0 then begin
              frmmain.cbLon.Items.Add('Curvilinear coordinates');
              curve:=true; //присваиваем флаг если координаты криволинейные
            end else begin // Если файл нормальный - Longitude(lon)
              curve:=false;

              nc_inq_vartype(ncid, varidp, vtype); // variable type
              setLength(ncLon_arr,  lenp);
               if VarToStr(vtype)='5'  then nc_get_var_float  (ncid, varidp, ncLon_arr);
               if VarToStr(vtype)='6'  then begin
                   setLength(globdouble, lenp);
                  nc_get_var_double (ncid, varidp, globdouble);
                 for ln_i:=0 to lenp-1 do nclon_arr[ln_i]:=globdouble[ln_i];
               end;

              for ln_i:=0 to lenp-1 do begin
                if nclon_arr[ln_i]>180 then ncLon_arr[ln_i]:=ncLon_arr[ln_i]-360;
               frmmain.cbLon.Items.Add(Vartostr(ncLon_arr[ln_i]));
              end;
           end;
       end;


       (* Latitude *)
       if (Copy(lowercase((pAnsiChar(dimname))), 1, 3)='lat')     or
          (trim(lowercase(pAnsiChar(dimname)))='y') then begin

         //Проверка для NEMO
         status:=nc_inq_varid (ncid, pAnsiChar('nav_lat'), varidp);
         if status=0 then begin
          frmmain.cbLat.Items.Add('Curvilinear coordinates');
         end else begin // Если файл нормальный - Longitude(lon)
          setlength(ncLat_arr,  lenp);
          nc_inq_vartype(ncid, varidp, vtype); // variable type
           if VarToStr(vtype)='5'  then begin
            nc_get_var_float  (ncid, varidp, ncLat_arr);
           end;
           if VarToStr(vtype)='6'  then begin
            setLength(globdouble, lenp);
             nc_get_var_double (ncid, varidp, globdouble);
             for lt_i:=0 to lenp-1 do nclat_arr[lt_i]:=globdouble[lt_i];
           end;

          for lt_i:=0 to lenp-1 do begin
            frmmain.cbLat.Items.Add(Vartostr(ncLat_arr[lt_i]));
          end;
        end;
       end;


       (* Depth / Levels *)
       if (Copy(lowercase((pAnsiChar(dimname))), 1, 3)='lev')     or
          (Copy(lowercase((pAnsiChar(dimname))), 1, 3)='dep')     or
          (Copy(lowercase((pAnsiChar(dimname))), 1, 4)='zlev')    or
          (Copy(lowercase((pAnsiChar(dimname))), 1, 6)='deptht')  or
          (trim(lowercase(pAnsiChar(dimname)))='z') then begin
         setlength(ncLev_arr,  lenp);
         nc_get_var_float (ncid, varidp, ncLev_arr);
         for i:=0 to high(ncLev_arr) do frmmain.cbLevels.Items.Add(Vartostr(nclev_arr[i]));
       // showmessage('depth');
       end;

       (* Time *)
       if (Copy(lowercase((pAnsiChar(dimname))), 1, 3)='tim') and
          (lowercase((pAnsiChar(dimname)))<>'time_bounds') then begin
        timeDid:=k;
        timeVid:=varidp;
         if (timevid>-1) and (timedid>-1) then begin
           nc_inq_dimlen (ncid, timeDid, lenp);

             setlength(ncTime_arr, lenp);
             nc_get_var_double (ncid, timeVid, ncTime_arr);
             nc_inq_attlen (ncid, timeVid, pAnsiChar('units'), attlenp);
             setlength(atttext, attlenp);
             nc_get_att_text (ncid, timeVid, pAnsiChar('units'), atttext);
           end;

           GetDates(trim(pAnsiChar(atttext)));  // convert time to real dates!!!!!
        end;
      end; // конец заполнения массивов

      // Цикл по переменным, определяем конечные и бесконечные
      isUnlim:=false;
      if unlimdimidp>0 then
        for i:=0 to unlimdimidp-1 do
         if k=unlimdim[i] then isUnlim:=true;

      if (IsUnlim=false) or (unlimdimidp=-1) then begin // если конечная переменная
       if outputid=1 then begin //вывод в мемо
         frmmain.mLog.Lines.Add(#9+pAnsiChar(dimname)+' = '+vartostr(lenp));
       end;
       if outputid=2 then writeln(fout, #9+pAnsiChar(dimname)+' = '+vartostr(lenp)+' ; '); // в файл
      end;

      if (IsUnlim=true) then begin // если бесконечная переменная
       if outputid=1 then frmmain.mLog.Lines.Add(#9+pAnsiChar(dimname)+  // мемо
                          ' = UNLIMITED ; // ('+vartostr(lenp)+' currently)');
       if outputid=2 then writeln(fout, #9+pAnsiChar(dimname)+ // файл
                          ' = UNLIMITED ; // ('+vartostr(lenp)+' currently)');
      end;

    //  showmessage('ok');
    end;


   (* nc_inq_var *) //get variable names, types, shapes
     if outputid=1 then begin // мемо
       frmmain.mLog.Lines.Add('');
       frmmain.mLog.Lines.Add('variables:');
     end;
     if outputid=2 then begin // файл
       writeln(fout);
       writeln(fout, 'variables:');
     end;

     (* NC_MAX_NAME - константа задана на форме main *)
     setlength(varname, NC_MAX_NAME); // задаем длину названия параметра
     setlength(attname, NC_MAX_NAME); // задаем длину названия аттрибута


    (* loop for variables *)
     for k:=0 to nvarsp-1 do begin
      status:=nc_inq_varname(ncid, k, varname); // variable name
       if status>0 then showmessage(pAnsiChar(nc_strerror(status)));

       //define compression rate
      status:=nc_inq_var_deflate(ncid, k, shufflep, deflatep, deflate_levelp);
      if status=0 then comp_ratio:=deflate_levelp else comp_ratio:=-9;
       if comp_ratio=-9 then comp_str:='';
       if comp_ratio=0  then comp_str:='(no compression)';
       if comp_ratio>0  then comp_str:='(compression='+inttostr(comp_ratio)+')';

      status:=nc_inq_vartype(ncid, k, vtype); // variable type
         if status>0 then showmessage(pAnsiChar(nc_strerror(status)));

          VarTypeStr:='';

          if VarToStr(vtype)='0'  then VarTypeStr:='nat';
          if VarToStr(vtype)='1'  then VarTypeStr:='byte';
          if VarToStr(vtype)='2'  then VarTypeStr:='char';
          if VarToStr(vtype)='3'  then VarTypeStr:='short';
          if VarToStr(vtype)='4'  then VarTypeStr:='int';
          if VarToStr(vtype)='5'  then VarTypeStr:='float';
          if VarToStr(vtype)='6'  then VarTypeStr:='double';
          if VarToStr(vtype)='7'  then VarTypeStr:='ubyte';
          if VarToStr(vtype)='8'  then VarTypeStr:='ushort';
          if VarToStr(vtype)='9'  then VarTypeStr:='uint';
          if VarToStr(vtype)='10' then VarTypeStr:='int64';
          if VarToStr(vtype)='11' then VarTypeStr:='uint64';
          if VarToStr(vtype)='12' then VarTypeStr:='string';
          if VarToStr(vtype)='13' then VarTypeStr:='vlen';
          if VarToStr(vtype)='14' then VarTypeStr:='opaque';
          if VarToStr(vtype)='15' then VarTypeStr:='enum';
          if VarToStr(vtype)='16' then VarTypeStr:='compound';

        status := nc_inq_varndims (ncid, k, varndimsp); //dimensions for variable
         if status>0 then showmessage(pAnsiChar(nc_strerror(status)));

        if outputid=1 then begin
         frmmain.cbAllVars.Items.Add(pAnsiChar(varname)); //Добавляем переменные
          if varndimsp>1 then
           frmmain.cbVariables.Items.Add(pAnsiChar(varname)); //НЕ ОСИ!!!
        end;

        SetLength(vardimidsp, varndimsp); //number of dimensions
        status := nc_inq_vardimid (ncid, k, vardimidsp); // Dimention ID's
          if status>0 then showmessage(pAnsiChar(nc_strerror(status)));

        DimStr:='';
        for i:=0 to varndimsp-1 do begin  // Loop for variable dimensions
         setlength(dimname, 0);
         setlength(dimname, NC_MAX_NAME);
         status:=nc_inq_dimname(ncid, vardimidsp[i], dimname); //Dimension's name
          if status>0 then showmessage(pAnsiChar(nc_strerror(status)));


         if DimStr='' then DimStr:=pAnsiChar(dimname) else DimStr:=DimStr+', '+pAnsiChar(dimname);
        end;

        // output in memo log
         if outputid=1 then
          frmmain.mLog.Lines.Add(#9+VarTypeStr+' '+pAnsiChar(varname)+'('+DimStr+') '+comp_str+';');

         // output in file
         if outputid=2 then
          writeln(fout, #9+VarTypeStr+' '+pAnsiChar(varname)+'('+DimStr+') ;');


      status := nc_inq_varnatts (ncid, k, varnattsp); // count of attributes for variable
       if status>0 then showmessage(pAnsiChar(nc_strerror(status)));

       (* internal loop for attributes *)
      for i:=0 to varnattsp-1 do begin
       status := nc_inq_attname(ncid, k, i, attname); // имя аттрибута
        if status>0 then showmessage(pAnsiChar(nc_strerror(status)));

       status := nc_inq_att(ncid, k, pAnsiChar(attname), atttype, attlenp); // тип, длина атрибута
        if status>0 then showmessage(pAnsiChar(nc_strerror(status)));

      // CHAR
      if VarToStr(atttype)='2' then begin
       setlength(atttext, 0);
       setlength(atttext, attlenp);
        nc_get_att_text(ncid, k, pAnsiChar(attname), atttext); //for char
       attstr:=pAnsiChar(atttext);
      end;

      // FLOAT
      if VarToStr(atttype)='5' then begin
       setlength(attfloat, 0);
       setlength(attfloat, attlenp);
        nc_get_att_float(ncid, k, pAnsiChar(attname), attfloat); //for float
        attstr:='';
        for c:=0 to attlenp-1 do
         if attStr='' then attstr:=FloatToStr(attfloat[c]) else
                           attstr:=attstr+', '+FloatToStr(attfloat[c]);
      end;

      // DOUBLE
      if VarToStr(atttype)='6' then begin
       setlength(attdouble, 0);
       setlength(attdouble, attlenp);
        nc_get_att_double(ncid, k, pAnsiChar(attname), attdouble); //for double
        attstr:='';
        for c:=0 to attlenp-1 do
         if attStr='' then attstr:=FloatToStr(attdouble[c]) else
                           attstr:=attstr+', '+FloatToStr(attdouble[c]);
      end;

      // SHORT
      if VarToStr(atttype)='3'  then begin
       setlength(attshort, 0);
       setlength(attshort, attlenp);
        nc_get_att_short(ncid, k, pAnsiChar(attname), attshort); //for short
        attstr:='';
        for c:=0 to attlenp-1 do
         if attStr='' then attstr:=IntToStr(attshort[c]) else
                           attstr:=attstr+', '+IntToStr(attshort[c]);
      end;

      // INTEGER
      if VarToStr(atttype)='4'then begin
       setlength(attinteger, 0);
       setlength(attinteger, attlenp);
        nc_get_att_int(ncid, k, pAnsiChar(attname), attinteger); //for short
        attstr:='';
        for c:=0 to attlenp-1 do
         if attStr='' then attstr:=IntToStr(attinteger[c]) else
                           attstr:=attstr+', '+IntToStr(attinteger[c]);
      end;

      if outputid=1 then frmmain.mLog.Lines.Add(#9+#9+pAnsiChar(varname)+':'+pAnsiChar(attname)+' = '+attstr+' ;');
      if outputid=2 then writeln(fout, #9+#9+pAnsiChar(varname)+':'+pAnsiChar(attname)+' = '+attstr+' ;');
     end;
     (* End of internal loop for attributes *)
    end;
    (* End of variables *)



    (* Global attributes *)
     if outputid=1 then begin
      frmmain.mLog.Lines.Add('');
      frmmain.mLog.Lines.Add('// global attributes:');
     end;
     if outputid=2 then begin
      writeln(fout, '');
      writeln(fout, '// global attributes:');
     end;

    setlength(globname, NC_MAX_NAME);
     for k:=0 to ngattsp-1 do begin
       status := nc_inq_attname(ncid, NC_GLOBAL, k, globname); // global attribute name
        if status>0 then showmessage(pAnsiChar(nc_strerror(status)));
       status := nc_inq_att(ncid, NC_GLOBAL, pAnsiChar(globname), globtype, globlenp); // global type, length
        if status>0 then showmessage(pAnsiChar(nc_strerror(status)));

        // CHAR
        if VarToStr(globtype)='2' then begin
         setlength(globtext, 0);
         setlength(globtext, globlenp);
           nc_get_att_text(ncid, NC_GLOBAL, pAnsiChar(globname), globtext); //global text
           globstr:=pAnsiChar(globtext);
        end;

        // FLOAT
        if VarToStr(globtype)='5' then begin
         setlength(globfloat, 0);
         setlength(globfloat, globlenp);
           nc_get_att_float(ncid, NC_GLOBAL, pAnsiChar(globname), globfloat); //for float
           globstr:='';
           for c:=0 to globlenp-1 do
            if globstr='' then globstr:=FloatToStr(globfloat[c]) else
                               globstr:=globstr+', '+FloatToStr(globfloat[c]);
        end;

        // DOUBLE
        if VarToStr(globtype)='6' then begin
         setlength(globdouble, 0);
         setlength(globdouble, globlenp);
          nc_get_att_double(ncid, NC_GLOBAL, pAnsiChar(globname), globdouble); //for double
          globstr:='';
          for c:=0 to globlenp-1 do
           if globstr='' then globstr:=FloatToStr(globdouble[c]) else
                              globstr:=globstr+', '+FloatToStr(globdouble[c]);
        end;

        // SHORT
        if VarToStr(globtype)='3'  then begin
         setlength(globshort, 0);
         setlength(globshort, globlenp);
          nc_get_att_short(ncid, NC_GLOBAL, pAnsiChar(globname), globshort); //for short
          globstr:='';
          for c:=0 to globlenp-1 do
           if globstr='' then globstr:=IntToStr(globshort[c]) else
                              globstr:=globstr+', '+IntToStr(globshort[c]);
        end;

        // INTEGER
        if VarToStr(globtype)='4'then begin
         setlength(globinteger, 0);
         setlength(globinteger, globlenp);
          nc_get_att_int(ncid, NC_GLOBAL, pAnsiChar(globname), globinteger); //for short
           globstr:='';
           for c:=0 to globlenp-1 do
            if globstr='' then globstr:=IntToStr(globinteger[c]) else
                               globstr:=globstr+', '+IntToStr(globinteger[c]);
      end;
      if outputid=1 then frmmain.mLog.Lines.Add(#9+#9+pAnsiChar(globname)+' = '+globstr+' ;');
      if outputid=2 then writeln(fout, #9+#9+pAnsiChar(globname)+' = '+globstr+' ;');
    end;
   (* End of global attributes *)

    // cursor at the first line
    if outputid=1 then begin
      frmmain.mLog.SelStart:=1;
      frmmain.mLog.SelLength:= 0;
    end;


    //Check netcdf format
     status:=nc_inq_format(ncid, formatp);
      if status>0 then showmessage(pAnsiChar(nc_strerror(status)));

      case formatp of
       1: ncformat:='NC_FORMAT_CLASSIC';
       2: ncformat:='NC_FORMAT_64BIT';
       3: ncformat:='NC_FORMAT_NETCDF4';
       4: ncformat:='NC_FORMAT_NETCDF4_CLASSIC';
      end;

      frmmain.statusbar1.Panels[1].Text:=ncpath+ncname+' || '+ncformat;

  finally
     status:=nc_close(ncid);  // Close file
      if status>0 then showmessage(pAnsiChar(nc_strerror(status)));
   end;
end;


(* Индекс широты *)
function GetLatIndex(Lat:real):integer;
Var
  k:integer;
begin
 Result:=-999;
  for k:=0 to high(ncLat_arr) do
    if ncLat_arr[k]=Lat then Result:=k;
end;

(* Индекс долготы *)
function GetLonIndex(Lon:real):integer;
Var
  k:integer;
begin
 Result:=-999;
  for k:=0 to high(ncLon_arr) do
    if ncLon_arr[k]=Lon then Result:=k;
end;



(* Определяем даты *)
procedure GetDates(ncDate:string);
Var
 k, c:integer;
 IniDate, CurDate:TDateTime;
 // Time in...
 DateInMSeconds, DateInSeconds, DateInMinutes, DateInHours, DateInDays, DateInMonth, DateInYears:boolean;
 Datestr, buf_str:string;
 yy, mn, dd, hh, mm, ss:word;
begin
 frmmain.cbDates.Clear; // date and/or time

 try
 // if date attributes aren't specified
 if ncdate='' then begin
   for k:=0 to high(ncTime_arr) do frmmain.cbDates.Items.Add(floattostr(ncTime_arr[k]));
  exit;
 end;

 DateInMSeconds := false;
 DateInSeconds  := false;
 DateInMinutes  := false;
 DateInHours    := false;
 DateInDays     := false;
 DateInMonth    := false;
 DateInYears    := false;


  if LowerCase(copy(ncDate, 1,12))='milliseconds' then DateInMSeconds :=true;
  if LowerCase(copy(ncDate, 1, 7))='seconds'      then DateInSeconds  :=true;
  if LowerCase(copy(ncDate, 1, 7))='minutes'      then DateInMinutes  :=true;
  if LowerCase(copy(ncDate, 1, 5))='hours'        then DateInHours    :=true;
  if LowerCase(copy(ncDate, 1, 4))='days'         then DateInDays     :=true;
  if LowerCase(copy(ncDate, 1, 6))='months'       then DateInMonth    :=true;
  if LowerCase(copy(ncDate, 1, 5))='years'        then DateInYears    :=true;

   if DateInMSeconds =true then DateStr:=trim(Copy(ncDate, 19, length(ncDate)-18));
   if DateInSeconds  =true then DateStr:=trim(Copy(ncDate, 14, length(ncDate)-13));
   if DateInMinutes  =true then DateStr:=trim(Copy(ncDate, 14, length(ncDate)-13));
   if DateInHours    =true then DateStr:=trim(Copy(ncDate, 12, length(ncDate)-11));
   if DateInDays     =true then DateStr:=trim(Copy(ncDate, 11, length(ncDate)-10));
   if DateInMonth    =true then DateStr:=trim(Copy(ncDate, 13, length(ncDate)-12));
   if DateInYears    =true then DateStr:=trim(Copy(ncDate, 12, length(ncDate)-11));

   //days since 1900-01-01 00:00
 //  showmessage(DateStr+'   '+inttostr(length(DateStr)));

  if length(dateStr)=10 then begin
   yy:=strtoint(copy(DateStr, 1, 4));
   mn:=strtoint(copy(DateStr, 6, 2));
   dd:=strtoint(copy(DateStr, 9, 2));
   hh:=0;
   mm:=0;
   ss:=0;
  end;

   if length(DateStr)>10 then begin
   c:=0;
   for k:=1 to 6 do begin
    buf_str:='';
    repeat
     inc(c);
     if (DateStr[c]<>'-') and (DateStr[c]<>' ') and (DateStr[c]<>':') then buf_str:=buf_str+datestr[c];
    until (DateStr[c]='-') or (DateStr[c]=' ') or
          (DateStr[c]=':') or (Length(dateStr)=c);

  //  showmessage(inttostr(k)+'   '+trim(buf_str));
     case k of
      1: yy:=StrToInt(trim(buf_str));
      2: mn:=StrToInt(trim(buf_str));
      3: dd:=StrToInt(trim(buf_str));
      4: hh:=StrToInt(trim(buf_str));
      5: mm:=StrToInt(trim(buf_str));
      6: begin
         if Length(dateStr)>16 then ss:=trunc(StrToFloat(trim(buf_str))) else ss:=0;
         end;
     end;
   end;
   end;

 //  showmessage(inttostr(yy)+'   '+inttostr(mn)+'   '+inttostr(dd)+'   '+inttostr(hh)+'   '+inttostr(ss));

   if yy>0 then IniDate:=EncodeDateTime(yy, mn, dd, hh, mm, ss, 0);
   if yy=0 then IniDate:=EncodeDateTime(1,  mn, dd, hh, mm, ss, 0);

   for k:=0 to high(ncTime_arr) do begin

    if DateInMSeconds =true then begin
   // showmessage('good');
       CurDate:=incmillisecond(IniDate, trunc(ncTime_arr[k]));
    //   if frac (ncTime_arr[k])>0 then CurDate:=IncMillisecond(CurDate, trunc(frac(ncTime_arr[k])*1000));
    end;

    if DateInSeconds =true then begin
       CurDate:=incsecond(IniDate, trunc(ncTime_arr[k]));
       if frac (ncTime_arr[k])>0 then CurDate:=IncMillisecond(CurDate, trunc(frac(ncTime_arr[k])*1000));
    end;

    if DateInMinutes =true then begin
      CurDate:=incminute(IniDate, trunc(ncTime_arr[k]));
      if frac (ncTime_arr[k])>0 then CurDate:=incsecond(CurDate, trunc(frac(ncTime_arr[k])*60));
    end;

    if DateInHours   =true then begin
      CurDate:=inchour(IniDate, trunc(ncTime_arr[k]));
      if frac (ncTime_arr[k])>0 then CurDate:=incminute(CurDate, trunc(frac(ncTime_arr[k])*60));
    end;

    if DateInDays    =true then begin
      CurDate:=IniDate+ncTime_arr[k];
     // if frac (ncTime_arr[k])>0 then CurDate:=inchour(CurDate, trunc(frac(ncTime_arr[k])*24));
    end;

    if DateInMonth   =true then CurDate:=incmonth (IniDate, trunc(ncTime_arr[k]));
    if DateInYears   =true then CurDate:=incyear  (IniDate, trunc(ncTime_arr[k]));

    //    showmessage(datetostr(IniDate)+'   '+inttostr(trunc(ncTime_arr[k]))+'   '+datetostr(CurDate));

     frmmain.cbDates.Items.Add(datetimetostr(CurDate));
   end;

 except
  // showmessage(ncdate+'   '+datestr+'   '+buf_str);
 end;

end;


procedure IndToDepth(Ind:string; var lev:string);
begin
   if Ind='10001' then lev:='3500';
   if Ind='10002' then lev:='3000';
   if Ind='10003' then lev:='2500';
   if Ind='10004' then lev:='2000';
   if Ind='10005' then lev:='1750';
   if Ind='10006' then lev:='1500';
   if Ind='10007' then lev:='1400';
   if Ind='10008' then lev:='1300';
   if Ind='10009' then lev:='1200';
   if Ind='10010' then lev:='1100';
   if Ind='10011' then lev:='1000';
   if Ind='10012' then lev:='0900';
   if Ind='10013' then lev:='0800';
   if Ind='10014' then lev:='0700';
   if Ind='10015' then lev:='0600';
   if Ind='10016' then lev:='0500';
   if Ind='10017' then lev:='0400';
   if Ind='10018' then lev:='0300';
   if Ind='10019' then lev:='0250';
   if Ind='10020' then lev:='0200';
   if Ind='10021' then lev:='0150';
   if Ind='10022' then lev:='0125';
   if Ind='10023' then lev:='0100';
   if Ind='10024' then lev:='0075';
   if Ind='10025' then lev:='0050';
   if Ind='10026' then lev:='0030';
   if Ind='10027' then lev:='0020';
   if Ind='10028' then lev:='0010';
   if Ind='10029' then lev:='0000';
end;


{ Distance [km] calculation between two points input}
{ Initial coordinates in degres decimal}
Procedure Distance(ln0,ln1,lt0,lt1:real; var Dist:real);
var
lnd,ltd,lnkm,ltkm,m,r:real;
begin
{ Coordinates in decimal reprisentation }
 lnd:=abs(ln1-ln0);
  if lnd>180 then lnd:=abs(360-lnd);
 ltd:=abs(lt1-lt0);
 r:=2*pi*6378.137/360;  {equatorial radius Hayford 1909 [km] 6378.137}
 m:=1.8532; {mile}
 lnkm:=r*cos((lt0+lt1)/2*(pi/180))*lnd;
 ltkm:=r*ltd;
Dist:=sqrt(lnkm*lnkm+ltkm*ltkm);
end;


//.............................................................
//Процедуры и функции вертикальной интерполяции профилей после ОА
//линейная по 2 горизонтам
function ODBPr_Line(x0,x1,x2,px1,px2:real) :real;
          begin
          if (x1-x2)<>0 then
          ODBPr_Line:=(px1*(x0-x2) - px2*(x0-x1)) / (x1 - x2);
          end;
//Лагранж  по 3 горизонтам
procedure ODBPr_Lag(x,x1,x2,x3,px1,px2,px3:real; var value:real);
   var
          a1,a2,a3              :real;
          b1,b2,b3,b4,b5,b6     :real;
          y1,y2,y3              :real;
          begin
          a1:=x-x1;          a2:=x-x2;          a3:=x-x3;
          b1:=x1-x2;         b2:=x1-x3;
          b3:=x2-x1;         b4:=x2-x3;
          b5:=x3-x1;         b6:=x3-x2;
          if (b1*b2<>0) then y1:=(a2*a3)/(b1*b2);
          if (b3*b4<>0) then y2:=(a1*a3)/(b3*b4);
          if (b5*b6<>0) then y3:=(a1*a2)/(b5*b6);
          value:=y1*px1 + y2*px2 + y3*px3;
          end;
//Рейнигер-Росс по 4 горизонтам
Procedure ODBPr_RR(level:real; l_arr,p_arr:array of real; var value:real);
   var
   kk,k,lev_n:longint;
   col,int_sx,mik_int,rown,ox,coin,check:integer;
   x,x1,x2,x3,x4,px1,px2,px3,px4        :real;
   p,p1,p2                              :real;
   c1,c2                                :real;
   a1,a2,a3,a4                          :real;
   l_12,l_23,l_34                       :real;
   ref                                  :real;
   st_lat                               :real;
   lev_f,lev_l,row_l,u                  :real;
   st                                   :string;
{..........................................................}
   begin
       x:=level;

{---uniform profile}
             x1:=l_arr[1];  px1:=p_arr[1];
             x2:=l_arr[2];  px2:=p_arr[2];
             x3:=l_arr[3];  px3:=p_arr[3];
             x4:=l_arr[4];  px4:=p_arr[4];
        if(abs(px1-px2)=0) and
          (abs(px2-px3)=0) and
          (abs(px3-px4)=0) then
          value:=(px2+px3)/2;

{---level coincide}
        coin:=0;
        if(x=x1) then begin value:=px1; coin:=1; end;
        if(x=x2) then begin value:=px2; coin:=1; end;
        if(x=x3) then begin value:=px3; coin:=1; end;
        if(x=x4) then begin value:=px4; coin:=1; end;

{y}     if(coin=0) then begin

{--- If not uniform profile}
        if(abs(px1-px2)>0) or
          (abs(px2-px3)>0) or
          (abs(px3-px4)>0) then
{x}     begin

{--- linearly interpolation}
             l_12:=ODBPr_Line(x,x1,x2,px1,px2);
             l_23:=ODBPr_Line(x,x2,x3,px2,px3);
             l_34:=ODBPr_Line(x,x3,x4,px3,px4);
          {  writeln('line; ',l_12:12:5,l_23:12:5,l_34:12:5);}
          {  readln;}
{--- reference curve}
             a1:=sqr(l_23-l_34)*l_12;
             a2:=sqr(l_12-l_23)*l_34;
             a3:=sqr(l_23-l_34);
             a4:=sqr(l_12-l_23);

                            check:=0;
         if((a3+a4)>0.000001) then check:=1;
            { writeln(a1:10:4,a2:10:4,a3:12:7,a4:12:7);
             writeln'check: ',check:5);}
         case check of
         1: begin  {exclude zero devizion}
             ref:=0.5*( l_23+ ((a1 + a2) / (a3 + a4)) );
{--- parabolic interpolation}
             ODBPr_Lag(x,x1,x2,x3,px1,px2,px3,p1);
             ODBPr_Lag(x,x2,x3,x4,px2,px3,px4,p2);
{--- weighing values}
             a1:=abs((ref-p1))*p2;
             a2:=abs((ref-p2))*p1;
             a3:=abs((ref-p1));
             a4:=abs((ref-p2));
             if (a3+a4)<>0 then value:=(a1+a2)/(a3+a4)
                           else value:=l_23;
     end; {case 1:}
         0:  value:=l_23;
     end; {case}

{x}  end; {if not uniform}
{y}  end; {if level coincide}
   end;


procedure ODBPr_VertInt(IntLev,LU1,LU2,LD1,LD2,VU1,VU2,VD1,VD2:real;
                        var IntVal:real; var Enable:boolean; Var IntMethod: integer);
var
k:integer;
nu,nd:integer;
h1Limit,h2Limit,h1,h2,h1u,h1d,h2u,h2d:real;
x1,x2,x3,x4,px1,px2,px3,px4,LineVal,pmax,pmin,deviation,rrVal,LagVal:real;
lev_arr,val_arr: array[1..4] of real;
begin
Enable:=false;

   (* update от 10.02.2010 *)
  //lev_arr[1]:=LU2; lev_arr[2]:=LU1; lev_arr[3]:=LD1; lev_arr[4]:=LD2;
  //val_arr[1]:=VU2; val_arr[2]:=VU1; val_arr[3]:=VD1; val_arr[4]:=VD2;
  lev_arr[1]:=LU1; lev_arr[2]:=LU2; lev_arr[3]:=LD1; lev_arr[4]:=LD2;  //AK
  val_arr[1]:=VU1; val_arr[2]:=VU2; val_arr[3]:=VD1; val_arr[4]:=VD2;  //AK


   //определяем пределы интервалов глубин при которых проводится интерполяция
   h1Limit:=5+(1000-5)/3500*IntLev;     {inner limit}
   h2Limit:=200+(1000-200)/3500*IntLev; {upper limit}

   //число горизонтов с наблюдениями выше и ниже стандартного
    nu:=0;
    nd:=0;
    for k:=1 to 2 do if lev_arr[k]<>-9 then nu:=nu+1;
    for k:=3 to 4 do if lev_arr[k]<>-9 then nd:=nd+1;


{!}if (nu>0) and (nd>0) then begin

   //разности глубин
     h1:=9999; h2:=9999;
     h2u:=9999; h2d:=9999;
     h1u:=abs(IntLev-lev_arr[2]);
     h1d:=abs(IntLev-lev_arr[3]);
     if nu>1 then h2u:=abs(IntLev-lev_arr[1]);
     if nd>1 then h2d:=abs(IntLev-lev_arr[4]);

     h1:=abs(lev_arr[3]-lev_arr[2]); //inner distance
     if (nu>1) and (nd>1) then
     h2:=abs(lev_arr[4]-lev_arr[1]); //outer distance

     //выбираем метод интерполяции
     //интерполяция проводится если расстояние от интерполируемого
     //до одного из ближайших горизонтов (h1u/h1d) не превышает установленный
     //внутренний предел (h1Limit)

     //интерполяция по 3 точкам используются если растояния от интерполируемого горизонта
     //до выше или ниже лежащей пары горизонтов (h1u,h2u  или h1d,h2d) не выходят
     //за установленные пределы (h1limit,h2Limit)

     //интерполяция по 4 точкам используются если растояния между внутренней и внешней парами
     //ближайших горизонтов не выходят за установленные пределы (h1limit,h2Limit)

     //если полученное нелинейными методами значение не укладывается в диапазон
     //значений параметра на ближайших горизонтах сниженного на 50% (из наибольшего
     //значения вычитается 25% диапозона, к наименьшему прибавляется 25% диапозона)
     //то значение замещается величеной полученной линейным методом

     IntMethod:=1; //Skip Interpolation
     if (h1u<=h1Limit) or (h1d<=h1Limit) then begin
                                                 IntMethod:=3; {  + x +    Linear}
      if (h1<=h1Limit)  and (h2<=h2Limit)  then  IntMethod:=4; {+ + x + +  RR}
      if (h2u<=h2Limit) and (h2d>h2Limit)  then  IntMethod:=5; {+ + x +    LagU}
      if (h2u>h2Limit)  and (h2d<=h2Limit) then  IntMethod:=6; {  + x + +  LagD}
     end;

     // showmessage('IntMethod: '+inttostr(intMethod));
     // sleep(1);
     //если расстояние между двумя ближайшими горизонтами больше внешнего предела,
     //интерполяция не проводится вообще
     if h1>h2Limit then IntMethod:=1;

     //memo1.Lines.Add('Int Method='+inttostr(IntMethod));


     case IntMethod of
{NO} 1: begin
         Enable:=false;
        end;
{Lin}3: begin
         Enable:=true;
         x1:=lev_arr[2];  px1:=val_arr[2];
         x2:=lev_arr[3];  px2:=val_arr[3];
         IntVal:=ODBPr_Line(IntLev,x1,x2,px1,px2);
        end;
{RR} 4: begin
         Enable:=true;
         x1:=lev_arr[2];  px1:=val_arr[2];
         x2:=lev_arr[3];  px2:=val_arr[3];
         LineVal:=ODBPr_Line(IntLev,x1,x2,px1,px2);
         IntVal:=LineVal;
         {...define nearest max and min}
         if(px1>=px2) then begin pmax:=px1; pmin:=px2; end
                      else begin pmax:=px2; pmin:=px1; end;
         Deviation:=abs(pmax-pmin)*0.25;
         ODBPr_RR(IntLev,lev_arr,val_arr,rrVal);

         //if interpolated value more or less than nearest values
         //and difference with linear int less then 25%
         if(rrVal>pmin) and (rrVal<pmax) and
           (rrVal>LineVal-deviation) and (rrVal<LineVal+deviation)
         then  IntVal:=rrVal;
     end; {4}

{LagUp} 5: begin
          Enable:=true;
            x1:=lev_arr[1];    px1:=val_arr[1];
            x2:=lev_arr[2];    px2:=val_arr[2];
            x3:=lev_arr[3];    px3:=val_arr[3];
            LineVal:=ODBPr_Line(IntLev,x2,x3,px2,px3);
            IntVal:=LineVal;
            {...define nearest max and min}
          if(px2>=px3) then begin pmax:=px2; pmin:=px3; end
                       else begin pmax:=px3; pmin:=px2; end;
            Deviation:=abs(pmax-pmin)*0.25;
            ODBPr_Lag(IntLev,x1,x2,x3,px1,px2,px3,LagVal);

            {...if interpolated value more or less than nearest values}
            if(LagVal>pmin) and (LagVal<pmax) and
              (LagVal>LineVal-deviation) and (LagVal<LineVal+deviation)
            then IntVal:=LagVal;
          end; { case 5:}

{LagDw} 6: begin
           Enable:=true;
            x1:=lev_arr[2];  px1:=val_arr[2];
            x2:=lev_arr[3];  px2:=val_arr[3];
            x3:=lev_arr[4];  px3:=val_arr[4];
            LineVal:=ODBPr_Line(IntLev,x1,x2,px1,px2);
            IntVal:=LineVal;
            {...define nearest max and min}
           if(px1>=px2) then begin pmax:=px1; pmin:=px2; end
                        else begin pmax:=px2; pmin:=px1; end;
            Deviation:=abs(pmax-pmin)*0.25;
            ODBPr_Lag(IntLev,x1,x2,x3,px1,px2,px3,LagVal);
            if(LagVal>pmin) and (LagVal<pmax) and
              (LagVal>LineVal-deviation) and (LagVal<LineVal+deviation)
            then IntVal:=LagVal;
         end; {6}
     end; {case}
{!}end;
end;


{m=0- depth to pressure, 1- pressure to depth}
procedure Depth_to_Pressure(z,lt_real:real; m:integer; var press:real);
var
k:integer;
gr0,pi,zi,x,eps :double;
 {...}
 function depth(p0:real;lat0:real):Real;
  begin
   depth:=((((-1.82E-15*p0+2.279E-10)*p0-2.2512E-5)*p0+9.72659)*p0)/lat0;
  end;
 function drdep(p0:real;lat0:real):real;
  begin
   drdep:=(((-7.28E-15*p0+6.837E-10)*p0-4.5024E-5)*p0+9.72659)/lat0;
  end;
 function gr(xz:real; gr0:real):real;
  begin
   gr:=gr0+1.092E-6*xz;
  end;
   {...}
  begin
   x:=sin(lt_real/57.29578);
   x:=x*x;
   gr0:=9.780318*(1+(5.2788E-3+2.36E-5*x)*x);
  case m of
  0:  begin
       pi:=z;
       zi:=depth(z,gr(z,gr0));
       for k:=1 to 10 do begin
        eps:=abs(zi-z);
        if(eps>0.0001) then begin
         pi:=pi+(z-zi)/drdep(pi,gr(pi,gr0));
         zi:=depth(pi,gr(pi,gr0));
        end;
       end;
            press:=pi;
            end;
  1:  press:=depth(z,gr(z,gr0));
  end; {case}
 end; {Depth_to_Pressure}


// The International Equation of State of seawater
// dens [kg/m*3]
// The specific volume (or steric) anomaly (svan [m*3/kg])
Procedure IEOS80(press,t,s:real;var svan,dens:real);
	var
	st,s0,a,a1,k0,r1,sig,tt,t0,
	b,b1,kw,r2,dr35p,pt,p0,c,aw,k35,r3,
	dvan,sr,d,bw,dk,gam,sva,e,pk,v350p:real;
	i,n:integer;
	const r3500=1028.1063; r4=4.8314e-4; dr350=28.106331;
	begin
	st:=s;
	s0:=st;
	tt:=t;
	t0:=tt;
	pt:=0.1*press;
	p0:=pt;
	sr:=sqrt(abs(s0));
	r1:=((((6.536332e-9*t0-1.120083e-6)*t0+1.001685e-4)*t0-
	    9.095290e-3)*t0+6.793952e-2)*t0-28.263737;
	r2:=(((5.3875e-9*t0-8.2467e-7)*t0+7.6438e-5)*t0-4.0899e-3)*t0+
	    8.24493e-1;
	r3:=(-1.6546e-6*t0+1.0227e-4)*t0-5.72466e-3;
	sig:=(r4*s0+r3*sr+r2)*s0+r1;
	v350p:=1./r3500;
	sva:=-sig*v350p/(r3500+sig);
	dens:=sig+dr350;
	svan:=sva*1e8;
	{   }
	e:=(9.1697e-10*t0+2.0816e-8)*t0-9.9348e-7;
	bw:=(5.2787e-8*t0-6.12293e-6)*t0+3.47718e-5;
	b:=bw+e*s0;
	d:=1.91075e-4;
	c:=(-1.6078e-6*t0-1.0981e-5)*t0+2.2838e-3;
	aw:=((-5.77905e-7*t0+1.16092e-4)*t0+1.43713e-3)*t0-0.1194975;
	a:=(d*sr+c)*s0+aw;
	b1:=(-5.3009e-4*t0+1.6483e-2)*t0+7.944e-2;
	a1:=((-6.1670e-5*t0+1.09987e-2)*t0-0.603459)*t0+54.6746;
	kw:=(((-5.155288e-5*t0+1.360477e-2)*t0-2.327105)*t0+
	    148.4206)*t0-1930.06;
	k0:=(b1*sr+a1)*s0+kw;
	dk:=(b*p0+a)*p0+k0;
	k35:=(5.03217e-5*p0+3.35940552)*p0+21582.27;
	gam:=p0/k35;
	pk:=1-gam;
	sva:=sva*pk+(v350p+sva)*p0*dk/(k35*(k35+dk));
	svan:=sva*1e8;
	v350p:=v350p*pk;
	dr35p:=gam/v350p;
	dvan:=sva/(v350p*(v350p+sva));
	dens:=dr350+dr35p-dvan;
end;{IEOS80}


function DirectoryIsEmpty(Directory: string): Boolean;
var
  SR: TSearchRec;
  i: Integer;
begin
  Result := False;
  FindFirst(IncludeTrailingPathDelimiter(Directory) + '*', faAnyFile, SR);
  for i := 1 to 2 do
    if (SR.Name = '.') or (SR.Name = '..') then
      Result := FindNext(SR) <> 0;
  FindClose(SR);
end;

end.
