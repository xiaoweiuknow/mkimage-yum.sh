#!/usr/bin/env bash
#
# Create a base CentOS Docker image.
#
# This script is useful on systems with yum installed (e.g., building
# a CentOS image on CentOS).  See contrib/mkimage-rinse.sh for a way
# to build CentOS images on other systems.

set -e

clear
echo "Centos 7.x Image Build Script"
echo "------------------------------------------------------------"
echo "Default is to work with local repository"
echo "comment following line if public repository will be used:"
echo "  cp /etc/yum.repos.d/CentOS-Base.repo ..../etc/yum.repos.d/"
echo ""
echo "To see possible group names run:"
echo "  sudo yum group list"
echo "------------------------------------------------------------"
echo ""

usage() {
    cat <<EOOPTS
$(basename $0) [OPTIONS] <name>
OPTIONS:
  -p "<packages>"     The list of packages to install in the container.
                      The default is blank. May use multiple times.
                      ex. -p nano -p nc -p yum-utils
  -e "<env group>"    Environment Group to install in the container.
                      The default is "Minimal Install". ONLY USE ONCE.
  -g "<groups>"       The groups of packages to install in the container.
                      The default is blank. May Use mutiple times.
  -r "<packages>"     The list of packages to remove post the env group install.
                      The default is blank. May use multiple times.
                      ex. -r Network Manager -r iptables					  
  -y <yumconf>        The path to the yum config to install packages from. The
                      default is /etc/yum.conf for Centos/RHEL
                      and /etc/dnf/dnf.conf for Fedora
  -t <tag>            Specify Tag information.
                      default is reffered at /etc/{redhat,system}-release
  -u "<your name>"    Enter name to be used as creator in info file
EOOPTS
    exit 1
}

# option defaults
yum_config=/etc/yum.conf
if [ -f /etc/dnf/dnf.conf ] && command -v dnf &> /dev/null; then
	yum_config=/etc/dnf/dnf.conf
	alias yum=dnf
fi
# for names with spaces, use double quotes (") as install_env_group=('Core' '"Compute Node"')
install_env_group=()
install_packages=()
install_other_groups=()
remove_packages=()
version=
while getopts ":y:p:g:t:h:u:e:r:" opt; do
    case $opt in
        y)
            yum_config=$OPTARG
            ;;
        u)  
            creator="$OPTARG"
	        ;;
        h)
            usage
            ;;
	p)
            install_packages+=("$OPTARG")
            ;;
	r)
            remove_packages+=("$OPTARG")
            ;;			
	e)
            install_env_group="$OPTARG"
            ;;			
        g)
            install_other_groups+=("$OPTARG")
            ;;
        t)
            version="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            usage
            ;;
    esac
done
shift $((OPTIND - 1))
name=$1

if [[ -z $name ]]; then
    usage
fi

