# ldc-iphone-dev
An LDC (LLVM-base D Compiler) development sandbox for iPhone iOS.

This [repo](https://github.com/smolt/ldc-iphone-dev) glues together various pieces needed to build an LDC cross compiler targeting iPhoneOS.  It also includes a few samples to show how to get started.  The compiler and libraries are in good enough shape to pass the druntime/phobos unittests with a few minor test failures (see [Unittest Status](#unittest-status) below).  This means someone could, if so inclined, build their D library and use it in an iOS App.  In theory.

Versions derived from: LDC 0.15.1 (DMD v2.066.1) and LLVM 3.5.1.

There is still stuff to [work on](#what-is-missing), but overall the core D language is ready to try on iOS.

## License 
Please read the [APPLE_LICENSE](https://github.com/smolt/iphoneos-apple-support/blob/master/APPLE_LICENSE) in directory iphoneos-apple-support before using.  This subdirectory has some modified source code derived from http://www.opensource.apple.com that makes TLS work on iOS.  As I understand it, if you publish an app or source that uses that code, you need to follow the provisions of the license.

LLVM also has its [LICENSE.TXT](https://github.com/smolt/llvm/blob/ios/LICENSE.TXT) and LDC its combined [LICENSE](https://github.com/smolt/ldc/blob/ios/LICENSE).

## Prerequisites
You will need an OS X host and Xcode.  I am currently on Mavericks 10.9 and Xcode 6.1.1.

The prerequisite packages are pretty much the same as listed for [building LDC](http://wiki.dlang.org/Building_LDC_from_source) with my comments in parentheses:

- git
- a C++ toolchain (use Xcode since iPhoneSDK is needed anyway to cross compile C in druntime/phobos and to run on an iOS device)
- CMake 2.8+ (I am using cmake-3.1.0-Darwin64.dmg from http://www.cmake.org/download/.  You will need to install command line tools by running CMake app and using install command line menu choice)
- libconfig++ and its header files (I built from source downloaded from http://www.hyperrealm.com/libconfig/)
- libcurl (needed by std.net.curl but I have not built for iOS yet. On TODO list)

LLVM is included as a submodule since it has been modified to support TLS on iOS.  No other LLVM will work.

To really have fun, you will need some way to run on an iOS device. Membership in the iOS Developer Program is one way to do it.

## Build
Download with git and build:

```
$ git clone --recursive https://github.com/smolt/ldc-iphone-dev.git
$ cd ldc-iphone-dev
$ tools/build-all
```

and grab a cup of coffee.  It will build LLMV, LDC, druntime, phobos,
and iphone-apple-support.  LLVM takes the longest by far, but probably
only needs to be built once.  The shell script `build-all` may eventually do some nice checking, but for now mostly just calls `make -j n` where `n` is all your cores but one.

You can quickly try the resulting compiler yourself by typing:

```
$ tools/iphoneos-ldc2 -c hello.d
```

This only gives you a .o file but using Xcode and a provisioning profile you could link, codesign, bundle, and run it on an iOS device.  A sample Xcode [project](#sample-hellod-project) does just that if you have a provisioning profile.

At this point, you have an LDC toolchain and druntime/phobos built for 32-bit armv7 iOS in `build/ldc`.  This ldc2 is actually configured to target all iOS devices from original iPhone (armv6) to iPhone 6 (arm64).   My only iOS devices are armv7 so that is the only target being built.  Plus, all iOS device from iPhone 3gs, iPod 3, AppleTV and up can run armv7 instructions [(see Device Compatability)](https://developer.apple.com/library/ios/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/DeviceCompatibilityMatrix/DeviceCompatibilityMatrix.html).  The equivalent gcc or clang target is armv7-apple-darwin, but under the hood in LLVM it is really thumbv7-apple-ios with cortex-a8 selected to enable neon and vfp3.

`iphoneos-ldc2` is nothing more than a script that does this:

```
$ build/ldc/bin/ldc2 -mtriple=thumbv7-apple-ios5 -mcpu=cortex-a8 -c hello.d
```

This script makes it easy to manage compiler defaults.  Clang presets many options when compiling for iOS based on the -arch switch but these presets are not in ldc2 main yet.  For now I think it is easier to tweak options with the iphoneos-ldc2 script.  Eventually ldc2 will be taught the iOS clang preset options for each iOS arch: armv6, armv7, armv7s, and arm64.

The ldc2 in build/ldc/bin can also target x86 and x86_64.  This is for eventual use of the iPhone Simulator.  Unfortunately you cannot run LDC compiled source on iPhone Sim yet because ld refuses to link files with OS X thread local variables when targeting iPhone Sim.  I assume this is just to prevent running code on the sim that cannot run in iOS.  I think we can get around this by using our own ld or using a different TLS approach that ld won't detect.

More will eventually be added to tools.  It is could be useful to add tools to your PATH.

## Sample helloD Project
[helloD](https://github.com/smolt/ldc-iphone-dev/tree/master/helloD) is a barebones Xcode project with four simple targets.  It only uses the console to demonstrate LDC compiled code running on an iOS device.

- hello_nolibs - the simplest barebones D without reliance on any D libs or libiphoneossup (not needed if TLS not used).
- helloD_druntime - a demo of various things in druntime including threads, TLS vars, and garbage collection.
- helloD - just hello using phobos std.stdio.writeln.
- objc_helloD - demo of how an Objective-C (or C or C++) main can use D.

## Unittests
An Xcode project called [unittester](https://github.com/smolt/ldc-iphone-dev/tree/master/unittester) is included that has targets for running the druntime and phobos unittests.  Two are D only with output to the console (nothing to see on the iOS device besides a black screen).  The other two are simple scrolling text apps that show the D unittest output as it runs.  These apps manage the UI with Objective-C and run the D unittests in another thread.

You can build and run the console druntime/phobos unittests from the shell.  Here I am running on my iPad mini (cortex-a9):

```
$ make -j 3 unittest
$ xcodebuild -project unittester/unittester.xcodeproj -destination "platform=iOS,name=Dan's iPad" test -scheme debug

=== BUILD TARGET unittester-debug OF PROJECT unittester WITH CONFIGURATION Debug ===
...
Testing 1 core.atomic: OK (took 0ms)
Testing 2 core.bitop: OK (took 0ms)
Testing 3 core.checkedint: OK (took 0ms)
Testing 4 core.demangle: OK (took 17ms)
...
Testing 113 std.zlib: OK (took 96ms)
Passed 112 of 113 (4 have tailored tests), 60 other modules did not have tests
Restoring FPU mode

$ xcodebuild -project unittester/unittester.xcodeproj -destination "platform=iOS,name=Dan's iPad" test -scheme release

=== BUILD TARGET unittester-release Tests OF PROJECT unittester WITH CONFIGURATION Debug ===
...
Testing 1 core.atomic: OK (took 0ms)
Testing 2 core.bitop: OK (took 0ms)
Testing 3 core.checkedint: OK (took 0ms)
Testing 4 core.demangle: OK (took 10ms)
...
Testing 113 std.zlib: OK (took 92ms)
Passed 110 of 113 (5 have tailored tests), 60 other modules did not have tests
Restoring FPU mode
```

Note: that iOS by default runs with the ARM FPU "Default NaN" and "Flush to Zero" modes enabled.  In order to pass many of the math unittests, these modes are disabled first.  This is something to consider if you are doing some fancy math and expect full subnormal and NaN behavior.

### Unittest Status
Most druntime and phobos unittests pass.  All except one are math
related.

- std.csv - a couple floating point off-by-one LSB differences
- std.internal.math.gammafunction - needs update for 64-bit reals
- std.math - floating point off-by-one LSB error in a few cases

Some failures only occur with optimization on (-O1 or higher):

- std.internal.math.errorfunction - erfc() NaN payload fails
- std.math - acosh() not producing NaN in a couple cases
- core.thread - a Fiber unittest crashes on multicore devices

All the failures are marked in the druntime and phobos source with
versions that begin with "WIP" to workaround the failure so rest of
test can run.  Grep for "WIP" to see all the details.

I think the only unittest failures to consider if using D in an iOS App would be the Fiber crash and possibly the acosh() if you are doing interesting math.

## What is Missing
Or what is left to do.

- Make prebuilt binaries
- Add libcurl to enable std.net.curl
- Ability to run on iPhone Simulator
- Ability run on arm64 devices - not tried yet
- Make symbolic debugging work - there is some dwarf incompatability so debug builds don't have -g turned.  The debug libs are just non-optimized, non-release builds for now.
- Objective-C interop - work in progress under [DIP 43](http://wiki.dlang.org/DIP43)
- APIs for iPhone SDK - [DStep](https://github.com/jacob-carlborg/dstep) helps here
- Build universal libs
- Xcode/D integration - needs someone who loves working with Xcode
- A D-based iOS App submitted to Apple App Store
- A D-based iOS App accepted by the Apple App Store!
- Figure out what else is left to do
