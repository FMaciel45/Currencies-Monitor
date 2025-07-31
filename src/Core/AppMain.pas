unit AppMain;

interface

procedure Initialize;
procedure Run;

implementation

uses
  Horse,
  BitcoinController,
  DollarController,
  EuroController,
  AllCurrenciesController;

procedure Initialize;

begin
  THorse.Get('/bitcoin', BitcoinController.GetPrice);
  THorse.Get('/dol', DollarController.GetPrice);
  THorse.Get('/euro', EuroController.GetPrice);
  THorse.Get('/currencies', AllCurrenciesController.GetAllPrices);
end;

procedure Run;

begin
  THorse.Listen(9000, // Porta

    procedure

    begin
      Writeln('API Bitcoin iniciadaem: http://localhost:9000/bitcoin');
      Writeln('API Dólar iniciada em: http://localhost:9000/dol');
      Writeln('API EURO iniciada em: http://localhost:9000/euro');
      Writeln('API para todas as moedas iniciada em: http://localhost:9000/currencies');
      Readln;
    end);

end;

end.
