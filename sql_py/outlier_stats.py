#######
# TO DO::
# replace save() with to_pickle(), load() with read_pickle(), and read_frame() with read_sql().
#############################
#
# This script, outlier_stats.py, creates 2 files ai_group_stats.txt and ai_outlier_stats.txt,
# imports these data into Oracle tables AI_GROUP_STATS and AI_OUTLIER_STATS, and updates
# Oracle table PUR_RATES_YYYY with values for field ai_group.
# These data include statistics on outlier limits for rates of use for each AI.
# The largest proportion of this script determines if there are distinct sets of rates
# within each AI for different pesticide products, crops or sites treated, and record types
# (ag or non-ag). If different sets are found, each set is given a different value
# for the variable "ai_group".
# Several outlier criteria are used such as flagging rates that are greater than a fixed value,
# 50 * median rate, or trimmed mean + 8* trimmed standard deviation.
# For a detailed explanation of these procedures see document on outliers, new_outlier2.pdf.
# Note that the fixed limits are no longer included in table AI_OUTLIER_STATS.
#
# This script starts with a list of parameters that can be used to adjust how the script
# is run or to adjust the algorithms used for determining groups of AI rates.
# Next, the script loads data either from Oracle tables or Python data files.
# Then several functions are defined.
# These functions are called by the main routine at the end of this script.
#
# There are two ways to generate frequency distributions of rates of use:
# 1. Run the R Script make_freq_plots.R (in outliers/new/R/).  This will generate frequency distribtuions
#    for the AIs you list and will also show the outlier limits
# 2. Open the Tableau file pur_rates_2012.twb (in outliers/new/tables/). This does not show
#    outlier limits, but you can explore the data more interactively, and view frequency
#    distribtuions by product and site.
#
# After you run this, to look at various statistics on outliers run first
# outlier_new2.sql, then outlier_results2.sql.
#
# If you need to install any of these packages, use:
# For numpy: http://sourceforge.net/projects/numpy/files/NumPy/1.10.2/numpy-1.10.2-win32-superpack-python2.7.exe
# For pandas: pip install pandas
# For cx_Oracle: use appropriate installer from https://pypi.python.org/pypi/cx_Oracle
#
import os
import sys
import numpy as np
from pandas import Series, DataFrame
import pandas as pd
import pandas.io.sql as sql
import cx_Oracle #Note from kim: Import cx_oracle was commented out which through an error when cx_oracle was called later in script, so i uncommented it
import gc
#import getpass #Note from kim, added getpass since included in script below - it is imported in high_values.py so maybe not needed here

# The following set of parameter should be defined in high_value.py (or in prelim.py?),
# which calls this script.
#userid = 'lwilhoit'
#userid = 'ksteinmann[pur_report]'#Note from Kim: commented out. Uncommenting it and changing to my password
#print 'Type your Oracle password (password is hidden as you type)'#Note from Kim: commented out. Uncommenting it
#password= getpass.getpass()#Note from Kim: commented out. Uncommenting it
#tns_service = '@dprprod2'#Note from Kim: commented out. Uncommenting it
#
#stat_year = 2017 #Note from Kim: preivously said stat_year = current_year. I do not see current_year defined anywhere? changed to 2017
#
#load_from_oracle = True #Note from Kim: commented out. Uncommenting it and changing to True
#
# When loading data into the Oracle tables AI_GROUP_STATS and AI_OUTLIER_STATS
# if you want to replace the data already in these tables, set
# replace_oracle_tables = True.
# If you want to add data to existing tables, set
# append_oracle_tables = True.
# If you don't want to do either set both parameters = False
# replace_oracle_tables = True #Note from kim: replace_oracle_tables and append_oracle_tables both commented out. Uncommenting and setting replace to true, append to false
# append_oracle_tables = False

# If you want to update Oracle table PUR_RATE_YYYY with new values for ai_groups, set
# update_pur_rates = False #Note from kim - update_pur_rates was commented out, which seems to default to true as the section still ran... the sql scripts this section calls do not exist, so i uncommented and set to false

# Parameters used in determining the groups of similar rates.
sum_sq_pct_diff_limit = 60
mean_trim_diff_limit = 1

# What is the minumum size of a group to consider separate group?
# These parameters are used in the code:
# min_box_size <- max(min_min_size, nrow(rates_ai_df)*min_size_prop)
min_min_size = 10
min_size_prop = 0.001

# Adjust the standard deviation used to get outlier limits (sd_trim_rate)
# by increasing its value for AIs with few records, using the equation:
# sd_rate_trim = max(sd_rate_trim_orig, sd_min)*(1+sd_adjust_a*(num_recs_trim**(-sd_adjust_b))).

# Set min value for sd_trim  = 0.04; this number was used because using sd below that produced
# a high percent of outliers.  There is no correlation of sd_trim with mean
# and only a weak correlation with number of records.
#
# For num recs <= 4 (or 5 or 6?), don't use the sd criteria, just the fixed criterion.
# However, I still calculate the statistics in this table, but exclude situations
# with num recs <= 4 in outlier script (variable v_num_recs_min in outliers_new_raw.sql)
sd_adjust_a = 60
sd_adjust_b = 1.7
sd_min = 0.05

