#!/bin/bash

# parametr 1 - url do pliku do pobrania
# parametr 2 - haslo do archiwum zakodowane w base64
# nazwa plilu powinna byc taka sama jak archiwum
#(rozni sie tylko rozszezeniem)
# parametr 3 - ilosc kolumn  w pliku wejsciowym 
# parametr 4 - maksymalna wartosc kolumny OrderQuantity
# parametr 5 - sciezka do pliku InternetSales_old.txt 
# parametr 6 - nr_indeksu
# parametr 7 - nazwa bazy danych ( do komendy mysql)
# parametr 8 - password coded in base64
# parametr 9 - hostname
# parametr 10 - email adress to send mail and files

# przykladowe wywolanie:
# bash script.sh <url_to_file> <password_in _base64> 7 100 <path_to_file_to_differnce> <nr_indeksu> <db_name> <db_password> <hostname> <email>


mkdir PROCESSED
TIMESTAMP=$(date '+%Y%m%d')

log_filename="$0_$TIMESTAMP.log"
touch PROCESSED/$log_filename

# pobieranie pliku
# ///////////////////////////////////////////////////////////////////////
wget -cq "$1" 
EXITCODE=$?
if [ $EXITCODE -ne 0 ];then
	echo "ERROR while downloading file"
	TIME=$(date '+%Y%m%d%H%M%S')
 	echo "$TIME - Downloading file - Error" >>PROCESSED/"$log_filename"
	exit 1
else
	TIME=$(date '+%Y%m%d%H%M%S')
 	echo "$TIME - Downloading file - Succesful" >>PROCESSED/"$log_filename"
fi

# rozpakowywanie archiwum
# /////////////////////////////////////////////////////////////////////////////////

filename=$(basename "$1")
password=$(echo "$2" | base64 -d)
unzip -qP "$password" $filename   

EXITCODE=$?
if [ $EXITCODE -ne 0 ];then
        echo "ERROR while extracting file"
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Extracting file - Error" >>PROCESSED/"$log_filename"
        exit 1
else
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Extracting file - Succesful" >>PROCESSED/"$log_filename"
fi

# walidacja pliku 

extension=".txt"
filename=$(basename $filename .zip)
filename_txt="$filename$extension"

dowloaded_nlines=$(cat $filename_txt |wc -l)	        		# linie pobrane z internetu 
mail_downloaded="Downloaded File has: $dowloaded_nlines lines"
echo -e "\t\t$mail_downloaded" >>PROCESSED/"$log_filename"


sed -i '/^$/d' "$filename_txt" 						# remove empty lines

EXITCODE=$?
if [ $EXITCODE -ne 0 ];then
        echo "ERROR while removing empty lines from file"
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Removing empty lines from file - Error" >>PROCESSED/"$log_filename"
        exit 1
else
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Removing empty lines from file - Succesful" >>PROCESSED/"$log_filename"
fi


without_empty_nlines=$(wc -l < "$filename_txt")   			# count empty lines
empty_nlines="$(($dowloaded_nlines-$without_empty_nlines))"
echo -e "\t\tDowloaded file has: $empty_nlines empty lines" >> PROCESSED/"$log_filename"

# remove lines with incorrect number of columns
# //////////////////////////////////////////////////////////////////////

filename_bad=${filename}".bad"${TIMESTAMP}

awk -v n="$3" -F'|' 'NF!=n ' "$filename_txt" > "$filename_bad"     
awk -v n="$3" -F'|' 'NF==n ' "$filename_txt" > temp_awk.txt
mv temp_awk.txt "$filename_txt" 

EXITCODE=$?
if [ $EXITCODE -ne 0 ];then
        echo "ERROR while removing lines with wrong number of columns file"
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Removing lines with wrong number of columns from file - Error" >>PROCESSED/"$log_filename"
        exit 1
else
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Removing lines with wrong number of columns from file - Succesful" >>PROCESSED/"$log_filename"
fi

invalid_ncol=$(wc -l < "$filename_bad")     				# count num of bad rows 				
echo -e "\t\tDownloaded file has: $invalid_ncol wrong length rows" >>PROCESSED/"$log_filename"

