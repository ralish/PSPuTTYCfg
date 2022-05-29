# See the help for Set-StrictMode for the full details on what this enables.
Set-StrictMode -Version 2.0

# Global variables (set by Initialize-PuTTYCfg on first invocation)
$Initialized = $false
$CfgData = [PSCustomObject]@{
    Json     = $null
    Registry = $null
}

# Module constants
Set-Variable -Option ReadOnly -Scope Script -Name JsonSchemaUri -Value 'https://raw.githubusercontent.com/ralish/PSPuTTYCfg/stable/schemas/session.jsonc'

# JSON session constants
Set-Variable -Option ReadOnly -Scope Script -Name JsonValidExts -Value @('.json', '.json')

# Registry session constants
Set-Variable -Option ReadOnly -Scope Script -Name RegSessionsPath -Value 'HKCU:\SOFTWARE\SimonTatham\PuTTY\Sessions'
Set-Variable -Option ReadOnly -Scope Script -Name RegIgnoredSettings -Value @(
    'BoldFont'
    'BoldFontCharSet'
    'BoldFontHeight'
    'BoldFontIsBold'
    'LoginShell'
    'NetHackKeypad'
    'PingInterval'
    'Present'
    'ScrollbarOnLeft'
    'ShadowBold'
    'ShadowBoldOffset'
    'StampUtmp'
    'TerminalModes'
    'UTF8Override'
    'WideBoldFont'
    'WideBoldFontCharSet'
    'WideBoldFontHeight'
    'WideBoldFontIsBold'
    'WideFont'
    'WideFontCharSet'
    'WideFontHeight'
    'WideFontIsBold'
    'WindowClass'
    'Wordness0'
    'Wordness32'
    'Wordness64'
    'Wordness96'
    'Wordness128'
    'Wordness160'
    'Wordness192'
    'Wordness224'
)

# PuTTY session
Class PuTTYSession {
    [String]$Name
    [String]$Origin
    [String[]]$Inherits
    [PSCustomObject]$Settings

    PuTTYSession([String]$Name, [String]$Origin) {
        $this.Name = $Name
        $this.Origin = $Origin
        $this.Inherits = @()
        $this.Settings = [PSCustomObject]@{
            '$schema' = $Script:JsonSchemaUri
        }
    }

    [String] ToString() {
        return 'PuTTY Session: {0}' -f $this.Name
    }
}

Function Export-PuTTYSession {
    <#
        .SYNOPSIS
        Exports PuTTY sessions to JSON files or the Windows registry

        .DESCRIPTION
        After importing PuTTY sessions they can be exported to a supported destination using this command.

        The supported destinations are to JSON files or the Windows registry under the PuTTY Sessions key.

        .PARAMETER Session
        PuTTY sessions to operate on as returned by a previous invocation of Import-PuTTYSession.

        .PARAMETER Path
        File system path where exported PuTTY sessions will be saved in JSON format.

        The destination directory must already exist.

        .PARAMETER Registry
        Export PuTTY sessions to the Windows registry as used by PuTTY.

        The PuTTY Sessions key must already exist.

        .PARAMETER Defaults
        The baseline defaults to use for unspecified settings when exporting to the Windows registry.

        The default is the PuTTY v0.77 defaults, however, earlier PuTTY versions are also supported.

        .PARAMETER Force
        Permit overwriting of existing PuTTY sessions.

        .EXAMPLE
        $Sessions | Export-PuTTYSession -Path $HOME\PuTTY

        Exports PuTTY sessions in the $Sessions variable to the $HOME\PuTTY directory.

        .EXAMPLE
        $Sessions | Export-PuTTYSession -Registry -Force

        Exports PuTTY sessions in the $Sessions variable to the PuTTY Sessions key. Matching existing PuTTY sessions will be overwritten.

        .LINK
        https://github.com/ralish/PSPuTTYCfg
    #>

    [CmdletBinding(DefaultParameterSetName = 'Json')]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PuTTYSession]$Session,

        [Parameter(ParameterSetName = 'Json', Mandatory)]
        [String]$Path,

        [Parameter(ParameterSetName = 'Registry', Mandatory)]
        [Switch]$Registry,

        [Parameter(ParameterSetName = 'Registry')]
        [ValidateSet('0.70', '0.71', '0.72', '0.73', '0.74', '0.75', '0.76', '0.77')]
        [String]$Defaults = '0.77',

        [Switch]$Force
    )

    Begin {
        Initialize-PuTTYCfg
        $Sessions = [Collections.ArrayList]::new()
    }

    Process {
        $null = $Sessions.Add($Session)
    }

    End {
        switch ($PSCmdlet.ParameterSetName) {
            'Json' { Export-PuTTYSessionToJson -Session $Sessions -Path $Path -Force:$Force }
            'Registry' { Export-PuTTYSessionToRegistry -Session $Sessions -Defaults $Defaults -Force:$Force }
            Default { throw ('Unknown provider: {0}' -f $PSCmdlet.ParameterSetName) }
        }
    }
}

