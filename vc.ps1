<#
.SYNOPSIS
Mount an encrypted VeraCrypt volume with parameters loaded from a Bitwarden server.

.DESCRIPTION
Connect to a Bitwarden server, retrieve the volume item, extract password and other parameters.
Mount the volume with VeraCrypt.

You MUST set some variables in the script OR pass them on the command line:
- $veracryptBinary: full path to VeraCrypt.exe (filename included), or only the binary name if in your PATH
- $pwdFile: full path (filename included) to a text file containing only your Bitwarden master password (only in non-interactive mode)
- $itemId: Bitwarden-assigned ID for your volume item

You MUST also provide your credentials, either with environment variables and password file OR use the interactive mode.
Only in non-interactive mode:
- BW_CLIENTID: client ID provided by Bitwarden for API access
- BW_CLIENTSECRET: client secret provided by Bitwarden for API access
They can be set directly into the script with $env:BW_CLIENTID and $env:BW_CLIENTSECRET or preloaded into your Windows environment. $env:BW_CLIENTSECRET will be unset by the script for security.

In interactive mode, you will be prompted by Bitwarden for your email address and your master password. Interactive mode is activated with the -interactive switch

You MUST first initialize the script by specifying the Bitwarden URL to use with the -server parameter (see example 2 below).

Parameters for VeraCrypt are extracted from the Custom Fields in Bitwarden item. Script will look for fields named:
- "Container Path": full path of the encrypted container
- "Mount Drive": drive letter to mount the container as (no : after, can be lower or upper case)
- "Hash": [sha256|sha-256|sha512|sha-512|whirlpool|ripemd160|ripemd-160]the hash method passed as the /hash parameter

jq (https://stedolan.github.io/jq/) MUST be installed and included in your PATH.

.INPUTS
None.

.OUTPUTS
None.

.EXAMPLE
PS> .\vc.ps1

.EXAMPLE
PS> .\vc.ps1 -server https://bitwarden.domain.tld

.EXAMPLE
PS> .\vc.ps1 -itemId 00000000-1111-2222-3333-444444444444 -veracryptBinary "C:\Program Files\VeraCrypt\VeraCrypt.exe"			 

.EXAMPLE
PS> .\vc.ps1 -itemId 00000000-1111-2222-3333-444444444444 -interactive			 

.EXAMPLE
PS> .\vc.ps1 -help
#>
[CmdletBinding(DefaultParameterSetName='AuthByKey')]
param(
	[Parameter(Mandatory=$false)]
	[string]
	# Specifies the Bitwarden server to use. Optional.
	$server,
	
	[Parameter(Mandatory=$false)]
	[string]
	# Specifies the item ID in Bitwarden vault to fetch
	$itemId="CHANGEME",
	
	[Parameter(Mandatory=$false, ParameterSetName="AuthByKey")]
	[string]
	# Specifies the full path to Bitwarden master password file
	$pwdFile="CHANGEME",
	
	[Parameter(Mandatory=$false, ParameterSetName="AuthByPassword")]
	[switch]
	# Activates interactive mode and prompts for email address and master password instead of using API key and password file.
	$interactive,
	
	[Parameter(Mandatory=$false)]
	[string]
	# Specifies the full path to VeraCrypt.exe binary
	$veracryptBinary="CHANGEME",
	
	# Displays help message.
	[switch]$help
)

if ($help) {
	echo 'PS> vc.ps1 [-server <String>] [-itemId <String>] [-pwdFile <String>] [-veracryptBinary <String>] [-help] [<CommonParameters>]'
	echo '    Mount the volume in non-interactive mode'
	echo ''
	echo 'PS> vc.ps1 [-server <String>] [-itemId <String>] [-interactive] [-veracryptBinary <String>] [-help] [<CommonParameters>]'
	echo '    Mount the volume in interactive mode and prompt for email/master password'
	echo ''
	echo 'For more help, see'
	echo 'PS> help C:\full\path\to\script.ps1'
	
	Exit 0
}

if (-Not $interactive) {
	$env:BW_CLIENTID="user.CHANGEME"
	$env:BW_CLIENTSECRET="CHANGEME"
}

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

if ($interactive) {
	bw.exe login
} else {
	bw.exe login --apikey *> $null
	Write-Progress -Id 2 -Activity 'Working with Bitwarden' -CurrentOperation 'Unlock the vault' -Status 'Progress:' -PercentComplete 13
	$sessionKey=bw.exe unlock --raw --passwordfile $pwdFile
}

Write-Progress -Id 2 -Activity 'Working with Bitwarden' -CurrentOperation 'Retrieve the item' -Status 'Progress:' -PercentComplete 25
$pass=bw.exe get password $itemId --session $sessionKey

Write-Progress -Id 2 -Activity 'Working with Bitwarden' -CurrentOperation 'Retrieve the item' -Status 'Progress:' -PercentComplete 38
$item=bw.exe get item $itemId --raw --session $sessionKey

Write-Progress -Id 2 -Activity 'Working with Bitwarden' -CurrentOperation 'Lock the vault' -Status 'Progress:' -PercentComplete 50
bw.exe lock *> $null

Write-Progress -Id 2 -Activity 'Working with Bitwarden' -CurrentOperation 'Logout' -Status 'Progress:' -PercentComplete 63
bw.exe logout *> $null

if (-Not $interactive) {
	$env:BW_CLIENTSECRET=$null
}

#########
# Process the values
#########
Write-Progress -Id 2 -Activity 'Processing the retrieved item' -Status 'Progress:' -PercentComplete 75

$vcFile=$item | jq.exe ".fields[] | select(.name == \`"Container Path\`") | .value"
$vcDrive=$item | jq.exe ".fields[] | select(.name == \`"Mount Drive\`") | .value"
$vcHash=$item | jq.exe ".fields[] | select(.name == \`"Hash\`") | .value"

$vcFile=$vcFile.replace("\\", "\")

$pass='"' + $pass + '"'

#########
# Mount the volume
#########
Write-Progress -Id 2 -Activity 'Mounting the volume' -Status 'Progress:' -PercentComplete 83
& $veracryptBinary /volume $vcFile /letter $vcDrive /hash $vcHash /auto /password $pass /quit /silent
Write-Progress -Id 2 -Activity 'Done!' -Status 'Progress:' -PercentComplete 100

Exit 0