# Trim parameters:
# If number of values in the vector >= trim_min,
# then remove a  fraction trim_prop from x at BOTH upper AND lower end of range of x
trim_min = 4
trim_prop = 0.05


##########################################################################################################################
# Load data into three Panda data frames, either from Oracle tables or Python data files.
if load_from_oracle:
    con = cx_Oracle.connect(userid + '/' + password + tns_service)

    # Separate into files by ai_type.
    print "Get herbicide data from Oracle:"
    pur_rates_df = \
        sql.read_sql(
            'SELECT chem_code, chemname, ai_name, ai_adjuvant, site_code, site_general, regno_short, ' + \
                    'ago_ind, unit_treated, log_ai_rate ' + \
            'FROM pur_rates_' + str(stat_year) + ' LEFT JOIN ai_categories USING (chem_code) ' + \
            "WHERE ai_type = 'HERBICIDE'", con)

    pur_rates_df.columns = [x.lower() for x in pur_rates_df.columns]
    pur_rates_df.to_pickle('high_values/outliers/tables/pur_rates_herbicide_df.pkl')

    del(pur_rates_df)
    gc.collect()

    print "Get insecticide data from Oracle:"
    pur_rates_df = \
        sql.read_sql(
            'SELECT chem_code, chemname, ai_name, ai_adjuvant, site_code, site_general, regno_short, ' + \
                    'ago_ind, unit_treated, log_ai_rate ' + \
            'FROM pur_rates_' + str(stat_year) + ' LEFT JOIN ai_categories USING (chem_code) ' + \
            "WHERE ai_type = 'INSECTICIDE'", con)

    pur_rates_df.columns = [x.lower() for x in pur_rates_df.columns]
    pur_rates_df.to_pickle('high_values/outliers/tables/pur_rates_insecticide_df.pkl')
    del(pur_rates_df)
    gc.collect()

    print "Get fungicide data from Oracle:"
    pur_rates_df = \
        sql.read_sql(
            'SELECT chem_code, chemname, ai_name, ai_adjuvant, site_code, site_general, regno_short, ' + \
                    'ago_ind, unit_treated, log_ai_rate ' + \
            'FROM pur_rates_' + str(stat_year) + ' LEFT JOIN ai_categories USING (chem_code) ' + \
            "WHERE ai_type = 'FUNGICIDE'", con)

    pur_rates_df.columns = [x.lower() for x in pur_rates_df.columns]
    pur_rates_df.to_pickle('high_values/outliers/tables/pur_rates_fungicide_df.pkl')

    del(pur_rates_df)
    gc.collect()

    print "Get adjuvant data from Oracle:"
    pur_rates_df = \
        sql.read_sql(
            'SELECT chem_code, chemname, ai_name, ai_adjuvant, site_code, site_general, regno_short, ' + \
                    'ago_ind, unit_treated, log_ai_rate ' + \
            'FROM pur_rates_' + str(stat_year) + ' LEFT JOIN ai_categories USING (chem_code) ' + \
            "WHERE ai_type = 'ADJUVANT'", con)

    pur_rates_df.columns = [x.lower() for x in pur_rates_df.columns]
    pur_rates_df.to_pickle('high_values/outliers/tables/pur_rates_adjuvant_df.pkl')

    del(pur_rates_df)
    gc.collect()

    print "Get other data from Oracle:"
    pur_rates_df = \
        sql.read_sql(
            'SELECT chem_code, chemname, ai_name, ai_adjuvant, site_code, site_general, regno_short, ' + \
                    'ago_ind, unit_treated, log_ai_rate ' + \
            'FROM pur_rates_' + str(stat_year) + ' LEFT JOIN ai_categories USING (chem_code) ' + \
            "WHERE ai_type NOT IN ('HERBICIDE', 'INSECTICIDE', 'FUNGICIDE', 'ADJUVANT') OR " + \
            'ai_type IS NULL', con)

    pur_rates_df.columns = [x.lower() for x in pur_rates_df.columns]
    pur_rates_df.to_pickle('high_values/outliers/tables/pur_rates_other_df.pkl')

    del(pur_rates_df)
    gc.collect()


##########################################################################################################################


##########################################################################################################################
# Function to create a trimmed vector:
# first NAs are removed from x;
# then, if number of values in x >= minnum,
# remove a  fraction p from x at BOTH upper AND lower end of range of x
# Returns sorted trimmed vector
def trim (xarray, p, minnum):
    # testing: xarray = [4, 2, 1, None, 10, 3, None, 4]
    xt = [x for x in xarray if pd.notnull(x)]
    xt.sort()
    n = len(xt)
    m = int(round(n*p))

    if n >= minnum:
        return xt[m:(n-m)]
    else:
        return xt
# end trim()
##########################################################################################################################


