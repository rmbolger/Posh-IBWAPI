title: Using Get-IBSchema

# Using Get-IBSchema

In WAPI 1.7.5 (NIOS 6.12), Infoblox added a `_schema` option to GET queries that will ignore most of the normal options and return a JSON view of the object model for the object type specified. This was presumably so that one could programmatically discover the WAPI object model without necessarily needing to look at the full HTML or PDF documentation. In WAPI 2.0 (NIOS 6.12 and 7.0), they expanded on the schema querying functionality by adding more metadata to the object model and a `_get_doc` option that returned human readable text descriptions. It feels like they're trying to slowly move towards feature parity with the full HTML/PDF documentation which will be awesome if/when they get there.

The goal of `Get-IBSchema` is to provide a `Get-Help` style view of the WAPI object model so that you don't necessarily have to continually reference the full documentation as you are developing your code. Some of the WAPI objects have fairly large object models and the full output can be pretty dense and long. So there are a lot of parameters that can help filter the output to only what you want to see.

!!! note
    Most of the examples below will be queried from a WAPI 2.0+ appliance. They should work the same way against 1.7.5, but there might be less data returned.

## The Basics

`Get-IBSchema` uses the same common connection settings as other *-IBObject queries including values saved with `Set-IBConfig`. It's important to note that the WAPI will return a view of the schema that is filtered for the WAPI version you request. So if your WAPI version is 2.x and your requested version is 1.5, you'll get the schema that existed in WAPI 1.5. This is cool because you can do schema queries for WAPI versions that didn't originally support schema queries.

Calling `Get-IBSchema` with no parameters or only a `-WAPIVersion` will return the base schema which includes the list of supported versions and the list of supported objects. For example:

```
PS C:\> Get-IBSchema -version 1.5

Requested Version: 1.5

Supported Versions:

1.0                          1.5                          1.7.5                        2.3
1.1                          1.6                          2.0                          2.3.1
1.2                          1.6.1                        2.1                          2.4
1.2.1                        1.7                          2.1.1                        2.5
1.3                          1.7.1                        2.1.2                        2.6
1.4                          1.7.2                        2.2                          2.6.1
1.4.1                        1.7.3                        2.2.1                        2.7
1.4.2                        1.7.4                        2.2.2

Supported Objects:

allrecords                   ipv6networkcontainer         record:cname                 sharedrecord:a
csvimporttask                ipv6range                    record:host                  sharedrecord:aaaa
discovery:device             ipv6sharednetwork            record:host_ipv4addr         sharedrecord:mx
discovery:deviceinterface    lease                        record:host_ipv6addr         sharedrecord:srv
discovery:deviceneighbor     macfilteraddress             record:mx                    sharedrecord:txt
discovery:status             member                       record:naptr                 snmpuser
fileop                       namedacl                     record:ptr                   view
fixedaddress                 network                      record:srv                   zone_auth
grid                         networkcontainer             record:txt                   zone_delegated
grid:dhcpproperties          networkview                  restartservicestatus         zone_forward
ipv4address                  permission                   roaminghost                  zone_stub
ipv6address                  range                        scheduledtask
ipv6fixedaddress             record:a                     search
ipv6network                  record:aaaa                  sharednetwork
```

To get the specifics for a particular object, add it with the `-ObjectType` parameter. The "RESTRICTIONS" section are the operations not supported by this object. Some objects may also have a "CLOUD RESTRICTIONS" section that has the operations not supported when querying via a cloud appliance.

Without any additional parameters, the fields are displayed in a table format similar to the "Fields List" section from the full docs. The TYPE column shows the data type of that field and whether it is an array or not indicated by `[]` after the type name. The SUPPORTS column indicates what operations are allowed for each field *(R = Read/Get, W = Write/Create, U = Update/Modify, D = Delete, S = Search)*. The BASE column indicates whether the field is returned by default as part of the base object. The SEARCH column indicates what types of searches are allowed against that field *(case-insensitive, regex, greater than, etc)*. If the object has functions associated with it, those are displayed in a separate section below the fields table.

