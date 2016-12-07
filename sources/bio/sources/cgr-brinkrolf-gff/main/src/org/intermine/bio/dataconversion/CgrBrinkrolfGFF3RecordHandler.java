package org.intermine.bio.dataconversion;

/*
 * Copyright (C) 2015 ChoMine
 *
 * This code may be freely distributed and modified under the
 * terms of the GNU Lesser General Public Licence.  This should
 * be distributed with the code.  See the LICENSE file for more
 * information or http://www.gnu.org/copyleft/lesser.html.
 *
 */
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.intermine.bio.io.gff3.GFF3Record;
import org.intermine.metadata.Model;
import org.intermine.xml.full.Item;

/**
 * A converter/retriever for the Chinese hamster dataset published by Brinkrolf
 * et al via GFF files.
 */

public class CgrBrinkrolfGFF3RecordHandler extends GFF3RecordHandler
{
	private ConcurrentHashMap<String, Item> geneMap = new ConcurrentHashMap<String, Item>();
	private ConcurrentHashMap<String, Item> xrefMap = new ConcurrentHashMap<String, Item>();
	private ConcurrentHashMap<String, Item> sourceMap = new ConcurrentHashMap<String, Item>();
	
	/**
     * Create a new ChoGFF3RecordHandler for the given data model.
     * @param model the model for which items will be created
     */
    public CgrBrinkrolfGFF3RecordHandler (Model model) {
        super(model);
        refsAndCollections.put("Exon", "transcripts");
        refsAndCollections.put("MRNA", "gene");
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void process(GFF3Record record) {
    	Item feature = getFeature();
    	String clsName = feature.getClassName();

    	if (clsName.equalsIgnoreCase("mRNA")) {
    		Map<String, List<String>> attributes = record.getAttributes();
    		annotateMRNA(feature, attributes);
    	}
    }
    
    private void annotateMRNA(Item mRNA, Map<String, List<String>> attributes) {
    	if (mRNA.getAttribute("primaryIdentifier") != null) {
    		String mRNA_id = mRNA.getAttribute("primaryIdentifier").getValue();
    		Item gene = geneMap.get(mRNA_id);
    		if (gene == null) {
    			gene = converter.createItem("Gene");
    			gene.setAttribute("primaryIdentifier", mRNA_id);
    			gene.setAttribute("length", mRNA.getAttribute("length").getValue());
    			gene.setReference("chromosome", mRNA.getReference("chromosome").getRefId());
    			gene.setReference("chromosomeLocation", mRNA.getReference("chromosomeLocation").getRefId());
    			geneMap.put(mRNA_id, gene);
    			addItem(gene);
    			gene.addToCollection("transcripts", mRNA);
        		mRNA.setReference("gene", gene);
    		}
    		String dbxref = getAttributeString(attributes, "db_xref");
    		if (dbxref != null) {
    			if (dbxref.contains("GI:")){
    				String[] spl = dbxref.split("GI:");
    				String[] spl2 = spl[1].split("//D");
    				Item xref = getXref(spl2[0]);
    				xref.setReference("subject", gene);
    				gene.addToCollection("crossReferences", xref);
    			}
    		}
    	}
    }
    
    private Item getXref (String id) {
    	Item genPept = sourceMap.get("GenPept");
    	if (genPept == null) {
    		genPept = converter.createItem("DataSource");
    		genPept.setAttribute("name", "GenPept");
    		genPept.setAttribute("url", "http://www.ncbi.nlm.nih.gov/protein/");
    		genPept.setAttribute("description", "Protein database");
    		sourceMap.put("GenPept", genPept);
    		addItem(genPept);
    	}
    	Item xref = xrefMap.get(id);
		if (xref == null) {
			xref = converter.createItem("CrossReference");
			xref.setAttribute("identifier", id);
			xref.setReference("source", genPept);
			xrefMap.put(id, xref);
			addItem(xref);
		}
		return xref;
    }
    
      
    private String getAttributeString(Map<String, List<String>> attributes, String name) {
    	List<String> l = attributes.get(name);
    	if (l != null) {
    		return l.get(0);
    	}
    	return null;
    }

}
