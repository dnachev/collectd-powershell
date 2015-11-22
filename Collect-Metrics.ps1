# PowerShell script to sample Performance Counters and send the statistics to collectd
# compatible server (anything, which supports collectd write_http plugin)
#
# The script will accept the specific parameters below plus any additional parameter, treated
# as performance counter name. More information can be found in Get-Counter documentation[1].
#
# Note: the script hasn't been extensively tested and it may not work.

param(
	[string]$User, # username to be used when sending statistics
	[string]$Token, # the password to be used when sending statistics 
	[System.Uri]$Url, # the HTTP URL to send the statistics to 
	[int]$Interval # the sampling interval
)

# Returns current time in UNIX format
function Current-UnixTime {
	[System.Math]::Round(((Get-Date).toUniversalTime() - (New-Object System.DateTime -Args 1970,1,1,0,0,0,0,Utc)).TotalSeconds, 0)	
}

# Returns the fully qualified hostname of the current machine
function Get-Hostname {
	[System.Net.Dns]::GetHostEntry([string]$env:computername).HostName
}

# Cache the hostname, it doesn't change very often
$TheHostname = Get-Hostname

# Create the necessary credentials for HTTP Basic Auth
$SecToken=ConvertTo-SecureString $Token -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential($User,$SecToken)

# Sanitizes the name of the counters/metrics to be valid collectd identifiers.
# Replaces a bunch of special characters with '_'. This doesn't lead to the most
# pleasant result, but gets the job done for now.
function Sanitize-MetricName ($Name) {
	$Name -replace '[\% /\[\]()?*^&$#@!<>{}]', '_'
}

# Ouputs a hashtable, representing a single sample of a single counter
# ready to be sent over HTTP once it is converted to JSON
# $Sample = \\hostname\processor(_total)\% user time
function Generate-Measurement ($Sample, $Time) {
	$path = ($Sample.Path -replace "\\\\", "\").Split("\\") # Remove leading slashes and split
	$m = ($path[2] | Select-String "(.+?)(\(.+\))?$") # Match processor(_total), where _total is the instance (i.e. D: when monitoring disks)
	$category = Sanitize-MetricName($m.matches.groups[1].Value) # First group will always contain the category without the instance
	$counter = Sanitize-MetricName($path[3])	# % user time - the actual metric, which was sampled
	@{
		values=@($Sample.CookedValue);
		dstypes=@("gauge"); # All measurements are gauges at the moment
		dsnames=@("");
		time=$Time;
		interval=$Interval;
		host=$TheHostname;
		plugin=$category
		plugin_instance=$Sample.InstanceName;
		type=$counter;
		type_instance=""
	}
}

Write-Output $args # Dumps the inputs for validation

Get-Counter -Counter @($args) -SampleInterval $Interval -Continuous |
	%{ 
		$time = Current-UnixTime
		@{
			Payload=@($_.CounterSamples | % { Generate-Measurement $_ $time })
		}
	} |
	% {ConvertTo-Json -InputObject $_.Payload -Compress} |
	% { Invoke-RestMethod $Url -Body "$_" -Method Post -ContentType application/json -Credential $Credentials -DisableKeepAlive }