```
PS C:\> Get-IBSchema member

OBJECT
    member (WAPI 2.7)

RESTRICTIONS
    scheduling, csv

FIELD                              TYPE                         SUPPORTS BASE SEARCH
-----                              ----                         -------- ---- ------
active_position                    string                       R
additional_ip_list                 interface[]                  RWU
bgp_as                             bgpas[]                      RWU
comment                            string                       RWU S         :=~
config_addr_type                   enum                         RWU S    X    =
dns_resolver_setting               setting:dnsresolver          RWU
dscp                               uint                         RWU
email_setting                      setting:email                RWU
enable_ha                          bool                         RWU S         =
enable_lom                         bool                         RWU
enable_member_redirect             bool                         RWU
enable_ro_api_access               bool                         RWU S         =
extattrs                           extattr                      RWU
external_syslog_backup_servers     extsyslogbackupserver[]      RWU
external_syslog_server_enable      bool                         RWU
host_name                          string                       RWU S    X    :=~
ipv4_address                       string                           S         =
ipv6_address                       string                           S         =
ipv6_setting                       ipv6setting                  RWU
ipv6_static_routes                 ipv6setting[]                RWU
is_dscp_capable                    bool                         R
lan2_enabled                       bool                         RWU
lan2_port_setting                  lan2portsetting              RWU
lcd_input                          bool                         RWU
lom_network_config                 lomnetworkconfig[]           RWU
lom_users                          lomuser[]                    RWU
master_candidate                   bool                         RWU S         =
member_service_communication       memberservicecommunication[] RWU
mgmt_port_setting                  mgmtportsetting              RWU
mmdb_ea_build_time                 timestamp                    R
mmdb_geoip_build_time              timestamp                    R
nat_setting                        natsetting                   RWU
node_info                          nodeinfo[]                   RWU
ntp_setting                        member:ntp                   RWU
ospf_list                          ospf[]                       RWU
passive_ha_arp_enabled             bool                         RWU
platform                           enum                         RWU S    X    =
pre_provisioning                   preprovision                 RWU
preserve_if_owns_delegation        bool                         RWU S         =
remote_console_access_enable       bool                         RWU
router_id                          uint                         RWU S         =
service_status                     memberservicestatus[]        R
service_type_configuration         enum                         RWU S    X    =
snmp_setting                       setting:snmp                 RWU
static_routes                      setting:network[]            RWU
support_access_enable              bool                         RWU
support_access_info                string                       R
syslog_proxy_setting               setting:syslogproxy          RWU
syslog_servers                     syslogserver[]               RWU
syslog_size                        uint                         RWU
threshold_traps                    thresholdtrap[]              RWU
time_zone                          string                       RWU
trap_notifications                 trapnotification[]           RWU
upgrade_group                      string                       RWU
use_dns_resolver_setting           bool                         RWU
use_dscp                           bool                         RWU
use_email_setting                  bool                         RWU
use_enable_lom                     bool                         RWU
use_enable_member_redirect         bool                         RWU
use_external_syslog_backup_servers bool                         RWU
use_lcd_input                      bool                         RWU
use_remote_console_access_enable   bool                         RWU
use_snmp_setting                   bool                         RWU
use_support_access_enable          bool                         RWU
use_syslog_proxy_setting           bool                         RWU
use_threshold_traps                bool                         RWU
use_time_zone                      bool                         RWU
use_trap_notifications             bool                         RWU
use_v4_vrrp                        bool                         RWU
vip_setting                        setting:network              RWU
vpn_mtu                            uint                         RWU

FUNCTIONS
    capture_traffic_control(action, interface, seconds_to_run)
    capture_traffic_status() => status, file_exists, file_size
    create_token() => pnode_tokens
    member_admin_operation(operation)
    read_token() => pnode_tokens
    requestrestartservicestatus(service_option)
    restartservices(restart_option, service_option)
```

## Filtering Results

The full output of some objects can be pretty long and while you could just pipe the output to `more` to get a paged view, you can also use `-Fields`, `-NoFields`, `-Operations`, `-Functions`, and `-NoFunctions` to limit the output.

`-Fields` takes a string array (optionally with wildcards) and filters the field list to only those fields that match at least one of the strings. So if you wanted to filter IP and NAT related fields on the `member` example above, you could do this:

```
PS C:\> Get-IBSchema member -Fields ip*,nat*

OBJECT
    member (WAPI 2.7)

RESTRICTIONS
    scheduling, csv

FIELD              TYPE          SUPPORTS BASE SEARCH
-----              ----          -------- ---- ------
ipv4_address       string            S         =
ipv6_address       string            S         =
ipv6_setting       ipv6setting   RWU
ipv6_static_routes ipv6setting[] RWU
nat_setting        natsetting    RWU

FUNCTIONS
    capture_traffic_control(action, interface, seconds_to_run)
    capture_traffic_status() => status, file_exists, file_size
    create_token() => pnode_tokens
    member_admin_operation(operation)
    read_token() => pnode_tokens
    requestrestartservicestatus(service_option)
    restartservices(restart_option, service_option)
```

And if you wanted to exclude the functions from the output, just add the `-NoFunctions` switch:

```
PS C:\> Get-IBSchema member -Fields ip*,nat* -NoFunctions

OBJECT
    member (WAPI 2.7)

RESTRICTIONS
    scheduling, csv

FIELD              TYPE          SUPPORTS BASE SEARCH
-----              ----          -------- ---- ------
ipv4_address       string            S         =
ipv6_address       string            S         =
ipv6_setting       ipv6setting   RWU
ipv6_static_routes ipv6setting[] RWU
nat_setting        natsetting    RWU
```

`-Operations` is used to filter fields by the operations they support in the SUPPORTS column. It also takes a string array (no wildcards) comprised of letter codes you want to limit the results to. So if you only wanted to return the fields that are searchable, you could do this:

