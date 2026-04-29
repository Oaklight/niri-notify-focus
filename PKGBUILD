# Maintainer: Pei Ding <oaklight@gmail.com>
pkgname=niri-notify-focus
pkgver=0.1.0
pkgrel=1
pkgdesc="Focus source window on notification click for the niri Wayland compositor"
arch=('any')
url="https://github.com/Oaklight/niri-notify-focus"
license=('MIT')
depends=('python' 'python-dbus' 'python-gobject')
optdepends=('niri: required Wayland compositor')
source=("${pkgname}-${pkgver}.tar.gz::${url}/archive/v${pkgver}.tar.gz")
sha256sums=('SKIP')

package() {
    cd "${pkgname}-${pkgver}"
    make install DESTDIR="${pkgdir}"
}
