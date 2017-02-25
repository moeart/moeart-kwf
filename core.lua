--[[

Copyright (C) 2017 MoeArt Development Team.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THEq
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]


local io = require("io")
local string = require("string")
local config = require("config")

local _M = {
    version = "0.1",
    RULE_TABLE = {},
    RULE_FILES = {
        "keyword.lst",
        "applyTo.lst"
    }
}


-- GET FULL FILENAME FOR EACH RULE
function _M.get_rule_files(rules_path)
    local rule_files = {}
    for _, file in ipairs(_M.RULE_FILES) do
        if file ~= "" then
            local file_name = rules_path .. '/' .. file
            ngx.log(ngx.DEBUG, string.format("reading rule %s from %s", file, file_name))
            rule_files[file] = file_name
        end
    end
    return rule_files
end


-- LOAD ALL KWF RULES WHEN NGINX START INITIATING
function _M.get_rules(rules_path)
    local rule_files = _M.get_rule_files(rules_path)
    if rule_files == {} then
        return nil
    end

    for rule_name, rule_file in pairs(rule_files) do
        local t_rule = {}
        
        -- reading all line to table
        for line in io.lines(rule_file) do
            table.insert(t_rule, line)
        end
        
        -- merge into one table
        ngx.log(ngx.INFO, string.format("rule_name:%s, value:%s", rule_name, t_rule))
        _M.RULE_TABLE[rule_name] = t_rule
        
    end
    return(_M.RULE_TABLE)
end


-- GET THE USER'S CLIENT IP ADDRESS
function _M.get_client_ip()
    local CLIENT_IP = ngx.req.get_headers()["Client_Ip"]
    if CLIENT_IP == nil then
        CLIENT_IP = ngx.req.get_headers()["Cdn_Src_Ip"]
    end
    if CLIENT_IP == nil then
        CLIENT_IP = ngx.req.get_headers()["X_Real_Ip"]
    end
    if CLIENT_IP == nil then
        CLIENT_IP = ngx.req.get_headers()["X_Forwarded_For"]
    end
    if CLIENT_IP == nil then
        CLIENT_IP  = ngx.var.remote_addr
    end
    if CLIENT_IP == nil then
        CLIENT_IP  = ""
    end
    return CLIENT_IP
end


-- KWF LOG RECORDING FUNCTION
function _M.log_record(method, url, data, keyword)
    -- if log has been disabled skip logging
    if config.log_enable ~= "on" then return end

    local log_path = config.log_dir
    local client_IP = _M.get_client_ip()
    local local_time = ngx.localtime()

    local log_line = client_IP .. "," .. method .. "," .. url .. "," .. data .. "," .. keyword .. "," .. local_time
    local log_name = string.format("%s/%s_kwf.csv", log_path, ngx.today())
    local file = io.open(log_name, "a")
    if file == nil then
        return
    end

    file:write(string.format("%s\n", log_line))
    file:flush()
    file:close()
end

return _M
