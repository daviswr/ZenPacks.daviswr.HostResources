# ZenPacks.daviswr.HostResources
ZenPack to monitor memory, swap, and processor utilization using HOST-RESOURCES-MIB, including CPU core components modeled by zenoss.snmp.CpuMap.

UCD-SNMP-MIB is likely a better source for memory and CPU utilization, but Windows and many Linux-based appliances lack support for it, so information in HOST-RESOURCES-MIB is a viable way to monitor basic health on those systems.

## Requirements
 * `snmpwalk` to be installed on the Zenoss collector and in the zenoss user's $PATH

## Limitations
 * Device-level datasources probably won't work on Zenoss 5+
 * SNMPv3 isn't currently supported for the device-level datasources
 * SNMPv1 or v2c usage for said datasources is currently determined by `defversion` in `snmp.conf` on the collector
 * These limitations will probably be resolved when the collection shell scripts are rewritten as PythonCollector datasources.

## Usage
I'm not going to make any assumptions about your device class organization, so it's up to you to apply the `zenoss.snmp.CpuMap` modeler and bind the `Host Resources CPU` & `Host Resources Memory` templates to the appropriate class or device.
