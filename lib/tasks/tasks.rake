def deliver(template)
  send_count = 0

  begin
    sellers = Seller.send "recipients_for_#{template}"
    smtp_settings = ActionMailer::Base.smtp_settings
    smtp = Net::SMTP.new(smtp_settings[:address], smtp_settings[:port])
    puts 'Connecting to SMTP server...'
    smtp.start(smtp_settings[:domain], smtp_settings[:user_name],
               smtp_settings[:password], smtp_settings[:authentication]) do |sender|
      puts "Sending to #{sellers.size} sellers..."
      sellers.each do |seller|
        tmail = Notifier.send "create_#{template}", seller
        sender.sendmail tmail.encoded, tmail.from, seller.email_address
        seller.send "send_#{template}!"
        send_count += 1
      end
    end
  rescue Exception => e
    puts "#{e.inspect}. Sleeping 30..."
    sleep 30
    retry
  end

  puts "Sent to #{send_count} of #{sellers.size} sellers."
end

task :welcome_back => :environment do
  deliver 'welcome_back'
end

task :reclaim_reminder => :environment do
  deliver 'reclaim_reminder'
end
