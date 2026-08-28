# bbr_classic-multi
**This Linux kernel module brings the original BBRv1 back as `bbr_classic`, so you can use both BBRv1 and BBRv2/3 side by side.
Why this: On BBRv2/3-patched kernels (e.g. CachyOS, TKG, Zen, Liquorix, and Xanmod), BBRv1 is replaced by BBRv2/3.**

<br />

## Install (build manual)

Builds and installs as kernel module. Requires kernel headers.

```sh
git clone https://github.com/damachine/bbr_classic-multi.git
cd bbr_classic-multi
make                # download tcp_bbr.c and build the module
sudo make install   # install module permanently (no DKMS)
```

## Install as DKMS package

```sh
git clone https://github.com/damachine/bbr_classic-multi.git
cd bbr_classic-multi
sudo make dkms-install
```

Uninstall:

```sh
sudo make dkms-uninstall
```

## Install **bbr-classic-dkms** (Arch-based distros)

```sh
git clone https://github.com/damachine/bbr_classic-multi.git
cd bbr_classic-multi
makepkg -si
```

Uninstall:

```sh
pacman -R bbr-classic-dkms
```

<br />

## Load & activate

```sh
# load module
sudo modprobe tcp_bbr_classic
# set Qdisc and congestion control algorithm
sudo sysctl -w net.core.default_qdisc=fq
sudo sysctl -w net.ipv4.tcp_congestion_control=bbr_classic
```

Verify:

```sh
# check module info
modinfo tcp_bbr_classic
# check module is loaded
lsmod | grep bbr_classic
# check congestion control algorithm and Qdisc
sysctl net.ipv4.tcp_congestion_control
sysctl net.core.default_qdisc
```

## Persistent

```sh
# add sysctl config file for persistent settings
sudo tee /etc/sysctl.d/99-bbr-classic.conf << EOF
# Set Qdisc (Fair Queue)
net.core.default_qdisc=fq
# Enable BBR Classic as TCP Congestion Control
net.ipv4.tcp_congestion_control=bbr_classic
EOF
# reload sysctl settings
sudo sysctl --system
```

<br />

## Testing performance

Requires `iperf3` and a server that allows selecting the congestion control algorithm.

```sh
# compare against BBRv3
iperf3 -c <server> -C bbr

# test BBR Classic
iperf3 -c <server> -C bbr_classic
```

See also: [CachyOS/linux-cachyos#706] for benchmark results.

<br />

## Technical Implementation

Build `tcp_bbr_classic.c` from `tcp_bbr.c` source:

- The unmodified BBRv1 source `tcp_bbr.c` is downloaded from the main Linux tree

Patches in `tcp_bbr_classic.c`:

- renames string literal "bbr" to "bbr_classic" for new congestion control name

- renames struct bbr to avoid symbol conflicts with in-tree BBRv3

- removes in-tree-only BTF kfunc metadata and skips its registration
  (CONFIG_DEBUG_INFO_BTF_MODULES compatibility)

- checks for BBRv3 kernels

The BBRv1 algorithm itself is untouched.

<br />

## Credits

Original idea and approach by [cmspam/bbr_classic](https://github.com/cmspam/bbr_classic).  

## License

GPL-2.0
