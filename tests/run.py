"""Run the Lua scenario suite using `python tests/run.py` (requires lupa)."""
from pathlib import Path
import os
from lupa.lua51 import LuaRuntime

os.chdir(Path(__file__).resolve().parents[1])
lua = LuaRuntime(unpack_returned_tuples=True)
for path in Path('.').glob('*.lua'):
    lua.execute('assert((loadstring or load)(...))', path.read_text(encoding='utf-8-sig'))
lua.execute(Path('tests/run.lua').read_text(encoding='utf-8-sig'))
lua.execute(Path('tests/progress.lua').read_text(encoding='utf-8-sig'))
lua.execute(Path('tests/tabs.lua').read_text(encoding='utf-8-sig'))

# Start without any libraries supplied by other addons. The UI scenario mocks
# above deliberately omit the minimap integration, so test its real dependencies.
libraries = LuaRuntime(unpack_returned_tuples=True)
libraries.execute('''
UIParent = {}
Minimap = { GetWidth = function() return 140 end,
    GetHeight = function() return 140 end, HookScript = function() end }
function CreateFrame() return { RegisterEvent = function() end,
    SetScript = function() end } end
function securecallfunction(fn, ...) return fn(...) end
''')
for entry in Path('SoloCompass.toc').read_text().splitlines():
    if entry.startswith('Libs\\'):
        library = Path(entry.replace('\\', '/'))
        libraries.execute(library.read_text(encoding='utf-8-sig'))
libraries.execute('''
assert(LibStub("CallbackHandler-1.0"))
local broker = LibStub("LibDataBroker-1.1")
assert(LibStub("LibDBIcon-1.0"))
local changed = false
broker.RegisterCallback({}, "LibDataBroker_AttributeChanged__icon",
    function() changed = true end)
local launcher = broker:NewDataObject("SoloCompass", {type="launcher", icon="old"})
launcher.icon = "new"
assert(changed and launcher.icon == "new")
''')
print('Bundled minimap libraries loaded in TOC order and dispatched callbacks')

lua.execute(Path('tests/pets.lua').read_text(encoding='utf-8-sig'))

lua.execute(Path('tests/housing.lua').read_text(encoding='utf-8-sig'))

lua.execute(Path('tests/refinements.lua').read_text(encoding='utf-8-sig'))

lua.execute(Path('tests/collections.lua').read_text(encoding='utf-8-sig'))

lua.execute(Path('tests/release.lua').read_text(encoding='utf-8-sig'))
