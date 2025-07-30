unit BitcoinController;

interface

uses
  Horse,
  CoinGeckoService;

procedure GetPrice(Req: THorseRequest; Res: THorseResponse; Next: TProc);

implementation

procedure GetPrice(Req: THorseRequest; Res: THorseResponse; Next: TProc);

begin
  Res.Send(TCoinGeckoService.GetBitcoinPrice);
end;

end.
