@echo off
echo ========================================================
echo   Starting ClaimDesk (Enterprise Expense Platform)
echo ========================================================
echo.
echo Launching ClaimDesk on Web Server (Port 5050)...
echo Once started, open http://localhost:5050 in your browser!
echo.
flutter run -d web-server --web-port=5050
pause

