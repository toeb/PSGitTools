$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

Describe "PSGitTools" {
    pushd
    
    mkdir "$TestDrive/myRepo"
    mkdir "$TestDrive/myRepo2.git"
    git init "$TestDrive/myRepo"
    git init "$TestDrive/myRepo2.git"
    
    Context "Get-GitRepositoryName"{
        
        It "should parent directory name if remote is  not set" {
           mkdir "$TestDrive/repo1"

           $result = Get-GitRepositoryName "$TestDrive/repo1";
           $result | Should be "repo1"
        }

        It "should get the remote name if it is a remote repository" {

            git clone "$TestDrive/myRepo" "$TestDrive/otherDir"

            $result = Get-GitRepositoryName "$TestDrive/otherDir"
            $result | Should Be "myRepo"
        }

        It "should remove '.git' extension from name"{
            git clone "$TestDrive/myRepo2.git" "$TestDrive/otherDir2"
            $result = Get-GitRepositoryName "$TestDrive/otherDir2"
            $result | Should Be "myRepo2"
        }
    }


    Context "Get-Revision" {

        It "Should return 0 for a newly created repository"{
            mkdir "$TestDrive/repo3"
            cd "$TestDrive/repo3"
            git init
            $result = Get-Revision
            $result | Should Be 0
        }

        It "Should return the correct revision number"{
            mkdir "$TestDrive/repo4"
            cd "$TestDrive/repo4"
            git init
            "some text" > "readme.md"
            git add "readme.md"
            git commit -m "message" 
            $result = Get-Revision "$TestDrive/repo4"
            $result | Should Be 1
        }

        It "Shoudl return the correct revision number after 2 commits"{

            mkdir "$TestDrive/repo5"
            cd "$TestDrive/repo5"
            git init
            "some text" > "readme.md"
            git add .
            git commit -m "message"
            "some new text" > "readme.md"
            git add -u
            git commit -m "message2"
            $result = Get-Revision
            $result | should be 2
        }
    }

    Context "TagCurrentVersion" {
        It "Should create v0.0.0.1 tag for initial version" {
            #arrange
            mkdir "$TestDrive/repo7" | cd
            git init > $null
            "text" > readme.md
            git add .
            git commit -m "initial commit"
            
            #act
            $version = TagCurrentVersion "$TestDrive/repo7"

            # check
            "$version" | should be "0.0.0.1"
            "$(get-lastversion)" | Should be "0.0.0.1"
        }

        It "Should no fail if current version is already tagged" {
            #arrange
            mkdir "$TestDrive/repo9" | cd
            git init 
            "text" > readme.md
            git add .
            git commit -m "init"

            #act
            $version1 = TagCurrentVersion "m"
            $version2 = TagCurrentVersion "m2"

            # check
            "$version2" | should be "$version1"

        }

        
    }

    Context "TagNextMinorVersion"{
        It "should tag version 0.1" {
            #arrange
            mkdir "$TestDrive/repo9" | cd
            git init 
            "text" > readme.md
            git add .
            git commit -m "init"

            $version = TagNextMinorVersion

            "$version" | should be "0.1.0.1"
        }
        

    }
    Context "TagNextMajorVersion"{
        It "should tag version 1.0"{
            
            #arrange
            mkdir "$TestDrive/repo9" | cd
            git init 
            "text" > readme.md
            git add .
            git commit -m "init"

            $version = TagNextMajorVersion

            "$version" | should be "1.0.0.1"

        }

        It "should reset minor version to 0"{
           #arrange
            mkdir "$TestDrive/repo9" | cd
            git init 
            "text" > readme.md
            git add .
            git commit -m "init"

            $version = TagNextMinorVersion "message"
            $version = TagNextMajorVersion "message"

            "$version" | should be "1.0.0.1"


        }

        It "should increment major version"{
           #arrange
            mkdir "$TestDrive/repo9" | cd
            git init 
            "text" > readme.md
            git add .
            git commit -m "init"

            $version = TagNextMajorVersion "message"
            $version = TagNextMajorVersion "message"

            "$version" | should be "2.0.0.1"

        }

    }


    Context "PushLastTag" {
        It "should push last tag to remote"{
            
        }
    }


    Context "Get-LastVersion" {
        It "Should return 0.0 if no version is present"{
            #arrange
            mkdir "$TestDrive/repo8" | cd

            # act
            "$(Get-LastVersion)" | should be "0.0"
            
        }
    }

    Context "Get-CurrentVersion"    {
        It "Should return 0.0.0.0 if no version is present"{
            #arrange
            mkdir "$TestDrive/repo6" |cd

            # act
            "$(Get-CurrentVersion)" | should be "0.0.0.0"
            
        } 

        

    }


    popd
}

