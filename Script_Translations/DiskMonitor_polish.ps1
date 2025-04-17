$startPath = Join-Path -Path $PSScriptRoot -ChildPath "log.txt"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# WAŻNE! Aby skrypt zadziałał poprawnie uruchom go za pomocą wersji PowerShell 7.5.0 lub nowszej.

#########################
##                     ##
##  📦 KONFIGURACJA   ##
##                     ##
#########################
$logPath = $startPath                         # Ścieżka do pliku z logami (ustaw na "none" jeśli nie chcesz logów lub $startPath jeśli plik log.txt jest w tym samym folderze co ten plik)
$gmailUser = "twójgmail@gmail.com"            # Twój gmail
$gmailAppPassword = "twoje-hasło-aplikacji"   # Hasło aplikacji google (czyli jak masz hasło np. edfw wtsg jbym khgz to musisz wpisać "edfwwtsgjbymkhgz")
# Jeśli nie wiesz jak pozyskać hasło aplikacji w google, tu masz poradnik:

# 1. Włącz uwierzytelnianie dwuskładnikowe (2FA) na swoim Gmailu
#    (przejdź do https://myaccount.google.com/security)

#2. Wejdź na 👉 https://myaccount.google.com/apppasswords
#   (Zaloguj się ponownie jeśli trzeba)

#   Jeśli strona się nie otwiera lub masz błąd:
#   ➤ Upewnij się, że używasz konta osobistego (nie firmowego Google Workspace)
#   ➤ Konto musi mieć włączoną weryfikację dwuetapową

#   Na stronie "Hasła aplikacji":
#   Wpisz np. PowerShell
#   Kliknij Utwórz

#   Skopiuj 16-znakowe hasło aplikacji i wpisz je w pole "edfwwtsgjbymkhgz" (usuwając z pola edfwwtsgjbymkhgz)

$thresholdGB = @(50, 40, 30, 20)              # Kiedy ma się wysyłać normaly alarm (wymień po przecinku MALEJĄCO)
$criticalThresholdGB = 10                     # Kiedy ma zostać wysłany krytyczny alarm (możesz wpisać tylko jedną liczbę)






$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$logoBase64 = "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"
$securePass = ConvertTo-SecureString $gmailAppPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($gmailUser, $securePass)
$alerts = @()
$subject = $null
$drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType = 3"

foreach ($drive in $drives) {
    $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
    $totalGB = [math]::Round($drive.Size / 1GB, 2)
    $deviceID = $drive.DeviceID

    if ($freeGB -lt $criticalThresholdGB) {
        $notHTMLformat = "🔥 KRYTYCZNY: Dysk $deviceID ma $freeGB GB wolnego z $totalGB GB (próg: $criticalThresholdGB GB)"
        $alerts += "🔥 <strong>KRYTYCZNY</strong>: Dysk <strong>$deviceID</strong> ma <strong>$freeGB GB</strong> wolnego z $totalGB GB (próg: $criticalThresholdGB GB)"
        $subject = "🔥🚨 KRYTYCZNY ALARM: Mało miejsca na dysku!"
        continue
    }

    foreach ($threshold in $thresholdGB) {
        if ($freeGB -lt $threshold) {
            $notHTMLformat = "⚠️ OSTRZEŻENIE: Dysk $deviceID ma $freeGB GB wolnego z $totalGB GB (próg: $threshold GB)"
            $alerts += "⚠️ <strong>OSTRZEŻENIE</strong>: Dysk <strong>$deviceID</strong> ma <strong>$freeGB GB</strong> wolnego z $totalGB GB (próg: $threshold GB)"
            if (-not $subject) {
                $subject = "🚨 ALARM: Mało miejsca na dysku!"
            }
            break
        }
    }
}

if ($alerts.Count -gt 0 -and $subject) {
    $bodyInner = ($alerts -join "<br>")

    $bodyHtml = @"
<!DOCTYPE html>
<html lang="pl">
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
  <p class="timestamp">Data generacji: $timestamp</p>
  <hr class="custom">
<div class="footer">
  <a href="https://github.com/Devs123Easy" target="_blank" style="text-decoration: none; color: inherit;">
    Powered by Devs123Easy
    <img src="cid:logo123" style="height:30px; vertical-align:middle; margin-left:6px;" alt="Logo" />
  </a>
</div>
</body>
</html>
"@

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
            Add-Content -Path $logPath -Value "#############################################################" -Encoding UTF8
            Add-Content -Path $logPath -Value "##                                                                                                                                                                           ##" -Encoding UTF8
            Add-Content -Path $logPath -Value "##                                                                      Log File Start                                                                        ##" -Encoding UTF8
            Add-Content -Path $logPath -Value "##                                                                                                                                                                           ##" -Encoding UTF8
            Add-Content -Path $logPath -Value "#############################################################" -Encoding UTF8
            Add-Content -Path $logPath -Value "" -Encoding UTF8
        }
        $logEntry = @"
[$timestamp]: Wysłano wiadomość gmail pod adres $gmailUser o tytule: "$subject" i treści: "$notHTMLformat".
----------------------------------------
"@
        Add-Content -Path $logPath -Value $logEntry -Encoding UTF8
    }
    else {
        exit 0
    }
}
else {
    if ($logPath -ne "none") {
        if (-not (Test-Path -Path $logPath)) {
            New-Item -Path $logPath -ItemType File -Force | Out-Null
            Add-Content -Path $logPath -Value "#############################################################" -Encoding UTF8
            Add-Content -Path $logPath -Value "##                                                                                                                                                                           ##" -Encoding UTF8
            Add-Content -Path $logPath -Value "##                                                                      Log File Start                                                                        ##" -Encoding UTF8
            Add-Content -Path $logPath -Value "##                                                                                                                                                                           ##" -Encoding UTF8
            Add-Content -Path $logPath -Value "#############################################################" -Encoding UTF8
            Add-Content -Path $logPath -Value "" -Encoding UTF8
        }
        $logEntry = @"
[$timestamp]: Nie wysłano wiadomości gmail ponieważ na komputerze jest jeszcze $freeGB GB wolnego miejsca z $totalGB wolnego.
----------------------------------------
"@
        Add-Content -Path $logPath -Value $logEntry -Encoding UTF8
    }
}
