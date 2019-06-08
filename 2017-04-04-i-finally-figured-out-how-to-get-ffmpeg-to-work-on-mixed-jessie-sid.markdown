---
layout: post
title: "I Finally Figured Out How to Get FFmpeg to Work on Mixed Jessie/sid"
date: 2017-04-04T23:42:58-07:00
---

**MAJOR EDIT: [DO NOT DO THIS](https://wiki.debian.org/DontBreakDebian)!!**

PLEASE PLEASE avoid using sid/jessie repos at the same time, I SEVERELY broke the apt-get package manager by doing this and ended up not being able to recover. I ended up having to reinstall the entire Debian OS, lmao.


<del>Recently adding the [Debian sid]() repos to my `sources.list`, I found that upgrading a certain few packages related to [`libimobiledevice-dev`](https://wiki.debian.org/iPhone) (in order to transfer photos from my iPhone 6S to my computer) caused other libraries to be needed to be upated. Of course, out of all the possible libraries, one of the libraries that was updated broke FFmpeg.</del>

# <del>Background<del>

<del>I was led on this frustrating adventure by my desire to move pictures from my iPhone to my computer. I could have gone the simple way and just used iTunes or something on a Windows computer, but you know what? It just happens that I have a backup folder already with all my photos on my Debian computer.</del>

<del>Simply the most magical thing about Debian is how I was able to USB transfer all the earlier photos from my phone to my computer without trouble, but I'd get Unhandled lockdown errors whenever I mount my iPhone this time around.</del>

<del>Forgetting to read the portion about using the [`jessie-backports` workaround](https://wiki.debian.org/iPhone#backporting_libimobiledevice_1.1.1_to_Squeeze), I rashly went to use the `sid` repos instead...</del>

# <del>The Problem</del>

<del>A few packages later (using `apt-get dist-upgrade` I think?), I was rather surprised to find that [OBS](https://obsproject.com/) had stopped working. Whenever I'd enter `obs` into terminal, it would spit out something like the following:</del>

``` bash
obs: symbol lookup error: /usr/lib/x86_64-linux-gnu/libass.so.5
undefined symbol: FT_Outline_EmboldenXY
```

<del>No problem. Can't be part of the package update, right... (it was)? I do a quick google search and discovered the [following](http://askubuntu.com/a/659630):</del>

1. <del>This was related to FFmpeg, not actually OBS</del>
2. <del>This works:</del>

``` bash
cd /usr/lib/x86_64-linux-gnu
ffmpeg
```

<del>The latter point was in particular, the most baffling thing about the whole issue. I couldn't comprehend how being in a specific library directory ended up allowing FFmpeg to work. I did not want to have to switch into this directory every time I needed to use FFmpeg, so I decided to attempted to fix the issue by compiling a new version of FFmpeg...</del>

# <del>Fixing it</del>

<del>I decided to recompile FFmpeg to try my luck and see if it is simply a minor library error (?? not even sure what I was thinking at the time).</del>

<del>Now I tried a wide variety of different compile options, including [this nifty script](https://github.com/lutris/ffmpeg-nvenc) which I used previously to install OBS and FFmpeg.</del>

<del>Surprise, surprise. It didn't work.</del>

<del>Knowing that it was a problem with `libass`, I was damned to find that even the FFmpeg build in the `sid` repos did not even work with the `libass` version packaged for that `jessie` or `testing`.</del>

<del>Basically in order to fix the problem, I cannot use dynamic links to the new version of libass, but I needed to retain a static link to the previous one with the FFmpeg binary.</del>

<del>I actually had modified the previous script exactly for this purpose, but in being new to this whole static thing, I mixed up `--enable-shared` and `--enable-static` flags multiple times. It turns out however, that the two don't really have anything in particular that relates them. Unbeknownst to me, I kept trying different combinations of fruitlessly changing the flags only to get linking errors with `x264` and `libass`.</del>

<del>In short, shared vs. static:</del>

1. <del>Shared flag - writes `.so` files to the library path for other binaries that use dynamic libraries to load the library. Newer versions replace this `.so` file with the newer version, thus updating for all binaries using this library.</del>
2. <del>Static flag - does not use `.so` file, but rather an `.a` file that is always the same. Updates do not affect static libraries, as the name "static" implies.</del>

<del>In the end, I went with using [this script](https://github.com/zimbatm/ffmpeg-static), but with a few minor modifications:</del>

``` patch
diff --git a/build.sh b/build.sh
index f94fdbe..cfc8a61 100755
--- a/build.sh
+++ b/build.sh
@@ -160,7 +160,7 @@ make install
 echo "*** Building libvpx ***"
 cd $BUILD_DIR/libvpx*
 [ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
-[ ! -f config.status ] && PATH="$BIN_DIR:$PATH" ./configure --prefix=$TARGET_DIR --disable-examples --disable-unit-tests --enable-pic
+[ ! -f config.status ] && PATH="$BIN_DIR:$PATH" ./configure --prefix=$TARGET_DIR --disable-examples --disable-unit-tests --enable-shared --enable-pic
 PATH="$BIN_DIR:$PATH" make -j $jval
 make install
 
@@ -196,6 +196,7 @@ PKG_CONFIG_PATH="$TARGET_DIR/lib/pkgconfig" ./configure \
   --enable-libvpx \
   --enable-libx264 \
   --enable-libx265 \
+  --enable-nvenc \
   --enable-nonfree
 PATH="$BIN_DIR:$PATH" make -j$NPROC
 make install
```

<del>I made a minor fix to VPX not being able to detected, although I am not completely sure how that is supposed to work.</del>

<del>(Quick note: NVENC capability dynamically loads files from the library path from the nVidia SDK, no compilation needed. I did not add a script to download the files because a) the toolkit requires signing in and b) I already have the files)</del>

# <del>Conclusion</del>

<del>I was eventually able to install OBS using the `ffmpeg-static` build script to build FFmpeg. Everything worked out in the end (except for one minor caveat that `ffplay` is never compiled, I will need to figure that out). If OBS is missing an FFmpeg compile dependency, then use `--enable-shared` to allow OBS to use them as well. Otherwise, errors such as missing `libswrescale` can be fixed using the `sid` packages.</del>
