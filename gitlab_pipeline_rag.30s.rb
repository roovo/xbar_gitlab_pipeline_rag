#!/usr/bin/env ruby

# <xbar.title>Gitlab Pipeline RAG</xbar.title>
# <xbar.desc>Shows the RAG status of your gitlab piplines.</xbar.desc>
# <xbar.author>roovo</xbar.author>
# <xbar.author.github>roovo</xbar.author.github>
# <xbar.version>v0.01</xbar.version>
# <xbar.dependencies>ruby</xbar.dependencies>
# <xbar.image>https://raw.githubusercontent.com/roovo/xbar_gitlab_pipeline_rag/refs/heads/main/gitlab_pipeline_rag.png</xbar.image>
# <xbar.abouturl>https://github.com/roovo/xbar_gitlab_pipeline_rag</xbar.abouturl>

# <xbar.var>string(GITLAB_URL=""): URL of your gitlab instance</xbar.var>
# <xbar.var>string(GITLAB_TOKEN=""): Gitlab access token</xbar.var>
# <xbar.var>string(PROJECTS_JSON=""): JSON object literal of projects and their Gitlab IDs, e.g. {"Project 1":123, "Project 2":17}</xbar.var>

require 'net/http'
require 'json'

def api_fetch(project_id)
  uri = URI("#{ENV['GITLAB_URL']}/api/v4/projects/#{project_id}/pipelines")
  params = { private_token: ENV['GITLAB_TOKEN'],
             order_by: 'id',
             sort: 'desc',
             page: 1,
             per_page: 100 }
  uri.query = URI.encode_www_form(params)

  res = Net::HTTP.get_response(uri)
  if res.is_a?(Net::HTTPSuccess)
    JSON.parse res.body
  elsif res.is_a?(Net::HTTPUnauthorized)
    raise 'Unauthorized - has your gitlab token expired?'
  else
    []
  end
end

def latest_pipeline(pipelines)
  pipelines
    .filter { |p| p['status'] != 'canceled' }
    .filter { |p| p['ref'] == 'main' || p['ref'].match(/^v\d+\.\d+\.\d+$/) }
    .first || {}
end

def overall_status(statuses)
  if statuses.include? 'failed'
    'failed'
  elsif statuses.include? 'manual'
    'manual'
  elsif statuses.uniq == ['success']
    'success'
  else
    'running'
  end
end

