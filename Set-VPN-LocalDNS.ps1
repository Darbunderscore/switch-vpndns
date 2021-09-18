
<#PSScriptInfo

.VERSION 1.0.0

.GUID c07f0f7f-8ef5-48c1-92ed-a2bd6cf5c1ed

.AUTHOR Brad Eley (brad.eley@gmail.com)

.COMPANYNAME 

.COPYRIGHT (c) 2021 Brad Eley. All rights reserved.

.TAGS 

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
Usage:  Set LAN_if to your Wired or Wifi local network interface alias. Set VPN_if to your VPN interface alias.
        Optionally specify an interface metric, otherwise the default is 10.
        Optionally specify a recheck interval (in seconds), otherwise the default is 60 seconds.
        To release IPv6 DHCP values (to force DNS over IPv4), specify the -DisableIPv6 switch.
        

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
    [int16]
    $Interval= 60
)

while ((Get-NetIPInterface -InterfaceAlias $VPN_if).connectionstate -eq "Connected"){
    write-host "Checking Interface Metric of $VPN_if..."
    if ((Get-NetIPInterface -InterfaceAlias $VPN_if).InterfaceMetric -ne $Metric){
        write-host "Interface Metric out of scope. Resetting..."
        Set-NetIPInterface -InterfaceAlias $VPN_if -InterfaceMetric $Metric
    }
    if ((Get-NetIPInterface -InterfaceAlias $LAN_if).InterfaceMetric -ne 1){ 
        Set-NetIPInterface -InterfaceAlias $LAN_if -InterfaceMetric 1
    }
    if ($DisableIPv6){ invoke-command -ScriptBlock { ipconfig /release6 >> $null } }
    Invoke-Command -ScriptBlock { ipconfig /flushdns >> $null }
    start-sleep -seconds $Interval
}
