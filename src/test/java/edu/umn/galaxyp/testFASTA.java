package edu.umn.galaxyp;

import org.junit.Test;
import java.io.BufferedWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import static org.junit.Assert.*;

/**
 * Created by caleb on 6/21/17.
 *
 * Testing FastaInput method by comparing
 * a copied-and-pasted FASTA file made into a HashMap (copied-and-pasted from testFASTA.txt)
 * to the same file read in by the FastaInput method of the FASTA class
 */
public class testFASTA {

    @Test
    public void testFastaInput() {
        Path testpath = Paths.get("./src/test/java/edu/umn/galaxyp/testFASTA.txt");
        FASTA testFASTA = new FASTA(testpath, false);
        Map<String, String> expectedMap= new HashMap<>();
        expectedMap.put(">MCHU - Calmodulin - Human, rabbit, bovine, rat, and chicken\n", "ADQLTEEQIAEFKEAFSLFDKDGDGTITTKELGTVMRSLGQNPTEAELQDMINEVDADGNGTID\n" +
                "FPEFLTMMARKMKDTDSEEEIREAFRVFDKDGNGYISAAELRHVMTNLGEKLTDEEVDEMIREA\n" +
                "DIDGDGQVNYEEFVQMMTAK*\n");
        expectedMap.put(">gi|5524211|gb||AAD44166.1 cytochrome b [Elephas maximus maximus]\n", "LCLYTHIGRNIYYGSYLYSETWNTGIMLLLITMATAFMGYVLPWGQMSFWGATVITNLFSAIPYIGTNLV\n" +
                "EWIWGGFSVDKATLNRFFAFHFILPFTMVALAGVHLTFLHETGSNNPLGLTSDSDKIPFHPYYTIKDFLG\n" +
                "LLILILLLLLLALLSPDMLGDPDNHMPADPLNTPLHIKPEWYFLFAYAILRSVPNKLGGVLALFLSIVIL\n" +
                "GLMPFLHTSKHRSMMLRPLSQALFWTLTMDLLTLTWIGSQPVEYPYTIIGQMASILYFSIILAFLPIAGX\n" +
                "IENY\n");
        Path writeOut = Paths.get("./src/test/java/edu/umn/galaxyp/testFASTA_OUT.txt");
        try(BufferedWriter bw = Files.newBufferedWriter(writeOut);){
            Iterator it = expectedMap.entrySet().iterator();
            while (it.hasNext()){
                Map.Entry pair = (Map.Entry)it.next();
                String key = (String)pair.getKey();
                bw.write(key, 0, key.length());
                String value = (String)pair.getValue();
                bw.write(value, 0, value.length());
            }
        } catch (IOException e){
            e.printStackTrace();
        }

        assertTrue(expectedMap.equals(testFASTA.getFastaHeaderMap()));
    }

    @Test
    public void testFastaHeaderCheck(){
        Path goodPath = Paths.get("./src/test/java/edu/umn/galaxyp/goodFasta.fasta");
        Path badPath = Paths.get("./src/test/java/edu/umn/galaxyp/badFasta.fasta");
        FASTA badHeaderFASTA = new FASTA(badPath, false);
        FASTA goodHeaderFASTA = new FASTA(goodPath, false);

        Map<String, String> goodHeaderExpected = new HashMap<>();
        goodHeaderExpected.put(">sp|Q62CE3|1A1D_BURMA 1-aminocyclopropane-1-carboxylate deaminase OS=Burkholderia mallei (strain ATCC 23344) GN=acdS PE=3 SV=1\n",
                        "MNLQKFSRYPLTFGPTPIQPLKRLSAHLGGKVELYAKRDDCNSGLAFGGNKTRKLEYLIP\n" +
                        "DALAQGCDTLVSIGGIQSNQTRQVAAVAAHLGMKCVLVQENWVNYHDAVYDRVGNIQMSR\n" +
                        "MMGADVRLVPDGFDIGFRKSWEDALADVRARGGKPYAIPAGCSDHPLGGLGFVGFAEEVR\n" +
                        "AQEAELGFQFDYVVVCSVTGSTQAGMVVGFAADGRADRVIGVDASAKPAQTREQILRIAK\n" +
                        "HTADRVELGRDITSADVVLDERFGGPEYGLPNEGTLEAIRLCAKLEGVLTDPVYEGKSMH\n" +
                        "GMIEKVRLGEFPAGSKVLYAHLGGVPALNAYSFLFRDG\n");
        assertTrue(goodHeaderFASTA.getGoodFastaHeaderMap().equals(goodHeaderExpected));

        Map<String, String> badHeaderExpected = new HashMap<>();
        badHeaderExpected.put(">gi||||5524211gbAAD44166.1 cytochrome b [Elephas maximus maximus]\n",
                        "LCLYTHIGRNIYYGSYLYSETWNTGIMLLLITMATAFMGYVLPWGQMSFWGATVITNLFSAIPYIGTNLV\n" +
                        "EWIWGGFSVDKATLNRFFAFHFILPFTMVALAGVHLTFLHETGSNNPLGLTSDSDKIPFHPYYTIKDFLG\n" +
                        "LLILILLLLLLALLSPDMLGDPDNHMPADPLNTPLHIKPEWYFLFAYAILRSVPNKLGGVLALFLSIVIL\n" +
                        "GLMPFLHTSKHRSMMLRPLSQALFWTLTMDLLTLTWIGSQPVEYPYTIIGQMASILYFSIILAFLPIAGX\n" +
                        "IENY\n");
        assertTrue(badHeaderFASTA.getBadFastaHeaderMap().equals(badHeaderExpected));
    }
}