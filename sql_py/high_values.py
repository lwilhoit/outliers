# To run this, start an Anaconda prompt, cd to this directory (use ar17 command),
# and type "activate pur" to start the pur anaconda environment.
# When you close this file, make a copy of the file in the sql_py dir
# so that it will be tracked in the git repository.
# The easiest way to do this is type "cpy" with is a Windows
# cmd file.

# install cx_oracle, ipython, numpy, pandas

# This script is used to look for values in the PUR which are
# unusually high for pounds of AI, amount treated, rate of use, or
# which have a large increase in lbs of AI or acres treated for particular
# counties, PUR record type (ag or nonag), and AIs.
#
# This file is normally in directory pur/annual_report/purYYYY/
# and the other scripts for outliers are in pur/annual_report/purYYYY/high_values/sql_py/

# This is run at two different times:
# First, it is run sometime in July to find records that may contain errors
# which can be sent back to the counties to have corrected or verified.
# These records will selected from the final outcome of this script,
# the table HIGH_VALUES_YYYY.
# For this run all Python variables below (variables that start with "run_")
# should be set = True.
#
# Second, in September or October after all data for the previous year
# have been received and corrected. The reason for this run is to
# create the Oracle tables AI_GROUPS, AI_OUTLIER_STATS,
# AI_GROUP_NONAG_STATS, and AI_OUTLIER_NONAG_STATS.  These
# tables are used by the loader program to flag records with high
# rates of use as they come to DPR from the counties.
# For this run only the outlier Python variables (variables that start with "run_outlier")
# should be set = True.
#
# The script run_pur_outlier creates a table of PUR records which
# were found to have some high rates or pounds per application.  This script is
# similar to that used in the loader program to flag outliers.
#
# In the early run of this script's ultimate goal is to create the Oracle table
# HIGH_VALUES_YYYY.  This flags each ag record with unusually large rate of use
# (pounds of AI per acre treated) and non-ag PUR record with unusually high
# pounds of AI per application (which is often called a rate, though you must
# note that the rate used for ag applications means pounds per area treated).
# This should be examined and all records that appear to be errors
# should be sent back to the counties for correction.
#
# High pounds are determined by two basic procedures:
# One procedure looks at the total pounds and acres or other unit treated
# of each AI by county, year, and month and flags all records for that county,
# year, and mmonth with unusually large pounds relative other pounds;
# the results of this procedure are in Oracle table CO_AI_HIGH_LIST.
# Another procedure looks at the frequency distributions of rates and flags any
# value which is high relative to other similar uses; the results of this
# procedure are in Oracle table PUR_OUTLIER.

# Create two Tableau files to determine if values in records marked in HIGH_VALUES_YYYY
# really do appear to be too high:
# 1. PUR_SUM, to show use by month and county for the past several years
# 2. PUR_RATES_YYYY, to show frequency distributions of rates by AI for most current year (or years)

# You might also want to create frequency distributions with outlier limits marked, using
# script make_freq_plots.R and freq.R

import os
import sys
import getpass
# userid= 'ksteinmann[pur_report]'
#userid= 'edenemark[pur_report]'
#userid = 'lwilhoit[pur_report]'
userid = 'lwilhoit'
print 'Type your Oracle password (password is hidden as you type)'
password= getpass.getpass()
tns_service = '@dprprod2'

stat_year = 2017

run_high_changes =  False

# The 7 variables following run_outliers are nested within the run_outliers block,
# so are called only if run_outlier = True.
run_outliers =                  True
run_outlier_setup =             False
run_outlier_major_ai =          False
run_outlier_pur_rates =         False
run_outlier_pur_rates_nonag =   False
run_outlier_stats =             True
run_outlier_stats_nonag =       False
run_pur_outlier =               False

run_high_values =               False

run_pur_sum =                   False

#____________________________________________________________________________________
# General parameters:
# If you want to reload data from Oracle tables in outlier_stats.py and outlier_stats_nonag.py
# set load_from_oracle = True.
load_from_oracle = True

# When loading data into the Oracle tables AI_GROUP_STATS and AI_OUTLIER_STATS
# During normal, yearly process set
# replace_oracle_tables = False and
# append_oracle_tables = True.
# These settings will cause the code to add data to AI_GROUP_STATS and AI_OUTLIER_STATS
# rather than replace the current tables.
replace_oracle_tables = True #Note from Kim: these two variables do not seem to be used anywhere else in this code?
append_oracle_tables = False

