param (        
     [string]$sqlPackageArguments     
    )

$ErrorActionPreference = 'Stop'
Write-Verbose "Entering script Microsoft.TeamFoundation.DistributedTask.Task.Deployment.Sql.ps1" -Verbose

function Get-SqlPackageOnTargetMachine
{
    try
    {
        $sqlDacPath, $sqlVersion = Locate-HighestVersionSqlPackageWithSql
        $sqlVersionNumber = [decimal] $sqlVersion
    }
    catch [System.Exception]
    {
        Write-Verbose ("Failed to get Dac Framework (installed with SQL Server) location with exception: " + $_.Exception.Message) -verbose
        $sqlVersionNumber = 0
    }

	try
    {
        $sqlMsiDacPath, $sqlMsiVersion = Locate-HighestVersionSqlPackageWithDacMsi
        $sqlMsiVersionNumber = [decimal] $sqlMsiVersion
    }
    catch [System.Exception]
    {
        Write-Verbose ("Failed to get Dac Framework (installed with DAC Framework) location with exception: " + $_.Exception.Message) -verbose
        $sqlMsiVersionNumber = 0
    }

    try
    {
        $vsDacPath, $vsVersion = Locate-HighestVersionSqlPackageInVS
        $vsVersionNumber = [decimal] $vsVersion
    }
    catch [System.Exception]
    {
        Write-Verbose ("Failed to get Dac Framework (installed with Visual Studio) location with exception: " + $_.Exception.Message) -verbose
        $vsVersionNumber = 0
    }

    if (($vsVersionNumber -ge $sqlVersionNumber) -and ($vsVersionNumber -ge $sqlMsiVersionNumber))
    {
        $dacPath = $vsDacPath
    }
	elseif ($sqlVersionNumber -ge $sqlMsiVersionNumber)
    {
        $dacPath = $sqlDacPath
    }
    else
    {
        $dacPath = $sqlMsiDacPath
    }

    if ($dacPath -eq $null)
    {
        throw  "Unable to find the location of Dac Framework (SqlPackage.exe) from registry on machine $env:COMPUTERNAME"
    }
    else
    {
        return $dacPath
    }
}

function Get-RegistryValueIgnoreError
{
    param
    (
        [parameter(Mandatory = $true)]
        [Microsoft.Win32.RegistryHive]
        $RegistryHive,

        [parameter(Mandatory = $true)]
        [System.String]
        $Key,

        [parameter(Mandatory = $true)]
        [System.String]
        $Value,

        [parameter(Mandatory = $true)]
        [Microsoft.Win32.RegistryView]
        $RegistryView
    )

    try
    {
        $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey($RegistryHive, $RegistryView)
        $subKey =  $baseKey.OpenSubKey($Key)
        if($subKey -ne $null)
        {
            return $subKey.GetValue($Value)
        }
    }
    catch
    {
    }
    return $null
}

function Get-SubKeysInFloatFormat($keys)
{
    $targetKeys = @() 
        foreach ($key in $keys) 
        {		  
            try {
                $targetKeys += [decimal] $key
            }
            catch {}
        }
   
    $targetKeys    
}

function Get-SqlPackageForSqlVersion([int] $majorVersion, [bool] $wow6432Node)
{
    $sqlInstallRootRegKey = "SOFTWARE", "Microsoft", "Microsoft SQL Server", "$majorVersion" -join [System.IO.Path]::DirectorySeparatorChar

    if ($wow6432Node -eq $true)
    {
        $sqlInstallRootPath = Get-RegistryValueIgnoreError LocalMachine "$sqlInstallRootRegKey" "VerSpecificRootDir" Registry64
    }
    else
    {        
        $sqlInstallRootPath = Get-RegistryValueIgnoreError LocalMachine "$sqlInstallRootRegKey" "VerSpecificRootDir" Registry32
    }
    
    if ($sqlInstallRootPath -eq $null)
    {
        return $null
    }
    
    Write-Verbose -verbose "Sql Version Specific Root Dir for version $majorVersion as read from registry: $sqlInstallRootPath"    
        
    $DacInstallPath = [System.IO.Path]::Combine($sqlInstallRootPath, "Dac", "bin", "SqlPackage.exe")

    if (Test-Path $DacInstallPath)
    {
        Write-Verbose -verbose "Dac Framework installed with SQL Version $majorVersion found at $DacInstallPath on machine $env:COMPUTERNAME"
        return $DacInstallPath
    }
    else
    {
        return $null
    }
}

