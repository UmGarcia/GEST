unit uAbstract_Client;

interface

uses
  Classes,
  SysUtils,
  uAbstract_Model,
  System.Generics.Collections,
  FireDAC.Comp.Client,
  Datasnap.DBClient,
  System.Rtti,
  Data.DB,
  System.RegularExpressions,
  System.Variants,
  System.DateUtils,
  StrUtils,
  Math,
  uGlobal;

type
  TQueries = class
  private
    FFetch   : String;
    FUpdate  : String;
    FDelete  : String;
    FInsert  : String;
    FJoins   : String;
    FKeyWhere: String;
    FKeys    : TStringList;
  published
    property Fetch    : string read FFetch write FFetch;
    property Update   : string read FUpdate write FUpdate;
    property Delete   : string read FDelete write FDelete;
    property Insert   : string read FInsert write FInsert;
    property Joins    : string read FJoins write FJoins;
    property KeyWhere : string read FKeyWhere write FKeyWhere;
    property Keys     : TStringList read FKeys write FKeys;
  public
    constructor Create();
    procedure Clear;
  end;

type
  TClient<T: TModel, constructor> = class(TObject)
  private
    FModels         : TObjectList<T>;
    FLoadForeign    : Boolean;
    FLoadForeignList: Boolean;
    FMainQuery      : TFDQuery;
    FAuxQuery       : TFDQuery;
    FIndex          : Integer;
    FQueries        : TQueries;
    FErrors         : TStringList;
  private
    procedure LoadFields();
  published
    property Models     : TObjectList<T> read FModels write FModels;
    property Errors     : TStringList read FErrors write FErrors;
  public
    constructor Create(LoadForeign: Boolean = False; LoadForeignList: Boolean = False); virtual;
    destructor Destroy; virtual;
    procedure ToClientDataSet(DataSet: TClientDataSet);
    function LoadData(Fields: Array of String; Values: Array of String; AppendTo: Boolean = False) : Boolean;
    procedure LoadQueries();
    procedure LoadByKeys();
    procedure Next();
    procedure Prior();
    procedure First();
    procedure Last();
    function EoF() : Boolean;
    function Insert(): Boolean;
    function Update(): Boolean;
    function Delete(): Boolean;
    function VerifyBeforeSave(Rotina : TRotine): Boolean; virtual;
    function ExecuteBeforeSave(): Boolean; virtual; abstract;
    function Model() : T;
  end;

implementation

{ TQueries }

procedure TQueries.Clear;
begin
  FFetch    := '';
  FUpdate   := '';
  FDelete   := '';
  FInsert   := '';
  FJoins    := '';
  FKeyWhere := '';
  FKeys.Clear;
end;

constructor TQueries.Create;
begin
  FKeys := TStringList.Create;
end;

{ TClient }

constructor TClient<T>.Create(LoadForeign: Boolean = False;
  LoadForeignList: Boolean = False);
begin
  FModels                 := TObjectList<T>.Create(False);
  FMainQuery              := TFDQuery.Create(nil);
  FMainQuery.Connection   := TGlobal.Controller.Connection;
  FAuxQuery               := TFDQuery.Create(nil);
  FAuxQuery.Connection    := TGlobal.Controller.Connection;
  FLoadForeign            := LoadForeign;
  FLoadForeignList        := LoadForeignList;
  FQueries                := TQueries.Create;
  FErrors                 := TStringList.Create;
  LoadQueries();

  FIndex := -1;
end;

function TClient<T>.Delete: Boolean;
var
  rtContext   : TRttiContext;
  rtType      : TRttiType;
  rtProperty  : TRttiProperty;
  vValue      : TValue;

  sTempString : String;
begin
  Self.Errors.Clear;
  Result := False;
  if not (FModels.Count > 0) then
    Exit;

  rtContext := TRttiContext.Create();
  try
    try
      rtType     := rtContext.GetType(T);
      FMainQuery.SQL.Text := FQueries.Delete + ' ' + FQueries.KeyWhere;
      for sTempString in FQueries.Keys do
      begin
        rtProperty := rtType.GetProperty(sTempString);
        FMainQuery.ParamByName('WH_' + sTempString).AsInteger := rtProperty.GetValue(Pointer(FModels.Items[FIndex])).AsInteger;
      end;

      FMainQuery.ExecSQL;
    finally
      rtContext.Free;
      FMainQuery.Close;
    end;
  except
    on e: exception do
      FErrors.Add(e.Message);
  end;
  Result := True;
