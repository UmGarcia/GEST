unit uClient_UF;

interface

uses
  uAbstract_Client,
  uModel_UF,
  System.Generics.Collections,
  System.SysUtils;

type
  TClientUF = class(TClient<TModelUF>)
  private

  published

  public
    constructor Create(); overload;
  end;

implementation

{ TClientCnae }

constructor TClienUF.Create;
begin
  inherited Create;
end;

end.
