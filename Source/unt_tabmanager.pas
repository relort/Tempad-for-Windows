unit unt_tabmanager;

interface

uses
    Windows,
    Messages,
    SysUtils,
    Classes,

    icClasses,
    icUtils,

    sqlite3,
    sqlitetable3
    ;

// Логіка таблиць полягає в тому, що в одній таблиці зберігаються описи, а в іншій данні
//
//
//     | TABLE 'Info'  |             | TABLE 'Data' |
//     | ID            | = = = = = = | ID           |
//     | Title         |             | Raw          | - данні
//     | Order         |
//     | ...           |
//
// ID from 'Info' == ID from 'Data'. Тому для того, шо витягнути данні, йдем в 'Data' по тому самому індексу
//


type
    iccTabManager =
        class sealed( iccObject)
            public type
                ictGetAllRequest =
                    ( garAll,        // deleted and not deleted
                      garNotDeleted, // only those that is not deleted
                      garDeleted     // only deleted
                    );

                ictSearchRequest = ictGetAllRequest;

                iccSearchItem =
                    class
                        public
                            ID      : Integer;
                            Title   : String;
                            Deleted : Boolean;
                        public
                            constructor Create( _id : DWORD; _title : String; _deleted : Boolean);
                    end;

                ictSearchItemCallbackFunc = reference to procedure ( _id : DWORD; _title : String; _Deleted : Boolean; var _aborted : Boolean);
                // _aborted is TRUE, that break the callbacks
            strict private const
                c_table_name_Info   = 'Info';
                c_table_name_Data   = 'Data';

                { table INFO}
                c_table_Info_column_count = 5;

                c_table_Info_columnID_name         = 'ID';
                  c_table_Info_columnID_type       = 'INTEGER PRIMARY KEY';
                  c_table_Info_columnID_index      = 0;

                c_table_Info_columnTitle_name      = 'Title';
                  c_table_Info_columnTitle_type    = 'TEXT';
                  c_table_Info_column1Title_index  = 1;

                c_table_Info_columnOrder_name      = 'Order';
                  c_table_Info_columnOrder_type    = 'NUMERIC';
                  c_table_Info_columnOrder_index   = 2;


                c_table_Info_columnDeleted_name    = 'Deleted';
                  c_table_Info_columnDeleted_type  = 'Number';
                  c_table_Info_columnDeleted_index = 3;

                c_table_Info_columnDelTime_name    = 'DelTime';
                  c_table_Info_columnDelTime_type  = 'INTEGER';
                  c_table_Info_columnDelTime_index = 4;

                { table DATA}
                c_table_Data_column_count = 2;

                c_table_Data_columnID_name         = 'ID';
                  c_table_Data_columnID_type       = 'INTEGER';
                  c_table_Data_columnID_index      = 0;

                c_table_Data_columnRaw_name        = 'Raw';
                  c_table_Data_columnRaw_type      = 'BLOB';
                  c_table_Data_columnRaw_index     = 1;
            strict private type
                ictState = ( sValidatedStructure,
                             sSessionIsOpened,
                             sInitialStats,
                             sDoVacuum
                           );
                icsState = set of ictState;
            strict private type
                icrParamRec =
                    record
                        public
                            Val1,
                            Val2 : String;
                        public
                            class function mk( _v1, _v2 : String) : icrParamRec; static; inline;
                    end;
            strict private
                FState      : icsState;
                FDBFilename : String;
                FDB         : TSQLiteDatabase;

                FLastID     : Integer;
                FCount      : Integer;
            strict private
                // db routines
                class function q_Update( _table : String;  _col, _val, _predicateCol, _predicateVal : String) : String; overload; // simple 1 val Update Query

                class function q_Update( _table : String; _colsVals, _predicateColVals : array of icrParamRec) : String; overload;

                class function q_DeleteID( _table : String; _arr : TArray<integer>) : String;


                class function gen_quote( _str : String; _coma : Boolean = true) : String; inline;
                class function gen_field( _name, _type : String; _coma : Boolean = true) : String; inline;
                //
                var FQuery_Counter_Writable : Integer; // queries followed with writing to db
                //
                function db_exec     ( _str : String) : Boolean; overload;
                function db_exec     ( _str : String; _stream : TStream) : Boolean; overload;
                function db_validateStructure() : Boolean; // true is everything is ok or reconsturcted
                function db_vacuum() : Boolean;
            strict private
                function initialStats() : Boolean;
            public
                constructor Create( _dbfilename : String); // creating and retrieving from DB
                destructor Destroy(); override;
            public
                function isCommitNeeded() : Boolean; // check if there were writable queries. Here we can check if it really nessesary to session_End() and then again session_Start()

                function session_Start() : Boolean;
                function session_End  () : Boolean;

                procedure vacuumEnable( _enable : Boolean = true);
                procedure vacuumPerform();

                procedure interrupt(); // terrible shit! Падло не робить так, як треба.. Кароч повна хуєта. (ну або я даун :) )

                function Count() : Integer; // return = count
                function GetAll( _prm : ictGetAllRequest) : iccxList;

                // search
                function Search( _str : String; _sr : ictSearchRequest; _perItemCallback : ictSearchItemCallbackFunc) : Boolean; // true - if found something, false - if not
                //

                function Add( _title : String; _order : Integer = -1) : Integer; // return = ID, -1 if not added
                function Del( _tid   : Integer)         : Boolean; overload; // true if done, otherwise false
                function Del( _tids  : TArray<integer>) : Boolean; overload;

                function Mark( _tid : Integer; _deleted : Boolean = true) : Boolean;

                function getInfo( _tid : Integer; out _title : String; out _order : Integer; out _deleted : Boolean) : Boolean; // true if data was taken
                function setInfo( _tid : Integer;     _title : String;     _order : Integer) : Boolean;

                function getData( _tid : Integer; out _data : String)   : Boolean; overload; // if true then _data = retrieved blob
                function getData( _tid : Integer;     _strs : TStrings) : Boolean; overload;
                function setData( _tid : Integer;     _data : String) : Boolean;

                function getTable( _str : String) : TSQLiteTable;
        end;

