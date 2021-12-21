#-----------------------------------------------------------------------------------------------------------------------------------------------
$path = "E:\AGH\SEMESTR 5\BAZY DANYCH PRZESTRZENNYCH\cw8-9\data"

# tworzenie katalogu PROCESSED
New-Item -Path "$path\PROCESSED" -ItemType Directory

$TIMESTAMP = ((Get-Date).toString("MM/dd/yyyy"))

#a) pobranie pliku
powershell -command "& {iwr https://home.agh.edu.pl/~wsarlej/Customers_Nov2021.zip -OutFile file.zip}"

#-----------------------------------------------------------------------------------------------------------------------------------------------
#b) rozpakowanie pliku
$shell = New-Object -ComObject shell.application
$zip = $shell.NameSpace("C:\Users\hp\file.zip")
foreach ($item in $zip.items()) {
  $shell.Namespace("E:\AGH\SEMESTR 5\BAZY DANYCH PRZESTRZENNYCH\cw8-9\data").CopyHere($item)
}


$file1 = "E:\AGH\SEMESTR 5\BAZY DANYCH PRZESTRZENNYCH\cw8-9\data\Customers_Nov2021.csv" 
$file1_content = Get-Content $file1
$file2 = "E:\AGH\SEMESTR 5\BAZY DANYCH PRZESTRZENNYCH\cw8-9\data\Customers_old.csv" 
$file3 = New-Item -Path "E:\AGH\SEMESTR 5\BAZY DANYCH PRZESTRZENNYCH\cw8-9\data\Customers_Nov2021_tmp.csv" 
$file4 = New-Item -Path "E:\AGH\SEMESTR 5\BAZY DANYCH PRZESTRZENNYCH\cw8-9\data\Customers_Nov2021_tmp2.csv"
$TIMESTAMP = ((Get-Date).toString("MM/dd/yyyy"))
$file5 = "E:\AGH\SEMESTR 5\BAZY DANYCH PRZESTRZENNYCH\cw8-9\data\Customers_Nov2021.bad_" + ${TIMESTAMP} + '.csv'
#-----------------------------------------------------------------------------------------------------------------------------------------------
#c1)usuwanie  pustych linijek
Get-Content "E:\AGH\SEMESTR 5\BAZY DANYCH PRZESTRZENNYCH\cw8-9\data\Customers_Nov2021.csv" | Where-Object length -gt 0 | Out-File "E:\AGH\SEMESTR 5\BAZY DANYCH PRZESTRZENNYCH\cw8-9\data\Customers_Nov2021_tmp.csv"

$compare = Compare-Object -referenceObject $(Get-Content $file3) -differenceObject $(Get-Content $file2) 
$compare | Where-Object {$_.SideIndicator -eq '<='} | Select-Object InputObject | Out-File -FilePath $file4

#usuwa zbędne 3 pierwsze wiersze 
(Get-Content $file4) | 
    Where-Object { -not $_.Contains('InputObject') } | 
        Where-Object { -not $_.Contains('-----------') } | 
            Select-Object -Skip 1 |
                Out-File -FilePath $file4
#-----------------------------------------------------------------------------------------------------------------------------------------------
#c2) znajduje część wspólną i przenosi do pliku błędnego Customers_Nov2021.bad_${TIMESTAMP}.csv
Compare-Object -ReferenceObject (Get-Content $file3) -IncludeEqual (Get-Content $file2) | 
    Where-Object {$_.SideIndicator -eq '=='} | 
        Select-Object InputObject | 
            Out-File -FilePath $file5
$duplicates_content = Get-Content $file5

#usuwa zbędne 3 pierwsze wiersze 
(Get-Content $file5) | 
    Where-Object { -not $_.Contains('InputObject') } | 
        Where-Object { -not $_.Contains('-----------') } | 
            Select-Object -Skip 1 |
                Out-File -FilePath $file5

Get-Content $file4 > $file1
Remove-Item -Path $file3
Remove-Item -Path $file4

#-----------------------------------------------------------------------------------------------------------------------------------------------
#d) 
#Install-Module -Name PostgresqlCmdlets -RequiredVersion 17.0.6634.0


# tworzenie tabeli

#instalowanie modułu:
#Install-Module PostgreSQLCmdlets

$IndexNumber = 404002
$Password = '*****'
$User = 'postgres'
$Database = 'cw8-9'
$Server = 'PostgreSQL 13'
$Table = "CUSTOMERS_$IndexNumber"


Set-Location 'C:\Program Files\PostgreSQL\13\bin\';
$env:PGPASSWORD = $Password;
psql -U $User -d $Database -c "drop table $Table;"
psql -U $User -d $Database -c "drop table best_customers_404002;"
#psql -U $User -d $Database -c "create extension if not exists postgis;"
psql -U $User -d $Database -c "create table if not exists $Table (first_name varchar(50), last_name varchar(50), email varchar(50), lat float, long float);"



#-----------------------------------------------------------------------------------------------------------------------------------------------
#E)	załaduje dane ze zweryfikowanego pliku do tabeli CUSTOMERS_${NUMERINDEKSU}

Set-Location 'C:\Program Files\PostgreSQL\13\bin\';
$env:PGPASSWORD = $Password;
$csv_ok = Get-Content "E:\AGH\SEMESTR 5\BAZY DANYCH PRZESTRZENNYCH\cw8-9\data\Customers_Nov2021.csv"

$csv_ok = $csv_ok -replace ",", "','"


for($i=0; $i -lt $csv_ok.Count-2; $i++)
    {
        $csv_ok[$i] = "'" + $csv_ok[$i] + "'"
        $values = $csv_ok[$i]
        psql -U postgres -d $Database -w -c "insert into $Table (first_name, last_name, email, lat, long) values ($values);"
    }
