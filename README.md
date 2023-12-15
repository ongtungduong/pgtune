# PGTune

## Parameters

* `CPU`: number of CPU cores - Example: 4

* `RAM`: RAM size in GB - Example: 8

* `TYPE`: type of database - Options: `web`, `oltp`, `dw`, `desktop`, `mixed`

* `CONNECTIONS`: number of connections - Example: 400

* `HARD_DRIVE`: type of hard drive - Options: `ssd`, `hdd`

**RAM and TYPE are required!**
 

## Clone the repository

```console
git clone https://github.com/ongtungduong/pgtune.git
cd pgtune
```

## How to use

**Remember to change the values of `CPU`, `RAM`, `TYPE`, `CONNECTIONS` and `HARD_DRIVE` in the file `params.env` before running command**

To get conf type configuration, run the following command:
```console
make conf > pgtune.conf
```

To get sql type configuration, run the following command:
```console
make sql > pgtune.sql
```


