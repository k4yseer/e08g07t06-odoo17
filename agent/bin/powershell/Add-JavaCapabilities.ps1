[CmdletBinding()]
param()

# Define the JRE/JDK key names.
$jre6KeyName = "Software\JavaSoft\Java Runtime Environment\1.6"
$jre7KeyName = "Software\JavaSoft\Java Runtime Environment\1.7"
$jre8KeyName = "Software\JavaSoft\Java Runtime Environment\1.8"
$jdk6KeyName = "Software\JavaSoft\Java Development Kit\1.6"
$jdk7KeyName = "Software\JavaSoft\Java Development Kit\1.7"
$jdk8KeyName = "Software\JavaSoft\Java Development Kit\1.8"

# JRE/JDK keys for major version >= 9
$jdk9AndGreaterNameOracle = "Software\JavaSoft\JDK"
$jre9AndGreaterNameOracle = "Software\JavaSoft\JRE"
$jre9AndGreaterName = "Software\JavaSoft\Java Runtime Environment"
$jdk9AndGreaterName = "Software\JavaSoft\Java Development Kit"
$minimumMajorVersion9 = 9

# JRE/JDK keys for AdoptOpenJDK
$jdk9AndGreaterNameAdoptOpenJDK = "Software\AdoptOpenJDK\JDK"
$jdk9AndGreaterNameAdoptOpenJRE = "Software\AdoptOpenJDK\JRE"

# These keys required for several previous versions of AdoptOpenJDK that were published under the name Eclipse Foundation
$jdk9AndGreaterNameAdoptOpenJDKEclipseFoundation = "Software\Eclipse Foundation\JDK"
$jdk9AndGreaterNameAdoptOpenJREEclipseFoundation = "Software\Eclipse Foundation\JRE"

# These keys required for latest versions of AdoptOpenJDK since they started to publish under Eclipse Adoptium name from 22th October 2021 https://blog.adoptopenjdk.net/2021/03/transition-to-eclipse-an-update/ 
$jdk9AndGreaterNameAdoptOpenJDKEclipseAdoptium = "Software\Eclipse Adoptium\JDK"
$jdk9AndGreaterNameAdoptOpenJREEclipseAdoptium = "Software\Eclipse Adoptium\JRE"

# JRE/JDK keys for AdoptOpenJDK with openj9 runtime
$jdk9AndGreaterNameAdoptOpenJDKSemeru = "Software\Semeru\JDK"
$jdk9AndGreaterNameAdoptOpenJRESemeru = "Software\Semeru\JRE"

# JVM subdirectories for AdoptOpenJDK, since it could be ditributed with two different JVM versions, which are located in different subdirectories inside version directory
$jvmHotSpot = "hotspot\MSI"
$jvmOpenj9 = "openj9\MSI"

# Check for JRE.
$latestJre = $null
$null = Add-CapabilityFromRegistry -Name 'java_6' -Hive 'LocalMachine' -View 'Registry32' -KeyName $jre6KeyName -ValueName 'JavaHome' -Value ([ref]$latestJre)
$null = Add-CapabilityFromRegistry -Name 'java_7' -Hive 'LocalMachine' -View 'Registry32' -KeyName $jre7KeyName -ValueName 'JavaHome' -Value ([ref]$latestJre)
$null = Add-CapabilityFromRegistry -Name 'java_8' -Hive 'LocalMachine' -View 'Registry32' -KeyName $jre8KeyName -ValueName 'JavaHome' -Value ([ref]$latestJre)
$null = Add-CapabilityFromRegistry -Name 'java_6_x64' -Hive 'LocalMachine' -View 'Registry64' -KeyName $jre6KeyName -ValueName 'JavaHome' -Value ([ref]$latestJre)
$null = Add-CapabilityFromRegistry -Name 'java_7_x64' -Hive 'LocalMachine' -View 'Registry64' -KeyName $jre7KeyName -ValueName 'JavaHome' -Value ([ref]$latestJre)
$null = Add-CapabilityFromRegistry -Name 'java_8_x64' -Hive 'LocalMachine' -View 'Registry64' -KeyName $jre8KeyName -ValueName 'JavaHome' -Value ([ref]$latestJre)

