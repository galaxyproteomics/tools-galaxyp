#!/usr/bin/env python

import pandas as pd
import numpy as np
from sklearn import linear_model
from sklearn.metrics import mean_absolute_error
import itertools
import os
import argparse
import re
import ConfigParser
import ast
import copy
import sys

import logging
log = logging.getLogger(__name__)


# filtering _outlier
def MahalanobisDist(x, y):
    covariance_xy = np.cov(x, y, rowvar=0)
    inv_covariance_xy = np.linalg.inv(covariance_xy)
    xy_mean = np.mean(x), np.mean(y)
    x_diff = np.array([x_i - xy_mean[0] for x_i in x])
    y_diff = np.array([y_i - xy_mean[1] for y_i in y])
    diff_xy = np.transpose([x_diff, y_diff])

    md = []
    for i in range(len(diff_xy)):
        md.append(np.sqrt(np.dot(np.dot(np.transpose(diff_xy[i]), inv_covariance_xy), diff_xy[i])))
    return md


# remove outlier
def MD_removeOutliers(x, y, width):
    MD = MahalanobisDist(x, y)
    threshold = np.mean(MD) * float(width)  # adjust 1.5 accordingly
    nx, ny, outliers = [], [], []
    for i in range(len(MD)):
        if MD[i] <= threshold:
            nx.append(x[i])
            ny.append(y[i])
        else:
            outliers.append(i)  # position of removed pair
    return (np.array(nx), np.array(ny), np.array(outliers))


# combination of rt predicted by each single model
def combine_model(x, model, err, weight_flag):
    x = x.values
    tot_err = np.sum(np.array(err)[np.where(~np.isnan(x))])

    app_sum = 0
    app_sum_2 = 0
    for ii in range(0, len(x)):
        if ~  np.isnan(x[ii]):
            if int(weight_flag) == 0:
                app_sum = app_sum + (model[ii].predict(x[ii])[0][0])
            else:
                app_sum_2 = app_sum_2 + (model[ii].predict(x[ii])[0][0] * (float(err[ii]) / float(tot_err)))

            # " output weighted mean
    if int(weight_flag) == 1:
        return float(app_sum_2)
    else:
        # output not weight
        return float(app_sum) / float(np.where(~ np.isnan(x))[0].shape[0])


# check columns read  from  a properties file
def check_columns_name(col_list, col_must_have):
    for c_name in col_must_have:
        if not (c_name in col_list):
            # fail
            return False
    # succes
    return True


