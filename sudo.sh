# (grep -qxF 'auth sufficient pam_tid.so asdf' /private/etc/pam.d/sudo)
# export already_has_line=$?

if [[ ! $(grep -xF 'auth sufficient pam_tid.so' /private/etc/pam.d/sudo) ]]; then
  echo "Enabling Touch ID for sudo access 🔑"
  sudo sed -i '' '2i\
auth sufficient pam_tid.so\
'  /private/etc/pam.d/sudo
fi