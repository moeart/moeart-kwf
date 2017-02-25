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

local rulematch = ngx.re.find
local unescape = ngx.unescape_uri
local escape = ngx.escape_uri

local string = require("string")
local config = require("ma_config")
local core = require("ma_core")

local _M = {
    RULES = {}
}


-- LOADING RULES FROM FILE TO MEMORY
function _M.load_rules()
    _M.RULES = core.get_rules(config.rule_dir)
    for k, v in pairs(_M.RULES)
    do
        ngx.log(ngx.INFO, string.format("-----S  set rule from %s  S-----", k))
        for kk, vv in pairs(v)
        do
            ngx.log(ngx.INFO, string.format("index:%s, rule:%s", kk, vv))
        end
        ngx.log(ngx.INFO, string.format("-----E  rule %s set finished  E-----", k))
    end
    return _M.RULES
end


-- GET RULE FROM MEMORY
function _M.get_rule(rule_file_name)
    ngx.log(ngx.DEBUG, rule_file_name)
    return _M.RULES[rule_file_name]
end


-- SITE API LIST MATCHER
function _M.site_api_matcher()
    local APPLY_LIST = _M.get_rule('applyTo.lst')
    local REQ_URI = ngx.var.scheme .. "://" .. ngx.var.http_host .. ngx.var.request_uri
    
    -- check is url matched?
    if APPLY_LIST ~= nil then
        for _, rule in pairs(APPLY_LIST) do
            if rule ~= "" and string.match(REQ_URI, rule) then
                ngx.log(ngx.INFO, string.format("url:%s matched!", REQ_URI))
                return true
            end
        end
    end
    
    ngx.log(ngx.DEBUG, string.format("url:%s missing!", REQ_URI))
    return false
end


-- CHECK IS ANY KEYWORD MATCHED
function _M.keyword_check()
    local KEYWORD_LIST = _M.get_rule('keyword.lst')
    local REQ_METHOD = ngx.req.get_method()
    local REQ_QUERY = nil
    
    if KEYWORD_LIST ~= nil then
        -- get query string
        if REQ_METHOD == "GET" then
            REQ_QUERY = ngx.var.query_string
        elseif REQ_METHOD == "POST" then
            -- bug: its only support urlencoded now
            if string.match(ngx.header.content_type, "application/x-www-form-urlencoded") then
                ngx.req.read_body()
                REQ_QUERY = ngx.encode_args(ngx.req.get_post_args())
            end
        end

        -- do check query string is ok or not
        if REQ_QUERY ~= nil then
            for _, rule in pairs(KEYWORD_LIST) do
                if rule ~= "" and string.match(unescape(REQ_QUERY), rule) then
                    -- replace % to %% because gsub not support % but %%
                    local rule_encode = escape(rule):gsub("%%","%%%%")
                    local kw_mask_encode = escape(config.keyword_mask):gsub("%%","%%%%")
                    -- replace matched keyword
                    local args = REQ_QUERY:gsub(rule_encode, kw_mask_encode)
                    -- reset the query string
                    if REQ_METHOD == "GET" then
                        ngx.req.set_uri_args(args)
                    else
                        ngx.req.set_body_data(args)
                    end
                    ngx.log(ngx.INFO, string.format("keyword:%s matched!", rule))
                    -- logging to file
                    core.log_record(REQ_METHOD, unescape(ngx.var.request_uri), unescape(REQ_QUERY), rule)
                    return true
                end
            end
        end
    end
    
    return false
end


-- KEYWORD FILTER START
function _M.do_filter()

    -- if kwf has been disabled skip check
    if config.kwf_enable ~= "on" then return end
    
    -- if site url not matched skip check
    if _M.site_api_matcher() ~= true then return end

    -- do keyword check now
    if _M.keyword_check() then
    else
        return
    end

end

return _M
