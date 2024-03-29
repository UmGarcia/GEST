unit uConfig;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.VCLUI.Wait, Data.DB, FireDAC.Comp.Client, FireDAC.Phys.MySQL,
  FireDAC.Phys.MySQLDef, uGlobal;

type
  TfrmConfig = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    edtHost: TEdit;
    Label2: TLabel;
    edtUsername: TEdit;
    Label3: TLabel;
    edtPassword: TEdit;
    Label4: TLabel;
    edtDB: TEdit;
    btnTest: TButton;
    btnGravar: TButton;
    procedure btnTestClick(Sender: TObject);
    procedure btnGravarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmConfig: TfrmConfig;

implementation

{$R *.dfm}

procedure TfrmConfig.btnGravarClick(Sender: TObject);
begin
  TGlobal.Controller.Hostname := edtHost.Text;
  TGlobal.Controller.Username := edtUsername.Text;
  TGlobal.Controller.Password := edtPassword.Text;
  TGlobal.Controller.Database := edtDB.Text;
  TGlobal.Controller.WriteConfig;

  Self.Close;
end;

procedure TfrmConfig.btnTestClick(Sender: TObject);
var
  Conn    : TFDConnection;
  oParams : TStrings;
begin
  Conn := TFDConnection.Create(Self);
  Conn.DriverName := 'pG';
  Conn.Params.add('Server=' + edtHost.Text);
  Conn.Params.UserName := edtUsername.Text;
  Conn.Params.Password := edtPassword.Text;
  Conn.Params.Database := edtDB.Text;

  try
    Conn.Connected := True;
    ShowMessage('Conex�o estabelecida com sucesso!');
  except
    on e: Exception do
    begin
      raise Exception.Create('Erro:' + e.Message);
    end;
  end;
end;

procedure TfrmConfig.FormCreate(Sender: TObject);
begin
  edtHost.Text       := TGlobal.Controller.Hostname;
  edtUsername.Text   := TGlobal.Controller.Username;
  edtPassword.Text   := TGlobal.Controller.Password;
  edtDB.Text         := TGlobal.Controller.Database;
end;

end.
