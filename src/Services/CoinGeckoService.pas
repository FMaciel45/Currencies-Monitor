unit CoinGeckoService;

interface

uses
  System.Classes;

type
  TCoinGeckoService = class
    class function GetBitcoinPrice: string;
  private
    class function GetEndpointFromConfig: string;
  end;

implementation

uses
  System.SysUtils,
  System.Net.HttpClient,
  System.JSON,
  System.IOUtils;

class function TCoinGeckoService.GetEndpointFromConfig: string;
var
  ConfigPath: string;
  ConfigFile: TStringStream;
  Json: TJSONObject;

begin
  ConfigPath := TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\src\Configs\endpoints.json');
  ConfigPath := TPath.GetFullPath(ConfigPath);

  if not FileExists(ConfigPath) then
    raise Exception.Create('Arquivo de configuração não encontrado: ' + ConfigPath);

  ConfigFile := TStringStream.Create('', TEncoding.UTF8);

  try
    ConfigFile.LoadFromFile(ConfigPath);
    Json := TJSONObject.ParseJSONValue(ConfigFile.DataString) as TJSONObject;

    if Assigned(Json) then
    try
      Result := Json.GetValue<string>('coinGecko');
    finally
      Json.Free;
    end
    else
      raise Exception.Create('Formato inválido no arquivo de configuração');
  finally
    ConfigFile.Free;
  end;

end;

class function TCoinGeckoService.GetBitcoinPrice: string;
var
  HttpClient: THTTPClient;
  Response: IHTTPResponse;
  Json: TJSONObject;
  Price: Double;
  EndpointUrl: string;

begin
  HttpClient := THTTPClient.Create;

  try
    try
      EndpointUrl := GetEndpointFromConfig;

      Response := HttpClient.Get(EndpointUrl);
      Json := TJSONObject.ParseJSONValue(Response.ContentAsString(TEncoding.UTF8)) as TJSONObject;

      if Assigned(Json) then
      try
        Price := Json.GetValue('bitcoin').GetValue<Double>('brl');
        Result := Format('{"moeda":"BTC/BRL","valor":%.2f}', [Price]);
      finally
        Json.Free;
      end
      else
        Result := '{"erro":"Dados inválidos"}';
    except
      on E: Exception do
        Result := Format('{"erro":"%s"}', [E.Message]);
    end;

  finally
    HttpClient.Free;
  end;
end;

end.
