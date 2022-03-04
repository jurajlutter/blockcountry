# blockcountry

A script for downloading rules from `https://www.ipdeny.com` and applying them
to FreeBSD's `pf` firewall.

Based on https://mirror.ideaz.sk/Software/SAGEtools/Tools/blockcountry.sh

## Usage:

1) Adjust TABLENAME and/or RULEDIR atop of `blockcountry_pf.sh` script

2) Add following or similar rules to `/etc/pf.conf`:

```
    table <countryblock> persist
    block quick log on em0 from <countryblock> to any
```

3) Reload the pf configuration

```
/etc/rc.d/pf reload
```

4) Load the apropriate blocking zones. Example:

```
    blockcountry_pf.sh by cn ru
```

5) Optionally, activate `blockcountry_pf.sh` script in crontab. Example for `/etc/crontab`, each day on 1:00:

```
0   1   *   *   *   root    /usr/local/sbin/blockcountry_pf.sh by cn ru > /dev/null 2&1
```
