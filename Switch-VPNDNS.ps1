
<#PSScriptInfo

.VERSION 1.2.0

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
v1.0.0
    Inital release.
v1.1.0
    Moved EL-PS-Common module to subdirectory to support git submodules.
v1.2.0
    Added validation checks for interfaces
    Added ability to reference LAN and VPN interfaces by alias or index.

USAGE:
Switch-VPNDNS -LAN <LAN_Interface_Alias> -VPN <VPN_Interface_Alias> [-Metric [integer]] [-Interval [integer]] [-DisableIPv6]
Switch-VPNDNS -LAN <LAN_Interface_Alias> -VPN_if <VPN_Interface_Index> [-Metric [integer]] [-Interval [integer]] [-DisableIPv6]
Switch-VPNDNS -LAN_if <LAN_Interface_Index> -VPN <VPN_Interface_Alias> [-Metric [integer]] [-Interval [integer]] [-DisableIPv6]
Switch-VPNDNS -LAN_if <LAN_Interface_Index> -VPN_if <VPN_Interface_Alias> [-Metric [integer]] [-Interval [integer]] [-DisableIPv6]

(Required) -LAN OR -LAN_if: Set -LAN to the local network interface alias OR -LAN_if to the the local network interface index.
(Required) -VPN OR -VPN_if: Set -VPN to the VPN interface alias OR -VPN_if to the VPN interface index.
(Optional) -Metric: Specify an interface metric, default is 10.
(Optional) -Interval: Specify a recheck interval (in seconds), default is 60.
(Optional) -DisableIPv6: Release IPv6 DHCP values (to force DNS over IPv4).
        
#>

<# 

.DESCRIPTION 
 Changes the IPv4 & IPv6 interface metric of the VPN adapter. Script will run while VPN is connected and periodically check to make sure values have not changed.

#> 
[CmdletBinding()]
param (
    [Parameter(Mandatory,
               ParameterSetName= 'Alias')]
    [Parameter(Mandatory,
               ParameterSetName= 'Alias-Index')]
    [string]
        $LAN,

    [Parameter(Mandatory,
               ParameterSetName= 'Alias')]
    [Parameter(Mandatory,
               ParameterSetName= 'Index-Alias')]
    [string]
        $VPN,

    [Parameter(Mandatory,
               ParameterSetName= 'Index-Alias')]
    [Parameter(Mandatory,
               ParameterSetName= 'Index')]
    [int]
        $LAN_if,

    [Parameter(Mandatory,
               ParameterSetName= 'Alias-Index')]
    [Parameter(Mandatory,
               ParameterSetName= 'Index')]
    [int]    
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

$ErrorActionPreference= "Stop"

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
    write-error -Message "FATAL: Could not elevate privleges. Please restart Powershell in elevated mode before running this script." -ErrorId 99 -TargetObject $_ -ErrorAction Stop
}

else { Write-Output "INFO: Running script in elevated mode." }

# Validate Interfaces
# 1. Interfaces exist?
If ($LAN) {
    Try{ $LAN_tmp= Get-NetAdapter $LAN }
    Catch { Write-Error -Message "FATAL: Could not find network interface $LAN."  -ErrorID 90 -TargetObject $_ -ErrorAction Stop }
    $LAN = $LAN_tmp
}
Elseif ($LAN_if){
    Try { $LAN_tmp= Get-NetAdapter -InterfaceIndex $LAN_if}
    Catch { Write-Error -Message "FATAL: Could not find network interface with interface index $LAN_if."  -ErrorID 90 -TargetObject $_ -ErrorAction Stop }
    $LAN = $LAN_tmp
}
If ($VPN) {
    Try{ $VPN_tmp= Get-NetAdapter $VPN }
    Catch { Write-Error -Message "FATAL: Could not find network interface $VPN."  -ErrorID 90 -TargetObject $_ -ErrorAction Stop }
    $VPN = $VPN_tmp
}
Elseif ($VPN_if){
    Try { $VPN_tmp= Get-NetAdapter -InterfaceIndex $VPN_if}
    Catch { Write-Error -Message "FATAL: Could not find network interface with interface index $VPN_if."  -ErrorID 90 -TargetObject $_ -ErrorAction Stop }
    $VPN = $VPN_tmp
}
# 2. Interfaces identical?
If ($LAN -eq $VPN) { Write-Error -Message "FATAL: LAN and VPN interfaces cannot be identical." -ErrorID 98  -TargetObject $_ -ErrorAction Stop}
# 3. Inferfaces connected?
If (($LAN.status -ne "Up") -or ($VPN.status -ne "Up")){ Write-Error -Message "FATAL: LAN and/or VPN interface(s) not connected."  -ErrorID 97 -TargetObject $_ -ErrorAction Stop }

##### MAIN #####

while ($($VPN | Get-NetIPInterface -PolicyStore ActiveStore).connectionstate -eq "connected"){
    write-output ("Checking Interface Metric of {0}..." -f $VPN.Name)
    if ((Get-NetIPInterface -InterfaceAlias $VPN.InterfaceAlias).InterfaceMetric -ne $Metric){
        write-output "Interface Metric out of scope. Resetting..."
        Set-NetIPInterface -InterfaceAlias $VPN.InterfaceAlias -InterfaceMetric $Metric
    }
    if ((Get-NetIPInterface -InterfaceAlias $LAN.InterfaceAlias).InterfaceMetric -ne 1){ 
        Set-NetIPInterface -InterfaceAlias $LAN.InterfaceAlias -InterfaceMetric 1
    }
    if ($DisableIPv6){ invoke-command -ScriptBlock { ipconfig /release6 >> $null } }
    Invoke-Command -ScriptBlock { ipconfig /flushdns >> $null }
    start-sleep -seconds $Interval
}
Write-Output "VPN is no longer connected, script exiting..."
[system.media.systemsounds]::Exclamation.play()
