<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="/WEB-INF/struts-html.tld" prefix="html" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib tagdir="/WEB-INF/tags" prefix="im"%>

<html:xhtml/>

<div class="body">
<im:boxarea title="Data" stylename="plainbox"><p><fmt:message key="dataCategories.intro"/></p></im:boxarea>


<table cellpadding="0" cellspacing="0" border="0" class="dbsources">
  <tr>
    <th>Data Category</th>
    <th>Organism</th>
    <th>Data</th>
    <th>Source</th>
    <th>PubMed</th>
  </tr>
  <tr>
      <td rowspan="3" class="leftcol">
          <h2><p>Genomes</p></h2>
      </td>
      <td> <i>C. griseus</i> </td>
      <td> Genome annotation for C. gricetulus </td>
      <td> - </td>
      <td> Brinkrolf et al - <a
              href="http://www.ncbi.nlm.nih.gov/pubmed/23929341" target="_new"
              class="extlink">PubMed: 23929341</a>
      </td>
  </tr>
  <tr>
      <td> <i>C. griseus</i> </td>
      <td> Genome annotation for C. gricetulus </td>
      <td> - </td>
      <td> Lewis et al - <a
              href="http://www.ncbi.nlm.nih.gov/pubmed/23873082" target="_new"
              class="extlink">PubMed: 23873082</a>
      </td>
  </tr>  
  <tr>
      <td> Chinese hamster ovary - K1 cell line </td>
      <td> Genome annotation for CHO-K1 cell line </td>
      <td> - </td>
      <td> Xu et al - <a
              href="http://www.ncbi.nlm.nih.gov/pubmed/21804562" target="_new"
              class="extlink">PubMed: 21804562</a>
      </td>
  </tr>  
  <tr>
    <td rowspan="2"  class="leftcol"><p><h2>Proteins</h2></p></td>
    <td>
        <p><i>C. griseus</i></p>
    </td>
    <td> Protein annotation</td>
    <td> <a href="http://www.ebi.uniprot.org/index.shtml" target="_new" class="extlink">UniProt</a> - Release 2016_10</td>
    <td> UniProt Consortium - <a href="http://www.ncbi.nlm.nih.gov/pubmed/17142230" target="_new" class="extlink">PubMed: 17142230</a></td>
  </tr>
  <tr>
    <td>
        <p><i>C. griseus</i></p>
    </td>
    <td> Protein family and domain assignments to proteins</td>
    <td> <a href="http://www.ebi.ac.uk/interpro" target="_new" class="extlink">InterPro</a>Version 60.0</td>
    <td> Mulder et al - <a href="http://www.ncbi.nlm.nih.gov/pubmed/17202162" target="_new" class="extlink">PubMed: 17202162</a></td>
  </tr>

  <tr>
    <td rowspan="2" class="leftcol"><p> <h2>Pathways</h2></p></td>
    <td> <p><i>C. griseus</i></p></td>
    <td> Curated pathway information and the genes involved in them</td>
    <td> <a href="http://www.genome.jp/kegg/" target="_new" class="extlink">KEGG</a> - Release 80.1</td>
    <td> Kanehisa et al - <a href="http://www.ncbi.nlm.nih.gov/pubmed/16381885" target="_new" class="extlink">PubMed: 16381885</a></td>
  </tr>
  <tr>
    <td> <p>Different CHO cell lines</p></td>
    <td> Metabolic model</td>
    <td> - </td>
    <td> Hefzi, Ang, Hanscho et al - <a href="https://www.ncbi.nlm.nih.gov/pubmed/27883890" target="_new" class="extlink">PubMed: 27883890</td>
  </tr>

  <tr>
      <td rowspan="1" class="leftcol"><p> <h2>ncRNA</h2></p></td>
      <td> <i>C. griseus</i></td>
      <td> miRNAs from miRBase</td>
      <td> <a href="http://www.mirbase.org/" target="_new" class="extlink">miRBase</a> - Release 21 </td>
      <td> Griffiths-Jones et al - <a href="http://www.ncbi.nlm.nih.gov/pubmed/16381832" target="_new" class="extlink">PubMed: 16381832</a></td>
  </tr>

  <tr>
    <td rowspan="2"  class="leftcol"><p><h2>Ontologies</h2></p></td>
    <td>
        <p><i> </i></p>
    </td>
    <td> Sequence ontology </td>
    <td> <a href="http://www.sequenceontology.org/" target="_new" class="extlink">The Sequence Ontology Project</a> - version 2015-06-22</td>
    <td> Sequence Ontology Project - <a href="http://www.ncbi.nlm.nih.gov/pubmed/15892872" target="_new" class="extlink">PubMed: 15892872</a></td>
  </tr>
  <tr>
    <td>
        <p><i> </i></p>
    </td>
    <td> GO annotations </td>
    <td> <a href="http://www.geneontology.org/" target="_new" class="extlink">Gene Ontology</a> - releases/version2016-11-29</td>
    <td> Gene Ontology Consortium - <a href="http://www.ncbi.nlm.nih.gov/pubmed/10802651" target="_new" class="extlink">PubMed: 10802651</a></td>
  </tr>

  <tr>
    <td rowspan="1" class="leftcol"><p> <h2>Publications</h2></p></td>
    <td> <p><i>C. griseus</i></p></td>
    <td> Gene versus publications </td>
    <td> <a href="http://www.ncbi.nlm.nih.gov/" target="_new" class="extlink">NCBI</a> - November 2016</td>
    <td> &nbsp; </td>
  </tr>

</table>
