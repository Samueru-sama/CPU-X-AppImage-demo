#!/bin/sh

set -eu
export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
APPIMAGETOOL="https://github.com/pkgforge-dev/appimagetool-uruntime/releases/download/continuous/appimagetool-$ARCH.AppImage"
UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
VERSION=$(pacman -Q cpu-x | awk 'NR==1 {print $2; exit}')
echo "$VERSION" > ~/version

# install debloated packages
LLVM_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/llvm-libs-nano-$PKG_TYPE"
LIBXML_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/libxml2-iculess-$PKG_TYPE"
MESA_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/mesa-mini-$PKG_TYPE"

echo "Installing debloated pckages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$LLVM_URL"   -O  ./llvm-libs.pkg.tar.zst
wget --retry-connrefused --tries=30 "$LIBXML_URL" -O  ./libxml2.pkg.tar.zst
wget --retry-connrefused --tries=30 "$MESA_URL"   -O  ./mesa.pkg.tar.zst

pacman -U --noconfirm ./*.pkg.tar.zst
rm -f ./*.pkg.tar.zst

# Prepare AppDir
mkdir -p ./AppDir
cd ./AppDir

# ADD LIBRARIES
wget "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -p -v -e -s -k \
	/usr/bin/cpu-x \
	/usr/lib/libcpuid.so* \
	/usr/lib/dri/* \
	/usr/lib/libEGL*.so* \
	/usr/lib/libvulkan*.so* \
	/usr/lib/libgirepository-*.so* \
	/usr/lib/gtk-*/*/immodules/*.so \
	/usr/lib/gdk-pixbuf-*/*/loaders/*

./lib4bin -s --with-wrappe /usr/lib/cpu-x/cpu-x-daemon

cp -v /usr/share/applications/*cpu-x.desktop           ./
cp -v /usr/share/icons/hicolor/256x256/apps/*cpu-x.png ./
cp -v /usr/share/icons/hicolor/256x256/apps/*cpu-x.png ./.DirIcon
cp -rv /usr/share/cpu-x                                ./share

# 👀 👀 👀
sed -i 's|/usr/lib/cpu-x|/tmp/.69420kek|g' ./shared/bin/cpu-x
echo '#!/bin/sh
CURRENTDIR="$(readlink -f "$(dirname "$0")")"
if [ ! -f /tmp/.69420kek/cpu-x-daemon ]; then
	mkdir -p /tmp/.69420kek
	cp "$CURRENTDIR"/cpu-x-daemon /tmp/.69420kek
fi
exec "$CURRENTDIR"/bin/cpu-x "$@"' > ./AppRun
chmod +x ./AppRun
./sharun -g

# MAKE APPIAMGE WITH URUNTIME
cd ..
wget "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool

echo "Generating AppImage..."
./appimagetool -n -u "$UPINFO" "$PWD"/AppDir "$PWD"/CPU-X-"$VERSION"-anylinux-"$ARCH".AppImage

echo "All Done!"
