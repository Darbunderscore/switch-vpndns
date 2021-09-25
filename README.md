# switch-vpndns.ps1
## Description

Changes the IPv4 & IPv6 interface metric of the VPN adapter. Script will run while VPN is connected and periodically checks to make sure values have not changed.
Optionally will run an IPCONFIG /RELEASE6 to clear IPv6 info to force Windows into using the IPv4-configured DNS servers.

## Usage
Switch-VPNDNS **-LAN_if** *LAN_Interface_Alias* **-VPN_if** *VPN_Interface_Alias* [**-Metric** [*integer*]] [**-Interval** [*integer*]] [**-DisableIPv6**]<br><br>
(Required) -LAN_if: Set -LAN_if to your Wired or Wifi local network interface alias.<br>
(Required) -VPN_if:      Set -VPN_if to your VPN interface alias.<br>
(Optional) -Metric:      Specify an interface metric, otherwise the default is 10.<br>
(Optional) -Interval:    Specify a recheck interval (in seconds), otherwise the default is 60 seconds.<br>
(Optional) -DisableIPv6: Release IPv6 DHCP values (to force DNS over IPv4).
