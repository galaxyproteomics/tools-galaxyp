package edu.umn.galaxyp;

//import com.compomics.util.protein.Header;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import java.util.logging.Logger;

//import org.apache.log4j.*;

public class ValidateFastaDatabase {

    private static Logger logger = Logger.getLogger(ValidateFastaDatabase.class.getName());

    private MultiSet<Header.DatabaseType> databaseTypeMultiSet;

    public MultiSet<Header.DatabaseType> getDatabaseTypeMultiSet() {
        return databaseTypeMultiSet;
    }

    public void setDatabaseTypeMultiSet(MultiSet<Header.DatabaseType> databaseTypeMultiSet) {
        this.databaseTypeMultiSet = databaseTypeMultiSet;
    }

    public void addDatabaseType(Header.DatabaseType value){
        this.databaseTypeMultiSet.add(value);
    }

    public ValidateFastaDatabase(){
        this.databaseTypeMultiSet = new MultiSet<Header.DatabaseType>();
    }

    public static void main(String[] args) {

        // construct empty instance of ValidateFastaDatabase, to record database types
        ValidateFastaDatabase vfd = new ValidateFastaDatabase();

        // input path
        Path fastaPath = Paths.get(args[0]);

        // output path for good and bad FASTAs
        Path outGoodFASTA = Paths.get(args[1]);
        Path outBadFASTA = Paths.get(args[2]);

        // if true, the presence of any invalid sequences triggers an exit code of 1
        boolean crash_if_invalid = Boolean.valueOf(args[3]);

        // if true, checks that is not a DNA or RNA sequence
        boolean checkIsProtein = Boolean.valueOf(args[4]);

        // if true, checks that is greater than a minimum length
        boolean checkLength = Boolean.valueOf(args[5]);

        int minimumLength = 0;
        if (checkLength){
            minimumLength = Integer.valueOf(args[6]);
        }

        vfd.readFASTAHeader(fastaPath,
                crash_if_invalid,
                outGoodFASTA,
                outBadFASTA,
                checkIsProtein,
                checkLength,
                minimumLength);

        System.out.println("Database Types");
        System.out.println(vfd.getDatabaseTypeMultiSet().toString());
    }

    /**
     * takes path to header, reads in FASTA file, and writes out sorted FASTA
     * @param inPath  path to FASTA file to be read in(NIO Path object)
     *  @param crash_if_invalid  if true, a badly formatted header (the first) will immediately cause a System.exit(1)
     * @param checkLength
     * @param minimumLength
     */
    public void readFASTAHeader(Path inPath,
                                boolean crash_if_invalid,
                                Path outPathGood,
                                Path outPathBad,
                                boolean checkIsProtein,
                                boolean checkLength,
                                int minimumLength){

        Header headerParsed = null;
        StringBuilder sequence = new StringBuilder(); // allows us to append all sequences of line

        try (BufferedWriter bwGood =
                     Files.newBufferedWriter(outPathGood);
             BufferedWriter bwBad = Files.newBufferedWriter(outPathBad);
             BufferedReader br = Files.newBufferedReader(inPath)){

            String line = br.readLine();

            // while there are still lines in the file
            while (line != null) {
                // indicates FASTA header line
                if (line.startsWith(">")){
                    String header = line + "\n";

                    // while there are still lines in the file and the next line is not a header
                    while ((line = br.readLine()) != null && !line.startsWith(">")){
                        sequence.append(line).append("\n");
                    }

                    // record that is sequentially updated
                    fastaRecord current_record = new fastaRecord(header, sequence.toString());
                    this.addDatabaseType(current_record.getDatabaseType());

                    // write FASTA header and sequence to either good or bad file
                    writeFasta(sequence, bwGood, bwBad, header,
                            current_record.isValidFastaHeader(),
                            current_record.isDnaSequence() || current_record.isRnaSequence(),
                            current_record.getSequenceLength() < minimumLength);

                    // empty the sequence builder to allow for appending the next sequence
                    sequence.setLength(0);
                }
            }

        } catch(IOException e) {
            logger.severe("FASTA file not found: " + e.toString());
        }
    }

    private static void writeFasta(StringBuilder sequence,
                                   BufferedWriter bwGood,
                                   BufferedWriter bwBad,
                                   String header,
                                   boolean isValidHeader,
                                   boolean isDnaOrRna,
                                   boolean isBelowMinimumLength) throws IOException {
        // Write to file
        // isDnaOrRna can only be true if checkIsProtein is true
        // same for checkLength
        if (isValidHeader && !isDnaOrRna && !isBelowMinimumLength) {
            bwGood.write(header, 0, header.length());
            bwGood.write(sequence.toString(), 0, sequence.length());
        } else {
            bwBad.write(header, 0, header.length());
            bwBad.write(sequence.toString(), 0, sequence.length());
        }
    }

//    /**
//     * check if header is valid, according to Compomics schema
//     *
//     * @param crash_if_invalid If true, program with System.exit(1) on first occurence of bad FASTA header
//     * @param header
//     * @return
//     */
//    public boolean isValidHeader(boolean crash_if_invalid, String header) {
//        Header headerParsed;
//        boolean isValidHeader = false;
//        try {
//            // attempt to parse the header
//            headerParsed = Header.parseFromFASTA(header);
//
//            // add database record to databaseTypeMultiset
//            this.addDatabaseType(headerParsed.getDatabaseType());
//
//            isValidHeader = true;
//        } catch(IllegalArgumentException iae){
//            // return exit code of 1 (abnormal termination)
//            if (crash_if_invalid) {
//                System.err.println("Invalid FASTA headers detected. Exit requested by user. ");
//                System.exit(1);
//            }
//            // else, print nothing
//            iae.getMessage();
//        }
//        return isValidHeader;
//    }
//
//    /**
//     * checks if a sequence is a DNA or RNA sequence. assumes
//     * that if a sequence contains only ACTG, is DNA, and if only
//     * contains ACUG, is RNA
//     *
//     * @param sequence (supposed) amino acid sequence from FASTA file
//     * @return true if only letters in sequence are A, C, T, and G OR A, C, U, and G
//     */
//    public static boolean isDnaOrRnaSequence(String sequence){
//        Set<String> lettersInSeq = new HashSet<String>();
//        for (int i = 0; i < sequence.length(); i++){
//            lettersInSeq.add(sequence.substring(i, i + 1));
//        }
//
//        Set<String> nucleotides = new HashSet<>();
//        nucleotides.addAll(Arrays.asList("A", "C", "T", "G", "\n", " "));
//
//        Set<String> nucleotidesRNA = new HashSet<>();
//        nucleotidesRNA.addAll(Arrays.asList("A", "C", "U", "G", "\n", " "));
//
//        return (nucleotides.containsAll(lettersInSeq) || nucleotidesRNA.containsAll(lettersInSeq)) ;
//    }
//    /***
//     *
//     *hide system output from compomics methods
//     *(for very large FASTA, compomics output may overflow
//     *standard output in Galaxy)
//     *idea from https://stackoverflow.com/questions/8363493/hiding-system-out-print-calls-of-a-class
//     */
////    private static PrintStream originalStream = System.out;
////    private static PrintStream dummyStream = new PrintStream(new OutputStream() {
////        @Override
////        public void write(int i) throws IOException {
////        }
////    });
}
