#!/usr/bin/env python

import ConfigParser
import argparse
import ast
import bisect
import glob
import logging
import multiprocessing
import os as os
import shlex
import subprocess
import sys
import time
import traceback
from sys import platform as _platform

import numpy as np
import pandas as pd
import pymzml
import simplejson as json

log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)


"""
 input
   - MS2 ID file
   - tol
   - half rt time window in minute
 output
   - list of intensities..+
"""

TXIC_PATH = os.environ.get('TXIC_PATH', './')


def compute_peptide_matrix(loc_output, log, tag_filename):
	name_col = []
	name_col.append('prot')
	d = []
	if not glob.glob(loc_output + '/*_moff_result.txt'):
		return -1
	for name in glob.glob(loc_output + '/*_moff_result.txt'):

		if 'match_' in os.path.basename(name):
			name_col.append('sumIntensity_' + os.path.basename(name).split('_match_moff_result.txt')[0])
		else:
			name_col.append('sumIntensity_' + os.path.basename(name).split('_moff_result.txt')[0])
		data = pd.read_csv(name, sep="\t")

		'''
		Other possibile quality controll filter
		data = data[ data['lwhm'] != -1]
		data = data[data['rwhm'] != -1 ]
		
		'''
		data = data[data['intensity'] != -1]
		data.sort_values('rt', ascending=True, inplace=True)
		log.critical('Collecting moFF result file : %s   --> Retrived peptide peaks after filtering:  %i',
					 os.path.basename(name), data.shape[0])
		# cleaning peptide fragmented more than one time. we keep the earliest one
		data.drop_duplicates(subset=['prot', 'peptide', 'mod_peptide', 'mass', 'charge'], keep='first', inplace=True)
		d.append(data[['prot', 'peptide', 'mod_peptide', 'mass', 'charge', 'rt_peak', 'rt', 'intensity']])

	intersect_share = reduce(np.union1d, ([x['peptide'].unique() for x in d]))
	index = intersect_share

	df = pd.DataFrame(index=index, columns=name_col)
	df = df.fillna(0)
	for i in range(0, len(d)):
		grouped = d[i].groupby('peptide', as_index=True)['prot', 'intensity']
		# print grouped.agg({'prot':'max', 'intensity':'sum'}).columns
		df.ix[:, i + 1] = grouped.agg({'prot': 'max', 'intensity': 'sum'})['intensity']
		df.ix[np.intersect1d(df.index, grouped.groups.keys()), 0] = grouped.agg({'prot': 'max', 'intensity': 'sum'})[
			'prot']
	# print df.head(5)
	df.reset_index(level=0, inplace=True)
	df = df.fillna(0)
	df.rename(columns={'index': 'peptide'}, inplace=True)
	log.critical('Writing peptide_summary intensity file')
	df.to_csv(os.path.join(loc_output, "peptide_summary_intensity_" + tag_filename + ".tab"), sep='\t', index=False)
	return 1


def save_moff_apex_result(list_df, result, folder_output, name):
	#print len(list_df)
	try:
		xx = []
		for df_index in range(0,len(list_df)):
			if result[df_index].get()[1] == -1:
				exit ('Raw file not retrieved: wrong path or upper/low case mismatch')
			else:
				#print result[df_index].get()[0]
				xx.append( result[df_index].get()[0] )

		#print len(xx)

		final_res = pd.concat(xx)
		if 'index' in final_res.columns:
			final_res.drop('index',axis=1,inplace=True )
		final_res.to_csv(os.path.join(folder_output, os.path.basename(name).split('.')[0] + "_moff_result.txt"), sep="\t",index=False)
	except Exception as e :
		traceback.print_exc()
		print
		# print os.path.join(folder_output,os.path.basename(name).split('.')[0]  + "_moff_result.txt")
		raise e
	return (1)



