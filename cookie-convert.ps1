param(
    [Parameter(Mandatory = $true)]
    [string]$Source,

    [Parameter(Mandatory = $true)]
    [string]$Target
)

$ErrorActionPreference = "Stop"

function Resolve-LiteralPathSafe {
    param([string]$PathValue)

    try {
        return (Resolve-Path -LiteralPath $PathValue).Path
    } catch {
        return $null
    }
}

function Get-FirstContentLine {
    param([string]$Text)

    foreach ($line in ($Text -split "`r?`n")) {
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            return $line.Trim()
        }
    }

    return ""
}

function Get-CookieCollection {
    param([object]$ParsedData)

    if ($null -eq $ParsedData) {
        return @()
    }

    if ($ParsedData.PSObject.Properties.Name -contains "cookies") {
        return @($ParsedData.cookies)
    }

    if ($ParsedData.PSObject.Properties.Name -contains "data") {
        return @($ParsedData.data)
    }

    if ($ParsedData -is [System.Collections.IEnumerable] -and -not ($ParsedData -is [string])) {
        return @($ParsedData)
    }

    return @($ParsedData)
}

function Get-ExpiryValue {
    param([object]$Cookie)

    foreach ($propertyName in @("expirationDate", "expires", "expiration")) {
        if ($Cookie.PSObject.Properties.Name -contains $propertyName) {
            $rawValue = $Cookie.$propertyName

            if ($null -eq $rawValue -or [string]::IsNullOrWhiteSpace([string]$rawValue)) {
                continue
            }

            try {
                return [int64][math]::Floor([double]$rawValue)
            } catch {
                continue
            }
        }
    }

    return 0
}

function Write-NetscapeCookieFile {
    param(
        [object[]]$Cookies,
        [string]$OutputPath
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# Netscape HTTP Cookie File")
    $lines.Add("# Converted for yt-dlp local account mode")
    $lines.Add("")

    $writtenCount = 0

    foreach ($cookie in $Cookies) {
        if ($null -eq $cookie) {
            continue
        }

        $domain = ""
        if ($cookie.PSObject.Properties.Name -contains "domain") {
            $domain = [string]$cookie.domain
        } elseif ($cookie.PSObject.Properties.Name -contains "host") {
            $domain = [string]$cookie.host
        }

        if ([string]::IsNullOrWhiteSpace($domain)) {
            continue
        }

        $name = ""
        if ($cookie.PSObject.Properties.Name -contains "name") {
            $name = [string]$cookie.name
        }

        if ([string]::IsNullOrWhiteSpace($name)) {
            continue
        }

        $value = ""
        if ($cookie.PSObject.Properties.Name -contains "value" -and $null -ne $cookie.value) {
            $value = [string]$cookie.value
        }

        $path = "/"
        if ($cookie.PSObject.Properties.Name -contains "path" -and -not [string]::IsNullOrWhiteSpace([string]$cookie.path)) {
            $path = [string]$cookie.path
        }

        $secure = "FALSE"
        if ($cookie.PSObject.Properties.Name -contains "secure" -and [bool]$cookie.secure) {
            $secure = "TRUE"
        }

        $hostOnly = $false
        if ($cookie.PSObject.Properties.Name -contains "hostOnly") {
            $hostOnly = [bool]$cookie.hostOnly
        }

        $includeSubdomains = "TRUE"
        if ($hostOnly -and -not $domain.StartsWith(".")) {
            $includeSubdomains = "FALSE"
        }

        $expiry = Get-ExpiryValue -Cookie $cookie
        $lines.Add("$domain`t$includeSubdomains`t$path`t$secure`t$expiry`t$name`t$value")
        $writtenCount++
    }

    if ($writtenCount -eq 0) {
        exit 5
    }

    $targetDirectory = Split-Path -Parent $OutputPath
    if (-not [string]::IsNullOrWhiteSpace($targetDirectory) -and -not (Test-Path -LiteralPath $targetDirectory)) {
        New-Item -ItemType Directory -Path $targetDirectory | Out-Null
    }

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($OutputPath, $lines, $encoding)
}

$sourcePath = Resolve-LiteralPathSafe -PathValue $Source
if (-not $sourcePath) {
    exit 2
}

$targetPath = [System.IO.Path]::GetFullPath($Target)
$rawText = Get-Content -LiteralPath $sourcePath -Raw
$trimmedText = $rawText.TrimStart()

if ([string]::IsNullOrWhiteSpace($trimmedText)) {
    exit 3
}

if ($trimmedText.StartsWith("[") -or $trimmedText.StartsWith("{")) {
    try {
        $parsedData = $rawText | ConvertFrom-Json -ErrorAction Stop
    } catch {
        exit 4
    }

    $cookieCollection = Get-CookieCollection -ParsedData $parsedData
    Write-NetscapeCookieFile -Cookies $cookieCollection -OutputPath $targetPath
    exit 0
}

$firstContentLine = Get-FirstContentLine -Text $rawText
if ($firstContentLine.StartsWith("#") -or $firstContentLine -match "^[^`t]+`t(TRUE|FALSE)`t") {
    if ($sourcePath -ieq $targetPath) {
        exit 0
    }

    Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force
    exit 0
}

exit 6
