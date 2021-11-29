(New-Object net.webclient).Downloadfile("https://download.slicer.org/download?os=win&stability=any", "C:\slicer.exe")
Start-Process C:\slicer.exe /S -NoNewWindow -Wait
$install_dir = (Get-ChildItem -Path C:\ProgramData\NA-MIC -Filter "Slicer*" -Directory).Fullname
New-Item -ItemType SymbolicLink -Path "C:\Users\Public\Desktop" -Value "$install_dir\Slicer.exe" -Name "Slicer"
Remove-Item C:\slicer.exe
