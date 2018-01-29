
sql_directory = 'sql_py/'
ctl_directory = 'sql_py/ctl_files/'

try:
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
    file_list.append(sql_directory + 'create_pur_rates.sql')
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

    for file in file_list:
        f = open(file)
        f.close

    print('All files exist.')
except FileNotFoundError as fnf:
    print('This file not found: {}'.format(fnf.filename))

