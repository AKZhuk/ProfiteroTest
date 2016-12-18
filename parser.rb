#!/usr/local/bin/ruby
require "nokogiri"
require 'open-uri'
require 'byebug'
require "csv"
require "json"
require 'spreadsheet'

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

	def write_to_excel
		Spreadsheet.client_encoding = 'UTF-8'
		book = Spreadsheet::Workbook.new
		sheet1 = book.create_worksheet
		sheet1.name = '1'
		@items.flatten!
		@items.each.with_index do |item, i|
			sheet1[i,0] = item[:name]
			sheet1[i,2] = item[:price]
			sheet1[i,4] = item[:image]
	  	end
		book.write 'products.xls'
	end

	def parse_excel_book
		workbook=Spreadsheet.open 'products.xls'
		sheet1 = workbook.worksheet '1'
		sheet1.each do |row|
		  puts "#{row[0]} - #{row[2]} - #{row[4]}"
		end
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

	def parse_csv_file
		CSV.foreach("lol.csv", "r") do |row|
			puts row
		end 
	end
		
	def write_to_json
		@items.flatten!
		file = File.new("my_json_data_file.json", "wb")
		file.write(@items.to_json)
		file.close
	end	

	def parse_json_file
		file = File.read("my_json_data_file.json")
		data = JSON.parse(file)
		puts data
	end	

	def write_to_xml
        @items.flatten! 
			builder = Nokogiri::XML::Builder.new do |xml|
			  xml.root {
			    @items.each do |item|
				    xml.products {
					        xml.name_  item[:name]
					        xml.price_ item[:price]
					    	xml.img_   item[:image]
				    }
				end
			  }
		end
		file = File.new("my_xml_product_file.xml", "wb")
		file.write(builder.to_xml)
		file.close
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
		#parse_catalog_page(next_page_link) unless next_page_relative_link.empty?
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
#parser.start
#parser.parse_excel_book
#parser.write_to_csv
#parser.write_to_excel
#parser.write_to_xml
#parser.write_to_json
#parser.parse_csv_file
parser.parse_json_file