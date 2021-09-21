unit uClient_Estado;

interface

uses
  uAbstract_Client,
  uModel_Estado,
  System.Generics.Collections,
  System.SysUtils;

type
  TClientEstado = class(TClient<TModelEstado>)
  private

  published

  public
    constructor Create(); overload;
  end;

implementation

{ TClientCnae }

constructor TClientEstado.Create;
begin
  inherited Create;
end;

end.