Function Import-PuTTYSession {
    <#
        .SYNOPSIS
        Imports PuTTY sessions from JSON files or the Windows registry

        .DESCRIPTION
        After importing PuTTY sessions using this command they can be exported to a supported destination.

        The supported sources are from JSON files or the Windows registry under the PuTTY Sessions key.

        .PARAMETER Path
        File system path where PuTTY sessions saved in JSON format will be imported.

        .PARAMETER Recurse
        Recurse into subdirectories under the provided file system path during import.

        .PARAMETER Registry
        Import PuTTY sessions from the Windows registry as used by PuTTY.

        .PARAMETER ExcludeDefault
        Exclude settings which match PuTTY's defaults when importing (i.e. only import customised settings).

        Currently this switch only supports using the defaults from PuTTY v0.77.

        .PARAMETER Filter
        Only import sessions where the session name matches the provided glob pattern.

        .EXAMPLE
        $Sessions = Import-PuTTYSession -Path $HOME\PuTTY

        Imports PuTTY sessions stored as JSON files in the $HOME\PuTTY directory.

        .EXAMPLE
        $Sessions = Import-PuTTYSession -Registry -Filter 'Personal*'

        Imports PuTTY sessions from the PuTTY Sessions key matching the glob pattern "Personal*".

        .LINK
        https://github.com/ralish/PSPuTTYCfg
    #>

    [CmdletBinding(DefaultParameterSetName = 'Json')]
    Param(
        [Parameter(ParameterSetName = 'Json', Mandatory)]
        [String]$Path,

        [Parameter(ParameterSetName = 'Json')]
        [Switch]$Recurse,

        [Parameter(ParameterSetName = 'Registry', Mandatory)]
        [Switch]$Registry,

        [Parameter(ParameterSetName = 'Registry')]
        [Switch]$ExcludeDefault,

        [String]$Filter
    )

    Begin {
        Initialize-PuTTYCfg

        $ImportParams = @{}
        if ($Filter) {
            $ImportParams['Filter'] = $Filter
        }
    }

    Process {
        switch ($PSCmdlet.ParameterSetName) {
            'Json' { Import-PuTTYSessionFromJson -Path $Path -Recurse:$Recurse @ImportParams }
            'Registry' { Import-PuTTYSessionFromRegistry -ExcludeDefault:$ExcludeDefault @ImportParams }
            Default { throw ('Unknown provider: {0}' -f $PSCmdlet.ParameterSetName) }
        }
    }
}

Function Initialize-PuTTYCfg {
    [CmdletBinding()]
    Param()

    if ($Initialized) {
        return
    }

    Write-Debug -Message 'Loading configuration data ...'
    $Path = Join-Path -Path $PSScriptRoot -ChildPath 'PSPuTTYCfg.jsonc'
    $Content = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
    $Data = $Content | ConvertFrom-Json -NoEnumerate -ErrorAction Stop
    Write-Debug -Message ('Loaded {0} PuTTY settings.' -f $Data.settings.Count)

    Write-Debug -Message 'Building JSON to Registry setting hashtable ...'
    $JsonSettings = @{}
    foreach ($Setting in $Data.settings) {
        $SettingKey = '{0}/{1}' -f $Setting.json.path, $Setting.json.name
        $JsonSettings[$SettingKey] = $Setting
    }
    $Script:CfgData.Json = $JsonSettings

    Write-Debug -Message 'Building Registry to JSON setting hashtable ...'
    $RegistrySettings = @{}
    foreach ($Setting in $Data.settings) {
        $SettingKey = $Setting.reg.name
        $RegistrySettings[$SettingKey] = $Setting
    }
    $Script:CfgData.Registry = $RegistrySettings

    $Script:Initialized = $true
}

