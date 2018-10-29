#!/bin/bash
# ${copyright}
# ------------------------------------------------------------------------------
# # Install Splunk Universal Forwarder with specified configurations
# Run this script as root


# Detect OS / Distribution
KNOWN_DISTRIBUTION="(Debian|Ubuntu|RedHat|CentOS|Parrot)"
DISTRIBUTION=$(lsb_release -d 2>/dev/null | grep -Eo $KNOWN_DISTRIBUTION)

if [ -f /etc/debian_version -o "$DISTRIBUTION" == "Debian" -o "$DISTRIBUTION" == "Ubuntu" -o "$DISTRIBUTION" == "Parrot" ]; then
    OS="Debian"
elif [ -f /etc/redhat-release -o "$DISTRIBUTION" == "RedHat" -o "$DISTRIBUTION" == "CentOS" ]; then
    OS="RedHat"
elif [[ -f /etc/os-release && $(grep "^NAME" /etc/os-release | grep -Eo '".*"' | tr -d \") == "Amazon Linux AMI" ]]; then
    OS="EC2"
else
    OS=$(uname -s)
fi

# Detect root user
if [ $(echo "$UID") = "0" ]; then
    _sudo=''
else
    _sudo='sudo'
fi

splunk_home="/opt/splunkforwarder"

function install_uf_debian {
    echo -e "\033[32m\nStep:Installing Splunk Universal Forwarder on Debian...\n\033[0m"
    if [ -d $splunk_home ]; then
        echo -e "\033[32m\nSplunk Universal Forwarder already exists, skipping installation...\n\033[0m"
    else
        if ! hash wget 2>/dev/null; then
            $_sudo apt-get install -y wget
        fi
        $_sudo wget -O splunkforwarder-7.1.0-2e75b3406c5b-linux-2.6-amd64.deb 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.1.0&product=universalforwarder&filename=splunkforwarder-7.1.0-2e75b3406c5b-linux-2.6-amd64.deb&wget=true'
        $_sudo dpkg -i splunkforwarder-7.1.0-2e75b3406c5b-linux-2.6-amd64.deb
        if [ $? -ne 0 ] ; then
            echo "Failed to install Splunk Universal Forwarder."
            exit 1
        fi
    fi
}

function install_uf_redhat {

    echo -e "\033[32m\nStep:Installing Splunk Universal Forwarder on Redhat...\n\033[0m"
    if [ -d $splunk_home ]; then
        echo -e "\033[32m\nSplunk Universal Forwarder already exists, skipping installation...\n\033[0m"
    else
        if ! hash wget 2>/dev/null; then
            $_sudo yum install -y wget
        fi
        $_sudo wget -O splunkforwarder-7.1.0-2e75b3406c5b-linux-2.6-x86_64.rpm 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.1.0&product=universalforwarder&filename=splunkforwarder-7.1.0-2e75b3406c5b-linux-2.6-x86_64.rpm&wget=true'
        $_sudo rpm -i splunkforwarder-7.1.0-2e75b3406c5b-linux-2.6-x86_64.rpm
        if [ $? -ne 0 ] ; then
            echo "Failed to install Splunk Universal Forwarder."
            exit 1
        fi
    fi
}

function set_up_deploy_poll {
    echo -e "\033[32m\nStep:Configuring deployment poll...\n\033[0m"
    conf_file="$splunk_home/etc/apps/ez_deploymentclient/local/deploymentclient.conf"
    $_sudo mkdir -p "$splunk_home/etc/apps/ez_deploymentclient/local"

    $_sudo touch $conf_file
    $_sudo chmod a+w $conf_file

    echo -e "[target-broker:deploymentServer]" >> $conf_file
    echo -e "targetUri = $SPLUNK_DEPLOYER" >> $conf_file

    echo -e "\n[deployment-client]" >> $conf_file
    echo -e "clientName = EZ-NIX-$HOSTNAME" >> $conf_file
}

function set_up_forwarder_server { 
    echo -e "\033[32m\nStep:Configuring forwarding to indexers...\n\033[0m"
    conf_file="$splunk_home/etc/apps/ez_forwarder_outputs/local/outputs.conf"
    $_sudo mkdir -p "$splunk_home/etc/apps/ez_forwarder_outputs/local"

    $_sudo touch $conf_file
    $_sudo chmod a+w $conf_file

    echo -e "[tcpout]" >> $conf_file
    echo -e "defaultGroup = primary_indexers" >> $conf_file

    echo -e "\n[tcpout:primary_indexers]" >> $conf_file
    echo -e "server = $SPLUNK_INDEXERS" >> $conf_file

}

function set_up_inputs {
    echo -e "\033[32m\nStep:Configuring inputs...\n\033[0m"
    conf_file="$splunk_home/etc/apps/ez_inputs/local/inputs.conf"
    $_sudo mkdir -p "$splunk_home/etc/apps/ez_inputs/local"

    $_sudo touch $conf_file
    $_sudo chmod a+w $conf_file

    echo -e "$SPLUNK_INPUTS" >> $conf_file
}

function set_up_credentials {
    echo -e "\033[32m\nStep:Configuring credentials...\n\033[0m"
    conf_file="$splunk_home/etc/system/local/user-seed.conf"

    $_sudo touch $conf_file
    $_sudo chmod a+w $conf_file

    echo -e "[user_info]" >> $conf_file
    echo -e "USERNAME = $SPLUNK_USER" >> $conf_file
    echo -e "PASSWORD = $SPLUNK_PASS" >> $conf_file
}

function configure {
    echo -e "\033[32m\nStep:Configure Splunk Universal Forwarder...\n\033[0m"

    set_up_deploy_poll
    set_up_forwarder_server
    set_up_inputs
    set_up_credentials

    echo -e "\033[32m\nStep:Enabling boot start for Splunk Universal Forwarder...\n\033[0m"
    sudo -u splunk $splunk_home/bin/splunk restart --answer-yes --auto-ports --no-prompt --accept-license
    $_sudo $splunk_home/bin/splunk enable boot-start -user splunk
}


if [ $OS = "Debian" ]; then
    install_uf_debian
    configure
elif [ $OS = "RedHat" ]; then
    install_uf_redhat
    configure
elif [ $OS = "EC2" ]; then
    install_uf_redhat
    configure
else
    echo -e "\033[31m\nNot supported operating system: $OS. Nothing is installed.\n\033[0m"
fi
