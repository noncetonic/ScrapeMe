#ScrapeBB.rb v1.2
#phpBB3 Memberlist Scraping Tool
#Coded by Luis Santana
#HackTalk Security Team
#Shouts to Shardy, Rage, Node, Xires & Stacy, Natron, Pure_Hate, J0hnnyBrav0

# Let's get the required gems
require "rubygems"
require "mechanize"
require "work_queue"
require "progressbar"

Mechanize::Util::CODE_DIC[:SJIS] = "UTF-8" # Ensuring we have UTF-8 Support

puts "****************************************"
puts "*               ScrapeBB               *"
puts "*               Coded By               *"
puts "*             Luis Santana             *" 
puts "*           HackTalk Security          *"
puts "****************************************"

# Let's create our signature "database"
sigs = Array['/html/body/div/div[2]/div[2]/form/div[2]/div/table/tbody/tr/td/a','/html/body/table/tbody/tr[5]/td/form[2]/table/tbody/tr/td[2]/a','/html/body/div/div[4]/div/div/div[3]/form/div[2]/div/table/tbody/tr/td/a']
# Get username, password, and website for scraping
puts "[+] Enter your username:"
user = gets.chomp
puts "[+] Enter your password:"
pass = gets.chomp
puts "[+] Enter the website without http and include forum path (no trailing /):"
site = gets.chomp

dump = File.open(site.gsub('/','_') + "_scrape.txt", "w") # Creating our file to dump usernames into

# Setting up Mechanize
agent = Mechanize.new
agent.user_agent_alias = "Windows Mozilla"

# Visit login page, fill form, and login
page = agent.get("http://#{site}/ucp.php?mode=login")
login_form = page.forms.last
login_form.username = user
login_form.password = pass
page = agent.submit(login_form, login_form.buttons.first)

#Visit memberlist page and grab the total number of pages
page = agent.get("http://#{site}/memberlist.php?start=0")
pages = page.body.match(/of..strong.([0-9]+)/m)

# Get our threadpool started with 25 threads with a max of 20 threads which can be waiting in the queue
wq = WorkQueue.new(25,20)

users = Array.new # Create array to hold usernames so that we don't potentially deadlock the dump file during writes

puts "[+] Now Scraping Please Wait"
pbar = ProgressBar.new("Scrape Process", pages[1].to_i) # Start our progress bar

# Start the pwnage
0.upto(pages[1].to_i).each do |count|
	wq.enqueue_b {
            page = agent.get("http://#{site}/memberlist.php?start=" + (count * 25).to_s)
			sigs.each do |sig|
            	page.search("#{sig}").each do |user|
                	if user.inner_html =~ /\D+/ then
                    	users.push("#{user.inner_html}")
                    end
        		end
			end
	}

	pbar.set(count)

	wq.join
end

# Finish off progress bar
pbar.finish

# Sort all usernames in the users array
users.sort!

# Save all sorted usernames into the dump file and print a closing message 
dump.puts(users.join("\n"))
puts "\nFinished Scraping"