#region .NET sessions

Function Add-PuTTYSetting {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [PuTTYSession]$Session,

        [Parameter(Mandatory)]
        [PSCustomObject]$SettingData,

        [Parameter(Mandatory)]
        [Object]$Value,

        [Switch]$Force
    )

    $Settings = $Session.Settings
    $SettingName = $SettingData.json.name
    $SettingPath = $SettingData.json.path
    $CurrentPath = [String]::Empty

    foreach ($PathElement in $SettingPath.TrimStart('/').Split('/')) {
        $CurrentPath = '{0}/{1}' -f $CurrentPath, $PathElement

        if ($Settings.PSObject.Properties[$PathElement]) {
            $PathProperty = $Settings.$PathElement

            if ($PathProperty -isnot [PSCustomObject]) {
                throw ('[{0}] Unexpected type at path "{1}" of settings object: {2}' -f $Session.Name, $CurrentPath, $PathProperty.GetType().Name)
            }
        } else {
            $Settings | Add-Member -NotePropertyName $PathElement -NotePropertyValue ([PSCustomObject]@{})
        }

        $Settings = $Settings.$PathElement
    }

    $Settings | Add-Member -NotePropertyName $SettingName -NotePropertyValue $Value -Force:$Force
}

Function Merge-PuTTYSettings {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [PuTTYSession]$Session,

        [Parameter(Mandatory)]
        [PSCustomObject]$Settings,

        [String]$CurrentPath = '/'
    )

    foreach ($Property in $Settings.PSObject.Properties) {
        if ($Property.MemberType -ne 'NoteProperty') {
            throw ('[{0}] Unexpected member type at path "{1}" of settings object: {2}' -f $Session.Name, $CurrentPath, $Property.MemberType)
        }

        $SettingName = $Property.Name
        if ($CurrentPath -eq '/' -and $SettingName -eq '$schema') {
            continue
        }

        $Setting = $Settings.$SettingName
        $SettingType = $Setting.GetType().Name

        if ($CurrentPath.EndsWith('/')) {
            $SettingPath = '{0}{1}' -f $CurrentPath, $SettingName
        } else {
            $SettingPath = '{0}/{1}' -f $CurrentPath, $SettingName
        }

        if ($SettingType -eq 'PSCustomObject') {
            Merge-PuTTYSettings -Session $Session -Settings $Setting -CurrentPath $SettingPath
            continue
        }

        if (!$CfgData.Json.ContainsKey($SettingPath)) {
            Write-Warning -Message ('[{0}] Ignoring unknown JSON setting: {1}' -f $Session.Name, $SettingPath)
            continue
        }

        $SettingData = $CfgData.Json[$SettingPath]
        Add-PuTTYSetting -Session $Session -SettingData $SettingData -Value $Setting -Force
    }
}

#endregion

#region JSON sessions

