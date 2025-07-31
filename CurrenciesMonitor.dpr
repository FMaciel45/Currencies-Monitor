program CurrenciesMonitor;

{$APPTYPE CONSOLE}

uses
  Horse,
  AppMain in 'src\Core\AppMain.pas',
  BitcoinController in 'src\Controllers\BitcoinController.pas',
  CoinGeckoService in 'src\Services\CoinGeckoService.pas',
  DollarController in 'src\Controllers\DollarController.pas',
  BCBService in 'src\Services\BCBService.pas',
  CurrencyRate in 'src\Models\CurrencyRate.pas',
  EuroController in 'src\Controllers\EuroController.pas',
  AllCurrenciesController in 'src\Controllers\AllCurrenciesController.pas';

begin
  AppMain.Initialize;
  AppMain.Run;
end.
