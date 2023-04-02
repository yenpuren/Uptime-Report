<######################################################################
Uptime Report
This Script gathers the report of system boot time using WMI query to remote servers and generates HTML output. 

.NOTES    
Name: Uptime_Report.ps1
Author: Navanath Yenpure

Version : 1.2
Update  : Check on Address Resolution Status
		: Check on WMI Query Status
Date	: 05-Oct-2022

Version	: 1.1
Date	: 05-Oct-2020

.ServerList
Add List of Servers in ServerList.txt file and keep on same directory

.EXAMPLE 
Uptime_Report.ps1
######################################################################>

$Now = Get-Date
Function GetStatusCode
{ 
	Param([int] $StatusCode)  
	switch($StatusCode)
	{
		0		{"Success"}
		11001	{"Buffer Too Small"}
		11002   {"Destination Net Unreachable"}
		11003   {"Destination Host Unreachable"}
		11004   {"Destination Protocol Unreachable"}
		11005   {"Destination Port Unreachable"}
		11006   {"No Resources"}
		11007   {"Bad Option"}
		11008   {"Hardware Error"}
		11009   {"Packet Too Big"}
		11010   {"Request Timed Out"}
		11011   {"Bad Request"}
		11012   {"Bad Route"}
		11013   {"TimeToLive Expired Transit"}
		11014   {"TimeToLive Expired Reassembly"}
		11015   {"Parameter Problem"}
		11016   {"Source Quench"}
		11017   {"Option Too Big"}
		11018   {"Bad Destination"}
		11032   {"Negotiating IPSEC"}
		11050   {"General Failure"}
		default {"Failed"}
	}
}
Function GetUpTime
{
	param([string] $LastBootTime)
	$Now = Get-Date
	$Uptime = (Get-Date) - [System.Management.ManagementDateTimeconverter]::ToDateTime($LastBootTime)
	"$($Uptime.Days) Days; $($Uptime.Hours) Hrs; $($Uptime.Minutes) Mins; $($Uptime.Seconds) Secs" 
}
#Change value of the following parameter as needed
$OutputFile = ".\Uptime-" + [DateTime]::Now.ToString("yyyy-MM-dd-HH-mm") + ".htm"
$ServerList = Get-Content ".\ServerList.txt"
$SlNo = 0
$Result = @()
Foreach($ServerName in $ServerList)
{
	$SlNo = $SlNo + 1
	$pingStatus.StatusCode = $null
	$pingStatus = Get-WmiObject -Query "Select * from win32_PingStatus where Address='$ServerName'"
	$Uptime = $null
	if($pingStatus.PrimaryAddressResolutionStatus -eq 0)
	{
		if($pingStatus.StatusCode -eq 0)
		{
			try {
				$OperatingSystem = Get-WmiObject Win32_OperatingSystem -ComputerName $ServerName -ErrorAction Stop
				$Uptime = GetUptime( $OperatingSystem.LastBootUpTime )
			}
			catch {
				$Uptime = "NA"
			}
		}
	
		$Result += New-Object PSObject -Property @{
			SlNo = $SlNo
			ServerName = $ServerName
			IPV4Address = $pingStatus.IPV4Address
			Status = GetStatusCode( $pingStatus.StatusCode )
			Uptime = $Uptime
		}
	}
	else {
		$Result += New-Object PSObject -Property @{
			SlNo = $SlNo
			ServerName = $ServerName
			IPV4Address = $pingStatus.IPV4Address
			Status = GetStatusCode( $pingStatus.PrimaryAddressResolutionStatus )
			Uptime = $Uptime
		}
	}
}

if($Result -ne $null)
{
	$HTML = '<style type="text/css">
	#Header{font-family:"Trebuchet MS", Arial, Helvetica, sans-serif;width:100%;border-collapse:collapse;}
	#Header td, #Header th {font-size:14px;border:1px solid #98bf21;padding:3px 7px 2px 7px;}
	#Header th {font-size:14px;text-align:left;padding-top:5px;padding-bottom:4px;background-color:#A7C942;color:#fff;}
	#Header tr.alt td {color:#000;background-color:#EAF2D3;}
	</Style>'
    $HTML += "<HTML><BODY><Table border=1 cellpadding=0 cellspacing=0 id=Header>
    <TR>
    <TH><B>Sl No.</B></TH>
    <TH><B>Server Name</B></TH>
    <TH><B>IP Address</B></TD>
    <TH><B>Ping Status</B></TH>
    <TH><B>Uptime</B></TH>
    </TR>"
    Foreach($Entry in $Result)
    {
        if($Entry.Status -ne "Success")
        {
            $HTML += "<TR bgColor=Red>"
        }
		elseif($Entry.Uptime -eq "NA")
		{
			$HTML += "<TR bgColor=Yellow>"
		}
		else
		{
			$HTML += "<TR>"
		}
		$HTML += "
		<TD>$($Entry.SlNo)</TD>
		<TD>$($Entry.ServerName)</TD>
		<TD>$($Entry.IPV4Address)</TD>
		<TD>$($Entry.Status)</TD>
		<TD>$($Entry.Uptime)</TD>
		</TR>"
    }
$HTML += "<p>
			Time : $($Now) <br>
         </P>"
$HTML += "<p style={font-family:arial;color:red;font-size:14px;text-align:center;}><u><b>Server Uptime</b></u></p>"
$HTML += "</Table></BODY></HTML>"
$HTML | Out-File $OutputFile
}invoke-item .\$outputfile