Function Add-PuTTYSessionJsonInherit {
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory)]
        [PuTTYSession]$Session,

        [Parameter(Mandatory)]
        [String]$InheritedSessionName,

        [Collections.ArrayList]$ProcessedSessions = [Collections.ArrayList]::new()
    )

    Write-Debug -Message ('[{0}] Processing inherited JSON session: {1}' -f $Session.Name, $InheritedSessionName)

    if ($Session.Name -eq $InheritedSessionName -or $ProcessedSessions -contains $InheritedSessionName) {
        throw ('Circular inheritance detected processing inherited session "{0}" specified by session: {1}' -f $InheritedSessionName, $Session.Name)
    }

    $InheritedSessionPath = Join-Path -Path (Split-Path -Path $Session.Origin -Parent) -ChildPath ('{0}.json' -f $InheritedSessionName)
    try {
        $InheritedJsonContent = Get-Content -LiteralPath $InheritedSessionPath -Raw -ErrorAction Stop
        $InheritedJsonSettings = $InheritedJsonContent | ConvertFrom-Json -NoEnumerate -ErrorAction Stop
    } catch {
        Write-Warning -Message ('Failed to load inherited session "{0}" specified by session: {1}' -f $InheritedSessionName, $Session.Name)
        throw $_
    }

    $null = $ProcessedSessions.Add($InheritedSessionName)

    if ($InheritedJsonSettings.PSObject.Properties['inherits']) {
        $InheritedJsonSessions = $InheritedJsonSettings.inherits

        foreach ($InheritedJsonSession in $InheritedJsonSessions) {
            Add-PuTTYSessionJsonInherit -Session $Session -InheritedSessionName $InheritedJsonSession -ProcessedSessions $ProcessedSessions
        }

        $InheritedJsonSettings.PSObject.Properties.Remove('inherits')
    }

    Merge-PuTTYSettings -Session $Session -Settings $InheritedJsonSettings
}

Function Convert-PuTTYSessionJsonToDotNet {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [IO.FileInfo[]]$JsonSession
    )

    Begin {
        $DotNetSessions = [Collections.ArrayList]::new()

        $WriteProgressParams = @{
            Activity = 'Importing PuTTY sessions'
        }
    }

    Process {
        for ($Index = 0; $Index -lt $JsonSession.Count; $Index++) {
            $CurrentSession = $JsonSession[$Index]
            $SessionName = $CurrentSession.BaseName
            $SessionPath = $CurrentSession.FullName

            $WriteProgressParams['Status'] = 'Importing from JSON: {0}' -f $SessionName
            $WriteProgressParams['PercentComplete'] = $Index / $JsonSession.Count * 100
            Write-Progress @WriteProgressParams

            try {
                $JsonContent = Get-Content -LiteralPath $SessionPath -Raw -ErrorAction Stop
                $JsonSettings = $JsonContent | ConvertFrom-Json -NoEnumerate -ErrorAction Stop
            } catch {
                Write-Error -Message $_
                continue
            }

            $DotNetSession = [PuTTYSession]::new($SessionName, $SessionPath)

            if ($JsonSettings.PSObject.Properties['inherits']) {
                $DotNetSession.Inherits = $JsonSettings.inherits
                $JsonSettings.PSObject.Properties.Remove('inherits')

                foreach ($InheritedJsonSession in $DotNetSession.Inherits) {
                    Add-PuTTYSessionJsonInherit -Session $DotNetSession -InheritedSessionName $InheritedJsonSession
                }
            }

            Merge-PuTTYSettings -Session $DotNetSession -Settings $JsonSettings
            $null = $DotNetSessions.Add($DotNetSession)
        }
    }

    End {
        Write-Progress @WriteProgressParams -Completed
        return $DotNetSessions
    }
}

Function Export-PuTTYSessionToJson {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [PuTTYSession[]]$Session,

        [Parameter(Mandatory)]
        [String]$Path,

        [Switch]$Force
    )

    Begin {
        try {
            $SessionDir = Get-Item -Path $Path -Force -ErrorAction Stop
        } catch {
            throw $_
        }

        if ($SessionDir -isnot [IO.DirectoryInfo]) {
            throw ('Expected a directory path but received: {0}' -f $SessionDir.GetType().Name)
        }

        $OutFileParams = @{
            ErrorAction = 'Stop'
        }

        if (!$Force) {
            $OutFileParams['NoClobber'] = $true
        }

        $WriteProgressParams = @{
            Activity = 'Exporting PuTTY sessions'
        }
    }

    Process {
        for ($Index = 0; $Index -lt $Session.Count; $Index++) {
            $CurrentSession = $Session[$Index]
            $SessionName = $CurrentSession.Name

            $WriteProgressParams['Status'] = 'Exporting to JSON: {0}' -f $SessionName
            $WriteProgressParams['PercentComplete'] = $Index / $Session.Count * 100
            Write-Progress @WriteProgressParams

            $SessionFile = '{0}.json' -f $SessionName
            $SessionPath = Join-Path -Path $SessionDir.FullName -ChildPath $SessionFile
            $CurrentSession.Settings | ConvertTo-Json -Depth 10 -ErrorAction Stop | Out-File -LiteralPath $SessionPath @OutFileParams
        }
    }

    End {
        Write-Progress @WriteProgressParams -Completed
    }
}

