package.loaded["purified"] = nil
package.loaded["purified"] = dofile(require("filesystem").path(debug.getinfo(2, "S").source:match("=(.+)")) ..
                                        "purified_package.lua")

dofile(package.loaded["purified"].rootPath .. "core/core_logic.lua")