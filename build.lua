-- Build script for Pico8 Development

local Config = require("config")
local lfs = require("lfs")

-- the main sections of a pico8 cart
Sections_ordered = {
    "__preamble__",
    "__lua__",
    "__gfx__",
    "__gff__",
    "__map__",
    "__sfx__",
    "__music__"
}

function read_cart(cart_path)
    local sections = {}
    for i,each in ipairs(Sections_ordered) do
        sections[each] = {}
    end
    local sec = "__preamble__"

    local cart_in = io.open(cart_path, "r")
    for line in cart_in:lines() do
        if sections[line] ~= nil then
            sec = line
        end

        table.insert(sections[sec], line)
    end

    io.close(cart_in)
    return sections
end

function find_lua_files(directory)
    local lua_files = {}
    local file

    for _file in lfs.dir(directory) do
        if _file ~= '..' and _file ~= '.' then
            file = directory .. _file 
            if lfs.attributes(file, 'mode') == 'file' and string.sub(file, -4) == '.lua' then
                table.insert(lua_files, file)
            elseif lfs.attributes(file, 'mode') == 'directory' then
                local lua_files_from_dir = find_lua_files(file .. '/')
                for _,f in ipairs(lua_files_from_dir) do
                    table.insert(lua_files, f)
                end
            end
        end
    end

    return lua_files
end

function read_src_lua(source_files)
    local lua_section = {'__lua__'}

    for _,source_path in ipairs(source_files) do
        print('Reading from ' .. source_path)
        table.insert(lua_section, "--" .. source_path)

        local lua_file = io.open(source_path, "r")
        for line in lua_file:lines() do
            table.insert(lua_section, line)
        end

        table.insert(lua_section, "-->8")
        io.close(lua_file)
    end

    return lua_section
end

function write_cart(cart_path, cart_sections)
    local cart_out = io.open(cart_path, "w")
    io.output(cart_out)

    for i,section in ipairs(Sections_ordered) do
        -- print("Writing section: " .. section)

        for _i,v in ipairs(cart_sections[section]) do
            io.write(v)
            io.write("\n")
        end
    end

    io.close(cart_out)
    print("Wrote to " .. cart_path)
end

function do_build()
    print('Watch directory modified, rebuilding...')
    local cart_sections = read_cart(Config.input_cart_path)
    local lua_source_files = find_lua_files(Config.source_dir)
    cart_sections.__lua__ = read_src_lua(lua_source_files)
    write_cart(Config.output_cart_path, cart_sections)
    print("Done.")
end

if Config.watch then
    local watcher = require 'watcher'
    watcher(Config.source_dir, do_build)
else
    do_build()
end

