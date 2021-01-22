#!/usr/bin/env python
# 
# Author: Praveen Kumar
# University of Minnesota
#
# Get peptide's genomic coordinate from the protein's genomic mapping sqlite file (which is derived from the https://toolshed.g2.bx.psu.edu/view/galaxyp/translate_bed/038ecf54cbec)
# 
# python peptideGenomicCoordinate.py <peptide_list> <mz_to_sqlite DB> <genomic mapping file DB> <output.bed>
# 
import re
import sys
import sqlite3


def main():
    conn = sqlite3.connect(sys.argv[2])
    c = conn.cursor()
    c.execute("DROP table if exists novel")
    conn.commit()
    c.execute("CREATE TABLE novel(peptide text)")
    pepfile = open(sys.argv[1],"r")
    
    pep_seq = []
    for seq in pepfile.readlines():
        seq = seq.strip()
        pep_seq.append(tuple([seq]))
    
    c.executemany("insert into novel(peptide) values(?)", pep_seq)
    conn.commit()
    
    c.execute("SELECT distinct psm.sequence, ps.id, ps.sequence from db_sequence ps, psm_entries psm, novel n, proteins_by_peptide pbp where psm.sequence = n.peptide and pbp.peptide_ref = psm.id and pbp.id = ps.id")
    rows = c.fetchall()

    conn1 = sqlite3.connect(sys.argv[3])
    c1 = conn1.cursor()

    outfh = open(sys.argv[4], "w")

    master_dict = {}
    for each in rows:
        peptide = each[0]
        acc = each[1]
        acc_seq = each[2]
    
        c1.execute("SELECT chrom,start,end,name,strand,cds_start,cds_end FROM feature_cds_map map WHERE map.name = '"+acc+"'")
        coordinates = c1.fetchall()
    
        if len(coordinates) != 0:
            pep_start = 0
            pep_end = 0
            flag = 0
            splice_flag = 0
            spliced_peptide = []
            for each_entry in coordinates:
                chromosome = each_entry[0]
                start = int(each_entry[1])
                end = int(each_entry[2])
                strand = each_entry[4]
                cds_start = int(each_entry[5])
                cds_end = int(each_entry[6])
                pep_pos_start = (acc_seq.find(re.findall(re.sub('[IL]','[IL]',peptide),acc_seq)[0])*3)
                pep_pos_end = pep_pos_start + (len(peptide)*3)
                if pep_pos_start >= cds_start and pep_pos_end <= cds_end:
                    if strand == "+":
                        pep_start = start + pep_pos_start - cds_start
                        pep_end = start + pep_pos_end - cds_start
                        pep_thick_start = 0
                        pep_thick_end = len(peptide)
                        flag == 1
                    else:
                        pep_end = end - pep_pos_start + cds_start
                        pep_start = end - pep_pos_end + cds_start
                        pep_thick_start = 0
                        pep_thick_end = len(peptide)
                        flag == 1
                    spliced_peptide = []
                    splice_flag = 0
                else:
                    if flag == 0:
                        if strand == "+":
                            if pep_pos_start >= cds_start and pep_pos_start <= cds_end and pep_pos_end > cds_end:
                                pep_start = start + pep_pos_start - cds_start
                                pep_end = end
                                pep_thick_start = 0
                                pep_thick_end = (pep_end-pep_start)
                                spliced_peptide.append([pep_start,pep_end,pep_thick_start,pep_thick_end])
                                splice_flag = splice_flag + 1
                                if splice_flag == 2:
                                    flag = 1
                            elif pep_pos_end >= cds_start and pep_pos_end <= cds_end and pep_pos_start < cds_start:
                                pep_start = start
                                pep_end = start + pep_pos_end - cds_start
                                pep_thick_start = (len(peptide)*3)-(pep_end-pep_start)
                                pep_thick_end = (len(peptide)*3)
                                spliced_peptide.append([pep_start,pep_end,pep_thick_start,pep_thick_end])
                                splice_flag = splice_flag + 1
                                if splice_flag == 2:
                                    flag = 1
                            else:
                                pass
                        else:
                            if pep_pos_start >= cds_start and pep_pos_start <= cds_end and pep_pos_end >= cds_end:
                                pep_start = start
                                pep_end = end - pep_pos_start - cds_start
                                pep_thick_start = 0
                                pep_thick_end = (pep_end-pep_start)
                                spliced_peptide.append([pep_start,pep_end,pep_thick_start,pep_thick_end])
                                splice_flag = splice_flag + 1
                                if splice_flag == 2:
                                    flag = 1
                            elif pep_pos_end >= cds_start and pep_pos_end <= cds_end and pep_pos_start <= cds_start:
                                pep_start = end - pep_pos_end + cds_start
                                pep_end = end
                                pep_thick_start = (len(peptide)*3)-(pep_end-pep_start)
                                pep_thick_end = (len(peptide)*3)
                                spliced_peptide.append([pep_start,pep_end,pep_thick_start,pep_thick_end])
                                splice_flag = splice_flag + 1
                                if splice_flag == 2:
                                    flag = 1
                            else:
                                pass

            if len(spliced_peptide) == 0:
                if strand == "+":
                    bed_line = [chromosome, str(pep_start), str(pep_end), peptide, "255", strand, str(pep_start), str(pep_end), "0", "1", str(pep_end-pep_start), "0"]
                else:
                    bed_line = [chromosome, str(pep_start), str(pep_end), peptide, "255", strand, str(pep_start), str(pep_end), "0", "1", str(pep_end-pep_start), "0"]
                outfh.write("\t".join(bed_line)+"\n")
            else:
                if strand == "+":
                    pep_entry = spliced_peptide
                    pep_start = min([pep_entry[0][0], pep_entry[1][0]])
                    pep_end = max([pep_entry[0][1], pep_entry[1][1]])
                    blockSize = [str(min([pep_entry[0][3], pep_entry[1][3]])),str(max([pep_entry[0][3], pep_entry[1][3]])-min([pep_entry[0][3], pep_entry[1][3]]))]
                    blockStarts = ["0", str(pep_end-pep_start-(max([pep_entry[0][3], pep_entry[1][3]])-min([pep_entry[0][3], pep_entry[1][3]])))]
                    bed_line = [chromosome, str(pep_start), str(pep_end), peptide, "255", strand, str(pep_start), str(pep_end), "0", "2", ",".join(blockSize), ",".join(blockStarts)]
                    outfh.write("\t".join(bed_line)+"\n")
                else:
                    pep_entry = spliced_peptide
                    pep_start = min([pep_entry[0][0], pep_entry[1][0]])
                    pep_end = max([pep_entry[0][1], pep_entry[1][1]])
                    blockSize = [str(min([pep_entry[0][3], pep_entry[1][3]])),str(max([pep_entry[0][3], pep_entry[1][3]])-min([pep_entry[0][3], pep_entry[1][3]]))]
                    blockStarts = ["0", str(pep_end-pep_start-(max([pep_entry[0][3], pep_entry[1][3]])-min([pep_entry[0][3], pep_entry[1][3]])))]
                    bed_line = [chromosome, str(pep_start), str(pep_end), peptide, "255", strand, str(pep_start), str(pep_end), "0", "2", ",".join(blockSize), ",".join(blockStarts)]
                    outfh.write("\t".join(bed_line)+"\n")
    c.execute("DROP table novel")
    conn.commit()
    conn.close()
    conn1.close()
    outfh.close()
    pepfile.close()
    
    return None
if __name__ == "__main__":
    main()
