@echo off
setlocal EnableExtensions EnableDelayedExpansion

call :UpdateRepo "openvino" || goto :FAIL
call :UpdateRepo "openvino.genai" || goto :FAIL

echo.
echo ==========================================
echo   All updates completed OK  ^✓
echo ==========================================
endlocal
exit /b 0

:UpdateRepo
set "REPO=%~1"
if not exist "%REPO%\" (
  echo.
  echo ==========================================
  echo   ERROR: Missing folder "%REPO%"
  echo ==========================================
  exit /b 1
)

echo.
echo ==========================================
echo   Updating: %REPO%
echo ==========================================

pushd "%REPO%" || exit /b 1

echo git pull
git pull || (popd & exit /b 1)

popd
echo Done: %REPO%
exit /b 0

:FAIL
echo.
echo ==========================================
echo   Update FAILED. Stopping.
echo ==========================================
endlocal
exit /b 1
