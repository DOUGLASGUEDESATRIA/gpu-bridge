#!/bin/bash
# install.sh — Instalação automática do GPU Hybrid Bridge
# Uso: bash install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KALI_SAFE="/mnt/winraid/__KALI_SAFE"

echo "═══════════════════════════════════════════════"
echo "  GPU Hybrid Bridge v5.1 — Installer"
echo "═══════════════════════════════════════════════"
echo ""

# 1. Verificar RAID
if [[ ! -d "$KALI_SAFE" ]]; then
    echo "❌ RAID não montado em $KALI_SAFE"
    exit 1
fi
echo "✅ RAID encontrado: $KALI_SAFE"

# 2. Criar diretórios
echo "📁 Criando diretórios..."
mkdir -p "$KALI_SAFE"/{models,scripts,caches/gpu,caches/cuda,tmp/ollama,logs/ollama}

# 3. Instalar gpu bridge
echo "📦 Instalando gpu bridge..."
sudo cp "$SCRIPT_DIR/scripts/gpu" /usr/local/bin/gpu
sudo chmod +x /usr/local/bin/gpu
cp "$SCRIPT_DIR/scripts/gpu" "$KALI_SAFE/scripts/gpu"
echo "  → /usr/local/bin/gpu"
echo "  → $KALI_SAFE/scripts/gpu (backup)"

# 4. Instalar systemd override
echo "⚙️  Configurando Ollama systemd..."
sudo mkdir -p /etc/systemd/system/ollama.service.d/
sudo cp "$SCRIPT_DIR/config/ollama-override.conf" /etc/systemd/system/ollama.service.d/override.conf
sudo systemctl daemon-reload
echo "  → /etc/systemd/system/ollama.service.d/override.conf"

# 5. Copilot instructions
echo "📝 Instalando Copilot instructions..."
cp "$SCRIPT_DIR/config/copilot-instructions.md" "$KALI_SAFE/copilot-instructions.md"
echo "  → $KALI_SAFE/copilot-instructions.md"

# 6. Verificar Ollama
if command -v ollama &>/dev/null; then
    echo "✅ Ollama encontrado: $(ollama --version 2>&1 | head -1)"
else
    echo "⚠️  Ollama não instalado. Instale com:"
    echo "   curl -fsSL https://ollama.com/install.sh | sh"
fi

# 7. Verificar modelo
echo ""
echo "📋 Verificando modelo..."
if OLLAMA_MODELS="$KALI_SAFE/models" ollama list 2>/dev/null | grep -q "qwen3-coder-abliterated:30b"; then
    echo "✅ Modelo qwen3-coder-abliterated:30b encontrado"
else
    echo "⚠️  Modelo não encontrado. Baixe com:"
    echo "   OLLAMA_MODELS=$KALI_SAFE/models ollama pull huihui_ai/qwen3-coder-abliterated:30b"
fi

# 8. Restart Ollama
echo ""
read -p "Reiniciar Ollama agora? [Y/n] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    sudo systemctl restart ollama
    sleep 2
    if curl -sf --connect-timeout 3 http://127.0.0.1:11434/api/tags &>/dev/null; then
        echo "✅ Ollama rodando"
    else
        echo "⚠️  Ollama iniciando... aguarde alguns segundos"
    fi
fi

echo ""
echo "═══════════════════════════════════════════════"
echo "  ✅ Instalação completa!"
echo ""
echo "  Teste: gpu stats"
echo "  Teste: gpu ask \"hello world\""
echo "═══════════════════════════════════════════════"