##########################################################################################################################
# Create the dataframe, stats_ai, which includes several statistics of rates of use for
# an AI for each record type, unit_treated, pesticide product, and crop or site treated.
# Later the dataframes for each AI are comined into another dataframe, AI_GROUP_STATS,
# that includes all AIs.
def create_stats_ai (p_chem_code, p_rates_ai_df, p_ago_ind, p_unit_treated):
    # Initialize dataframe stats_ai. A list of variables is provided
    # so that these variables appear in this order.
    stats_ai = \
       DataFrame(columns=['chem_code', 'ai_group', 'site_general', 'regno_short',
                 'ago_ind', 'unit_treated', 'chemname', 'ai_name', 'ai_adjuvant',
                 'mean_trim', 'mean', 'median',
                 'sd_rate_trim', 'sd_rate_trim_orig', 'sd_rate',
                 'sum_sq_rate_trim', 'num_recs', 'num_recs_trim', 'year'])

    chemname = list(set(p_rates_ai_df.chemname))[0]
    ai_name = list(set(p_rates_ai_df.ai_name))[0]
    ai_adjuvant = list(set(p_rates_ai_df.ai_adjuvant))[0]

    for site_value in set(p_rates_ai_df.site_general):
        #print '____site = ' + site_value
        # Either of the following statements are equivalent:
        # for product_value in set(p_rates_ai_df.ix[p_rates_ai_df.site_general==site_value, "regno_short"]):
        for product_value in set(p_rates_ai_df.regno_short[p_rates_ai_df.site_general==site_value]):
            # print '__prod = ' + product_value

            log_ai_rates = \
                p_rates_ai_df.log_ai_rate[(p_rates_ai_df.site_general == site_value) & (p_rates_ai_df.regno_short == product_value)]

            #print '______log_ai_rates = ' + str(log_ai_rates)

            log_ai_rates = log_ai_rates[pd.notnull(log_ai_rates)]

            rates_trim = trim(log_ai_rates, trim_prop, trim_min)
            num_recs = len(log_ai_rates)
            num_recs_trim = len(rates_trim)
            median_rate = np.median(log_ai_rates)
            mean_rate = np.mean(log_ai_rates)
            mean_rate_trim = np.mean(rates_trim)
            sd_rate = np.std(log_ai_rates, ddof=1)
            sd_rate_trim_orig = np.std(rates_trim, ddof=1)
            sd_rate_trim = max(sd_rate_trim_orig, sd_min)*(1+sd_adjust_a*(num_recs_trim**(-sd_adjust_b)))

            if np.isnan(sd_rate) or np.isinf(sd_rate):
                sd_rate = None

            if np.isnan(sd_rate_trim_orig) or np.isinf(sd_rate_trim_orig):
                sd_rate_trim_orig = None

            if np.isnan(sd_rate_trim) or np.isinf(sd_rate_trim):
                sd_rate_trim = None

            if num_recs_trim == 1:
                sum_sq_rate_trim = 0
            else:
                # Note: np.var() uses N in denominator.
                sum_sq_rate_trim = np.var(rates_trim)*num_recs_trim

            stats_temp = \
            DataFrame({'year':[stat_year], 'site_general':[site_value], 'chem_code':[p_chem_code],
                       'chemname':[chemname], 'ai_name':[ai_name], 'ai_adjuvant':[ai_adjuvant],
                       'regno_short':[product_value], 'ago_ind':[p_ago_ind], 'unit_treated':[p_unit_treated],
                       'median':[median_rate], 'mean':[mean_rate], 'mean_trim':[mean_rate_trim],
                       'sd_rate':[sd_rate], 'sd_rate_trim_orig':[sd_rate_trim_orig], 'sd_rate_trim':[sd_rate_trim],
                       'sum_sq_rate_trim':[sum_sq_rate_trim], 'num_recs':[num_recs], 'num_recs_trim':[num_recs_trim],
                       'ai_group':[None]},
                    columns=['chem_code', 'ai_group', 'site_general', 'regno_short',
                             'ago_ind', 'unit_treated', 'chemname', 'ai_name', 'ai_adjuvant',
                             'mean_trim', 'mean', 'median',
                             'sd_rate_trim', 'sd_rate_trim_orig', 'sd_rate',
                             'sum_sq_rate_trim', 'num_recs', 'num_recs_trim', 'year'])

            stats_ai = pd.concat([stats_ai, stats_temp])

    stats_ai.index = range(1, len(stats_ai)+1)
    return stats_ai
# end create_stats_ai()
##########################################################################################################################


