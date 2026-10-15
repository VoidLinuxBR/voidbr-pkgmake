# Imagem de build do pkgmake: Void Linux limpo com as ferramentas básicas.
# O pkgmake em si NÃO entra na imagem: o pkgmake-docker monta o do host
# (somente leitura), então o container usa sempre a mesma versão que você tem.
FROM ghcr.io/void-linux/void-glibc-full:latest

RUN xbps-install -Syu xbps \
	&& xbps-install -Syu \
	&& xbps-install -y base-devel bash git curl wget unzip fakeroot shfmt sudo shadow xz zstd ncurses \
	&& xbps-remove -Oy

# usuário de build (uid/gid ajustados no entrypoint para os do host)
RUN useradd -m -s /bin/bash builder \
	&& echo 'builder ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/builder \
	&& chmod 440 /etc/sudoers.d/builder

COPY pkgmake.conf /etc/pkgmake.conf
COPY entrypoint.sh /usr/local/bin/pkgmake-entrypoint
RUN chmod 755 /usr/local/bin/pkgmake-entrypoint

WORKDIR /build
ENTRYPOINT ["/usr/local/bin/pkgmake-entrypoint"]
