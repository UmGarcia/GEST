unit uCadFornecedor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls, System.ImageList, Vcl.ImgList, Vcl.Mask, Vcl.DBCtrls, Data.DB, Datasnap.DBClient, Vcl.ComCtrls, uClient_Fornecedor,
  uGlobal, System.RegularExpressions,
  uModel_Fornecedor;

type
  TfrmCadFornecedor = class(TForm)
    pnlTop: TPanel;
    btnSave: TBitBtn;
    imgBtns: TImageList;
    btnCancel: TBitBtn;
    dsMain: TDataSource;
    cdsMain: TClientDataSet;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    dbeNome: TDBEdit;
    Label1: TLabel;
    dbeNomeFantasia: TDBEdit;
    Label2: TLabel;
    Label3: TLabel;
    dbeCGC: TDBEdit;
    Label4: TLabel;
    cdsMainid: TIntegerField;
    cdsMainatividade_principal: TIntegerField;
    cdsMaindescatividade_principal: TWideStringField;
    cdsMaindata_situacao: TDateField;
    te: TWideStringField;
    cdsMainnome: TWideStringField;
    cdsMainnome_fantasia: TWideStringField;
    cdsMainuf: TWideStringField;
    cdsMainuf_descricao: TWideStringField;
    cdsMainemail: TWideStringField;
    cdsMainsituacao: TWideStringField;
    cdsMainbairro: TWideStringField;
    cdsMainlogradouro: TWideStringField;
    cdsMaincomplemento: TWideStringField;
    cdsMainnumero: TWideStringField;
    cdsMainmunicipio: TWideStringField;
    cdsMainporte: TWideStringField;
    cdsMainabertura: TDateField;
    cdsMainnatureza_juridica: TWideStringField;
    cdsMainente_federativo: TWideStringField;
    cdsMainsituacao_especial: TWideStringField;
    cdsMainmotivo_situacaoesp: TWideStringField;
    cdsMaindata_situacaoesp: TDateField;
    cdsMaincapital_social: TFMTBCDField;
    edtDescCNAE: TEdit;
    Label5: TLabel;
    dbeLogradouro: TDBEdit;
    Label6: TLabel;
    GroupBox3: TGroupBox;
    Label7: TLabel;
    dbeEmail: TDBEdit;
    Label8: TLabel;
    Label9: TLabel;
    dteSituacao: TDateTimePicker;
    DBRadioGroup1: TDBRadioGroup;
    Label10: TLabel;
    dbeBairro: TDBEdit;
    Label11: TLabel;
    dbeNumero: TDBEdit;
    Label12: TLabel;
    dbeMunicipio: TDBEdit;
    Label13: TLabel;
    dbeNatureza: TDBComboBox;
    Label15: TLabel;
    cboUF: TComboBox;
    cboAtividadePrincipal: TComboBox;
    cboTipo: TDBComboBox;
    dbeTelefone: TDBEdit;
    cdsMaintelefone: TStringField;
    Label16: TLabel;
    dbeCEP: TDBEdit;
    Label14: TLabel;
    dbeComplemento: TDBEdit;
    cdsMaincnpj: TStringField;
    cdsMaincep: TStringField;
    btnConsultar: TBitBtn;
    btnCopiar: TBitBtn;
    procedure FormCreate(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure dbeTelefoneEnter(Sender: TObject);
    procedure cdsMainemailValidate(Sender: TField);
    procedure cdsMaintelefoneChange(Sender: TField);
    procedure btnSaveClick(Sender: TObject);
    procedure btnConsultarClick(Sender: TObject);
    procedure btnCopiarClick(Sender: TObject);
  private
    gFornecedor : TClientFornecedor;
    rRotine     : TRotine;
  public
    { Public declarations }
  end;

var
  frmCadFornecedor: TfrmCadFornecedor;

  function Execute(Rotina : TRotine; ID : Integer = 0) : Boolean;
  function Query(out Model : TModelFornecedor) : Boolean;

implementation

uses
  uClient_CNAE,
  uClient_Estado, uConsultarCNPJ;

{$R *.dfm}

function Execute(Rotina : TRotine; ID : Integer = 0) : Boolean;
begin
  frmCadFornecedor             := TfrmCadFornecedor.Create(nil);
  frmCadFornecedor.gFornecedor := TClientFornecedor.Create;
  try
    with frmCadFornecedor do
    begin
      if (Rotina = rtEdit) then
      begin
        rRotine := Rotina;
        gFornecedor.LoadData(['ID'], [IntToStr(ID)]);
        gFornecedor.ToClientDataSet(cdsMain);
        dteSituacao.Date                 := gFornecedor.Model.DATA_SITUACAO;
        cboUF.ItemIndex                  := cboUF.ITEMS.IndexOf(gFornecedor.Model.UF);
        cboAtividadePrincipal.ItemIndex  := cboAtividadePrincipal.ITEMS.IndexOf(IntToStr(gFornecedor.Model.ATIVIDADE_PRINCIPAL));
        cdsMain.Edit;
      end else if (Rotina = rtInsert) then
      begin
        cdsMain.Append;
        dteSituacao.Date := Date();
      end;

      Result := ShowModal = mrOk;
    end;
  finally
    FreeAndNil(frmCadFornecedor);
  end;
end;

function Query(out Model : TModelFornecedor) : Boolean;
begin
  frmCadFornecedor             := TfrmCadFornecedor.Create(nil);
  frmCadFornecedor.gFornecedor := TClientFornecedor.Create;
  try
    with frmCadFornecedor do
    begin
      gFornecedor.Models.Add(Model);
      gFornecedor.Last;
      gFornecedor.ToClientDataSet(cdsMain);

      dteSituacao.Date                 := gFornecedor.Model.DATA_SITUACAO;
      cboUF.ItemIndex                  := cboUF.ITEMS.IndexOf(gFornecedor.Model.UF);
      cboAtividadePrincipal.ItemIndex  := cboAtividadePrincipal.ITEMS.IndexOf(IntToStr(gFornecedor.Model.ATIVIDADE_PRINCIPAL));

      cdsMain.Edit;
      cdsMain.FieldByName('Atividade_Principal').AsInteger := StrToInt(cboAtividadePrincipal.Text);
      cdsMain.FieldByName('NATUREZA_JURIDICA').AsString   := (dbeNatureza.Text);
      cdsMain.FieldByName('UF').AsString                  := (cboUF.Text);
      cdsMain.FieldByName('DATA_SITUACAO').AsDateTime     := dteSituacao.Date;
      cdsMain.Post;

      btnSave.Visible      := False;
      btnConsultar.Visible := False;
      btnCopiar.Visible    := True;

      Result := ShowModal = mrOk;
    end;
  finally
    FreeAndNil(frmCadFornecedor);
  end;
end;

procedure TfrmCadFornecedor.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
  Self.Close;
end;

procedure TfrmCadFornecedor.btnConsultarClick(Sender: TObject);
var
  Model : TModelFornecedor;
begin
  if uConsultarCNPJ.Execute(Model) then
  begin
    gFornecedor.Models.Clear;
    gFornecedor.Models.Add(Model);
    gFornecedor.Last;
    cdsMain.EmptyDataSet;
    gFornecedor.ToClientDataSet(cdsMain);

    cdsMain.Edit;

    dteSituacao.Date                 := gFornecedor.Model.DATA_SITUACAO;
    cboUF.ItemIndex                  := cboUF.ITEMS.IndexOf(gFornecedor.Model.UF);
    cboAtividadePrincipal.ItemIndex  := cboAtividadePrincipal.ITEMS.IndexOf(IntToStr(gFornecedor.Model.ATIVIDADE_PRINCIPAL));
  end;
end;

procedure TfrmCadFornecedor.btnCopiarClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TfrmCadFornecedor.btnSaveClick(Sender: TObject);
begin
  if cdsMain.State in [dsInsert] then
    gFornecedor.Models.Add(TModelFornecedor.Create);

  gFornecedor.Last;

  cdsMain.FieldByName('Atividade_Principal').AsInteger := StrToInt(cboAtividadePrincipal.Text);
  cdsMain.FieldByName('NATUREZA_JURIDICA').AsString   := (dbeNatureza.Text);
  cdsMain.FieldByName('UF').AsString                  := (cboUF.Text);
  cdsMain.FieldByName('DATA_SITUACAO').AsDateTime     := dteSituacao.Date;

  gFornecedor.Model.Nome                := cdsMain.FieldByName('nome').AsString;
  gFornecedor.Model.TIPO                := cdsMain.FieldByName('TIPO').AsString;
  gFornecedor.Model.Nome_Fantasia       := cdsMain.FieldByName('Nome_Fantasia').AsString;
  gFornecedor.Model.CNPJ                := cdsMain.FieldByName('CNPJ').AsString;
  gFornecedor.Model.Atividade_Principal := cdsMain.FieldByName('Atividade_Principal').AsInteger;
  gFornecedor.Model.SITUACAO            := cdsMain.FieldByName('situacao').AsString;
  gFornecedor.Model.DATA_SITUACAO       := cdsMain.FieldByName('DATA_SITUACAO').AsDateTime;
  gFornecedor.Model.NATUREZA_JURIDICA   := cdsMain.FieldByName('NATUREZA_JURIDICA').AsString;
  gFornecedor.Model.LOGRADOURO          := cdsMain.FieldByName('LOGRADOURO').AsString;
  gFornecedor.Model.NUMERO              := cdsMain.FieldByName('NUMERO').AsString;
  gFornecedor.Model.BAIRRO              := cdsMain.FieldByName('BAIRRO').AsString;
  gFornecedor.Model.CEP                 := cdsMain.FieldByName('CEP').AsString;
  gFornecedor.Model.COMPLEMENTO         := cdsMain.FieldByName('COMPLEMENTO').AsString;
  gFornecedor.Model.MUNICIPIO           := cdsMain.FieldByName('MUNICIPIO').AsString;
  gFornecedor.Model.EMAIL               := cdsMain.FieldByName('EMAIL').AsString;
  gFornecedor.Model.TELEFONE            := cdsMain.FieldByName('TELEFONE').AsString;
  gFornecedor.Model.UF            := cdsMain.FieldByName('UF').AsString;

  if rRotine in [rtInsert] then
  begin
    if not gFornecedor.Insert then
    begin
      raise Exception.Create(gFornecedor.Errors[gFornecedor.Errors.Count -1])
    end;
  end
  else if rRotine in [rtEdit] then
  begin
    if not gFornecedor.Update then
      raise Exception.Create(gFornecedor.Errors[gFornecedor.Errors.Count -1]);
  end;

  ModalResult := mrOk;
end;

procedure TfrmCadFornecedor.cdsMainemailValidate(Sender: TField);
var
  rRegex: TRegex;
  bRet  : Boolean;
begin
end;

procedure TfrmCadFornecedor.cdsMaintelefoneChange(Sender: TField);
begin
  if Length(Sender.AsString) = 10 then
    cdsMaintelefone.EditMask := '(99) 9999-9999;0;'
  else
    cdsMaintelefone.EditMask := '(99) #9999-9999;0;'
end;

procedure TfrmCadFornecedor.dbeTelefoneEnter(Sender: TObject);
begin
  cdsMaintelefone.EditMask := '(99) #9999-9999;0;';
end;

procedure TfrmCadFornecedor.FormCreate(Sender: TObject);
var
  CNAE : TClientCNAE;
  UF   : TClientEstado;
begin
  if not(cdsMain.Active) and (cdsMain.Fields.Count > 0) then
    cdsMain.CreateDataSet;

  try
    CNAE := TClientCNAE.Create;
    UF   := TClientEstado.Create;
    CNAE.LoadData([], []);
    UF.LoadData([], []);

    UF.First;
    while not (UF.EoF) do
    begin
      cboUF.Items.Add(UF.Model.ID);
      UF.Next;
    end;

    CNAE.First;
    while not (CNAE.EoF) do
    begin
      cboAtividadePrincipal.Items.Add(IntToStr(CNAE.Model.CODIGO_CNAE));
      CNAE.Next;
    end;

    cboAtividadePrincipal.ItemIndex := 0;
    cboUF.ItemIndex := 0;
  finally
    FreeAndNil(CNAE);
    FreeAndNil(UF);
  end;
end;

end.