##########################################################################################################################
# Determine if the rates of use for this AI, record type, and unit treated can be separated
# into distinct rates for different products and sites. If they can, assign each
# set of rates a unique value for variable ai_group.
def create_groups (p_stats_ai, p_rates_ai_df, p_ago_ind, p_unit_treated):
    min_box_size = max(min_min_size, sum(p_stats_ai.num_recs)*min_size_prop)

    p_stats_ai = p_stats_ai.sort_index(by='mean_trim', ascending=False)

    # The following procedure will combine rates from different sites and products for each AI
    # into groups with similar values of trimmed mean and separated from other groups.
    # The dataframe p_stats_ai was created in the previous function and includes several
    # statistics of rates of use for the current AI for each record type, unit_treated,
    # pesticide product, and crop or site treated. It is sorted by trimmed mean starting
    # with the highest mean.
    # The procedure looks at each row in p_stats_ai which does not yet have
    # a group assigned to it (p_stats_ai.ai_group[i] is null) and determines if
    # this rate is similar to the rates of the current ai_group. If it is,
    # its ai_group is set equal that the current ai_group.
    # Each time this loops through all records in p_stats_ai, the group number
    # increases.  That is, the first time through ai_group is set = 1 and the
    # first record in p_stats_ai (which has the highest rate) has its ai_group set = 1.
    # All other records with similar rates have their ai_group set = 1.
    # After it goes through all records, if there are still records with no group
    # number it will loop through again setting group number = 2; etc.
    # Rates are considered similar if their values are close to one another and
    # if the sum of squares of rates in a group is different from the sum of
    # squares in other groups.
    # Here is a more detailed explanation of the criteria to use in determining the
    # groups of similar rates. A set of log rates (for a specific value of site and for product)
    # is considered to part of a different group than the current group if:
    # 1. sum_sq_trim_pct_diff > sum_sq_pct_diff_limit
    # 		where sum_sq_trim_pct_diff = (sum_sq_trim_total - sum_sq_trim_now - sum_sq_trim_next)/sum_sq_trim_total * 100,
    # 				sum_sq_trim_now is the sum of squares of the trimmed set of all log rates in a group so far, and
    # 				sum_sq_trim_next is the sum of squares for the rates in the next set of records for a site and product, and
    # 				sum_sq_trim_total is the sum of squares for the rates in both sets.
    # 		A large sum_sq_trim_pct_diff means that two sets of rates are different from one another.
    # 		This is similar to the criterion used in regression trees.
    #
    # 2. mean_trim_inital_diff > mean_trim_diff_limit,
    # 		where mean_trim_inital_diff = abs(mean_trim_inital - mean_trim_next),
    # 				mean_trim_inital is the trimmed mean of the log rates of the first set of rates,
    # 				mean_trim_next is the trimmed mean of the next group.
    #		Currently mean_trim_diff_limit = 1, which means that this criteria requires that the
    # 		non-log mean is < 0.1 of non-log group mean or non-log mean > 10 * non-log group mean, or
    # 		you can say they differ by more than one order of magnitude.
    #		This is similar to the criteria used in PRIM (patient rule induction method).
    ai_group = 0
    while any(x is None for x in p_stats_ai.ai_group):
        # print "In while statement"
        ai_group = ai_group + 1
        mean_trim_inital = None
        first_in_group = True

        # print "__Group " + str(ai_group) + "; Min box size " + str(min_box_size)
        for i in p_stats_ai.index :
            if pd.isnull(p_stats_ai.ai_group[i]):
                #print "__i = " + str(i) + '; ' + p_stats_ai.regno_short[i] + '; ' + str(p_stats_ai.mean_trim[i]) + '; num_recs ' + str(p_stats_ai.num_recs[i])
                #print "i = " + str(i)

                # If the number of records with this site and product is less than min_box_size,
                # set group = 0.  Later the procedure will assign these small groups to one
                # of the main groups.
                if p_stats_ai.num_recs[i] < min_box_size:
                    p_stats_ai.ai_group[i] = 0
                else:
                    if first_in_group:
                        first_in_group = False
                        group_now = p_rates_ai_df[(p_rates_ai_df.site_general==p_stats_ai.site_general[i]) &
                                                  (p_rates_ai_df.regno_short==p_stats_ai.regno_short[i])]

                        p_stats_ai.ai_group[i] = ai_group

                        # print '__Shape of group_now (first group) ' + str(group_now.shape) + '; type ' + str(type(group_now))
                    else:
                        # Get the statistics for the current group:
                        # set rates_trim_now = all the rates for this site and product but remove the highest and lowest rates.
                        # print '__Shape of group_now (later group) ' + str(group_now.shape) + '; type ' + str(type(group_now))
                        rates_trim_now = Series(trim(group_now.log_ai_rate, trim_prop, trim_min))
                        rates_trim_now = rates_trim_now[pd.notnull(rates_trim_now)]
                        num_recs_trim_now = len(rates_trim_now)

                        mean_trim_now = np.mean(rates_trim_now)
                        if pd.isnull(mean_trim_inital):
                           mean_trim_inital = mean_trim_now

                        sum_sq_trim_now = np.var(rates_trim_now)*num_recs_trim_now

                        # Get the statistics for the next group:
                        rates_next = p_rates_ai_df.log_ai_rate[(p_rates_ai_df.site_general==p_stats_ai.site_general[i]) & \
                                                    (p_rates_ai_df.regno_short==p_stats_ai.regno_short[i])]
                        rates_trim_next = Series(trim(rates_next, trim_prop, trim_min))
                        num_recs_trim_next = p_stats_ai.num_recs_trim[i]

                        mean_trim_next = p_stats_ai.mean_trim[i]
                        sum_sq_trim_next = p_stats_ai.sum_sq_rate_trim[i]

                        mean_trim_inital_diff = abs(mean_trim_inital - mean_trim_next)

                        # Get the statistics for the combined group:
                        total_rates_trim = pd.concat([rates_trim_now, rates_trim_next])
                        num_recs_trim_total = len(total_rates_trim)

                        sum_sq_trim_total = np.var(total_rates_trim)*num_recs_trim_total
                        sum_sq_trim_pct_diff = (sum_sq_trim_total - sum_sq_trim_now - sum_sq_trim_next)/sum_sq_trim_total * 100

                        if pd.notnull(sum_sq_trim_pct_diff) & \
                               (not((mean_trim_inital_diff > mean_trim_diff_limit) & \
                                    (sum_sq_trim_pct_diff > sum_sq_pct_diff_limit))):
                            groupi = p_rates_ai_df[(p_rates_ai_df.site_general==p_stats_ai.site_general[i]) & \
                                                   (p_rates_ai_df.regno_short==p_stats_ai.regno_short[i])]
                            # print '__Shape of groupi ' + str(groupi.shape) + '; type ' + str(type(group_now))
                            group_now = pd.concat([group_now, groupi])
                            p_stats_ai.ai_group[i] = ai_group
                            group_now.index = range(1, len(group_now)+1)

    #print "__end ai_group " + str(ai_group)

    return p_stats_ai
