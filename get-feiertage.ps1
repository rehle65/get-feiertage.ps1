<#
.SYNOPSIS

Berechnung der Feiertage eines Jahres.

.DESCRIPTION

Das Script ermittelt die für ein vorgegebenes Jahr folgende Termine:
- Alle christlichen Feiertage
- Karneval
- Muttertag
- Datum der Umstellung auf Sommerzeit
- Datum der Umstellung auf Winterzeit
- Tag der Deutschen Einheit

Die Ausgabe erfolgt tabellarisch nach Datum sortiert und beinhaltet auch den Wochentag.

.EXAMPLE
.\get-feiertage.ps1
.\get-feiertage.ps1 -jahr 2019

.PARAMETER jahr
Angabe des gewünschten Jahres, für das die Feiertage ermittelt werden sollen

.LINK
https://github.com/rehle65/get-feiertage.ps1

.NOTES
Version: 1.5
File Name: get-feiertage.ps1
Author: Roland Ehle, https://github.com/rehle65/get-feiertage.ps1
Requires: Powershell >= 2.0

01/2023 - Minor changes in Code to reflect exeptions
09/2018 - Thanksgiving (USA) hinzugefügt
02/2018 - Bugfix für Muttertag, wenn der 1. Mai auf einen Sonntag fällt.
02/2017 - Initial Version
#>


# Berechnung der Feiertage unter Verwendung der Gaußschen Osterformel
# Siehe auch https://de.wikipedia.org/wiki/Gau%C3%9Fsche_Osterformel

param([String]$jahr = (get-date).year)

$global:ausgabe = @()

$daynames = @("Ostersonntag","Rosenmontag","Karneval","Aschermittwoch","Karfreitag","Ostermontag","Himmelfahrt","Pfingstsonntag","Pfingstmontag","Fronleichnam","ErsterAdvent","ZweiterAdvent","DritterAdvent","VierterAdvent","ErsterMai","Muttertag","Sommerzeit","Winterzeit","Erntedank","Einheitstag","Reformationstag","Allerheiligen","Busstag","Volkstrauertag","Totensonntag","HeiligerAbend","Silvester","Neujahrstag","Dreikoenigstag","ErsterWeihnachtstag","ZweiterWeihnachtstag","Thanksgiving")

# Gauß'sche Osterformel
# Berechne die Werte für a, b, c, k, p, q ,M, d, N und e nach der Gaußschen Osterformel von 1816
$a = $jahr % 19
$b = $jahr % 4
$c = $jahr % 7
$k = [math]::truncate($jahr / 100)
$p = [math]::truncate((8 * $k + 13) / 25)
$q = [math]::truncate($k /4)

$M = (15 + $k - $p -$q) % 30
$d = (19 * $a + $M) % 30
$N = (4 + $k -$q) % 7
$e = (2 * $b + 4 * $c + 6 * $d + $N) % 7

$month = 3
# Exceptions
if (($d -eq 29) -and ($e -eq 6)) {
	$day = 50
} elseif (($d -eq 28) -and ($e -eq 6) -and ($a -gt 10)) {
	$day = 49
} else {
	$day = 22 + $d + $e
}

if ($day -gt 31) {
	$day = $day - 31
	$month = 4
}

# Basierend auf Ostersonntag, können andere Feiertage berechnet
$ostersonntag = get-date -year $jahr -Month $month -Day $day

$rosenmontag = $ostersonntag.AddDays(-48)
$karneval = $ostersonntag.AddDays(-47)
$aschermittwoch = $ostersonntag.AddDays(-46)
$karfreitag = $ostersonntag.AddDays(-2)
$ostermontag = $ostersonntag.AddDays(1)
$himmelfahrt = $ostersonntag.AddDays(39)
$pfingstsonntag = $ostersonntag.AddDays(49)
$pfingstmontag = $ostersonntag.AddDays(50)
$fronleichnam = $ostersonntag.AddDays(60)

# Buß- und Bettag fällt auf den Mittwoch vor dem Sonntag vor dem ersten Adventssonntag. Der erste Adventssonntag liegt drei Wochen vor dem vierten Adventssonntag. 
# Der vierte Adventssonntag ist wiederum der Sonntag vor dem 25. Dezember eines Jahres.
# Get-Date -UFormat %u

$Weihnachten = get-date -year $jahr -month 12 -day 25 -UFormat %u
if ($Weihnachten -eq 0) {
	$Weihnachten = 7
}

$ersterweihnachtstag = get-date -year $jahr -month 12 -day 25
$zweiterweihnachtstag = get-date -year $jahr -month 12 -day 26

