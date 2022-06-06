# switch-vpndns.ps1
## Description

Changes the IPv4 & IPv6 interface metric of the VPN adapter. Script will run while VPN is connected and periodically checks to make sure values have not changed.
Optionally will run an IPCONFIG /RELEASE6 to clear IPv6 info to force Windows into using the IPv4-configured DNS servers.

## Usage
Switch-VPNDNS **-LAN** *<LAN_Interface_Alias>* **-VPN** *<VPN_Interface_Alias>* [-Metric [integer]] [-Interval [integer]] [-DisableIPv6]<br>
Switch-VPNDNS **-LAN** *<LAN_Interface_Alias>* **-VPN_if** *<VPN_Interface_Index>* [-Metric [integer]] [-Interval [integer]] [-DisableIPv6]<br>
Switch-VPNDNS **-LAN_if** *<LAN_Interface_Index>* **-VPN** *<VPN_Interface_Alias>* [-Metric [integer]] [-Interval [integer]] [-DisableIPv6]<br>
Switch-VPNDNS **-LAN_if** *<LAN_Interface_Index>* **-VPN_if** *<VPN_Interface_Index>* [-Metric [integer]] [-Interval [integer]] [-DisableIPv6]<br>

(Required) -LAN OR -LAN_if: Set -LAN to the local network interface alias OR -LAN_if to the the local network interface index.<br>
(Required) -VPN OR -VPN_if: Set -VPN to the VPN interface alias OR -VPN_if to the VPN interface index.<br>
(Optional) -Metric: Specify an interface metric, default is 10.<br>
(Optional) -Interval: Specify a recheck interval (in seconds), default is 60.<br>
(Optional) -DisableIPv6: Release IPv6 DHCP values (to force DNS over IPv4).<br>

### If Cloning Repo:
This repository makes use of a submodule. After cloning, run the following commands to retrieve the files:<br>
**git submodule init**<br>
**git submodule update** 
