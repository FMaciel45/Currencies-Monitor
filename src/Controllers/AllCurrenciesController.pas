unit AllCurrenciesController;

interface

uses
  Horse,
  CoinGeckoService,
  BCBService,
  System.JSON,
  System.SysUtils;

procedure GetAllPrices(Req: THorseRequest; Res: THorseResponse; Next: TProc);

implementation

procedure GetAllPrices(Req: THorseRequest; Res: THorseResponse; Next: TProc);

var
  JsonResponse: TJSONObject;
  BitcoinStr, DollarStr, EuroStr: string;
  ErrorMessage: string;
  
begin
  JsonResponse := TJSONObject.Create;
  
  try
    try
      BitcoinStr := TCoinGeckoService.GetBitcoinPrice;

      DollarStr := TBCBService.GetDollarPrice;

      EuroStr := TBCBService.GetEuroPrice;

      JsonResponse.AddPair('all', TJSONObject.Create
        .AddPair('bitcoin', BitcoinStr)
        .AddPair('dollar', DollarStr)
        .AddPair('euro', EuroStr));

      Res.Send(JsonResponse.ToString);

    except
      on E: Exception do
      
      begin
        JsonResponse.Free;

        ErrorMessage := 'Erro ao processar dados: ' + E.Message;
        JsonResponse := TJSONObject.Create;
        JsonResponse.AddPair('error', ErrorMessage);
        
        Res.Send(JsonResponse).Status(THTTPStatus.InternalServerError);
      end;
      
    end;
    
  finally
    JsonResponse.Free;
    
  end;      
  
end;

end.
