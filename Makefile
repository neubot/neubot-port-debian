# Makefile

#
# Copyright (c) 2012-2013
#     Nexa Center for Internet & Society, Politecnico di Torino (DAUIN)
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

VERSION = 0.4.16.8
MIRROR = http://releases.neubot.org/_packages
TARBALL = neubot-$(VERSION).tar.gz
SIGNATURE = $(TARBALL).sig
SRCDIR = neubot-$(VERSION)

DEB_VERSION = $(VERSION)-1

.PHONY: all clean deb-package deb-package-nox regress

all: deb-package deb-package-nox
	scripts/update_apt

$(TARBALL):
	wget $(MIRROR)/$(TARBALL)
$(TARBALL).sig:
	wget $(MIRROR)/$(TARBALL).sig

$(SRCDIR): $(TARBALL) $(TARBALL).sig
	openssl dgst -sha256 -verify pubkey.pem -signature \
			$(TARBALL).sig $(TARBALL)
	tar -xzf $(TARBALL)
	for PATCH in $$(ls *.patch); do \
		(cd neubot-$(VERSION) && patch -Np1 -i ../$$PATCH); \
	done

_make_deb: $(SRCDIR)
	( \
	 set -e; \
	 cd $(SRCDIR); \
	 fakeroot ../scripts/make_deb $(_DEB_PKGNAME) $(DEB_VERSION); \
	 lintian ../$(_DEB_PKGNAME)-$(DEB_VERSION)_all.deb; \
	)

neubot-$(DEB_VERSION)_all.deb:
	make -f Makefile _make_deb _DEB_PKGNAME=neubot
neubot-nox-$(DEB_VERSION)_all.deb:
	make -f Makefile _make_deb _DEB_PKGNAME=neubot-nox

deb-package: neubot-$(DEB_VERSION)_all.deb
deb-package-nox: neubot-nox-$(DEB_VERSION)_all.deb

regress: deb-package deb-package-nox
	rm -rf -- regress/success regress/failure
	for FILE in $$(find regress -type f -perm +0111); do \
	    echo "* Running regression test: $$FILE"; \
	    ./$$FILE; \
	    if [ $$? -ne 0 ]; then \
	        echo $$FILE >> regress/failure; \
	    else \
	        echo $$FILE >> regress/success; \
	    fi; \
	    echo ""; \
	    echo ""; \
	done
	if [ -f regress/failure ]; then \
	    echo "*** At least one regression test has failed"; \
	    echo "*** Check regress/failure for more info"; \
	    exit 1; \
	fi

clean:
	rm -rf -- $(TARBALL) $(SIGNATURE) $(SRCDIR) dist/
veryclean: clean
	rm -rf -- *.deb Packages Packages.gz Release Release.gpg
