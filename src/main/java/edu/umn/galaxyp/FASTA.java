package edu.umn.galaxyp;

import com.compomics.util.protein.Header;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.logging.Logger;

/**
 * Created by caleb on 6/21/17.
 *
 *
 * a HashMap of headers (in String form) and sequences
 *
 */
public class FASTA {
    private Map<String, String> fastaHeaderMap;
    private static final Logger logger = Logger.getLogger(FASTA.class.getName());

    // default constructor
    public FASTA(){
    }

    // constructor that takes the path of the FASTA file
    public FASTA(Path path){

        // LinkedHashMap will (probably) result in the same ordering of the FASTA file
        fastaHeaderMap = new LinkedHashMap<>();
        StringBuilder sequence = new StringBuilder(); // allows us to append all sequences of line

        // automatically closes reader if IOException
        try (BufferedReader br = Files.newBufferedReader(path)){
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

                    // add header and sequence to HashMap
                    fastaHeaderMap.put(header, sequence.toString());

                    // empty the sequence builder to allow for appending the next sequence
                    sequence.setLength(0);
                }
            }

        } catch(IOException e) {
            logger.severe("FASTA file not found: " + e.toString());
        }
    }

    public Map<String, String> getFastaHeaderMap() {
        return fastaHeaderMap;
    }

    public void setFastaHeaderMap(Map<String, String> fastaHeaderMap) {
        this.fastaHeaderMap = fastaHeaderMap;
    }

    /* direct good and bad FASTA sequences into different text files
     */
    public Map<String, Integer> sortFastaByHeader(Path goodFASTA, Path badFASTA, Boolean crash_if_invalid){
        Iterator fastaMapIterator = this.fastaHeaderMap.entrySet().iterator();
        Map<String, Integer> countSequences = new HashMap<>();
        countSequences.put("Passed", 0);
        countSequences.put("Failed", 0);

        try (BufferedWriter bwGood = Files.newBufferedWriter(goodFASTA);
             BufferedWriter bwBad = Files.newBufferedWriter(badFASTA)){
                while (fastaMapIterator.hasNext()) {
                    Map.Entry pair = (Map.Entry) fastaMapIterator.next();
                    String header = (String) pair.getKey();
                    String sequence = (String) pair.getValue();


                    if (isValidFastaHeader(header, crash_if_invalid)) {
                        bwGood.write(header, 0, header.length());
                        bwGood.write(sequence, 0, sequence.length());
                        countSequences.put("Passed", countSequences.get("Passed")+1);
                    } else {
                        bwBad.write(header, 0, header.length());
                        bwBad.write(sequence, 0, sequence.length());
                        countSequences.put("Failed", countSequences.get("Failed")+1);
                    }
                }
            } catch(IOException e) {
                     e.printStackTrace();
        }
        return countSequences;
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

    // checks FASTA header for validity, using compomics method `Header.parseFromFASTA()`
    // Returns true if header is valid
    public static boolean isValidFastaHeader(String aFastaHeader, boolean crash_if_invalid){
        Header header = null;
        try {
            // set out to dummy stream for Header method
            System.setOut(dummyStream);

            // attempt to parse the header
            header = Header.parseFromFASTA(aFastaHeader);

            // return to regular system out
            System.setOut(originalStream);
        } catch(IllegalArgumentException iae){
            // return exit code of 1 (abnormal termination)
            if (crash_if_invalid) {
                System.err.println("Invalid FASTA headers detected. Exit requested by user. ");
                System.exit(1);
            }
            // else, print nothing
            iae.getMessage();
        }
        if (header == null){
            return false;
        } else {
            return true;
        }
    }
}