end;

destructor TClient<T>.Destroy;
begin
  FreeAndNil(FModels);
  FreeAndNil(FMainQuery);
  FreeAndNil(FAuxQuery);
end;

function TClient<T>.EoF: Boolean;
begin
  Result := FIndex = FModels.Count - 1;
end;

procedure TClient<T>.First;
begin
  FIndex := 0;
end;

function TClient<T>.Insert: Boolean;
var
  rtContext   : TRttiContext;
  rtType      : TRttiType;
  rtProperty  : TRttiProperty;
  vValue      : TValue;

  sTempString : String;
  vFField     : TField;
begin
  Self.Errors.Clear;
  Result := False;
  if not (FModels.Count > 0) then
    Exit;

  if not VerifyBeforeSave(rtInsert) then
    Exit;

  rtContext := TRttiContext.Create();
  try
    try
      rtType     := rtContext.GetType(T);
      FMainQuery.SQL.Text := FQueries.Insert;

      for rtProperty in rtType.GetProperties() do
      begin
        if (dbUpdate in TDBField(rtProperty.GetAttributes[0]).Types)  then
        begin
          vValue  := rtProperty.GetValue(Pointer(FModels.Items[FIndex])).ToString();
          vFField := FAuxQuery.FindField(rtProperty.Name);
          if (vFField is TStringField) or (vFField is TWideStringField) then
            FMainQuery.ParamByName('NEW_' + rtProperty.Name).AsString  := vValue.ToString
          else if vFField is TIntegerField then
            FMainQuery.ParamByName('NEW_' + rtProperty.Name).AsInteger := StrToIntDef(vValue.ToString, 0)
          else if vFField is TFMTBCDField then
            FMainQuery.ParamByName('NEW_' + rtProperty.Name).AsFloat   := StrToFloatDef(vValue.ToString, 0.00)
          else if vFField is TDateField then
            FMainQuery.ParamByName('NEW_' + rtProperty.Name).AsDate    := StrToDate(IfThen(vValue.ToString <> '', vValue.ToString, '30/12/1899'))
        end;
      end;

      FMainQuery.ExecSQL;
    finally
      rtContext.Free;
      FMainQuery.Close;
    end;
  except
    on e: exception do
      FErrors.Add(e.Message);
  end;
  Result := True;
end;

procedure TClient<T>.Last;
begin
  FIndex := FModels.Count - 1;
end;

procedure TClient<T>.LoadByKeys();
var
  sFields     : array of String;
  sValues     : array of String;

  rtContext   : TRttiContext;
  rtType      : TRttiType;
  rtProperty  : TRttiProperty;
  vValue      : TValue;

  sTempString : String;
begin
  if not (FModels.Count > 0) then
    Exit;

  rtContext := TRttiContext.Create();
  try
    rtType     := rtContext.GetType(T);
    for sTempString in FQueries.Keys do
    begin
      SetLength(sFields, Length(sFields) + 1);
      SetLength(sValues, Length(sValues) + 1);
      rtProperty := rtType.GetProperty(sTempString);

      sFields[Length(sFields) - 1] := sTempString;
      sValues[Length(sValues) - 1] := rtProperty.GetValue(Pointer(FModels.Items[FIndex])).ToString;
    end;

    Self.LoadData(sFields, sValues);
  finally
    rtContext.Free;
  end;
end;

function TClient<T>.LoadData(Fields, Values: array of String; AppendTo: Boolean = False): Boolean;
var
  i         : Integer;
  sWhere    : String;
  Model     : T;

  rtContext : TRttiContext;
  rtType    : TRttiType;
  rtProperty: TRttiProperty;
  vValue    : TValue;

  fAux      : Double;