# If you want to update Oracle table PUR_RATE_YYYY with new values for ai_groups, set
# update_pur_rates = True
update_pur_rates = False

# One of the scripts for checking high values, create_pur_sum.sql, creates the table PUR_SUM.
# This table can be used for error checking or later for looking at trends in use.
# For error checking purposes, set parameter "which_pur" = "USE_PUR".
# For looking at trends later, after table PUR&&1 has been created, set which_pur = "USE_PUR_YYYY"
# and set cutoff_date = to label database cutoff date.
which_pur = 'USE_PUR'
# which_pur = 'USE_PUR_YYYY'
cutoff_date = '7_17_2017'

# Set rerun = False the first time you run script create_pur_sum.sql.  If this needs to
# rerun later, set rerun = True.  All this does is prevent recreation of the "old" tables
# in several of the scripts.
rerun = 'True'

# Number of years to use to determine if value in current year is high
# relative to previous years.  It is used to create table CO_AI_STATS.
num_years_high_changes = 5

# Number of years used for table CO_AI_MONTH.
num_years_all = 15

# Number of years used for table PUR_RATES.
num_stat_years = 10

# Number of years used for table FIXED_OUTLIER_RATES_AIS and FIXED_OUTLIER_LBS_APP_AIS.
num_fixed_years = 16


#################################################################################################
if run_high_changes:
    # Create tables and graphs for checking large increases in pounds of AI and acres treated.
    # The final table in this section, CO_AI_HIGH_LIST, contains use by AI, county, and record type with
    # a large increase in use in the current year compared to previous 4 years.

    # Create table CO_AI_MONTH, which has summary PUR data for the last 15 years (or num_years_all).
    # This table includes use by county, record type (ag_ind), AI, and month
    # It is used later in this script to look for unusually high
    # uses during the last year.
    print "___________________________________________________________________________________________"
    print "Running Oracle script create_co_ai_month.sql"
    return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
                             ' @high_values/high_changes/sql_py/create_co_ai_month ' + str(stat_year) + ' ' + 
                             str(stat_year-num_years_all+1))
    if return_status != 0:
        print "Python script ended because of an error in create_co_ai_month.sql."
        sys.exit()

    # Create table CO_AI_STATS, which includes various statistics
    # of use for each AI, county, and record type. It is used to determine
    # if there are any unusually large changes in pounds of AI	in the current
    # year compared to previous 4 years (or num_years_high_changes-1) for
    # each county and record type.
    print "___________________________________________________________________________________________"
    print "Running Oracle script create_co_ai_stats.sql"
    return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
                             ' @high_values/high_changes/sql_py/create_co_ai_stats ' + str(stat_year) + ' ' + 
                             str(stat_year-num_years_high_changes+1))
    if return_status != 0:
        print "Python script ended because of an error in create_co_ai_stats.sql."
        sys.exit()

    # Creates table CO_AI_HIGH_LIST, which contains those records
    # from CO_AI_STATS that have an unusually large increase in pounds of AI
    # or acres treated in the current year compared to previous 4 years for
    # each AI, county, and record type.
    print "___________________________________________________________________________________________"
    print "Running Oracle script create_co_ai_high_list.sql"
    return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
                             ' @high_values/high_changes/sql_py/create_co_ai_high_list ' + str(stat_year) + ' ' + 
                             str(stat_year-num_years_high_changes+1))
    if return_status != 0:
        print "Python script ended because of an error in create_co_ai_high_list.sql."
        sys.exit()


