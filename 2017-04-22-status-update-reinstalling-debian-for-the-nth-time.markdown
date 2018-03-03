---
layout: post
title: "Status Update: Reinstalling Debian (for the Nth Time)"
date: 2017-04-22T23:30:03-07:00
---

It's really not something I do everyday, but apparently, since I've broken my Debian computer so many damn times that I kinda have a routine of what programs to install and what packages to use. There were a few interesting changes and things that I've learned from my most recent failure (see [my previous post for the retardation]({{ site.url }}/blog/2017/04/04/i-finally-figured-out-how-to-get-ffmpeg-to-work-on-mixed-jessie-sid.html)).

# Initial Setup

I'm forever in love with 3 tools in particular, [Albert Launcher](https://github.com/albertlauncher/albert), tmux, and [compiled Vim](https://github.com/Valloric/YouCompleteMe/wiki/Building-Vim-from-source) (which I should note also requires Ruby and Python, which I use [rbenv](https://github.com/rbenv/rbenv) and [pyenv](https://github.com/pyenv/pyenv) respectively).

I had no issues installing Albert, for it was a precompiled package. However, I had considerable trouble trying to get tmux to play nicely with [powerline](https://github.com/powerline/powerline). One of the confusing things was the way you install powerline is actually using python's pip, which came bundled with the `2.7.9` version that I was using from `pyenv`. Depending on what you used to install powerline, the `--user` flag was used in the official documentation, which placed the package in a different directory than if you had installed it without (the `--user` flag would place it in `.local`, while without the flag, it would place the package in `~/.pyenv/versions/2.7.9/...`). Using `pip show powerline-status` will show you where the powerline directory is stored, and I finished the rest after finding this [well-written post on AskUbuntu](https://askubuntu.com/a/283909).

Further, another little quirk about pyenv is that it does not automatically install its dependencies, you must look at what you need to install [here](https://github.com/pyenv/pyenv/wiki/Common-build-problems). The same cannot be said for `rbenv`, however you must also (ironically) [install the `install`](https://github.com/rbenv/ruby-build) command in order to install it in the first place.

So back to actually installing tmux itself, the issue was trying to get the command prompt to render correctly, as it would be cut off after my username. I later also got the classic "everything is bold" bug in tmux, but both were fixed by adding the following to my `.bashrc`:

``` bash
export TERM=xterm-256color
```

After that, everything worked like charm. I then installed vim and XFCE, removing all the GNOME packages except for the theme (I like the theme actually).

# NVIDIA drivers

Ah, the bane of linux gaming, installing GPU drivers. For the past few years, I've used the proprietary ones off of the Nvidia site, but I decided to take the ones packaged in `jessie-backports` for a spin this time (the reason being that they have the new 375 drivers). I ran into the same roadblock a few dozen times, when DKMS and the `xorg` nvidia package kept getting stuck. Evidently, the way to fix this was actually to stop XDM, but my intuition was uh... Not exactly up to par the few dozen times that I did it. I even went so far as to attempt to build from source using the `deb-src` repository for `jessie-backports`, again getting stuck with the dependencies issue. However, just remember to shutoff your window manager for like 15 minutes while it installs, and then when `apt-get` finishes with an error on the `xorg` package, just reboot and the problem should be solved (`sudo dpkg --configure -a` may be needed). The NVIDIA drivers are exceptionally awkward to resolve because one needs to keep rebooting and repeating the reconfiguration until the dependencies are resolved.

As with the classic setup, I also [blacklisted `nouveau`](https://askubuntu.com/questions/481414/install-nvidia-driver-instead-nouveau) as well.

# Other things I install

Some of the other packages I install are Google Chrome, Jetbrains Toolbox (along with a few IDEs), and [Infinality](https://github.com/cmpitg/infinality-debian-package). I also use [sdkman](http://sdkman.io/) for quite a few different things such as Java/Maven. I also do quite a bit of customization on other things such as installing a solarized-light theme for xfce-terminal, and other font related changes.

# Back to the FFmpeg problem...

After breaking my system after that episode, I was eagar to reinstall FFmpeg and OBS the correct way this time. Ironically, I AGAIN broke my system in the process of writing this blog post by removing all the GNOME packages and borking with `polkit`. So in fact, I had to redo everything previously written in the process of describing my installation process, and again got close to breaking the DM by forgetting to reconfigure.

Anyways, with that debacle over, I found to my surprise that using [the script](https://github.com/lutris/ffmpeg-nvenc) I had used in the previous article did not work. However, with some digging around, I was finally able to get it to work after about a week:

1. The first problem was dependency conflicts. `libvdpau-dev` and `libva-dev` and any other libraries that conflict with the `jessie` packages need to be removed from the installer script and installed using:

``` bash
sudo apt-get install -t jessie-backports libvdpau-dev libva-dev # And any other conflicts
```

2. Run the script: `sudo ./build.sh -o -d /usr/local`. No problems here.

3. Optional: I replaced the NVENC header files with a newer version that I downloaded off the NVIDIA site.

4. Starting both `ffmpeg` and `obs` should produce an error that looks something like:

``` bash
error while loading shared libraries: libavdevice.so.57: cannot open shared object file
```

5. Open up `/etc/ld.so.conf` and use the following lines (libav and nvenc links) - [Source](https://forum.ivorde.com/ffmpeg-error-while-loading-shared-libraries-libavdevice-so-52-cannot-open-shared-object-file-no-t129.html):

```
include /etc/ld.so.conf.d/*.conf
/usr/local/lib
/usr/lib/x86_64-linux-gnu/nvidia/current
```

6. OBS should have an error having to do with not being able to find `libcuda.so` and `libnvidia-encode.so`. These files are provided by installing the following libraries:

``` bash
sudo apt-get install -t jessie-backports libnvidia-encode1 libcuda1
```

7. Run `sudo ldconfig` to create the links

8. Open up OBS and profit

# Conclusion

Getting myself up to speed was a hell of a joyride...
