Pod::Spec.new do |s|
  s.name             = 'Form'
  s.version          = '0.0.1'
  s.summary          = '表单'
  
  s.homepage         = 'https://github.com/isxq'
  s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author           = { '申小强' => 'shen_x_q@163.com' }
  s.source           = { :git => './', :tag => '#{s.version}' }

  s.ios.deployment_target = '10.0'

  s.source_files = 'Classes/**/*.{swift}'
  s.resources = 'Resources/*'

end
