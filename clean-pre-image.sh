set -x

# effectively: febootstrap-minimize --keep-zoneinfo --keep-rpmdb --keep-services "$target".
#  locales
rm -rfv "$target"/usr/{{lib,share}/locale,{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive}
#  docs and man pages
rm -rfv "$target"/usr/share/{man,doc,info,gnome/help}
#  cracklib
rm -rfv "$target"/usr/share/cracklib
#  i18n
rm -rfv "$target"/usr/share/i18n
#  yum cache
rm -rfv "$target"/var/cache/yum
mkdir -p --mode=0755 "$target"/var/cache/yum
#  sln
rm -rfv "$target"/sbin/sln
#  ldconfig
rm -rfv "$target"/etc/ld.so.cache "$target"/var/cache/ldconfig
mkdir -p --mode=0755 "$target"/var/cache/ldconfig

