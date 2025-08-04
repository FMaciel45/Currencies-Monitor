program CurrenciesMonitor; // Ponto de entrada do app

{$APPTYPE CONSOLE}
{$IFDEF DEBUG}
{$ENDIF}

uses
  Horse,
  FireDAC.DApt, // FireDAC -> acesso ao BD
  FireDAC.Phys.SQLite, // Driver SQLite p/ o FireDAC
  FireDAC.STAN.Def, // Definições padrão do FireDAC
  FireDAC.Stan.Async, // p/operações assíncronas
  FireDAC.Comp.Client, // Componentes de conexão DB
  AppMain in 'src\Core\AppMain.pas',
  BitcoinController in 'src\Controllers\BitcoinController.pas',
  CoinGeckoService in 'src\Services\CoinGeckoService.pas',
  DollarController in 'src\Controllers\DollarController.pas',
  BCBService in 'src\Services\BCBService.pas',
  CurrencyRate in 'src\Models\CurrencyRate.pas',
  EuroController in 'src\Controllers\EuroController.pas',
  AllCurrenciesController in 'src\Controllers\AllCurrenciesController.pas',
  DatabaseManager in 'src\Database\DatabaseManager.pas';

begin
  System.ReportMemoryLeaksOnShutdown := True; // Relata vazamentos de memória

  FDManager.Active := True; // Ativa o gerenciador de conexões FireDAC
  FDManager.Open;

  AppMain.Initialize;
  AppMain.Run;
end.
