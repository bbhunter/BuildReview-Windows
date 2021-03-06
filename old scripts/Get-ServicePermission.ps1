Param([string[]]$ComputerName=$($env:COMPUTERNAME),$Credential=$null)

if($Credential){
    $services = gwmi win32_service -ComputerName $ComputerName -Credential $Credential
}else{
    $services = gwmi win32_service -ComputerName $ComputerName
}

Foreach($Service IN ($Services | select-object __server, Name, StartName, @{'n'='Executable';e={$($($_.pathname -split "\.exe")[0] + ".exe").Replace('"','')}})){

$CurrentComputer = $ComputerName
    
if($Credential){
    $File = gwmi Win32_LogicalFileSecuritySetting -ComputerName $ComputerName -Credential $Credential -Filter "path=`"$($Service.Executable.Replace('\\','\').Replace('\','\\'))`""
}else{
    $File = gwmi Win32_LogicalFileSecuritySetting -ComputerName $ComputerName -Filter "path=`"$($Service.Executable.Replace('\\','\').Replace('\','\\'))`""
}
if($File){
    try{
        $File.GetSecurityDescriptor().Descriptor.DACL | where {$_.AccessMask -as [Security.AccessControl.FileSystemRights]} |select `
                    @{name="ComputerName";Expression={$CurrentComputer}},
                    @{name="ServiceName";Expression={$Service.Name}},
                    @{name="Executable";Expression={$Service.Executable}},
                    @{name="StartName";Expression={$Service.StartName}},
    				@{name="Principal";Expression={"{0}\{1}" -f $_.Trustee.Domain,$_.Trustee.name}},
    				@{name="Rights";Expression={[Security.AccessControl.FileSystemRights] $_.AccessMask }},
    				@{name="AceFlags";Expression={[Security.AccessControl.AceFlags] $_.AceFlags }},
    				@{name="AceType";Expression={[Security.AccessControl.AceType] $_.AceType }}
    }
    catch{
    '' | select `
                    @{name="ComputerName";Expression={$CurrentComputer}},
                    @{name="ServiceName";Expression={$Service.Name}},
                    @{name="Executable";Expression={$Service.Executable}},
                    @{name="StartName";Expression={$Service.StartName}},
    				@{name="Principal";Expression={"Fatal error obtaining permissions - $_"}},
    				@{name="Rights";Expression={$null}},
    				@{name="AceFlags";Expression={$null}},
    				@{name="AceType";Expression={$null}}
    }

}else{
'' | select `
                @{name="ComputerName";Expression={$CurrentComputer}},
                @{name="ServiceName";Expression={$Service.Name}},
                @{name="Executable";Expression={$Service.Executable}},
                @{name="StartName";Expression={$Service.StartName}},
				@{name="Principal";Expression={$null}},
				@{name="Rights";Expression={$null}},
				@{name="AceFlags";Expression={$null}},
				@{name="AceType";Expression={$null}}

}
				

}