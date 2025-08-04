unit BitcoinController;

interface

uses
  Horse,
  System.JSON,
  CoinGeckoService,
  DatabaseManager;

procedure GetPrice(Req: THorseRequest; Res: THorseResponse; Next: TProc);

implementation

uses
  System.SysUtils,
  System.Net.HTTPClient; // P/ códigos de status HTTP

procedure GetPrice(Req: THorseRequest; Res: THorseResponse; Next: TProc);

var
  ResponseObj, FinalResponse: TJSONObject;

begin
  FinalResponse := TJSONObject.Create; // Objeto principal de resposta

  try
    ResponseObj := TCoinGeckoService.GetBitcoinPrice; // Consulta API externa

    try
      // Copia todos os pares do ResponseObj para o FinalResponse
      FinalResponse.AddPair('success', ResponseObj.GetValue('success').Clone as TJSONBool);

      if ResponseObj.GetValue<Boolean>('success') then
      begin // Adiciona cotação atual e histórico
        FinalResponse.AddPair('current', ResponseObj.GetValue('data').Clone as TJSONObject);
        FinalResponse.AddPair('history', TDatabaseManager.GetCurrencyHistory('BTC/BRL'));
      end

      else
      begin
        FinalResponse.AddPair('error', ResponseObj.GetValue('error').Clone as TJSONString);
        Res.Send(FinalResponse).Status(THTTPStatus.InternalServerError);
        Exit; // Interrompe o fluxo em caso de erro na API
      end;

      Res.Send(FinalResponse.ToString);

    finally
      ResponseObj.Free; // Libera memória da resposta da API

    end;

  except // Tratamento de erros inesperados
    on E: Exception do
    begin
      FinalResponse.AddPair('success', TJSONBool.Create(False));
      FinalResponse.AddPair('error', E.Message);
      Res.Send(FinalResponse).Status(THTTPStatus.InternalServerError);
    end;

  end;

end;

end.
