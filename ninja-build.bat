
@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ============================================================
REM Build OpenVINO + OpenVINO.GenAI (Ninja) and package ZIP
REM Assumes this .cmd lives in the parent folder containing:
REM   .\openvino\
REM   .\openvino.genai\
REM Optional:
REM   .\build-env\Scripts\activate.bat  (python venv)
REM
REM Usage:
REM   build_all.cmd -Help
REM   build_all.cmd [-Tag <name>] [-ArchiveOnly]
REM ============================================================

REM -------------------------------
REM Help handling (anywhere)
REM -------------------------------
for %%A in (%*) do (
  if /I "%%~A"=="-Help"  goto :USAGE
  if /I "%%~A"=="--help" goto :USAGE
  if /I "%%~A"=="-h"     goto :USAGE
  if /I "%%~A"=="/?"     goto :USAGE
)

REM --- Root directory where this script lives ---
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

REM --- Repo locations ---
set "OV_SRC=%ROOT%\openvino"
set "GENAI_SRC=%ROOT%\openvino.genai"

REM --- Build directories ---
set "OV_BUILD=%OV_SRC%\build-ninja"
set "GENAI_BUILD=%GENAI_SRC%\build-ninja"

REM --- Install directory (keep consistent) ---
set "OV_INSTALL=%OV_BUILD%\install"

REM --- OpenVINO Developer Package directory ---
REM OpenVINO docs: the Developer Package is generated in the OpenVINO build dir,
REM and consumers should point OpenVINODeveloperPackage_DIR to that build dir. [1](https://docs.openvino.ai/2025/documentation/openvino-extensibility/openvino-plugin-library/build-plugin-using-cmake.html)[2](https://docs.openvino.ai/2024/documentation/openvino-extensibility/openvino-plugin-library/build-plugin-using-cmake.html)
set "OV_DEVPKG_DIR=%OV_BUILD%"

REM --- ccache launcher (adjust if needed) ---
set "CCACHE_EXE=C:\Users\dneve\ccache\ccache.exe"

REM --- Artifacts Directory
set "ARTIFACTS_DIR=%ROOT%\artifacts"

REM --- Visual Studio environment setup (x64) ---
set "VCVARS64=C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat"
if not exist "%VCVARS64%" (
  echo ERROR: vcvars64.bat not found at:
  echo   %VCVARS64%
  echo Edit VCVARS64 path in this script.
  exit /b 1
)

REM --- Sanity checks ---
if not exist "%OV_SRC%\CMakeLists.txt" (
  echo ERROR: OpenVINO repo not found at %OV_SRC%
  exit /b 1
)
if not exist "%GENAI_SRC%\CMakeLists.txt" (
  echo ERROR: openvino.genai repo not found at %GENAI_SRC%
  exit /b 1
)

echo.
echo ============================================================
echo Paths
echo ============================================================
echo ROOT          = %ROOT%
echo OV_SRC        = %OV_SRC%
echo OV_BUILD      = %OV_BUILD%
echo OV_INSTALL    = %OV_INSTALL%
echo OV_DEVPKG     = %OV_DEVPKG_DIR%
echo GENAI_SRC     = %GENAI_SRC%
echo GENAI_BUILD   = %GENAI_BUILD%
echo CCACHE_EXE    = %CCACHE_EXE%
echo ARTIFACTS_DIR = %ARTIFACTS_DIR%
echo ============================================================

echo.
echo ============================================================
echo 1^) Initializing Visual Studio x64 environment...
echo ============================================================
call "%VCVARS64%" || exit /b 1

REM --- Optional python venv activation (cmd uses activate.bat) ---
if exist "%ROOT%\build-env\Scripts\activate.bat" (
  echo.
  echo ============================================================
  echo 2^) Activating Python venv...
  echo ============================================================
  call "%ROOT%\build-env\Scripts\activate.bat"
)

echo.
echo ============================================================
echo 3^) Configure + build OpenVINO...
echo ============================================================

if not exist "%OV_BUILD%" mkdir "%OV_BUILD%"
pushd "%OV_BUILD%" || exit /b 1

cmake -G Ninja ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INSTALL_PREFIX="%OV_INSTALL%" ^
  -DENABLE_PLUGINS_XML=ON ^
  -DENABLE_DEBUG_CAPS=ON ^
  -DENABLE_NPU_DEBUG_CAPS=ON ^
  -DENABLE_INTEL_NPU_PROTOPIPE=OFF ^
  -DCMAKE_C_COMPILER_LAUNCHER="%CCACHE_EXE%" ^
  -DCMAKE_CXX_COMPILER_LAUNCHER="%CCACHE_EXE%" ^
  .. || (popd && exit /b 1)

cmake --build . --target install --parallel 8 || (popd && exit /b 1)

popd

echo.
echo ============================================================
echo 4^) Configure + build OpenVINO.GenAI...
echo ============================================================

