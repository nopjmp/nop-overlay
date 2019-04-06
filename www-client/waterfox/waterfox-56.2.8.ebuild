# Copyright 1999-2017 Gentoo Foundation
# Copyright 2018 nopjmp
# Distributed under the terms of the GNU General Public License v2

# TODO: system-harfbuzz and friends may or may not work and needed fixing

EAPI=6
WANT_AUTOCONF="2.1"
MOZ_ESR=""

# This list can be updated with scripts/get_langs.sh from the mozilla overlay
MOZ_LANGS=( ach af an ar as ast az bg bn-BD bn-IN br bs ca cak cs cy da de dsb
el en en-GB en-US en-ZA eo es-AR es-CL es-ES es-MX et eu fa ff fi fr fy-NL ga-IE
gd gl gn gu-IN he hi-IN hr hsb hu hy-AM id is it ja ka kab kk km kn ko lij lt lv
mai mk ml mr ms nb-NO nl nn-NO or pa-IN pl pt-BR pt-PT rm ro ru si sk sl son sq
sr sv-SE ta te th tr uk uz vi xh zh-CN zh-TW )

# Patch version
MOZ_HTTP_URI="https://archive.mozilla.org/pub/${PN}/releases"

MOZCONFIG_OPTIONAL_WIFI=1

inherit check-reqs flag-o-matic toolchain-funcs eutils gnome2-utils mozcoreconf-v5 pax-utils xdg-utils autotools virtualx mozlinguas-v2

DESCRIPTION="Waterfox Web Browser"
HOMEPAGE="http://www.waterfoxproject.org/"

KEYWORDS="~amd64 ~x86"

SLOT="0"
LICENSE="MPL-2.0 GPL-2 LGPL-2.1"
IUSE="+clang eme-free +gmp-autoupdate hardened hwaccel jack nsplugin selinux test dbus debug neon pulseaudio selinux startup-notification system-harfbuzz system-icu system-jpeg system-libevent system-sqlite system-libvpx"

SRC_URI="https://github.com/MrAlex94/Waterfox/archive/${PV}.tar.gz"

ASM_DEPEND=">=dev-lang/yasm-1.1"

# some notes on deps:
# gtk:2 minimum is technically 2.10 but gio support (enabled by default) needs 2.14
# media-libs/mesa needs to be 10.2 or above due to a bug with flash+vdpau

RDEPEND=">=app-text/hunspell-1.5.4:=
	dev-libs/atk
	dev-libs/expat
	>=x11-libs/cairo-1.10[X]
	>=x11-libs/gtk+-2.18:2
	x11-libs/gdk-pixbuf
	>=x11-libs/pango-1.22.0
	>=media-libs/libpng-1.6.31:0=[apng]
	>=media-libs/mesa-10.2:*
	media-libs/fontconfig
	>=media-libs/freetype-2.4.10
	kernel_linux? ( !pulseaudio? ( media-libs/alsa-lib ) )
	pulseaudio? ( || ( media-sound/pulseaudio
		>=media-sound/apulse-0.1.9 ) )
	virtual/freedesktop-icon-theme
	dbus? ( >=sys-apps/dbus-0.60
		>=dev-libs/dbus-glib-0.72 )
	startup-notification? ( >=x11-libs/startup-notification-0.8 )
	>=x11-libs/pixman-0.19.2
	>=dev-libs/glib-2.26:2
	>=sys-libs/zlib-1.2.3
	>=virtual/libffi-3.0.10
	>=dev-libs/nss-3.32
	>=dev-libs/nspr-4.16
	sys-devel/llvm
	clang? ( sys-devel/clang )
	app-arch/zip
	app-arch/unzip
	virtual/ffmpeg
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrender
	x11-libs/libXt
	system-icu? ( >=dev-libs/icu-59.1:= )
	system-jpeg? ( >=media-libs/libjpeg-turbo-1.2.1 )
	system-libevent? ( >=dev-libs/libevent-2.0:0= )
	system-sqlite? ( >=dev-db/sqlite-3.19.3:3[secure-delete,debug=] )
	system-libvpx? ( >=media-libs/libvpx-1.5.0:0=[postproc] )
	system-harfbuzz? ( >=media-libs/harfbuzz-1.3.3:0= >=media-gfx/graphite2-1.3.9-r1 )
	pulseaudio? ( || ( media-sound/pulseaudio
		>=media-sound/apulse-0.1.9 ) )
	jack? ( virtual/jack )
	selinux? ( sec-policy/selinux-mozilla )"

