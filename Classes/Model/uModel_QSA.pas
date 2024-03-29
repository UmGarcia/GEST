unit uModel_QSA;

interface

uses uAbstract_Model;

type
  [TTable('QSA')]
  TModelQSA = class(TModel)
  private
    FID: Integer;
    FNOME: String;
    FCODIGO: Integer;
  published
    [TDBField('IDentificador', [dbKey])]
    property ID: Integer read FID write FID;
    [TDBField('Nome', [dbUpdate])]
    property NOME: String read FNOME write FNOME;
    [TDBField('C�digo', [dbUpdate])]
    property CODIGO: Integer read FCODIGO write FCODIGO;
  end;

implementation

end.
