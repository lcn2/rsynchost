#!/usr/bin/env bash
#
# rsyncto - rsync a local directory to a remote host
#
# Copyright (c) 2001-2014,2022 by Landon Curt Noll.  All Rights Reserved.
#
# Permission to use, copy, modify, and distribute this software and
# its documentation for any purpose and without fee is hereby granted,
# provided that the above copyright, this permission notice and text
# this comment, and the disclaimer below appear in all of the following:
#
#       supporting documentation
#       source copies
#       source works derived from this source
#       binaries derived from this source or from derived source
#
# LANDON CURT NOLL DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
# INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
# EVENT SHALL LANDON CURT NOLL BE LIABLE FOR ANY SPECIAL, INDIRECT OR
# CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF
# USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.
#
# chongo <was here> /\oo/\
#
# Share and enjoy!

# parse args
#
export RSYNCTO_VERSION="1.19 2022-11-11"
USAGE="usage: $0 [-h] [-q] [-v] [-V] [-C] [-d] [-E] [-f] [-k] [-m] [-n] [-p num] [-P num] [-u] [-x] [-z] dir [user@]host[:dest]

	-h	print help and exit
	-q	quiet operation
	-v	verbose output, showing the progress of the transfer, print transfer stats
	-V	print version and exit

	-C	exclude RCS, CVS, tmp, .o, .a, .so, .Z, .orig, .rej, .BAK ...
	-d	transfer directories without recursing
	-E	macOS only: copy extended attributes and enable filesystem caching (def: don't)
	-f	force deletion of dirs even if not empty
	-k	keep all files in the remote host, do not delete anything
	-m	prune empty directory chains from file-list
	-n	trial run, transfer nothing
	-p num	Change the ssh TCP port to num (default: 22)
	-P num	alias for -p num (default: 22)
	-u	skip files that are newer on the remote host
	-x	not to cross filesystem boundaries
	-z	compress via ssh, not via rsync (def: compress via rsync only)

	dir	directory on current host to transfer
	user	copy as user on remote host (def: current user)
	host	host to transfer to
	dest	destination directory on the remote host (def: dir)

rsyncto: rsync a local directory to a remote host

Exit codes:
     0      all is well

     1-89   rsync error

    92	    help mode or print version
    93	    invalid command line

    94	    already on remote host
    95	    cannot determine the parent directory of dir
    96	    cannot cd to parent directory of dir
    97	    dir not found
    98	    cannot determine basename of dir

   100-109  critical tool not executable or not found

 >=110      internal error

$0: version: $RSYNCTO_VERSION"
C_FLAG=
D_FLAG=
CAP_E_FLAG=
F_FLAG=
K_FLAG=
M_FLAG=
N_FLAG=
P_FLAG="22"
Q_FLAG=
U_FLAG=
V_FLAG=
X_FLAG=
Z_FLAG=
export C_FLAG D_FLAG F_FLAG CAP_E_FLAG K_FLAG M_FLAG N_FLAG P_FLAG Q_FLAG U_FLAG V_FLAG X_FLAG Z_FLAG
while getopts :CdEfhkmnp:P:quxvVz flag; do
    case "$flag" in
    C) C_FLAG="true" ;;
    d) D_FLAG="true" ;;
    E) CAP_E_FLAG="true" ;;
    f) F_FLAG="true" ;;
    h) echo "$USAGE";
	exit 92;
	;;
    k) K_FLAG="true" ;;
    m) M_FLAG="true" ;;
    n) N_FLAG="true" ;;
    p) P_FLAG="$OPTARG"; ;;
    P) P_FLAG="$OPTARG"; ;;
    q) Q_FLAG="true" ;;
    u) U_FLAG="true" ;;
    v) V_FLAG="true" ;;
    V) echo "$RSYNCTO_VERSION";
	exit 92;
	;;
    x) X_FLAG="true" ;;
    z) Z_FLAG="true" ;;
    \?) "$0: ERROR: invalid option: -$OPTARG" 1>&2;
	exit 93;
	;;
    :)  echo "$0: ERROR: option -$OPTARG requires an argument" 1>&2;
	exit 93
	;;
    *)
	;;
    esac
