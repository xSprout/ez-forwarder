# ez-forwarder

This app generates a string a code that completes the following, after being entered into powershell or bash:

1. Downloading the universal forwarder (v7.1.x) from splunk.
2. Installing the forwarder
3. Generating and configuring the following files
	+ deploymentclient.conf
		- Settings for what deployment server to phonehome into, and changing the deployment client's name to be automatically pulled into the serverclass included with the app.
	+ outputs.conf 
		- Settings for what indexers the forwarder should send data to.
	+ inputs.conf
		- Settings for what inputs should be enabled right after install (note that specifying inputs from the deployment server using serverclasses is best practices)
	+ user-seed.conf 
		- Settings for configuring the credentials to manage the forwarder locally
4. Start the forwarder
5. Set up the forwarder to run at boot.

## Installing the app:

The app is meant to be installed on the deployment server and the search head, or a combined instance of the two.

Extract the zip to the $SPLUNK_HOME/etc/apps/ folder. (Make sure the folder's name after you extract is "ez-forwarder")

Or 

In your terminal, Navigate to $SPLUNK_HOME/etc/apps/ and clone the repository with the following command:

`git clone https://github.com/xSprout/ez-forwarder.git`

## Using the app:

Fill out the fields on the app:

1. Deployment server - should be the IP:Port of the deployment. By default it is the host you are currently connecting to (whatever is in the URL bar)
2. Outputs - should be a comma-delimited list of the IP:Ports of your indexer tier. By default this is set to any connected search peers, and if none are found; it is the host you are currently connecting to (whatever is in the URL bar) with the port 9997.
3. Inputs - Just the inputs.conf text you want on the forwarder. 
	- See http://docs.splunk.com/Documentation/Splunk/latest/Admin/Inputsconf for details.
4. Configure Forwarder credentials - The username and password you want the forwarder to accept when making changes locally.
5. Run the script
	* Copy-Paste - Copy paste the one-liner into bash (*nix machines) or powershell as administrator (windows machines)
	* OR (*nix search head and clients only, requires hostkey) - Enter the details of the deployment client to install the forwarder to with a click of a button.
		1. Enter the IP/FQDN of the host you want to ssh into
		2. Enter the username that should be used to ssh into the client
		3. Enter the absolute location of the hostkey on the Search Head/Deployment Server
		4. Click the button to have the SH/DS ssh into the client and execute the script. Area below should come up with a result.
