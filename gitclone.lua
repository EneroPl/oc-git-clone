local internet = require("internet")
local json = require("lib.dkjson")
local fs = require("filesystem")
local shell = require("shell")

local CONTENTS_URL = "https://api.github.com/repos/%s/%s/contents/%s"
local RAW_URL = "https://raw.githubusercontent.com/%s/%s/main/%s"

local args = {...}
local GitHub = {}

local function getFilePaths(path)
    path = path or ""

    local handle = internet.request(string.format(CONTENTS_URL, args[1], args[2], path), nil, {
        headers = {
            ["Authorization"] = "token " .. args[3],
            ["User-Agent"] = "Lua-Script"
        }
    })

    local result = ""

    for chunk in handle do
        result = result .. chunk
    end

    local mt = getmetatable(handle)
    local code, message = mt.__index.response()

    if code ~= 200 then
        print("Ты долбеоп оно не рабоатет")
        return nil
    end

    result = json.decode(result)

    local contents = {}
    for _, item in pairs(result) do
        if item.type == "file" then
            table.insert(contents, item.path)
        elseif item.type == "dir" then
            local sub_paths = getFilePaths(item.path)
            for _, sub_path in ipairs(sub_paths) do
                table.insert(contents, sub_path)
            end
        end
    end

    return contents
end

print("Получение информации о репозитории " .. args[2])
local paths = getFilePaths()

if not paths or paths == nil then
    print("Ошибка получения путей")
end

print("Клонирование репозитория...")
for index, filepath in pairs(paths) do
    local url = string.format(RAW_URL, args[1], args[2], filepath)
    local dirPath = filepath:match("(.*/)")

    if type(dirPath) == 'string' and dirPath ~= "" then
        if not fs.exists("/home/" .. dirPath) then
            shell.execute("mkdir " .. dirPath)
        end
    end

    print(filepath)
    shell.execute("wget " .. url .. " " .. filepath .. " -fQ")
    os.sleep(0.1)
end
print("Репозиторий " .. args[2] .. " успешно склонирован.")
