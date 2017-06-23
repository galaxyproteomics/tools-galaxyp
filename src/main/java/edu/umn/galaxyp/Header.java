/*
 * Copyright (C) Lennart Martens
 *
 * Contact: lennart.martens AT UGent.be (' AT ' to be replaced with '@')
 */

/*
 * Created by IntelliJ IDEA.
 * User: Lennart
 * Date: 7-okt-02
 * Time: 13:43:28
 */
//package com.compomics.util.protein;
package edu.umn.galaxyp;

//import com.compomics.util.experiment.identification.protein_sequences.SequenceFactory;
import java.io.Serializable;
//import org.apache.log4j.Logger;

import java.util.StringTokenizer;
import java.util.logging.Logger;

/**
 * This class represents the header for a Protein instance. It is meant to work
 * closely with FASTA format notation. The Header class knows how to handle
 * certain often-used headers such as SwissProt and NCBI formatted FASTA
 * headers.<br> Note that the Header class is it's own factory, and should be
 * used as such.
 *
 * @author Lennart Martens
 * @author Harald Barsnes
 * @author Marc Vaudel
 */
public class Header implements Cloneable, Serializable {

    /**
     * The version UID for Serialization/Deserialization compatibility.
     */
    static final long serialVersionUID = 7665784733371863163L;
    /**
     * Class specific log4j logger for Header instances.
     */
    private static Logger logger = Logger.getLogger(Header.class.getName());

    /**
     * Private constructor to force use of factory methods.
     */
    private Header() {
    }
    /**
     * The ID String corresponds to the String that is present as the first
     * element following the opening '&gt;'. It is most notably 'sw' for
     * SwissProt, and 'gi' for NCBI. <br> ID is the first element in the
     * abbreviated header String.
     */
    private String iID = null;
    /**
     * The foreign ID is the ID of another database this entry is originally
     * from. Most notably used for SwissProt entries in NCBI. <br> The foreign
     * ID String is an addendum to the accession String in the abbreviated
     * header String.
     */
    private String iForeignID = null;
    /**
     * The accession String is the unique identifier for the sequence in the
     * respective database. Note that for NCBI, the accession number also
     * defines a unique moment in time. <br> Accession String is the second
     * element in the abbreviated header String.
     */
    private String iAccession = null;
    /**
     * Extracted database name. As there are no standard database names, this is
     * only an internally consistent naming scheme included to be able to later
     * separate the databases. For example when linking to the online version of
     * the database. The links themselves are not included as these might change
     * outside the control of the compomics-utilities library. Note that the
     * type is set to unknown by default, and is set to the correct type during
     * the parsing of the header.
     */
    private DatabaseType databaseType = DatabaseType.Unknown;

    /**
     * A list of the database types. As there are no standard database names,
     * this is only an internally consistent naming scheme included to be able
     * to later separate the databases. For example when linking to the online
     * version of the database. The links themselves are not included as these
     * might change outside the control of the compomics-utilities library.
     */
    public enum DatabaseType {

        UniProt("UniProtKB", "14681372"), EnsemblGenomes("Ensembl Genomes", "26578574"), SGD("Saccharomyces Genome Database (SGD)", "9399804"), Arabidopsis_thaliana_TAIR("The Arabidopsis Information Resource (TAIR)", "12519987"),
        PSB_Arabidopsis_thaliana("PSB Arabidopsis thaliana", null), Drosophile("Drosophile", null), Flybase("Flybase", null), NCBI("NCBI Reference Sequences (RefSeq)", "22121212"),
        M_Tuberculosis("TBDatabase (TBDB)", "18835847"), H_Invitation("H_Invitation", null), Halobacterium("Halobacterium", null), H_Influenza("H_Influenza", null),
        C_Trachomatis("C_Trachomatis", null), GenomeTranslation("Genome Translation", null), Listeria("Listeria", null), GAFFA("GAFFA", null),
        UPS("Universal Proteomic Standard (UPS)", null), Generic_Header(null, null), IPI("International Protein Index (IPI)", "15221759"), Generic_Split_Header(null, null),
        NextProt("neXtProt", "22139911"), UniRef("UniRef", null), Unknown(null, null); // @TODO: add support for Ensembl headers?

        /**
         * The full name of the database.
         */
        String fullName;
        /**
         * The PubMed id of the database.
         */
        String pmid;

        /**
         * Constructor.
         *
         * @param fullName the full name
         * @param pmid the PubMed ID.
         */
        private DatabaseType(String fullName, String pmid) {
            this.fullName = fullName;
            this.pmid = pmid;
        }

        /**
         * Returns the full name of the database, null if not set.
         *
         * @return the full name of the database
         */
        public String getFullName() {
            return fullName;
        }

        /**
         * Returns the PubMed id of the database, null if not set.
         *
         * @return the PubMed id of the database
         */
        public String getPmid() {
            return pmid;
        }
    }
    /**
     * The foreign accession String is an accession String in another database
     * of significance. Most notably used for SwissProt accessions that are kept
     * in the NCBI database. <br> The foreign accession String is an addendum to
     * the foreign ID String in the abbreviated header String.
     */
    private String iForeignAccession = null;
    /**
     * The description is a more or less elaborate description of the protein in
     * question. <br> The description is the third element (and final) in the
     * abbreviated header String.
     */
    private String iDescription = null;
    /**
     * A short protein description, removing all but the protein description
     * itself. For example: "GRP78_HUMAN 78 kDa glucose-regulated protein
     * OS=Homo sapiens GN=HSPA5 PE=1 SV=2" becomes "78 kDa glucose-regulated
     * protein".
     */
    private String iDescriptionShort = null;
    /**
     * Protein name, the protein name extracted from the protein description.
     * For example: "GRP78_HUMAN 78 kDa glucose-regulated protein OS=Homo
     * sapiens GN=HSPA5 PE=1 SV=2" returns "GRP78_HUMAN".
     */
    private String iDescriptionProteinName = null;
    /**
     * The name of the gene the protein comes from. Note that this is only
     * available for UniProt and NextProt based databases.
     */
    private String iGeneName = null;
    /**
     * The protein evidence for the protein. Note that this is only available
     * for UniProt-based databases.
     */
    private String iProteinEvidence = null;
    /**
     * The name of the taxonomy the protein comes from. Note that this is only
     * available for UniProt-based databases.
     */
    private String iTaxonomy = null;
    /**
     * The foreign Description is a description for an entry in another DB. Most
     * notably, the SwissProt short description for an entry that is found
     * within NCBI. <br> The foreign description is an addendum to the foreign
     * accession String in the abbreviated header String.
     */
    private String iForeignDescription = null;
    /**
     * This variable holds all unidentified parts for the Header. If the String
     * was not (recognized as) a standard SwissProt or NCBI header, this
     * variable holds the entire header.
     */
    private String iRest = null;
    /**
     * This variable holds the raw complete unformatted header. Only trailing
     * white space is removed.
     */
    private String iRawHeader = null;
    /**
     * This StringBuffer holds all the addenda for this header.
     */
    private StringBuffer iAddenda = null;
    /**
     * This variable holds a possible start index for the associated sequence.
     */
    private int iStart = -1;
    /**
     * This variable holds a possible end index for the associated sequence.
     */
    private int iEnd = -1;

