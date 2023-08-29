<#
.SYNOPSIS
Dismount all VeraCrypt volumes.

.DESCRIPTION
Dismount all currently mounted VeraCrypt columes.

You MUST set some variables in the script OR pass them on the command line:
- $veracryptBinary: full path to VeraCrypt.exe (filename included)

.INPUTS
None.

.OUTPUTS
None.

.EXAMPLE
PS> .\vc-dismount.ps1	 

.EXAMPLE
PS> .\vc-dismount.ps1 -help
#>
[CmdletBinding()]
param(	
	[Parameter(Mandatory=$false)]
	[string]
	# Specifies the full path to VeraCrypt.exe binary
	$veracryptBinary="C:\Program Files\VeraCrypt\VeraCrypt.exe",
	
	# Displays help message.
	[switch]$help
)

if ($help) {
	echo 'PS> vc-dismount.ps1 [-veracryptBinary <String>] [-help] [<CommonParameters>]'
	echo '    Dismount all volumes in non-interactive mode'
	echo ''
	echo 'For more help, see'
	echo 'PS> help C:\full\path\to\script.ps1'
	
	Exit 0
}

#########
# Dismount the volume
#########
Write-Progress -Id 1 -Activity 'Dismounting the volumes' -Status 'Progress:' -PercentComplete 0
& $veracryptBinary /dismount /quit /force
Write-Progress -Id 1 -Activity 'Done!' -Status 'Progress:' -PercentComplete 100

Exit 0