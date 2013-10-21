Neubot debian
'''''''''''''

Script and patches to build Neubot for Debian.

The ``Makefile`` delegates the bulk of the work to ``scripts/make_deb``.

The main Neubot repository is:

    https://github.com/neubot/neubot

Dependencies
------------

I have not rigorously tracked the dependencies; however, you need
at least ``dpkg-dev``, ``wget``, ``openssl``, ``gnupg``, ``python``,
``lintian``, ``fakeroot``, ``patch``, ``sudo``, and ``make``.

How to build packages
---------------------

Just type ``make deb-package`` and/or ``make deb-package-nox``.

How to make a release
---------------------

Make sure you are Simone Basso, then type ``make all``. This command
runs ``make deb-package`` and ``make deb-package-nox``, then it
creates and signs all the files required to setup an alternative
Debian repository.

How to run the regression tests
-------------------------------

Just type ``make regress``.

Procedure for testing a release under Ubuntu
--------------------------------------------

First of all, run the regression tests.

Then:

#. make sure that Neubot autoupdates on a Ubuntu machine where a
   previous version of Neubot was already installed;

#. install Neubot on an Ubuntu machine and:

     #. make sure it prompts for privacy settings during the
        install;

     #. make sure it prompts for privacy settings after a
        reboot;

     #. make sure that the following commands work properly: `bittorrent`,
        `browser`, `dash`, `database`, `notifier`, `privacy`, `raw`,
        `speedtest`, `viewer`.

I typically test new releases on Ubuntu 12.04.
