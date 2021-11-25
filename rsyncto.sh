#!/bin/bash -
#
# rsyncto - rsync a local directory to a remost host
#
# @(#) $Revision: 1.18 $
# @(#) $Id: rsyncto.sh,v 1.18 2014/01/24 07:45:51 chongo Exp $
# @(#) $Source: /usr/local/src/bin/rsynchost/RCS/rsyncto.sh,v $
#
# Copyright (c) 2001-2014 by Landon Curt Noll.  All Rights Reserved.
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

# NOTE: exit 0 thru exit 89 are reserved for rsync success / error codes
#	     90 thru 99 are used for argument parsing error codes
#	     100 thru 109 are used for missing program error codes
#	     110 theu 119 are used for runtime non-rsync error codes

# parse args
#
USAGE="usage: $0 [-C] [-e] [-k] [-n] [-p num] [-q] [-v] [-x] [-z] dir [user@]host[:dest]

	-C	exclude RCS, CVS, tmp, .o, .a, .so, .Z, .orig, .rej, .BAK ...
	-e	copy extended attributes and disable cache (def: don't)
	-k	keep remote files, do not delete anything
	-n	trial run, transfer nothing
	-p num	Change the ssh TCP port to num (default: 22)
		NOTE: -P num is an alias for -p num
	-q	quiet operation
	-v	verbose output
	-x	not to cross filesystem boundaries
	-z	compression via the transport (ssh) shell, not via rsync itself

	dir	directory on current host to tranfer
	host	host to transfer to
	:dest	optional destination directory (def: use dir)"
C_FLAG=
E_FLAG=
K_FLAG=
N_FLAG=
P_FLAG="22"
Q_FLAG=
V_FLAG=
X_FLAG=
Z_FLAG=
set -- $(/usr/bin/getopt Ceknp:P:qvxz $*)
if [[ $? != 0 ]]; then
    echo "$0: unknown or invalid -flag" 1>&2
    echo "$USAGE" 1>&2
    exit 90
fi
for i in $*; do
    case $i in
    -C) C_FLAG="true" ;;
    -e) E_FLAG="true" ;;
    -k) K_FLAG="true" ;;
    -n) N_FLAG="true" ;;
    -p) P_FLAG="$2"; ;;
    -P) P_FLAG="$2"; ;;
    -q) Q_FLAG="true" ;;
    -v) V_FLAG="true" ;;
    -x) X_FLAG="true" ;;
    -z) Z_FLAG="true" ;;
    --) shift; break ;;
    esac
    shift
