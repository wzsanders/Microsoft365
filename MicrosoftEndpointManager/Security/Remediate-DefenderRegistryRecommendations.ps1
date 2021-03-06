#region Config
$AppName = "Remediate-Defender-Registry-Recommendations"
$client = "William Sanders"
$logPath = "$env:ProgramData\$client\logs"
$logFile = "$logPath\$AppName.log"
#region Keys
$hkcuKeys = @()
# $hkcuKeys = @(
#     [PSCustomObject]@{
#         Guid  = "{639eb309-1f65-4071-a4df-6d0443c87236}"
#         Name  = "RunAsPPL"
#         Type  = "DWord"
#         Value = 1
#         Path  = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
#     }
# )
$hklmKeys = @(
    [PSCustomObject]@{
        Path  = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        Name  = "RunAsPPL"
        Type  = "DWord"
        Value = 1
    },
    [PSCustomObject]@{
        Path  = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        Name  = "DisableDomainCreds"
        Type  = "DWord"
        Value = 1
    },
    [PSCustomObject]@{
        Path  = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        Name  = "MaxDevicePasswordFailedAttempts"
        Type  = "DWord"
        Value = 10
    }
)
#endregion
#endregion
#region Functions
function Set-RegistryKey {
    <#
    .SYNOPSIS
        This function will set the specified registry key to the specified value. If the key path does not exist, it will be created.
    .EXAMPLE
        PS> Set-RegistryKey -RegistryInstance @{'Name' = 'Setting'; 'Type' = 'String'; 'Value' = 'someval'; 'Path' = 'SOFTWARE\Microsoft\Windows\Something'}
        This example would modify the string reigstry key 'Setting' to 'someval' in the registry key 'SOFTWARE\Microsoft\Windows\Something'.
    .PARAMETER RegistryInstance
        A hash table containing key names of 'Name' designating the registry value name, 'Type' to designate the type
        of registry value which can be 'String, Binary, DWord, ExpandString, or MultiString', 'Value' which is the
        value of the registry key, and 'Path' designating the parent registry key the registry value is in.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        $RegistryInstance
    )
    try {
        foreach ($instance in $RegistryInstance) {
            # Create the key path if it does not exist
            if (-Not (Test-Path -Path $instance.Path)) {
                Write-Host -Object "Registry path $($instance.Path) does not exist. Creating..." -ForegroundColor Green
                if ($PSCmdlet.ShouldProcess($instance.Path, "Create Registry Key")) {
                    New-Item -Path ($instance.Path | Split-Path -Parent) -Name ($instance.Path | Split-Path -Leaf) -Force | Out-Null
                }
            }
            else {
                Write-Host -Object "Registry path $($instance.Path) exists. Continuing..." -ForegroundColor Green
            }
            # Create (or modify) the specified value
            if ($PSCmdlet.ShouldProcess($instance.Name, "Set Registry Value")) {
            Write-Host -Object "Setting item property $($instance.Name)" -ForegroundColor Green
                Set-ItemProperty -Path $instance.Path -Name $instance.Name -Value $instance.Value -Type $instance.Type -Force | Out-Null
            }
        }
    }
    catch {
        throw -Message $_.Exception.Message
    }
}
#endregion
#region Logging
if (!(Test-Path -Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force | Out-Null
}
$errorOccurred = $false
Start-Transcript -Path $logFile -ErrorAction SilentlyContinue -Force
#endregion
#region Process
try {
    if ($hkcuKeys) {
        Write-Host -Object "Setting HKCU registry keys" -ForegroundColor Green
        foreach ($key in $hkcuKeys) {
            # TODO: Add support for setting registry keys for all users
        }
    }

    Write-Host -Object "Setting HKLM registry keys" -ForegroundColor Green
    foreach ($key in $hklmKeys) {
        Set-RegistryKey -RegistryInstance $key
    }
}
catch {
    $errorOccurred = $_.Exception.Message
}
finally {
    if ($errorOccurred) {
        Write-Warning -Message $errorOccurred
        Stop-Transcript
        throw $errorOccurred
    }
    else {
        Write-Host -Object "Script completed successfully"
        Stop-Transcript -ErrorAction SilentlyContinue
    }
}
#endregion

