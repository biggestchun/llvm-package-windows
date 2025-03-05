@echo off

:: Reset variables
set TARGET_CPU=amd64
set GENERATOR=NMake Makefiles
set CONFIGURATION=Release
set WORKING_DIR=%HOMEDRIVE%%HOMEPATH%

:: Parse command line arguments
:parse_args
if "%1" == "" goto :finalize
if /i "%1" == "x86" (
    set TARGET_CPU=x86
    shift
    goto :parse_args
)
if /i "%1" == "x64" (
    set TARGET_CPU=amd64
    shift
    goto :parse_args
)
if /i "%1" == "ninja" (
    set GENERATOR=Ninja
    shift
    goto :parse_args
)
if /i "%1" == "nmake" (
    set GENERATOR=NMake Makefiles
    shift
    goto :parse_args
)
if /i "%1" == "debug" (
    set CONFIGURATION=Debug
    shift
    goto :parse_args
)
if /i "%1" == "release" (
    set CONFIGURATION=Release
    shift
    goto :parse_args
)

echo Invalid argument: '%1'
exit /b 1

:finalize

:: Set up directories
set LLVM_VERSION=%1
if "%LLVM_VERSION%" == "" set LLVM_VERSION=17.0.1

set LLVM_RELEASE_NAME=llvm-%LLVM_VERSION%-windows-%TARGET_CPU%-clang
set LLVM_RELEASE_DIR=%WORKING_DIR%\%LLVM_RELEASE_NAME%
set LLVM_RELEASE_DIR=%LLVM_RELEASE_DIR:\=/%
set LLVM_BUILD_DIR=%WORKING_DIR%\llvm-build-%LLVM_VERSION%
set LLVM_BUILD_DIR=%LLVM_BUILD_DIR:\=/%

:: Set compiler options
set CMAKE_COMPILER_OPTIONS=-DCMAKE_C_COMPILER=clang-cl -DCMAKE_CXX_COMPILER=clang-cl

:: Configure build flags based on generator
if /i "%GENERATOR%" == "Ninja" (
    set CMAKE_BUILD_FLAGS=--config %CONFIGURATION%
) else (
    set CMAKE_BUILD_FLAGS=
)

:: Set up LLVM cmake configuration
set LLVM_CMAKE_CONFIGURE_FLAGS= ^
    -G "%GENERATOR%" ^
    %CMAKE_COMPILER_OPTIONS% ^
    -DCMAKE_INSTALL_PREFIX=%LLVM_RELEASE_DIR% ^
    -DCMAKE_BUILD_TYPE=%CONFIGURATION% ^
    -DLLVM_ENABLE_Z3_SOLVER=ON ^
    -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;compiler-rt;libcxx;lld" ^
    -DLLVM_FORCE_BUILD_RUNTIME=ON ^
    -DLLVM_ENABLE_TERMINFO=OFF ^
    -DLLVM_ENABLE_ZLIB=OFF ^
    -DLLVM_INCLUDE_BENCHMARKS=OFF ^
    -DLLVM_INCLUDE_DOCS=OFF ^
    -DLLVM_INCLUDE_EXAMPLES=OFF ^
    -DLLVM_INCLUDE_GO_TESTS=OFF ^
    -DLLVM_INCLUDE_RUNTIMES=OFF ^
    -DLLVM_INCLUDE_TESTS=OFF ^
    -DLLVM_INCLUDE_UTILS=OFF ^
    -DLLVM_ENABLE_DUMP=ON ^
    -DLLVM_ENABLE_LIBCXX=ON

:: Create build directory if it doesn't exist
if not exist "%LLVM_BUILD_DIR%" mkdir "%LLVM_BUILD_DIR%"

echo ---------------------------------------------------------------------------
echo LLVM_VERSION:                %LLVM_VERSION%
echo TARGET_CPU:                  %TARGET_CPU%
echo GENERATOR:                   %GENERATOR%
echo CONFIGURATION:               %CONFIGURATION%
echo LLVM_RELEASE_DIR:            %LLVM_RELEASE_DIR%
echo LLVM_BUILD_DIR:              %LLVM_BUILD_DIR%
echo LLVM_CMAKE_CONFIGURE_FLAGS:  %LLVM_CMAKE_CONFIGURE_FLAGS%
echo ---------------------------------------------------------------------------

:: Configure LLVM
echo Configuring LLVM...
cd "%LLVM_BUILD_DIR%"
cmake -S path\to\llvm-project\llvm %LLVM_CMAKE_CONFIGURE_FLAGS%

:: Build LLVM
echo Building LLVM...
cmake --build . %CMAKE_BUILD_FLAGS%

:: Install LLVM
echo Installing LLVM...
cmake --install .

echo ---------------------------------------------------------------------------
echo LLVM build completed successfully!
echo Installation directory: %LLVM_RELEASE_DIR%
echo ---------------------------------------------------------------------------
