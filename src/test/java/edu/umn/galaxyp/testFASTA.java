package edu.umn.galaxyp;

import org.junit.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.logging.Logger;

import static org.junit.Assert.*;

/**
 * Runs several JUnit tests on the individual FASTA database validations
 */
public class testFASTA {

    // test that the reading and writing process works
    // does not crash if invalid, does not check for protein or length or accession
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

        vfd.readAndWriteFASTAHeader(inPath,
                false,
                outPathGood,
                outPathBad,
                false,
                false,
                0,
                false);

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


    // checks that the DNA check identifies DNA sequences,
    // the RNA identifies RNA sequences,
    // and that neither identify a protein sequence
    @Test
    public void testDNAorRNA() {
        FastaRecord dnaSeq = new FastaRecord("ACTGAACTGAATG");
        FastaRecord rnaSeq = new FastaRecord("ACUGAAUGACUAUUUUUUUACUACUG");
        FastaRecord protSeq = new FastaRecord("EWIWGGFSVDKATLNRFFAFHFILPFTMVALAGVHLTFLHETGSNNPLGLTSDSDKIPFHPYYTIKDFLG");

        assertTrue(dnaSeq.isDnaSequence());
        assertTrue(rnaSeq.isRnaSequence());
        assertFalse(protSeq.isRnaSequence() || protSeq.isDnaSequence());
    }

    // confirm that FastaRecord constructor will identify valid accessions but not
    // invalid accessions
    @Test
    public void testAccessions() {
        Logger logger = Logger.getLogger("testAccessions");

        FastaRecord hasNotAccession = new FastaRecord(">generic||1",
                "MNLQKFSRYPLTFGPTPIQPLKRLSAHLGGKVELYAKRDDCNSGLAFGGNKTRKLEYLIP");
        FastaRecord differentBadAccession = new FastaRecord(">generic| |01",
                "MNLQKFSRYPLTFGPTPIQPLKRLSAHLGGKVELYAKRDDCNSGLAFGGNKTRKLEYLIP");
        FastaRecord thirdBadAccession = new FastaRecord(">MCHU - Calmodulin - Human, rabbit, bovine, rat, and chicken",
                "MNLQKFSRYPLTFGPTPIQPLKRLSAHLGGKVELYAKRDDCNSGLAFGGNKTRKLEYLIP");

        FastaRecord hasAccession = new FastaRecord(
                ">sp|Q62CE3|1A1D_BURMA 1-aminocyclopropane-1-carboxylate deaminase OS=Burkholderia mallei (strain ATCC 23344) GN=acdS PE=3 SV=1",
                "MNLQKFSRYPLTFGPTPIQPLKRLSAHLGGKVELYAKRDDCNSGLAFGGNKTRKLEYLIP");

        // good accession
        assertTrue(hasAccession.getHasAccession());

        // bad accessions
        assertFalse(hasNotAccession.getHasAccession());
        assertFalse(differentBadAccession.getHasAccession());
        assertFalse(thirdBadAccession.getHasAccession());
    }

    @Test
    public void testLengthCheck() {
        Logger logger = Logger.getLogger("testLengthCheck");

        // create fasta database object
        ValidateFastaDatabase vfd = new ValidateFastaDatabase();

        FastaRecord tooShort = new FastaRecord("MNLQ");
        FastaRecord longEnough = new FastaRecord("MNLQAA");
        FastaRecord nullSeq = new FastaRecord("");

        assertFalse(vfd.passBelowMinimumLength(true, 5, tooShort));
        assertTrue(vfd.passBelowMinimumLength(true, 5, longEnough));
        assertFalse(vfd.passBelowMinimumLength(true, 5, nullSeq));
    }

    @Test
    public void testValidFastaHeader() {
        Logger logger = Logger.getLogger("testValidFastaHeader");

        FastaRecord valid = new FastaRecord(">generic|001", "MMAATK");
        FastaRecord invalid = new FastaRecord(">generic001", "MMATK");

        assertTrue(valid.isValidFastaHeader());
        assertFalse(invalid.isValidFastaHeader());
    }
}