    /**
     * Factory method that constructs a Header instance based on a FASTA header
     * line.
     *
     * @param aFASTAHeader the String with the original FASTA header line.
     * @return Header with the Header instance representing the given header.
     * The object returned will have been parsed correctly if it is a standard
     * SwissProt or NCBI formatted header, and will be plain in all other cases.
     * @throws StringIndexOutOfBoundsException thrown if issues occur during the
     * parsing
     */
    public static Header parseFromFASTA(String aFASTAHeader) throws StringIndexOutOfBoundsException {
        Header result = null;

        if (aFASTAHeader == null) {
            // Do nothing, just return 'null'.
        } else if (aFASTAHeader.trim().equals("")) {
            result = new Header();
            result.iRest = "";
            result.iRawHeader = "";
        } else {
            result = new Header();

            // remove leading and trailing white space
            aFASTAHeader = aFASTAHeader.trim();

            // save the raw unformatted header
            result.iRawHeader = aFASTAHeader;

            // remove leading '>', if present
            if (aFASTAHeader.startsWith(">")) {
                aFASTAHeader = aFASTAHeader.substring(1);
            }

            // Now check for the possible presence of addenda in the header.
            // First check the description for addenda, and if that should fail, give 'Rest' a chance.
            int liPos;
            if ((liPos = aFASTAHeader.indexOf("^A")) >= 0) {
                result.iAddenda = new StringBuffer(aFASTAHeader.substring(liPos));
                aFASTAHeader = aFASTAHeader.substring(0, liPos);
            }
            try {
                // First determine what kind of Header we've got.
                if (aFASTAHeader.startsWith("sw|") || aFASTAHeader.startsWith("SW|")) {
                    // SwissProt.
                    // We need to find three elements:
                    //   - the ID (sw, we already know that one).
                    //   - the accession String (easily retrieved as the next String).
                    //   - the description (composed of the short description and the longer,
                    //     verbose description)
                    StringTokenizer lSt = new StringTokenizer(aFASTAHeader, "|");

                    // There should be at least three tokens.
                    if (lSt.countTokens() < 3) {
                        throw new IllegalArgumentException("Non-standard or false SwissProt header passed. "
                                + "Expecting something like: '>sw|Pxxxx|ACTB_HUMAN xxxx xxx xxxx ...', received '" + aFASTAHeader + "'.");
                    } else {
                        result.databaseType = DatabaseType.UniProt;
                        result.iID = lSt.nextToken();
                        result.iAccession = lSt.nextToken();

                        // Check for the presence of a location.
                        int index;
                        if ((index = result.iAccession.indexOf(" (")) > 0) {
                            String temp = result.iAccession.substring(index);
                            result.iAccession = result.iAccession.substring(0, index);
                            int open = 2;
                            int minus = temp.indexOf("-");
                            int end = temp.indexOf(")");
                            result.iStart = Integer.parseInt(temp.substring(open, minus));
                            result.iEnd = Integer.parseInt(temp.substring(minus + 1, end));
                        }

                        // get the description
                        result.iDescription = lSt.nextToken();

                        // try to get the gene name and taxonomy from the description
                        parseUniProtDescription(result);

                        // If there are any more elements, add them to the 'rest' section.
                        if (lSt.hasMoreTokens()) {
                            StringBuilder lBuffer = new StringBuilder();
                            while (lSt.hasMoreTokens()) {
                                lBuffer.append(lSt.nextToken());
                            }
                            result.iRest = lBuffer.toString();
                        }
                    }
                } else if (aFASTAHeader.startsWith("gi|") || aFASTAHeader.startsWith("GI|")) {
                    // NCBI.
                    // We need to check for a number of things here:
                    //   - first of all, we should get the ID (which we already have, 'gi')
                    //   - second is the NCBI accession String
                    //   - third we need to check for a foreign ID and accession
                    //   - If there is a foreign accession, there could also be a description
                    //     associated. Get that one too.
                    //   - finally, get the full NCBI description.
                    StringTokenizer lSt = new StringTokenizer(aFASTAHeader, "|");

                    // We expect to see either two or at least four or more tokens.
                    int tokenCount = lSt.countTokens();
                    if (tokenCount == 3) {
                        result.databaseType = DatabaseType.NCBI;
                        result.iID = lSt.nextToken();
                        result.iAccession = lSt.nextToken();
                        // Check for the presence of a location.
                        int index;
                        if ((index = result.iAccession.indexOf(" (")) > 0) {
                            String temp = result.iAccession.substring(index);
                            result.iAccession = result.iAccession.substring(0, index);
                            int open = 2;
                            int minus = temp.indexOf("-");
                            int end = temp.indexOf(")");
                            result.iStart = Integer.parseInt(temp.substring(open, minus));
                            result.iEnd = Integer.parseInt(temp.substring(minus + 1, end));
                        }
                        result.iDescription = lSt.nextToken().trim();
                    } else if (tokenCount < 4) {
                        throw new IllegalArgumentException("Non-standard or false NCBInr header passed. "
                                + "Expecting something like: '>gi|xxxxx|xx|xxxxx|(x) xxxx xxx xxxx ...', received '" + aFASTAHeader + "'.");
                    } else {
                        result.databaseType = DatabaseType.NCBI;
                        result.iID = lSt.nextToken();
                        result.iAccession = lSt.nextToken();
                        // Check for the presence of a location.
                        int index;
                        if ((index = result.iAccession.indexOf(" (")) > 0) {
                            String temp = result.iAccession.substring(index);
                            result.iAccession = result.iAccession.substring(0, index);
                            int open = 2;
                            int minus = temp.indexOf("-");
                            int end = temp.indexOf(")");
                            result.iStart = Integer.parseInt(temp.substring(open, minus));
                            result.iEnd = Integer.parseInt(temp.substring(minus + 1, end));
                        }
                        result.iForeignID = lSt.nextToken();
                        // Only retrieve the foreign accession if it is specifed (meaning a token count of 5).
                        if (tokenCount >= 5) {
                            result.iForeignAccession = lSt.nextToken();
                        }
                        StringBuilder lSB = new StringBuilder();
                        while (lSt.hasMoreTokens()) {
                            lSB.append(lSt.nextToken());
                        }
                        String temp = lSB.toString();
                        if (temp.startsWith(" ")) {
                            // Only description present.
                            result.iDescription = temp.substring(1);
                        } else {
                            // Up to the first space is foreign description.
                            int location = temp.indexOf(" ");
                            result.iForeignDescription = temp.substring(0, location);
                            result.iDescription = temp.substring(location + 1);
                        }
                    }
                } else if (aFASTAHeader.startsWith("IPI:") || aFASTAHeader.startsWith("ipi:") || aFASTAHeader.startsWith("IPI|") || aFASTAHeader.startsWith("ipi|")) {
                    // An IPI header looks like:
                    // >IPI:IPIxxxxxx.y|REFSEQ_XP:XP_aaaaa[|many more like this can be present] Tax_Id=9606 descr
                    result.databaseType = DatabaseType.IPI;
                    result.iID = "IPI";
                    result.iAccession = aFASTAHeader.substring(4, aFASTAHeader.indexOf("|", 4));
                    // Check for the presence of a location.
                    int index;
                    if ((index = result.iAccession.indexOf(" (")) > 0) {
                        String temp = result.iAccession.substring(index);
                        result.iAccession = result.iAccession.substring(0, index);
                        int open = 2;
                        int minus = temp.indexOf("-");
                        int end = temp.indexOf(")");
                        result.iStart = Integer.parseInt(temp.substring(open, minus));
                        result.iEnd = Integer.parseInt(temp.substring(minus + 1, end));
                    }
                    // Take everything from the first '|' we meet after the accession number.
                    result.iDescription = aFASTAHeader.substring(aFASTAHeader.indexOf("|", 5) + 1);
                } else if (aFASTAHeader.startsWith("HIT")) {
                    try {
                        //http://www.h-invitational.jp/
                        // A H-Invitation database entry looks like:
                        // >HIT000000001.10|HIX0021591.10|AB002292.2|NO|NO|HC|cds 185..4219|DH domain containing protein.
                        result.databaseType = DatabaseType.H_Invitation;
                        result.iID = "";
                        result.iAccession = aFASTAHeader.substring(0, aFASTAHeader.indexOf("|"));
                        // Check for the presence of a location.
                        int index;
                        if ((index = result.iAccession.indexOf(" (")) > 0) {
                            String temp = result.iAccession.substring(index);
                            result.iAccession = result.iAccession.substring(0, index);
                            int open = 2;
                            int minus = temp.indexOf("-");
                            int end = temp.indexOf(")");
                            result.iStart = Integer.parseInt(temp.substring(open, minus));
                            result.iEnd = Integer.parseInt(temp.substring(minus + 1, end));
                        }
                        // Take everything from the first '|' we meet after the accession number.
                        result.iDescription = aFASTAHeader.substring(aFASTAHeader.indexOf("|") + 1);
                    } catch (Exception excep) {
//                        logger.severe(excep.getMessage());
//                        logger.info(aFASTAHeader);
                    }
                } else if (aFASTAHeader.startsWith("OE")) {
                    // Halobacterium header from the Max Planck people.
                    // We need to find two elements:
                    //   - the accession String (easily retrieved as the next String until a space is encountered).
                    //   - the description
                    int accessionEndLoc = aFASTAHeader.indexOf(" ");
                    if (accessionEndLoc < 0 || aFASTAHeader.length() < (accessionEndLoc + 4)) {
                        throw new IllegalArgumentException("Non-standard Halobacterium (Max Planck) header passed. "
                                + "Expecting something like '>OExyz (OExyz) xxx xxx xxx', but was '" + aFASTAHeader + "'!");
                    }
                    // Now we have to see if there is location information present.
                    // This is a bit tricky here, because the accession number itself is repeated between '()' after the space.
                    if (aFASTAHeader.charAt(accessionEndLoc + 1) == '(' && Character.isDigit(aFASTAHeader.charAt(accessionEndLoc + 2))) {
                        // start and end found. Add it to the accession number and remove it from the description.
                        accessionEndLoc = aFASTAHeader.indexOf(")", accessionEndLoc) + 1;
                    }
                    result.databaseType = DatabaseType.Halobacterium;
                    result.iID = "";
                    result.iAccession = aFASTAHeader.substring(0, accessionEndLoc).trim();
                    // Check for the presence of a location.
                    int index;
                    if ((index = result.iAccession.indexOf(" (")) > 0) {
                        String temp = result.iAccession.substring(index);
                        result.iAccession = result.iAccession.substring(0, index);
                        int open = 2;
                        int minus = temp.indexOf("-");
                        int end = temp.indexOf(")");
                        result.iStart = Integer.parseInt(temp.substring(open, minus));
                        result.iEnd = Integer.parseInt(temp.substring(minus + 1, end));
                    }
                    result.iDescription = aFASTAHeader.substring(accessionEndLoc).trim();
                } else if (aFASTAHeader.startsWith("hflu_")) {
                    // H Influenza header from Novartis.
                    // We need to find two elements:
                    //   - the accession String (easily retrieved as the next String until a space is encountered).
                    //   - the description
                    int accessionEndLoc = aFASTAHeader.indexOf(" ");
                    if (accessionEndLoc < 0) {
                        throw new IllegalArgumentException("Non-standard H Influenza (Novartis) header passed. "
                                + "Expecting something like '>hflu_lsi_xxxx xxx xxx xxx', but was '" + aFASTAHeader + "'!");
                    }
                    // Now we have to see if there is location information present.
                    if (aFASTAHeader.charAt(accessionEndLoc + 1) == '(' && Character.isDigit(aFASTAHeader.charAt(accessionEndLoc + 2))) {
                        // start and end found. Add it to the accession number and remove it from the description.
                        accessionEndLoc = aFASTAHeader.indexOf(")", accessionEndLoc) + 1;
                    }
                    result.databaseType = DatabaseType.H_Influenza;
                    result.iID = "";
                    result.iAccession = aFASTAHeader.substring(0, accessionEndLoc).trim();
                    // Check for the presence of a location.
                    int index;
                    if ((index = result.iAccession.indexOf(" (")) > 0) {
                        String temp = result.iAccession.substring(index);
                        result.iAccession = result.iAccession.substring(0, index);
                        int open = 2;
                        int minus = temp.indexOf("-");
                        int end = temp.indexOf(")");
                        result.iStart = Integer.parseInt(temp.substring(open, minus));
                        result.iEnd = Integer.parseInt(temp.substring(minus + 1, end));
                    }
                    result.iDescription = aFASTAHeader.substring(accessionEndLoc).trim();
                } else if (aFASTAHeader.startsWith("C.tr_") || aFASTAHeader.startsWith("C_trachomatis_")) {
                    // C. Trachomatis header.
                    // We need to find two elements:
                    //   - the accession String (retrieved as the actual accession String which lasts up to the first space).
                    //   - the description (everything after the first space).
                    int accessionEndLoc = aFASTAHeader.indexOf(" ");
                    if (accessionEndLoc < 0) {
                        throw new IllegalArgumentException("Non-standard C trachomatis header passed. "
                                + "Expecting something like '>C_tr_Lx_x [xxx - xxx] | xxx xxx ', but was '" + aFASTAHeader + "'!");
                    }
                    // Now we have to see if there is location information present.
                    if (aFASTAHeader.charAt(accessionEndLoc + 1) == '(' && Character.isDigit(aFASTAHeader.charAt(accessionEndLoc + 2))) {
                        // start and end found. Add it to the accession number and remove it from the description.
                        accessionEndLoc = aFASTAHeader.indexOf(")", accessionEndLoc) + 1;
                    }
                    result.databaseType = DatabaseType.C_Trachomatis;
                    result.iID = "";
                    result.iAccession = aFASTAHeader.substring(0, accessionEndLoc).trim();
                    // Check for the presence of a location.
                    int index;
                    if ((index = result.iAccession.indexOf(" (")) > 0) {
                        String temp = result.iAccession.substring(index);
                        result.iAccession = result.iAccession.substring(0, index);
                        int open = 2;
                        int minus = temp.indexOf("-");
                        int end = temp.indexOf(")");
                        result.iStart = Integer.parseInt(temp.substring(open, minus));
                        result.iEnd = Integer.parseInt(temp.substring(minus + 1, end));
                    }
                    result.iDescription = aFASTAHeader.substring(accessionEndLoc).trim();
                } else if (aFASTAHeader.startsWith(" M. tub.")) {
                    // M. Tuberculosis header.
                    // We need to find two elements:
                    //   - the accession String (retrieved as the first pipe-delimited String).
                    //   - the description (everything after the pipe that closes the accession String).
                    int accessionStartLoc = aFASTAHeader.indexOf("|") + 1;
                    int accessionEndLoc = aFASTAHeader.indexOf("|", accessionStartLoc);
                    if (accessionEndLoc < 0) {
                        throw new IllegalArgumentException("Non-standard M tuberculosis header passed. "
                                + "Expecting something like '>M. tub.xxx|Rvxxx| xxx xxx', but was '" + aFASTAHeader + "'!");
                    }
                    result.databaseType = DatabaseType.M_Tuberculosis;
                    result.iID = aFASTAHeader.substring(0, accessionStartLoc - 1);
                    result.iAccession = aFASTAHeader.substring(accessionStartLoc, accessionEndLoc).trim();
                    // Check for the presence of a location.
                    int index;
                    if ((index = result.iAccession.indexOf(" (")) > 0) {
                        String temp = result.iAccession.substring(index);
                        result.iAccession = result.iAccession.substring(0, index);
                        int open = 2;
                        int minus = temp.indexOf("-");
                        int end = temp.indexOf(")");
                        result.iStart = Integer.parseInt(temp.substring(open, minus));
                        result.iEnd = Integer.parseInt(temp.substring(minus + 1, end));
                    }
                    result.iDescription = aFASTAHeader.substring(accessionEndLoc + 1).trim();
                } else if (aFASTAHeader.matches("^CG.* pep:.*")) {
                    // Drosophile DB.
                    // We need to find two elements:
                    //   - the accession String (retrieved as the trimmed version of everything
                    //     up to (and NOT including) " pep:"
                    //   - the description (everything (trimmed) starting from (and including) the " pep:".
                    int pepLoc = aFASTAHeader.indexOf(" pep:");
                    result.databaseType = DatabaseType.Drosophile;
                    result.iID = "";
                    result.iAccession = aFASTAHeader.substring(0, pepLoc).trim();
                    String possibleDescriptionPrefix = "";
                    // See if there is "(*xE*)" information wrongly assigned to the accession number.
                    if (result.iAccession.indexOf("(*") > 0) {
                        possibleDescriptionPrefix = result.iAccession.substring(result.iAccession.indexOf("(*"), result.iAccession.indexOf("*)") + 2) + " ";
                        result.iAccession = result.iAccession.substring(0, result.iAccession.indexOf("(*"));
                    }
                    // Check for the presence of a location.
                    int index;
                    if ((index = result.iAccession.indexOf(" (")) > 0) {
                        String temp = result.iAccession.substring(index);
                        result.iAccession = result.iAccession.substring(0, index);
                        int open = 2;
                        int minus = temp.indexOf("-");
                        int end = temp.indexOf(")");
                        result.iStart = Integer.parseInt(temp.substring(open, minus));
                        result.iEnd = Integer.parseInt(temp.substring(minus + 1, end));
                    }
                    result.iDescription = possibleDescriptionPrefix + aFASTAHeader.substring(pepLoc).trim();
                } else if (aFASTAHeader.matches(".*SGDID:[^\\s]+,.*")) {
                    // OK, SGD entry. The text up to but not including the first space is deemed accession,
                    // everything else is taken as description.
                    // So we need to find two elements:
                    //   - the accession String (taking into account possible location info).
                    //   - the description
                    int accessionEndLoc = aFASTAHeader.indexOf(" ");
                    if (accessionEndLoc < 0) {
                        throw new IllegalArgumentException("Non-standard SGD header passed. "
                                + "Expecting something like '>xxxx xxx SGDID:xxxx xxx', but was '" + aFASTAHeader + "'!");
                    }
                    // Now we have to see if there is location information present.
                    if (aFASTAHeader.charAt(accessionEndLoc + 1) == '(' && Character.isDigit(aFASTAHeader.charAt(accessionEndLoc + 2))) {
                        // start and end found. Add it to the accession number and remove it from the description.
                        accessionEndLoc = aFASTAHeader.indexOf(")", accessionEndLoc) + 1;
                    }
                    result.databaseType = DatabaseType.SGD;
                    result.iID = "";
                    result.iAccession = aFASTAHeader.substring(0, accessionEndLoc).trim();
                    // Check for the presence of a location.
                    int index;
                    if ((index = result.iAccession.indexOf(" (")) > 0) {
                        String temp = result.iAccession.substring(index);
                        result.iAccession = result.iAccession.substring(0, index);
                        int open = 2;
                        int minus = temp.indexOf("-");
                        int end = temp.indexOf(")");
                        result.iStart = Integer.parseInt(temp.substring(open, minus));
                        result.iEnd = Integer.parseInt(temp.substring(minus + 1, end));
                    }
                    result.iDescription = aFASTAHeader.substring(accessionEndLoc).trim();
                } else if (aFASTAHeader.startsWith("generic")) {

                    // try to parse as a generic header with splitters
                    // should look something like this:
                    // >generic_some_tag|proten_accession|a description for this protein
                    result.databaseType = DatabaseType.Generic_Split_Header;
                    result.iID = aFASTAHeader.substring(0, aFASTAHeader.indexOf("|"));

                    String subHeader = aFASTAHeader.substring(aFASTAHeader.indexOf("|") + 1);

                    if (subHeader.contains("|")) {
                        result.iAccession = subHeader.substring(0, subHeader.indexOf("|"));
                        result.iDescription = subHeader.substring(subHeader.indexOf("|") + 1).trim();
                    } else {
                        result.iAccession = subHeader;
                        result.iDescription = "";
                    }

                } else if (aFASTAHeader.matches("^[^\\s]+_[^\\s]+ \\([PQOA][^\\s]+\\) .*") && aFASTAHeader.lastIndexOf("|") == -1) {
                    // Old (everything before 9.0 release (31 Oct 2006)) standard SwissProt header as
                    // present in the Expasy FTP FASTA file.
                    // Is formatted something like this:
                    //  >XXX_YYYY (acc) rest
                    int start = aFASTAHeader.indexOf(" (");
                    int end = aFASTAHeader.indexOf(") ");
                    result.iAccession = aFASTAHeader.substring(start + 2, end);
                    result.databaseType = DatabaseType.UniProt;
                    result.iID = "sw"; // @TODO: remove hardcoding?
                    result.iDescription = aFASTAHeader.substring(0, start) + " " + aFASTAHeader.substring(end + 2);

                    // try to get the gene name and taxonomy
                    //parseUniProtDescription(result);  // @TOOD: not sure if the header has the right format...
                } else if (aFASTAHeader.matches("^sp\\|[^|]*\\|[^\\s]+_[^\\s]+ .*")) {
                    // New (September 2008 and beyond) standard SwissProt header as
                    // present in the Expasy FTP FASTA file.
                    // Is formatted something like this:
                    //  >sp|accession|ID descr rest (including taxonomy, if available)
                    String tempHeader = aFASTAHeader.substring(3);
                    result.iAccession = tempHeader.substring(0, tempHeader.indexOf("|")).trim();
                    // See if there is location information.
                    if (result.iAccession.matches("[^\\(]+\\([\\d]+ [\\d]\\)$")) {
                        int openBracket = result.iAccession.indexOf("(");
                        result.iStart = Integer.parseInt(result.iAccession.substring(openBracket, result.iAccession.indexOf(" ", openBracket)).trim());
                        result.iEnd = Integer.parseInt(result.iAccession.substring(result.iAccession.indexOf(" ", openBracket), result.iAccession.indexOf(")")).trim());
                        result.iAccession = result.iAccession.substring(0, openBracket).trim();
                    } else if (result.iAccession.matches("[^\\(]+\\([\\d]+-[\\d]+\\)$")) {
                        int openBracket = result.iAccession.indexOf("(");
                        result.iStart = Integer.parseInt(result.iAccession.substring(openBracket + 1, result.iAccession.indexOf("-", openBracket)).trim());
                        result.iEnd = Integer.parseInt(result.iAccession.substring(result.iAccession.indexOf("-", openBracket) + 1, result.iAccession.indexOf(")")).trim());
                        result.iAccession = result.iAccession.substring(0, openBracket).trim();
                    }
                    result.databaseType = DatabaseType.UniProt;
                    result.iID = "sp";
                    result.iDescription = tempHeader.substring(tempHeader.indexOf("|") + 1);

                    // try to get the gene name and taxonomy
                    parseUniProtDescription(result);

                } else if (aFASTAHeader.matches("^tr\\|[^|]*\\|[^\\s]+_[^\\s]+ .*")) {
                    // New (September 2008 and beyond) standard SwissProt header as
                    // present in the Expasy FTP FASTA file.
                    // Is formatted something like this:
                    //  >tr|accession|ID descr rest (including taxonomy, if available)
                    String tempHeader = aFASTAHeader.substring(3);
                    result.iAccession = tempHeader.substring(0, tempHeader.indexOf("|")).trim();
                    // See if there is location information.
                    if (result.iAccession.matches("[^\\(]+\\([\\d]+ [\\d]+\\)$")) {
                        int openBracket = result.iAccession.indexOf("(");
                        result.iStart = Integer.parseInt(result.iAccession.substring(openBracket + 1, result.iAccession.indexOf(" ", openBracket)).trim());
                        result.iEnd = Integer.parseInt(result.iAccession.substring(result.iAccession.indexOf(" ", openBracket), result.iAccession.indexOf(")")).trim());
                        result.iAccession = result.iAccession.substring(0, openBracket).trim();
                    } else if (result.iAccession.matches("[^\\(]+\\([\\d]+-[\\d]+\\)$")) {
                        int openBracket = result.iAccession.indexOf("(");
                        result.iStart = Integer.parseInt(result.iAccession.substring(openBracket + 1, result.iAccession.indexOf("-", openBracket)).trim());
                        result.iEnd = Integer.parseInt(result.iAccession.substring(result.iAccession.indexOf("-", openBracket) + 1, result.iAccession.indexOf(")")).trim());
                        result.iAccession = result.iAccession.substring(0, openBracket).trim();
                    }
                    result.databaseType = DatabaseType.UniProt;
                    result.iID = "tr";
                    result.iDescription = tempHeader.substring(tempHeader.indexOf("|") + 1);

                    // try to get the gene name and taxonomy
                    parseUniProtDescription(result);
                }  else if (aFASTAHeader.matches("^en\\|[^|]*\\|.*")) {
                    // Ensembl Genomes header
                    // Is formatted something like this:
                    //  >en|CCF76815|pCol1B9_SL1344:3971-4420 conserved hypothetical plasmid protein
                    String tempHeader = aFASTAHeader.substring(3);
                    result.iAccession = tempHeader.substring(0, tempHeader.indexOf("|")).trim();
                    // See if there is location information.
                    if (result.iAccession.matches("[^\\(]+\\([\\d]+ [\\d]+\\)$")) {
                        int openBracket = result.iAccession.indexOf("(");
                        result.iStart = Integer.parseInt(result.iAccession.substring(openBracket + 1, result.iAccession.indexOf(" ", openBracket)).trim());
                        result.iEnd = Integer.parseInt(result.iAccession.substring(result.iAccession.indexOf(" ", openBracket), result.iAccession.indexOf(")")).trim());
                        result.iAccession = result.iAccession.substring(0, openBracket).trim();
                    } else if (result.iAccession.matches("[^\\(]+\\([\\d]+-[\\d]+\\)$")) {
                        int openBracket = result.iAccession.indexOf("(");
                        result.iStart = Integer.parseInt(result.iAccession.substring(openBracket + 1, result.iAccession.indexOf("-", openBracket)).trim());
                        result.iEnd = Integer.parseInt(result.iAccession.substring(result.iAccession.indexOf("-", openBracket) + 1, result.iAccession.indexOf(")")).trim());
                        result.iAccession = result.iAccession.substring(0, openBracket).trim();
                    }
                    result.databaseType = DatabaseType.EnsemblGenomes;
                    result.iID = "en";
                    result.iDescription = tempHeader.substring(tempHeader.indexOf("|") + 1);

                    // try to get the gene name and taxonomy
                    parseUniProtDescription(result);

                } else if (aFASTAHeader.startsWith("nxp|NX_") && aFASTAHeader.split("\\|").length == 5) { // @TODO: replace by regular expression?
                    // header should look like this:
                    // >nxp|NX_P02768-1|ALB|Serum albumin|Iso 1
                    result.databaseType = DatabaseType.NextProt;
                    result.iID = "nxp";

                    String[] headerElements = aFASTAHeader.split("\\|");

                    result.iAccession = headerElements[1];
                    result.iGeneName = headerElements[2];
                    result.iDescription = headerElements[3] + "|" + headerElements[4];

                } else if (aFASTAHeader.startsWith("UniRef") && aFASTAHeader.contains(" ")) { // @TODO: replace by regular expression?

                    // header should look like this:
                    // >UniRef100_U3PVA8 Protein IroK n=22 Tax=Escherichia coli RepID=IROK_ECOL
                    result.databaseType = DatabaseType.UniRef;
                    result.iID = ""; // @TODO: could be UniRef or UniRef100 etc?

                    result.iAccession = aFASTAHeader.substring(0, aFASTAHeader.indexOf(" "));
                    result.iDescription = aFASTAHeader.substring(aFASTAHeader.indexOf(" ") + 1);

                } else if (aFASTAHeader.matches("^[^\\s]*\\|[^\\s]+_[^\\s]+ .*")) {
                    // New (9.0 release (31 Oct 2006) and beyond) standard SwissProt header as
                    // present in the Expasy FTP FASTA file.
                    // Is formatted something like this:
                    //  >accession|ID descr rest (including taxonomy, if available)
                    result.iAccession = aFASTAHeader.substring(0, aFASTAHeader.indexOf("|")).trim();
                    // See if there is location information.
                    if (aFASTAHeader.matches("[^\\(]+\\([\\d]+ [\\d]\\)$")) {
                        int openBracket = aFASTAHeader.indexOf("(");
                        result.iAccession = aFASTAHeader.substring(0, openBracket).trim();
                        result.iStart = Integer.parseInt(aFASTAHeader.substring(openBracket, aFASTAHeader.indexOf(" ", openBracket)).trim());
                        result.iEnd = Integer.parseInt(aFASTAHeader.substring(aFASTAHeader.indexOf(" ", openBracket), aFASTAHeader.indexOf(")")).trim());
                    }
                    result.databaseType = DatabaseType.UniProt;
                    result.iID = "sw"; // @TODO: remove hardcoding?
                    result.iDescription = aFASTAHeader.substring(aFASTAHeader.indexOf("|") + 1);

                    // try to get the gene name and taxonomy
                    parseUniProtDescription(result);
                } else if (aFASTAHeader.matches("^FB.+\\stype=.*")) {
                    // Flybase FASTA format.
                    // Accession number
                    result.iAccession = aFASTAHeader.substring(0, aFASTAHeader.indexOf("type")).trim();
                    if (result.iAccession.matches("[^\\(]+\\([\\d]+-[\\d]+\\)$")) {
                        int openBracket = result.iAccession.indexOf("(");
                        result.iStart = Integer.parseInt(result.iAccession.substring(openBracket + 1, result.iAccession.indexOf("-", openBracket)).trim());
                        result.iEnd = Integer.parseInt(result.iAccession.substring(result.iAccession.indexOf("-", openBracket) + 1, result.iAccession.indexOf(")")).trim());
                        result.iAccession = result.iAccession.substring(0, openBracket).trim();
                    }
                    result.databaseType = DatabaseType.Flybase;
                    result.iID = "";
                    result.iDescription = aFASTAHeader.substring(aFASTAHeader.indexOf("type="));
                } else if (aFASTAHeader.matches(".* [.]*\\[[\\d]+[ ]?\\-[ ]?[\\d]+\\].*")) {
                    // A header translating a genome sequence into a protein sequences.
                    // We need to find two elements, separated by a space:
                    //   - the accession string (retrieved as the first part of a space delimited String).
                    //   - the nucleic acid start and stop site (between brackets, separated by a '-').
                    //
                    // ex:  >dm345_3L-sense [234353534-234353938]
                    //      >dmic_c_1_469 Dialister micraerophilus DSM 19965 [161699 - 160872] aspartate-semialdehyde dehydrogenase Database
                    //      >synsp_j_c_8_5 Synergistes[G-2] sp. oral taxon 357 W5455 (JCVI) [820 - 1089]  ORF
                    int accessionEndLoc = aFASTAHeader.indexOf(" ");
                    if (accessionEndLoc < 0) {
                        throw new IllegalArgumentException("Incorrect genome to protein sequence header. "
                                + "Expected something like '>dm345_3L-sense (something) [234353-234359] (something)', but found '" + aFASTAHeader + "'!");
                    }
                    result.databaseType = DatabaseType.GenomeTranslation;
                    result.iID = aFASTAHeader.substring(0, accessionEndLoc).trim();
                    result.iAccession = aFASTAHeader.substring(0, accessionEndLoc).trim();

                    // Parse the location.
                    int index1 = aFASTAHeader.lastIndexOf("["); // @TODO: should check for [number-number] or [number -  number], as the current test will fail if the part after the indexes contains [...
                    int index2 = aFASTAHeader.indexOf("]", index1);
                    int separation = aFASTAHeader.indexOf("-", index1);

                    if (index1 > 0 && index2 > 0 && separation > 0) {
                        try {
                            result.iStart = Integer.parseInt(aFASTAHeader.substring(index1 + 1, separation).trim());
                            result.iEnd = Integer.parseInt(aFASTAHeader.substring(separation + 1, index2).trim());
                        } catch (NumberFormatException e) {
                            throw new IllegalArgumentException("Incorrect genome to protein sequence header. "
                                    + "Expected something like '>dm345_3L-sense (something) [234353-234359] (something)', but found '" + aFASTAHeader + "'!");
                        }
                    }

                    result.iDescription = aFASTAHeader.substring(accessionEndLoc + 1).trim();
                } else if (aFASTAHeader.matches("^[^|\t]* [|] Symbol[^|]*[|] [^|]* [|].*")) {
                    // The Arabidopsis thaliana database; TAIR format
                    // We need to find two elements, separated by pipes:
                    //   - the accession number with version (retrieved as the part before the first pipe).
                    //   - the description (retrieved as the part between the second and third pipe).
                    //
                    // ex: >AT1G08520.1 | Symbol: PDE166 | magnesium-chelatase subunit chlD, chloroplast, putative / Mg-protoporphyrin IX chelatase, putative (CHLD), similar to Mg-chelatase SP:O24133 from Nicotiana tabacum, GB:AF014399 GI:2318116 from (Pisum sativum) | chr1:2696415-2700961 FORWARD | Aliases: T27G7.20, T27G7_20, PDE166, PIGMENT DEFECTIVE 166
                    int firstPipeLoc = aFASTAHeader.indexOf("|");
                    result.databaseType = DatabaseType.Arabidopsis_thaliana_TAIR;
                    result.iAccession = aFASTAHeader.substring(0, firstPipeLoc).trim();
                    result.iID = "";
                    int secondPipeLoc = aFASTAHeader.indexOf("|", firstPipeLoc + 1);
                    int thirdPipeLoc = aFASTAHeader.indexOf("|", secondPipeLoc + 1);
                    result.iDescription = aFASTAHeader.substring(secondPipeLoc + 1, thirdPipeLoc).trim();
                    // Check for the presence of a location.
                    int index;
                    if ((index = result.iAccession.indexOf(" (")) > 0) {
                        String temp = result.iAccession.substring(index);
                        result.iAccession = result.iAccession.substring(0, index);
                        int open = 2;
                        int minus = temp.indexOf("-");
                        int end = temp.indexOf(")");
                        result.iStart = Integer.parseInt(temp.substring(open, minus));
                        result.iEnd = Integer.parseInt(temp.substring(minus + 1, end));
                    }
                } else if (aFASTAHeader.matches("^nrAt[^\t]*\t.*")) {
                    // The PSB Arabidopsis thaliana database; proprietary format
                    // We need to find three elements:
                    //   - the internal accession (at the start, separated by 'tab' and space from the next part).
                    //   - the external accession (between '()', after the internal accession).
                    //   - the description (retrieved as the rest of the header).
                    //
                    // ex: nrAt0.2_1 	(TR:Q8HT11_ARATH) Photosystem II CP43 protein (Fragment).- Arabidopsis thaliana (Mouse-ear cress).
                    int openBracketLoc = aFASTAHeader.indexOf("(");
                    int closeBracketLoc = aFASTAHeader.indexOf(")");
                    // If there is a location, there will be a closing bracket at 'closeBracketLoc+1' as well.
                    // If so, use this one.
                    int tempLoc = closeBracketLoc + 1;
                    if (aFASTAHeader.length() > tempLoc && aFASTAHeader.charAt(tempLoc) == ')') {
                        closeBracketLoc = tempLoc;
                    }
                    result.databaseType = DatabaseType.PSB_Arabidopsis_thaliana;
                    result.iAccession = aFASTAHeader.substring(openBracketLoc + 1, closeBracketLoc).trim();
                    result.iID = aFASTAHeader.substring(0, openBracketLoc).trim();
                    result.iDescription = aFASTAHeader.substring(closeBracketLoc + 1).trim();
                    // Check for the presence of a location.
                    int index;
                    if ((index = result.iAccession.indexOf(" (")) > 0) {
                        String temp = result.iAccession.substring(index);
                        result.iAccession = result.iAccession.substring(0, index);
                        int open = 2;
                        int minus = temp.indexOf("-");
                        int end = temp.indexOf(")");
                        result.iStart = Integer.parseInt(temp.substring(open, minus));
                        result.iEnd = Integer.parseInt(temp.substring(minus + 1, end));
                    }
                } else if (aFASTAHeader.matches("^L. monocytogenes[^|]*[|][^|]*[|].*")) {
                    // The Listeria database; proprietary format
                    // We need to find three elements:
                    //   - the leader element (at the start, separated by '|' from the next part).
                    //   - the accession number (between '||', after the leader).
                    //   - the description (retrieved as the rest of the header).
                    //
                    // ex: L. monocytogenes EGD-e|LMO02333|'comK: 158 aa - competence transcription factor (C-terminal part)
                    int firstPipe = aFASTAHeader.indexOf("|");
                    int secondPipe = aFASTAHeader.indexOf("|", firstPipe + 1);
                    result.databaseType = DatabaseType.Listeria;
                    result.iID = aFASTAHeader.substring(0, firstPipe).trim();
                    result.iAccession = aFASTAHeader.substring(firstPipe + 1, secondPipe).trim();
                    result.iDescription = aFASTAHeader.substring(secondPipe + 1).trim();
                    // Check for the presence of a location.
                    int index;
                    if ((index = result.iAccession.indexOf(" (")) > 0) {
                        String temp = result.iAccession.substring(index);
                        result.iAccession = result.iAccession.substring(0, index);
                        int open = 2;
                        int minus = temp.indexOf("-");
                        int end = temp.indexOf(")");
                        result.iStart = Integer.parseInt(temp.substring(open, minus));
                        result.iEnd = Integer.parseInt(temp.substring(minus + 1, end));
                    }
                } else if (aFASTAHeader.toLowerCase().startsWith("gaffa")) {

                    // A Genome Annotation Framework for Flexible Analysis (GAFFA) header.
                    // Should look like this:
                    // >GAFFA|"accession"|"species"/unknown
                    // Example:
                    //  >GAFFA|cgb_GMPQSG401A00X3_1_cgb_pilot_F1_1|unknown
                    result.databaseType = DatabaseType.GAFFA;
                    try {
                        result.iAccession = aFASTAHeader.substring(aFASTAHeader.indexOf("|") + 1, aFASTAHeader.lastIndexOf("|"));
                        result.iDescription = aFASTAHeader.substring(aFASTAHeader.lastIndexOf("|") + 1);
                    } catch (IndexOutOfBoundsException e) {
                        result.iAccession = aFASTAHeader.substring(aFASTAHeader.indexOf("|") + 1);
                        result.iDescription = "";
                    }
                    result.iID = "GAFFA";
                } else if (aFASTAHeader.contains("_HUMAN_UPS")) {
                    // UPS sequences, processed like SGD
                    int accessionEndLoc = aFASTAHeader.indexOf(" ");
                    if (accessionEndLoc < 0) {
                        throw new IllegalArgumentException("Non-standard UPS header passed. "
                                + "Expecting something like '>xxxx xxxxx_HUMAN_UPS xxxxxxx xxx', but was '" + aFASTAHeader + "'.");
                    }
                    // Now we have to see if there is location information present.
                    if (aFASTAHeader.charAt(accessionEndLoc + 1) == '(' && Character.isDigit(aFASTAHeader.charAt(accessionEndLoc + 2))) {
                        // start and end found. Add it to the accession number and remove it from the description.
                        accessionEndLoc = aFASTAHeader.indexOf(")", accessionEndLoc) + 1;
                    }
                    result.databaseType = DatabaseType.UPS;
                    result.iID = "";
                    result.iAccession = aFASTAHeader.substring(0, accessionEndLoc).trim();
                    // Check for the presence of a location.
                    int index;
                    if ((index = result.iAccession.indexOf(" (")) > 0) {
                        String temp = result.iAccession.substring(index);
                        result.iAccession = result.iAccession.substring(0, index);
                        int open = 2;
                        int minus = temp.indexOf("-");
                        int end = temp.indexOf(")");
                        result.iStart = Integer.parseInt(temp.substring(open, minus));
                        result.iEnd = Integer.parseInt(temp.substring(minus + 1, end));
                    }
                    result.iDescription = aFASTAHeader.substring(accessionEndLoc).trim();
                } else {
                    // Okay, try the often-used 'generic' approach. If this fails, we go to the worse-case scenario, ie. do not process at all.
                    // Testing for this is somewhat more complicated.

                    // Often used simple header; looks like:
                    // >NP0465 (NP0465) A description for this protein.
                    // We need to find two elements:
                    //   - the accession String (easily retrieved as the next String until a space is encountered).
                    //   - the description
                    result.databaseType = DatabaseType.Generic_Header;
                    int accessionEndLoc = aFASTAHeader.indexOf(" ");

                    // Temporary storage variables.
                    int startSecAcc = -1;
                    int endSecAcc = -1;
                    String testAccession = null;
                    String testDescription = null;
                    int testStart = -1;
                    int testEnd = -1;

                    if ((accessionEndLoc > 0) && (aFASTAHeader.contains("(")) && (aFASTAHeader.indexOf(")", aFASTAHeader.indexOf("(") + 1) >= 0)) {
                        // Now we have to see if there is location information present.
                        if (aFASTAHeader.substring(accessionEndLoc + 1, aFASTAHeader.indexOf(")", accessionEndLoc + 2) + 1).matches("[(][0-9]+-[0-9]+[)]") && !aFASTAHeader.substring(accessionEndLoc + 2, aFASTAHeader.indexOf(")", accessionEndLoc + 2)).equals(aFASTAHeader.substring(0, accessionEndLoc).trim())) {
                            // start and end found. Add it to the accession number and remove it from the description.
                            accessionEndLoc = aFASTAHeader.indexOf(")", accessionEndLoc) + 1;
                        }
                        testAccession = aFASTAHeader.substring(0, accessionEndLoc).trim();
                        // Check for the presence of a location.
                        int index;
                        if ((index = testAccession.indexOf(" (")) > 0) {
                            String temp = testAccession.substring(index);
                            testAccession = testAccession.substring(0, index);
                            int open = 2;
                            int minus = temp.indexOf("-");
                            int end = temp.indexOf(")");
                            testStart = Integer.parseInt(temp.substring(open, minus));
                            testEnd = Integer.parseInt(temp.substring(minus + 1, end));
                        }
                        testDescription = aFASTAHeader.substring(accessionEndLoc).trim();
                        // Find the second occurrence of the accession number, which should be in the description.
                        int enzymicity = -1;
                        if (testDescription.contains("(*") && testDescription.indexOf("*)", testDescription.indexOf("(*" + 4)) > 0) {
                            enzymicity = testDescription.indexOf("*)") + 2;
                        }
                        startSecAcc = testDescription.indexOf("(", enzymicity);
                        endSecAcc = testDescription.indexOf(")", startSecAcc + 2);
                    }
                    // See if the accessions match up.
                    if (startSecAcc >= 0 && endSecAcc >= 0 && testDescription != null && testDescription.substring(startSecAcc + 1, endSecAcc).trim().equals(testAccession.trim())) {
                        result.iID = "";
                        result.iAccession = testAccession;
                        result.iDescription = testDescription;
                        if (testStart >= 0 && testEnd >= 0) {
                            result.iStart = testStart;
                            result.iEnd = testEnd;
                        }
                    } else {
                        //try >nonsense|accession|description
                        if (aFASTAHeader.lastIndexOf("|") >= 0) {
                            String end = aFASTAHeader.substring(aFASTAHeader.indexOf("|") + 1);
                            if (end.contains("|")) {
                                result.iAccession = end.substring(0, end.indexOf("|"));
                                result.iDescription = end.substring(end.indexOf("|") + 1);
                            }
                        }

                        // Unknown.
                        // Everything is rest.
                        result.iRest = aFASTAHeader;

                        // Check for the presence of a location.
                        int index;
                        if (((index = result.iRest.lastIndexOf(" (")) > 0) && (result.iRest.lastIndexOf(")") > 0) && (result.iRest.lastIndexOf("-") > index)) {
                            String temp = result.iRest.substring(index);
                            int open = 2;
                            int minus = temp.indexOf("-");
                            int end = temp.lastIndexOf(")");
                            try {
                                int tempStart = Integer.parseInt(temp.substring(open, minus));
                                int tempEnd = Integer.parseInt(temp.substring(minus + 1, end));
                                result.iStart = tempStart;
                                result.iEnd = tempEnd;
                                result.iRest = result.iRest.substring(0, index);
                            } catch (Exception e) {
                                // apparently not location info.
                            }
                        }
                    }
                }
            } catch (StringIndexOutOfBoundsException e) {
                throw new StringIndexOutOfBoundsException("Unable to process FASTA header line:\n"
                        + "'" + aFASTAHeader + "'\n"
                        + "as a '" + result.databaseType + "' header.\n"
                        + "Process cancelled.");
            } catch (RuntimeException excep) {
//                logger.severe(" * Unable to process FASTA header line:\n\t" + aFASTAHeader + "\n\n"); // @TODO: throw a proper exception!!!
                throw excep;
            }
        }

        return result;
    }

