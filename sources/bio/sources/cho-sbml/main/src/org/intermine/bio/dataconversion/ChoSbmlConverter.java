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

import java.io.File;
import java.io.Reader;
import java.util.HashSet;
import java.util.concurrent.ConcurrentHashMap;

import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.apache.log4j.Logger;
import org.intermine.dataconversion.ItemWriter;
import org.intermine.metadata.Model;
import org.intermine.objectstore.ObjectStoreException;
import org.intermine.xml.full.Item;
import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;



/**
 * 
 * @author
 */
public class ChoSbmlConverter extends BioFileConverter
{
	
	private static final Logger LOG = Logger.getLogger(ChoSbmlConverter.class);

    private static final String DATASET_TITLE = "CHO sbml models";
    private static final String DATA_SOURCE_NAME = "sbml";
    
    private ConcurrentHashMap<String, Item> modelMap = new ConcurrentHashMap<String, Item>();
    private ConcurrentHashMap<String, Item> compartmentMap = new ConcurrentHashMap<String, Item>();
    private ConcurrentHashMap<String, Item> speciesMap = new ConcurrentHashMap<String, Item>();
    private ConcurrentHashMap<String, Item> reactionMap = new ConcurrentHashMap<String, Item>();
//    private ConcurrentHashMap<String, ArrayList<Item>> geneMap = new ConcurrentHashMap<String, ArrayList<Item>>();
    private ConcurrentHashMap<String, Item> speciesReferenceMap = new ConcurrentHashMap<String, Item>();
    
    private ConcurrentHashMap<String, Item> m_compartmentMap = new ConcurrentHashMap<String, Item>();
    private ConcurrentHashMap<String, Item> m_speciesMap = new ConcurrentHashMap<String, Item>();
    private ConcurrentHashMap<String, Item> m_reactionMap = new ConcurrentHashMap<String, Item>();
//    private ConcurrentHashMap<String, ArrayList<Item>> m_geneMap = new ConcurrentHashMap<String, ArrayList<Item>>();
    private ConcurrentHashMap<String, Item> m_speciesReferenceMap = new ConcurrentHashMap<String, Item>();
    private HashSet<Item> m_modelReactionSet = new HashSet<Item>();

    private Item currentModel;
    private String actualReactionId;
	private boolean inReactants = false;
    
    /**
     * Constructor
     * @param writer the ItemWriter used to handle the resultant items
     * @param model the Model
     */
    public ChoSbmlConverter(ItemWriter writer, Model model) {
        super(writer, model, DATA_SOURCE_NAME, DATASET_TITLE, null);
    }

    /**
     * 
     *
     * {@inheritDoc}
     */
    public void process(Reader reader) throws Exception {
    	try {
    		m_compartmentMap.clear();
    		m_speciesMap.clear();
    		m_reactionMap.clear();
//    		m_geneMap.clear();
    		m_speciesReferenceMap.clear();
    		m_modelReactionSet.clear();
    		File inputFile = getCurrentFile();
    		SAXParserFactory factory = SAXParserFactory.newInstance();
    		SAXParser saxParser = factory.newSAXParser();
    		SbmlHandler sbmlHandler = new SbmlHandler();
    		saxParser.parse(inputFile, sbmlHandler);     
    	} catch (Exception e) {
    		e.printStackTrace();
    	}
    	try {
    		store(currentModel);
    		store(m_compartmentMap.values());
    		store(m_speciesMap.values());
    		store(m_reactionMap.values());
//    		Iterator<ArrayList<Item>> iter = m_geneMap.values().iterator();
//    		while (iter.hasNext()){
//    			ArrayList<Item> temp = iter.next();
//    			Iterator<Item> iter2 = temp.iterator();
//    			while (iter2.hasNext()){
//    				store(iter2.next());
//    			}
//    		}
    		store(m_speciesReferenceMap.values());
    		store(m_modelReactionSet);
    	} catch (ObjectStoreException e){
    		LOG.error("Could not store sbml model");
    		e.printStackTrace();

    	}
    }
    
    private class SbmlHandler extends DefaultHandler {

    	
    	
    	@Override
    	public void startElement(String uri,String localName, String qName, Attributes attributes) throws SAXException {
    		try {
    			if (qName.equals("model")){
    				processModel(attributes);
    			} else if (qName.equals("compartment")){
    				processCompartment(attributes);
    			} else if (qName.equals("species")){
    				processSpecies(attributes);
    			} else if (qName.equals("reaction")){
    				processReaction(attributes);
    			} else if (qName.equals("listOfReactants")) {
    				inReactants = true;
    			} else if (qName.equals("speciesReference")){
    				processSpeciesReference(attributes);
//    			} else if (qName.equals("fbc:geneProduct")){
//    				processGeneProducts(attributes);
//    			} else if (qName.equals("fbc:geneProductRef")) {
//    				processGeneProductRef(attributes);
    			}
    		} catch (Exception e){
    			LOG.error("SBML file is not valid");
    			e.printStackTrace();
    			System.exit(1);
    		}
    	}

