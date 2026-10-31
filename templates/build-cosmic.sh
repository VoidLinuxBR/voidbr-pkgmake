#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
#  build-cosmic.sh - compila as receitas do COSMIC (voidbr-pkgmake/templates)
#                    na sequência de dependência, usando pkgmake -s
#
#  Uso: build-cosmic.sh [opções]
#    -C, --dir <dir>      diretório templates/ (padrão: ./templates ou .)
#    -f, --from <pacote>  recomeça a partir deste pacote
#    -k, --keep-going     não para no primeiro erro
#    -l, --list           só lista a sequência e sai
#    -h, --help           mostra esta ajuda
#
#  Variáveis: PKGMAKE (padrão: pkgmake), LOGDIR (padrão: /tmp/logs-cosmic),
#             NO_COLOR=1 desliga as cores
#
#  Copyright (c) 2026, Vilmar Catafesta <vcatafesta@gmail.com>
#  Copyright (c) 2026, VoidLinuxBR Team
#  Licença: MIT

set -uo pipefail

# cores (minúsculas); desligue com NO_COLOR=1
if [[ -z "${NO_COLOR:-}" ]]; then
	reset="\033[0m"
	bold="\033[1m"
	red="\033[1;31m"
	green="\033[1;32m"
	yellow="\033[1;33m"
	blue="\033[1;34m"
	magenta="\033[1;35m"
	cyan="\033[1;36m"
	white="\033[1;37m"
	gray="\033[0;90m"
else
	reset="" bold="" red="" green="" yellow="" blue="" magenta="" cyan="" white="" gray=""
fi

# sequência por nível: dentro do nível a ordem não importa
packages=(
	# nível 0
	pop-icon-theme
	cosmic-comp
	cosmic-idle
	cosmic-monitor
	cosmic-osd
	cosmic-osk
	cosmic-panel
	cosmic-player
	cosmic-randr
	cosmic-sound-theme
	cosmic-viewer
	cosmic-wallpapers
	# nível 1
	cosmic-icon-theme
	cosmic-settings-daemon
	pop-launcher
	# nível 2
	cosmic-app-library
	cosmic-applets
	cosmic-bg
	cosmic-files
	cosmic-greeter
	cosmic-initial-setup
	cosmic-launcher
	cosmic-notifications
	cosmic-settings
	cosmic-store
	cosmic-terminal
	cosmic-text-editor
	cosmic-workspaces
	xdg-desktop-portal-cosmic
	# nível 3
	cosmic-screenshot
	# nível 4
	cosmic-session
)

PKGMAKE="${PKGMAKE:-pkgmake}"
LOGDIR="${LOGDIR:-/tmp/logs-cosmic}"
dir=""
from=""
keep_going=false
list_only=false

msg() { echo -e "${blue}==>${reset} ${cyan}$*${reset}"; }
ok() { echo -e "${green}[ OK ]${reset} $*"; }
fail() { echo -e "${red}[ERRO]${reset} $*"; }
die() { fail "$*"; exit 1; }

usage() {
	local me="${0##*/}"
	echo -e "${white}${me}${reset} - compila as receitas do ${cyan}COSMIC${reset} (voidbr-pkgmake/templates)"
	echo -e "  na sequência de dependência, usando ${green}pkgmake -s${reset}"
	echo
	echo -e "${yellow}Uso:${reset} ${white}${me}${reset} ${gray}[opções]${reset}"
	echo
	echo -e "${yellow}Opções:${reset}"
	echo -e "  ${green}-C${reset}, ${green}--dir${reset} ${cyan}<dir>${reset}      diretório templates/ ${gray}(padrão: ./templates ou .)${reset}"
	echo -e "  ${green}-f${reset}, ${green}--from${reset} ${cyan}<pacote>${reset}  recomeça a partir deste pacote"
	echo -e "  ${green}-k${reset}, ${green}--keep-going${reset}     não para no primeiro erro"
	echo -e "  ${green}-l${reset}, ${green}--list${reset}           só lista a sequência e sai"
	echo -e "  ${green}-h${reset}, ${green}--help${reset}           mostra esta ajuda"
	echo
	echo -e "${yellow}Variáveis:${reset}"
	echo -e "  ${magenta}PKGMAKE${reset}   comando de build ${gray}(padrão: pkgmake)${reset}"
	echo -e "  ${magenta}LOGDIR${reset}    diretório dos logs ${gray}(padrão: /tmp/logs-cosmic)${reset}"
	echo -e "  ${magenta}NO_COLOR${reset}  ${cyan}1${reset} desliga as cores"
	echo
	echo -e "${yellow}Exemplos:${reset}"
	echo -e "  ${white}${me}${reset}                         ${gray}# compila os 31 na sequência${reset}"
	echo -e "  ${white}${me}${reset} ${green}-l${reset}                      ${gray}# só lista a sequência${reset}"
	echo -e "  ${white}${me}${reset} ${green}--from${reset} ${cyan}cosmic-greeter${reset}   ${gray}# recomeça a partir de um pacote${reset}"
	echo -e "  ${magenta}PKGMAKE${reset}=${cyan}makepkg${reset} ${white}${me}${reset} ${green}-k${reset}       ${gray}# usa makepkg e não para no erro${reset}"
	exit 0
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	-C | --dir) dir="${2:-}"; shift 2 ;;
	-f | --from) from="${2:-}"; shift 2 ;;
	-k | --keep-going) keep_going=true; shift ;;
	-l | --list) list_only=true; shift ;;
	-h | --help) usage ;;
	*) die "opção inválida: $1" ;;
	esac