#################################################################################################
if run_outliers:
    print "___________________________________________________________________________________________"
    print "Running outlier procedure"
    # These scripts create tables needed by the outlier program.  However, they should already
    # exist, so normally there is no need to run these.
    if run_outlier_setup:
        # Create empty tables: FIXED_OUTLIER_RATES and FIXED_OUTLIER_LBS_APP 
        # The following scripts use the Oracle loader program to load data from text files
        # into these tables.
        # Other scripts create tables: FIXED_OUTLIER_RATES_AIS and FIXED_OUTLIER_LBS_APP_AIS
        # these queries also populates the table, so data do not need to be
        # loaded from text files.
        print "___________________________________________________________________________________________"
        print "Running Oracle script create_fixed_outlier_rates.sql"
        return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
                                 ' @high_values/outliers/sql_py/create_fixed_outlier_rates ')
        if return_status != 0:
            print "Python script ended because of an error in create_fixed_outlier_rates.sql."
            sys.exit()

        print "___________________________________________________________________________________________"
        print "Load data into table FIXED_OUTLIER_RATES."
        return_status = os.system('cd high_values/outliers/sql_py/ctl_files & sqlldr USERID=' + userid + tns_service + '/' + password +
                 ' CONTROL=fixed_outlier_rates.ctl SKIP=1 LOG=fixed_outlier_rates.log errors=999999')
        if return_status != 0:
            print 'Python script ended because of an error in sqlldr fixed_outlier_rates.ctl'
            sys.exit()

        print "___________________________________________________________________________________________"
        print "Create and populate table FIXED_OUTLIER_RATES_AIS."
        return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
                                  ' @high_values/outliers/sql_py/create_fixed_outlier_rates_ais ' +
                                  str(stat_year) + ' ' + str(num_fixed_years))
        if return_status != 0:
            print 'Python script ended because of an error in create_fixed_outlier_rates_ais.sql'
            sys.exit()

        print "___________________________________________________________________________________________"
        print "Running Oracle script create_fixed_outlier_lbs_app.sql"
        return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
                                 ' @high_values/outliers/sql_py/create_fixed_outlier_lbs_app ')
        if return_status != 0:
            print "Python script ended because of an error in create_fixed_outlier_lbs_app.sql."
            sys.exit()

        print "___________________________________________________________________________________________"
        print "Load data into table FIXED_OUTLIER_LBS_APP."
        return_status = os.system('cd high_values/outliers/sql_py/ctl_files & sqlldr USERID=' + userid + tns_service + '/' + password +
                 ' CONTROL=fixed_outlier_lbs_app.ctl SKIP=1 LOG=fixed_outlier_lbs_app.log errors=999999')
        if return_status != 0:
            print 'Python script ended because of an error in sqlldr fixed_outlier_lbs_app.ctl'
            sys.exit()

        print "___________________________________________________________________________________________"
        print "Create and populate table FIXED_OUTLIER_LBS_APP_AIS."
        return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
                                  ' @high_values/outliers/sql_py/create_fixed_outlier_lbs_app_ais ' +
                                  str(stat_year) + ' ' + str(num_fixed_years))
        if return_status != 0:
            print 'Python script ended because of an error in create_fixed_outlier_lbs_app_ais.sql'
            sys.exit()


        # Create empty table PUR_SITE_GROUPS.
