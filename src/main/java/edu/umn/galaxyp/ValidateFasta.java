package edu.umn.galaxyp;
import com.compomics.util.experiment.identification.protein_sequences.SequenceFactory;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.sql.SQLException;

import static java.nio.file.StandardCopyOption.*;


//import org.apache.log4j.*;

public class ValidateFasta {

    //private static Logger logger = Logger.getLogger(ValidateFasta.class.getName());

    public static void main(String[] args) throws IOException, IllegalArgumentException,ClassNotFoundException, SQLException, InterruptedException{

        // read testFasta text file, using SequenceFactory methods
        File fastaFile = new File(args[0]);

        // for copying using NIO
        Path fastaPath = Paths.get(args[0]);

        // create SequenceFactory
        SequenceFactory seq = SequenceFactory.getInstance();

        // load fasta file and index it - will throw an error if the header is wrong
        // if correct, will copy file to new filename
        try {
            seq.loadFastaFile(fastaFile);
            // write copy same file to different output if it passes
            Files.copy(fastaPath, Paths.get(args[1]), StandardCopyOption.REPLACE_EXISTING);

        } catch(IllegalArgumentException e) {
            System.err.println(e.getMessage());
        } finally {
//            // remove .cui file, which is the fasta index
            Path fastaIndexPath = Paths.get(args[0] + ".cui");
            Files.deleteIfExists(fastaIndexPath);
        }


    }
}
