unit CoinGeckoService;

interface

uses
  System.Classes,
  System.JSON;

type
  TCoinGeckoService = class
    class function GetBitcoinPrice: TJSONObject;

  private
    class function GetEndpointFromConfig: string;
    class function ParseBitcoinResponse(ResponseContent: string): TJSONObject;
  end;

implementation

uses
  System.SysUtils,
  System.Net.HttpClient, // P/ requisi��es HTTP
  System.IOUtils, // Manipula��o de arquivos
  DatabaseManager; // Persist�ncia no banco de dados

class function TCoinGeckoService.GetEndpointFromConfig: string;
var
  ConfigPath: string;
  ConfigFile: TStringStream;
  Json: TJSONObject;

begin
  ConfigPath := TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\src\Configs\endpoints.json'); // Caminho p/ o arquivo de configura��o
  ConfigPath := TPath.GetFullPath(ConfigPath);

  if not FileExists(ConfigPath) then
    raise Exception.Create('Arquivo de configura��o n�o encontrado: ' + ConfigPath);

  ConfigFile := TStringStream.Create('', TEncoding.UTF8);

  try
    // Carrega e parseia o JSON
    ConfigFile.LoadFromFile(ConfigPath);
    Json := TJSONObject.ParseJSONValue(ConfigFile.DataString) as TJSONObject;

    if Assigned(Json) then
    try
      Result := Json.GetValue<string>('coinGecko'); // Obt�m endpoint espec�fico p/ o CoinGecko
    finally
      Json.Free;
    end

    else
      raise Exception.Create('Formato inv�lido no arquivo de configura��o');

  finally
    ConfigFile.Free;
  end;

end;

class function TCoinGeckoService.ParseBitcoinResponse(ResponseContent: string): TJSONObject;
var
  Json, BitcoinData: TJSONObject;
  Price: Double;
  FormattedPrice: string;

begin
  Result := TJSONObject.Create;

  try
    Json := TJSONObject.ParseJSONValue(ResponseContent) as TJSONObject; // Converte string JSON para objeto
    if not Assigned(Json) then
      raise Exception.Create('Resposta inv�lida da API');

    try
      BitcoinData := Json.GetValue('bitcoin') as TJSONObject; // Extrai dados espec�ficos do Bitcoin
      if not Assigned(BitcoinData) then
        raise Exception.Create('Dados do Bitcoin n�o encontrados');

      // Obt�m e formata o valor
      Price := BitcoinData.GetValue<Double>('brl');
      FormattedPrice := FormatFloat('0.0000', Price);

      // Constr�i resposta padronizada
      Result.AddPair('success', TJSONBool.Create(True));
      Result.AddPair('data', TJSONObject.Create
        .AddPair('moeda', 'BTC/BRL')
        .AddPair('valor', TJSONNumber.Create(StrToFloat(FormattedPrice))));

      // Persiste no BD
      TDatabaseManager.SaveCurrencyRate('BTC/BRL', Price);

    finally
      Json.Free;
    end;

  except // Em caso de erro, limpa e recria o objeto de retorno
    on E: Exception do
    begin
      Result.Free;
      Result := TJSONObject.Create;
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('error', E.Message);
    end;

  end;

end;

class function TCoinGeckoService.GetBitcoinPrice: TJSONObject;
var
  HttpClient: THTTPClient;
  Response: IHTTPResponse;
  EndpointUrl: string;

begin
  HttpClient := THTTPClient.Create;
  try
    try
      EndpointUrl := GetEndpointFromConfig; // Obt�m URL configurada
      Response := HttpClient.Get(EndpointUrl); // Faz requisi��o HTTP GET

      // Valida status code
      if Response.StatusCode <> 200 then
        raise Exception.CreateFmt('Erro na API: %d %s',
          [Response.StatusCode, Response.StatusText]);

      // Processa resposta
      Result := ParseBitcoinResponse(Response.ContentAsString(TEncoding.UTF8));

    except // Tratamento de erros
      on E: Exception do
      begin
        Result := TJSONObject.Create;
        Result.AddPair('success', TJSONBool.Create(False));
        Result.AddPair('error', E.Message);
      end;

    end;

  finally
    HttpClient.Free;
  end;

end;

end.
