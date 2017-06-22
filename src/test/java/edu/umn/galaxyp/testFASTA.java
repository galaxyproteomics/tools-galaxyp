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
        FASTA testFASTA = new FASTA(testpath);
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
        Path testpath = Paths.get("./src/test/java/edu/umn/galaxyp/fastaFilteringTest_IN.txt");
        String badHeader = ">gi||||5524211gbAAD44166.1 cytochrome b [Elephas maximus maximus]";
        String goodHeader = ">gi|5524211|gb|AAD44166.1 cytochrome b [Elephas maximus maximus]";

        assertTrue(!FASTA.isValidFastaHeader(badHeader, false));
        assertTrue(FASTA.isValidFastaHeader(goodHeader, false));
    }
}