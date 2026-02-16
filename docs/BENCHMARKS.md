# Benchmarks de Modelos na RTX 4090

## Benchmark Final (3-way)

Teste: análise de segurança de script Python 200 linhas.

| Modelo | Tipo | VRAM | tok/s | Qualidade | Veredicto |
|--------|------|------|-------|-----------|-----------|
| qwen2.5-coder-abliterate:7b | Dense 7B | ~5GB | 160 | Básica | ❌ Eliminado |
| qwen2.5-coder-abliterate:14b | Dense 14B | ~10GB | 82 | Boa | ❌ Eliminado |
| qwen2.5-coder-abliterate:32b | Dense 32B | ~20GB | 7.5 | Excelente | ❌ 11x lento |
| devstral | MoE | ~14GB | 53 | Média | ❌ Eliminado |
| **qwen3-coder-abliterated:30b** | **MoE 30B** | **~23GB** | **178** | **Excelente** | **✅ CAMPEÃO** |

## Por que MoE 30B é mais rápido que Dense 7B?

- MoE (Mixture of Experts) tem 128 experts mas ativa apenas 8 por token
- Parâmetros ativos por token: ~3.3B (menos que os 7B do dense)
- Mesma VRAM que dense 32B, mas velocidade de modelo 3B
- Qualidade de modelo 30B porque tem 30B de conhecimento total

## Velocidades Típicas (v5.1, Feb 2026)

| Cenário | tok/s | Latência |
|---------|-------|----------|
| Warm (modelo loaded) | 178 | <100ms first token |
| Cache hit | 352 | <50ms (sem inferência) |
| Cold start (KEEP_ALIVE=-1) | N/A | Modelo nunca descarrega |
| Prompt grande (8K tokens) | ~170 | Normal |

## VRAM Breakdown

| Component | VRAM |
|-----------|------|
| Model weights (Q4_K_M) | ~18GB |
| KV cache (32K ctx, q8_0) | ~4GB |
| CUDA overhead | ~1GB |
| **Total** | **~23GB / 24GB** |
