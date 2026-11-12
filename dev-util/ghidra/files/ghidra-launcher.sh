#!/bin/sh
# Start a Ghidra tool with a JDK 25 (Ghidra 12 needs Java 25), whichever Java
# VM is the system default.
# Installed as /usr/bin/ghidra (GUI) and /usr/bin/ghidra-analyzeHeadless; the
# name it is called by picks the Ghidra script to run.
set -eu

GHIDRA_HOME=/opt/ghidra

if [ -z "${JAVA_HOME:-}" ]; then
	for jdk in /usr/lib/jvm/openjdk-bin-25 /usr/lib/jvm/openjdk-25; do
		if [ -x "${jdk}/bin/java" ]; then
			JAVA_HOME=${jdk}
			break
		fi
	done
fi
if [ -n "${JAVA_HOME:-}" ]; then
	export JAVA_HOME
	PATH=${JAVA_HOME}/bin:${PATH}
	export PATH
fi

case "$(basename "$0")" in
	ghidra-analyzeHeadless) exec "${GHIDRA_HOME}/support/analyzeHeadless" "$@" ;;
	*) exec "${GHIDRA_HOME}/ghidraRun" "$@" ;;
esac