#       print "___________________________________________________________________________________________"
#       print "Running Oracle script create_pur_site_groups.sql"
#       return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
#                                 ' @high_values/outliers/sql_py/create_pur_site_groups ')
#       if return_status != 0:
#          print "Python script ended because of an error in create_pur_site_groups.sql."
#          sys.exit()
#
#       # Load PUR_SITE_GROUPS with data from pur_site_groups.txt
#       print "___________________________________________________________________________________________"
#       print "Load data into table PUR_SITE_GROUPS."
#       return_status = os.system('cd high_values/outliers/sql_py/ctl_files & sqlldr USERID=' + userid + tns_service + '/' + password +
#                ' CONTROL=pur_site_groups.ctl SKIP=1 LOG=pur_site_groups.log errors=999999')
#
#       if return_status != 0:
#           print 'Python script ended because of an error in sqlldr pur_site_groups.ctl'
#           sys.exit()
#
#       # Create tables PROD_ADJUVANT and CHEM_ADJUVANT.
#       print "___________________________________________________________________________________________"
#       print "Running Oracle script create_adjuvants.sql"
#       return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
#                                 ' @high_values/outliers/sql_py/create_adjuvants ')
#       if return_status != 0:
#           print "Python script ended because of an error in create_adjuvants.sql."
#           sys.exit()
#
#       # Create table AI_NAMES,
#       print "___________________________________________________________________________________________"
#       print "Running Oracle script create_ai_names.sql"
#       return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
#                                 ' @high_values/outliers/sql_py/create_ai_names ')
#       if return_status != 0:
#           print "Python script ended because of an error in create_ai_names.sql."
#           sys.exit()

        #################################################################################################
        # Create table PROD_CHEM_MAJOR_AI, which is only used for the outlier scripts and may need to be recreated
        # occasionally to udpate it for new products.
        if run_outlier_major_ai:
            print "___________________________________________________________________________________________"
            print "Running Oracle script create_prod_chem_major_ai.sql"
            return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
                                      ' @high_values/outliers/sql_py/create_prod_chem_major_ai ')
            if return_status != 0:
                print "Python script ended because of an error in create_prod_chem_major_ai.sql."
                sys.exit()


    #################################################################################################
    if run_outlier_pur_rates:
        # Create tables AI_NUM_RECS_YYYY and AI_NUM_RECS_SUM_YYYY. AI_NUM_RECS_YYYY is an intermediate
        # table used to create another intermediate table, AI_NUM_RECS_SUM_YYYY, which is used to
        # create table PUR_RATES_YYYY.
        # print "_____________________________________________________________________________________________________________________"
        print "Running Oracle script create_ai_num_recs.sql"
        return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
                                  ' @high_values/outliers/sql_py/create_ai_num_recs ' + str(stat_year) + ' ' + str(num_stat_years))
        if return_status != 0:
            print "Python script ended because of an error in create_ai_num_recs.sql."
            sys.exit()

        # Create table PUR_RATES_YYYY. This table is used in calculating various statistics
        # (done in the Python script outlier_stats.py) which are used to determine likely outliers
        # in rates of use.
        print "_____________________________________________________________________________________________________________________"
        print "Running Oracle script create_pur_rates.sql"
        return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
                                  ' @high_values/outliers/sql_py/create_pur_rates ' + str(stat_year) + ' ' + str(num_stat_years))
        if return_status != 0:
            print "Python script ended because of an error in create_pur_rates.sql."
            sys.exit()

    #################################################################################################
    if run_outlier_pur_rates_nonag:
        # Create intermediate tables AI_NUM_RECS_NONAG_YYYY and AI_NUM_RECS_NONAG_SUM_YYYY.
        print "_____________________________________________________________________________________________________________________"
        print "Running Oracle script create_ai_num_recs_nonag.sql"
        return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
                                  ' @high_values/outliers/sql_py/create_ai_num_recs_nonag ' + str(stat_year) + ' ' + str(num_stat_years))
        if return_status != 0:
            print "Python script ended because of an error in create_ai_num_recs_nonag.sql."
            sys.exit()

        # Create table PUR_RATES_NONAG_YYYY.
        print "_____________________________________________________________________________________________________________________"
        print "Running Oracle script create_pur_rates_nonag.sql"
        return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
                                  ' @high_values/outliers/sql_py/create_pur_rates_nonag ' + str(stat_year) + ' ' + str(num_stat_years))
        if return_status != 0:
            print "Python script ended because of an error in create_pur_rates_nonag.sql."
            sys.exit()

    #################################################################################################
    if run_outlier_stats:
        # The SQL script creates two empty Oracle tables AI_GROUP_STATS and AI_OUTLIER_STATS
        # and the Python script creates 2 files ai_group_stats.txt and ai_outlier_stats.txt,
        # imports these data into the Oracle tables, and updates Oracle table
        # PUR_RATES_YYYY with values for field ai_group.
        # Table AI_GROUP_STATS gives the ai_group number for each AI, site, product,
        # record type, and unit treated using data from PUR_RATES_YYYY. It also contains various
        # statistics for rates of use.
        # Table AI_OUTLIER_STATS gives all the different kinds of outlier limits for
        # rates of use (pounds of AI per unit treated) each AI, ai_group, record type, and unit treated.
        # The largest proportion of this script determines if there are distinct sets of rates
        # within each AI for different pesticide products, crops or sites treated, and record types
        # (ag or non-ag). If different sets are found, each set is given a different value
        # for the variable "ai_group".
        # I have commented out the call to create_ai_groups_ai_outlier_stats.sql
        # because I don't normally want to recreate these tables, but
        # rather add the new year's data to them.
        print "_____________________________________________________________________________________________________________________"
        print "Running Oracle script create_ai_groups_ai_outlier_stats.sql"
        return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
                                  ' @high_values/outliers/sql_py/create_ai_groups_ai_outlier_stats ')
        if return_status != 0:
            print "Python script ended because of an error in create_ai_groups_ai_outlier_stats.sql."
            sys.exit()

        print "_____________________________________________________________________________________________________________________"
        print "Running Python script outlier_stats.py"
        execfile("high_values/outliers/sql_py/outlier_stats.py")


    #################################################################################################
    if run_outlier_stats_nonag:
        # The SQL script creates two Oracle tables AI_GROUP_NONAG_STATS and AI_OUTLIER_NONAG_STATS
        # and the Python script creates 2 files ai_group_nonag_stats.txt and ai_outlier_nonag_stats.txt,
        # imports these data into the Oracle tables, and updates Oracle table
        # PUR_RATES_YYYY with values for field ai_group.
        # This differs from the tables above in the meaning of rates of use.  Here the rate
        # means pounds of AI per application and includes only monthly summary PUR records
        # (which are mostly non-ag applications).
        # Table AI_GROUP_NONAG_STATS gives the ai_group number for each AI, site, and product.
        # It also contains various statistics of use.
        # Table AI_OUTLIER_STATS gives all the different kinds of outlier limits for pounds of AI
        # per application for each AI and ai_group.
        # I have commented out the call to create_ai_groups_ai_outlier_stats.sql
        # because I don't normally want to recreate these tables, but
        # rather add the new year's data to them.
        # I have commented out the call to create_ai_groups_ai_outlier_stats.sql
        # because I don't normally want to recreate these tables, but
        # rather add the new year's data to them.
        print "_____________________________________________________________________________________________________________________"
        print "Running Oracle script create_ai_groups_ai_outlier_stats_nonag.sql"
        return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
                               ' @high_values/outliers/sql_py/create_ai_groups_ai_outlier_stats_nonag ')
        if return_status != 0:
            print "Python script ended because of an error in create_ai_groups_ai_outlier_stats_nonag.sql."
            sys.exit()

        print "_____________________________________________________________________________________________________________________"
        print "Running Python script outlier_stats_nonag.py"
        execfile("high_values/outliers/sql_py/outlier_stats_nonag.py")


    #################################################################################################
    if run_pur_outlier:
        # Create table PUR_OUTLIER_YYYY.
        print "_____________________________________________________________________________________________________________________"
        print "Running Oracle script create_pur_outlier.sql"
        return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
                                  ' @high_values/outliers/sql_py/create_pur_outlier ' + str(stat_year))
        if return_status != 0:
            print "Python script ended because of an error in create_pur_outlier.sql."
            sys.exit()