#-----------------------------------------------------------------------------------------------------------------------------------------------
#F) przeniesie przetworzony plik do podkatalogu PROCESSED dodając prefix ${TIMESTAMP}_ do nazwy pliku
Set-Location $path

${TIMESTAMP1} = ${TIMESTAMP} + "_"
Move-Item -Path "$path\Customers_Nov2021.csv" -Destination "$path\PROCESSED" -PassThru -ErrorAction Stop
Rename-Item -Path "$path\PROCESSED\Customers_Nov2021.csv" "${TIMESTAMP1}Customers_Nov2021.csv"
#-----------------------------------------------------------------------------------------------------------------------------------------------


#G)	wyśle email zawierający nst. raport: temat: CUSTOMERS LOAD - ${TIMESTAMP}, treść:
#•	liczba wierszy w pliku pobranym z internetu,

$l_wierszy_w_pobranym_pliku = ($file1_content).Count

#•	liczba poprawnych wierszy (po czyszczeniu),
$l_wierszy_w_poprawnym_pliku_pc = (Get-Content "$path\PROCESSED\${TIMESTAMP1}Customers_Nov2021.csv").Count

#•	liczba duplikatów w pliku wejściowym
$content_pliku_z_bledami = Get-Content "$path\Customers_Nov2021.bad_${TIMESTAMP}.csv"
$l_wierszy_w_pliku_z_bledami = ($content_pliku_z_bledami | Where-Object length -gt 0 ).Count - 1

#•	ilość danych załadowanych do tabeli CUSTOMERS_${NUMERINDEKSU}.
$l_kolumn_w_poprawnym_pliku = (Get-Content "$path\PROCESSED\${TIMESTAMP1}Customers_Nov2021.csv"| get-member -type NoteProperty).Count -1
$ilosc_danych = $l_wierszy_w_poprawnym_pliku_pc * $l_kolumn_w_poprawnym_pliku



#wysyłanie maila

    $nadawca = "juliakwasniak@gmail.com"
    $odbiorca = "juliakwasniak@gmail.com"
    $emailpass = '*****'
    $temat = "CUSTOMERS LOAD - ${TIMESTAMP}"
    $tresc = "Liczba wierszy w pliku pobranym z internetu: ${l_wierszy_w_pobranym_pliku}; iczba poprawnych wierszy (po czyszczeniu): $l_wierszy_w_poprawnym_pliku_pc; liczba duplikatów w pliku wejściowym: $l_wierszy_w_pliku_z_bledami; ilość danych załadowanych do tabeli $Table : $ilosc_danych"




    $message = New-Object Net.Mail.MailMessage
    $message.From = $nadawca
    $message.To.Add($odbiorca)
    $message.Subject = $temat
    $message.Body = $tresc
    $smtp = New-Object Net.Mail.SmtpClient("smtp.gmail.com", 587)
    $smtp.EnableSSL = $true
    $smtp.Credentials = New-Object System.Net.NetworkCredential($nadawca, $emailpass)
    $smtp.Timeout = 500000 
    $smtp.Send($message)
    write-host "Mail Sent" 
#-----------------------------------------------------------------------------------------


#H)	uruchomi kwerendę SQL, która znajdzie imiona i nazwiska klientów, którzy mieszkają w promieniu 50 kilometrów od punktu: 41.39988501005976, -75.67329768604034 
#(funkcja ST_DistanceSpheroid) i zapisze je do tabeli BEST_CUSTOMERS_${NUMERINDEKSU},

Set-Location 'C:\Program Files\PostgreSQL\13\bin\';
$env:PGPASSWORD = $Password;
psql -U $User -d $Database -w -f "E:\AGH\SEMESTR 5\BAZY DANYCH PRZESTRZENNYCH\cw8-9\data\zapytanie.txt" 
#funkcja zwraca odległóść w metrach

#-----------------------------------------------------------------------------------
#I)	wyeksportuje zawartość tabeli BEST_CUSTOMERS_${NUMERINDEKSU} do pliku csv o takiej samej nazwie jak tabela źródłowa,

Set-Location 'C:\Program Files\PostgreSQL\13\bin\';
$env:PGPASSWORD = $Password;
psql -U $User -d $Database -w -c "COPY best_customers_404002 TO 'E:\AGH\SEMESTR 5\BAZY DANYCH PRZESTRZENNYCH\cw8-9\data\best_customers_404002.csv' DELIMITER ',' CSV HEADER;" 

#J)	skompresuje wyeksportowany plik csv
Compress-Archive -Path "$path\best_customers_404002.csv" -DestinationPath "$path\best_customers_404002.zip"


#K)	wyśle skompresowany plik do adresata poczty razem z raportem o treści: data ostatniej modyfikacji, ilość wierszy w pliku csv,
    Get-ItemProperty "$path\best_customers_404002.csv" | Format-Wide -Property CreationTime > "$path\creation_time.txt"
    $creation_time = Get-Content "$path\creation_time.txt"
    $ile_wierszy = (Get-Content "$path\best_customers_404002.csv").Count
    $temat2 = "RAPORT - ${TIMESTAMP}"
    $tresc2 = "Liczba wierszy w pliku csv: $ile_wierszy; data ostatniej modyfikacji: $creation_time "



    $message = New-Object Net.Mail.MailMessage
    $message.From = $nadawca
    $message.To.Add($odbiorca)
    $message.Subject = $temat2
    $message.Body = $tresc2
    $smtp = New-Object Net.Mail.SmtpClient("smtp.gmail.com", 587)
    $smtp.EnableSSL = $true
    $smtp.Credentials = New-Object System.Net.NetworkCredential($nadawca, $emailpass) 
    $smtp.Send($message)
    write-host "Mail Sent" 