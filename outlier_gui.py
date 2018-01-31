
"""
Create tables to find high or outlier values in the PUR.
""" 

# To do:
# 1. Print output to screen during long running processes.
#    I tried doing that in long_running.py and test.sql
#    but this does not work like I want.
# 2. If an Oracle table needed for a script is too old 
#    (set by parameter num_days_old) ask user if they
#    still want to use it.  You cannot get user input
#    from a PL/SQL script, so you need a bit of other
#    to do that.

import os
import sys
import subprocess
# import traceback
import logging
logging.basicConfig(level=logging.INFO, format='*** %(levelname)s: %(message)s: %(asctime)s' )

#import daiquiri
#daiquiri.setup()
#logger = daiquiri.getLogger()

# Logging levels from lowest to highest:
# DEBUG
# INFO
# WARNING
# ERROR
# CRITICAL

# So, if you wanted to see only ERROR and CRITICAL logging, set level=logging.ERROR.

# For simple explanation of python logging, see "Automate the boring stuff with Python", p 221

from sys import version_info
if version_info.major == 2:
    # We are using Python 2.x
    logging.debug('Start of program, using Python 2.x')
    from Tkinter import *
    # Or: import Tkinter as tk
elif version_info.major == 3:
    # We are using Python 3.x
    logging.debug('Start of program, using Python 3.x')
    from tkinter import *
    # import tkinter as tk


tns_service = '@dprprod2'
sql_directory = 'sql_py/'
table_directory = 'tables/'
ctl_directory = 'sql_py/ctl_files/'
ctl_options = ' SKIP=1 errors=999999 LOG='

# Define tkinter variables;
# Note that you first need to define a variable for Tk().
root = Tk()
root.title("Run outlier procedures")
userid_tk = StringVar()
password_tk = StringVar() # defines the widget state as string

run_outliers_tk = BooleanVar()
run_outlier_setup_tk = BooleanVar()
run_fixed_tables_tk = BooleanVar()
run_ai_num_recs_tk = BooleanVar()
run_pur_rates_tk = BooleanVar()

stat_year_tk = IntVar()
num_stat_years_tk = IntVar()
num_days_old_tk = IntVar()
load_from_oracle_tk = BooleanVar()

# Importing function start_procedures does not work
#import start

def call_sql(sql_login, sql_file, *option_list):
    """ Call Oracle to run script in sql_file.
        Parameter sql_login is a string defined at the beginning of
        procedure start_procedures.  It contains the command "sqlplus"
        and the userid and password.

        Parameter sql_file is the name of the SQL script to be run.
    """
    logging.info("\n"+"*"*80)
    logging.info('Start of call_sql() using file %s', sql_file)
    try:
        logging.debug("Running Oracle script " + sql_file)

        sql_file = sql_directory+sql_file

        sql_options = ''
        for i in option_list:
            sql_options = sql_options + ' ' + str(i)

        response = subprocess.run(sql_login + '@' + sql_file + sql_options, 
                                  stderr=subprocess.PIPE, stdout=subprocess.PIPE, shell=True)
        # assert response.returncode == 0, 'Assert: error in SQL script'

        # response.stdout value is a byte code (respresented by b' ')
        # to get a regular string, use decode('UTF-8')
        stdout_str = response.stdout.decode('UTF-8') 
        stderr_str = response.stderr.decode('UTF-8') 
        print(stdout_str)
        print(stderr_str)
        logging.debug('returncode = ' + str(response.returncode))
        logging.debug('find = ' + str(stdout_str.find('SQL*Plus')))

        # sqlplus() does not always return a number > 0 when errors occur,
        # such as when you have an invalid option.
        # In these cases the script will have 'SQL*Plus' in the stdout.
        # However, some errors might cause the script to hang with no messages;
        # in those cases you need to stop it by typing ctrl-c. 
        if response.returncode != 0 or stdout_str.find('SQL*Plus') > -1:
            raise Exception
    except Exception as ex:
        logging.info("\n")
        logging.exception('Exception of type {0} raised with arguments {1!r}'.format(type(ex).__name__, ex.args))
        #logger.error('Exception of type {0} raised with arguments {1!r}'.format(type(ex).__name__, ex.args))