# default to Core group if not specified otherwise
if [ ${#install_env_group[*]} -eq 0 ]; then
   install_env_group=('Minimal Install')
fi

target=$(mktemp -d --tmpdir $(basename $0).XXXXXX)

set -x

mkdir -m 755 "$target"/dev
mknod -m 600 "$target"/dev/console c 5 1
mknod -m 600 "$target"/dev/initctl p
mknod -m 666 "$target"/dev/full c 1 7
mknod -m 666 "$target"/dev/null c 1 3
mknod -m 666 "$target"/dev/ptmx c 5 2
mknod -m 666 "$target"/dev/random c 1 8
mknod -m 666 "$target"/dev/tty c 5 0
mknod -m 666 "$target"/dev/tty0 c 4 0
mknod -m 666 "$target"/dev/urandom c 1 9
mknod -m 666 "$target"/dev/zero c 1 5

# amazon linux yum will fail without vars set
if [ -d /etc/yum/vars ]; then
	mkdir -p -m 755 "$target"/etc/yum
	cp -a /etc/yum/vars "$target"/etc/yum/
fi

if [[ -n "$install_env_group" ]];
then
    yum -c "$yum_config" --installroot="$target" --releasever=/ --setopt=tsflags=nodocs \
        --setopt=group_package_types=mandatory -y groupinstall "${install_env_group[*]}"
fi

#Copy host repo to image. Disable this if using public repositories
cp /etc/yum.repos.d/CentOS-Base.repo "$target"/etc/yum.repos.d/

#Create docker-image-info file
echo "Date/Time Created" > "$target"/etc/docker-image-info
echo "-----------------------------" >> "$target"/etc/docker-image-info
date  >> "$target"/etc/docker-image-info
echo "" >> "$target"/etc/docker-image-info
echo "Created By" >> "$target"/etc/docker-image-info
echo "-----------------------------" >> "$target"/etc/docker-image-info
echo $creator >> "$target"/etc/docker-image-info
echo "" >> "$target"/etc/docker-image-info
echo "Environment Group Installed" >> "$target"/etc/docker-image-info
echo "-----------------------------" >> "$target"/etc/docker-image-info
echo $install_env_group >> "$target"/etc/docker-image-info
echo "" >> "$target"/etc/docker-image-info
echo "Packages Removed" >> "$target"/etc/docker-image-info
echo "-----------------------------" >> "$target"/etc/docker-image-info

if [[ -n "$remove_packages" ]];
then
    for package_removal in "${remove_packages[@]}";
    do
    yum -c "$yum_config" --installroot="$target" --releasever=/ --setopt=tsflags=nodocs \
        --setopt=group_package_types=mandatory -y remove "$package_removal"
    echo $package_removal >> "$target"/etc/docker-image-info
    done
fi

echo "" >> "$target"/etc/docker-image-info
echo "Other Groups Installed" >> "$target"/etc/docker-image-info
echo "-----------------------------" >> "$target"/etc/docker-image-info

if [[ -n "$install_other_groups" ]];
then
    for group_name in "${install_other_groups[@]}";
    do
    yum -c "$yum_config" --installroot="$target" --releasever=/ --setopt=tsflags=nodocs \
        --setopt=group_package_types=mandatory -y groupinstall "$group_name"
    echo $group_name >> "$target"/etc/docker-image-info
    done
fi

echo "" >> "$target"/etc/docker-image-info
echo "Additional Packages Installed" >> "$target"/etc/docker-image-info
echo "-----------------------------" >> "$target"/etc/docker-image-info

if [[ -n "$install_packages" ]];
then
    for package_name in "${install_packages[@]}";
    do
    yum -c "$yum_config" --installroot="$target" --releasever=/ --setopt=tsflags=nodocs \
        --setopt=group_package_types=mandatory -y install "$package_name"
    echo $package_name >> "$target"/etc/docker-image-info
    done
fi

yum -c "$yum_config" --installroot="$target" -y clean all

cat > "$target"/etc/sysconfig/network <<EOF
NETWORKING=yes
HOSTNAME=localhost.localdomain
EOF

# effectively: febootstrap-minimize --keep-zoneinfo --keep-rpmdb --keep-services "$target".
#  locales
rm -rf "$target"/usr/{{lib,share}/locale,{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive}
#  docs and man pages
rm -rf "$target"/usr/share/{man,doc,info,gnome/help}
#  cracklib
rm -rf "$target"/usr/share/cracklib
#  i18n
rm -rf "$target"/usr/share/i18n
#  yum cache
rm -rf "$target"/var/cache/yum
mkdir -p --mode=0755 "$target"/var/cache/yum
#  sln
rm -rf "$target"/sbin/sln
#  ldconfig
rm -rf "$target"/etc/ld.so.cache "$target"/var/cache/ldconfig
mkdir -p --mode=0755 "$target"/var/cache/ldconfig

if [ -z "$version" ]; then
    for file in "$target"/etc/{redhat,system}-release
    do
        if [ -r "$file" ]; then
            version="$(sed 's/^[^0-9\]*\([0-9.]\+\).*$/\1/' "$file")"
            break
        fi
    done
fi

if [ -z "$version" ]; then
    echo >&2 "warning: cannot autodetect OS version, using '$name' as tag"
    version=$name
fi

tar --numeric-owner -c -C "$target" . | docker import - $name:$version -m "Owner: $creator - Aurotech"

docker run -i -t --rm $name:$version /bin/bash -c 'cat /etc/docker-image-info'

rm -rf "$target"
