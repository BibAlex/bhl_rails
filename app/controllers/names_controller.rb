class NamesController < ApplicationController
  def index
    @page_title = I18n.t(:tree_of_life_title)
    @entries = Hierarchy.find_all_by_browsable(1)
  end

  def show
    parent_id = params[:id]
    hierarchy_id = params[:h_id]
    parent_id = 0 unless parent_id
    hierarchy_id = DEFAULT_HIERARCHY_ID unless hierarchy_id
    @hierarchy_entries = HierarchyEntry.find_siblings(hierarchy_id, parent_id)
    render :layout => 'main' # this is a blank layout as I don't need any layout in this action
  end
  
  def get_content
    @id = params[:id]
    @taxon_concept_id = HierarchyEntry.get_taxon_concept_id(@id)
    @name = TaxonConcept.get_name(@taxon_concept_id)
    image_source = TaxonConcept.get_image(@taxon_concept_id)
    if image_source.nil?
      @image = nil
    else
      @image = EOL_CONTENT_PATH + image_source.to_s.from(0).to(3) + "/" +  
                  image_source.to_s.from(4).to(1) + "/" + 
                  image_source.to_s.from(6).to(1) + "/" +
                  image_source.to_s.from(8).to(1) + "/" +
                  image_source.to_s.from(10) + "_260_190.jpg"
    end
    
    rsolr = RSolr.connect :url => SOLR_BOOKS_METADATA
    search = rsolr.select :params => { :q => "name:#{@name}"}
    @books_count = search['response']['numFound']
    
    render :layout => 'main' # this is a blank layout as I don't need any layout in this action
  end
end
