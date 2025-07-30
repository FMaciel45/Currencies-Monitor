unit CurrencyRate; // Tipagem forte

interface

type
  TCurrencyRate = record
    CurrencyCode: string;
    Rate: Double;
    LastUpdated: TDateTime;
  end;

implementation

end.
