#Requires -RunAsAdministrator
#Requires -Modules ("FailoverClusters", "Hyper-V")
$ErrorActionPreference = "Stop"

Import-Module -Name ("FailoverClusters", "Hyper-V")
$ConfigFile_Path = "$env:APPDATA\Microsoft\Windows\Hyper-V\Client\1.0\virtmgmt.VMBrowser.config"

$PreviousSelectedServer = $ServerList = $null
Try
    {
        # Should succeed if host is member of FailOverCluster
        $ServerList = Get-ClusterNode | Select-Object -ExpandProperty "Name"
        $PreviousSelectedServer = $env:COMPUTERNAME
    }
Catch
    {
        Write-Host "Host is not a member of a cluster. Adding all Hyper-V hosts from all Clusters"

        foreach ($i_Cluster in (Get-Cluster -Domain (Get-ComputerInfo | Select-Object -ExpandProperty "CsDomain") | Select-Object -ExpandProperty "Name"))
            {
                $ServerList += Get-ClusterNode -Cluster $i_Cluster | Select-Object -ExpandProperty "Name"
            }
    }

$ServerList = $ServerList | Sort-Object

$ConfigFile_Contents = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <Microsoft.Virtualization.Client.VMBrowser.BrowserConfigurationOptions>
        <setting name="SnapshotPaneCollapsed" type="System.Boolean">
            <value>False</value>
        </setting>
        <setting name="MainSplitterRatio" type="System.Single">
            <value>0.75</value>
        </setting>
        <setting name="BrowserComputerNames" type="System.String">
            <value>$($ServerList -join ";")</value>
        </setting>
        <setting name="CurrentVisibleColumns" type="System.String">
            <value>Name:191;State:87;CpuUsage:87;AssignedMemory:120;Uptime:100;Task:200</value>
        </setting>
        <setting name="DontTakeSnapshotBeforeApply" type="System.Int32">
            <value>0</value>
        </setting>
        <setting name="SortColumnIndex" type="System.Int32">
            <value>0</value>
        </setting>
        <setting name="SortDirection" type="System.String">
            <value>Ascending</value>
        </setting>
        <setting name="FirstTimeRunBrowser" type="System.Boolean">
            <value>False</value>
        </setting>
        <setting name="PreviousSelectedServer" type="System.String">
            <value>$($PreviousSelectedServer)</value>
        </setting>
        <setting name="AutoCompleteComputerNames" type="System.String">
            <value>$($ServerList -join ";")</value>
        </setting>
    </Microsoft.Virtualization.Client.VMBrowser.BrowserConfigurationOptions>
</configuration>
"@


If ((Test-Path -Path $ConfigFile_Path) -eq $false)
    {
        # To create the directories if not already there. Out-File -Force doesn't do it
        New-Item -Path $ConfigFile_Path -ItemType File -Force
    }
Out-File -InputObject $ConfigFile_Contents -FilePath $ConfigFile_Path -Force -Encoding utf8