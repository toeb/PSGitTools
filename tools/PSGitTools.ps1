#returns the last version by analysing existing tags, 
#assumes an initial tag is present
# assumes tags are named v{major}.{minor}.[{revision}]
function Get-LastVersion(){
[OutputType([version])]
$lastTagCommit = git rev-list --tags --max-count=1
$lastTag = git describe --tags $lastTagCommit
$tagPrefix = "v"
$versionString = $lastTag -replace "$tagPrefix", ""
write-host -NoNewline "last tagged commit "
write-host -NoNewline -ForegroundColor "yellow" $lastTag
write-host -NoNewline " revision "
write-host -ForegroundColor "yellow" "$lastTagCommit"

[version]$version = New-Object System.Version($versionString)
return $version;
}
#returns the name of the repository 
#first checks remote name, then uses name of containing directory
function Get-GitRepositoryName($path){
    if($path -eq $Null){
        $path = Get-Location
    }
    pushd
    cd $path
    $result= git config --get remote.origin.url
    if($result -eq $Null){
        $result = Get-Location
    } 
    [string] $name = Split-Path $result -Leaf
    if($name.EndsWith(".git")){
        $name=$name.Substring(0,$name.Length-4)
    }
    popd
    return $name;
}



# returns current revision by counting the nummer of commits
function Get-Revision($path){
    if($path -eq $Null) {
        $path = Get-Location
    }
    pushd
    cd $path
    $lastTagCommitResult = ExecGit "rev-list HEAD" 

    $lastTagCommitResultLines= $lastTagCommitResult | Split-String -RemoveEmptyStrings

    $lastTagCommit = $lastTagCommitResultLines |  select -First 1 -Last 1
    $revs  = ExecGit " rev-list $lastTagCommit  |  Measure-Object -Line"
    popd
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

function Get-BuildNumber(){
    return 0;
}

#returns the last minor version with an up to date revision number
function Get-CurrentVersion(){
    [OutputType([version])]
    [version]$version = Get-LastVersion;
    $rev = Get-Revision;
    $build = Get-BuildNumber;
    [version]$next = New-Object System.Version($version.Major, $version.Minor,$build, $rev);
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

# creates a tag for the the current version
# the current version consists of the manually set major and minor version
# and the curretn revision.
function TagCurrentVersion{
    param(
     [Parameter(Mandatory=$true,HelpMessage="commit message for current tag")] [string] $tagMessage,
     [Parameter(HelpMessage="the root directory of the local repository, if not specified the current directory is used")]$path
    )

    if($path -eq $null){
        $path = Get-Location
    }
    pushd 
    cd $path
    $version = Get-CurrentVersion;
    $tagName = "v{0}" -f "$version".Trim();
    write-host -NoNewline "Tagging current revision to ";
    write-host -ForegroundColor DarkYellow "$tagName"; 
    
    git tag -a $tagName -m $tagMessage
    popd
    return $version
}
function Get-CurrentTagCommitMessage($path){
    $version = Get-CurrentVersion $path
    return "Tagging version $version"
}
#creates a tag with the next major version (minor version starts again at 0)
function TagNextMajorVersion($tagMessage){
    $version = Get-NextMajorVersion;
    $tagName=  "v{0}" -f "$version".Trim();
    write-host -NoNewline "Tagging next majo version to ";
    write-host -ForegroundColor DarkYellow "$tagName"; 
    git tag -a $tagName -m $tagMessage
    return $version
}

# gets the last tagged version and pushes it to the remote
function PushLastTag(){
    $version = Get-LastVersion;  
    $tagName=  "v{0}" -f "$version".Trim();
    $ErrorActionPreference='Stop';
    git push origin $tagName
    return $version;
}


function Exec($file, $arguments){
$processStartInfo = new-object system.diagnostics.processStartInfo
$processStartInfo.workingDirectory = (get-location).path
$processStartInfo.fileName = $file
$processStartInfo.arguments = $arguments
$processStartInfo.useShellExecute = $false
$processStartInfo.RedirectStandardOutput = $true;
$processStartInfo.RedirectStandardError = $true;
$process = [system.diagnostics.process]::start($processStartInfo);
$result =  $process.waitForExit();
return $process.StandardOutput.ReadToEnd();

}

# silently executes a git  string
function ExecGit($arguments){
 $result=  Exec -file "git" -arguments $arguments
 return $result;
}