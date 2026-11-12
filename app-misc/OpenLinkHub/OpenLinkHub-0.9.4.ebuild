# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module linux-info systemd udev

EGO_SUM=(
	"github.com/godbus/dbus/v5 v5.1.0"
	"github.com/godbus/dbus/v5 v5.1.0/go.mod"
	"github.com/golang/freetype v0.0.0-20170609003504-e2365dfdc4a0"
	"github.com/golang/freetype v0.0.0-20170609003504-e2365dfdc4a0/go.mod"
	"github.com/sstallion/go-hid v0.14.1"
	"github.com/sstallion/go-hid v0.14.1/go.mod"
	"golang.org/x/crypto v0.58.0"
	"golang.org/x/crypto v0.58.0/go.mod"
	"golang.org/x/image v0.47.0"
	"golang.org/x/image v0.47.0/go.mod"
	"golang.org/x/sys v0.49.0"
	"golang.org/x/sys v0.49.0/go.mod"
	"golang.org/x/text v0.43.0"
	"golang.org/x/text v0.43.0/go.mod"
)
go-module_set_globals

DESCRIPTION="Open source Linux interface for iCUE LINK Hub and Corsair AIOs"
HOMEPAGE="https://github.com/jurkovic-nikola/OpenLinkHub"

SRC_URI="
	https://github.com/jurkovic-nikola/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz
	${EGO_SUM_SRC_URI}
"

LICENSE="GPL-3 BSD BSD-2 || ( FTL GPL-2+ )"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	acct-group/openlinkhub
	acct-user/openlinkhub
	media-video/pipewire
	virtual/libudev
	virtual/libusb:1
	sys-apps/i2c-tools
"
RDEPEND="${DEPEND}"
BDEPEND="
	>=dev-lang/go-1.26.0
	virtual/pkgconfig
"

pkg_setup() {
	local CONFIG_CHECK="~I2C_CHARDEV"
	linux-info_pkg_setup
}

src_compile() {
	export CGO_ENABLED=1
	export CGO_CFLAGS_ALLOW=-fno-strict-overflow
	ego build .
}

src_install() {
	# 1. Binary
	dobin OpenLinkHub

	# 2. Data Directory
	insinto /var/lib/${PN}
	doins -r api database openrgb static web

	# 3. Permissions (User created by acct-user package)
	fowners -R openlinkhub:openlinkhub /var/lib/${PN}

	# 4. Udev Rules (Generated)
	# We create a catch-all rule for Vendor 1b1c (Corsair) so mice/headsets work
	cat > "${T}/99-openlinkhub.rules" <<-EOF
	# OpenLinkHub Rules
	# Grant 'openlinkhub' group access to all Corsair USB devices (Vendor 1b1c)
	# This covers Commander Pro, AIOs, Lighting Nodes, etc.
	SUBSYSTEMS=="usb", ATTRS{idVendor}=="1b1c", GROUP="openlinkhub", MODE="0660"

	# Grant access to Corsair HID devices (raw access needed for protocol)
	# This covers Mice, Keyboards, Headsets
	KERNEL=="hidraw*", ATTRS{idVendor}=="1b1c", GROUP="openlinkhub", MODE="0660"
	EOF

	udev_dorules "${T}/99-openlinkhub.rules"

	# 5. Systemd Service
	cat > "${T}/${PN}.service" <<-EOF
	[Unit]
	Description=OpenLinkHub Corsair Control Service
	After=network.target

	[Service]
	ExecStart=/usr/bin/OpenLinkHub
	Restart=always
	User=openlinkhub
	Group=openlinkhub
	WorkingDirectory=/var/lib/${PN}

	[Install]
	WantedBy=multi-user.target
	EOF

	systemd_dounit "${T}/${PN}.service"
}

pkg_postinst() {
	udev_reload
	elog "Installation complete."
	elog "Service runs as user 'openlinkhub'."
	elog "Udev rules installed for all Corsair devices (USB+HID)."
	elog "Enable with: systemctl enable --now ${PN}"
}
