"""Run the Lua scenario suite using `python tests/run.py` (requires lupa)."""
from pathlib import Path
import os
from lupa.lua51 import LuaRuntime

os.chdir(Path(__file__).resolve().parents[1])
lua = LuaRuntime(unpack_returned_tuples=True)
for path in Path('.').glob('*.lua'):
    lua.execute('assert((loadstring or load)(...))', path.read_text(encoding='utf-8-sig'))
lua.execute(Path('tests/run.lua').read_text(encoding='utf-8-sig'))
