#!/usr/bin/env bash
#
# rsyncfrom - rsync from a remote to a local directory
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
export RSYNCFROM_VERSION="1.23 2022-11-17"
USAGE="rsyncfrom - rsync from a remote host to a local directory

usage: $0 [-options ...] [user@]host[:dir] dest

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

$0: version: $RSYNCFROM_VERSION"
A_FLAG=
CAP_C_FLAG=
D_FLAG=
CAP_E_FLAG=
F_FLAG=
I_FLAG=
K_FLAG=
M_FLAG=
N_FLAG=
CAP_N_FLAG=
P_FLAG="22"
Q_FLAG=
S_FLAG=
CAP_S_FLAG=
U_FLAG=
V_FLAG=
X_FLAG=
Z_FLAG=
export A_FLAG CAP_C_FLAG D_FLAG CAP_E_FLAG F_FLAG I_FLAG K_FLAG M_FLAG N_FLAG
export CAP_N_FLAG P_FLAG Q_FLAG S_FLAG CAP_S_FLAG U_FLAG V_FLAG X_FLAG Z_FLAG
HOSTNAME_PATH=
SSH_PATH=
RSYNC_PATH=
DIRNAME_PATH=
BASENAME_PATH=
export HOSTNAME_PATH SSH_PATH RSYNC_PATH DIRNAME_PATH BASENAME_PATH
while getopts :aCdEfhikmnNp:P:qsSt:uxvVz flag; do
    case "$flag" in
    a) A_FLAG="true" ;;
    C) CAP_C_FLAG="true" ;;
    d) D_FLAG="true" ;;
    E) CAP_E_FLAG="true" ;;
    f) F_FLAG="true" ;;
    h) echo "$USAGE";
	exit 92;
	;;
    i) I_FLAG="true" ;;
    k) K_FLAG="true" ;;
    m) M_FLAG="true" ;;
    n) N_FLAG="true" ;;
    N) N_FLAG="true";
       CAP_N_FLAG="true" ;;
    p) P_FLAG="$OPTARG"; ;;
    P) P_FLAG="$OPTARG"; ;;
    q) Q_FLAG="true" ;;
    s) S_FLAG="true" ;;
    S) CAP_S_FLAG="true" ;;
    t) case "$OPTARG" in
       hostname=*)
           HOSTNAME_PATH=${OPTARG##hostname=}
	   ;;
       ssh=*)
           SSH_PATH=${OPTARG##ssh=}
	   ;;
       rsync=*)
           RSYNC_PATH=${OPTARG##rsync=}
	   ;;
       dirname=*)
           DIRNAME_PATH=${OPTARG##dirname=}
	   ;;
       basename=*)
           BASENAME_PATH=${OPTARG##basename=}
	   ;;
       *)  echo "$0: ERROR: -t option not of the form tool=path where tool is one of: hostname ssh rsync dirname basename" 1>&2
           exit 93;
           ;;
       esac
       ;;
    u) U_FLAG="true" ;;
    v) V_FLAG="true" ;;
    V) echo "$RSYNCFROM_VERSION";
	exit 92;
	;;
    x) X_FLAG="true" ;;
    z) Z_FLAG="true" ;;
    \?) "$0: ERROR: invalid option: -$OPTARG" 1>&2;
	exit 93;
	;;
    :)  echo "$0: ERROR: option -$OPTARG requires an argument" 1>&2;
	exit 93;
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
if [[ -n $F_FLAG && -n $K_FLAG ]]; then
    echo "$0: ERROR: -f and -k conflict and cannot be used together" 1>&2
    exit 93
fi
ORIG_ARG1="$1"
ORIG_ARG2="$2"
export ORIG_ARG1 ORIG_ARG2
case "$1" in
*:*) USERHOST=${1%%:*}; DIR_PATH=${1##*:}; ;;
*) USERHOST="$1"; DIR_PATH= ;;	# use DEST
esac
DEST="$2"
export USERHOST DIR_PATH DEST

