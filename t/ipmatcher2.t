use Test::Nginx::Socket 'no_plan';

our $HttpConfig = <<'_EOC_';
    lua_package_path "lib/?.lua;/usr/local/share/lua/5.1/?.lua;;";
    lua_socket_log_errors off;
    lua_code_cache on;
_EOC_


# master_on();
# workers(4);
no_shuffle();
run_tests();

__DATA__

=== TEST 1: 
--- http_config eval: $::HttpConfig
--- config     
location /t {
        content_by_lua_block {
            local ipmatcher = require "resty.ipmatcher"
            local m = ipmatcher.new()
            m:insert_ipv4_with_mask("192.168.3.1/24", 1)
            local a = m:match_ipv4("192.168.3.1")
            ngx.say(a)
        }
    }
--- request
GET /t/a
--- error_code: 200
--- response_body_like
1

=== TEST 2: 
--- http_config eval: $::HttpConfig
--- config     
location /t {
        content_by_lua_block {
            local ipmatcher = require "resty.ipmatcher"
            local m = ipmatcher.new()
            m:insert_ipv4_with_mask("192.168.3.1/24", 1)
            m:remove_ipv4_with_mask("192.168.3.1/24")
            local a = m:match_ipv4("192.168.3.1")
            ngx.say(a)
        }
    }
--- request
GET /t/a
--- error_code: 200
--- response_body_like
0