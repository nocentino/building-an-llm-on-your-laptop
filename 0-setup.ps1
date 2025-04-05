############################################################################################################
# Create an Azure SQL Database using PowerShell Azure module
############################################################################################################

# Authenticate with Azure
Connect-AzAccount -SubscriptionId 'fd0c5e48-eea6-4b37-a076-0e23e0df74cb'

# Define resource group and database details
$resourceGroupName = "building-an-llm"
$location = "centralus"
$adminSqlLogin = "SqlAdmin"
$password = "S0methingS@Str0ng!"
$serverName = "server-$(Get-Random)"
$databaseName = "AdventureWorksLT"
$myipaddress = (Invoke-WebRequest ifconfig.me/ip).Content
$startIp = $myipaddress
$endIp = $myipaddress

# Create a secure SQL credential
$SqlCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force)



# Create a resource group
$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location



# Create an Azure SQL Server
$server = New-AzSqlServer -ResourceGroupName $resourceGroup.ResourceGroupName `
    -ServerName $serverName `
    -Location $location `
    -SqlAdministratorCredentials $SqlCredential



# Create a server firewall rule to allow access from the current IP
$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroup.ResourceGroupName `
    -ServerName $serverName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp 



# Create a blank database with an S0 performance level
$database = New-AzSqlDatabase -ResourceGroupName $resourceGroup.ResourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -RequestedServiceObjectiveName "S0" `
    -SampleName "AdventureWorksLT"
