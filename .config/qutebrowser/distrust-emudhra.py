#!/usr/bin/env python3
"""Apply the pinned NSS mitigation from qutebrowser issue #9032.

This is a partial mitigation: verify all test certificates in the browser
after a full restart. qutebrowser 3.7.0 has reports of incomplete rejection.
https://github.com/qutebrowser/qutebrowser/issues/9032
"""

import hashlib
import json
from pathlib import Path
import ssl
import subprocess
from urllib.request import urlopen


URL = "https://emudhra.we-have-a-problem.com/impacted-intermediates.json"
SHA256 = "f67b3abe9b4879f4e91874ed041beccd71257f1db41c588c724ccf12aa90c59e"


def main():
    database = Path.home() / ".pki/nssdb"
    if not (database / "cert9.db").is_file():
        raise RuntimeError("Expected an existing NSS database at " + str(database))
    with urlopen(URL, timeout=30) as response:
        payload = response.read(1024 * 1024)
    if hashlib.sha256(payload).hexdigest() != SHA256:
        raise RuntimeError("Certificate list checksum mismatch; no certificates imported")
    certificates = json.loads(payload)
    if len(certificates) != 16 or len({c['spki_sha256'] for c in certificates}) != 8:
        raise RuntimeError("Expected sixteen certificates covering eight compromised keys")
    # Validate every certificate before changing any trust entries.
    for certificate in certificates:
        der = ssl.PEM_cert_to_DER_cert(certificate["pem"])
        if hashlib.sha256(der).hexdigest() != certificate["sha256"].lower():
            raise RuntimeError("Certificate fingerprint mismatch")
    for certificate in certificates:
        subprocess.run(
            ["certutil", "-d", "sql:" + str(database), "-A", "-a", "-t", "p,p,p",
             "-n", "eMudhra " + certificate["sha256"].lower()],
            input=certificate["pem"], text=True, check=True,
        )
    print("Distrusted all 16 certificates for eight eMudhra keys. Fully restart QtWebEngine apps and test rejection.")


if __name__ == "__main__":
    main()