# end create_groups()
##########################################################################################################################


##########################################################################################################################
# Since data (for a single site-product) were assigned to groups sequentially, before all
# groups were determined, it may be that some data are actually closer to a group created later.
# Also small groups (which are identified in the code above by setting stats$group = 0)
# have not yet been assigned to any group.
# This function will reassign data to another group if its trimmed mean
# is closer to the trimmed mean of that group.
def reassign_groups (p_stats_ai, p_rates_ai_df):
    # It is possible that number of records for all site-product groups are small,
    # so that all have group = 0; in that case set all group values = 1.
    # Also, if there is only one group, set all group values = 1.
    #stats_groups = DataFrame()
    if max(p_stats_ai.ai_group) < 2:
        p_stats_ai.ai_group = 1
        return p_stats_ai

    # First, get the trimmed mean rates for each of the current AI groups (except for group 0).
    # For each of the current groups, get a list of the sites and prods for that group,
    # which are needed to get a list of rates for that group. Then calculate the
    # trimmed mean of those rates.  Create a data frame, stats_group, with the
    # trimmed mean for each group.
    stats_groups = DataFrame()
    for i in set(p_stats_ai.ai_group[p_stats_ai.ai_group > 0]):
        site_prod = p_stats_ai.ix[p_stats_ai.ai_group == i, ['site_general', 'regno_short']]

        rates_group = Series()
        for j in site_prod.index:
            rates_groupj = p_rates_ai_df.log_ai_rate[(p_rates_ai_df.site_general == site_prod.site_general[j]) & \
                                                     (p_rates_ai_df.regno_short == site_prod.regno_short[j])]
            rates_group = pd.concat([rates_group, rates_groupj])

        rates_group = rates_group[pd.notnull(rates_group)]
        rates_trim = Series(trim(rates_group, trim_prop, trim_min))
        mean_trim = np.mean(rates_trim)

        stats_groupsi = DataFrame({'ai_group': [i], 'mean_trim': [mean_trim]})
        stats_groups = pd.concat([stats_groups, stats_groupsi])

    #print '......................................................'
    #print 'stats_groups'
    #print stats_groups

    stats_groups.index = range(1, len(stats_groups)+1)
    p_stats_ai.index = range(1, len(p_stats_ai)+1)

    # Then for each data set, find the group with trimmed mean rate closest
    # to the mean rate of that data set.
    for i in p_stats_ai.index:
        #print '......................................................'
        #print 'i = ' + str(i) + ' mean_trim = ' + str(p_stats_ai.mean_trim[i])

        min_diff = 1000000
        for j in stats_groups.index:
            mean_trim_diff = abs(p_stats_ai.mean_trim[i] - stats_groups.mean_trim[j])
            if  mean_trim_diff < min_diff:
                min_diff = mean_trim_diff
                group_min_diff = stats_groups.ai_group[j]

        #print 'group_min_diff = ' + str(group_min_diff) + '; min_diff = ' + str(min_diff)
        p_stats_ai.ai_group[i] = group_min_diff

    return p_stats_ai
# end reassign_groups()
##########################################################################################################################


