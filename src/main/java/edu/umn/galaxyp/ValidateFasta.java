package edu.umn.galaxyp;

//import com.compomics.util.protein.Header;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.logging.Logger;

//import org.apache.log4j.*;

public class ValidateFasta {

    private static Logger logger = Logger.getLogger(ValidateFasta.class.getName());

    public static void main(String[] args) {

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

        MultiSet<Header.DatabaseType> databaseTypes = FASTA.readFASTAHeader(fastaPath, crash_if_invalid,
                outGoodFASTA, outBadFASTA, checkIsProtein, checkLength, minimumLength);
        System.out.println("Database Types");
        System.out.println(databaseTypes.toString());
    }
}
