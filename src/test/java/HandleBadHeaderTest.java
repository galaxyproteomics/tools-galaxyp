import org.junit.*;

import edu.umn.galaxyp.HandleBadHeader;

import static edu.umn.galaxyp.HandleBadHeader.checkHeader;
import static org.junit.Assert.assertEquals;

/**
 * Created by caleb on 6/21/17.
 */
public class HandleBadHeaderTest {


    @Test
    public void testBadHeader() {
        String goodHeader = ">gi|5524211|gb||AAD44166.1 cytochrome b [Elephas maximus maximus]";
        String badHeader = ">gi||||5524211gbAAD44166.1 cytochrome b [Elephas maximus maximus]";

        assertEquals(0, checkHeader(goodHeader));
        assertEquals(1, checkHeader(badHeader));
    }

}
