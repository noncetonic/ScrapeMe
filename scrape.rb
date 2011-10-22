#ScrapeBB.rb v1.1 (NOW WITH THREADING!!!)
#phpBB3 Memberlist Scraping Tool
#Coded by Luis Santana
#HackTalk Security Team
#Shouts to Shardy, Rage, Node, Xires & Stacy, Natron, Pure_Hate, J0hnnyBrav0

require "rubygems"
require "mechanize"
require "work_queue"
require "progressbar"

Mechanize::Util::CODE_DIC[:SJIS] = "UTF-8"

puts "****************************************"
puts "*               ScrapeBB               *"
puts "*               Coded By               *"
puts "*             Luis Santana             *" 
puts "*           HackTalk Security          *"
puts "****************************************"

puts "Enter your username:"
user = gets.chomp
puts "Enter your password:"
pass = gets.chomp
puts "Enter the website without http and include the phpBB3 path (no trailing /):"
site = gets.chomp

dump = File.open(site.gsub('/','_') + "_scrape.txt", "w")

agent = Mechanize.new
agent.user_agent_alias = "Windows Mozilla"
page = agent.get("http://#{site}/ucp.php?mode=login")

login_form = page.forms.last
login_form.username = user
login_form.password = pass
page = agent.submit(login_form, login_form.buttons.first)

page = agent.get("http://#{site}/memberlist.php?start=0")
pages = page.body.match(/of..strong.([0-9]+)/m)

wq = WorkQueue.new(25,20)
users = Array.new
pbar = ProgressBar.new("Scrape Process", pages[1].to_i)

0.upto(pages[1].to_i).each do |count|
	wq.enqueue_b {
            page = agent.get("http://#{site}/memberlist.php?start=" + (count * 25).to_s)
            page.search("/html/body/div/div[2]/div[2]/form/div[2]/div/table/tbody/tr/td/a").each do |user|
                    if user.inner_html =~ /\D+/ then
                    	users.push("#{user.inner_html}")
                    end
        	end
    		page.search("/html/body/table/tbody/tr[5]/td/form[2]/table/tbody/tr/td[2]/a").each do |user|
        		if user.inner_html =~ /\D+/ then
            		users.push("#{user.inner_html}")
        		end
    		end

			page.search("/html/body/div/div[4]/div/div/div[3]/form/div[2]/div/table/tbody/tr/td/a").each do |user|
				if user.inner_html =~ /\D+/ then
					users.push("#{user.inner_html}")
				end
			end
	}

	pbar.set(count)

	wq.join
end
pbar.finish
users.sort!
dump.puts(users.join("\n"))
puts "\nFinished Scraping"
