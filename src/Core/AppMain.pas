unit AppMain;

interface

procedure Initialize;
procedure Run;

implementation

uses
  Horse,
  BitcoinController;

procedure Initialize;

begin
  THorse.Get('/bitcoin', BitcoinController.GetPrice);
end;

procedure Run;

begin
  THorse.Listen(9000,
    procedure
    begin
      Writeln('API Bitcoin iniciada: http://localhost:9000/bitcoin');
      Readln;
    end);
end;

end.
