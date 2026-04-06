# בניית טיימר פומודורו משלכם במגש המערכת (System Tray) באמצעות PowerShell בלבד

**[טכניקת פומודורו](https://en.wikipedia.org/wiki/Pomodoro_Technique)** היא שיטה פופולרית לניהול זמן שפותחה על ידי פרנצ'סקו צ'ירילו בסוף שנות ה-80. הקונספט פשוט: מחלקים את העבודה למקטעים של 25 דקות (הנקראים "פומודורו"), המופרדים בהפסקות קצרות של 5 דקות. לאחר כל ארבעה מחזורים, לוקחים הפסקה ארוכה יותר. גישה זו עוזרת לשמור על ריכוז, למנוע שחיקה ומאפשרת שליטה טובה יותר בזרימת העבודה.

במאמר זה, אראה לכם כיצד לכתוב טיימר פומודורו משלכם באמצעות PowerShell בלבד. הוא ירוץ ברקע, יציג ספירה לאחור בכותרת החלון, וניתן יהיה לשלוט בו דרך תפריט הקשר במגש המערכת (System Tray) — **וכל זה תוך שמירה על סקריפט של פחות מ-100 שורות קוד**.

ננצל את ה-**.NET Framework** (ספריות WinForms), מה שיאפשר לנו:

1. **ליצור אייקון באזור ההתראות (System Tray).**
2. **להטמיע תפריט הקשר (Context Menu).**
3. **להשתמש באובייקט "Timer" להרצת קוד ברקע.**

---

## שלב 1: הכנת ספריות ומשתנים

כדי ליצור את הממשק הגרפי, אנו זקוקים לספריות `System.Windows.Forms` ו-`System.Drawing`. נגדיר גם את הגדרות הזמן ונשתמש בטווח ההכרה (Scope) של `$script:` כדי להבטיח שלמטפלי האירועים (לחיצות על התפריט) תהיה גישה ישירה למשתני הטיימר.

```powershell
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# הגדרות זמן (בדקות)
$workTime = 25
$breakTime = 5
$script:timeLeft = $workTime * 60
$script:isWorking = $true
```

## שלב 2: יצירת אייקון המגש (NotifyIcon)

אובייקט ה-`NotifyIcon` אחראי על הופעת האייקון במגש המערכת (ליד השעון). ליציבות מרבית ב-Windows 10/11, נשתמש באייקון המערכת הסטנדרטי "Information" (עיגול כחול עם האות "i").

```powershell
$script:ni = New-Object System.Windows.Forms.NotifyIcon
$script:ni.Icon = [System.Drawing.SystemIcons]::Information
$script:ni.Visible = $true
$script:ni.Text = "פומודורו: לחיצה ימנית להתחלה"
```

## שלב 3: לוגיקת הטיימר ואוטומציית שלבים

הטיימר פועל כאירוע (Event) שמופעל מדי שנייה. לוגיקה זו כוללת מעבר אוטומטי: כאשר זמן העבודה מסתיים, הסקריפט עובר אוטומטית למצב הפסקה ומתחיל ספירה לאחור חדשה.

*הערה חשובה:* בגרסאות PowerShell מודרניות (7+), יש להמיר מספרים בצורה מפורשת ל-`[int]` בעת עיצוב מחרוזות כדי למנוע שגיאות עיבוד.

```powershell
$script:timer = New-Object System.Windows.Forms.Timer
$script:timer.Interval = 1000

$script:timer.Add_Tick({
    if ($script:timeLeft -gt 0) {
        $script:timeLeft--
    } else {
        # החלפת מצב עבודה <-> הפסקה
        $script:isWorking = -not $script:isWorking
        $script:timeLeft = ($script:isWorking ? $workTime : $breakTime) * 60
        
        # התראת "בלון" של Windows
        $msg = if ($script:isWorking) { "זמן לעבוד!" } else { "זמן להפסקה!" }
        $script:ni.ShowBalloonTip(5000, "Pomodoro", $msg, "Info")
    }

    # עדכונים ויזואליים (מגש המערכת, כותרת החלון, קונסולה)
    [int]$m = [Math]::Floor($script:timeLeft / 60)
    [int]$s = $script:timeLeft % 60
    $phase = if ($script:isWorking) { "עבודה" } else { "הפסקה" }
    $displayTime = "{0:D2}:{1:D2}" -f $m, $s
    
    $script:ni.Text = "פומודורו [$phase]: $displayTime"
    $host.UI.RawUI.WindowTitle = "[$displayTime] - $phase"
    Write-Host "`r>>> שלב: $phase | זמן נותר: $displayTime    " -NoNewline -ForegroundColor Cyan
})
```

## שלב 4: ניהול תפריט ההקשר

כדי להבטיח שכפתורי התפריט יפעלו בצורה אמינה בכל גרסת PowerShell, אנו יוצרים אותם כאובייקטי `ToolStripMenuItem` נפרדים ונרשמים לאירוע ה-`Click`.

```powershell
$menu = New-Object System.Windows.Forms.ContextMenuStrip

$btnStart = New-Object System.Windows.Forms.ToolStripMenuItem("הפעלה / השהייה")
$btnStart.add_Click({
    if ($script:timer.Enabled) { $script:timer.Stop() } else { $script:timer.Start() }
})

$btnExit = New-Object System.Windows.Forms.ToolStripMenuItem("יציאה")
$btnExit.add_Click({
    $script:ni.Visible = $false
    [System.Windows.Forms.Application]::Exit()
    Stop-Process -Id $PID
})

[void]$menu.Items.Add($btnStart)
[void]$menu.Items.Add("-") # קו מפריד
[void]$menu.Items.Add($btnExit)
$script:ni.ContextMenuStrip = $menu
```

## שלב 5: הרצת לולאת האירועים

ללא פקודה זו, הסקריפט יסתיים מיד לאחר ביצוע הקוד. פקודת ה-`Run()` גורמת לאפליקציה "להמתין" לפעולות משתמש ולאותות מהטיימר.

```powershell
[System.Windows.Forms.Application]::Run()
```

---

**הקוד המלא והסופי**
זמין במאגר: [pomodoro.ps1](https://github.com/hypo69/PomodoroPS/blob/master/he/pomodoro.ps1)