@echo off
setlocal
cd /d "%~dp0"
where flutter >nul 2>nul
if errorlevel 1 (
  echo Khong tim thay Flutter. Hay cai Flutter SDK va them flutter\bin vao PATH.
  pause
  exit /b 1
)
call flutter create --platforms=android,windows --project-name isolate_demo .
if errorlevel 1 exit /b 1
rem Xoa test mau do flutter create sinh ra, khong phu hop UI cua du an nay.
if exist test\widget_test.dart del test\widget_test.dart
call flutter pub get
if errorlevel 1 exit /b 1
echo.
echo Da khoi tao xong. Chay: flutter devices
echo Sau do: flutter run -d DEVICE_ID
pause
