# Regenerate _data/releases.yml from GitHub API.
#
# All pages derive the current stable release from the first non-prerelease
# entry in this file. Run this script after each new release or RC tag.
#
# Stable release dates are sourced from blog post filenames where available,
# falling back to the GitHub commit date for releases without a post.
#
# Usage:
#   bundle exec ruby gen_releasedata.rb
#
# Requires a GitHub token via GH_TOKEN env var or `gh auth token`.

require 'net/http'
require 'json'
require 'yaml'

REPO = 'mruby/mruby'
DATA_FILE = File.join(__dir__, '_data', 'releases.yml')

def gh_get(path)
  uri = URI("https://api.github.com#{path}")
  token = ENV['GH_TOKEN'] || `gh auth token 2>/dev/null`.strip
  headers = {
    'Accept'        => 'application/vnd.github.v3+json',
    'User-Agent'    => 'mruby-site',
    'Authorization' => "Bearer #{token}"
  }
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    JSON.parse(http.get(uri.request_uri, headers).body)
  end
end

# Derive release dates from blog post filenames (format: YYYY-MM-DD-mruby-X.Y.Z-released.*)
post_dates = {}
Dir.glob(File.join(__dir__, '_posts', '*.{markdown,md}')).each do |f|
  if (m = File.basename(f).match(/^(\d{4}-\d{2}-\d{2})-mruby-([\d.]+)-released/))
    post_dates[m[2]] = m[1]
  end
end

# Fetch all tags (paginated)
tags = []
page = 1
loop do
  batch = gh_get("/repos/#{REPO}/tags?per_page=100&page=#{page}")
  break if batch.empty?
  tags.concat(batch)
  break if batch.size < 100
  page += 1
end

# Keep all version-like tags (stable + rc/preview)
versioned = tags.select { |t| t['name'].match?(/^\d/) }

releases = versioned.map do |tag|
  version = tag['name']
  prerelease = !version.match?(/^\d+\.\d+\.\d+$/)
  date = post_dates[version] || begin
    commit = gh_get("/repos/#{REPO}/commits/#{tag['commit']['sha']}")
    commit.dig('commit', 'committer', 'date')&.slice(0, 10)
  end
  $stdout.puts "  #{version}: #{date}#{' (prerelease)' if prerelease}"
  { 'version' => version, 'date' => date, 'prerelease' => prerelease }
end

File.write(DATA_FILE, releases.to_yaml)
$stdout.puts "\nWritten #{releases.size} releases to #{DATA_FILE}"
