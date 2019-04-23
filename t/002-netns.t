# vim:set ft= ts=4 sw=4 et fdm=marker:

use Test::Nginx::Socket::Lua;

$ENV{TEST_NGINX_HTML_DIR} ||= html_dir();

add_block_preprocessor(sub {
    my $block = shift;

    if (!defined $block->request) {
        $block->set_value("request", "GET /t");
    }

    if (!defined $block->no_error_log) {
        $block->set_value("no_error_log", "[error]");
    }
});

env_to_nginx("PATH");
log_level('debug');

repeat_each(1);

plan tests => repeat_each() * (blocks() * 3);

#no_diff();
no_long_string();

run_tests();

__DATA__

=== TEST 1: with default http listen configuration
--- config
    location = /t {
        content_by_lua_block {
            local function set_up_ngx_tmp_conf()
                local conf = [[
                    events {
                        worker_connections 64;
                    }
                    http {
                        server {
                            location / {
                                return 200 'OK';
                            }
                        }
                    }
                ]]

                assert(os.execute("mkdir -p $TEST_NGINX_HTML_DIR/logs"))

                local conf_file = "$TEST_NGINX_HTML_DIR/nginx.conf"
                local f, err = io.open(conf_file, "w")
                if not f then
                    ngx.log(ngx.ERR, err)
                    return
                end

                assert(f:write(conf))

                return conf_file
            end

            local function get_ngx_bin_path()
                local ffi = require "ffi"
                ffi.cdef[[char **ngx_argv;]]
                return ffi.string(ffi.C.ngx_argv[0])
            end

            local conf_file = set_up_ngx_tmp_conf()
            local nginx = get_ngx_bin_path()

            local cmd = nginx .. " -p $TEST_NGINX_HTML_DIR -c " .. conf_file .. " -t"
            local p, err = io.popen(cmd)
            if not p then
                ngx.log(ngx.ERR, err)
                return
            end

            local out, err = p:read("*a")
            if not out then
                ngx.log(ngx.ERR, err)

            else
                ngx.log(ngx.WARN, out)
            end
        }
    }
--- error_log
test is successful
