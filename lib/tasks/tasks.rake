require 'net/smtp'
require 'enumerator'

desc 'Rebuild acts_as_ferret indices'
task :rebuild_index => :environment do
  Barcode.rebuild_index
  Book.rebuild_index
  Seller.rebuild_index
end

namespace :git do
  desc 'Run before every git commit'
  task :precommit => :environment do
    Rake::Task['asset:packager:build_all'].invoke
  end
end

namespace :send do
  desc 'Send welcome back e-mail to sellers'
  task :welcome_back => :environment do
    ENV['template'] = 'welcome_back'
    Rake::Task['send:welcome_back'].invoke
  end

  desc 'Send reclaim reminder e-mail to sellers'
  task :reclaim_reminder => :environment do
    ENV['template'] = 'reclaim_reminder'
    Rake::Task['send:reclaim_reminder'].invoke
  end

  task :template => :environment do
    send_count = 0

    begin
      sellers = Seller.send "recipients_for_#{ENV['template']}"
      smtp_settings = ActionMailer::Base.smtp_settings
      smtp = Net::SMTP.new(smtp_settings[:address], smtp_settings[:port])
      smtp.enable_starttls_auto
      smtp.start(smtp_settings[:domain], smtp_settings[:user_name],
                 smtp_settings[:password], smtp_settings[:authentication]) do |sender|
        puts "Sending to #{sellers.size} sellers..."
        sellers.each do |seller|
          tmail = Notifier.send "create_#{ENV['template']}", seller
          sender.sendmail tmail.encoded, tmail.from, seller.email_address
          seller.send "send_#{ENV['template']}!"
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
end
