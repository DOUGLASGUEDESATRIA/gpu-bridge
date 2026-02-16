# Decisões de Arquitetura

## Por que Híbrido (Opus + GPU local)?

- **Opus**: Raciocínio profundo, planejamento, decisões complexas — mas não processa arquivos grandes eficientemente
- **GPU local (RTX 4090)**: Processamento bruto a 180 tok/s — mas sem capacidade de raciocínio multi-step
- **Resultado**: Opus pensa, GPU executa, Opus analisa output. Melhor dos dois mundos.

## Por que Modelo Único (qwen3-coder-abliterated:30b)?

Testamos 7+ modelos. O MoE 30B venceu em todos os critérios:

- **Mais rápido que 7B**: 178 tok/s vs 160 tok/s (MoE ativa só 3.3B/token)
- **Melhor qualidade que 14B**: Respostas mais estruturadas e completas
- **Sem censura**: Abliterated (pesos modificados, não prompt hack)
- **Cabe na VRAM**: ~23GB de 24GB (com q8_0 KV cache + flash attention)

Modelos eliminados:
- `qwen2.5-coder:7b` — mais lento que 30B MoE, menor qualidade
- `qwen2.5-coder:14b` — mais lento, menor qualidade
- `qwen2.5-coder:32b` — 7.5 tok/s (11x mais lento), dense demais pra 24GB
- `devstral` — 53 tok/s, qualidade inferior

## Por que 32K Context?

- RTX 4090 tem 24GB. Com q8_0 KV cache + flash attention, 32K tokens cabe.
- v4.0 usava 8192 (desperdiçava 87.5% da capacidade).
- 32768 = máximo seguro sem OOM.

## Por que KEEP_ALIVE=-1?

- Modelo de 23GB demora ~3s para carregar na VRAM.
- Com only 1 modelo, não há competição por VRAM.
- -1 = modelo fica loaded para sempre. Zero cold starts.

## Por que Abliterated?

Modelos padrão recusam qualquer coisa relacionada a security research.
Abliterated (huihui_ai) remove censura no nível dos weights — não é jailbreak por prompt,
é remoção permanente das camadas de recusa. Funciona 100% sem workarounds.

## Por que Cache no RAID?

- RAID tem 7.5TB e 2.9 GB/s write speed.
- Cache entries são texto pequeno (~4KB cada).
- Sem impacto no disco do sistema.
- 24h TTL evita stale data sem perder performance.

## Por que Temperatures Diferentes?

Cada tipo de tarefa precisa de trade-off diferente:
- **classify (0.05)**: Precisa de JSON consistente, zero criatividade
- **scan/vuln/diff (0.1)**: Precisa ser preciso mas pode variar formatação
- **summarize/bulk (0.2)**: Precisa sintetizar, alguma liberdade
- **ask (0.3)**: Conversa geral, mais liberdade criativa

## Por que Auto-Chunk em vez de Rejeitar Arquivos Grandes?

Filosofia v6.0: **a GPU nunca deve ficar ociosa**. Quando um arquivo não cabe no contexto de 32K tokens:

1. **Opus fatia** — `gpu chunk` calcula chunks que cabem no contexto (~800 linhas com overlap de 50)
2. **GPU processa em paralelo** — 2 workers simultâneos (`OLLAMA_NUM_PARALLEL=2`)
3. **Resultados agregados** — com ranges de linhas reais para rastreabilidade

Antes (v5.x): "arquivo grande → delega para Opus" (GPU ociosa).
Agora (v6.0): "arquivo grande → Opus fatia → GPU processa tudo → Opus raciocina sobre resultado".

O overlap entre chunks (50 linhas por padrão) garante que bugs em fronteiras não sejam perdidos.

## Por que Pipeline (stdin→GPU→stdout)?

`gpu pipe` permite composição Unix nativa:
```bash
gpu scan app.js "bugs" | gpu pipe "priorizar por severidade"
cat crash.log | gpu pipe "extrair stack traces"
```

Isso transforma a GPU num filtro de texto inteligente — encaixável em qualquer pipeline existente.

## Por que smart_extract Head+Middle+Tail?

v3.0–v5.x usavam split 70/30 (head+tail). Problema: o meio do arquivo era sempre perdido.
Muitos bugs e lógica crítica ficam no meio. v6.0 usa 40/30/30 (head+middle+tail):

- **Head (40%)**: Imports, config, setup
- **Middle (30%)**: Lógica core, funções principais
- **Tail (30%)**: Error handlers, cleanup, exports

Isso dá cobertura uniforme do arquivo sem duplicação.