done
shift $(( OPTIND - 1 ));
if [[ $# != 2 ]]; then
    echo "$0: ERROR: $USAGE" 1>&2
    exit 93
fi
SRC="$1"
case "$2" in
*:*) USERHOST=${2%%:*}; DEST_PATH=${2##*:}; ;;
*) USERHOST="$2"; DEST_PATH= ;;	# empty DEST_PATH will become SRC_FULL_PATH
esac
export SRC USERHOST DEST_PATH

# firewall - only use commands from trusted directories
#
# Because we might want to run this command as a privileged user, we only
# use commands from explicit paths from well known system directories.
#
# We use hostname rather than rely on the common $HOST variable
# because $HOST is not universally set and may be incorrectly set.
#
# We use the basename command instead of bash variable ${XYZZY##*/}
# because we need a precise basename operation the dir argument
# contains an unusual path.
#
# We use the dirname command instead of bash variable ${XYZZY%/*}
# because we need a precise dirname operation the dir argument
# contains an unusual path.
#
if [[ -x "/bin/hostname" ]]; then
    HOSTNAME_PROG="/bin/hostname"
elif [[ -x "/usr/bin/hostname" ]]; then
    HOSTNAME_PROG="/usr/bin/hostname"
elif [[ -x "/usr/local/bin/hostname" ]]; then
    HOSTNAME_PROG="/usr/local/bin/hostname"
elif [[ -x "/sbin/hostname" ]]; then
    HOSTNAME_PROG="/sbin/hostname"
elif [[ -x "/usr/sbin/hostname" ]]; then
    HOSTNAME_PROG="/usr/sbin/hostname"
elif [[ -x "$HOME/bin/hostname" ]]; then
    HOSTNAME_PROG="$HOME/bin/hostname"
else
    echo "$0: ERROR: cannot find hostname executable" 1>&2
    exit 100
fi
export HOSTNAME_PROG
if [[ -x "/usr/bin/ssh" ]]; then
    SSH_PROG="/usr/bin/ssh"
elif [[ -x "/bin/ssh" ]]; then
    SSH_PROG="/bin/ssh"
elif [[ -x "/usr/local/bin/ssh" ]]; then
    SSH_PROG="/usr/local/bin/ssh"
elif [[ -x "/sbin/ssh" ]]; then
    SSH_PROG="/sbin/ssh"
elif [[ -x "/usr/sbin/ssh" ]]; then
    SSH_PROG="/usr/sbin/ssh"
elif [[ -x "$HOME/bin/ssh" ]]; then
    SSH_PROG="$HOME/bin/ssh"
else
    echo "$0: ERROR: cannot find ssh executable" 1>&2
    exit 101
fi
export SSH_PROG
if [[ -x "/usr/bin/rsync" ]]; then
    RSYNC_PROG="/usr/bin/rsync"
elif [[ -x "/bin/rsync" ]]; then
    RSYNC_PROG="/bin/rsync"
elif [[ -x "/usr/local/bin/rsync" ]]; then
    RSYNC_PROG="/usr/local/bin/rsync"
elif [[ -x "/sbin/rsync" ]]; then
    RSYNC_PROG="/sbin/rsync"
elif [[ -x "/usr/sbin/rsync" ]]; then
    RSYNC_PROG="/usr/sbin/rsync"
elif [[ -x "$HOME/bin/rsync" ]]; then
    RSYNC_PROG="$HOME/bin/rsync"
else
    echo "$0: ERROR: cannot find rsync executable" 1>&2
    exit 102
fi
export RSYNC_PROG
if [[ -x "/usr/bin/dirname" ]]; then
    DIRNAME_PROG="/usr/bin/dirname"
elif [[ -x "/bin/dirname" ]]; then
    DIRNAME_PROG="/bin/dirname"
elif [[ -x "/usr/local/bin/dirname" ]]; then
    DIRNAME_PROG="/usr/local/bin/dirname"
elif [[ -x "/sbin/dirname" ]]; then
    DIRNAME_PROG="/sbin/dirname"
elif [[ -x "/usr/sbin/dirname" ]]; then
    DIRNAME_PROG="/usr/sbin/dirname"
elif [[ -x "$HOME/bin/dirname" ]]; then
    DIRNAME_PROG="$HOME/bin/dirname"
else
    echo "$0: ERROR: cannot find dirname executable" 1>&2
    exit 103
fi
export DIRNAME_PROG
if [[ -x "/bin/basename" ]]; then
    BASENAME_PROG="/bin/basename"
elif [[ -x "/usr/bin/basename" ]]; then
    BASENAME_PROG="/usr/bin/basename"
elif [[ -x "/usr/local/bin/basename" ]]; then
    BASENAME_PROG="/usr/local/bin/basename"
elif [[ -x "/sbin/basename" ]]; then
    BASENAME_PROG="/sbin/basename"
elif [[ -x "/usr/sbin/basename" ]]; then
    BASENAME_PROG="/usr/sbin/basename"
elif [[ -x "$HOME/bin/basename" ]]; then
    BASENAME_PROG="$HOME/bin/basename"
else
    echo "$0: ERROR: cannot find basename executable" 1>&2
    exit 104
fi
export BASENAME_PROG

# be sure we are not on the remote host
#
HOST=${USERHOST##*@}
if [[ $($HOSTNAME_PROG -s) = "$HOST" ]]; then
    echo "$0: ERROR: already on $HOST" 1>&2
    exit 94
fi
export HOST

# the source dir must exist
#
if [[ ! -e "$SRC" ]]; then
    echo "$0: ERROR: $SRC not found" 1>&2
    exit 97
fi

# move into the directory of the SRC
#
# If SRC is /foo/bar, we move to /foo.
# If SRC is ., we move to . (not ..)
#
DIR_OF_SRC=$("$DIRNAME_PROG" "$SRC")
if [[ ! -d "$DIR_OF_SRC" ]]; then
    echo "$0: ERROR: parent directory: $DIR_OF_SRC does not exist" 1>&2
    exit 95
fi
export DIR_OF_SRC
# warning: Use 'cd ... || exit' or 'cd ... || return' in case cd fails. [SC2164]
# shellcheck disable=SC2164
cd "$DIR_OF_SRC" 2>/dev/null
status="$?"
if [[ "$status" -ne "0" ]]; then
    echo "$0: ERROR: cannot cd $DIR_OF_SRC" 1>&2
    exit 96
fi

# determine the full path of $DIR_OF_SRC which is now .
#
SRC_FULL_PATH=$(pwd)
export SRC_FULL_PATH

# determine, under SRC_FULL_PATH what we rsync from
#
FROM=$("$BASENAME_PROG" "$SRC")
if [[ ! -e "$FROM" ]]; then
    echo "$0: ERROR: $FROM not found under $SRC_FULL_PATH" 1>&2
    exit 98
fi
export FROM

# determine destination path
#
DEST_PATH=${DEST_PATH:-$SRC_FULL_PATH}

# construct rsync args
#
if [[ -n "$Z_FLAG" ]]; then
    PRE_E_AGS=(-e)
    E_ARGS=(\""$SSH_PROG" -a -T -p "$P_FLAG" -q -x -C -o Compression=yes -o ConnectionAttempts=20\")
else
    PRE_E_AGS=(-z -e)
    E_ARGS=(\""$SSH_PROG" -a -T -p "$P_FLAG" -q -x -o Compression=no -o ConnectionAttempts=20\")
fi
RSYNC_ARGS=(-a -S -0 --no-motd)
if [[ -n "$C_FLAG" ]]; then
    RSYNC_ARGS+=(-C --exclude=\'.*.swp\')
fi
if [[ -n "$D_FLAG" ]]; then
    RSYNC_ARGS+=(-d)
fi
if [[ -n "$CAP_E_FLAG" ]]; then
    RSYNC_ARGS+=(--extended-attributes --cache)
fi
if [[ -n "$F_FLAG" ]]; then
    RSYNC_ARGS+=(--force)
fi
if [[ -z "$K_FLAG" ]]; then
    RSYNC_ARGS+=(--delete)
fi
if [[ -n "$M_FLAG" ]]; then
    RSYNC_ARGS+=(-m)
fi
if [[ -n "$N_FLAG" ]]; then
    RSYNC_ARGS+=(-n)
fi
if [[ -n "$Q_FLAG" ]]; then
    RSYNC_ARGS+=(-q)
fi
if [[ -n "$U_FLAG" ]]; then
    RSYNC_ARGS+=(-u)
fi
if [[ -n "$V_FLAG" ]]; then
    RSYNC_ARGS+=(-v --progress --stats)
fi
if [[ -n "$X_FLAG" ]]; then
    RSYNC_ARGS+=(-x)
fi
export PRE_E_AGS E_ARGS RSYNC_ARGS

# execute the rsync command
#
if [[ -n "$V_FLAG" ]]; then
    echo "cd $DIR_OF_SRC; $RSYNC_PROG ${PRE_E_AGS[*]} ${E_ARGS[*]} ${RSYNC_ARGS[*]} $FROM $USERHOST:$DEST_PATH"
fi
if [[ -z "$N_FLAG" || -n "$V_FLAG" ]]; then
    # warning: eval negates the benefit of arrays. Drop eval to preserve whitespace/symbols (or eval as string). [SC2294]
    # shellcheck disable=SC2294
    eval "$RSYNC_PROG" "${PRE_E_AGS[*]}" "${E_ARGS[*]}" "${RSYNC_ARGS[*]}" "$FROM" "$USERHOST:$DEST_PATH"
    status="$?"
else
    status="0"
fi
export status

# All Done!!! -- Jessica Noll, Age 2
#
exit "$status"
