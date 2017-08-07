# Created by: Robbie Toumbs
# Created on: 6/30/2017
# Version 2.0
<#
    Version 1.0: Created Script. 
    Version 2.0: Modified script to also include the removal of share drives. 
    This could also be used to accept an input from an application calling this script when automatiting group membership adds in AD. 
#>
# Description = 'This script is used to remove and add share drive based on a user input it creates net logon files, removes/adds share drives'
# Prerequisits of this script - Have atleast read only access to \\share\Scripts and have permissions on DB to read share drive paths 
# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = '3.0' "Version 3.0 due to Send-mail commandlet used. Was created on 5.0 and has not been tested upon versions below 5.0

#Start of script 
Write-Host "*******************************************************"
Write-Host "* " -NoNewline
Write-Host "          The complete Logon Script Editor          " -ForegroundColor Green -NoNewline 
Write-Host "*"
Write-Host "*******************************************************`n"

. \\functionfilethatqueries\databasefor_networkpath\FUNCTIONS.ps1

Function Email($subject, $body) #email function used to track errors 
{
	$emailFrom = $env:USERNAME+"@example.org" 
    $emailTo = "admin@example.com"
    $subject = $subject
    $body = $body
	$smtpserver="smpt.server.address" 
	Send-MailMessage -From $emailFrom -To $emailTo -Subject $subject -Body $body -SmtpServer $smtpServer 
}

#removal is working as intended 
Function RemoveShareDrive($path2remove) #function used to remove share drive 
{

	Copy-Item "$NETLOGON_Filepath\$ADuserScriptPath" -Destination "$NETLOGON_Filepath\$username.bat.bak"

    $newcontent=""
    $outputcontent=""
    $line=""
    $line2=""
    $content = Get-Content "$NETLOGON_Filepath\$username.bat"

	$alphabet=@()
	$alphabet=@("",("A","a"),("B","b"),("C","c"),("D","d"),("E","e"),("F","f"),("G","g"),("H","h"),("I","i"),("J","j"),("K","k"),("L","l"),("M","m"),("N","n"),("O","o"),("P","p"),("Q","q"),("R","r"),("S","s"),("T","t"),("U","u"),("V","v"),("W","w"),("X","x"),("Y","y"),("Z","z"))
	#loops through alphabet to find match with letter and breaks so that it can be removed 
	For ($alpha=26; $alpha -ge 0; --$alpha)
	{
		$letter=$alphabet[$alpha][0]
		$pathcompare="NET USE $letter"+": $path2remove"
		$netdelete="NET USE $letter"+": /D"

		$comparing=Compare-Object $content $pathcompare -IncludeEqual
		If($comparing.SideIndicator -eq "==")
		{break}

	}
	#$i=1
	#removes share drive path 
	Foreach($line in $content)
	{
			#Write-Host "Line"$i
			$comparing = Compare-Object $line $pathcompare -IncludeEqual
		   If($comparing.SideIndicator -eq "==")
		   {
				#Write-Host "`r`n`r`nMatch" $line
			   Continue
		   }
		   If($comparing.SideIndicator -ne "==")
		   {
				[array]$newcontent+="$line"
		   }
		  # $i++
	}
	#Pause
	   # $t=1
	#removes NET USE : /D line
	Foreach($line2 in $newcontent)
	{
			#Write-Host "Line"$t
			$comparingnet = Compare-Object $line2 $netdelete -IncludeEqual
			If($comparingnet.SideIndicator -eq "==")
			{
				#Write-Host "`r`n`r`nMatch" $line2
			}
			If($comparingnet.SideIndicator -ne "==")
			{
				[array]$outputcontent+="$line2"
			}
		   # $t++
	}
	#outputs file
	$outputcontent=($outputcontent | Out-String).TrimStart()
	$outputcontent=$outputcontent.TrimEnd()
	$outputcontent|Out-File -Encoding utf8 "$NETLOGON_Filepath\$username.bat"
	
	#$showdiff=Compare-Object $outputcontent (Get-Content "$NETLOGON_Filepath\$username.bat.bak")
	Write-Host "`r`nShare Drive has been removed..." -ForegroundColor Green
	Write-Host "`r`nVerify the path was removed from the bat file:`r`n" $outputcontent
	Pause 
	Exit
	
}

