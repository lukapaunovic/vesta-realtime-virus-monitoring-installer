# Realtime Monitoring Maldet + Extended ClamAV Signatures for VestaCP
# Installer for CentOS systems by @lukapaunovic

yum -y install epel-release

# Install ClamAV fully
yum -y install clamav-server clamav-data clamav-update clamav-filesystem clamav clamav-scanner-systemd clamav-devel clamav-lib clamav-server-systemd

# Fix for "Hint: The database directory must be writable for UID 1001 or GID 1001"
chown clam:clam /var/lib/clamav

# Required by Maldetect for realtime monitoring

yum install inotify-tools -y

# Extended signatures for ClamAV
echo "DatabaseCustomURL http://cdn.malware.expert/malware.expert.ndb" >> /etc/freshclam.conf
echo "DatabaseCustomURL http://cdn.malware.expert/malware.expert.hdb" >> /etc/freshclam.conf
echo "DatabaseCustomURL http://cdn.malware.expert/malware.expert.ldb" >> /etc/freshclam.conf
echo "DatabaseCustomURL http://cdn.malware.expert/malware.expert.fp" >> /etc/freshclam.conf
echo "DatabaseCustomURL http://www.rfxn.com/downloads/rfxn.ndb" >> /etc/freshclam.conf
echo "DatabaseCustomURL http://www.rfxn.com/downloads/rfxn.hdb" >> /etc/freshclam.conf

# Update signatures

freshclam

# Install Maldetect
cd $(mktemp -d)
wget http://www.rfxn.com/downloads/maldetect-current.tar.gz
tar -xzf maldetect-current.tar.gz
cd maldetect-*
sh ./install.sh

# Set all public_*html folders to monitoring paths

find /home/*/web/ -name 'public_*html' -type d > /usr/local/maldetect/monitor_paths

# Configure Maldet

sed -i 's/quarantine_hits=\"0\"/quarantine_hits=\"1\"/g' /usr/local/maldetect/conf.maldet
sed -i 's/quarantine_clean=\"0\"/quarantine_clean=\"1\"/g' /usr/local/maldetect/conf.maldet
sed -i 's/\# default_monitor_mode/default_monitor_mode/g' /usr/local/maldetect/conf.maldet
# Enable MalDetect at startup and start

if [ $(ps --no-headers -o comm 1) == systemd ]; then
    systemctl enable maldet
    systemctl start maldet
else
    chkconfig maldet on
    service maldet start
fi

echo "Done, you may want to update email_alert and email_addr in /usr/local/maldetect/conf.maldet to receive notifications. Restart service afterwards with: service maldet restart"
