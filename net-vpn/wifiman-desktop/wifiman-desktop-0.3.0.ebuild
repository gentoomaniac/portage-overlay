# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker

DESCRIPTION="Discover devices and access Teleport VPNs"
HOMEPAGE="https://wifiman.com/"
SRC_URI="amd64? ( https://desktop.wifiman.com/wifiman-desktop-0.3.0-linux-amd64.deb -> ${P}.x86_64.deb )"

LICENSE=""
SLOT="0"
KEYWORDS="amd64"

RESTRICT="mirror strip test bindist"

IUSE=""

DEPEND="
app-accessibility/at-spi2-atk
app-crypt/libsecret
dev-libs/nss
gui-libs/gtk
x11-libs/libnotify
x11-libs/libXScrnSaver
x11-libs/libXtst
x11-misc/xdg-utils
media-video/ffmpeg[chromium]
"
RDEPEND="
acct-group/wifiman
${DEPEND}"
BDEPEND=""

S=${WORKDIR}

src_prepare() {
  default
}

src_unpack() {
  unpack_deb ${P}.x86_64.deb || die src unpack failed
}

src_install() {
  cp -ar "${S}/opt"  "${D}" || die "Install failed!"
  cp -ar "${S}/usr"  "${D}" || die "Install failed!"

  mv "${D}/opt/WiFiman Desktop" "${D}/opt/WiFiman"
  chgrp -R wifiman "${D}/opt/WiFiman"

  dosym "/opt/WiFiman/wifiman-desktop" /usr/bin/wifiman-desktop
}

pkg_postinst() {
  # Stop old instance
  pkill -SIGTERM -f /opt/WiFiman/wifiman-desktop

  ### Can't use wifiman-desktopd install/uninstall due to non-escaped path in generated .service
  cp -f /opt/WiFiman/service/wifiman-desktop.service /etc/systemd/system/


  # customised
  mkdir -p -m 775 /opt/WiFiman/tmp
  chgrp wifiman /opt/WiFiman/tmp
  chmod -R 775 /opt/WiFiman/assets

  sudo chmod 4774 "/opt/WiFiman/wifiman-desktop"

  sudo sed -i 's;opt/WiFiman Desktop/;opt/WiFiman/;g' /usr/share/applications/wifiman-desktop.desktop
  sudo sed -i 's;opt/WiFiman Desktop/;opt/WiFiman/;g' /etc/systemd/system/wifiman-desktop.service
  # end


  ### Service
  systemctl daemon-reload
  systemctl enable wifiman-desktop.service
  systemctl start wifiman-desktop.service

  update-mime-database /usr/share/mime &>/dev/null
  update-desktop-database /usr/share/applications &>/dev/null
}

pkg_postrm() {
  # Can't use wifiman-desktopd, already removed
  systemctl stop wifiman-desktop.service
  systemctl disable wifiman-desktop.service
  if ! [ -f /opt/WiFiman\ Desktop/wifiman-desktop ]; then
      rm -Rf /opt/WiFiman\ Desktop/
      rm -f /etc/systemd/system/wifiman-desktop.service
      systemctl daemon-reload
  fi
}
