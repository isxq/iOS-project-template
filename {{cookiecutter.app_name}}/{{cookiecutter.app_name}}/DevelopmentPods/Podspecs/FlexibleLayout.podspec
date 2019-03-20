Pod::Spec.new do |s|
  s.name             = 'Flexible'
  s.version          = '0.0.1'
  s.summary          = '布局框架'
  
  s.homepage         = 'https://github.com/isxq'
  s.license          = { :type => 'MIT', :file => '../LICENSE.md' }
  s.author           = { '申小强' => 'shen_x_q@163.com' }
  s.source           = { :git => '../Flexible', :tag => '#{s.version}' }

  s.ios.deployment_target = '10.0'

  s.source_files = 'Flexible/Classes/**/*.{swift}'
  s.resources = 'Flexible/Resources/*'

end