    /**
     * Returns the ID.
     *
     * @return the ID
     */
    public String getID() {
        return this.iID;
    }

    /**
     * Sets the ID. Null if not set.
     *
     * @param aID the ID
     */
    public void setID(String aID) {
        iID = aID;
    }

    /**
     * Returns the foreign ID. Null if not set.
     *
     * @return the foreign ID
     */
    public String getForeignID() {
        return iForeignID;
    }

    /**
     * Sets the foreign ID.
     *
     * @param aForeignID the foreign ID
     */
    public void setForeignID(String aForeignID) {
        iForeignID = aForeignID;
    }

    /**
     * Returns the accession. Null if not set.
     *
     * @return the accession
     */
    public String getAccession() {
        return iAccession;
    }

    /**
     * Sets the accession.
     *
     * @param aAccession the accession
     */
    public void setAccession(String aAccession) {
        iAccession = aAccession;
    }

    /**
     * Returns the accession or if this is null the rest. This is a quick fix
     * for unsupported custom headers.
     *
     * @return the accession or if this is null the rest
     */
    public String getAccessionOrRest() {
        if (iAccession == null) {
            return iRest;
        } else {
            return iAccession;
        }
    }

    /**
     * Returns the database type as inferred from the header structure.
     *
     * @return the database type
     */
    public DatabaseType getDatabaseType() {
        return databaseType;
    }

