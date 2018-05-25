# Pixel C kernel build scripts

This is a set of scripts to generate a working kernel for the Pixel C.

## TL;DR

```
git clone https://github.com/pixelc-linux/linux.git
git clone https://github.com/pixelc-linux/pixelc-kernel-scripts.git
git clone https://github.com/pixelc-linux/pixelc-mkinitramfs.sh.git
cd pixelc-kernel-scripts
./defconfig.sh ../linux
./build.sh ../linux
./make_zimage.sh
cd ../pixelc-mkinitramfs.sh
./mkinitramfs.sh -o ../pixelc-kernel-scripts/initramfs.cpio
cd ../pixelc-kernel-scripts
cp output/Image.fit .
# if you want to just boot
fastboot boot Image.fit initramfs.cpio.gz
# if you want to flash
./make_image.sh Image.fit initramfs.cpio.gz
./sign_image.sh
fastboot flash boot boot.img
fastboot boot boot.img
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
image. For this, you use the `make_zimage.sh` script:

```
./make_zimage.sh
```

By default, it will attempt to take the files from `build`, as is default
for the other scripts. If you changed the build directory, pass it as the
first argument to the script.

The result will be in `output`. If you don't want that, pass your own path
as the second argument to the script.

### Booting

Now you only need a ramdisk. You can create one or obtain a pre-built one
from another repository:

https://github.com/pixelc-linux/pixelc-mkinitramfs.sh

You can then boot the kernel + the ramdisk using `fastboot`:

```
fastboot boot Image.fit initramfs.cpio.gz
```

Once you have verified it successfully boots, you might want to flash it
onto the device. However, the device won't boot unsigned images, therefore
you need to sign it using Chrome OS keys and the `futility` tool.

### Signing

#### Generating a complete unsigned image

First, you will need to create a single unsigned boot image using your
kernel and ramdisk. For that, you will use the `make_image.sh` script.

```
./make_image.sh output/Image.fit path/to/initramfs.cpio.gz
```

This script uses the Android `mkbootimg` tool. If it's not present in `PATH`,
you can point the script to it using the `MKBOOTIMG` environment variable.

This creates a `boot.img.unsigned` file. If you don't like that name for some
reason, you can pass your own name using the third parameter to the script.

#### Signing the image

The final script here is `sign_image.sh`. It requires the `futility` tool
as well as ChromeOS developer keys. You can typically find both in a package
named `vboot-kernel-utils` or so.

If you don't have `futility` in `PATH`, you can point the script to it using
the `FUTILITY` environment variable. Also, if `/usr/share/vboot` is not the
default path to the keys, you can specify `VBOOT_PATH` as well. This path
is checked for the presence of `devkeys/kernel_data_key.{vpubk,vprivk}`.

If you satisfy both conditions, run the script:

```
./sign_image.sh
```

This assumes there is a `boot.img.unsigned`. If you changed the filename,
pass it as the first argument to the script. It will emit a `boot.img` by
default; you can change that by passing your desired filename as the second
argument to the script.

### Flashing

Once you have a signed image, you can flash it onto your Pixel C. You do
that normally using `fastboot`:

```
fastboot flash boot boot.img
fastboot boot boot.img
```

The device should boot, assuming your kernel, ramdisk and root filesystem
are correctly set up.