TANUKI_ICONS = {
  'success' => 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAABLUExURQAAACLFXiLFXiLFXiLFXiLFXiLFXiLFXiLFXiLFXiLFXiLFXiLFXiLFXiLFXiLFXiLFXiLFXiLFXiLFXiLFXiLFXiLFXiLFXgAAAL+eej0AAAAXdFJOUwAAZAHzIid3jQYKQryfMQJRLxbboG1FTLOwXgAAAAFiS0dEAIgFHUgAAAAHdElNRQfqBQsSFiEruUiiAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI2LTA1LTExVDE4OjIyOjMyKzAwOjAw66ymNwAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNi0wNS0xMVQxODoyMjozMiswMDowMJrxHosAAAAodEVYdGRhdGU6dGltZXN0YW1wADIwMjYtMDUtMTFUMTg6MjI6MzIrMDA6MDDN5D9UAAAAbElEQVQY012OWQ6AIBBDi4gs7rj0/jd1GDVR+tO+lxAGQENalFiykTIt6VQ4sjVAR9Kr8LI6IEjpG1tGQCxFl1JyutDzHwy1GGsx1WKuBZYfL/L/+uFVL8zbg1vGnbgr7xFvzCF8GHxy8rzHBQVoDxTACASEAAAAAElFTkSuQmCC',
  'failed'  => 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAABLUExURQAAAO9ERO9ERO9ERO9ERO9ERO9ERO9ERO9ERO9ERO9ERO9ERO9ERO9ERO9ERO9ERO9ERO9ERO9ERO9ERO9ERO9ERO9ERO9ERAAAADyj2E4AAAAXdFJOUwAAZAHzIid3jQYKQryfMQJRLxbboG1FTLOwXgAAAAFiS0dEAIgFHUgAAAAHdElNRQfqBQsSFiEruUiiAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI2LTA1LTExVDE4OjIyOjMzKzAwOjAwTdutgwAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNi0wNS0xMVQxODoyMjozMyswMDowMDyGFT8AAAAodEVYdGRhdGU6dGltZXN0YW1wADIwMjYtMDUtMTFUMTg6MjI6MzMrMDA6MDBrkzTgAAAAbElEQVQY012OWQ6AIBBDi4gs7rj0/jd1GDVR+tO+lxAGQENalFiykTIt6VQ4sjVAR9Kr8LI6IEjpG1tGQCxFl1JyutDzHwy1GGsx1WKuBZYfL/L/+uFVL8zbg1vGnbgr7xFvzCF8GHxy8rzHBQVoDxTACASEAAAAAElFTkSuQmCC',
  'manual'  => 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAABLUExURQAAAJyjr5yjr5yjr5yjr5yjr5yjr5yjr5yjr5yjr5yjr5yjr5yjr5yjr5yjr5yjr5yjr5yjr5yjr5yjr5yjr5yjr5yjr5yjrwAAAKJt7P4AAAAXdFJOUwAAZAHzIid3jQYKQryfMQJRLxbboG1FTLOwXgAAAAFiS0dEAIgFHUgAAAAHdElNRQfqBQsSFiEruUiiAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI2LTA1LTExVDE4OjIyOjMzKzAwOjAwTdutgwAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNi0wNS0xMVQxODoyMjozMyswMDowMDyGFT8AAAAodEVYdGRhdGU6dGltZXN0YW1wADIwMjYtMDUtMTFUMTg6MjI6MzMrMDA6MDBrkzTgAAAAbElEQVQY012OWQ6AIBBDi4gs7rj0/jd1GDVR+tO+lxAGQENalFiykTIt6VQ4sjVAR9Kr8LI6IEjpG1tGQCxFl1JyutDzHwy1GGsx1WKuBZYfL/L/+uFVL8zbg1vGnbgr7xFvzCF8GHxy8rzHBQVoDxTACASEAAAAAElFTkSuQmCC',
  'running' => 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAABLUExURQAAAPlzFvlzFvlzFvlzFvlzFvlzFvlzFvlzFvlzFvlzFvlzFvlzFvlzFvlzFvlzFvlzFvlzFvlzFvlzFvlzFvlzFvlzFvlzFgAAAEs7MrYAAAAXdFJOUwAAZAHzIid3jQYKQryfMQJRLxbboG1FTLOwXgAAAAFiS0dEAIgFHUgAAAAHdElNRQfqBQsSFiEruUiiAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI2LTA1LTExVDE4OjIyOjMzKzAwOjAwTdutgwAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNi0wNS0xMVQxODoyMjozMyswMDowMDyGFT8AAAAodEVYdGRhdGU6dGltZXN0YW1wADIwMjYtMDUtMTFUMTg6MjI6MzMrMDA6MDBrkzTgAAAAbElEQVQY012OWQ6AIBBDi4gs7rj0/jd1GDVR+tO+lxAGQENalFiykTIt6VQ4sjVAR9Kr8LI6IEjpG1tGQCxFl1JyutDzHwy1GGsx1WKuBZYfL/L/+uFVL8zbg1vGnbgr7xFvzCF8GHxy8rzHBQVoDxTACASEAAAAAElFTkSuQmCC'
}.freeze

def icon(status)
  TANUKI_ICONS.fetch(status, TANUKI_ICONS['running'])
end

begin
  projects = JSON.parse ENV['PROJECTS_JSON']
  project_pipelines = projects.map { |name, id| [name, api_fetch(id)] }
  latest_pipelines = project_pipelines.map { |name, p| [name, latest_pipeline(p)] }
                                      .reject { |_, p| p.empty? }
  latest_statuses = latest_pipelines.map(&:last).map { |p| p.fetch('status', 'unknown') }
  overall = overall_status(latest_statuses)

  puts "| image=#{icon(overall)}"
  puts '---'

  latest_pipelines.each do |name, pipline|
    puts "#{name} | image=#{icon(pipline.fetch('status', 'running'))} href=#{pipline.fetch('web_url').gsub(/ *\d+$/, '')}"
  end
rescue StandardError => e
  puts '⚠️'
  puts '---'
  puts e.message.gsub(/\(.*\)/, '')
end
