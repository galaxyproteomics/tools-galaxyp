package edu.umn.galaxyp;

//import com.compomics.util.protein.Header;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.*;
import java.util.logging.Logger;

/**
 *
 * The main data contained in FASTA is a HashMap of FASTA headers (in String form) and sequences. *
 *
 * @author caleb
 *
 *
 *
 *
 */
public class FASTA {
    private static final Logger logger = Logger.getLogger(FASTA.class.getName());

    public FASTA(){
    }
    /**
     * takes path to header, reads in FASTA file, and writes out sorted FASTA
     * @param inPath  path to FASTA file to be read in(NIO Path object)
     *  @param crash_if_invalid  if true, a badly formatted header (the first) will immediately cause a System.exit(1)
     * @param checkLength
     * @param minimumLength
     */
    public static MultiSet<Header.DatabaseType> readFASTAHeader(Path inPath,
                                                                boolean crash_if_invalid,
                                                                Path outPathGood,
                                                                Path outPathBad,
                                                                boolean checkIsProtein,
                                                                boolean checkLength,
                                                                int minimumLength){
        MultiSet<Header.DatabaseType> databaseTypesCount = new MultiSet<>();
        Header headerParsed = null;
        StringBuilder sequence = new StringBuilder(); // allows us to append all sequences of line

        try (BufferedWriter bwGood =
                     Files.newBufferedWriter(outPathGood, StandardCharsets.UTF_8,
                                                StandardOpenOption.CREATE);
             BufferedWriter bwBad = Files.newBufferedWriter(outPathBad);
             BufferedReader br = Files.newBufferedReader(inPath)){

            String line = br.readLine();

            // while there are still lines in the file
            while (line != null) {
                // indicates FASTA header line
                if (line.startsWith(">")){
                    String header = line + "\n";
//                    logger.info("Header: " + header);

                    // while there are still lines in the file and the next line is not a header
                    while ((line = br.readLine()) != null && !line.startsWith(">")){
                        sequence.append(line).append("\n");
                    }

                    // check if header is valid
                    boolean isValidHeader = false;
                    try {
                        // attempt to parse the header
                        // set out to dummy stream for Header method, to avoid console output from Header
                        System.setOut(dummyStream);
                        headerParsed = Header.parseFromFASTA(header);
                        Header.DatabaseType dbType = headerParsed.getDatabaseType();
                        databaseTypesCount.add(dbType);
                        // return to regular system out
                        System.setOut(originalStream);
                        isValidHeader = true;
                    } catch(IllegalArgumentException iae){
                        // return exit code of 1 (abnormal termination)
                        if (crash_if_invalid) {
                            System.err.println("Invalid FASTA headers detected. Exit requested by user. ");
                            System.exit(1);
                        }
                        // else, print nothing
                        iae.getMessage();
                    }

                    // TODO run extra checks on sequence

                    // check that is not a DNA or RNA sequence, if requested
                    boolean isDnaOrRna = false;
                    if (checkIsProtein) {
                        isDnaOrRna = isDnaOrRnaSequence(sequence.toString());
                    }

                    // check that it has a minimum length
                    boolean isBelowMinimumLength = false;
                    if (checkLength) {
                        isBelowMinimumLength = sequence.length() < minimumLength;
                    }

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

                    // empty the sequence builder to allow for appending the next sequence
                    sequence.setLength(0);
                }
            }

        } catch(IOException e) {
            logger.severe("FASTA file not found: " + e.toString());
        }
        return databaseTypesCount;
    }

    /**
     * checks if a sequence is a DNA or RNA sequence. assumes
     * that if a sequence contains only ACTG, is DNA, and if only
     * contains ACUG, is RNA
     *
     * @param sequence (supposed) amino acid sequence from FASTA file
     * @return true if only letters in sequence are A, C, T, and G OR A, C, U, and G
     */
    public static boolean isDnaOrRnaSequence(String sequence){
        Set<String> lettersInSeq = new HashSet<String>();
        for (int i = 0; i < sequence.length(); i++){
            lettersInSeq.add(sequence.substring(i, i + 1));
        }

        Set<String> nucleotides = new HashSet<>();
        nucleotides.addAll(Arrays.asList("A", "C", "T", "G", "\n", " "));

        Set<String> nucleotidesRNA = new HashSet<>();
        nucleotidesRNA.addAll(Arrays.asList("A", "C", "U", "G", "\n", " "));

        return (nucleotides.containsAll(lettersInSeq) || nucleotidesRNA.containsAll(lettersInSeq)) ;
    }
    /***
     *
     *hide system output from compomics methods
     *(for very large FASTA, compomics output may overflow
     *standard output in Galaxy)
     *idea from https://stackoverflow.com/questions/8363493/hiding-system-out-print-calls-of-a-class
    */
    private static PrintStream originalStream = System.out;
    private static PrintStream dummyStream = new PrintStream(new OutputStream() {
        @Override
        public void write(int i) throws IOException {
        }
    });
}
