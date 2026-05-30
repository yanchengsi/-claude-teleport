# 独立 Toast 测试脚本 - 在终端中手动运行: powershell -File test_toast.ps1
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class ToastFix {
    [DllImport("shell32.dll", SetLastError = true)]
    public static extern int SetCurrentProcessExplicitAppUserModelID(
        [MarshalAs(UnmanagedType.LPWStr)] string AppID);
}
"@

# 步骤1: 在一切之前设置 AppId
$appId = 'Microsoft.Windows.Explorer'
$result = [ToastFix]::SetCurrentProcessExplicitAppUserModelID($appId)
Write-Host "SetCurrentProcessExplicitAppUserModelID($appId) = $result"

# 步骤2: 用 WinRT 原生 API 发通知
[Windows.UI.Notifications.ToastNotificationManager, Windows, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

$xml = [Windows.Data.Xml.Dom.XmlDocument]::new()
$xml.LoadXml(@'
<toast>
  <visual>
    <binding template="ToastText02">
      <text id="1">🔔 Can you see this?</text>
      <text id="2">If visible, Toast system works with Explorer AppId</text>
    </binding>
  </visual>
</toast>
'@)

$toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId)
$notifier.Show($toast)
Write-Host "Toast sent! Check your screen."
Start-Sleep -Seconds 3
Write-Host "Done."
