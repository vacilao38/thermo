# Memória BMDS — codex_thermometer-f2b83602a8

```bmds-json
{
  "bmds": "0.1",
  "kind": "manifest",
  "id": "bmds://codex_thermometer-f2b83602a8/manifest/root",
  "rev": 1,
  "profile": "portable",
  "created_at": "2026-10-27T08:35:01-03:00",
  "slot_profile": [
    "núcleo",
    "fatos",
    "decisões",
    "pendências",
    "entidades",
    "cronologia",
    "evidências_e_conflitos",
    "chaves_de_recuperação"
  ]
}
```

```bmds-json
{
  "bmds": "0.1",
  "kind": "cache",
  "id": "bmds://codex_thermometer-f2b83602a8/cell/thermo-windows-0.1.0-7dbd5ae695",
  "rev": 1,
  "cell_type": "atomic",
  "created_at": "2026-10-27T08:59:39-03:00",
  "tags": [
    "codex",
    "thermo",
    "tokens",
    "windows"
  ],
  "slots": [
    "Thermo 0.1.0: aplicativo Windows para acompanhar reserva e atividade do Codex, solicitado em 27/10/2026 com inspiração neomórfica.",
    [
      "Flutter 3.44.1/Dart 3.12.1; consulta real via app-server do Codex instalado.",
      "rateLimitsByLimitId preferido, duração efetiva das janelas e resetsAt; account/usage/read fornece histórico de atividade.",
      "13 testes unitários/widget e integração Windows com conta real passaram; Release compilado."
    ],
    [
      "Pedido do usuário: Windows e design inspirado em neomorfismo.",
      "Regra do workspace: repositório próprio público; nenhuma autorização para catálogo ou downloads públicos.",
      "Implementado: compacto, fixação Win32, bandeja, temas, pausa, consulta automática e contadores locais incrementais."
    ],
    [
      "Validar em outro Windows sem SDK e com instalação diferente do Codex; Narrador não ensaiado.",
      "ai-memory indisponível em localhost:49374 (conexão recusada); sem indexação ou sincronização de wiki declarada."
    ],
    {
      "repo": "https://github.com/vacilao38/thermo",
      "central": "../clustter-main",
      "handoff": "handoffs/thermo.md",
      "sources": [
        "docs/DESIGN.md",
        "docs/VALIDATION.md"
      ]
    },
    "27/10/2026: criado repositório próprio, app, contrato de dados, testes, build Windows e cadastro no inventário.",
    [
      "Origem: solicitação atual do usuário, documentação oficial OpenAI App Server e schema do Codex 0.164.0-alpha.11.1.",
      "Tokens de atividade/cache não equivalem à franquia percentual. Tokens restantes da assinatura não são informados; mostrar explicitamente desconhecido.",
      "Dados de conta e capturas locais não são versionados; logs e autenticação não são exportados. Sem dados pessoais neste registro."
    ],
    [
      "thermo",
      "codex",
      "limites",
      "tokens",
      "windows",
      "neomorfismo",
      "app-server"
    ]
  ],
  "provenance": {
    "operation": "write",
    "sources": [],
    "actor": "human"
  }
}
```
```bmds-json
{
  "bmds": "0.1",
  "kind": "stack",
  "id": "bmds://codex_thermometer-f2b83602a8/stack/desenvolvimento",
  "rev": 1,
  "updated_at": "2026-10-27T08:59:39-03:00",
  "logical_clock": 1,
  "members": [
    {
      "id": "bmds://codex_thermometer-f2b83602a8/cell/thermo-windows-0.1.0-7dbd5ae695",
      "rev": 1
    }
  ],
  "policy": {
    "soft_cells": 16,
    "hard_tokens": 4096,
    "keep_hot": 4
  }
}
```

```bmds-json
{
  "bmds": "0.1",
  "kind": "cache",
  "id": "bmds://codex_thermometer-f2b83602a8/cell/msvc-utf-8-no-runner-2775400c1d",
  "rev": 1,
  "cell_type": "atomic",
  "created_at": "2026-10-27T09:06:26-03:00",
  "tags": [
    "thermo",
    "utf8",
    "windows"
  ],
  "slots": [
    "Gotcha verificado no runner Windows: arquivo C++ em UTF-8 também exige MSVC /utf-8.",
    [
      "O título nativo inicial interpretou o separador como U+00C2 U+00B7.",
      "Após target_compile_options runner PRIVATE /utf-8, Release recompilado; título correto confirmado por codepoints e processo respondendo.",
      "Instalador final regenerado; tamanho/hash em docs/VALIDATION.md."
    ],
    [
      "Manter /utf-8 no alvo runner para preservar títulos, tooltips e mensagens nativas em português."
    ],
    [],
    [
      "windows/runner/CMakeLists.txt",
      "windows/runner/main.cpp",
      "docs/VALIDATION.md"
    ],
    "27/10/2026: correção final de codificação após inspeção da instância Release real.",
    [
      "Origem: observação do processo próprio Thermo e comparação dos codepoints antes/depois; sem dados da conta.",
      "13 testes e integração real passaram antes deste ajuste de compilador. O pacote foi recompilado, aberto e conferido depois."
    ],
    [
      "utf8",
      "msvc",
      "windows",
      "runner",
      "thermo"
    ]
  ],
  "provenance": {
    "operation": "write",
    "sources": [],
    "actor": "human"
  }
}
```
```bmds-json
{
  "bmds": "0.1",
  "kind": "stack",
  "id": "bmds://codex_thermometer-f2b83602a8/stack/desenvolvimento",
  "rev": 2,
  "updated_at": "2026-10-27T09:06:26-03:00",
  "logical_clock": 2,
  "members": [
    {
      "id": "bmds://codex_thermometer-f2b83602a8/cell/msvc-utf-8-no-runner-2775400c1d",
      "rev": 1
    },
    {
      "id": "bmds://codex_thermometer-f2b83602a8/cell/thermo-windows-0.1.0-7dbd5ae695",
      "rev": 1
    }
  ],
  "policy": {
    "soft_cells": 16,
    "hard_tokens": 4096,
    "keep_hot": 4
  },
  "parent_rev": 1
}
```