##########################################################################################################################
# Get the statistics for all AI groups, which now includes any reassignments to groups.
# This creates two data frames, AI_GROUP_STATS and AI_OUTLIER_STATS, which are used
# by the outlier program to flag outliers in the PUR.
# Data frame AI_GROUP_STATS shows the group number for each AI, site, product, ago_ind, and unit_treated
# and a set of statistics for rates or use.
# Data frame AI_OUTLIER_STATS gives the outlier limits for each AI, group, ago_ind, and unit_treated.
# Create data frame AI_OUTLIER_STATS
def create_ai_outlier_stats (p_stats_ai, p_rates_ai_df, p_ago_ind, p_unit_treated):
    chem_code = list(set(p_stats_ai.chem_code))[0]
    ai_outlier_stats = \
        DataFrame(columns=['year', 'chem_code', 'ai_group',
                           'ago_ind', 'unit_treated',
                           'num_recs', 'num_recs_trim',
                           'median_rate', 'mean_rate', 'mean_rate_trim',
                           'sd_rate', 'sd_rate_trim_orig', 'sd_rate_trim',
                           'sum_sq_rate_trim',
                           'med50', 'med100', 'med150', 'med200', 'med250', 'med300', 'med400', 'med500',
                           'mean3sd', 'mean5sd', 'mean7sd', 'mean8sd', 'mean10sd', 'mean12sd', 'mean15sd'])

    for ai_group in set(p_stats_ai.ai_group):
        site_prod = p_stats_ai.ix[p_stats_ai.ai_group == ai_group, ['site_general', 'regno_short']]

        rates_group = Series()
        for j in site_prod.index:
            rates_groupj = p_rates_ai_df.log_ai_rate[(p_rates_ai_df.site_general == site_prod.site_general[j]) & \
                                                     (p_rates_ai_df.regno_short == site_prod.regno_short[j])]
            rates_group = pd.concat([rates_group, rates_groupj])

        rates_group = rates_group[pd.notnull(rates_group)]
        rates_trim = Series(trim(rates_group, trim_prop, trim_min))

        num_recs_group = len(rates_group)
        num_recs_group_trim = len(rates_trim)

        mean_rate = np.mean(rates_group)
        mean_rate_trim = np.mean(rates_trim)
        median_rate = np.median(rates_group)

        if num_recs_group == 1:
            sd_rate = 0.0
            sum_sq_rate = 0.0
        else:
            sd_rate = np.std(rates_group, ddof=1)
            sum_sq_rate = np.var(rates_group)*num_recs_group

            if np.isnan(sd_rate) or np.isinf(sd_rate):
                sd_rate = None

            if np.isnan(sum_sq_rate) or np.isinf(sum_sq_rate):
                sum_sq_rate = None

        if num_recs_group_trim == 1:
            sd_rate_trim_orig = 0
            sd_rate_trim = 0
            sum_sq_rate_trim = 0
        else:
            sd_rate_trim_orig = np.std(rates_trim, ddof=1)
            sd_rate_trim = max(sd_rate_trim_orig, sd_min)*(1+sd_adjust_a*(num_recs_group_trim**(-sd_adjust_b)))
            sum_sq_rate_trim = np.var(rates_trim)*num_recs_group_trim

            if np.isnan(sd_rate_trim_orig) or np.isinf(sd_rate_trim_orig):
                sd_rate_trim_orig = None

            if np.isnan(sd_rate_trim) or np.isinf(sd_rate_trim):
                    sd_rate_trim = None

            if np.isnan(sum_sq_rate_trim) or np.isinf(sum_sq_rate_trim):
                sum_sq_rate_trim = None

        med50 = median_rate +  np.log10(50)
        med100 = median_rate +  np.log10(100)
        med150 = median_rate +  np.log10(150)
        med200 = median_rate +  np.log10(200)
        med250 = median_rate +  np.log10(250)
        med300 = median_rate +  np.log10(300)
        med400 = median_rate +  np.log10(400)
        med500 = median_rate +  np.log10(500)
        mean3sd = mean_rate_trim + 3*sd_rate_trim
        mean5sd = mean_rate_trim + 5*sd_rate_trim
        mean7sd = mean_rate_trim + 7*sd_rate_trim
        mean8sd = mean_rate_trim + 8*sd_rate_trim
        mean10sd = mean_rate_trim + 10*sd_rate_trim
        mean12sd = mean_rate_trim + 12*sd_rate_trim
        mean15sd = mean_rate_trim + 15*sd_rate_trim

        ai_adjuvant = list(set(p_rates_ai_df.ai_adjuvant))[0]

        # We can not determine if this is a WATER because there may be
        # several sites in this set of records.
        # In the analysis or in the loader procedure which examines
        # each individual record then can determine if this is a WATER.
        # if p_ago_ind == 'N' and p_rates_ai_df.site_code in [65000, 65503]:
        #    ai_rate_type = 'WATER'
        #elif ai_adjuvant == 'Y' and p_ago_ind == 'A' and p_unit_treated == 'A':
        if ai_adjuvant == 'Y' and p_ago_ind == 'A' and p_unit_treated == 'A':
            ai_rate_type = 'ADJUVANT'
        elif chem_code in (136, 233, 385, 573, 616, 970):
            ai_rate_type = 'HIGH_RATE_AI'
        elif chem_code in (7, 99, 270, 358, 401, 560, 765, 1596, 1794, 2106, 2210, 2273, 2629, 5785):
            ai_rate_type = 'MEDIUM_RATE_AI'
        else:
            ai_rate_type = 'NORMAL_RATE_AI'

            # (65000 in set(p_rates_ai_df.site_code) or 65503 in set(p_rates_ai_df.site_code)):
        #print 'ago ' + p_ago_ind + '; unit ' + p_unit_treated + '; adj ' + ai_adjuvant + '; chem ' + str(chem_code) + '; type ' + ai_rate_type

        ai_outlier_statsi = \
        DataFrame({'year':[stat_year], 'chem_code':[chem_code], 'ai_group':[ai_group],
                   'ago_ind':[p_ago_ind], 'unit_treated':[p_unit_treated],
                   'num_recs':[num_recs_group], 'num_recs_trim':[num_recs_group_trim],
                   'median_rate':[median_rate],'mean_rate':[mean_rate], 'mean_rate_trim':[mean_rate_trim],
                   'sd_rate':[sd_rate], 'sd_rate_trim_orig':[sd_rate_trim_orig], 'sd_rate_trim':[sd_rate_trim],
                   'sum_sq_rate_trim':[sum_sq_rate_trim],
                   'med50':[med50], 'med100':[med100], 'med150':[med150], 'med200':[med200], 'med250':[med250],
                   'med300':[med300], 'med400':[med400], 'med500':[med500],
                   'mean3sd':[mean3sd], 'mean5sd':[mean5sd], 'mean7sd':[mean7sd], 'mean8sd':[mean8sd],
                   'mean10sd':[mean10sd], 'mean12sd':[mean12sd], 'mean15sd':[mean15sd]},
                  columns=['year', 'chem_code', 'ai_group',
                           'ago_ind', 'unit_treated',
                           'num_recs', 'num_recs_trim',
                           'median_rate', 'mean_rate', 'mean_rate_trim',
                           'sd_rate', 'sd_rate_trim_orig', 'sd_rate_trim',
                           'sum_sq_rate_trim',
                           'med50', 'med100', 'med150', 'med200', 'med250', 'med300', 'med400', 'med500',
                           'mean3sd', 'mean5sd', 'mean7sd', 'mean8sd', 'mean10sd', 'mean12sd', 'mean15sd'])

        ai_outlier_stats = pd.concat([ai_outlier_stats, ai_outlier_statsi])

    return ai_outlier_stats

