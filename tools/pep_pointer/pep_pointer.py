
#
# Author: Praveen Kumar
# Updated: April 6th, 2018 (updated to python3: May 2022)
#
#
#

import re


def main():
    import sys
    if len(sys.argv) == 4:
        inputFile = sys.argv
        infh = open(inputFile[1], "r")
        # infh = open("Mus_musculus.GRCm38.90.chr.gtf", "r")

        gtf = {}
        gtf_transcript = {}
        gtf_gene = {}
        for each in infh.readlines():
            a = each.split("\t")
            if re.search("^[^#]", each):
                if re.search("gene_biotype \"protein_coding\"", a[8]) and int(a[4].strip()) != int(a[3].strip()):
                    type = a[2].strip()
                    if type == "gene" or type == "exon" or type == "CDS" or type == "five_prime_utr" or type == "three_prime_utr":
                        chr = "chr" + a[0].strip()
                        strand = a[6].strip()
                        if strand == "+":
                            start = a[3].strip()
                            end = a[4].strip()
                        elif strand == "-":
                            if int(a[4].strip()) > int(a[3].strip()):
                                start = a[3].strip()
                                end = a[4].strip()
                            elif int(a[4].strip()) < int(a[3].strip()):
                                start = a[4].strip()
                                end = a[3].strip()
                            else:
                                print("Please check the start end coordinates in the GTF file")
                        else:
                            print("Please check the strand information in the GTF file. It should be '+' or '-'.")
                        if strand not in gtf:
                            gtf[strand] = {}
                        if type not in gtf[strand]:
                            gtf[strand][type] = []
                        b = re.search("gene_id \"(.+?)\";", a[8].strip())
                        gene = b.group(1)
                        if type == "gene":
                            transcript = ""
                        else:
                            b = re.search("transcript_id \"(.+?)\";", a[8].strip())
                            transcript = b.group(1)
                        data = (chr, start, end, gene, transcript, strand, type)
                        gtf[strand][type].append(data)

                        if type == "exon":
                            if chr + "#" + strand in gtf_transcript:
                                if transcript + "#" + gene in gtf_transcript[chr + "#" + strand]:
                                    gtf_transcript[chr + "#" + strand][transcript + "#" + gene][0].append(int(start))
                                    gtf_transcript[chr + "#" + strand][transcript + "#" + gene][1].append(int(end))
                                else:
                                    gtf_transcript[chr + "#" + strand][transcript + "#" + gene] = [[], []]
                                    gtf_transcript[chr + "#" + strand][transcript + "#" + gene][0].append(int(start))
                                    gtf_transcript[chr + "#" + strand][transcript + "#" + gene][1].append(int(end))
                            else:
                                gtf_transcript[chr + "#" + strand] = {}
                                gtf_transcript[chr + "#" + strand][transcript + "#" + gene] = [[], []]
                                gtf_transcript[chr + "#" + strand][transcript + "#" + gene][0].append(int(start))
                                gtf_transcript[chr + "#" + strand][transcript + "#" + gene][1].append(int(end))

                        if type == "gene":
                            if chr + "#" + strand in gtf_gene:
                                gtf_gene[chr + "#" + strand][0].append(int(start))
                                gtf_gene[chr + "#" + strand][1].append(int(end))
                                gtf_gene[chr + "#" + strand][2].append(gene)
                            else:
                                gtf_gene[chr + "#" + strand] = [[0], [0], ["no_gene"]]
                                gtf_gene[chr + "#" + strand][0].append(int(start))
                                gtf_gene[chr + "#" + strand][1].append(int(end))
                                gtf_gene[chr + "#" + strand][2].append(gene)

        # "Starting Reading Intron . . ."

        gtf["+"]["intron"] = []
        gtf["-"]["intron"] = []
        for chr_strand in gtf_transcript.keys():
            chr = chr_strand.split("#")[0]
            strand = chr_strand.split("#")[1]

            for transcript_gene in gtf_transcript[chr_strand].keys():
                start_list = gtf_transcript[chr_strand][transcript_gene][0]
                end_list = gtf_transcript[chr_strand][transcript_gene][1]
                sorted_start_index = [i[0] for i in sorted(enumerate(start_list), key=lambda x:x[1])]
                sorted_end_index = [i[0] for i in sorted(enumerate(end_list), key=lambda x:x[1])]
                if sorted_start_index == sorted_end_index:
                    sorted_start = sorted(start_list)
                    sorted_end = [end_list[i] for i in sorted_start_index]
                    for x in range(len(sorted_start))[1:]:
                        intron_start = sorted_end[x - 1] + 1
                        intron_end = sorted_start[x] - 1
                        transcript = transcript_gene.split("#")[0]
                        gene = transcript_gene.split("#")[1]
                        data = (chr, str(intron_start), str(intron_end), gene, transcript, strand, "intron")
                        gtf[strand]["intron"].append(data)

        # "Starting Reading Intergenic . . ."

        gtf["+"]["intergenic"] = []
        gtf["-"]["intergenic"] = []
        for chr_strand in gtf_gene.keys():
            chr = chr_strand.split("#")[0]
            strand = chr_strand.split("#")[1]
            start_list = gtf_gene[chr_strand][0]
            end_list = gtf_gene[chr_strand][1]
            gene_list = gtf_gene[chr_strand][2]
            sorted_start_index = [i[0] for i in sorted(enumerate(start_list), key=lambda x:x[1])]
            sorted_end_index = [i[0] for i in sorted(enumerate(end_list), key=lambda x:x[1])]

            sorted_start = sorted(start_list)
            sorted_end = [end_list[i] for i in sorted_start_index]
            sorted_gene = [gene_list[i] for i in sorted_start_index]
            for x in range(len(sorted_start))[1:]:
                intergene_start = sorted_end[x - 1] + 1
                intergene_end = sorted_start[x] - 1
                if intergene_start < intergene_end:
                    intergene_1 = sorted_gene[x - 1]
                    intergene_2 = sorted_gene[x]
                    gene = intergene_1 + "-#-" + intergene_2
                    data = (chr, str(intergene_start), str(intergene_end), gene, "", strand, "intergenic")
                    gtf[strand]["intergenic"].append(data)

        import sqlite3
        # conn = sqlite3.connect('gtf_database.db')
        conn = sqlite3.connect(":memory:")
        c = conn.cursor()
        # c.execute("DROP TABLE IF EXISTS gtf_data;")
        # c.execute("CREATE TABLE IF NOT EXISTS gtf_data(chr text, start int, end int, gene text, transcript text, strand text, type text)")
        c.execute("CREATE TABLE gtf_data(chr text, start int, end int, gene text, transcript text, strand text, type text)")

        for strand in gtf.keys():
            if strand not in ["+", "-"]:
                print("Please check the strand information in the GTF file. It should be '+' or '-'.")

            for type in gtf[strand].keys():
                data = gtf[strand][type]
                c.executemany('INSERT INTO gtf_data VALUES (?,?,?,?,?,?,?)', data)

        conn.commit()

        infh = open(inputFile[2], "r")
        # infh = open("Mouse_Data_All_peptides_withNewDBs.txt", "r")
        data = infh.readlines()
        # output file
        outfh = open(inputFile[3], 'w')
        # outfh = open("classified_1_Mouse_Data_All_peptides_withNewDBs.txt", "w")

        for each in data:
            a = each.strip().split("\t")
            chr = a[0].strip()
            pep_start = str(int(a[1].strip()) + 1)
            pep_end = a[2].strip()
            strand = a[5].strip()
            each = "\t".join(a[:6])
            if (len(a) == 12 and int(a[9]) == 1) or (len(a) == 6):
                c.execute("select * from gtf_data where type = 'CDS' and chr = '" + chr + "' and start <= " + pep_start + " and end >= " + pep_end + " and strand = '" + strand + "' ")
                rows = c.fetchall()
                if len(rows) > 0:
                    outfh.write(each.strip() + "\tCDS\n")
                else:
                    c.execute("select * from gtf_data where type = 'five_prime_utr' and chr = '" + chr + "' and start <= " + pep_start + " and end >= " + pep_end + " and strand = '" + strand + "' ")
                    rows = c.fetchall()
                    if len(rows) > 0:
                        outfh.write(each.strip() + "\tfive_prime_utr\n")
                    else:
                        c.execute("select * from gtf_data where type = 'three_prime_utr' and chr = '" + chr + "' and start <= " + pep_start + " and end >= " + pep_end + " and strand = '" + strand + "' ")
                        rows = c.fetchall()
                        if len(rows) > 0:
                            outfh.write(each.strip() + "\tthree_prime_utr\n")
                        else:
                            c.execute("select * from gtf_data where type = 'exon' and chr = '" + chr + "' and start <= " + pep_start + " and end >= " + pep_end + " and strand = '" + strand + "' ")
                            rows = c.fetchall()
                            if len(rows) > 0:
                                outfh.write(each.strip() + "\texon\n")
                            else:
                                c.execute("select * from gtf_data where type = 'intron' and chr = '" + chr + "' and start <= " + pep_start + " and end >= " + pep_end + " and strand = '" + strand + "' ")
                                rows = c.fetchall()
                                if len(rows) > 0:
                                    outfh.write(each.strip() + "\tintron\n")
                                else:
                                    c.execute("select * from gtf_data where type = 'gene' and chr = '" + chr + "' and start <= " + pep_start + " and end >= " + pep_end + " and strand = '" + strand + "' ")
                                    rows = c.fetchall()
                                    if len(rows) > 0:
                                        outfh.write(each.strip() + "\tgene\n")
                                    else:
                                        c.execute("select * from gtf_data where type = 'intergenic' and chr = '" + chr + "' and start <= " + pep_start + " and end >= " + pep_end + " and strand = '" + strand + "' ")
                                        rows = c.fetchall()
                                        if len(rows) > 0:
                                            outfh.write(each.strip() + "\tintergene\n")
                                        else:
                                            outfh.write(each.strip() + "\tOVERLAPPING_ON_TWO_REGIONS: PLEASE_LOOK_MANUALLY (Will be updated in next version)\n")
            elif (len(a) == 12 and int(a[9]) == 2):
                outfh.write(each.strip() + "\tSpliceJunction\n")
            else:
                outfh.write(each.strip() + "\tPlease check\n")

        conn.close()
        outfh.close()
    else:
        print("USAGE: python pep_pointer.py <input GTF file> <input tblastn file> <name of output file>")
    return None


if __name__ == "__main__":
    main()
