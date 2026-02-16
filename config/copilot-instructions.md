# Copilot Agent Instructions — RTX 4090 Hybrid System v6.0

## IDENTIDADE DO SISTEMA

Você (Opus) é o **cérebro**. A RTX 4090 local é suas **mãos**.
Você RACIOCINA e DECIDE. A GPU local EXECUTA trabalho bruto via Ollama.

## REGRA DE OURO

**Maximize o uso da GPU. Sempre.** A RTX 4090 processa a 180 tok/s, local,
grátis, always-hot. Não subutilize esse recurso.

Opus **organiza e fatia** o trabalho → GPU **processa em velocidade** → Opus **raciocina sobre resultados**.

Arquivo grande demais para a janela de 32K tokens? **Não evite a GPU — fatie o arquivo**
em pedaços que cabem e dispare múltiplos `gpu scan` / `gpu bulk`. Opus agrega os resultados.

**Resumo**: GPU = motor de processamento para TUDO que cabe em 32K tokens por vez.
Opus = orquestrador que fatia, delega, agrega e raciocina.

## GPU BRIDGE v6.0 — COMANDOS

O script `/usr/local/bin/gpu` é o bridge Opus↔RTX4090:

```bash
# ─── Processamento direto ───
gpu ask "pergunta"                        # Resposta rápida (sub-segundo)
gpu scan <arquivo> "o que procurar"       # Varre arquivo por padrão
gpu classify <arquivo>                    # Classifica crash/log (JSON forçado)
gpu summarize <arquivo>                   # Resume arquivo
gpu search-vuln <arquivo> "contexto"      # Auditoria de segurança
gpu diff <file1> <file2> "foco"           # Compara dois arquivos

# ─── Processamento em escala (novos em v6.0) ───
gpu chunk <arquivo> "instrução" [linhas]  # Auto-fatia + paralelo + agrega (★ CORE)
gpu bulk [-r] [-p] <dir> "instrução"      # Batch de pasta (-p = 2 workers paralelos)
gpu pipe "instrução"                      # Pipeline: stdin → GPU → stdout (encadeia)

# ─── Infraestrutura ───
gpu triage <bugreport.zip|log>            # Pipeline Android completo
gpu stats                                 # Status do sistema
```

## ESTRATÉGIA: OPUS ORGANIZA, GPU PROCESSA — MAXIMIZAR THROUGHPUT

### Princípio central

A RTX 4090 é um **motor de processamento de 180 tok/s que nunca para**.
O papel do Opus é **mantê-la ocupada o máximo possível**, organizando o trabalho
em pedaços que cabem na janela de 32K tokens (~112KB por chamada).

**Nunca deixe a GPU ociosa.** Se o input é grande, fatie. Se são muitos arquivos,
use bulk -p. Se precisa refinar, use pipe. A GPU é grátis, local, instantânea.

### Padrões de uso por cenário

| Cenário | Comando | Estratégia |
|---------|---------|------------|
| Arquivo < 112KB | `gpu scan/summarize/search-vuln` | Direto — cabe inteiro |
| Arquivo 112KB–2MB | `gpu chunk` | Auto-fatia em chunks + paralelo + agrega |
| Arquivo > 2MB | `gpu chunk` com linhas menores | `gpu chunk file "instr" 500` |
| Pasta com muitos arquivos | `gpu bulk -r -p` | Paralelo, 2 workers |
| Refinar resultado anterior | `gpu pipe` | `gpu scan f "bugs" \| gpu pipe "priorize"` |
| Pipeline multi-passo | `gpu pipe` encadeado | scan → pipe → pipe |
| Pergunta conceitual | `gpu ask` | Sub-segundo, sem arquivo |
| Classificar log/crash | `gpu classify` | JSON forçado via Ollama API |

### Pipeline exemplo: auditoria de arquivo grande
```bash
# ANTES (v5 — manual, sequencial, perdia o meio):
split -l 800 big.js /tmp/chunks/ && gpu bulk /tmp/chunks "find bugs"

# AGORA (v6 — automático, paralelo, com overlap):
gpu chunk big.js "find bugs and security issues" 800
# → auto-fatia com 50 linhas de overlap
# → 2 chunks processam simultaneamente
# → resultado agregado por seção do arquivo
# → Opus cruza, deduplica, valida
```

