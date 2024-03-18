local base        = require("resty.core.base")
local bit         = require("bit")
local clear_tab   = require("table.clear")
local nkeys       = require("table.nkeys")
local new_tab     = base.new_tab
local find_str    = string.find
local tonumber    = tonumber
local ipairs      = ipairs
local pairs       = pairs
local ffi         = require "ffi"
local ffi_cdef    = ffi.cdef
local ffi_copy    = ffi.copy
local ffi_new     = ffi.new
local C           = ffi.C
local string      = string
local setmetatable=setmetatable
local type        = type
local error       = error
local str_sub     = string.sub
local str_byte    = string.byte
local cur_level   = ngx.config.subsystem == "http" and
                    require "ngx.errlog" .get_sys_filter_level()

local AF_INET     = 2
local AF_INET6    = 10
if ffi.os == "OSX" then
    AF_INET6 = 30
elseif ffi.os == "BSD" then
    AF_INET6 = 28
elseif ffi.os == "Windows" then
    AF_INET6 = 23
end


local _M = {_VERSION = 0.3}


ffi_cdef[[
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


return _M