    /**
     * Sets the database type.
     *
     * @param aDatabaseType the database type
     */
    public void setDatabaseType(DatabaseType aDatabaseType) {
        databaseType = aDatabaseType;
    }

    /**
     * Returns the foreign accession. Null if not set.
     *
     * @return the foreign accession
     */
    public String getForeignAccession() {
        return iForeignAccession;
    }

    /**
     * Sets the foreign accession.
     *
     * @param aForeignAccession the foreign accession
     */
    public void setForeignAccession(String aForeignAccession) {
        iForeignAccession = aForeignAccession;
    }

    /**
     * Returns the description. Null if not set.
     *
     * @return the description
     */
    public String getDescription() {
        return iDescription;
    }

    /**
     * Sets the description.
     *
     * @param aDescription the description
     */
    public void setDescription(String aDescription) {
        iDescription = aDescription;
    }

    /**
     * Returns the short description. Null if not set.
     *
     * @return the short description
     */
    public String getDescriptionShort() {
        return iDescriptionShort;
    }

    /**
     * Sets the short description.
     *
     * @param aDescriptionShort the short description
     */
    public void setDescriptionShort(String aDescriptionShort) {
        iDescriptionShort = aDescriptionShort;
    }

    /**
     * Returns the protein name as inferred from the description.
     *
     * @return the protein name
     */
    public String getDescriptionProteinName() {
        return iDescriptionProteinName;
    }

