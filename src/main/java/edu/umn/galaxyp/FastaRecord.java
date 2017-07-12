package edu.umn.galaxyp;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import java.util.logging.Logger;

/**
 * Contains a single FASTA database entry
 */

public class FastaRecord {
    private static final Logger logger = Logger.getLogger(FastaRecord.class.getName());

    private String header;
    private String sequence;
    private String sequenceTrimmed;
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
     * @param header raw FASTA header from file - should still start with '>'
     * @param sequence raw FASTA sequence from file - may contain newline characters
     */

    public FastaRecord(String header,
                       String sequence) {

        this.header = header;

        // populates sequence, sequenceTrimmed, isDna/RnaSequence, sequenceSet, and sequenceLength
        initializeSequenceData(sequence);


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
     * @param sequence raw sequence from FASTA file
     */
    public FastaRecord(String sequence) {
        initializeSequenceData(sequence);
    }

    private void initializeSequenceData(String sequence) {
        this.sequence = sequence;
        this.sequenceTrimmed = trimSequence();
        this.sequenceLength = this.sequenceTrimmed.length();
        this.sequenceSet = createSequenceSet();

        // protein vs. dna or rna
        this.isDnaSequence = isDNA();
        this.isRnaSequence = isRNA();
    }

    private String trimSequence() {
        // remove newline character, windows carriage return doohickey, tabs, and spaces
        // will remove spaces at end of lines, which is the only place they could be at all
        return this.sequence.replaceAll("[\n\r\t ]", "");
    }

    private Set<String> createSequenceSet(){
        // create set that contains all symbols in sequence
        Set<String> localSequenceSet = new HashSet<>();
        for (int i = 0; i < this.sequenceTrimmed.length(); i++) {
            localSequenceSet.add(this.sequenceTrimmed.substring(i, i + 1));
        }
        return localSequenceSet;
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
        nucleotidesRNA.addAll(Arrays.asList("A", "C", "T", "G"));

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
        nucleotidesRNA.addAll(Arrays.asList("A", "C", "U", "G"));

        return (nucleotidesRNA.containsAll(sequenceSet)) ;
    }

    private boolean isPeptide(){
        Set<String> aminoAcids = new HashSet<>();
        aminoAcids.addAll(Arrays.asList(
                "A", "I", "L", "V",  // aliphatic, hydrophobic side chain
                "F", "W", "Y", // aromatic, hydrophobic side chain
                "N", "C", "Q", "M", "S", "T", // polar neutral side chain
                "D", "E", // charged side chain, acidic
                "R", "H", "K", // charged side chain, basic
                "G", "P" // unique aas
                ));

        return (aminoAcids.containsAll(sequenceSet)) ;
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
