unit EuroController;

interface

uses
  Horse,
  BCBService,
  DatabaseManager,
  System.JSON,
  System.SysUtils;

procedure GetPrice(Req: THorseRequest; Res: THorseResponse; Next: TProc);

implementation

uses
  System.Net.HTTPClient; // P/ códigos de status HTTP

procedure GetPrice(Req: THorseRequest; Res: THorseResponse; Next: TProc);

var
  JsonResponse, CurrentData: TJSONObject;
  EuroResponse: TJSONObject;

begin
  JsonResponse := TJSONObject.Create; // Objeto principal de resposta
  EuroResponse := nil; // Inicializa como nil para gerenciamento seguro

  try
    try
      // Obtém os dados atuais do Euro como TJSONObject diretamente
      EuroResponse := TBCBService.GetEuroPrice; // Consulta API do BCB

      // Verifica se a resposta foi bem sucedida
      if EuroResponse.GetValue<Boolean>('success') then
      begin
        CurrentData := EuroResponse.GetValue('data') as TJSONObject;

        JsonResponse.AddPair('success', TJSONBool.Create(True));
        JsonResponse.AddPair('current', CurrentData.Clone as TJSONObject);
        JsonResponse.AddPair('history', TDatabaseManager.GetCurrencyHistory('EUR/BRL'));

        Res.Send(JsonResponse.ToString);
      end

      else

      begin
        // Se houve erro, repassa a mensagem
        JsonResponse.AddPair('success', TJSONBool.Create(False));
        JsonResponse.AddPair('error', EuroResponse.GetValue('error').Clone as TJSONString);
        Res.Send(JsonResponse).Status(THTTPStatus.InternalServerError);
      end;

    except // Trata erros inesperados
      on E: Exception do
      begin
        JsonResponse.AddPair('success', TJSONBool.Create(False));
        JsonResponse.AddPair('error', E.Message);
        Res.Send(JsonResponse).Status(THTTPStatus.InternalServerError);
      end;

    end;

  finally
    JsonResponse.Free; // Libera objeto principal
    if Assigned(EuroResponse) then EuroResponse.Free; // Libera resposta da API se existir
  end;

end;

end.
