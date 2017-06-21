package edu.umn.galaxyp;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;
import java.util.logging.Logger;

//import org.apache.log4j.*;

public class ValidateFasta {

    private static Logger logger = Logger.getLogger(ValidateFasta.class.getName());

    public static void main(String[] args) {

        // input path
        Path fastaPath = Paths.get(args[0]);

        // load fasta file
        FASTA fasta = new FASTA(fastaPath);

        // performs filtering, I/O, and returns a count of good and bad sequences
        Map<String, Integer> countSequences = fasta.sortFastaByHeader(Paths.get(args[1]), Paths.get(args[2]));
        String prettyPrintMap = "Sequences Passed: " + countSequences.get("Passed").toString() + "\n" +
                "Sequences Failed: " + countSequences.get("Failed").toString();
        // iterate through header strings and write to separate file streams
        System.out.print(prettyPrintMap);
    }
}
