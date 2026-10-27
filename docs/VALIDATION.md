# Validação · 27/10/2026

## Executado e aprovado

- `flutter analyze --no-pub`: nenhum problema.
- `flutter test --no-pub`: 13 testes. Cobrem ausência de dados, janelas semanais sem janela curta, preferir múltiplos buckets ao legado, clamping, reset vencido, soma de sete datas, baseline herdado, snapshots repetidos, replay de fork, JSON parcial e UTF-8, recuperação de falha e layout de 360/790/1120 px com texto 150%.
- `flutter test integration_test/windows_test.dart -d windows --no-pub`: integração real aprovada. Consulta limites/histórico da conta pelo Codex instalado; lê eventos locais reais; obtém taxa de tokens/min após duas leituras; confere Win32 topmost, compacto, recolher/mostrar e capturas renderizadas nos temas claro/escuro e nas áreas superior/inferior. Dados e capturas ficam em outputs/ ignorado.
- `flutter build windows --release --no-pub`: executável x64 `0.1.0+1` compilado.
- Instalador NSIS por usuário gerado pelo empacotador compartilhado. Runtime VC145 incluído. Setup normal: 10.071.674 bytes; SHA-256 `f5299fb8e87ec793794cb6acf8281c3a07934f922a790a9042dde87bca89609b`.
- Pacote de teste isolado instalado/desinstalado com `tool/check_installer.py`. Confirmados registro separado, binários e CRT presentes, remoção do executável/registro e preservação de arquivo adicional do usuário. O alvo foi outputs/installer-test, sem atalhos nem registro da instalação normal.
- Segunda passagem crítica feita pelo próprio agente: corrigidos overflow no cabeçalho em tela estreita, contagem de replay entre forks e contraste de cores de texto no tema escuro. Nenhuma revisão independente por outro agente foi alegada.

## Ocorrências resolvidas

- Primeira compilação Release coincidiu com integração Debug no mesmo diretório CMake e falhou na etapa INSTALL. Execuções seguintes ocorreram em sequência e passaram. Não executar dois builds do projeto ao mesmo tempo.
- O runtime externo de Computer Use não inicializou neste ambiente. A inspeção visual usou imagens do RepaintBoundary do aplicativo Windows em execução, e os controles Win32 foram verificados pela integração nativa.

## Não executado / limitações

- Windows limpo sem SDK, Narrador, múltiplos monitores/DPI e instalação de Codex em outro layout não foram ensaiados. A integração usou o Windows e a conta desta máquina.
- Atualização de versão anterior não se aplica à primeira versão. Protocolo Update já integrado, mas não há publicação do app no feed nem no catálogo; não foram inventadas versões para testar a rede de produção.
- Não há certificado de editor no instalador local. Não há inicio automático com Windows nem coleta com o monitor fechado.
- Percentuais e tokens de atividade não são conversíveis em uma franquia fixa de tokens. Contadores locais podem estar incompletos. Datas do histórico e atraso de consolidação são definidos pelo servidor.
- Serviço ai-memory recusou conexão em localhost:49374 mesmo na tentativa com acesso de rede. BMDS local validado; nenhuma indexação na wiki foi declarada.

Fontes do contrato: docs/DESIGN.md. Continuidade: ../clustter-main/handoffs/thermo.md. Nenhum dado real de conta consta neste documento.