def map_ps2moff(data,type_mapping):
	data.drop(data.columns[[0]], axis=1, inplace=True)
	data.columns = data.columns.str.lower()
	if type_mapping == 'col_must_have_mbr':
		data.rename(columns={'sequence': 'peptide', 'modified sequence': 'mod_peptide', 'measured charge': 'charge',
		                     'theoretical mass': 'mass', 'protein(s)': 'prot', 'm/z': 'mz'}, inplace=True)
	if type_mapping == 'col_must_have_apex':
		data.rename(columns={'sequence': 'peptide', 'measured charge': 'charge', 'theoretical mass': 'mass',
		                     'protein(s)': 'prot', 'm/z': 'mz'}, inplace=True)
	return data, data.columns.values.tolist()




'''
input list of columns
list of column names from PS default template loaded from .properties
'''

def check_ps_input_data(input_column_name, list_col_ps_default):
	input_column_name.sort()
	list_col_ps_default.sort()
	if list_col_ps_default == input_column_name:
		# detected a default PS input file
		return 1
	else:
		# not detected a default PS input file
		return 0


def check_columns_name(col_list, col_must_have):
	for c_name in col_must_have:
		if not (c_name in col_list):
			# fail
			print 'The following filed name is missing or wrong: ', c_name
			return 1
	# succes
	return 0


def scan_mzml ( name ):
# when I am using thermo raw and --raw_repo option used
	if name is None:
		return (-1,-1)
	if ('MZML' in name.upper()):

		rt_list = []
		runid_list = []
		run_temp = pymzml.run.Reader( name )
		for spectrum in run_temp:
			if spectrum['ms level'] == 1:
				rt_list.append(spectrum['scan start time'])
				runid_list.append(spectrum['id'])

		return (rt_list,runid_list )
	else:
		# in case of raw file  I put to -1 -1 thm result
		return (-1,-1 )


def  mzML_get_all( temp,tol,loc,run,   rt_list1, runid_list1 ):
	app_list=[]
	for index_ms2, row in temp.iterrows():
		
		data, status=pyMZML_xic_out(loc, float(tol / (10 ** 6)), row['ts'], row['te'], row['mz'],run, runid_list1,rt_list1 )
		# status is evaluated only herenot used anymore
		if status != -1 :
			app_list.append(data)
		else:
			app_list.append(pd.DataFrame(columns=['rt','intensity']))
	return app_list



def pyMZML_xic_out(name, ppmPrecision, minRT, maxRT, MZValue,run, runid_list,rt_list ):
	timeDependentIntensities = []
	minpos = bisect.bisect_left(rt_list, minRT)
	maxpos = bisect.bisect_left(rt_list, maxRT)

	for specpos in range(minpos,maxpos):
		specid = runid_list[specpos]
		spectrum = run[specid]
		if spectrum['scan start time'] > maxRT:
			break
		if spectrum['scan start time'] > minRT and spectrum['scan start time'] < maxRT:
			#print 'in ', specid
			lower_index = bisect.bisect(spectrum.peaks, (float(MZValue - ppmPrecision * MZValue), None))
			upper_index = bisect.bisect(spectrum.peaks, (float(MZValue + ppmPrecision * MZValue), None))
			maxI = 0.0
			for sp in spectrum.peaks[lower_index: upper_index]:
				if sp[1] > maxI:
					maxI = sp[1]
			if maxI > 0:
				timeDependentIntensities.append([spectrum['scan start time'], maxI])

	if len(timeDependentIntensities) > 5:
		return (pd.DataFrame(timeDependentIntensities, columns=['rt', 'intensity']), 1)
	else:
		return (pd.DataFrame(timeDependentIntensities, columns=['rt', 'intensity']), -1)

def check_log_existence(file_to_check):
	if os.path.isfile(file_to_check):
		os.remove(file_to_check)
		return 1
	else:
		return -1


def check_output_folder_existence(loc_output ):
   if not os.path.exists(loc_output):
	os.mkdir(loc_output)
	return 1
   else:
	return 0

