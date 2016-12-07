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
import org.intermine.metadata.Model;

/**
 * A converter/retriever for the Cho dataset via GFF files.
 */

public class ChoXuGFF3RecordHandler extends ChoLewisXuGFF3RecordHandler
{
	
	/**
	 * Create a new ChoGFF3RecordHandler for the given data model.
	 * @param model the model for which items will be created
	 */
	public ChoXuGFF3RecordHandler (Model model) {
		super(model, "xu");
	}

}
