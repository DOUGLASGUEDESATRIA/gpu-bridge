# GPU Hybrid Bridge v5.1

**Sistema híbrido Opus↔RTX 4090** — Copilot (Opus) raciocina, GPU local executa.

## Arquitetura

```
┌─────────────┐     ┌─────────────┐     ┌──────────────────┐
│  Copilot     │────▶│  gpu CLI    │────▶│  Ollama + RTX    │
│  (Opus)      │◀────│  bridge     │◀────│  4090 (24GB)     │
│  = cérebro   │     │  = terminal │     │  = processamento │
└─────────────┘     └─────────────┘     └──────────────────┘
```

O Opus lê outputs compactos e aplica raciocínio profundo.
A GPU processa trabalho bruto a 180 tok/s sem censura.

## Hardware

| Component | Spec |
|-----------|------|
| GPU | NVIDIA RTX 4090, 24GB VRAM, PCIe Gen4 x16 |
| CPU | Intel i9-13900K, 24c/32t, 5.8GHz |
| RAM | 128GB DDR5 |
| Storage | RAID 7.5TB (/mnt/winraid), 2.9 GB/s write |
| OS | Kali Linux, kernel 6.18.x |

## Modelo

| Propriedade | Valor |
|-------------|-------|
| Nome | `huihui_ai/qwen3-coder-abliterated:30b` |
| Tipo | MoE — 30B total, 3.3B ativos/token, 128 experts |
| Quantização | Q4_K_M (18GB download, ~23GB VRAM loaded) |
| Velocidade | ~180 tok/s |
| Contexto | 32768 tokens |
| Censura | Zero (abliterated — pesos modificados no nível dos weights) |

## Comandos

```bash
gpu ask "pergunta"                    # Pergunta rápida (~0.5s)
gpu scan <file> "query"               # Varre arquivo por padrão
gpu classify <file>                   # Classifica crash/log → JSON
gpu summarize <file>                  # Resume arquivo grande
gpu triage <bugreport.zip|log>        # Pipeline Android completo
gpu search-vuln <file> "contexto"     # Auditoria de segurança
gpu bulk [-r] <dir> "instrução"       # Processa pasta inteira
gpu diff <f1> <f2> "foco"             # Compara dois arquivos
gpu stats                             # Status do sistema
```

## Instalação

### 1. Ollama + Modelo

```bash
# Instalar Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Baixar modelo abliterated (18GB)
OLLAMA_MODELS=/mnt/winraid/__KALI_SAFE/models ollama pull huihui_ai/qwen3-coder-abliterated:30b
```

### 2. Systemd Override

```bash
sudo mkdir -p /etc/systemd/system/ollama.service.d/
sudo cp config/ollama-override.conf /etc/systemd/system/ollama.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

### 3. GPU Bridge Script

```bash
sudo cp scripts/gpu /usr/local/bin/gpu
sudo chmod +x /usr/local/bin/gpu
```

### 4. VS Code / Copilot Instructions

```bash
# Copiar instruções globais
cp config/copilot-instructions.md /mnt/winraid/__KALI_SAFE/copilot-instructions.md

# O settings.json já está configurado com:
# - github.copilot.chat.instructions → aponta pro arquivo
# - github.copilot.chat.codeGeneration.instructions → aponta pro arquivo
# Ver config/vscode-settings.json para referência
```

## Estrutura do Repositório

```
gpu-hybrid-bridge/
├── README.md                          # Este arquivo
├── scripts/
│   └── gpu                            # Bridge script v5.1 (824 linhas)
├── config/
│   ├── copilot-instructions.md        # Instruções globais pro Copilot
│   ├── ollama-override.conf           # Systemd override (performance)
│   └── vscode-settings.json           # VS Code settings de referência
├── docs/
│   ├── ARCHITECTURE.md                # Decisões de arquitetura
│   ├── BENCHMARKS.md                  # Benchmarks de modelos
│   └── CHANGELOG.md                   # Histórico de versões
└── install.sh                         # Script de instalação automática
```

## Otimizações Ollama (systemd override)

| Setting | Valor | Efeito |
|---------|-------|--------|
| `OLLAMA_FLASH_ATTENTION` | 1 | ~2x mais rápido, menos VRAM no KV |
| `OLLAMA_KV_CACHE_TYPE` | q8_0 | ~40% economia de VRAM no context |
| `OLLAMA_KEEP_ALIVE` | -1 | Modelo nunca descarrega (always hot) |
| `OLLAMA_NUM_PARALLEL` | 2 | Até 2 queries simultâneas |
| `nvidia-smi -pm 1` | ExecStartPost | GPU persistence mode, sem cold start CUDA |
| Storage paths | RAID | Modelos, tmp, cache, logs — tudo no RAID |

## Temperaturas por Comando

| Tipo | Temp | Comandos |
|------|------|----------|
| Deterministic | 0.05 | classify |
| Analytical | 0.10 | scan, search-vuln, diff |
| Balanced | 0.20 | summarize, bulk |
| Creative | 0.30 | ask |

## Histórico

| Versão | Data | Mudanças |
|--------|------|----------|
| v1.0 | — | Script inicial, 17 bugs |
| v2.0 | — | SIGPIPE fix, multi-model, cache |
| v3.0 | — | Smart extraction, content limits |
| v4.0 | — | Single model (30B MoE), limpeza |
| v5.0 | — | 32K ctx, KEEP_ALIVE=-1, retry, temperatures, cache expansion |
| v5.1 | Feb 2026 | Cache guard, validate_model integrado, binary rejection, dynamic stats |

## Sessão Já Iniciada

Para ativar o modo monstro num chat Copilot já aberto:

```
Leia /mnt/winraid/__KALI_SAFE/copilot-instructions.md e siga como regra pro resto deste chat.
```

## Licença

Uso pessoal. Sistema feito sob medida para RTX 4090 + Kali Linux.
