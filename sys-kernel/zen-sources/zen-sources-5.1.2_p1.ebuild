# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

K_PREPATCHED="yes"
UNIPATCH_STRICTORDER="yes"
K_SECURITY_UNSUPPORTED="1"
K_DEBLOB_AVAILABLE=0
CKV="${PV}"

ETYPE="sources"

# v5.1.2-zen1 
EGIT_COMMIT="v${PV/_p/-zen}"
EGIT_REPO_URI="https://github.com/zen-kernel/zen-kernel.git"

inherit kernel-2 git-r3
detect_version

K_NOSETEXTRAVERSION="don't_set_it"
DESCRIPTION="The Zen Kernel Live Sources"
HOMEPAGE="https://zen-kernel.org"

IUSE=""
KEYWORDS="~amd64"

K_EXTRAEINFO="For more info on zen-sources, and for how to report problems, see: \
${HOMEPAGE}, also go to #zen-sources on freenode"

S="${WORKDIR}/${P}"

src_install() {
	cd "${WORKDIR}"
	dodir /usr/src
	echo ">>> Copying sources ..."

	mv "${S}" "${ED}"usr/src/linux-${PV/_p/-zen} || die
}
