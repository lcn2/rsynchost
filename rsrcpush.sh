#!/bin/bash -
#
# rsrcpush - rsync a source local directory to a remost host src directory
#
# @(#) $Revision: 1.4 $
# @(#) $Id: rsrcpush.sh,v 1.4 2013/12/28 03:00:46 chongo Exp $
# @(#) $Source: /usr/local/src/bin/rsynchost/RCS/rsrcpush.sh,v $
#
# Copyright (c) 2001-2013 by Landon Curt Noll.  All Rights Reserved.
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
DEFAULT_TARGETS="chongo@shell.sonic.net paulnoll@shell.sonic.net"
USAGE="usage: $0 [-b base] [-h] [-k] [-n] [-q] [-v] [-x]
		     [[-t target]...] l_dir r_dir

	-b base	directory base of remote src tree when r_dir is not /-based
		    (def: ~/src where ~ is the remote user home directory)
	-h	print usage message
	-k	keep remote files, do not delete anything
	-n	trial run, transfer nothing
	-q	quiet operation
	-v	verbose output
	-x	run rsync in verbose mode

	-t target	remote target name (def: all default targets)

		Default target list: $DEFAULT_TARGETS

	l_dir	top of local source directory to send
	r_dir	relative path under base to receive src
		   If r_dir starts with /, rdir is absolute path"
BASE='~/src'
K_FLAG=
N_FLAG=
Q_FLAG=
V_FLAG=
X_FLAG=
TARGET_SET=
set -- $(/usr/bin/getopt b:hknqvxt: $*)
if [[ $? != 0 ]]; then
    echo "$0: unknown or invalid -flag" 1>&2
    echo "$USAGE" 1>&2
    exit 1
fi
for i in $*; do
    case $i in
    -b) BASE="$2"; ;;
    -h) echo "$USAGE" 1>&2 ; exit 0 ;;
    -k) K_FLAG="-k" ;;
    -n) N_FLAG="-n" ;;
    -q) Q_FLAG="-q" ;;
    -v) V_FLAG="true" ;;
    -x) X_FLAG="-v" ;;
    -t) TARGET_SET="$TARGET_SET $2" ;;
    --) shift; break ;;
    esac
    shift
done
# check args
if [[ $# != 2 ]]; then
    echo "$USAGE" 1>&2
    exit 2
fi
L_DIR="$1"
if [[ -z "$L_DIR" ]]; then
    echo "$0: FATAL: l_dir argument is empty" 1>&2
    exit 3
fi
if [[ ! -e "$L_DIR" ]]; then
    echo "$0: FATAL: l_dir missing: $L_DIR" 1>&2
    exit 4
fi
R_DIR="$2"
if [[ -z "$R_DIR" ]]; then
    echo "$0: FATAL: r_dir argument is empty" 1>&2
    exit 5
fi
# form the target set if defaulting
TARGET_SET="${TARGET_SET:-$DEFAULT_TARGETS}"
# form remote path
case "$R_DIR" in
/*) ;;
*) R_DIR="$BASE/$R_DIR"
esac
#
export BASE K_FLAG N_FLAG Q_FLAG V_FLAG X_FLAG
export USAGE DEFAULT_TARGETS TARGET_SET
export L_DIR R_DIR

# firewall - use only shell builtins and explicit paths
#
if [[ -x "/bin/rsyncto" ]]; then
    RSYNCTO_PROG="/bin/rsyncto"
elif [[ -x "/usr/bin/rsyncto" ]]; then
    RSYNCTO_PROG="/usr/bin/rsyncto"
elif [[ -x "/usr/local/bin/rsyncto" ]]; then
    RSYNCTO_PROG="/usr/local/bin/rsyncto"
elif [[ -x "/sbin/rsyncto" ]]; then
    RSYNCTO_PROG="/sbin/rsyncto"
elif [[ -x "/usr/sbin/rsyncto" ]]; then
    RSYNCTO_PROG="/usr/sbin/rsyncto"
elif [[ -x "$HOME/bin/rsyncto" ]]; then
    RSYNCTO_PROG="$HOME/bin/rsyncto"
else
    echo "$0: cannot find rsyncto executable" 1>&2
    exit 6
fi
export RSYNCTO_PROG

# form rsyncto args
#
RSYNCTO_ARGS="-C"
if [[ -n "$K_FLAG" ]]; then
    RSYNCTO_ARGS="$RSYNCTO_ARGS -k"
fi
if [[ -n "$N_FLAG" ]]; then
    RSYNCTO_ARGS="$RSYNCTO_ARGS -n"
fi
if [[ -n "$Q_FLAG" ]]; then
    RSYNCTO_ARGS="$RSYNCTO_ARGS -q"
fi
if [[ -n "$X_FLAG" ]]; then
    RSYNCTO_ARGS="$RSYNCTO_ARGS -v"
fi

# execute the rsyncto over the target set
#
for target in $TARGET_SET; do
    if [[ -n "$V_FLAG" ]]; then
	echo "$RSYNCTO_PROG $RSYNCTO_ARGS $L_DIR $target:$R_DIR" 1>&2
    fi
    eval $RSYNCTO_PROG $RSYNCTO_ARGS "$L_DIR" "$target:$R_DIR"
    status=$?
    if [[ $status != 0 ]]; then
	echo "$0: $RSYNCTO_PROG $RSYNCTO_ARGS $L_DIR $target:$R_DIR error: $status" 1>&2
	exit $status
    fi
done

# All Done!!! -- Jessica Noll, Age 2
#
exit 0
