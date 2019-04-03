[![Gentoo discord server](https://img.shields.io/discord/249111029668249601.svg?style=flat-square&label=Gentoo%20Linux)](https://discord.gg/Gentoo)

# nop-overlay

This overlay is mostly software I've enjoyed using or other people seem to enjoy using. I'm still new to ebuilds so please be patient with me and if you find a better way to do something, submit an issue.

## Basic usage

### Layman

```
layman -o https://github.com/nopjmp/nop-overlay/raw/master/layman.xml -f -a nop-overlay
```

### repos.conf

```
[nop-overlay]
location = /usr/local/nop-overlay
sync-type = git
sync-uri = https://github.com/nopjmp/nop-overlay.git
auto-sync = yes
```

All software is marked as testing. You'll need to unmask the keywords in your packages.keywords directory/file.

## TODO

Add more memes.
