
import os
import sys
from Tkinter import *

def start_procedures():
    userid = userid_tk.get()
    password = password_tk.get()
    stat_year = stat_year_tk.get()
    run_outliers = run_outliers_tk.get()

    print "You entered:"
    print "User Id: " + userid
    print "Login Password: " + password
    print "Year: " + str(stat_year)

    print "Run outlier: " + str(run_outliers)
    print '*'*60

    if run_outliers:
        print "_"*60
        print "Running outlier procedure"

        print "Running Oracle script temp.sql"
        return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
                                 ' @temp ')
        if return_status != 0:
            print "Python script ended because of an error in temp.sql."
            sys.exit()

    else:
        print "Outliers not run"


from outlier_gui import *