#       print("Exception raised in procedure call_sql()")
#       template = "An exception of type {0} occurred. Arguments:\n{1!r}"
#       message = template.format(type(ex).__name__, ex.args)
#       print(message)
#       print(traceback.format_exc())
        sys.exit()

def call_ctl(loader_login, load_table):
    print("\n" + "*"*80)
    logging.info('Start of call_ctl() using table %s', load_table)
    try:
        logging.debug("Load data into table " + load_table.upper())

        ctl_file = ctl_directory + load_table + '.ctl'
        log_file = ctl_directory + load_table + '.log'

        loader_string = loader_login + ctl_file + ctl_options + log_file

        response = subprocess.run(loader_string, stderr=subprocess.PIPE, stdout=subprocess.PIPE, shell=True)        

        stdout_str = response.stdout.decode('UTF-8') 
        stderr_str = response.stderr.decode('UTF-8') 
        print(stdout_str)
        print(stderr_str)
        logging.debug('returncode = ' + str(response.returncode))
        logging.debug('find = ' + str(stdout_str.find('SQL*Plus')))

        if response.returncode != 0 or stdout_str.find('SQL*Plus') > -1:
            raise Exception
    except Exception as ex:
        logging.info("\n")
        logging.exception('Exception of type {0} raised with arguments {1!r}'.format(type(ex).__name__, ex.args))
#       print( "Python script raised an exception running " + ctl_file)
#       template = "An exception of type {0} occurred. Arguments:\n{1!r}"
#       message = template.format(type(ex).__name__, ex.args)
#       print(message)
        sys.exit()

