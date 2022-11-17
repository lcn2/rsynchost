# rsynchost

## rsync front end - sync to/from a remote host via ssh

```
rsyncfrom - rsync from a remote host to a local directory
rsyncto - rsync from a local directory to a remote host
```

## Usage:

```
rsyncfrom [-options ...] [user@]host[:dir] dest
rsyncto [-options ...] src [user@]host[:dir]
```

## To install:

NOTE: Before installing, we recommend that you verify that you have the latest
release of the [rsynchost repo](https://github.com/lcn2/rsynchost):

```url
https://github.com/lcn2/rsynchost
```

Try:

```sh
$ git pull
```

Then:


```sh
$ make clobber all install
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
XXX: The man pages are being written.  In the mean time run: `rsyncfrom -h` and `rsyncto -h`.
```

## Examples:

Pull a tree from a remote host in verbose mode:

```sh
rsyncfrom -v host.example.org /usr/local/src/bin/name
```

To see what might happen if were to push a tree to a remote host (but don't change anything):

```sh
rsyncto -n -v /var/tmp/foo server.example.com
```

To just see the `cd(1)` and `rsync(1)` (via `ssh(1)`) command needed
to sync a local directory onto a remote host (but don't connect and
don't change anything):

```sh
rsyncto -N -v /project/curds archive.example.net
```
