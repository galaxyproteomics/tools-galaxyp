package edu.umn.galaxyp;

import com.compomics.util.protein.Header;

import java.util.Formatter;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

/**
 * Created by caleb on 6/22/17.
 * MultiSet, implemented with a backing map
 *
 */

public class MultiSet<T> {
    private HashMap<T, Integer> setOfObjects;

    public MultiSet(){
        setOfObjects = new HashMap<>();
    }

    public MultiSet(T[] objects){
        setOfObjects = new HashMap<>();
        for (T elem : objects) add(elem);
    }

    public HashMap<T, Integer> getMap(){
        return setOfObjects;
    }

    public void add(T value){
        if (setOfObjects == null){
            setOfObjects = new HashMap<>();
        }
        if (setOfObjects.containsKey(value)){
            int currentNumber = setOfObjects.get(value);
            setOfObjects.put(value, currentNumber + 1);
        } else {
            setOfObjects.put(value, 1);
        }
    }

    public int remove(T value){
        int currentNumber = setOfObjects.get(value);
        if (currentNumber == 0){
            setOfObjects.remove(value);
            return -1;
        }
        int newNumber = setOfObjects.get(value) - 1;
        setOfObjects.put(value, newNumber);
        if (newNumber == 0){
            setOfObjects.remove(value);
        }
        return newNumber;
    }

    @Override
    public String toString() {
        StringBuilder prettyPrint = new StringBuilder();
        Formatter formatter = new Formatter(prettyPrint, Locale.US);
        for (Map.Entry<T, Integer> entry : setOfObjects.entrySet()){
            T key = entry.getKey();
            Integer value = entry.getValue();
            formatter.format("%1$-15s %2$s %n", key.toString() + ":", value.toString());
        }
        return prettyPrint.toString();
    }
}