if [[ -n ${MOZCONFIG_OPTIONAL_GTK3} ]]; then
	MOZCONFIG_OPTIONAL_GTK2ONLY=
	if [[ ${MOZCONFIG_OPTIONAL_GTK3} = "enabled" ]]; then
		IUSE+=" +force-gtk3"
	else
		IUSE+=" force-gtk3"
	fi
	RDEPEND+=" force-gtk3? ( >=x11-libs/gtk+-3.4.0:3 )"
elif [[ -n ${MOZCONFIG_OPTIONAL_GTK2ONLY} ]]; then
	if [[ ${MOZCONFIG_OPTIONAL_GTK2ONLY} = "enabled" ]]; then
		IUSE+=" +gtk2"
	else
		IUSE+=" gtk2"
	fi
	RDEPEND+=" !gtk2? ( >=x11-libs/gtk+-3.4.0:3 )"
else
	# no gtk3 related dep set by optional use flags, force it
	RDEPEND+="  >=x11-libs/gtk+-3.4.0:3"
fi
if [[ -n ${MOZCONFIG_OPTIONAL_WIFI} ]]; then
	if [[ ${MOZCONFIG_OPTIONAL_WIFI} = "enabled" ]]; then
		IUSE+=" +wifi"
	else
		IUSE+=" wifi"
	fi
	RDEPEND+="
	wifi? (
		kernel_linux? ( >=sys-apps/dbus-0.60
			>=dev-libs/dbus-glib-0.72
			net-misc/networkmanager )
	)"
fi

DEPEND="${RDEPEND}
	>=sys-devel/binutils-2.16.1
	sys-apps/findutils
	>=virtual/rust-1.17.1
	amd64? ( ${ASM_DEPEND} virtual/opengl )
	x86? ( ${ASM_DEPEND} virtual/opengl )"
	#>=dev-util/cargo-0.17.1

S="${WORKDIR}/Waterfox-${MOZ_PV}"

QA_PRESTRIPPED="usr/lib*/${PN}/waterfox"

BUILD_OBJ_DIR="${S}/ff"

# allow GMP_PLUGIN_LIST to be set in an eclass or
# overridden in the enviromnent (advanced hackers only)
if [[ -z $GMP_PLUGIN_LIST ]]; then
	GMP_PLUGIN_LIST=( gmp-gmpopenh264 gmp-widevinecdm )
fi

pkg_setup() {
	moz_pkgsetup

	# Avoid PGO profiling problems due to enviroment leakage
	# These should *always* be cleaned up anyway
	unset DBUS_SESSION_BUS_ADDRESS \
		DISPLAY \
		ORBIT_SOCKETDIR \
		SESSION_MANAGER \
		XDG_SESSION_COOKIE \
		XAUTHORITY

}

pkg_pretend() {
	# Ensure we have enough disk space to compile
	if use debug || use test ; then
		CHECKREQS_DISK_BUILD="8G"
	else
		CHECKREQS_DISK_BUILD="4G"
	fi
	check-reqs_pkg_setup
}

src_unpack() {
	unpack ${A}

	# Unpack language packs
	mozlinguas_src_unpack
}

src_prepare() {
	eapply "${FILESDIR}/gentoo"

	# Enable gnomebreakpad
	if use debug ; then
		sed -i -e "s:GNOME_DISABLE_CRASH_DIALOG=1:GNOME_DISABLE_CRASH_DIALOG=0:g" \
			"${S}"/build/unix/run-mozilla.sh || die "sed failed!"
	fi

	# Drop -Wl,--as-needed related manipulation for ia64 as it causes ld sefgaults, bug #582432
	if use ia64 ; then
		sed -i \
		-e '/^OS_LIBS += no_as_needed/d' \
		-e '/^OS_LIBS += as_needed/d' \
		"${S}"/widget/gtk/mozgtk/gtk2/moz.build \
		"${S}"/widget/gtk/mozgtk/gtk3/moz.build \
		|| die "sed failed to drop --as-needed for ia64"
	fi

	# Ensure that our plugins dir is enabled as default
	sed -i -e "s:/usr/lib/mozilla/plugins:/usr/lib/nsbrowser/plugins:" \
		"${S}"/xpcom/io/nsAppFileLocationProvider.cpp || die "sed failed to replace plugin path for 32bit!"
	sed -i -e "s:/usr/lib64/mozilla/plugins:/usr/lib64/nsbrowser/plugins:" \
		"${S}"/xpcom/io/nsAppFileLocationProvider.cpp || die "sed failed to replace plugin path for 64bit!"

	# Fix sandbox violations during make clean, bug 372817
	sed -e "s:\(/no-such-file\):${T}\1:g" \
		-i "${S}"/config/rules.mk \
		-i "${S}"/nsprpub/configure{.in,} \
		|| die

	# Don't exit with error when some libs are missing which we have in
	# system.
	sed '/^MOZ_PKG_FATAL_WARNINGS/s@= 1@= 0@' \
		-i "${S}"/browser/installer/Makefile.in || die

	# Don't error out when there's no files to be removed:
	sed 's@\(xargs rm\)$@\1 -f@' \
		-i "${S}"/toolkit/mozapps/installer/packager.mk || die

	# Allow user to apply any additional patches without modifing ebuild
	eapply_user

	# Autotools configure is now called old-configure.in
	# This works because there is still a configure.in that happens to be for the
	# shell wrapper configure script
	eautoreconf old-configure.in

	# Must run autoconf in js/src
	cd "${S}"/js/src || die
	eautoconf old-configure.in
}