```
PS C:\> Get-IBSchema member -Operations s -NoFunctions

OBJECT
    member (WAPI 2.7)

RESTRICTIONS
    scheduling, csv

FIELD                       TYPE     SUPPORTS BASE SEARCH
-----                       ----     -------- ---- ------
comment                     string   RWU S         :=~
config_addr_type            enum     RWU S    X    =
enable_ha                   bool     RWU S         =
enable_ro_api_access        bool     RWU S         =
host_name                   string   RWU S    X    :=~
ipv4_address                string       S         =
ipv6_address                string       S         =
master_candidate            bool     RWU S         =
platform                    enum     RWU S    X    =
preserve_if_owns_delegation bool     RWU S         =
router_id                   uint     RWU S         =
service_type_configuration  enum     RWU S    X    =
```

If you're done checking field details and want to know about specific functions, `-Functions` works the same way as `-Fields` and `-NoFields` works the same way as `-NoFunctions`. So let's say you want to see the traffic capture related functions for `member`, you could do something like this:

```
PS C:\> Get-IBSchema member -Functions capture* -NoFields

OBJECT
    member (WAPI 2.7)

RESTRICTIONS
    scheduling, csv

FUNCTIONS
    capture_traffic_control(action, interface, seconds_to_run)
    capture_traffic_status() => status, file_exists, file_size
```

## Detailed View

The default view of fields and functions is intended to be a quick reference. But particularly for functions, sometimes you need more detail. For that, you can use the `-Detailed` switch:

```
PS C:\> Get-IBSchema member -Functions capture* -NoFields -Detailed

OBJECT
    member (WAPI 2.7)

RESTRICTIONS
    scheduling, csv

FUNCTIONS

    ----------------------------------------------------------
    capture_traffic_control
    ----------------------------------------------------------
        Starts/Stops a traffic capture session on the specified member node.

    INPUTS

        action <{ START | STOP }>
            The traffic capture action.

        interface <{ ALL | HA | LAN1 | LAN2 | MGMT }>
            The interface on which the traffic is captured.

        seconds_to_run <uint>
            The number of seconds for which the traffic capture is going to run.

    ----------------------------------------------------------
    capture_traffic_status
    ----------------------------------------------------------
        Gets traffic capture status on the specified member node.

    OUTPUTS

        status <{ STOPPED | RUNNING | UNKNOWN }>
            The status of the capture operation for the member.

        file_exists <bool>
            Determines if the capture file for the member exist or not.

        file_size <uint>
            The size of the traffic capture file for the member.
```

It can also help to get details for fields as well. Let's add the `-Detailed` flag to one of our previous examples:

```
PS C:\> Get-IBSchema member -Fields ip*,nat* -NoFunctions -Detailed
OBJECT
    member (WAPI 2.7)

RESTRICTIONS
    scheduling, csv

FIELDS
    ipv4_address <string>
        The member's IPv4 Address.

        Supports: Search

        This field is available for search via:
            '=' (exact equality)

    ipv6_address <string>
        The member's IPv6 Address.

        Supports: Search

        This field is available for search via:
            '=' (exact equality)

    ipv6_setting <ipv6setting>
        IPV6 setting for member.

        Supports: Read, Write, Update

    ipv6_static_routes <ipv6setting[]>
        List of IPv6 static routes.

        Supports: Read, Write, Update

    nat_setting <natsetting>
        NAT settings for the member.

        Supports: Read, Write, Update
```

## Raw Output and HTML Fallback

For whatever reason, you may want to just get the raw schema data back instead of a pretty printed view. In that case, use the `-Raw` switch. Filtering parameters are ignored when using `-Raw`.

```
PS C:\> Get-IBSchema member -Raw

cloud_additional_restrictions : {}
fields                        : {@{doc=The active server of a Grid member.; is_array=False; name=active_position;
                                standard_field=False; supports=r; type=System.Object[]}, @{doc=The additional IP list
                                of a Grid member. This list contains additional interface information that can be used
                                at the member level. Note that interface structure(s) with interface type set to
                                'MGMT' are not supported.; is_array=True; name=additional_ip_list; schema=;
                                standard_field=False; supports=rwu; type=System.Object[]; wapi_primitive=struct},
                                @{doc=The BGP configuration for anycast for a Grid member.; is_array=True;
                                name=bgp_as; schema=; standard_field=False; supports=rwu; type=System.Object[];
                                wapi_primitive=struct}, @{doc=Starts/Stops a traffic capture session on the specified
                                member node.; is_array=False; name=capture_traffic_control; schema=;
                                standard_field=False; supports=rwu; type=System.Object[]; wapi_primitive=funccall}...}
restrictions                  : {scheduling, csv}
schema_version                : 2
type                          : member
version                       : 2.7
wapi_primitive                : object
```

Until schema queries reach feature parity with the HTML docs, it may still occasionally be necessary to view the full HTML. In these cases, you can use `-LaunchHTML` as a shortcut to get to the specific object page you want to view. It will attempt to "start" the URL for that page which should open your default web browser to the location.

```
PS C:\> Get-IBSchema member -LaunchHTML

# (launches browser to https://<WAPIHost>/wapidoc/objects/member.html)
```
