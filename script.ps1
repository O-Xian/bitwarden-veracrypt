<#
.SYNOPSIS
Mount an encrypted VeraCrypt volume with parameters loaded from a Bitwarden server.

.DESCRIPTION
Connect to a Bitwarden server, retrieve the volume item, extract password and other parameters.
Mount the volume with VeraCrypt.

You MUST set some variables in the script:
- $veracryptBinary: full path to VeraCrypt.exe (filename included)
- $pwdFile: full path (filename included) to a text file containing only your Bitwarden master password
- $itemId: Bitwarden-assigned ID for your volume item

The script expects two environment variables to be set:
- BW_CLIENTID: client ID provided by Bitwarden for API access
- BW_CLIENTSECRET: client secret provided by Bitwarden for API access
They can be set directly into the script with $env:BW_CLIENTID and $env:BW_CLIENTSECRET or preloaded into your Windows environment. $env:BW_CLIENTSECRET will be unset by the script for security.

You MUST first initialize the script by specifying the Bitwarden URL to use with the -server parameter (see example 2 below).

.INPUTS
-server <string> may be provided from the pipeline.

.OUTPUTS
None.

.EXAMPLE
PS> .\vs.ps1

.EXAMPLE
PS> .\vs.ps1 -server https://bitwarden.domain.tld

.EXAMPLE
PS> .\vs.ps1 -help
#>
param(
	[Parameter(Mandatory=$false, ValueFromPipeline=$true)]
	[string]
	# Specifies the Bitwarden server to use. Optional.
	$server,
	
	# Displays help message.
	[switch]$help
)

if ($help) {
	echo '.\vc.ps1'
	echo '    Mount the volume'
	echo ''
	echo '.\vc.ps1 -server https://bitwarden.domain.tld'
	echo '    Set the Bitwarden server to the provided URL and then mount the volume'
	Exit 0
}

$veracryptBinary="C:\Program Files\VeraCrypt\VeraCrypt.exe"
$env:BW_CLIENTID="user.CHANGEME"
$env:BW_CLIENTSECRET="CHANGEME"
$pwdFile="CHANGEME"
$itemId="CHANGEME"

#########
# Is the user trying to change the Bitwarden server?
#########
if ($server) {
	process {
		Write-Progress -Id 1 -Activity 'Setting Bitwarden URL' -CurrentOperation 'Write config file' -Status 'Progress:' -PercentComplete 0
		bw.exe config server $server
		Write-Progress -Id 1 -Activity 'Setting Bitwarden URL' -CurrentOperation 'Done!' -Status 'Progress:' -PercentComplete 100
	}
}

#########
# Fetch the info from Bitwarden
# password on one side and the whole item on the other
#########
Write-Progress -Id 2 -Activity 'Working with Bitwarden' -CurrentOperation 'Login' -Status 'Progress:' -PercentComplete 0
bw.exe login --apikey *> $null
Write-Progress -Id 2 -Activity 'Working with Bitwarden' -CurrentOperation 'Unlock the vault' -Status 'Progress:' -PercentComplete 13
$sessionKey=bw.exe unlock --raw --passwordfile $pwdFile

Write-Progress -Id 2 -Activity 'Working with Bitwarden' -CurrentOperation 'Retrieve the item' -Status 'Progress:' -PercentComplete 25
$pass=bw.exe get password $itemId --session $sessionKey
Write-Progress -Id 2 -Activity 'Working with Bitwarden' -CurrentOperation 'Retrieve the item' -Status 'Progress:' -PercentComplete 38
$item=bw.exe get item $itemId --raw --session $sessionKey

Write-Progress -Id 2 -Activity 'Working with Bitwarden' -CurrentOperation 'Lock the vault' -Status 'Progress:' -PercentComplete 50
bw.exe lock *> $null
Write-Progress -Id 2 -Activity 'Working with Bitwarden' -CurrentOperation 'Logout' -Status 'Progress:' -PercentComplete 63
bw.exe logout *> $null
$env:BW_CLIENTSECRET=$null

#########
# Process the values
#########
Write-Progress -Id 2 -Activity 'Processing the retrieved item' -Status 'Progress:' -PercentComplete 75
$vcFile=$item | jq.exe '.fields[0] | .value'
$vcDrive=$item | jq.exe '.fields[1] | .value'
$vcPkcs=$item | jq.exe '.fields[2] | .value'
$vcHash=$item | jq.exe '.fields[3] | .value'

$vcFile=$vcFile.replace("\\", "\")



#########
# Mount the volume
#########
Write-Progress -Id 2 -Activity 'Mounting the volume' -Status 'Progress:' -PercentComplete 83
& $veracryptBinary /volume $vcFile /letter $vcDrive /hash $vcHash /auto /password $pass /quit /silent
Write-Progress -Id 2 -Activity 'Done!' -Status 'Progress:' -PercentComplete 100

Exit 0