# firewall - only use commands from trusted directories, unless -t tool=path is used
#
# Because we might want to run this command as a privileged user, we only
# use commands from explicit paths from well known system directories.
#
# We use hostname rather than rely on the common $HOST variable
# because $HOST is not universally set and may be incorrectly set.
#
# We use the basename command instead of bash variable ${XYZZY##*/}
# because we need a precise basename operation the dest argument
# contains an unusual path.
#
# We use the dirname command instead of bash variable ${XYZZY%/*}
# because we need a precise dirname operation the dest argument
# contains an unusual path.
#
if [[ -z $HOSTNAME_PATH ]]; then
    if [[ -x "/usr/bin/hostname" ]]; then
	HOSTNAME_PATH="/usr/bin/hostname"
    elif [[ -x "/bin/hostname" ]]; then
	HOSTNAME_PATH="/bin/hostname"
    elif [[ -x "/sbin/hostname" ]]; then
	HOSTNAME_PATH="/sbin/hostname"
    elif [[ -x "/usr/sbin/hostname" ]]; then
	HOSTNAME_PATH="/usr/sbin/hostname"
    elif [[ -x "/usr/local/bin/hostname" ]]; then
	HOSTNAME_PATH="/usr/local/bin/hostname"
    elif [[ -x "/usr/global/bin/hostname" ]]; then
	HOSTNAME_PATH="/usr/global/bin/hostname"
    elif [[ -x "$HOME/bin/hostname" ]]; then
	HOSTNAME_PATH="$HOME/bin/hostname"
    fi
fi
if [[ -z $HOSTNAME_PATH ]]; then
    echo "$0: ERROR: executable hostname not found in the standard places: $HOSTNAME_PATH" 1>&2
    exit 100
elif [[ ! -e $HOSTNAME_PATH ]]; then
    echo "$0: ERROR: hostname not found: $HOSTNAME_PATH" 1>&2
    exit 100
elif [[ ! -f $HOSTNAME_PATH ]]; then
    echo "$0: ERROR: hostname a file: $HOSTNAME_PATH" 1>&2
    exit 100
elif [[ ! -x $HOSTNAME_PATH ]]; then
    echo "$0: ERROR: hostname not executable: $HOSTNAME_PATH" 1>&2
    exit 100
fi
export HOSTNAME_PATH
#
if [[ -z $SSH_PATH ]]; then
    if [[ -x "/usr/bin/ssh" ]]; then
	SSH_PATH="/usr/bin/ssh"
    elif [[ -x "/bin/ssh" ]]; then
	SSH_PATH="/bin/ssh"
    elif [[ -x "/sbin/ssh" ]]; then
	SSH_PATH="/sbin/ssh"
    elif [[ -x "/usr/sbin/ssh" ]]; then
	SSH_PATH="/usr/sbin/ssh"
    elif [[ -x "/usr/local/bin/ssh" ]]; then
	SSH_PATH="/usr/local/bin/ssh"
    elif [[ -x "/usr/global/bin/ssh" ]]; then
	SSH_PATH="/usr/global/bin/ssh"
    elif [[ -x "$HOME/bin/ssh" ]]; then
	SSH_PATH="$HOME/bin/ssh"
    fi
fi
if [[ -z $SSH_PATH ]]; then
    echo "$0: ERROR: executable ssh not found in the standard places: $SSH_PATH" 1>&2
    exit 101
elif [[ ! -e $SSH_PATH ]]; then
    echo "$0: ERROR: ssh not found: $SSH_PATH" 1>&2
    exit 101
elif [[ ! -f $SSH_PATH ]]; then
    echo "$0: ERROR: ssh a file: $SSH_PATH" 1>&2
    exit 101
elif [[ ! -x $SSH_PATH ]]; then
    echo "$0: ERROR: ssh not executable: $SSH_PATH" 1>&2
    exit 101
