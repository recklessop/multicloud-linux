# All four returned values should match on a Hyper-V VM
Get-WmiObject Win32_SystemEnclosure | select-object -Expandproperty serialnumber
Get-WmiObject Win32_SystemEnclosure | select-object -Expandproperty SMBIOSAssetTag
Get-WmiObject Win32_SystemEnclosure | select-object -Expandproperty serialnumber
Get-WmiObject Win32_BaseBoard | select-object -ExpandProperty SerialNumber
