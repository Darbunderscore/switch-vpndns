Function Initialize-NetAdapters {
    Param (
        $ScriptArgs
    )
    # 1. Interfaces exist?
        Foreach ($param in $ScriptArgs.GetEnumerator()) {
            Switch ($param.key) {
                "LAN"    { [CimInstance]$Global:LAN = Get-NetAdapter -Name $param.Value }
                "LAN_if" { [CimInstance]$Global:LAN = Get-NetAdapter -InterfaceIndex $param.Value }
                "VPN"    { [CimInstance]$Global:VPN = Get-NetAdapter -Name $param.Value }
                "VPN_if" { [CimInstance]$Global:VPN = Get-NetAdapter -InterfaceIndex $param.Value }
                Default {}
            }
        }
    # 2. Interfaces identical?
        If ($Global:LAN -eq $Global:VPN) { Write-Error -Message "FATAL: The same network adapter cannot be used for both LAN and VPN interfaces." -ErrorID 98  -TargetObject $_ -ErrorAction Stop}
    # 3. Interfaces up?
        If (($Global:LAN.status -ne "Up") -or ($Global:VPN.status -ne "Up")){ Write-Error -Message "FATAL: LAN and/or VPN interface(s) not connected."  -ErrorID 97 -TargetObject $_ -ErrorAction Stop }
    }
Function Invoke-SwitchVPNDNS {
    Param (
        $LAN,
        $VPN,
        $Metric,
        [switch]$DisableIPv6,
        $Interval
    )
    While ((Get-NetIPInterface -InterfaceAlias $VPN.InterfaceAlias).ConnectionState -eq "Connected"){
        Clear-Host
        Write-Output ("Checking Interface Metric of {0}..." -f $VPN.Name)
            if ((Get-NetIPInterface -InterfaceAlias $VPN.InterfaceAlias).InterfaceMetric -ne $Metric){
                Write-Output "Interface Metric out of scope. Resetting to $Metric..."
                    Set-NetIPInterface -InterfaceAlias $VPN.InterfaceAlias -InterfaceMetric $Metric
            }
        
        Write-Output ("Checking Interface Metric of {0}..." -f $LAN.Name)
            if ((Get-NetIPInterface -InterfaceAlias $LAN.InterfaceAlias).InterfaceMetric -ne 1){ 
                Write-Output "Interface metric out of scope. Resetting to 1..."
                    Set-NetIPInterface -InterfaceAlias $LAN.InterfaceAlias -InterfaceMetric 1
            }
        
        if ($DisableIPv6){
            Write-Output "Releasing IPv6 DHCP Lease..."
                Get-NetIPAddress -InterfaceAlias $LAN.InterfaceAlias -AddressFamily IPv6 | Remove-NetIPAddress -Confirm:$false | Out-Null
        }
        
        Write-Output "Flushing DNS Cache..."
            Clear-DnsClientCache | Out-Null
        Write-Output "Sleeping for $Interval seconds..."
            Start-Sleep -Seconds $Interval
    }
    
    Write-Output "INFO: VPN is no longer connected."
    [system.media.systemsounds]::Exclamation.play()
}