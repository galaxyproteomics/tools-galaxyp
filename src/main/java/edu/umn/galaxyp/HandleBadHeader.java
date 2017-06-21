package edu.umn.galaxyp;

import com.compomics.util.protein.Header;

/**
 * Created by caleb on 6/21/17.
 *
 * designed to check if a Header is valid or not - probably want to change the name
 */
public class HandleBadHeader {

    public static int checkHeader(String aFastaHeader){

        try {
            Header header = Header.parseFromFASTA(aFastaHeader);
        } catch(IllegalArgumentException iae){
            return 1;
        }

        return 0;
    }
}
