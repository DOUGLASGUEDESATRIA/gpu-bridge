# Changelog

## v5.1 (February 2026) — CURRENT

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