def compute_log_LR (data_xic,index,v_max):
	log_time = [-1, -1]
	c_left = 0
	find_5 = False
	stop = False
	while c_left < (index - 1) and not stop:
		if not find_5 and ( data_xic.ix[(index - 1) - c_left, 1] <= (0.5 * v_max)):
			find_5 = True
			log_time[0] = data_xic.ix[(index - 1) - c_left, 0] * 60
			stop = True
		c_left += 1
	find_5 = False
	stop = False
	r_left = 0
	while ((index + 1) + r_left <  data_xic.shape[0] ) and not stop:
		if not find_5 and data_xic.ix[(index + 1) + r_left, 1] <= (0.50 * v_max):
			find_5 = True
			log_time[1] = data_xic.ix[(index + 1) + r_left, 0] * 60
			stop = True
		r_left += 1
	return log_time





def compute_peak_simple(x,xic_array,log,mbr_flag, h_rt_w,s_w,s_w_match,offset_index):
	c = x.name
	data_xic = xic_array[c]
	time_w= x['rt'] /60
	if mbr_flag == 0:
		log.info('peptide at line %i -->  MZ: %4.4f RT: %4.4f',(offset_index +c +2), x['mz'], time_w)
		temp_w = s_w
	else:
		log.info('peptide at line %i -->  MZ: %4.4f RT: %4.4f matched (yes=1/no=0): %i',(offset_index + c +2), x['mz'], time_w,x['matched'])
					# row['matched'])
		if x['matched'] == 1:
			temp_w = s_w_match
		else:
			temp_w = s_w
	if data_xic[(data_xic['rt'] > (time_w - temp_w)) & (data_xic['rt'] < (time_w + temp_w))].shape[0] >= 1:
		#data_xic[(data_xic['rt'] > (time_w - temp_w)) & (data_xic['rt'] < (time_w + temp_w))].to_csv('thermo_testXIC_'+str(c)+'.txt',index=False,sep='\t')
		ind_v = data_xic.index
		pp = data_xic[data_xic["intensity"] == data_xic[(data_xic['rt'] > (time_w - temp_w)) & (data_xic['rt'] < (time_w + temp_w))]['intensity'].max()].index
		pos_p = ind_v[pp]
		if pos_p.values.shape[0] > 1:
			print 'error'
			return pd.Series({'intensity': -1, 'rt_peak': -1,'lwhm':-1,'rwhm':-1,'5p_noise':-1,'10p_noise':-1,'SNR':-1,'log_L_R':-1,'log_int':-1})
		val_max = data_xic.ix[pos_p, 1].values
	else:
		log.info('peptide at line %i -->  MZ: %4.4f RT: %4.4f ', (offset_index +c +2), x['mz'], time_w)
		log.info("\t LW_BOUND window  %4.4f", time_w - temp_w)
		log.info("\t UP_BOUND window %4.4f", time_w + temp_w)
		log.info("\t WARNINGS: moff_rtWin_peak is not enough to detect the max peak ")

		return  pd.Series({'intensity': -1, 'rt_peak': -1,
				   'lwhm':-1,
					'rwhm':-1,
					'5p_noise':-1,
					'10p_noise':-1,
					'SNR':-1,
					'log_L_R':-1,
					'log_int':-1})
	pnoise_5 = np.percentile(data_xic[(data_xic['rt'] > (time_w - h_rt_w )) & (data_xic['rt'] < (time_w + h_rt_w ))]['intensity'], 5 )
	pnoise_10 = np.percentile( data_xic[(data_xic['rt'] > (time_w - h_rt_w )) & (data_xic['rt'] < (time_w + h_rt_w)  )]['intensity'], 10)
	# find the lwhm and rwhm
	time_point =  compute_log_LR (data_xic,pos_p[0],val_max)
	if time_point[0]== -1 or  time_point[1] ==-1:
		# keep the shape measure to -1
		log_L_R=-1
	else:
			log_L_R= np.log2(abs( time_w  - time_point[0]) / abs( time_w - time_point[1]))
	
	if (pnoise_5 == 0 and pnoise_10 > 0):
				SNR  = 20 * np.log10(data_xic.ix[pos_p, 1].values / pnoise_10)
	else:
		if pnoise_5 != 0:
				SNR = 20 * np.log10(data_xic.ix[pos_p, 1].values / pnoise_5)
		else:
				log.info('\t 5 percentile is %4.4f (added 0.5)', pnoise_5)
				SNR = 20 * np.log10(data_xic.ix[pos_p, 1].values / (pnoise_5 +0.5))
	
	return pd.Series({'intensity': val_max[0], 'rt_peak': data_xic.ix[pos_p, 0].values[0] * 60,
			   'lwhm': time_point[0] ,
				'rwhm': time_point[1] ,
				'5p_noise': pnoise_5,
				'10p_noise':pnoise_10,
				'SNR':SNR[0],
				'log_L_R': log_L_R,
				'log_int': np.log2(val_max)[0] })




