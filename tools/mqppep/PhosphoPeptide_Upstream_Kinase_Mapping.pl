#!/usr/local/bin/perl
###############################################################################################################################
#    perl Kinase_enrichment_analysis_complete_v0.pl
#
#    Nick Graham, USC
#    2016-02-27
#
#    Built from scripts written by NG at UCLA in Tom Graeber's lab:
#        CombinePhosphoSites.pl
#        Retrieve_p_motifs.pl
#        NetworKIN_Motif_Finder_v7.pl
#
#    Given a list of phospho-peptides, find protein information and upstream kinases.
#    Output file can be used for KS enrichment score calculations using Enrichment_Score4Directory.pl
#
#    Updated 2022-01-13, Art Eschenlauer, UMN on behalf of Justin Drake's lab:
#        Added warnings and used strict;
#        fixed some code paths resulting in more NetworKIN matches;
#        applied Aho-Corasick algorithm (via external Python script because Perl implementation was still too slow)
#        to speed up "Match the non_p_peptides to the @sequences array";
#        added support for SQLite-formatted UniProtKB/Swiss-Prot data as an alternative to FASTA-formatted data;
#        added support for SQLite output in addition to tabular files.
#
#
###############################################################################################################################

use strict;
use warnings 'FATAL' => 'all';

use Getopt::Std;
use DBD::SQLite::Constants qw/:file_open/;
use DBI qw(:sql_types);
use File::Copy;
use File::Basename;
use POSIX qw(strftime);
use Time::HiRes qw(gettimeofday);
#use Data::Dump qw(dump);

my $USE_SEARCH_PPEP_PY = 1;
#my $FAILED_MATCH_SEQ = "Failed match";
my $FAILED_MATCH_SEQ = 'No Sequence';
my $FAILED_MATCH_GENE_NAME = 'No_Gene_Name';

my $dirname = dirname(__FILE__);
my %opts;
my ($file_in, $average_or_sum, $db_out, $file_out, $file_melt, $phospho_type);
my $dbtype;
my ($fasta_in, $networkin_in, $motifs_in, $PSP_Kinase_Substrate_in, $PSP_Regulatory_Sites_in);
my (@samples, %sample_id_lut, %ppep_id_lut, %data, @tmp_data, %n);
my $line = 0;
my @failed_match = ($FAILED_MATCH_SEQ);
my @failed_matches;
my (%all_data);
my (@p_peptides, @non_p_peptides);
my @parsed_fasta;
my (@accessions, @names, @sequences, @databases, $database);
my ($dbfile, $dbh, $stmth);
my @col_names;
my (%matched_sequences, %accessions,     %names,     %sites,   );
my (@tmp_matches,       @tmp_accessions, @tmp_names, @tmp_sites);
my (%p_residues, @tmp_p_residues, @p_sites, $left, $right, %p_motifs, @tmp_motifs_array, $tmp_motif, $tmp_site, %residues);
my (@kinases_observed, $kinases);
my (@kinases_observed_lbl, @phosphosites_observed_lbl);
my ($p_sequence_kinase, $p_sequence, $kinase);
my (@motif_sequence, %motif_type, %motif_count);
my (@kinases_PhosphoSite, $kinases_PhosphoSite);
my ($p_sequence_kinase_PhosphoSite, $p_sequence_PhosphoSite, $kinase_PhosphoSite);
my (%regulatory_sites_PhosphoSite_hash);
my (%domain, %ON_FUNCTION, %ON_PROCESS, %ON_PROT_INTERACT, %ON_OTHER_INTERACT, %notes, %organism);
my (%unique_motifs);
my ($kinase_substrate_NetworKIN_matches, $kinase_motif_matches, $kinase_substrate_PhosphoSite_matches);
my %psp_regsite_protein_2;
my (%domain_2, %ON_FUNCTION_2, %ON_PROCESS_2, %ON_PROT_INTERACT_2, %N_PROT_INTERACT, %ON_OTHER_INTERACT_2, %notes_2, %organism_2);
my @timeData;
my $PhosphoSitePlusCitation;
my %site_description;

my %kinase_substrate_NetworKIN_matches;
my %kinase_motif_matches;
my $regulatory_sites_PhosphoSite;
my ($seq_plus5aa, $seq_plus7aa, %seq_plus7aa_2);
my %kinase_substrate_PhosphoSite_matches;
my @formatted_sequence;
my $pSTY_sequence;
my $i;
my @a;
my $use_sqlite;
my $verbose;

##########
## opts ##
##########
  ## input files
    # i : path to input file, e.g., 'outputfile_STEP2.txt'
    # f : path to UniProtKB/SwissProt FASTA
    # s : optional species argument
    # n : path to NetworKIN_201612_cutoffscore2.0.txt
    # m : path to pSTY_Motifs.txt
    # p : path to 2017-03_PSP_Kinase_Substrate_Dataset.txt
    # r : path to 2017-03_PSP_Regulatory_sites.txt
  ## options
    # P : phospho_type
    # F : function
    # v : verbose output
  ## output files
    # o : path to output file
    # O : path to "melted" output file
    # D : path to output SQLite file

sub usage()
    {
        print STDERR <<"EOH";
    This program given a list of phospho-peptides, finds protein information and upstream kinases.
    usage: $0 [-hvd] -f FASTA_file
     -h : this (help) message
     -v : slightly verbose
     -a : use SQLite less
     ## input files
     -i : path to input file, e.g., 'outputfile_STEP2.txt'
     -f : path to UniProtDB/SwissProt FASTA
     -s : optional species filter argument for PSP records; defaults to 'human'
     -n : path to NetworKIN_201612_cutoffscore2.0.txt
     -m : path to pSTY_Motifs.txt
     -p : path to 2017-03_PSP_Kinase_Substrate_Dataset.txt
     -r : path to 2017-03_PSP_Regulatory_sites.txt
     ## options
     -P : phospho_type
     -F : function
     ## output files
     -o : path to output file
     -O : path to "melted" output file
     -D : path to output SQLite file
    example: $0
EOH
        exit;
    }

sub format_localtime_iso8601 {
    # ref: https://perldoc.perl.org/Time::HiRes
    my ($seconds, $microseconds) = gettimeofday;
    # ref: https://pubs.opengroup.org/onlinepubs/9699919799/functions/strftime.html
    return strftime("%Y-%m-%dT%H:%M:%S",localtime(time)) . sprintf(".%03d", $microseconds/1000);
}

sub replace_pSpTpY {
    my ($formatted_sequence, $phospho_type) = @_;
    if ($phospho_type eq 'y') {
        $formatted_sequence =~ s/pS/S/g;
        $formatted_sequence =~ s/pT/T/g;
        $formatted_sequence =~ s/pY/y/g;
        }
    elsif ($phospho_type eq "sty") {
        $formatted_sequence =~ s/pS/s/g;
        $formatted_sequence =~ s/pT/t/g;
        $formatted_sequence =~ s/pY/y/g;
        }
    $formatted_sequence;
}

sub pseudo_sed
{
    # pseudo_sed produces "UniProt_ID\tDescription\tOS\tOX\tGN\tPE\tSV"
    # Comments give the sed equivalent
    my ($t) = @_;
    my $s = $t;
    # / GN=/!{ s:\(OX=[^ \t]*\):\1 GN=N/A:; };
    unless ($s =~ m / GN=/s)
    {
        $s =~ s :(OX=[^ \t]*):${1} GN=N/A:s;
    }
    # / PE=/!{ s:\(GN=[^ \t]*\):\1 PE=N/A:; };
    unless ($s =~ m / PE=/s)
    {
        $s =~ s :(GN=[^ \t]*):${1} PE=N/A:s;
    }
    # / SV=/!{ s:\(PE=[^ \t]*\):\1 SV=N/A:; };
    unless ($s =~ m / SV=/s)
    {
        $s =~ s :(PE=[^ \t]*):${1} SV=N/A:s;
    }
    # s/^sp.//;
    $s =~ s :^...::s;
    # s/[|]/\t/g;
    $s =~ s :[|]:\t:sg;
    if ( !($s =~ m/ OX=/s)
      && !($s =~ m/ GN=/s)
      && !($s =~ m/ PE=/s)
      && !($s =~ m/ SV=/s)
    ) {
      # OS= is used elsewhere, but it's not helpful without OX and GN
      $s =~ s/OS=/Species /g;
      # supply sensible default values
      $s .= "\tN/A\t-1\tN/A\tN/A\tN/A";
    } else {
      # s/ OS=/\t/;
      if ($s =~ m/ OS=/s) { $s =~ s: OS=:\t:s; } else { $s =~ s:(.*)\t:$1\tN/A\t:x; };
      # s/ OX=/\t/;
      if ($s =~ m/ OX=/s) { $s =~ s: OX=:\t:s; } else { $s =~ s:(.*)\t:$1\t-1\t:x; };
      # s/ GN=/\t/;
      if ($s =~ m/ GN=/s) { $s =~ s: GN=:\t:s; } else { $s =~ s:(.*)\t:$1\tN/A\t:x; };
      # s/ PE=/\t/;
      if ($s =~ m/ PE=/s) { $s =~ s: PE=:\t:s; } else { $s =~ s:(.*)\t:$1\tN/A\t:x; };
      # s/ SV=/\t/;
      if ($s =~ m/ SV=/s) { $s =~ s: SV=:\t:s; } else { $s =~ s:(.*)\t:$1\tN/A\t:x; };
    }
    return $s;
} # sub pseudo_sed

getopts('i:f:s:n:m:p:r:P:F:o:O:D:hva', \%opts) ;


if (exists($opts{'h'})) {
    usage();
}
if (exists($opts{'a'})) {
    $USE_SEARCH_PPEP_PY = 0;
}
if (exists($opts{'v'})) {
    $verbose = 1;
} else {
    $verbose = 0;
}
if (!exists($opts{'i'}) || !-e $opts{'i'}) {
    die('Input File not found');
} else {
    $file_in = $opts{'i'};
}
if (!exists($opts{'f'}) || !-e $opts{'f'}) {
    die('FASTA not found');
} else {
    $fasta_in = $opts{'f'};
    $use_sqlite = 0;
}
my $species;
if ((!exists($opts{'s'})) || ($opts{'s'} eq '')) {
    $species = 'human';
} else {
    $species = $opts{'s'};
    print "'-s' option is '$species'\n";
}
print "species filter is '$species'\n";

if (!exists($opts{'n'}) || !-e $opts{'n'}) {
    die('Input NetworKIN File not found');
} else {
    $networkin_in = $opts{'n'};
}
if (!exists($opts{'m'}) || !-e $opts{'m'}) {
    die('Input pSTY_Motifs File not found');
} else {
    $motifs_in = $opts{'m'};
}
if (!exists($opts{'p'}) || !-e $opts{'p'}) {
    die('Input PSP_Kinase_Substrate_Dataset File not found');
} else {
    $PSP_Kinase_Substrate_in = $opts{'p'};
}
if (!exists($opts{'r'}) || !-e $opts{'r'}) {
    die('Input PSP_Regulatory_sites File not found');
} else {
    $PSP_Regulatory_Sites_in = $opts{'r'};
}
if (exists($opts{'P'})) {
    $phospho_type = $opts{'P'};
}
else {
    $phospho_type = "sty";
}
if (exists($opts{'F'})) {
    $average_or_sum = $opts{'F'};
}
else {
    $average_or_sum = "sum";
}
if (exists($opts{'D'})) {
    $db_out = $opts{'D'};
}
else {
    $db_out = "db_out.sqlite";
}
if (exists($opts{'O'})) {
    $file_melt = $opts{'O'};
}
else {
    $file_melt = "output_melt.tsv";
}
if (exists($opts{'o'})) {
    $file_out = $opts{'o'};
}
else {
    $file_out = "output.tsv";
}


