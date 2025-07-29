program CurrenciesMonitor;

{$APPTYPE CONSOLE}

uses
  Horse,
  AppMain in 'src\Core\AppMain.pas',
  BitcoinController in 'src\Controllers\BitcoinController.pas',
  CoinGeckoService in 'src\Services\CoinGeckoService.pas';

begin
  AppMain.Initialize;
  AppMain.Run;
end.