    	@Override
    	public void endElement(String uri, String localName, String qName) throws SAXException {
    		if (qName.equals("listOfReactants")) {
    			inReactants = false;
			}
    	}

    	@Override
    	public void characters(char ch[], int start, int length) throws SAXException {

    	}
    	
    	private void checkValue(String val, String msg) throws Exception {
    		if (val == null){
    			throw new Exception(msg + " is not available");
    		} else if (val.isEmpty()){
    			throw new Exception(msg + " is not available");
    		}
    	}
    	
    	private void checkItem(Item item, String msg) throws Exception{
    		if (item == null){
    			throw new Exception(msg + " is not available");
    		}
    	}
    	
    	private Item getItem(String type, String id, ConcurrentHashMap<String, Item> map) throws Exception{
    		Item item = null;
    		if (map != null){
    			if (map.get(id) != null){
    				return map.get(id);
    			}
    		}
    		item = createItem(type);
    		return item;
    		
    	}
    	
    	private boolean existItem(String type, String id, ConcurrentHashMap<String, Item> map) throws Exception{
    		if (map != null){
    			if (map.get(id) != null){
    				return true;
    			}
    		} else {
    			
    		}
    		return false;
    	}
    	
//    	private boolean existItemInList(String type, String id, ConcurrentHashMap<String, ArrayList<Item>> map) throws Exception{
//    		if (map != null){
//    			if (map.get(id) != null){
//    				return true;
//    			}
//    		}
//    		return false;
//    	}
    	
//    	private void processGeneProductRef(Attributes attributes) throws Exception {
//    		String product = attributes.getValue("fbc:geneProduct");
//    		checkValue(product, "Gene product");
//    		ArrayList<Item> gene = geneMap.get(product);
//    		if (gene == null){
//    			throw new Exception("Product gene " + product + " is not available");
//    		}
//    		Item reaction = reactionMap.get(actualReactionId);
//    		Iterator<Item> iter = gene.iterator();
//    		while (iter.hasNext()){
//    			Item geneItem = iter.next();
//    			reaction.addToCollection("genes", geneItem);
//        		geneItem.addToCollection("reactions", reaction);
//    		}
//    	}
    	
//    	private void processGeneProducts(Attributes attributes) throws Exception {
//    		// get attributes
//    		String id = attributes.getValue("fbc:id");
//			String label = attributes.getValue("fbc:label");
//			// check attributes
//			checkValue(id, "GeneProduct id");
//			checkValue(label, "GeneProduct label for " + id);
//			// create gene(s)
//			if (!existItemInList("Gene", id, geneMap)){
//				ArrayList<Item> geneList = new ArrayList<Item>();
//				if (label.contains(",")){
//					String[] temp = label.split(",");
//					for (int i = 0; i < temp.length; i++){
//						Item gene = createItem("Gene");
//						gene.setAttribute("primaryIdentifier", temp[i]);
//						gene.setAttribute("secondaryIdentifier", temp[i]);
//						gene.setAttribute("geneID", temp[i]);
//						gene.setAttribute("modelID", id);
//						if (!geneList.contains(gene)) {
//							geneList.add(gene);
//							geneMap.put(id, geneList);
//							m_geneMap.put(id, geneMap.get(id));
//						}
//					}
//				} else {
//					Item gene = createItem("Gene");
//					gene.setAttribute("primaryIdentifier", label);
//					gene.setAttribute("secondaryIdentifier", label);
//					gene.setAttribute("geneID", label);
//					gene.setAttribute("modelID", id);
//					if (!geneList.contains(gene)) {
//						geneList.add(gene);
//						geneMap.put(id, geneList);
//						m_geneMap.put(id, geneMap.get(id));
//					}
//				}
//			}			
//    	}
    	
    	private void processModel(Attributes attributes) throws Exception {
    		// get attributes
    		String id = attributes.getValue("id");
    		// check attributes
    		checkValue(id, "Model id");
    		// create compartment
    		if (!existItem("MetabolicModel", id, modelMap)){
    			Item model = getItem("MetabolicModel", id, modelMap);
    			model.setAttribute("primaryIdentifier", id);
    			model.setAttribute("name", id);
    			modelMap.put(id, model);
    			currentModel = model;
    		} else {
    			throw new Exception("Metabolic Model " + id + " already loaded");
    		}
    	}
    	
    	private void processCompartment(Attributes attributes) throws Exception {
    		// get attributes
    		String id = attributes.getValue("id");
			String name = attributes.getValue("name");
			// check attributes
			checkValue(id, "Compartment id");
			checkValue(name, "Compartment name for " + id);
			// create compartment
			Item compartment;
			if (!existItem("Compartment", id, compartmentMap)){
				compartment = getItem("Compartment", id, compartmentMap);
				compartment.setAttribute("primaryIdentifier", id);
				compartment.setAttribute("name", name);
				compartmentMap.put(id, compartment);
				m_compartmentMap.put(id, compartment);
			}
			// add compartment to model
			compartment = getItem("Compartment", id, compartmentMap);
			currentModel.addToCollection("compartments", compartment);
    	}
    	
