# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit bash-completion-r1

DESCRIPTION="A simple TTY terminal application which features a simple commandline interface."
HOMEPAGE="https://tio.github.io"
SRC_URI="https://github.com/tio/tio/releases/download/v${PV}/${P}.tar.xz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64 ~x86"

src_configure() {
	econf \
	--with-bash-completion-dir="$(get_bashcompdir)"
}

src_install() {
	default

	newbashcomp contrib/${PN}.bash-completion ${PN}
}
