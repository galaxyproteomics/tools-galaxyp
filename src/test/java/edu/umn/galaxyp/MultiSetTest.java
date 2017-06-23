package edu.umn.galaxyp;

import org.junit.Test;

import java.util.HashMap;

import static org.junit.Assert.*;

/**
 * Created by caleb on 6/22/17.
 */
public class MultiSetTest {

    @Test
    public void testMultiSet() throws Exception {
        String[] objects = {"Bos", "Tis", "Janics"};
        MultiSet<String> multi = new MultiSet<>(objects);

        HashMap<String, Integer> compareHashMap = new HashMap<>();
        compareHashMap.put("Bos", 1);
        compareHashMap.put("Tis", 1);
        compareHashMap.put("Janics", 1);

        assertTrue(compareHashMap.equals(multi.getMap()));

        multi.add("Bos");
        compareHashMap.put("Bos", 2);
        assertTrue(compareHashMap.equals(multi.getMap()));

        multi.remove("Janics");
        compareHashMap.remove("Janics");
        assertTrue(compareHashMap.equals(multi.getMap()));
    }

}