done

if $list_only; then
	n=0
	for p in "${packages[@]}"; do
		printf "${gray}%2d${reset}  ${yellow}%s${reset}\n" "$((++n))" "$p"
	done
	exit 0
fi

# localiza templates/
if [[ -z "$dir" ]]; then
	if [[ -d templates/cosmic-session ]]; then
		dir="templates"
	elif [[ -d cosmic-session ]]; then
		dir="."
	else
		die "templates/ não encontrado; use -C <dir>"
	fi
fi
dir="$(readlink -f "$dir")"

command -v "$PKGMAKE" >/dev/null 2>&1 || die "$PKGMAKE não encontrado"
[[ "$(id -u)" -eq 0 ]] && die "rode como usuário comum (o pkgmake usa sudo só para os makedepends)"

# confere se todas as receitas existem antes de começar
for p in "${packages[@]}"; do
	[[ -f "$dir/$p/PKGFILE" ]] || die "receita não encontrada: $dir/$p/PKGFILE"
done

# --from: pula até o pacote indicado
if [[ -n "$from" ]]; then
	found=false
	for i in "${!packages[@]}"; do
		if [[ "${packages[$i]}" == "$from" ]]; then
			packages=("${packages[@]:$i}")
			found=true
			break
		fi
	done
	$found || die "pacote não está na sequência: $from"
fi

mkdir -p "$LOGDIR" || die "não foi possível criar $LOGDIR"

total=${#packages[@]}
done_ok=()
done_fail=()
n=0
start_all=$SECONDS

for p in "${packages[@]}"; do
	((n++))
	log="$LOGDIR/$p.log"
	msg "${white}[$n/$total]${reset} ${yellow}$p${reset} ${gray}(log: $log)${reset}"
	start=$SECONDS

	if (cd "$dir/$p" && "$PKGMAKE" -s) >"$log" 2>&1; then
		ok "${bold}$p${reset} ${gray}($((SECONDS - start))s)${reset}"
		done_ok+=("$p")
	else
		fail "${bold}$p${reset} ${gray}($((SECONDS - start))s)${reset} — últimas linhas de ${yellow}$log${reset}:"
		tail -n 15 "$log" | sed "s/^/    $(printf '%b' "$magenta")│$(printf '%b' "$reset") /"
		done_fail+=("$p")
		if ! $keep_going; then
			echo
			msg "Parado em ${yellow}$p${cyan}. Para continuar depois da correção:"
			echo -e "    ${green}$0 -C $dir --from $p${reset}"
			break
		fi
	fi
done

echo
msg "${white}Resumo${reset} ${gray}($(((SECONDS - start_all) / 60))min)${reset}"
echo -e "  ${green}compilados:${reset} ${bold}${#done_ok[@]}${reset}/$total"
((${#done_fail[@]})) && echo -e "  ${red}falharam:${reset}   ${yellow}${done_fail[*]}${reset}"
echo -e "  ${cyan}logs em:${reset}    $LOGDIR"

((${#done_fail[@]} == 0))
