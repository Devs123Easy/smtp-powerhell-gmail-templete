# 📬 Smtp PowerShell Gmail Template

Monitor disk space usage on Windows machines and send alert emails via Gmail using PowerShell.  
Customizable thresholds, styled HTML emails and logging to file – all in one script.

---

## ✨ Features

- ✅ Checks free space on local drives
- 📉 Sends alert when space drops below defined thresholds
- 🛑 Sends **critical alerts** when space is dangerously low
- 📨 Sends email via Gmail SMTP with inline HTML
- 📂 Optional logging to `log.txt`
- 🔒 Uses Gmail App Passwords for secure authentication

---

## ⚙️ Requirements

- **PowerShell 7.5.0 or newer**
- Enabled **Gmail 2FA (Two-Factor Authentication)**
- Created **Gmail App Password**  
  👉 [How to create one](https://support.google.com/accounts/answer/185833?hl=en)

---

## 🚀 How to Use

1. **Clone this repo** or copy the `.ps1` file
2. Open PowerShell and run:

   ```powershell
   .\DiskMonitor.ps1
---
# 📌 Configuration
Inside the script, configure the following:

   ```powershell
   $logPath = "C:\users\example\log.txt"    # "none" to disable logging or $startPath if the file log.txt is in the same path as this script
   $gmailUser = "yourgmail@gmail.com"       # Your Gmail address
   $gmailAppPassword = "your-app-password"  # Your Gmail App Password
   $thresholdGB = @(50, 40, 30, 20)         # Warning thresholds in descending order
   $criticalThresholdGB = 10                # Critical threshold (only one value allowed)
   ```
---
# 📧 Email Example
- Styled HTML message
- Timestamp

# 📄 License
MIT License © Devs123Easy

---
💡 Tip
Want to turn this into a scheduled task? Use Task Scheduler to run it every X hours automatically and monitor servers without lifting a finger 💪