    /**
     * Sets the protein name.
     *
     * @param aDescriptionProteinName the protein name
     */
    public void setDescriptionProteinName(String aDescriptionProteinName) {
        iDescriptionProteinName = aDescriptionProteinName;
    }

    /**
     * Returns the gene name.
     *
     * @return the gene name
     */
    public String getGeneName() {
        return iGeneName;
    }

    /**
     * Set the gene name.
     *
     * @param aGeneName the gene name
     */
    public void setGeneName(String aGeneName) {
        iGeneName = aGeneName;
    }

    /**
     * Returns the protein evidence level.
     *
     * @return the protein evidence level
     */
    public String getProteinEvidence() {
        return iProteinEvidence;
    }

    /**
     * Sets the protein evidence level.
     *
     * @param aProteinEvidence the protein evidence level
     */
    public void setProteinEvidence(String aProteinEvidence) {
        iProteinEvidence = aProteinEvidence;
    }

    /**
     * Returns the taxonomy.
     *
     * @return the taxonomy
     */
    public String getTaxonomy() {
        return iTaxonomy;
    }

    /**
     * Sets the taxonomy.
     *
     * @param aTaxonomy the taxonomy
     */
    public void setTaxonomy(String aTaxonomy) {
        iTaxonomy = aTaxonomy;
    }