begin
  Self.Errors.Clear;
  Result    := False;

  if Length(Fields) <> Length(Values) then
  begin
    FErrors.Add('Quantidade de campos difere da quantidade de valores!');
  end;
  rtContext := TRttiContext.Create();
  try
    try
      if not AppendTo then
        FModels.Clear;
      FMainQuery.SQL.Text := FQueries.Fetch;
      for i := 0 to (Length(Values) - 1) do
      begin
        if sWhere <> EmptyStr then
          sWhere := sWhere + ' AND ';
        sWhere := sWhere + 'A.' + Fields[i] + ' = ' + QuotedStr(Values[i]);
      end;

      if Length(Values) > 0 then
        FMainQuery.SQL.Text := FMainQuery.SQL.Text + ' WHERE ' + (sWhere);
      FMainQuery.Open();

      if (FMainQuery.IsEmpty) then
        Exit;

      FMainQuery.First;
      rtType := rtContext.GetType(T);
      while not(FMainQuery.Eof) do
      begin
        Model := T.Create;
        for rtProperty in rtType.GetProperties() do
        begin
          if not (rtProperty.IsReadable) or (dbForeignList in TDBField(rtProperty.GetAttributes[0]).Types) then
            Continue;

            case FMainQuery.FieldByName(rtProperty.Name).DataType of
              ftInteger, ftSmallInt:
                rtProperty.SetValue(Pointer(Model), IfThen(FMainQuery.FieldByName(rtProperty.Name).AsInteger <> 0, FMainQuery.FieldByName(rtProperty.Name).AsInteger, 0));
              ftFloat, ftCurrency, ftBCD, ftFMTBcd:
                rtProperty.SetValue(Pointer(Model), IfThen(FMainQuery.FieldByName(rtProperty.Name).AsFloat <> 0, FMainQuery.FieldByName(rtProperty.Name).AsFloat, 0));
              ftDate, ftDateTime :
              begin
                fAux := StrToDate(IfThen(FMainQuery.FieldByName(rtProperty.Name).AsString <> '', FMainQuery.FieldByName(rtProperty.Name).AsString, '30/12/1899')) ;
                if fAux <> 0 then
                  rtProperty.SetValue(Pointer(Model), fAux);
              end
            else
              rtProperty.SetValue(Pointer(Model), FMainQuery.FieldByName(rtProperty.Name).AsString);
          end;
        end;
        FModels.Add(Model);
        FMainQuery.Next;
      end;

      Self.First;
    finally
      FreeAndNil(rtType);
      FreeAndNil(rtProperty);
      rtContext.Free;

      Result := not (FMainQuery.IsEmpty);
      FMainQuery.EmptyDataSet;
      FMainQuery.Close;
    end;
  except
    on e: exception do
      FErrors.Add(e.Message);
  end;
end;

procedure TClient<T>.LoadFields;
begin
  if FQueries.Fetch = EmptyStr then
    Exit;

  if not FAuxQuery.Connection.Connected then
    Exit;

  FAuxQuery.Close;
  FAuxQuery.SQL.Text := FQueries.Fetch + ' LIMIT 0';
  FAuxQuery.Open();
end;

procedure TClient<T>.LoadQueries;
var
  rtContext : TRttiContext;
  rtType    : TRttiType;
  rtProperty: TRttiProperty;
  vValue    : TValue;

  vAttr     : TDBField;

  vForeign  : TDictionary<String, String>;
  vItem     : TPair<string, string>;
  sValues   : String;
