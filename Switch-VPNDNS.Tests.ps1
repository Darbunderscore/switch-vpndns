BeforeAll {
    $LAN_Mock = New-Object Microsoft.Management.Infrastructure.CimInstance('Null')
        $LAN_Mock | Add-Member -TypeName 'Microsoft.Management.Infrastructure.CimInstance#MSFT_NetAdapter' Name             "LAN-Test"
        $LAN_Mock | Add-Member -TypeName 'Microsoft.Management.Infrastructure.CimInstance#MSFT_NetAdapter' InterfaceAlias   "LAN-Test"
        $LAN_Mock | Add-Member -TypeName 'Microsoft.Management.Infrastructure.CimInstance#MSFT_NetAdapter' ConnectionState  "Connected"
        $LAN_Mock | Add-Member -TypeName 'Microsoft.Management.Infrastructure.CimInstance#MSFT_NetAdapter' ifIndex          98
        $LAN_Mock | Add-Member -TypeName 'Microsoft.Management.Infrastructure.CimInstance#MSFT_NetAdapter' InterfaceMetric  10
        $LAN_Mock | Add-Member -TypeName 'Microsoft.Management.Infrastructure.CimInstance#MSFT_NetAdapter' Status           "Up"
    $VPN_Mock = New-Object Microsoft.Management.Infrastructure.CimInstance('Null')
        $VPN_Mock | Add-Member -TypeName 'Microsoft.Management.Infrastructure.CimInstance#MSFT_NetAdapter' Name             "VPN-Test"
        $VPN_Mock | Add-Member -TypeName 'Microsoft.Management.Infrastructure.CimInstance#MSFT_NetAdapter' InterfaceAlias   "VPN-Test"
        $VPN_Mock | Add-Member -TypeName 'Microsoft.Management.Infrastructure.CimInstance#MSFT_NetAdapter' ConnectionState  "Connected"
        $VPN_Mock | Add-Member -TypeName 'Microsoft.Management.Infrastructure.CimInstance#MSFT_NetAdapter' ifIndex          99
        $VPN_Mock | Add-Member -TypeName 'Microsoft.Management.Infrastructure.CimInstance#MSFT_NetAdapter' InterfaceMetric  1
        $VPN_Mock | Add-Member -TypeName 'Microsoft.Management.Infrastructure.CimInstance#MSFT_NetAdapter' Status           "Up"

    #. $PSCommandPath.Replace('.Tests.ps1','.ps1') -LAN $LAN_Mock.Name -VPN $VPN_Mock.Name
    . $PSScriptRoot/Switch-VPNDNS-Func.ps1
    Import-Module $PSScriptRoot\PSModules\EL-PS-Common.psm1 -Force
}

Describe "Switch-VPNDNS" {
    BeforeAll {
        #Create mock obejcts for LAN and VPN adapters and interfaces
       
        Mock Get-NetAdapter { Return $LAN_Mock } -ParameterFilter { $Name -eq $LAN_Mock.Name }
        Mock Get-NetAdapter { Return $VPN_Mock } -ParameterFilter { $Name -eq $VPN_Mock.Name }
        Mock Get-NetAdapter { Return $LAN_Mock } -ParameterFilter { $InterfaceIndex -eq $LAN_Mock.ifIndex }
        Mock Get-NetAdapter { Return $VPN_Mock } -ParameterFilter { $InterfaceIndex -eq $VPN_Mock.ifIndex }
        Mock Get-NetAdapter { Return "Error" }
        
        Mock Get-NetIPInterface { Return $LAN_Mock } -ParameterFilter { $InterfaceAlias -eq $LAN_Mock.InterfaceAlias}
        Mock Get-NetIPInterface { Return $VPN_Mock } -ParameterFilter { $InterfaceAlias -eq $VPN_Mock.InterfaceAlias} 
        Mock Get-NetIPInterface { Return Write-Output }
        
        Mock Set-NetIPInterface { $LAN.InterfaceMetric = 1 } -ParameterFilter { $InterfaceAlias -eq $LAN_Mock.InterfaceAlias }
        Mock Set-NetIPInterface { $VPN.InterfaceMetric = $Metric } -ParameterFilter { $InterfaceAlias -eq $VPN_Mock.InterfaceAlias }
        
        Mock Restart-ScriptElevated {} -ModuleName EL-PS-Common
    
    }
    Context "Test ParameterSets"{
        BeforeAll {
            $VPN_Mock.ConnectionState = "Disconnected"
            $Metric = 10
            $Interval = 1
        }
        It "Testing Alias ParameterSet" {
            & $PSScriptRoot\Switch-VPNDNS.ps1 -LAN $LAN_Mock.Name -VPN $VPN_Mock.Name -Interval $Interval -Metric $Metric    
            
        }
        It "Testing Index ParameterSet" {
            & $PSScriptRoot\Switch-VPNDNS.ps1 -LAN_if $LAN_Mock.ifIndex -VPN_if $VPN_Mock.ifIndex -Interval 1
    
        }
        It "Testing Alias-Index ParameterSet" {
            & $PSScriptRoot\Switch-VPNDNS.ps1 -LAN $LAN_Mock.Name -VPN_if $VPN_Mock.ifIndex -Interval 1
        
        }
        It "Testing Index-Alias ParameterSet" {
            & $PSScriptRoot\Switch-VPNDNS.ps1 -LAN_if $LAN_Mock.ifIndex -VPN $VPN_Mock.Name -Interval 1
 
        }
        <#It "Get-NetAdapter returns ifIndex"{
            
           
        }#>
    }
    <#Context "Test-Admin" {
        It "When the user context running the function is NOT an admin and the -elevated switch was not passed, run function restart-scriptelevated" {

            Mock Test-Admin {$false}

            $Results= switch-vpndns -lan
            
            $results | Should -Be "False"
        }
        it "testing pester"{
            $Test | Should -BeNullOrEmpty
        }
    }#>
}
