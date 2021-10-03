
<#PSScriptInfo

.VERSION 1.3.0

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
    Rewrote check for elevated state to use new function.
v1.2.1
    Bugfix: Script erroneously detects LAN and VPN interfaces as not up.
V1.3.0
    Created function for retreiving adapter info and running validation tests.
    Created function for running main loop
    Created Pester tests

USAGE:
Switch-VPNDNS -LAN <LAN_Interface_Alias> -VPN <VPN_Interface_Alias> [-Metric [integer]] [-Interval [integer]] [-DisableIPv6]
Switch-VPNDNS -LAN <LAN_Interface_Alias> -VPN_if <VPN_Interface_Index> [-Metric [integer]] [-Interval [integer]] [-DisableIPv6]
Switch-VPNDNS -LAN_if <LAN_Interface_Index> -VPN <VPN_Interface_Alias> [-Metric [integer]] [-Interval [integer]] [-DisableIPv6]
Switch-VPNDNS -LAN_if <LAN_Interface_Index> -VPN_if <VPN_Interface_Index> [-Metric [integer]] [-Interval [integer]] [-DisableIPv6]

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

##### INCLUDES ##################

Import-Module $PSScriptRoot\PSModules\EL-PS-Common.psm1
. $PSScriptRoot\Switch-VPNDNS-Func.ps1

##### BEFORE ####################

$ErrorActionPreference= "Stop"

# Check that script is running with elevated access:
If (!(Test-Admin) -and $elevated){
    Write-Error -Message "FATAL: Could not elevate privleges. Please restart PowerShell in elevated mode before running this script." -ErrorId 99 -TargetObject $_ -ErrorAction Stop
}
Elseif (!(Test-Admin)){
    Write-Warning "Script ran with non-elevated privleges."
    Restart-ScriptElevated -ScriptArgs $PSBoundParameters -PSPath $PSCommandPath
    exit
}
Else { Write-Output "INFO: Running script in elevated mode." }

##### MAIN ######################

Initialize-NetAdapters -ScriptArgs $PSBoundParameters

If ($DisableIPv6){ Invoke-Switch -LAN $Global:LAN -VPN $Global:VPN -Metric $Global:Metric -Interval $Interval -DisableIPv6 }
Else { Invoke-Switch -LAN $Global:LAN -VPN $Global:VPN -Metric $Global:Metric -Interval $Interval }

##### END #######################

Write-Output "VPN is no longer connected, script exiting..."
[system.media.systemsounds]::Exclamation.play()

##### SCRIPT END ################ 