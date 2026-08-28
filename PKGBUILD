# Maintainer: damachin3 (damachine3 at proton dot me)
# Website: https://github.com/damachine/bbr_classic-multi
pkgname=bbr-classic-dkms
pkgver=7.2
pkgrel=1
pkgdesc="BBRv1 TCP congestion control module (backport for BBRv3-patched kernels)"
arch=('any')
license=('GPL-2.0-only')
url="https://github.com/damachine/bbr_classic-multi"
depends=('dkms')
source=("tcp_bbr.c::https://raw.githubusercontent.com/torvalds/linux/v${pkgver}/net/ipv4/tcp_bbr.c"
        "Makefile"
        "dkms.conf")
sha256sums=('a67fb17544c459823485ebffdc1924bad1566b20dcd54fd24c95c910e64f15a7'
            '557d63518b0e4ceeb1ec2e92ba0ef44b5e330705ad7265b19264bb67ace1eabd'
            'e42c6fa831a6188f12b36358c6c7b04d41bc53c16ebec4520d01830e3aa8c261')

package() {
    install -dm755 "${pkgdir}/usr/src/bbr-classic-${pkgver}"
    install -m644 "tcp_bbr.c" "${pkgdir}/usr/src/bbr-classic-${pkgver}/"
    install -m644 "Makefile" "${pkgdir}/usr/src/bbr-classic-${pkgver}/"
    sed "s/@VERSION@/${pkgver}/" "dkms.conf" > "${pkgdir}/usr/src/bbr-classic-${pkgver}/dkms.conf"
}