###############################################################################################################################
# Print the relevant file names to the screen
###############################################################################################################################
# print "\nData file:  $data_in\nFASTA file:  $fasta_in\nSpecies:  $species\nOutput file:  $motifs_out\n\n";
print "\n--- parameters:\n";
print "Data file:  $file_in\nAverage or sum identical p-sites?  $average_or_sum\nOutput file:  $file_out\nMelted map:  $file_melt\n";
if ($use_sqlite == 0) {
  print "Motifs file:  $motifs_in\nNetworKIN file:  networkin_in\nPhosphosite kinase substrate data:  $PSP_Kinase_Substrate_in\nPhosphosite regulatory site data:  $PSP_Regulatory_Sites_in\nUniProtKB/SwissProt FASTA file:  $fasta_in\nOutput SQLite file: $db_out\n";
} else {
  print "Motifs file:  $motifs_in\nNetworKIN file:  networkin_in\nPhosphosite kinase substrate data:  $PSP_Kinase_Substrate_in\nPhosphosite regulatory site data:  $PSP_Regulatory_Sites_in\nUniProtKB/SwissProt SQLIte file:  $dbfile\nOutput SQLite file: $db_out\n";
}
print "...\n\n";

print "Phospho-residues(s) = $phospho_type\n\n";
if ($phospho_type ne 'y') {
    if ($phospho_type ne 'sty') {
        die "\nUsage error:\nYou must choose a phospho-type, either y or sty\n\n";
    }
}

###############################################################################################################################
# read the input data file
# average or sum identical phospho-sites, depending on the value of $average_or_sum
###############################################################################################################################

open (IN, "$file_in") or die "I couldn't find the input file:  $file_in\n";

die "\n\nScript died: You must choose either average or sum for \$average_or_sum\n\n" if (($average_or_sum ne "sum") && ($average_or_sum ne "average")) ;


$line = 0;