if  (-not (Test-Path env:DISABLE_JAVA_CAPABILITY_HIGHER_THAN_9)) {
    try {
        $null = Add-CapabilityFromRegistryWithLastVersionAvailable -PrefixName 'java_' -Hive 'LocalMachine' -View 'Registry32' -KeyName $jre9AndGreaterName -ValueName 'JavaHome' -Value ([ref]$latestJre) -MinimumMajorVersion $minimumMajorVersion9
        $null = Add-CapabilityFromRegistryWithLastVersionAvailable -PrefixName 'java_' -Hive 'LocalMachine' -View 'Registry32' -KeyName $jre9AndGreaterNameOracle -ValueName 'JavaHome' -Value ([ref]$latestJre) -MinimumMajorVersion $minimumMajorVersion9
        $null = Add-CapabilityFromRegistryWithLastVersionAvailable -PrefixName 'java_' -PostfixName '_x64' -Hive 'LocalMachine' -View 'Registry64' -KeyName $jre9AndGreaterName -ValueName 'JavaHome' -Value ([ref]$latestJre) -MinimumMajorVersion $minimumMajorVersion9
        $null = Add-CapabilityFromRegistryWithLastVersionAvailable -PrefixName 'java_' -PostfixName '_x64' -Hive 'LocalMachine' -View 'Registry64' -KeyName $jre9AndGreaterNameOracle -ValueName 'JavaHome' -Value ([ref]$latestJre) -MinimumMajorVersion $minimumMajorVersion9
    } catch {
        Write-Host "An error occured while trying to check if there are JRE >= 9"
        Write-Host $_
    }
}

# Check default reg keys for AdoptOpenJDK in case we didn't find JRE in JavaSoft
if (-not $latestJre) {
    # AdoptOpenJDK section
    $null = Add-CapabilityFromRegistryWithLastVersionAvailable -PrefixName 'java_' -PostfixName '_x64' -Hive 'LocalMachine' -View 'Registry64' -KeyName $jdk9AndGreaterNameAdoptOpenJRE -ValueName 'Path' -Value ([ref]$latestJre) -VersionSubdirectory $jvmHotSpot -MinimumMajorVersion $minimumMajorVersion9
    $null = Add-CapabilityFromRegistryWithLastVersionAvailable -PrefixName 'java_' -PostfixName '_x64' -Hive 'LocalMachine' -View 'Registry64' -KeyName $jdk9AndGreaterNameAdoptOpenJRE -ValueName 'Path' -Value ([ref]$latestJre) -VersionSubdirectory $jvmOpenj9 -MinimumMajorVersion $minimumMajorVersion9
    $null = Add-CapabilityFromRegistryWithLastVersionAvailable -PrefixName 'java_' -PostfixName '_x64' -Hive 'LocalMachine' -View 'Registry64' -KeyName $jdk9AndGreaterNameAdoptOpenJREEclipseAdoptium -ValueName 'Path' -Value ([ref]$latestJre) -VersionSubdirectory $jvmHotSpot -MinimumMajorVersion $minimumMajorVersion9
    $null = Add-CapabilityFromRegistryWithLastVersionAvailable -PrefixName 'java_' -PostfixName '_x64' -Hive 'LocalMachine' -View 'Registry64' -KeyName $jdk9AndGreaterNameAdoptOpenJREEclipseFoundation -ValueName 'Path' -Value ([ref]$latestJre) -VersionSubdirectory $jvmHotSpot -MinimumMajorVersion $minimumMajorVersion9
    $null = Add-CapabilityFromRegistryWithLastVersionAvailable -PrefixName 'java_' -PostfixName '_x64' -Hive 'LocalMachine' -View 'Registry64' -KeyName $jdk9AndGreaterNameAdoptOpenJRESemeru -ValueName 'Path' -Value ([ref]$latestJre) -VersionSubdirectory $jvmOpenj9 -MinimumMajorVersion $minimumMajorVersion9
}

if ($latestJre) {
    # Favor x64.
    Write-Capability -Name 'java' -Value $latestJre
}

