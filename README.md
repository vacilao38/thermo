# Thermo · Codex Usage Monitor

Aplicativo Windows com um termômetro de reserva do Codex, inspirado em neomorfismo. Projeto independente; não afiliado à OpenAI.

- Saldo real das janelas disponíveis na conta, com previsão de renovação.
- Histórico de tokens da conta hoje e nas últimas sete datas, gráfico diário e detalhes locais de entrada/cache/saída.
- Tokens por minuto observados neste computador, em janela de até 60 segundos.
- Janela compacta, sempre visível, bandeja do Windows, pausa, atualização manual e temas claro/escuro.
- Preferências visuais locais. Não exporta conversas nem salva histórico de consumo.

**Tokens restantes da assinatura:** o contrato do Codex informa percentuais de franquia, sem um orçamento fixo de tokens. O Thermo mostra “Não informado”. Tokens de atividade, contexto e franquia são medidas diferentes. Não é um medidor de faturamento.

## Usar

Execute o instalador local `dist/0.1.0/Thermo-0.1.0-Windows-x64-Setup.exe` e abra Thermo pelo menu Iniciar. Alternativamente, execute `build/windows/x64/runner/Release/codex_thermometer.exe` mantendo todas as DLLs e a pasta data ao lado.

Requer Windows 10/11 x64 e o Codex para Windows instalado, com login ChatGPT válido. O app encontra o executável desktop em LOCALAPPDATA/OpenAI/Codex/bin ou codex.exe no PATH. Respeita CODEX_HOME quando configurado. A autenticação é gerenciada pelo Codex; não forneça uma chave API ao Thermo.

F5 atualiza; Ctrl+M alterna compacto; Ctrl+P fixa a janela. A seta para baixo recolhe à bandeja. Clique no ícone para voltar ou use o menu de contexto para sair. Fechar a janela encerra o monitor. Não inicia automaticamente com o Windows.

## O que os dados representam

Conta: consulta a cada 60 s. Histórico: a cada 5 min, com datas e atraso definidos pelo servidor. Atividade local: a cada 5 s, a partir dos eventos token_count dos logs de sessões. Logs podem estar incompletos ou conter sessões de contas anteriores; os dados locais não são usados para estimar a franquia da conta atual. Cache já faz parte da entrada e não deve ser somado a ela. Um dia ausente não vira zero. Sem rede, a última leitura fica identificada; não há saldo inventado após o horário de renovação.

## Desenvolver

Flutter 3.44.1 / Dart 3.12.1, Visual Studio C++ Desktop e Windows SDK. Dependências fixadas em pubspec.lock; componente Update fixado por commit.

```powershell
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub
flutter test integration_test/windows_test.dart -d windows --no-pub
flutter build windows --release --no-pub
```

Execute integração e build sequencialmente: ambos usam a instalação CMake do mesmo projeto. A integração depende do Codex e da conta real desta máquina; as contagens e capturas permanecem ignoradas em outputs/. Para compilar um instalador local, use o empacotador compartilhado descrito na central, informando o runtime CRT do Visual Studio quando necessário.

Código público em https://github.com/vacilao38/thermo. Instaladores e inclusão no catálogo dependem de publicação explicitamente autorizada; este repositório não publica builds por conta própria. Update consulta o feed Clustter e só anuncia versões existentes, sem instalação automática.

Contrato, fontes e escolhas em docs/DESIGN.md; evidências e limites em docs/VALIDATION.md. Arquivos de texto UTF-8. Licença MIT.
