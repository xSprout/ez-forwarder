# currently must be 'runas' administrator for proper install

# if splunk_home not provided, use default
if([string]::IsNullOrEmpty($splunk_home)) {
  $splunk_home = "$env:programfiles\SplunkUniversalForwarder"
}

# URI to download the install file
$insturi = 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=windows&version=7.1.1&product=universalforwarder&filename=splunkforwarder-7.1.1-8f0ead9ec3db-x64-release.msi&wget=true'

# directory for file to be downloaded to:
# currently set to download in the path that the script is in:
$path = Convert-Path .
$outputdir = $path + '\splunkuniversalforwarder.msi'

# file name of .msi installation file
$install_file = 'splunkuniversalforwarder.msi'

echo "[*] indexer server(s): $SPLUNK_INDEXERS"

# Installation Directory for UniversalForwarder
$installdir = $splunk_home

echo "[*] checking for previous installations of splunk>..."

# checks to see if a splunk folder already exists in Program Files
# will skip installation if it finds a splunk folder

if (Test-Path -Path $installdir -PathType Container)
{
    echo "[!] install directory already exists. continuing to congure .."
}else{
    echo "[*] downloading splunk> universal forwarder..."

    # downloads splunk install file
    # this method significantly faster than Invoke-WebRequest
    (New-Object System.Net.WebClient).DownloadFile($insturi, $outputdir)

    # check if download succedded
    if (-not $?)
    {
        echo "[!] failed to download splunk> universal forwarder..."
        exit 1
    }

    echo "[*] installing splunk> universal fowarder..."

    # uses msi to install splunk forwarder, file names need to match and be co-located
    # /quiet suppresses gui, otherwise the script will fail
    # additional switches would be needed for an enterprise installation
    # testing on whether local user can collect log files (i believe no)
    # might need to be installed as a domain user or local admin?
    # see: <http://docs.splunk.com/Documentation/Forwarder/6.5.1/Forwarder/InstallaWindowsuniversalforwarderfromthecommandline>
    # for supported switches and installation instructions
    Start-Process -FilePath msiexec.exe -ArgumentList "/i $install_file INSTALLDIR=`"$installdir`" AGREETOLICENSE=Yes /quiet" -Wait
}

# **********  Configure deploymentclient.conf file  ************

echo "[*] configuring deploymentclient.conf..."

# location of deploymentclient.conf file
$conf_file = $splunk_home + "\etc\apps\ez_deploymentclient\local\deploymentclient.conf"
md "$splunk_home\etc\apps\ez_deploymentclient\local" -ea 0 | out-null

echo "[target-broker:deploymentServer]" >> $conf_file
echo "targetUri = $env:SPLUNK_DEPLOYER" >> $conf_file
echo "" >> $conf_file
echo "[deployment-client]" >> $conf_file
echo "clientName = EZ-WIN-$env:computername" >> $conf_file
echo "" >> $conf_file

# **********  Configure Outputs.conf file  ************

echo "[*] configuring outputs.conf..."

# location of outputs.conf file
$conf_file = $splunk_home + "\etc\apps\ez_forwarder_outputs\local\outputs.conf"
md "$splunk_home\etc\apps\ez_forwarder_outputs\local" -ea 0 | out-null

echo "[tcpout]" >> $conf_file
echo "defaultGroup = primary_indexers" >> $conf_file
echo "" >> $conf_file
echo "[tcpout:primary_indexers]" >> $conf_file
echo "server = $env:SPLUNK_INDEXERS" >> $conf_file
echo "" >> $conf_file

# **********  Configure inputs.conf file  ************

echo "[*] configuring inputs.conf..."

# location of inputs.conf file
$conf_file = $splunk_home + "\etc\apps\ez_inputs\local\inputs.conf"
md "$splunk_home\etc\apps\ez_inputs\local" -ea 0 | out-null

echo "$env:SPLUNK_INPUTS" >> $conf_file

# **********  Configure user-seed.conf file  ************

echo "[*] configuring user-seed.conf..."

# location of user-seed.conf file
$conf_file = $splunk_home + "\etc\system\local\user-seed.conf"

echo "[user_info]" >> $conf_file
echo "USERNAME = $env:SPLUNK_USER" >> $conf_file
echo "PASSWORD = $env:SPLUNK_PASS" >> $conf_file

# **********  Start Splunk and check if process started  *****************

# restart splunk universal forwarder
$splunkexe = $splunk_home + "\bin\splunk.exe"
echo "[*] Restarting splunk> universal fowarder"
& "$splunkexe" restart

# checks to see if splunkd is running which indicates good install
# then adds the necessary lines to input.conf to retreive powershell logs
$splunk = Get-Process -Name "splunkd" -ErrorAction SilentlyContinue

if ($splunk -ne $null)  # confirms if it restarted successfully
{
    echo "[*] splunk> successfully started."
    echo "[*] running clean up."

    if (Test-Path -Path $install_file)
    {
        Remove-Item $install_file
    }

    echo "[*] clean up complete. Exiting..."
    return
}else{
    echo '[!] splunk process not running!'
    echo '[!] check to make sure installation was successful.'
    return
}
