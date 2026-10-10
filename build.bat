@echo off

:: 1. Assemble the code
nasm -f win64 program.asm -o program.obj
if %errorlevel% neq 0 exit /b %errorlevel%

:: 2. Link using the classic OMAGIC flag (-N)
gcc program.obj -o program.exe -nostdlib -lkernel32 -s ^
    -Wl,--subsystem,console ^
    -Wl,-N
    
if %errorlevel% neq 0 exit /b %errorlevel%

:: 3. Clean up
del program.obj

echo Build complete! Running program...
echo ---------------------------------
.\program.exe