implementation


{ iccTabManager.icrParamRec }

class function iccTabManager.icrParamRec.mk(_v1, _v2: String): icrParamRec;
begin
    result.Val1 := _v1;
    result.Val2 := _v2;
end;

{ iccTabManager }

class function iccTabManager.gen_quote( _str : String; _coma : Boolean = true) : String;
begin
    result := '"' + _str + '"';
    if _coma
        then result := result + ','
end;

class function iccTabManager.gen_field( _name, _type : String; _coma : Boolean = true) : String;
begin
    result := '"' + _name + '" ' + _type;
    if _coma then
        result := result + ',';
end;

class function iccTabManager.q_Update( _table, _col, _val, _predicateCol, _predicateVal : String) : String;
begin
    result := 'UPDATE `' +  _table + '` SET `' + _col + '` = "' + str_screening( _val, '''', '''''') + '" WHERE `' + _predicateCol + '` = "' + str_screening( _predicateVal, '''', '''''') + '"';
end;

class function iccTabManager.q_Update( _table : String; _colsVals, _predicateColVals : array of icrParamRec) : String;

    function mkColsVals( _arr : array of icrParamRec) : string;
    var ndx : integer;
        len : integer;
    begin
        len := Length( _arr);

        for ndx := 0 to len - 1 do
            begin
                result := result + ' `' + _arr[ndx].Val1 + '` = "' + _arr[ndx].Val2 + '"';
                if ndx + 1 < len
                    then result := result + ', ';
            end;
    end;

begin
    Result := 'UPDATE `' + _table + '` SET ' + str_screening( mkColsVals( _colsVals), '''', '''''') + ' WHERE ' + str_screening( mkColsVals( _predicateColVals), '''', '''''');
end;

class function iccTabManager.q_DeleteID( _table : String; _arr : TArray<integer>) : String;

    function mkColsVals() : String;
    var ndx : integer;
        len : integer;
    begin
        len := Length( _arr);

        for ndx := 0 to len - 1 do
            begin
                Result := result + ' `ID` = ' + IntToStr( _arr[ndx]);
                if ndx + 1 < len
                    then result := result + ' or ';
            end;
    end;

begin
    Result := 'DELETE FROM `' + _table + '` WHERE ' + str_screening( mkColsVals(), '''', '''''');
end;

function iccTabManager.db_exec( _str : String) : Boolean;
begin
    result := true;

    try
        FDB.ExecSQL( AnsiString( UTF8Encode( _str)));
        inc( FQuery_Counter_Writable);
    except
        result := false;
    end;
end;

function iccTabManager.db_exec( _str : String; _stream : TStream) : Boolean;
begin
    result := true;

    try
        FDB.UpdateBlob( AnsiString( UTF8Encode( _str)), _stream);
        inc( FQuery_Counter_Writable);
    except
        result := false;
    end;
end;

function iccTabManager.db_validateStructure() : Boolean;
var tmpTable          : TSQLiteTable;
    needToCreateTable : Boolean;


    function checkColumns_table_Info( _availAmount : Integer) : Boolean; // true if everything is ok
    var colarr : array of record N, T : String end; {Name, Type}
        ndx    : Integer;
    begin
        result := false;
        if _availAmount <> c_table_Info_column_count
            then exit;

        setLength( colarr, c_table_Info_column_count);

        // get info
        tmpTable.MoveFirst();
        for ndx := 0 to c_table_Info_column_count - 1 do
            begin
                colarr[ndx].N := tmpTable.FieldAsString( 1);
                colarr[ndx].T := tmpTable.FieldAsString( 2);

                tmpTable.Next();
            end;

        // compare
        ndx := 0;
        ndx := ndx + Byte( (colarr[0].N = c_table_Info_columnID_name     ) and ( colarr[0].T = 'INTEGER'));
        ndx := ndx + Byte( (colarr[1].N = c_table_Info_columnTitle_name  ) and ( colarr[1].T = c_table_Info_columnTitle_type   ));
        ndx := ndx + Byte( (colarr[2].N = c_table_Info_columnOrder_name  ) and ( colarr[2].T = c_table_Info_columnOrder_type   ));
        ndx := ndx + Byte( (colarr[3].N = c_table_Info_columnDeleted_name) and ( colarr[3].T = c_table_Info_columnDeleted_type ));
        ndx := ndx + Byte( (colarr[4].N = c_table_Info_columnDelTime_name) and ( colarr[4].T = c_table_Info_columnDelTime_type ));

        result := ndx = c_table_Info_column_count;

        setLength( colarr, 0);
    end;

    function checkColumns_table_Data( _availAmount : Integer) : Boolean;
    var colarr : array of record N, T : String end; {Name, Type}
        ndx    : Integer;
    begin
        result := false;
        if _availAmount <> c_table_Data_column_count
            then exit;

        setLength( colarr, c_table_Data_column_count);

        // get info
        tmpTable.MoveFirst();
        for ndx := 0 to c_table_Data_column_count - 1 do
            begin
                colarr[ndx].N := tmpTable.FieldAsString( 1);
                colarr[ndx].T := tmpTable.FieldAsString( 2);

                tmpTable.Next();
            end;

        // compare
        ndx := 0;
        ndx := ndx + Byte( (colarr[0].N = c_table_Data_columnID_name ) and ( colarr[0].T = 'INTEGER'));
        ndx := ndx + Byte( (colarr[1].N = c_table_Data_columnRaw_name) and ( colarr[1].T = c_table_Data_columnRaw_type));

        result := ndx = c_table_Data_column_count;

        setLength( colarr, 0);
    end;

begin
    result := true;

    try
        tmpTable := nil;
        try
            ////////////////
            // CHECKING INFO
            needToCreateTable := not FDB.TableExists( c_table_name_Info); // do we need to create table

            if not needToCreateTable
                then begin
                         tmpTable := getTable( 'PRAGMA TABLE_INFO(' + c_table_name_Info + ')');

                         if not checkColumns_table_Info( tmpTable.RowCount)
                             then begin
                                      needToCreateTable := True;

                                      if not db_exec( 'DROP TABLE ' + c_table_name_Info)
                                          then raise iccException.Create( 'db_validateStructure() -> DROP INFO TABLE failed.');
                                  end;
                     end;

            if needToCreateTable
                then if not db_exec( 'CREATE TABLE ' + c_table_name_Info +
                                     '(' + gen_field( c_table_Info_columnID_name     , c_table_Info_columnID_type     ) +
                                           gen_field( c_table_Info_columnTitle_name  , c_table_Info_columnTitle_type  ) +
                                           gen_field( c_table_Info_columnOrder_name  , c_table_Info_columnOrder_type  ) +
                                           gen_field( c_table_Info_columnDeleted_name, c_table_Info_columnDeleted_type) +
                                           gen_field( c_table_Info_columnDelTime_name, c_table_Info_columnDelTime_type, false) +
                                     ')'
                                   )
                         then raise iccException.Create( 'db_validateStructure() -> CREATE INFO TABLE failed.');

            tmpTable.Free();
            tmpTable := nil;


            ////////////////
            // CHECKING DATA
            needToCreateTable := not FDB.TableExists( c_table_name_Data); // do we need to create table

            if not needToCreateTable
                then begin
                         tmpTable := getTable( 'PRAGMA TABLE_INFO(' + c_table_name_Data + ')');

                         if not checkColumns_table_Data( tmpTable.RowCount)
                             then begin
                                      needToCreateTable := True;

                                      if not db_exec( 'DROP TABLE ' + c_table_name_Data)
                                          then raise iccException.Create( 'db_validateStructure() -> DROP DATA TABLE failed.');
                                  end;
                     end;

            if needToCreateTable
                then if not db_exec( 'CREATE TABLE ' + c_table_name_Data +
                                     '(' + gen_field( c_table_Data_columnID_name, c_table_Data_columnID_type) +
                                           gen_field( c_table_Data_columnRaw_name, c_table_Data_columnRaw_type, false) +
                                     ')'
                                   )
                         then raise iccException.Create( 'db_validateStructure() -> CREATE DATA TABLE failed.');
        finally
            tmpTable.Free();
        end;
    except
        result := false;
    end;
end;

function iccTabManager.db_vacuum() : Boolean;
begin
    result := true;

    if not ( sDoVacuum in FState)
        then exit;

    try
        if not db_exec( 'VACUUM')
            then raise iccException.Create( 'db_vacuum() -> failed.');

        Exclude( FState, sDoVacuum);
    except
        result := false;
    end;
end;

function iccTabManager.initialStats() : Boolean;
var tmpTable : TSQLiteTable;
begin
    result := true;

    tmpTable := nil;
    try
        tmpTable := getTable( 'SELECT rowid FROM ' + c_table_name_Info + ' ORDER BY rowid DESC');

        FCount  := tmpTable.RowCount;

        if tmpTable.RowCount = 0
            then FLastId := 0
            else FLastID := StrToInt( tmpTable.FieldAsString( 0));
    except
        result := false;
    end;
    tmpTable.Free();
end;

constructor iccTabManager.Create(_dbfilename: String);
begin
    // default state
    FState := [];
    //

    FDBFilename := _dbfilename;
    FDB := TSQLiteDatabase.Create( FDBFilename);

    if not session_Start()
        then raise iccException.Create( 'session_Start() -> failed. Database is locked');

    if not db_validateStructure()
        then raise iccException.Create( 'db_validateStructure() -> failed');
    Include( FState, sValidatedStructure);

    if not initialStats() // FLastID, FCount
        then raise iccException.Create( 'initialStats() -> failed');
    Include( FState, sInitialStats);
end;

destructor iccTabManager.Destroy;
begin
    if FDB = nil
        then raise iccException.Create( 'iccTabManager.Destroy() -> FDB = nil', iccException.c_prior_FATAL);



    if not session_End()
        then raise iccException.Create( 'session_End() -> failed');

    if not db_vacuum()
        then raise iccException.Create( 'db_vacuum() -> failed');

    FDB.Destroy();
    inherited;
end;

function iccTabManager.isCommitNeeded() : Boolean;
begin
    result := FQuery_Counter_Writable > 0;
    //if result then MessageBox( 0, 'need to save', '', 0);
end;

function iccTabManager.session_Start() : Boolean;
begin
    result := db_exec( 'BEGIN EXCLUSIVE');

    if result
        then Include( FState, sSessionIsOpened);

    // reset counter
    FQuery_Counter_Writable := 0; // duplicated for sure
end;

function iccTabManager.session_End  () : Boolean;
begin
    result := true;

    if not ( sSessionIsOpened in FState)
        then exit;

    result := db_exec( 'COMMIT');

    // reset counter
    FQuery_Counter_Writable := 0; // duplicated for sure

    Exclude( FState, sSessionIsOpened);
end;

procedure iccTabManager.vacuumEnable( _enable : Boolean = true);
begin
    if _enable
        then Include( FState, sDoVacuum)
        else Exclude( FState, sDoVacuum);
end;

procedure iccTabManager.vacuumPerform();
begin
    if not db_vacuum()
        then raise iccException.Create( 'db_vacuum() -> failed.');
end;

procedure iccTabManager.interrupt();
begin
     raise iccException_NotImplYet.Create();

     sqlite3.SQLite3_Interrupt( FDB);
     sqlite3.SQLite3_Interrupt( FDB.DB);
end;

function iccTabManager.Count() : Integer;
begin
    result := FCount;
end;

function iccTabManager.GetAll( _prm : ictGetAllRequest) : iccxList;
var tmpTable : TSQLiteTable;
    ndx : integer;

    query : String;
begin
    result := nil; // default result

    query := 'SELECT rowid FROM ' + c_table_name_Info + ' %s ORDER BY `%s` %s';
    case _prm of
        garAll
            : begin
                  query := Format( query, ['', c_table_Info_columnOrder_name, 'ASC']);
              end;
        garNotDeleted
            : begin
                  query := Format( query, ['WHERE `Deleted`=0', c_table_Info_columnOrder_name, 'ASC']);
              end;
        garDeleted
            : begin
                  query := Format( query, ['WHERE `Deleted`=1', c_table_Info_columnDelTime_name, 'DESC']);
              end;
    end;

    tmpTable := nil;
    try
        //tmpTable := FDB.GetTable( AnsiString( query));
        tmpTable := getTable( String( AnsiString( query)));


        result := iccxList.Create( 128);

        for ndx := 0 to tmpTable.RowCount - 1 do
            begin
                result.Add( StrToInt( tmpTable.FieldAsString( 0)));
                tmpTable.Next();
            end;
    except
        result.Free();
        result := nil;
    end;
    tmpTable.Free();
end;

function iccTabManager.Search( _str : String; _sr : ictSearchRequest; _perItemCallback : ictSearchItemCallbackFunc) : Boolean;
var tmpTable    : TSQLiteTable;
    ndx         : integer;

    query       : String;

    aborted     : Boolean;

    int_id      : DWORD;
    str_title   : string;
    bol_deleted : Boolean;
begin
    tmpTable := nil;
    try
        _str := str_screening( _str, '"', '""');
        _str := str_screening( _str, '*', '%');

        query := Format( 'SELECT %s FROM `%s` ,' +
                         '(' +
                           'SELECT ID AS OCCUR FROM `%s`' +
                           'WHERE `%s` LIKE "%%%s%%"' +
                           'UNION ' +
                           'SELECT ID AS OCCUR FROM `%s`' +
                           'WHERE `%s` LIKE "%%%s%%"' +
                         ')' +
                         'WHERE ID = OCCUR '
                         ,
                         [ 'ID, Title, Deleted',
                           c_table_name_Info,
                           c_table_name_Data,
                           'Raw',
                           _str,
                           c_table_name_Info,
                           'Title',
                           _str
                         ]
                       );

        case _sr of
            garAll
                : begin
                      // do nothing
                      //query := query + '';
                  end;
            garNotDeleted
                : begin
                      //
                      query := query + ' AND Deleted = 0';
                  end;
            garDeleted
                : begin
                      query := query + ' AND Deleted = 1';
                  end;
        end;

        query := query + ' ORDER BY DELETED ASC, DelTime DESC';


        // DO
        tmpTable := getTable( String( AnsiString( UTF8Encode( query))));

        // loop
        aborted := false;
        for ndx := 0 to tmpTable.RowCount - 1 do
            if not aborted
                then begin
                         int_id      := tmpTable.FieldAsInteger( 0);
                         str_title   := UTF8ToString( RawByteString( tmpTable.FieldAsString( 1)));
                         bol_deleted := Boolean( StrToInt( tmpTable.FieldAsString( 2)));

                         _perItemCallback( int_id, str_title, bol_deleted, aborted);

                         tmpTable.Next();
                     end;

        result := true;
    except
        result := false; // error and fuck off
    end;

    tmpTable.Free();
end;

function iccTabManager.Add( _title : String; _order : Integer = -1) : Integer;
begin
    try
        if not db_exec( 'INSERT INTO ' + c_table_name_Info +
                        '(' + gen_quote( c_table_Info_columnID_name) +
                              gen_quote( c_table_Info_columnTitle_name) +
                              gen_quote( c_table_Info_columnOrder_name) +
                              gen_quote( c_table_Info_columnDeleted_name, false) +
                        ')' +
                        'VALUES' +
                        '(' + IntToStr( FLastID + 1)       + ','  +
                              gen_quote( str_screening( _title))  +
                              IntToStr( _order)            + ','  +
                              IntToStr( 0)                 +
                        ')'
                      )
            or
            not db_exec( 'INSERT INTO ' + c_table_name_Data +
                         '(' + gen_quote( c_table_Data_columnID_name, false) + ')' +
                         'VALUES' +
                         '(' + IntToStr( FLastID + 1) + ')'
                       )

            then raise iccException.Create( 'tab_Add() -> failed.');

        FLastID := FLastID + 1;
        result  := FLastID; // !
    except
        result := -1;
    end;
end;

function iccTabManager.Del( _tid   : Integer) : Boolean; // true if done, otherwise false
begin
    { TODO: Improve. Add Exceptions}
    result := db_exec( 'DELETE FROM ' + c_table_name_Info + ' WHERE rowid = ' + IntToStr( _tid));

    if not result
        then raise iccException.Create( 'Error Message');

    result := db_exec( 'DELETE FROM ' + c_table_name_Data + ' WHERE ' + c_table_Data_columnID_name + ' = ' + IntToStr( _tid));
end;

function iccTabManager.Del(_tids: TArray<integer>) : Boolean;
begin
    raise iccException_NotImplYet.Create();
    result := db_exec( q_DeleteID( c_table_name_Info, _tids));
end;

function iccTabManager.Mark( _tid : Integer; _deleted : Boolean = true) : Boolean;
begin
    //result := db_exec( q_Update( c_table_name, c_column4_name, IntToStr( Byte( _deleted)), 'rowid', IntToStr( _tid)));
    result := db_exec( q_Update( c_table_name_Info,
                                 // set
                                 [ icrParamRec.mk( c_table_Info_columnDeleted_name, IntToStr( Byte(_deleted))),
                                   icrParamRec.mk( c_table_Info_columnDelTime_name, FloatToStr( now))
                                 ],
                                 // predicate
                                 [icrParamRec.mk( 'rowid', IntToStr( _tid))]
                               )
                     );
end;

function iccTabManager.getInfo( _tid : Integer; out _title : String; out _order : Integer; out _deleted : Boolean) : Boolean;
var tmpTable : TSQLiteTable;
begin
    result := true;

    tmpTable := nil;
    try
        tmpTable := getTable( String( AnsiString(
                              'SELECT `' + c_table_Info_columnTitle_name + '`, `'
                                         + c_table_Info_columnOrder_name + '`, `'
                                         + c_table_Info_columnDelTime_name + '` '  +
                              'FROM ' + c_table_name_Info + ' WHERE rowid = ' + IntToStr( _tid)
                              )
                            ));

        if tmpTable.RowCount = 0
            then raise iccException.Create( 'tab_getInfo() -> Unexisted _tid was specified.');


        _title   := Utf8ToString( AnsiString( tmpTable.FieldAsString( 0)));
        _order   := StrToIntDef( tmpTable.FieldAsString( 1), 0);
        _deleted := Boolean( StrToIntDef( tmpTable.FieldAsString( 2), 0));
    except
        result := false;
    end;
    tmpTable.Free();
end;

function iccTabManager.setInfo( _tid : Integer; _title : String; _order : Integer) : Boolean;
begin
    result := true;

    try
        if not db_exec( 'UPDATE ' + c_table_name_Info + ' ' +
                        'SET ' +
                            '`' + c_table_Info_columnTitle_name + '` = "' + str_screening( _title) + '", ' +
                            '`' + c_table_Info_columnOrder_name + '` = '  + IntToStr( _order)      + ' '   +
                        'WHERE rowid = ' + IntToStr( _tid)
                      )
            then raise iccException.Create( 'tab_setInfo() -> failed.');
    except
        result := false;
    end;
end;

function iccTabManager.getData( _tid : Integer; out _data : String) : Boolean; // if true then _data = retrieved blob
var tmpTable : TSQLiteTable;
begin
    result := true;

    tmpTable := nil;
    try
        tmpTable := getTable( String( AnsiString( 'SELECT ' + c_table_Data_columnRaw_name + ' FROM ' + c_table_name_Data + ' WHERE ' + c_table_Data_columnID_name + '=' + IntToStr( _tid))));

        if tmpTable.RowCount = 0
            then raise iccException.Create( 'tab_getData() -> Unexisted _tid was specified.');


        _data := Utf8ToString( RawByteString( tmpTable.FieldAsString( 0)));
    except
        result := false;
    end;
    tmpTable.Free();
end;

function iccTabManager.getData( _tid : Integer; _strs : TStrings) : Boolean;
var tmpTable : TSQLiteTable;
begin
    result := true;

    tmpTable := nil;
    try
        tmpTable := getTable( String( AnsiString( 'SELECT ' + c_table_Data_columnRaw_name + ' FROM ' + c_table_name_Data + ' WHERE ' + c_table_Data_columnID_name + '=' + IntToStr( _tid))));

        if tmpTable.RowCount = 0
            then raise iccException.Create( 'tab_getData() -> Unexisted _tid was specified.');

        _strs.Text := Utf8ToString( RawByteString( tmpTable.FieldAsString( 0)));
    except
        result := false;
    end;
    tmpTable.Free();
end;

function iccTabManager.setData( _tid : Integer;     _data : String) : Boolean;
var ss : TStringStream;
begin
    result := true;

    try
        ss := nil;
        try
            if _data = ''
                then begin // write empty string
                         if not db_exec( 'UPDATE ' + c_table_name_Data + ' SET ' + c_table_Data_columnRaw_name + ' = "" WHERE ' + c_table_Data_columnID_name + '=' + IntToStr( _tid))
                             then raise iccException.Create( 'tab_setData() -> failed.');
                     end
                else begin // write blob
                         ss := TStringStream.Create( _data, TEncoding.UTF8);

                         if not db_exec( 'UPDATE ' + c_table_name_Data + ' SET ' + c_table_Data_columnRaw_name + ' = ? WHERE ' + c_table_Data_columnID_name + '=' + IntToStr( _tid), ss)
                             then raise iccException.Create( 'tab_setData() -> failed.');
                     end;
        finally
            ss.Free();
        end;
    except
        result := false;
    end;
end;

function iccTabManager.getTable( _str : String) : TSQLiteTable;
begin
    result := FDB.GetTable( AnsiString( UTF8Encode( _Str)));
end;


{ iccTabManager.ictSearchItem }

constructor iccTabManager.iccSearchItem.Create(_id: DWORD; _title: String; _deleted: Boolean);
begin
    ID      := _id;
    Title   := _title;
    Deleted := _deleted;
end;

end.
