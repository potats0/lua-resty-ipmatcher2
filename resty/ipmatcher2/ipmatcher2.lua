local ffi      = require "ffi"
local base     = require("resty.core.base")
local ip       = require("resty.ipmatcher2.ip")
local new_tab  = base.new_tab

local lib_name = "libipmatcher.so"
if ffi.os == "OSX" then
    lib_name = "libipmatcher.dylib"
end

ffi.cdef [[
void free_prefix_trie(void *prefix_map_ptr);

char get(void *prefix_map_ptr, uint32_t ipv4_addr, uint8_t netmask);

int insert(void *prefix_map_ptr, uint32_t ipv4_addr, uint8_t netmask, uint8_t action);

void *new_prefix_trie(void);

void remove(void *prefix_map_ptr, uint32_t ipv4_addr, uint8_t netmask);
]]

local _M = {
    _VERSION = '0.01'
}
local function load_shared_lib(so_name)
    local string_gmatch = string.gmatch
    local string_match = string.match
    local io_open = io.open
    local io_close = io.close

    local cpath = package.cpath
    local tried_paths = new_tab(32, 0)
    local i = 1

    for k, _ in string_gmatch(cpath, "[^;]+") do
        local fpath = string_match(k, "(.*/)")
        fpath = fpath .. so_name
        -- Don't get me wrong, the only way to know if a file exist is trying
        -- to open it.
        local f = io_open(fpath)
        if f ~= nil then
            io_close(f)
            return ffi.load(fpath)
        end
        tried_paths[i] = fpath
        i = i + 1
    end

    return nil, tried_paths
end



local prefix_C, tried_paths = load_shared_lib(lib_name)
if not prefix_C then
    tried_paths[#tried_paths + 1] = 'tried above paths but can not load '
        .. lib_name
    error(table.concat(tried_paths, '\r\n', 1, #tried_paths))
end

_M.new_prefix_trie = prefix_C.new_prefix_trie
_M.insert = prefix_C.insert
_M.get = prefix_C.get
_M.free = prefix_C.free_prefix_trie
_M.remove = prefix_C.remove

-- prefix_C.insert(tree, 3232235776, 24, 1)

-- local addr = ip.parse_ipv4("192.168.1.1")
-- local r = prefix_C.get(tree, addr, 32)

-- print(r)

return _M
