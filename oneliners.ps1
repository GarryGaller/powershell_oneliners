Полезные и не очень одно(двух\трех\etc)строчники и просто примеры 

#=======================================================
# ПЕРЕМЕННЫЕ ОКРУЖЕНИЯ
#=======================================================
$env:windir
$env:appdata
$env:username
$env:path

#=======================================================
# ПРОЦЕССЫ И СИСТЕМА
#=======================================================

# получить список процессов, отсортированных по возрастанию рабочего набора
ps|sort WorkingSet -ErrorAction Silent|select ProcessName,WorkingSet|ft -auto

# получить три процесса с максимальным рабочим набором памяти
ps|sort WorkingSet| select -Last 3
ps|sort WorkingSet -Descending| select -first 3

# получить три процесса с минимальным  рабочим набором памяти
ps|sort WorkingSet| select -first 3
ps|sort WorkingSet -Descending| select -last 3

# получить максимальный рабочий набор процессов одним значением
(ps | measure workingset -max).Maximum

# получить минимальный рабочий набор процессов одним значением
(ps | measure workingset -min).Minimum

# либо всю информацию сразу
ps | measure workingset -min -max -aver -sum

# время работы процесса в формате 00:00:00.0000000
"$((get-date)-(ps -id $PID).StartTime)"
"$((get-date)-(ps -id $PID).StartTime)"
(New-TimeSpan (ps -id $PID).StartTime).ToString()

#время работы процесса - дробное число минут
(new-timespan (ps -id $PID).StartTime).TotalMinutes

# время старта системы в формате 00:00:00.0000000
"$((ps winlogon).StartTime)"

# время работы системы без перезагрузки в формате 00:00:00.0000000
"$((get-date)-(ps winlogon).StartTime)"
"$(New-TimeSpan (ps winlogon).StartTime)"

# время работы системы без перезагрузки в формате 00:00
((get-date)-(ps winlogon).StartTime).ToString("hh':'mm")
(New-TimeSpan (ps winlogon).StartTime).ToString("hh':'mm")

# время работы системы без перезагрузки в формате 00
((get-date)-(ps winlogon).StartTime).ToString("hh")
(New-TimeSpan (ps winlogon).StartTime).ToString("hh")


# получить список процессов, отсортированных по возрастанию рабочего набора
ps|sort WorkingSet -ErrorAction Silent|select ProcessName,WorkingSet|ft -auto

# получить три самых новых запущенных поцессов
ps|sort StartTime -ErrorAction Silent| select ProcessName,StartTime  -last 3

# получить три самых ранних запущенных поцессов
ps|sort StartTime -ErrorAction Silent| select ProcessName,StartTime  -first 3

# получить список из 10 процессов отсортированных по дате создания исполняемого файла
ps | ? {'System', 'Idle' -notcontains $_.Name}| 
    gi -ErrorAction Silent| sort CreationTime -desc | 
        select Directory, Name, CreationTime, LastWriteTime -first 10

# получить список системных процессов
gwmi win32_process  | ? {$_.getowner().user -match "система|system"}| select -Expand name

# тоже самое, но для версий powershell от 4.0 и выше
ps -IncludeUserName | ? UserName -match "система|system"| select -Expand name
ps -IncludeUserName | ? {$_.UserName -match "система|system"}| select -Expand name

# получить список имен процессов имеющих более, чем один экземпляр
ps| group ProcessName | ? {$_.count -gt 1}

# получить  объект  FileVersionInfo процесса и все его свойства, отфильтровав по производителю (только программы microsoft)
ps | ? Path |  gi | % versioninfo | ? CompanyName -eq "Microsoft Corporation"| fl 

# получить  объект  FileVersionInfo у всех пользовательских процессов и все его свойства, отфильтровав по производителю (кроме программ microsoft)
ps | ? UserName -notmatch "система|system" | ? Path |  gi | % versioninfo | ? CompanyName -ne "Microsoft Corporation"| fl

#=======================================================
# РЕЕСТР
#=======================================================

# получить список программ из автозагрузки текущего пользователя
cd HKCU:\Software\Microsoft\Windows\CurrentVersion\Run;gi .  # точка здесь не случайно :-)
# либо так
gp HKCU:\Software\Microsoft\Windows\CurrentVersion\Run
gi HKCU:\Software\Microsoft\Windows\CurrentVersion\Run

# название интернет подключения
(gp HKCU:\RemoteAccess).InternetProfile 
# политика выполнения скриптов для текущего пользователя
(gi HKCU:\Software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell).GetValue('ExecutionPolicy')
(gp HKCU:\Software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell).ExecutionPolicy
# политика выполнения скриптов для всех пользователей
(gp HKLM:\Software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell).ExecutionPolicy

# получить значение по умолчанию - в данном случае программу, ассоциированную с протоколом http
(gp HKLM:\Software\classes\http\shell\open\command).'(default)'

# дата инсталляции windows
[TimeZone]::CurrentTimeZone.ToLocalTime([DateTime]'1.1.1970').AddSeconds(
        (gp 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').InstallDate
        )

#=======================================================
# ЖУРНАЛ СОБЫТИЙ WINDOWS
#=======================================================
get-winevent -listlog  *|select LogName,LogFilePath|ogv

#=======================================================
#   ПРАВА ДОСТУПА НА ФАЙЛОВЫЕ ОБЪЕКТЫ
#=======================================================

(Get-Acl -Path $pwd).Access|ft `
      @{n="Группа\Пользователь";   e={$_.IdentityReference}},
      @{n="Тип доступа";           e={$_.AccessControlType}},
      @{n="Права NTFS";            e={$_.FileSystemRights};a="left"},
      @{n="Флаги наследования";    e={$_.InheritanceFlags};a="left"},
      @{n="Флаги распространения"; e={$_.PropagationFlags}}

#Вывести список возможных разрешений
[system.enum]::getnames([System.Security.AccessControl.FileSystemRights])


($acl=Get-Acl "d:\1.txt").SetOwner([System.Security.Principal.NTAccount]"Администраторы")
$acl | Set-Acl "d:\1.txt"


#=======================================================
#   WMI и все, все, все
#=======================================================
# получаем список локальных администраторов
$users=(gcim win32_group -Filter "name = 'Administrators' or name = 'Администраторы'"|
        gcai -Association win32_groupuser).name

# или так для версии powershell без Get-CimInstance и Get-CimAssociatedInstance
$users2=(gwmi win32_groupuser | ? { $_.GroupComponent -match 'Administrators|Администраторы' } | % {
        [wmi]$_.PartComponent}).name


# фильтруем по домену
$domain = 'MyComp'
$group  = 'Администраторы'
$user   = 'Garry'

# пользователи входящие в групп Администраторы в домене Domain
gcim win32_group -Filter "name='$group' and Domain='$domain'"|
    gcai -Association win32_groupuser| 
        select -Expand Name

# пользователи входящие в групп Администраторы в домене Domain
gwmi win32_groupuser |
    ? { $_.GroupComponent -match "Domain=`"$domain`",Name=`"$group`""}|    
        % {[wmi]$_.PartComponent}|
            select -Expand name 

#N.B: двойные внешние кавычки - для интерполяции переменных, внутренние двойные - для поиска по точному совпадению в такого вида строке:
# \\COMP\root\cimv2:Win32_Group.Domain="COMP",Name="Администраторы"
# так как двойные кавычки используются внутри внешних - их нужно экранировать акцентом `


# входит ли данный пользователь данного домена в данную группу
(gcim win32_group -Filter "name='$group' and Domain='$domain'"|
    gcai -Association win32_groupuser).name -icontains  $user

