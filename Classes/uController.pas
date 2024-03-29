unit uController;

interface

uses
  FireDAC.Comp.Client, Classes, SysUtils, System.JSON, FireDAC.Phys.PGWrapper;

type
  TController = class
  private
    FConnection : TFDConnection;
    FHostName   : String;
    FUsername   : String;
    FPassword   : String;
    FDatabase   : String;
    procedure ConnError(ASender: TObject; AInitiator: TObject; var AException: Exception);
  published
    property Connection : TFDConnection read FConnection write FConnection;
    property Hostname   : String        read FHostName   write FHostName;
    property Username   : String        read FUsername   write FUsername;
    property Password   : String        read FPassword   write FPassword;
    property Database   : String        read FDatabase   write FDatabase;
  public
    constructor Create(Hostname : String = ''; Username : String = ''; Password : String = ''; Database : String = '');
    destructor Destroy;
    function LoadConnection() : String;
    function ParseConfig(Path: String; DefaultValue : String = ''): String;
    procedure Populate();
    procedure WriteConfig();
  end;

implementation

{ TController }

constructor TController.Create(Hostname : String = ''; Username : String = ''; Password : String = ''; Database : String = '');
begin
  FUsername := Username;
  FPassword := Password;
  FDatabase := Database;

  FConnection := TFDConnection.Create(nil);
  FConnection.OnError := ConnError;
end;

destructor TController.Destroy;
begin
  FreeAndNil(FConnection);
end;

procedure TController.ConnError(ASender: TObject; AInitiator: TObject; var AException: Exception);
var
  oExc: EPgNativeException;
begin
  if AException is EPgNativeException then begin
    oExc := EPgNativeException(AException);
    oExc.Message := 'Por favor no primeiro uso configure a conex�o com o banco de dados!';
  end;
end;

function TController.LoadConnection : String;
begin
  try
    FConnection.DriverName := 'pG';
    FConnection.Params.add('Server=' + Hostname);
    FConnection.Params.UserName := Username;
    FConnection.Params.Password := Password;
    FConnection.Params.Database := Database;
    if (Database <> EmptyStr) and (Username <> EmptyStr) and (Hostname <> EmptyStr) then
      FConnection.Connected := True;
  except
    on e: EPgNativeException do
    begin
      Result := e.Message;
    end;
  end;
end;

procedure TController.WriteConfig();
var
  mainObject : TJSonObject;
  dbObject   : TJSonObject;
  teste  : TJsonPair;

  stream     : TFileStream;
  json       : String;
begin
  mainObject := TJSonObject.Create;
  dbObject   := TJSonObject.Create;
  stream     := TFileStream.Create(GetCurrentDir + '\config.json', fmCreate or fmOpenWrite or fmShareDenyWrite);
  try
    dbObject.AddPair('Host'         , Self.Hostname);
    dbObject.AddPair('UserName'     , Self.UserName);
    dbObject.AddPair('Password'     , Self.Password);
    dbObject.AddPair('DatabaseName' , Self.Database);

    mainObject.AddPair('Database', dbObject);

    json := (mainObject.ToJSON());
    stream.writebuffer(PChar(json)^, Length(json) * 2);
  finally
    FreeAndNil(mainObject);
    FreeAndNil(stream);
  end;
end;

function TController.ParseConfig(Path: String; DefaultValue : String = ''): String;
var
  JSonValue  : TJSonValue;
  JSONString : string;
  Branch     : string;

  stream     : TFileStream;

  Flags : Word;
begin
  try
    try
      Flags := fmOpenRead;

      if not FileExists(GetCurrentDir + '\config.json') then
        Flags := Flags or fmCreate;

      stream := TFileStream.Create(GetCurrentDir + '\config.json', Flags);

      if stream.Size > 0 then
      begin
        SetLength(JSONString, stream.Size div 2);
        stream.Read(Pointer(JSONString)^, stream.Size);
      end;

      JSonValue := TJSonObject.ParseJSONValue(JSONString);
      Result := JSonValue.GetValue<string>(Path, DefaultValue);
    except
      Result := DefaultValue;
    end;
  finally
    FreeAndNil(JSonValue);
    FreeAndNil(stream);
  end;
end;

procedure TController.Populate();
begin
  Self.Hostname := ParseConfig('Database.Host', '127.0.0.1');
  Self.Username := ParseConfig('Database.UserName', 'postgres');
  Self.Password := ParseConfig('Database.Password');
  Self.Database := ParseConfig('Database.DatabaseName');
end;

end.
