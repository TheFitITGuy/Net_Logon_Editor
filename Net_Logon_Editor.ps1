# Created by: Robbie Toumbs
# Created on: 5/20/2017
# Version 1.1
<#
    Version 1.0: Created Script. Requires finalised testing to see if this can be compelted for a use case.
    Version 1.1: Calls a function script that is in #### that reads RMS data for Share drive paths
#>
# Copyright = '(c) 2014 . All rights reserved.'
# Description of the functionality provided by this script
# Description = 'This script is used to automate the process of mapping net login scripts. It will detect drive letters in use and drives that are already mapped.
#Prerequisits of this script - Have atleast read only access to #### and be a part of SHS RMS Users or SHS RMS Admins
# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = '3.0' "Only version this has been tested upon. This should work on versions past 3.0

#List of Variables Defined
<#
    $Alphabet is used to create a multidemensional array of the alphabet of upper and lower case
    $batpath is used for get-content of the users bat file
    $aLetter is set equal to the alphabet coresponding to the number the loop is on in upper case
	$Drive is set to the share drive that needs to be mapped and will be set out to the bat file by appending it
    $userbat is set equal to what the users bat file should be named username.bat (i.e. Robbie Toumbs would have rtoumbs.bat)
    $testpath is equal to where the netlogon file should be located
	$path is set to the path that needs to be mapped
    $Filepath is set equal to where the net logon script is located
	$testpath is testing that path to verify if the bat file is actually created
	$Batfile is set to find a match of the path
	$NetLogon_Template is set to the template that is needed to create a net logon
    $alphabets is a new variable that creates a multidemnsional arry of the alphabet of upper and lower case
    $b is used to loop through the alphabet in the second alpahabet array alphabets
    $bLetter is set equal to the alphabet coresponding to the number the loop is on in upper case
    $Pathcompare is set any to a letter variable that the drive that may match the path if mapped
    $compare is set equal to a comare object of of $batpath($batpath is used for get-content of the users bat file ) and compares it to the any possible drive letter the drive could be mapped to
    $compare.SideIndicator allows me to match if we get a match of a line
#>
Function DriveLetter()


{
    #$alphabet is a multidimensional array that contains upper and lower case letters
    $alphabet =@("",("A","a"),("B","b"),("C","c"),("D","d"),("E","e"),("F","f"),("G","g"),("H","h"),("I","i"),("J","j"),("K","k"),("L","l"),("M","m"),("N","n"),("O","o"),("P","p"),("Q","q"),("R","r"),("S","s"),("T","t"),("U","u"),("V","v"),("W","w"),("X","x"),("Y","y"),("Z","z"))

    #for loop using the variable $a looping back from 26 to 1
    For($a=26; $a -ge 1; --$a)
    {
        #$checkletter is used to get the content of the $userbat file
        $checkletter = Get-Content $Filepath
        #$aLetter is set so that it corresponses with the number in the loop which will go from Z-A
        $aLetter = $alphabet[$a][0]
        #If statement that will match the letter so that P drive, C drive, and V drive is not mapped
        If(($aLetter -eq "P") -or ($aLetter -eq "p") -or ($aLetter -eq "C") -or ($aLetter -eq "c"))
        {
             Write-host "$aLetter is not avalible for net logon" -ForegroundColor Yellow
	         Continue
        }
        #If statement that if the letter is used it will not be used again in the bat file
        If($Checkletter -match $aLetter+":")
        {
            Write-host "Drive $aLetter is taken" -ForegroundColor Yellow
            Continue
        }
        #If statement that if the letter is not used in the bat file it will be used
        If($Checkletter -notmatch $aLetter+":")
        {
            #$Drive is the used to set up the NET USE Letter: /D and new line NET USE Letter: Path
            $Drive = "NET USE "+$aLetter+": /D"+"`r`nNET USE $aLetter"+": $Path"
            #Appeneds the bat file and adds the drives and encodes in the format that the bat file uses
            $Drive|Out-File -encoding utf8 -Append $Filepath
            Write-Host "`n`r$Drive`r`nwas added to $username net logon" -ForegroundColor Green
            Pause
            Exit
        }

    }
}