src_configure() {
	MEXTENSIONS="default"

	####################################
	#
	# mozconfig, CFLAGS and CXXFLAGS setup
	#
	####################################

	# Waterfox includes it's own config. Remove it
	rm "${S}"/.mozconfig

	mozconfig_init

	# Migrated from mozcoreconf-2
	mozconfig_annotate 'system_libs' \
		--with-system-zlib \
		--with-system-bz2

	# Must pass release in order to properly select linker via gold useflag
	mozconfig_annotate 'Enable by Waterfox' --enable-release

	# Must pass --enable-gold if using ld.gold
	if tc-ld-is-gold ; then
		mozconfig_annotate 'tc-ld-is-gold=true' --enable-gold
	else
		mozconfig_annotate 'tc-ld-is-gold=false' --disable-gold
	fi

	# Waterfox branding
	mozconfig_annotate '' --with-app-name=waterfox
	mozconfig_annotate '' --with-app-basename=Waterfox
	mozconfig_annotate '' --with-branding=browser/branding/unofficial
	mozconfig_annotate '' --with-distribution-id=org.waterfoxproject

	# Enable position independent executables
	mozconfig_annotate 'enabled by Gentoo' --enable-pie
	mozconfig_use_enable debug
	mozconfig_use_enable debug tests

	if ! use debug ; then
		mozconfig_annotate 'disabled by Gentoo' --disable-debug-symbols
	else
		mozconfig_annotate 'enabled by Gentoo' --enable-debug-symbols
	fi

	mozconfig_use_enable startup-notification

	if [[ -n ${MOZCONFIG_OPTIONAL_WIFI} ]] ; then
		# wifi pulls in dbus so manage both here
		mozconfig_use_enable wifi necko-wifi
		if use kernel_linux && use wifi && ! use dbus; then
			echo "Enabling dbus support due to wifi request"
			mozconfig_annotate 'dbus required by necko-wifi on linux' --enable-dbus
		else
			mozconfig_use_enable dbus
		fi
	else
		mozconfig_use_enable dbus
		mozconfig_annotate 'disabled' --disable-necko-wifi
	fi

	if [[ -n ${MOZCONFIG_OPTIONAL_JIT} ]]; then
		mozconfig_use_enable jit ion
	fi

	# These are enabled by default in all mozilla applications
	mozconfig_annotate '' --with-system-nspr --with-nspr-prefix="${SYSROOT}${EPREFIX}"/usr
	mozconfig_annotate '' --with-system-nss --with-nss-prefix="${SYSROOT}${EPREFIX}"/usr
	mozconfig_annotate '' --x-includes="${SYSROOT}${EPREFIX}"/usr/include --x-libraries="${SYSROOT}${EPREFIX}"/usr/$(get_libdir)
	if use system-libevent; then
		mozconfig_annotate '' --with-system-libevent="${SYSROOT}${EPREFIX}"/usr
	fi
	mozconfig_annotate '' --prefix="${EPREFIX}"/usr
	mozconfig_annotate '' --libdir="${EPREFIX}"/usr/$(get_libdir)
	mozconfig_annotate 'Gentoo default' --enable-system-hunspell
	mozconfig_annotate '' --disable-crashreporter
	mozconfig_annotate 'Gentoo default' --with-system-png
	mozconfig_annotate '' --enable-system-ffi
	mozconfig_annotate '' --disable-gconf
	mozconfig_annotate '' --with-intl-api

	# default toolkit is cairo-gtk3, optional use flags can change this
	local toolkit="cairo-gtk3"
	local toolkit_comment=""
	if [[ -n ${MOZCONFIG_OPTIONAL_GTK3} ]]; then
		if ! use force-gtk3; then
			toolkit="cairo-gtk2"
			toolkit_comment="force-gtk3 use flag"
		fi
	fi
	if [[ -n ${MOZCONFIG_OPTIONAL_GTK2ONLY} ]]; then
		if use gtk2 ; then
			toolkit="cairo-gtk2"
		else
			toolkit_comment="gtk2 use flag"
		fi
	fi
	if [[ -n ${MOZCONFIG_OPTIONAL_QT5} ]]; then
		if use qt5; then
			toolkit="cairo-qt"
			toolkit_comment="qt5 use flag"
			# need to specify these vars because the qt5 versions are not found otherwise,
			# and setting --with-qtdir overrides the pkg-config include dirs
			local i
			for i in qmake moc rcc; do
				echo "export HOST_${i^^}=\"$(qt5_get_bindir)/${i}\"" \
					>> "${S}"/.mozconfig || die
			done
			echo 'unset QTDIR' >> "${S}"/.mozconfig || die
			mozconfig_annotate '+qt5' --disable-gio
		fi
	fi
	mozconfig_annotate "${toolkit_comment}" --enable-default-toolkit=${toolkit}

	# Instead of the standard --build= and --host=, mozilla uses --host instead
	# of --build, and --target intstead of --host.
	# Note, mozilla also has --build but it does not do what you think it does.
	# Set both --target and --host as mozilla uses python to guess values otherwise
	mozconfig_annotate '' --target="${CHOST}"
	mozconfig_annotate '' --host="${CBUILD:-${CHOST}}"

	mozconfig_use_enable pulseaudio
	# force the deprecated alsa sound code if pulseaudio is disabled
	if use kernel_linux && ! use pulseaudio ; then
		mozconfig_annotate '-pulseaudio' --enable-alsa
	fi

	# For testing purpose only
	mozconfig_annotate 'Sandbox' --enable-content-sandbox

	mozconfig_use_enable system-sqlite
	mozconfig_use_with system-jpeg
	mozconfig_use_with system-icu
	mozconfig_use_with system-libvpx
	#mozconfig_use_with system-harfbuzz
	#mozconfig_use_with system-harfbuzz system-graphite2

	# enable JACK, bug 600002
	mozconfig_use_enable jack

	use eme-free && mozconfig_annotate '+eme-free' --disable-eme

	# Add full relro support for hardened
	if use hardened; then
		append-ldflags "-Wl,-z,relro,-z,now"
		mozconfig_use_enable hardened hardening
	fi

	# Only available on mozilla-overlay for experimentation -- Removed in Gentoo repo per bug 571180
	#use egl && mozconfig_annotate 'Enable EGL as GL provider' --with-gl-provider=EGL

	mozconfig_annotate '' --enable-extensions="${MEXTENSIONS}"

	# Waterfox specific
	mozconfig_annotate "Disable crashreporter" --disable-crashreporter
	mozconfig_annotate "Disable js shell" --disable-js-shell
	mozconfig_annotate "Disable maintenance service" --disable-maintenance-service
	mozconfig_annotate "Disable profiling" --disable-profiling
	mozconfig_annotate "Disable signmar" --disable-signmar
	mozconfig_annotate "Disable verify mar" --disable-verify-mar
	mozconfig_annotate "Disable updater" --disable-updater

	mozconfig_annotate "Rust SIMD" --enable-rust-simd
	mozconfig_annotate "Stylo" --enable-stylo=build

	# https://bugzilla.mozilla.org/show_bug.cgi?id=1423822
	mozconfig_annotate "elf-hack is broken when using Clang/GCC8" --disable-elf-hack

	echo "export MOZ_GECKO_PROFILER=" >> "${S}"/.mozconfig
	echo "export MOZ_ENABLE_PROFILER_SPS=" >> "${S}"/.mozconfig
	echo "export MOZ_PROFILING=" >> "${S}"/.mozconfig
	echo "mk_add_options MOZ_OBJDIR=${BUILD_OBJ_DIR}" >> "${S}"/.mozconfig
	echo "mk_add_options XARGS=/usr/bin/xargs" >> "${S}"/.mozconfig

	# Finalize and report settings
	mozconfig_final

	# workaround for funky/broken upstream configure...
	SHELL="${SHELL:-${EPREFIX}/bin/bash}" \
	emake -f client.mk configure
}