def apex_multithr(data_ms2,name_file, raw_name, tol, h_rt_w, s_w, s_w_match, loc_raw, loc_output,offset_index,  rt_list , id_list ):
	#setting logger for multiprocess
	ch = logging.StreamHandler()
	ch.setLevel(logging.ERROR)
	log.addHandler(ch)

	#setting flag and ptah
	moff_path = os.path.dirname(sys.argv[0])
	flag_mzml = False
	flag_windows = False
	mbr_flag = 0

	# set platform
	if _platform in ["linux", "linux2", 'darwin']:
		flag_windows = False
	elif _platform == "win32":
		flag_windows = True


	# check output log file in right location
	if loc_output != '':
		if not (os.path.isdir(loc_output)):
			os.makedirs(loc_output)
			log.info("created output folder: ", loc_output)

	# to be checked if it is works ffor both caseses
	fh = logging.FileHandler(os.path.join(loc_output, name_file + '__moff.log'), mode='a')

	fh.setLevel(logging.INFO)
	log.addHandler(fh)

	# check mbr input file
	if '_match' in name_file:
		# in case of mbr , here i dont have evaluate the flag mbr
		start = name_file.find('_match')
		# extract the name of the file
		name_file = name_file[0:start]

	if loc_raw is not None:
		if flag_windows:
		   loc  = os.path.join(loc_raw, name_file.upper()+ '.RAW')

		else:
			# raw file name must have capitals letters :) this shloud be checked
			# this should be done in moe elegant way

			loc  = os.path.normcase(os.path.join(loc_raw, name_file + '.RAW'))

			if not (os.path.isfile(loc)):
				loc  = os.path.join(loc_raw, name_file + '.raw')

	else:
		#mzML work only with --inputraw option
		loc  = raw_name
		if ('MZML' in raw_name.upper()):
			flag_mzml = True

	if os.path.isfile(loc):
		log.info('raw file exist')
	else:
		#exit('ERROR: Wrong path or wrong raw file name included: %s' % loc  )
		log.info('ERROR: Wrong path or wrong raw file name included: %s' % loc  )
		return (None,-1)



	index_offset = data_ms2.columns.shape[0] - 1

	data_ms2["intensity"] = -1
	data_ms2["rt_peak"] = -1
	data_ms2["lwhm"] = -1
	data_ms2["rwhm"] = -1
	data_ms2["5p_noise"] = -1
	data_ms2["10p_noise"] = -1
	data_ms2["SNR"] = -1
	data_ms2["log_L_R"] = -1
	data_ms2["log_int"] = -1
	data_ms2["rt_peak"] = data_ms2["rt_peak"].astype('float64')
	data_ms2['intensity'] = data_ms2['intensity'].astype('float64')
	data_ms2['lwhm'] = data_ms2['lwhm'].astype('float64')
	data_ms2["rwhm"] = data_ms2['rwhm'].astype('float64')
	data_ms2["5p_noise"] = data_ms2['5p_noise'].astype('float64')
	data_ms2["10p_noise"] = data_ms2['10p_noise'].astype('float64')
	data_ms2["SNR"] = data_ms2['SNR'].astype('float64')
	data_ms2["log_L_R"] = data_ms2['log_L_R'].astype('float64')
	data_ms2["log_int"] = data_ms2['log_int'].astype('float64')



	# set mbr_flag
	if 'matched' in data_ms2.columns:
		mbr_flag = 1
		#log.critical('Apex module has detected mbr peptides')
		#log.info('moff_rtWin_peak for matched peptide:   %4.4f ', s_w_match)

	# get txic path: assumes txic is in the same directory as moff.py
	txic_executable_name="txic_json.exe"
	txic_path = os.path.join(os.path.dirname(os.path.realpath(sys.argv[0])), txic_executable_name)

	## to export a list of XIc
	try:
		temp=data_ms2[['mz','rt']].copy()
	# strange cases

		temp.ix[:,'tol'] = int( tol)
		temp['ts'] = (data_ms2['rt'] /60 ) - h_rt_w
		temp['te'] = (data_ms2['rt']  /60 ) + h_rt_w
		temp.drop('rt',1,inplace=True )
		if not flag_mzml :
			# txic-28-9-separate-jsonlines.exe
			if not flag_windows:
				args_txic = shlex.split( "mono " + txic_path + " -j " + temp.to_json( orient='records' ) + " -f " + loc,posix=True )
			else:
				args_txic = shlex.split(txic_path + " -j " + temp.to_json(orient='records') + " -f " + loc, posix=False)
			start_timelocal = time.time()
			p = subprocess.Popen(args_txic, stdout=subprocess.PIPE)
			output, err = p.communicate()
			xic_data=[]
			for l in range ( 0,temp.shape[0] ) :
					temp = json.loads( output.split('\n')[l].decode("utf-8") )
					xic_data.append(pd.DataFrame( { 'rt' : temp['results']['times'], 'intensity':  temp['results']['intensities'] }   , columns=['rt', 'intensity'] ) )
		else:
			run_temp = pymzml.run.Reader(raw_name)
			xic_data =  mzML_get_all( temp,tol,loc, run_temp ,rt_list , id_list  )
			#10p_noise    5p_noise  SNR     intensity  log_L_R    log_int  lwhm rt_peak  rwhm
		data_ms2.reset_index(inplace=True)
		data_ms2[['10p_noise','5p_noise','SNR','intensity','log_L_R','log_int' ,'lwhm','rt_peak','rwhm']] = data_ms2.apply(lambda x : compute_peak_simple( x,xic_data ,log,mbr_flag ,h_rt_w,s_w,s_w_match,offset_index) , axis=1   )
	except Exception as e:
		traceback.print_exc()
		print
		raise e

	return  (data_ms2,1)