def start_procedures():
    logging.info("\n"+"*"*80)
    logging.info('Start of start_procedures()')
    try:
        # Test to see if these files can be found. If not, the fopen() function
        # will raise a FileNotFoundError exception.
        file_list = []
        file_list.append(sql_directory + 'create_adjuvants.sql')
        file_list.append(sql_directory + 'create_ai_groups_ai_outlier_stats.sql')
        file_list.append(sql_directory + 'create_ai_groups_ai_outlier_stats_nonag.sql')
        file_list.append(sql_directory + 'create_ai_names.sql')
        file_list.append(sql_directory + 'create_ai_num_recs.sql')
        file_list.append(sql_directory + 'create_ai_num_recs_nonag.sql')
        file_list.append(sql_directory + 'create_fixed_outlier_lbs_app.sql')
        file_list.append(sql_directory + 'create_fixed_outlier_lbs_app_ais.sql')
        file_list.append(sql_directory + 'create_fixed_outlier_rates.sql')
        file_list.append(sql_directory + 'create_fixed_outlier_rates_ais.sql')
        file_list.append(sql_directory + 'create_prod_chem_major_ai.sql')
        file_list.append(sql_directory + 'create_pur_outlier.sql')
        file_list.append(sql_directory + 'create_pur_rates_nonag.sql')
        file_list.append(sql_directory + 'create_pur_site_groups.sql')
        file_list.append(sql_directory + 'outlier_stats.py')
        file_list.append(sql_directory + 'outlier_stats_nonag.py')

        file_list.append(ctl_directory + 'ai_group_nonag_stats_append.ctl')
        file_list.append(ctl_directory + 'ai_group_nonag_stats_replace.ctl')
        file_list.append(ctl_directory + 'ai_group_stats_append.ctl')
        file_list.append(ctl_directory + 'ai_group_stats_replace.ctl')
        file_list.append(ctl_directory + 'ai_outlier_nonag_stats_append.ctl')
        file_list.append(ctl_directory + 'ai_outlier_nonag_stats_replace.ctl')
        file_list.append(ctl_directory + 'ai_outlier_stats_append.ctl')
        file_list.append(ctl_directory + 'ai_outlier_stats_replace.ctl')
        file_list.append(ctl_directory + 'fixed_outlier_lbs_app.ctl')
        file_list.append(ctl_directory + 'fixed_outlier_rates.ctl')
        file_list.append(ctl_directory + 'pur_site_groups.ctl')

        file_list.append(table_directory + 'fixed_outlier_rates.txt')
        file_list.append(table_directory + 'fixed_outlier_lbs_app.txt')

        for file in file_list:
            f = open(file)
            f.close

        logging.debug('All files exist.')
        print("\n")
                
        userid = userid_tk.get()
        password = password_tk.get()

        # sqlplus option -S suppresses of sqlplus banner; -L attempts to log on only once, which is needed to catch errors in this python script.
        sql_login = 'sqlplus -S -L ' + userid + tns_service + '/' + password + ' '
        loader_login = 'cd ' + ctl_directory + ' & sqlldr USERID = ' + userid + tns_service + '/' + password + ' CONTROL='

        run_outliers = run_outliers_tk.get()
        run_outlier_setup = run_outlier_setup_tk.get()
        run_fixed_tables = run_fixed_tables_tk.get()
        run_ai_num_recs = run_ai_num_recs_tk.get()
        run_pur_rates = run_pur_rates_tk.get()

        stat_year = stat_year_tk.get()
        num_stat_years = num_stat_years_tk.get()
        num_days_old = num_days_old_tk.get()
        load_from_oracle = load_from_oracle_tk.get()

        logging.debug("You entered:")
        logging.debug("User Id: " + userid)
        logging.debug("Login Password: " + password)
        logging.debug("run_outliers: " + str(run_outliers))
        logging.debug("run_outlier_setup: " + str(run_outlier_setup))
        logging.debug("run_fixed_tables: " + str(run_fixed_tables))
        logging.debug("run_ai_num_recs: " + str(run_ai_num_recs))
        logging.debug("run_pur_rates: " + str(run_pur_rates))
        logging.debug("Year: " + str(stat_year))
        logging.debug("Num of years: " + str(num_stat_years))
        logging.debug("Num of days old: " + str(num_days_old))
        logging.debug("load_from_oracle: " + str(load_from_oracle))

        if run_outliers:
            if run_outlier_setup:
                #################################################################################
                # Create empty table PUR_SITE_GROUPS
                sql_file = 'create_pur_site_groups.sql'
                call_sql(sql_login, sql_file)


            if run_fixed_tables:
                #################################################################################
                # Create empty table FIXED_OUTLIER_RATES
                sql_file = 'create_fixed_outlier_rates.sql'
                call_sql(sql_login, sql_file)

                # Load data into table FIXED_OUTLIER_RATES
                load_table = 'fixed_outlier_rates'
                call_ctl(loader_login, load_table)


            if run_ai_num_recs:
                #################################################################################
                # Create tables AI_NUM_RECS_YYYY and AI_NUM_RECS_SUM_YYYY. AI_NUM_RECS_YYYY is an intermediate
                # table used to create another intermediate table, AI_NUM_RECS_SUM_YYYY, which is used to
                # create table PUR_RATES_YYYY.
                sql_file = 'create_ai_num_recs.sql'
                call_sql(sql_login, sql_file, stat_year, num_stat_years, num_days_old)

            if run_pur_rates:
                #################################################################################
                # Create table PUR_RATES_YYYY.
                sql_file = 'create_pur_rates.sql'
                call_sql(sql_login, sql_file, stat_year, num_stat_years, num_days_old)
        else:
            logging.debug("Outliers not run")

        logging.info("*"*80)
        logging.info("Procedures have finished.")
    except FileNotFoundError as fnf:
        logging.debug('In start_procedures() this file not found: {}'.format(fnf.filename))
        sys.exit()
    except Exception as ex:
        logging.info("\n")
        logging.exception('Exception of type {0} raised with arguments {1!r}'.format(type(ex).__name__, ex.args))
#       print( "Python script threw an exception running start_procedures().")
#       # root.destroy()
#       template = "An exception of type {0} occurred. Arguments:\n{1!r}"
#       message = template.format(type(ex).__name__, ex.args)
#       print(message)
#       print(traceback.format_exc())
        sys.exit()

def quit_program():
     sys.exit()


###########################################################
# Login frame
login_frame = Frame(root, bd=3, relief=SUNKEN)
login_frame.grid(row=1, column=1, padx=2, pady=2, sticky='w')
#login_frame.pack()

