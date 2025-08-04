# Currencies Monitor

Este repositório contém o projeto **Currencies Monitor**, um Console App que possui o objetivo de documentar o meu estudo sobre Delphi e o Framework Web Horse. 
O projeto utiliza as tecnologias mencionadas para a criação de APIs RESTful e se integra com diferentes fontes de dados para obter as informações das moedas.

## Tecnologias Utilizadas

*   `Delphi`: Linguagem de programação e ambiente de desenvolvimento.
*   `Horse Framework`: Framework para desenvolvimento de APIs RESTful em Delphi.
*   `FireDAC`: Biblioteca de acesso a dados para conexão com bancos de dados (utilizado com SQLite).
*   `SQLite`: Banco de dados leve e embarcado para armazenamento local.
*   `CoinGecko API`: API externa para obtenção de cotações de criptomoedas (ex.: Bitcoin).
*   `Banco Central do Brasil (BCB) API`: API para obtenção de cotações de moedas fiduciárias (ex.: Dólar e Euro).

## Estrutura do Projeto

O projeto segue uma estrutura modular, organizada nas seguintes pastas principais dentro de `src`:

*   `Configs`: Contém arquivos de configuração, como `endpoints.json` (para URLs de APIs externas) e `currencies.db` (banco de dados SQLite).
*   `Controllers`: Define os controladores da API, responsáveis por lidar com as requisições HTTP e orquestrar as operações. Exemplos incluem `BitcoinController.pas`, `DollarController.pas`, `EuroController.pas` e `AllCurrenciesController.pas`.
*   `Core`: Contém arquivos centrais do aplicativo, como `AppMain.pas` (ponto de entrada da aplicação) e `Globals.pas` (variáveis e funções globais).
*   `Database`: Gerencia a conexão e operações com o banco de dados, com o arquivo `DatabaseManager.pas`.
*   `Models`: Define os modelos de dados, como `CurrencyRate.pas`, que representa a estrutura das informações de cotação das moedas.
*   `Services`: Contém os serviços que interagem com APIs externas para obter os dados das moedas, como `BCBService.pas` (para dados do Banco Central) e `CoinGeckoService.pas` (para dados do CoinGecko).

## Funcionalidades

O `Currencies Monitor` oferece as seguintes funcionalidades:

*   **Monitoramento da cotação do Bitcoin**: Obtém a cotação do Bitcoin através da API CoinGecko.
*   **Monitoramento da cotação do Dólar e do Euro**: Obtém as cotações do Dólar e Euro através da API do Banco Central do Brasil.
*   **API RESTful**: Expõe endpoints para consulta das cotações das moedas.
*   **Persistência de Dados**: Armazena dados em um banco de dados SQLite local.

## Como Executar o Projeto

1.  **Pré-requisitos**: Certifique-se de ter o Delphi instalado com suporte ao FireDAC.
2.  **Clonar o Repositório**: `git clone https://github.com/FMaciel45/Currencies-Monitor.git`
3.  **Abrir no Delphi**: Abra o arquivo `CurrenciesMonitor.dpr` no Delphi.
4.  **Configuração**: Verifique os endpoints no arquivo `src/Configs/endpoints.json` e ajuste se necessário.
5.  **Compilar e Executar**: Compile e execute o projeto diretamente do Delphi.

## Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou pull requests para melhorias, correção de bugs ou novas funcionalidades.
