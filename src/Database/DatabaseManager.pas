unit DatabaseManager;

interface

uses
  System.SysUtils,
  System.Classes,
  System.DateUtils,
  System.IOUtils,
  System.JSON,
  FireDAC.Comp.Client,
  FireDAC.Stan.Def,
  FireDAC.DApt,
  FireDAC.Stan.Async;

type
  TDatabaseManager = class

  private
    class var FConnection: TFDConnection; // Conex�o �nica com o BD (Singleton -> inst�ncia �nica)
    class var FLock: TObject;
    class procedure InitializeDatabase; // Cria tabelas e �ndices se n�o existirem
    class function GetLatestValue(const CurrencyPair: string; out Value: Double): Boolean; // Obt�m o �ltimo valor salvo

  public
    class constructor Create; // Inicializa conex�o e estrutura do BD
    class destructor Destroy; // Libera recursos
    class procedure SaveCurrencyRate(const CurrencyPair: string; Value: Double); // Salva nova cota��o no BD
    class function GetCurrencyHistory(const CurrencyPair: string): TJSONArray; // Recupera hist�rico
  end;

implementation

uses
  FireDAC.Phys.SQLiteDef;

class constructor TDatabaseManager.Create;
begin
  FLock := TObject.Create; // Inicializa objeto de lock p/ thread-safety

  // Configura��o de conex�o com o SQLite
  FConnection := TFDConnection.Create(nil);
  FConnection.Params.DriverID := 'SQLite';
  FConnection.Params.Database := TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\src\Configs\currencies.db'); // Caminho do banco (SQLite -> local)

  // Otimiza��es p/ o SQLite
  FConnection.Params.Add('LockingMode=Normal');
  FConnection.Params.Add('Synchronous=Normal');
  FConnection.Params.Add('JournalMode=WAL');

  FConnection.Connected := True; // Estabelece conex�o
  InitializeDatabase; // Cria estrutura do BD
end;

class destructor TDatabaseManager.Destroy;
begin
  FConnection.Free; // Libera conex�o
  FLock.Free; // Libera objeto de lock
end;

class procedure TDatabaseManager.InitializeDatabase;
begin
  System.TMonitor.Enter(FLock);
  
  try // Cria tabela principal se n�o existir
    FConnection.ExecSQL(
      'CREATE TABLE IF NOT EXISTS currency_rates (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
      'currency_pair TEXT NOT NULL,' +
      'value REAL NOT NULL,' +
      'created_at DATETIME DEFAULT CURRENT_TIMESTAMP)'
    );

    // �ndice p/ otimizar buscas por par de moedas
    FConnection.ExecSQL(
      'CREATE INDEX IF NOT EXISTS idx_currency_pair ON currency_rates (currency_pair)'
    );

  finally
    System.TMonitor.Exit(FLock); // Libera o lock
  end;

end;

class function TDatabaseManager.GetLatestValue(const CurrencyPair: string; out Value: Double): Boolean;
var
  Query: TFDQuery;

begin
  System.TMonitor.Enter(FLock);

  try
    Query := TFDQuery.Create(nil);
    try
      Query.Connection := FConnection;
      Query.SQL.Text :=
        'SELECT value FROM currency_rates ' +
        'WHERE currency_pair = :pair ' +
        'ORDER BY created_at DESC ' + // Ordena pelo mais recente
        'LIMIT 1'; // Pega apenas o �ltimo
      Query.ParamByName('pair').AsString := CurrencyPair;
      Query.Open;

      Result := not Query.Eof; // Verifica se encontrou registro
      if Result then
        Value := Query.FieldByName('value').AsFloat;

    finally
      Query.Free;
    end;

  finally
    System.TMonitor.Exit(FLock);
  end;

end;

class procedure TDatabaseManager.SaveCurrencyRate(const CurrencyPair: string; Value: Double);
var
  Query: TFDQuery;
  LatestValue: Double;
  ShouldSave: Boolean;

begin
  System.TMonitor.Enter(FLock);

  try
    // Verifica se o valor � diferente do �ltimo registrado
    ShouldSave := not GetLatestValue(CurrencyPair, LatestValue) or (LatestValue <> Value);

    if ShouldSave then // Evita duplicatas
    begin
      Query := TFDQuery.Create(nil);
      
      try
        Query.Connection := FConnection;
        
        // Insere novo registro
        Query.SQL.Text := 'INSERT INTO currency_rates (currency_pair, value) VALUES (:pair, :value)';
        Query.ParamByName('pair').AsString := CurrencyPair;
        Query.ParamByName('value').AsFloat := Value;
        Query.ExecSQL;

        // Remove registros antigos (mant�m apenas os �ltimos 10)
        Query.SQL.Text :=
          'DELETE FROM currency_rates WHERE id NOT IN (' +
          '  SELECT id FROM currency_rates ' +
          '  WHERE currency_pair = :pair ' +
          '  ORDER BY created_at DESC ' +
          '  LIMIT 10) ' +
          'AND currency_pair = :pair';
        Query.ParamByName('pair').AsString := CurrencyPair;
        Query.ExecSQL;

      finally
        Query.Free;
      end;

    end;

  finally
    System.TMonitor.Exit(FLock);
  end;

end;

class function TDatabaseManager.GetCurrencyHistory(const CurrencyPair: string): TJSONArray;
var
  Query: TFDQuery;
  HistoryItem: TJSONObject;

begin
  Result := TJSONArray.Create;
  System.TMonitor.Enter(FLock);

  try
    Query := TFDQuery.Create(nil);
    
    try
      Query.Connection := FConnection;
      Query.SQL.Text :=
        'SELECT value, datetime(created_at) as formatted_date ' +
        'FROM currency_rates ' +
        'WHERE currency_pair = :pair ' +
        'ORDER BY created_at DESC ' + // Do mais recente ao mais antigo
        'LIMIT 10'; // Garante apenas os 10 registros mais recentes
      Query.ParamByName('pair').AsString := CurrencyPair;
      Query.Open;

      // Converte cada registro p/ JSON
      while not Query.Eof do
      begin
        HistoryItem := TJSONObject.Create;
        HistoryItem.AddPair('value', TJSONNumber.Create(Query.FieldByName('value').AsFloat));
        HistoryItem.AddPair('date', Query.FieldByName('formatted_date').AsString);
        Result.AddElement(HistoryItem);
        Query.Next;
      end;

    finally
      Query.Free;
    end;

  finally
    System.TMonitor.Exit(FLock);
  end;

end;

end.
