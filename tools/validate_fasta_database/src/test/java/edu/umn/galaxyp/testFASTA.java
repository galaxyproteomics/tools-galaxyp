package edu.umn.galaxyp;

import org.junit.Rule;
import org.junit.Test;
import org.junit.contrib.java.lang.system.ExpectedSystemExit;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import java.util.logging.Logger;

import static org.junit.Assert.*;

/**
 * Runs several JUnit tests on the individual FASTA database validations
 */
public class testFASTA {

    @Rule
    public final ExpectedSystemExit exit = ExpectedSystemExit.none();


    // test System.exit(1) on bad header
    @Test
    public void testExit() {
        ValidateFastaDatabase vfd = new ValidateFastaDatabase();

        Path inPath = Paths.get("./src/test/java/edu/umn/galaxyp/goodAndBadFasta.fasta");

        // files actually obtained from method
        Path outPathGood = Paths.get("./src/test/java/edu/umn/galaxyp/fastaFilteringTest_obtained_GOOD.fasta");
        Path outPathBad = Paths.get("./src/test/java/edu/umn/galaxyp/fastaFilteringTest_obtained_BAD.fasta");

        // expected files
        Path outPathGoodExpected = Paths.get("./src/test/java/edu/umn/galaxyp/goodFasta.fasta");
        Path outPathBadExpected = Paths.get("./src/test/java/edu/umn/galaxyp/badFasta.fasta");
        exit.expectSystemExitWithStatus(1);
        vfd.readAndWriteFASTAHeader(inPath,
                outPathGood,
                outPathBad,
                true,
                false,
                "",
                false,
                0);
    }

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
                outPathGood,
                outPathBad,
                false,
                false,
                "",
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


    // checks that the DNA check identifies DNA sequences,
    // the RNA identifies RNA sequences,
    // and that neither identify a protein sequence
    @Test
    public void testDNAorRNAorAA() {
        // test kind of ugly sequences, with escape characters
        FastaRecord dnaSeq = new FastaRecord("ACTGAACTGAATG\t\r ");
        assertTrue(dnaSeq.isDnaSequence());

        FastaRecord rnaSeq = new FastaRecord("ACUGAAUGACUAUUUUUUUACUACUG");
        assertTrue(rnaSeq.isRnaSequence());

        FastaRecord protSeq = new FastaRecord("EWIWGGFSVDKATLNRFFAFHFILPFTMVALAG"+
                "VHLTFLHETGSNNPLGLTSDSDKIPFHPYYTIKDFLG\n");
        assertTrue(protSeq.getIsAASequence());

        // another prot seq, with non-standard letters
        FastaRecord nonStandardProt = new FastaRecord("EXXYMM", "XY");
        assertTrue(nonStandardProt.getIsAASequence());


        // same sequence, don't add custom letters
        FastaRecord nonStandardProtFail = new FastaRecord("EXXYMM");
        assertFalse(nonStandardProtFail.getIsAASequence());
    }

    // confirm that FastaRecord constructor will identify valid accessions but not
    // invalid accessions
    @Test
    public void testAccessions() {
        Logger logger = Logger.getLogger("testAccessions");

        FastaRecord hasNotAccession = new FastaRecord(">generic||1",
                "MNLQKFSRYPLTFGPTPIQPLKRLSAHLGGKVELYAKRDDCNSGLAFGGNKTRKLEYLIP", "");
        FastaRecord differentBadAccession = new FastaRecord(">generic| |01",
                "MNLQKFSRYPLTFGPTPIQPLKRLSAHLGGKVELYAKRDDCNSGLAFGGNKTRKLEYLIP", "");
        FastaRecord thirdBadAccession = new FastaRecord(">MCHU - Calmodulin - Human, rabbit, bovine, rat, and chicken",
                "MNLQKFSRYPLTFGPTPIQPLKRLSAHLGGKVELYAKRDDCNSGLAFGGNKTRKLEYLIP", "");

        FastaRecord hasAccession = new FastaRecord(
                ">sp|Q62CE3|1A1D_BURMA 1-aminocyclopropane-1-carboxylate deaminase OS=Burkholderia mallei (strain ATCC 23344) GN=acdS PE=3 SV=1",
                "MNLQKFSRYPLTFGPTPIQPLKRLSAHLGGKVELYAKRDDCNSGLAFGGNKTRKLEYLIP", "");

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

        assertFalse(vfd.passBelowMinimumLength(5, tooShort));
        assertTrue(vfd.passBelowMinimumLength(5, longEnough));
        assertFalse(vfd.passBelowMinimumLength(5, nullSeq));
    }

    @Test
    public void testValidFastaHeader() {
        Logger logger = Logger.getLogger("testValidFastaHeader");

        FastaRecord valid = new FastaRecord(">generic|001", "MMAATK", "");
        FastaRecord invalid = new FastaRecord(">generic001", "MMATK", "");

        assertTrue(valid.isValidFastaHeader());
        assertFalse(invalid.isValidFastaHeader());
    }

    @Test
    public void testSequenceSetCreation() {
        Logger logger = Logger.getLogger("testSequenceSetCreation");

        String sequence = "MMNLQATTY\n\r\t ";
        FastaRecord testSet = new FastaRecord(sequence);

        // expected set does not have \n, \r, \t or space
        Set<String> expectedSet = new HashSet<>(Arrays.asList("M", "N", "L", "Q", "A", "T", "Y"));
        assertTrue(testSet.getSequenceSet().equals(expectedSet));
    }

    @Test
    public void testAddLettersToAminoAcids() {
        Logger logger = Logger.getLogger("testAddLetters");

        String sequence = "MMNLQATTY";
        String customLetters = "XYZ";
        FastaRecord testSet = new FastaRecord(sequence, customLetters);

        //comparison
        Set<String> aminoAcids = new HashSet<>();

        aminoAcids.addAll(Arrays.asList(
                "A", "I", "L", "V",  // aliphatic, hydrophobic side chain
                "F", "W", "Y", // aromatic, hydrophobic side chain
                "N", "C", "Q", "M", "S", "T", // polar neutral side chain
                "D", "E", // charged side chain, acidic
                "R", "H", "K", // charged side chain, basic
                "G", "P", // unique aas
                "X", "Y", "Z" //new letters
        ));

        assertEquals(aminoAcids, testSet.getAminoAcids());
    }
}

