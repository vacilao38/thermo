# Thermo · decisão e contrato de dados

Pedido de 27/10/2026: aplicativo Windows sempre disponível que mostre reserva e consumo do Codex, inspirado em neomorfismo e no método da skill mobile-app-studio.

## Escolha

Flutter 3.44.1 / Dart 3.12.1 já integra os projetos Clustter e o protocolo Update. WPF exigiria outro SDK e implementação do protocolo; Electron adicionaria um navegador completo a um painel pequeno. Flutter permite uma interface customizada e um runner Win32 curto para fixar, compactar e recolher à bandeja. Somente Windows x64 nesta versão.

Interface cinza azulada, superfícies elevadas de sombras suaves, contraste de texto preservado, jade para reserva e lilás para histórico. O movimento funcional se limita aos controles nativos e componentes do Flutter; não há animação decorativa contínua. Layout rolável, escala de texto e tema escuro. Ícones têm tooltip/semântica e atalhos de teclado. Não há promessa de auditoria de leitor de tela.

## Fontes decisivas

- [OpenAI App Server](https://learn.chatgpt.com/docs/app-server): handshake initialize/initialized; account/rateLimits/read e account/usage/read. Contrato confirmado com schema gerado pelo Codex instalado 0.164.0-alpha.11.1. Não usa API de inferência nem exige chave API.
- [CodexBar, repositório original](https://github.com/steipete/CodexBar): referência de produto para consulta rápida de reserva e reset. Nenhum código copiado; interface original para Windows.
- [Flutter Windows](https://docs.flutter.dev/platform-integration/windows/building): runner C++ e interoperabilidade Win32. Mantém o título e os controles padrão da janela.
- [Fluent motion](https://fluent2.microsoft.design/motion): parcimônia de movimento, conforme docs/MOTION.md da central.

## Dados

- Limites: preferir rateLimitsByLimitId quando disponível; rateLimits é fallback legado. Mostrar somente janelas retornadas, identificadas pela duração efetiva. Não presumir que primary sempre é cinco horas. Não somar janelas. Termômetro usa o menor percentual restante entre janelas ainda válidas do grupo selecionado.
- Renovação: resetsAt é Unix em segundos. A contagem regressiva usa horário local; ao passar a data, mostrar confirmação pendente, sem inventar 100% disponíveis.
- Tokens da conta: dailyUsageBuckets e lifetimeTokens são atividade, potencialmente atrasada. As datas são as informadas pelo backend; não prometer fuso de fechamento diário. Dia ausente é desconhecido. Sete dias soma somente buckets informados nas sete datas correspondentes.
- Tokens locais: contadores incrementais de eventos event_msg/token_count; não usa conteúdo das mensagens. Baseline herdado por fork não é consumo novo. Snapshot repetido não duplica consumo. Ao detectar redução do contador, retoma pelo last_token_usage. Arquivos que não mudaram não são relidos. Varredura de metadados e bytes acrescentados ocorre em isolate; linhas parciais e UTF-8 são preservados até newline. Atividade local é auxiliar e pode ser incompleta.
- Ritmo: delta observado neste PC, dividido pelo tempo realmente observado, em janela de até 60 segundos. Primeira amostra não cria taxa; mudança de dia zera amostras.
- Tokens restantes da assinatura não são informados pelo contrato. Mostrar explicitamente “Não informado”. Não extrapolar esse número a partir da quota percentual ou do histórico.

## Atualização e privacidade

Conta a cada 60 s, histórico a cada cinco minutos, local a cada cinco segundos. Pausa e refresh manual funcionais; dados antigos identificados. Falhas de histórico não escondem quotas válidas. Preferências de tema/fixação/compacto ficam em preferences.json na pasta de suporte por usuário. Contadores, histórico, e-mails e IDs não são persistidos nem enviados a terceiros. O Codex gerencia seu próprio login. O app não altera a conta, não consome resets ou créditos e não gera respostas. Update usa somente feed público, sem cadastrar o app no catálogo. O histórico local pode conter sessões de diferentes contas que passaram por este PC; não é usado para estimar a franquia da conta atual.

## Aceitação

Executável Windows com reserva real, resets, tokens da conta, taxa local, bandeja, janela compacta/fixada, erros recuperáveis e sem valores simulados no produto. Validação automatizada da contagem e de layout estreito/texto 150%; integração com conta real e Win32, capturas somente locais; compilação e instalador local. Estado dos checks e limitações ficam em VALIDATION.md.
