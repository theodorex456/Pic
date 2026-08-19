# ===== 参数（按需修改）=====
$OldPrefix = "frame_"   # 原前缀
$NewPrefix = "frame_"           # 新前缀（不想改就写和上面一样）
$OldSuffix = ""            # 原后缀
$NewSuffix = ""            # 新后缀（不想改就写和上面一样）
$NewStart  = 1                   # 重命名后从几开始
$Width     = 4                   # 新编号位数

$tmpTag  = ".__renametmp__"
$pattern = '^' + [regex]::Escape($OldPrefix) + '(\d+)' + [regex]::Escape($OldSuffix) + '(.*)$'

# 收集所有匹配文件，按原编号升序排序（编号不连续、不等宽都能正确排）
$files = @(Get-ChildItem -File | Where-Object { $_.Name -match $pattern } |
    Sort-Object { [int][regex]::Match($_.Name, $pattern).Groups[1].Value })

if ($files.Count -eq 0) { Write-Host "没有找到匹配的文件"; exit }

# 第一步：全部改成临时名（两段式，避免新旧编号撞车）
foreach ($f in $files) {
    Rename-Item -LiteralPath $f.FullName -NewName ($f.Name + $tmpTag)
}

# 第二步：改成「新前缀 + 连续新编号 + 新后缀 + 扩展名」
$tmpFiles = @(Get-ChildItem -File | Where-Object { $_.Name -like "*$tmpTag" } |
    Sort-Object { [int][regex]::Match($_.Name, $pattern).Groups[1].Value })

$i = 0
foreach ($f in $tmpFiles) {
    $newNum = ($NewStart + $i).ToString("D$Width")
    $orig   = $f.Name.Substring(0, $f.Name.Length - $tmpTag.Length)
    $ext    = [regex]::Match($orig, $pattern).Groups[2].Value   # 扩展名（如 .mp4）
    Rename-Item -LiteralPath $f.FullName -NewName ("$NewPrefix$newNum$NewSuffix$ext")
    $i++
}

Write-Host "完成：共重命名 $($files.Count) 个文件"