# Check for JDK.
$latestJdk = $null
$null = Add-CapabilityFromRegistry -Name 'jdk_6' -Hive 'LocalMachine' -View 'Registry32' -KeyName $jdk6KeyName -ValueName 'JavaHome' -Value ([ref]$latestJdk)
$null = Add-CapabilityFromRegistry -Name 'jdk_7' -Hive 'LocalMachine' -View 'Registry32' -KeyName $jdk7KeyName -ValueName 'JavaHome' -Value ([ref]$latestJdk)
$null = Add-CapabilityFromRegistry -Name 'jdk_8' -Hive 'LocalMachine' -View 'Registry32' -KeyName $jdk8KeyName -ValueName 'JavaHome' -Value ([ref]$latestJdk)
$null = Add-CapabilityFromRegistry -Name 'jdk_6_x64' -Hive 'LocalMachine' -View 'Registry64' -KeyName $jdk6KeyName -ValueName 'JavaHome' -Value ([ref]$latestJdk)
$null = Add-CapabilityFromRegistry -Name 'jdk_7_x64' -Hive 'LocalMachine' -View 'Registry64' -KeyName $jdk7KeyName -ValueName 'JavaHome' -Value ([ref]$latestJdk)
$null = Add-CapabilityFromRegistry -Name 'jdk_8_x64' -Hive 'LocalMachine' -View 'Registry64' -KeyName $jdk8KeyName -ValueName 'JavaHome' -Value ([ref]$latestJdk)

if  (-not (Test-Path env:DISABLE_JAVA_CAPABILITY_HIGHER_THAN_9)) {
    try {
        $null = Add-CapabilityFromRegistryWithLastVersionAvailable -PrefixName 'jdk_' -Hive 'LocalMachine' -View 'Registry32' -KeyName $jdk9AndGreaterName -ValueName 'JavaHome' -Value ([ref]$latestJdk) -MinimumMajorVersion $minimumMajorVersion9
        $null = Add-CapabilityFromRegistryWithLastVersionAvailable -PrefixName 'jdk_' -Hive 'LocalMachine' -View 'Registry32' -KeyName $jdk9AndGreaterNameOracle -ValueName 'JavaHome' -Value ([ref]$latestJdk) -MinimumMajorVersion $minimumMajorVersion9
        $null = Add-CapabilityFromRegistryWithLastVersionAvailable -PrefixName 'jdk_' -PostfixName '_x64' -Hive 'LocalMachine' -View 'Registry64' -KeyName $jdk9AndGreaterName -ValueName 'JavaHome' -Value ([ref]$latestJdk) -MinimumMajorVersion $minimumMajorVersion9
        $null = Add-CapabilityFromRegistryWithLastVersionAvailable -PrefixName 'jdk_' -PostfixName '_x64' -Hive 'LocalMachine' -View 'Registry64' -KeyName $jdk9AndGreaterNameOracle -ValueName 'JavaHome' -Value ([ref]$latestJdk) -MinimumMajorVersion $minimumMajorVersion9
    } catch {
        Write-Host "An error occured while trying to check if there are JDK >= 9"
        Write-Host $_
    }
}

