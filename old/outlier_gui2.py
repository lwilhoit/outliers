
"""
Code illustration: 1.12
A demonstration of tkinter Variable Class
IntVar, StringVar & BooleanVar

@Tkinter GUI Application Development Hotshot
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

# Define tkinter variables;
# Note that you first need to define a variable for Tk().
root = Tk()
root.title("Run outlier procedures")
userid_tk = StringVar()
password_tk = StringVar() # defines the widget state as string
stat_year_tk = IntVar()
run_outliers_tk = BooleanVar()

# Importing function start_procedures does not work
#import start

class OracleException(Exception): pass

#def start_procedures(userid_tk, password_tk, stat_year_tk, run_outliers_tk):
def start_procedures():
    userid = userid_tk.get()
    password = password_tk.get()
    stat_year = stat_year_tk.get()
    run_outliers = run_outliers_tk.get()

    print( "You entered:")
    print( "User Id: " + userid)
    print( "Login Password: " + password)
    print( "Year: " + str(stat_year))

    print( "Run outlier: " + str(run_outliers))
    print( '*'*60)

    if run_outliers:
        print( "_"*60)
        print( "Running outlier procedure")

        print( "Running Oracle script temp.sql")
#       return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
#                                ' @temp1 ')
#       if return_status != 0:
#           print( "Python script ended because of an error in temp.sql.")
#           root.destroy()
#            sys.exit()
#
        try:
            #return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password + ' @temp2 ')
            #if return_status != 0:
            #    raise Exception("index error argument")

            f = open('temp.sql')
            f.close

            response = subprocess.run('sqlplus -S -L ' + userid + tns_service + '/' + password + ' @temp ', 
                                      stderr=subprocess.PIPE, stdout=subprocess.PIPE, shell=True)

            stdout_str = response.stdout.decode('UTF-8') 
            stderr_str = response.stderr.decode('UTF-8') 
            print('stdout = ', stdout_str)
            print('stderr = ', stderr_str)
            print('returncode = ' + str(response.returncode))
            print('find = ' + str(stdout_str.find('SQL*Plus')))

            if response.returncode != 0 or stdout_str.find('SQL*Plus') > -1:
                raise OracleException("Oracle exception")

        except Exception as ex:
            print( "Python script threw an exception running temp.sql: ")
            # print(ex)
            template = "An exception of type {0} occurred. Arguments:\n{1!r}"
            message = template.format(type(ex).__name__, ex.args)
            print(message)
            sys.exit()

    else:
        print( "Outliers not run")

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
# Parameter frame
param_frame = Frame(root, bd=3, relief=SUNKEN)
param_frame.grid(row=2, column=1, padx=2, pady=2, sticky='w')
#param_frame.pack(side=LEFT, fill=X)

Label(param_frame, text="Set parameters", font="TkHeadingFont 12"). \
      grid(row=1, column=1, columnspan=2, padx=2, pady=2)

# What year?
Label(param_frame, text="Year: ").grid(row=2, column=1, sticky='w')
Entry(param_frame, width=40, textvariable=stat_year_tk).grid(row=2, column=2, columnspan=2)
stat_year_tk.set("2017")

# Which procedures to run
Checkbutton(param_frame, text="Run Outliers", variable=run_outliers_tk).grid(row=3, column=2)
run_outliers_tk.set(True)


############################################################
# Start frame
start_frame = Frame(root, bd=3, relief=SUNKEN)
start_frame.grid(row=3, column=1, padx=4, pady=10)
#start_frame.pack()

# Start the procedrues
Button(start_frame, text="Start Procedures", 
       command=start_procedures).grid(row=1, column=3)
      #command=start.start_procedures(userid_tk, password_tk, stat_year_tk, run_outliers_tk)).grid(row=6, column=3)


root.mainloop()
