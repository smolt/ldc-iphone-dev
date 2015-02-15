# ldc-iphone-dev
LDC (LLVM-base D Compiler) for iPhoneOS development sand box

## License 
Please read the [APPLE_LICENSE](https://github.com/smolt/iphoneos-apple-support/blob/master/APPLE_LICENSE) in directory iphoneos-apple-support before using.  This subdirectory has some modified source code derived from http://www.opensource.apple.com that makes TLS work on iOS.  As I understand it, if you publish an app or source that uses that code, you need to follow the provisions of the license.

LLVM also has its [LICENSE.TXT](https://github.com/smolt/llvm/blob/ios/LICENSE.TXT) and LDC its combined [LICENSE](https://github.com/smolt/ldc/blob/ios/LICENSE).

## Prerequisites
The prerequiste packages are same as listed for LDC build (with my comments in parens):
- a C++ toolchain (I use Xcode since iPhoneSDK is needed to cross compile libraries)
- CMake 2.8+ (I am using cmake-3.1.0-Darwin64.dmg successfully from http://www.cmake.org/download/)
- libconfig++ and its header files (I built from source at http://www.hyperrealm.com/libconfig/)

LLVM in included in subdir llvm since it has been modified to support TLS on iOS.

To really have fun, you will need some way to run on an iOS device. Membership in the iOS Developer Program is one way to do it.

## Build
This is still a work in progress as I gradually cleanup and include by build/test tools in this repo.  I also have very simple iOS apps to include.

Still, you should be able to clone and build this with:

```
$ git clone --recursive https://github.com/smolt/ldc-iphone-dev.git
$ tools/build-all
```

The shell script `build-all` will eventually do some nice checking, but for now mostly just calls `make -j ncpu` to use all your cores but one.

At this point, you will just have a functioning LDC toolchain and libs for 32-bit ARMv7 iOS built.  More to come soon to show how to run phobos unittests on a device and some simple iOS apps.
