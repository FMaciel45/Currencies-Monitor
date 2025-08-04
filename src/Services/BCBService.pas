unit BCBService;

interface

uses
  System.Classes,
  System.JSON;

type
  TBCBService = class
    class function GetDollarPrice: TJSONObject;
    class function GetEuroPrice: TJSONObject;

  private
    class function GetDollarEndpoint: string;
    class function GetEuroEndpoint: string;
    class function GetPriceFromEndpoint(const AEndpoint: string; const ACurrencyPair: string): TJSONObject;
  end;

implementation

uses
  System.SysUtils,
  System.Net.HttpClient,
  System.IOUtils, // P/ manipulação de arquivos
  DatabaseManager; // P/ persistência dos dados

class function TBCBService.GetDollarEndpoint: string;
var
  ConfigPath: string;
  ConfigFile: TStringStream;
  Json: TJSONObject;

begin
  ConfigPath := TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\src\Configs\endpoints.json'); // caminho p/ o arquivo de configuração
  ConfigPath := TPath.GetFullPath(ConfigPath);

  if not FileExists(ConfigPath) then  // Verifica existência do arquivo
    raise Exception.Create('Arquivo de configuração não encontrado: ' + ConfigPath);

  ConfigFile := TStringStream.Create('', TEncoding.UTF8);

  try // Carrega e parseia JSON
    ConfigFile.LoadFromFile(ConfigPath);
    Json := TJSONObject.ParseJSONValue(ConfigFile.DataString) as TJSONObject;

    if Assigned(Json) then
    try
      Result := Json.GetValue<string>('bcbDolar'); // Extrai endpoint específico
    finally
      Json.Free;
    end

    else
      raise Exception.Create('Formato inválido no arquivo de configuração');

  finally
    ConfigFile.Free;
  end;

end;

class function TBCBService.GetEuroEndpoint: string;
var
  ConfigPath: string;
  ConfigFile: TStringStream;
  Json: TJSONObject;

begin
  ConfigPath := TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\src\Configs\endpoints.json'); // caminho p/ o arquivo de configuração
  ConfigPath := TPath.GetFullPath(ConfigPath);

  if not FileExists(ConfigPath) then // Verifica existência do arquivo
    raise Exception.Create('Arquivo de configuração não encontrado: ' + ConfigPath);

  ConfigFile := TStringStream.Create('', TEncoding.UTF8);

  try // Carrega e parseia JSON
    ConfigFile.LoadFromFile(ConfigPath);
    Json := TJSONObject.ParseJSONValue(ConfigFile.DataString) as TJSONObject;

    if Assigned(Json) then
    try
      Result := Json.GetValue<string>('bcbEuro'); // Extrai endpoint específico
    finally
      Json.Free;
    end

    else
      raise Exception.Create('Formato inválido no arquivo de configuração');

  finally
    ConfigFile.Free;
  end;

end;

// Método p/ consulta à API
class function TBCBService.GetPriceFromEndpoint(const AEndpoint: string; const ACurrencyPair: string): TJSONObject;
var
  HttpClient: THTTPClient;
  Response: IHTTPResponse;
  JsonArray: TJSONArray;
  JsonItem: TJSONObject;
  Price: Double;
  FormattedPrice: string;

begin
  Result := TJSONObject.Create;
  HttpClient := THTTPClient.Create;
  JsonArray := nil;

  try
    try
      Response := HttpClient.Get(AEndpoint); // Faz a requisição HTTP

      if Response.StatusCode <> 200 then // Verifica status
        raise Exception.CreateFmt('Erro na API: %d %s', [Response.StatusCode, Response.StatusText]);

      JsonArray := TJSONObject.ParseJSONValue(Response.ContentAsString(TEncoding.UTF8)) as TJSONArray; // Parse da resposta

      if not Assigned(JsonArray) or (JsonArray.Count = 0) then
        raise Exception.Create('Dados não encontrados na resposta da API');

      // Extrai o valor
      JsonItem := JsonArray.Items[0] as TJSONObject;
      Price := JsonItem.GetValue<Double>('valor');

      FormattedPrice := FormatFloat('0.0000', Price); // Formatação

      // Persiste no BD
      TDatabaseManager.SaveCurrencyRate(ACurrencyPair, Price);

      // Constrói o objeto de resposta
      Result.AddPair('success', TJSONBool.Create(True));
      Result.AddPair('data', TJSONObject.Create
        .AddPair('moeda', ACurrencyPair)
        .AddPair('valor', TJSONNumber.Create(StrToFloat(FormattedPrice))));

    except // Tratamento de erros
      on E: Exception do
      begin
        Result.AddPair('success', TJSONBool.Create(False));
        Result.AddPair('error', E.Message);
      end;

    end;

  finally // Limpeza
    HttpClient.Free;
    if Assigned(JsonArray) then
      JsonArray.Free;

  end;

end;

// Facade p/ cotação do Dólar (fornece uma interface simplificada)
class function TBCBService.GetDollarPrice: TJSONObject;
begin
  Result := GetPriceFromEndpoint(GetDollarEndpoint, 'USD/BRL');
end;

// Facade p/ cotação do Euro (fornece uma interface simplificada)
class function TBCBService.GetEuroPrice: TJSONObject;
begin
  Result := GetPriceFromEndpoint(GetEuroEndpoint, 'EUR/BRL');
end;

end.