function Locate-HighestVersionSqlPackageWithSql()
{
    $sqlRegKey = "HKLM:", "SOFTWARE", "Wow6432Node", "Microsoft", "Microsoft SQL Server"-join [System.IO.Path]::DirectorySeparatorChar
    $sqlRegKey64 = "HKLM:", "SOFTWARE", "Microsoft", "Microsoft SQL Server"-join [System.IO.Path]::DirectorySeparatorChar

    if (-not (Test-Path $sqlRegKey))
    {
        $sqlRegKey = $sqlRegKey64
    }

    if (-not (Test-Path $sqlRegKey))
    {
        return $null, 0
    }

    $keys = Get-Item $sqlRegKey | %{$_.GetSubKeyNames()} 
    $versions = Get-SubKeysInFloatFormat $keys | Sort-Object -Descending

    Write-Verbose -verbose "Sql Versions installed on machine $env:COMPUTERNAME as read from registry: $versions"        

    foreach ($majorVersion in $versions) 
    {
        $DacInstallPathWow6432Node = Get-SqlPackageForSqlVersion $majorVersion $true
        $DacInstallPath = Get-SqlPackageForSqlVersion $majorVersion $false

        if ($DacInstallPathWow6432Node -ne $null)
        {            
            return $DacInstallPathWow6432Node, $majorVersion
        }
        elseif ($DacInstallPath -ne $null)
        {
            return $DacInstallPath, $majorVersion
        }
    }

    Write-Verbose -verbose "Dac Framework (installed with SQL) not found on machine $env:COMPUTERNAME"      

    return $null, 0
}

function Locate-HighestVersionSqlPackageWithDacMsi()
{
    $sqlRegKeyWow = "HKLM:", "SOFTWARE", "Wow6432Node", "Microsoft", "Microsoft SQL Server", "DACFramework", "CurrentVersion" -join [System.IO.Path]::DirectorySeparatorChar
    $sqlRegKey = "HKLM:", "SOFTWARE", "Microsoft", "Microsoft SQL Server", "DACFramework", "CurrentVersion" -join [System.IO.Path]::DirectorySeparatorChar

	$sqlKey = "SOFTWARE", "Microsoft", "Microsoft SQL Server", "DACFramework", "CurrentVersion" -join [System.IO.Path]::DirectorySeparatorChar
	
    if (Test-Path $sqlRegKey)
    {
        $dacVersion = Get-RegistryValueIgnoreError LocalMachine "$sqlKey" "Version" Registry64
        $majorVersion = $dacVersion.Substring(0, $dacVersion.IndexOf(".")) + "0"
    }
    
    if (Test-Path $sqlRegKeyWow)
    {
        $dacVersionX86 = Get-RegistryValueIgnoreError LocalMachine "$sqlKey" "Version" Registry32
        $majorVersionX86 = $dacVersionX86.Substring(0, $dacVersionX86.IndexOf(".")) + "0"
    }

	if ((-not($dacVersion)) -and (-not($dacVersionX86)))
	{
	    Write-Verbose -verbose "Dac Framework (installed with DAC Framework) not found on machine $env:COMPUTERNAME"   
	    return $null, 0
	}    

    if ($majorVersionX86 -gt $majorVersion)
    {
        $majorVersion = $majorVersionX86
    }

	$dacRelativePath = "Microsoft SQL Server", "$majorVersion", "DAC", "bin", "SqlPackage.exe" -join [System.IO.Path]::DirectorySeparatorChar
	$programFiles = $env:ProgramFiles
	$programFilesX86 = "${env:ProgramFiles(x86)}"

	if (-not ($programFilesX86 -eq $null))
	{
	    $dacPath = $programFilesX86, $dacRelativePath -join [System.IO.Path]::DirectorySeparatorChar

		if (Test-Path("$dacPath"))
		{
            Write-Verbose -verbose "Dac Framework (installed with DAC Framework Msi) found on machine $env:COMPUTERNAME at $dacPath"  
            return $dacPath, $majorVersion
		}		
	}

	if (-not ($programFiles -eq $null))
	{
	    $dacPath = $programFiles, $dacRelativePath -join [System.IO.Path]::DirectorySeparatorChar

		if (Test-Path($dacPath))
		{
            Write-Verbose -verbose "Dac Framework (installed with DAC Framework Msi) found on machine $env:COMPUTERNAME at $dacPath"  
            return $dacPath, $majorVersion
		}		
	}
    
    return $null, 0
}