# end create_ai_outlier_stats()
##########################################################################################################################



##########################################################################################################################
# Main program
# This script creates two data frames: AI_GROUP_STATS and AI_OUTLIER_STATS.
# The first two statements creates these as empty data frames.
# To sort the columns in these data frames, you need to list them in the proper order
# both here and in the statement which adds records to the data frame later
# (in functions reassign_groups() and create_ai_outlier_stats()).

ai_group_stats = \
   DataFrame(columns=['chem_code', 'ai_group', 'site_general', 'regno_short',
                 'ago_ind', 'unit_treated', 'chemname', 'ai_name', 'ai_adjuvant',
                 'mean_trim', 'mean', 'median',
                 'sd_rate_trim', 'sd_rate_trim_orig', 'sd_rate',
                 'sum_sq_rate_trim', 'num_recs', 'num_recs_trim', 'year'])

ai_outlier_stats = \
    DataFrame(columns=['year', 'chem_code', 'ai_group',
                       'ago_ind', 'unit_treated',
                       'num_recs', 'num_recs_trim',
                       'median_rate', 'mean_rate', 'mean_rate_trim',
                       'sd_rate', 'sd_rate_trim_orig', 'sd_rate_trim',
                       'sum_sq_rate_trim',
                       'med50', 'med100', 'med150', 'med200', 'med250', 'med300', 'med400', 'med500',
                       'mean3sd', 'mean5sd', 'mean7sd', 'mean8sd', 'mean10sd', 'mean12sd', 'mean15sd'])

ai_type_list = ['insecticide', 'herbicide', 'fungicide', 'adjuvant', 'other']