    	private String getSpeciesId(String id){
    		String x = id.replaceAll("^M_", "");
    		x = x.replaceAll("_.$", "");
    		return x;
    	}
    	
    	private void processSpecies(Attributes attributes) throws Exception{
    		// get attributes
    		String id = attributes.getValue("id");
    		id = getSpeciesId(id);
			String name = attributes.getValue("name");
			String compartment = attributes.getValue("compartment");
			String formula = attributes.getValue("fbc:chemicalFormula");
			// check attributes
			checkValue(id, "Species id");
			checkValue(name, "Name for species id " + id);
			checkValue(compartment, "Compartment for species id " + id);
			Item compartment_item = compartmentMap.get(compartment);
			checkItem(compartment_item, "Compartment " + compartment + " for species " + id);
			// create species
			Item species;
			if (!existItem("Species", id, speciesMap)){
				species = getItem("Species", id, speciesMap);
				species.setAttribute("primaryIdentifier", id);
				species.setAttribute("name", name);
				if (formula != null) {
					species.setAttribute("formula", formula);
				}
				speciesMap.put(id, species);
				m_speciesMap.put(id, species);
			}
			// add species to model
			species = getItem("Species", id, speciesMap);
			boolean addToComp = true;
			if (compartment_item.hasCollection("species")){
				if (compartment_item.getCollection("species").getRefIds().contains(species.getIdentifier())){
					addToComp = false;
				}
			}
			if (addToComp) {
				compartment_item.addToCollection("species", species);
				species.addToCollection("compartments", compartment_item);
			}
			currentModel.addToCollection("species", species);
    	}
    	
    	private String getReactionId(String modelId) {
    		String id = modelId;
			id = id.replaceFirst("R_", "");
			return id;
    	}
    	
    	private void processReaction(Attributes attributes) throws Exception{
    		// get attributes
    		String model_id = attributes.getValue("id");
			String name = attributes.getValue("name");
			String reversible = attributes.getValue("reversible");
			reversible = (reversible == null) ? "true" : reversible;
			// check attributes
			checkValue(model_id, "Reaction id");
			checkValue(name, "Name for reaction id " + model_id);
			// set actual reaction id for reactants and products
			String id = getReactionId(model_id);
			actualReactionId = id;
			// create reaction
			Item reaction;
			if (!existItem("Reaction", id, reactionMap)){
				reaction = getItem("Reaction", id, reactionMap);
				reaction.setAttribute("primaryIdentifier", id);
				reaction.setAttribute("name", name);
				reaction.setAttribute("modelID", model_id);
				reactionMap.put(id, reaction);
				m_reactionMap.put(id, reaction);
			}
			reaction = getItem("Reaction", id, reactionMap);
			Item modelReaction = createItem("ReactionDetail");
			modelReaction.setAttribute("name", name);
			modelReaction.setAttribute("reversible", reversible);
			modelReaction.setReference("reaction", reaction);
			modelReaction.setReference("metabolicmodel", currentModel);
			m_modelReactionSet.add(modelReaction);
    	}
    	
    	private void processSpeciesReference(Attributes attributes) throws Exception{
    		// get and check actual reaction
    		Item reaction_item = reactionMap.get(actualReactionId);
    		checkItem(reaction_item, "reaction for reaction id " + actualReactionId);
    		// get attributes
    		String species = attributes.getValue("species");
			String stoichiometry = attributes.getValue("stoichiometry");
			// check attributes
			checkValue(species, "species for reaction " + actualReactionId);
			checkValue(stoichiometry, "stoichiometry for reaction " + actualReactionId);
			if (inReactants){
				stoichiometry = Double.toString(-1 * Double.valueOf(stoichiometry)); 
			}
			// get and check species
			String species_id = getSpeciesId(species);
			Item species_item = speciesMap.get(species_id);
			checkItem(species_item, species_id + " for reaction " + actualReactionId);
			// create collections
			species_item.addToCollection("reactions", reaction_item);
			reaction_item.addToCollection("species", species_item);
			// create reactant or product
			String name = species_item.getAttribute("name").getValue();
			String ref_id = stoichiometry + "_" + name;
			if (!existItem("Speciesreference", ref_id, speciesReferenceMap)){
				Item item = getItem("Speciesreference", ref_id, speciesReferenceMap);
				item.setAttribute("stoichiometry", stoichiometry);
				item.setAttribute("name", name);
				item.setReference("species", species_item);
				speciesReferenceMap.put(ref_id, item);
				m_speciesReferenceMap.put(ref_id, item);
			}	
			Item item = speciesReferenceMap.get(ref_id);
			reaction_item.addToCollection("speciesreferences", item);
			item.addToCollection("reactions", reaction_item);
    	}

    }

}
