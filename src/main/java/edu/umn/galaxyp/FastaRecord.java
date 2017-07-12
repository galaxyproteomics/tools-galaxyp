package edu.umn.galaxyp;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import java.util.logging.Logger;

/**
 * Created by caleb on 6/28/17.
 */

public class FastaRecord {
    private static final Logger logger = Logger.getLogger(FastaRecord.class.getName());
    private String header;
    private String sequence;
    private boolean isDnaSequence;
    private boolean isRnaSequence;
    private boolean isValidFastaHeader;
    private String accession;
    private boolean hasAccession;
    private Header.DatabaseType databaseType;
    private Set<String> sequenceSet;
    private int sequenceLength;

    // default constructor
    public FastaRecord(){
    }

    /**
     * For gathering data on one FASTA record (header followed by sequence). Sets all variables.
     *
     * @param header
     * @param sequence
     */

    public FastaRecord(String header,
                       String sequence) {
        this.header = header;
        this.sequence = sequence;

        // strip any newline characters off for length measurement
        this.sequenceLength = sequence.replaceAll("\n", "").length();

        // create set that contains all symbols in sequence
        this.sequenceSet = new HashSet<>();
        for (int i = 0; i < this.sequence.length(); i++){
            this.sequenceSet.add(this.sequence.substring(i, i + 1));
        }

        // protein vs. dna or rna
        this.isDnaSequence = isDNA();
        this.isRnaSequence = isRNA();

        // check if is valid header
        Header headerParsed;

        try {
            // attempt to parse the header
            headerParsed = Header.parseFromFASTA(header);

            // add database record to databaseTypeMultiset
            this.setDatabaseType(headerParsed.getDatabaseType());

            // if try succeeds, then this is a valid header
            this.isValidFastaHeader = true;

            // test for presence of accession number
            this.accession = headerParsed.getAccession();
            this.hasAccession = checkAccession(accession);

        } catch(Exception e){

            // if fails, then this is an invalid header
            this.isValidFastaHeader = false;

            // still set database type
            this.setDatabaseType(null);

            // print nothing (isValidFastaHeader = false will cause Sys.exit(1) above)
            e.getMessage();
        }

    }



    /**
     * Gathering data on sequence alone. used for testing DNA and RNA checks
     *
     * @param sequence
     */
    public FastaRecord(String sequence) {
        this.sequence = sequence;
        this.sequenceLength = sequence.length();

        this.sequenceSet = new HashSet<>();

        // create set that contains all symbols in sequence
        Set<String> lettersInSeq = new HashSet<String>();
        for (int i = 0; i < this.sequence.length(); i++){
            this.sequenceSet.add(this.sequence.substring(i, i + 1));
        }

        // protein vs. dna or rna
        this.isDnaSequence = isDNA();
        this.isRnaSequence = isRNA();
    }

    private boolean checkAccession(String accession){
        if (accession == null) {
            return false;
        } else if (accession.equals("") || accession.equals(" ")){
            return false;
        } else {
            return true;
        }
    }
    /**
     * checks if a sequence is a DNA or RNA sequence. assumes
     * that if a sequence contains only ACTG, is DNA, and if only
     * contains ACUG, is RNA
     *
     * @return true if only letters in sequence are A, C, T, and G OR A, C, U, and G
     */
    private boolean isDNA(){
        Set<String> nucleotidesRNA = new HashSet<>();
        nucleotidesRNA.addAll(Arrays.asList("A", "C", "T", "G", "\n", " "));

        return (nucleotidesRNA.containsAll(sequenceSet)) ;
    }

    /**
     * checks if a sequence is a DNA or RNA sequence. assumes
     * that if a sequence contains only ACTG, is DNA, and if only
     * contains ACUG, is RNA
     *
     * @return true if only letters in sequence are A, C, T, and G OR A, C, U, and G
     */
    private boolean isRNA(){

        Set<String> nucleotidesRNA = new HashSet<>();
        nucleotidesRNA.addAll(Arrays.asList("A", "C", "U", "G", "\n", " "));

        return (nucleotidesRNA.containsAll(sequenceSet)) ;
    }


    public String getHeader() {
        return header;
    }

    public void setHeader(String header) {
        this.header = header;
    }

    public String getSequence() {
        return sequence;
    }

    public void setSequence(String sequence) {
        this.sequence = sequence;
    }

    public boolean isDnaSequence() {
        return isDnaSequence;
    }

    public void setDnaSequence(boolean dnaSequence) {
        isDnaSequence = dnaSequence;
    }

    public boolean isRnaSequence() {
        return isRnaSequence;
    }

    public void setRnaSequence(boolean rnaSequence) {
        isRnaSequence = rnaSequence;
    }

    public boolean isValidFastaHeader() {
        return isValidFastaHeader;
    }

    public void setValidFastaHeader(boolean validFastaHeader) {
        isValidFastaHeader = validFastaHeader;
    }

    public Header.DatabaseType getDatabaseType() {
        return databaseType;
    }

    public void setDatabaseType(Header.DatabaseType databaseType) {
        this.databaseType = databaseType;
    }

    public Set<String> getSequenceSet() {
        return sequenceSet;
    }

    public void setSequenceSet(Set<String> sequenceSet) {
        this.sequenceSet = sequenceSet;
    }

    public int getSequenceLength() {
        return sequenceLength;
    }

    public void setSequenceLength(int sequenceLength) {
        this.sequenceLength = sequenceLength;
    }

    public String getAccession() { return accession; }

    public void setAccession(String accession) { this.accession = accession; }

    public boolean getHasAccession() { return hasAccession;    }

    public void setHasAccession(boolean hasAccession) { this.hasAccession = hasAccession;  }
}
