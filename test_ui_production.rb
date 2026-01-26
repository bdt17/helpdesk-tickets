#!/usr/bin/env ruby
require 'net/http'
require 'nokogiri'
require 'colorize'
require 'json'
require 'tty-table'

# ========================================
# THOMAS IT PHARMA HELPDESK - PRODUCTION UI TEST SUITE
# Tests ALL pages + future-proof
# ========================================
class ThomasITHelpdeskProductionTester
  BASE_URL = ENV['TEST_URL'] || 'https://helpdesk-tickets-zyfh.onrender.com'
  PAGES = ['/', '/tickets', '/stats', '/about']
  
  attr_reader :results
  
  def initialize
    @results = { passed: 0, failed: 0, total: 0, page_data: {} }
    puts "🚀 THOMAS IT PHARMA HELPDESK".green.bold
    puts "📍 PRODUCTION URL: #{BASE_URL}".cyan.bold
    puts "⏰ Testing #{PAGES.count} pages...".yellow
    puts "=" * 80
  end
  
  def run_full_suite
    test_critical_paths
    test_data_integrity
    test_pharma_priorities
    test_responsiveness
    generate_report
    save_json_report
    exit_status
  end
  
  def test_critical_paths
    puts "\n📋 1. CRITICAL PATHS".cyan.bold
    PAGES.each do |path|
      print "   🔗 #{path.ljust(15)} ".white
      result = test_page_load(path)
      log_result(path, result)
    end
  end
  
  def test_data_integrity
    puts "\n📊 2. DATA INTEGRITY".cyan.bold
    home_data = scrape_homepage
    log_result('tickets_count', home_data[:tickets])
    log_result('pharma_priority', home_data[:priority_1])
    log_result('stats', home_data[:stats])
  end
  
  def test_pharma_priorities
    puts "\n🎯 3. PHARMA PRIORITIES".cyan.bold
    priorities = scrape_priorities
    priorities.each do |priority|
      log_result("priority_#{priority[:id]}", priority[:title])
    end
  end
  
  def test_responsiveness
    puts "\n📱 4. RESPONSIVENESS".cyan.bold
    response_times = PAGES.map { |p| measure_response_time(p) }
    avg_response = response_times.sum / response_times.size.to_f
    log_result('avg_response_time', "#{avg_response.round(2)}s")
    
    if avg_response < 3.0
      puts "   ✅ AVERAGE: #{avg_response.round(2)}s (FAST)".green
    else
      puts "   ⚠️  AVERAGE: #{avg_response.round(2)}s (SLOW)".yellow
    end
  end
  
  def generate_report
    puts "\n" + "="*80
    puts "🏆 PRODUCTION CERTIFICATION REPORT".green.bold
    
    table = TTY::Table.new(
      ['TEST', 'STATUS', 'DETAILS'],
      results[:page_data].map do |test, data|
        status = data[:passed] ? '✅ PASS' : '❌ FAIL'
        color = data[:passed] ? :green : :red
        [test.to_s.capitalize, status.send(color), data[:details] || 'OK']
      end
    )
    puts table.render(:unicode, alignments: [:left, :center, :left])
    
    puts "\n📈 SUMMARY".cyan.bold
    puts "✅ PASSED: #{results[:passed]} | ❌ FAILED: #{results[:failed]}"
    puts "🎯 PHARMA TRANSPORT = #{results[:page_data][:pharma_priority]&.dig(:details) || 'PENDING'}"
  end
  
  private
  
  def test_page_load(path)
    response = safe_http_get(path)
    if response[:success]
      puts "#{response[:time].round(2)}s".green
      { passed: true, details: "#{response[:code]} #{response[:time].round(2)}s" }
    else
      puts "FAIL".red
      { passed: false, details: response[:error] }
    end
  end
  
  def scrape_homepage
    response = safe_http_get('/')
    return { tickets: 0 } unless response[:success]
    
    doc = Nokogiri::HTML(response[:body])
    {
      tickets: doc.css('table tr').count - 1,
      priority_1: doc.css('table tr td:nth-child(2)').first&.text&.strip,
      stats: doc.text.scan(/Open.*?\d+|Total.*?\d+/i)
    }
  end
  
  def scrape_priorities
    response = safe_http_get('/')
    return [] unless response[:success]
    
    doc = Nokogiri::HTML(response[:body])
    doc.css('table tr')[1..6].map.with_index do |row, i|
      {
        id: i+1,
        title: row.css('td:nth-child(2)')&.text&.strip,
        status: row.css('td:nth-child(3)')&.text&.strip
      }
    end
  end
  
  def measure_response_time(path)
    start_time = Time.now
    safe_http_get(path)
    Time.now - start_time
  end
  
  def safe_http_get(path)
    start_time = Time.now
    uri = "#{BASE_URL}#{path}"
    
    begin
      http = Net::HTTP.new(URI(uri).host, URI(uri).port)
      http.use_ssl = uri.start_with?('https')
      http.open_timeout = 15
      http.read_timeout = 15
      
      response = http.request(Net::HTTP::Get.new(URI(uri).request_uri))
      {
        success: response.code == '200',
        code: response.code,
        body: response.body,
        time: Time.now - start_time
      }
    rescue => e
      {
        success: false,
        error: e.message,
        time: Time.now - start_time
      }
    end
  end
  
  def log_result(test_name, data)
    passed = data.is_a?(Hash) ? data[:passed] : !!data
    results[:page_data][test_name] = {
      passed: passed,
      details: data.is_a?(Hash) ? data[:details] : data.to_s
    }
    results[:passed] += 1 if passed
    results[:failed] += 1 unless passed
    results[:total] += 1
  end
  
  def save_json_report
    File.write('ui_test_report.json', JSON.pretty_generate(results))
    puts "💾 Report saved: ui_test_report.json".green
  end
  
  def exit_status
    exit results[:failed] > 0 ? 1 : 0
  end
end

# EXECUTE FULL PRODUCTION TEST SUITE
ThomasITHelpdeskProductionTester.new.run_full_suite
