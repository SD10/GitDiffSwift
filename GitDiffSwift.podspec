Pod::Spec.new do |s|
  s.name             = 'GitDiffSwift'
  s.version          = '0.0.1'
  s.summary          = 'A git diff parser written in Swift.'
  s.homepage         = 'https://github.com/SD10/GitDiffSwift'
  s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author           = { 'Steven Deutsch' => 'stevensdeutsch@yahoo.com' }
  s.social_media_url = 'https://twitter.com/_SD10_'
  s.source           = { :git => "https://github.com/SD10/GitDiffSwift.git", :tag => s.version }
  s.source_files     = 'Sources/**/*.swift'
  s.platform         = :osx, '10.9'
end
