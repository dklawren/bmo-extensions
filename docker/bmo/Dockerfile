# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.

FROM mozillaconduit/docker-bmo
MAINTAINER David Lawrence <dkl@mozilla.com>

ENV BUGZILLA_ROOT /home/bugzilla/devel/htdocs/bmo

# Packages
COPY conf/rpm_list /rpm_list
RUN yum -y install `cat /rpm_list` && yum clean all

# Copy setup scripts
COPY scripts/* /usr/local/bin/
RUN chmod 755 /usr/local/bin/*

# Development environment setup
RUN su - $BUGZILLA_USER -c dev_config.sh

RUN chown -R $BUGZILLA_USER.$BUGZILLA_USER /home/$BUGZILLA_USER
