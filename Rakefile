namespace :gen do
  desc 'Regenerate mrbgem library data (_data/mgems.yml)'
  task :mgemdata do
    require 'mgem'
    require 'yaml'

    # mgem still uses old exists? method
    class File
      class << self
        alias_method :exists?, :exist? unless method_defined?(:exists?)
      end
    end

    include Mrbgem
    mgems = load_gems
    mgems.update!

    mgem_info = mgems.map do |mgem|
      {
        'name'        => mgem.name,
        'description' => mgem.description,
        'author'      => mgem.author,
        'website'     => mgem.website,
        'protocol'    => mgem.protocol,
        'repository'  => mgem.repository,
        'repooptions' => mgem.repooptions
      }
    end

    mgem_info.sort_by! { |g| g['name'].downcase }

    dest = File.join(__dir__, '_data', 'mgems.yml')

    File.write(dest, mgem_info.to_yaml)
    puts "Written #{dest}"
  end

  desc 'Regenerate API documentation from mruby source (clones latest release into mruby/)'
  task :mrbdoc do
    require 'json'
    require 'shellwords'

    # Resolve latest stable release tag via gh CLI (mruby uses tags, not GitHub Releases)
    tags = []
    page = 1
    loop do
      batch = JSON.parse(`gh api "repos/mruby/mruby/tags?per_page=100&page=#{page}"`)
      break if batch.empty?
      tags.concat(batch)
      break if batch.size < 100
      page += 1
    end
    tag = tags.map { |t| t['name'] }.find { |n| n.match?(/^\d+\.\d+\.\d+$/) }
    raise "Could not determine latest stable mruby release tag" unless tag
    puts "Latest mruby release: #{tag}"

    # Clone mruby at the release tag (or skip if already at the right version)
    mruby_dir = File.join(__dir__, 'mruby')
    current_tag = Dir.exist?(mruby_dir) ? `git -C #{Shellwords.escape(mruby_dir)} describe --exact-match HEAD 2>/dev/null`.strip : nil
    if current_tag == tag
      puts "mruby #{tag} already cloned, skipping clone"
    else
      puts current_tag ? "mruby dir exists at #{current_tag}, re-cloning at #{tag}" : "Cloning mruby #{tag}"
      FileUtils.rm_rf(mruby_dir)
      sh "git clone --depth 1 --branch #{Shellwords.escape(tag)} https://github.com/mruby/mruby.git #{Shellwords.escape(mruby_dir)}"
    end

    # Run mrbdoc (from yard-mruby) in the mruby directory — equivalent to doc:api
    Dir.chdir(mruby_dir) do
      sh "env BUNDLE_GEMFILE=#{Shellwords.escape(File.join(__dir__, 'Gemfile'))} bundle exec mrbdoc"
    end

    # Copy generated docs into our docs/api/ directory
    dest = File.join(__dir__, 'docs', 'api')
    FileUtils.mkdir_p(dest)
    FileUtils.cp_r(Dir.glob("#{mruby_dir}/doc/api/*"), dest)
    puts "Copied mruby API docs to #{dest}"
  end

  desc 'Regenerate contributor list from mruby AUTHORS file (_data/contributors.yml)'
  task :contributors do
    require 'yaml'

    mruby_dir = File.join(__dir__, 'mruby')
    raise "mruby/ not found — run gen:mrbdoc first" unless Dir.exist?(mruby_dir)

    threshold = (ENV['CONTRIBUTOR_THRESHOLD'] || '10').to_i

    # AUTHORS format: "   COUNT Name (@login)[*+]"
    contributors = File.readlines(File.join(mruby_dir, 'AUTHORS'), chomp: true)
      .filter_map do |line|
        m = line.match(/^\s*(\d+)\s+(.+?)\s+\(@([\w-]+)\)[*+]?\s*$/)
        next unless m
        count = m[1].to_i
        next if count < threshold
        { 'name' => m[2], 'login' => m[3], 'count' => count }
      end

    dest = File.join(__dir__, '_data', 'contributors.yml')
    File.write(dest, contributors.to_yaml)
    puts "Written #{contributors.size} contributors (threshold: #{threshold} commits) to #{dest}"
  end

  desc 'Regenerate release data from GitHub API (_data/releases.yml)'
  task :releasedata do
    require 'json'
    require 'shellwords'
    require 'yaml'

    repo      = 'mruby/mruby'
    data_file = File.join(__dir__, '_data', 'releases.yml')

    gh_api = lambda { |path| JSON.parse(`gh api #{Shellwords.escape(path)}`) }

    post_dates = {}
    Dir.glob(File.join(__dir__, '_posts', '*.{markdown,md}')).each do |f|
      if (m = File.basename(f).match(/^(\d{4}-\d{2}-\d{2})-mruby-([\d.]+)-released/))
        post_dates[m[2]] = m[1]
      end
    end

    tags = []
    page = 1
    loop do
      batch = gh_api.call("/repos/#{repo}/tags?per_page=100&page=#{page}")
      break if batch.empty?
      tags.concat(batch)
      break if batch.size < 100
      page += 1
    end

    versioned = tags.select { |t| t['name'].match?(/^\d/) }

    releases = versioned.map do |tag|
      version    = tag['name']
      prerelease = !version.match?(/^\d+\.\d+\.\d+$/)
      date       = post_dates[version] || begin
        commit = gh_api.call("/repos/#{repo}/commits/#{tag['commit']['sha']}")
        commit.dig('commit', 'committer', 'date')&.slice(0, 10)
      end
      puts "  #{version}: #{date}#{' (prerelease)' if prerelease}"
      { 'version' => version, 'date' => date, 'prerelease' => prerelease }
    end

    File.write(data_file, releases.to_yaml)
    puts "\nWritten #{releases.size} releases to #{data_file}"
  end
end

desc 'Build the Jekyll site'
task build: %w[gen:mgemdata gen:mrbdoc gen:contributors gen:releasedata] do
  sh 'bundle exec jekyll build'
end

desc 'Serve the Jekyll site locally with live reload'
task :serve do
  sh 'bundle exec jekyll serve'
end

task default: :build