begin
  rtContext := TRttiContext.Create();
  vForeign := TDictionary<String, String>.Create;
  try
    FQueries.Clear;

    FMainQuery.SQL.Clear;
    rtType := rtContext.GetType(T);

    for rtProperty in rtType.GetProperties() do
    begin
      if not (rtProperty.IsWritable) then
        Continue;

      if Length(rtProperty.GetAttributes) <> 0 then
      begin
        vAttr := TDBField(rtProperty.GetAttributes[0]);

        if (dbForeignList in vAttr.Types) then
          Continue;

        if FQueries.Fetch <> EmptyStr then
          FQueries.Fetch := FQueries.Fetch + ','#13;

        if (FQueries.Insert <> EmptyStr) and not(dbForeign in vAttr.Types) then
          FQueries.Insert := FQueries.Insert + ', ';

        if (sValues <> EmptyStr) and not(dbForeign in vAttr.Types) then
          sValues := sValues + ', ';

        if (FQueries.Update <> EmptyStr) and (dbUpdate in vAttr.Types) then
          FQueries.Update := FQueries.Update + ', ';

        if (dbKey in vAttr.Types) then
        begin
          if FQueries.KeyWhere <> EmptyStr then
            FQueries.KeyWhere := FQueries.KeyWhere + '    AND ('
          else
            FQueries.KeyWhere := FQueries.KeyWhere + ' WHERE '#13;

          FQueries.KeyWhere := FQueries.KeyWhere + '       (' + rtProperty.Name + ' = :WH_' +
            rtProperty.Name + ')';

          FQueries.Fetch := FQueries.Fetch + '       A.' + rtProperty.Name;
          FQueries.Keys.Add(rtProperty.Name);
        end
        else if (dbForeign in vAttr.Types) and (vAttr.ForeignAlias <> EmptyStr)
        then
        begin
          FQueries.Fetch := FQueries.Fetch + '       ' + vAttr.ForeignAlias +
            '.' + vAttr.ForeignField + ' AS ' + rtProperty.Name;
        end
        else if (dbUpdate in vAttr.Types) then
        begin
          FQueries.Update := FQueries.Update + rtProperty.Name + ' = :NEW_' +
            rtProperty.Name;

            FQueries.Fetch := FQueries.Fetch + '       A.' + rtProperty.Name;
            FQueries.Insert := FQueries.Insert + rtProperty.Name;

            sValues := sValues + ':NEW_' + rtProperty.Name;
        end;

        if dbForeignWhere in vAttr.Types then
        begin
          if vForeign.ContainsKey(vAttr.ForeignTable + ' ' + vAttr.ForeignAlias)
          then
          begin
            vForeign.Items[vAttr.ForeignTable + ' ' + vAttr.ForeignAlias] :=
              vForeign.Items[vAttr.ForeignTable + ' ' + vAttr.ForeignAlias] +
              ' AND A.' + rtProperty.Name + ' = ' + vAttr.ForeignAlias + '.' +
              vAttr.ForeignField;
          end
          else
          begin
            vForeign.Add(vAttr.ForeignTable + ' ' + vAttr.ForeignAlias,
              'A.' + rtProperty.Name + ' = ' + vAttr.ForeignAlias + '.' +
              vAttr.ForeignField);
          end;
        end;
      end;
    end;

    FQueries.Fetch := 'SELECT'#13 + FQueries.Fetch + #13;
    FQueries.Fetch := FQueries.Fetch + '  FROM ' + TTable(rtType.GetAttributes[0]).Name + ' A';

    for vItem in vForeign do
    begin
      FQueries.Fetch := #13 + FQueries.Fetch +
        ('  LEFT JOIN ' + vItem.Key + ' ON (' + vItem.Value + ')');
    end;

    FQueries.Insert := 'INSERT INTO ' + TTable(rtType.GetAttributes[0]).Name + '(' + FQueries.Insert + ') VALUES(' + sValues + ')';
    FQueries.Update := 'UPDATE ' + TTable(rtType.GetAttributes[0]).Name + ' SET ' + FQueries.Update;
    FQueries.Delete := 'DELETE FROM ' + TTable(rtType.GetAttributes[0]).Name + '';
    LoadFields;
  finally
    rtContext.Free;
  end;
end;

function TClient<T>.Model: T;
begin
  if FModels.Count > 0 then
    Result := FModels[FIndex];
end;

procedure TClient<T>.Next;
begin
  if FModels.Count = 0 then
    FIndex := -1
  else if FIndex >= FModels.Count - 1  then
    FIndex := 0
  else
    Inc(FIndex);
end;

procedure TClient<T>.Prior;
begin
  if FModels.Count = 0 then
    FIndex := -1
  else if FIndex = 0 then
    FIndex := FModels.Count - 1
  else
    Dec(FIndex);
end;

procedure TClient<T>.ToClientDataSet(DataSet: TClientDataSet);
var
  rtContext : TRttiContext;
  rtType    : TRttiType;
  rtProperty: TRttiProperty;
  vValue    : TValue;

  Model     : T;
  Field     : TField;