# remove duplicate lines
# ////////////////////////////////////////////////////////////////////

awk 'NR == 1; NR>1 {print $0 |"sort -n"}' "$filename_txt" > sorted_txt  # use awk to save header line on the top of file 
uniq -D sorted_txt  >> "$filename_bad"					# add duplicated lines to bad file

EXITCODE=$?
if [ $EXITCODE -ne 0 ];then
        echo "ERROR while removing duplicated lines from file"
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Removing duplicated lines from file - Error" >>PROCESSED/"$log_filename"
        exit 1
else
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Removing duplicated lines from file - Succesful" >>PROCESSED/"$log_filename"
fi


uniq -u sorted_txt > "$filename_txt"
rm sorted_txt

bad_lines_with_duplicated=$(wc -l < "$filename_bad")
duplicated_nlines="$(($bad_lines_with_duplicated-$invalid_ncol))"
mail_duplicated="Downloaded file has: $duplicated_nlines duplicated lines"
echo -e "\t\t$mail_duplicated" >>PROCESSED/"$log_filename"

# usuniecie linii gdzie, kolumna Orderquantity>100 
# //////////////////////////////////////////////////////////////

awk -v val=$4 -F'|' '$5 >val || $5 ==""' "$filename_txt" |tail -n +2 >> "$filename_bad"    #added check if field is empty !!!
head -n 1 "$filename_txt" >header_line
cat header_line >tmp_awk_quant
awk -v val=$4 -F'|' '$5 <=val && $5!="" ' "$filename_txt"  >>tmp_awk_quant

EXITCODE=$?
if [ $EXITCODE -ne 0 ];then
        echo "ERROR while removing bad quantity column values from file"
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Removing wrong quantity values from file - Error" >>PROCESSED/"$log_filename"
        exit 1
else
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Removing wrong quantity values from file - Succesful" >>PROCESSED/"$log_filename"
fi

mv tmp_awk_quant "$filename_txt"

bad_lines_with_quantity=$(wc -l < "$filename_bad")
quant_nlines="$(($bad_lines_with_quantity-$bad_lines_with_duplicated))"
echo -e "\t\tDowloaded file has: $quant_nlines bad OrderQuality lines" >>PROCESSED/"$log_filename"


#porownaj z plikim InternetSales_old.txt
# ///////////////////////////////////////////
tail -n +2 "$filename_txt" | sort > sorted_new_txt					# tail to omit header line!
dos2unix -q "$5"   								# to change file format !!!!!! (erase line break '^M') 
tail -n +2 "$5" | sort > sorted_old_txt

diff  sorted_old_txt sorted_new_txt  --changed-group-format=""  >> "$filename_bad"
EXITCODE=$?
 											# exit code 0 - files not differ, 	
     											#  1- files differ, greater-->error
if [ $EXITCODE -gt 1 ];then
        echo "ERROR while removing lines which we already have in our file"
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Removing lines which we already have in our file - Error" >>PROCESSED/"$log_filename"
        exit 1
else
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME -Removing lines which we already have in our file - Succesful" >>PROCESSED/"$log_filename"
fi

all_bad_lines=$(wc -l <"$filename_bad")
lines_common_to_both_files=$(($all_bad_lines-$bad_lines_with_quantity))
echo -e "\t\tDowloaded file has $lines_common_to_both_files common lines with  our file" >> PROCESSED/"$log_filename"

cat header_line > tmp_after_check 
diff sorted_old_txt sorted_new_txt --old-group-format=""  --unchanged-group-format=""  >>tmp_after_check
mv tmp_after_check "$filename_txt"

# usuwanie linii ktore maja wartosc w SecretCode
# /////////////////////////////////////////////////////////////

awk  -F'|' ' $7 !=""'  InternetSales_new.txt  | tail -n +2 | cut -d'|' -f -6 | awk '{print $0"|"}' >> "$filename_bad"
EXITCODE=$?
if [ $EXITCODE -ne 0 ];then
        echo "ERROR with securecode column file"
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Removing lines which have data in securecode column in file - Error" >>PROCESSED/"$log_filename"
        exit 1
