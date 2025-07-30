unit EuroController;

interface

uses
  Horse,
  BCBService;

procedure GetPrice(Req: THorseRequest; Res: THorseResponse; Next: TProc);

implementation

procedure GetPrice(Req: THorseRequest; Res: THorseResponse; Next: TProc);

begin
  Res.Send(TBCBService.GetEuroPrice);
end;

end.
