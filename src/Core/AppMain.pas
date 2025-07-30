unit AppMain;

interface

procedure Initialize;
procedure Run;

implementation

uses
  Horse,
  BitcoinController,
  DollarController,
  EuroController;

procedure Initialize;

begin
  THorse.Get('/bitcoin', BitcoinController.GetPrice);
  THorse.Get('/dol', DollarController.GetPrice);
  THorse.Get('/euro', EuroController.GetPrice);
end;

procedure Run;

begin
  THorse.Listen(9000,

    procedure

    begin
      Writeln('API Bitcoin iniciadaem: http://localhost:9000/bitcoin');
      Writeln('API Dólar iniciada em: http://localhost:9000/dol');
      Writeln('API eURO iniciada em: http://localhost:9000/euro');
      Readln;
    end);
end;

end.
