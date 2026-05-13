#!/usr/bin/env python3
"""Certificate management for work machines (Zscaler TLS inspection).

rebuild:     Concatenate Zscaler root + Python certifi → unified PEM bundle
inject-jdk:  Import Zscaler root into mise-managed JDK cacerts via keytool
"""

import shutil
import subprocess
import sys
from pathlib import Path

CERTS_DIR = Path.home() / ".config/certs"
ROOT_CERT = CERTS_DIR / "ZscalerRootCertificate-2048-SHA256.crt"
BUNDLE = CERTS_DIR / "bundle.pem"
JDK_CACERTS_PASSWORD = "changeit"


def rebuild():
    """Build the unified CA bundle: Zscaler root + certifi."""
    import certifi

    if not ROOT_CERT.exists():
        print(f"Root cert missing at {ROOT_CERT}", file=sys.stderr)
        sys.exit(1)

    BUNDLE.write_bytes(ROOT_CERT.read_bytes() + Path(certifi.where()).read_bytes())
    print(f"Wrote {BUNDLE}")


def inject_jdk():
    """Import Zscaler root into the active mise-installed JDK's cacerts."""
    if not ROOT_CERT.exists():
        print(f"Root cert missing at {ROOT_CERT}", file=sys.stderr)
        sys.exit(1)

    if not shutil.which("mise"):
        print("mise not installed; can't locate the JDK", file=sys.stderr)
        sys.exit(1)

    result = subprocess.run(["mise", "where", "java"], capture_output=True, text=True)
    java_home = Path(result.stdout.strip())
    if not java_home.is_dir():
        print("No Java installed via mise", file=sys.stderr)
        sys.exit(1)

    cacerts = java_home / "lib/security/cacerts"
    keytool = java_home / "bin/keytool"

    if not cacerts.is_file():
        print(f"JDK cacerts not found at {cacerts}", file=sys.stderr)
        sys.exit(1)
    if not keytool.exists():
        print(f"keytool not found at {keytool}", file=sys.stderr)
        sys.exit(1)

    # Drop existing alias (may not exist)
    subprocess.run(
        [str(keytool), "-delete", "-alias", "zscaler",
         "-keystore", str(cacerts), "-storepass", JDK_CACERTS_PASSWORD],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False,
    )

    subprocess.run(
        [str(keytool), "-importcert", "-alias", "zscaler",
         "-file", str(ROOT_CERT), "-keystore", str(cacerts),
         "-storepass", JDK_CACERTS_PASSWORD, "-noprompt"],
        stdout=subprocess.DEVNULL, check=True,
    )
    print(f"Injected zscaler into {cacerts}")


def main():
    if len(sys.argv) < 2:
        print("Usage: certs.py [rebuild | inject-jdk]")
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "rebuild":
        rebuild()
    elif cmd == "inject-jdk":
        inject_jdk()
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)


if __name__ == "__main__":
    main()
