unit uClient_Fornecedor;

interface

uses
  uAbstract_Client,
  uModel_Fornecedor,
  System.Generics.Collections,
  System.SysUtils,
  System.RegularExpressions,
  uGlobal;

type
  TClientFornecedor = class(TClient<TModelFornecedor>)
  public
    function VerifyBeforeSave(Rotine : TRotine): Boolean; override;
    function ExecuteBeforeSave(): Boolean; override;
  end;

implementation

uses
  uValidate;

{ TClientFornecedor }

function TClientFornecedor.ExecuteBeforeSave: Boolean;
begin
  Self.Model.Nome          := UpperCase(Self.Model.Nome);
  Self.Model.Nome_Fantasia := UpperCase(Self.Model.Nome_Fantasia);
end;

function TClientFornecedor.VerifyBeforeSave(Rotine : TRotine): Boolean;
var
  rRegex            : TRegex;
  bRet              : Boolean;

  vClientFornecedor : TClientFornecedor;
begin
  Result := False;
  if not inherited then
    Exit;

  if Rotine = rtInsert then
  begin
    vClientFornecedor := TClientFornecedor.Create;
    try
      if vClientFornecedor.LoadData(['CNPJ'], [Self.Model.CNPJ]) then
      begin
        Self.Errors.Add('J� existe um fornecedor com o CNPJ informado!');
        Exit;
      end;
    finally
      FreeAndNil(vClientFornecedor);
    end;
  end;

  if not isCNPJ(rRegex.Replace(Self.Model.CNPJ, '\D', '')) then
  begin
    Self.Errors.Add('CNPJ ' + Self.Model.CNPJ + ' inv�lido!');
    Exit;
  end;

  if Self.Model.EMAIL <> '' then
  begin
    bRet := rRegex.IsMatch(Self.Model.EMAIL , '^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]*[a-zA-Z0-9]+$');
    if not bRet then
    begin
     Self.Errors.Add('E-mail inv�lido!');
     Exit;
    end;
  end;

  if Self.Model.TELEFONE <> '' then
  begin
    bRet := rRegex.IsMatch(Self.Model.TELEFONE, '^([0-9]{2})(?:[0-9]{4}|9[0-9]{4})[0-9]{4}$');
    if not bRet then
    begin
     Self.Errors.Add('Telefone inv�lido!');
     Exit;
    end;
  end;

  Result := true;
end;

end.
