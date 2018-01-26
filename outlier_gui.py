
"""
Create tables to find high or outlier values in the PUR.
""" 

import os
import sys
import subprocess

from sys import version_info
if version_info.major == 2:
    # We are using Python 2.x
    print("We are using Python 2.x")
    from Tkinter import *
    # Or: import Tkinter as tk
elif version_info.major == 3:
    # We are using Python 3.x
    print("We are using Python 3.x")
    from tkinter import *
    # import tkinter as tk


tns_service = '@dprprod2'
sql_directory = 'sql_py/'
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
run_pur_rates_tk = BooleanVar()

stat_year_tk = IntVar()
num_stat_years_tk = IntVar()
load_from_oracle_tk = BooleanVar()

# Importing function start_procedures does not work
#import start

def call_sql(sql_login, sql_file, *option_list):
    try:
        print("\n", "*"*80)
        print("Running Oracle script", sql_file)

        # Test to see if sql_file can be found. If not, this statement
        # will raise a FileNotFoundError exception.
        sql_file = sql_directory + sql_file
        f = open(sql_file)
        f.close

        sql_options = ''
        for i in option_list:
            sql_options = sql_options + ' ' + str(i)

        response = subprocess.run(sql_login + '@' + sql_file + sql_options, 
                                  stderr=subprocess.PIPE, stdout=subprocess.PIPE, shell=True)

        # response.stdout value is a byte code (respresented by b' ')
        # to get a regular string, use decode('UTF-8')
        stdout_str = response.stdout.decode('UTF-8') 
        stderr_str = response.stderr.decode('UTF-8') 
        print(stdout_str)
        print(stderr_str)
        print('returncode = ' + str(response.returncode))
        print('find = ' + str(stdout_str.find('SQL*Plus')))

        # sqlplus() does not always return a number > 0 when errors occur;
        # some of the additional errors will have 'SQL*Plus' in the stdout.
        # However, some errors will just cause the script to stop with no messages.
        if response.returncode != 0 or stdout_str.find('SQL*Plus') > -1:
            raise Exception
    except FileNotFoundError as fnf:
        print('In call_sql() this file not found: {}'.format(fnf.filename))
        sys.exit()
    except Exception as ex:
        print("Exception raised in procedure call_sql()")
        template = "An exception of type {0} occurred. Arguments:\n{1!r}"
        message = template.format(type(ex).__name__, ex.args)
        print(message)
        sys.exit()

def call_ctl(loader_login, load_table):
    try:
        print("\n", "*"*80)
        print("Load data into table", load_table.upper())

        ctl_file = load_table + '.ctl'
        log_file = load_table + '.log'

        f = open(ctl_directory + ctl_file)
        f.close

        loader_string = loader_login + ctl_file + ctl_options + log_file

        response = subprocess.run(loader_string, stderr=subprocess.PIPE, stdout=subprocess.PIPE, shell=True)

        stdout_str = response.stdout.decode('UTF-8') 
        stderr_str = response.stderr.decode('UTF-8') 
        print(stdout_str)
        print(stderr_str)
        print('returncode = ' + str(response.returncode))
        print('find = ' + str(stdout_str.find('SQL*Plus')))

        if response.returncode != 0 or stdout_str.find('SQL*Plus') > -1:
            raise Exception
    except FileNotFoundError as fnf:
        print('In call_ctl() this file not found: {}'.format(fnf.filename))
        sys.exit()
    except Exception as ex:
        print( "Python script raised an exception running " + ctl_file)
        template = "An exception of type {0} occurred. Arguments:\n{1!r}"
        message = template.format(type(ex).__name__, ex.args)
        print(message)
        sys.exit()

def start_procedures():
    try:
        userid = userid_tk.get()
        password = password_tk.get()

        # sqlplus option -S suppresses of sqlplus banner; -L attempts to log on only once, which is needed to catch errors in this python script.
        sql_login = 'sqlplus -S -L ' + userid + tns_service + '/' + password + ' '
        loader_login = 'cd ' + ctl_directory + ' & sqlldr USERID = ' + userid + tns_service + '/' + password + ' CONTROL='

        run_outliers = run_outliers_tk.get()
        run_outlier_setup = run_outlier_setup_tk.get()
        run_pur_rates = run_pur_rates_tk.get()

        stat_year = stat_year_tk.get()
        num_stat_years = num_stat_years_tk.get()
        load_from_oracle = load_from_oracle_tk.get()

        print("You entered:")
        print("User Id: " + userid)
        print("Login Password: " + password)
        print("run_outliers: " + str(run_outliers))
        print("run_outlier_setup: " + str(run_outlier_setup))
        print("Year: " + str(stat_year))
        print("Num of years: " + str(num_stat_years))
        print("load_from_oracle: " + str(load_from_oracle))


        if run_outliers:
            if run_outlier_setup:
                #################################################################################
                # Create empty table FIXED_OUTLIER_RATES
                sql_file = 'create_fixed_outlier_rates.sql'
                call_sql(sql_login, sql_file)

                # Load data into table FIXED_OUTLIER_RATES
                load_table = 'fixed_outlier_rates'
                call_ctl(loader_login, load_table)

            if run_pur_rates:
                #################################################################################
                # Create tables AI_NUM_RECS_YYYY and AI_NUM_RECS_SUM_YYYY. AI_NUM_RECS_YYYY is an intermediate
                # table used to create another intermediate table, AI_NUM_RECS_SUM_YYYY, which is used to
                # create table PUR_RATES_YYYY.
                sql_file = 'create_ai_num_recs.sql'
                call_sql(sql_login, sql_file, stat_year, num_stat_years)

        else:
            print("Outliers not run")

        print("*"*80)
        print("Procedures have finished.")
    except FileNotFoundError as fnf:
        print('In start_procedures() this file not found: {}'.format(fnf.filename))
        sys.exit()
    except Exception as ex:
        print( "Python script threw an exception running start_procedures().")
        # root.destroy()
        template = "An exception of type {0} occurred. Arguments:\n{1!r}"
        message = template.format(type(ex).__name__, ex.args)
        print(message)
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
if run_outliers_tk.get():
    run_outlier_setup_tk.set(True)
else:
    run_outlier_setup_tk.set(False)

Checkbutton(proc_frame, text="Run PUR Rates", variable=run_pur_rates_tk).grid(row=4, column=1, sticky='w')
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
num_stat_years_tk.set("10")

# Load data from the Oracle database?
Checkbutton(param_frame, text="Load from Oracle", variable=load_from_oracle_tk).grid(row=4, column=1, columnspan=2, sticky='w')
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
