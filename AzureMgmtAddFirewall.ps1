##################### Script Configuration #####################

    # Leave empty to process all subscriptions
    $subscriptions = @("subscription1","subscription2","subscription3")
    
    # Name of the server you want to set a rule for such as "qnfm83tqem"
    # If left blank, rules will be adjusted for all servers found in the subscription(s)
    $servername = ""

    # This cannot be left blank
    $ruleName = "myRuleName"

    $startIpAddress = "23.103.190.210"
    $endIpAddress = "23.103.190.210"

    # If true, rule is added/updated. 
    # If false, any existing matching rule is removed
    $addOrUpdate = $true

    $ErrorActionPreference = "Stop"

################################################################

if(!$ruleName)
{
    throw [Exception] "You must specify a string for ruleName"
}

if (!$subscriptions)
{
    $subscriptions = Get-AzureSubscription | Select -ExpandProperty SubscriptionName
}


foreach ($subscription in $subscriptions)
{
    "Processing Subscription $subscription..."
    Select-AzureSubscription $subscription

    "Getting list of servers..."
    $servers = Get-AzureSqlDatabaseServer
    if($serverName){
        "Only getting servers for $($servername)"
        $servers = $servers | where {$_.ServerName -eq $serverName}
    }

    $serverCount = $servers | Measure | Select -ExpandProperty Count
    $i = 0
    "Processing $($serverCount) server(s)"
    foreach ($server in $servers)
    {
        $i++    
        $serverRules = Get-AzureSqlDatabaseServerFirewallRule -ServerName $server.ServerName
        $existingRule = $serverRules | where { $_.RuleName -eq $ruleName }
        if($addOrUpdate){
            if ($existingRule) {
                if($existingRule.StartIpAddress -eq $startIpAddress) {
                    "Skipping unchanged rule for server $($i) of $($serverCount): $($server.ServerName)"
                } else {
                    "Updating pre-existing rule for server $($i) of $($serverCount): $($server.ServerName)"
                    Set-AzureSqlDatabaseServerFirewallRule -ServerName $server.ServerName -RuleName $ruleName -StartIpAddress $startIpAddress -EndIpAddress $endIpAddress
                }
            }
            else {
                "Adding rule for server $($i) of $($serverCount): $($server.ServerName)"
                New-AzureSqlDatabaseServerFirewallRule -ServerName $server.ServerName -RuleName $ruleName -StartIpAddress $startIpAddress -EndIpAddress $endIpAddress 
            }
        } else{
            "Removing pre-existing rule for server $($i) of $($serverCount): $($server.ServerName)"
            Remove-AzureSqlDatabaseServerFirewallRule -ServerName $server.ServerName -RuleName $ruleName
        }
    }
}