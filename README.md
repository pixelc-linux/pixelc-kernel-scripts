# Pixel C kernel build scripts

This is a set of scripts to generate a working kernel for the Pixel C.

## TL;DR

```
git clone https://github.com/q66/linux.git
git clone https://github.com/pixelc-linux/pixelc-kernel-scripts.git
cd pixelc-kernel-scripts
./defconfig.sh ../linux
./build.sh ../linux
ls build/arch/arm64/boot
```

## Long version

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