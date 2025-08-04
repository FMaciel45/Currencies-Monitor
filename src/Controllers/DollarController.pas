unit DollarController;

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
  DollarResponse: TJSONObject;

begin
  JsonResponse := TJSONObject.Create; // Objeto principal de resposta
  DollarResponse := nil; // Inicializa como nil para gerenciamento seguro

  try
    try
      // Obtém os dados atuais do Dólar como TJSONObject diretamente
      DollarResponse := TBCBService.GetDollarPrice; // Consulta API do BCB

      // Verifica se a resposta foi bem sucedida
      if DollarResponse.GetValue<Boolean>('success') then
      begin
        CurrentData := DollarResponse.GetValue('data') as TJSONObject;

        // Constrói a resposta completa
        JsonResponse.AddPair('success', TJSONBool.Create(True));
        JsonResponse.AddPair('current', CurrentData.Clone as TJSONObject);
        JsonResponse.AddPair('history', TDatabaseManager.GetCurrencyHistory('USD/BRL'));

        Res.Send(JsonResponse.ToString);
      end

      else

      begin
        // Se houve erro, repassa a mensagem
        JsonResponse.AddPair('success', TJSONBool.Create(False));
        JsonResponse.AddPair('error', DollarResponse.GetValue('error').Clone as TJSONString);
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
    if Assigned(DollarResponse) then DollarResponse.Free; // Libera resposta da API se existir
  end;

end;

end.
