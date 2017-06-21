package edu.umn.galaxyp;

import com.compomics.util.protein.Header;

import java.io.BufferedReader;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Logger;

/**
 * Created by caleb on 6/21/17.
 *
 *
 * a HashMap of headers (in String form) and sequences
 *
 */
public class localFasta {
    private Map<String, String> fastaHeaderMap;
    private static final Logger logger = Logger.getLogger(localFasta.class.getName());

    public Map<String, String> getFastaHeaderMap() {
        return fastaHeaderMap;
    }

    public void setFastaHeaderMap(Map<String, String> fastaHeaderMap) {
        this.fastaHeaderMap = fastaHeaderMap;
    }

    public localFasta(){
    }

    // constructor that takes the path of the FASTA file
    public localFasta(Path path){
        fastaHeaderMap = new HashMap<>();
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

}
