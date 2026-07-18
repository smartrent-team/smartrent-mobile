# Script khởi động đồng thời 2 tunnel LocalXpose cho Backend (3000) và AI (8000)
Write-Host "Dang khoi dong cac tunnel LocalXpose..." -ForegroundColor Green

# 1. Mo cua so moi chay tunnel cho Backend (Port 3000)
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host '--- LOCALXPOSE PORT 3000 (Backend) ---' -ForegroundColor Cyan; loclx tunnel http --to 3000"

# 2. Mo cua so moi chay tunnel cho AI (Port 8000)
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host '--- LOCALXPOSE PORT 8000 (AI Service) ---' -ForegroundColor Magenta; loclx tunnel http --to 8000"

Write-Host "Da khoi chay 2 tunnel thanh cong trong cua so rieng biet!" -ForegroundColor Yellow
Write-Host "Hay copy 2 link duong dan tuong ung va dan vao file config.json." -ForegroundColor Yellow