    /**
     * Returns the foreign description.
     *
     * @return the foreign description
     */
    public String getForeignDescription() {
        return iForeignDescription;
    }

    /**
     * Sets the foreign description.
     *
     * @param aForeignDescription the foreign description
     */
    public void setForeignDescription(String aForeignDescription) {
        iForeignDescription = aForeignDescription;
    }

    /**
     * Returns the rest of the header.
     *
     * @return the rest of the header
     */
    public String getRest() {
        return iRest;
    }

    /**
     * Sets the rest of the header.
     *
     * @param aRest the rest of the header
     */
    public void setRest(String aRest) {
        iRest = aRest;
    }

    /**
     * Returns the entire header.
     *
     * @return the entire header
     */
    public String getRawHeader() {
        return iRawHeader;
    }

    /**
     * Sets the entire header.
     *
     * @param aRawHeader the entire header
     */
    public void setRawHeader(String aRawHeader) {
        iRawHeader = aRawHeader;
    }

//    /**
//     * Returns a simplified protein description for a UniProt header. For
//     * example "GRP78_HUMAN 78 kDa glucose-regulated protein OS=Homo sapiens
//     * GN=HSPA5 PE=1 SV=2" becomes "78 kDa glucose-regulated protein
//     * [GRP78_HUMAN]". For non UniProt headers the normal protein description is
//     * returned.
//     *
//     * @return a simplified protein description for a UniProt header
//     */
//    public String getSimpleProteinDescription() {
//        if (databaseType == DatabaseType.UniProt) {
//
//            // get the default simple header
//            String temp = iDescriptionShort + " (" + iDescriptionProteinName + ")";
//
//            // see if we need to add a decoy flag
//            if (SequenceFactory.getInstance().isDecoyAccession(iAccession)) {
//                temp = SequenceFactory.getDefaultDecoyDescription(temp);
//            }
//
//            return temp;
//        } else if (iDescription != null) {
//            return iDescription;
//        } else {
//            return "";
//        }
//    }

