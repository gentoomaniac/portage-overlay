# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module linux-info systemd udev

DESCRIPTION="Open source Linux interface for iCUE LINK Hub and Corsair AIOs"
HOMEPAGE="https://github.com/jurkovic-nikola/OpenLinkHub"

SRC_URI="
	https://github.com/jurkovic-nikola/OpenLinkHub/archive/v${PV}.tar.gz -> ${P}.tar.gz
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

# 1. OVERRIDE SRC_UNPACK
# This is the fix. We prevent go-module.eclass from trying to verify deps
# before we have moved the vendor directory into place.
src_unpack() {
	default
}

src_prepare() {
	default

	# 2. Fix Directory Structure
	# The GitHub archive unpacks to OpenLinkHub-0.7.4 (which matches S)
	# The vendor tarball unpacks to "vendor/" in WORKDIR.
	# We must move "vendor/" inside "OpenLinkHub-0.7.4/"
	if [[ -d "${WORKDIR}/vendor" ]]; then
		mv "${WORKDIR}/vendor" "${S}/" || die "Could not move vendor directory"
	fi
}

src_compile() {
	# 3. Force Offline Build
	# We explicitly tell Go to use the vendor directory we just moved
	export CGO_ENABLED=1
	export GOFLAGS="-mod=vendor"
	export GOPROXY=off

	ego build .
}

src_install() {
	dobin OpenLinkHub

	if [[ -f "99-openlinkhub.rules" ]]; then
		sed -i 's/GROUP=".*"/GROUP="i2c"/' 99-openlinkhub.rules
		udev_dorules 99-openlinkhub.rules
	fi

	cat > "${T}/openlinkhub.service" <<-EOF
	[Unit]
	Description=OpenLinkHub Corsair Control Service
	After=network.target

	[Service]
	ExecStart=/usr/bin/OpenLinkHub
	Restart=always
	DynamicUser=yes
	User=openlinkhub
	SupplementaryGroups=i2c usb
	StateDirectory=openlinkhub
	WorkingDirectory=/var/lib/openlinkhub

	[Install]
	WantedBy=multi-user.target
	EOF

	systemd_dounit "${T}/openlinkhub.service"
}

pkg_postinst() {
	udev_reload
	elog "Systemd 'DynamicUser' is active. Data stored in /var/lib/openlinkhub."
	elog "Enable with: systemctl enable --now openlinkhub"
}
