PREFIX ?= /usr
ETCDIR ?= /etc
BINDIR   = $(PREFIX)/bin
SHAREDIR = $(PREFIX)/share/pkgmake
DOCDIR   = $(PREFIX)/share/doc/pkgmake
COMPDIR  = $(PREFIX)/share/bash-completion/completions

# mesmas dependências do pacote voidbr-pkgmake (pkgfile/PKGFILE)
DEPENDS = base-devel bash curl git xbps xbps-triggers coreutils ncurses ncurses-devel cmake docker docker-buildx jq shfmt

SHELL := /bin/bash
.ONESHELL:

all:
	@echo "Nada a compilar. Use: sudo make install"

install: deps files conf post-install

# dependências (só no sistema real; com DESTDIR é empacotamento, não instala nada)
deps:
	@if [ -n "$(DESTDIR)" ]; then exit 0; fi
	if ! command -v xbps-install >/dev/null 2>&1; then
		echo "==> aviso: xbps-install não encontrado; instale as dependências manualmente: $(DEPENDS)"
		exit 0
	fi
	missing=""
	for d in $(DEPENDS); do
		xbps-query "$$d" >/dev/null 2>&1 && continue
		# fornecido por outro pacote (provides), ex.: xbps do VoidBR
		LC_ALL=C xbps-install -n "$$d" 2>&1 | grep -q "already installed" && continue
		missing="$$missing $$d"
	done
	if [ -n "$$missing" ]; then
		echo "==> Instalando dependências:$$missing"
		xbps-install -Sy $$missing
	fi

# arquivos (igual ao package() do PKGFILE: copia a árvore usr/)
files:
	@install -d $(DESTDIR)$(BINDIR) $(DESTDIR)$(SHAREDIR)/docker $(DESTDIR)$(DOCDIR) $(DESTDIR)$(COMPDIR)
	install -m 755 usr/bin/pkgmake usr/bin/makepkg usr/bin/pkgmake-docker usr/bin/makepkg-docker $(DESTDIR)$(BINDIR)
	install -m 644 usr/share/pkgmake/*.sh usr/share/pkgmake/pkgnames.map $(DESTDIR)$(SHAREDIR)
	install -m 644 usr/share/pkgmake/docker/Dockerfile usr/share/pkgmake/docker/entrypoint.sh $(DESTDIR)$(SHAREDIR)/docker
	install -m 644 usr/share/bash-completion/completions/pkgmake $(DESTDIR)$(COMPDIR)/pkgmake
	install -m 644 README.md $(DESTDIR)$(DOCDIR)/README.md
	echo "==> Arquivos instalados em $(DESTDIR)$(PREFIX)"

# configuração: nunca sobrescreve a do usuário (igual ao backup= do PKGFILE)
conf:
	@install -d $(DESTDIR)$(ETCDIR)
	if [ -f $(DESTDIR)$(ETCDIR)/pkgmake.conf ]; then
		install -m 644 etc/pkgmake.conf $(DESTDIR)$(ETCDIR)/pkgmake.conf.new
		echo "==> $(ETCDIR)/pkgmake.conf existente mantido; modelo novo em $(ETCDIR)/pkgmake.conf.new"
	else
		install -m 644 etc/pkgmake.conf $(DESTDIR)$(ETCDIR)/pkgmake.conf
		echo "==> $(ETCDIR)/pkgmake.conf instalado: ajuste PKGDEST e PACKAGER"
	fi

# grupo e serviço do docker (igual ao post_install do PKGFILE)
post-install:
	@if [ -n "$(DESTDIR)" ]; then exit 0; fi
	user="$${SUDO_USER:-}"
	if [ -z "$$user" ] || [ "$$user" = root ]; then
		user="$$(getent passwd 1000 | cut -d: -f1)"
	fi
	getent group docker >/dev/null 2>&1 || groupadd -r docker
	if [ -n "$$user" ]; then
		if id -nG "$$user" | grep -qw docker; then
			echo "==> usuário '$$user' já está no grupo docker"
		else
			usermod -aG docker "$$user"
			echo "==> usuário '$$user' adicionado ao grupo docker (saia e entre de novo na sessão, ou rode: newgrp docker)"
		fi
	fi
	if [ "$$(stat -c %d:%i /)" != "$$(stat -c %d:%i /proc/1/root/. 2>/dev/null)" ]; then
		echo "==> chroot detectado: ative o docker depois com: vservice add docker"
	elif sv status docker 2>/dev/null | grep -q '^run:'; then
		echo "==> serviço docker ativo"
	elif [ -t 0 ]; then
		read -r -p "Serviço docker não está ativo. Ativar e subir agora? [S/n] " resp || resp=n
		case "$$resp" in
		"" | [SsYy]*)
			if command -v vservice >/dev/null 2>&1; then
				vservice add docker
			else
				ln -sf /etc/sv/docker /var/service/
			fi
			sleep 2
			if sv status docker 2>/dev/null | grep -q '^run:'; then
				echo "==> serviço docker ativo"
			else
				echo "==> serviço docker não subiu; verifique com: sv status docker"
			fi
			;;
		*)
			echo "==> serviço docker não ativado; para ativar: vservice add docker"
			;;
		esac
	else
		echo "==> serviço docker não está ativo; para ativar: vservice add docker"
	fi

# remove os arquivos, mas mantém o /etc/pkgmake.conf do usuário
uninstall:
	@rm -f $(DESTDIR)$(BINDIR)/pkgmake $(DESTDIR)$(BINDIR)/makepkg
	rm -f $(DESTDIR)$(BINDIR)/pkgmake-docker $(DESTDIR)$(BINDIR)/makepkg-docker
	rm -f $(DESTDIR)$(COMPDIR)/pkgmake
	rm -rf $(DESTDIR)$(SHAREDIR) $(DESTDIR)$(DOCDIR)
	rm -f $(DESTDIR)$(ETCDIR)/pkgmake.conf.new
	echo "==> pkgmake removido ($(ETCDIR)/pkgmake.conf mantido)"

.PHONY: all install deps files conf post-install uninstall
