function Get-TargetResource {
	[CmdletBinding()]
	[OutputType([Hashtable])]
	param (
		[Parameter(Mandatory)]
		[String]$ServerInstance,

		[Parameter(Mandatory)]
		[String]$Database
	)

	Write-Verbose -Message "Getting the database recovery model information for $Database on $ServerInstance."

    $SQLDBInfo = Get-MrSQLDBInfo -ServerInstance $ServerInstance -Database $Database

	$returnValue = @{
		ServerInstance = [String]$ServerInstance
		Database = [String]$SQLDBInfo.Name
		RecoveryModel = [String]$SQLDBInfo.RecoveryModel
	}

	$returnValue
	
}

function Set-TargetResource {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory )]
		[String]$ServerInstance,

		[Parameter(Mandatory)]
		[String]$Database,

		[ValidateSet('Full', 'BulkLogged', 'Simple')]
		[String]$RecoveryModel

	)

	Write-Verbose -Message "Setting the database recovery model to $RecoveryModel for the $Database on $ServerInstance."
    
    Set-MrSQLRecoverModel -ServerInstance $ServerInstance -Database $Database -RecoveryModel $RecoveryModel       

	#Include this line if the resource requires a system reboot.
	#$global:DSCMachineStatus = 1

}

function Test-TargetResource {
	[CmdletBinding()]
	[OutputType([Boolean])]
	param (
		[Parameter(Mandatory)]
		[String]$ServerInstance,

		[Parameter(Mandatory)]
		[String]$Database,
        
        [Parameter(Mandatory)]
		[ValidateSet('Full', 'BulkLogged', 'Simple')]
		[String]$RecoveryModel
	)

	Write-Verbose "Testing $Database on $ServerInstance to see if the recovery model is $RecoveryModel."

    $SQLDBInfo = Get-MrSQLDBInfo -ServerInstance $ServerInstance -Database $Database

    if ($SQLDBInfo.RecoveryModel -eq $RecoveryModel) {

        [bool]$result = $true

    }
    elseif ($SQLDBInfo.RecoveryModel -ne $RecoveryModel) {

        [bool]$result = $false

    }
	
	$result

}

function Get-MrSQLDBInfo {
    
    [CmdletBinding()]
    param (

      	[parameter(Mandatory)]
		[String]$ServerInstance,

		[parameter(Mandatory)]
		[String]$Database  

    )

    Import-Module SQLPS -DisableNameChecking -ErrorAction SilentlyContinue
    $SQL = New-Object('Microsoft.SqlServer.Management.Smo.Server') -ArgumentList $ServerInstance
    $SQL.Databases.Where({$_.Name -eq $Database})
}

function Set-MrSQLRecoverModel {
    
    [CmdletBinding()]
    param (

		[Parameter(Mandatory)]
		[String]$ServerInstance,

		[Parameter(Mandatory)]
		[String]$Database,

		[ValidateSet('Full', 'BulkLogged', 'Simple')]
		[String]$RecoveryModel

    )

    Import-Module SQLPS -DisableNameChecking -ErrorAction SilentlyContinue
    $SQL = New-Object('Microsoft.SqlServer.Management.Smo.Server') -ArgumentList $ServerInstance
    
    $SQL.Databases.Where({$_.Name -eq $Database}) |
    ForEach-Object {
        $_.RecoveryModel = $RecoveryModel
        $_.Alter()
    }

}

Export-ModuleMember -Function *-TargetResource