done
if [[ $# != 2 ]]; then
    echo "$USAGE" 1>&2
    exit 91
fi
export C_FLAG E_FLAG K_FLAG N_FLAG P_FLAG Q_FLAG V_FLAG X_FLAG Z_FLAG
SRC="$1"
case "$2" in
*:*) USERHOST=${2%%:*}; DEST_PATH=${2##*:}; ;;
*) USERHOST="$2"; DEST_PATH= ;;	# empty DEST_PATH will become ABSDIR_OF_SRC
esac
export SRC USERHOST DEST_PATH

# firewall - use only shell builtins and explicit paths
#
if [[ ! -e "$SRC" ]]; then
    echo "$0: $SRC not found" 1>&2
    exit 100
fi
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
    echo "$0: cannot find hostname executable" 1>&2
    exit 101
fi
export HOSTNAME_PROG
if [[ -x "/bin/sed" ]]; then
    SED_PROG="/bin/sed"
elif [[ -x "/usr/bin/sed" ]]; then
    SED_PROG="/usr/bin/sed"
elif [[ -x "/usr/local/bin/sed" ]]; then
    SED_PROG="/usr/local/bin/sed"
elif [[ -x "/sbin/sed" ]]; then
    SED_PROG="/sbin/sed"
elif [[ -x "/usr/sbin/sed" ]]; then
    SED_PROG="/usr/sbin/sed"
elif [[ -x "$HOME/bin/sed" ]]; then
    SED_PROG="$HOME/bin/sed"
else
    echo "$0: cannot find sed executable" 1>&2
    exit 102
fi
export SED_PROG
HOST=$(echo $USERHOST | $SED_PROG -e 's/^.*@//')
if [[ $($HOSTNAME_PROG -s) = "$HOST" ]]; then
    echo "$0: already on $HOST" 1>&2
    exit 103
fi
export HOST
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
    echo "$0: cannot find ssh executable" 1>&2
    exit 104
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
    echo "$0: cannot find rsync executable" 1>&2
    exit 105
fi
export RSYNC_PROG
if [[ -x "/bin/pwd" ]]; then
    PWD_PROG="/bin/pwd"
elif [[ -x "/usr/bin/pwd" ]]; then
    PWD_PROG="/usr/bin/pwd"
elif [[ -x "/usr/local/bin/pwd" ]]; then
    PWD_PROG="/usr/local/bin/pwd"
elif [[ -x "/sbin/pwd" ]]; then
    PWD_PROG="/sbin/pwd"
elif [[ -x "/usr/sbin/pwd" ]]; then
    PWD_PROG="/usr/sbin/pwd"
elif [[ -x "$HOME/bin/pwd" ]]; then
    PWD_PROG="$HOME/bin/pwd"
else
    echo "$0: cannot find pwd executable" 1>&2
    exit 106
fi
export PWD_PROG
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
    echo "$0: cannot find dirname executable" 1>&2
    exit 107
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
    echo "$0: cannot find basename executable" 1>&2
    exit 108
fi
export BASENAME_PROG

# move into the directory of the SRC
#
# If SRC is /foo/bar, we move to /foo.
# If SRC is ., we move to . (not ..)
#
DIR_OF_SRC=$($DIRNAME_PROG $SRC)
if [[ ! -d "$DIR_OF_SRC" ]]; then
    echo "$0: parent directory: $DIR_OF_SRC does not exist" 1>&2
    exit 110
fi
export DIR_OF_SRC
cd "$DIR_OF_SRC" 2>/dev/null
status="$?"
if [[ "$status" -ne "0" ]]; then
    echo "$0: cannot cd $DIR_OF_SRC" 1>&2
    exit 111
fi

# get the real absolue path of the directory of the SRC
#
ABSDIR_OF_SRC=$($PWD_PROG)
export ABSDIR_OF_SRC

# determine, under ABSDIR_OF_SRC what we rsync from
#
FROM=$($BASENAME_PROG $SRC)
if [[ ! -e "$FROM" ]]; then
    echo "$0: $FROM not found under $ABSDIR_OF_SRC" 1>&2
    exit 112
fi
export FROM

# determine destnation path
#
DEST_PATH=${DEST_PATH:-$ABSDIR_OF_SRC}

# construct rsync args
#
RSYNC_ARGS="-a -S -0"
if [[ -n "$C_FLAG" ]]; then
    RSYNC_ARGS="$RSYNC_ARGS -C --exclude='.*.swp'"
fi
if [[ -n "$E_FLAG" ]]; then
    RSYNC_ARGS="$RSYNC_ARGS --extended-attributes --cache"
fi
if [[ -z "$K_FLAG" ]]; then
    RSYNC_ARGS="$RSYNC_ARGS --delete"
fi
if [[ -n "$N_FLAG" ]]; then
    RSYNC_ARGS="$RSYNC_ARGS -n"
fi
if [[ -n "$Q_FLAG" ]]; then
    RSYNC_ARGS="$RSYNC_ARGS -q"
fi
if [[ -n "$V_FLAG" ]]; then
    RSYNC_ARGS="$RSYNC_ARGS -v"
fi
if [[ -n "$X_FLAG" ]]; then
    RSYNC_ARGS="$RSYNC_ARGS -x"
fi
# NOTE: -z should be added last to avoid quoting problems
if [[ -n "$Z_FLAG" ]]; then
    RSYNC_ARGS='-e "'$SSH_PROG' -a -T -p '$P_FLAG' -q -x -o CompressionLevel=9 -o Compression=yes -o ConnectionAttempts=20"'" $RSYNC_ARGS"
else
    RSYNC_ARGS='-z -e "'$SSH_PROG' -a -T -p '$P_FLAG' -q -x -o Compression=no -o ConnectionAttempts=20"'" $RSYNC_ARGS"
fi
export RSYNC_ARGS

# execute the rsync command
#
if [[ -n "$V_FLAG" ]]; then
    echo cd "$ABSDIR_OF_SRC;" $RSYNC_PROG $RSYNC_ARGS "$FROM" "$USERHOST:$DEST_PATH"
fi
if [[ -z "$N_FLAG" || -n "$V_FLAG" ]]; then
    eval $RSYNC_PROG $RSYNC_ARGS "$FROM" "$USERHOST:$DEST_PATH"
    status="$?"
else
    status="0"
fi
exit "$status"
