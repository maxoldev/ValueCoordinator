Pod::Spec.new do |s|
  s.name             = 'ValueCoordinator'
  s.version          = '1.0.0'
  s.summary          = 'The resulting value determination with a managed stack of value providers.'

  s.description      = <<-DESC
  Create a coordinated value, add value providers, customize the resulting value determining strategy. 
                       DESC

  s.homepage         = 'https://github.com/maxoldev/ValueCoordinator'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Max Sol' => 'maxoldev@gmail.com' }
  s.source           = { :git => 'https://github.com/maxoldev/ValueCoordinator.git', :tag => s.version.to_s }

  s.swift_versions = ['5']

  s.ios.deployment_target = '9.0'
  s.tvos.deployment_target = '9.0'
  s.osx.deployment_target = '10.13'
  s.watchos.deployment_target = '3.0'

  s.source_files = 'ValueCoordinator/Classes/**/*'
end
