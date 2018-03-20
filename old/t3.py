
import os
import sys
import subprocess

tns_service = '@dprprod2'
sql_directory = 'sql_py/'

userid = 'lwilhoit'
password = 'nashira8'

sql_file = 't3 '

testing = True

if testing:
    comment1 = ''
    comment2 = ''
else:
    comment1 = '/*'
    comment2 = '*/'


sql_options = comment1 + ' ' + comment2

sql_login = 'sqlplus -S -L ' + userid + tns_service + '/' + password + ' '

response = subprocess.run(sql_login + '@' + sql_file + sql_options, 
                          stderr=subprocess.PIPE, stdout=subprocess.PIPE, shell=True)

stdout_str = response.stdout.decode('UTF-8') 
stderr_str = response.stderr.decode('UTF-8') 
print(stdout_str)
print(stderr_str)

