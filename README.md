# Name

High-performance IP address matching with prefix-trie for OpenResty Lua.
support longest prefix match

# Table of Contents

- [Name](#name)
- [Table of Contents](#table-of-contents)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [ipmatcher.new](#ipmatchernew)
    - [Usage](#usage)
    - [Example](#example)
  - [ipmatcher.insert\_ipv4\_host](#ipmatcherinsert_ipv4_host)
    - [Usage](#usage-1)
    - [Example](#example-1)
  - [ipmatcher.insert\_ipv4\_with\_mask](#ipmatcherinsert_ipv4_with_mask)
    - [Usage](#usage-2)
    - [Example](#example-2)
  - [ipmatcher:match\_ipv4](#ipmatchermatch_ipv4)
    - [Usage](#usage-3)
    - [Example](#example-3)
  - [ipmatcher:remove\_host](#ipmatcherremove_host)
    - [Usage](#usage-4)
    - [Example](#example-4)
  - [ipmatcher:remove\_ipv4\_with\_mask](#ipmatcherremove_ipv4_with_mask)
    - [Usage](#usage-5)
    - [Example](#example-5)
- [Installation](#installation)
  - [From LuaRocks](#from-luarocks)
  - [From Source](#from-source)

# Synopsis

```lua
location / {
    content_by_lua_block {
            local ipmatcher = require "resty.ipmatcher"
            local m = ipmatcher.new()
            m:insert_ipv4_with_mask("192.168.3.1/24", 1)
            m:remove_ipv4_with_mask("192.168.3.1/24")
            local a = m:match_ipv4("192.168.3.1")
            ngx.say(a)
    }
}
```

[Back to TOC](#table-of-contents)

# Methods

## ipmatcher.new

Creates a new hash table to store IP addresses.

### Usage

```lua
ok = ipmatcher.new()
```

### Example

```lua
local ip= ipmatcher.new()
```

[Back to TOC](#table-of-contents)

## ipmatcher.insert_ipv4_host

add a host ipv4 to prefix-trie

### Usage
ip is a ipv4 address such as '192.168.1.1'
action is a number, such as 1 'allow' or 'deny' 2
delay is a number of automatic aging, default is 0 whichmeans never auto-aging

```lua
ipmatcher.insert_ipv4_host(ip, action, delay)
```

### Example

```lua
local ip = ipmatcher.new()
ip:insert_ipv4_host("192.168.3.1", 1, 1)

```

[Back to TOC](#table-of-contents)

## ipmatcher.insert_ipv4_with_mask

add a CIDR into a prefix-trie

### Usage
ip is a CIDR address such as '192.168.1.0/24'
action is a number, such as 1 'allow' or 'deny' 2
delay is a number of automatic aging, default is 0 whichmeans never auto-aging

```lua
ipmatcher.insert_ipv4_with_mask(ip, action, delay)
```

### Example

```lua
local ip = ipmatcher.new()
ip:insert_ipv4_with_mask("192.168.3.0/24", 1, 1)

```

[Back to TOC](#table-of-contents)


## ipmatcher:match_ipv4
check whether a ipv4 address matches a prefix-trie

### Usage
ip is a host ipv4, "192.168.3.1"

```lua
local res = ipmatcher.match_ipv4(ip)
```
return action of the ip.

### Example

```lua
local ip = ipmatcher.new()
ip:insert_ipv4_with_mask("192.168.3.0/24", 1, 1)
local res = ipmatcher.match_ipv4('192.168.3.1')
local res = ipmatcher.match_ipv4('192.168.3.2')

```
[Back to TOC](#table-of-contents)


## ipmatcher:remove_host
remove a ipv4 host from the prefix-trie

### Usage
ip is a host ipv4, "192.168.3.1"

```lua
local res = ipmatcher.remove_host(ip)
```

### Example

```lua
local ip = ipmatcher.new()
ip:insert_ipv4_host("192.168.3.1", 1, 1)
ip:remove_host("192.168.3.1")

```

[Back to TOC](#table-of-contents)

## ipmatcher:remove_ipv4_with_mask
remove a CIDR from the prefix-trie

### Usage
ip is a CIDR ipv4, "192.168.3.1/24"

```lua
local res = ipmatcher.remove_ipv4_with_mask(ip)
```

### Example

```lua
local ip = ipmatcher.new()
ip:insert_ipv4_with_mask("192.168.3.0/24", 1, 1)
ip:remove_ipv4_with_mask("192.168.3.0/24")

```

[Back to TOC](#table-of-contents)

# Installation
you need besure installed the rust stable version before compile the lua-resty-ipmatcher2

## From LuaRocks

```shell
luarocks install lua-resty-ipmatcher2
```

## From Source

```shell
make install
```

[Back to TOC](#table-of-contents)