$vierteradvent = (get-date -year $jahr -month 12 -day 25).AddDays(-$Weihnachten)
$ersteradvent = $vierteradvent.AddDays(-21)
$zweiteradvent = $vierteradvent.AddDays(-14)
$dritteradvent = $vierteradvent.AddDays(-7)

# Muttertag findet am zweiten Sonntag im Mai statt
$ErsterMai = get-date -year $jahr -month 5 -day 1
$firstmayday = get-date -year $jahr -month 5 -day 1 -uFormat %u


if ($firstmayday -gt 0) {
	$firstsundayinmay = $ErsterMai.AddDays(7 - $firstmayday)
} else {
	$firstsundayinmay = $ErsterMai
}

$muttertag = $firstsundayinmay.AddDays(7)

# Thanksgiving findet am vierten Donnerstag im November statt
$ersterNov = Get-Date -Year $jahr -Month 11 -Day 1
$firstnovday = Get-Date -Year $jahr -Month 11 -Day 1 -UFormat %u

if ($firstnovday -gt 4) {
	$firstthursdayinnov = $ersterNov.AddDays(4 + (7 - $firstnovday))
} elseif ($firstnovday -lt 4) {
	$firstthursdayinnov = $ersterNov.AddDays(4 - $firstnovday)
} else {
	$firstthursdayinnov = $ersterNov
}

$Thanksgiving = $firstthursdayinnov.AddDays(21)

# Umstellung von Winterzeit auf Sommerzeit fällt auf den letzten Sonntag im März
$lastmarch = get-date -year $jahr -month 3 -day 31
$lastmarchday = get-date -year $jahr -month 3 -day 31 -uFormat %u

if ($lastmarchday -ne 0) {
	$sommerzeit = $lastmarch.AddDays(-$lastmarchday)
} else {
	$sommerzeit = $lastmarch
}

# Umstellung von Sommerzeit auf Winterzeit fällt auf den letzten Sonntag im Oktober
$lastoctober = get-date -year $jahr -month 10 -day 31
$lastoctoberday = get-date -year $jahr -month 10 -day 31 -uFormat %u

if ($lastoctoberday -ne 0) {
	$winterzeit = $lastoctober.AddDays(-$lastoctoberday)
} else {
	$winterzeit = $lastoctober
}

# Erntedank fällt auf den ersten Sonntag im Oktober
$firstoctober = get-date -year $jahr -month 10 -day 1
$firstoctoberday = get-date -year $jahr -month 10 -day 1 -uFormat %u

if ($firstoctoberday -ne 0) {
	$erntedank = $firstoctober.AddDays(7 - $firstoctoberday)
} else {
	$erntedank = $firstoctober
}


$einheitstag = get-date -year $jahr -month 10 -day 3
$reformationstag = $lastoctober
$allerheiligen = get-date -year $jahr -month 11 -day 1

#Volkstrauertag ist 14 Tage vor dem ersten Advent
$volkstrauertag = $ersteradvent.AddDays(-14)

# Buß- und Bettag ist 11 Tage vor dem ersten Advent
$busstag = $ersteradvent.AddDays(-11)

# Totensonntag ist 7 Tage vor dem ersten Advent
$totensonntag = $ersteradvent.AddDays(-7)

$HeiligerAbend = get-date -year $jahr -month 12 -day 24
$silvester = get-date -year $jahr -month 12 -day 31

$neujahrstag = get-date -year $jahr -month 1 -day 1
$dreikoenigstag = get-date -year $jahr -month 1 -day 6

# Putting all together

foreach ($dayname in $daynames) {
	$feiertag = "" | Select-Object Datum,Feiertag,Wochentag,Value
	$value = get-variable $dayname -ValueOnly
	$feiertag.Datum = get-date $value -Format "dd.MM.yyyy"

	if ($dayname -ilike "ErsterMai") {
		$feiertag.Feiertag = "Tag der Arbeit"
	} elseif ($dayname -ilike "Erster*") {
		$feiertag.Feiertag = $dayname.Insert(6, " ")
	} elseif (($dayname -ilike "Zweiter*") -or ($dayname -ilike "Dritter*") -or ($dayname -ilike "Vierter*")) {
		$feiertag.Feiertag = $dayname.Insert(7, " ")
	} elseif ($dayname -ilike "Dreikoenigstag") {
		$Feiertag.Feiertag = "Heilige Drei Könige"
	} elseif ($dayname -ilike "Einheitstag") {
		$Feiertag.Feiertag = "Tag der Deutschen Einheit"
	} else {
		$feiertag.Feiertag = $dayname
	}
	$feiertag.Wochentag = get-date $value -Format dddd
	$feiertag.Value = $value

	$global:ausgabe += $feiertag
	
}
$global:ausgabe = $global:ausgabe | Sort-Object value
$global:ausgabe | Format-Table Datum,Feiertag,Wochentag