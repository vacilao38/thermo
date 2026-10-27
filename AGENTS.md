# Thermo

- UTF-8 em todos os arquivos de texto.
- Aplicativo Windows Flutter; não gerar versões mobile sem solicitação.
- Consultar limites e atividade via app-server do Codex instalado. Não ler/extrair auth.json, criar turnos ou substituir a autenticação do Codex.
- Percentuais são franquias; tokens são atividade. Nunca converter percentuais em uma franquia de tokens suposta.
- Não persistir nem versionar contadores reais da conta, sessões, capturas, identificadores, tokens de autenticação ou logs. outputs/, dist/, .local/ e .bmds/ são locais.
- Código em repositório próprio público. Publicação de instaladores, releases e inclusão no catálogo requerem pedido explícito.
- Validar cálculos/leitura incremental, análise Flutter e integração Windows para mudanças pertinentes.
- A central de continuidade é ../clustter-main; handoff em handoffs/thermo.md.
