Pod::Spec.new do |s|
    s.name         = "WatchConnector"
    s.version      = "0.1.1"
    s.summary      = "WatchConnector is a tool for more convenient interaction between Watch and Phone."
    s.description  = "WatchConnector is a tool for more convenient interaction between Watch and Phone. See the README"
    s.homepage     = "https://github.com/NSSimpleApps/WatchConnector"
    s.license      = { :type => 'MIT', :file => 'LICENSE' }
    s.author       = { 'NSSimpleApps, Sergey Poluyanov' => 'ns.simple.apps@gmail.com' }
    s.source       = { :git => "https://github.com/NSSimpleApps/WatchConnector.git", :tag => s.version.to_s }
    s.requires_arc = true
    s.platform                  = :ios, '9.0'
    s.platform                  = :watchos, '2.0'
    s.ios.deployment_target     = '9.0'
    s.watchos.deployment_target     = '2.0'
    s.source_files = "Source/WatchConnector.swift"
end