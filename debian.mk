# debian.mk

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

VERSION = 0.4.16.8-1

#
# The list of .PHONY targets.  This is also used to build the
# help message--and note that the targets named with a leading
# underscore are private.
#
# Here we list targets in file order because this makes it easier
# to maintain this list.
#
PHONIES += help
PHONIES += regress
PHONIES += deb
PHONIES += release

.PHONY: $(PHONIES)

help:
	@printf "Targets:"
	@for TARGET in `grep ^PHONIES Makefile|sed 's/^.*+= //'`; do \
	     if echo $$TARGET|grep -qv ^_; then \
	         printf " $$TARGET"; \
	     fi; \
	 done
	@printf '\n'

regress:
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

#      _      _
#   __| | ___| |__
#  / _` |/ _ \ '_ \
# | (_| |  __/ |_) |
#  \__,_|\___|_.__/
#
# Make package for Debian/Ubuntu/Mint
#

deb:
	fakeroot ../scripts/make_deb neubot $(VERSION)
	fakeroot ../scripts/make_deb neubot-nox $(VERSION)
	lintian ../neubot-$(VERSION)_all.deb
	lintian ../neubot-nox-$(VERSION)_all.deb

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
