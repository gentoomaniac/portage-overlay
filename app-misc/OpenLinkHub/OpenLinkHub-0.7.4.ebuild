# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module linux-info systemd udev

DESCRIPTION="Open source Linux interface for iCUE LINK Hub and Corsair AIOs"
HOMEPAGE="https://github.com/jurkovic-nikola/OpenLinkHub"

SRC_URI="
	https://github.com/jurkovic-nikola/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz
	${P}-vendor.tar.xz
"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	acct-group/i2c
	virtual/libusb:1
	sys-apps/i2c-tools
"
RDEPEND="${DEPEND}"
BDEPEND=""

pkg_setup() {
	local CONFIG_CHECK="~I2C_CHARDEV"
	linux-info_pkg_setup
}

src_unpack() {
	# Just unpack. Don't let go-module eclass try to verify yet.
	default
}

src_prepare() {
	default

	# NOTE: We do NOT move source files here because they are already correct.

	# Move vendor directory into place
	if [[ -d "${WORKDIR}/vendor" ]]; then
		mv "${WORKDIR}/vendor" "${S}/" || die "Could not move vendor directory"
	fi
}

src_compile() {
	export CGO_ENABLED=1
	export GOFLAGS="-mod=vendor"
	export GOPROXY=off
	ego build .
}

src_install() {
	# 1. Binary
	dobin OpenLinkHub

	# 2. Static Assets (Immutable) -> /usr/share
	insinto /usr/share/${PN}
	doins -r api openrgb static web

	# 3. State Data (Mutable) -> /var/lib
	insinto /var/lib/${PN}
	doins -r database

	# 4. Symlinks
	dosym -r /usr/share/${PN}/api     /var/lib/${PN}/api
	dosym -r /usr/share/${PN}/openrgb /var/lib/${PN}/openrgb
	dosym -r /usr/share/${PN}/static  /var/lib/${PN}/static
	dosym -r /usr/share/${PN}/web     /var/lib/${PN}/web

	# 5. Udev Rules
	if [[ -f "99-openlinkhub.rules" ]]; then
		sed -i 's/GROUP=".*"/GROUP="i2c"/' 99-openlinkhub.rules
		udev_dorules 99-openlinkhub.rules
	fi

	# 6. Systemd Service
	cat > "${T}/${PN}.service" <<-EOF
	[Unit]
	Description=OpenLinkHub Corsair Control Service
	After=network.target

	[Service]
	ExecStart=/usr/bin/OpenLinkHub
	Restart=always
	DynamicUser=yes
	User=openlinkhub
	SupplementaryGroups=i2c usb
	StateDirectory=${PN}
	WorkingDirectory=/var/lib/${PN}

	[Install]
	WantedBy=multi-user.target
	EOF

	systemd_dounit "${T}/${PN}.service"
}

pkg_postinst() {
	udev_reload
	elog "Installation complete."
	elog "Enable with: systemctl enable --now ${PN}"
}