    /**
     * This method returns an abbreviated version of the Header, suitable for
     * inclusion in FASTA formatted files. <br> The abbreviated header is
     * composed in the following way: <br>
     * &gt;[ID]|[accession_string]|([foreign_ID]|[foreign_accession_string]|[foreign_description]
     * )[description]
     *
     * @return String with the abbreviated header.
     */
    public String getAbbreviatedFASTAHeader() {
        return getAbbreviatedFASTAHeader("");
    }

    /**
     * This method returns an abbreviated version of the Header, suitable for
     * inclusion in FASTA formatted files. <br> The abbreviated header is
     * composed in the following way: <br>
     * &gt;[ID]|[accession_string]|([foreign_ID]|[foreign_accession_string]|[foreign_description]
     * )[description]
     *
     *
     * @param decoyTag the decoy tag to add
     * @return String with the abbreviated header.
     */
    public String getAbbreviatedFASTAHeader(String decoyTag) {

        StringBuffer result = new StringBuffer(">" + this.getCoreHeader() + decoyTag);

        if (this.iID == null || this.databaseType == DatabaseType.Unknown) {
            // Apparently we have not been able to identify and parse this header.
            // In that case, the core header already contains everything, so don't do anything.
        } else {
            // Some more appending to be done here.
            if (!this.iID.equals("")) {
                if (this.databaseType == DatabaseType.UniProt
                        || this.databaseType == DatabaseType.IPI
                        || this.databaseType == DatabaseType.Listeria
                        || this.databaseType == DatabaseType.NextProt
                        || this.databaseType == DatabaseType.EnsemblGenomes) {
                    // FASTA entry with pipe ('|') separating core header from description.
                    result.append("|").append(this.iDescription);
                } else if (this.databaseType == DatabaseType.NCBI) {
                    // NCBI entry.
                    result.append("|");
                    // See if we have a foreign ID.
                    if (iForeignID != null) {
                        result.append(this.iForeignID).append("|").append(this.iForeignAccession).append("|");
                        // See if we also have a description.
                        if (this.iForeignDescription != null) {
                            result.append(this.iForeignDescription);
                        }
                    }
                    // Add the Description.
                    result.append(" ").append(this.iDescription);
                } else if (this.databaseType == DatabaseType.M_Tuberculosis) {
                    // Mycobacterium tuberculosis entry.
                    result.append("|").append(this.iDescription);
                } else if (this.databaseType == DatabaseType.GenomeTranslation) {
                    // Genome to protein sequnece translation.
                    result = new StringBuffer(">" + this.iAccession + decoyTag + " " + this.iDescription);
                } else if (this.databaseType == DatabaseType.PSB_Arabidopsis_thaliana) {
                    // Proprietary PSB A. thaliana entry
                    result.append(" ").append(this.iDescription);
                }
            } else {
                if (this.databaseType == DatabaseType.H_Invitation) {
                    result.append("|").append(this.iDescription);
                } else {
                    // Just add a space and the description.
                    result.append(" ").append(this.iDescription);
                }
            }
        }

        return result.toString();
    }

    /**
     * This method reports on the entire processed(!) header. To get the raw
     * header use getRawHeader instead.
     *
     * @return String with the full header.
     */
    public String toString() {
        return toString("");
    }

    /**
     * This method reports on the entire processed(!) header, with the given
     * decoy tag added. To get the raw header use getRawHeader instead.
     *
     * @param decoyTag the decoy tag to add
     * @return String with the full header.
     */
    public String toString(String decoyTag) {

        String result;

        if (databaseType == DatabaseType.Generic_Split_Header) {
            result = ">" + this.iID + decoyTag + "|" + this.iAccession + "|" + this.iDescription;
        } else {
            if (this.iID == null) {
                result = this.getAbbreviatedFASTAHeader(decoyTag);
            } else {
                result = this.getAbbreviatedFASTAHeader(decoyTag);
                if (this.iRest != null) {
                    result += " " + this.iRest;
                }
            }
        }

        result += decoyTag;
        return result;
    }

    /**
     * This method will attribute a score to the current header, based on the
     * following scoring list: <ul> <li> SwissProt : 4 </li> <li> IPI, SwissProt
     * reference : 3 </li> <li> IPI, TrEMBL or REFSEQ_NP reference : 2 </li>
     * <li> IPI, without SwissProt, TrEMBL or REFSEQ_NP reference : 1 </li> <li>
     * NCBI, SwissProt reference : 2</li> <li> NCBI, other reference : 1</li>
     * <li> Unknown header format : 0</li> </ul>
     *
     * @return int with the header score. The higher the score, the more
     * interesting a Header is.
     */
    public int getScore() {

        int score = -1; // @TODO: should rely in database type instead of the ID tag?

        // Score the header...
        if (this.iID == null || this.iID.equals("") || this.iID.startsWith(" M. tub.") || this.iID.startsWith("nrAt") || this.iID.startsWith("L. monocytogenes")) {
            score = 0;
        } else if (this.iID.equalsIgnoreCase("sw") || this.iID.equalsIgnoreCase("sp")) {
            score = 4;
        } else if (this.iID.equalsIgnoreCase("tr")) {
            score = 2;
        } else if (this.iID.equalsIgnoreCase("ipi")) {
            if (this.iDescription != null && this.iDescription.toUpperCase().contains("SWISS-PROT")) {
                score = 3;
            } else if (this.iDescription != null && ((this.iDescription.toUpperCase().contains("TREMBL")) || (this.iDescription.toUpperCase().contains("REFSEQ_NP")))) {
                score = 2;
            } else {
                score = 1;
            }
        } else if (this.iID.equalsIgnoreCase("gi")) {
            if (this.iForeignID != null && this.iForeignID.equals("sp")) {
                score = 2;
            } else {
                score = 1;
            }
        } else if (this.iID.equalsIgnoreCase("en")) {
            score = 3;
        }
        return score;
    }

