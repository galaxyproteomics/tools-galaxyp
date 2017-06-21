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

import static java.nio.file.Files.newBufferedWriter;
import static org.junit.Assert.*;

/**
 * Created by caleb on 6/21/17.
 *
 * Testing FastaInput method by comparing
 * a copied-and-pasted FASTA file made into a HashMap (copied-and-pasted from localFastaTEST.txt)
 * to the same file read in by the FastaInput method of the localFasta class
 */
public class localFastaTest {

    @Test
    public void testFastaInput() {
        Path testpath = Paths.get("/home/caleb/IdeaProjects/FastaHeader/src/test/java/localFastaTEST.txt");
        localFasta testFASTA = new localFasta(testpath);
        System.out.println(testFASTA.toString());
        Map<String, String> expectedMap= new HashMap<>();
        expectedMap.put(">MCHU - Calmodulin - Human, rabbit, bovine, rat, and chicken\n", "ADQLTEEQIAEFKEAFSLFDKDGDGTITTKELGTVMRSLGQNPTEAELQDMINEVDADGNGTID\n" +
                "FPEFLTMMARKMKDTDSEEEIREAFRVFDKDGNGYISAAELRHVMTNLGEKLTDEEVDEMIREA\n" +
                "DIDGDGQVNYEEFVQMMTAK*\n");
        expectedMap.put(">gi|5524211|gb||AAD44166.1 cytochrome b [Elephas maximus maximus]\n", "LCLYTHIGRNIYYGSYLYSETWNTGIMLLLITMATAFMGYVLPWGQMSFWGATVITNLFSAIPYIGTNLV\n" +
                "EWIWGGFSVDKATLNRFFAFHFILPFTMVALAGVHLTFLHETGSNNPLGLTSDSDKIPFHPYYTIKDFLG\n" +
                "LLILILLLLLLALLSPDMLGDPDNHMPADPLNTPLHIKPEWYFLFAYAILRSVPNKLGGVLALFLSIVIL\n" +
                "GLMPFLHTSKHRSMMLRPLSQALFWTLTMDLLTLTWIGSQPVEYPYTIIGQMASILYFSIILAFLPIAGX\n" +
                "IENY\n");
        Path writeOut = Paths.get("/home/caleb/IdeaProjects/FastaHeader/src/test/java/localFastaTEST_OUT.txt");
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
}