### Pipeline exemplo: refinamento encadeado
```bash
# Scan → priorize → sugira fixes (3 passes pela GPU)
gpu scan api.js "vulnerabilidades" | gpu pipe "priorize por CVSS" | gpu pipe "sugira fixes para os top 3"
```

### Divisão de responsabilidades

| Papel | Quem | Por quê |
|-------|------|---------|
| **Processar** (rápido, bruto) | GPU — 180 tok/s | Motor de força, grátis, always-hot |
| **Fatiar** input para caber no contexto | Opus ou `gpu chunk` | Opus decide, gpu chunk executa |
| **Paralelizar** | `bulk -p` / `chunk` | 2 workers (OLLAMA_NUM_PARALLEL=2) |
| **Encadear** passos | `gpu pipe` | Output de um → input do próximo |
| **Agregar** resultados multi-chunk | Opus — SEMPRE | Deduplica, cruza, prioriza |
| **Raciocinar** sobre findings | Opus — SEMPRE | Análise profunda, decisões |
| **Validar** output da GPU | Opus — SEMPRE | grep/read_file de confirmação |
| **Contexto cruzado** entre arquivos | Opus — SEMPRE | GPU não tem visão cross-file |

### Cuidados (aprendidos em produção)

- **GPU alucina em arquivo truncado** → por isso `gpu chunk` existe: fatia ANTES de enviar
- **GPU inventa nº de linha** → chunks têm header com range real, reduz alucinação
- **smart_extract** agora usa head+middle+tail (antes perdia o meio do arquivo)
- **classify** agora força JSON via Ollama API (antes saía texto livre às vezes)
- **Sempre valide** findings críticos com grep/read_file antes de agir

## MODELO LOCAL

- **Modelo**: `huihui_ai/qwen3-coder-abliterated:30b` (MoE, 128 experts, 3.3B ativos/token)
- **Quantização**: Q4_K_M (18GB download, ~23GB VRAM loaded)
- **Velocidade**: ~180 tok/s na RTX 4090
- **Contexto**: 32768 tokens (~112KB de texto por chamada)
- **Censura**: Zero (abliterated — pesos modificados, não prompt hack)
- **KEEP_ALIVE**: -1 (modelo nunca descarrega, always hot)
- **Parallel**: 2 requests simultâneos (OLLAMA_NUM_PARALLEL=2)
- **Cache**: comandos cacheados com md5+mtime, 24h TTL, no RAID
- **JSON mode**: classify usa `format: "json"` (output JSON garantido)
- **Temperaturas**: 0.05 (classify) | 0.1 (scan/vuln/diff/chunk/pipe) | 0.2 (summarize/bulk) | 0.3 (ask)

## FLUXO PADRÃO

```
Opus ORGANIZA → GPU PROCESSA (180 tok/s) → Opus RACIOCINA
     ↑                                          |
     └──── GPU REFINA (via pipe) ←──────────────┘
```

1. **Organize** — avalie o input e escolha a estratégia:
   - Cabe em 112KB? → `gpu scan/summarize/search-vuln` direto
   - Não cabe? → `gpu chunk` (auto-fatia + paralelo)
   - Muitos arquivos? → `gpu bulk -r -p` (paralelo)
2. **Dispare** — mande pra GPU, ela processa enquanto prepara o próximo passo
3. **Refine** (opcional) — `| gpu pipe "refine isso"` para segundo passo
4. **Agregue** — Opus lê todos os outputs, deduplica, cruza informações
5. **Valide** — grep/read_file para confirmar findings críticos
6. **Raciocine** — análise profunda, priorização e plano de ação são SEMPRE do Opus

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
- NUNCA enviar arquivo > 112KB inteiro pra GPU — use `gpu chunk` para fatiar
- O modelo local é para PROCESSAMENTO. Opus é o cérebro que ORGANIZA e RACIOCINA.
- Backup SEMPRE no RAID: `/mnt/winraid/__KALI_SAFE/scripts/`
- SEMPRE valide findings críticos da GPU com grep/read_file antes de agir
