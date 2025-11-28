# Описание

# Нумерация релизов такая: vMajor.Minor.Patch+Build
# .\tag.ps1                # Автоинкремент patch + build
# .\tag.ps1 -Bump minor    # Инкремент minor
# .\tag.ps1 -Annotated -Message "Release notes"
# .\tag.ps1 -Init v1.0.0+1 # Если тегов нет

param(
    [ValidateSet('major','minor','patch')]
    [string]$Bump = 'patch',      # Что инкрементировать
    [switch]$Annotated,           # Создавать аннотированный тег (-a)
    [string]$Message,             # Сообщение для аннотированного тега (-m).
    [string]$Init,                # Начальный тег, если нет тегов (например, v1.0.0+1).
    [switch]$Help,                # Показать справку
    [ValidateSet('beta','rc')]
    [string]$PreRelease           # Предрелизный суффикс (beta или rc)
)


function Show-Help {
    Write-Host @"
Использование: .\tag.ps1 [опции]

Опции:
  -Bump <major|minor|patch>    Что инкрементировать (по умолчанию patch)
  -Annotated                   Создать аннотированный тег
  -Message <текст>             Сообщение для аннотированного тега
  -Init <vX.Y.Z+N>             Начальный тег, если тегов нет
  -PreRelease <beta|rc>        Добавить суффикс предрелиза (-beta или -rc)
  -Help                        Показать эту справку

Примеры:
  .\tag.ps1
  .\tag.ps1 -Bump minor
  .\tag.ps1 -Annotated -Message "Release notes"
  .\tag.ps1 -PreRelease beta
"@
    exit
}

if ($Help) { Show-Help }

# ===== Утилиты =====

function Fail($msg) {
    Write-Error $msg
    exit 1
}

function Ensure-Git {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Fail "Git не найден в PATH. Установи Git и запусти заново."
    }
}

function Ensure-GitRepo {
    $top = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0) {
        Fail "Текущая директория не является Git-репозиторием."
    }
}




function Get-LatestTagObject {
    git fetch --tags | Out-Null
    $latestTag = git tag --sort=-creatordate | Select-Object -First 1

    if (-not $latestTag) {
        return $null
    }

    $pattern = '^v(?<major>[0-9]+)\.(?<minor>[0-9]+)\.(?<patch>[0-9]+)\+(?<build>[0-9]+)$'
    if ($latestTag -match $pattern) {
        return [pscustomobject]@{
            Tag   = $latestTag
            Major = [int]$Matches.major
            Minor = [int]$Matches.minor
            Patch = [int]$Matches.patch
            Build = [int]$Matches.build
        }
    } else {
        Fail "Последний тег '$latestTag' не соответствует формату vMAJOR.MINOR.PATCH+BUILD."
    }
}


function Parse-Tag([string]$t) {
    $pattern = '^v(?<major>[0-9]+)\.(?<minor>[0-9]+)\.(?<patch>[0-9]+)\+(?<build>[0-9]+)$'
    if ($t -match $pattern) {
        return [pscustomobject]@{
            Tag   = $t
            Major = [int]$Matches.major
            Minor = [int]$Matches.minor
            Patch = [int]$Matches.patch
            Build = [int]$Matches.build
        }
    } else {
        Fail "Тег '$t' не соответствует шаблону vMAJOR.MINOR.PATCH+BUILD, например v1.1.2+13."
    }
}

function Compute-NextTag($current) {
    # Если нет текущих тегов — используем Init или дефолтный старт
    if ($null -eq $current) {
        if ($Init) {
            # Если Init задан — создаём ровно этот тег (без автоинкремента)
            return $Init
        } else {
            # Иначе — дефолт: первый тег
            Write-Host "Тегов не найдено. Создаю начальный тег 'v0.1.0+1'. Можно переопределить параметром -Init."
            return "v0.1.0+1"
        }
    }

    $major = $current.Major
    $minor = $current.Minor
    $patch = $current.Patch
    $build = $current.Build

    switch ($Bump) {
        'major' {
            $major = $major + 1
            $minor = 0
            $patch = 0
        }
        'minor' {
            $minor = $minor + 1
            $patch = 0
        }
        'patch' {
            $patch = $patch + 1
        }
    }

    # Билд всегда инкрементируем на 1
    $build = $build + 1

    return "v$major.$minor.$patch+$build"
}

function Tag-Exists-Locally([string]$tag) {
    git rev-parse $tag 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Tag-Exists-Remotely([string]$tag) {
    $remoteTags = git ls-remote --tags origin
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Не удалось получить теги с 'origin'. Продолжаю без удалённой проверки."
        return $false
    }
    return ($remoteTags -match "refs/tags/$([Regex]::Escape($tag))")
}

function Create-And-Push-Tag([string]$tag) {
    if ($Annotated) {
        if (-not $Message) { $Message = "Release $tag" }
        git tag -a $tag -m $Message
    } else {
        git tag $tag
    }
    if ($LASTEXITCODE -ne 0) { Fail "Ошибка при создании тега '$tag'." }

    git push origin $tag
    if ($LASTEXITCODE -ne 0) { Fail "Ошибка при отправке тега '$tag' на GitHub." }
    Write-Host "✅ Тег '$tag' создан и отправлен на GitHub."
}

# ===== Основной поток =====

Ensure-Git
Ensure-GitRepo

$latest = Get-LatestTagObject
$latestTag = $latest.Tag
Write-Host "Последний Тег: '$latestTag'"
$nextTag = Compute-NextTag -current $latest
Write-Host "Следующий Тег: '$nextTag'"

if (Tag-Exists-Locally $nextTag) {
    Fail "Тег '$nextTag' уже существует локально."
}

if (Tag-Exists-Remotely $nextTag) {
    Fail "Тег '$nextTag' уже существует на GitHub (origin)."
}

Create-And-Push-Tag $nextTag