begin
  if (DataSet = nil) then
    Exit;

  if not(DataSet.Active) then
    DataSet.CreateDataSet;

  DataSet.EmptyDataSet;
  rtContext := TRttiContext.Create();
  try
    rtType := rtContext.GetType(T);
    DataSet.DisableControls;
    for Model in FModels do
    begin
      DataSet.Append;
      for rtProperty in rtType.GetProperties() do
      begin
        if not rtProperty.IsReadable then
          Continue;

        Field := DataSet.FindField(rtProperty.Name);

        if Field <> nil then
        begin
          if Field.DisplayLabel <> TDBField(rtProperty.GetAttributes[0]).Description then
            DataSet.FieldByName(rtProperty.Name).DisplayLabel := TDBField(rtProperty.GetAttributes[0]).Description;

          case DataSet.FieldByName(rtProperty.Name).DataType of
            ftInteger, ftSmallInt:
              DataSet.FieldByName(rtProperty.Name).AsInteger := rtProperty.GetValue(Pointer(Model)).AsInteger;
            ftFloat, ftCurrency, ftBCD, ftFMTBcd:
              DataSet.FieldByName(rtProperty.Name).AsFloat   := StrToFloat(rtProperty.GetValue(Pointer(Model)).ToString);
          else
            DataSet.FieldByName(rtProperty.Name).AsString    := rtProperty.GetValue(Pointer(Model)).ToString;
          end;
        end;
      end;
      DataSet.Post;
    end;
  finally
    rtContext.Free;
    DataSet.EnableControls;
  end;
end;

function TClient<T>.Update: Boolean;
var
  rtContext   : TRttiContext;
  rtType      : TRttiType;
  rtProperty  : TRttiProperty;
  vValue      : TValue;
  vFField     : TField;

  sTempString : String;
begin
  Self.Errors.Clear;
  Result := False;
  if not (FModels.Count > 0) then
    Exit;

  if not VerifyBeforeSave(rtEdit) then
    Exit;

  rtContext := TRttiContext.Create();
  try
    try
      rtType     := rtContext.GetType(T);
      FMainQuery.SQL.Text := FQueries.Update + ' ' + FQueries.KeyWhere;
      for sTempString in FQueries.Keys do
      begin
        rtProperty := rtType.GetProperty(sTempString);
        FMainQuery.ParamByName('WH_' + sTempString).AsInteger := StrToiNT(rtProperty.GetValue(Pointer(FModels.Items[FIndex])).ToString);
      end;

      for rtProperty in rtType.GetProperties() do
      begin
        if not (dbUpdate in TDBField(rtProperty.GetAttributes[0]).Types) then
          Continue;

        if (dbUpdate in TDBField(rtProperty.GetAttributes[0]).Types)  then
        begin
          vValue  := rtProperty.GetValue(Pointer(FModels.Items[FIndex])).ToString();
          vFField := FAuxQuery.FindField(rtProperty.Name);
          if (vFField is TStringField) or (vFField is TWideStringField) then
            FMainQuery.ParamByName('NEW_' + rtProperty.Name).AsString  := vValue.ToString
          else if vFField is TIntegerField then
            FMainQuery.ParamByName('NEW_' + rtProperty.Name).AsInteger := StrToIntDef(vValue.ToString, 0)
          else if vFField is TFMTBCDField then
            FMainQuery.ParamByName('NEW_' + rtProperty.Name).AsFloat   := StrToFloatDef(vValue.ToString, 0.00)
          else if vFField is TDateField then
            FMainQuery.ParamByName('NEW_' + rtProperty.Name).AsDate    := StrToDate(IfThen(vValue.ToString <> '', vValue.ToString, '30/12/1899'))
        end;
      end;

      FMainQuery.ExecSQL;
    finally
      rtContext.Free;
      FMainQuery.Close;
    end;
  except
    on e: exception do
      FErrors.Add(e.Message);
  end;
  Result := True;
end;

function TClient<T>.VerifyBeforeSave(Rotina : TRotine): Boolean;
var
  rtContext : TRttiContext;
  rtType    : TRttiType;
  rtProperty: TRttiProperty;
  vValue    : TValue;

  Model     : T;

  vAttr     : TDBField;
begin
  Result := False;
  rtContext := TRttiContext.Create();
  try
    rtType := rtContext.GetType(T);

    for Model in FModels do
    begin
      for rtProperty in rtType.GetProperties() do
      begin
        if TDBField(rtProperty.GetAttributes[0]).CanBeEmpty then
          Continue;

          if (rtProperty.GetValue(Pointer(Model)).ToString = EmptyStr) or (rtProperty.GetValue(Pointer(Model)).ToString = '0') then
          begin
            FErrors.Add('O campo ' + TDBField(rtProperty.GetAttributes[0]).Description + ' n�o pode ser vazio ou nulo!');
            Exit;
          end;
        end;
      end;
  finally
    rtContext.Free;
  end;
  Result := True;
end;

end.
