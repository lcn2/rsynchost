# rsynchost

## rsync front end - sync to/from a remote host via ssh

```
rsyncfrom - rsync from a remote host to a local directory
rsyncto - rsync from a local directory to a remote host
```

## Examples:

Pull a directory tree from a remote host in verbose mode
to a local directory of the same path:

```sh
rsyncfrom -v host.example.org /usr/local/src/bin/name
```

Push a local copy of a directory tree onto the same
path on a remote host:

```sh
rsyncto -v /usr/local/src/bin/curds host.example.org
```

**IMPORTANT:**

```
Because you can do a lot of damage by syncing the wrong thing to/from the wrong host,
we STRONGLY RECOMMEND that you ALWAYS try the command with -n -v options first!
```

The use of `-n -v` will:

- print the effective commands that will be used
- make a connection to the remote host
- go through the syncing motions *without changing anything*
- print some syncing stats

For example:

```sh
rsyncfrom -n -v archive.example.net /project/curds
rsyncto -n -v /project/curds archive.example.net
```

By default, the same path is used on the local host as the remote host.

To sync from a **directory** on a remote host, into a **different** local directory
and sync a local directory into a **different** **directory** on a remote host:

```sh
rsyncfrom -v host.example.org:/var/tmp/testdir /usr/local/src/bin/new
rsyncto -v /usr/local/src/bin/workdir host.example.org:/var/tmp/testdir
```

NOTE: When using the _host:dir_ form, the _dir_ **MUST** be a directory.

Without using the _host:dir_ form, you may sync either a directory tree or just a single file:

```sh
rsyncfrom -v host.example.org /etc/motd
rsyncto -v /etc/motd host.example.org
```

To see what might happen without even connecting to the remote host,
use the `-N -v` options:

```sh
rsyncfrom -N -v archive.example.net /project/curds
rsyncto -N -v /project/curds archive.example.net
```

## To install:

The primary location of the [rsynchost repo](https://github.com/lcn2/rsynchost) is:

```url
https://github.com/lcn2/rsynchost
```

To fetch this repo and move into the sub-directory `rsynchost`:

```sh
git clone https://github.com/lcn2/rsynchost.git
cd rsynchost
```

To update your repo with the latest from the master branch:


```sh
git pull
```

To install under `/usr/local/bin`:


```sh
make clobber all install
```

## Usage:

```
rsyncfrom [-options ...] [user@]host[:dir] dest
rsyncto [-options ...] src [user@]host[:dir]
```

## Common options:

While `rsyncfrom` and `rsyncto` have a number of _-options_, the most common and useful are:

```
-n
```
Connect and run thru the `rsync(1)` motions, but to not change anything

```
-v
```
Print the `cd(1)` and `rsync(1)` operations.  Unless `-N` is used, run `rsync(1)` in verbose mode.

```
-N
```
Print the `cd(1)` and `rsync(1)` operations but do not run `rsync(1)` do not connect, do not change anything.

See the `rsyncfrom(1)` and `rsyncto(1)` man pages for a complete list of  _-options_.

```
XXX: The man pages are being written.  In the mean time run:

```sh
rsyncfrom -h
rsyncto -h
```
```
