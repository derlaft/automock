#!/bin/bash
#<LocationMatch "^/+$">
#    Options -Indexes
#    ErrorDocument 403 /.noindex.html
#</LocationMatch>
source automock.conf
backup ()
{
  cp "${1}" "${DIR}"/backups/
}
sudoers ()
{
  backup "/etc/sudoers"
  echo "Defaults:${USER} !requiretty
Defaults:apache !requiretty
${USER} ALL=(ALL) NOPASSWD: /usr/sbin/semanage, /usr/sbin/restorecon, /usr/sbin/setsebool, /usr/bin/rm
apache ALL=(${USER}) NOPASSWD: ${DIR}/automock.sh" >> /etc/sudoers
}
httpd ()
{
  backup "/etc/httpd/conf.d/welcome.conf"
  echo "DocumentRoot ${ROOT} 
Alias /repos ${REPODIR}/packages
Alias /automock ${DIR}/web
<Directory "${ROOT}">
  Options Indexes
  AllowOverride None
  Require all granted
  Order allow,deny
  Allow from all
</Directory>
<Directory "${DIR}">
  Options -Indexes
  AllowOverride None
  Require all granted
  Order allow,deny
  Allow from all
</Directory>" >> /etc/httpd/conf.d/automock.conf
}
init ()
{
  # Clean
  rm -rf "${REPODIR}"/*
  # Create repodirs
  mkdir -p "${REPODIR}"/packages/f{18,19}/
  # Create jobs directories
  mkdir -p "${JOBS}"/ "${JOBS}"/running/ "${TMPJOBSRUN}"/
  # Chown
  chown -R ${USER}:${GROUP} "${ROOT}"/
}
if [[ `whoami` = root ]]; then
  # Install requirements
  yum install -y mock-scm sudo createrepo sed gawk httpd php
  # Make primary dir
  mkdir "${DIR}" "${DIR}"/backups/
  # Create user for build
  useradd -M -g ${GROUP} -G mock -s /bin/false ${USER}
  sudoers
  httpd
  init
  crontab -u apache cron
  systemctl enable httpd.service
  systemctl restart httpd.service
  cp -R * "${DIR}"
  exit 0
else
  echo "Failed! Run as root!"
  exit 1
fi
