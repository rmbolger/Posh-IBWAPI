title: Definitive REST examples

# Background

This page will attempt to be a ported version of a now archived [Infoblox community](https://community.infoblox.com) post called "The definitive list of REST examples" using Posh-IBWAPI functions.

All examples assume you have already configured common connection settings with `Set-IBConfig`. If you're still using the default self-signed Infoblox certificates, don't forget to include `-SkipCertificateCheck`. For example:

```powershell
Set-IBConfig -ProfileName mygrid -host gridmaster.test.com -ver latest -cred (Get-Credential) -SkipCertificateCheck
```

Functions generally output zero or more `PSCustomObject` objects natively parsed from the WAPI's JSON output or raw object reference strings. While trying the examples on your own, it can be helpful to convert your own result objects to JSON for better readability. For example:

```powershell
$hosts = Get-IBObject -type record:host
# output the first host result as JSON
$hosts[0] | ConvertTo-Json -Depth 5
```

# The definitive list of REST examples

A common question we are asked is "Do you have some examples of specific REST calls", or "How can I get started with testing the WAPI?".
 
The API docs are good if you need the technical details, but this post hopes to address the overall fundamentals.
 
## The Basics
- use `Get-IBObject` to get/search
- use `New-IBObject` to add
- use `Set-IBObject` to modify
- use `Remove-IBObject` to remove

If you want to modify an object, you have to use a `Get-IBObject` to read it first. This will give you the `_ref` *(among other base fields)*, which you will need in order to update that object.

```powershell
# Get a specific host by name (case-insensitive)
$testhost = Get-IBObject -type record:host -filters 'name:=test_host.test.com'

# $testhost looks like the following when converted to JSON
{
    "_ref":  "record:host/ZG5zLmhvc3QkLjEubmV0LmR2b2x2ZS5leHRucw:test_host.test.com/default",
    "ipv4addrs":  [
                      {
                          "_ref":  "record:host_ipv4addr/ZG5zLmhvc3RfYWRkcmVzcyQuMS5uZXQuZHZvbHZlLmV4dG5zLjEwLjE3LjYuNC4:192.168.0.1/test_host.test.com/default",
                          "configure_for_dhcp":  false,
                          "host":  "test_host.test.com",
                          "ipv4addr":  "1.1.1.1"
                      }
                  ],
    "name":  "test_host.test.com",
    "view":  "default"
}
```

!!! note
    You can use `-ReturnAllFields` to return all available data for a given object type. This flag requires WAPI version 1.7.5+ because it involves extra queries to the schema under the hood. Thus, it is also less performant than a normal query because of the extra roundtrips to the server. If you know the fields you want, it is better to use `-ReturnFields 'field1','field2','fieldX'`. Using `-ReturnFields` will prevent the base fields from being returned unless you explicitly include them or also use `-ReturnBaseFields`.

There are two different ways to modify the host you just queried. They involve slightly different ways of calling `Set-IBObject`. The easiest, particularly if you're making the same change to multiple objects, is usually to just pipe the variable to `Set-IBObject` and provide a template for the changes with `-TemplateObject`. This works because `Set-IBObject` knows how to pull the `_ref` field out of the pipelined object and use it for `-ObjectRef`:

```powershell
# create a template to change the IP address
$template = @{ipv4addrs=@(@{ipv4addr='1.1.1.2'})}

# save the change
$testhost | Set-IBObject -template $template

# this also works when you only have a copy of the _ref string
Set-IBObject -ref 'record:host/ZG5zLmhvc3QkLjEubmV0LmR2b2x2ZS5' -template $template
```

The second way involves modifying the variable and then piping it to `Set-IBObject` by itself. This has a tendency to be more difficult because read-only fields in the original variable need to be removed or an error will be thrown. It can also be more tedious to add fields if the original variable doesn't contain the fields you want to edit. However, this way can also be easier if you're changing many objects in a more algorithmic way; such as modifying a set of hostnames using string replacement.

```powershell
# remove the read-only 'host' field from the nested 'record:host_ipv4addr' object
$testhost.ipv4addrs[0].PSObject.Properties.Remove('host')

# change the IP address
$testhost.ipv4addrs[0].ipv4addr = '1.1.1.2'

# add a comment
$testhost | Add-Member @{comment='my test host'}

# save the change
$testhost | Set-IBObject
```

## Search for HOST by name

```powershell
# case-sensitive exact match using '='
Get-IBObject -type record:host -filters 'name=my.fqdn.org'

# case-insensitive exact match using ':=' (Requires WAPI 1.4+)
Get-IBObject -type record:host -filters 'name:=my.fqdn.org'

# case-sensitive Regex partial match using '~='
Get-IBObject -type record:host -filters 'name~=my'

# case-insensitive Regex partial match using ':~=' (Requires WAPI 1.4+)
Get-IBObject -type record:host -filters 'name:~=my'
```

## Search for FixedAddress by MAC

```powershell
# return base fields + mac
Get-IBObject -type fixedaddress -filters 'mac=aa:bb:cc:11:22:33' -fields 'mac' -base
```

## Search for objects associated with a specific IP address

```powershell
$ipObj = Get-IBObject -type ipv4address -filters 'status=USED','ip_address=1.1.1.1'

# the object references are stored in the 'objects' field, but we can
# also query for additional information
$ipObj | select -expand objects | Get-IBObject

# just list the names associated with that IP
$ipObj | select -expand names
```

## Add a HOST

```powershell
# build the host variable
$newhost = @{ name='wapi.test.org'; ipv4addrs=@( @{ ipv4addr='1.1.1.21' } ) }

# Note: `configure_for_dns` defaults to $true which means the 'test.org' DNS zone for
# this host must be managed by Infoblox for the call to succeed. Otherwise, you must
# set configure_for_dns=$false in the host variable.

# Note: the network containing the specified IP must also be managed by Infoblox for 
# the call to succeed.

# create the host
$newhost | New-IBObject -type record:host
```

## Delete a HOST

```powershell
# search for the host we want to delete
$delHost = Get-IBObject -type record:host -filters 'name=wapi.test.org'

# delete it
$delHost | Remove-IBObject

# or delete it directly using an already known object reference
Remove-IBOBject -ref 'record:host/ZG5zLmhvc3QkLm5vbl9ETlNfaG'
```

## Update a host, or change the IP address

(See the examples in [The Basics](#the-basics))

## Add/Remove IP addresses from a host without altering the original list

```powershell
# add with `ipv4addrs+` in your change template
$template = @{ 'ipv4addrs+' = @( @{ ipv4addr='2.2.2.22' }, @{ ipv4addr='4.4.4.24' } ) }

# save the change using a known object reference
Set-IBObject -ref 'record:host/ZG5zLmhvc3QkLl9kZWZhdWx0Lm9yZy5naC' -template $template

# remove with `ipv4addrs-' in your change template
$template = @{ 'ipv4addrs-' = @( @{ ipv4addr='2.2.2.22' } ) }

# save the change using an existing $myhost variable returned by Get-IBObject
$myhost | Set-IBObject -template $template
```

## Add a HOST with next_available IP address from a network

```powershell
# create the host variable
$newhost = @{ name='wapi.test.org'; ipv4addrs=@( @{} ) }
$newhost.ipv4addrs[0].ipv4addr = 'func:nextavailableip:10.1.1.0/24'

# 'func:' syntax also supports these forms:
# func:nextavailableip:network/ZG54dfgsrDFEFfsfsLzA:10.0.0.0/8/default
# func:nextavailableip:10.0.0.0/8
# func:nextavailableip:10.0.0.0/8,external
# func:nextavailableip:10.0.0.3-10.0.0.10

# OR you can use the longhand form
$newhost = @{ name='wapi.test.org'; ipv4addrs=@( @{ ipv4addr=@{} } ) }
$newhost.ipv4addrs[0].ipv4addr._function = 'next_available_ip'
$newhost.ipv4addrs[0].ipv4addr._object_field = 'value'
$newhost.ipv4addrs[0].ipv4addr._object = '10.1.1.0/24'
$newhost.ipv4addrs[0].ipv4addr._parameters = @{ num=1; exclude=@('10.1.1.50','10.1.1.60') }

# create the host
$newhost | New-IBObject -type record:host
```

## Add a HOST with next_available IP address from a network using a complex search (e.g Extensible Attributes)

```powershell
# This is similar to the previous example using longhand form
# But you need to pass the search criteria in the `_object_parameters` field
# Note also that `_object` changes from a reference to a type
$newhost = @{ name='wapi.test.org'; ipv4addrs=@( @{ ipv4addr=@{} } ) }
$newhost.ipv4addrs[0].ipv4addr._function = 'next_available_ip'
$newhost.ipv4addrs[0].ipv4addr._object_field = 'value'
$newhost.ipv4addrs[0].ipv4addr._object = 'network'
$newhost.ipv4addrs[0].ipv4addr._object_parameters = @{ '*Site'='Santa Clara' }
$newhost.ipv4addrs[0].ipv4addr._parameters = @{ num=1; exclude=@('10.1.1.50','10.1.1.60') }

# create the host
$newhost | New-IBObject -type record:host
```

## Add a HOST with a fixed address

```powershell
# basically the same as adding a normal host, but include a mac address
$newhost = @{ name='wapi.test.org'; ipv4addrs=@( @{} ) }
$newhost.ipv4addrs[0].ipv4addr = '1.1.1.21'
$newhost.ipv4addrs[0].mac = 'aa:bb:cc:11:22:21'

# create the host
$newhost | New-IBObject -type record:host
```

## Add a Fixed address

```powershell
New-IBObject -type fixedaddress -IBObject @{ipv4addr='1.1.1.21';mac='aa:bb:cc:11:22:21'}
```

## Add a Fixed address Reservation

```powershell
New-IBObject -type fixedaddress -IBObject @{ipv4addr='1.1.1.21';mac='00:00:00:00:00:00'}
```

## Search for a subnet

```powershell
$subnet = Get-IBObject -type network -filters 'network=1.1.1.0/24'
```

## Get Next Available address from a subnet

```powershell
# using the $subnet variable returned from Get-IBObject
$subnet | Invoke-IBFunction -name 'next_available_ip' -args @{num=1}

# and if you just want the raw values
$subnet | Invoke-IBFunction -name 'next_available_ip' -args @{num=1} | Select -expand ips
```

## Get the next 5 IP addresses

```powershell
# using the $subnet variable returned from Get-IBObject
$subnet | Invoke-IBFunction -name 'next_available_ip' -args @{num=5}

# and if you just want the raw values
$subnet | Invoke-IBFunction -name 'next_available_ip' -args @{num=5} | Select -expand ips
```

## Get all the addresses (and records) in a subnet

```powershell
Get-IBObject -type ipv4address -filters 'network=1.1.1.0/24'
```

## Get all the IP addresses in a given range

```powershell
Get-IBObject -type ipv4address -filters 'ip_address>=1.1.1.1','ip_address<=1.1.1.10'
```

## Search for HOSTS by Extensible Attribute

```powershell
# when filtering on EA, prepend '*' to the front of the EA name
Get-IBObject -type record:host -filters '*Floor=3rd' -fields 'extattrs'
```

## Add extensible Attributes to an object

```powershell
# using a $myhost variable returned by Get-IBObject
$myhost | Set-IBObject -template @{extattrs=@{Site=@{value='East'}}}

# combine with the previous example to change all hosts on the
# 3rd Floor to the 5th Floor
Get-IBObject -type record:host -filters '*Floor=3rd' | 
  Set-IBObject -template @{extattrs=@{Floor=@{value='5th'}}}
```

## Add a value to a "List" type Extensible Attribute 

```powershell
# get the existing definition
$listdef = Get-IBObject -type extensibleattributedef -Filters 'name=MyList' -Fields 'list_values'

# add a new item to the list
$listdef.list_values += @{value='NewValue'}

# write the updated object back to Infoblox
$listdef | Set-IBObject
```

## Add a HOST with aliases

```powershell
# build the host variable
$newhost = @{ name='wapialiased.test.org'; ipv4addrs=@( @{ ipv4addr='1.1.1.21' } ) }
$newhost.aliases = @('remote','pointer')

# create the host
$newhost | New-IBObject -type record:host
```

## Get all the aliases on a host

```powershell
Get-IBObject -type record:host -filters 'name=wapialiased.test.org' -fields 'aliases' -base
```

## Remove or modify aliases from a host

```powershell
# using a $myhost variable returned by Get-IBObject

# remove all existing aliases by sending an empty list
$myhost | Set-IBObject -template @{aliases=@()}

# or modify by sending a new list
$myhost | Set-IBObject -template @{aliases=@('remote2')}
```

## Add a CNAME

```powershell
$cname = @{name='cname.test.org';canonical='wapi.test.org'}
New-IBObject -type record:cname -IBObject $cname
```

## DELETE a CNAME

```powershell
# get a reference to the existing object
$myCname = Get-IBObject -type record:cname -filters 'name=cname.test.org'

# delete it
$myCname | Remove-IBObject
```

## Move a CNAME to point to a new canonical

```powershell
# get a reference to the existing object
$myCname = Get-IBObject -type record:cname -filters 'name=cname.test.org'

# set a new canonical
$myCname | Set-IBObject -template @{canonical='wapi-new.test.org'}
```

## Add a network or a container

```powershell
# NIOS will auto create the container if it needs to
New-IBObject -type network -IBObject @{network='45.0.45.0/24'}
```

## Add a network and assign to a member

```powershell
# build the network variable
$newNet = @{network='45.0.46.0/24'; members=@()}
$newNet.members += @{'_struct'='dhcpmember'; ipv4addr='192.168.1.3'}


# create the network
$newNet | New-IBObject -type network
```

## Add a DHCP range

```powershell
# build the range variable
$newRange = @{ start_addr='45.0.46.20'; end_addr='45.0.46.101' }
$newRange.server_association_type = 'MEMBER'
$newRange.member = @{ '_struct'='dhcpmember'; ipv4addr='192.168.1.3' }

# create the range
$newRange | New-IBObject -type range
```

## Add a DHCP reserved range

```powershell
# If you don't assign a member, the range just gets created as 'reserved'
New-IBObject -type range -IBObject @{ start_addr='45.0.46.20'; end_addr='45.0.46.101' }
```

## Add a zone association to a network

```powershell
# create a template object
$zoneAssoc = @{ zone_associations=@() }
$zoneAssoc.zone_associations += @{ fqdn='test.org'; is_default=$true }

# assuming you have the network object reference string already
Set-IBObject -ref 'network/ZG5zLm5l...' -template $zoneAssoc
```

## List the zone_associations on a network

```powershell
# assuming you have the network object reference string already
Get-IBObject -ref 'network/ZG5zLm5l...' -fields 'zone_associations' -base

# or not
Get-IBObject -type network -filters 'network=45.0.46.0/24' -fields 'zone_associations' -base
```

## Add a zone, of type forward

`forwarding_servers` are the grid members that will forward for that zone

```powershell
# build the zone variable
$fwdZone = @{ fqdn='foo.com'; forward_to=@(); forwarding_servers=@() }
$fwdZone.forward_to += @{ address='1.1.1.1'; name='ns.foo.com' }
$fwdZone.forward_to += @{ address='1.1.1.2'; name='ns2.foo.com' }
$fwdZone.forwarding_servers += @{ name='infoblox2.localdomain' }
$fwdZone.forwarding_servers += @{ name='infoblox1.localdomain' }

# create the zone
$fwdZone | New-IBObject -type zone_forward
```

## Get "restart status" of grid services

```powershell
# First make a function call to 'refresh the restartservicestatus object'
# (this doesn't return any data)
Get-IBObject -type grid | 
    Invoke-IBFunction -name requestrestartservicestatus -args @{service_option='ALL'}

# Now get the updated restartservicestatus object
# If the status for things is REQUESTING, wait a few seconds and try again
Get-IBObject -type restartservicestatus
```

## Restart services

```powershell
$restartArgs = @{member_order='SIMULTANEOUSLY';service_option='ALL'}
Get-IBObject -type grid | Invoke-IBFunction -name restartservices -args $restartArgs
```

## Export a database

In Posh-IBWAPI 2.x or later:

```powershell
Receive-IBFile -FunctionName getgriddata -OutFile .\backup.tar.gz -FunctionArgs @{type='BACKUP'}
```

In Posh-IBWAPI 1.x:

```powershell
# request a download token and URL
$dl = Invoke-IBFunction -ref fileop -name getgriddata -args @{type='BACKUP'}

# download the file
Invoke-IBWAPI -Uri $dl.url -ContentType 'application/force-download' `
              -Credential (Get-IBConfig).Credential `
              -OutFile .\backup.tar.gz

# inform Infoblox that the download is complete
Invoke-IBFunction -ref fileop -name downloadcomplete -args @{token=$dl.token}
```

## Export a CSV file

In Posh-IBWAPI 2.x or later:

```powershell
Receive-IBFile -FunctionName csv_export -OutFile .\hosts.csv -FunctionArgs @{_object='record:host'}
```

In Posh-IBWAPI 1.x:

```powershell
# request a download token and URL
$dl = Invoke-IBFunction -ref fileop -name csv_export -args @{_object='record:host'}

# download the file
Invoke-IBWAPI -Uri $dl.url -ContentType 'application/force-download' `
              -Credential (Get-IBConfig).Credential `
              -OutFile .\hosts.csv

# inform Infoblox that the download is complete
Invoke-IBFunction -ref fileop -name downloadcomplete -args @{token=$dl.token}
```

## Export the results of a WAPI call

And save the data to disk. (Yes, you can cache results)

```powershell
# build the args object
$funcArgs = @{ _encoding='JSON'; _filename='allhosts.corp.org.json';
               _object='record:host'; _return_fields='name,extattrs';
               zone='corp.org' }

# call the function
Invoke-IBFunction -ref fileop -name read -args $funcArgs

# The file will be in a folder 'wapi_output' in the HTTP file distribution
```
