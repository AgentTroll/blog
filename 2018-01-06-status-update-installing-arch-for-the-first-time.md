---
layout: post
title: "Status Update: Installing Arch for the First Time"
date: 2018-03-03T01:19:40-07:00
---

It’s been draining on the soul, but luckily coming up with a “unique” title has been rejuvenating (rejuvinatig? rejuvenating? whatever).

I don’t profess to be an expert on ArchLinux, or even Linux in general but based on my experience installing Arch on my MacBook Pro 11.something, I’d be even more wary of following a random blog post (because it probably won’t work). I don’t think any of the issues that I encountered were unique by any means, but I believe my own little successes are the result of the wealth of mainly online resources. I’m therefore very keen to share my own experience and perhaps someone might come along and save a few hours of their lifetime and hair-tearing.

# Getting Over the Hurdle

For me, the primary challenge in the first place was connecting to the Internet. To go along with that, my MacBook carries with it a Broadcom Wireless interface, which requires a proprietary driver in order to work correctly. Fortunately, it was just the right hardware that happened to work with the proprietary driver. Unfortunately, the driver requires the Internet to obtain, and my USB was all occupied with carrying the bootable ISO. Therefore, the only way I can get the required packages is by exiting the Arch CLI and manually downloading on macOS, then going back and mounting whatever partition on which I downloaded the package.

First lesson here: it is impossible to install Arch without access to another installation with Internet. Let me repeat that: **IMPOSSIBLE**. If you are rich and can buy an ethernet/thunderbolt adapter, go nuts, save yourself some time. Otherwise, you must at least have a VM that boots the Arch ISO in order to download the packages. I’ll spare the gory details of trying to compile `broadcom-wl`, which consisted of failing to compile due to Internet requirements, not realizing that you can’t get the right kernel version without rebooting, and thinking that `mkinitcpio` will save my butt (It didn’t).

Secondly, to install packages on a different computer, you must A) Know how how to install Arch B) Get the built packages and C) Get those packages onto the laptop. Honestly, I messed up enough times without Internet access in the first place just dealing with A: formatting the wrong partition (luckily the USB /dev/sdb) multiple times before I figured out why my bootable USB wasn’t bootable anymore, dealing with `mount -o force ...` in order to be able to write, and forgetting to mount the target partition. Needless to say, there was lots of `rm -fR /`, but at the same time, the repetition drilled in deep the commands required, so I got faster and faster at failing. Better to fail quickly than slowly I suppose.

In short, the process went something like so for me: mount temp partition from the VirtualBox “disk,” then run the following:

``` shell
pacman -Sy
pacman -S --cachdir . --dbpath /tmp base base-devel linux-headers broadcom-wl-dkms wpa_supplicant
```

And then transfer the all the .pkg files onto macOS using nc. Once I have them, I can then put them on a mounted transfer partition that I used to access those files more easily from the boot CLI.

# Finally, Installation
The truth is that in order to install the base system, one only needs the base package, and that’s it. In short, you need to do the following in order to “install” Arch:

  1. `cgdisk` and format the partition
  2. Mount desired partition
  3. Mount the `/boot` partition
  4. `pacstrap` the desired repo with the base arg
  5. Chroot into the mount dir
  6. Create `systemd-boot` entry for the correct partition
  7. Reboot

I won’t go into specifics here, since firstly I’m not a very good source of info and secondly, because these are quite easy steps that you can find on the Internet. Again, needless to say, I messed up on multiple occaisions here: `cgdisk` on the wrong disk, forgetting to mount `/boot` and ending up with an unbootable system, writing the wrong partition UUID to `systemd-boot`, etc…

It is absolutely vital that you are able to reboot. This is the only way that you can update to the correct kernel version and access your modules, and I guarantee that a successful boot is the most important milestone here, even if you aren’t able to connect to the WiFi quite yet.

# The WiFi Problem

Back to our initial issue, although we have Arch installed without using the Internet on the target machine, we still do not have Internet access. Luckily, having the `broadcom-wl-dkms` file on our transfer partition, we can `pacman -S` that very easily. Having already confirmed that the kernel has been updated, we can safely restart and see through `ip a` that the driver has successfully detected the network interface - a good sign.

For me, this all happened at school, where the WiFi setup was a little more complicated since we used WPA Enterprise, so I had to wait until I got home.

The good news came late at night, when I was toying with `wpa_supplicant`. I was able to use `wpa_password` to generate the config, but not realizing that I needed to also set the `ap_scan` and ssid scan in order to detect my network (which had SSID masking enabled), I was finally able to connect to the Internet. Content with Internet access for the time being, I got to installing and setting up a few other personal neccessities:

  * Xorg
  * Display Manager (LightDM)
    - Careful, you also need the locker (I used gtk) for it to work!
  * i3wm, dmenu
  * Users
  * `chromium`
  * `xfce4-terminal`

But since the entire idea of my laptop was that it was portable, and I already had a well-established Debain computer at home, I was bent on getting WiFi to work at my school. That wouldn’t happen for another several weeks though; it was winter break, and I didn’t plan on going to school at all to test whether or not my config worked.

# The Breakthrough

It takes only a few seconds to look at the massive variety in responses to the “proper” config for WPA Enterprise one can find on Google, but as it turns out, whatever people say “works for them” is very blatantly BS. The config depends entirely on the network, and there is no way around having to try out different combinations of “WPA-EAP/IEEE801X…” and “CCMP/TKIP/…” and other options that I still have no interest in. However, recalling that I have a handy MacBook, I booted into macOS to see if I can get some hints by connecting to the WiFi, which I already knew worked splendidly without any hassle. From there, I knew that I could use “WPA-EAP” and “PEAP” options, and the rest goes guess-and-check.

For my own future reference, this is what I used:

```
Description='Automatically generated profile by wifi-menu'
Interface=wlp2s0
Connection=wireless
Security=wpa-configsection
ESSID=$SSID
IP=dhcp
WPAConfigSection=(
        'ssid="$SSID"'
        'proto=RSN'
        'key_mgmt=WPA-EAP'
        'eap=PEAP'
        'identity="$USERNAME"'
        'password="$PASSWORD"'
        'phase1="peaplabel=auto peapver=0"'
        'phase2="auth=MSCHAPV2"'
)
```

# Final Thoughts

Although trying a CLI-based install for the first time was an interesting experience, and I felt like I learned a lot from it compared to a more graphical nod that Debian takes, it still was frustrating and uncooperative even at the best of times. I’m happy with the end result, even if it’s not perfect though, and as always, the pleasure and satisfaction that comes with finally wrangling something to work is much more powerful than the ordeal that it takes to acheive that.

Although it *would* be nice if I could actually see anything, I still haven’t figured out that HiDPI thing yet…