Label(login_frame, text="Log onto Oracle", font="TkHeadingFont 12"). \
      grid(row=1, column=1, columnspan=2, padx=2, pady=2)

# Oracle user ID
Label(login_frame, text="User Id: ").grid(row=2, column=1, sticky='w', padx=2, pady=2)
Entry(login_frame, width=40, textvariable=userid_tk).grid(row=2, column=2, columnspan=2, padx=2, pady=2)
userid_tk.set("lwilhoit")

# password
Label(login_frame, text="Password: ").grid(row=3, column=1, sticky='w', padx=2, pady=2)
Entry(login_frame,width=40, show="*",  textvariable=password_tk). \
      grid(row=3, column=2, columnspan=2, padx=2, pady=2) 
password_tk.set("nashira8")


############################################################
# Procedure frame
proc_frame = Frame(root, bd=3, relief=SUNKEN)
proc_frame.grid(row=2, column=1, padx=2, pady=2, sticky='w')

Label(proc_frame, text="Choose which procedures to run", font="TkHeadingFont 12"). \
      grid(row=1, column=1, columnspan=2, padx=2, pady=2)

# Which procedures to run
Checkbutton(proc_frame, text="Run Outliers", variable=run_outliers_tk).grid(row=2, column=1, sticky='w')
run_outliers_tk.set(True)

Checkbutton(proc_frame, text="Outlier Setup", variable=run_outlier_setup_tk).grid(row=3, column=1, sticky='w')
run_outlier_setup_tk.set(False)
#if run_outliers_tk.get():
#    run_outlier_setup_tk.set(True)
#else:
#    run_outlier_setup_tk.set(False)

Checkbutton(proc_frame, text="Run fixed tables", variable=run_fixed_tables_tk).grid(row=4, column=1, sticky='w')
run_fixed_tables_tk.set(False)

Checkbutton(proc_frame, text="Run AI num recs", variable=run_ai_num_recs_tk).grid(row=5, column=1, sticky='w')
run_ai_num_recs_tk.set(True)

Checkbutton(proc_frame, text="Run PUR Rates (need table ai_num_recs for this)", variable=run_pur_rates_tk).grid(row=6, column=1, sticky='w')
run_pur_rates_tk.set(True)


############################################################
# Parameter frame
param_frame = Frame(root, bd=3, relief=SUNKEN)
param_frame.grid(row=3, column=1, padx=2, pady=2, sticky='w')

Label(param_frame, text="Set parameters", font="TkHeadingFont 12"). \
      grid(row=1, column=1, columnspan=2, padx=2, pady=2)

# What year?
Label(param_frame, text="Year: ").grid(row=2, column=1, sticky='w')
Entry(param_frame, width=40, textvariable=stat_year_tk).grid(row=2, column=2)
stat_year_tk.set("2018")

# Number of years?
Label(param_frame, text="Number of years: ").grid(row=3, column=1, sticky='w')
Entry(param_frame, width=40, textvariable=num_stat_years_tk).grid(row=3, column=2)
num_stat_years_tk.set("1")

# Number of years?
Label(param_frame, text="Number of days table is considered too old: ").grid(row=4, column=1, sticky='w')
Entry(param_frame, width=40, textvariable=num_days_old_tk).grid(row=4, column=2)
num_days_old_tk.set("100")


# Load data from the Oracle database?
Checkbutton(param_frame, text="Load from Oracle", variable=load_from_oracle_tk).grid(row=5, column=1, columnspan=2, sticky='w')
load_from_oracle_tk.set(True)



############################################################
# Start frame
start_frame = Frame(root, bd=3, relief=SUNKEN)
start_frame.grid(row=4, column=1, padx=4, pady=10)

# Start the procedrues
Button(start_frame, text="Start Procedures", 
       command=start_procedures).grid(row=1, column=3)
      #command=start.start_procedures(userid_tk, password_tk, stat_year_tk, run_outliers_tk)).grid(row=6, column=3)

############################################################
# End frame
end_frame = Frame(root, bd=3, relief=SUNKEN)
end_frame.grid(row=5, column=1, padx=4, pady=10)

# Quit the program
Button(end_frame, text="Quit", command=quit_program).grid(row=1, column=3)

root.mainloop()
