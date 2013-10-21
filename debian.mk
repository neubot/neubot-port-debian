# Makefile

#
# Copyright (c) 2010-2013
#     Nexa Center for Internet & Society, Politecnico di Torino
#     and Simone Basso <bassosimone@gmail.com>
#
# This file is part of Neubot <http://www.neubot.org/>.
#
# Neubot is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Neubot is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Neubot.  If not, see <http://www.gnu.org/licenses/>.
#

#
# Adapted from Neubot 0.4.15.6's makefile
#

VERSION = 0.4.16.8-1_all

#
# The list of .PHONY targets.  This is also used to build the
# help message--and note that the targets named with a leading
# underscore are private.
# Here we list targets in file order because this makes it easier
# to maintain this list.
#
PHONIES += help
PHONIES += regress
PHONIES += _deb_data
PHONIES += _deb_control
PHONIES += _deb
PHONIES += deb
PHONIES += release

.PHONY: $(PHONIES)

help:
	@printf "Targets:"
	@for TARGET in `grep ^PHONIES Makefile|sed 's/^.*+= //'`; do	\
	     if echo $$TARGET|grep -qv ^_; then				\
	         printf " $$TARGET";					\
	     fi;							\
	 done
	@printf '\n'

regress:
	rm -rf -- regress/success regress/failure
	for FILE in $$(find regress -type f -perm -0111); do		\
	    echo "* Running regression test: $$FILE";			\
	    ./$$FILE;							\
	    if [ $$? -ne 0 ]; then					\
	        echo $$FILE >> regress/failure;				\
	    else							\
	        echo $$FILE >> regress/success;				\
	    fi;								\
	    echo "";							\
	    echo "";							\
	done
	if [ -f regress/failure ]; then					\
	    echo "*** At least one regression test has failed";		\
	    echo "*** Check regress/failure for more info";		\
	    exit 1;							\
	fi

#      _      _
#   __| | ___| |__
#  / _` |/ _ \ '_ \
# | (_| |  __/ |_) |
#  \__,_|\___|_.__/
#
# Make package for Debian/Ubuntu/Mint
#

INSTALL = install

DEB_PACKAGE = ../dist/neubot-$(VERSION).deb
DEB_PACKAGE_NOX = ../dist/neubot-nox-$(VERSION).deb

_deb_data:
	make -f Makefile _install DESTDIR=../dist/data PREFIX=/usr \
	    LOCALSTATEDIR=/var/lib SYSCONFDIR=/etc
	$(INSTALL) -d ../dist/data/etc/apt/sources.list.d
	$(INSTALL) -m644 ../Debian/neubot.list \
	    ../dist/data/etc/apt/sources.list.d/
	$(INSTALL) -d ../dist/data/etc/cron.daily
	$(INSTALL) ../Debian/cron-neubot ../dist/data/etc/cron.daily/neubot
	$(INSTALL) -d ../dist/data/etc/init.d
	$(INSTALL) ../Debian/init-neubot ../dist/data/etc/init.d/neubot
	$(INSTALL) -d ../dist/data/usr/share/doc/neubot
	$(INSTALL) -m644 ../Debian/copyright ../dist/data/usr/share/doc/neubot/
	$(INSTALL) -m644 ../Debian/changelog.Debian.gz \
	    ../dist/data/usr/share/doc/neubot

_deb_control:
	$(INSTALL) -d ../dist/control
	$(INSTALL) -m644 ../Debian/control/control ../dist/control/control
	$(INSTALL) -m644 ../Debian/control/conffiles ../dist/control/conffiles
	$(INSTALL) ../Debian/control/postinst ../dist/control/postinst
	$(INSTALL) ../Debian/control/prerm ../dist/control/prerm
	$(INSTALL) ../Debian/control/postrm ../dist/control/postrm

	$(INSTALL) -m644 /dev/null ../dist/control/md5sums
	./scripts/cksum.py -a md5 `find ../dist/data -type f` \
	    > ../dist/control/md5sums
	./scripts/sed_inplace 's|..\/dist\/data\/||g' ../dist/control/md5sums

	SIZE=`du -k -s ../dist/data/|cut -f1` && \
	 ./scripts/sed_inplace "s|@SIZE@|$$SIZE|" ../dist/control/control

#
# Note that we must make _deb_data before _deb_control
# because the latter must calculate the md5sums and the
# total size.
# Fakeroot will guarantee that we don't ship a debian
# package with ordinary user ownership.
#
_deb:
	make -f ../debian.mk _deb_data
	cd ../dist/data && tar czf ../data.tar.gz ./*
	make -f ../debian.mk _deb_control
	cd ../dist/control && tar czf ../control.tar.gz ./*
	echo '2.0' > ../dist/debian-binary
	ar r $(DEB_PACKAGE) ../dist/debian-binary \
	 ../dist/control.tar.gz ../dist/data.tar.gz

	$(INSTALL) -m644 ../Debian/control/control-nox ../dist/control/control
	SIZE=`du -k -s ../dist/data/|cut -f1` && \
	 ./scripts/sed_inplace "s|@SIZE@|$$SIZE|" ../dist/control/control
	cd ../dist/control && tar czf ../control.tar.gz ./*
	ar r $(DEB_PACKAGE_NOX) ../dist/debian-binary \
	 ../dist/control.tar.gz ../dist/data.tar.gz

	cd ../dist && rm -rf debian-binary control.tar.gz data.tar.gz \
         control/ data/
	chmod 644 $(DEB_PACKAGE)
	chmod 644 $(DEB_PACKAGE_NOX)

deb:
	fakeroot make -f ../debian.mk _deb
	lintian $(DEB_PACKAGE)
	# This still fails because of /usr/share/doc/neubot...
	lintian $(DEB_PACKAGE_NOX) || true

#           _
#  _ __ ___| | ___  __ _ ___  ___
# | '__/ _ \ |/ _ \/ _` / __|/ _ \
# | | |  __/ |  __/ (_| \__ \  __/
# |_|  \___|_|\___|\__,_|___/\___|
#
# Bless a new neubot release (Debian).
#
release:
	make -f ../debian.mk deb
	../scripts/update_apt
	cd dist && find -type f -exec chmod 644 {} \;
	cd dist && find -type d -exec chmod 755 {} \;
