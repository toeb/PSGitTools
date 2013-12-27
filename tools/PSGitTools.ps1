#returns the last version by analysing existing tags, 
#assumes an initial tag is present
# assumes tags are named v{major}.{minor}.[{revision}]
function Get-LastVersion(){
$lastTagCommit = git rev-list --tags --max-count=1
$lastTag = git describe --tags $lastTagCommit
$tagPrefix = "v"
$versionString = $lastTag -replace "$tagPrefix", ""
write-host -NoNewline "last tagged commit "
write-host -NoNewline -ForegroundColor "yellow" $lastTag
write-host -NoNewline " revision "
write-host -ForegroundColor "yellow" "$lastTagCommit"
[reflection.assembly]::LoadWithPartialName("System.Version")

$version = New-Object System.Version($versionString)
return $version;

}

# returns current revision by counting the nummer of commits to HEAD
function Get-Revision(){
$lastTagCommit = git rev-list HEAD
 $revs  = git rev-list $lastTagCommit |  Measure-Object -Line 
 return $revs.Lines
}
#returns the next major version {major}.{minor}.{revision}
function Get-NextMajorVersion(){
    $version = Get-LastVersion;
    [reflection.assembly]::LoadWithPartialName("System.Version")
    [int] $major = $version.Major+1;
    $rev = Get-Revision
    $nextMajor = New-Object System.Version($major, 0,$rev);
    return $nextMajor;
}

#returns the next minor version {major}.{minor}.{revision}
function Get-NextMinorVersion(){
    $version = Get-LastVersion;
    [reflection.assembly]::LoadWithPartialName("System.Version")
    [int] $minor= $version.Minor+1;
    $rev = Get-Revision
    $next= New-Object System.Version($version.Major, $minor, $rev);
    return $next;
}

#returns the last minor version with an up to date revision number
function Get-CurrentVersion(){
    $version = Get-LastVersion;
    [reflection.assembly]::LoadWithPartialName("System.Version")
    $rev = Get-Revision;
    $next = New-Object System.Version($version.Major, $version.Minor, $rev);
    return $next;
}

#creates a tag with the next minor version
function TagNextMinorVersion($tagMessage){
    $version = Get-NextMinorVersion; 
    $tagName=  "v{0}" -f "$version".Trim();
    write-host -NoNewline "Tagging next minor version to ";
    write-host -ForegroundColor DarkYellow "$tagName"; 
    git tag -a $tagName -m $tagMessage
}
function TagCurrentRevision($tagMessage){
   $version = Get-CurrentVersion;
   $tagName = "v{0}" -f "$version".Trim();
    write-host -NoNewline "Tagging current revision to ";
    write-host -ForegroundColor DarkYellow "$tagName"; 
    
    git tag -a $tagName -m $tagMessage
   
}
#creates a tag with the next major version (minor version starts again at 0)
function TagNextMajorVersion($tagMessage){
    $version = Get-NextMajorVersion;
    $tagName=  "v{0}" -f "$version".Trim();
    write-host -NoNewline "Tagging next majo version to ";
    write-host -ForegroundColor DarkYellow "$tagName"; 
    git tag -a $tagName -m $tagMessage
}

function PushLastTag(){
 $version = Get-LastVersion;  

 $tagName=  "v{0}" -f "$version".Trim();
 $ErrorActionPreference='Stop';

    git push origin $tagName
    
}