fi
export SSH_PATH
#
if [[ -z $RSYNC_PATH ]]; then
    if [[ -x "/usr/bin/rsync" ]]; then
	RSYNC_PATH="/usr/bin/rsync"
    elif [[ -x "/bin/rsync" ]]; then
	RSYNC_PATH="/bin/rsync"
    elif [[ -x "/sbin/rsync" ]]; then
	RSYNC_PATH="/sbin/rsync"
    elif [[ -x "/usr/sbin/rsync" ]]; then
	RSYNC_PATH="/usr/sbin/rsync"
    elif [[ -x "/usr/local/bin/rsync" ]]; then
	RSYNC_PATH="/usr/local/bin/rsync"
    elif [[ -x "/usr/global/bin/rsync" ]]; then
	RSYNC_PATH="/usr/global/bin/rsync"
    elif [[ -x "$HOME/bin/rsync" ]]; then
	RSYNC_PATH="$HOME/bin/rsync"
    fi
fi
if [[ -z $RSYNC_PATH ]]; then
    echo "$0: ERROR: executable rsync not found in the standard places: $RSYNC_PATH" 1>&2
    exit 102
elif [[ ! -e $RSYNC_PATH ]]; then
    echo "$0: ERROR: rsync not found: $RSYNC_PATH" 1>&2
    exit 102
elif [[ ! -f $RSYNC_PATH ]]; then
    echo "$0: ERROR: rsync a file: $RSYNC_PATH" 1>&2
    exit 102
elif [[ ! -x $RSYNC_PATH ]]; then
    echo "$0: ERROR: rsync not executable: $RSYNC_PATH" 1>&2
    exit 102
fi
export RSYNC_PATH
#
if [[ -z $DIRNAME_PATH ]]; then
    if [[ -x "/usr/bin/dirname" ]]; then
	DIRNAME_PATH="/usr/bin/dirname"
    elif [[ -x "/bin/dirname" ]]; then
	DIRNAME_PATH="/bin/dirname"
    elif [[ -x "/sbin/dirname" ]]; then
	DIRNAME_PATH="/sbin/dirname"
    elif [[ -x "/usr/sbin/dirname" ]]; then
	DIRNAME_PATH="/usr/sbin/dirname"
    elif [[ -x "/usr/global/bin/dirname" ]]; then
	DIRNAME_PATH="/usr/global/bin/dirname"
    elif [[ -x "/usr/local/bin/dirname" ]]; then
	DIRNAME_PATH="/usr/local/bin/dirname"
    elif [[ -x "$HOME/bin/dirname" ]]; then
	DIRNAME_PATH="$HOME/bin/dirname"
    fi
fi
if [[ -z $DIRNAME_PATH ]]; then
    echo "$0: ERROR: executable dirname not found in the standard places: $DIRNAME_PATH" 1>&2
    exit 103
elif [[ ! -e $DIRNAME_PATH ]]; then
    echo "$0: ERROR: dirname not found: $DIRNAME_PATH" 1>&2
    exit 103
elif [[ ! -f $DIRNAME_PATH ]]; then
    echo "$0: ERROR: dirname a file: $DIRNAME_PATH" 1>&2
    exit 103
elif [[ ! -x $DIRNAME_PATH ]]; then
    echo "$0: ERROR: dirname not executable: $DIRNAME_PATH" 1>&2
    exit 103
fi
export DIRNAME_PATH
#
if [[ -z $BASENAME_PATH ]]; then
    if [[ -x "/usr/bin/basename" ]]; then
	BASENAME_PATH="/usr/bin/basename"
    elif [[ -x "/bin/basename" ]]; then
	BASENAME_PATH="/bin/basename"
    elif [[ -x "/sbin/basename" ]]; then
	BASENAME_PATH="/sbin/basename"
    elif [[ -x "/usr/sbin/basename" ]]; then
	BASENAME_PATH="/usr/sbin/basename"
    elif [[ -x "/usr/local/bin/basename" ]]; then
	BASENAME_PATH="/usr/global/bin/basename"
    elif [[ -x "/usr/global/bin/basename" ]]; then
	BASENAME_PATH="/usr/local/bin/basename"
    elif [[ -x "$HOME/bin/basename" ]]; then
	BASENAME_PATH="$HOME/bin/basename"
    fi
