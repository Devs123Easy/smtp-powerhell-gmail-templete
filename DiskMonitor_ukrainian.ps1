$startPath = Join-Path -Path $PSScriptRoot -ChildPath "log.txt"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
####################
# ⚙️ Налаштування #
####################
$logPath = $startPath                       # Шлях до файлу журналу ("none" для відключення або $startPath якщо log.txt в тій же папці)
$gmailUser = "yourgmail@gmail.com"         # Ваша адреса Gmail
$gmailAppPassword = "your-app-password"    # Пароль додатку Gmail
$thresholdGB = @(50, 40, 30, 20)            # Порогові значення для попереджень (спаданням)
$criticalThresholdGB = 10                  # Критичний поріг (одне значення)

# 💙💛💙💛💙💛💙💛💙💛💙💛💙💛💙💛💙💛💙💛💙💛

# 📅 Поточна дата
$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

# 🔒 Захищене збереження пароля
$securePass = ConvertTo-SecureString $gmailAppPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($gmailUser, $securePass)

# 📊 Перевірка дисків
$alerts = @()
$subject = $null
$drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType = 3"

foreach ($drive in $drives) {
    $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
    $totalGB = [math]::Round($drive.Size / 1GB, 2)
    $deviceID = $drive.DeviceID

    if ($freeGB -lt $criticalThresholdGB) {
        $notHTMLformat = "🔥 КРИТИЧНО: Диск $deviceID має лише $freeGB ГБ вільного з $totalGB ГБ (поріг: 10 ГБ)"
        $alerts += "🔥 <strong>КРИТИЧНО</strong>: Диск <strong>$deviceID</strong> має <strong>$freeGB ГБ</strong> вільного з $totalGB ГБ (поріг: 10 ГБ)"
        $subject = "🔥🚨 КРИТИЧНЕ ПОПЕРЕДЖЕННЯ: Мало місця на диску!"
        continue
    }

    foreach ($threshold in $thresholdGB) {
        if ($freeGB -lt $threshold) {
            $notHTMLformat = "⚠️ Попередження: Диск $deviceID має $freeGB ГБ вільного з $totalGB ГБ (поріг: $threshold ГБ)"
            $alerts += "⚠️ <strong>ПОПЕРЕДЖЕННЯ</strong>: Диск <strong>$deviceID</strong> має <strong>$freeGB ГБ</strong> вільного з $totalGB ГБ (поріг: $threshold ГБ)"
            if (-not $subject) {
                $subject = "🚨 Попередження: Недостатньо місця на диску"
            }
            break
        }
    }
}

# ✉️ Якщо є попередження — надсилаємо лист
if ($alerts.Count -gt 0 -and $subject) {
    $bodyInner = ($alerts -join "<br>")

    $bodyHtml = @"
<!DOCTYPE html>
<html lang="uk">
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: 'Segoe UI', sans-serif; font-size: 14px; }
    strong { color: #b30000; }
    .footer { font-size: 12px; color: gray; margin-top: 30px; }
    .timestamp { font-size: 12px; color: #666; }
    hr.custom { width: 50%; margin: 1px; border: 1px solid #ccc; opacity: 0.4; }
  </style>
</head>
<body>
  <h2>$subject</h2>
  <p>$bodyInner</p>
  <p class="timestamp">Дата генерації: $timestamp</p>
  <hr class="custom">
  <div class="footer">
    <a href="https://github.com/Devs123Easy" target="_blank" style="text-decoration: none; color: inherit;">
      Створено Devs123Easy
      <img src="cid:logo123" style="height:30px; vertical-align:middle; margin-left:6px;" alt="Logo" />
    </a>
  </div>
</body>
</html>
"@

    # Логотип (встав свій base64)
    $logoBase64 = "..." # Тут вставляється реальний base64
    $logoBytes = [Convert]::FromBase64String($logoBase64)
    $logoStream = New-Object System.IO.MemoryStream(,$logoBytes)
    $linkedLogo = New-Object System.Net.Mail.LinkedResource($logoStream, "image/png")
    $linkedLogo.ContentId = "logo123"
    $linkedLogo.TransferEncoding = [System.Net.Mime.TransferEncoding]::Base64

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $altView = [System.Net.Mail.AlternateView]::CreateAlternateViewFromString($bodyHtml, $utf8NoBom, "text/html")
    $altView.LinkedResources.Add($linkedLogo)

    $mail = New-Object System.Net.Mail.MailMessage
    $mail.From = $gmailUser
    $mail.To.Add($gmailUser)
    $mail.Subject = $subject
    $mail.SubjectEncoding = $utf8NoBom
    $mail.BodyEncoding = $utf8NoBom
    $mail.IsBodyHtml = $true
    $mail.AlternateViews.Add($altView)

    $smtp = New-Object Net.Mail.SmtpClient("smtp.gmail.com", 587)
    $smtp.EnableSsl = $true
    $smtp.Credentials = $cred

    $smtp.Send($mail)

    if ($logPath -ne "none") {
        if (-not (Test-Path -Path $logPath)) {
            New-Item -Path $logPath -ItemType File -Force | Out-Null
        }
        $logEntry = @"
[$timestamp]: Надіслано email на адресу $gmailUser з темою: "$subject" і повідомленням: "$notHTMLformat".
----------------------------------------
"@
        Add-Content -Path $logPath -Value $logEntry -Encoding UTF8
    }
}
else {
    if ($logPath -ne "none") {
        if (-not (Test-Path -Path $logPath)) {
            New-Item -Path $logPath -ItemType File -Force | Out-Null
        }
        $logEntry = @"
[$timestamp]: Повідомлення не надіслано. На дисках залишилось ще достатньо вільного місця.
----------------------------------------
"@
        Add-Content -Path $logPath -Value $logEntry -Encoding UTF8
    }
}
