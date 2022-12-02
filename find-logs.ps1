param ($Env, $Destination, $Keyword)

function IsFileOfInterest {
    param (
        [string] $file
    )

    return $file -match '^(connector_prorail.log|export.log|connector_prorail_calculator)'
}

function HasKeyword {
    param (
        [string] $file,
        [string] $keyword
    )

    return Select-String -Path $file -Pattern $keyword -SimpleMatch -Quiet
}

function Get-Sources {
    param (
        [string] $env
    )

    switch($env) {
        'acc-dev' {
            return 'puhaaps0320', 'puhaaps0323'
        }

        'acc-sla' {
            return 'puhaaps0312', 'puhaaps0314'
        }

        'opl' {
            return 'puhaaps0316', 'puhaaps0317'
        }

        'prd' {
            return 'puhaps0444', 'puhaps0445'
        }
    }

    return 'sw-iis-dev.geodan.nl', 'sw-iis-dev-wc.geodan.nl'
}

function Copy-Logs {
    param (
        [string] $path,
        [string] $keyword,
        [string] $destination
    )

    New-Item -Path $destination -ItemType Directory -Force

    foreach($item in Get-ChildItem $path) {
        if (IsFileOfInterest($item)) {
            Write-Host "Scanning $item ...       `r" -NoNewline
            if (HasKeyword -file $path$item -keyword $keyword) {
                Copy-Item -Path $path$item -Destination $destination
                Write-Host "File copied: $item                   "
            }
        }
    }
    Write-Host "                                                                   "
}

function Extract-Logs {
    param (
        [string] $env,
        [string] $keyword,
        [string] $destination
    )

    foreach($machine in Get-Sources $env) {
        $folder = if ($machine -match '(geodan|spoorweb)') { 'c$\ProgramData\spoorweb' } else { 'spoorweblogs' }
        $src = "\\$machine\$folder\"
        $outDest = ($destination + "\" + $env + "\" + $machine)
        Copy-Logs -path $src -destination $outDest -keyword $keyword
    }
    
}

# When having problem with signing:
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass 

Extract-Logs -env $Env -keyword $Keyword -destination $Destination