#Add Share drive function  
Function AddShareDrive($path2add)
{
	$look4path = ""
	$adddrive = ""

	$look4path = Get-Content "$NETLOGON_Filepath\$username.bat"

	$alphabet =@("",("A","a"),("B","b"),("C","c"),("D","d"),("E","e"),("F","f"),("G","g"),("H","h"),("I","i"),("J","j"),("K","k"),("L","l"),("M","m"),("N","n"),("O","o"),("P","p"),("Q","q"),("R","r"),("S","s"),("T","t"),("U","u"),("V","v"),("W","w"),("X","x"),("Y","y"),("Z","z"))
	#loops through first looking for a match 
	For($a=26; $a -ge 0; --$a)
	{
		$aletter = $alphabet[$a][0]
		$netshareadd = "NET USE "+$aletter+": $path2add"
		$compare_mapped = Compare-Object $look4path $netshareadd -IncludeEqual
		If($compare_mapped.SideIndicator -eq "==")
		{
			Write-Host "`r`nDrive is already Mapped`r`n" -ForegroundColor Red
			$look4path
			Pause 
			Exit
		}
		If($a -eq 0) #no match is found it will now add drive 
		{
			#map drive 
			for($b=26; $b -ge 0; --$b)
			{
				$freeletter = $alphabet[$b][0]
				If($b -eq 0) #net logon file has looped through the alphabet and is full 
				{
					Write-Host "Please verify the Net Logon File is full" 
					Pause 
					Exit 
				}
				If(($freeletter -eq "P") -or ($freeletter -eq "p") -or ($freeletter -eq "C") -or ($freeletter -eq "c") -or ($freeletter -eq "V") -or ($freeletter -eq "v")) #letters not used as they dont work when mapped
				{Continue}
				If($look4path -match $freeletter+":") #letter is taken
				{Continue}
				If($look4path -notmatch $freeletter+":") #letter is free for use
				{
					#Found unused letter and will map the drive now 
					$adddrive = "NET USE "+$freeletter+": /D"+"`r`nNET USE $freeletter"+": $path2add"
					$setgoodbat = $look4path | Out-String
					$setgoodbat = $setgoodbat.TrimEnd()
					Set-Content -Encoding utf8 -Path "$NETLOGON_Filepath\$username.bat" -Value $setgoodbat
					Start-Sleep -Seconds 5
					#sleep set so that it can be set before trying to add the path 
					$adddrive|Out-File -encoding utf8 -Append "$NETLOGON_Filepath\$username.bat"

					If($testpath -eq $false) #used for if a net logon file was created so that it does not through an error when trying to compare 
					{
						Write-Host "`r`nNet logon was created for $username and `r`n$adddrive was added!" -ForegroundColor Green
						Pause 
						Exit
					}
					If($testpath -ne $false) #verifies the path was mapped if the bat file was not created 
					{
						$original = $look4path | Out-String
						$Original = $Original.TrimEnd()
						$mapped = $Original+"`r`n$adddrive"

						$testthe_add = Get-Content "$NETLOGON_Filepath\$username.bat"
						$testthe_add = ($testthe_add | Out-String).TrimEnd()
						$final_add_compare = Compare-Object $mapped $testthe_add -IncludeEqual
						If($final_add_compare.SideIndicator -ne "=>" -or "<=" -and $final_add_compare.SideIndicator -eq "==") #successfully compared and looks correct
						{
							Write-Host "The $Path was successfully mapped!`r`nVerify below:`r`n" -ForegroundColor Green
							$testthe_add
							Pause 
							Exit
						}
						Else #something doesn't look right an error email is sent 
						{
							Write-Host "Something Happened! There was an Error please verify the Net Logon" -ForegroundColor Red
							$subject_add = "An Error Occured on NET_LOGON_Editor.ps1!"
							$body_add = "An Error Occured and NET_LOGON_Editor.ps1 could not verify a Share Drive was Mapped for $username!"
							Email $subject_add $body_add
							Pause 
							Exit
						}
					}
				}
			}
		}
	}
}