Function CheckPath_inBat()
{
    #If statement that if the path to the net logon file does not exist it will create a net logon file for the user
    If($testpath -eq $False) #set up to also be able to see if net logon is not set in AD
    {
        #$Netlogon_Template is set to the string that is needed for a blank bat file
        $NetLogon_Template = "@echo off`r`n`r`nCALL %LOGONSERVER%\NETLOGON\Logon.BAT`r`n`r`nREM	MAP PERSONAL AND SHARED FOLDERS`r`n"
        #$Netlogon_Template is piped out to create a new batfile
        $NetLogon_Template | Out-File -encoding utf8 $Filepath
         DriveLetter
         Pause
    }
    If($testpath -ne $False)
    {
        #$batpath gets the conent of the bat file for the user
        $batpath = Get-content $Filepath
        #$batfile searches the bat file for matches of the path that will be added
        $Batfile = Select-String -Path $Filepath -simplematch $Path #If the string can not be search it will be created
        #copies the item that we are going to modify and creates a bak file so that a back up is created
        Copy-Item $Filepath -Destination "$Filepath.bak"
        #If statement that if the $Batfile has a match it will do something
        If ($Batfile -ne $null)
        {
            #$alphabets is a multidemnsional array of upper and lower case letters of the alphabet
            $alphabets =@("",("A","a"),("B","b"),("C","c"),("D","d"),("E","e"),("F","f"),("G","g"),("H","h"),("I","i"),("J","j"),("K","k"),("L","l"),("M","m"),("N","n"),("O","o"),("P","p"),("Q","q"),("R","r"),("S","s"),("T","t"),("U","u"),("V","v"),("W","w"),("X","x"),("Y","y"),("Z","z"))
            #for loop to loop through the alphabet
            For($b=26; $b -ge 0; --$b)
            {
                #$bLetter is used to loop through the alphabet by changing which letter we are picking in the multidimenssional arry
                $bLetter = $alphabets[$b][0]
                #$Pathcompare is used for a second match test as this is more in depth and must include all components of the line in the bat file
                $Pathcompare = "NET USE "+$bLetter+": $Path"
                #$compare compares the batfile and compares again the $Pathcompare variable
                $compare = Compare-Object $batpath $Pathcompare -IncludeEqual
                #If statement used so that if the compare finds something that is the same it will say that the drive is already mapped
                If($compare.SideIndicator -eq "==")
                    {
                        Write-Host "`r`nDrive is already Mapped" -ForegroundColor Red
                        Pause
                        Exit
                    }
                #If statement so that if all letters have been looped through it will know that we have found no match and will map the drive
                If($b -eq 0)
                    {
                        #Calls the function DriveLetter so that a match has not been found and will map the drive
                        DriveLetter
                    }

            }

        }
        else
        {
            Write-Host "`r`nShare drive $Path is being mapped`r`n" -ForegroundColor Green
            #Calls the function DriveLetter as a match was not found and will map the path specificed
            DriveLetter
        }
    }
}

Write-Host "`r`n###Logon Script Editor###`r`n"
#Start of script
#Calls function file
. \\filepathtofunctionfile
#$path reads the security group from the input of the user
$SecurityGroup = Read-Host "Enter the Security Group of the Share Drive you would like to add to the net logon"
# $SG calls the function of getfilepath of the security group
$Path = GetFilePath $SecurityGroup

If($Path -eq $null)
{
    Write-Host "`r`n`r`nPlease verify your Security Group.`r`nCould not locate the path to the share drive" -ForegroundColor Red
    $emailFrom = $env:USERNAME+"@email.com
    $emailTo = "email recipiant"
    $CC = "ccemail"
    $subject = "Net Logon Editor was unable to add a Share Drive"
    $body = "$SecurityGroup was unable to be found in RMS. Please Verify that the Security Group was unable to be located as it is not mapped in RMS."
	$smtpserver="SMTP server address"
	Send-MailMessage -From $emailFrom -To $emailTo -Cc $CC -Subject $subject -Body $body -SmtpServer $smtpServer
}

Else
{
    #$username reads the input for the username of the person we will be adding to their net logon
    $username = Read-Host "Enter the username of the person you would like to add the share drive to"
    #$User searches AD for the script that may be created for a user
    $User = Get-ADUser $username -Properties ScriptPath
    #moves a PSCustomvariable to a variable for the script path
    $userbat = $User.ScriptPath
    #$Filepath is set to a test path of the user desktop instead of the cdcdc1\netlogon share
    $Filepath = "\\NETlogon\fileserver\$username.bat"
    #$testpath is used to verify that the bat file exists in the net logon script share drive
    $testpath =  Test-Path $Filepath
    $logonscriptpath = "NETlogon\fileserver"
    #if statements are used so taht if the user script is set up it will go through another set of checklists
    If($userbat -ne $null)
    {
        Write-host "`r`nUser has a bat file`r`n" -ForegroundColor Green
        #if statement to see if the user has a bat that matches the username of the user
        If("$username.bat" -eq $userbat)
        {
            Write-Host "`r`nUsers bat file matches their username`r`n" -ForegroundColor Green
            $file = Get-Content $Filepath | Out-String
            $file = $file.trimend()
            Set-Content -Encoding utf8 $Filepath $file
            #calls the function CheckPath_inBat to try to find a match and if no match is found it will map the drive
            CheckPath_inBat

        }
        #else statement so that if it does not match the username it copies the bat file that is in place and creates a new batfile with the username
        else
        {
           Write-Host "`r`nUsers bat file is a generic bat file or not their username`r`n"
           If ($testpath -eq $true)
           {
                Write-Host "Please verify that the bat in this location ($logonscriptpath\$username.bat) is not in use and delete and rerun this script" -ForegroundColor Red
                Pause
                Exit

           }
           else
           {

               $file = Get-Content "$logonscriptpath\$userbat" | Out-String
               $file = $file.trimend()
               Set-Content -Encoding utf8 $Filepath $file
               #Copy-Item "$Filepath" -Destination $Filepath
               #Sets AD users account with the logon script that is going to be created
               Set-ADUser $username -ScriptPath "$username.bat"
               #calls the function CheckPath_inBat to try to find a match and if no match is found it will map the drive
               CheckPath_inBat
           }
        }
    }
    If($userbat -eq $null)
    {
        Write-host "User does not have a bat file"
        #Sets AD users account with the logon script that is going to be created
        Set-ADUser $username -ScriptPath "$username.bat"
        #calls the function CheckPath_inBat to try to find a match and if no match is found it will map the drive
        CheckPath_inBat

    }

}