# входит ли данный пользователь данного домена в данную группу
(gwmi win32_groupuser |
    ?{ $_.GroupComponent -match "Domain=`"$domain`",Name=`"$group`""}|
         % {[wmi]$_.PartComponent}).name -icontains  $user
          
# реализация вывода ps -IncludeUserName средствами WMI 
gwmi win32_process |select `
    @{n="Handles";           e={$_.Handles}},
    @{n="WS(K)";             e={$_.WS/1kb}},
    @{n="VM(M)";             e={[math]::round($_.VM/1mb)}},
    @{n="User+Kernel CPU(s)";e={$_.UserModeTime+$_.KernelModeTime}},
    @{n=" Id";               e={$_.Handle}},
    @{n="Process Owner";     e={"{0,-15}" -f $_.getowner().user}},
    @{n="Process Name";      e={$_.Name}}|ft -auto

#=======================================================
# МАССИВЫ
#=======================================================
$arr1 = 1,2,3,4,5,6,7,8,9,10              # Объявляем числовой массив
$arr2 = "A", "B", "C", "D", "E", "F", "G" # Объявляем строковой массив

Write-Host $arr1 # Таким образом мы увидим значения массива в строчку
#1 2 3 4 5 6 7 8 9 10
Write-Host $arr2
#A B C D E F G
$arr1 # Таким образом мы увидим значения массивов в столбик
$arr2

$arr1[-1]        # С помощью знака "минус" можно выбирать элементы начиная с конца массива: 10
$arr1[-3]        # 8
$arr1[0,4,9]     # Выбираем сразу несколько элементов из массива: 1,5,10
$arr2[0..3]      # Выбираем диапазон значений начиная с первого и заканчивая четвертым: A,B,C,D
$arr1[3..-2]     # Выборка диапазона в обратном порядке, начиная с четвертого, затем третьего и заканчивая предпоследним
#4,3,2,1,10,9
$arr1[0..2+7..9] # Выберем несколько диапазонов сразу с помощью знака "плюс": 1,2,3,8,9,10

$arr=1,2,3,4,5; $skip=2,5
# удалить из $arr элементы, которые есть  в $skip
$arr | ? {$skip -notcontains $_}

# удалить дубликаты из последовательности 
[Linq.Enumerable]::Distinct([string[]]@("a","a","b","c","d")) 
[Linq.Enumerable]::Distinct([char[]]@("hello world".ToCharArray())) 

# обратного метода - извлечь дубликаты - в LINQ я не обнаружил,
# поэтому придумал вот такой способ - используя hashtable
$enum=1,2,3,3,4,5,5
$a = @{};$enum| % {$a[$_]++};$a.keys | ? {$a[$_] -ne 1}

#=======================================================
# ФАЙЛЫ И ДИРЕКТОРИИ
#=======================================================

# прочитать последнюю строку файла
cat test.txt -tail 1
(cat test.txt)[-1]

# прочитать n строк с начала файла
cat test.txt -TotalCount 2
cat test.txt -first 2

# прочитать три  последние строки файла
cat test.txt -tail 3
(cat test.txt)[-1..-3]

# последняя строка, третье слово, четвертый символ
(-split $(cat c:\1.txt)[-1])[2][3]

# вывести все строки кроме последней
0..(($t=(cat test.txt)).Length-2)| % {$t[$_]}

# подсчитать кол-во строк, слов и символов в тексте, вывести как список
cat test.txt|measure -line -word -char|fl

#минимальный, максимальный, суммарный и средний размер всех файлов в текущем каталоге.
dir| measure length -min -max -aver -sum

# получить три самых больших по размеру файла в каталоге

dir | ? {$_.Mode -notmatch "d"}|sort length | select -last 3
dir | ? {!$_.PsIsContainer}|sort length | select -last 3
dir | ? {!$_.PsIsContainer}|sort length -Desc| select -first 3


# получить три самых меньших по размеру файла в каталоге
dir -File|sort length | select -first 3
dir | ? {$_.Mode -notmatch "d"}|sort length | select -first 3
dir | ? {!$_.PsIsContainer}|sort length | select -first 3
dir | ? {!$_.PsIsContainer}|sort length -Desc| select -last 3

# получить файлы наименьшего и наибольшего размеров в каталоге
($$ = ls -r| ? {!$_.PSIsContainer} | sort Length | select FullName, Length, CreationTime) |
? {$_.Length -eq $$[0].Length -or $_.Length -eq $$[-1].Length}

# второй вариант - здесь будет вывод не всех совпавших по размеру, а только двух
$$ = ls -r| ? {!$_.PSIsContainer} | sort Length | select FullName, Length, CreationTime
$$[0]
$$[-1]
# третий  вариант
ls -r| ? {!$_.PSIsContainer} | sort Length | select FullName, Length, CreationTime -First 1 -Last 1|ft -auto
ls -r| ? {!$_.PSIsContainer} | sort Length | select FullName, Length, CreationTime -First 1 -Last 1|ft -wrap

# получить файлы с нулевым размером
(dir).Where({$_.Length -eq 0})
dir | ? Length -eq 0

# файлы больше 1 kb
dir | ? {$_.Length -gt 1kb}

# получить три самых старых файла по времени редактирования
# с использованеим LINQ
(dir |sort LastWriteTime).Where({!$_.PSIsContainer},"first",3)

# получить в вывод только полные пути из объекта
((dir|sort LastWriteTime).Where({!$_.PSIsContainer},"First",3)).fullname

# для версии Powershell 2.0-3.0  
dir | ? {!$_.PSIsContainer}|sort LastWriteTime | select -first 3 -Expand FullName


# получить три самых новых файла по времени создания  (powershell > 3.0)
dir -File|sort CreationTime|select -last 3 -Expand FullName
dir -File|sort CreationTime -Desc|select -first 3 -Expand FullName

# с использованеим LINQ
(dir|sort CreationTime).Where({!$_.PSIsContainer},"Last",3)
(dir|sort CreationTime -Desc).Where({!$_.PSIsContainer},"First",3)
# получить в вывод только полные пути из объекта
((dir|sort CreationTime -Desc).Where({!$_.PSIsContainer},"First",3)).fullname

# для версии Powershell 2.0-3.0  
dir | ? {!$_.PSIsContainer}|sort CreationTime -Desc|select -first 3 -Expand FullName


# получить три самых новых файла по времени редактирования
# с использованеим LINQ
(dir|sort LastWriteTime).Where({!$_.PSIsContainer},"Last",3)

# получить в вывод только полные пути из объекта
((dir|sort LastWriteTime).Where({!$_.PSIsContainer},"Last",3)).fullname

# для версии Powershell 2.0-3.0  
dir | ? {!$_.PSIsContainer}|sort LastWriteTime | ? {!$_.PSIsContainer}| select -Last 3 -Expand FullName

# удаление пустых файлов
ls .\test -r| ? {!$_.length}| % {rm $_.FullName -Force -ea 0}
ls .\test -r| ? length -eq 0| % {rm $_.FullName -Force -ea 0}

# удаление пустых папок, кроме вложенных друг в друга
dir $dir -dir | ? {(dir $_.FullName -force -rec) -eq $null}|del -force

# удаление иерархии пустых папок
dir $dir -dir -rec  | ? {(dir $_.FullName -file -force -rec) -eq $null}|del -force -rec
dir $dir -dir -rec  | ? {@(dir $_.FullName -file -force -rec).Length -eq 0}|del -force -rec

# тоже самое для PS 2.0
dir $dir -rec -force  | ? {$_.PSIsContainer -and @(dir $_.FullName -rec -force | ? {!$_.PSIsContainer}).Length -eq 0} | del -force -rec
dir $dir -rec -force  | ? {$_.PSIsContainer -and (dir $_.FullName -rec -force | ? {!$_.PSIsContainer}) -eq $null}| del -force -rec

# удаление из указанной папки файлов старше 30 дней по дате записи (можно заменить на CreationTime)
# c исключением опред. папки
#dir $dir -rec  | ? {$_.Directory -notlike "*UserData"} | ? {$_.LastWriteTime -lt (get-date).AddDays(-30)}|del -force
dir $dir -rec -file  | ? {$_.Directory.Name -ne "UserData"} | ? {$_.LastWriteTime -lt (get-date).AddDays(-30)}|del -force

# получить список имен файлов имеющих дубликаты
dir ".\test\*" -inc *.txt -rec| % {$a = @{}}{$a[$_.name]++}
    $a.keys | ? {$a[$_] -ne 1}| % {"{0}={1}" -f $_,$a[$_]}

# или лучше так
dir "d:\test\" -inc *.txt -rec -EA 0 |% {
    $h=@{}}{$h[$_.name]++};$h.keys | ? {$h[$_] -ne 1
    }| % {"{0}={1}" -f $_,$h[$_]}

# переименование расширений
ls d:\dir\*.xxx| % {cp $_ ($_.directoryname + "\"+ $_.BaseName+".yyy")}
ls d:\dir\*.xxx|ren -newname { $_.name -replace '\.xxx$','.yyy' }
ls d:\dir\*.txt|ren -newname { $_.name -replace '\.txt$','.log'}

# замена расширения в строке посредством регулярного выражения
"c:\12345.678.0\123.txt" -replace '(.+\.)(.+)$','$1log'


# получить временные метки файла
dir c:\config.sys -Force| select *time|fl

dir d:\dir\* -Force| select fullname,mode,*time|ft -auto

# тоже самое, но длинные пути файлов обрезаются перед до 20 символов, чтобы влезть в таблицу
dir d:\dir\* -Force| select @{n='Path';
                              e={$_.fullname -replace "^(.{20}).+(.{4})$",'$1...$2'}},
                                    mode,*time|ft -auto

# вручную нарисованная таблица файлов с указанными атрибутами
$FileFolder = "c:\temp"
"".PadRight(94,"-")
    "|{0,-60}|{1,10}|{2,20}|"-f "Имя файла","Атрибуты","Размер(Mb)";
        "".PadRight(94,"-")
dir $FileFolder | ? {$_.mode -like "*r*"}| % {$length=0}{
    $name=$_.name;if ($name.Length -gt 60){
        $name=$name -replace "^(.{20}).+(.{4})$",'$1...$2'
    }
    "|{0,-60}|{1,10}|{2,20}|"-f $name,$_.mode,($_.length/1MB).ToString("F2");
        $length+=$_.Length
}
"".PadRight(94,"-")
    "|{0,-60}{1,32}|"-f "Общая сумма:","$(($length/1MB).ToString('F2')) Mb";
           "".PadRight(94,"-")


# удалить рекурсивно все файлы из папок 
del d:\test -inc *.* -rec -force  # так удалит только файлы имеющие расширение, а также папки с точкой в имени
dir d:\temp -file -rec -force|del  # а так только файлы
# для версии Powershell 2.0-3.0 
dir d:\temp -rec -force | ? {!$_.PSIsContainer}|del

# обрезать имя файла
(dir -file d:\test\*).name.Substring(0,4)
(dir -file d:\test\* -r).name.Substring(0,4) # рекурсивно

dir -file d:\test\*|foreach{
    #$date = $_.name.Substring(0,4);  # substring может вызвать ошибку доступа к индексу
    # или так
    $date = -join $_.name[0..3]      # срезы - беопасный вариант доступа к диапазону индексов
    echo $date
}


dir -file|foreach{ "{0,-50} {1:#,#0.0000} Mb" -f  (-join $_.name[0..49]), $($_.length/1MB)}

dir -file|foreach{ "{0,-50} {1:#,#0.0000} Kb" -f  (-join $_.name[0..49]), $($_.length/1kb)}

dir | ? {!$_.PSIsContainer}| foreach{ "{0,-50} {1:#,#0.0000} Kb" -f  (-join $_.name[0..49]), $($_.length/1kb)}

dir | Select Name, @{N="Size";E={"{0:#,#0.0000} Kb" -f $($_.Length / 1kb)}}

dir -file | Select Name, @{N="Size";E={
    $size = $_.Length
    if     ($size -gt 1TB) {"{0:0.00} Tb" -f $($size / 1Tb)}
    elseif ($size -gt 1GB) {"{0:0.00} Gb" -f $($size / 1Gb)}
    elseif ($size -gt 1MB) {"{0:0.00} Mb" -f $($size / 1Mb)}
    elseif ($size -gt 1KB) {"{0:0.00} Kb" -f $($size / 1Kb)}
    elseIf ($size -ge 0)   {"{0:0.00} B"  -f $size}
    }
}

dir | where {!$_.PSIsContainer} | foreach{ "{0,-50} {1:#,#0.0000} Mb" -f  $_.name, $($_.length/1MB)}
dir | where {!$_.PSIsContainer} | Select Name, @{N="Size";E={"{0:#,#0.000} Kb" -f $($_.Length / 1kb)}}


dir | ? {!$_.PSIsContainer} | Select Name, @{N="Size";E={
    $size = $_.Length
    if     ($size -gt 1TB) {"{0:0.00} Tb" -f $($size / 1Tb)}
    elseif ($size -gt 1GB) {"{0:0.00} Gb" -f $($size / 1Gb)}
    elseif ($size -gt 1MB) {"{0:0.00} Mb" -f $($size / 1Mb)}
    elseif ($size -gt 1KB) {"{0:0.00} Kb" -f $($size / 1Kb)}
    elseIf ($size -ge 0)   {"{0:0.00} B"  -f $size}
    }
}


#https://superuser.com/questions/468782/show-human-readable-file-sizes-in-the-default-powershell-ls-command

Function Format-FileSize() {
    Param ([int]$size)
    If     ($size -gt 1TB) {[string]::Format("{0:0.00} TB", $size / 1TB)}
    ElseIf ($size -gt 1GB) {[string]::Format("{0:0.00} GB", $size / 1GB)}
    ElseIf ($size -gt 1MB) {[string]::Format("{0:0.00} MB", $size / 1MB)}
    ElseIf ($size -gt 1KB) {[string]::Format("{0:0.00} kB", $size / 1KB)}
    ElseIf ($size -gt 0)   {[string]::Format("{0:0.00} B", $size)}
    Else                   {""}
}

dir| Select Name, @{N="Size";E={Format-FileSize($_.Length)}}




# для Powershell 2.0
(dir d:\test\* | ? {!$_.PSIsContainer}).name.Substring(0,4) 
(dir d:\test\*).Where({!$_.PSIsContainer}).name.Substring(0,4)
(dir d:\test\*|Where{!$_.PSIsContainer}).name.Substring(0,4)

#=======================================================
#  АРХИВАЦИЯ ФАЙЛОВ
#=======================================================
$FileFolder = "c:\Temp"
$ZipDestination = "c:\Temp\test.zip"
 
Add-Type -AssemblyName System.IO.Compression.FileSystem
$Compression =[IO.Compression.CompressionLevel]::Optimal
# открыть архив для обновления
$Archive = [IO.Compression.ZipFile]::Open($ZipDestination, "Update")

# добавить в архив файлы только с атрибутом readonly 
dir $FileFolder | ? {$_.mode -like "*r*"}| % {
    [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Archive, $_.FullName, $_.Name, $Compression)
}
$Archive.Dispose()

# создать архив из директории
$source = "C:\Testzip\1"
$destination = "C:\Testzip\1.zip"
$level = [System.IO.Compression.CompressionLevel]::Optimal
$Include = $false # не включать в архив базовый каталог:
[IO.Compression.ZipFile]::CreateFromDirectory($source, $destination, $level, $Include)

# извлечь архив в директорию
$source = "C:\Testzip\1.zip"
$destination = "C:\Testzip"
[IO.Compression.ZipFile]::ExtractToDirectory($source, $destination)


#=======================================================
#  ДИСКИ И РАЗДЕЛЫ
#=======================================================
[System.IO.DriveInfo]::getdrives()|? drivetype -eq "fixed"|ft `
      @{n="Буква тома";    e={$_.Name}},
      @{n="Метка тома";    e={$_.VolumeLabel}},
      @{n="Формат";        e={$_.DriveFormat};a="right"},
      @{n="Размер(Gb)";    e={($_.TotalSize/1GB).ToString("F2")};a="right"},
      @{n="Свободно(Gb)";  e={($_.AvailableFreeSpace/1GB).ToString("F2")};a="right"}

gwmi Win32_logicaldisk -Filter 'DriveType="3"'|ft `
      @{n="Буква тома";    e={$_.Name}},
      @{n="Метка тома";    e={$_.VolumeName}},
      @{n="Формат";        e={$_.FileSystem};a="right"},
      @{n="Размер(Gb)";    e={($_.Size/1GB).ToString("F2")};a="right"},
      @{n="Свободно(Gb)";  e={($_.FreeSpace/1GB).ToString("F2")};a="right"},
      @{n="Dirty";         e={$_.VolumeDirty}},
      @{n="MediaType";     e={$_.MediaType}},
      @{n="Описание";      e={$_.Description}}

gwmi Win32_DiskDrive -Filter "MediaType='Fixed hard disk media'"|ft `
      @{n="Имя диска";       e={$_.Name}},
      @{n="Модель";          e={$_.Model}},
      @{n="Число разделов";  e={$_.Partitions}},
      @{n="Размер(GB)";      e={($_.Size/1GB).ToString("F2")};a="right"},
      @{n="Серийный номер";  e={$_.SerialNumber};a="right"}

gwmi Win32_DiskPartition|ft `
      @{n="Имя раздела";         e={$_.Name}},
      @{n="Индекс тома";         e={$_.Index}},
      @{n="Индекс диска";        e={$_.DiskIndex}},
      @{n="Bootable";            e={$_.Bootable}},
      @{n="Boot`nPartition";     e={$_.BootPartition}},
      @{n="Primary`nPartition";  e={$_.PrimaryPartition}},
      @{n="Начало смещения";     e={$_.StartingOffset}},
      @{n="Скрытые сектора";     e={$_.HiddenSectors}}


#=======================================================
#  МОДУЛИ
#=======================================================
# список командлетов экспортируемых модулем
$keys=($command=(Get-Module -Name Microsoft.PowerShell.Management).ExportedCommands).Keys
$keys | ? {$command[$_].CommandType -eq 'cmdlet'}

Import-Module BitsTransfer
# список командлетов и функций экспортируемых модулем
$keys=($command=(Get-Module -Name BitsTransfer).ExportedCommands).Keys
$keys | ? {$command[$_].CommandType -match 'cmdlet|function'}

# список всех команд экспортируемых модулем
Import-Module ISE
((Get-Module -Name ISE).ExportedCommands).Keys

# общая таблица по доступным командам всех модулей
Get-Module -ListAvailable

# общий список
Get-Module -ListAvailable| % {
    Import-Module $_.name
    write-host "Модуль: $_" -ForegroundColor Red
    "-------------------------------------"
    ((Get-Module -Name $_.name).ExportedCommands).Keys
    "-------------------------------------"
}
#=======================================================
# ТЕКСТОВЫЕ ОПЕРАЦИИ И РЕГУЛЯРНЫЕ ВЫРАЖЕНИЯ
#=======================================================

# вывести все слова длиной = 5 символов
(-split "hello world hello world halloween").Where({$_.Length -eq 5})
# вывести первое слово длиной = 5 символов
(-split "hello world hello world halloween").Where({$_.Length -eq 5},"First",1)
# вывести последнее слово длиной = 5 символов
(-split "hello world hello world halloween").Where({$_.Length -eq 5},"Last",1)
# вывести слова начинающиеся на букву h
(-split "hello world hello world halloween").Where({$_[0] -eq "h"})

# вывести все слова более трех символов
"я из лесу вышел был сильный мороз".Split().Where({$_.length -gt 3})

# сделать каждое слово в предложении с прописной буквы
[regex]::replace('hello world','\b.', {$args[0].Value.ToUpper()})

# более экзотический вариант ([char]32  - это пробел)
'hello world' -split [char]32| % {"$($_[0])".ToUpper() + (-join $_[1..$($_.Length-1)])}
# тоже самое, но с использованием статического метода Char.ToUpper()
'hello world' -split [char]32| % {[char]::ToUpper($_[0]) + (-join $_[1..$($_.Length-1)])}
# а здесь заменим манипуляции с получением диапазона символов(и их последующего склеивания) -
# обычным методом Substring()
'hello world' -split [char]32| % {[char]::ToUpper($_[0]) + $_.Substring(1,$_.Length-1)}

# создать линию из 20 звездочек
[Linq.Enumerable]::Repeat("*",20) -join ""
New-Object String("*",20)
"*".PadRight(20,"*")

# разбить строку на строки по два символа
"1234567890" -replace '(.{2})',"`$1`r`n"
# здесь дополнительно удаляется последний перевод строки
("1234567890" -replace '(.{2})',"`$1`r`n").TrimEnd([char[]](10,13))

[regex]::replace("1234567890",'.{2}',{$args[0].Value+"`r`n"})

(cat 2.txt) -replace '(^.{4})(?:.*)','$1'

# массовое удаление кириллицы из группы файлов
dir *.txt| % {out-file $_ -Input (cat $_| % {$_ -replace '[а-я]+',''})}
dir *.txt| % {out-file $_ -Input ((cat $_) -replace '[а-я]+','')}

"урезать","все","строки", "до", "четырех","символов" -replace '(^.{4})(?:.*)','$1'
"урезать`nвсе`nстроки`nдо`nчетерых`nсимволов" -replace '(?m)(^.{4})(?:.*)','$1'

# удалить одну букву из сочетания символов
[regex]::replace("5-2025кс15",'(\p{IsCyrillic})с','$1')

# получить последний элемент пути
$uri = "http://download.microsoft.com/download/9/A/8/9A8FCFAA-78A0-49F5-8C8E-4EAE185F515C/Windows6.1-KB917607-x64.msu"
($uri -split "/")[-1];
$uri.split("/")[-1];
([uri]$uri).Segments[-1]
$uri -replace '^.*/'

# генерация случайного имени из 7 латинских букв
$name = -join (0..7 | % {$rnd = New-Object Random}{[Char]$rnd.Next(97, 122)})

# вставить строку после каждой n-ой строки
sls "^.*$" input.txt | % {$t="";$n=6}{if ($_.LineNumber -eq $n){
    $n*=2; $_.Line+="`nновая строка"};$t+=$_.Line+"`n"}
$t|out-file input.txt -enc default

# вывести help команд cmd c нумерацией
$text = "";help.exe| % {$text+=$_ +"`r`n"}
$m = ([regex]"(?sm)(^[A-Z]+.+?)(?=`r`n[A-Z]+)").Matches($text)
0..($m.count-1)| % {("[" +($_+1)+"]" + $m[$_].Groups[1].value)

help.exe| % {$i=1}{if ($_ -match'(^[A-Z]{2,})' ){$_ -replace $matches[0], ('[{0:d2}] {1}' -f $i++, $matches[0])} else {$_}}

# удаление из файлов определенного набора символов
# вариант с рекурсивным обходом всех субдиректорий          
$source = "d:\test" # источник файлов        
$maskfile = '*.txt' # маска файлов
$pattern='(?s)o0.+' #'(?s)o0.+\z'

dir $source -inc $maskfile -rec| % {
        out-file $_ -Input ([IO.File]::ReadAllText( 
                $_.fullname,[Text.Encoding]::Default)| % {$_ -replace $pattern}) -enc default
        }

dir $source -inc $maskfile -rec| % {
        out-file $_ -Input (cat -raw $_| % {$_ -replace $pattern}) -enc default
        } 
        
dir $source -inc $maskfile -rec| % {
         (cat -raw $_| % {$_ -replace $pattern})|out-file $_ -enc default
        } 

# переименование файлов из списка путей по списку имен
cat source.txt|%{$n=0;$f=cat names.txt}{ren $_ $f[$n];$n++;}

# прочитать текст с конца
$text = [IO.File]::ReadAllText("$($pwd.path)\text.txt",[Text.Encoding]::Default)
([regex]::Matches($text,'.','RightToLeft,Singleline')| ForEach {$_.value}) -join ''
# символы без учета \n
([regex]::Matches($text,'.','RightToLeft')| ForEach {$_.value}) -join ''
<#
.зов утсоровх яащузев ,акдашоЛ
урог в оннелдем ястеаминдоп ,ужялГ
.зором йыньлис лыб ;лешыв усел зи Я
,уроп ююнмиз юунедутс в ,ыджандО
#>


([regex]::Matches($text,'.','RightToLeft,Singleline') | ForEach {$_.value}
) -join '' -replace "`n`r","`r`n" |sc text_new.txt -enc Default

$a = (cat -raw -enc Default text.txt) -split "";
[array]::Reverse($a);
$a -join '' -replace "`n`r","`r`n" | sc text_new.txt -enc Default


gc text.txt -enc Default|%{-join ($x = $_).tochararray()[$x.length..0]}
<#
,уроп ююнмиз юунедутс в ,ыджандО
.зором йыньлис лыб ;лешыв усел зи Я
урог в оннелдем ястеаминдоп ,ужялГ
.зов утсоровх яащузев ,акдашоЛ
#>

gc text.txt -raw -enc Default|%{-join ($x = $_).tochararray()[$x.length..0] -replace "`n`r","`r`n"} | out-file text_new.txt -enc Default

gc text_UTF8.txt -raw -enc UTF8|%{-join ($x = $_).tochararray()[$x.length..0] -replace "`n`r","`r`n"} | out-file text_new_UTF8_1.txt -enc UTF8

#=======================================================
# ДАТА И ВРЕМЯ
#=======================================================
# вывод даты и времени в сокращенном формате  мм.дд.гггг
"$(get-date)"          # 12/23/2015 18:16:15
"$([datetime]::now)"   # 12/23/2015 18:16:15

# вывод даты и времени в сокращенном формате - дд.мм.гггг
(get-date).ToString()  # 23.12.2015 18:16:15

# [datetime]::parse() формат мм.дд.гггг не распознает
# вот это работать не будет
[datetime]::parse("$(get-date)")
# либо ошибка если второе число больше 12, либо неправильная интерпретация даты
[datetime]::parse("12/31/2015") # 31 декабря по get-date - и получаем ошибку
# а вот так дата распознается верно
[datetime]"$(get-date)"
[datetime]"12/31/2015"

# отформатировать вывод даты
get-date -f 'dd\\MM\\yyyy'
get-date -f "dd'/'MM'/'yyyy"

# отформатировать вывод даты и времени
get-date -f 'HH:mm:ss'    # 23:11:05
get-date -f 'HH:MM:ss'    # 23:11:05
get-date -f 'H:m:s'       # время без ведущих нулей в случае одной цифры; h -часы по гринвичу, а не локальное время
get-date -f 'dd.MM.yyyy'  # 15.12.2015
get-date -f 'g'           # 15.12.2015 23:11
get-date -f 'G'           # 15.12.2015 23:11:05
get-date -f 'dd'          # 15 - день месяца, в диапазоне от 01 до 31.
get-date -f 'ddd'         # вт - сокращенное название дня недели
get-date -f 'dddd'        # полное название дня недели
get-date -f 'm'           # декабря 15
get-date -f 'M'           # декабря 15 
get-date -f 'MM'          # 12 - месяц, в диапазоне от 01 до 12.
get-date -f 'MMM'         # дек - сокращенное название месяца
get-date -f 'MMMM'        # Декабрь - полное название месяца
get-date -f 'y'           # Декабрь 2015
get-date -f 'Y'           # Декабрь 2015
get-date -f 'yy'          # 15 - год, в диапазоне от 0 до 99
get-date -f 'yyyy'        # 2015
get-date -f 'T'           # только время:  20:15:33
get-date -f 't'           # только время:  20:15
get-date -f 'D'           # только дата: 21 декабря 2015 г.
get-date -f 'd'           # только дата: 15.12.2015

# или  так
'{0:HH:mm:ss}'            -f (get-date)
'{0:dd.MM.yyyy}'          -f (get-date)
'{0:dd.MM.yyyy HH:mm}'    -f (get-date)
'{0:dd.MM.yyyy HH:mm:ss}' -f (get-date)

# обратная конвертация из сокращенного в полный строковой формат
[datetime]::ParseExact("$(get-date)","MM'/'dd'/'yyyy HH:mm:ss",$null)

[timespan]$ts = [DateTime]::Now.Ticks
"{0:00}:{1:00}:{2:00}.{3:00}" -f $ts.Hours, $ts.Minutes, $ts.Seconds, ($ts.Milliseconds/10)

[datetime]::ParseExact('11222015-13~44~14','MMddyyyy-ss~mm~HH',$null)

[datetime]::parse("22/2/2015 23:12:33.1233")
[datetime]"2/22/2015"
[datetime]"23:12:33"
[datetime]::parse('2015-12-08')

(get-date).ToString("dd.MM.yyyy HH:mm:ss.fff")
(get-date).ToString("s.f")
(get-date).ToString("ddd d MMM")
(get-date).ToString("dd-MMM-yyyy")

(get-date).ToString("dd-MMM-yyyy",[Globalization.CultureInfo]::CreateSpecificCulture("en-US"))

([datetime]::parse('2015-03-08')).ToString("dd-MMM-yyyy",[Globalization.CultureInfo]::CreateSpecificCulture("en-US"))
([datetime]::parse('2015-03-08')).ToString("dd-MMM-yyyy",[Globalization.CultureInfo]::CurrentUICulture) # последний параметр для текущей локали можно опустить
# русское название дня недели все равно не выводит
([datetime]::parse("$(get-date)",[Globalization.CultureInfo]::CreateSpecificCulture("ru-RU"))).DayOfWeek

# определяем день недели
powershell get-date -f 'dddd'                                   # текущий день недели
powershell ([datetime]::parse('31/12/2018')).ToString('dddd')   # формат ввода дд.мм.гггг , локализованное имя дня недели
powershell ([datetime]'12/31/2018').ToString('dddd')            # формат ввода мм.дд.гггг (либо гггг.мм.дд), локализованное имя дня недели
powershell ([datetime]::parse('31/12/2018')).DayOfWeek          # анг. название дня недели
powershell ([datetime]'12/31/2018').DayOfWeek                   # анг. название дня недели
powershell ([datetime]::parse('31/12/2018',[Globalization.CultureInfo]::CreateSpecificCulture('ru-RU'))).DayOfWeek #  имя дня недели в указанной культуре
([datetime]::ParseExact('12/31/2018','MM/dd/yyyy',$null)).ToString('dddd')

# узнаем названия дня недели; DayOfWeek выдает только анг. названия
(get-date).DayOfWeek
([datetime]::parse("2015/12/15")).DayOfWeek
([datetime]"2015/12/15").DayOfWeek 

# а так - локализованные имена
[datetime]::parse("2015/12/15").ToString("dddd")
([datetime]"2015/12/15").ToString("dddd")

# задав культуру - можно переопределить получаемые имена на нужный язык
$ci=new-object Globalization.CultureInfo("fr-FR", $false)
(get-date).ToString("dddd",$ci)


# можно вообще переопределить культуру для текущего потока - действует только пока жив выполняемый поток
[Threading.Thread]::CurrentThread.CurrentCulture=new-object Globalization.CultureInfo("de-DE", $false)
[Globalization.CultureInfo]::CurrentCulture
([datetime]"2015/12/15").ToString("dddd")
(get-date).ToString("dddd")

# получить вчерашний день
(Get-date -hour 0 -minute 0 -second 0).AddDays(-1).Date.Day

# получить файлы старше 31-го дня (созданные более чем 31 день назад)
dir  | ? { $_.CreationTime -lt (get-date).AddDays(-31)}

# получить файлы измененные не более суток назад
dir  | ? { $_.LastWriteTime -gt (get-date).AddDays(-1)}
# или так
dir  | ? { $_.LastWriteTime -gt (get-date).AddHours(-24)}
# получить файлы измененные не более часа назад
dir  | ? { $_.LastWriteTime -gt (get-date).AddHours(-1)}

dir  | ? {($_.LastWriteTime).Date -eq (Get-date -hour 0 -minute 0 -second 0).AddDays(-1).Date}
dir  | ? {($_.LastWriteTime).Date -eq ([DateTime]::Now.Date).AddDays(-1)}
# или так - с указанием даты
dir  | ? {($_.LastWriteTime).Date -eq ([datetime] "07/11/2015")}  #7 ноября 2015 г. 0:00:00

# узнать сколько \секунд\минут\часов\дней назад был изменен файл
((get-date) -(gi test.txt).LastWriteTime).TotalSeconds
((get-date) -(gi test.txt).LastWriteTime).TotalMinutes
((get-date) -(gi test.txt).LastWriteTime).TotalHours 
((get-date) -(gi test.txt).LastWriteTime).TotalDays

#"================================================="
# получаем рабочие дни текущего месяца
$Year=(get-date).Year;$Month=(get-date).Month
1..([datetime]::DaysInMonth($Year,$Month)) | ? {
    ($DayOfWeek=([datetime]"$Year.$Month.$_").DayOfWeek) -notmatch 'Saturday|Sunday'
  }| % {"[{0:d2}]={1}" -f $_,$DayOfWeek}

# отобразить рабочие (кроме субботы\воскресенья) дни текущего месяца
$Year=(get-date).Year;$Month=(get-date).Month
1..[datetime]::DaysInMonth($Year,$Month) | ? {
    ($DayOfWeek=([datetime]"$Year.$Month.$_").DayOfWeek) -notmatch 'Saturday|Sunday'}

$Year=(get-date).Year;$Month=(get-date).Month
(1..[datetime]::DaysInMonth($Year,$Month)).Where(
      {($DayOfWeek=([datetime]"$Year.$Month.$_").DayOfWeek) -notmatch 'Saturday|Sunday'})

$Year=(get-date).Year;$Month=(get-date).Month
([int[]](1..[datetime]::DaysInMonth($Year,$Month))).Where(
      {($DayOfWeek=([datetime]"$Year.$Month.$_").DayOfWeek) -notmatch 'Saturday|Sunday'})

# а вот здесь получаем уже русские названия
$Year=(get-date).Year;$Month=(get-date).Month
1..([datetime]::DaysInMonth($Year,$Month)) | ? {
    ($DayOfWeek=([datetime]"$Year.$Month.$_").ToString("dddd")) -notmatch 'cуббота|воскресенье'
  }| % {"[{0:d2}]={1}" -f $_,$DayOfWeek}

"================================================="
((Get-Date –Date '01/01/1970') + (
    gp 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion' | 
    Select -Expand 'InstallDate' | 
    %{ New-Timespan -Seconds $_})
).ToString('yyyyMMdd')

((Get-Date –Date '01/01/1970') +  (New-Timespan -Seconds  1601924879)).ToString('yyyyMMdd')
([DateTime]'1.1.1970' + (new-timespan -sec 1601924879)).ToString('yyyyMMdd')
"================================================="


# вывести номер дня и название дня недели каждого дня указанного месяца в указанном году
1..([datetime]::DaysInMonth(2015,12))| % {"{0}:{1}" -f $_,([datetime]"2015.12.$_").DayOfWeek}

# получить дату 90 дней назад
(get-date) - (new-timespan -days 90)
(get-date).AddDays(-90)
(get-date).AddDays(-90).ToString('yyyy-MM-dd')

# массивы сокращений месяцев и дней принятые в определенном языке и региональных параметрах.

$ci=[Globalization.CultureInfo]::CreateSpecificCulture("en-US")
# здесь будет вывод для американской культуры
$ci.DateTimeFormat.AbbreviatedMonthNames
$ci.DateTimeFormat.AbbreviatedDayNames
$ci.DateTimeFormat.DayNames

# для культуры UI интерфейса windows (используются локальные настройки)
$ci=[Globalization.CultureInfo]::CurrentUICulture
# в случае русской локализации получаем следующее:
# массив трехбуквенных сокращений месяцев
$ci.DateTimeFormat.AbbreviatedMonthNames -join ","
# янв,фев,мар,апр,май,июн,июл,авг,сен,окт,ноя,дек,

# массив двухбуквенных сокращений дней
$ci.DateTimeFormat.AbbreviatedDayNames -join ","
# Вс,Пн,Вт,Ср,Чт,Пт,Сб

# полные имена дней для указанной культуры
$ci.DateTimeFormat.DayNames -join ","
# воскресенье,понедельник,вторник,среда,четверг,пятница,суббота

# все типы форматов для указанной культуры 
$ci.DateTimeFormat |select
<#
DateSeparator                    : .
FirstDayOfWeek                   : Monday
CalendarWeekRule                 : FirstDay
FullDateTimePattern              : d MMMM yyyy 'г.' HH:mm:ss
LongDatePattern                  : d MMMM yyyy 'г.'
LongTimePattern                  : HH:mm:ss
MonthDayPattern                  : MMMM dd
PMDesignator                     : 
RFC1123Pattern                   : ddd, dd MMM yyyy HH':'mm':'ss 'GMT'
ShortDatePattern                 : dd.MM.yyyy
ShortTimePattern                 : H:mm
SortableDateTimePattern          : yyyy'-'MM'-'dd'T'HH':'mm':'ss
TimeSeparator                    : :
UniversalSortableDateTimePattern : yyyy'-'MM'-'dd HH':'mm':'ss'Z'
YearMonthPattern                 : MMMM yyyy
AbbreviatedDayNames              : {Вс, Пн, Вт, Ср...}
ShortestDayNames                 : {Вс, Пн, Вт, Ср...}
DayNames                         : {воскресенье, понедельник, вторник, среда...}
AbbreviatedMonthNames            : {янв, фев, мар, апр...}
MonthNames                       : {Январь, Февраль, Март, Апрель...}
IsReadOnly                       : False
NativeCalendarName               : григорианский календарь
AbbreviatedMonthGenitiveNames    : {янв, фев, мар, апр...}
MonthGenitiveNames               : {января, февраля, марта, апреля...}
#>

# capitalize first letter 
[Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase('ИВАН ИВАНОВИЧ ИВАНОВ'.ToLower())
# Иван Иванович Иванов
#=======================================================
# ФОРМАТИРОВАНИЕ ЧИСЕЛ
#=======================================================
"[{0:d2}]  {1} {2}" -f  1,20,30  # только для целых чисел - добавляет первые ноли до нужной ширины
"[{0, 20}] {1} {2}" -f  1,20,30  # дополняет пробелами слева  (выравнивание по правому краю)
"[{0,-20}] {1} {2}" -f  1,20,30  # дополняет пробелами справа (выравнивание по левому краю)

"{0:d5}"   -f 1234     # определяет минимальное число цифр, недостающие заменяются нулями
"{0:n2}"   -f 123.4656 # определяет число цифр после запятой(минимум: 2), округляя до ближайшего значения
"{0:P0}"   -f (5/100)  # добавляет знак % и преобразует в процентное соотношение
"{0:P1}"   -f (3/33)   # добавляет знак %, преобразует в процентное соотношение и округляет вверх до одной цифры после запятой

# форматирование дробной части числа
"{0:F0}"   -f 123.4656 # 123
(10/3).ToString("F0")  # 3
(10/3).ToString("F2")  # 3,33

# форматирование числа с точкой вместо запятой в качестве разделителя целой и дробной части
(13/1000).ToString('f3',[Globalization.CultureInfo]::CreateSpecificCulture("en-US")) 

# преобразование в 16 представление
(255).ToString('X')    # FF 
(255).ToString('X8')   # 000000FF 
(255).ToString('x')    # ff
"{0:X}" -f 255         # FF 

# использование заполнителей
"{0:#.##}"      -f 123.456     # 123,46
"{0:0.00}"      -f 123.456     # 123,46
"{0:0000.000}"  -f 123.4       # 0123,400
"{0:#,,}"       -f 1234567890  # 1235
"{0:#,#}"       -f 1234567890  # 1 234 567 890
"{0:#,###}"     -f 1234567890  # 1 234 567 890
"{0:##,##0.00}" -f 1234567890  # 1 234 567 890,00
"{0:##,#}"      -f 1234567890  # 1 234 567 890
"{0:#,#}"       -f 1234567890  # 1 234 567 890
"{0:#,##}"      -f 1234567890  # 1 234 567 890
"{0:###,#}"     -f 1234567890  # 1 234 567 890

"{0:#,##0,,}"  -f 1234567890  # 1 235
"{0:#,##0,}"   -f 1234567890  # 1 234 568
"{0:#0.##%}"   -f 0.086       # 8,6%  ;  тоже самое: "{0:P1}" -f 0.086 
"{0:0.#%}"     -f 0.086       # 8,6%
"{0:0.00%}"    -f 0.086       # 8,60%
"{0:0.%}"      -f 0.086       # 9%
"{0:.%}"       -f 0.086       # 9%

# вывести диапазон чисел в формате 001,002 и т.д
0..100| % {"$_".PadLeft('3','0')}
0..100| % {"{0:d3}" -f  $_}

#=======================================================
# ВЫДЕЛЕНИЕ ТЕКСТА ЦВЕТОМ
#=======================================================

# выведем все доступные цвета и подсветим их
0..15| % {Write-Host ([ConsoleColor]$_) -f ([ConsoleColor]$_)}

# выведем в одно предложение все доступные цвета и каждое имя раскрасим в его цвет
[Enum]::GetValues([ConsoleColor])| % {write-host ("$_"+" ") -f $_ -NoNewline}

[Enum]::GetValues([ConsoleColor])| % {write-host ("[{0}]{1}" -f ([int]$_),$_) -for $_}

# раскрасим все слова в предложении 
$c=0;
(@"
однажды, в студеную зимнюю пору, 
я из лесу вышел; был сильный мороз
"@) -split [char]32| Foreach {write-host ($_+" ") -f ([ConsoleColor]$c++) -NoNewline}

$c=0;cat 1.txt| % {
    ($_ -split [char]32| % {
        write-host ($_+" ") -f ([ConsoleColor]$c++) -n;if ($c -gt 15){$c=0}});
            write-host ""}

#=======================================================
# МАТЕМАТИКА
#=======================================================

 # удвоить каждый элемент списка
1..10| % {$_*2}
# или так
(1..10).ForEach({$_*2})

# удвоить каждый элемент списка - вывести как строку значений через запятую
(1,2,3,4,5| % {$_*2}) -join ","
 
# удвоить каждый элемент списка - записать явно  как массив значений int
[int[]]$m=1,2,3,4,5| % {$_*2}

# экзотический способ  проделать подобные операции над элементами
# прибавить 1 к каждому элементу списка
[regex]::replace(@(1,2,3,4,5),"[0-9]", { [int]$args[0].Value+1})
# удвоить каждый элемент списка
[regex]::replace(@(1..5),"\d", { [int]$args[0].Value *2})

$res=0
# вычисляет частное двух чисел - в $res возвращается остаток
[math]::DivRem(5,2, [ref]$res)

# возвращает целую часть числа
[math]::Truncate(10.7)
#=======================================================
# СТАТИЧЕСКИЕ LINQ МЕТОДЫ 
#=======================================================

[Linq.Enumerable]::Repeat("word",1000)                          # повторить элемент n-ое число раз
[Linq.Enumerable]::Range(0,10).Where({$_ % 2},"First",2)        # вывести первые два нечетных числа
[Linq.Enumerable]::Range(0,10).Where({$_ % 2},"Last",2)         # вывести последние два нечетных числа
[Linq.Enumerable]::Range(0,10).Where({$_ % 2},"SkipUntil",2)    # вывести первые два четных числа
$Split=[Linq.Enumerable]::Range(0,10).Where({$_ % 2},"Split")   # поделить последовательность на два субмассива, 
# где в первом - то, что удовлетворяет условию (нечетные числа), во втором - то, что нет (четные).
$Split[0]
$Split[1]
[Linq.Enumerable]::Distinct([int[]]@(1,2,2,2,2))              # удалить дубликаты
[Linq.Enumerable]::Intersect([int[]]@(1,2,3),[int[]]@(0,2))   # выбрать пересекающиеся элементы 
[Linq.Enumerable]::Except([int[]]@(1,1,2,3,4),[int[]]@(1,2))  # выбрать элементы которые есть в первой, но не во второй; повторы в первой также исключаются
[Linq.Enumerable]::First([int[]]@(1,2,3))                     # получить первый элемент последовательности
[Linq.Enumerable]::Last( [int[]]@(1,2,3))                     # получить последний элемент последовательности
[Linq.Enumerable]::ElementAt([int[]]@(1,2,3),2)               # получить элемент последовательности по индексу
[Linq.Enumerable]::Take( [int[]]@(1,20,30),2)                 # взять указанное число элементов последовательности
[Linq.Enumerable]::Skip( [int[]]@(1,20,30),1)                 # пропустить указанное число элементов последовательности, вернуть остальные
[Linq.Enumerable]::Min([int[]]@(9,99,999,99999))              # получить минимальное число в последовательности
[Linq.Enumerable]::Max([int[]]@(9,99,999,99999))              # получить максимальное число в последовательности
[Linq.Enumerable]::Sum([int[]]@(0..1000))                     # получить сумму элементов последовательности 
[Linq.Enumerable]::Average([int[]]@(1,2,3,4))                 # получить cреднее арифметическое числовых значений элементов последовательности 
[Linq.Enumerable]::Contains([int[]]@(1,2),2)                  # проверить содержится ли элемент в последовательности   
[Linq.Enumerable]::Any([int[]]@(1,2))                         # проверить содержится ли хоть один элемент в последовательности  
[Linq.Enumerable]::ToList([int[]]@(9,99,999,99999))           # преобразовать последовательность в тип List  
[Linq.Enumerable]::AsEnumerable([int[]]@(9,99,999,99999))     # преобразовать последовательность в тип IEnumerable<T> 

# мгновенная генерация большого файла
[IO.File]::WriteAllLines("$($pwd.path)\1.txt", [Linq.Enumerable]::Repeat("aaaaaaaaaa",3000000));

# Этот список, разумеется, неполный. К тому же, почти все методы имеют перегрузки. 
# Есть также методы в которых можно использовать предикаты и так называемые action'ы

#=======================================================
# INTERNET 
#=======================================================

# получить все ссылки со страницы
(wget "http://www.cyberforum.ru/").Links.Href

# получить страницу как html
(wget "http://www.cyberforum.ru/").Content|out-file cyberforum.html

# получить таблицу с полями: имя ссылки, адрес
 (wget "http://www.cyberforum.ru/").Links| select innertext, href

<#
# так почему то не получается вывести таблицу
((wget "http://www.cyberforum.ru/").Links)| ft ` 
        @{n="Имя ссылки";  e={$_.innertext}},
        @{n="Адрес";       e={ [Uri]::UnEscapeDataString($_.href)}}

#>

 
# экранирование адресов URL  и передаваемых данных в запросах
[Uri]::EscapeDataString("!@#$%^&*()_-+=|\/{}<>':;?~.,")
#=> %21%40%23%24%25%5E%26%2A%28%29_-%2B%3D%7C%5C%2F%7B%7D%3C%3E%60%27%3A%3B%3F~.%2C
 
[Uri]::EscapeUriString( "!@#$%^&*()_-+=|\/{}<>':;?~.,")
#=> !@#$%25%5E&*()_-+=%7C%5C/%7B%7D%3C%3E%60':;?~.,

#=======================================================
# ПРОФИЛИРОВАНИЕ (ЗАМЕРЫ ВРЕМЕНИ РАБОТЫ КОДА)
#=======================================================
# встроенное средство - выдает время в виде объекта TimeSpan
measure-command {for ($i=0;$i -le 1000000;$i++){}}
# при желании объект можно привести к строке вида 00:00:00.0000000
"$(measure-command {for ($i=0;$i -le 1000000;$i++){}})"

# средства из NET - также выдают объект TimeSpan
$startTiks = [DateTime]::Now.Ticks
for ($i=0;$i -le 1000000;$i++){}
([TimeSpan]([DateTime]::Now.Ticks - $startTiks)).ToString()

# более короткий вариант
"$([TimeSpan]([DateTime]::Now.Ticks - $startTiks))" 

# используем класс StopWatch
$sw=[Diagnostics.StopWatch]::StartNew()
for ($i=0;$i -le 1000000;$i++){}
$sw.Stop()
"$($sw.Elapsed)"

$sw=[Diagnostics.StopWatch]::StartNew()
(1..10000).ForEach({$_})
"$sw.Stop()
$($sw.Elapsed)"

$sw = New-Object -TypeName "Diagnostics.StopWatch"
$sw.Start()
(1..10000).ForEach({$_})
$sw.Stop()
"$($sw.Elapsed)"

#=======================================================
# ПЛАНИРОВАНИЕ ЗАДАНИЙ
#=======================================================
# выполнить сегодня
$trigger = New-JobTrigger -Once -at 17:45

# выполнить в определенный день
$trigger = New—JobTrigger –Once –At "7/20/2012 3:00 AM"

#Триггер по условию AtLogOn для пользователя LAB\admin создается следующим образом
$trigger = New—JobTrigger —AtLogOn —User LAB\admin

#Триггер по условию Daily создается следующим образом
$trigger = New—JobTrigger –Daily –At "6:15 AM" –DaysInterval 3

#Триггер по условию Weekly создается следующим образом
# каждые две недели по Monday, Wednesday, Friday в 21:00
$trigger = New—JobTrigger –Weekly –DaysOfWeek Monday, Wednesday, Friday –At "21:00" –WeeksInterval 2

# Каждый 1,3,5 (понедельник, среда и пятница) день недели в 3 утра
$trigger = New—JobTrigger –Weekly –DaysOfWeek 1,3,5 –At 3:00AM

# создать задание с указанным триггером
$job = Register-ScheduledJob -Name JobName -FilePath "$PSScriptRoot\cleaner.ps1" -Trigger $trigger

# удалить задание по имени
Unregister-ScheduledJob -name JobName

# получить триггеры
Get-ScheduledJob| Get-JobTrigger

# или  так
$list=@() # список ненайденных Id триггеров
(Get-ScheduledJob).GetTriggers([int[]]@(1,2,3,4),[ref]$list)

# получить какой-то один триггер по его id
(Get-ScheduledJob).GetTrigger(1)

# включить отключенный триггер
Get-ScheduledJob -Name Test3| Get-JobTrigger|Enable-JobTrigger

# удалить указанные триггеры
(Get-ScheduledJob).RemoveTriggers([int[]]@(2,3,4),$false)

Remove-JobTrigger -name Job -TriggerId 2
Get-ScheduledJob | Get-JobTrigger | Where-Object {$_.Frequency -eq "AtStartup"} | ForEach-Object { Remove-JobTrigger -InputObject $_.JobDefinition -TriggerID $_.ID}

# создать триггер и добавить его в существующее задание
$Daily = New-JobTrigger -Daily -At 3AM
Add-JobTrigger -Trigger $Daily -Name TestJob

# перезапустить задание
(Get-ScheduledJob -Name JobName).Run()
(Get-ScheduledJob -Name JobName).StartJob()
# стартует без вывода информации о задании в консоль
(Get-ScheduledJob -Name JobName).RunAsTask() 

$jobDef = [Microsoft.PowerShell.ScheduledJob.ScheduledJobDefinition]::LoadFromStore('JobName', "$env:appdata\Microsoft\Windows\PowerShell\ScheduledJobs"); 
$jobDef.Run()
# или так
((Get-ScheduledJob)::LoadFromStore('JobName', "$env:appdata\Microsoft\Windows\PowerShell\ScheduledJobs")).Run()

# удалить всю историю выполнения заданий
(Get-ScheduledJob).ClearExecutionHistory()

# удалить задание ($true - stop any running instances of the scheduled job definition)
(Get-ScheduledJob -Name JobName).Remove($true)

# узнать состояние задания: включено\отключено
(Get-ScheduledJob -Name JobName).Enabled

# отключить  с сохранением результатов
(Get-ScheduledJob -Name JobName).SetEnabled($false,$true)
# включить
(Get-ScheduledJob -Name Test3).SetEnabled($true,$true)

# получить командную строку запуска задания
(Get-ScheduledJob -Name JobName).PSExecutionArgs

# получить путь до скрипта или текст команды задания
(Get-ScheduledJob -Name JobName).Command

#=======================================================
# ПОТОКИ
#=======================================================
# приостановить выполнение текущего потока программы
[Threading.Thread]::CurrentThread.Suspend()
# возобновить выполнение текущего потока программы
[Threading.Thread]::CurrentThread.Resume()
# блокирует вызывающий поток до завершения потока или истечения указанного времени в миллисек.
[Threading.Thread]::CurrentThread.Join(3000)

#=======================================================
# ЗВУКИ
#=======================================================
[Media.SystemSounds]::Asterisk.Play()
[Media.SystemSounds]::Exclamation.Play()
[Media.SystemSounds]::Beep.Play()
#=======================================================
# ПАРАЛЛЕЛЬНЫЕ ВЫПОЛНЕНИЕ ЗАДАЧ
#=======================================================

# паралелльная выполнение задач - на примере загрузки контента из интерента
workflow Test-Workflow
        {
            Parallel
            {
                wget 'http://www.cyberforum.ru/robots.txt' -OutFile 'robots1.txt';
                wget 'http://www.cyberforum.ru/robots.txt' -OutFile 'robots2.txt';
                wget 'http://www.cyberforum.ru/robots.txt' -OutFile 'robots3.txt';
            }
  }

# создадим три файла по 3 млн. строк используя переданный контент для заполнения
# скорость выполнения данного кода ~6 секунд
# аналогичный код на C# выполняется за 1-2 сек.
workflow CreateDict($words) {
    foreach –parallel ($w in $words){
    $workflow:c++
    sc ("test"+$c+".txt") ([Linq.Enumerable]::Repeat($words[$c-1],3000000));
   }
 }

CreateDict ("aaaaaaaaaa", "bbbbbbbbbb","ccccccccccccc")

# на примере предыдущего скрипта перепишем нашу загрузку контента из интернета
workflow ParallelDownload($urls) {
    foreach –parallel ($u in $urls){
    $workflow:c++
    # получить последний элемент пути - имя файла для сохранения - можно разными способами
    # wget $u -OutFile ($u -split "/")[-1];
    # wget $u -OutFile $u.split("/")[-1];
    wget $u -OutFile  ([uri]$u).Segments[-1]
    

    }
 }

ParallelDownload ('http://www.cyberforum.ru/robots.txt',
                'http://www.cyberforum.ru/robots1.txt',
                'http://www.cyberforum.ru/robots2.txt')

# параллельное выполнение команды на всех компьютерах сразу
Invoke-AsWorkflow -Expression "ipconfig /all" -PSComputerName (cat DomainControllers.txt) -AsJob -JobName IPConfig



$bytes = [bitconverter]::GetBytes([int64] "0xf05d42655f12")
[array]::Reverse( $bytes)
[bitconverter]::ToInt64($bytes,0)

#$bytes = ([int64] "0xf05d42655f12"  | Format-Hex).Bytes
#[array]::Reverse( $bytes)
#[bitconverter]::ToInt64($bytes,0)
