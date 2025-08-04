unit AllCurrenciesController;

interface

uses
  Horse,
  CoinGeckoService,
  BCBService,
  System.JSON,
  System.SysUtils;

procedure GetAllPrices(Req: THorseRequest; Res: THorseResponse; Next: TProc); // Retorna todas as cotações em um único JSON

implementation

procedure GetAllPrices(Req: THorseRequest; Res: THorseResponse; Next: TProc);

var
  JsonResponse, AllData: TJSONObject;
  BitcoinObj, DollarObj, EuroObj: TJSONObject;

begin
  JsonResponse := TJSONObject.Create;
  AllData := TJSONObject.Create;
  BitcoinObj := nil;
  DollarObj := nil;
  EuroObj := nil;

  try
    try
      // Obtém as cotações como TJSONObject
      BitcoinObj := TCoinGeckoService.GetBitcoinPrice;
      DollarObj := TBCBService.GetDollarPrice;
      EuroObj := TBCBService.GetEuroPrice;

      // Verifica se todos os objetos foram criados com sucesso
      if Assigned(BitcoinObj) and BitcoinObj.GetValue<Boolean>('success') and
         Assigned(DollarObj) and DollarObj.GetValue<Boolean>('success') and
         Assigned(EuroObj) and EuroObj.GetValue<Boolean>('success') then

      begin
        JsonResponse.AddPair('success', TJSONBool.Create(True));

        // Adiciona apenas os dados mais atuais
        AllData.AddPair('bitcoin', BitcoinObj.GetValue('data').Clone as TJSONObject);
        AllData.AddPair('dollar', DollarObj.GetValue('data').Clone as TJSONObject);
        AllData.AddPair('euro', EuroObj.GetValue('data').Clone as TJSONObject);

        JsonResponse.AddPair('data', AllData);
        Res.Send(JsonResponse.ToString);
      end

      else

      begin
        // Verifica qual moeda falhou
        if not Assigned(BitcoinObj) or not BitcoinObj.GetValue<Boolean>('success') then
          JsonResponse.AddPair('bitcoin_error', 'Failed to get Bitcoin data');

        if not Assigned(DollarObj) or not DollarObj.GetValue<Boolean>('success') then
          JsonResponse.AddPair('dollar_error', 'Failed to get Dollar data');

        if not Assigned(EuroObj) or not EuroObj.GetValue<Boolean>('success') then
          JsonResponse.AddPair('euro_error', 'Failed to get Euro data');

        JsonResponse.AddPair('success', TJSONBool.Create(False));

        Res.Send(JsonResponse).Status(THTTPStatus.InternalServerError);
      end;

    except // Tratamento de erros globais
      on E: Exception do
      begin
        JsonResponse.AddPair('success', TJSONBool.Create(False));
        JsonResponse.AddPair('error', E.Message);
        Res.Send(JsonResponse).Status(THTTPStatus.InternalServerError); // Cód. HTTP 500
      end;

    end;

  finally
    if Assigned(BitcoinObj) then BitcoinObj.Free;
    if Assigned(DollarObj) then DollarObj.Free;
    if Assigned(EuroObj) then EuroObj.Free;

    JsonResponse.Free; // Libera a resposta principal
  end;

end;

end.
