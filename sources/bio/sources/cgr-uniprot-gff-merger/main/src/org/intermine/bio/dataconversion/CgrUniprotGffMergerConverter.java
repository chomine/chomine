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

import org.intermine.dataconversion.FileConverter;
import org.intermine.dataconversion.ItemWriter;
import org.intermine.metadata.Model;
import org.intermine.util.FormattedTextParser;
import org.intermine.xml.full.Item;


/**
 * 
 * @author
 */
public class CgrUniprotGffMergerConverter extends FileConverter
{
    
    private ConcurrentHashMap<String, Item> geneMap = new ConcurrentHashMap<String, Item>();
	private ConcurrentHashMap<String, Item> proteinMap = new ConcurrentHashMap<String, Item>();
		
    /**
     * Constructor
     * @param writer the ItemWriter used to handle the resultant items
     * @param model the Model
     */
    public CgrUniprotGffMergerConverter(ItemWriter writer, Model model) {
    	super(writer, model);
    }

    /**
     * 
     *
     * {@inheritDoc}
     */
    public void process(Reader reader) throws Exception {
    	Iterator<?> lineIter = FormattedTextParser.parseCsvDelimitedReader(reader);
    	 while (lineIter.hasNext()) {
             String[] line = (String[]) lineIter.next();
             if (line.length < 3 || line[0].startsWith("#")) {
                 continue;
             }
             String gene_id = line[0];
             String protein_id = line[1];
             String protein_acc = line[2];
             
             Item gene = geneMap.get(gene_id);
             if (gene == null){
            	 gene = createItem("Gene");
            	 gene.setAttribute("primaryIdentifier", gene_id);
            	 geneMap.put(gene_id, gene);
             }
             Item protein = proteinMap.get(protein_id);
             if (protein == null){
            	 protein = createItem("Protein");
            	 protein.setAttribute("primaryIdentifier", protein_id);
            	 protein.setAttribute("primaryAccession", protein_acc);
            	 proteinMap.put(protein_id, protein);
             }
             gene.addToCollection("proteins", protein);
             protein.addToCollection("genes", gene);
             geneMap.replace(gene_id, gene);
             proteinMap.replace(protein_id, protein);
         }
    	 System.out.println(geneMap.values());
    	 store(geneMap.values());
    	 store(proteinMap.values());
    	 geneMap.clear();
    }
}
