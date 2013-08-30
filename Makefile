# Rudimentary Makefile for building an SRPM.
#

NAME=yubiauthd

#########################################################
# YOU SHOULDN'T NEED TO CHANGE ANYTHING BELOW THIS LINE #
#########################################################

### Makefile.common ###
# Most of the below Makefile was pulled from Fedora's Makefile.common,
# which is available at http://cvs.fedora.redhat.com/.  It has been lightly
# tweaked to suit our needs.
#
# Licensed under the new-BSD license (http://www.opensource.org/licenses/bsd-license.php)
# Copyright (C) 2004-2005 Red Hat, Inc.
# Copyright (C) 2005 Fedora Foundation

# a base directory where we'll put as much temporary working stuff as we can
ifndef WORKDIR
WORKDIR := $(shell pwd)
endif
## of course all this can also be overridden in your RPM macros file,
## but this way you can separate your normal RPM setup from your CVS
## setup. Override RPM_WITH_DIRS in ~/.cvspkgsrc to avoid the usage of
## these variables.
SRCRPMDIR ?= $(WORKDIR)
BUILDDIR ?= $(WORKDIR)
RPMDIR ?= $(WORKDIR)

## SOURCEDIR is special; it has to match the CVS checkout directory,
## because the CVS checkout directory contains the patch files. So it basically
## can't be overridden without breaking things. But we leave it a variable
## for consistency, and in hopes of convincing it to work sometime.
ifndef SOURCEDIR
SOURCEDIR := $(shell pwd)
endif
ifndef SPECDIR
SPECDIR := $(shell pwd)
endif
ifndef SPECFILE
SPECFILE = $(SPECDIR)/$(NAME).spec
endif

ifndef VERSION
VERSION := $(shell git describe --tags | perl -p -e 's/([\d\.]+)-(\d+)-g(\w+)?/\1/')
endif

ifndef RELEASE
RELEASE := $(shell git describe --tags | perl -p -e 's/([\d\.]+)-(\d+)-g(\w+)?/\2.git.\3/')
ifeq ($(RELEASE),$(VERSION))
RELEASE := 1
endif
endif

ifndef RPM_DEFINES
RPM_DEFINES = --define "_sourcedir $(SOURCEDIR)" \
		--define "_specdir $(SPECDIR)" \
		--define "_builddir $(BUILDDIR)" \
		--define "_srcrpmdir $(SRCRPMDIR)" \
		--define "_rpmdir $(RPMDIR)"
endif

ifndef RPM
RPM := $(shell if test -f /usr/bin/rpmbuild ; then echo rpmbuild ; else echo rpm ; fi)
endif
ifndef RPM_WITH_DIRS
RPM_WITH_DIRS = $(RPM) $(RPM_DEFINES)
endif

# Initialize the variables that we need, but are not defined
# the name of the package
ifndef NAME
$(error "You can not run this Makefile without having NAME defined")
endif
# this is used in make patch, maybe make clean eventually.
# would be nicer to autodetermine from the spec file...
RPM_BUILD_DIR ?= $(BUILDDIR)/$(NAME)-$(VERSION)

#Need someplace that's not $WORKDIR to build our tarball in...
ifndef TMPDIR
TMPDIR = /tmp/$(NAME)-$(VERSION)-$(RELEASE)-BUILDTEMP
endif

.PHONY: srpm clean
# use this to build an srpm locally
srpm: $(WORKDIR)/$(NAME)-$(VERSION).tar.bz2
	$(RPM_WITH_DIRS) --nodeps -bs $(SPECFILE)
	rm -rf $(TMPDIR)


$(WORKDIR)/$(NAME)-$(VERSION).tar.bz2:
	if [ ! -d $(TMPDIR) ]; then mkdir -p $(TMPDIR);	fi

	# Stupid rpm build being strict about changelog dates. :P
	git log --date=rfc --pretty=format:'* %cd %cn <%cE>%n- commit %H%n- %s%n' . | sed 's/^\(\* ...\), \([0-9]*\) \(...\) \(....\).............../\1 \3 \2 \4 -/' >> $(SPECFILE)
	perl -pi -e "s/Version: unknown/Version: $(VERSION)/" $(SPECFILE)
	perl -pi -e "s/Release: unknown/Release: $(RELEASE)/" $(SPECFILE)
	ln -s $(SOURCEDIR) $(TMPDIR)/$(NAME)-$(VERSION)
	tar -cjhf $(TMPDIR)/$(NAME)-$(VERSION).tar.bz2 --exclude .git --exclude Makefile -C $(TMPDIR) $(NAME)-$(VERSION)
	cp $(TMPDIR)/$(NAME)-$(VERSION).tar.bz2 $(SOURCEDIR)

clean:
	rm -rf $(TMPDIR)
	rm -f $(WORKDIR)/$(NAME)-$(VERSION).tar.bz2
	rm -f $(WORKDIR)/$(NAME)-$(VERSION)-$(RELEASE).src.rpm

# default target - retrieve the sources and make the module specific targets
sources: $(SOURCEDIR)/$(NAME)-$(VERSION).tar.bz2 $(TARGETS)