if not exist "%GENAI_BUILD%" mkdir "%GENAI_BUILD%"
pushd "%GENAI_BUILD%" || exit /b 1

REM IMPORTANT:
REM OpenVINODeveloperPackage_DIR should point to the OpenVINO BUILD tree,
REM not the install tree, because the OpenVINO Developer Package is generated
REM in the build directory and consumed from there. [1](https://docs.openvino.ai/2025/documentation/openvino-extensibility/openvino-plugin-library/build-plugin-using-cmake.html)[3](https://github.com/openvinotoolkit/openvino/blob/master/cmake/templates/OpenVINODeveloperPackageConfig.cmake.in)
REM Install GenAI into the same install prefix as OpenVINO (so one runtime tree).
cmake -G Ninja ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INSTALL_PREFIX="%OV_INSTALL%" ^
  -DOpenVINODeveloperPackage_DIR="%OV_DEVPKG_DIR%" ^
  -DCMAKE_C_COMPILER_LAUNCHER="%CCACHE_EXE%" ^
  -DCMAKE_CXX_COMPILER_LAUNCHER="%CCACHE_EXE%" ^
  .. || (popd && exit /b 1)

cmake --build . --target install --parallel 8 || (popd && exit /b 1)

popd

echo.
echo ============================================================
echo 5^) Packaging (ZIP) using openvino\post-build.ps1...
echo ============================================================

REM post-build.ps1 uses relative paths like src/core/include/... and calls git,
REM so run it from the OpenVINO repo root.
pushd "%OV_SRC%" || exit /b 1

REM Forward all script arguments to post-build.ps1 (e.g. -Tag, -ArchiveOnly).
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass ^
  -File "%OV_SRC%\post-build.ps1" ^
  -BuildPath "%OV_INSTALL%" ^
  %* || (popd && exit /b 1)

popd


REM ------------------------------------------------------------
REM 6^) Copy the most recent generated ZIP into .\artifacts
REM ------------------------------------------------------------
if not exist "%ARTIFACTS_DIR%" (
  mkdir "%ARTIFACTS_DIR%" || (
    echo ERROR: Failed to create artifacts directory: %ARTIFACTS_DIR%
    exit /b 1
  )
)

REM Ensure PowerShell is available (needed for search)
where powershell.exe >nul 2>&1
if errorlevel 1 (
  echo ERROR: powershell.exe not found in PATH. Required for artifact copy.
  exit /b 1
)

REM Prefer a narrow search in OV_BUILD, then fall back to OV_SRC
set "LATEST_ZIP="

for /f "usebackq delims=" %%Z in (`
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
    "$z=Get-ChildItem -Path '%OV_BUILD%' -Filter *.zip -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1; if($z){$z.FullName}"
`) do set "LATEST_ZIP=%%Z"

if not defined LATEST_ZIP (
  for /f "usebackq delims=" %%Z in (`
    powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
      "$z=Get-ChildItem -Path '%OV_SRC%' -Filter *.zip -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1; if($z){$z.FullName}"
  `) do set "LATEST_ZIP=%%Z"
)

if not defined LATEST_ZIP (
  echo WARNING: No .zip found under %OV_BUILD% or %OV_SRC%. Skipping artifact copy.
) else (
  echo Latest ZIP found: "!LATEST_ZIP!"
  echo Copying to "%ARTIFACTS_DIR%\"
  copy /Y "!LATEST_ZIP!" "%ARTIFACTS_DIR%\" >nul || (
    echo ERROR: Failed to copy "!LATEST_ZIP!" to "%ARTIFACTS_DIR%"
    exit /b 1
  )
  for %%F in ("!LATEST_ZIP!") do echo Artifact copied: "%ARTIFACTS_DIR%\%%~nxF"
)

echo.
echo ============================================================
echo DONE:  Build + install + package complete
echo Install path: %OV_INSTALL%
echo Artifacts dir: %ARTIFACTS_DIR%
echo ============================================================

endlocal
exit /b 0


:USAGE
echo.
echo ============================================================
echo build_all.cmd - Build OpenVINO + OpenVINO.GenAI + package zip
echo ============================================================
echo.
echo Location assumptions:
echo   - This script is in the parent folder containing:
echo       .\openvino\
echo       .\openvino.genai\
echo   - Optional python venv:
echo       .\build-env\Scripts\activate.bat
echo.
echo Usage:
echo   build_all.cmd -Help
echo   build_all.cmd [post-build.ps1 options]
echo.
echo This script forwards ALL arguments to openvino\post-build.ps1.
echo Common post-build.ps1 options:
echo   -Tag ^<name^>        Add suffix tag in zip name
echo   -ArchiveOnly       Create zip only, skip upload
echo.
echo Examples:
echo   build_all.cmd -ArchiveOnly
echo   build_all.cmd -Tag nightly -ArchiveOnly
echo.
endlocal
exit /b 0