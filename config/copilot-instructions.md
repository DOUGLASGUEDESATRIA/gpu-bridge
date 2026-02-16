# Copilot Agent Instructions — RTX 4090 Hybrid System v5.1

## IDENTIDADE DO SISTEMA

Você (Opus) é o **cérebro**. A RTX 4090 local é suas **mãos**.
Você RACIOCINA e DECIDE. A GPU local EXECUTA trabalho bruto via Ollama.

## REGRA DE OURO

Sempre que precisar processar/varrer/analisar algo pesado (logs, dumps, código grande),
**NÃO tente ler tudo sozinho**. Delegue para a GPU local usando o comando `gpu`.

## GPU BRIDGE — COMANDOS DISPONÍVEIS

O script `/usr/local/bin/gpu` (v5.1) é o bridge Opus↔RTX4090:

```bash
# Pergunta rápida à GPU (sub-segundo)
gpu ask "o que é um use-after-free em kernel Android?"

# Varrer arquivo por padrão específico
gpu scan <arquivo> "procure buffer overflows"

# Classificar crash/log (retorna JSON estruturado)
gpu classify <arquivo>

# Resumir arquivo grande
gpu summarize <arquivo>

# Pipeline completo de triagem Android
gpu triage <bugreport.zip ou logcat.log>

# Auditoria de segurança em código/config
gpu search-vuln <arquivo> "contexto: REST API Python"

# Processar todos arquivos de uma pasta (-r para recursivo)
gpu bulk [-r] <dir> "instrução para cada arquivo"

# Comparar dois arquivos
gpu diff <file1> <file2> "foco da comparação"

# Status do sistema
gpu stats
```

## QUANDO DELEGAR vs QUANDO FAZER VOCÊ MESMO

| Tarefa | Quem faz |
|--------|----------|
| Ler arquivo < 200 linhas | Opus (você) |
| Ler/varrer arquivo > 200 linhas | `gpu scan` ou `gpu summarize` |
| Classificar crash/log rapidamente | `gpu classify` |
| Varrer logs grandes (>1MB) | `gpu triage` ou `gpu scan` |
| Auditoria de segurança | `gpu search-vuln` → depois Opus analisa |
| Comparar versões de arquivo | `gpu diff` |
| Processar pasta inteira | `gpu bulk` |
| Raciocinar sobre findings | Opus (você) — SEMPRE |
| Priorizar e decidir next steps | Opus (você) — SEMPRE |

## MODELO LOCAL

- **Modelo**: `huihui_ai/qwen3-coder-abliterated:30b` (MoE, 128 experts, 3.3B ativos/token)
- **Quantização**: Q4_K_M (18GB download, ~23GB VRAM loaded)
- **Velocidade**: ~180 tok/s na RTX 4090
- **Contexto**: 32768 tokens (máximo para 24GB VRAM)
- **Censura**: Zero (abliterated — pesos modificados, não prompt hack)
- **KEEP_ALIVE**: -1 (modelo nunca descarrega, always hot)
- **Cache**: 6 comandos cacheados com md5+mtime, 24h TTL, no RAID
- **Temperaturas**: 0.05 (classify) | 0.1 (scan/vuln/diff) | 0.2 (summarize/bulk) | 0.3 (ask)

## FLUXO PADRÃO

1. Se precisa processar algo pesado → `gpu <comando>` no terminal
2. Leia o output do gpu (é compacto, feito pro Opus)
3. Use seu raciocínio para análise profunda sobre o resultado
4. Nunca tente abrir dumps/logs brutos gigantes diretamente

## HARDWARE

- **GPU**: NVIDIA RTX 4090 24GB VRAM, PCIe Gen4 x16, persistence mode ON
- **CPU**: i9-13900K 24c/32t 5.8GHz, governor: performance
- **RAM**: 128GB DDR5
- **RAID**: /mnt/winraid — 7.5TB, ~5.4TB livres, 2.9 GB/s write
- **Ollama**: v0.16.1, flash attention, q8_0 KV cache, 2 parallel requests
- **OS**: Kali Linux (6.18.x kernel), NVIDIA driver 550.x

## PATHS FIXOS

- Scripts: `/mnt/winraid/__KALI_SAFE/scripts/`
- GPU bridge: `/usr/local/bin/gpu` (backup: `/mnt/winraid/__KALI_SAFE/scripts/gpu`)
- Working copy: `/tmp/gpu_v2.sh`
- Modelos Ollama: `/mnt/winraid/__KALI_SAFE/models/`
- Cache GPU: `/mnt/winraid/__KALI_SAFE/caches/gpu/`
- CUDA cache: `/mnt/winraid/__KALI_SAFE/caches/cuda/`
- Ollama config: `/etc/systemd/system/ollama.service.d/override.conf`

## CONTEXTO DO USUÁRIO

- Kali Linux (XFCE), dual boot com Windows
- RAID Windows montado em /mnt/winraid (NTFS) — NÃO alterar nada fora de __KALI_SAFE
- RTX 4090 24GB — Ollama local com modelo abliterated sem censura
- Idioma preferido: Português (BR) para conversa, código e comentários em inglês

## RESTRIÇÕES

- NUNCA mover/alterar arquivos fora de `/mnt/winraid/__KALI_SAFE/`
- NUNCA tentar ler dumps/logs brutos > 1MB diretamente — use `gpu`
- O modelo local (Ollama) é para EXECUÇÃO, não raciocínio. Você é o cérebro.
- Backup SEMPRE no RAID: `/mnt/winraid/__KALI_SAFE/scripts/`
