package org.intermine.bio.dataconversion;

/*
 * Copyright (C) 2016 ChoMine
 *
 * This code may be freely distributed and modified under the
 * terms of the GNU Lesser General Public Licence.  This should
 * be distributed with the code.  See the LICENSE file for more
 * information or http://www.gnu.org/copyleft/lesser.html.
 *
 */
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.intermine.bio.io.gff3.GFF3Record;
import org.intermine.metadata.Model;
import org.intermine.xml.full.Attribute;
import org.intermine.xml.full.Item;

/**
 * A converter/retriever for the Cho dataset via GFF files.
 */

public class ChoLewisXuGFF3RecordHandler extends GFF3RecordHandler
{
	private ConcurrentHashMap<String, Item> genesMap = new ConcurrentHashMap<String, Item>();
	private ConcurrentHashMap<String, Item> transcriptMap = new ConcurrentHashMap<String, Item>();
	private ConcurrentHashMap<String, Item> miRBaseMap = new ConcurrentHashMap<String, Item>();
	private ConcurrentHashMap<String, Item> proteinMap = new ConcurrentHashMap<String, Item>();
	
	private String prefix;
	
	/**
	 * Create a new ChoGFF3RecordHandler for the given data model.
	 * @param model the model for which items will be created
	 */
	public ChoLewisXuGFF3RecordHandler (Model model, String prefix) {
		super(model);
		this.prefix = prefix;
		refsAndCollections.put("Exon", "transcripts");
        refsAndCollections.put("MRNA", "gene");
        refsAndCollections.put("TRNA", "gene");
        refsAndCollections.put("RRNA", "gene");
        refsAndCollections.put("NcRNA", "gene");
        refsAndCollections.put("PrimaryTranscript", "gene");
        refsAndCollections.put("CGeneSegment", "gene");
        refsAndCollections.put("VGeneSegment", "gene");
	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	public void process(GFF3Record record) {
		Item feature = getFeature();
		Map<String, List<String>> attributes = record.getAttributes();
		
		// general jobs
		setIDs(feature, attributes);
		setNotes(feature, attributes);
		
		// annotate different features
		if (attributes != null) {
			String featureName = feature.getClassName();
			if (featureName.equalsIgnoreCase("gene")) {
				annotateGene(feature, attributes);
			} else if (featureName.equalsIgnoreCase("mRNA")) {
				annotateMRNA(feature, attributes);
			} else if (featureName.equalsIgnoreCase("tRNA")) {
				annotateTRna(feature, attributes);
			} else if (featureName.equalsIgnoreCase("rRNA")) {
				annotateTranscript(feature, attributes);
			} else if (featureName.equalsIgnoreCase("ncRNA")) {
				annotateNcRNA(feature, attributes);
			} else if (featureName.equalsIgnoreCase("PrimaryTranscript")) {
				annotateTranscript(feature, attributes);
			} else if (featureName.equalsIgnoreCase("transcript")) {
				annotateTranscript(feature, attributes);
			} else if (featureName.equalsIgnoreCase("CGeneSegment")) {
				annotateGeneSegment(feature, attributes);
			} else if (featureName.equalsIgnoreCase("VGeneSegment")) {
				annotateGeneSegment(feature, attributes);
			} else if (featureName.equalsIgnoreCase("CDS")) {
				annotateCDS(feature, attributes);
			} else if (featureName.equalsIgnoreCase("exon")) {
				annotateExon(feature, attributes);
			}
		}
	}
	
	private void annotateGene(Item gene, Map<String, List<String>> attributes) {
		String gene_id = prefix + "." + getAttributeString(attributes, "ID");
		if (gene_id != null) {
			if (!genesMap.contains(gene_id)) {
				gene.setClassName("Gene");
				gene.setReference("organism", getOrganism());
				// if another thread in the meantime added the gene use that one
				if (genesMap.putIfAbsent(gene_id, gene) != null){
					gene = genesMap.get(gene_id);
				}
				genesMap.put(gene_id, gene);
			}
			gene.setAttribute("symbol", getAttributeString(attributes, "gene"));
			gene.setAttribute("name", getAttributeString(attributes, "Name"));
			addGeneID(gene, attributes);
			setPartial(gene, attributes);
			appendToAttribute(gene, attributes, "description", "description");
			setSingleAttribute(gene, attributes, "pseudo", "pseudo");
			addGeneSynonyms(gene, attributes);
		}
	}
	
	private void annotateTranscript(Item transcript, Map<String, List<String>> attributes) {
		String id = prefix + "." + getAttributeString(attributes, "ID");
		if (id != null) {
			if (!transcriptMap.contains(id)) {
				transcript.setReference("organism", getOrganism());
				String name = getAttributeString(attributes, "Name");
				if (name != null) {
					transcript.setAttribute("symbol", name);
					transcript.setAttribute("name", name);
				}
				addTranscriptID(transcript, attributes);
				addTranscriptParent(transcript, attributes);
				setProductDescription(transcript, attributes);
				// if another thread in the meantime added the transcript use that one
				if (transcriptMap.putIfAbsent(id, transcript) != null) {
					transcript = transcriptMap.get(id);
				}
			} else {
				System.out.println("[Transcript] found " + id + " already in my list");
			}
			addMiRBase(transcript, attributes);
		}
	}
	private void annotateMRNA(Item mRNA, Map<String, List<String>> attributes) {
		annotateTranscript(mRNA, attributes);
		setPartial(mRNA, attributes);
	}
	
	private void annotateNcRNA(Item ncRNA, Map<String, List<String>> attributes) {
		annotateTranscript(ncRNA, attributes);
		setSingleAttribute(ncRNA, attributes, "ncrna_class", "ncRnaClass");
	}
	
	private void annotateTRna(Item tRNA, Map<String, List<String>> attributes) {
		annotateTranscript(tRNA, attributes);
		setSingleAttribute(tRNA, attributes, "part", "part");
		setSingleAttribute(tRNA, attributes, "anticodon", "anticodon");
	}
	
	private void annotateCDS (Item cds, Map<String, List<String>> attributes) {
		setPartial(cds, attributes);
		setProductDescription(cds, attributes);
		List<String> plist = attributes.get("parent_type");
		if (plist != null) {
			if (!plist.isEmpty()) {
				String parent_type = plist.get(0);
				if (parent_type.equals("gene")) {
					Item gene = getParentGene(attributes);
					if (gene != null) {
						cds.setReference("gene", gene);
						gene.addToCollection("CDSs", cds);
					}
				} else if (parent_type.equals("mRNA")) {
					Item mRNA = getParentTranscript(attributes, "MRNA");
					if (mRNA != null) {
						cds.setReference("transcript", mRNA);
						mRNA.addToCollection("CDSs", cds);
					}
				}
			}
		}
		Item protein = getProtein(attributes);
		if (protein != null) {
			cds.setReference("protein", protein);
			protein.addToCollection("CDSs", cds);
		}
	}
	
	private void annotateExon (Item exon, Map<String, List<String>> attributes) {
		setPartial(exon, attributes);
		setProductDescription(exon, attributes);
		setSingleAttribute(exon, attributes, "exon_number", "exonNumber");
		List<String> plist = attributes.get("parent_type");
		if (plist != null) {
			if (!plist.isEmpty()) {
				String parent_type = plist.get(0);
				Item parent = null;
				if (parent_type.equalsIgnoreCase("transcript")) {
					parent = getParentTranscript(attributes, "Transcript");
				} else if (parent_type.equalsIgnoreCase("primary_transcript")) {
					parent = getParentTranscript(attributes, "PrimaryTranscript");
				} else if (parent_type.equalsIgnoreCase("ncRNA")) {
					parent = getParentTranscript(attributes, "NcRNA");
				} else if (parent_type.equalsIgnoreCase("mRNA")) {
					parent = getParentTranscript(attributes, "MRNA");
				} else if (parent_type.equalsIgnoreCase("rRNA")) {
					parent = getParentTranscript(attributes, "RRNA");
				} else if (parent_type.equalsIgnoreCase("tRNA")) {
					parent = getParentTranscript(attributes, "TRNA");
				}
				if (parent != null) {
					exon.addToCollection("transcripts", parent);
					parent.addToCollection("exons", exon);
				}
			}
		}		
	}
	
	private void annotateGeneSegment(Item item, Map<String, List<String>> attributes) {
		setSingleAttribute(item, attributes, "part", "part");
		Item gene = getParentGene(attributes);
		if (gene != null) {
			item.setReference("gene", gene);
			gene.addToCollection("genesegments", item);
		}
	}
	
	
	private String getAttributeString(Map<String, List<String>> attributes, String name) {
		List<String> l = attributes.get(name);
		if (l != null) {
			if (!l.isEmpty()){
				return l.get(0);
			}
		}
		return null;
	}
	
	private void setSingleAttribute (Item item, Map<String, List<String>> attributes, String gffAttr, String modelAttr) {
		List<String> list = attributes.get(gffAttr);
		if (list != null) {
			if (!list.isEmpty()) {
				item.setAttribute(modelAttr, list.get(0));
			}
		}
	}
	
	private void setPrefixAttribute (Item item, Map<String, List<String>> attributes, String gffAttr, String modelAttr) {
		List<String> list = attributes.get(gffAttr);
		if (list != null) {
			if (!list.isEmpty()) {
				item.setAttribute(modelAttr, prefix + "." + list.get(0));
			}
		}
	}
	
	private void appendToAttribute(Item item, Map<String, List<String>> attributes, String gffAttr, String modelAttr) {
		List<String> list = attributes.get(gffAttr);
		if (list != null) {
			Iterator<String> iter = list.iterator();
			while (iter.hasNext()) {
				String note = iter.next();
				Attribute noteAttribute = item.getAttribute(modelAttr);
				if (noteAttribute != null) {
					note = noteAttribute.getValue() + ";" + note;
				}
				item.setAttribute(modelAttr, note);
			}
		}
	}
	
	private void setPartial(Item item, Map<String, List<String>> attributes) {
		setSingleAttribute(item, attributes, "partial", "partial");
	}
	
	private void setIDs(Item item, Map<String, List<String>> attributes) {
		setPrefixAttribute(item, attributes, "ID", "primaryIdentifier");
		List<String> dbxrefs = attributes.get("Dbxref");
		if (dbxrefs != null) {
			Iterator<String> iter = dbxrefs.iterator();
			if (iter.hasNext()) {
				String dbxref = iter.next();
				if (dbxref.contains("Genbank:")){
					String[] spl = dbxref.split("Genbank:");
					String div = "//D";
					if (spl[1].contains(",")) {
						div = ",";
					} else if (spl[1].contains(",")) {
						div = ";";
					}
					String[] spl2 = spl[1].split(div);
					item.setAttribute("genbank", spl2[0]);	
				}
			}
		}
	}

	private void setNotes(Item item, Map<String, List<String>> attributes) {
	    addNote(item, attributes, "Note", "Note");
	    addNote(item, attributes, "exception", "Exception");
	    addNote(item, attributes, "transl_exception", "TranslationException");
	}

	private void addNote(Item item, Map<String, List<String>> attributes, String gffNote, String type) {
	   	List<String> l = attributes.get(gffNote);
    	if (l != null) {
    		Iterator<String> iter = l.iterator();
    		while (iter.hasNext()) {
    			Item temp = converter.createItem("Comment");
    			temp.setAttribute("type", type);
    			temp.setAttribute("description", iter.next());
    			addItem(temp);
    			item.addToCollection("comments", temp);
    		}
    	}	
	}
	
	private void addGeneID(Item gene, Map<String, List<String>> attributes) {
		List<String> dbxrefs = attributes.get("Dbxref");
		if (dbxrefs != null) {
			if (!dbxrefs.isEmpty()){
				String dbxref = dbxrefs.get(0);
				if (dbxref.contains("GeneID:")){
					String[] spl = dbxref.split("GeneID:");
					String div = "//D";
					if (spl[1].contains(",")) {
						div = ",";
					} else if (spl[1].contains(";")) {
						div = ";";
					}
					String[] spl2 = spl[1].split(div);
					gene.setAttribute("secondaryIdentifier", spl2[0]);	
				}
			}
		}
	}
	
	private void addGeneSynonyms(Item gene, Map<String, List<String>> attributes) {
		List<String> syn = attributes.get("gene_synonym");
		if (syn != null) {
			Iterator<String> iter = syn.iterator();
			while (iter.hasNext()) {
				String synon = iter.next();
				Item s = converter.createItem("Synonym");
				s.setAttribute("value", synon);
				s.setReference("subject", gene);
				addItem(s);
				gene.addToCollection("synonyms", s);
			}
		}
	}

	private void addTranscriptID(Item transcript, Map<String, List<String>> attributes) {
		String val = getAttributeString(attributes, "transcript_id");
		if (val != null) {
			transcript.setAttribute("secondaryIdentifier", val);
		}
	}
	
	private void addTranscriptParent(Item transcript, Map<String, List<String>> attributes) {
		Item gene = getParentGene(attributes);
		if (gene != null) {
			transcript.setReference("gene", gene);
			gene.addToCollection("transcripts", transcript);
		}
	}

	private void addMiRBase(Item transcript, Map<String, List<String>> attributes) {
		List<String> dbxrefs = attributes.get("Dbxref");
		if (dbxrefs != null) {
			Iterator<String> iter = dbxrefs.iterator();
			if (iter.hasNext()) {
				String dbxref = iter.next();
				if (dbxref.contains("miRBase:")){
					String[] spl = dbxref.split("miRBase:");
					for (int i=1; i<spl.length; i++) {
						String div = "//D";
						if (spl[1].contains(",")) {
							div = ",";
						} else if (spl[1].contains(",")) {
							div = ";";
						}
						String[] spl2 = spl[1].split(div);
						String id = spl2[0];
						Item mirbase = miRBaseMap.get(id);
						if (mirbase == null) {
							mirbase = converter.createItem("MiRBase");
							mirbase.addToCollection("transcripts", transcript);
							if (miRBaseMap.putIfAbsent(id, mirbase) == null){
								addItem(mirbase);
							} else {
								mirbase = miRBaseMap.get(id);
							}
							
						}
						transcript.addToCollection("mirbases", mirbase);
					}
				}
			}
		}

	}

	private void setProductDescription(Item item, Map<String, List<String>> attributes) {
		List<String> l = attributes.get("product");
    	if (l != null) {
    		Iterator<String> iter = l.iterator();
    		while (iter.hasNext()) {
    			Item comment = converter.createItem("Comment");
    			comment.setAttribute("type", "Product");
    			comment.setAttribute("description", iter.next());
    			addItem(comment);
    			item.addToCollection("comments", comment);
    		}
    	}
	}
	
	private Item getParentGene(Map<String, List<String>> attributes) {
		String id = getAttributeString(attributes, "Parent");
		if (id != null) {
			id = prefix + "." + id;
			Item gene = genesMap.get(id);
			if (gene == null) {
				gene = converter.createItem("Gene");
				gene.setReference("organism", getOrganism());
				gene.setAttribute("primaryIdentifier", id);
				if (genesMap.putIfAbsent(id, gene) == null) {
					addItem(gene);
				} else {
					gene = genesMap.get(id);
				}
			}
			return gene;
		}
		return null;
	}
	
	private Item getParentTranscript(Map<String, List<String>> attributes, String classname) {
		String id = getAttributeString(attributes, "Parent");
		if (id != null) {
			id = prefix + "." + id;
			Item item = transcriptMap.get(id);
			if (item == null) {
				item = converter.createItem(classname);
				item.setReference("organism", getOrganism());
				item.setAttribute("primaryIdentifier", id);
				if (transcriptMap.putIfAbsent(id, item) == null) {
					addItem(item);
				} else {
					item = transcriptMap.get(id);
				}
			}
			return item;
		}
		return null;
	}

	private Item getProtein(Map<String, List<String>> attributes) {
		String protein_id = getAttributeString(attributes, "protein_id");
		if (protein_id != null) {
			Item protein = proteinMap.get(protein_id);
			if (protein == null) {
				protein = converter.createItem("Protein");
				protein.setAttribute("primaryIdentifier", protein_id);
				protein.setAttribute("symbol", protein_id);
				protein.setReference("organism", getOrganism());
				if (proteinMap.putIfAbsent(protein_id, protein) == null){
					addItem(protein);
				} else {
					protein = proteinMap.get(protein_id);
				}
				
			}
			return protein;
		}
		return null;
	}

}
