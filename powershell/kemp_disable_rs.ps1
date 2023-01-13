<#
.DESCRIPTION
  This is a script to report to check the health of hypervisors (vmware and rhv).
.PARAMETER vlb
  The connection hostname or IP address of the Kemp Load Balancer to connect to e.g. "qld-ndb2=vlb01"
.PARAMETER vlbport
  The port that will be used to connect to the Kemp Load Balancer API e.g. 8443
.PARAMETER maintenance_rs
  The IP address of the Real Server that will be disabled for maintenance e.g. 172.16.0.22
.INPUTS
  Requires Windows Vault entry for "kemp-query"
.OUTPUTS
  Log file stored in "C:\temp\hypervisor_daily_checks$(Get-Date –f yyyy-MM-dd-HHmm).log"
  Email will be sent to list of addresses in $msgto array.
.NOTES
  Version:        1.0
  Author:         Joshua Perry
  Creation Date:  16/11/2022
  Purpose/Change: This is an evolution of a previous script (vmware_daily_checks.ps1) to include multiple hypervisors.
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>

#----------------------------------------------------------[Logging Start]---------------------------------------------------------

    # Begin Log

        Start-Transcript -Path "C:\temp\kemp_disable_rs_$(Get-Date -f yyyy-MM-dd-HHmm).log"

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

    # Import Settings

        $settingsfile = "c:\temp\kemp_disable_rs.config"
        $settings = Get-Content $settingsfile | Out-String | ConvertFrom-StringData

        # Example File Structre: See example_hypervisor_daily_checks_settings.config file.


    # Set Error Action to Silently Continue

        $ErrorActionPreference = "SilentlyContinue"

    # Initialise Arrays

        $rhvauth = @()

    # Create HTML Header

        $Header = @("
        <style>
        TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
        TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #21c465;}
        TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
        .header {
            padding: 60px;
            text-align: center;
            background: #FFFFFF;
            color: black;
            font-size: 45px;
            line-height: 45px;
        }
        </style>
        <div class='header'>
            <h1>Hypervisor Health Check Report</h1>
        </div>
        ")

#----------------------------------------------------------[Declarations]----------------------------------------------------------

    # General
    
        # N/A

    # SMTP Settings
    
        #$msgsubj = $settings.msgsubj
        #$msgfrom = $settings.msgfrom
        #$msgto = $settings.msgto | convertfrom-json
        #$smtpServer = $settings.smtpsrv
        #$smtp = New-Object Net.Mail.SmtpClient($SmtpServer, 25)

    # Get Account for Kemp API Authentication

        # Retrieve Credentials from Vault

            [Windows.Security.Credentials.PasswordVault,Windows.Security.Credentials,ContentType=WindowsRuntime]
            $vaultresource="kemp-query" # Be sure to store hypervisor readonly credentials in password vault with this resource name
            $vault = New-Object Windows.Security.Credentials.PasswordVault
            $username = ( $vault.RetrieveAll() | Where-Object { $_.Resource -eq $vaultresource } | Select-Object -First 1 ).UserName
            $user = ($username.split("@"))[0]
            $domain = ($username.split("@"))[1]
            $password = ( $vault.Retrieve( $vaultresource, $username ) | Select-Object -First 1 ).Password
            $securepass = ConvertTo-SecureString -String $password -AsPlainText -Force
                
        # Set Secure Credentials Variable
            
            $credential = New-Object System.Management.Automation.PSCredential ($username, $securepass)
        
        # Clean Up

            Remove-Variable password # So that we don't have the unsecure password lingering in memory

#----------------------------------------------------------[Gather Data]-----------------------------------------------------------

    # Kemp Details
    
        if ($null -eq $vlb) {
            $vlb = $settings.vlb
        }

        if ($null -eq $vlbport) {
            $vlbport = $settings.vlbport
        }
        
        if ($null -eq $maintenance_rs) {
            $maintenance_rs = $settings.maintenance_rs
        }

#-----------------------------------------------------------[Functions]------------------------------------------------------------

    # N/A

#-----------------------------------------------------[Gather Real Server DAtaConnect to Hypervisors]-----------------------------------------------------

    Initialize-LmConnectionParameters -Address $vlb -LBPort $vlbport -Credential $creds -Verbose
    $getvs = Get-AdcVirtualService
    $realservers = @()
    foreach ($vs in $getvs.data.vs) {
        foreach ($rs in $vs.rs) {
            $realservers += New-Object -TypeName PSObject -Property @{
                            vsnickname = $vs.nickname;
                            vsaddr = $vs.vsaddress;
                            vsport = $vs.vsport;
                            vsprotocol = $vs.protocol;
                            vsindex = $vs.index;
                            rsdnsname = $rs.dnsname;
                            rsaddr = $rs.addr;
                            rsport = $rs.port;
                            rsweight = $rs.weight;
                            rsindex = $rs.rsindex;
                            rsenable = $rs.enable;
                            rsstatus = $rs.status;
                            }
            }
        }

    $rsbefore = $realservers | where-object {$_.rsaddr -eq $maintenance_rs}
    $realservermaint = $realservers | where-object {$_.rsaddr -eq $maintenance_rs -and $_.rsstatus -ne "Disabled"}
    foreach ($rsmaint in realservermaint) {
        $setrs = Set-AdcRealServer -rsindex $rsmaint.rsindex -enable $False -vsindex $rsmaint.vsindex
        $setrs | Format-List
    }

#----------------------------------------------------------[Logging Stop]----------------------------------------------------------

    # Stop Log
    
        Stop-Transcript