#!/usr/bin/make
#
# rsynchost - host based rsync utilities
#
# @(#) $Revision: 1.11 $
# @(#) $Id: Makefile,v 1.11 2014/03/15 23:59:57 root Exp $
# @(#) $Source: /usr/local/src/bin/rsynchost/RCS/Makefile,v $
#
# Copyright (c) 2001-2013,2021 by Landon Curt Noll.  All Rights Reserved.
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

SHELL=/bin/bash
INSTALL= install
BINMODE=0555
RM= rm
CP= cp
CHMOD= chmod
SHELLCHECK= shellcheck

DESTBIN=/usr/local/bin

TARGETS= rsyncfrom rsyncto

all: ${TARGETS}

rsyncfrom: rsyncfrom.sh
	${RM} -f $@
	${CP} $@.sh $@
	${CHMOD} +x $@

rsyncto: rsyncto.sh
	${RM} -f $@
	${CP} $@.sh $@
	${CHMOD} +x $@

# local rules
#
shellcheck: rsyncfrom.sh rsyncto.sh
	${SHELLCHECK} -f gcc -- rsyncfrom.sh rsyncto.sh

install: all
	${INSTALL} -c -m ${BINMODE} ${TARGETS} ${DESTBIN}

clean:

clobber: clean
	${RM} -f ${TARGETS}
