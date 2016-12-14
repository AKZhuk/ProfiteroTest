#!/usr/local/bin/ruby
require "nokogiri"
require 'open-uri'
require 'byebug'
require "csv"

class Parser
  PRODUCT_BLOCK_PATH = ".//*[@id='center_column']/div[3]/div/div/div/div[2]"
  PRODUCT_LINK_PATH = ".//div/div[1]/div[1]/h5/a[@class='product-name']/@href"
  PRODUCT_PATH = ".//*[@id='attributes']/fieldset/div/ul[@class='attribute_labels_lists']"
	PRODUCT_NAME_PATH = ".//*[@id='right']/div/div[1]/div/h1/text()"
	PRODUCT_IMAGE_PATH = ".//*[@id='bigpic']/@src"
	HOST = "http://www.petsonic.com"
	LINK_TO_TEST = "http://www.petsonic.com/es/perros/snacks-y-huesos-perro"

  attr_reader :items

  def initialize
		@items= []
  end

	def start
		if ARGV.length != 2
		  puts "We need two arguments: link filename"
		  exit
		end
		parse_catalog_page(ARGV[0])
	end

	def write_to_csv
	  @items.flatten! 
		CSV.open(ARGV[1], "wb") do |csv|
	  		csv << ["name", "price", "image"]
	  		@items.each do |item|
	  		 	csv << [item[:name],item[:price],item[:image]]  
	  		end
		end
	end	

  private

	def parse_catalog_page(catalog_link)
		page = Nokogiri::HTML(open(catalog_link))
		page.xpath(PRODUCT_BLOCK_PATH).each do |product_block|
			product_link = product_block.xpath(PRODUCT_LINK_PATH).text
			@items.push(get_multi_product(product_link))
		end

		next_page_relative_link = page.xpath(".//*[@id='pagination_next_bottom']/a/@href").text
		next_page_link = HOST + next_page_relative_link	
		parse_catalog_page(next_page_link) unless next_page_relative_link.empty?
	end

	def get_multi_product(product_link)
		variants = []
		page = Nokogiri::HTML(open(product_link))
		page.xpath(PRODUCT_PATH).each do |product|
			variants.push(parse_info(product,page))
		end
		variants	
	end

	def parse_info(product, page)
    attribute = product.xpath(".//li/span[@class='attribute_name']").text
    variant = {
      name: page.xpath(PRODUCT_NAME_PATH).text + " " + attribute,
      price: product.xpath(".//li/span[3]").text,
      image: page.xpath(PRODUCT_IMAGE_PATH).text,
    }
	end

end

parser = Parser.new
parser.start
parser.write_to_csv