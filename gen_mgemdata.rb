require 'mgem'
require 'yaml'

mgems = load_gems 

mgems.update!

mgem_info = []
mgems.each do |mgem| 
  mgem_info << { 
    'name' => mgem.name,
    'description' => mgem.description,
    'author' => mgem.author,
    'website' => mgem.website,
    'protocol' => mgem.protocol,
    'repository' => mgem.repository,
    'repooptions' => mgem.repooptions
  }
end

File.open('_data/mgems.yml', 'w') do |f| 
  f.write(mgem_info.to_yaml)
end
