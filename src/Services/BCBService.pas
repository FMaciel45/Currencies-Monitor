unit BCBService;

interface

uses
  System.Classes;

type
  TBCBService  = class
    class function GetDollarPrice: string;
    class function GetEuroPrice: string;

  private
    class function GetDollarEndpoint: string;
    class function GetEuroEndpoint: string;
    class function GetPriceFromEndpoint(const AEndpoint: string; const ACurrencyPair: string): string;
  end;

implementation

uses
  System.SysUtils,
  System.Net.HttpClient,
  System.JSON,
  System.IOUtils;

class function TBCBService.GetDollarEndpoint: string;
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
      Result := Json.GetValue<string>('bcbDolar');
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
      Result := Json.GetValue<string>('bcbEuro');
    finally
      Json.Free;
    end

    else
      raise Exception.Create('Formato inválido no arquivo de configuração');

  finally
    ConfigFile.Free;
  end;

end;

class function TBCBService.GetPriceFromEndpoint(const AEndpoint: string; const ACurrencyPair: string): string;
var
  HttpClient: THTTPClient;
  Response: IHTTPResponse;
  JsonArray: TJSONArray;
  JsonItem: TJSONObject;
  Price: Double;

begin
  HttpClient := THTTPClient.Create;
  JsonArray := nil;

  try
    try
      Response := HttpClient.Get(AEndpoint);
      JsonArray := TJSONObject.ParseJSONValue(Response.ContentAsString(TEncoding.UTF8)) as TJSONArray;

      if not Assigned(JsonArray) or (JsonArray.Count = 0) then
        Exit('{"erro":"Dados não encontrados"}');

      JsonItem := JsonArray.Items[0] as TJSONObject;
      Price := JsonItem.GetValue<Double>('valor');

      Result := Format('{"moeda":"%s","valor":%.4f}', [ACurrencyPair, Price]);

    except
      on E: Exception do
        Result := Format('{"erro":"%s"}', [E.Message]);
    end;

  finally
    HttpClient.Free;

    if Assigned (JsonArray) then
      JsonArray.Free;
  end;
end;

class function TBCBService.GetDollarPrice: string;
begin
  Result := GetPriceFromEndpoint(GetDollarEndpoint, 'USD/BRL');
end;

class function TBCBService.GetEuroPrice: string;
begin
  Result := GetPriceFromEndpoint(GeteUROEndpoint, 'EUR/BRL');
end;

end.
