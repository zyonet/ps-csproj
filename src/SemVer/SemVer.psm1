
if (-not ([System.Management.Automation.PSTypeName]'VersionComponent').Type) {
Add-Type -TypeDefinition @"
   public enum VersionComponent
   {
      Major = 0,
      Minor = 1,
      Patch = 2,
      Build = 3,
      Suffix = 4,
      SuffixBuild = 5,
      SuffixRevision = 6
   }
"@
}


<#

.SYNOPSIS
Updates given component of a SemVer string

.DESCRIPTION 

.PARAMETER ver 
SemVer string 

.EXAMPLE 
Update-Version "1.0.1" Patch 
1.0.2
Increment Patch component of version 1.0.1

.NOTES
#>
function Update-Version {
    param(
        [Parameter(mandatory=$true)]$ver, 
        [VersionComponent]$component = [VersionComponent]::Patch, 
        $value = $null
        ) 
    
    $null = $ver -match "(?<version>[0-9]+(\.[0-9]+)*)(-(?<suffix>.*)){0,1}"
    $version = $matches["version"]
    $suffix = $matches["suffix"]
    
    $vernums = $version.Split(@('.'))
    $lastNumIdx = $component
    if ($component -lt [VersionComponent]::Suffix) {
        $lastNum = [int]::Parse($vernums[$lastNumIdx])
        
        <# for($i = $vernums.Count-1; $i -ge 0; $i--) {
            if ([int]::TryParse($vernums[$i], [ref] $lastNum)) {
                $lastNumIdx = $i
                break
            }
        }#>
        if ($value -ne $null) {
            $lastNum = $value
        }
        else {
            $lastNum++
        }
        $vernums[$component] = $lastNum.ToString()
        #each lesser component should be set to 0 
        for($i = $component + 1; $i -lt $vernums.length; $i++) {
            $vernums[$i] = 0
        }
    } else {
        if ([string]::IsNullOrEmpty($suffix)) {
            #throw "version '$ver' has no suffix"
            $suffix = "build000"
        }
        
        if ($component -eq [VersionComponent]::SuffixBuild) {
            if ($suffix -match "build([0-9]+)") {
                $num = [int]$matches[1]
                if ($value -ne $null) {
                    $num = $value
                }
                else {
                    $num++
                }
                $suffix = $suffix -replace "build[0-9]+","build$($num.ToString("000"))"
            }
            else {
                throw "suffix '$suffix' does not match build[0-9] pattern"
            }
        }
        if ($component -eq [VersionComponent]::SuffixRevision) {
            if ($suffix -match "build([0-9]+)-(?<rev>[a-fA-F0-9]+)(-|$)") {
                $rev = $Matches["rev"]
                $suffix = $suffix -replace "$rev",$value
            }
            else {
                $suffix = $suffix + "-$value"
            }
        }
    }
    
    $ver2 = [string]::Join(".", $vernums)
    if (![string]::IsNullOrEmpty($suffix)) {
        $ver2 += "-$suffix"
    }

    return $ver2
}

# Export-ModuleMember -Function * -Alias *