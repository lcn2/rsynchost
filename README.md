# rsynchost

## rsync front end - sync to/from a remote host via ssh

* rsyncfrom - rsync from a remote host to a local directory

* rsyncto - rsync from a local directory to a remote host


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


# Examples

Pull a directory tree from a remote host in verbose mode
to a local directory of the same path:

```sh
$ /usr/local/bin/rsyncfrom -v host.example.org /usr/local/src/bin/name
```

Push a local copy of a directory tree onto the same
path on a remote host:

```sh
$ /usr/local/bin/rsyncto -v /usr/local/src/bin/curds host.example.org
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
$ /usr/local/bin/rsyncfrom -v host.example.org:/var/tmp/testdir /usr/local/src/bin/new
$ /usr/local/bin/rsyncto -v /usr/local/src/bin/workdir host.example.org:/var/tmp/testdir
```

NOTE: When using the _host:dir_ form, the _dir_ **MUST** be a directory.

Without using the _host:dir_ form, you may sync either a directory tree or just a single file:

```sh
$ /usr/local/bin/rsyncfrom -v host.example.org /etc/motd
rsyncto -v /etc/motd host.example.org
```
$ /usr/local/bin/
To see what might happen without even connecting to the remote host,
use the `-N -v` options:

```sh
$ /usr/local/bin/rsyncfrom -N -v archive.example.net /project/curds
$ /usr/local/bin/rsyncto -N -v /project/curds archive.example.net
```


# To use


## rsyncfrom - rsync from a remote host to a local directory

```
/usr/local/bin/rsyncfrom [-options ...] [user@]host[:dir] dest

	-a	resolve directories to an absolute path from / (def: use directory paths as is)
	-C	rsync will exclude a broad range of files that you often don't want to transfer (def: don't exclude)
	-d	transfer directories without recursing (def: recursively transfer the directory tree)
	-E	macOS only: copy extended attributes, resource forks, enable filesystem caching (def: don't)
	-f	delete a non-empty directory when it is to be replaced by a non-directory (def: don't)
	-i	internal shell variable values printed (def: don't)
	-h	print help and exit (def: don't)
	-k	keep all files in the destination, do not delete anything (def: delete as needed)
	-m	prune empty directory chains from file-list (def: don't)
	-n		trial run: transfer nothing, do not remove nor create anything, use rsync with -n (def: do as needed)
	-N		do not execute rsync, implies -n (def: execute rsync)
	-p port		use ssh over TCP port (def: 22)
	-P port		alias for -p num (def: 22)
	-q		quiet operation (def: normal output)
	-s		skip creating files and directories that do not exist on the destination (def: create as needed)
	-S		skip creating files and directories that already exist on the destination (def: create as needed)
	-t tool=path	use tool from path where tool may be one of: hostname ssh rsync dirname basename (def: use well known path)
	-u		skip files that are newer in the destination (def: don't)
	-x	do not cross filesystem boundaries when recursing (def: do)
	-v	verbose output, show progress of transfer, print transfer stats (def: normal output, no progress nor stat info)
	-V	print version and exit (def: don't)
	-z	compress via ssh, not via rsync (def: compress via rsync only)

	user	copy as user on remote host (def: current user)
	host	host to transfer from
	dir	optional copy from under remote host directory dir (def: use dest, in which case dest may be a file)
	dest	destination on current host to transfer to

See rsyncfrom(1) man page for more details.

Exit codes:
     0      all is well
     1-89   rsync and/or ssh error
    92	    help mode or print version
    93	    invalid command line
    94	    already on remote host
    95	    cannot create parent directory of dest
    96	    cannot cd to parent directory of dest
    98	    cannot determine basename of dest
   100-109  critical tool not executable or not found
 >=110      internal error

/usr/local/bin/rsyncfrom: version: 1.25.1 2025-04-13
```


## rsyncto - rsync from a local directory to a remote host

```
/usr/local/bin/rsyncto [-options ...] src [user@]host[:dir]

	-a	resolve directories to an absolute path from / (def: use directory paths as is)
	-C	rsync will exclude a broad range of files that you often don't want to transfer (def: don't exclude)
	-d	transfer directories without recursing (def: recursively transfer the directory tree)
	-E	macOS only: copy extended attributes, resource forks, enable filesystem caching (def: don't)
	-f	delete a non-empty directory when it is to be replaced by a non-directory (def: don't)
	-i	internal shell variable values printed (def: don't)
	-h	print help and exit (def: don't)
	-k	keep all files in the destination, do not delete anything (def: delete as needed)
	-m	prune empty directory chains from file-list (def: don't)
	-n		trial run: transfer nothing, do not remove nor create anything, use rsync with -n (def: do as needed)
	-N		do not execute rsync, implies -n (def: execute rsync)
	-p port		use ssh over TCP port (def: 22)
	-P port		alias for -p num (def: 22)
	-q		quiet operation (def: normal output)
	-s		skip creating files and directories that do not exist on the destination (def: create as needed)
	-S		skip creating files and directories that already exist on the destination (def: create as needed)
	-t tool=path	use tool from path where tool may be one of: hostname ssh rsync dirname basename (def: use well known path)
	-u		skip files that are newer in the destination (def: don't)
	-x	do not cross filesystem boundaries when recursing (def: do)
	-v	verbose output, show progress of transfer, print transfer stats (def: normal output, no progress nor stat info)
	-V	print version and exit (def: don't)
	-z	compress via ssh, not via rsync (def: compress via rsync only)

	src	source of current host to transfer
	user	copy as user on remote host (def: current user)
	host	host to transfer to
	dir	optional destination directory on the remote host (def: use as parent directory of src)

See rsyncto(1) man page for more details.

Exit codes:
     0      all is well
     1-89   rsync and/or ssh error
    92	    help mode or print version
    93	    invalid command line
    94	    already on remote host
    95	    cannot determine the parent directory of src
    96	    cannot cd to parent directory of src
    97	    src not found
    98	    cannot determine basename of src
   100-109  critical tool not executable or not found
 >=110      internal error

/usr/local/bin/rsyncto: version: 1.25.1 2025-04-13
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



# Reporting Security Issues

To report a security issue, please visit "[Reporting Security Issues](https://github.com/lcn2/rsynchost/security/policy)".
