@echo off
setlocal

echo ==========================================
echo  INFORSA - Setup Flutter Laptop Baru
echo ==========================================
echo.

REM Pastikan script berjalan dari folder project script ini
cd /d "%~dp0"

echo [1/6] Cek Flutter tersedia...
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter tidak ditemukan di PATH.
  echo Install Flutter lalu restart terminal.
  pause
  exit /b 1
)

echo [2/6] Lepas atribut read-only pada file lock jika ada...
if exist pubspec.lock attrib -R pubspec.lock

echo [3/6] Bersihkan cache lokal project...
if exist pubspec.lock del /f /q pubspec.lock
if exist .dart_tool rmdir /s /q .dart_tool
if exist build rmdir /s /q build

echo [4/6] Flutter clean...
call flutter clean
if errorlevel 1 (
  echo flutter clean gagal.
  pause
  exit /b 1
)

echo [5/6] Ambil dependency...
call flutter pub get
if errorlevel 1 (
  echo flutter pub get gagal.
  echo Coba jalankan CMD sebagai Administrator lalu ulangi script ini.
  pause
  exit /b 1
)

echo [6/6] Cek environment Flutter...
call flutter doctor -v

echo.
echo Menjalankan aplikasi di Chrome...
call flutter run -d chrome
if errorlevel 1 (
  echo Gagal menjalankan di Chrome.
  echo Pastikan Chrome terinstall dan Web support Flutter aktif.
  echo Cek daftar device dengan: flutter devices
  pause
  exit /b 1
)

echo.
echo ==========================================
echo Setup selesai. Aplikasi sudah dijalankan di Chrome.
echo ==========================================
echo.
pause
endlocal
