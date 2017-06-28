package edu.umn.galaxyp;

import org.junit.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import static org.junit.Assert.*;

/**
 * Created by caleb on 6/21/17.
 *
 * Testing FastaInput method by comparing
 * to the same file read in by the FastaInput method of the FASTA class
 */
public class testFASTA {

    @Test
    public void testInOutFASTA() {
        Path inPath = Paths.get("./src/test/java/edu/umn/galaxyp/goodAndBadFasta.fasta");

        // files actually obtained from method
        Path outPathGood = Paths.get("./src/test/java/edu/umn/galaxyp/fastaFilteringTest_obtained_GOOD.fasta");
        Path outPathBad = Paths.get("./src/test/java/edu/umn/galaxyp/fastaFilteringTest_obtained_BAD.fasta");

        // expected files
        Path outPathGoodExpected = Paths.get("./src/test/java/edu/umn/galaxyp/goodFasta.fasta");
        Path outPathBadExpected = Paths.get("./src/test/java/edu/umn/galaxyp/badFasta.fasta");

        MultiSet<Header.DatabaseType> databaseTypes =
                FASTA.readFASTAHeader(inPath, false,
                    outPathGood, outPathBad, false, false, 0);

        // read in files
        try {
            byte[] expectedGood = Files.readAllBytes(outPathGoodExpected);
            byte[] expectedBad = Files.readAllBytes(outPathBadExpected);
            byte[] actualGood = Files.readAllBytes(outPathGood);
            byte[] actualBad = Files.readAllBytes(outPathBad);

            assertArrayEquals(expectedGood, actualGood);
            assertArrayEquals(expectedBad, actualBad);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Test
    public void testDNAorRNA() {
        String dnaSeq = "ACTGAACTGAATG";
        String rnaSeq = "ACUGAAUGACUAUUUUUUUACUACUG";
        String protSeq = "EWIWGGFSVDKATLNRFFAFHFILPFTMVALAGVHLTFLHETGSNNPLGLTSDSDKIPFHPYYTIKDFLG";

        assertTrue(FASTA.isDnaOrRnaSequence(dnaSeq));
        assertTrue(FASTA.isDnaOrRnaSequence(rnaSeq));
        assertFalse(FASTA.isDnaOrRnaSequence(protSeq));
    }
}