    /**
     * This method reports on the core information for the header, which is
     * comprised of the ID and the accession String:
     * <pre>
     *     [ID]|[accession_string]
     * </pre> This is mostly useful for appending this core as an addendum to
     * another header.
     *
     * @return String with the header core data ([ID]|[accession_string]).
     */
    public String getCoreHeader() {
        String result = null;
        if (iID != null && iID.startsWith("nrAt")) { // @TODO: should rely in database type instead of the ID tag?
            result = this.getID() + " \t(" + this.getAccession();
        } else if (iID != null && !iID.equals("")) {
            result = this.getID() + "|" + this.getAccession();
        } else if (iID != null && iID.equals("")) {
            // No ID given, so just take the accession.
            result = this.getAccession();
        } else if (iID == null) {
            result = this.iRest;
        }

        // See if we need to add information about the location.
        if (iStart >= 0) {
            result += " (" + Integer.toString(iStart) + "-" + Integer.toString(iEnd) + ")";
        }

        // For the PSB A. Thaliana, we need to include the closing ')'.
        if (iID != null && iID.startsWith("nrAt")) {
            result += ")";
        }

        return result;
    }

    /**
     * This method allows the addition of an addendum to the list. If the
     * addendum is already preceded with '^A', it is added as is, otherwise '^A'
     * is prepended before addition to the list.
     *
     * @param aAddendum String with the addendum, facultatively preceded by
     * '^A'.
     */
    public void addAddendum(String aAddendum) {
        // First see if we have addenda already.
        if (this.iAddenda == null) {
            iAddenda = new StringBuffer();
        }

        // Now check for the presence of the '^A' sequence.
        if (aAddendum.startsWith("^A")) {
            iAddenda.append(aAddendum);
        } else {
            iAddenda.append("^A").append(aAddendum);
        }
    }

    /**
     * This method allows the caller to retrieve all addenda for the current
     * header, or 'null' if there aren't any.
     *
     * @return String with the addenda, or 'null' if there aren't any.
     */
    public String getAddenda() {
        String result = null;
        if (this.iAddenda != null) {
            result = iAddenda.toString();
        }
        return result;
    }

    /**
     * This method reports on the presence of addenda for this header.
     *
     * @return boolean whether addenda are present.
     */
    public boolean hasAddenda() {
        boolean result = false;

        if (this.iAddenda != null) {
            result = true;
        }

        return result;
    }

    /**
     * This method reports on the full header, with the addenda (if present). If
     * no addenda are present, this method reports the same information as the
     * 'toString()' method.
     *
     * @return String with the header and addenda (if any).
     */
    public String getFullHeaderWithAddenda() {
        String result = this.toString();

        if (this.iAddenda != null) {
            result += iAddenda.toString();
        }

        return result;
    }

    /**
     * This method returns an abbreviated version of the Header, suitable for
     * inclusion in FASTA formatted files. <br> The abbreviated header is
     * composed in the following way: <br>
     * &gt;[ID]|[accession_string]|([foreign_ID]|[foreign_accession_string]|[foreign_description]
     * )[description]([addenda])
     * <br>
     * Note that the output of this method is identical to that of the
     * getAbbreviatedFASTAHeader() if no addenda are present.
     *
     * @return String with the abbreviated header and addenda (if any).
     */
    public String getAbbreviatedFASTAHeaderWithAddenda() {
        String result = this.getAbbreviatedFASTAHeader();

        if (this.iAddenda != null) {
            result += iAddenda.toString();
        }

        return result;
    }

    /**
     * This method allows the caller to add information to the header about
     * location of the sequence in a certain master sequence. <br> This
     * information is typically specified right after the accession number:
     * <pre>
     *     [id]|[accession_string] ([startindex]-[endindex])|...
     * </pre> <b>Please note the following:</b> <ul> <li>If an index is already
     * present, it is removed and replaced.</li> <li>If the header is of unknown
     * format, the indeces are appended to the end of the header.</li> </ul>
     *
     * @param aStart int with the startindex.
     * @param aEnd int with the endindex.
     */
    public void setLocation(int aStart, int aEnd) {
        this.iStart = aStart;
        this.iEnd = aEnd;
    }

    /**
     * This method reports on the start index of the header. It returns '-1' if
     * no location is specified.
     *
     * @return int with the start location, or '-1' if none was defined.
     */
    public int getStartLocation() {
        return iStart;
    }

    /**
     * This method reports on the end index of the header. It returns '-1' if no
     * location is specified.
     *
     * @return int with the end location, or '-1' if none was defined.
     */
    public int getEndLocation() {
        return iEnd;
    }

    /**
     * This method provides a deep copy of the Header instance.
     *
     * @return Object Header that is a deep copy of this Header.
     */
    public Object clone() {
        Object result = null;
        try {
            result = super.clone();
        } catch (CloneNotSupportedException cnse) {
//            logger.severe(cnse.getMessage());
        }
        return result;
    }

    /**
     * Returns the implemented database types as an array of String.
     *
     * @return the implemented database types as an array of String
     */
    public static String[] getDatabaseTypesAsString() {
        DatabaseType[] enumValues = DatabaseType.values();
        String[] result = new String[enumValues.length];
        for (int i = 0; i < enumValues.length; i++) {
            result[i] = getDatabaseTypeAsString(enumValues[i]);
        }
        return result;
    }

    /**
     * Convenience method returning the database name as a String.
     *
     * @param databaseType the database type
     * @return the name
     */
    public static String getDatabaseTypeAsString(DatabaseType databaseType) {

        switch (databaseType) {
            case UniProt:
                return "UniProtKB";
            case Unknown:
                return "Unknown";
            case NCBI:
                return "NCBI";
            case IPI:
                return "IPI (deprecated)";
            case H_Invitation:
                return "H_Invitation";
            case Halobacterium:
                return "Halobacterium";
            case H_Influenza:
                return "H_Influenza";
            case C_Trachomatis:
                return "C_Trachomatis";
            case M_Tuberculosis:
                return "M_Tuberculosis";
            case Drosophile:
                return "Drosophile";
            case SGD:
                return "SGD";
            case Flybase:
                return "Flybase";
            case GenomeTranslation:
                return "Genome to protein translation";
            case Arabidopsis_thaliana_TAIR:
                return "Arabidopsis thaliana TAIR";
            case PSB_Arabidopsis_thaliana:
                return "PSB Arabidopsis thaliana";
            case Listeria:
                return "Listeria";
            case Generic_Header:
                return "User Defined";
            case Generic_Split_Header:
                return "Generic Header";
            case GAFFA:
                return "GAFFA";
            case UPS:
                return "Universal Proteomic Standard";
            case NextProt:
                return "neXtProt";
            case UniRef:
                return "UniRef";
            default:
                throw new UnsupportedOperationException("Database type not implemented: " + databaseType + ".");
        }
    }

    /**
     * Tries to extract the gene name, taxonomy and the protein evidence level
     * from a UniProt description.
     *
     * @param header the header to parse.
     */
    private static void parseUniProtDescription(Header header) {

        // try to get the gene name from the description
        if (header.iDescription.contains(" GN=")) {
            int geneStartIndex = header.iDescription.indexOf(" GN=") + 4;
            int geneEndIndex = header.iDescription.indexOf(" ", geneStartIndex);

            if (geneEndIndex != -1) {
                header.iGeneName = header.iDescription.substring(geneStartIndex, geneEndIndex);
            } else {
                header.iGeneName = header.iDescription.substring(geneStartIndex);
            }
        }

        // try to get the protein evidence level from the description
        if (header.iDescription.contains(" PE=")) {
            int evidenceStartIndex = header.iDescription.indexOf(" PE=") + 4;
            int evidenceEndIndex = header.iDescription.indexOf(" ", evidenceStartIndex);

            if (evidenceEndIndex != -1) {
                header.iProteinEvidence = header.iDescription.substring(evidenceStartIndex, evidenceEndIndex);
            } else {
                header.iProteinEvidence = header.iDescription.substring(evidenceStartIndex);
            }

            // http://www.uniprot.org/manual/protein_existence
        }

        // try to get the taxonomy name from the description
        if (header.iDescription.contains(" OS=")) {
            int taxonomyStartIndex = header.iDescription.indexOf(" OS=") + 4;
            int taxonomyEndIndex = header.iDescription.indexOf(" GN=");

            // have to check if gene name is in the header
            if (taxonomyEndIndex == -1) {
                if (header.iDescription.contains(" PE=")) {
                    taxonomyEndIndex = header.iDescription.indexOf(" PE=");
                } else {
                    taxonomyEndIndex = header.iDescription.length();
                }
            }

            header.iTaxonomy = header.iDescription.substring(taxonomyStartIndex, taxonomyEndIndex);

            // now we can also shorten the protein description
            String tempShortHeader = header.iDescription.substring(0, taxonomyStartIndex - 3);
            header.iDescriptionShort = tempShortHeader.substring(tempShortHeader.indexOf(" ") + 1).trim();
            header.iDescriptionProteinName = tempShortHeader.substring(0, tempShortHeader.indexOf(" "));
        }
    }

    /**
     * Return the Uniprot protein evidence type as text.
     *
     * @param type the type of evidence
     *
     * @return the protein evidence type as text
     */
    public static String getProteinEvidencAsString(Integer type) {

        switch (type) {
            case 1:
                return "Protein";
            case 2:
                return "Transcript";
            case 3:
                return "Homology";
            case 4:
                return "Predicted";
            case 5:
                return "Uncertain";
            default:
                return null;
        }
    }
}
