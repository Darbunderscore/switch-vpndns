
<#PSScriptInfo

.VERSION 1.0.0

.GUID c07f0f7f-8ef5-48c1-92ed-a2bd6cf5c1ed

.AUTHOR Brad Eley (brad.eley@gmail.com)

.COMPANYNAME 

.COPYRIGHT (c) 2021 Brad Eley (brad.eley@gmail.com)
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

.TAGS 

.LICENSEURI https://www.gnu.org/licenses/

.PROJECTURI https://github.com/Darbunderscore/switch-vpndns

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
Usage:  Set LAN_if to your Wired or Wifi local network interface alias. Set VPN_if to your VPN interface alias.
        Optionally specify an interface metric, otherwise the default is 10.
        Optionally specify a recheck interval (in seconds), otherwise the default is 60 seconds.
        To release IPv6 DHCP values (to force DNS over IPv4), specify the -DisableIPv6 switch.
        
#Requires -Module EL-PS-Common
#>



<# 

.DESCRIPTION 
 Changes the IPv4 & IPv6 interface metric of the VPN adapter. Script will run while VPN is connected and periodically check to make sure values have not changed.

#> 
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $LAN_if,
    [Parameter(Mandatory)]
    [string]
    $VPN_if,
    [int]
    $Metric= 10,
    [switch]
    $DisableIPv6,
    [int]
    $Interval= 60,
    [switch]
    $Elevated
)

### INCLUDES ####################

Import-Module $PSScriptRoot\PSModules\EL-PS-Common.psm1

#################################

# Check that script is running with elevated access
if (!(Test-Admin))  {
    Write-Warning "Script ran with non-elevated privleges."
    if (!$elevated) 
    {
        write-output "INFO: Attempting script restart in elevated mode..."
        $AllParameters_String = "";
        ForEach ($Parameter in $PSBoundParameters.GetEnumerator()){
            $Parameter_Key = $Parameter.Key;
            $Parameter_Value = $Parameter.Value;
            $Parameter_Value_Type = $Parameter_Value.GetType().Name;
    
            If ($Parameter_Value_Type -Eq "SwitchParameter"){
                $AllParameters_String += " -$Parameter_Key";
            } Else {
                $AllParameters_String += " -$Parameter_Key `"$Parameter_Value`"";
            }
        }
    
        $Arguments= @("-NoProfile","-NoExit","-File",$PSCommandPath,"-elevated",$AllParameters_String)
    
        Start-Process PowerShell -Verb Runas -ArgumentList $Arguments
        exit
    } 
    # tried to elevate, did not work, aborting
    write-error -Message "Could not elevate privleges. Please restart Powershell in elevated mode before running this script." -ErrorId 99 -TargetObject $_ -ErrorAction Stop
}

else { Write-Output "INFO: Running script in elevated mode." }

##### MAIN #####

while ((Get-NetIPInterface -InterfaceAlias $VPN_if).connectionstate -eq "Connected"){
    write-output "Checking Interface Metric of $VPN_if..."
    if ((Get-NetIPInterface -InterfaceAlias $VPN_if).InterfaceMetric -ne $Metric){
        write-output "Interface Metric out of scope. Resetting..."
        Set-NetIPInterface -InterfaceAlias $VPN_if -InterfaceMetric $Metric
    }
    if ((Get-NetIPInterface -InterfaceAlias $LAN_if).InterfaceMetric -ne 1){ 
        Set-NetIPInterface -InterfaceAlias $LAN_if -InterfaceMetric 1
    }
    if ($DisableIPv6){ invoke-command -ScriptBlock { ipconfig /release6 >> $null } }
    Invoke-Command -ScriptBlock { ipconfig /flushdns >> $null }
    start-sleep -seconds $Interval
}
Write-Output "VPN is no longer connected, script exiting..."
[system.media.systemsounds]::Exclamation.play()
