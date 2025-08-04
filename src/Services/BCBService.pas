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
  System.IOUtils, // P/ manipula��o de arquivos
  DatabaseManager; // P/ persist�ncia dos dados

class function TBCBService.GetDollarEndpoint: string;
var
  ConfigPath: string;
  ConfigFile: TStringStream;
  Json: TJSONObject;

begin
  ConfigPath := TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\src\Configs\endpoints.json'); // caminho p/ o arquivo de configura��o
  ConfigPath := TPath.GetFullPath(ConfigPath);

  if not FileExists(ConfigPath) then  // Verifica exist�ncia do arquivo
    raise Exception.Create('Arquivo de configura��o n�o encontrado: ' + ConfigPath);

  ConfigFile := TStringStream.Create('', TEncoding.UTF8);

  try // Carrega e parseia JSON
    ConfigFile.LoadFromFile(ConfigPath);
    Json := TJSONObject.ParseJSONValue(ConfigFile.DataString) as TJSONObject;

    if Assigned(Json) then
    try
      Result := Json.GetValue<string>('bcbDolar'); // Extrai endpoint espec�fico
    finally
      Json.Free;
    end

    else
      raise Exception.Create('Formato inv�lido no arquivo de configura��o');

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
  ConfigPath := TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\src\Configs\endpoints.json'); // caminho p/ o arquivo de configura��o
  ConfigPath := TPath.GetFullPath(ConfigPath);

  if not FileExists(ConfigPath) then // Verifica exist�ncia do arquivo
    raise Exception.Create('Arquivo de configura��o n�o encontrado: ' + ConfigPath);

  ConfigFile := TStringStream.Create('', TEncoding.UTF8);

  try // Carrega e parseia JSON
    ConfigFile.LoadFromFile(ConfigPath);
    Json := TJSONObject.ParseJSONValue(ConfigFile.DataString) as TJSONObject;

    if Assigned(Json) then
    try
      Result := Json.GetValue<string>('bcbEuro'); // Extrai endpoint espec�fico
    finally
      Json.Free;
    end

    else
      raise Exception.Create('Formato inv�lido no arquivo de configura��o');

  finally
    ConfigFile.Free;
  end;

end;

// M�todo p/ consulta � API
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
      Response := HttpClient.Get(AEndpoint); // Faz a requisi��o HTTP

      if Response.StatusCode <> 200 then // Verifica status
        raise Exception.CreateFmt('Erro na API: %d %s', [Response.StatusCode, Response.StatusText]);

      JsonArray := TJSONObject.ParseJSONValue(Response.ContentAsString(TEncoding.UTF8)) as TJSONArray; // Parse da resposta

      if not Assigned(JsonArray) or (JsonArray.Count = 0) then
        raise Exception.Create('Dados n�o encontrados na resposta da API');

      // Extrai o valor
      JsonItem := JsonArray.Items[0] as TJSONObject;
      Price := JsonItem.GetValue<Double>('valor');

      FormattedPrice := FormatFloat('0.0000', Price); // Formata��o

      // Persiste no BD
      TDatabaseManager.SaveCurrencyRate(ACurrencyPair, Price);

      // Constr�i o objeto de resposta
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

// Facade p/ cota��o do D�lar (fornece uma interface simplificada)
class function TBCBService.GetDollarPrice: TJSONObject;
begin
  Result := GetPriceFromEndpoint(GetDollarEndpoint, 'USD/BRL');
end;

// Facade p/ cota��o do Euro (fornece uma interface simplificada)
class function TBCBService.GetEuroPrice: TJSONObject;
begin
  Result := GetPriceFromEndpoint(GetEuroEndpoint, 'EUR/BRL');
end;

end.