fi
if [[ -z $BASENAME_PATH ]]; then
    echo "$0: ERROR: executable basename not found in the standard places: $BASENAME_PATH" 1>&2
    exit 104
elif [[ ! -e $BASENAME_PATH ]]; then
    echo "$0: ERROR: basename not found: $BASENAME_PATH" 1>&2
    exit 104
elif [[ ! -f $BASENAME_PATH ]]; then
    echo "$0: ERROR: basename a file: $BASENAME_PATH" 1>&2
    exit 104
elif [[ ! -x $BASENAME_PATH ]]; then
    echo "$0: ERROR: basename not executable: $BASENAME_PATH" 1>&2
    exit 104
fi
export BASENAME_PATH

# debugging
#
if [[ -n $I_FLAG ]]; then
    echo "$0: debug: ORIG_ARG1=$ORIG_ARG1" 1>&2
    echo "$0: debug: ORIG_ARG2=$ORIG_ARG2" 1>&2
    echo "$0: debug: HOSTNAME_PATH=$HOSTNAME_PATH" 1>&2
    echo "$0: debug: SSH_PATH=$SSH_PATH" 1>&2
    echo "$0: debug: RSYNC_PATH=$RSYNC_PATH" 1>&2
    echo "$0: debug: DIRNAME_PATH=$DIRNAME_PATH" 1>&2
    echo "$0: debug: BASENAME_PATH=$BASENAME_PATH" 1>&2
fi

