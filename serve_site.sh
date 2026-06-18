#!/bin/bash
# ============================================================
# AMSI Raccoon Lab - Local Website Preview (Linux/macOS)
# ============================================================
# Starts a local Jekyll development server to preview the
# GitHub Pages site before pushing.
#
# Usage:
#   chmod +x serve_site.sh
#   ./serve_site.sh
#
# Options:
#   --install    Install Ruby/Jekyll dependencies first
#   --port PORT  Use a custom port (default: 4000)
# ============================================================

set -e

PORT=4000
INSTALL=false

# Parse arguments
for arg in "$@"; do
  case $arg in
    --install)
      INSTALL=true
      shift
      ;;
    --port)
      PORT="$2"
      shift 2
      ;;
    --port=*)
      PORT="${arg#*=}"
      shift
      ;;
    --help|-h)
      echo "Usage: ./serve_site.sh [--install] [--port PORT]"
      echo ""
      echo "Options:"
      echo "  --install    Install dependencies (Ruby gems)"
      echo "  --port PORT  Custom port (default: 4000)"
      echo "  --help       Show this help"
      exit 0
      ;;
  esac
done

echo "============================================"
echo "  AMSI Raccoon Lab - Local Site Preview"
echo "============================================"
echo ""

# Check Ruby
if ! command -v ruby &> /dev/null; then
  echo "[ERROR] Ruby is not installed."
  echo ""
  echo "Install Ruby:"
  echo "  Ubuntu/Debian:  sudo apt install ruby-full build-essential"
  echo "  Fedora:         sudo dnf install ruby ruby-devel"
  echo "  macOS:          brew install ruby"
  echo "  Arch:           sudo pacman -S ruby"
  echo ""
  exit 1
fi

echo "[OK] Ruby $(ruby --version | cut -d' ' -f2) found"

# Check Bundler
if ! command -v bundle &> /dev/null; then
  echo "[!] Bundler not found. Installing..."
  gem install bundler
fi

echo "[OK] Bundler $(bundle --version | cut -d' ' -f3) found"

# Install dependencies
if [ "$INSTALL" = true ] || [ ! -d "vendor/bundle" ]; then
  echo ""
  echo "[*] Installing dependencies..."
  bundle config set --local path 'vendor/bundle'
  bundle install
  echo "[OK] Dependencies installed"
fi

echo ""
echo "--------------------------------------------"
echo "  Starting Jekyll development server..."
echo "  URL: http://localhost:${PORT}/MostShittyAV/"
echo "  Press Ctrl+C to stop"
echo "--------------------------------------------"
echo ""

# Serve the site
bundle exec jekyll serve \
  --port "$PORT" \
  --livereload \
  --open-url \
  --baseurl "/MostShittyAV" \
  2>&1
