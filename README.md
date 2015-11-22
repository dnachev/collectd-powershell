# collectd-powershell
PowerShell script to publish metrics using the write_http format

## Disclaimer
The script has been tested on only one Windows 7 instance, no promises it is made, it will work on another instance.

## Features
* Continously monitors specified Windows performance counters and send updates to HTTP server using the collectd [write_http format](https://collectd.org/wiki/index.php/Plugin:Write_HTTP#Example_data).

## Installation
* Make sure [PowerShell 4](https://www.microsoft.com/en-us/download/details.aspx?id=40855) is available on the system.
* Download and run as any other PowerShell script

## Usage
The script accepts the following named parameters:
* `-User` - username to be used when sending statistics
* `-Token` - password to be used when sending statistics
* `-Url` - the HTTP URL to send the statistics to
* `-Interval` - the sampling interval to be used

All other parameters passed to the script are considered to be the paths (names) of the performance counters. Their naming is not quite straight-forward, but they can be viewed in Windows Performance Monitor. Alternatively, PowerShell function [`Get-Counter`](https://technet.microsoft.com/en-us/library/hh849685.aspx) to get list all available counters.

Here is an example command to execute the script:

    ./Collect-Metrics `
   	    -User "me@acme.com" `
	    -Token password `
	    -Url https://collectd.librato.com/v1/measurements `
	    -Interval 60 `
    	"\Processor Information(_Total)\% Idle Time"`
	    "\Processor Information(_Total)\% Interrupt Time"`
	    "\Processor Information(_Total)\% Privileged Time"`
	    "\Processor Information(_Total)\% User Time"`
	    "\Memory\Available Bytes"`
	    "\Memory\Page Faults/sec"`
	    "\PhysicalDisk(1 C:)\Avg. Disk sec/Read"`
	    "\PhysicalDisk(1 C:)\Avg. Disk sec/Write"`
    	"\PhysicalDisk(1 C:)\Disk Read Bytes/sec"`
	    "\PhysicalDisk(1 C:)\Disk Write Bytes/sec"`
	    "\LogicalDisk(C:)\% Free Space"`
	    "\Network Interface(Realtek PCIe GBE Family Controller)\Packets Received/sec"`
	    "\Network Interface(Realtek PCIe GBE Family Controller)\Packets Sent/sec"`
	    "\Network Interface(Realtek PCIe GBE Family Controller)\Bytes Received/sec"`
	    "\Network Interface(Realtek PCIe GBE Family Controller)\Bytes Sent/sec"`

The command will send statistics about CPU usage, basic memory statistics, disk access times and read/write speed and the network packets and bytes.
