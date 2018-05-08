# Pixel C kernel build scripts

This is a set of scripts to generate a working kernel for the Pixel C.

## TL;DR

```
git clone https://github.com/q66/linux.git
git clone https://github.com/pixelc-linux/pixelc-kernel-scripts.git
cd pixelc-kernel-scripts
./defconfig.sh ../linux
./build.sh ../linux
./build_fit.sh
ls output
```

## Long version

### Kernel build

A basic build consists of two steps.

Configuration:

```
./defconfig.sh path_to_linux_kernel_tree
```

The configuration used for defconfig is `tegra21_defconfig`. You can override
that with the `KERN_DEFCONFIG` environment variable.

Building:

```
./build.sh path_to_linux_kernel_tree -j5
```

You can also configure the kernel before building:

```
./config.sh path_to_linux_kernel_tree
```

That by default runs `menuconfig`, you can set the config tool to use with
the `KERN_CONFIGTOOL` environment variable (e.g. `gconfig` or `oldconfig`).

The kernel tree must be patched for Pixel C, an upstream kernel tree won't
function correctly.

Replace `-j5` with how many threads you usually use for building. The scripts
by default build out-of-tree in the `build` directory. You can change that
directory with the `KERN_BUILDDIR` variable; you can also make it build in
the kernel tree by specifying `KERN_BUILD_IN_TREE`.

Other accepted variables are:

- `KERN_CROSS_PREFIX` - by default `aarch64-linux-gnu-`, the kernel cross
  toolchain prefix.
- `KERN_NO_CROSS` - set to any value if you want to use the host compiler.

The `build/arch/arm64/boot` directory will afterwards contain an `Image` as
well as device tree blobs.

### Bootable image creation

After the kernel is built, this is not enough to boot it. You need to bundle
the kernel and a corresponding Flattened Device Tree blob into a U-boot .fit
image. For this, you use the `build_fit.sh` script:

```
./build_fit.sh
```

By default, it will attempt to take the files from `build`, as is default
for the other scripts. If you changed the build directory, pass it as the
first argument to the script.

The result will be in `output`. If you don't want that, pass your own path
as the second argument to the script.

### Booting

Now you only need a ramdisk. You can create one or obtain a pre-built one
from another repository:

https://github.com/pixelc-linux/pixelc-mkinitrd.sh

You can then boot the kernel + the ramdisk using `fastboot`:

```
fastboot boot Image.fit initrd.img
```

Once you have verified it successfully boots, you might want to flash it
onto the device. However, the device won't boot unsigned images, therefore
you need to sign it using Chrome OS keys and the `futility` tool.

### Signing

TBD.
