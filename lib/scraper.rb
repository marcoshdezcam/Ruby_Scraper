require_relative '../config/credentials.rb'
require 'mechanize'
require 'pry'
require 'selenium-webdriver'

class Scraper
  attr_reader :agent, :chrome, :results, :keywords, :distributors

  def initialize(keywords)
    @agent = Mechanize.new
    chrome_options = Selenium::WebDriver::Chrome::Options.new
    chrome_options.add_argument('--headless')
    @chrome = Selenium::WebDriver.for :chrome, options: chrome_options
    @results = [['Product name'], ['Price'], ['URL']]
    @keywords = keywords
    @distributors = {
      mercadolibre: 'https://www.mercadolibre.com.mx/', cyberpuerta: 'https://www.cyberpuerta.mx/',
      pchmayoreo: 'https://www.pchmayoreo.com/', mipc: 'https://mipc.com.mx/',
      oribalstore: 'https://www.orbitalstore.mx/buscador/index.php?terms=', grupodecme: 'https://grupodecme.com',
      digitalife: 'https://www.digitalife.com.mx/', pcel: 'https://pcel.com/index.php?route=product/search',
      ddtech: 'https://ddtech.mx/', zegucom: 'https://www.zegucom.com.mx/',
      pcmig: 'https://pcmig.com.mx/', highpro: 'https://highpro.com.mx/',
      pcdigital: 'https://www.pcdigital.com.mx/', intercompras: 'https://intercompras.com/'
    }
  end

  def search
    mercadolibre
    cyberpuerta
    pchmayoreo
    mipc
    orbitalstore
    grupodecme
    digitalife
    pcel
    ddtech
    zegucom
    pcmig
    highpro
    pcdigital
    intercompras
    clean_results
  end

  def mercadolibre
    webpage = @agent.get(distributors[:mercadolibre])
    webpage.forms.first.as_word = @keywords
    results_page = webpage.forms.first.submit
    results_page.css('div.ui-search-result__wrapper').each do |item|
      @results[0] << item.css('h2.ui-search-item__title').text
      @results[1] << item.css('span.ui-search-price__part').first.text
      @results[2] << item.css('a').first['href']
    end
  end

  def cyberpuerta
    webpage = @agent.get(distributors[:cyberpuerta])
    webpage.form('search').searchparam = @keywords
    results_page = webpage.form('search').submit
    results_page.css('div.emproduct').each do |item|
      @results[0] << item.css('a.emproduct_right_title').text
      @results[1] << item.css('label.price').text
      @results[2] << item.css('a.emproduct_right_title').first['href']
    end
  end

  def pchmayoreo
    webpage = agent.get(distributors[:pchmayoreo])
    login_page = webpage.link_with(text: 'Iniciar Sesión').click
    login_form = login_page.form_with(id: 'login-form')
    login_form.field_with(id: 'email').value = ENV['pch_user_id']
    login_form.field_with(id: 'pass').value = ENV['pch_pass_key']
    client_homepage = login_form.submit
    search_form = client_homepage.form_with(id: 'search_mini_form')
    search_form.q = @keywords
    results_page = agent.submit(search_form)
    results_page.css('div.item-inner').each do |item|
      @results[0] << item.css('h2.product-name').text
      @results[1] << item.css('span.price').first.text
      @results[2] << item.css('h2.product-name a').first['href']
    end
  end

  def mipc
    webpage = agent.get(distributors[:mipc])
    webpage.form_with(id: 'search_mini_form').q = @keywords
    results_page = webpage.form_with(id: 'search_mini_form').submit
    results_page.css('li.product-item').each do |item|
      @results[0] << item.css('h5.product-item-name').text
      @results[1] << item.at('[data-price-type="finalPrice"]').text
      @results[2] << item.css('a.product-item-link').first['href']
    end
  end

  def orbitalstore
    results_page = agent.get(distributors[:oribalstore] + @keywords)
    results_page.css('div.item').each do |item|
      @results[0] << item.css('a.title').text
      @results[1] << item.css('div.played').text
      @results[2] << item.css('a.title').first['href']
    end
  end

  def grupodecme
    webpage = agent.get(distributors[:grupodecme])
    webpage.forms.first.q = @keywords
    results_page = webpage.forms.first.submit
    results_page.css('a.product-grid-item').each do |item|
      @results[0] << item.css('p').text
      @results[1] << item.css('span.visually-hidden')[1].text
      @results[2] << (distributors[:grupodecme] + item['href'])
    end
  end

  def digitalife
    webpage = agent.get(distributors[:digitalife])
    webpage.form_with(class: 'buscador form-inline text-center').term = @keywords
    results_page = webpage.form_with(class: 'buscador form-inline text-center').submit
    results_page.css('div.productoInfoBloq').each do |item|
      @results[0] << item.css('span.tituloHighlight').text
      @results[1] << item.css('div.precioFlag').text
      @results[2] << item.css('a').first['href']
    end
  end

  def pcel
    chrome.navigate.to distributors[:pcel]
    input = chrome.find_element(name: 'filter_name')
    input.send_keys @keywords
    chrome.find_element(class: 'button-search').click
    results_page = agent.get(chrome.current_url)
    results_page.css('tr').each do |item|
      @results[0] << item.css('div.name').text[0...35] unless item.css('div.name').empty?
      @results[1] << item.css('span.price-new').text unless item.css('div.name').empty?
      @results[2] << item.css('a').first['href'] unless item.css('div.name').empty?
    end
  end

  def ddtech
    webpage = agent.get(distributors[:ddtech])
    webpage.forms.first.search = @keywords
    results_page = webpage.forms.first.submit
    results_page.css('div.item').each do |item|
      @results[0] << item.css('a').text
      @results[1] << item.css('span.price').text
      @results[2] << item.css('a').first['href']
    end
  end

  def zegucom
    webpage = agent.get(distributors[:zegucom])
    webpage.forms.first.cons = @keywords
    results_page = webpage.forms.first.submit
    results_page.css('div.search-result').each do |item|
      @results[0] << item.css('div.result-description a').text
      @results[1] << item.css('span.result-price-search').text
      @results[2] << distributors[:zegucom] + item.css('a')[1]['href']
    end
  end

  def pcmig
    webpage = agent.get(distributors[:pcmig])
    webpage.forms.first.s = @keywords
    results_page = webpage.forms.first.submit
    results_page.css('div.product-wrapper').each do |item|
      @results[0] << item.css('h2.product-name').first.text
      @results[1] << item.css('span.woocommerce-Price-amount').first.text
      @results[2] << item.css('a').first['href']
    end
  end

  def highpro
    webpage = agent.get(distributors[:highpro])
    webpage.form_with(id: 'searchbox').search_query = @keywords
    results_page = webpage.form_with(id: 'searchbox').submit
    results_page.css('div.product-container').each do |item|
      @results[0] << item.css('h5.product-title-item').text
      @results[1] << item.css('div.product-price-and-shipping').text
      @results[2] << item.css('a').first['href']
    end
  end

  def pcdigital
    chrome.navigate.to distributors[:pcdigital]
    input = chrome.find_element(name: 'search')
    input.send_keys @keywords
    chrome.find_element(class: 'button-search').click
    results_page = agent.get(chrome.current_url)
    chrome.quit
    results_page.css('div.product').each do |item|
      @results[0] << item.css('div.name').text
      @results[1] << item.css('span.price-new').text
      @results[2] << item.css('div.name a').first['href']
    end
  end

  def intercompras
    webpage = agent.get(distributors[:intercompras])
    webpage.forms.first.keywords = @keywords
    results_page = webpage.forms.first.submit
    results_page.css('div.divContentProductInfo').each do |item|
      @results[0] << item.css('a.spanProductListInfoTitle').text
      @results[1] << item.css('div.divProductListPrice').text
      @results[2] << item.css('a').first['href']
    end
  end

  def clean_results
    @results.each do |parameter|
      parameter.each do |item|
        item.tr!("\t", '')
        item.tr!("\n", '')
        item.tr!("\r", '')
        item.strip!
      end
    end
  end

  def show_results
    @results
  end

  def create_listing; end
end

scraping_test = Scraper.new('RAM 8GB')
scraping_test.search
binding.pry