src_compile() {
	MOZ_MAKE_FLAGS="${MAKEOPTS}" SHELL="${SHELL:-${EPREFIX}/bin/bash}" \
	emake -f client.mk realbuild
}

src_install() {
	cd "${BUILD_OBJ_DIR}" || die

	# Pax mark xpcshell for hardened support, only used for startupcache creation.
	pax-mark m "${BUILD_OBJ_DIR}"/dist/bin/xpcshell

	# Add our default prefs for firefox
	cp "${FILESDIR}"/gentoo-default-prefs.js \
		"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
		|| die

	# Augment this with hwaccel prefs
	if use hwaccel ; then
		cat "${FILESDIR}"/gentoo-hwaccel-prefs.js >> \
		"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
		|| die
	fi

	echo "pref(\"extensions.autoDisableScopes\", 3);" >> \
		"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
		|| die

	if use nsplugin; then
		echo "pref(\"plugin.load_flash_only\", false);" >> \
			"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
			|| die
	fi

	local plugin
	use gmp-autoupdate || use eme-free || for plugin in "${GMP_PLUGIN_LIST[@]}" ; do
		echo "pref(\"media.${plugin}.autoupdate\", false);" >> \
			"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
			|| die
	done

	MOZ_MAKE_FLAGS="${MAKEOPTS}" SHELL="${SHELL:-${EPREFIX}/bin/bash}" \
	emake DESTDIR="${D}" install

	# Install language packs
	mozlinguas_src_install

	local size sizes icon_path icon name
	sizes="16 22 24 32 256"
	icon_path="${S}/browser/branding/official"
	icon="${PN}"
	name="Waterfox"

	# Install icons and .desktop for menu entry
	for size in ${sizes}; do
		insinto "/usr/share/icons/hicolor/${size}x${size}/apps"
		newins "${icon_path}/default${size}.png" "${icon}.png"
	done
	# The 128x128 icon has a different name
	insinto "/usr/share/icons/hicolor/128x128/apps"
	newins "${icon_path}/mozicon128.png" "${icon}.png"
	# Install a 48x48 icon into /usr/share/pixmaps for legacy DEs
	newicon "${icon_path}/content/icon48.png" "${icon}.png"
	newmenu "${FILESDIR}/icon/${PN}.desktop" "${PN}.desktop"
	sed -i -e "s:@NAME@:${name}:" -e "s:@ICON@:${icon}:" \
		"${ED}/usr/share/applications/${PN}.desktop" || die

	# Add StartupNotify=true bug 237317
	if use startup-notification ; then
		echo "StartupNotify=true"\
			 >> "${ED}/usr/share/applications/${PN}.desktop" \
			|| die
	fi

	# Required in order to use plugins and even run waterfox on hardened.
	pax-mark m "${ED}"${MOZILLA_FIVE_HOME}/{waterfox,plugin-container}
}