# run the mbr in moFF : input  ms2 identified peptide   output csv file with the matched peptides added
def run_mbr(args):
    if not (os.path.isdir(args.loc_in)):
        exit(str(args.loc_in) + '-->  input folder does not exist ! ')

    if str(args.loc_in) == '':
        output_dir = 'mbr_output'
    else:
        if os.path.exists(os.path.join(args.loc_in)):
            # if '/' in  str(args.loc_in):
            output_dir = os.path.join(args.loc_in, 'mbr_output')
        else:
            exit(os.path.join(args.loc_in) + ' EXIT input folder path not well specified --> / missing ')

    if not (os.path.isdir(output_dir)):
        log.info("Created MBR output folder in :", output_dir)
        os.makedirs(output_dir)
    else:
        log.info("MBR Output folder in :", output_dir)

    moff_path = os.path.dirname(sys.argv[0])
    config = ConfigParser.RawConfigParser()
    config.read(os.path.join(moff_path, 'moff_setting.properties'))

    # it s always placed in same folder of moff_mbr.py
    # read input
    # comment better
    # name of the input file
    exp_set = []
    # list of the input dataframe
    exp_t = []
    # list of the output dataframe
    exp_out = []
    # lsit of input datafra used as help
    exp_subset = []
    for root, dirs, files in os.walk(args.loc_in):
        for f in files:
            if f.endswith('.' + args.ext):
                exp_set.append(os.path.join(root, f))

    if args.sample is not None:
        exp_set_app = copy.deepcopy(exp_set)
        for a in exp_set:
            if re.search(args.sample, a) is None:
                exp_set_app.remove(a)
        exp_set = exp_set_app

    if (exp_set == []) or (len(exp_set) == 1):
        exit('ERROR input files not found or just one input file selected . check the folder or the extension given in input')

    for a in exp_set:
        log.info('Reading file:  ', a)
        exp_subset.append(a)
        data_moff = pd.read_csv(a, sep="\t", header=0)
        list_name = data_moff.columns.values.tolist()
        if not check_columns_name(list_name, ast.literal_eval(config.get('moFF', 'col_must_have_x'))):
            exit('ERROR minimal field requested are missing or wrong')
        data_moff['matched'] = 0
        data_moff['mass'] = data_moff['mass'].map('{:.4f}'.format)

        data_moff['code_unique'] = data_moff['peptide'].astype(str) + '_' + data_moff['mass'].astype(str)
        data_moff = data_moff.sort(columns='rt')
        exp_t.append(data_moff)
        exp_out.append(data_moff)

    log.info('Read input --> done ')
    # parameter of the number of query
    # set a list of filed mandatory
    # ['matched','peptide','mass','mz','charge','prot','rt']

    n_replicates = len(exp_t)
    exp_set = exp_subset
    aa = range(0, n_replicates)
    out = list(itertools.product(aa, repeat=2))
    # just to save all the model
    # list of the model saved
    model_save = []
    # list of the error in min/or sec
    model_err = []
    # list of the status of the model -1 means model not available for low points in the training set
    model_status = []
    # add matched columns
    list_name.append('matched')
    # final status -1 if one of the output is empty
    out_flag = 1
    # input of the methods

    log.info('Filtering is %s : ', 'active' if args.out_flag == 1 else 'not active')
    log.info('Number of replicates %i,', n_replicates)
    log.info('Pairwise model computation ----')

    if args.rt_feat_file is not None:
        log.info('Custom list of peptide used  provided by the user in %s', args.rt_feat_file)
        shared_pep_list = pd.read_csv(args.rt_feat_file, sep='\t')
        shared_pep_list['mass'] = shared_pep_list['mass'].map('{:.4f}'.format)
        shared_pep_list['code'] = shared_pep_list['peptide'].astype(str) + '_' + shared_pep_list['mass'].astype(str)
        list_shared_pep = shared_pep_list['code']
        log.info('Custom list of peptide contains  %i ', list_shared_pep.shape[0])

    for jj in aa:
        log.info('matching  in ', exp_set[jj])

        for i in out:
            if i[0] == jj and i[1] != jj:
                if args.rt_feat_file is not None:
                    # use of custom peptide
                    comA = exp_t[i[0]][exp_t[i[0]]['code_unique'].isin(list_shared_pep)][['code_unique', 'peptide', 'prot', 'rt']]
                    comB = exp_t[i[1]][exp_t[i[1]]['code_unique'].isin(list_shared_pep)][['code_unique', 'peptide', 'prot', 'rt']]
                    comA = comA.groupby('code_unique', as_index=False).mean()
                    comB = comB.groupby('code_unique', as_index=False).mean()
                    common = pd.merge(comA, comB, on=['code_unique'], how='inner')
                else:
                    # use of shared peptdes.
                    log.info('  Matching  %s peptide in   searching in %s ', exp_set[i[0]], exp_set[i[1]])
                    list_pep_repA = exp_t[i[0]]['code_unique'].unique()
                    list_pep_repB = exp_t[i[1]]['code_unique'].unique()
                    log.info('Peptide unique (mass + sequence) %i , %i ',
                             list_pep_repA.shape[0],
                             list_pep_repB.shape[0])
                    set_dif_s_in_1 = np.setdiff1d(list_pep_repB, list_pep_repA)
                    add_pep_frame = exp_t[i[1]][exp_t[i[1]]['code_unique'].isin(set_dif_s_in_1)].copy()
                    pep_shared = np.intersect1d(list_pep_repA, list_pep_repB)
                    log.info('  Peptide (mass + sequence)  added size  %i ', add_pep_frame.shape[0])
                    log.info('  Peptide (mass + sequence) )shared  %i ', pep_shared.shape[0])
                    comA = exp_t[i[0]][exp_t[i[0]]['code_unique'].isin(pep_shared)][
                        ['code_unique', 'peptide', 'prot', 'rt']]
                    comB = exp_t[i[1]][exp_t[i[1]]['code_unique'].isin(pep_shared)][
                        ['code_unique', 'peptide', 'prot', 'rt']]
                    comA = comA.groupby('code_unique', as_index=False).mean()
                    comB = comB.groupby('code_unique', as_index=False).mean()
                    common = pd.merge(comA, comB, on=['code_unique'], how='inner')
                if common.shape[0] <= 10 and args.rt_feat_file is not None:
                    model_status.append(-1)
                    continue
                # filtering outlier option
                else:
                    if int(args.out_flag) == 1:
                        filt_x, filt_y, pos_out = MD_removeOutliers(common['rt_y'].values, common['rt_x'].values,
                                                                    args.w_filt)
                        data_B = filt_x
                        data_A = filt_y
                        data_B = np.reshape(data_B, [filt_x.shape[0], 1])
                        data_A = np.reshape(data_A, [filt_y.shape[0], 1])
                        log.info('Outlier founded %i  w.r.t %i', pos_out.shape[0], common['rt_y'].shape[0])
                    else:
                        data_B = common['rt_y'].values
                        data_A = common['rt_x'].values
                        data_B = np.reshape(data_B, [common.shape[0], 1])
                        data_A = np.reshape(data_A, [common.shape[0], 1])
                    log.info(' Size trainig shared peptide , %i %i ', data_A.shape[0], data_B.shape[0])
                    clf = linear_model.RidgeCV(alphas=np.power(2, np.linspace(-30, 30)), scoring='mean_absolute_error')
                    clf.fit(data_B, data_A)
                    clf_final = linear_model.Ridge(alpha=clf.alpha_)
                    clf_final.fit(data_B, data_A)
                    # save the model
                    model_save.append(clf_final)
                    model_err.append(mean_absolute_error(data_A, clf_final.predict(data_B)))
                    log.info(' Mean absolute error training : %4.4f sec',
                             mean_absolute_error(data_A, clf_final.predict(data_B)))
                    model_status.append(1)
    if np.where(np.array(model_status) == -1)[0].shape[0] >= (len(aa) / 2):
        log.error('MBR aborted :  mbr cannnot be run, not enough shared pepetide among the replicates ')
        exit('ERROR : mbr cannnot be run, not enough shared pepetide among the replicates')

    log.info('Combination of the  model  --------')
    log.info('Weighted combination  %s : ', 'Weighted' if int(args.w_comb) == 1 else 'Unweighted')

    diff_field = np.setdiff1d(exp_t[0].columns, ['matched', 'peptide', 'mass', 'mz', 'charge', 'prot', 'rt'])

    for jj in aa:
        pre_pep_save = []
        log.info('Predict rt for the exp.  in ', exp_set[jj])
        c_rt = 0
        for i in out:
            if i[0] == jj and i[1] != jj:
                log.info('Matching peptides found  in  %s ', exp_set[i[1]])
                list_pep_repA = exp_t[i[0]]['peptide'].unique()
                list_pep_repB = exp_t[i[1]]['peptide'].unique()
                set_dif_s_in_1 = np.setdiff1d(list_pep_repB, list_pep_repA)
                add_pep_frame = exp_t[i[1]][exp_t[i[1]]['peptide'].isin(set_dif_s_in_1)].copy()
                add_pep_frame = add_pep_frame[['peptide', 'mass', 'mz', 'charge', 'prot', 'rt']]
                add_pep_frame['code_unique'] = '_'.join(
                    add_pep_frame['peptide'], add_pep_frame['prot'], add_pep_frame['mass'].astype(str), add_pep_frame['charge'].astype(str))
                add_pep_frame = add_pep_frame.groupby('code_unique', as_index=False)[
                    'peptide', 'mass', 'charge', 'mz', 'prot', 'rt'].aggregate(max)
                add_pep_frame = add_pep_frame[['peptide', 'mass', 'mz', 'charge', 'prot', 'rt']]
                list_name = add_pep_frame.columns.tolist()
                list_name = [w.replace('rt', 'rt_' + str(c_rt)) for w in list_name]
                add_pep_frame.columns = list_name
                pre_pep_save.append(add_pep_frame)
                c_rt += 1
            # print 'input columns',pre_pep_save[0].columns
        if n_replicates == 2:
            test = pre_pep_save[0]
        else:
            test = reduce(
                lambda left, right: pd.merge(left, right, on=['peptide', 'mass', 'mz', 'charge', 'prot'], how='outer'),
                pre_pep_save)

        # (n_replicates-1) == offset for the  model vector
        # print test.columns[5:6]

        test['time_pred'] = test.ix[:, 5: (5 + (n_replicates - 1))].apply(
            lambda x: combine_model(x, model_save[(jj * (n_replicates - 1)):((jj + 1) * (n_replicates - 1))],
                                    model_err[(jj * (n_replicates - 1)):((jj + 1) * (n_replicates - 1))], args.w_comb),
            axis=1)
        test['matched'] = 1
        # print test.columns.tolist()
        # iif n_replicates > 3:
        #   test.drop('rt_x', axis=1, inplace=True)
        #   test.drop('rt_y', axis=1, inplace=True)
        #   test.drop('rt', axis=1, inplace=True)
        # else:
        #   if  n_replicates == 3:
        #       test.drop('rt_x', axis=1, inplace=True)
        #       test.drop('rt_y', axis=1, inplace=True)
        #   else:
        #       test.drop('rt', axis=1, inplace=True)

        # still to check better
        if test[test['time_pred'] <= 0].shape[0] >= 1:
            log.info(' -- Predicted negative RT: those peptide will be deleted')
            test = test[test['time_pred'] > 0]

        list_name = test.columns.tolist()
        list_name = [w.replace('time_pred', 'rt') for w in list_name]
        test.columns = list_name

        test = test[['peptide', 'mass', 'mz', 'charge', 'prot', 'rt', 'matched']]
        # just put nan with the missing values
        for field in diff_field.tolist():
            test[field] = np.nan  # -1

        log.info('Before adding %s contains %i ', exp_set[jj], exp_t[jj].shape[0])
        exp_out[jj] = pd.concat([exp_t[jj], test], join='outer', axis=0)
        log.info('After MBR %s contains:  %i  peptides', exp_set[jj], exp_out[jj].shape[0])
        log.info('matched features',
                 exp_out[jj][exp_out[jj]['matched'] == 1].shape,
                 'MS2 features', exp_out[jj][exp_out[jj]['matched'] == 0].shape)
        exp_out[jj].to_csv(
            path_or_buf=os.path.join(output_dir, os.path.split(exp_set[jj])[1].split('.')[0] + '_match.txt'), sep='\t', index=False)

        if exp_out[jj].shape[0] > 0:
            out_flag = 1 * out_flag
        else:
            out_flag = -1 * out_flag

    return out_flag


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='moFF match between run input parameter')

    parser.add_argument('--inputF', dest='loc_in', action='store',
                        help='specify the folder of the input MS2 peptide files  REQUIRED]', required=True)

    parser.add_argument('--sample', dest='sample', action='store',
                        help='specify which replicate files are used fot mbr [regular expr. are valid] ',
                        required=False)

    parser.add_argument('--ext', dest='ext', action='store', default='txt',
                        help='specify the exstension of the input file (txt as default value)', required=False)

    parser.add_argument('--log_file_name', dest='log_label', default='moFF', action='store',
                        help='a label name for the log file (moFF_mbr.log as default log file name)', required=False)

    parser.add_argument('--filt_width', dest='w_filt', action='store', default=2,
                        help='width value of the filter (k * mean(Dist_Malahobi , k = 2 as default) ', required=False)

    parser.add_argument('--out_filt', dest='out_flag', action='store', default=1,
                        help='filter outlier in each rt time allignment (active as default)', required=False)

    parser.add_argument('--weight_comb', dest='w_comb', action='store', default=0,
                        help='weights for model combination combination : 0 for no weight (default) 1 weighted devised by model errors.',
                        required=False)

    parser.add_argument('--rt_feat_file', dest='rt_feat_file', action='store',
                        help='specify the file that contains the features to use in the match-between-run RT prediction ',
                        required=False)

    args = parser.parse_args()

    w_mbr = logging.FileHandler(os.path.join(args.loc_in, args.log_label + '_mbr_.log'), mode='w')
    w_mbr.setLevel(logging.INFO)
    log.addHandler(w_mbr)

    run_mbr(args)
