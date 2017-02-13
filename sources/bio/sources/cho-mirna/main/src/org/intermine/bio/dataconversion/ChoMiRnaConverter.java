package org.intermine.bio.dataconversion;

/*
 * Copyright (C) 2002-2015 FlyMine
 *
 * This code may be freely distributed and modified under the
 * terms of the GNU Lesser General Public Licence.  This should
 * be distributed with the code.  See the LICENSE file for more
 * information or http://www.gnu.org/copyleft/lesser.html.
 *
 */

import java.io.Reader;
import java.util.Iterator;
import java.util.concurrent.ConcurrentHashMap;

import org.apache.log4j.Logger;
import org.intermine.dataconversion.ItemWriter;
import org.intermine.metadata.Model;
import org.intermine.metadata.Util;
import org.intermine.util.FormattedTextParser;
import org.intermine.xml.full.Item;



/**
 * 
 * @author
 */
public class ChoMiRnaConverter extends BioFileConverter
{
	
	private static final Logger LOG = Logger.getLogger(ChoMiRnaConverter.class);

    private static final String DATASET_TITLE = "CHO miRNA";
    private static final String DATA_SOURCE_NAME = "miRNA";
    
    private ConcurrentHashMap<String, Item> miRnaMap = new ConcurrentHashMap<String, Item>();
    private ConcurrentHashMap<String, Item> chrMap = new ConcurrentHashMap<String, Item>();
    
    /**
     * Constructor
     * @param writer the ItemWriter used to handle the resultant items
     * @param model the Model
     */
    public ChoMiRnaConverter(ItemWriter writer, Model model) {
        super(writer, model, DATA_SOURCE_NAME, DATASET_TITLE, null);
    }

    /**
     * 
     *
     * {@inheritDoc}
     */
    public void process(Reader reader) throws Exception {
    	// Create Data source for miRBase
		Item datasource = createItem("DataSource");
		datasource.setAttribute("name", "miRBase");
		datasource.setAttribute("url", "http://www.mirbase.org/");
		datasource.setAttribute("description", "microRNA database");	
    	
    	Iterator<?> lineIter = FormattedTextParser.parseTabDelimitedReader(reader);
    	while (lineIter.hasNext()) {
    		// split into infos
    		String[] line = (String[]) lineIter.next();
    		
    		// check line structure
    		if (line.length < 7){
    			LOG.error("miRNA bowtie file has wrong format: as line cannot be split into 7 Strings:\n" + line + "\n");
    			continue;
    		}
    		
    		// define id and name
    		String id = line[0];
    		String[] temp = id.split(" ");
    		String name = temp[0];
    		String mirbase_id = temp[1];
    		
    		// define if miRNA is stemloop or mature and set parent name
    		boolean is_mature = false;
    		String parent = name;
    		if (mirbase_id.contains("MIMAT")){
    			// check line structure for mature miRNAs
    			if (line.length < 8){
        			LOG.error("miRNA bowtie file has wrong format: as line cannot be split into 8 Strings:\n" + line + "\n");
        			continue;
        		}
    			is_mature = true;
    			parent = line[7];
    		}
    		
    		// get other information out of line
    		String strand = line[1];
    		String chromosome = line[2];
    		int start = Integer.parseInt(line[3]);
    		String sequence = line[4];
    		int len = sequence.length();
    		int end = start + len - 1;
    		
    		// get or create the miRNA item
    		Item cgrMiRNA = miRnaMap.get(parent);
    		if (cgrMiRNA == null){
    			cgrMiRNA = createItem("CgrMiRNA");
    			cgrMiRNA.setAttribute("primaryIdentifier", parent);
    			cgrMiRNA.setAttribute("name", parent);
    			cgrMiRNA.setAttribute("symbol", parent);
    			miRnaMap.put(parent, cgrMiRNA);
            }
    		
    		// set miRNA type (mature or stemloop)
    		Item miRNA = createItem("MiRNA");
    		String type = is_mature ? "mature" : "stemloop";
    		miRNA.setAttribute("type", type);
    		miRNA.setAttribute("name", name);
    		miRNA.setAttribute("symbol", name);
    		miRNA.setAttribute("length", Integer.toString(len));
    		miRNA.setAttribute("mirbaseaccession", mirbase_id);
    		String m_id;
    		if (chromosome.startsWith("gi")){
    			m_id = "lewis.";
    		} else if (chromosome.startsWith("N")){
    			m_id = "xu.";
    		} else {
    			m_id = "brinkrolf.";
    		}
    		m_id = m_id.concat(name);
    		miRNA.setAttribute("primaryIdentifier", m_id);
    		
    		// add sequence
    		Item seqItem = createItem("Sequence");
    		seqItem.setAttribute("residues", sequence);
    		seqItem.setAttribute("length", Integer.toString(len));
    		seqItem.setAttribute("md5checksum", Util.getMd5checksum(sequence));
    		miRNA.setReference("sequence", seqItem);
    		store(seqItem);

    		// get or create chromosome
    		Item chrItem = chrMap.get(chromosome);
    		if (chrItem == null){
    			chrItem = createItem("Chromosome");
    			chrItem.setAttribute("primaryIdentifier", chromosome);
    			chrMap.put(chromosome, chrItem);
    		}
    		
    		// create location item
    		Item locItem = createItem("Location");
    		locItem.setAttribute("start", Integer.toString(start));
    		locItem.setAttribute("end", Integer.toString(end));
    		locItem.setAttribute("strand", strand);
    		locItem.setReference("locatedOn", chrItem);
    		chrItem.addToCollection("locatedFeatures", locItem);
    		    		
    		// link miRNA to location
    		locItem.setReference("feature", miRNA);
    		store(locItem);
    		
    		// Create CrossReference for miRBase
    		Item crossReference = createItem("CrossReference");
    		crossReference.setAttribute("identifier", mirbase_id);
    		crossReference.setReference("source", datasource);
    		miRNA.addToCollection("crossReferences", crossReference);
    		crossReference.setReference("subject", miRNA);
    		store(crossReference);
    		
    		cgrMiRNA.addToCollection("mirnas", miRNA);
    		miRNA.setReference("cgrmirna", cgrMiRNA);
    		miRNA.setReference("chromosomeLocation", locItem);
    		store(miRNA);
    	}

    	// store items to database
    	store(miRnaMap.values());
    	store(chrMap.values());
    	store(datasource);
    }
    
}