Function Import-PuTTYSessionFromJson {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]$Path,

        [String]$Filter,
        [Switch]$Recurse
    )

    try {
        $SessionPath = Get-Item -Path $Path -Force -ErrorAction Stop
    } catch {
        throw $_
    }

    if ($SessionPath -is [IO.FileInfo]) {
        if ($SessionPath.Extension -In $JsonValidExts) {
            $JsonSessions = @($SessionPath)
        } else {
            throw ('Provided path is not a JSON file: {0}' -f $Path)
        }
    } elseif ($SessionPath -is [IO.DirectoryInfo]) {
        Write-Debug -Message ('Enumerating JSON sessions at path: {0}' -f $Path)
        $JsonSessions = Get-ChildItem -Path $Path -File -Recurse:$Recurse | Where-Object Extension -In $JsonValidExts

        if ($JsonSessions.Count -eq 0) {
            throw ('No JSON sessions found at path: {0}' -f $Path)
        }
    } else {
        throw ('Expected a filesystem path but received: {0}' -f $SessionPath.GetType().Name)
    }

    if ($Filter) {
        Write-Debug -Message 'Applying sessions filter ...'
        $JsonSessions = @($JsonSessions | Where-Object BaseName -Like $Filter)

        if ($JsonSessions.Count -eq 0) {
            Write-Error -Message ('No JSON sessions match filter: {0}' -f $Filter)
        }
    }

    Write-Debug -Message 'Converting JSON sessions to .NET objects ...'
    $DotNetSessions = Convert-PuTTYSessionJsonToDotNet -JsonSession $JsonSessions

    return $DotNetSessions
}

#endregion

#region Registry sessions