def main_apex_alone():
	parser = argparse.ArgumentParser(description='moFF input parameter')
	parser.add_argument('--inputtsv', dest='name', action='store',
						help='specify the input file with the MS2 peptides/features', required=True)
	parser.add_argument('--inputraw', dest='raw_list', action='store', help='specify directly raw file', required=False)
	parser.add_argument('--tol', dest='toll', action='store', type=float, help='specify the tollerance parameter in ppm',
						required=True)
	parser.add_argument('--rt_w', dest='rt_window', action='store', type=float, default=3,
						help='specify rt window for xic (minute). Default value is 3 min', required=False)
	parser.add_argument('--rt_p', dest='rt_p_window', action='store', type=float, default=1,
						help='specify the time windows for the peak ( minute). Default value is 1 minute ', required=False)
	parser.add_argument('--rt_p_match', dest='rt_p_window_match', action='store', type=float, default=1.2,
						help='specify the time windows for the matched  peak ( minute). Default value is 1.2 minute ',
						required=False)
	parser.add_argument('--raw_repo', dest='raw', action='store', help='specify the raw file repository folder',
						required=False)
	parser.add_argument('--output_folder', dest='loc_out', action='store', default='', help='specify the folder output',
						required=False)
	parser.add_argument('--peptide_summary', dest='pep_matrix', action='store', type=int, default=0, help='summarize all the peptide intesity in one tab-delited file ',required=False)

	parser.add_argument('--tag_pep_sum_file', dest='tag_pepsum', action='store', type=str, default='moFF_run', help='a tag that is used in the peptide summary file name', required=False)


	args = parser.parse_args()

	if (args.raw_list is None) and (args.raw is None):
		exit('you must specify and raw files  with --inputraw (file name) or --raw_repo (folder)')
	if (args.raw_list is not None) and (args.raw is not None):
		exit('you must specify raw files using only one options --inputraw (file name) or --raw_repo (folder) ')


	file_name = args.name
	tol = args.toll
	h_rt_w = args.rt_window
	s_w = args.rt_p_window
	s_w_match = args.rt_p_window_match

	loc_raw = args.raw
	loc_output = args.loc_out
	# set stream option for logger
	ch = logging.StreamHandler()
	ch.setLevel(logging.ERROR)
	log.addHandler(ch)

	config = ConfigParser.RawConfigParser()
	config.read(os.path.join(os.path.dirname(os.path.realpath(sys.argv[0])), 'moff_setting.properties'))

	df = pd.read_csv(file_name, sep="\t")
	#df = df.ix[0:100,:]
	## check and eventually tranf for PS template
	if not 'matched' in df.columns:
		# check if it is a PS file ,
		list_name = df.columns.values.tolist()
		# get the lists of PS  defaultcolumns from properties file
		list = ast.literal_eval(config.get('moFF', 'ps_default_export_v1'))
		# here it controls if the input file is a PS export; if yes it maps the input in right moFF name
		if check_ps_input_data(list_name, list) == 1:
			# map  the columns name according to moFF input requirements
			if args.pep_matrix != 1:
				data_ms2, list_name = map_ps2moff(df,'col_must_have_apex')
			else:
				data_ms2, list_name = map_ps2moff(df, 'col_must_have_mbr')
	## check if the field names are good, in case of pep summary we need same req as in  mbr
	if args.pep_matrix == 1:
		if  check_columns_name(df.columns.tolist(), ast.literal_eval(config.get('moFF', 'col_must_have_mbr'))) == 1 :
			exit('ERROR minimal field requested are missing or wrong')
	else:
		if  check_columns_name(df.columns.tolist(), ast.literal_eval(config.get('moFF', 'col_must_have_apex'))) == 1 :
			exit('ERROR minimal field requested are missing or wrong')

	log.critical('moff Input file: %s  XIC_tol %s XIC_win %4.4f moff_rtWin_peak %4.4f ' % (file_name, tol, h_rt_w, s_w))
	if args.raw_list is None:
		log.critical('RAW file from folder :  %s' % loc_raw)
	else:
		log.critical('RAW file  :  %s' % args.raw_list)

	log.critical('Output file in :  %s', loc_output)

	# multiprocessing.cpu_count()
	data_split = np.array_split(df,  multiprocessing.cpu_count()  )

	##--used for test
	#data_split = np.array_split(df, 1)
	#print data_split[0].shape
	##used for test
	log.critical('Starting Apex  .....')
	name = os.path.basename(file_name).split('.')[0]

	check_output_folder_existence(loc_output )

	##check the existencce of the log file before to go to multiprocess
	check_log_existence(os.path.join(loc_output, name + '__moff.log'))

	rt_list , id_list = scan_mzml ( args.raw_list )

	#multiprocessing.cpu_count()
	myPool = multiprocessing.Pool(  multiprocessing.cpu_count()   )
	## code below id for testing
	#myPool = multiprocessing.Pool(10 )
	## end testing
	result = {}
	offset = 0
	start_time = time.time()
	for df_index in range(0, len(data_split)):
		result[df_index] = myPool.apply_async(apex_multithr, args=(
		data_split[df_index], name, args.raw_list, tol, h_rt_w, s_w, s_w_match, loc_raw, loc_output, offset,  rt_list , id_list ))
		offset += len(data_split[df_index])

	myPool.close()
	myPool.join()
	log.critical('...apex terminated')
	log.critical( 'Computational time (sec):  %4.4f ' % (time.time() -start_time))
	print 'Time no result collect',  time.time() -start_time
	start_time_2 = time.time()
	save_moff_apex_result(data_split, result, loc_output, file_name)
	#print 'Time no result collect 2',  time.time() -start_time_2
	if args.pep_matrix == 1 :
		# # TO DO manage the error with retunr -1 like in moff_all.py  master repo
		state = compute_peptide_matrix(loc_output,log,args.tag_pepsum)
		if state ==-1 :
			log.critical ('Error during the computation of the peptide intensity summary file: Check the output folder that contains the moFF results file')

if __name__ == '__main__':
	main_apex_alone()