while (<IN>) {
    chomp;
    my @x = split(/\t/);
    for my $n (0 .. $#x) {$x[$n] =~ s/\r//g; $x[$n]  =~ s/\n//g; $x[$n]  =~ s/\"//g;}

    # Read in the samples
    if ($line == 0) {
        for my $n (1 .. $#x) {
            push (@samples, $x[$n]);
            $sample_id_lut{$x[$n]} = $n;
        }
        $line++;
    } else {
        # check whether we have already seen a phospho-peptide
        if (exists($data{$x[0]})) {
            if ($average_or_sum eq "sum") {        # add the data
                # unload the data
                @tmp_data = (); foreach (@{$data{$x[0]}}) { push(@tmp_data, $_); }
                # add the new data and repack
                for my $k (0 .. $#tmp_data) { $tmp_data[$k] = $tmp_data[$k] + $x[$k+1]; }
                $all_data{$x[0]} = (); for my $k (0 .. $#tmp_data) { push(@{$all_data{$x[0]}}, $tmp_data[$k]); }

            } elsif ($average_or_sum eq "average") {        # average the data
                # unload the data
                @tmp_data = (); foreach (@{$all_data{$x[0]}}) { push(@tmp_data, $_); }
                # average with the new data and repack
                for my $k (0 .. $#tmp_data) { $tmp_data[$k] = ( $tmp_data[$k]*$n{$x[0]} + $x[0] ) / ($n{$x[0]} + 1); }
                $n{$x[0]}++;
                $data{$x[0]} = (); for my $k (0 .. $#tmp_data) { push(@{$data{$x[0]}}, $tmp_data[$k]); }
            }
        }
        # if the phospho-sequence has not been seen, save the data
        else {
            for my $k (1 .. $#x) { push(@{$data{$x[0]}}, $x[$k]); }
            $n{$x[0]} = 1;
        }
    }
}
close(IN);


###############################################################################################################################
# Search the FASTA database for phospho-sites and motifs
#
# based on Retrieve_p_peptide_motifs_v2.pl
###############################################################################################################################


###############################################################################################################################
#
#    Read in the Data file:
#        1) make @p_peptides array as in the original file
#        2) make @non_p_peptides array w/o residue modifications (p, #, other)
#
###############################################################################################################################

foreach my $peptide (keys %data) {
    $peptide =~ s/s/pS/g;    $peptide =~ s/t/pT/g;    $peptide =~ s/y/pY/g;
    push (@p_peptides, $peptide);
    $peptide =~ s/p//g;
    push(@non_p_peptides, $peptide);
}

if ($use_sqlite == 0) {
  ###############################################################################################################################
  #
  #    Read in the UniProtKB/Swiss-Prot data from FASTA; save to @sequences array and SQLite output database
  #
  ###############################################################################################################################

  # e.g.
  #   >sp|Q9Y3B9|RRP15_HUMAN RRP15-like protein OS=Homo sapiens OX=9606 GN=RRP15 PE=1 SV=2
  #   MAAAAPDSRVSEEENLKKTPKKKMKMVTGAVASVLEDEATDTSDSEGSCGSEKDHFYSDD
  #   DAIEADSEGDAEPCDKENENDGESSVGTNMGWADAMAKVLNKKTPESKPTILVKNKKLEK
  #   EKEKLKQERLEKIKQRDKRLEWEMMCRVKPDVVQDKETERNLQRIATRGVVQLFNAVQKH
  #   QKNVDEKVKEAGSSMRKRAKLISTVSKKDFISVLRGMDGSTNETASSRKKPKAKQTEVKS
  #   EEGPGWTILRDDFMMGASMKDWDKESDGPDDSRPESASDSDT
  # accession: Q9Y3B9
  # name: RRP15_HUMAN RRP15-like protein OS=Homo sapiens OX=9606 GN=RRP15 PE=1 SV=2
  # sequence: MAAAAPDSRVSEEENLKKTPKKKMKMVTGAVASVLEDEATDTSDSEGSCGSEKDHFYSDD DAIEADSEGDAEPCDKENENDGESSVGTNMGWADAMAKVLNKKTPESKPTILVKNKKLEK EKEKLKQERLEKIKQRDKRLEWEMMCRVKPDVVQDKETERNLQRIATRGVVQLFNAVQKH QKNVDEKVKEAGSSMRKRAKLISTVSKKDFISVLRGMDGSTNETASSRKKPKAKQTEVKS EEGPGWTILRDDFMMGASMKDWDKESDGPDDSRPESASDSDT
  #
  # e.g.
  #   >gi|114939|sp|P00722.2|BGAL_ECOLI Beta-galactosidase (Lactase) cRAP
  #   >gi|52001466|sp|P00366.2|DHE3_BOVIN Glutamate dehydrogenase 1, mitochondrial precursor (GDH) cRAP
  #
  # e.g.
  #   >zs|P00009.24.AR-V2_1.zs|zs_peptide_0024_AR-V2_1


  open (IN1, "$fasta_in") or die "I couldn't find $fasta_in\n";
  print "Reading FASTA file $fasta_in\n";
  # ref: https://perldoc.perl.org/perlsyn#Compound-Statements
  #      "If the condition expression of a while statement is based on any of
  #      a group of iterative expression types then it gets some magic treatment.
  #      The affected iterative expression types are readline, the <FILEHANDLE>
  #      input operator, readdir, glob, the <PATTERN> globbing operator, and
  #      `each`. If the condition expression is one of these expression types,
  #      then the value yielded by the iterative operator will be implicitly
  #      assigned to `$_`."
  while (<IN1>) {
    chomp;
    # ref: https://perldoc.perl.org/functions/split#split-/PATTERN/,EXPR
    #      "If only PATTERN is given, EXPR defaults to $_."
    my (@x) = split(/\|/);
    # begin FIX >gi|114939|sp|P00722.2|BGAL_ECOLI Beta-galactosidase (Lactase) cRAP
    if (@x > 3) {
      @x = (">".$x[$#x - 2], $x[$#x - 1], $x[$#x]);
    }
    # end FIX >gi|114939|sp|P00722.2|BGAL_ECOLI Beta-galactosidase (Lactase) cRAP
    for my $i (0 .. $#x) {
      $x[$i] =~ s/\r//g; $x[$i]  =~ s/\n//g; $x[$i]  =~ s/\"//g; }
    # Use of uninitialized value $x[0] in pattern match (m//) at /home/rstudio/src/mqppep/tools/mqppep/PhosphoPeptide_Upstream_Kinase_Mapping.pl line 411, <IN1> line 3.
    if (exists($x[0])) {
      if ($x[0] =~ /^>/) {
        # parsing header line
        $x[0] =~ s/\>//g;
        push (@databases, $x[0]);
        push (@accessions, $x[1]);
        push (@names, $x[2]);
        # format tags of standard UniProtKB headers as tab-separated values
        # pseudo_sed produces "UniProt_ID\tDescription\tOS\tOX\tGN\tPE\tSV"
        $_ = pseudo_sed(join "\t", (">".$x[0], $x[1], $x[2]));
        # append tab as separator between header and sequence
        s/$/\t/;
        # parsed_fasta gets "UniProt_ID\tDescription\tOS\tOX\tGN\tPE\tSV\t"
        print "push (\@parsed_fasta, $_)\n" if (0 && $x[0] ne "zs");
        push (@parsed_fasta, $_);
      } elsif ($x[0] =~ /^\w/) {
        # line is a portion of the sequence
        if (defined $sequences[$#accessions]) {
          $sequences[$#accessions] = $sequences[$#accessions].$x[0];
        } else {
          $sequences[$#accessions] = $x[0];
        }
        $parsed_fasta[$#accessions] = $parsed_fasta[$#accessions].$x[0];
      }
    }
  }
  close IN1;
  print "Done Reading FASTA file $fasta_in\n";
  $dbfile = $db_out;
  print "Begin writing $dbfile at " . format_localtime_iso8601() . "\n";
  $dbh = DBI->connect("dbi:SQLite:$dbfile", undef, undef);
  my $auto_commit = $dbh->{AutoCommit};
  print "auto_commit was $auto_commit and is now 0\n" if ($verbose);
  $dbh->{AutoCommit} = 0;

  # begin DDL-to-SQLite
  # ---
  $stmth = $dbh->prepare("
    DROP TABLE IF EXISTS UniProtKB;
    ");
  $stmth->execute();

  $stmth = $dbh->prepare("
  CREATE TABLE UniProtKB (
    Uniprot_ID TEXT PRIMARY KEY ON CONFLICT IGNORE,
    Description TEXT,
    Organism_Name TEXT,
    Organism_ID INTEGER,
    Gene_Name TEXT,
    PE TEXT,
    SV TEXT,
    Sequence TEXT,
    Database TEXT
  )
  ");
  $stmth->execute();
  $stmth = $dbh->prepare("
  CREATE UNIQUE INDEX idx_uniq_UniProtKB_0 on UniProtKB(Uniprot_ID);
  ");
  $stmth->execute();
  $stmth = $dbh->prepare("
  CREATE INDEX idx_UniProtKB_0 on UniProtKB(Gene_Name);
  ");
  $stmth->execute();
  # ...
  # end DDL-to-SQLite

  # insert all rows
  # begin store-to-SQLite "UniProtKB" table
  # ---
  $stmth = $dbh->prepare("
  INSERT INTO UniProtKB (
    Uniprot_ID,
    Description,
    Organism_Name,
    Organism_ID,
    Gene_Name,
    PE,
    SV,
    Sequence,
    Database
  ) VALUES (?,?,?,?,?,?,?,?,?)
  ");
  my $row_count = 1;
  my $row_string;
  my (@row, @rows);
  my $wrd;
  while ( scalar @parsed_fasta > 0 ) {
      $database = $databases[$#parsed_fasta];
      # row_string gets "UniProt_ID\tDescription\tOS\tOX\tGN\tPE\tSV\t"
      #                  1           2            3   4   5   6   7   sequence database
      $row_string = pop(@parsed_fasta);
      @row = (split /\t/, $row_string);
      if ((not exists($row[4])) || ($row[4] eq "")) {
        die("invalid fasta line\n$row_string\n");
      };
      if ($row[4] eq "N/A") {
        print "Organism_ID is 'N/A' for row $row_count:\n'$row_string'\n";
        $row[4] = -1;
      };
      for $i (1..3,5..8) {
          #BIND print "bind_param $i, $row[$i]\n";
          $stmth->bind_param($i, $row[$i]);
      }
      #BIND print "bind_param 4, $row[4]\n";
      $stmth->bind_param(9, $database);
      #BIND print "bind_param 4, $row[4]\n";
      $stmth->bind_param(4, $row[4], { TYPE => SQL_INTEGER });
      if (not $stmth->execute()) {
          print "Error in row $row_count: " . $dbh->errstr . "\n";
          print "Row $row_count: $row_string\n";
          print "Row $row_count: " . ($row_string =~ s/\t/@/g) . "\n";
      }
      if (0 && $database ne "zs") {
          print "row_count: $row_count\n";
          #### print "row_string: $row_string\n";
          print "Row $row_count: $row_string\n";
          for $i (1..3,5..8) {
              print "bind_param $i, $row[$i]\n" if (exists($row[$i]));
          }
          print "bind_param 4, $row[4]\n" if (exists($row[4]));
          print "bind_param 9, $database\n";
      };
      $row_count += 1;
  }
  # ...
  # end store-to-SQLite "UniProtKB" table

  print "begin commit at " . format_localtime_iso8601() . "\n";
  $dbh->{AutoCommit} = $auto_commit;
  print "auto_commit is now $auto_commit\n" if ($verbose);
  $dbh->disconnect if ( defined $dbh );
  print "Finished writing $dbfile at " . format_localtime_iso8601() . "\n\n";
  $dbtype = "FASTA";
}

if ($use_sqlite == 1) {
  ###############################################################################################################################
  #
  #    Read in the UniProtKB/Swiss-Prot data from SQLite; save to @sequences array
  #
  ###############################################################################################################################

  copy($dbfile, $db_out) or die "Copy $dbfile to $db_out failed: $!";

  # https://metacpan.org/pod/DBD::SQLite#Read-Only-Database
  $dbh = DBI->connect("dbi:SQLite:$dbfile", undef, undef, {
    sqlite_open_flags => SQLITE_OPEN_READONLY,
  });
  print "DB connection $dbh is to $dbfile\n";

  # Uniprot_ID, Description, Organism_Name, Organism_ID, Gene_Name, PE, SV, Sequence
  $stmth = $dbh->prepare("
  SELECT Uniprot_ID
  , Description
    || CASE WHEN Organism_Name = 'N/A' THEN '' ELSE ' OS=' || Organism_Name END
    || CASE WHEN Organism_ID = -1      THEN '' ELSE ' OX=' || Organism_ID   END
    || CASE WHEN Gene_Name = 'N/A'     THEN '' ELSE ' GN=' || Gene_Name     END
    || CASE WHEN PE = 'N/A'            THEN '' ELSE ' PE=' || PE            END
    || CASE WHEN SV = 'N/A'            THEN '' ELSE ' SV=' || SV            END
    AS Description
  , Sequence
  , Database
  FROM
    UniProtKB
  ");
  $stmth->execute();
  @col_names = @{$stmth->{NAME}};
  print "\nColumn names selected from UniProtKB SQLite table: " . join(", ", @col_names) . "\n\n" if ($verbose);
  while (my @row = $stmth->fetchrow_array) {
    push (@names,              $row[1]); # redacted Description
    push (@accessions,         $row[0]); # Uniprot_ID
    $sequences[$#accessions] = $row[2];  # Sequence
    push (@databases,          $row[3]); # Database (should be 'sp')
  }

  $dbh->disconnect if ( defined $dbh );

  print "Done Reading UniProtKB/Swiss-Prot file $dbfile\n\n";
  $dbtype = "SQLite";
}

print "$#accessions accessions were read from the UniProtKB/Swiss-Prot $dbtype file\n";

######################
  $dbh = DBI->connect("dbi:SQLite:$dbfile", undef, undef);
  $stmth = $dbh->prepare("
  INSERT INTO UniProtKB (
    Uniprot_ID,
    Description,
    Organism_Name,
    Organism_ID,
    Gene_Name,
    PE,
    SV,
    Sequence,
    Database
  ) VALUES (
    'No Uniprot_ID',
    'NO_GENE_SYMBOL No Description',
    'No Organism_Name',
    0,
    '$FAILED_MATCH_GENE_NAME',
    '0',
    '0',
    '$FAILED_MATCH_SEQ',
    'No Database'
  )
  ");
  if (not $stmth->execute()) {
      print "Error inserting dummy row into UniProtKB: $stmth->errstr\n";
  }
  $dbh->disconnect if ( defined $dbh );
######################

@timeData = localtime(time);
print "\n--- Start search at " . format_localtime_iso8601() ."\n";

print "    --> Calling 'search_ppep' script\n\n";
if ($verbose) {
  $i = system("python $dirname/search_ppep.py -u $db_out -p $file_in --verbose");
} else {
  $i = system("python $dirname/search_ppep.py -u $db_out -p $file_in");
}
if ($i) {
  print "python $dirname/search_ppep.py -u $db_out -p $file_in\n  exited with exit code $i\n";
  die "Search failed for phosphopeptides in SwissProt/SQLite file.";
}
print "    <-- Returned from 'search_ppep' script\n";

@timeData = localtime(time);
print "... Finished search at " . format_localtime_iso8601() ."\n\n";


###############################################################################################################################
#
#    Match the non_p_peptides to the @sequences array:
#        1) Format the motifs +/- 10 residues around the phospho-site
#        2) Print the original data plus the phospho-motif to the output file
#
###############################################################################################################################


print "--- Match the non_p_peptides to the \@sequences array:\n";

if ($USE_SEARCH_PPEP_PY) {
  print "Find the matching protein sequence(s) for the peptide using SQLite\n";
} else {
  print "Find the matching protein sequence(s) for the peptide using slow search\n";
}

# https://metacpan.org/pod/DBD::SQLite#Read-Only-Database
$dbh = DBI->connect("dbi:SQLite:$db_out", undef, undef, {
  sqlite_open_flags => SQLITE_OPEN_READONLY,
});
print "DB connection $dbh is to $db_out\n";

# CREATE VIEW uniprotid_pep_ppep AS
#   SELECT   deppep_UniProtKB.UniprotKB_ID       AS accession
#          , deppep.seq                          AS peptide
#          , ppep.seq                            AS phosphopeptide
#          , UniProtKB.Sequence                  AS sequence
#          , UniProtKB.Description               AS description
#   FROM     ppep, deppep, deppep_UniProtKB, UniProtKB
#   WHERE    deppep.id = ppep.deppep_id
#   AND      deppep.id = deppep_UniProtKB.deppep_id
#   AND      deppep_UniProtKB.UniprotKB_ID = UniProtKB.Uniprot_ID
#   ORDER BY UniprotKB_ID, deppep.seq, ppep.seq;

my %ppep_to_count_lut;
print "start select peptide counts " . format_localtime_iso8601() . "\n";
my $uniprotkb_pep_ppep_view_stmth = $dbh->prepare("
    SELECT DISTINCT
      phosphopeptide
    , count(*) as i
    FROM
      uniprotkb_pep_ppep_view
    GROUP BY
      phosphopeptide
    ORDER BY
      phosphopeptide
");
if (not $uniprotkb_pep_ppep_view_stmth->execute()) {
    die "Error fetching peptide counts: $uniprotkb_pep_ppep_view_stmth->errstr\n";
}
while (my @row = $uniprotkb_pep_ppep_view_stmth->fetchrow_array) {
  $ppep_to_count_lut{$row[0]} = $row[1];
  #print "\$ppep_to_count_lut{$row[0]} = $ppep_to_count_lut{$row[0]}\n";
}

# accession, peptide, sequence, description, phosphopeptide, long_description, pos_start, pos_end, scrubbed, ppep_id
# 0          1        2         3            4               5                 6          7        8         9
my $COL_ACCESSION        = 0;
my $COL_PEPTIDE          = 1;
my $COL_SEQUENCE         = 2;
my $COL_DESCRIPTION      = 3;
my $COL_PHOSPHOPEPTIDE   = 4;
my $COL_LONG_DESCRIPTION = 5;
my $COL_POS_START        = 6;
my $COL_POS_END          = 7;
my $COL_SCRUBBED         = 8;
my $COL_PPEP_ID          = 9;

my %ppep_to_row_lut;
print "start select all records without qualification " . format_localtime_iso8601() . "\n";
$uniprotkb_pep_ppep_view_stmth = $dbh->prepare("
    SELECT DISTINCT
      accession
    , peptide
    , sequence
    , description
    , phosphopeptide
    , long_description
    , pos_start
    , pos_end
    , scrubbed
    , ppep_id
    FROM
      uniprotkb_pep_ppep_view
    ORDER BY
      phosphopeptide
");
if (not $uniprotkb_pep_ppep_view_stmth->execute()) {
    die "Error fetching all records without qualification: $uniprotkb_pep_ppep_view_stmth->errstr\n";
}
my $current_ppep;
my $counter = 0;
my $former_ppep = "";
@tmp_matches = ();
@tmp_accessions = ();
@tmp_names = ();
@tmp_sites = ();
while (my @row = $uniprotkb_pep_ppep_view_stmth->fetchrow_array) {
    # Identify phosphopeptide for current row;
    #   it is an error for it to change when the counter is not zero.
    $current_ppep = $row[$COL_PHOSPHOPEPTIDE];

    # when counter is zero, prepare for a new phosphopeptide
    if (not $current_ppep eq $former_ppep) {
        die "counter is $counter instead of zero" if ($counter != 0);
        $ppep_id_lut{$current_ppep} = $row[$COL_PPEP_ID];
        print "next phosphpepetide: $current_ppep; id: $ppep_id_lut{$current_ppep}\n" if ($verbose);
        $counter = $ppep_to_count_lut{$current_ppep};
        @tmp_matches = ();
        @tmp_accessions = ();
        @tmp_names = ();
        @tmp_sites = ();
    }

    if ($USE_SEARCH_PPEP_PY) {
        push(@tmp_matches,    $row[ $COL_SEQUENCE         ]);
        push(@tmp_accessions, $row[ $COL_ACCESSION        ]);
        push(@tmp_names,      $row[ $COL_LONG_DESCRIPTION ]);
        push(@tmp_sites,      $row[ $COL_POS_START        ]);
    }

    # Prepare counter and phosphopeptide tracker for next row
    $former_ppep = $current_ppep;
    $counter -= 1;

    # Set trackers for later use after last instance of current phosphopeptide
    if ($counter == 0) {
        if ($USE_SEARCH_PPEP_PY) {
            $matched_sequences{$current_ppep} = [ @tmp_matches ];
            $accessions{       $current_ppep} = [ @tmp_accessions ];
            $names{            $current_ppep} = [ @tmp_names ];
            $sites{            $current_ppep} = [ @tmp_sites ];
        }
    }
}


print "end select all records without qualification " . format_localtime_iso8601() . "\n";

for my $j (0 .. $#p_peptides) {

    #Find the matching protein sequence(s) for the peptide using SQLite
    my ($site, $sequence);
    my (@row, @rows);
    my $match = 0;
    my $p_peptide = $p_peptides[$j];
    @tmp_matches = ();
    @tmp_accessions = ();
    @tmp_names = ();
    @tmp_sites = ();

    #Find the matching protein sequence(s) for the peptide using slow search
    $site = -1;
    unless ($USE_SEARCH_PPEP_PY) {
        for my $k (0 .. $#sequences) {
            $site = index($sequences[$k], $non_p_peptides[$j]);
            if ($site != -1) {
                  push(@tmp_matches, $sequences[$k]);
                  push(@tmp_accessions, $accessions[$k]);
                  push(@tmp_names, $names[$k]);
                  push(@tmp_sites, $site);
                }
                # print "Non-phosphpeptide $non_p_peptides[$j] matched accession $accessions[$k] ($names[$k]) at site $site\n";
                $site = -1; $match++;
                # print "tmp_accessions @tmp_accessions \n";
        }
        if ($match == 0) {    # Check to see if no match was found.  Skip to next if no match found.
            print "Warning:  Failed match for $p_peptides[$j]\n";
            $matched_sequences{$p_peptides[$j]} = \@failed_match;
            push(@failed_matches,$p_peptides[$j]);
            next;
        } else {
            $matched_sequences{$p_peptides[$j]} = [ @tmp_matches ];
            $accessions{$p_peptides[$j]} = [ @tmp_accessions ];
            $names{$p_peptides[$j]} = [ @tmp_names ];
            $sites{$p_peptides[$j]} = [ @tmp_sites ];
        }
    }

} # end for my $j (0 .. $#p_peptides)

print "... Finished match the non_p_peptides at " . format_localtime_iso8601() ."\n\n";

print "--- Match the p_peptides to the \@sequences array:\n";

for my $peptide_to_match ( keys %matched_sequences ) {
    if (grep($peptide_to_match, @failed_matches)) {
        print "Failed to match peptide $peptide_to_match\n";
    }
    next if (grep($peptide_to_match, @failed_matches));
    my @matches = @{$matched_sequences{$peptide_to_match}};
    @tmp_motifs_array = ();
    for my $i (0 .. $#matches) {

        # Find the location of the phospo-site in the sequence(s)
        $tmp_site = 0; my $offset = 0;
        my $tmp_p_peptide = $peptide_to_match;
        $tmp_p_peptide =~ s/#//g; $tmp_p_peptide =~ s/\d//g; $tmp_p_peptide =~ s/\_//g; $tmp_p_peptide =~ s/\.//g;

        # Find all phosphorylated residues in the p_peptide
        @p_sites = ();
        while ($tmp_site != -1) {
            $tmp_site = index($tmp_p_peptide, 'p', $offset);
            if ($tmp_site != -1) {push (@p_sites, $tmp_site);}
            $offset = $tmp_site + 1;
            $tmp_p_peptide =~ s/p//;
        }
        @tmp_p_residues = ();
        for my $l (0 .. $#p_sites) {
            next if not defined $sites{$peptide_to_match}[$i];

            push (@tmp_p_residues, $p_sites[$l] + $sites{$peptide_to_match}[$i]);

            # Match the sequences around the phospho residues to find the motifs
            my ($desired_residues_L, $desired_residues_R);
            if ($tmp_p_residues[0] - 10 < 0) {    #check to see if there are fewer than 10 residues left of the first p-site
                # eg, XXXpYXX want $desired_residues_L = 3, $p_residues[0] = 3
                $desired_residues_L = $tmp_p_residues[0];
            }
            else {
                $desired_residues_L = 10;
            }
            my $seq_length = length($matched_sequences{$peptide_to_match}[$i]);
            if ($tmp_p_residues[$#tmp_p_residues] + 10 > $seq_length) {    #check to see if there are fewer than 10 residues right of the last p-site
                $desired_residues_R = $seq_length - ($tmp_p_residues[$#tmp_p_residues] + 1);
                # eg, XXXpYXX want $desired_residues_R = 2, $seq_length = 6, $p_residues[$#p_residues] = 3
                # print "Line 170:  seq_length = $seq_length\tp_residue = $p_residues[$#p_residues]\n";
            }
            else {
                $desired_residues_R = 10;
            }

            my $total_length = $desired_residues_L + $tmp_p_residues[$#tmp_p_residues] - $tmp_p_residues[0] + $desired_residues_R + 1;
            my $arg2 = $tmp_p_residues[0] - $desired_residues_L;
            my $arg1 = $matched_sequences{$peptide_to_match}[$i];

            if (($total_length > 0) && (length($arg1) > $arg2 + $total_length - 1)) {
                $tmp_motif = substr($arg1, $arg2, $total_length);

                # Put the "p" back in front of the appropriate phospho-residue(s).
                my (@tmp_residues, $tmp_position);
                for my $m (0 .. $#p_sites) {
                    # print "Line 183: $p_sites[$m]\n";
                    if ($m == 0) {
                        $tmp_position = $desired_residues_L;
                    } else {
                        $tmp_position = $desired_residues_L + $p_sites[$m] - $p_sites[0];
                    }
                    if ($tmp_position < length($tmp_motif) + 1) {
                        push (@tmp_residues, substr($tmp_motif, $tmp_position, 1));
                        if ($tmp_residues[$m] eq "S") {substr($tmp_motif, $tmp_position, 1, "s");}
                        if ($tmp_residues[$m] eq "T") {substr($tmp_motif, $tmp_position, 1, "t");}
                        if ($tmp_residues[$m] eq "Y") {substr($tmp_motif, $tmp_position, 1, "y");}
                    }
                }

                $tmp_motif =~ s/s/pS/g; $tmp_motif =~ s/t/pT/g; $tmp_motif =~ s/y/pY/g;

                # Comment out on 8.10.13 to remove the numbers from motifs
                my $left_residue = $tmp_p_residues[0] - $desired_residues_L+1;
                my $right_residue = $tmp_p_residues[$#tmp_p_residues] + $desired_residues_R+1;
                $tmp_motif = $left_residue."-[ ".$tmp_motif." ]-".$right_residue;
                push(@tmp_motifs_array, $tmp_motif);
                $residues{$peptide_to_match}{$i} = [ @tmp_residues ];
                $p_residues{$peptide_to_match}{$i} = [ @tmp_p_residues ];
            }
        }
        $p_motifs{$peptide_to_match} = [ @tmp_motifs_array ];
    }  # end for my $i (0 .. $#matches)       ### this bracket could be in the wrong place
}

print "... Finished match the p_peptides to the \@sequences array at " . format_localtime_iso8601() ."\n\n";

###############################################################################################################################
#
#  Annotate the peptides with the NetworKIN predictions and HPRD / Phosida kinase motifs
#
###############################################################################################################################


print "--- Reading various site data:\n";

###############################################################################################################################
#
#    Read the NetworKIN_predictions file:
#        1) make a "kinases_observed" array
#        2) annotate the phospho-substrates with the appropriate kinase
#
###############################################################################################################################
my $SITE_KINASE_SUBSTRATE = 1;
$site_description{$SITE_KINASE_SUBSTRATE} = "NetworKIN";

open (IN1, "$networkin_in") or die "I couldn't find $networkin_in\n";
print "Reading the NetworKIN data:  $networkin_in\n";
while (<IN1>) {
    chomp;
    my (@x) = split(/\t/);
    for my $i (0 .. $#x) {
        $x[$i] =~ s/\r//g;     $x[$i]  =~ s/\n//g; $x[$i]  =~ s/\"//g;
    }
    next if ($x[0] eq "#substrate");
    if (exists ($kinases -> {$x[2]})) {
        #do nothing
    }
    else {
        $kinases -> {$x[2]} = $x[2];
        push (@kinases_observed, $x[2]);
    }
    my $tmp = $x[10]."_".$x[2];    #eg, REEILsEMKKV_PKCalpha
    if (exists($p_sequence_kinase -> {$tmp})) {
        #do nothing
    }
    else {
        $p_sequence_kinase -> {$tmp} = $tmp;
    }
}
close IN1;

###############################################################################################################################
#
#    Read the Kinase motifs file:
#        1) make a "motif_sequence" array
#
###############################################################################################################################

# file format (tab separated):
#   x[0] = primary key (character), e.g., '17' or '23a'
#   x[1] = pattern (egrep pattern), e.g., '(M|I|L|V|F|Y).R..(pS|pT)'
#   x[2] = description, e.g., 'PKA_Phosida' or '14-3-3 domain binding motif (HPRD)' or 'Akt kinase substrate motif (HPRD & Phosida)'

my $SITE_MOTIF = 2;
$site_description{$SITE_MOTIF} = "motif";

open (IN2, "$motifs_in") or die "I couldn't find $motifs_in\n";
print "Reading the Motifs file:  $motifs_in\n";

while (<IN2>) {
    chomp;
    my (@x) = split(/\t/);
    for my $i (0 .. 2) {
        $x[$i] =~ s/\r//g;
        $x[$i]  =~ s/\n//g;
        $x[$i]  =~ s/\"//g;
        }
    if (exists ($motif_type{$x[1]})) {
        $motif_type{$x[1]} = $motif_type{$x[1]}." & ".$x[2];
    } else {
        $motif_type{$x[1]} = $x[2];
        $motif_count{$x[1]} = 0;
        push (@motif_sequence, $x[1]);
    }
}
close (IN2);


###############################################################################################################################
#  6.28.2011
#    Read PSP_Kinase_Substrate data:
#        1) make a "kinases_PhosphoSite" array
#        2) annotate the phospho-substrates with the appropriate kinase
#
#  Columns:
#     (0) GENE
#     (1) KINASE
#     (2) KIN_ACC_ID
#     (3) KIN_ORGANISM
#     (4) SUBSTRATE
#     (5) SUB_GENE_ID
#     (6) SUB_ACC_ID
#     (7) SUB_GENE
#     (8) SUB_ORGANISM
#     (9) SUB_MOD_RSD
#     (10) SITE_GRP_ID
#     (11) SITE_+/-7_AA
#     (12) DOMAIN
#     (13) IN_VIVO_RXN
#     (14) IN_VITRO_RXN
#     (15) CST_CAT#
###############################################################################################################################

my $SITE_PHOSPHOSITE = 3;
$site_description{$SITE_PHOSPHOSITE} = "PhosphoSite";


$line = 0;

open (IN3, "$PSP_Kinase_Substrate_in") or die "I couldn't find $PSP_Kinase_Substrate_in\n";
print "Reading the PhosphoSite Kinase-Substrate data:  $PSP_Kinase_Substrate_in\n";

while (<IN3>) {
    chomp;
    my (@x) = split(/\t/);
    for my $i (0 .. $#x) {
        $x[$i] =~ s/\r//g; $x[$i]  =~ s/\n//g; $x[$i]  =~ s/\"//g;
        }
    if ($line != 0) {
        if (($species eq $x[3]) && ($species eq $x[8])) {
            if (exists ($kinases_PhosphoSite -> {$x[0]})) {
                #do nothing
            }
            else {
                $kinases_PhosphoSite -> {$x[0]} = $x[0];
                push (@kinases_PhosphoSite, $x[0]);
            }
            my $offset = 0;
            # Replace the superfluous lower case s, t and y
            my @lowercase = ('s','t','y');
            my @uppercase = ('S','T','Y');
            for my $k (0 .. 2) {
                my $site = 0;
                while ($site != -1) {
                    $site = index($x[11],$lowercase[$k], $offset);
                    if (($site != 7) && ($site != -1)) {substr($x[11], $site, 1, $uppercase[$k]);}
                    $offset = $site + 1;
                }
            }
            my $tmp = $x[11]."_".$x[0];        #eg, RTPGRPLsSYGMDSR_PAK2
            if (exists($p_sequence_kinase_PhosphoSite -> {$tmp})) {
                #do nothing
            }
            else {
                $p_sequence_kinase_PhosphoSite -> {$tmp} = $tmp;
            }
        }
        else {
            # do nothing
            #print "PSP_kinase_substrate line rejected because KIN_ORGANISM is '$x[3]' and SUB_ORGANISM is '$x[8]': $line\n";
        }
    }
    $line++;
}
close IN3;


###############################################################################################################################
#  Read PhosphoSite regulatory site data:
#        1) make a "regulatory_sites_PhosphoSite" hash
#
#  Columns:
#    (0)  GENE
#    (1)  PROTEIN           --> #ACE %psp_regsite_protein
#    (2)  PROT_TYPE
#    (3)  ACC_ID
#    (4)  GENE_ID
#    (5)  HU_CHR_LOC
#    (6)  ORGANISM          --> %organism
#    (7)  MOD_RSD
#    (8)  SITE_GRP_ID
#    (9)  SITE_+/-7_AA      --> %regulatory_sites_PhosphoSite_hash
#    (10) DOMAIN            --> %domain
#    (11) ON_FUNCTION       --> %ON_FUNCTION
#    (12) ON_PROCESS        --> %ON_PROCESS
#    (13) ON_PROT_INTERACT  --> %ON_PROT_INTERACT
#    (14) ON_OTHER_INTERACT --> %ON_OTHER_INTERACT
#    (15) PMIDs
#    (16) LT_LIT
#    (17) MS_LIT
#    (18) MS_CST
#    (19) NOTES             --> %notes
###############################################################################################################################


$dbh = DBI->connect("dbi:SQLite:$db_out", undef, undef);
my $auto_commit = $dbh->{AutoCommit};
$dbh->{AutoCommit} = 0;
print "DB connection $dbh is to $db_out, opened for modification\n";

# add partial PSP_Regulatory_site table (if not exists) regardless of whether SwissProt input was FASTA or SQLite
$stmth = $dbh->prepare("
CREATE TABLE IF NOT EXISTS PSP_Regulatory_site (
  SITE_PLUSMINUS_7AA TEXT PRIMARY KEY ON CONFLICT IGNORE,
  DOMAIN             TEXT,
  ON_FUNCTION        TEXT,
  ON_PROCESS         TEXT,
  ON_PROT_INTERACT   TEXT,
  ON_OTHER_INTERACT  TEXT,
  NOTES              TEXT,
  ORGANISM           TEXT,
  PROTEIN            TEXT
)
");
$stmth->execute();

# add partial PSP_Regulatory_site LUT (if not exists) regardless of whether SwissProt input was FASTA or SQLite
$stmth = $dbh->prepare("
CREATE TABLE IF NOT EXISTS ppep_regsite_LUT
( ppep_id            INTEGER REFERENCES ppep(id)
, site_plusminus_7AA TEXT    REFERENCES PSP_Regulatory_site(site_plusminus_7AA)
, PRIMARY KEY (ppep_id, site_plusminus_7AA) ON CONFLICT IGNORE
);
");
$stmth->execute();

# $stmth = $dbh->prepare("
# CREATE UNIQUE INDEX idx_PSP_Regulatory_site_0
#   ON PSP_Regulatory_site(site_plusminus_7AA);
# ");
# $stmth->execute();


# add Citation table (if not exists) regardless of whether SwissProt input was FASTA or SQLite
my $citation_sql;
$citation_sql = "
CREATE TABLE IF NOT EXISTS Citation (
  ObjectName TEXT REFERENCES sqlite_schema(name) ON DELETE CASCADE,
  CitationData TEXT,
  PRIMARY KEY (ObjectName, CitationData) ON CONFLICT IGNORE
)
";
$stmth = $dbh->prepare($citation_sql);
$stmth->execute();


open (IN4, "$PSP_Regulatory_Sites_in") or die "I couldn't find $PSP_Regulatory_Sites_in\n";
print "Reading the PhosphoSite regulatory site data:  $PSP_Regulatory_Sites_in\n";


$line = -1;
while (<IN4>) {
    $line++;
    chomp;
    if ($_ =~ m/PhosphoSitePlus/) {
        #$PhosphoSitePlusCitation = ($_ =~ s/PhosphoSitePlus/FooBar/g);
        $PhosphoSitePlusCitation = $_;
        $PhosphoSitePlusCitation =~ s/\t//g;
        $PhosphoSitePlusCitation =~ s/\r//g;
        $PhosphoSitePlusCitation =~ s/\n//g;
        $PhosphoSitePlusCitation =~ s/""/"/g;
        $PhosphoSitePlusCitation =~ s/^"//g;
        $PhosphoSitePlusCitation =~ s/"$//g;
        print "$PhosphoSitePlusCitation\n";
        next;
    }
    my (@x) = split(/\t/);
    for my $i (0 .. $#x) {
        $x[$i] =~ s/\r//g; $x[$i]  =~ s/\n//g; $x[$i]  =~ s/\"//g;
    }
    my $found_GENE=0;
    if ( (not exists($x[0])) ) {
        next;
    }
    elsif ( ($x[0] eq "GENE") ) {
        $found_GENE=1;
        next;
    }
    if ( (not exists($x[9])) || ($x[9] eq "") ) {
        if (exists($x[8]) && (not $x[8] eq "")) {
            die "$PSP_Regulatory_Sites_in line $line has no SITE_+/-7_AA: $_\n";
        } else {
            if ( (not exists($x[1])) || (not $x[1] eq "") ) {
                print "$PSP_Regulatory_Sites_in line $line (".length($_)." characters) has no SITE_+/-7_AA: $_\n"
                  if $found_GENE==1;
            }
            next;
        }
    }
    elsif ($line != 0) {
        if ($species ne $x[6]) {
            # Do nothing - this record was filtered out by the species filter
        }
        elsif (!exists($regulatory_sites_PhosphoSite_hash{$x[9]})) {
            if (!defined $domain{$x[9]} || $domain{$x[9]} eq "") {
                $regulatory_sites_PhosphoSite_hash{$x[9]} = $x[9];
                $domain{$x[9]} = $x[10];
                $ON_FUNCTION{$x[9]} = $x[11];
                $ON_PROCESS{$x[9]} = $x[12];
                $ON_PROT_INTERACT{$x[9]} = $x[13];
                $ON_OTHER_INTERACT{$x[9]} = $x[14];
                $notes{$x[9]} = $x[19];
                $organism{$x[9]} = $x[6];
            }
        }
        else {
            # $domain
            if (!defined $domain{$x[9]} || $domain{$x[9]} eq "") {
                if ($x[10] ne "") {
                  $domain{$x[9]} = $domain{$x[10]};
                  }
                else {
                  # do nothing
                  }
            }
            else {
                if ($domain{$x[9]} =~ /$x[10]/) {
                  # do nothing
                  }
                else {
                  $domain{$x[9]} = $domain{$x[9]}." / ".$x[10];
                  #print "INFO line $line - compound domain for 7aa:  GENE $x[0]   PROTEIN $x[1]   PROT_TYPE $x[2]   ACC_ID $x[3]   GENE_ID $x[4]   HU_CHR_LOC $x[5]   ORGANISM $x[6]   MOD_RSD $x[7]   SITE_GRP_ID $x[8]   SITE_+/-7_AA $x[9]   DOMAIN $domain{$x[9]}\n";
                  }
            }

            # $ON_FUNCTION
            if (!defined $ON_FUNCTION{$x[9]} || $ON_FUNCTION{$x[9]} eq "") {
                $ON_FUNCTION{$x[9]} = $ON_FUNCTION{$x[10]};
            } elsif ($x[10] eq "") {
                # do nothing
            }
            else {
                $ON_FUNCTION{$x[9]} = $ON_FUNCTION{$x[9]}." / ".$x[10];
            }

            # $ON_PROCESS
            if (!defined $ON_PROCESS{$x[9]} || $ON_PROCESS{$x[9]} eq "") {
                $ON_PROCESS{$x[9]} = $ON_PROCESS{$x[10]};
            } elsif ($x[10] eq "") {
                # do nothing
            }
            else {
                $ON_PROCESS{$x[9]} = $ON_PROCESS{$x[9]}." / ".$x[10];
            }

            # $ON_PROT_INTERACT
            if (!defined $ON_PROT_INTERACT{$x[9]}  || $ON_PROT_INTERACT{$x[9]} eq "") {
                $ON_PROT_INTERACT{$x[9]} = $ON_PROT_INTERACT{$x[10]};
            } elsif ($x[10] eq "") {
                # do nothing
            }
            else {
                $ON_PROT_INTERACT{$x[9]} = $ON_PROT_INTERACT{$x[9]}." / ".$x[10];
            }

            # $ON_OTHER_INTERACT
            if (!defined $ON_OTHER_INTERACT{$x[9]} || $ON_OTHER_INTERACT{$x[9]} eq "") {
                $ON_OTHER_INTERACT{$x[9]} = $ON_OTHER_INTERACT{$x[10]};
            } elsif ($x[10] eq "") {
                # do nothing
            }
            else {
                $ON_OTHER_INTERACT{$x[9]} = $ON_OTHER_INTERACT{$x[9]}." / ".$x[10];
            }

            # $notes
            if (!defined $notes{$x[9]} || $notes{$x[9]} eq "") {
                $notes{$x[9]} = $notes{$x[10]};
            } elsif ($x[10] eq "") {
                # do nothing
            }
            else {
                $notes{$x[9]} = $notes{$x[9]}." / ".$x[10];
            }

            # $organism
            if (!defined $organism{$x[9]} || $organism{$x[9]} eq "") {
                $organism{$x[9]} = $organism{$x[10]};
            } elsif ($x[10] eq "") {
                # do nothing
            }
            else {
                $organism{$x[9]} = $organism{$x[9]}." / ".$x[10];
            }
        }
    }
}
close IN4;

print "... Finished reading various site data at " . format_localtime_iso8601() ."\n\n";

$stmth = $dbh->prepare("
INSERT INTO Citation (
  ObjectName,
  CitationData
) VALUES (?,?)
");

sub add_citation {
    my ($cit_table, $cit_text, $cit_label) = @_;
    $stmth->bind_param(1, $cit_table);
    $stmth->bind_param(2, $cit_text);
    if (not $stmth->execute()) {
        print "Error writing $cit_label cit for table $cit_table: $stmth->errstr\n";
    }
}
my ($citation_text, $citation_table);

# PSP regulatory or kinase/substrate site
$citation_text = 'PhosphoSitePlus(R) (PSP) was created by Cell Signaling Technology Inc. It is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License. When using PSP data or analyses in printed publications or in online resources, the following acknowledgements must be included: (a) the words "PhosphoSitePlus(R), www.phosphosite.org" must be included at appropriate places in the text or webpage, and (b) the following citation must be included in the bibliography: "Hornbeck PV, Zhang B, Murray B, Kornhauser JM, Latham V, Skrzypek E PhosphoSitePlus, 2014: mutations, PTMs and recalibrations. Nucleic Acids Res. 2015 43:D512-20. PMID: 25514926."';
$citation_table = "PSP_Regulatory_site";
add_citation($citation_table, $citation_text, "PSP_Kinase_Substrate");
$citation_table = "psp_gene_site";
add_citation($citation_table, $citation_text, "PSP_Kinase_Substrate");
$citation_table = "psp_gene_site_view";
add_citation($citation_table, $citation_text, "PSP_Regulatory_site");
$citation_text = 'Hornbeck, 2014, "PhosphoSitePlus, 2014: mutations, PTMs and recalibrations.", https://pubmed.ncbi.nlm.nih.gov/22135298, https://doi.org/10.1093/nar/gkr1122';
$citation_table = "PSP_Regulatory_site";
add_citation($citation_table, $citation_text, "PSP_Regulatory_site");
$citation_table = "psp_gene_site";
add_citation($citation_table, $citation_text, "PSP_Kinase_Substrate");
$citation_table = "psp_gene_site_view";
add_citation($citation_table, $citation_text, "PSP_Kinase_Substrate");

# NetworKIN site
$citation_text = 'Linding, 2007, "Systematic discovery of in vivo phosphorylation networks.", https://pubmed.ncbi.nlm.nih.gov/17570479, https://doi.org/10.1016/j.cell.2007.05.052';
$citation_table = "psp_gene_site";
add_citation($citation_table, $citation_text, "NetworkKIN");
$citation_table = "psp_gene_site_view";
add_citation($citation_table, $citation_text, "NetworkKIN");
$citation_text = 'Horn, 2014, "KinomeXplorer: an integrated platform for kinome biology studies.", https://pubmed.ncbi.nlm.nih.gov/24874572, https://doi.org/10.1038/nmeth.296';
$citation_table = "psp_gene_site";
add_citation($citation_table, $citation_text, "NetworkKIN");
$citation_table = "psp_gene_site_view";
add_citation($citation_table, $citation_text, "NetworkKIN");
$citation_text = 'Aken, 2016, "The Ensembl gene annotation system.", https://pubmed.ncbi.nlm.nih.gov/33137190, https://doi.org/10.1093/database/baw093';
$citation_table = "psp_gene_site";
add_citation($citation_table, $citation_text, "NetworkKIN");
$citation_table = "psp_gene_site_view";
add_citation($citation_table, $citation_text, "NetworkKIN");

# pSTY motifs
$citation_text = 'Amanchy, 2007, "A curated compendium of phosphorylation motifs.", https://pubmed.ncbi.nlm.nih.gov/17344875, https://doi.org/10.1038/nbt0307-285';
$citation_table = "psp_gene_site";
add_citation($citation_table, $citation_text, "Amanchy_pSTY_motifs");
$citation_table = "psp_gene_site_view";
add_citation($citation_table, $citation_text, "Amanchy_pSTY_motifs");
$citation_text = 'Gnad, 2011, "PHOSIDA 2011: the posttranslational modification database.", https://pubmed.ncbi.nlm.nih.gov/21081558, https://doi.org/10.1093/nar/gkq1159';
$citation_table = "psp_gene_site";
add_citation($citation_table, $citation_text, "Phosida_pSTY_motifs");
$citation_table = "psp_gene_site_view";
add_citation($citation_table, $citation_text, "Phosida_pSTY_motifs");


###############################################################################################################################
#
#    Read the data file:
#        1) find sequences that match the NetworKIN predictions
#        2) find motifs that match the observed sequences
#
###############################################################################################################################

print "--- Find sequences that match the NetworKIN predictions and find motifs that match observed sequences\n";

my $ppep_regsite_LUT_stmth;
$ppep_regsite_LUT_stmth = $dbh->prepare("
  INSERT INTO ppep_regsite_LUT (
    ppep_id,
    site_plusminus_7AA
  ) VALUES (?,?)
");

my ($start_seconds, $start_microseconds) = gettimeofday;

foreach my $peptide (keys %data) {
    # find the unique phospho-motifs for this $peptide
    my @all_motifs = ();
    my $have_all_motifs = 0;
    for my $i (0 .. $#{ $matched_sequences{$peptide} } ) {
        my $tmp_motif = $p_motifs{$peptide}[$i];
        push(@all_motifs, $tmp_motif);
        $have_all_motifs = 1;
    }
    if ($have_all_motifs == 1) {
        for my $j (0 .. $#all_motifs) {
            if (defined $all_motifs[$j]) {
                $all_motifs[$j] =~ s/\d+-\[\s//;
                $all_motifs[$j] =~ s/\s\]\-\d+//;
            }
        }
    }
    my %seen = ();
    if ($have_all_motifs == 1) {
        foreach my $a (@all_motifs) {
            if (defined $a) {
                if (exists($seen{$a})) {
                    next;
                } else {
                    push(@{$unique_motifs{$peptide}}, $a);
                    $seen{$a} = 1;
                }
            }
            print "push(\@{\$unique_motifs{$peptide}}, $a);\n" if ($verbose);
        }
    }

    # count the number of phospo-sites in the motif
    my $number_pY = 0;
    my $number_pSTY = 0;
    if ($phospho_type eq 'y') {
        if (defined(${$unique_motifs{$peptide}}[0])) {
            while (${$unique_motifs{$peptide}}[0] =~ /pY/g) {
                $number_pY++;
            }
        }
    }
    if ($phospho_type eq 'sty') {
        print "looking for unique_motifs for $peptide\n" if ($verbose);
        if (defined(${$unique_motifs{$peptide}}[0])) {
            while (${$unique_motifs{$peptide}}[0] =~ /(pS|pT|pY)/g) {
                $number_pSTY++;
               print "We have found $number_pSTY unique_motifs for $peptide\n" if ($verbose);
            }
        }
    }


    # search each of the unique motifs for matches
    print "searching $#{$unique_motifs{$peptide}} motifs for peptide $peptide\n" if ($verbose);
    for my $i (0 .. $#{$unique_motifs{$peptide}}) {
        print "\$i = $i; peptide = $peptide; unique_motif = ${$unique_motifs{$peptide}}[$i]\n" if ($verbose);
        my $tmp_motif = ${$unique_motifs{$peptide}}[$i];
        print "   --- matching unique motif $tmp_motif for peptide  $peptide at " . format_localtime_iso8601() ."\n" if ($verbose);
        my $formatted_sequence;
        if (($number_pY == 1) || ($number_pSTY == 1)) {
            my $seq_plus5aa = "";
            my $seq_plus7aa = "";
            $formatted_sequence = &replace_pSpTpY($tmp_motif, $phospho_type);
            print "       a #pY $number_pY; #pSTY $number_pSTY; matching formatted motif $formatted_sequence for peptide  $peptide at " . format_localtime_iso8601() ."\n" if ($verbose);
            if ($phospho_type eq 'y') {
                $seq_plus5aa = (split(/(\w{0,5}y\w{0,5})/, $formatted_sequence))[1];
                $seq_plus7aa = (split(/(\w{0,7}y\w{0,7})/, $formatted_sequence))[1];
            }
            elsif ($phospho_type eq "sty") {
                $seq_plus5aa = (split(/(\w{0,5}(s|t|y)\w{0,5})/, $formatted_sequence))[1];
                $seq_plus7aa = (split(/(\w{0,7}(s|t|y)\w{0,7})/, $formatted_sequence))[1];
            }

            if (defined $seq_plus7aa) {
                # commit the 7aa LUT records
                $ppep_regsite_LUT_stmth->bind_param( 1, $ppep_id_lut{$peptide} );
                $ppep_regsite_LUT_stmth->bind_param( 2, $seq_plus7aa             );
                if (not $ppep_regsite_LUT_stmth->execute()) {
                    print "Error writing tuple ($ppep_id_lut{$peptide},$seq_plus7aa) for peptide $peptide to ppep_regsite_LUT: $ppep_regsite_LUT_stmth->errstr\n";
                }
            }
            for my $i (0 .. $#kinases_observed) {
                if (defined $seq_plus5aa) {
                    my $tmp = $seq_plus5aa."_".$kinases_observed[$i];    #eg, should be PGRPLsSYGMD_PKCalpha
                    if (exists($p_sequence_kinase -> {$tmp})) {
                        $kinase_substrate_NetworKIN_matches{$peptide}{$kinases_observed[$i]} = "X"; #ACE
                    }
                }
            }
            for my $i (0 .. $#motif_sequence) {
                if ($peptide =~ /$motif_sequence[$i]/) {
                    $kinase_motif_matches{$peptide}{$motif_sequence[$i]} = "X";
                }
            }
            for my $i (0 .. $#kinases_PhosphoSite) {
                if (defined $seq_plus7aa) {
                    my $tmp = $seq_plus7aa."_".$kinases_PhosphoSite[$i];    #eg, should be RTPGRPLsSYGMDSR_PAK2
                    if (exists($p_sequence_kinase_PhosphoSite -> {$tmp})) {
                        $kinase_substrate_PhosphoSite_matches{$peptide}{$kinases_PhosphoSite[$i]} = "X";
                    }
                }
            }
            if (exists($regulatory_sites_PhosphoSite_hash{$seq_plus7aa})) {
                $seq_plus7aa_2{$peptide} = $seq_plus7aa;
                $domain_2{$peptide} = $domain{$seq_plus7aa};
                $ON_FUNCTION_2{$peptide} = $ON_FUNCTION{$seq_plus7aa};
                $ON_PROCESS_2{$peptide} = $ON_PROCESS{$seq_plus7aa};
                $ON_PROT_INTERACT_2{$peptide} = $ON_PROT_INTERACT{$seq_plus7aa};
                $ON_OTHER_INTERACT_2{$peptide} = $ON_OTHER_INTERACT{$seq_plus7aa};
                $notes_2{$peptide} = $notes{$seq_plus7aa};
                $organism_2{$peptide} = $organism{$seq_plus7aa};
            } else {
            }
        }
        elsif (($number_pY > 1) || ($number_pSTY > 1)) {  #eg, if $x[4] is 1308-[ VIYFQAIEEVpYpYDHLRSAAKKR ]-1329 and $number_pY == 2
            $formatted_sequence = $tmp_motif;
            $seq_plus5aa = "";
            $seq_plus7aa = "";
            #Create the sequences with only one phosphorylation site
            #eg, 1308-[ VIYFQAIEEVpYpYDHLRSAAKKR ]-1329, which becomes  1308-[ VIYFQAIEEVpYYDHLRSAAKKR ]-1329  and  1308-[ VIYFQAIEEVYpYDHLRSAAKKR ]-1329

            my (@sites, $offset, $next_p_site);
            $sites[0] = index($tmp_motif, "p");
            $offset = $sites[0] + 1;
            $next_p_site = 0;
            while ($next_p_site != -1) {
                $next_p_site = index($tmp_motif, "p", $offset);
                if ($next_p_site != -1) {
                    push (@sites, $next_p_site);
                }
                $offset = $next_p_site+1;
            }

            my @pSTY_sequences;
            for my $n (0 .. $#sites) {
                $pSTY_sequences[$n] = $tmp_motif;
                for (my $m = $#sites; $m >= 0; $m--) {
                    if ($m != $n) {substr($pSTY_sequences[$n], $sites[$m], 1) = "";}
                }
            }

            my @formatted_sequences;
            for my $k (0 .. $#sites) {
                $formatted_sequences[$k] = &replace_pSpTpY($pSTY_sequences[$k], $phospho_type);
            }

            for my $k (0 .. $#formatted_sequences) {
                print "       b #pY $number_pY; #pSTY $number_pSTY; matching formatted motif $formatted_sequences[$k] for peptide  $peptide at " . format_localtime_iso8601() ."\n" if ($verbose);
                if ($phospho_type eq 'y') {
                    $seq_plus5aa = (split(/(\w{0,5}y\w{0,5})/, $formatted_sequences[$k]))[1];
                    $seq_plus7aa = (split(/(\w{0,7}y\w{0,7})/, $formatted_sequences[$k]))[1];
                }
                elsif ($phospho_type eq "sty") {
                    $seq_plus5aa = (split(/(\w{0,5}(s|t|y)\w{0,5})/, $formatted_sequences[$k]))[1];
                    $seq_plus7aa = (split(/(\w{0,7}(s|t|y)\w{0,7})/, $formatted_sequences[$k]))[1];
                }
                for my $i (0 .. $#kinases_observed) {
                    my $tmp = $seq_plus5aa."_".$kinases_observed[$i];    #eg, should look like REEILsEMKKV_PKCalpha
                    if (exists($p_sequence_kinase -> {$tmp})) {
                        $kinase_substrate_NetworKIN_matches{$peptide}{$kinases_observed[$i]} = "X";
                    }
                }
                $pSTY_sequence = $formatted_sequences[$k];
                for my $i (0 .. $#motif_sequence) {
                    if ($pSTY_sequence =~ /$motif_sequence[$i]/) {
                        $kinase_motif_matches{$peptide}{$motif_sequence[$i]} = "X";
                    }
                }
                for my $i (0 .. $#kinases_PhosphoSite) {
                    my $tmp = $seq_plus7aa."_".$kinases_PhosphoSite[$i];    #eg, should be RTPGRPLsSYGMDSR_PAK2
                    #print "seq_plus7aa._.kinases_PhosphoSite[i] is $tmp";
                    if (exists($p_sequence_kinase_PhosphoSite -> {$tmp})) {
                        $kinase_substrate_PhosphoSite_matches{$peptide}{$kinases_PhosphoSite[$i]} = "X";
                    }
                }
                if (exists($regulatory_sites_PhosphoSite -> {$seq_plus7aa})) {
                    $seq_plus7aa_2{$peptide} = $seq_plus7aa;

                    # $domain
                    if ($domain_2{$peptide} eq "") {
                        $domain_2{$peptide} = $domain{$seq_plus7aa};
                    }
                    elsif ($domain{$seq_plus7aa} eq "") {
                        # do nothing
                    }
                    else {
                        $domain_2{$peptide} = $domain_2{$peptide}." / ".$domain{$seq_plus7aa};
                    }


                    # $ON_FUNCTION_2
                    if ($ON_FUNCTION_2{$peptide} eq "") {
                        $ON_FUNCTION_2{$peptide} = $ON_FUNCTION{$seq_plus7aa};
                    }
                    elsif ($ON_FUNCTION{$seq_plus7aa} eq "") {
                        # do nothing
                    }
                    else {
                        $ON_FUNCTION_2{$peptide} = $ON_FUNCTION_2{$peptide}." / ".$ON_FUNCTION{$seq_plus7aa};
                    }

                    # $ON_PROCESS_2
                    if ($ON_PROCESS_2{$peptide} eq "") {
                        $ON_PROCESS_2{$peptide} = $ON_PROCESS{$seq_plus7aa};
                    }
                    elsif ($ON_PROCESS{$seq_plus7aa} eq "") {
                        # do nothing
                    }
                    else {
                        $ON_PROCESS_2{$peptide} = $ON_PROCESS_2{$peptide}." / ".$ON_PROCESS{$seq_plus7aa};
                    }

                    # $ON_PROT_INTERACT_2
                    if ($ON_PROT_INTERACT_2{$peptide} eq "") {
                        $ON_PROT_INTERACT_2{$peptide} = $ON_PROT_INTERACT{$seq_plus7aa};
                    }
                    elsif ($ON_PROT_INTERACT{$seq_plus7aa} eq "") {
                        # do nothing
                    }
                    else {
                        $ON_PROT_INTERACT_2{$peptide} = $ON_PROT_INTERACT_2{$peptide}." / ".$ON_PROT_INTERACT{$seq_plus7aa};
                    }

                    # $ON_OTHER_INTERACT_2
                    if ($ON_OTHER_INTERACT_2{$peptide} eq "") {
                        $ON_OTHER_INTERACT_2{$peptide} = $ON_OTHER_INTERACT{$seq_plus7aa};
                    }
                    elsif ($ON_OTHER_INTERACT{$seq_plus7aa} eq "") {
                        # do nothing
                    }
                    else {
                        $ON_OTHER_INTERACT_2{$peptide} = $ON_OTHER_INTERACT_2{$peptide}." / ".$ON_OTHER_INTERACT{$seq_plus7aa};
                    }

                    # $notes_2
                    if ($notes_2{$peptide} eq "") {
                        $notes_2{$peptide} = $notes{$seq_plus7aa};
                    }
                    elsif ($notes{$seq_plus7aa} eq "") {
                        # do nothing
                    }
                    else {
                        $notes_2{$peptide} = $notes_2{$peptide}." / ".$notes{$seq_plus7aa};
                    }
                    $notes_2{$peptide} = $notes{$seq_plus7aa};

                    # $organism_2
                    if ($organism_2{$peptide} eq "") {
                        $organism_2{$peptide} = $organism{$seq_plus7aa};
                    }
                    elsif ($organism{$seq_plus7aa} eq "") {
                        # do nothing
                    }
                    else {
                        $organism_2{$peptide} = $organism_2{$peptide}." / ".$organism{$seq_plus7aa};
                    }
                    $organism_2{$peptide} = $organism{$seq_plus7aa};
                } else {
                } # if (exists($regulatory_sites_PhosphoSite -> {$seq_plus7aa}))
            } # for my $k (0 .. $#formatted_sequences)
        } # if/else number of phosphosites
    } # for each motif i # for my $i (0 .. $#{$unique_motifs{$peptide}})
} # for each $peptide

my ($end_seconds, $end_microseconds) = gettimeofday;

my $delta_seconds = $end_seconds - $start_seconds;
my $delta_microseconds = $end_microseconds - $start_microseconds;
$delta_microseconds += 1000000 * $delta_seconds;
my $key_count = keys(%data);
print sprintf("Average search time is %d microseconds per phopshopeptide\n", ($delta_microseconds / $key_count));

($start_seconds, $start_microseconds) = gettimeofday;

print "Writing PSP_Regulatory_site records\n";

my $psp_regulatory_site_stmth = $dbh->prepare("
    INSERT INTO PSP_Regulatory_site (
      DOMAIN,
      ON_FUNCTION,
      ON_PROCESS,
      ON_PROT_INTERACT,
      ON_OTHER_INTERACT,
      NOTES,
      SITE_PLUSMINUS_7AA,
      ORGANISM
    ) VALUES (?,?,?,?,?,?,?,?)
    ");

foreach my $peptide (keys %data) {
    if (exists($domain_2{$peptide}) and (defined $domain_2{$peptide}) and (not $domain_2{$peptide} eq "") ) {
        $psp_regulatory_site_stmth->bind_param(1, $domain_2{$peptide});
        $psp_regulatory_site_stmth->bind_param(2, $ON_FUNCTION_2{$peptide});
        $psp_regulatory_site_stmth->bind_param(3, $ON_PROCESS_2{$peptide});
        $psp_regulatory_site_stmth->bind_param(4, $ON_PROT_INTERACT_2{$peptide});
        $psp_regulatory_site_stmth->bind_param(5, $ON_OTHER_INTERACT_2{$peptide});
        $psp_regulatory_site_stmth->bind_param(6, $notes_2{$peptide});
        $psp_regulatory_site_stmth->bind_param(7, $seq_plus7aa_2{$peptide});
        $psp_regulatory_site_stmth->bind_param(8, $organism_2{$peptide});
        if (not $psp_regulatory_site_stmth->execute()) {
            print "Error writing PSP_Regulatory_site for one regulatory site with peptide '$domain_2{$peptide}': $psp_regulatory_site_stmth->errstr\n";
        } else {
        }
    } elsif (exists($domain_2{$peptide}) and (not defined $domain_2{$peptide})) {
        print "\$domain_2{$peptide} is undefined\n";  #ACE
    }
}

$dbh->{AutoCommit} = $auto_commit;
# auto_commit implicitly finishes psp_regulatory_site_stmth, apparently # $psp_regulatory_site_stmth->finish;
$dbh->disconnect if ( defined $dbh );


($end_seconds, $end_microseconds) = gettimeofday;

$delta_seconds = $end_seconds - $start_seconds;
$delta_microseconds = $end_microseconds - $start_microseconds;
$delta_microseconds += 1000000 * $delta_seconds;
$key_count = keys(%data);
print sprintf("Write time is %d microseconds\n", ($delta_microseconds));

print "... Finished find sequences that match the NetworKIN predictions and find motifs that match observed sequences at " . format_localtime_iso8601() ."\n\n";

###############################################################################################################################
#
# Print to the output file
#
###############################################################################################################################
open (OUT, ">$file_out") || die "could not open the fileout: $file_out";
open (MELT, ">$file_melt") || die "could not open the fileout: $file_melt";

# print the header info
print MELT "phospho_peptide\tgene_names\tsite_type\tkinase_map\n";
print OUT "p-peptide\tProtein description\tGene name(s)\tFASTA name\tPhospho-sites\tUnique phospho-motifs, no residue numbers\tAccessions\tPhospho-motifs for all members of protein group with residue numbers\t";

# print the PhosphoSite regulatory data
print OUT "Domain\tON_FUNCTION\tON_PROCESS\tON_PROT_INTERACT\tON_OTHER_INTERACT\tPhosphoSite notes\t";

# print the sample names
for my $i (0 .. $#samples) { print OUT "$samples[$i]\t"; }

# print the kinases and groups
for my $i (0 .. $#kinases_observed) {
    my $temp = $kinases_observed[$i]."_NetworKIN";
    print OUT "$temp\t";
    push(@kinases_observed_lbl, $temp);
}
for my $i (0 .. $#motif_sequence) {
    print OUT "$motif_type{$motif_sequence[$i]} ($motif_sequence[$i])\t";
}
for my $i (0 .. $#kinases_PhosphoSite) {
    my $temp = $kinases_PhosphoSite[$i]."_PhosphoSite";
    if ($i < $#kinases_PhosphoSite) { print OUT "$temp\t"; }
    if ($i == $#kinases_PhosphoSite) { print OUT "$temp\n"; }
    push(@phosphosites_observed_lbl, $temp);
}

# begin DDL-to-SQLite
# ---
$dbh = DBI->connect("dbi:SQLite:$db_out", undef, undef);
$auto_commit = $dbh->{AutoCommit};
$dbh->{AutoCommit} = 0;
print "DB connection $dbh is to $db_out, opened for modification\n";

my $sample_stmth;
$sample_stmth = $dbh->prepare("
  INSERT INTO sample (
    id,
    name
  ) VALUES (?,?)
");

my $ppep_intensity_stmth;
$ppep_intensity_stmth = $dbh->prepare("
  INSERT INTO ppep_intensity (
    ppep_id,
    sample_id,
    intensity
  ) VALUES (?,?,?)
");

my $site_type_stmth;
$site_type_stmth = $dbh->prepare("
  insert into site_type (
    id,
    type_name
  ) values (?,?)
");

my $ppep_gene_site_stmth;
$ppep_gene_site_stmth = $dbh->prepare("
  insert into ppep_gene_site (
    ppep_id,
    gene_names,
    kinase_map,
    site_type_id
  ) values (?,?,?,?)
");

my $ppep_metadata_stmth;
$ppep_metadata_stmth = $dbh->prepare("
  INSERT INTO ppep_metadata
    ( ppep_id
    , protein_description
    , gene_name
    , FASTA_name
    , phospho_sites
    , motifs_unique
    , accessions
    , motifs_all_members
    , domain
    , ON_FUNCTION
    , ON_PROCESS
    , ON_PROT_INTERACT
    , ON_OTHER_INTERACT
    , notes
  ) VALUES (
    ?,?,?,?,?,?,?
  , ?,?,?,?,?,?,?
  )
");
# end DDL-to-SQLite
# ...

# begin store-to-SQLite "sample" table
# ---
# %sample_id_lut maps name -> ID
for my $sample_name (keys %sample_id_lut) {
    $sample_stmth->bind_param( 2, $sample_name                 );
    $sample_stmth->bind_param( 1, $sample_id_lut{$sample_name} );
    if (not $sample_stmth->execute()) {
        print "Error writing tuple ($sample_name,$sample_id_lut{$sample_name}): $sample_stmth->errstr\n";
    }
}
# end store-to-SQLite "sample" table
# ...

# begin store-to-SQLite "site_type" table
# ---
sub add_site_type {
    my ($site_type_id, $site_type_type_name) = @_;
    $site_type_stmth->bind_param( 2, $site_type_type_name );
    $site_type_stmth->bind_param( 1, $site_type_id        );
    if (not $site_type_stmth->execute()) {
        die "Error writing tuple ($site_type_id,$site_type_type_name): $site_type_stmth->errstr\n";
    }
}
add_site_type($SITE_KINASE_SUBSTRATE, $site_description{$SITE_KINASE_SUBSTRATE});
add_site_type($SITE_MOTIF, $site_description{$SITE_MOTIF});
add_site_type($SITE_PHOSPHOSITE, $site_description{$SITE_PHOSPHOSITE});
# end store-to-SQLite "site_type" table
# ...

foreach my $peptide (sort(keys %data)) {
    next if (grep($peptide, @failed_matches));
    my $ppep_id = $ppep_id_lut{$peptide};
    my @ppep_metadata = ();
    my @ppep_intensity = ();
    my @gene = ();
    my $gene_names;
    my $j;
    # Print the peptide itself
    #   column 1: p-peptide
    print OUT "$peptide\t";
    push (@ppep_metadata, $ppep_id);
    push (@ppep_intensity, $peptide);

    my $verbose_cond = 0; # $peptide eq 'AAAAAAAGDpSDpSWDADAFSVEDPVR' || $peptide eq 'KKGGpSpSDEGPEPEAEEpSDLDSGSVHSASGRPDGPVR';
    # skip over failed matches
    print "\nfirst match for '$peptide' is '$matched_sequences{$peptide}[0]' and FAILED_MATCH_SEQ is '$FAILED_MATCH_SEQ'\n" if $verbose_cond;
    if ($matched_sequences{$peptide}[0] eq $FAILED_MATCH_SEQ) {
        # column 2: Protein description
        # column 3: Gene name(s)
        # column 4: FASTA name
        # column 5: phospho-residues
        # Column 6: UNIQUE phospho-motifs
        # Column 7: accessions
        # Column 8: ALL motifs with residue numbers
        #          2                                     3   4   5   6   7   8
        print OUT "Sequence not found in FASTA database\tNA\tNA\tNA\tNA\tNA\tNA\t";
        print "No match found for '$peptide' in sequence database\n";
        $gene_names = '$FAILED_MATCH_GENE_NAME';
    } else {
        my @description = ();
        my %seen = ();
        # Print just the protein description
        for $i (0 .. $#{$names{$peptide}}) {
            my $long_name = $names{$peptide}[$i];
            my @naming_parts = split(/\sOS/, $long_name);
            my @front_half = split(/\s/, $naming_parts[0]);
            push(@description, join(" ", @front_half[1..($#front_half)]));
        }
        # column 2: Protein description
        print OUT join(" /// ", @description), "\t";
        push (@ppep_metadata, join(" /// ", @description));

        # Print just the gene name
        for $i (0 .. $#{$names{$peptide}}) {
            my $tmp_gene = $names{$peptide}[$i];
            $tmp_gene =~ s/^.*GN=//;
            $tmp_gene =~ s/\s.*//;
            if (!exists($seen{$tmp_gene})) {
                push(@gene, $tmp_gene);
                $seen{$tmp_gene} = $tmp_gene;
            }
        }
        # column 3: Gene name(s)
        $gene_names = join(" /// ", @gene);
        print OUT $gene_names, "\t";
        push (@ppep_metadata, join(" /// ", @gene));

        # column 4: FASTA name
        print OUT join(" /// ", @{$names{$peptide}}), "\t";
        push (@ppep_metadata, join(" /// ", @{$names{$peptide}}));

        # column 5: phospho-residues
        my $tmp_for_insert = "";
        my $foobar;
        for my $i (0 .. $#{ $matched_sequences{$peptide} } ) {
            print "match $i for '$peptide' is '$matched_sequences{$peptide}[$i]'\n" if $verbose_cond;
            if ($i < $#{ $matched_sequences{$peptide} }) {
                if (defined $p_residues{$peptide}{$i}) {
                    @tmp_p_residues = @{$p_residues{$peptide}{$i}};
                    for $j (0 .. $#tmp_p_residues) {
                        if ($j < $#tmp_p_residues) {
                            my $tmp_site_for_printing = $p_residues{$peptide}{$i}[$j] + 1;        # added 12.05.2012 for Justin's data
                            print OUT "p$residues{$peptide}{$i}[$j]$tmp_site_for_printing, ";
                            $tmp_for_insert .= "p$residues{$peptide}{$i}[$j]$tmp_site_for_printing, ";
                        }
                        elsif ($j == $#tmp_p_residues) {
                            my $tmp_site_for_printing = $p_residues{$peptide}{$i}[$j] + 1;        # added 12.05.2012 for Justin's data
                            print OUT "p$residues{$peptide}{$i}[$j]$tmp_site_for_printing /// ";
                            $tmp_for_insert .= "p$residues{$peptide}{$i}[$j]$tmp_site_for_printing /// ";
                        }
                    }
                }
            }
            elsif ($i == $#{ $matched_sequences{$peptide} }) {
                my $there_were_sites = 0;
                if (defined $p_residues{$peptide}{$i}) {
                    @tmp_p_residues = @{$p_residues{$peptide}{$i}};
                    if ($#tmp_p_residues > 0) {
                        for my $j (0 .. $#tmp_p_residues) {
                            if ($j < $#tmp_p_residues) {
                                if (defined $p_residues{$peptide}{$i}[$j]) {
                                    my $tmp_site_for_printing = $p_residues{$peptide}{$i}[$j] + 1;        # added 12.05.2012 for Justin's data
                                    $foobar = $residues{$peptide}{$i}[$j];
                                    if (defined $foobar) {
                                        print OUT "$foobar";
                                        print OUT "$tmp_site_for_printing, ";
                                        $tmp_for_insert .= "p$residues{$peptide}{$i}[$j]$tmp_site_for_printing, ";
                                        $there_were_sites = 1;
                                    }
                                }
                            }
                            elsif ($j == $#tmp_p_residues) {
                                if (defined $p_residues{$peptide}{$i}[$j]) {
                                    $foobar = $residues{$peptide}{$i}[$j];
                                    if (defined $foobar) {
                                        my $tmp_site_for_printing = $p_residues{$peptide}{$i}[$j] + 1;        # added 12.05.2012 for Justin's data
                                        print OUT "$foobar";
                                        print OUT "$tmp_site_for_printing\t";
                                        $tmp_for_insert .= "p$residues{$peptide}{$i}[$j]$tmp_site_for_printing";
                                        $there_were_sites = 1;
                                    }
                                }
                            }
                        }
                    }
                }
                if (0 == $there_were_sites) {
                  print OUT "\t";
                }
            }
        }
        print "tmp_for_insert '$tmp_for_insert' for '$peptide'\n" if $verbose_cond;
        push (@ppep_metadata, $tmp_for_insert);

        # Column 6: UNIQUE phospho-motifs
        print OUT join(" /// ", @{$unique_motifs{$peptide}}), "\t";
        push (@ppep_metadata, join(" /// ", @{$unique_motifs{$peptide}}));

        # Column 7: accessions
        if (defined $accessions{$peptide}) {
            print OUT join(" /// ", @{$accessions{$peptide}}), "\t";
            push (@ppep_metadata, join(" /// ", @{$accessions{$peptide}}));
        } else {
            print OUT "\t";
            push (@ppep_metadata, "");
        }

        # Column 8: ALL motifs with residue numbers
        if (defined $p_motifs{$peptide}) {
            print OUT join(" /// ", @{$p_motifs{$peptide}}), "\t";
            push (@ppep_metadata, join(" /// ", @{$p_motifs{$peptide}}));
        } else {
            print OUT "\t";
            push (@ppep_metadata, "");
        }

    }

    # Print the PhosphoSite regulatory data

    if (defined $domain_2{$peptide})            { print OUT "$domain_2{$peptide}\t";            } else { print OUT "\t"; }
    if (defined $ON_FUNCTION_2{$peptide})       { print OUT "$ON_FUNCTION_2{$peptide}\t";       } else { print OUT "\t"; }
    if (defined $ON_PROCESS_2{$peptide})        { print OUT "$ON_PROCESS_2{$peptide}\t";        } else { print OUT "\t"; }
    if (defined $ON_PROT_INTERACT_2{$peptide})  { print OUT "$ON_PROT_INTERACT_2{$peptide}\t";  } else { print OUT "\t"; }
    if (defined $ON_OTHER_INTERACT_2{$peptide}) { print OUT "$ON_OTHER_INTERACT_2{$peptide}\t"; } else { print OUT "\t"; }
    if (defined $notes_2{$peptide})             { print OUT "$notes_2{$peptide}\t";             } else { print OUT "\t"; }

    if (defined $domain_2{$peptide})            { push (@ppep_metadata, $domain_2{$peptide});            } else { push(@ppep_metadata, ""); }
    if (defined $ON_FUNCTION_2{$peptide})       { push (@ppep_metadata, $ON_FUNCTION_2{$peptide});       } else { push(@ppep_metadata, ""); }
    if (defined $ON_PROCESS_2{$peptide})        { push (@ppep_metadata, $ON_PROCESS_2{$peptide});        } else { push(@ppep_metadata, ""); }
    if (defined $ON_PROT_INTERACT_2{$peptide})  { push (@ppep_metadata, $ON_PROT_INTERACT_2{$peptide});  } else { push(@ppep_metadata, ""); }
    if (defined $ON_OTHER_INTERACT_2{$peptide}) { push (@ppep_metadata, $ON_OTHER_INTERACT_2{$peptide}); } else { push(@ppep_metadata, ""); }
    if (defined $notes_2{$peptide})             { push (@ppep_metadata, $notes_2{$peptide});             } else { push(@ppep_metadata, ""); }

    # begin store-to-SQLite "ppep_metadata" table
    # ---
    for $i (1..14) {
        $ppep_metadata_stmth->bind_param($i, $ppep_metadata[$i-1]);
    }
    if (not $ppep_metadata_stmth->execute()) {
        print "Error writing ppep_metadata row for phosphopeptide $ppep_metadata[$i]: $ppep_metadata_stmth->errstr\n";
    }
    # ...
    # end store-to-SQLite "ppep_metadata" table

    # Print the data
    @tmp_data = ();
    foreach (@{$data{$peptide}}) {
        push(@tmp_data, $_);
    }
    print OUT join("\t", @tmp_data), "\t";

    # begin store-to-SQLite "ppep_intensity" table
    # ---
    # commit the sample intensities
    $i = 0;
    foreach (@{$data{$peptide}}) {
        my $intense = $_;
        $ppep_intensity_stmth->bind_param( 1, $ppep_id                     );
        $ppep_intensity_stmth->bind_param( 2, $sample_id_lut{$samples[$i]} );
        $ppep_intensity_stmth->bind_param( 3, $intense                     );
        if (not $ppep_intensity_stmth->execute()) {
            print "Error writing tuple ($peptide,$samples[$i],$intense): $ppep_intensity_stmth->errstr\n";
        }
        $i += 1;
    }
    # ...
    # end store-to-SQLite "ppep_intensity" table

    # print the kinase-substrate data
    for my $i (0 .. $#kinases_observed) {
        if (exists($kinase_substrate_NetworKIN_matches{$peptide}{$kinases_observed[$i]})) {
            print OUT "X\t";
            my $NetworKIN_label = $kinases_observed[$i]."_NetworKIN";
            print MELT "$peptide\t$gene_names\t$site_description{$SITE_KINASE_SUBSTRATE}\t$NetworKIN_label\n";
            # begin store-to-SQLite "ppep_gene_site" table
            # ---
            $ppep_gene_site_stmth->bind_param(1, $ppep_id);               # ppep_gene_site.ppep_id
            $ppep_gene_site_stmth->bind_param(2, $gene_names);            # ppep_gene_site.gene_names
            $ppep_gene_site_stmth->bind_param(3, $NetworKIN_label);       # ppep_gene_site.kinase_map
            $ppep_gene_site_stmth->bind_param(4, $SITE_KINASE_SUBSTRATE); # ppep_gene_site.site_type_id
            if (not $ppep_gene_site_stmth->execute()) {
                print "Error writing tuple ($peptide,$gene_names,$kinases_observed[$i]): $ppep_gene_site_stmth->errstr\n";
            }
            # ...
            # end store-to-SQLite "ppep_gene_site" table
        }
        else { print OUT "\t";}
    }
    my %wrote_motif;
    my $motif_parts_0;
    for my $i (0 .. $#motif_sequence) {
        if (exists($kinase_motif_matches{$peptide}{$motif_sequence[$i]})) {
            print OUT "X\t";
            $motif_parts_0 = $motif_type{$motif_sequence[$i]}." ".$motif_sequence[$i];
            my $key = "$peptide\t$gene_names\t$motif_parts_0";
            if (!exists($wrote_motif{$key})) {
                $wrote_motif{$key} = $key;
                print MELT "$peptide\t$gene_names\t$site_description{$SITE_MOTIF}\t$motif_parts_0\n";
                # print "Line 657: i is $i\t$kinase_motif_matches{$peptide}{$motif_sequence[$i]}\n";            #debug
                # begin store-to-SQLite "ppep_gene_site" table
                # ---
                $ppep_gene_site_stmth->bind_param(1, $ppep_id);        # ppep_gene_site.ppep_id
                $ppep_gene_site_stmth->bind_param(2, $gene_names);     # ppep_gene_site.gene_names
                $ppep_gene_site_stmth->bind_param(3, $motif_parts_0); # ppep_gene_site.kinase_map
                $ppep_gene_site_stmth->bind_param(4, $SITE_MOTIF);     # ppep_gene_site.site_type_id
                if (not $ppep_gene_site_stmth->execute()) {
                    print "Error writing tuple ($peptide,$gene_names,$motif_parts_0): $ppep_gene_site_stmth->errstr\n";
                }
                # ...
                # end store-to-SQLite "ppep_gene_site" table
            }
        }
        else { print OUT "\t";}
    }
    for my $i (0 .. $#kinases_PhosphoSite) {
        if (exists($kinase_substrate_PhosphoSite_matches{$peptide}{$kinases_PhosphoSite[$i]})) {
            print MELT "$peptide\t$gene_names\t$site_description{$SITE_PHOSPHOSITE}\t$phosphosites_observed_lbl[$i]\n";
            if ($i < $#kinases_PhosphoSite) {
                print OUT "X\t";
            }
            else {
                print OUT "X\n";
            }
            # begin store-to-SQLite "ppep_gene_site" table
            # ---
            $ppep_gene_site_stmth->bind_param(1, $ppep_id);                       # ppep_gene_site.ppep_id
            $ppep_gene_site_stmth->bind_param(2, $gene_names);                    # ppep_gene_site.gene_names
            $ppep_gene_site_stmth->bind_param(3, $phosphosites_observed_lbl[$i]); # ppep_gene_site.kinase_map
            $ppep_gene_site_stmth->bind_param(4, $SITE_PHOSPHOSITE);              # ppep_gene_site.site_type_id
            if (not $ppep_gene_site_stmth->execute()) {
                print "Error writing tuple ($peptide,$gene_names,$phosphosites_observed_lbl[$i]): $ppep_gene_site_stmth->errstr\n";
            }
            # ...
            # end store-to-SQLite "ppep_gene_site" table
        }
        else {
            if ($i < $#kinases_PhosphoSite) {
                print OUT "\t";
            }
            elsif ($i == $#kinases_PhosphoSite) {
                print OUT "\n";
            }
        }
    }
}

close OUT;
close MELT;
$ppep_gene_site_stmth->finish;
print "begin DB commit at " . format_localtime_iso8601() . "\n";
$dbh->{AutoCommit} = $auto_commit;
$dbh->disconnect if ( defined $dbh );

print "\nFinished writing output at " . format_localtime_iso8601() ."\n\n";

###############################################################################################################################