#################################################################################################
if run_high_values:
    # Creates the table Oracle table HIGH_VALUES.  Download data from this table,
    # import into Excel, and mark records to send to the counties for error checking and
    # correction. Table HIGH_VALUES combines the results of tables HIGH_LBS, HIGH_ACRES, HIGH_RATES,
    # and HIGH_CHANGES to create a table of individual PUR records with flags for each kind
    # of high value.  This should be examined and all records that appear
    # to be errors should be sent back to the counties for correction.
    # Creates table pur_lbs_percentiles_&&1, which contains percentiles in lbs of AI
    # by AI, county, and record type for the previous 5 years (or num_years_high_changes).
    # This table is used in create_high_values.sql.

    # Create table PUR_LBS_PERCENTILES_YYYY.
    print "___________________________________________________________________________________________"
    print "Running Oracle script create_pur_percentiles.sql"
    return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
                              ' @high_values/sql_py/create_pur_percentiles ' + str(stat_year) + ' ' + str(stat_year-num_years_high_changes+1))
    if return_status != 0:
        print "Python script ended because of an error in create_pur_percentiles.sql."
        sys.exit()

    # Create indexes. NoTE from Kim _ causing too many errors (name is already used by an existing object appears often, then the code seems to stall until i type exit() - it wont return to the highvalues python script)  so commented out 7 lines below
    #print "___________________________________________________________________________________________"
    #print "Running Oracle script create_indexes.sql"
    #return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
    #                          ' @high_values/outliers/sql_py/create_indexes ')
    #if return_status != 0:
    #    print "Python script ended because of an error in create_indexes.sql."
    #    sys.exit()

    # Create table HIGH_VALUES_YYYY.
    print "_____________________________________________________________________________________________________________________"
    print "Running Oracle script create_high_values.sql"
    return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
                           ' @high_values/outliers/sql_py/create_high_values ' + str(stat_year))
    if return_status != 0:
        print "Python script ended because of an error in create_high_values.sql."
        sys.exit()


#################################################################################################
if run_pur_sum:
    # Create table PUR_SUM.
    print "___________________________________________________________________________________________"
    print "Running Oracle script create_pur_sum.sql"
    return_status = os.system('sqlplus -s ' + userid + tns_service + '/' + password +
                              ' @oracle_tables/sql/create_pur_sum ' + str(stat_year) + ' ' + cutoff_date + ' ' +
                              which_pur + ' ' + rerun)
    if return_status != 0:
        print "Python script ended because of an error in create_pur_sum.sql."
        sys.exit()