function Locate-SqlPackageInVS([string] $version)
{
    $vsRegKeyForVersion = "SOFTWARE", "Microsoft", "VisualStudio", $version -join [System.IO.Path]::DirectorySeparatorChar

    $vsInstallDir = Get-RegistryValueIgnoreError LocalMachine "$vsRegKeyForVersion" "InstallDir" Registry64

    if ($vsInstallDir -eq $null)
    {
        $vsInstallDir = Get-RegistryValueIgnoreError LocalMachine "$vsRegKeyForVersion"  "InstallDir" Registry32
    } 

    if ($vsInstallDir)
    {
        Write-Verbose -verbose "Visual Studio install location: $vsInstallDir" 

        $dacExtensionPath = [System.IO.Path]::Combine("Extensions", "Microsoft", "SQLDB", "DAC")
        $dacParentDir = [System.IO.Path]::Combine($vsInstallDir, $dacExtensionPath)

        if (Test-Path $dacParentDir)
        {
            $dacVersionDirs = Get-ChildItem $dacParentDir | Sort-Object @{e={$_.Name -as [int]}} -Descending

            foreach ($dacVersionDir in $dacVersionDirs) 
            {
                $dacVersion = $dacVersionDir.Name
                $dacFullPath = [System.IO.Path]::Combine($dacVersionDir.FullName, "SqlPackage.exe")

                if(Test-Path $dacFullPath -pathtype leaf)
                {
                    Write-Verbose -verbose "Dac Framework installed with Visual Studio found at $dacFullPath on machine $env:COMPUTERNAME"
                    return $dacFullPath, $dacVersion
                }
                else
                {
                    Write-Verbose -verbose "Unable to find Dac framework installed with Visual Studio at $($dacVersionDir.FullName) on machine $env:COMPUTERNAME"
                }
            }
        }
    }

    return $null, 0
}

function Locate-HighestVersionSqlPackageInVS()
{
    $vsRegKey = "HKLM:", "SOFTWARE", "Wow6432Node", "Microsoft", "VisualStudio" -join [System.IO.Path]::DirectorySeparatorChar
    $vsRegKey64 = "HKLM:", "SOFTWARE", "Microsoft", "VisualStudio" -join [System.IO.Path]::DirectorySeparatorChar

    if (-not (Test-Path $vsRegKey))
    {
        $vsRegKey = $vsRegKey64
    }

    if (-not (Test-Path $vsRegKey))
    {
        Write-Verbose -verbose "Visual Studio not found on machine $env:COMPUTERNAME"     
        return $null, 0
    }

    $keys = Get-Item $vsRegKey | %{$_.GetSubKeyNames()} 
    $versions = Get-SubKeysInFloatFormat $keys | Sort-Object -Descending 

    Write-Verbose -verbose "Visual Studio versions found on machine $env:COMPUTERNAME as read from registry: $versions"        

    foreach ($majorVersion in $versions)
    {
        $dacFullPath, $dacVersion = Locate-SqlPackageInVS $majorVersion

        if ($dacFullPath -ne $null)
        {
            return $dacFullPath, $dacVersion
        }
    }

    Write-Verbose -verbose "Dac Framework (installed with Visual Studio) not found on machine $env:COMPUTERNAME"    

    return $null, 0
}

