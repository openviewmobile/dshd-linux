#!/usr/bin/env bash
# Sign RPMs with Fedora's rpm implementation. Ubuntu's rpm package does not
# produce a signature even when rpm --addsign exits zero.
set -euo pipefail

dnf install -y -q gnupg2 rpm-sign >/dev/null
shopt -s nullglob
rpms=(/rpms/*.rpm)
[[ ${#rpms[@]} -gt 0 ]] || { echo "no RPMs to sign" >&2; exit 1; }

sign_args=(
  --addsign
  --define "_signature gpg"
  --define "_gpg_name $FPR"
  --define "_gpg_path /root/.gnupg"
)
if [[ -n ${GPG_PASSPHRASE:-} && -f /tmp/gpg-pass ]]; then
  sign_args+=(--define "__gpg_sign_cmd %{__gpg} gpg --batch --no-armor --pinentry-mode loopback --passphrase-file /tmp/gpg-pass -u %{_gpg_name} -sbo %{__signature_filename} %{__plaintext_filename}")
else
  sign_args+=(--define "__gpg_sign_cmd %{__gpg} gpg --batch --no-armor -u %{_gpg_name} -sbo %{__signature_filename} %{__plaintext_filename}")
fi

for rpm in "${rpms[@]}"; do
  rpm "${sign_args[@]}" "$rpm"
  rpmkeys --checksig "$rpm" | grep -qE 'digests signatures OK|signatures OK' || {
    echo "RPM signature missing: $rpm" >&2
    exit 1
  }
done
touch /rpms/.rpms-signed
