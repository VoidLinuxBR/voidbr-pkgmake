#!/usr/bin/env bash
set -e

# pkgmake installer
# Instalação direta via GitHub (wget ou curl), igual ao "make install"
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/voidlinuxbr/voidbr-pkgmake/main/install.sh | sudo bash
#   wget -qO-  https://raw.githubusercontent.com/voidlinuxbr/voidbr-pkgmake/main/install.sh | sudo bash

TARBALL_URL="https://github.com/voidlinuxbr/voidbr-pkgmake/archive/refs/heads/main.tar.gz"

TMPDIR="$(mktemp -d)"

die() {
	echo "erro: $*" >&2
	exit 1
}

info() {
	echo "==> $*"
}

cleanup() {
	rm -rf "$TMPDIR"
}
trap cleanup EXIT

if [[ $EUID -ne 0 ]]; then
	die "execute este instalador como root (sudo)"
fi

command -v tar >/dev/null 2>&1 || die "comando 'tar' não encontrado"

# Downloader
if command -v curl >/dev/null 2>&1; then
	DL="curl -fsSL"
elif command -v wget >/dev/null 2>&1; then
	DL="wget -qO-"
else
	die "necessário 'curl' ou 'wget' para download"
fi

# make: o instalador usa o Makefile do repositório
if ! command -v make >/dev/null 2>&1; then
	command -v xbps-install >/dev/null 2>&1 || die "comando 'make' não encontrado"
	info "Instalando make..."
	xbps-install -Sy make
fi

info "Baixando voidbr-pkgmake do GitHub..."
$DL "$TARBALL_URL" | tar -xz -C "$TMPDIR" || die "falha ao baixar/extrair $TARBALL_URL"

SRC="$(find "$TMPDIR" -mindepth 1 -maxdepth 1 -type d | head -n1)"
[[ -f "$SRC/Makefile" ]] || die "Makefile não encontrado no pacote baixado"

info "Instalando (make install)..."
# no "curl | sudo bash" o stdin é o próprio script: perguntas leem do terminal
if [[ -r /dev/tty ]] && { : </dev/tty; } 2>/dev/null; then
	make -C "$SRC" install </dev/tty
else
	make -C "$SRC" install </dev/null
fi

info "Instalação concluída com sucesso."
info "Execute 'pkgmake --help' para começar."
