namespace :git do
  desc 'Run before every git commit'
  task :precommit => :environment do
    Rake::Task['asset:packager:build_all'].invoke
  end
end
