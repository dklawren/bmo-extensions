#!/bin/bash -e
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

MYSQL_USER=${MYSQL_USER:-"bugs"}
MYSQL_NAME=${MYSQL_NAME:-"bugs"}
MYSQL_HOST=${MYSQL_HOST:-"localhost"}
MYSQL_PASS=${MYSQL_PASS:-"bugs"}
MYSQL_PORT=${MYSQL_PORT:-"3306"}
MYSQL_ROOT_PASS=${MYSQL_ROOT_PASS:-""}

if [ "$MYSQL_HOST" = "localhost" ]; then
    echo -e "\n== Starting database"
    /usr/bin/mysqld_safe &
fi

echo -e "\n== Checking database"
CHECK_HOST=$MYSQL_HOST CHECK_PORT=$MYSQL_PORT takis
mysql -u root -h $MYSQL_HOST mysql -e "GRANT ALL PRIVILEGES ON *.* TO bugs@'%' IDENTIFIED BY 'bugs'; FLUSH PRIVILEGES;" || exit 1
mysql -u root -h $MYSQL_HOST mysql -e "CREATE DATABASE IF NOT EXISTS bugs_bmo CHARACTER SET = 'utf8';" || exit 1

# Environment setup
if [ ! -e "$BUGZILLA_ROOT" ]; then
    git clone $GITHUB_BASE_GIT -b $GITHUB_BASE_BRANCH --depth 1 $BUGZILLA_ROOT \
        && ln -sf $BUGZILLA_LIB $BUGZILLA_ROOT/local
fi

echo -e "\n== Running checksetup"
cd $BUGZILLA_ROOT
rm -f localconfig data/params
/bin/cat <<EOM >checksetup_answers.txt
\$answer{'ADMIN_EMAIL'} = 'admin@mozilla.bugs';
\$answer{'ADMIN_LOGIN'} = 'admin';
\$answer{'ADMIN_OK'} = 'Y';
\$answer{'ADMIN_PASSWORD'} = 'password123456789!';
\$answer{'ADMIN_REALNAME'} = 'QA Admin';
\$answer{'NO_PAUSE'} = 1;
\$answer{'apache_size_limit'} = 700000;
\$answer{'auth_delegation'} = 1;
\$answer{'bugzilla_version'} = '4.2';
\$answer{'create_htaccess'} = '';
\$answer{'db_check'} = 1;
\$answer{'db_driver'} = 'mysql';
\$answer{'db_host'} = '$MYSQL_HOST';
\$answer{'db_name'} = '$MYSQL_NAME',
\$answer{'db_pass'} = '$MYSQL_PASS';
\$answer{'db_port'} = $MYSQL_PORT;
\$answer{'db_user'} = '$MYSQL_USER';
\$answer{'memcached_servers'} = "localhost:11211";
\$answer{'urlbase'} = 'http://bmo.test/';
\$answer{'webservergroup'} = 'bugzilla';
EOM

./checksetup.pl checksetup_answers.txt
./checksetup.pl checksetup_answers.txt

echo -e "\n== Generating test data"
perl scripts/generate_bmo_data.pl
#generate_conduit_data.pl

echo -e "\n== Starting memcached"
/usr/bin/memcached -u memcached -d

echo -e "\n== Starting push daemon"
su - $BUGZILLA_USER -c "cd $BUGZILLA_ROOT; perl ./extensions/Push/bin/bugzilla-pushd.pl start"

echo -e "\n== Starting web server"
/usr/sbin/httpd -DFOREGROUND -einfo
