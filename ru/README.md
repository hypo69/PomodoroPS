# Создаем свой Pomodoro-таймер в системном трее на чистом PowerShell

**[Техника Pomodoro](https://habr.com/ru/articles/705334/)** — это популярный метод управления временем, разработанный Франческо Чирилло в конце 1980-х. Его суть проста: вы разбиваете работу на 25-минутные интервалы (называемые «помидорами»), разделенные короткими 5-минутными перерывами. После каждых четырех циклов следует длинный перерыв. Это помогает сохранять концентрацию, избегать выгорания и лучше контролировать рабочий процесс.

В этой статье я покажу, как написать свой Pomodoro-таймер на чистом PowerShell, который будет работать в фоновом режиме, отображать обратный отсчет в заголовке окна и управляться через контекстное меню в системном трее — **при этом весь скрипт занимает менее 100 строк кода**.

Мы будем использовать **.NET Framework** (библиотеки WinForms), что позволит нам:

1. **Создать иконку в области уведомлений.**
2. **Работать с контекстным меню.**
3. **Использовать объект «Таймер» для выполнения кода в фоновом режиме.**

---

## Шаг 1: Подготовка библиотек и переменных

Для создания графического интерфейса нам понадобятся сборки `System.Windows.Forms` и `System.Drawing`. Также мы определим настройки времени и будем использовать область видимости `$script:`, чтобы обработчики событий (клики по меню) имели прямой доступ к переменным таймера.

```powershell
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# Настройки времени (в минутах)
$workTime = 25
$breakTime = 5
$script:timeLeft = $workTime * 60
$script:isWorking = $true
```

## Шаг 2: Создание иконки в трее (NotifyIcon)

Объект `NotifyIcon` отвечает за появление иконки в системном трее (рядом с часами). Для максимальной стабильности в Windows 10/11 мы будем использовать стандартную системную иконку «Information» (синий кружок с буквой «i»).

```powershell
$script:ni = New-Object System.Windows.Forms.NotifyIcon
$script:ni.Icon = [System.Drawing.SystemIcons]::Information
$script:ni.Visible = $true
$script:ni.Text = "Pomodoro: Нажмите правой кнопкой"
```

## Шаг 3: Логика таймера и автоматизация фаз

Таймер работает как событие, которое срабатывает каждую секунду. Здесь реализован автоматический переход: когда заканчивается время работы, скрипт сам переключается на отдых и начинает новый отсчет.

*Важный нюанс:* В современных версиях PowerShell (7+) при форматировании времени необходимо принудительно приводить числа к типу `[int]`, чтобы избежать ошибок обработки строк.

```powershell
$script:timer = New-Object System.Windows.Forms.Timer
$script:timer.Interval = 1000

$script:timer.Add_Tick({
    if ($script:timeLeft -gt 0) {
        $script:timeLeft--
    } else {
        # Смена режима Работа <-> Отдых
        $script:isWorking = -not $script:isWorking
        $script:timeLeft = ($script:isWorking ? $workTime : $breakTime) * 60
        
        # Всплывающее уведомление в Windows
        $msg = if ($script:isWorking) { "Пора за работу!" } else { "Время отдыхать!" }
        $script:ni.ShowBalloonTip(5000, "Pomodoro", $msg, "Info")
    }

    # Визуальное обновление (Трей, Заголовок окна, Консоль)
    [int]$m = [Math]::Floor($script:timeLeft / 60)
    [int]$s = $script:timeLeft % 60
    $phase = if ($script:isWorking) { "РАБОТА" } else { "ОТДЫХ" }
    $displayTime = "{0:D2}:{1:D2}" -f $m, $s
    
    $script:ni.Text = "Pomodoro [$phase]: $displayTime"
    $host.UI.RawUI.WindowTitle = "[$displayTime] - $phase"
    Write-Host "`r>>> Фаза: $phase | Осталось: $displayTime    " -NoNewline -ForegroundColor Cyan
})
```

## Шаг 4: Управление через контекстное меню

Чтобы кнопки меню гарантированно срабатывали в любой версии PowerShell, мы создаем их как отдельные объекты `ToolStripMenuItem` и подписываемся на событие `Click`.

```powershell
$menu = New-Object System.Windows.Forms.ContextMenuStrip

$btnStart = New-Object System.Windows.Forms.ToolStripMenuItem("Старт / Пауза")
$btnStart.add_Click({
    if ($script:timer.Enabled) { $script:timer.Stop() } else { $script:timer.Start() }
})

$btnExit = New-Object System.Windows.Forms.ToolStripMenuItem("Выход")
$btnExit.add_Click({
    $script:ni.Visible = $false
    [System.Windows.Forms.Application]::Exit()
    Stop-Process -Id $PID
})

[void]$menu.Items.Add($btnStart)
[void]$menu.Items.Add("-") # Разделитель
[void]$menu.Items.Add($btnExit)
$script:ni.ContextMenuStrip = $menu
```

## Шаг 5: Запуск цикла обработки событий

Без этого метода скрипт завершится мгновенно после выполнения кода. Команда `Run()` заставляет приложение «ожидать» действий пользователя и сигналов таймера.

```powershell
[System.Windows.Forms.Application]::Run()
```

---

**Итоговый полный код**
можно найти в репозитории: [pomodoro.ps1](https://github.com/hypo69/PomodoroPS/blob/master/ru/pomodoro.ps1)
