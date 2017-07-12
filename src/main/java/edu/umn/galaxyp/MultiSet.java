package edu.umn.galaxyp;

//import com.compomics.util.protein.Header;

import java.util.Formatter;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

/**
 * MultiSet, implemented with a backing HashMap
 * <br> The keys may be of any type. 
 * @author Caleb Easterly
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
        if (value == null){
            // do nothing
        } else if (setOfObjects.containsKey(value)){
            int currentNumber = setOfObjects.get(value);
            setOfObjects.put(value, currentNumber + 1);
        } else {
            setOfObjects.put(value, 1);
        }
    }

    /**
     *
     * @param value
     * @return A positive integer indicates the number of @param value left in the set. A return value of null indicates that value is null.
     * A return value of -1 indicates that the object doesn't exist in the set.
     */
    public Integer remove(T value){
        if (value == null){
            return null;
        }
        Integer currentNumber = setOfObjects.get(value);

        if (currentNumber != null) {
            int newNumber = setOfObjects.get(value) - 1;
            setOfObjects.put(value, newNumber);
            if (newNumber == 0){
                setOfObjects.remove(value);
            }
            return newNumber;
        } else {
            return -1;
        }
    }

    @Override
    public String toString() {
        StringBuilder prettyPrint = new StringBuilder();
        Formatter formatter = new Formatter(prettyPrint, Locale.US);
        for (Map.Entry<T, Integer> entry : setOfObjects.entrySet()){
            T key = entry.getKey();
            Integer value = entry.getValue();
            formatter.format("%1$-25s %2$s %n", key.toString() + ":", value.toString());
        }
        return prettyPrint.toString();
    }
}
