# MiniOS
Minimal operating system for MiniArch

...

## Dependencies

- *NIX Host system
    - the emulator only works on UNIX-like system. support for NT is not soon, use WSL if you want to use this on Windows

- Python 3.x
    - from your system's package manager
    - make sure that `python3` and `python` refers to the same executable

- Lark parser
    - via pip: `pip install lark` or your system specific installation
    - required for the assembler

- [MiniArch Assembler and Emulator](https://github.com/gusza110811/miniArch)
    - file `assembler/main.py` symlinked as `ma-as` anywhere in PATH
    - file `emulator/main.py` symlinked as `ma-vm` anywhere in PATH

- [BadFS Interface](https://github.com/gusza110811/BadFS)
    - file `main.py` symlinked as `badfs` anywhere in PATH
