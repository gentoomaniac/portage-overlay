# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Release zips are named after the build date, not just the version.
BUILD_DATE="20261016"

DESCRIPTION="Software reverse engineering framework by the NSA"
HOMEPAGE="https://ghidra-sre.org https://github.com/NationalSecurityAgency/ghidra"
SRC_URI="https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${PV}_build/ghidra_${PV}_PUBLIC_${BUILD_DATE}.zip"
S="${WORKDIR}/ghidra_${PV}_PUBLIC"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"

# Prebuilt release: the native decompiler and sleigh binaries ship in the zip.
RESTRICT="strip test"
QA_PREBUILT="opt/ghidra/*"

RDEPEND="virtual/jdk:25[-headless-awt]"
BDEPEND="app-arch/unzip"

src_install() {
	# cp -R keeps the executable bits of the launch scripts and native tools,
	# which doins would drop. Ownership is not kept: the unpacked files belong to
	# the portage user under FEATURES=userpriv, installed ones should be root's.
	dodir /opt/ghidra
	cp -R --no-preserve=ownership . "${ED}/opt/ghidra" || die

	newbin "${FILESDIR}/ghidra-launcher.sh" ghidra
	dosym ghidra /usr/bin/ghidra-analyzeHeadless
}

pkg_postinst() {
	elog "Start the GUI with 'ghidra' and headless analysis with"
	elog "'ghidra-analyzeHeadless'. Both use JDK 25 from /usr/lib/jvm unless"
	elog "JAVA_HOME is set."
}
