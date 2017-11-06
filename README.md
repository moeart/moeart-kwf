# MoeArt Keyword Filter

MoeArt Keyword Filter(MA-KWF) is a keyword filter for nginx with Lua support, such as openresty. MA-KWF can helps you block bad keywords submit to your site, and making a harmonious and beautiful social environment.

MA-KWF designed by MoeArt Development Team with MIT License, and it can works fine with Lua based WAF, such as X-Waf.

# Features

- Block bad keywords with GET/POST/PUT method
- Block bad keywords with JSON method
- Customizable bad keyword replacement mask symbol
- Protect data integrity when filter bad keywords
- Simple keywords library file format (one line one word) 
- Hot update keyword without restart server
- Multi-platform support, Linux, Unix, Windows, BSD etc.

# Installation Guide

**PLEASE BE SURE OPENRESTY WORKS FINE BEFORE ALL !!**

1. Make sure Openresty is working fine.
2. Clone MA-KWF to Openresty:

    ```bash
    cd /usr/local/openresty/nginx/conf
    git clone https://github.com/moeart/moeart-kwf ma-kwf/
    ```

3. Upload your keyword list file to ```/usr/local/openresty/nginx/conf/ma-kwf/keyword.lst```, such as:

    ```
    萌冬瓜
    萌西瓜
    萌南瓜
    萌北瓜
    moeart
    acgdraw
    ```

4. Setting up your API or some URL you want protect, modify file ```/usr/local/openresty/nginx/conf/ma-kwf/applyTo.lst```, such as:

    ```
    http://www.example.com/api/v2/post
    example.com/api/v1
    example.com/api/v2
    www.example.com
    sub.example.com
    ?type=post
    ```

5. Modify nginx configuration file, Insert code:

    ```
    http {
        ... ...
        lua_package_path "/usr/local/openresty/nginx/conf/moeart-kwf/?.lua;/usr/local/lib/lua/?.lua;";
        lua_code_cache on;
        
        init_by_lua_file /usr/local/openresty/nginx/conf/moeart-kwf/init.lua;
        access_by_lua_file /usr/local/openresty/nginx/conf/moeart-kwf/access.lua;
        ... ...
    }
    ```

6. Restart or reload your nginx or openresty.

# Make Compatible with WAF

**SUCH AS X-WAF, PLEASE FOLLOW INSTALLATION GUIDE STEP 1 TO 4 FIRST !!**

5. Modify nginx configuration file, such as:

    ```
    http {
        ... ...
        lua_package_path "/usr/local/openresty/nginx/conf/moeart-kwf/?.lua;/usr/local/openresty/nginx/conf/x-waf/?.lua;/usr/local/lib/lua/?.lua;";
        ... ...
    }
    ```

6. Copy all content in ```moeart-kwf/init.lua``` to end of the file ```x-waf/init.lua```.
7. Copy all content in ```moeart-kwf/access.lua``` to end of the file ```x-waf/access.lua```.
8. Restart or reload your nginx or openresty.

## Thanks

1. [Openresty](https://openresty.org)
2. [Waf](https://github.com/unixhot/waf)
3. [X-Waf](https://waf.xsec.io)
3. [Github](https://github.com)