$ASTERISK_PASSWORD = "********"

$indexOfTargetPassword = $sqlPackageArguments.IndexOf("/TargetPassword");
if( $indexOfTargetPassword -ge 0 )
{
    $indexOfFirstQuote = $sqlPackageArguments.IndexOf("'",$indexOfTargetPassword);
    $indexOfSecondQuote = $sqlPackageArguments.IndexOf("'",$indexOfFirstQuote+1);
    $sqlPackageArgumentsToBeLogged = $sqlPackageArguments.Substring(0,$indexOfFirstQuote+1) + $ASTERISK_PASSWORD + $sqlPackageArguments.Substring($indexOfSecondQuote) 
}
else
{
    $sqlPackageArgumentsToBeLogged = $sqlPackageArguments
}
Write-Verbose "sqlPackageArguments = $sqlPackageArgumentsToBeLogged" -Verbose

$sqlPackage = Get-SqlPackageOnTargetMachine

$sqlPackageArguments = $sqlPackageArguments.Trim('"', ' ')

$command = "`"$sqlPackage`" $sqlPackageArguments"

$command = $command.Replace("'", "`"")

$indexOfTargetPassword = $command.IndexOf("/TargetPassword");
if( $indexOfTargetPassword -ge 0 )
{
    $indexOfFirstQuote = $command.IndexOf('"',$indexOfTargetPassword);
    $indexOfSecondQuote = $command.IndexOf('"',$indexOfFirstQuote+1);
    $commandToBeLogged = $command.Substring(0,$indexOfFirstQuote+1) + $ASTERISK_PASSWORD + $command.Substring($indexOfSecondQuote) 
}
else
{
    $commandToBeLogged = $command
}
Write-Verbose "Executing : $commandToBeLogged" -Verbose

$PowershellVersion5 = "5"
$ErrorActionPreference = 'Continue'

