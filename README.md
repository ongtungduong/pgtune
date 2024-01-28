# PGTune

## Parameters

* `-c`: number of CPU cores - Example: 4

* `-r`: RAM size in GB - Example: 16

* `-t`: type of database - Options: `web`, `oltp`, `dw`, `desktop`, `mixed`

* `-k`: number of connections - Example: 600

* `-d`: type of hard drive - Options: `ssd`, `hdd` - (default: ssd)

* `-o`: output format - Options: conf, sql - (default: conf)

**RAM and TYPE are required!**

## How to use

**Get pgtune**

```console
curl https://raw.githubusercontent.com/ongtungduong/pgtune/main/pgtune.sh > /usr/local/bin/pgtune
chmod +x /usr/local/bin/pgtune
```

**Show pgtune manual**
```console
pgtune help
```
