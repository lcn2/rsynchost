#!/bin/bash -
#
# rmake - run make on a remote server
#
# @(#) $Revision: 1.3 $
# @(#) $Id: rmake.sh,v 1.3 2014/02/12 02:49:17 root Exp $
# @(#) $Source: /usr/local/src/bin/rsynchost/RCS/rmake.sh,v $
#
# Copyright (c) 2013-2014 by Landon Curt Noll.  All Rights Reserved.
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
USAGE="usage: $0 [-b base] [-h] [-v] [[-t target]...] rmake_dir rmake_arg ...

	-b base	directory base of remote src tree when r_dir is not /-based
		    (def: ~/src where ~ is the remote user home directory)
	-h	print usage message
	-v	verbose output

	-t target	remote target name (def: all default targets)

		Default target list: chongo@shell.sonic.net paulnoll@shell.sonic.net

	rmake_dir	relative path of directory with Makefile under base
		   	    If rmake_dir starts with /, rdir is absolute path
        rmake_arg ...	argments to remote make"
BASE='~/src'
V_FLAG=
TARGET_SET=
set -- $(/usr/bin/getopt b:ht:v $*)
if [[ $? != 0 ]]; then
    echo "$0: unknown or invalid -flag" 1>&2
    echo "$USAGE" 1>&2
    exit 1
fi
for i in $*; do
    case $i in
    -b) BASE="$2"; ;;
    -h) echo "$USAGE" 1>&2 ; exit 0 ;;
    -t) TARGET_SET="$TARGET_SET $2" ;;
    -v) V_FLAG="true" ;;
    --) shift; break ;;
    esac
    shift
done
# check args
if [[ $# < 2 ]]; then
    echo "$USAGE" 1>&2
    exit 2
fi
RMAKE_DIR="$1"
shift
if [[ -z "$RMAKE_DIR" ]]; then
    echo "$0: FATAL: rmake_dir argument is empty" 1>&2
    exit 3
fi
# form the target set if defaulting
TARGET_SET="${TARGET_SET:-$DEFAULT_TARGETS}"
# form remote path to makefile
case "$RMAKE_DIR" in
/*) ;;
*) RMAKE_DIR="$BASE/$RMAKE_DIR"
esac
#
export BASE V_FLAG
export USAGE DEFAULT_TARGETS TARGET_SET
export RMAKE_DIR

# firewall - use only shell builtins and explicit paths
#
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

# execute the rsyncto over the target set
#
for target in $TARGET_SET; do

    # setup make args for given targets
    #
    case "$target" in
    chongo@shell.sonic.net)
	DESTBIN='~/bin'
	MAN1DIR='~/man/man1'
	;;
    paulnoll@shell.sonic.net)
	DESTBIN='~/bin'
	MAN1DIR='~/man/man1'
	;;
    *)
	DESTBIN='/usr/local/bin'
	MAN1DIR='/usr/local/man/man1'
	;;
    esac
    export DESTBIN MAN1DIR

    # execute make on a given target
    #
    if [[ -n "$V_FLAG" ]]; then
	echo "$SSH_PROG $target \"cd $RMAKE_DIR ; make $@ DESTBIN=$DESTBIN MAN1DIR=$MAN1DIR\"" 1>&2
    fi
    eval "$SSH_PROG $target \"cd $RMAKE_DIR ; make $@ DESTBIN=$DESTBIN MAN1DIR=$MAN1DIR\""
    status=$?
    if [[ $status != 0 ]]; then
	echo "$0: $SSH_PROG $target cd $RMAKE_DIR \\; make $@ error: $status" 1>&2
	exit $status
    fi
done

# All Done!!! -- Jessica Noll, Age 2
#
exit 0
