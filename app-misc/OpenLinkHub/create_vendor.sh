#!/bin/bash

VERSION=${VERSION:-0.7.4}
PN="OpenLinkHub"
DISTDIR="/var/cache/distfiles"

echo ">>> Downloading ${PN} v${VERSION}..."
wget "https://github.com/jurkovic-nikola/${PN}/archive/refs/tags/${VERSION}.tar.gz" -O "${PN}-${VERSION}.tar.gz"

echo ">>> Unpacking..."
tar -xf "${PN}-${VERSION}.tar.gz"
cd "${PN}-${VERSION}" || exit 1

echo ">>> Vendoring dependencies..."
go mod vendor

echo ">>> Creating vendor tarball..."
tar -acf "../${PN}-${VERSION}-vendor.tar.xz" vendor

cd ..
rm -rf "${PN}-${VERSION}"

echo ">>> Moving tarballs to ${DISTDIR}..."
sudo mv "${PN}-${VERSION}.tar.gz" "${PN}-${VERSION}-vendor.tar.xz" "${DISTDIR}/"

echo ">>> Done! You can now run 'ebuild ${PN}-${VERSION}.ebuild manifest' and emerge."