if ($PSVersionTable.PSVersion.Major -ge $PowershellVersion5)
{
    cmd.exe /c "$command"
}
else
{
    cmd.exe /c "`"$command`""
}

$ErrorActionPreference = 'Stop'

# SIG # Begin signature block
# MIIoLQYJKoZIhvcNAQcCoIIoHjCCKBoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCASfteqeV7jt1Fl
# qrQmDCdwFY9iW8VvbialeekQtAqBEKCCDXYwggX0MIID3KADAgECAhMzAAAEhV6Z
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGg0wghoJAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAASFXpnsDlkvzdcAAAAABIUwDQYJYIZIAWUDBAIB
# BQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJPtIuLu7ZVTRDXIZDcKJ7/p
# zCya6+upYiVNIXfJvZ0EMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEARj7KygeL5A3HZGrjOS+F9w3a6wYTcLKoKrjnuUfT6tMmGdW0EEX2TYP2
# QRhuUW3nKwd1/cRruDaeYIWpyzIAfQe6NeghLWI9NkkE7ePms8gBvHkXZJQpVPwg
# meaI37d+bR8R6PssXUF7GHPHkyvlDCT1fIVYAI/DPMhVVX8FEvjmGQnLbdJoZ2UO
# IffgfEFIwpXSLy3nRPAVkWReAv+l/U2in/sVXYhZOgWm9qW9tXPhkKeRkc9ZzM6K
# xIjrqcvEsHEaRmQzBP5O0sC8PmC6Eu1UXVpaIElcuCSFYvn61avp8RC/xlOO2lVM
# Hg8OGyhaVrPoGiT2gQ/6MtdqPaAEv6GCF5cwgheTBgorBgEEAYI3AwMBMYIXgzCC
# F38GCSqGSIb3DQEHAqCCF3AwghdsAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFSBgsq
# hkiG9w0BCRABBKCCAUEEggE9MIIBOQIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCAcQrkkfYYPJjSckCt70LyCEkWm4gzg+qAwhlgcpfVxTAIGaW+fmhZN
# GBMyMDI2MDIwNjA2MjA0MS44MDlaMASAAgH0oIHRpIHOMIHLMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046MzcwMy0w
# NUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Wg
# ghHtMIIHIDCCBQigAwIBAgITMwAAAgpHshTZ7rKzDwABAAACCjANBgkqhkiG9w0B
# AQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0yNTAxMzAxOTQy
# NTdaFw0yNjA0MjIxOTQyNTdaMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25z
# MScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046MzcwMy0wNUUwLUQ5NDcxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCy7NzwEpb7BpwAk9LJ00Xq30TcTjcwNZ80TxAtAbhS
# aJ2kwnJA1Au/Do9/fEBjAHv6Mmtt3fmPDeIJnQ7VBeIq8RcfjcjrbPIg3wA5v5MQ
# flPNSBNOvcXRP+fZnAy0ELDzfnJHnCkZNsQUZ7GF7LxULTKOYY2YJw4TrmcHohkY
# 6DjCZyxhqmGQwwdbjoPWRbYu/ozFem/yfJPyjVBql1068bcVh58A8c5CD6TWN/L3
# u+Ny+7O8+Dver6qBT44Ey7pfPZMZ1Hi7yvCLv5LGzSB6o2OD5GIZy7z4kh8UYHdz
# jn9Wx+QZ2233SJQKtZhpI7uHf3oMTg0zanQfz7mgudefmGBrQEg1ox3n+3Tizh0D
# 9zVmNQP9sFjsPQtNGZ9ID9H8A+kFInx4mrSxA2SyGMOQcxlGM30ktIKM3iqCuFEU
# 9CHVMpN94/1fl4T6PonJ+/oWJqFlatYuMKv2Z8uiprnFcAxCpOsDIVBO9K1vHeAM
# iQQUlcE9CD536I1YLnmO2qHagPPmXhdOGrHUnCUtop21elukHh75q/5zH+OnNekp
# 5udpjQNZCviYAZdHsLnkU0NfUAr6r1UqDcSq1yf5RiwimB8SjsdmHll4gPjmqVi0
# /rmnM1oAEQm3PyWcTQQibYLiuKN7Y4io5bJTVwm+vRRbpJ5UL/D33C//7qnHbeoW
# BQIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFAKvF0EEj4AyPfY8W/qrsAvftZwkMB8G
# A1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCG
# Tmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUy
# MFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4w
# XAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwG
# A1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwDgYDVR0PAQH/BAQD
# AgeAMA0GCSqGSIb3DQEBCwUAA4ICAQCwk3PW0CyjOaqXCMOusTde7ep2CwP/xV1J
# 3o9KAiKSdq8a2UR5RCHYhnJseemweMUH2kNefpnAh2Bn8H2opDztDJkj8OYRd/KQ
# ysE12NwaY3KOwAW8Rg8OdXv5fUZIsOWgprkCQM0VoFHdXYExkJN3EzBbUCUw3yb4
# gAFPK56T+6cPpI8MJLJCQXHNMgti2QZhX9KkfRAffFYMFcpsbI+oziC5Brrk3361
# cJFHhgEJR0J42nqZTGSgUpDGHSZARGqNcAV5h+OQDLeF2p3URx/P6McUg1nJ2gMP
# YBsD+bwd9B0c/XIZ9Mt3ujlELPpkijjCdSZxhzu2M3SZWJr57uY+FC+LspvIOH1O
# pofanh3JGDosNcAEu9yUMWKsEBMngD6VWQSQYZ6X9F80zCoeZwTq0i9AujnYzzx5
# W2fEgZejRu6K1GCASmztNlYJlACjqafWRofTqkJhV/J2v97X3ruDvfpuOuQoUtVA
# wXrDsG2NOBuvVso5KdW54hBSsz/4+ORB4qLnq4/GNtajUHorKRKHGOgFo8DKaXG+
# UNANwhGNxHbILSa59PxExMgCjBRP3828yGKsquSEzzLNWnz5af9ZmeH4809fwItt
# I41JkuiY9X6hmMmLYv8OY34vvOK+zyxkS+9BULVAP6gt+yaHaBlrln8Gi4/dBr2y
# 6Srr/56g0DCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZI
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
# 6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDBcQZqELQdVTNYs6FwZvKhggNQ
# MIICOAIBATCB+aGB0aSBzjCByzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEn
# MCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjM3MDMtMDVFMC1EOTQ3MSUwIwYDVQQD
# ExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQDR
# AMVJlA6bKq93Vnu3UkJgm5HlYaCBgzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUAAgUA7S/b1zAiGA8yMDI2MDIwNjAzMTc0
# M1oYDzIwMjYwMjA3MDMxNzQzWjB3MD0GCisGAQQBhFkKBAExLzAtMAoCBQDtL9vX
# AgEAMAoCAQACAg4VAgH/MAcCAQACAhJaMAoCBQDtMS1XAgEAMDYGCisGAQQBhFkK
# BAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJ
# KoZIhvcNAQELBQADggEBAI8XN3ljkH3GLgz05AaXtiJglmQDYfaP6BD2Lz5ChusL
# 0dNmWAytorXOFY9/Hgy6gf6I0intOjIAefnIxwGU4d8m58wKwTJqH4dCJI8gs1H8
# V1Xm+7/rNK81YnW+9MpkqTjkf6mUt+f33D2qjDW2HBnR3vxC2l+6bBI3mTNBkEkp
# 8chiTJRGfxcviaflZx3yH41EEza/gpcpK1xyjWmEW3HrPTYBwxa/DKQS5+Trat8m
# dEdbs/aXCnni+qkwc1vmvmeTu+D6pAC+hR/t1hkEN4ZA819Tx9k5bx65Hvqd4NQE
# LVDIcpwjAfVXvZRQoKIDf/6TqJCYdhV2jSyZBngGkP8xggQNMIIECQIBATCBkzB8
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1N
# aWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAgpHshTZ7rKzDwABAAAC
# CjANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEE
# MC8GCSqGSIb3DQEJBDEiBCCfQvQbgDrHYQj2OCpNEio6J5feNA0kBLNMGfkoKrim
# 2TCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EIE2ay/y0epK/X3Z03KTcloqE
# 8u9IXRtdO7Mex0hw9+SaMIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENB
# IDIwMTACEzMAAAIKR7IU2e6ysw8AAQAAAgowIgQgWsOD0WvpDJoaYmGAIX13HEYt
# QadwrFaDyrhIOzEK+wUwDQYJKoZIhvcNAQELBQAEggIALjA2/htqh/g4Wvq55x2n
# /FKO0K5XnHsh7YSvKIoetilrpxFSvNTQ/T/EybwTfy5QvMHNvKytxRESR+Gpg/BU
# cc7uOPj+7TUAcfuJwDQtk5ETz3gEXkFsPSVuLX+Lwkwbk8/9b/qgkZ9wILtU9J7y
# aevOzDe3Ht585AqVCe7sFd/0WdYNrDcGw8hAiJqSIHfph2O89vtYGn+Cll0xIKhy
# PBxTKkM03IlaLu6ReqG5RN49jbzAapvzy/Xmi62pcgXGDGPZIFGoDKTokjA2Zkee
# oPiRLElf/aN9zJAY1s7Jr2SS7PTmsfoOwyCTgNR4OuOpwAw3surzm95gnrpfvDkG
# Z/1k8SEhVFJOBAz1rh6/rfe8XpJoT2AJ52w0H6VpYhuF1EeYli+z77gUS+8BIT0L
# EACBgeap48otvjsFe0/S7X5HSidseqVRi1QOVIOzxHhJbU/wu4VzxUtA1h0PLDGC
# D/Gq6Wq1XQgS6xfTNQSFnclKXEiKnmxgJV1tycBcxRXZVMaL53K9KBQhs6RqKJDM
# /BOA76HhXc97IvzF+ReWb55Qmokx7lCXn7GSBwbYjxrOjFNIwy0cKK90Oac+Yxdy
# Os+zju2CE2kz3G8wmOe3LBVju3InYVZ40MK+g9UU3nuiMlyV/T96qkxzT6fwBa/n
# VOqOhFJWK/grCNn5hBXDiGU=
# SIG # End signature block