pkg_preinst() {
	gnome2_icon_savelist

	# if the apulse libs are available in MOZILLA_FIVE_HOME then apulse
	# doesn't need to be forced into the LD_LIBRARY_PATH
	if use pulseaudio && has_version ">=media-sound/apulse-0.1.9" ; then
		einfo "APULSE found - Generating library symlinks for sound support"
		local lib
		pushd "${ED}"${MOZILLA_FIVE_HOME} &>/dev/null || die
		for lib in ../apulse/libpulse{.so{,.0},-simple.so{,.0}} ; do
			# a quickpkg rolled by hand will grab symlinks as part of the package,
			# so we need to avoid creating them if they already exist.
			if ! [ -L ${lib##*/} ]; then
				ln -s "${lib}" ${lib##*/} || die
			fi
		done
		popd &>/dev/null || die
	fi
}

pkg_postinst() {
	# Update mimedb for the new .desktop file
	xdg_desktop_database_update
	gnome2_icon_cache_update

	if ! use gmp-autoupdate && ! use eme-free ; then
		elog "USE='-gmp-autoupdate' has disabled the following plugins from updating or"
		elog "installing into new profiles:"
		local plugin
		for plugin in "${GMP_PLUGIN_LIST[@]}"; do elog "\t ${plugin}" ; done
	fi

	if use pulseaudio && has_version ">=media-sound/apulse-0.1.9"; then
		elog "Apulse was detected at merge time on this system and so it will always be"
		elog "used for sound.  If you wish to use pulseaudio instead please unmerge"
		elog "media-sound/apulse."
	fi
}

pkg_postrm() {
	gnome2_icon_cache_update
}