#working function. Creates Templates 
Function CreateNetlogon($filepath)
{
	$netlogon_template = "@echo off`r`n`r`nCALL %LOGONSERVER%\Login.BAT`r`n`r`nREM	MAP PERSONAL AND SHARED FOLDERS`r`n"
	$netlogon_template | Out-File -Encoding utf8 $filepath
}

#Works for both Removals and Additions 
For($i=0; $i -le 25; $i++)
{
	$remove_or_add = ""
	$rms_sharepath=""
	$sharedrive_path=""
	$username=""
    $testpath=""
	#selecting if the user wants to add or remove a share drive 
	$remove_or_add = Read-Host "Enter R for removal or A for adding a share drive"
	If($remove_or_add.ToLower() -eq "r")
	{
		Write-Host "You selected removing Share Drive..."
		break
	}
	If($remove_or_add.ToLower() -eq "a")
	{
		Write-Host "You selected adding Share Drive..."
		break
	}
	If(($remove_or_add.ToLower() -ne "a") -or ($remove_or_add.ToLower() -ne "r"))
	{
		Write-Host "Please select either Removal or addition of a share drive"
		Pause 
		Clear
	}
}


	$rms_sharepath = Read-Host "`r`nEnter the Security Group"
	$sharedrive_path= GetFilePath $rms_sharepath
	If($sharedrive_path -eq $null) #couldn't find security group 
	{
		Write-Host "`r`n`r`nPlease verify your Security Group.`r`nCould not locate the path to the share drive`r`nEnsure that you are only removing \\basagh\DEPTS or \\basagh\TEAM`r`n" -ForegroundColor Red
		$Path_null="NET LOGON Removal - Couldn't find Path"
		$path_null_body="$SecurityGroup was unable to be found in Database. Please Verify that the Security Group is not mapped."
		Email $Path_null $path_null_body 
    
		Pause
		Exit

	}
	Else 	#Else statement that if $security group returns it will go through the drive mapping script 
	{
		$username = Read-Host "`r`nEnter the username"
		Try 
		{$User = Get-ADUser $username -Properties ScriptPath }
		Catch
		{
			Write-Host "$username could not be located. Please verify that the username is correct!" -ForegroundColor Red
			Pause
			Exit 
		}
		$ADuserScriptPath = $User.ScriptPath
		$NETLOGON_Filepath = "C:\users\$env:username\desktop"
		$testpath = Test-Path "$NETLOGON_Filepath\$ADuserScriptPath"
		If($ADuserScriptPath -eq "$username.bat") #AD net logon path is set to the username
		{
			Write-Host $User.Name "`r`nhas a bat file set in AD and it matches their username`r`n"
			If ($testpath -eq $true) #bat file exists w\username 
			{
				Write-Host "Bat File exists"
				if($remove_or_add.ToLower() -eq 'r')
				{
					RemoveShareDrive $sharedrive_path
				}
				If($remove_or_add.ToLower() -eq 'a')
				{
					AddShareDrive $sharedrive_path
				} 
				Pause 
				Exit 
			}
			If($testpath -ne $true) #bat file does not exist 
			{
				Write-Host "`r`nBatfile does not exist. `r`nCreating Net logon File" -ForegroundColor Red
				Set-ADUser $username -ScriptPath "$username.bat"
				CreateNetlogon "$NETLOGON_Filepath\$username.bat"
				$User = Get-ADUser $username -Properties ScriptPath
				$ADuserScriptPath = $User.ScriptPath
				if($remove_or_add.ToLower() -eq 'r')
				{
					RemoveShareDrive $sharedrive_path
				}
				If($remove_or_add.ToLower() -eq 'a')
				{
					AddShareDrive $sharedrive_path
				}
				Pause
				Exit
			}

		}
		If($ADuserScriptPath -ne "$username.bat") #bat file is generic or not the username of the employee
		{
			If($ADuserScriptPath -eq $null) #nothing is set in the script path so it will not try to copy it
			{
				Write-Host $User.Name "bat file does not match their username"
				$testpath_username = Test-Path "$NETLOGON_Filepath\$username.bat"
				If($testpath_username -eq $true)  #bat file exists and is now set in AD 
				{
					Write-Host "`r`nBat file exists and is now set in AD" -ForegroundColor Green
					Set-ADUser $username -ScriptPath "$username.bat"
					$User = Get-ADUser $username -Properties ScriptPath
					$ADuserScriptPath = $User.ScriptPath
					Start-Sleep -Seconds 3
					Write-Host "`r`n Begining..."
					if($remove_or_add.ToLower() -eq 'r')
					{
						RemoveShareDrive $sharedrive_path
					}
					If($remove_or_add.ToLower() -eq 'a')
					{
						AddShareDrive $sharedrive_path
					}
					Pause
					Exit
				}
				If ($testpath_username -eq $false) #bat file doesnt exist and creates the net logon
				{
					Set-ADUser $username -ScriptPath "$username.bat"
					CreateNetlogon "$NETLOGON_Filepath\$username.bat"
					Write-Host "`r`nBat file was created with the name $username.bat" -ForegroundColor Green
					Start-Sleep -Seconds 3
					Write-Host "`r`n Begining..."
					if($remove_or_add.ToLower() -eq 'r')
					{
						Write-Host $User.Name "User did not have a bat file before running this script.`r`nThere is nothing to remove."
					}
					If($remove_or_add.ToLower() -eq 'a')
					{
						AddShareDrive $sharedrive_path
					}
					Pause 
					Exit
				}

			}
			If ($testpath -eq $true) #bat file exists with generic or nonusername name 
			{ 
				Set-ADUser $username -ScriptPath "$username.bat"
				Copy-Item "$NETLOGON_Filepath\$ADuserScriptPath" -Destination "$NETLOGON_Filepath\$username.bat"
				$testpath_username = Test-Path "$NETLOGON_Filepath\$username.bat"
				If($testpath_username -eq $true)  #file was copied and now matches username
				{
					Write-Host "`r`nBat file was created with the name $username.bat" -ForegroundColor Green
					Write-Host "`r`n Begining..."
					Set-ADUser $username -ScriptPath "$username.bat"
					Start-Sleep -Seconds 3
					if($remove_or_add.ToLower() -eq 'r')
					{
						RemoveShareDrive $sharedrive_path
					}
					If($remove_or_add.ToLower() -eq 'a')
					{
						AddShareDrive $sharedrive_path
					}
					Pause
					Exit
				}
				If ($testpath_username -ne $true) #error when trying to copy and an email is sent out 
				{
					Write-Host "`r`nThere was an error coping the file.`r`nPlease verify that the file was or wasn't created. "
					$sub_copy_error 
					$body_copy_error
					Email $sub_copy_error $body_copy_error
					Pause 
					Exit
				}
			}
			If ($testpath -ne $true)  #file does not exist and creates batfile 
			{
				Write-Host "`r`nCreating Net logon File" -ForegroundColor Red
				Set-ADUser $username -ScriptPath "$username.bat"
				CreateNetlogon "$NETLOGON_Filepath\$username.bat"
				Start-Sleep -Seconds 3
				if($remove_or_add.ToLower() -eq 'r')
				{
					RemoveShareDrive $sharedrive_path
				}
				If($remove_or_add.ToLower() -eq 'a')
				{
					AddShareDrive $sharedrive_path
				}
				Pause
				Exit
			}

		}
	
	}