else
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Removing lines which have data in securecode column in file - Succesful" >>PROCESSED/"$log_filename"
fi

all_bad_lines_without_securecode=$(wc -l <"$filename_bad")
lines_with_securecode=$(($all_bad_lines_without_securecode-$all_bad_lines))
echo -e "\t\tDowloaded file has $lines_with_securecode lines with securecode column not empty" >>PROCESSED/"$log_filename"

cat header_line >tmp_non_securecode
tail -n +2 InternetSales_new.txt|awk  -F'|' ' $7 ==""'  >>tmp_non_securecode 			# field ssecurecode should be empty 
mv tmp_non_securecode "$filename_txt"

rm sorted_old_txt sorted_new_txt

# usuniecie lini gdzie imie i nazwisko nie ma przecinka miedzy
#///////////////////////////////////////////////////////////////

awk -F"|" '!match($3,",") ' "$filename_txt" | tail -n +2  >> "$filename_bad"

cat header_line >tmp_without_comma
awk -F"|" 'match($3,",") ' "$filename_txt"  >> tmp_without_comma

EXITCODE=$?
if [ $EXITCODE -ne 0 ];then
        echo "ERROR while removing wrong name and surname field - do not have comma"
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Removing wrong name and surname field which do not have comma - Error" >>PROCESSED/"$log_filename"
        exit 1
else
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Removing wrong name and surname field which do not have comma - Succesful" >>PROCESSED/"$log_filename"
fi

mv tmp_without_comma "$filename_txt"
all_bad_lines_name_surname=$(wc -l <"$filename_bad")
lines_with_bad_name_surname=$(($all_bad_lines_name_surname-$all_bad_lines_without_securecode))
mail_all_bad="File has got $all_bad_lines_name_surname wrong or not appropriate lines"
echo -e "\t\tDowloaded file has $lines_with_bad_name_surname lines without comma between name and surname" >>PROCESSED/"$log_filename"

#podziel Customer_Name na FIRST_NAEM and LAST_NAME
 
echo "FIRST_NAME" > first_name
echo "LAST_NAME" > last_name
cut -d'|' -f-2 "$filename_txt" >first2col
cut -d'|' -f4- "$filename_txt"  >last4col
cut -d'|' -f3 "$filename_txt" | tr -d "\""| cut -d','  -f2 |tail -n +2 >>first_name
cut -d'|' -f3 "$filename_txt" | tr -d "\""| cut -d','  -f1 |tail -n +2 >> last_name 
paste -d'|' first2col first_name last_name last4col > "$filename_txt"


EXITCODE=$?
 if [ $EXITCODE -ne 0 ];then
        echo "ERROR while splitting Customer_name field in file"
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Splitting column Customer_name to first and last name - Error" >>PROCESSED/"$log_filename"
        exit 1
else
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Splitting column Customer_name to first and last name  - Succesful" >>PROCESSED/"$log_filename"
fi

rm first2col last4col first_name last_name header_line

# create table and insert filtred data to the mysql db 
# ////////////////////////////////////////////////////////////////////////////////////////////

col1=$(head -n1 "$filename_txt" |cut -d'|' -f1)
col2=$(head -n1 "$filename_txt" |cut -d'|' -f2)
col3=$(head -n1 "$filename_txt" |cut -d'|' -f3)
col4=$(head -n1 "$filename_txt" |cut -d'|' -f4)
col5=$(head -n1 "$filename_txt" |cut -d'|' -f5)
col6=$(head -n1 "$filename_txt" |cut -d'|' -f6)
col7=$(head -n1 "$filename_txt" |cut -d'|' -f7)
col8=$(head -n1 "$filename_txt" |cut -d'|' -f8)

password_db=$(echo "$8" | base64 -d)
export MYSQL_PWD=$password_db 									# to suppress warning 
db_name="CUSTOMERS_$6"

mysql -u "$7" -h  "$9" -P 3306 -D "$7" --silent -e "CREATE TABLE $db_name($col1 INTEGER,$col2 VARCHAR(20),$col3 VARCHAR(40),$col4 VARCHAR(40),$col5 VARCHAR(20),$col6 VARCHAR(20),$col7 FLOAT,$col8 VARCHAR(20) );"

