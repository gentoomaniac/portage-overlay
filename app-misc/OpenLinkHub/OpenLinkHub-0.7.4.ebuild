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
	default
}

src_prepare() {
	default
	# Move vendor directory into place
	if [[ -d "${WORKDIR}/vendor" ]]; then
		mv "${WORKDIR}/vendor" "${S}/" || die
	fi
}

src_compile() {
	export CGO_ENABLED=1
	export GOFLAGS="-mod=vendor"
	export GOPROXY=off
	ego build .
}

src_install() {
	# 1. Install Binary to standard path
	dobin OpenLinkHub

	# 2. Install ALL assets directly to /var/lib/OpenLinkHub
	# This includes both the mutable database and the static web/api assets.
	# The app will find them all in its working directory.
	insinto /var/lib/${PN}
	doins -r api database openrgb static web

	# 3. Udev Rules
	if [[ -f "99-openlinkhub.rules" ]]; then
		sed -i 's/GROUP=".*"/GROUP="i2c"/' 99-openlinkhub.rules
		udev_dorules 99-openlinkhub.rules
	fi

	# 4. Systemd Service
	cat > "${T}/${PN}.service" <<-EOF
	[Unit]
	Description=OpenLinkHub Corsair Control Service
	After=network.target

	[Service]
	ExecStart=/usr/bin/OpenLinkHub
	Restart=always

	# User Management
	# DynamicUser creates a transient user 'openlinkhub'
	DynamicUser=yes
	User=openlinkhub
	SupplementaryGroups=i2c usb

	# Directory Management
	# 1. StateDirectory creates /var/lib/OpenLinkHub if missing.
	# 2. IMPORTANT: It recursively chowns the directory to the DynamicUser on start.
	#    This ensures the app can read/write everything we installed there.
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
	elog "All data files are located in: /var/lib/${PN}"
	elog "Enable with: systemctl enable --now ${PN}"
}
