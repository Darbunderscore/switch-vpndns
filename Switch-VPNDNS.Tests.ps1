BeforeAll {
    # Create mock obejcts for LAN and VPN adapters and interfaces
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

    . $PSScriptRoot/Switch-VPNDNS-Func.ps1
}

Describe 'Switch-VPNDNS' {
    BeforeAll {
        
        $Metric = 10
        $Interval = 1

        Mock Get-NetAdapter { Return $LAN_Mock } -ParameterFilter { $Name -eq $LAN_Mock.Name }
        Mock Get-NetAdapter { Return $VPN_Mock } -ParameterFilter { $Name -eq $VPN_Mock.Name }
        Mock Get-NetAdapter { Return $LAN_Mock } -ParameterFilter { $InterfaceIndex -eq $LAN_Mock.ifIndex }
        Mock Get-NetAdapter { Return $VPN_Mock } -ParameterFilter { $InterfaceIndex -eq $VPN_Mock.ifIndex }
        Mock Get-NetAdapter {}
        
        Mock Get-NetIPInterface { Return $LAN_Mock } -ParameterFilter { $InterfaceAlias -eq $LAN_Mock.InterfaceAlias}
        Mock Get-NetIPInterface { Return $VPN_Mock } -ParameterFilter { $InterfaceAlias -eq $VPN_Mock.InterfaceAlias} 
        Mock Get-NetIPInterface { Return Write-Output }
        
        Mock Set-NetIPInterface { $Global:LAN.InterfaceMetric = 1 } -ParameterFilter { $InterfaceAlias -eq $LAN_Mock.InterfaceAlias }
        Mock Set-NetIPInterface { $Global:VPN.InterfaceMetric = $Metric } -ParameterFilter { $InterfaceAlias -eq $VPN_Mock.InterfaceAlias }
        
        Mock Restart-ScriptElevated {}

        Mock Test-Admin { Return $true }
    }
    
    Context "Test ParameterSets"{
        BeforeAll {
            Mock Import-Module { Throw "ParameterSet Passed." }
        }
        It "Testing <Name> ParameterSet" -ForEach @(
            @{ "Result" = { & $PSScriptRoot\Switch-VPNDNS.ps1 -LAN $LAN_Mock.Name -VPN $VPN_Mock.Name -Interval $Interval -Metric $Metric -DisableIPv6 -elevated };              "Name" = "Alias"        }
            @{ "Result" = { & $PSScriptRoot\Switch-VPNDNS.ps1 -LAN_if $LAN_Mock.ifIndex -VPN_if $VPN_Mock.ifIndex -Interval $Interval -Metric $Metric -DisableIPv6 -elevated };  "Name" = "Index"        }
            @{ "Result" = { & $PSScriptRoot\Switch-VPNDNS.ps1 -LAN $LAN_Mock.Name -VPN_if $VPN_Mock.ifIndex -Interval $Interval -Metric $Metric -DisableIPv6 -elevated };        "Name" = "Alias-Index"  }
            @{ "Result" = { & $PSScriptRoot\Switch-VPNDNS.ps1 -LAN_if $LAN_Mock.ifIndex -VPN $VPN_Mock.Name -Interval $Interval -Metric $Metric -DisableIPv6 -elevated };        "Name" = "Index-Alias"  }
        ) {
            $Result | Should -Throw "ParameterSet Passed."
        }
    }

    Context 'Test-Admin' {
        BeforeAll {
            Mock Test-Admin { Return $false }
            Mock Write-Warning {}
        }

        It "When the user context running the function is NOT an admin and the -elevated switch was not passed" {
            & $PSScriptRoot\Switch-VPNDNS.ps1 -LAN $LAN_Mock.Name -VPN $VPN_Mock.Name -Interval $Interval -Metric $Metric -DisableIPv6
            
            Should -Invoke Restart-ScriptElevated -Exactly 1 
        }
        It "When the user context running the function is NOT an admin and -elevated switch WAS passed" {
            $Result = { & $PSScriptRoot\Switch-VPNDNS.ps1 -LAN $LAN_Mock.Name -VPN $VPN_Mock.Name -Interval $Interval -Metric $Metric -DisableIPv6 -elevated }

            $Result | Should -Throw
        }
    }

    Context 'Initalize-NetAdapters' {
        Context "By name" {
            BeforeAll{
                $ScriptArgs = @{ "LAN" = $LAN_Mock.Name;"VPN" = $VPN_Mock.Name}
            }
            BeforeEach {
                $LAN_Mock.Name = "LAN-Test"
                $LAN_Mock.ifIndex = 98
                $LAN_Mock.Status = "Up"
                $VPN_Mock.Name = "VPN-Test"
                $VPN_Mock.ifIndex = 99
                $VPN_Mock.Status = "Up"
            }

            It "When both interfaces are found and status' are up" {              
                Initialize-NetAdapters -ScriptArgs $ScriptArgs
                $Global:LAN.Status | Should -Be "Up"
                $Global:VPN.Status | Should -Be "Up"
            }
            It "When <Adapter.Name> <ifProperty> is <ifState>" -ForEach @(
                @{ "Adapter" = $LAN_Mock; "ifProperty" = 'Status';  "ifState" = "Down"           }
               # @{ "ifName" = $LAN_Mock; "ifProperty" = 'Status';  "ifState" = "Down"       ; "Result" = { $LAN_Mock.Status = "Down"; Initialize-NetAdapters -ScriptArgs $ScriptArgs } }
               # @{ "ifName" = $VPN_Mock; "ifProperty" = 'Status';  "ifState" = "Down"          }
               # @{ "ifName" = $LAN_Mock; "ifProperty" = 'Name';    "ifState" = "VPN-Test"      }
               # @{ "ifName" = $LAN_Mock; "ifProperty" = 'Name';    "ifState" = "LAN-Invalid"   }
               # @{ "ifName" = $VPN_Mock; "ifProperty" = 'Name';    "ifState" = "VPN-Invalid"   }
            ) {
                
                $_.Adapter.$ifProperty = $ifState

                $Result= {Initialize-NetAdapters -ScriptArgs $ScriptArgs}
                $Result | Should -Throw
            }
           <# It "When <ifName1.Name> <ifProperty1> is <ifState1> and <ifName2.Name> <ifProperty2> is <ifState2>" -ForEach @(
                @{  "ifName1" = $LAN_Mock; "ifProperty1" = 'Status'; "ifState1" = "Down"       ;`
                    "ifName2" = $VPN_Mock; "ifProperty2" = 'Status'; "ifState2" = "Down"       }
                @{  "ifName1" = $LAN_Mock; "ifProperty1" = 'Name';   "ifState1" = "LAN-Invalid";`
                    "ifName2" = $VPN_Mock; "ifProperty2" = 'Name';   "ifState2" = "VPN-Invalid"}   
            ){
                $ifNme1.$ifProperty1 = $ifState1
                $ifName2.$ifProperty2 = $ifState2

                $Result= {Initialize-NetAdapters -ScriptArgs $ScriptArgs}
                $Result | Should -Throw
            }   #>
        }
        
        Context "By index" {
            BeforeAll {
                $ScriptArgs = @{ "LAN_if" = $LAN_Mock.ifIndex;"VPN_if" = $VPN_Mock.ifIndex}
            }
            BeforeEach {
                $LAN_Mock.Name = "LAN-Test"
                $LAN_Mock.ifIndex = 98
                $LAN_Mock.Status = "Up"
                $VPN_Mock.Name = "VPN-Test"
                $VPN_Mock.ifIndex = 99
                $VPN_Mock.Status = "Up"
            }

            It "When both interfaces are found and status' are up" {              
                Initialize-NetAdapters -ScriptArgs $ScriptArgs
                $Global:LAN.Status | Should -Be "Up"
                $Global:VPN.Status | Should -Be "Up"
            }
            It "When LAN interface is down" {
                $LAN_Mock.Status = "Down"

                $Result= {Initialize-NetAdapters -ScriptArgs $ScriptArgs}
                $Result | Should -Throw
            }
            It "When VPN interface is down" {
                $VPN_Mock.Status = "Down"

                $Result= {Initialize-NetAdapters -ScriptArgs $ScriptArgs}
                $Result | Should -Throw
            }
            It "When both interfaces are down" {
                $LAN_Mock.Status = "Down"
                $VPN_Mock.Status = "Down"

                $Result= {Initialize-NetAdapters -ScriptArgs $ScriptArgs}
                $Result | Should -Throw
            }
            It "When the same adapter was used for LAN and VPN" {
                $LAN_Mock.ifIndex = 99

                $Result= {Initialize-NetAdapters -ScriptArgs $ScriptArgs}
                $Result | Should -Throw
            }
            It "When LAN adapter not found" {
                $LAN_Mock.ifIndex = 97

                $Result= {Initialize-NetAdapters -ScriptArgs $ScriptArgs}
                $Result | Should -Throw
            }
            It "When VPN adapter not found" {
                $VPN_Mock.ifIndex = 97

                $Result= {Initialize-NetAdapters -ScriptArgs $ScriptArgs}
                $Result | Should -Throw
            }
            It "When neither adapter is found" {
                $LAN_Mock.ifIndex = 97
                $VPN_Mock.ifIndex = 96

                $Result= {Initialize-NetAdapters -ScriptArgs $ScriptArgs}
                $Result | Should -Throw
            }     
        }
    }
}