Function Convert-PuTTYSessionRegistryToDotNet {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [Microsoft.Win32.RegistryKey[]]$RegSession,

        [Switch]$ExcludeDefault
    )

    Begin {
        $DotNetSessions = [Collections.ArrayList]::new()

        $WriteProgressParams = @{
            Activity = 'Importing PuTTY sessions'
        }
    }

    Process {
        for ($Index = 0; $Index -lt $RegSession.Count; $Index++) {
            $CurrentSession = $RegSession[$Index]
            $SessionName = ConvertFrom-PuTTYEscapedRegistrySessionKey -SessionName $CurrentSession.PSChildName

            $WriteProgressParams['Status'] = 'Importing from registry: {0}' -f $SessionName
            $WriteProgressParams['PercentComplete'] = $Index / $RegSession.Count * 100
            Write-Progress @WriteProgressParams

            $RegSettings = $CurrentSession.GetValueNames()
            if ($RegSettings.Count -eq 0) {
                Write-Warning -Message ('[{0}] Skipping registry session with no settings.' -f $SessionName)
                continue
            }

            $DotNetSession = [PuTTYSession]::new($SessionName, $CurrentSession.Name.Replace('HKEY_CURRENT_USER\', 'HKCU:\'))

            foreach ($RegSetting in ($CurrentSession.GetValueNames() | Sort-Object)) {
                if ($CfgData.Registry.ContainsKey($RegSetting)) {
                    $SettingData = $CfgData.Registry[$RegSetting]
                } else {
                    if ($RegSetting -notin $RegIgnoredSettings) {
                        Write-Warning -Message ('[{0}] Ignoring unknown registry setting: {1}' -f $SessionName, $RegSetting)
                    }
                    continue
                }

                $DotNetSettingValue = Convert-PuTTYSettingRegistryToDotNet -RegSession $CurrentSession -SettingData $SettingData -ExcludeDefault:$ExcludeDefault
                if ($null -ne $DotNetSettingValue) {
                    Add-PuTTYSetting -Session $DotNetSession -SettingData $SettingData -Value $DotNetSettingValue
                }
            }

            # The default .NET types used for values retrieved from the registry can differ from those
            # used for deserialized JSON (e.g. Int32 for registry DWord versus Int64 for JSON integer).
            # Perform a roundtrip (de)serialisation to JSON to ensure consistency among all .NET types.
            $JsonSettings = $DotNetSession.Settings | ConvertTo-Json -Depth 10 -ErrorAction Stop
            $DotNetSession.Settings = $JsonSettings | ConvertFrom-Json -NoEnumerate -ErrorAction Stop

            $null = $DotNetSessions.Add($DotNetSession)
        }
    }

    End {
        Write-Progress @WriteProgressParams -Completed
        return $DotNetSessions
    }
}

Function Convert-PuTTYSettingRegistryToDotNet {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [Microsoft.Win32.RegistryKey]$RegSession,

        [Parameter(Mandatory)]
        [PSCustomObject]$SettingData,

        [Switch]$ExcludeDefault
    )

    $SessionName = ConvertFrom-PuTTYEscapedRegistrySessionKey -SessionName $RegSession.PSChildName

    $RegSettingName = $SettingData.reg.name
    $RegSettingType = $RegSession.GetValueKind($RegSettingName)
    if ($RegSettingType -ne $SettingData.reg.type) {
        Write-Error -Message ('[{0}] Registry setting {1} has type "{2}" but expected: "{3}"' -f $SessionName, $RegSettingName, $RegSettingType, $SettingData.reg.type)
        return
    }

    $RegSettingValue = $RegSession.GetValue($RegSettingName)
    if ($ExcludeDefault -and $RegSettingValue -eq $SettingData.reg.default) {
        return
    }

    $JsonSettingType = $SettingData.json.type
    $SettingIsEnumType = $SettingData.PSObject.Properties.Name -contains 'enum'

    switch ($RegSettingType) {
        'DWord' {
            switch ($JsonSettingType) {
                'integer' {
                    if (!$SettingIsEnumType) { return $RegSettingValue }

                    $EnumName = Find-EnumName -Enum $SettingData.enum -Value $RegSettingValue
                    if ($EnumName) { return [int]$EnumName }
                    Write-Error -Message ('[{0}] Registry setting {1} has unknown enumeration value: {2}' -f $SessionName, $RegSettingName, $RegSettingValue)
                }

                'boolean' {
                    if ($RegSettingValue -eq 0 -or $RegSettingValue -eq 1) { return [bool]$RegSettingValue }
                    Write-Error -Message ('[{0}] Registry setting {1} has invalid value for boolean type: {2}' -f $SessionName, $RegSettingName, $RegSettingValue)
                }

                'string' {
                    $EnumName = Find-EnumName -Enum $SettingData.enum -Value $RegSettingValue
                    if ($EnumName) { return $EnumName }
                    Write-Error -Message ('[{0}] Registry setting {1} has unknown enumeration value: {2}' -f $SessionName, $RegSettingName, $RegSettingValue)
                }

                Default { throw ('Unexpected JSON type: {0}' -f $JsonSettingType) }
            }
        }

        'String' {
            switch ($JsonSettingType) {
                'array' {
                    if ($RegSettingValue -ne [String]::Empty) {
                        return , $RegSettingValue.Split(',')
                    }
                    return , @()
                }

                'string' {
                    if (!$SettingIsEnumType) { return $RegSettingValue }

                    $EnumName = Find-EnumName -Enum $SettingData.enum -Value $RegSettingValue
                    if ($EnumName) { return $EnumName }
                    Write-Error -Message ('[{0}] Registry setting {1} has unknown enumeration value: {2}' -f $SessionName, $RegSettingName, $RegSettingValue)
                }

                Default { throw ('Unexpected JSON type: {0}' -f $JsonSettingType) }
            }
        }

        Default { throw ('Unexpected registry type: {0}' -f $RegSettingType) }
    }

    return $null
}