for ai_type in ai_type_list:
    print('\n')
    print('*********************************************************************************************')
    print 'Reading pur_rates_df dataframe from ' + 'pur_rates_' + ai_type + '_df.pkl'
    pur_rates_df = pd.read_pickle('high_values/outliers/tables/pur_rates_' + ai_type + '_df.pkl')

    #for (ago_ind, unit_treated) in [(a, b) for a in ['A'] for b in ['U']]:
    for (ago_ind, unit_treated) in [(a, b) for a in ['A', 'N'] for b in ['A', 'C', 'P', 'U']]:
        print('\n')
        print('===================================================================')
        print 'ago_ind = ' + ago_ind + '; unit_treated = ' + unit_treated

        ai_list = sorted(set(pur_rates_df.chem_code[(pur_rates_df.ago_ind == ago_ind) & (pur_rates_df.unit_treated == unit_treated)]))

        # ai_list = [53, 2132]

        if not ai_list: # This will evaluate to True if ai_list contains no elements or if ai_list = None
            continue
        print ai_list

        # print('\n')
        # print('===================================================================')
        for chem_code in ai_list:
            rates_ai_df = \
                pur_rates_df[(pur_rates_df.ago_ind == ago_ind) & (pur_rates_df.unit_treated == unit_treated) &
                             (pur_rates_df.chem_code == chem_code)]

            # print 'AI = ' + str(chem_code) + '; num recs = ' + str(len(rates_ai_df))

            # print('Call create_stats_ai()')
            stats_ai = create_stats_ai(chem_code, rates_ai_df, ago_ind, unit_treated)

            # print '_________________________________________________________'
            # print 'Call create_groups()'
            stats_ai = create_groups(stats_ai, rates_ai_df, ago_ind, unit_treated)

            # Create data frame AI_GROUP_STATS
            # print '_________________________________________________________'
            # print 'Call reassign_groups()'
            stats_ai = reassign_groups(stats_ai, rates_ai_df)
            ai_group_stats = pd.concat([ai_group_stats, stats_ai])

            # Create data frame AI_OUTLIER_STATS
            # print '_________________________________________________________'
            # print 'Call create_ai_outlier_stats()'
            ai_outlier_statsi = create_ai_outlier_stats(stats_ai, rates_ai_df, ago_ind, unit_treated)
            ai_outlier_stats = pd.concat([ai_outlier_stats, ai_outlier_statsi])

    del(pur_rates_df)
    gc.collect()

# Export the two data frames to tab-delimited text files.
print('\n')
print('*********************************************************************************************')
print('Export data frames ai_group_stats and ai_outlier_stats to files.')
if not ai_group_stats.empty:
    ai_group_stats.to_csv('high_values/outliers/tables/ai_group_stats.txt', index=False, sep='\t')

if not ai_outlier_stats.empty:
    ai_outlier_stats.to_csv('high_values/outliers/tables/ai_outlier_stats.txt', index=False, sep='\t')


# Update PUR_RATE with values for ai_group.
# First, load data from ai_outlier_stats.txt and ai_group_stats.txt into
# the Oracle tables AI_OUTLIER_STATS and AI_GROUP_STATS.
# You can either replace all the current data in these Oracle tables
# with the values in the text files, by setting parameter replace_oracle_tables = TRUE, or
# add the new data to data already in the tables, by setting parameter append_oracle_tables = TRUE.
if replace_oracle_tables:
    print('\n')
    print('*********************************************************************************************')
    print('Load data from ai_outlier_stats.txt into Oracle table AI_OUTLIER_STATS, replacing existing data.')
    return_status = os.system('sqlldr USERID=' + userid + '/' + password + tns_service +
                      ' CONTROL=high_values/outliers/sql_py/ctl_files/ai_outlier_stats_replace.ctl SKIP=1 LOG=high_values/outliers/sql_py/ctl_files/ai_outlier_stats.log errors=999999')

    if return_status != 0:
        print 'Python script ended because of an error in sqlldr'
        # sys.exit()

    print('\n')
    print('*********************************************************************************************')
    print('Load data from ai_group_stats.txt into Oracle table AI_GROUP_STATS, replacing existing data.')
    return_status = os.system('sqlldr USERID=' + userid + '/' + password + tns_service +
                      ' CONTROL=high_values/outliers/sql_py/ctl_files/ai_group_stats_replace.ctl SKIP=1 LOG=high_values/sql_py/ctl_files/ai_group_stats.log errors=999999')

    if return_status != 0:
        print 'Python script ended because of an error in sqlldr'
        # sys.exit()

elif append_oracle_tables:
    print('\n')
    print('*********************************************************************************************')
    print('Load data from ai_outlier_stats.txt into Oracle table AI_OUTLIER_STATS, adding to existing data.')
    return_status = os.system('sqlldr USERID=' + userid + '/' + password + tns_service +
                      ' CONTROL=high_values/sql_py/ctl_files/ai_outlier_stats_append.ctl SKIP=1 LOG=high_values/sql_py/ctl_files//ai_outlier_stats.log errors=999999')

    if return_status != 0:
        print 'Python script ended because of an error in sqlldr'
        # sys.exit()


    print('\n')
    print('*********************************************************************************************')
    print('Load data from ai_group_stats.txt into Oracle table AI_GROUP_STATS, adding to existing data.')
    return_status = os.system('sqlldr USERID=' + userid + '/' + password + tns_service +
                      ' CONTROL=high_values/sql_py/ctl_files/ai_group_stats_append.ctl SKIP=1 LOG=high_values/sql_py/ctl_files/ai_group_stats.log errors=999999')

    if return_status != 0:
        print 'Python script ended because of an error in sqlldr'
        # sys.exit()

if update_pur_rates:
    print('\n')
    print('*********************************************************************************************')
    print('Update ai_group in table PUR_RATES_' + str(stat_year))
    return_status = os.system('sqlplus -s ' + userid + '/' + password + tns_service +
                                      ' @high_values/outliers/sql_py/update_ai_group ' + str(stat_year))
    if return_status != 0:
        print "Python script ended because of an error in update_ai_group.sql."
        sys.exit()

print 'Finished with no errors.'
print('\n')