# Check default reg keys for AdoptOpenJDK in case we didn't find JDK in JavaSoft
if (-not $latestJdk) {
    # AdoptOpenJDK section
    $null = Add-CapabilityFromRegistryWithLastVersionAvailable -PrefixName 'jdk_' -PostfixName '_x64' -Hive 'LocalMachine' -View 'Registry64' -KeyName $jdk9AndGreaterNameAdoptOpenJDK -ValueName 'Path' -Value ([ref]$latestJdk) -VersionSubdirectory $jvmHotSpot -MinimumMajorVersion $minimumMajorVersion9
    $null = Add-CapabilityFromRegistryWithLastVersionAvailable -PrefixName 'jdk_' -PostfixName '_x64' -Hive 'LocalMachine' -View 'Registry64' -KeyName $jdk9AndGreaterNameAdoptOpenJDK -ValueName 'Path' -Value ([ref]$latestJdk) -VersionSubdirectory $jvmOpenj9 -MinimumMajorVersion $minimumMajorVersion9
    $null = Add-CapabilityFromRegistryWithLastVersionAvailable -PrefixName 'jdk_' -PostfixName '_x64' -Hive 'LocalMachine' -View 'Registry64' -KeyName $jdk9AndGreaterNameAdoptOpenJDKEclipseAdoptium -ValueName 'Path' -Value ([ref]$latestJdk) -VersionSubdirectory $jvmHotSpot -MinimumMajorVersion $minimumMajorVersion9
    $null = Add-CapabilityFromRegistryWithLastVersionAvailable -PrefixName 'jdk_' -PostfixName '_x64' -Hive 'LocalMachine' -View 'Registry64' -KeyName $jdk9AndGreaterNameAdoptOpenJDKEclipseFoundation -ValueName 'Path' -Value ([ref]$latestJdk) -VersionSubdirectory $jvmHotSpot -MinimumMajorVersion $minimumMajorVersion9
    $null = Add-CapabilityFromRegistryWithLastVersionAvailable -PrefixName 'jdk_' -PostfixName '_x64' -Hive 'LocalMachine' -View 'Registry64' -KeyName $jdk9AndGreaterNameAdoptOpenJDKSemeru -ValueName 'Path' -Value ([ref]$latestJdk) -VersionSubdirectory $jvmOpenj9 -MinimumMajorVersion $minimumMajorVersion9
}

if ($latestJdk) {
    # Favor x64.
    Write-Capability -Name 'jdk' -Value $latestJdk

    if (!($latestJre)) {
        Write-Capability -Name 'java' -Value $latestJdk
    }
}