Function Convert-PuTTYSettingsDotNetToRegistry {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [PuTTYSession]$Session,

        [Parameter(Mandatory)]
        [Hashtable]$RegSettings,

        [PSCustomObject]$Settings,
        [String]$CurrentPath = '/'
    )

    if (!$Settings) {
        $Settings = $Session.Settings
    }

    foreach ($Property in $Settings.PSObject.Properties) {
        if ($Property.MemberType -ne 'NoteProperty') {
            throw ('[{0}] Unexpected member type at path "{1}" of settings object: {2}' -f $Session.Name, $CurrentPath, $Property.MemberType)
        }

        $SettingName = $Property.Name
        if ($CurrentPath -eq '/' -and $SettingName -eq '$schema') {
            continue
        }

        $Setting = $Settings.$SettingName
        $SettingType = $Setting.GetType().Name

        if ($CurrentPath.EndsWith('/')) {
            $SettingPath = '{0}{1}' -f $CurrentPath, $SettingName
        } else {
            $SettingPath = '{0}/{1}' -f $CurrentPath, $SettingName
        }

        if ($SettingType -eq 'PSCustomObject') {
            Convert-PuTTYSettingsDotNetToRegistry -Session $Session -RegSettings $RegSettings -Settings $Setting -CurrentPath $SettingPath
            continue
        }

        if (!$CfgData.Json.ContainsKey($SettingPath)) {
            Write-Warning -Message ('[{0}] Ignoring unknown JSON setting: {1}' -f $Session.Name, $SettingPath)
            continue
        }

        $SettingData = $CfgData.Json[$SettingPath]

        if ($SettingType -eq 'Object[]') {
            $RegSettings[$SettingData.reg.name] = [String]::Join(',', $Setting)
            continue
        }

        if ($SettingData.PSObject.Properties.Name -contains 'enum') {
            $Setting = $SettingData.enum.$Setting
        }

        $RegSettings[$SettingData.reg.name] = $Setting
    }
}

Function Export-PuTTYSessionToRegistry {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [PuTTYSession[]]$Session,

        [Parameter(Mandatory)]
        [String]$Defaults,

        [Switch]$Force
    )

    Begin {
        try {
            Write-Verbose -Message ('Loading defaults from PuTTY v{0} ...' -f $Defaults)
            $DefaultsPath = Join-Path -Path $PSScriptRoot -ChildPath ('defaults\Default Settings - v{0}.json' -f $Defaults)
            $DefaultsFile = Get-Item -Path $DefaultsPath -ErrorAction Stop
            $DefaultSettings = Import-PuTTYSession -Path $DefaultsFile -Verbose:$false

            if (!(Test-Path -Path $RegSessionsPath -PathType Container)) {
                Write-Debug -Message ('Creating saved sessions registry key: {0}' -f $RegSessionsPath)
                $null = New-Item -Path $RegSessionsPath -Force -ErrorAction Stop
            }
        } catch {
            throw $_
        }

        $WriteProgressParams = @{
            Activity = 'Exporting PuTTY sessions'
        }
    }

    Process {
        for ($Index = 0; $Index -lt $Session.Count; $Index++) {
            $CurrentSession = $Session[$Index]
            $SessionName = $CurrentSession.Name

            $WriteProgressParams['Status'] = 'Exporting to registry: {0}' -f $SessionName
            $WriteProgressParams['PercentComplete'] = $Index / $Session.Count * 100
            Write-Progress @WriteProgressParams

            $RegSession = [PuTTYSession]::new($SessionName, $CurrentSession.Origin)
            Merge-PuTTYSettings -Session $RegSession -Settings $DefaultSettings.Settings
            Merge-PuTTYSettings -Session $RegSession -Settings $CurrentSession.Settings

            $RegSettings = @{}
            Convert-PuTTYSettingsDotNetToRegistry -Session $RegSession -RegSettings $RegSettings

            Set-PuTTYSessionRegistry -Session $RegSession -RegSettings $RegSettings
        }
    }

    End {
        Write-Progress @WriteProgressParams -Completed
    }
}

