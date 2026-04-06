# PomodoroPS

# Создаем свой Pomodoro-таймер в системном трее с помощью PowerShell

В этой статье я показываю, как написать полноценный Pomodoro-таймер,
который будет работать в фоновом режиме, отображаться в системном трее (рядом с часами)
и отправлять уведомления.

Мы будем использовать **.NET Framework** (библиотеки WinForms), что позволит нам:

1. Создать иконку в области уведомлений.
2. Работать с контекстным меню.
3. Использовать объект «Таймер» для выполнения кода в фоновом режиме.

---

## Шаг 1: Подключаем библиотеки и настраиваем переменные

Для графического интерфейса нам понадобятся сборки `System.Windows.Forms` и `System.Drawing`. Также зададим стандартные интервалы (25 минут работы и 5 минут отдыха).

```powershell
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$workTime = 25
$breakTime = 5
$script:timeLeft = $workTime * 60 # Время в секундах
$script:isWorking = $true        # Флаг: работаем или отдыхаем
```

## Шаг 2: Создаем иконку в трее (NotifyIcon)

Объект `NotifyIcon` — это и есть та самая иконка в трее. Чтобы она работала, нам нужно вытащить стандартную иконку из самого процесса PowerShell.

```powershell
$ni = New-Object System.Windows.Forms.NotifyIcon
$ni.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Process -id $PID).Path)
$ni.Visible = $true
$ni.Text = "Pomodoro: Готов к работе"
```

## Шаг 3: Логика таймера

Таймер в PowerShell работает как событие. Каждую секунду (1000 мс) он будет уменьшать счетчик и обновлять текст при наведении на иконку.

```powershell
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000 

$timer.Add_Tick({
    if ($script:timeLeft -gt 0) {
        $script:timeLeft--
        $m = [Math]::Floor($script:timeLeft / 60)
        $s = $script:timeLeft % 60
        # Обновляем текст при наведении на иконку
        $ni.Text = "Осталось: {0:D2}:{1:D2} ({2})" -f $m, $s, ($script:isWorking ? "Работа" : "Отдых")
    } else {
        $timer.Stop()
        $script:isWorking = -not $script:isWorking # Меняем режим
        $script:timeLeft = ($script:isWorking ? $workTime : $breakTime) * 60
        
        # Показываем всплывающее уведомление в Windows
        $msg = $script:isWorking ? "Пора работать!" : "Время отдыхать!"
        $ni.ShowBalloonTip(3000, "Pomodoro", $msg, "Info")
    }
})
```

## Шаг 4: Контекстное меню

Чтобы управлять программой, добавим меню, которое появляется при нажатии правой кнопкой мыши.

```powershell
$menu = New-Object System.Windows.Forms.ContextMenuStrip
$btnStart = $menu.Items.Add("Старт / Пауза")
$btnReset = $menu.Items.Add("Сброс")
$menu.Items.Add("-") # Разделитель
$btnExit = $menu.Items.Add("Выход")

$btnStart.Add_Click({ 
    if ($timer.Enabled) { $timer.Stop() } else { $timer.Start() } 
})

$btnExit.Add_Click({
    $ni.Visible = $false # Важно скрыть иконку перед выходом
    [System.Windows.Forms.Application]::Exit()
    Exit
})

$ni.ContextMenuStrip = $menu
```

## Шаг 5: Запуск цикла обработки событий

В PowerShell скрипт обычно завершается сразу после выполнения последней строки. Чтобы приложение «жило» и реагировало на клики, нужно запустить бесконечный цикл обработки событий Windows.

```powershell
[System.Windows.Forms.Application]::Run()
```

---

## Как запустить скрипт

1. Скопируйте весь код в файл с расширением `.ps1` (например, `pomodoro.ps1`).
2. Нажмите правой кнопкой мыши по файлу и выберите **Run with PowerShell** (Выполнить с помощью PowerShell).
3. В трее появится синяя иконка. Нажмите на нее правой кнопкой мыши и выберите **Старт**.

## Итоговый полный код

<details>
<summary>Нажмите, чтобы развернуть код</summary>

```powershell
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$workTime = 25
$breakTime = 5
$script:timeLeft = $workTime * 60
$script:isWorking = $true

$ni = New-Object System.Windows.Forms.NotifyIcon
$ni.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Process -id $PID).Path)
$ni.Visible = $true
$ni.Text = "Pomodoro: Готов к работе"

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000 

$timer.Add_Tick({
    if ($script:timeLeft -gt 0) {
        $script:timeLeft--
        $m = [Math]::Floor($script:timeLeft / 60)
        $s = $script:timeLeft % 60
        $ni.Text = "Осталось: {0:D2}:{1:D2} ({2})" -f $m, $s, ($script:isWorking ? "Работа" : "Отдых")
    } else {
        $timer.Stop()
        $script:isWorking = -not $script:isWorking
        $script:timeLeft = ($script:isWorking ? $workTime : $breakTime) * 60
        $ni.ShowBalloonTip(3000, "Pomodoro", ($script:isWorking ? "Пора работать!" : "Время отдыхать!"), "Info")
    }
})

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$btnStart = $menu.Items.Add("Старт / Пауза")
$btnReset = $menu.Items.Add("Сброс")
$menu.Items.Add("-")
$btnExit = $menu.Items.Add("Выход")

$btnStart.Add_Click({ if ($timer.Enabled) { $timer.Stop() } else { $timer.Start() } })
$btnReset.Add_Click({ $timer.Stop(); $script:timeLeft = $workTime * 60; $ni.Text = "Сброшено" })
$btnExit.Add_Click({ $ni.Visible = $false; [System.Windows.Forms.Application]::Exit(); Exit })

$ni.ContextMenuStrip = $menu
[System.Windows.Forms.Application]::Run()
```

</details>

## Заключение

Этот проект показывает, насколько гибким может быть PowerShell. Мы использовали таймеры, делегаты событий и системный трей всего в 50 строках кода. На базе этого скрипта можно добавить звуковые уведомления (`[System.Media.SystemSounds]::Beep.Play()`) или запись логов работы в текстовый файл для учета продуктивности.