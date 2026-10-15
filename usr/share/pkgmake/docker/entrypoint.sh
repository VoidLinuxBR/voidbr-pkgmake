#!/bin/sh
# entrypoint do container pkgmake-docker (roda como root e repassa para o usuário builder)
set -e

uid="${PKGMAKE_UID:-1000}"
gid="${PKGMAKE_GID:-1000}"

# mesmo uid/gid do host: src/, pkg/ e os .xbps ficam com o dono certo
[ "$(id -g builder)" = "$gid" ] || groupmod -o -g "$gid" builder
[ "$(id -u builder)" = "$uid" ] || usermod -o -u "$uid" builder
chown builder:builder /home/builder

# repositório local montado em /repo: resolve dependências locais (ex.: bun-bin)
if ls /repo/*-repodata >/dev/null 2>&1; then
	echo "repository=/repo" >/etc/xbps.d/00-pkgmake-local.conf
fi

# sincroniza os índices e aceita a chave pública do repositório local, se houver
yes | xbps-install -S >/dev/null 2>&1 || true

exec sudo -H -u builder -- pkgmake "$@"
