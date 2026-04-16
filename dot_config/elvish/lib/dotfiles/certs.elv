# certs.elv — Build the work CA bundle.
#
# Concatenates the Zscaler root cert with Python certifi's CA bundle into
# a single PEM file that TLS clients (curl, requests, node, aws) can trust.
#
# Usage:
#   use dotfiles/certs
#   certs:rebuild

use os
use path
use str

var certs-dir = ~/.config/certs
var root-cert = $certs-dir/ZscalerRootCertificate-2048-SHA256.crt
var bundle = $certs-dir/bundle.pem
var jdk-cacerts-password = changeit

fn -certifi-path {
  # Ask Python's certifi package where its CA bundle lives.
  # `uv run --with certifi` pulls in certifi on demand, so this works from
  # any cwd without needing a project that depends on it.
  if (has-external uv) {
    uv run --quiet --with certifi --no-project python -c 'import certifi; print(certifi.where())'
  } elif (has-external python3) {
    python3 -c 'import certifi; print(certifi.where())'
  } else {
    fail "Neither uv nor python3 found; install one to build the cert bundle."
  }
}

fn rebuild {
  if (not (os:exists $root-cert)) {
    fail "Root cert missing at "$root-cert" — run `chezmoi apply` on a work machine."
  }
  var certifi = (str:trim-space (-certifi-path | slurp))
  if (not (path:is-regular $certifi)) {
    fail "certifi bundle not found at "$certifi
  }
  cat $root-cert $certifi > $bundle
  echo "Wrote "$bundle
}

fn bundle-path {
  # Return the bundle path (for use in scripts).
  put $bundle
}

fn inject-zscaler-into-jdk {
  # Import the Zscaler root directly into the active mise-installed JDK's
  # cacerts. Re-run whenever mise switches Java versions — the new JDK comes
  # with a fresh bundled cacerts that lacks the Zscaler root, and the JVM
  # doesn't honor SSL_CERT_FILE, so TLS to internal services breaks without
  # this. Idempotent: re-imports cleanly if zscaler alias is already present.
  if (not (os:exists $root-cert)) {
    fail "Root cert missing at "$root-cert
  }
  if (not (has-external mise)) {
    fail "mise not installed; can't locate the JDK"
  }
  var java-home = (str:trim-space (mise where java 2>/dev/null | slurp))
  if (eq $java-home "") {
    fail "No Java installed via mise. Run `mise install java` first."
  }
  var cacerts = $java-home/lib/security/cacerts
  var keytool = $java-home/bin/keytool
  if (not (path:is-regular $cacerts)) {
    fail "JDK cacerts not found at "$cacerts
  }
  if (not (path:is-regular &follow-symlink $keytool)) {
    fail "keytool not found at "$keytool
  }

  # Drop any existing zscaler alias (ignore errors — may not be present),
  # then import fresh.
  try {
    $keytool -delete ^
      -alias zscaler ^
      -keystore $cacerts ^
      -storepass $jdk-cacerts-password >/dev/null 2>&1
  } catch e { }

  $keytool -importcert ^
    -alias zscaler ^
    -file $root-cert ^
    -keystore $cacerts ^
    -storepass $jdk-cacerts-password ^
    -noprompt >/dev/null
  echo "Injected zscaler into "$cacerts
}
