# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="User for the OpenLinkHub service"

ACCT_USER_ID=-1
ACCT_USER_GROUPS=( "openlinkhub" "usb" "i2c" )
ACCT_USER_HOME="/var/lib/OpenLinkHub"
ACCT_USER_SHELL="/sbin/nologin"

acct-user_add_deps
