# bitwarden-veracrypt
Connect to a Bitwarden server, retrieve the volume item, extract password and other parameters.
Mount the volume with VeraCrypt.

## Prerequisites
- Bitwarden CLI (https://bitwarden.com/download/) is installed and in the `PATH`
- jq (https://stedolan.github.io/jq/) is installed and in the `PATH`
- VeraCrypt (https://veracrypt.fr) is installed

## Configuration
You MUST set some variables in the script OR pass them on the command line:
- `$veracryptBinary`: full path to VeraCrypt.exe (filename included), or only the binary name if in your `PATH`
- `$pwdFile`: full path (filename included) to a text file containing only your Bitwarden master password (only in non-interactive mode)
- `$itemId`: Bitwarden-assigned ID for your volume item

You MUST also provide your credentials, either with environment variables and password file OR use the interactive mode.
Only in non-interactive mode:
- `BW_CLIENTID`: client ID provided by Bitwarden for API access
- `BW_CLIENTSECRET`: client secret provided by Bitwarden for API access
They can be set directly into the script with `$env:BW_CLIENTID` and `$env:BW_CLIENTSECRET` or preloaded into your Windows environment. `$env:BW_CLIENTSECRET` will be unset by the script for security.

In interactive mode, you will be prompted by Bitwarden for your email address and your master password. Interactive mode is activated with the `-interactive` switch

You MUST first initialize the script by specifying the Bitwarden URL to use with the `-server` parameter (see example 2 below).

Parameters for VeraCrypt are extracted from the Custom Fields in Bitwarden item. Script will look for fields named:
- `Container Path`: full path of the encrypted container
- `Mount Drive`: drive letter to mount the container as (no : after, can be lower or upper case)
- `Hash`: `[sha256|sha-256|sha512|sha-512|whirlpool|ripemd160|ripemd-160]` the hash method passed as the `/hash` parameter

## Usage

    PS> .\vs.ps1
  
Mounts the volume with all default info (as per `$env:` and inline defaults)  

    PS> .\vs.ps1 -server https://bitwarden.domain.tld
  
Initaliazes Bitwarden CLI with a custom server, then mounts the volume.

    PS> .\vs.ps1 -itemId 00000000-1111-2222-3333-444444444444 -veracryptBinary "C:\Program Files\VeraCrypt\VeraCrypt.exe"
  
Uses provided vault item ID to fetch volume info, and then mounts it with the linked VeraCrypt binary.

    PS> .\vs.ps1 -itemId 00000000-1111-2222-3333-444444444444 -interactive	
  
Does not rely on $env nor password file to open the Bitwarden vault but insteads lets Bitwarden CLI client asks for your credentials. Then mounts the volume identified by the provided vault item ID.

    PS> .\vs.ps1 -help
  
Displays help message and exits.  
