local base         = require("resty.core.base")
local bit          = require("bit")
local clear_tab    = require("table.clear")
local nkeys        = require("table.nkeys")
local ipmatcher2   = require("resty.ipmatcher2.ipmatcher2")
local new_tab      = base.new_tab
local find_str     = string.find
local tonumber     = tonumber
local ipairs       = ipairs
local pairs        = pairs
local ffi          = require "ffi"
local ffi_cdef     = ffi.cdef
local ffi_copy     = ffi.copy
local ffi_new      = ffi.new
local C            = ffi.C
local insert_tab   = table.insert
local sort_tab     = table.sort
local string       = string
local setmetatable = setmetatable
local type         = type
local error        = error
local str_sub      = string.sub
local str_byte     = string.byte
local cur_level    = ngx.config.subsystem == "http" and
    require "ngx.errlog".get_sys_filter_level()

local AF_INET      = 2
local AF_INET6     = 10
if ffi.os == "OSX" then
    AF_INET6 = 30
elseif ffi.os == "BSD" then
    AF_INET6 = 28
elseif ffi.os == "Windows" then
    AF_INET6 = 23
end


local _M = { _VERSION = 0.3 }



ffi_cdef [[
    int inet_pton(int af, const char * restrict src, void * restrict dst);
    uint32_t ntohl(uint32_t netlong);
]]


local parse_ipv4
do
    local inet = ffi_new("unsigned int [1]")

    function parse_ipv4(ip)
        if not ip then
            return false
        end

        if C.inet_pton(AF_INET, ip, inet) ~= 1 then
            return false
        end

        return C.ntohl(inet[0])
    end
end
_M.parse_ipv4 = parse_ipv4

local parse_bin_ipv4
do
    local inet = ffi_new("unsigned int [1]")

    function parse_bin_ipv4(ip)
        if not ip or #ip ~= 4 then
            return false
        end

        ffi_copy(inet, ip, 4)
        return C.ntohl(inet[0])
    end
end

local parse_ipv6
do
    local inets = ffi_new("unsigned int [4]")

    function parse_ipv6(ip)
        if not ip then
            return false
        end

        if str_byte(ip, 1, 1) == str_byte('[')
            and str_byte(ip, #ip) == str_byte(']') then
            -- strip square brackets around IPv6 literal if present
            ip = str_sub(ip, 2, #ip - 1)
        end

        if C.inet_pton(AF_INET6, ip, inets) ~= 1 then
            return false
        end

        local inets_arr = new_tab(4, 0)
        for i = 0, 3 do
            insert_tab(inets_arr, C.ntohl(inets[i]))
        end
        return inets_arr
    end
end
_M.parse_ipv6 = parse_ipv6

local parse_bin_ipv6
do
    local inets = ffi_new("unsigned int [4]")

    function parse_bin_ipv6(ip)
        if not ip or #ip ~= 16 then
            return false
        end

        ffi_copy(inets, ip, 16)
        local inets_arr = new_tab(4, 0)
        for i = 0, 3 do
            insert_tab(inets_arr, C.ntohl(inets[i]))
        end
        return inets_arr
    end
end

local function gc_free(self)
    -- if ngx.worker.exiting() then
    --     return
    -- end
    ngx.log(ngx.ERR, "free")
    self:free()
end

local mt = { __index = _M, __gc = gc_free }


local ngx_log = ngx.log
local ngx_INFO = ngx.INFO
local function log_info(...)
    if cur_level and ngx_INFO > cur_level then
        return
    end

    return ngx_log(ngx_INFO, ...)
end


local function split_ip(ip_addr_org)
    local idx = find_str(ip_addr_org, "/", 1, true)
    if not idx then
        return ip_addr_org
    end

    local ip_addr = str_sub(ip_addr_org, 1, idx - 1)
    local ip_addr_mask = str_sub(ip_addr_org, idx + 1)
    return ip_addr, tonumber(ip_addr_mask)
end
_M.split_ip = split_ip


local idxs = {}
local function gen_ipv6_idxs(inets_ipv6, mask)
    clear_tab(idxs)

    for _, inet in ipairs(inets_ipv6) do
        local valid_mask = mask
        if valid_mask > 32 then
            valid_mask = 32
        end

        if valid_mask == 32 then
            insert_tab(idxs, inet)
        else
            insert_tab(idxs, bit.rshift(inet, 32 - valid_mask))
        end

        mask = mask - 32
        if mask <= 0 then
            break
        end
    end

    return idxs
end


local function cmp(x, y)
    return x > y
end


function _M.new()
    local self = {
        tree = ipmatcher2.new_prefix_trie()
    }
    return setmetatable(self, mt)
end

function _M.insert_ipv4_with_mask(self, ip, action)
    -- 该函数将一个CIDR格式的ipv4格式，插入到前缀树中，格式为"192.168.3.1/24", action 中，0代表什么都不做，1代表阻断，2代表白名单通过
    local prefix_trie = self.tree
    local net_addr, mask = split_ip(ip)
    -- 把网络地址(ipv4)转换成32uint数字
    local ipv4_bin_addr = parse_ipv4(net_addr)
    ipmatcher2.insert(prefix_trie, ipv4_bin_addr, mask, action)
end

function _M.insert_ipv4_host(self, ip, action)
    -- 该函数将一个主机ipv4地址，插入到前缀树中，格式为"192.168.3.1", action 中，0代表什么都不做，1代表阻断，2代表白名单通过
    return self:insert_ipv4_with_mask(ip .. "32", action)
end

function _M.remove_ipv4_with_mask(self, ip)
    -- 该函数将一个CIDR格式的ipv4，从前缀树中删除，格式为"192.168.3.1/24"
    local prefix_trie = self.tree
    local net_addr, mask = split_ip(ip)
    -- 把网络地址(ipv4)转换成32uint数字
    local ipv4_bin_addr = parse_ipv4(net_addr)
    ipmatcher2.remove(prefix_trie, ipv4_bin_addr, mask)
end

function _M.remove_host(self, ip)
    -- 该函数将一个主机的ipv4，从前缀树中删除，格式为"192.168.3.1/24"
    return self:remove_ipv4_with_mask(ip .. "32")
end

function _M.match_ipv4(self, ip)
    local prefix_trie = self.tree
    -- 把网络地址(ipv4)转换成32uint数字
    local ipv4_bin_addr = parse_ipv4(ip)
    -- 32位netmask，匹配主机
    local res = ipmatcher2.get(prefix_trie, ipv4_bin_addr, 32)
    return res
end

function _M.free(self)
    local prefix_trie = self.tree
    ipmatcher2.free(prefix_trie)
end

return _M
