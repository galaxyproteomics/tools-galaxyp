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
        ValidateFastaDatabase vfd = new ValidateFastaDatabase();

        Path inPath = Paths.get("./src/test/java/edu/umn/galaxyp/goodAndBadFasta.fasta");

        // files actually obtained from method
        Path outPathGood = Paths.get("./src/test/java/edu/umn/galaxyp/fastaFilteringTest_obtained_GOOD.fasta");
        Path outPathBad = Paths.get("./src/test/java/edu/umn/galaxyp/fastaFilteringTest_obtained_BAD.fasta");

        // expected files
        Path outPathGoodExpected = Paths.get("./src/test/java/edu/umn/galaxyp/goodFasta.fasta");
        Path outPathBadExpected = Paths.get("./src/test/java/edu/umn/galaxyp/badFasta.fasta");

        vfd.readFASTAHeader(inPath,
                false,
                outPathGood,
                outPathBad,
                false,
                false,
                0);

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
        FastaRecord dnaSeq = new FastaRecord("ACTGAACTGAATG");
        FastaRecord rnaSeq = new FastaRecord("ACUGAAUGACUAUUUUUUUACUACUG");
        FastaRecord protSeq = new FastaRecord("EWIWGGFSVDKATLNRFFAFHFILPFTMVALAGVHLTFLHETGSNNPLGLTSDSDKIPFHPYYTIKDFLG");

        assertTrue(dnaSeq.isDnaSequence());
        assertTrue(rnaSeq.isRnaSequence());
        assertFalse(protSeq.isRnaSequence() || protSeq.isDnaSequence());
    }
}