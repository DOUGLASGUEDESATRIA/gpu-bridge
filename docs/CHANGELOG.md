# Changelog

## v6.1 (February 2026) — CURRENT

### Philosophy Change: GPU = Data Processor, Not Analyst
- **`EXTRACT_RULE` constant**: Injected into all processing prompts — GPU extracts, never analyzes
- **All prompts rewritten**: scan, vuln, chunk, diff, summarize, pipe, bulk — from "analyze" to "extract"
- **GPU never opines**: No severity assessment, no recommendations, no interpretation
- **Opus is the brain**: Only Opus analyzes, prioritizes, reasons, and creates

### Temperature Simplification (4 → 3 tiers)
- **Eliminated `TEMP_ANALYTICAL` (0.1)**: Extraction doesn't need creativity
- **Extract (0.05)**: scan, search-vuln, diff, chunk, pipe, classify — deterministic extraction
- **Condense (0.2)**: summarize, bulk — structured condensation
- **Creative (0.3)**: ask — only command where GPU "thinks"

### Documentation
- **copilot-instructions.md**: Full rewrite with processor philosophy, updated tables
- **README.md**: Updated architecture diagram, temperature table, version history
- **ARCHITECTURE.md**: New "GPU = Pure Processor" rationale section, updated temperature docs

### Improvement Round 1
- **Cache key includes VERSION**: Prompt changes auto-invalidate cache
- **scan auto-chunks**: Files exceeding context auto-redirect to `gpu chunk`
- **Parallel error handling**: Workers capture stderr, report failures with ⚠️ marker
- **smart_extract truncation warning**: Logs "Truncado: XKB → YKB (Z%)" when truncating
- **`gpu cache-clean`**: New command to purge expired cache (>24h)
- **Chunk overlap configurable**: 4th param in `gpu chunk` (default: 50 lines)

### Improvement Round 2
- **summarize/search-vuln auto-chunk**: Same auto-redirect pattern as scan for large files
- **`--no-cache` global flag**: `gpu --no-cache <cmd>` forces reprocessing
- **Differentiated exit codes**: 0=OK, 2=file, 3=ollama, 4=timeout, 5=usage (documented in help)

### Rating: 10/10

---

## v6.0 (February 2026)

### New Commands
- **`gpu chunk <file> "instrução"`**: Auto-fatia arquivos grandes com overlap configurável, processa chunks em paralelo (2 workers), agrega resultados com ranges de linhas reais
- **`gpu pipe "instrução"`**: stdin→GPU→stdout — permite encadear comandos: `gpu scan f | gpu pipe "resumir"`
- **`gpu bulk -p`**: Modo paralelo com 2 workers simultâneos via `OLLAMA_NUM_PARALLEL=2`

### Improvements
- **smart_extract**: Head(40%) + Middle(30%) + Tail(30%) em vez de Head(70%) + Tail(30%) — para de perder o meio dos arquivos
- **classify JSON**: Usa `format: "json"` do Ollama — output é JSON puro garantido
- **ollama_query $5 format**: Novo parâmetro para forçar JSON mode na API
- **dd bs=4096**: `smart_extract` usa `bs=4096 | head -c` em vez de `bs=1` (ordens de magnitude mais rápido)
- **cache_put printf**: `printf '%s'` em vez de `echo` — sem newlines fantasma, safe para conteúdo com `-n`/`-e`
- **Chunk range tracking**: Ranges de linhas reais salvos em metadata durante fatiamento, lidos na agregação (sem aproximação)

### Fixes
- **Chunk infinite loop**: Adicionado `(( end_line >= total_lines )) && break` no overlap loop

### Rating: 10/10

---

## v5.1 (February 2026)

### Fixes
- **Cache guard**: Resultados vazios/falhos nunca são cacheados (guard `[[ -n "$result" ]]` em 5 comandos)
- **validate_model() integrado**: Chamado dentro de `ensure_ollama()` automaticamente — zero dead code
- **Binary rejection**: `require_file()` agora rejeita arquivos binários (antes desperdiçava tokens com lixo)
- **Dynamic stats**: `gpu stats` lê info do modelo via `/api/ps` em vez de texto hardcoded

### Rating: 10/10

---

## v5.0 (February 2026)

### Major Changes
- **32K context**: `num_ctx` de 8192 → 32768 (aproveitando 100% da capacidade)
- **KEEP_ALIVE=-1**: Modelo nunca descarrega (expires year 2318)
- **GPU persistence mode**: `nvidia-smi -pm 1` via systemd ExecStartPost
- **Retry logic**: `MAX_RETRIES=1` com backoff no `ollama_query()`
- **Temperature per command**: 4 temperaturas (0.05/0.1/0.2/0.3)
- **Cache expansion**: 6 comandos cacheados (era 2)
- **Content limits expanded**: small=8K, med=48K, large=80K, vuln=64K, diff=32K
- **Timer fix**: `_timer_start` posicionado corretamente no classify
- **Dead code removed**: `resolve_model()` eliminada

### Rating: 8.5/10 (before v5.1 micro-fixes)

---

## v4.0 (February 2026)

### Major Changes
- **Single model architecture**: Removidos 7B, 14B, devstral — only qwen3-coder-abliterated:30b
- **Simplified**: Sem multi-tier, sem model selection logic
- Primeira auditoria revelou 10 issues (6.5/10)

---

## v3.0

### Major Changes
- Smart content extraction (head + tail split 70/30)
- Content limits por tipo de comando
- `search-vuln` empty line bug fix
- RAID cache system

---

## v2.0

### Major Changes
- **SIGPIPE fix**: Captura curl em variável antes de pipe para jq
- Multi-model strategy (later removed in v4)
- Cache system introduced

---

## v1.0

### Initial Release
- Basic bridge script
- 17 bugs discovered in first audit
- Single model, no cache, no retry
