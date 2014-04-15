require 'git'

Dir.mktmpdir do |tmp_mruby_src|

  Git.clone('https://github.com/mruby/mruby.git', 'mruby', :path => tmp_mruby_src)
 
  $: << "#{tmp_mruby_src}/mruby/doc/language/mrbdoc/lib"

  require 'mrbdoc_analyze'
  require 'mrbdoc_docu'

  mrbdoc = MRBDoc.new

  mrbdoc.analyze_code "#{tmp_mruby_src}/mruby/" do |progress|
    puts progress
  end

  cfg = {:print_line_no => false}
  mrbdoc.write_documentation 'docs/', cfg do |progress|
    puts progress
  end

  Dir.glob('docs/*.md') do |md_filename|
    title = File.basename(md_filename, '.md')
    File.open("#{md_filename}.tmp", 'w') do |md_file|
      md_file << "---\nlayout: default\ntitle: #{title}\n---\n\n"
      md_file << File.read(md_filename)
    end
    File.rename("#{md_filename}.tmp", md_filename)
  end

end