EXITCODE=$?
if [ $EXITCODE -ne 0 ];then
        echo "ERROR while creating table in remote db"
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Creating table in db - Error" >>PROCESSED/"$log_filename"
        exit 1
else
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Creating table in db - Succesful" >>PROCESSED/"$log_filename"
fi

tail -n +2 "$filename_txt" | tr ',' '.' >filename_txt_without_header   # change comma to dot to easily insert to db 
mv "$filename_txt" PROCESSED/

mysql -u "$7" -h  "$9" -P 3306 -D "$7" --silent -e "LOAD DATA LOCAL INFILE 'filename_txt_without_header' INTO TABLE $db_name FIELDS TERMINATED BY '|';"

EXITCODE=$?
if [ $EXITCODE -ne 0 ];then
        echo "ERROR inserting data to db table"
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Inserting data to db table - Error" >>PROCESSED/"$log_filename"
        exit 1
else
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Inserting data to db table - Succesful" >>PROCESSED/"$log_filename"
fi

rm filename_txt_without_header


# update wartosci SecretCode w tabeli  losowym stringiem
# ///////////////////////////////////////////////////////////////////////////////

random_string="$(openssl rand -hex 5)"

mysql -u "$7" -h  "$9" -P 3306 -D "$7" --silent -e "UPDATE $db_name SET $col8='$random_string';"

EXITCODE=$?
if [ $EXITCODE -ne 0 ];then
        echo "ERROR while upadating SecureCode"
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Updating table- Error" >>PROCESSED/"$log_filename"
        exit 1
else
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Updatind table  - Succesful" >>PROCESSED/"$log_filename"
fi
# export data from table to .csv file <I try to use mysqldump command but I did not managed to set it properly)
# ///////////////////////////////////////////////////////////////////////////////////////////////////////////

mysql -u "$7" -h  "$9" -P 3306 -D "$7" --silent -e "SELECT * FROM $db_name;"|sed 's/\t/,/g' > $db_name.csv

EXITCODE=$?
if [ $EXITCODE -ne 0 ];then
        echo "ERROR while exporting table to csv file"
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Exporting table to .csv file - Error" >>PROCESSED/"$log_filename"
        exit 1
else
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Exporting table to .csv file  - Succesful" >>PROCESSED/"$log_filename"
fi

# compress .csv file
# /////////////////////////////////////////////////////////////////////////////////

zip  -q $db_name $db_name.csv  

EXITCODE=$?
if [ $EXITCODE -ne 0 ];then
        echo "ERROR while zipping .csv file"
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Zipping .csv file - Error" >>PROCESSED/"$log_filename"
        exit 1
else
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Zipping .csv file - Succesful" >>PROCESSED/"$log_filename"
fi


mail_all_bad="File has got $all_bad_lines_name_surname wrong or not appropriate lines"

good_lines=$(($dowloaded_nlines-$all_bad_lines_name_surname))
mail_all_good="File has got $good_lines good lines"

count_table=$(mysql -u "$7" -h  "$9" -P 3306 -D "$7" --silent -e "SELECT COUNT(*) FROM $db_name;")
mail_insert="To database was loaded $count_table lines"

echo -e "$mail_downloaded\n$mail_all_good \n$mail_duplicated \n$mail_all_bad \n$mail_insert"

# send emails with attachment

# echo -e "$mail_downloaded\n$mail_all_good \n$mail_duplicated \n$mail_all_bad \n$mail_insert" |mailx -s "CUSTOMERS LOAD - $TIMESTAMP" $10
# mailx -s "$TIMESTAMP,$good_lines "-a $db_name.zip -a $log_filename $10
EXITCODE=$?
if [ $EXITCODE -ne 0 ];then
        echo "ERROR while sending mails"
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Sending email - Error" >>PROCESSED/"$log_filename"
        exit 1
else
        TIME=$(date '+%Y%m%d%H%M%S')
        echo "$TIME - Sending mail - Succesful" >>PROCESSED/"$log_filename"
fi