# be sure we are not on the remote host
#
HOST=${USERHOST##*@}
if [[ $($HOSTNAME_PATH -s) == "$HOST" ]]; then
    echo "$0: ERROR: already on $HOST" 1>&2
    exit 94
fi
export HOST

# create, if needed the directory that will contain dest
#
DIRNAME_DEST=$("$DIRNAME_PATH" "$DEST")
status="$?"
if [[ "$status" -ne "0" ]]; then
    echo "$0: ERROR: dirname: $DIRNAME_PATH of: $DEST failed, exit code: $status" 1>&2
    exit 95
fi
if [[ -z "$N_FLAG" ]]; then
    if [[ ! -d "$DIRNAME_DEST" ]]; then
	mkdir -p "$DIRNAME_DEST"
    fi
    if [[ ! -d "$DIRNAME_DEST" ]]; then
	echo "$0: ERROR: count not create parent directory: $DIRNAME_DEST" 1>&2
	exit 95
    fi
elif [[ -n $I_FLAG ]]; then
    if [[ -d "$DIRNAME_DEST" ]]; then
	echo "$0: debug: DIRNAME_DEST is already a directory: $DIRNAME_DEST" 1>&2
    else
	echo "$0: debug: mkdir -p $DIRNAME_DEST" 1>&2
    fi
fi
export DIRNAME_DEST

# move into the directory of the DEST
#
# warning: Use 'cd ... || exit' or 'cd ... || return' in case cd fails. [SC2164]
# shellcheck disable=SC2164
cd "$DIRNAME_DEST" 2>/dev/null
status="$?"
if [[ "$status" -ne "0" ]]; then
    echo "$0: ERROR: cannot cd parent directory: $DIRNAME_DEST" 1>&2
    exit 96
fi

# determine the directory of dest
#
# Due to the cd above, the directory of dest is now .
#
if [[ -n $A_FLAG ]]; then
    DIRNAME_DEST_PATH=$(pwd -P)
else
    DIRNAME_DEST_PATH="$DIRNAME_DEST"
fi
export DIRNAME_DEST_PATH

# determine the destination name under the current directory
#
DEST=$("$BASENAME_PATH" "$DEST")
status="$?"
if [[ "$status" -ne "0" ]]; then
    echo "$0: ERROR: basename: $BASENAME_PATH of: $DEST failed, exit code: $status" 1>&2
    exit 98
fi
export DEST

# more debugging
#
# If no :dir given in 1st argument ($DIR_PATH is empty):
#
#	echo "cd $DIRNAME_DEST; $RSYNC_PATH ${PRE_E_AGS[*]} ${E_ARGS[*]} ${RSYNC_ARGS[*]} $USERHOST:$DIRNAME_DEST_PATH/$DEST ."
#
# If :dir given in 1st argument ($DIR_PATH is not empty):
#
#	echo "cd $DIRNAME_DEST; $RSYNC_PATH ${PRE_E_AGS[*]} ${E_ARGS[*]} ${RSYNC_ARGS[*]} $USERHOST:$DIR_PATH/ $DEST"
#
if [[ -n $I_FLAG ]]; then
    echo "$0: debug: HOST=$HOST" 1>&2
    echo "$0: debug: DEST=$DEST" 1>&2
    echo "$0: debug: DIRNAME_DEST_PATH=$DIRNAME_DEST_PATH" 1>&2
    echo "$0: debug: DIRNAME_DEST=$DIRNAME_DEST" 1>&2
    echo "$0: debug: DIR_PATH=$DIR_PATH" 1>&2
    echo "$0: debug: cd: $DIRNAME_DEST" 1>&2
    echo "$0: debug: USERHOST=$USERHOST" 1>&2
    if [[ -z $DIR_PATH ]]; then
	echo "$0: debug: from: $USERHOST:$DIRNAME_DEST_PATH/$DEST" 1>&2
    else
	echo "$0: debug: from: $USERHOST:$DIR_PATH/" 1>&2
    fi
    echo "$0: debug: to: $DIRNAME_DEST/$DEST" 1>&2
fi

# execute the rsync command
#
if [[ -n "$Z_FLAG" ]]; then
    PRE_E_AGS=(-e)
    E_ARGS=(\""$SSH_PATH" -a -T -p "$P_FLAG" -q -x -C -o Compression=yes -o ConnectionAttempts=20\")
else
    PRE_E_AGS=(-z -e)
    E_ARGS=(\""$SSH_PATH" -a -T -p "$P_FLAG" -q -x -o Compression=no -o ConnectionAttempts=20\")
fi
RSYNC_ARGS=(-a -S -0 --no-motd)
if [[ -n "$CAP_C_FLAG" ]]; then
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
if [[ -n "$S_FLAG" ]]; then
    RSYNC_ARGS+=(--ignore-non-existing)
fi
if [[ -n "$CAP_S_FLAG" ]]; then
    RSYNC_ARGS+=(--ignore-existing)
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
    if [[ -z $DIR_PATH ]]; then
	echo "cd $DIRNAME_DEST; $RSYNC_PATH ${PRE_E_AGS[*]} ${E_ARGS[*]} ${RSYNC_ARGS[*]} $USERHOST:$DIRNAME_DEST_PATH/$DEST ."
    else
	echo "cd $DIRNAME_DEST; $RSYNC_PATH ${PRE_E_AGS[*]} ${E_ARGS[*]} ${RSYNC_ARGS[*]} $USERHOST:$DIR_PATH/ $DEST"
    fi
fi
if [[ -z "$CAP_N_FLAG" ]]; then
    if [[ -z $DIR_PATH ]]; then
	# warning: eval negates the benefit of arrays. Drop eval to preserve whitespace/symbols (or eval as string). [SC2294]
	# shellcheck disable=SC2294
	eval "$RSYNC_PATH" "${PRE_E_AGS[*]}" "${E_ARGS[*]}" "${RSYNC_ARGS[*]}" "$USERHOST:$DIRNAME_DEST_PATH/$DEST" .
	status="$?"
   else
	# warning: eval negates the benefit of arrays. Drop eval to preserve whitespace/symbols (or eval as string). [SC2294]
	# shellcheck disable=SC2294
	eval "$RSYNC_PATH" "${PRE_E_AGS[*]}" "${E_ARGS[*]}" "${RSYNC_ARGS[*]}" "$USERHOST:$DIR_PATH/" "$DEST"
	status="$?"
   fi
else
    status="0"
fi
export status

# All Done!!! -- Jessica Noll, Age 2
#
exit "$status"