# SIG # Begin signature block
# MIIoKgYJKoZIhvcNAQcCoIIoGzCCKBcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBLTDBXOq2L2qu5
# EMVq1eURFS7cpBgTWmK5DdpGpsi0LKCCDXYwggX0MIID3KADAgECAhMzAAAEhV6Z
# 7A5ZL83XAAAAAASFMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjUwNjE5MTgyMTM3WhcNMjYwNjE3MTgyMTM3WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDASkh1cpvuUqfbqxele7LCSHEamVNBfFE4uY1FkGsAdUF/vnjpE1dnAD9vMOqy
# 5ZO49ILhP4jiP/P2Pn9ao+5TDtKmcQ+pZdzbG7t43yRXJC3nXvTGQroodPi9USQi
# 9rI+0gwuXRKBII7L+k3kMkKLmFrsWUjzgXVCLYa6ZH7BCALAcJWZTwWPoiT4HpqQ
# hJcYLB7pfetAVCeBEVZD8itKQ6QA5/LQR+9X6dlSj4Vxta4JnpxvgSrkjXCz+tlJ
# 67ABZ551lw23RWU1uyfgCfEFhBfiyPR2WSjskPl9ap6qrf8fNQ1sGYun2p4JdXxe
# UAKf1hVa/3TQXjvPTiRXCnJPAgMBAAGjggFzMIIBbzAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUuCZyGiCuLYE0aU7j5TFqY05kko0w
# RQYDVR0RBD4wPKQ6MDgxHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEW
# MBQGA1UEBRMNMjMwMDEyKzUwNTM1OTAfBgNVHSMEGDAWgBRIbmTlUAXTgqoXNzci
# tW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3JsMGEG
# CCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3J0
# MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIBACjmqAp2Ci4sTHZci+qk
# tEAKsFk5HNVGKyWR2rFGXsd7cggZ04H5U4SV0fAL6fOE9dLvt4I7HBHLhpGdE5Uj
# Ly4NxLTG2bDAkeAVmxmd2uKWVGKym1aarDxXfv3GCN4mRX+Pn4c+py3S/6Kkt5eS
# DAIIsrzKw3Kh2SW1hCwXX/k1v4b+NH1Fjl+i/xPJspXCFuZB4aC5FLT5fgbRKqns
# WeAdn8DsrYQhT3QXLt6Nv3/dMzv7G/Cdpbdcoul8FYl+t3dmXM+SIClC3l2ae0wO
# lNrQ42yQEycuPU5OoqLT85jsZ7+4CaScfFINlO7l7Y7r/xauqHbSPQ1r3oIC+e71
# 5s2G3ClZa3y99aYx2lnXYe1srcrIx8NAXTViiypXVn9ZGmEkfNcfDiqGQwkml5z9
# nm3pWiBZ69adaBBbAFEjyJG4y0a76bel/4sDCVvaZzLM3TFbxVO9BQrjZRtbJZbk
# C3XArpLqZSfx53SuYdddxPX8pvcqFuEu8wcUeD05t9xNbJ4TtdAECJlEi0vvBxlm
# M5tzFXy2qZeqPMXHSQYqPgZ9jvScZ6NwznFD0+33kbzyhOSz/WuGbAu4cHZG8gKn
# lQVT4uA2Diex9DMs2WHiokNknYlLoUeWXW1QrJLpqO82TLyKTbBM/oZHAdIc0kzo
# STro9b3+vjn2809D0+SOOCVZMIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEwOTA5WjB+MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQg
# Q29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+laUKq4BjgaBEm6f8MMHt03
# a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc6Whe0t+bU7IKLMOv2akr
# rnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4Ddato88tt8zpcoRb0Rrrg
# OGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+lD3v++MrWhAfTVYoonpy
# 4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nkkDstrjNYxbc+/jLTswM9
# sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6A4aN91/w0FK/jJSHvMAh
# dCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmdX4jiJV3TIUs+UsS1Vz8k
# A/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL5zmhD+kjSbwYuER8ReTB
# w3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zdsGbiwZeBe+3W7UvnSSmn
# Eyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3T8HhhUSJxAlMxdSlQy90
# lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS4NaIjAsCAwEAAaOCAe0w
# ggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRIbmTlUAXTgqoXNzcitW2o
# ynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
# VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBDuRQFTuHqp8cx0SOJNDBa
# BgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3JsMF4GCCsG
# AQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3J0MIGfBgNV
# HSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEFBQcCARYzaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1hcnljcHMuaHRtMEAGCCsG
# AQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkAYwB5AF8AcwB0AGEAdABl
# AG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn8oalmOBUeRou09h0ZyKb
# C5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7v0epo/Np22O/IjWll11l
# hJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0bpdS1HXeUOeLpZMlEPXh6
# I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/KmtYSWMfCWluWpiW5IP0
# wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvyCInWH8MyGOLwxS3OW560
# STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBpmLJZiWhub6e3dMNABQam
# ASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJihsMdYzaXht/a8/jyFqGa
# J+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYbBL7fQccOKO7eZS/sl/ah
# XJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbSoqKfenoi+kiVH6v7RyOA
# 9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sLgOppO6/8MO0ETI7f33Vt
# Y5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtXcVZOSEXAQsmbdlsKgEhr
# /Xmfwb1tbWrJUnMTDXpQzTGCGgowghoGAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAASFXpnsDlkvzdcAAAAABIUwDQYJYIZIAWUDBAIB
# BQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIP1r26ja0Xd+Wr2Ntrtb3cY5
# M07/W1VGK1GBi1k59xN2MEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAYjL2I3Pk8aGcJ6xecfxSpG7jT2+F9FZapRFH5qudgnls+/B5KH9JUPaZ
# 8VCHxLV4RLpbAwydN7P0lAHjdDToCFIfrp8DEQP1TIG0/eXZ5i3Iw3e4wvm4PM18
# koYqsLh1PAMMGzIHc5TAmQrS/MgsbUohdy4QXac4imUACgbo/KAXJc+zgMKPHc+X
# IXD66iqfcQdvqvWk1wkrzMySR7Uy0F70fDrKZn6tBHgftTlll7ypJaQQ7bf2HL1V
# qFcggOTtZuYGM3QMiOg47M4077IuHKXV+HzOeb7ORTGRIGwTuPH1hC3gcy11rcW5
# UIkNskONwQt1tLlMAIn5/iZ5HF8VJKGCF5QwgheQBgorBgEEAYI3AwMBMYIXgDCC
# F3wGCSqGSIb3DQEHAqCCF20wghdpAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFSBgsq
# hkiG9w0BCRABBKCCAUEEggE9MIIBOQIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCC/+s6RwtItSg0hJfjW8GRSWnDymGTq5JcwTM8aUAtOywIGaW+wjjPB
# GBMyMDI2MDIwNjA2MjA0MS4xNjFaMASAAgH0oIHRpIHOMIHLMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046OTYwMC0w
# NUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Wg
# ghHqMIIHIDCCBQigAwIBAgITMwAAAgTY4A4HlzJYmAABAAACBDANBgkqhkiG9w0B
# AQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0yNTAxMzAxOTQy
# NDdaFw0yNjA0MjIxOTQyNDdaMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25z
# MScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046OTYwMC0wNUUwLUQ5NDcxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQDw3Sbcee2d66vkWGTIXhfGqqgQGxQXTnq44XlUvNzF
# St7ELtO4B939jwZFX7DrRt/4fpzGNkFdGpc7EL5S86qKYv360eXjW+fIv1lAqDD3
# 1d/p8Ai9/AZz8M95zo0rDpK2csz9WAyR9FtUDx52VOs9qP3/pgpHvgUvD8s6/3KN
# ITzms8QC1tJ3TMw1cRn9CZgVIYzw2iD/ZvOW0sbF/DRdgM8UdtxjFIKTXTaI/bJh
# sQge3TwayKQ2j85RafFFVCR5/ChapkrBQWGwNFaPzpmYN46mPiOvUxriISC9nQ/G
# rDXUJWzLDmchrmr2baABJevvw31UYlTlLZY6zUmjkgaRfpozd+Glq9TY2E3Dglr6
# PtTEKgPu2hM6v8NiU5nTvxhDnxdmcf8UN7goeVlELXbOm7j8yw1xM9IyyQuUMWko
# rBaN/5r9g4lvYkMohRXEYB0tMaOPt0FmZmQMLBFpNRVnXBTa4haXvn1adKrvTz8V
# lfnHxkH6riA/h2AlqYWhv0YULsEcHnaDWgqA29ry+jH097MpJ/FHGHxk+d9kH2L5
# aJPpAYuNmMNPB7FDTPWAx7Apjr/J5MhUx0i07gV2brAZ9J9RHi+fMPbS+Qm4AonC
# 5iOTj+dKCttVRs+jKKuO63CLwqlljvnUCmuSavOX54IXOtKcFZkfDdOZ7cE4DioP
# 1QIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFBp1dktAcGpW/Km6qm+vu4M1GaJfMB8G
# A1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCG
# Tmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUy
# MFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4w
# XAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwG
# A1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwDgYDVR0PAQH/BAQD
# AgeAMA0GCSqGSIb3DQEBCwUAA4ICAQBecv6sRw2HTLMyUC1WJJ+FR+DgA9Jkv0lG
# sIt4y69CmOj8R63oFbhSmcdpakxqNbr8v9dyTb4RDyNqtohiiXbtrXmQK5X7y/Q+
# +F0zMotTtTpTPvG3eltyV/LvO15mrLoNQ7W4VH58aLt030tORxs8VnAQQF5BmQQM
# Oua+EQgH4f1F4uF6rl3EC17JBSJ0wjHSea/n0WYiHPR0qkz/NRAf8lSUUV0gbIMa
# wGIjn7+RKyCr+8l1xdNkK/F0UYuX3hG0nE+9Wc0L4A/enluUN7Pa9vOV6Vi3BOJS
# T0RY/ax7iZ45leM8kqCw7BFPcTIkWzxpjr2nCtirnkw7OBQ6FNgwIuAvYNTU7r60
# W421YFOL5pTsMZcNDOOsA01xv7ymCF6zknMGpRHuw0Rb2BAJC9quU7CXWbMbAJLd
# Z6XINKariSmCX3/MLdzcW5XOycK0QhoRNRf4WqXRshEBaY2ymJvHO48oSSY/kpuY
# vBS3ljAAuLN7Rp8jWS7t916paGeE7prmrP9FJsoy1LFKmFnW+vg43ANhByuAEXq9
# Cay5o7K2H5NFnR5wj/SLRKwK1iyUX926i1TEviEiAh/PVyJbAD4koipig28p/6HD
# uiYOZ0wUkm/a5W8orIjoOdU3XsJ4i08CfNp5I73CsvB5QPYMcLpF9NO/1LvoQAw3
# UPdL55M5HTCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZI
# hvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# MjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAy
# MDEwMB4XDTIxMDkzMDE4MjIyNVoXDTMwMDkzMDE4MzIyNVowfDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
# bWUtU3RhbXAgUENBIDIwMTAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
# AQDk4aZM57RyIQt5osvXJHm9DtWC0/3unAcH0qlsTnXIyjVX9gF/bErg4r25Phdg
# M/9cT8dm95VTcVrifkpa/rg2Z4VGIwy1jRPPdzLAEBjoYH1qUoNEt6aORmsHFPPF
# dvWGUNzBRMhxXFExN6AKOG6N7dcP2CZTfDlhAnrEqv1yaa8dq6z2Nr41JmTamDu6
# GnszrYBbfowQHJ1S/rboYiXcag/PXfT+jlPP1uyFVk3v3byNpOORj7I5LFGc6XBp
# Dco2LXCOMcg1KL3jtIckw+DJj361VI/c+gVVmG1oO5pGve2krnopN6zL64NF50Zu
# yjLVwIYwXE8s4mKyzbnijYjklqwBSru+cakXW2dg3viSkR4dPf0gz3N9QZpGdc3E
# XzTdEonW/aUgfX782Z5F37ZyL9t9X4C626p+Nuw2TPYrbqgSUei/BQOj0XOmTTd0
# lBw0gg/wEPK3Rxjtp+iZfD9M269ewvPV2HM9Q07BMzlMjgK8QmguEOqEUUbi0b1q
# GFphAXPKZ6Je1yh2AuIzGHLXpyDwwvoSCtdjbwzJNmSLW6CmgyFdXzB0kZSU2LlQ
# +QuJYfM2BjUYhEfb3BvR/bLUHMVr9lxSUV0S2yW6r1AFemzFER1y7435UsSFF5PA
# PBXbGjfHCBUYP3irRbb1Hode2o+eFnJpxq57t7c+auIurQIDAQABo4IB3TCCAdkw
# EgYJKwYBBAGCNxUBBAUCAwEAATAjBgkrBgEEAYI3FQIEFgQUKqdS/mTEmr6CkTxG
# NSnPEP8vBO4wHQYDVR0OBBYEFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMFwGA1UdIARV
# MFMwUQYMKwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTATBgNVHSUEDDAK
# BggrBgEFBQcDCDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMC
# AYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV9lbLj+iiXGJo0T2UkFvX
# zpoYxDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20v
# cGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcmwwWgYI
# KwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNydDANBgkqhkiG
# 9w0BAQsFAAOCAgEAnVV9/Cqt4SwfZwExJFvhnnJL/Klv6lwUtj5OR2R4sQaTlz0x
# M7U518JxNj/aZGx80HU5bbsPMeTCj/ts0aGUGCLu6WZnOlNN3Zi6th542DYunKmC
# VgADsAW+iehp4LoJ7nvfam++Kctu2D9IdQHZGN5tggz1bSNU5HhTdSRXud2f8449
# xvNo32X2pFaq95W2KFUn0CS9QKC/GbYSEhFdPSfgQJY4rPf5KYnDvBewVIVCs/wM
# nosZiefwC2qBwoEZQhlSdYo2wh3DYXMuLGt7bj8sCXgU6ZGyqVvfSaN0DLzskYDS
# PeZKPmY7T7uG+jIa2Zb0j/aRAfbOxnT99kxybxCrdTDFNLB62FD+CljdQDzHVG2d
# Y3RILLFORy3BFARxv2T5JL5zbcqOCb2zAVdJVGTZc9d/HltEAY5aGZFrDZ+kKNxn
# GSgkujhLmm77IVRrakURR6nxt67I6IleT53S0Ex2tVdUCbFpAUR+fKFhbHP+Crvs
# QWY9af3LwUFJfn6Tvsv4O+S3Fb+0zj6lMVGEvL8CwYKiexcdFYmNcP7ntdAoGokL
# jzbaukz5m/8K6TT4JDVnK+ANuOaMmdbhIurwJ0I9JZTmdHRbatGePu1+oDEzfbzL
# 6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDBcQZqELQdVTNYs6FwZvKhggNN
# MIICNQIBATCB+aGB0aSBzjCByzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEn
# MCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjk2MDAtMDVFMC1EOTQ3MSUwIwYDVQQD
# ExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQC6
# PYHRw9+9SH+1pwy6qzVG3k9lbqCBgzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUAAgUA7S/szjAiGA8yMDI2MDIwNjA0MzAw
# NloYDzIwMjYwMjA3MDQzMDA2WjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDtL+zO
# AgEAMAcCAQACAjTtMAcCAQACAhMYMAoCBQDtMT5OAgEAMDYGCisGAQQBhFkKBAIx
# KDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJKoZI
# hvcNAQELBQADggEBAIzHnUuAL0TV2WboQsx4n5aG/lT/n4sWkP9CFGY7whvjOk4s
# ChJGNKvZ+P6GTUuEA8nNHGWs4gG+jzOEYV9uK1NoyNzm5DztOL8JcG0HULmAtkGc
# Uqr99Bv6zZCXUweYKF1Gm+GMToWImGdWs2kmLhv/aI5MY2EYFdKrYOP1gTvt6D7s
# 2WO7NKmpS4RiPO+G7pmSEYSSH72HSXWdZTetLFPU5pX+iy5fiiO+WoeL71SQdhfs
# Lj7ynw3tKT1IxcytyQszVWLdMZKARMB1eZTcE+ROJWWVUw61sHWK/HN/KNUSpvYT
# JMrAaJxxnT5osemh3F6ALFUoY4f3/frcWuiq2DQxggQNMIIECQIBATCBkzB8MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAgTY4A4HlzJYmAABAAACBDAN
# BglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8G
# CSqGSIb3DQEJBDEiBCDYKWx5M3dpHb6nGkKvnC0AjNcN1U3LSxQJSCtkD+HfyjCB
# +gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EIPnteGX9Wwq8VdJM6mjfx1GEJsu7
# /6kU6l0SS5rcebn+MIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTACEzMAAAIE2OAOB5cyWJgAAQAAAgQwIgQgrd7CAAp1ImFrd9aKxKbhWfliCU/o
# Glnc09blmW4I8zEwDQYJKoZIhvcNAQELBQAEggIAaaQB3faw48WjbjraxKo6Fkv9
# nx9+qfwS9cB8ST5PkMTNsHF3ToJ6UxZmzeEZNlp+YfOd7T9dvIQG3QbJKnEOshT5
# pfs7AKcXz4j3pqEdgRLfqAYD6DGdzkUBxrAEn6o8vIaDVndPjxP8V8fy3iKkgMsp
# 7BdAhZD1ljylshZ40slZ/Ypi3LMB58rr6RJ2w2SFOlCL37X4IGexlob20JOfzgwM
# VH6fcR3KU1QZ53g6ToIfr5dLDCLgBLtf8RylB7xpve9K32UHa5NF80HUxxhXhjTR
# bs84gWOL+JVbiFBr586rOjLnX89jnlVQb8SZoSqKmiiXsfXi0+flajnAiwlGP8aI
# gFxjzVGz4oJsJVt2QtfVM9TguxCfN6R6YX8JWAtLv8Ntwf1zwaO5A3zxxMOqx9B7
# 5AUoTXLwVC1xtMW9gt8oK20JLKLDilZgMw7ULPolP53ofYnisioULdsZshIID9XB
# 0l2rkOCS/T7cKtNWr6c034HmZ12Wo85IQ7BU1QIQ+AyW9eZ9gW2negD2m83TCtj7
# MtHHTEO/7LqGyfEHyxqReiu5Mb5I2PlGhdju8C+TfMdlLEwyL3EyfBfhcFSimX7P
# gjSAhty2z9xFtuowl7Rb4QYrhlBwJjbA2p6Trg9iKQU6QmHXWj9yR9lSgcXXGS1t
# sFCAdpKI1SMKY0myoIA=
# SIG # End signature block