Function Import-PuTTYSessionFromRegistry {
    [CmdletBinding()]
    Param(
        [Switch]$ExcludeDefault,
        [String]$Filter
    )

    Write-Debug -Message 'Enumerating registry sessions ...'
    try {
        $RegSessions = Get-ChildItem -Path $RegSessionsPath -ErrorAction Stop
    } catch [Management.Automation.ItemNotFoundException] {
        Write-Error -Message ('Saved sessions registry key does not exist: {0}' -f $RegSessionsPath)
        return
    }

    if ($RegSessions.Count -eq 0) {
        Write-Warning -Message 'No saved sessions found in the registry.'
        return
    }

    if ($Filter) {
        Write-Debug -Message 'Applying sessions filter ...'
        $RegSessions = @($RegSessions | Where-Object PSChildName -Like $Filter)

        if ($RegSessions.Count -eq 0) {
            Write-Error -Message ('No registry sessions match filter: {0}' -f $Filter)
            return
        }
    }

    Write-Debug -Message 'Converting registry sessions to .NET objects ...'
    $DotNetSessions = Convert-PuTTYSessionRegistryToDotNet -RegSession $RegSessions -ExcludeDefault:$ExcludeDefault

    return $DotNetSessions
}

Function Set-PuTTYSessionRegistry {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [PuTTYSession]$Session,

        [Parameter(Mandatory)]
        [Hashtable]$RegSettings
    )

    $RegSessionName = ConvertTo-PuTTYEscapedRegistrySessionKey -SessionName $Session.Name
    $RegSessionPath = Join-Path -Path $RegSessionsPath -ChildPath $RegSessionName

    try {
        $null = Get-Item -Path $RegSessionPath -ErrorAction Stop
        if (!$Force) {
            Write-Warning -Message ('Skipping existing registry session: {0}' -f $Session.Name)
            return
        }
    } catch [Management.Automation.ItemNotFoundException] {
        $null = New-Item -Path $RegSessionsPath -Name $RegSessionName
    }

    foreach ($RegSettingName in $RegSettings.Keys) {
        $RegSettingType = $CfgData.Registry[$RegSettingName].reg.type
        $RegSettingValue = $RegSettings[$RegSettingName]
        Set-ItemProperty -Path $RegSessionPath -Name $RegSettingName -Type $RegSettingType -Value $RegSettingValue
    }
}

#endregion

#region Utilities

# PowerShell implementation to match PuTTY internal method:
# void unescape_registry_key(const char *in, strbuf *out)
Function ConvertFrom-PuTTYEscapedRegistrySessionKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]$SessionName
    )

    $Result = [Text.StringBuilder]::new($SessionName.Length)

    for ($Index = 0; $Index -lt $SessionName.Length) {
        if ($SessionName[$Index] -ne '%') {
            $null = $Result.Append($SessionName[$Index++])
            continue
        }

        $null = $Result.Append([Char][Convert]::ToByte($SessionName.Substring(++$Index, 2), 16))
        $Index += 2
    }

    return $Result.ToString()
}

# PowerShell implementation to match PuTTY internal method:
# void escape_registry_key(const char *in, strbuf *out)
Function ConvertTo-PuTTYEscapedRegistrySessionKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]$SessionName
    )

    $Result = [Text.StringBuilder]::new($SessionName.Length, 1024)

    $FirstChar = $true
    foreach ($Char in $SessionName.ToCharArray()) {
        if ($Char -le ' ' -or $Char -eq '%' -or $Char -eq '*' -or $Char -eq '?' -or $Char -eq '\' -or $Char -gt '~' -or ($Char -eq '.' -and $FirstChar)) {
            $null = $Result.Append('%')
            $null = $Result.Append('{0:X2}' -f [System.Text.Encoding]::ASCII.GetBytes($Char)[0])
        } else {
            $null = $Result.Append($Char)
        }
        $FirstChar = $false
    }

    return $Result.ToString()
}

Function Find-EnumName {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Enum,

        [Parameter(Mandatory)]
        [Object]$Value
    )

    foreach ($Name in $Enum.PSObject.Properties.Name) {
        if ($Enum.$Name -eq $Value) {
            return $Name
        }
    }
}

#endregion
